# QEMU Legacy iOS

Experimental iOS front end and porting effort targeting the **iPhone 4 GSM (n90ap)** and **iOS 7.1.2** guest.

> **Build status:** The SwiftUI app scaffold now compiles and the GitHub Actions workflow has successfully packaged an unsigned IPA. This is not yet a working emulator: the A4 machine/CPU/boot pipeline is not connected to the app, and no guest boot has been verified.

## iPhone 4 / A4 source

The repository contains copied iPhone 4 board and A4 peripheral sources in `vendor/qemu-iphone4/`, pinned to upstream QEMU-iOS commit `db230fe8e8e4d297724b2eccdc38bdc21876696a`. The shared `ipad1.c` source defines the distinct GSM iPhone 4 `a4_n90` profile; select it as `-M iPhone-4` (not `-M ipad1`). The source set includes S5L8930 devices, shared A4-generation peripherals, NAND/NOR and iBoot support, plus the adjacent models referenced by the pinned `CONFIG_IPAD1` build registration. The N90 profile enables BCM4329 Wi-Fi and an 8 GiB raw NAND configuration (four 2 GiB dies); see [Wi-Fi and storage configuration](docs/WIFI-AND-STORAGE.md) and the [8 GB NAND generator](scripts/create-iphone4-8gb-nand.sh). See [QEMU source integration](docs/QEMU-SOURCE-INTEGRATION.md) for the machine-profile distinction and staging details.

Selected Podium ARMv7 CPU, DBT/JIT, memory, boot and UI files are in `vendor/podium-a4/`. Attribution and compatibility notes are in `docs/PODIUM-A4-REUSE.md`.

**The complete generic QEMU engine is not included.** The old Git submodule link has been removed. The copied board sources are ordinary files, but still need to be overlaid into a compatible generic QEMU tree or ported to a complete native Swift engine before they can run.

## Build an unsigned IPA

The GitHub Actions workflow checks out the pinned QEMU-iOS engine submodule, uses XcodeGen to generate the current SwiftUI project from `ios/project.yml`, builds the app for iOS device, packages an unsigned IPA, and uploads it as `QEMULegacyIOS-unsigned-ipa`. The current workflow does not yet compile or link QEMU into the app.

Open [Actions → Build iOS IPA](https://github.com/Nuclear616/qemu-legacy-ios/actions/workflows/build-ipa.yml), choose a successful run, and download the artifact. The IPA is unsigned and must be signed before installation.

## Current app behavior

The app displays the iPhone 4 GSM / A4 / n90ap target, allows selecting an IPSW file, and includes an Emulator Settings screen. Settings include 1/2/4/8/16/32 GiB NAND size, a guest iOS version selector, experimental/unsigned firmware toggles, and an option to request Cydia after jailbreak. These are currently saved UI preferences only: IPSW parsing, signature/boot handling, dynamic NAND creation, guest boot, jailbreak and Cydia installation are not implemented yet. The current UI target uses iOS 17.0 or later.

## JIT and Cydia

Host JIT on iOS 27.0.1 is separate from guest iOS 7.1.2 compatibility. The copied Podium JIT code is not integrated or verified on this host OS.

Cydia can only be installed inside a booted guest after a compatible jailbreak/bootstrap is applied. No Apple firmware, iBoot binary, NAND dump, IPSW, jailbreak payload or Cydia package is included.

## Licensing

QEMU-derived sources retain upstream notices in `vendor/qemu-iphone4/upstream/`. Podium-derived files are attributed in `docs/PODIUM-A4-REUSE.md`. Preserve all applicable upstream licenses.
