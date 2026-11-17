# Project Astra

Experimental iOS front end and porting effort targeting the **iPhone 4 GSM (n90ap)** and **iOS 7.1.2** guest.

> **Build status:** The SwiftUI app scaffold now compiles and the GitHub Actions workflow has successfully packaged an unsigned IPA. This is not yet a working emulator: the A4 machine/CPU/boot pipeline is not connected to the app, and no guest boot has been verified.

## iPhone 4 / A4 source

The repository contains copied iPhone 4 board and A4 peripheral sources in `vendor/qemu-iphone4/`, pinned to upstream QEMU-iOS commit `db230fe8e8e4d297724b2eccdc38bdc21876696a`. The shared `ipad1.c` source defines the distinct GSM iPhone 4 `a4_n90` profile; select it as `-M iPhone-4` (not `-M ipad1`). The source set includes S5L8930 devices, shared A4-generation peripherals, NAND/NOR and iBoot support, plus the adjacent models referenced by the pinned `CONFIG_IPAD1` build registration. The N90 profile enables BCM4329 Wi-Fi and an 8 GiB raw NAND configuration (four 2 GiB dies); see [Wi-Fi and storage configuration](docs/WIFI-AND-STORAGE.md) and the [8 GB NAND generator](scripts/create-iphone4-8gb-nand.sh). See [QEMU source integration](docs/QEMU-SOURCE-INTEGRATION.md) for the machine-profile distinction and staging details.

Selected Podium ARMv7 CPU, DBT/JIT, memory, boot and UI files are in `vendor/podium-a4/`. Attribution and compatibility notes are in `docs/PODIUM-A4-REUSE.md`.

**The complete QEMU-iOS source is pinned as `vendor/qemu-engine`** at upstream commit `db230fe8e8e4d297724b2eccdc38bdc21876696a`. It is source-only at present: the upstream app library build is macOS-oriented, and this repository has not yet built a QEMU library for the iOS device SDK or linked its app ABI. The copied N90 board files still need to be reconciled with the full source and compiled.

## Build an unsigned IPA

The GitHub Actions workflow checks out the pinned QEMU-iOS engine submodule, uses XcodeGen to generate the current SwiftUI project from `ios/project.yml`, builds the app for iOS device, packages an unsigned IPA, and uploads it as `Project-Astra-unsigned-ipa`. The workflow now attempts to cross-build the QEMU engine for the iOS device SDK and embed it in the IPA; this engine build is still under CI validation.

Open [Actions → Build iOS IPA](https://github.com/Nuclear616/qemu-legacy-ios/actions/workflows/build-ipa.yml), choose a successful run, and download the artifact. The IPA is unsigned and must be signed before installation.

## Current app behavior

The app displays the iPhone 4 GSM / A4 / n90ap target, can browse the IPSW.me v4 catalog for iPhone3,1 and download a selected IPSW directly from Apple's CDN into the app's Documents folder, and retains manual IPSW import as a fallback. It also accepts a pre-prepared FirmwareKit device directory: the selected folder must contain `kboot.bin` and a non-empty `nand/` directory. The app copies and validates that bundle, creates a writable overlay directory, and constructs the documented `-M iPhone-4` machine arguments. It includes settings for 1/2/4/8/16/32 GiB NAND size, guest iOS version, experimental/unsigned firmware, post-jailbreak Cydia, and JIT preference. It also probes whether the host process can allocate a `MAP_JIT` mapping. The prepared-bundle import and boot-argument preparation are implemented, and the IPA workflow now builds and embeds a QEMU runtime candidate. A successful build and device boot have not yet been verified, so the Start button should still be considered experimental. IPSW parsing, in-app FirmwareKit preparation, dynamic NAND creation/resizing, the display/input bridge, actual guest boot, jailbreak and Cydia installation remain incomplete. The geometry of an imported NAND bundle is authoritative; changing the storage-size preference does not resize existing NAND files. The Project Astra app target requires iOS 17.0 or later. The built-in StikJIT helper extension requires iOS 26 or later; importing a pairing file is the iOS 26 path, while on-device pairing from Developer Mode settings is available on iOS 27 or later.

## JIT and Cydia

Host JIT on iOS 27.0.1 is separate from guest iOS 7.1.2 compatibility. The app includes selectable JIT methods and a bundled StikJIT helper workflow. The QEMU TCG code cache still needs its own complete integration with the iOS JIT write-protection API; successful helper attachment or memory validation alone does not prove QEMU's translated code can execute. iOS 27 JIT activation also depends on the signing and pairing path; see [JIT notes](docs/JIT-ON-IOS.md).

Cydia can only be installed inside a booted guest after a compatible jailbreak/bootstrap is applied. No Apple firmware, iBoot binary, NAND dump, IPSW, jailbreak payload or Cydia package is included.

## Licensing

QEMU-derived sources retain upstream notices in `vendor/qemu-iphone4/upstream/`. Podium-derived files are attributed in `docs/PODIUM-A4-REUSE.md`. Preserve all applicable upstream licenses.
