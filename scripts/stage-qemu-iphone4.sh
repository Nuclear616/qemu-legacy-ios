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

for subtree in hw/arm hw/misc include/hw/arm include/hw/misc include/hw/net; do
  if [ -d "$VENDOR/$subtree" ]; then
    mkdir -p "$ENGINE/$subtree"
    cp -R "$VENDOR/$subtree/." "$ENGINE/$subtree/"
  fi
done

# Keep this list aligned with the pinned CONFIG_IPAD1 source registrations.
for source in \
  ipad1.c s5l8930_dmc.c s5l8930_pmgr.c s5l8930_gpio.c \
  s5l8930_iop.c s5l8930_iop_core.c s5l8930_sdio.c s5l8930_i2c.c \
  s5l8930_display.c s5l8930_dart.c s5l8930_cdma.c s5l8930_bbspi.c \
  s5l8930_h2fmi.c s5l8930_sha1.c s5l8930_ltc4099.c s5l8930_hdq.c \
  s5l8930_i2s.c s5l8930_isp.c s5l8940_isp.c img_topaz.c img_topaz_h264.c \
  s5l8920.c s5l8920_pmgr.c s5l8920_dart.c s5l8920_pwm.c \
  s5l8920_vxd.c s5l8920_vxd_h264.c s5l8920_jpeg.c \
  s5l8950.c cs42l65.c cs35l19.c nand-image.c tsl2561.c \
  ipod_touch_sdio.c bcm_fullmac.c mrvl8686.c; do
  if [ ! -f "$ENGINE/hw/arm/$source" ]; then
    echo "Missing staged CONFIG_IPAD1 source: hw/arm/$source" >&2
    exit 4
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
echo "Select the GSM iPhone 4 board with -M iPhone-4 (not -M ipad1)."
echo "The default NAND ID is Samsung 0x7294D7EC (16 GB); preserve matching DT geometry."
echo "The BCM4329 Wi-Fi bridge is enabled by default; use wifi=on and a wifi0 netdev."
echo "Merge the pinned Kconfig/Meson fragments from $VENDOR/upstream/hw into the generic QEMU build files."

# Register the shared BCM4329 SDIO/full-MAC implementation exactly once.
if ! grep -q "ipod_touch_sdio.c" "$ENGINE/hw/arm/meson.build"; then
  printf '%s\n' "" "# QEMU Legacy iOS: BCM4329 Wi-Fi for the iPhone 4 GSM board." "arm_ss.add(when: 'CONFIG_IPAD1', if_true: files('ipod_touch_sdio.c', 'bcm_fullmac.c', 'mrvl8686.c'))" >> "$ENGINE/hw/arm/meson.build"
fi

if [ -f "$ENGINE/hw/arm/trace-events" ] && ! grep -q "ipod_touch_sdio_log" "$ENGINE/hw/arm/trace-events"; then
  echo "QEMU trace-events is missing ipod_touch_sdio_log; merge the pinned trace-events entry." >&2
  exit 5
fi

echo "Generic QEMU dependencies and firmware images must be supplied separately."
