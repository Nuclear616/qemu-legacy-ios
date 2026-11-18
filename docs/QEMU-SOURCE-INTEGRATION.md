# QEMU iPhone 4 source integration

## Correct machine identity

The board implementation lives in `hw/arm/ipad1.c`, but that filename is historical/shared: the file defines multiple S5L8930 A4 board profiles. It explicitly defines the GSM iPhone 4 profile as `a4_n90` and registers the QEMU machine type `iPhone-4`. Use:

```sh
-M iPhone-4
```

Do not use `-M ipad1` for the target device. The iPhone 4 profile is N90AP, S5L8930/A4, 512 MiB RAM, portrait 640x960 display and the iPhone 4 touch profile. It has its own baseband wiring and board properties. The same source file also contains iPad 1 and iPod touch 4 profiles; they are not interchangeable.

## Copied source closure

The repository keeps the board/peripheral C files and their headers as ordinary files under `vendor/qemu-iphone4/hw` and `vendor/qemu-iphone4/include`. In addition to the A4-specific models, the upstream `CONFIG_IPAD1` Meson registration compiles a few shared/adjacent models. These were easy to miss when copying only files with an `s5l8930` prefix.

The following files were added to satisfy that registration's source list:

- `hw/arm/s5l8950.c`
- `hw/arm/cs42l65.c`
- `hw/arm/cs35l19.c`
- `hw/arm/tsl2561.c`

The S5L8950 model is an A6/iPhone 5 model, not the iPhone 4. It is included because the pinned upstream Meson file puts it in the same `CONFIG_IPAD1` compilation condition. It does not change the selected `iPhone-4` machine.

## Staging into a generic QEMU tree

Run `scripts/stage-qemu-iphone4.sh` with `QEMU_SOURCE_DIR` pointing at a compatible full QEMU source checkout. The script copies the vendored `hw/arm`, `hw/misc`, and `include/hw` files into that checkout. The pinned upstream build-registration references are preserved under `vendor/qemu-iphone4/upstream/hw`.

The generic QEMU source tree is deliberately not represented as a Git submodule. The staging script does not blindly overwrite a destination tree's complete `meson.build` or `Kconfig`; those files contain many unrelated machine registrations and must be merged with the pinned upstream fragments. The required iPhone 4 machine is gated by `CONFIG_IPAD1`, which selects the PL192 interrupt controller, Exynos4 support and iOS baseband support in the pinned Kconfig.

This is source staging, not a verified QEMU build. A compatible full QEMU checkout, its normal build dependencies, and integration of the matching Kconfig/Meson registrations are still required before compiling.

## ZIP source-bundle workflow

The supplemental device implementation can be handled as one ZIP instead of
manually copying individual C/header files. The bundle layout preserves the
QEMU-relative paths:

```text
hw/arm/...
hw/misc/...
include/hw/arm/...
include/hw/misc/...
include/hw/net/...
upstream/hw/arm/trace-events
ASTRA-SOURCE-MANIFEST.json
```

`scripts/qemu-device-source-bundle.py` creates the ZIP from
`vendor/qemu-iphone4`, adds a SHA-256 manifest, and verifies every entry
before extraction. It rejects path traversal, symlinks, unexpected top-level
paths, missing required files, and content that does not match the manifest.

The normal engine build now automatically:
1. Packages the complete vendored `hw/`, `include/`, and `upstream/`
   trees into a temporary ZIP.
2. Verifies and extracts the ZIP into a temporary staging directory.
3. Overlays every bundled `hw/` and `include/` file into the matching
   location under `vendor/qemu-engine/`.
4. Merges the device-specific Meson/Kconfig registrations without replacing
   QEMU's full registration files.
5. Configures Meson and runs Ninja to compile the selected device source
   closure into `qemu-system-arm`, then links the iOS runtime dylib.

You can also supply a prebuilt archive by setting
`QEMU_DEVICE_SOURCES_ZIP` to its path. The GitHub Actions multi-device
workflow exposes this as the optional `device_sources_zip_path` input; leave
it blank to generate the ZIP automatically from the checked-in vendor files.
The archive must use the layout above and include the generated manifest.

## Firmware boundary

The repository contains emulation code, not Apple's proprietary firmware. Supply legally obtained device firmware and any required boot-chain/identity assets separately. NAND/NOR device models and image-loading code are not themselves a NAND dump or bootable iPhone firmware.

## Additional machine enabled in the iOS engine

The pinned QEMU-iOS revision already contains an S5L8900 machine for the
**original iPhone 2G (M68AP)**. It is registered as:

```sh
-M iPhone-2G
```

The iOS engine build now enables both `CONFIG_IPAD1` (A4 iPhone 4) and
`CONFIG_IPOD_TOUCH_1G` (S5L8900 original iPhone 2G) in the same
`qemu-system-arm` build. The latter selects the shared S5L8900/S5L8720
device support and its required USB, NAND, display, input, and peripheral
models. The upstream iOS UI bridge already has an `iPhone-2G` device profile
and routes Home/Power input to that machine.

**This does not yet make the app's iPhone 2G boot flow complete.** The
S5L8900 machine uses a different boot contract from the A4 iPhone 4:
a boot ROM, decrypted iBoot, a NAND page-store, and a NOR image. The current
Astra prepared-firmware importer still accepts only the N90AP `kboot.bin`
plus NAND bundle and always launches `-M iPhone-4`. A dedicated M68AP
firmware-preparation/import path and an on-device boot test are still needed.

The original iPhone 2G machine must not be treated as an iPhone 3G machine.
Although the iPhone 3G also uses an S5L8900-family SoC, it is the separate
N82AP board and is not registered by this `iPhone-2G` machine. The iPhone 3G
and iPhone 4S/A5 remain unsupported by the current engine.
