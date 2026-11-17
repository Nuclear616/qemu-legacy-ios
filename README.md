# Project Astra

Experimental iOS front end and porting effort targeting the **iPhone 4 GSM (n90ap)** and **iOS 7.1.2** guest.

 > **Build status:** An earlier scaffold-only workflow packaged an unsigned IPA. The current workflow also builds the iOS QEMU engine and includes the Astra StikJIT helper, but that combined build is still being validated. This is not yet a verified working emulator: no guest boot has been confirmed.

## iPhone 4 / A4 source

The repository contains copied iPhone 4 board and A4 peripheral sources in `vendor/qemu-iphone4/`, sourced from upstream QEMU-iOS commit `db230fe8e8e4d297724b2eccdc38bdc21876696a`. The shared `ipad1.c` source defines the distinct GSM iPhone 4 `a4_n90` profile; select it as `-M iPhone-4` (not `-M ipad1`). The source set includes S5L8930 devices, shared A4-generation peripherals, NAND/NOR and iBoot support, plus the adjacent models referenced by the pinned `CONFIG_IPAD1` build registration. The N90 profile enables BCM4329 Wi-Fi and an 8 GiB raw NAND configuration (four 2 GiB dies); see [Wi-Fi and storage configuration](docs/WIFI-AND-STORAGE.md) and the [8 GB NAND generator](scripts/create-iphone4-8gb-nand.sh). See [QEMU source integration](docs/QEMU-SOURCE-INTEGRATION.md) for the machine-profile distinction and staging details.

Selected Podium ARMv7 CPU, DBT/JIT, memory, boot and UI files are in `vendor/podium-a4/`. Attribution and compatibility notes are in `docs/PODIUM-A4-REUSE.md`.

**The complete QEMU-iOS source is pinned as `vendor/qemu-engine`** at upstream commit `db230fe8e8e4d297724b2eccdc38bdc21876696a`. A dedicated cross-build script now configures the engine for the iOS device SDK, stages the iPhone 4 board sources, and attempts to produce an embeddable `libqemu-arm.dylib`. CI has exposed toolchain/configuration issues that are being corrected; a successful engine build and guest boot have not yet been verified.

## Build an unsigned IPA

The GitHub Actions workflow checks out the pinned QEMU-iOS engine submodule, uses XcodeGen to generate the SwiftUI project from `ios/project.yml`, and attempts to cross-build the engine for the iOS device SDK before packaging an unsigned IPA. The combined engine/IPA pipeline is experimental and must pass CI before the resulting package can be considered complete.

Open [Actions → Build iOS IPA](https://github.com/Nuclear616/qemu-legacy-ios/actions/workflows/build-ipa.yml), choose a successful run, and download the artifact. The IPA is unsigned and must be signed before installation.

## Current app behavior

The app displays the iPhone 4 GSM / A4 / n90ap target, can browse the IPSW.me v4 catalog for iPhone3,1 and download a selected IPSW directly from Apple's CDN into the app's Documents folder, and retains manual IPSW import as a fallback. It also accepts a pre-prepared FirmwareKit device directory: the selected folder must contain `kboot.bin` and a non-empty `nand/` directory. The app copies and validates that bundle, creates a writable overlay directory, and constructs the documented `-M iPhone-4` machine arguments. It includes settings for 1/2/4/8/16/32 GiB NAND size, guest iOS version, experimental/unsigned firmware, post-jailbreak Cydia, and JIT preference. It also probes whether the host process can allocate a `MAP_JIT` mapping. The prepared-bundle import and boot-argument preparation are implemented, and the IPA workflow now builds and embeds a QEMU runtime candidate. A successful build and device boot have not yet been verified, so the Start button should still be considered experimental. IPSW parsing, in-app FirmwareKit preparation, dynamic NAND creation/resizing, the display/input bridge, actual guest boot, jailbreak and Cydia installation remain incomplete. The geometry of an imported NAND bundle is authoritative; changing the storage-size preference does not resize existing NAND files. The Project Astra app target requires iOS 17.0 or later. The built-in StikJIT helper extension requires iOS 26 or later; importing a pairing file is the iOS 26 path, while on-device pairing from Developer Mode settings is available on iOS 27 or later.

## JIT and Cydia

Host JIT on iOS 27.0.1 is separate from guest iOS 7.1.2 compatibility. The app includes selectable JIT methods and a bundled StikJIT helper workflow. The QEMU TCG code cache still needs its own complete integration with the iOS JIT write-protection API; successful helper attachment or memory validation alone does not prove QEMU's translated code can execute. iOS 27 JIT activation also depends on the signing and pairing path; see [JIT notes](docs/JIT-ON-IOS.md).

Cydia can only be installed inside a booted guest after a compatible jailbreak/bootstrap is applied. No Apple firmware, iBoot binary, NAND dump, IPSW, jailbreak payload or Cydia package is included.

## Credits and licensing

Project Astra is created and maintained by **Nuclear616**. See [AUTHORS.md](AUTHORS.md) for project and upstream credits, [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the license inventory and Apple firmware/device notices, and [PUBLIC-RELEASE-CHECKLIST.md](PUBLIC-RELEASE-CHECKLIST.md) before making this repository public. Project-authored code is offered under GPLv2; third-party components retain their own licenses and notices. QEMU-derived source notices are preserved in `vendor/qemu-iphone4/upstream/`.

**Apple firmware is not included or relicensed here.** Do not commit or publish IPSW files, extracted firmware, boot ROMs, or device dumps unless redistribution is expressly authorized by Apple. Project Astra is not affiliated with or endorsed by Apple.
