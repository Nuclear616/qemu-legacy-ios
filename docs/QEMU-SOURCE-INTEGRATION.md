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

## Firmware boundary

The repository contains emulation code, not Apple's proprietary firmware. Supply legally obtained device firmware and any required boot-chain/identity assets separately. NAND/NOR device models and image-loading code are not themselves a NAND dump or bootable iPhone firmware.
