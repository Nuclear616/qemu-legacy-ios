#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ENGINE="${QEMU_SOURCE_DIR:-}"
VENDOR="$ROOT/vendor/qemu-iphone4"

if [ -z "$ENGINE" ]; then
  echo "Set QEMU_SOURCE_DIR to a separately obtained compatible QEMU source tree." >&2
  echo "The generic QEMU engine is not vendored or linked as a submodule here." >&2
  exit 2
fi

if [ ! -f "$ENGINE/meson.build" ] || [ ! -f "$ENGINE/hw/arm/meson.build" ]; then
  echo "QEMU source tree not found or incomplete at: $ENGINE" >&2
  exit 2
fi

for subtree in hw/arm hw/misc include/hw/arm include/hw/misc; do
  if [ -d "$VENDOR/$subtree" ]; then
    mkdir -p "$ENGINE/$subtree"
    cp -R "$VENDOR/$subtree/." "$ENGINE/$subtree/"
  fi
done

grep -q "CONFIG_IPAD1" "$ENGINE/hw/arm/meson.build" || {
  echo "QEMU engine is missing CONFIG_IPAD1 source registration." >&2
  exit 3
}
grep -q "config IPAD1" "$ENGINE/hw/arm/Kconfig" || {
  echo "QEMU engine is missing the IPAD1 Kconfig option." >&2
  exit 3
}

echo "Staged copied iPhone 4 GSM (n90ap/A4) sources into: $ENGINE"
echo "Generic QEMU dependencies and firmware images must be supplied separately."
