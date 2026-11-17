#!/usr/bin/env bash
# Vendor the built-in StikJIT implementation from Husk at a pinned revision.
# Upstream is GPL-2.0-or-later; StikJIT.framework is MPL-2.0.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REV="29abb512d81bf8cc08babcbe7f7007cb557208ef"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ARCHIVE="$WORK/husk.tar.gz"
SOURCE="$WORK/husk"

echo "Fetching Husk built-in StikJIT source at $REV"
curl --fail --location --retry 3 --silent --show-error \
  "https://codeload.github.com/Leviidev/Husk/tar.gz/$REV" -o "$ARCHIVE"
mkdir -p "$SOURCE"
tar -xzf "$ARCHIVE" --strip-components=1 -C "$SOURCE"

APP="$ROOT/ios/Sources/HuskJIT"
HELPER="$ROOT/ios/Sources/HuskJITHelper"
VENDOR="$ROOT/ios/vendor/husk-stikjit"
mkdir -p "$APP" "$HELPER" "$ROOT/ios/Resources" "$ROOT/ios/Frameworks" "$VENDOR"

# App-side orchestration, pairing and helper-extension request transport.
for file in JITBuiltIn.swift JITPairing.swift JITSetup.swift HuskRPPairing.h; do
  cp "$SOURCE/src/app/Husk/$file" "$APP/$file"
done
# Brand the iOS 27 pairing host as Project Astra rather than the upstream app.
python3 - "$APP/JITPairing.swift" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
s = s.replace('static let hostName = "Husk"', 'static let hostName = "Project Astra"', 1)
p.write_text(s)
PY
cp "$SOURCE/src/app/HuskJITHelper/HuskJITMessages.swift" "$APP/HuskJITMessages.swift"
cp "$SOURCE/src/app/Husk/Resources/husk-jit.js" "$ROOT/ios/Resources/husk-jit.js"

# Claim and validate Astra's fixed-size QEMU code cache while the helper is
# still servicing breakpoint RPCs. Waiting only for CS_DEBUGGED is not enough:
# the helper detaches as soon as the app sends the detach breakpoint.
python3 - "$APP/JITSetup.swift" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = """                    readiness = Self.waitForDebugger { attached in
                        finish(attached ? nil : "The helper did not attach within 90 seconds. "
                                              + "Check that LocalDevVPN is connected, then try again.")
                    }"""
new = """                    readiness = Self.waitForDebugger { attached in
                        guard attached else {
                            finish("The helper did not attach within 90 seconds. Check that LocalDevVPN is connected, then try again.")
                            return
                        }
                        let claimed = AstraJITMemory.prepareWhileDebuggerAttached()
                        finish(claimed ? nil : "StikJIT attached, but Project Astra could not claim and validate its QEMU JIT memory region. Check the JIT memory log and try again.")
                    }"""
if old not in s:
    raise SystemExit("Could not find Husk's built-in attach callback to integrate Astra's QEMU JIT allocator")
p.write_text(s.replace(old, new, 1))
PY

# The helper is a separate extension process: it must not be compiled into the app.
cp "$SOURCE/src/app/HuskJITHelper/HuskJITHelper.swift" "$HELPER/HuskJITHelper.swift"
cp "$SOURCE/src/app/HuskJITHelper/HuskJITMessages.swift" "$HELPER/HuskJITMessages.swift"
cp "$SOURCE/src/app/HuskJITHelper/Info.plist" "$HELPER/Info.plist"

# StikJIT is dynamically used by the helper. The post-build phase copies it into
# the containing app's Frameworks directory for sideloaders to sign together.
rm -rf "$ROOT/ios/Frameworks/StikJIT.xcframework"
cp -R "$SOURCE/src/app/Frameworks/StikJIT.xcframework" "$ROOT/ios/Frameworks/StikJIT.xcframework"

# On-device iOS 27 pairing uses idevice's PairableHost through this small Rust
# static library. Keep its source and notices with the vendored upstream files.
rm -rf "$VENDOR/src"
mkdir -p "$VENDOR/src"
cp "$SOURCE/LICENSE" "$VENDOR/LICENSE"
cp "$SOURCE/docs/06-built-in-jit.md" "$VENDOR/BUILT-IN-JIT.md"
cp "$SOURCE/docs/02-jit-substrate.md" "$VENDOR/JIT-SUBSTRATE.md"
cp "$SOURCE/src/rppairing-ios/Cargo.toml" "$VENDOR/src/Cargo.toml"
cp "$SOURCE/src/rppairing-ios/Cargo.lock" "$VENDOR/src/Cargo.lock"
cp "$SOURCE/src/rppairing-ios/notices.py" "$VENDOR/src/notices.py"
rm -rf "$VENDOR/src/src"
cp -R "$SOURCE/src/rppairing-ios/src" "$VENDOR/src/src"
cp "$SOURCE/src/app/Husk/Resources/legal/LICENSE-StikJIT-MPL-2.0.txt" "$VENDOR/LICENSE-StikJIT-MPL-2.0.txt"

if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
fi
rustup target add aarch64-apple-ios
(
  cd "$VENDOR/src"
  cargo build --release --locked --target aarch64-apple-ios
)
mkdir -p "$ROOT/ios/build/lib"
cp "$VENDOR/src/target/aarch64-apple-ios/release/libhusk_rppairing.a" "$ROOT/ios/build/lib/libhusk_rppairing.a"
python3 "$VENDOR/src/notices.py" "$ROOT/ios/Resources/LICENSES-rppairing-crates.txt"

echo "Built-in StikJIT sources, helper framework and iOS pairing library are ready."
