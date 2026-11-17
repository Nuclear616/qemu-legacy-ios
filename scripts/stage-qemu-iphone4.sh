#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ENGINE="${QEMU_SOURCE_DIR:-$ROOT/vendor/qemu-ios}"
VENDOR="$ROOT/vendor/qemu-iphone4"

if [ ! -f "$ENGINE/meson.build" ] || [ ! -f "$ENGINE/hw/arm/meson.build" ]; then
  echo "QEMU source tree not found at: $ENGINE" >&2
  echo "Initialize the pinned QEMU engine checkout or set QEMU_SOURCE_DIR." >&2
  exit 2
fi

# Stage the copied Apple board sources at their original QEMU-relative paths.
# This deliberately copies source files; it does not rely on symlinks.
for subtree in hw/arm hw/misc include/hw/arm include/hw/misc; do
  if [ -d "$VENDOR/$subtree" ]; then
    mkdir -p "$ENGINE/$subtree"
    cp -R "$VENDOR/$subtree/." "$ENGINE/$subtree/"
  fi
done

# The upstream revision already registers CONFIG_IPAD1 and its dependencies.
# Fail early if the selected engine revision is not compatible with this board.
grep -q "CONFIG_IPAD1" "$ENGINE/hw/arm/meson.build" || {
  echo "QEMU engine is missing CONFIG_IPAD1 source registration." >&2
  exit 3
}
grep -q "config IPAD1" "$ENGINE/hw/arm/Kconfig" || {
  echo "QEMU engine is missing the IPAD1 Kconfig option." >&2
  exit 3
}
test -f "$ENGINE/hw/arm/ipad1.c"
test -f "$ENGINE/hw/arm/it_iboot.c"
test -f "$ENGINE/hw/arm/nand-image.c"
test -f "$ENGINE/hw/arm/s5l8900_nand_ecc.c"
test -f "$ENGINE/hw/arm/s5l8930_h2fmi.c"

echo "Staged copied iPhone 4 GSM (n90ap/A4) source into: $ENGINE"
echo "Machine type: iPhone-4"
echo "Firmware/NAND/NOR input images must be supplied separately."
