# QEMU Legacy iOS

Experimental iOS front end targeting the **iPhone 4 GSM (n90ap)** and **iOS 7.1.2** guest.

## Current status

- iPhone 4/A4 QEMU board and peripheral sources are copied into `vendor/qemu-iphone4/`.
- Selected Podium ARMv7 CPU, memory, boot and UI sources are copied into `vendor/podium-a4/`.
- A native SwiftUI app target is defined in `ios/project.yml`.
- GitHub Actions generates the Xcode project with XcodeGen and builds an unsigned IPA.
- **This is currently a front-end scaffold. The A4 machine/CPU/boot pipeline is not connected to Start, and no guest boot has been verified.**

## Build

Run **Actions → Build iOS IPA → Run workflow**. The workflow installs XcodeGen, generates the project, builds for iOS device, and uploads an unsigned IPA artifact. Sign it before installation.

The front end currently targets iOS 17.0 or later. No Apple firmware, iBoot binary, NAND dump, IPSW, or Cydia package is included. Selecting an IPSW only records the selected file; extraction and boot are not implemented.

## JIT

Host JIT on iOS 27.0.1 is separate from guest iOS 7.1.2 compatibility. The copied Podium JIT code is not integrated or verified on this host OS.

## Licensing

QEMU-derived sources retain upstream notices in `vendor/qemu-iphone4/upstream/`. Podium-derived files are attributed in `docs/PODIUM-A4-REUSE.md`. Preserve all applicable upstream licenses.
