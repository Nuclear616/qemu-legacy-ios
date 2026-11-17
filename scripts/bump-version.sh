#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$ROOT/VERSION"
python3 - "$VERSION_FILE" "${1:-}" <<'PY'
import pathlib
import re
import secrets
import string
import sys

path = pathlib.Path(sys.argv[1])
current = sys.argv[2] if len(sys.argv) > 2 else (path.read_text().strip() if path.exists() else "0.0.0")
match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", current)

if not match:
    # Once the numeric range is exhausted, every subsequent build gets a
    # fresh, 16-character identifier using digits and upper/lowercase letters.
    alphabet = string.digits + string.ascii_uppercase + string.ascii_lowercase
    next_version = "".join(secrets.choice(alphabet) for _ in range(16))
else:
    major, minor, patch = map(int, match.groups())
    if (major, minor, patch) == (128, 32, 16):
        alphabet = string.digits + string.ascii_uppercase + string.ascii_lowercase
        next_version = "".join(secrets.choice(alphabet) for _ in range(16))
    elif major == 0 and minor == 0 and patch < 16:
        next_version = f"0.0.{patch + 1}"
    elif patch < 16:
        next_version = f"{major}.{minor}.{patch + 1}"
    elif minor < 32:
        next_version = f"{major}.{minor + 1}.0"
    else:
        next_version = f"{major + 1}.0.0"

path.write_text(next_version + "\n")
print(next_version)
PY
