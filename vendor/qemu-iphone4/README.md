# Vendored iPhone 4 GSM (n90ap) source

Copied from `samhenrigold/qemu-ios` at commit `db230fe8e8e4d297724b2eccdc38bdc21876696a`. These are ordinary files in this repository, not a Git submodule.

## Copied implementation

- `hw/arm/ipad1.c`: A4 board profiles including `a4_n90` and the `iPhone-4` machine.
- `hw/arm/s5l8930_*.c` and matching headers: S5L8930/A4 devices.
- `hw/arm/ipod_touch_*.c` and matching headers: shared A4-generation peripherals.
- NAND image, ECC, H2FMI, NOR/SPI and iBoot support.
- Guest helper, baseband and vibrator models where included.
- Upstream build metadata and license texts are retained under `upstream/`.

## Important source boundary

This is **not the complete QEMU engine**. Generic QEMU CPU, TCG, memory, device framework, Meson and other dependencies have not been copied into this directory. The staging script can overlay these board files into a separately obtained compatible QEMU source tree by setting `QEMU_SOURCE_DIR`; this repository no longer links or checks out the upstream engine as a submodule.

## Firmware and NAND data

No Apple iBoot, boot ROM, IPSW, kernel, root filesystem, NAND dump, NOR contents, activation data or Wi-Fi firmware is included. The board code expects prepared boot and storage inputs; copying emulator source does not create those images. The upstream FirmwareKit preparation pipeline is a separate dependency.

## Cydia

Cydia is not part of the hardware emulator. It can only be installed inside the guest after iOS 7.1.2 boots and a compatible jailbreak/bootstrap has been applied. No Cydia app package or jailbreak payload is included.
