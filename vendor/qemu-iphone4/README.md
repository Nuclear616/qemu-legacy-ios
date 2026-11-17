# Vendored iPhone 4 GSM (n90ap) source

This directory contains copied source files from `samhenrigold/qemu-ios` at
`db230fe8e8e4d297724b2eccdc38bdc21876696a`.

## Copied implementation

- `hw/arm/ipad1.c`: A4 SoC and board profiles, including `a4_n90` and the
  `iPhone-4` machine type.
- `hw/arm/s5l8930_*.c` and `include/hw/arm/s5l8930.h`: S5L8930/A4 SoC
  devices, MMIO, interrupts, memory controller, display, DART, DMA, IOP,
  storage, power, I2C, audio and related hardware.
- `hw/arm/ipod_touch_*.c` and matching headers: shared A4-generation
  peripherals used by the iPhone 4 board.
- `hw/arm/it_iboot.c`: iBoot/boot handoff support.
- `hw/arm/nand-image.c`, `s5l8900_nand_ecc.c`, and
  `s5l8930_h2fmi.c`: NAND image, ECC and controller support.
- `hw/arm/ipod_touch_nor_spi.c`: NOR/SPI support used by the board's
  firmware layout.
- `hw/misc/ios_baseband*.c` and `ios_vibrator.c`: baseband and vibration
  device models.
- `hw/arm/guest-*.c`, `guest-services.c`, `guest-gles.c`, and
  `ipod-agent.c`: guest-side service bridges used by the upstream machine.
- `docs/n90/README.md`: upstream board notes and the documented iOS 7.1.2
  boot results.
- `upstream/hw/arm/meson.build`, `upstream/hw/arm/Kconfig`, and the
  misc build metadata: reference build registration from the same revision.
- `upstream/COPYING` and `upstream/LICENSE`: upstream license texts.

## Firmware and NAND data

The emulator source knows how to load KBoot, NAND and NOR inputs; this
repository does **not** contain Apple's iBoot, boot ROM, IPSW, kernel,
root filesystem, NAND dump, NOR contents, activation data or Wi-Fi firmware.
Those are firmware assets, not emulator source files. Supply a compatible
iPhone3,1/iPhone 4 GSM firmware set that you are entitled to use. For iOS
7.1.2, upstream's documented build is `n90ap-11D257`.

The board code expects a prepared KBoot image plus NAND storage and optional
NOR overlay paths. It does not manufacture those files from an IPSW by itself;
the upstream FirmwareKit preparation pipeline is a separate dependency.

## Build integration status

The source is copied as ordinary files (not a Git submodule). It is staged
into the QEMU source tree by `scripts/stage-qemu-iphone4.sh`. The generic
QEMU CPU, TCG, memory, device framework and build system are still required;
the current repository keeps the pinned QEMU source checkout for that engine.
The copied board source has not yet been compiled or boot-tested in this fork.

## Cydia

Cydia is not part of the hardware emulator. It can only be installed inside
the guest after iOS 7.1.2 boots and a compatible jailbreak/bootstrap has been
applied. No Cydia app package or jailbreak payload is included here. The
eventual app should allow importing user-supplied jailbreak/bootstrap files
rather than bundling copyrighted or device-specific firmware.
