#!/usr/bin/env bash
# Vendor the built-in StikJIT implementation from Leviidev/Husk at a pinned
# revision, then brand the app-side integration as Project Astra.
# Preserve upstream GPL/MPL notices and source attribution.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REV="29abb512d81bf8cc08babcbe7f7007cb557208ef"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ARCHIVE="$WORK/upstream.tar.gz"
SOURCE="$WORK/upstream"

echo "Fetching Project Astra's pinned built-in StikJIT source"
curl --fail --location --retry 3 --silent --show-error \
  "https://codeload.github.com/Leviidev/Husk/tar.gz/$REV" -o "$ARCHIVE"
mkdir -p "$SOURCE"
tar -xzf "$ARCHIVE" --strip-components=1 -C "$SOURCE"

APP="$ROOT/ios/Sources/AstraJIT"
HELPER="$ROOT/ios/Sources/AstraJITHelper"
VENDOR="$ROOT/ios/vendor/stikjit"
mkdir -p "$APP" "$HELPER" "$ROOT/ios/Resources" "$ROOT/ios/Frameworks" "$VENDOR"

# App-side orchestration, pairing, and helper-extension request transport.
for file in JITBuiltIn.swift JITPairing.swift JITSetup.swift; do
  cp "$SOURCE/src/app/Husk/$file" "$APP/$file"
done
cp "$SOURCE/src/app/Husk/HuskRPPairing.h" "$APP/AstraRPPairing.h"
cp "$SOURCE/src/app/HuskJITHelper/HuskJITMessages.swift" "$APP/AstraJITMessages.swift"
cp "$SOURCE/src/app/Husk/Resources/husk-jit.js" "$ROOT/ios/Resources/astra-jit.js"

# Keep the helper in its own extension process.
cp "$SOURCE/src/app/HuskJITHelper/HuskJITHelper.swift" "$HELPER/AstraJITHelper.swift"
cp "$SOURCE/src/app/HuskJITHelper/HuskJITMessages.swift" "$HELPER/AstraJITMessages.swift"
cp "$SOURCE/src/app/HuskJITHelper/Info.plist" "$HELPER/Info.plist"

# Apply the Project Astra product identity to the copied implementation.
# C ABI symbols are renamed in both the Rust implementation and its header.
python3 - "$APP" "$HELPER" "$ROOT/ios/Resources/astra-jit.js" <<'PY'
from pathlib import Path
import sys
roots = [Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])]
replacements = [
    ("HuskJITHelperHandler", "AstraJITHelperHandler"),
    ("HuskJITHelper", "AstraJITHelper"),
    ("HuskBuiltInJIT", "AstraBuiltInJIT"),
    ("HuskJITRequest", "AstraJITRequest"),
    ("HuskJITWork", "AstraJITWork"),
    ("HuskJIT", "AstraJIT"),
    ("HuskLog", "AstraLog"),
    ("husk_rppairing", "astra_rppairing"),
    ("husk.jit", "astra.jit"),
    ("husk.pairing", "astra.pairing"),
    ("com.husk.app", "com.projectastra.app"),
    ("husk-jit.js", "astra-jit.js"),
    ("Husk", "Project Astra"),
    ("husk", "astra"),
]
for root in roots:
    files = [root] if root.is_file() else [
        p for p in root.rglob("*") if p.is_file() and p.suffix in {".swift", ".h", ".plist", ".js"}
    ]
    for path in files:
        try:
            text = path.read_text()
        except UnicodeDecodeError:
            continue
        for old, new in replacements:
            text = text.replace(old, new)
        path.write_text(text)
# Keep the method's platform scope explicit in the selector.
p = Path(sys.argv[1]) / "JITSetup.swift"
text = p.read_text().replace(
    'case .builtIn: return "Built-in StikJIT"',
    'case .builtIn: return "Built-in StikJIT (iOS 27+)"'
)
p.write_text(text)
# On-device pairing is a distinct iOS 27+ capability; imported pairing files
# remain available on iOS 26 for the built-in helper.
p = Path(sys.argv[1]) / "JITPairing.swift"
text = p.read_text().replace('static let hostName = "Project Astra"', 'static let hostName = "Project Astra"')
p.write_text(text)
PY

# The app's C/Swift bridge uses the Astra-renamed pairing header.
cat > "$APP/AstraJITBridge.h" <<'EOF'
#include "AstraRPPairing.h"
EOF

# StikJIT framework is loaded by the helper extension. Retain its upstream
# binary unchanged and keep its original MPL license alongside the IPA.
rm -rf "$ROOT/ios/Frameworks/StikJIT.xcframework"
cp -R "$SOURCE/src/app/Frameworks/StikJIT.xcframework" "$ROOT/ios/Frameworks/StikJIT.xcframework"

# Vendor the Rust PairableHost source and its original notices.
rm -rf "$VENDOR/src"
mkdir -p "$VENDOR/src"
cp "$SOURCE/LICENSE" "$VENDOR/LICENSE"
cp "$SOURCE/docs/06-built-in-jit.md" "$VENDOR/BUILT-IN-JIT.md"
cp "$SOURCE/docs/02-jit-substrate.md" "$VENDOR/JIT-SUBSTRATE.md"
cp "$SOURCE/src/rppairing-ios/Cargo.toml" "$VENDOR/src/Cargo.toml"
cp "$SOURCE/src/rppairing-ios/Cargo.lock" "$VENDOR/src/Cargo.lock"
cp "$SOURCE/src/rppairing-ios/notices.py" "$VENDOR/src/notices.py"
cp -R "$SOURCE/src/rppairing-ios/src" "$VENDOR/src/src"
cp "$SOURCE/src/app/Husk/Resources/legal/LICENSE-StikJIT-MPL-2.0.txt" "$VENDOR/LICENSE-StikJIT-MPL-2.0.txt"
cp "$SOURCE/LICENSE" "$ROOT/ios/Resources/LICENSE-UPSTREAM-GPL-2.0-or-later.txt"
cp "$SOURCE/src/app/Husk/Resources/legal/LICENSE-StikJIT-MPL-2.0.txt" "$ROOT/ios/Resources/LICENSE-StikJIT-MPL-2.0.txt"

# Rename the crate's output/library ABI while retaining the upstream package
# identity in Cargo.lock for reproducible locked dependency resolution.
python3 - "$VENDOR/src" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
cargo = root / "Cargo.toml"
s = cargo.read_text().replace('[lib]\ncrate-type', '[lib]\nname = "astra_rppairing"\ncrate-type')
cargo.write_text(s)
for p in (root / "src").rglob("*.rs"):
    s = p.read_text().replace("husk_rppairing", "astra_rppairing")
    p.write_text(s)
PY

if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
fi
rustup target add aarch64-apple-ios
export IPHONEOS_DEPLOYMENT_TARGET=17.0
(
  cd "$VENDOR/src"
  cargo build --release --locked --target aarch64-apple-ios
)
mkdir -p "$ROOT/ios/build/lib"
cp "$VENDOR/src/target/aarch64-apple-ios/release/libastra_rppairing.a" "$ROOT/ios/build/lib/libastra_rppairing.a"
python3 "$VENDOR/src/notices.py" "$ROOT/ios/Resources/LICENSES-rppairing-crates.txt"

cat > "$VENDOR/UPSTREAM-NOTICE.md" <<EOF
# Upstream source notice

Project Astra's built-in StikJIT integration is adapted from Leviidev/Husk
at revision $REV. The upstream source is licensed under GPL-2.0-or-later.
The bundled StikJIT.framework retains its upstream MPL-2.0 license.
See LICENSE and LICENSE-StikJIT-MPL-2.0.txt in this directory.
EOF

echo "Project Astra StikJIT sources, helper extension, and pairing library are ready."
