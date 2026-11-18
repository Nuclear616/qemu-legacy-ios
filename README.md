# Project Astra

Experimental iOS front end and porting effort targeting the **iPhone 4 GSM (n90ap)** and **iOS 7.1.2** guest.

 > **Build status:** The iOS ARM64 QEMU engine has now compiled successfully and is published as a versioned GitHub Release asset. The first successful engine build was Actions run #29; it produced a 32.5 MB arm64 dylib targeting iOS 17. The IPA workflow's architecture-check argument bug has been corrected and packaging is awaiting a deliberate manual run. No iOS guest boot has yet been confirmed, so Project Astra is not yet a verified working emulator.

## iPhone 4 / A4 source

The repository contains copied iPhone 4 board and A4 peripheral sources in `vendor/qemu-iphone4/`, sourced from upstream QEMU-iOS commit `db230fe8e8e4d297724b2eccdc38bdc21876696a`. The shared `ipad1.c` source defines the distinct GSM iPhone 4 `a4_n90` profile; select it as `-M iPhone-4` (not `-M ipad1`). The source set includes S5L8930 devices, shared A4-generation peripherals, NAND/NOR and iBoot support, plus the adjacent models referenced by the pinned `CONFIG_IPAD1` build registration. The N90 profile enables BCM4329 Wi-Fi and an 8 GiB raw NAND configuration (four 2 GiB dies); see [Wi-Fi and storage configuration](docs/WIFI-AND-STORAGE.md) and the [8 GB NAND generator](scripts/create-iphone4-8gb-nand.sh). See [QEMU source integration](docs/QEMU-SOURCE-INTEGRATION.md) for the machine-profile distinction and staging details.

Selected Podium ARMv7 CPU, DBT/JIT, memory, boot and UI files are in `vendor/podium-a4/`. Attribution and compatibility notes are in `docs/PODIUM-A4-REUSE.md`.

**The complete QEMU-iOS source is pinned as `vendor/qemu-engine`** at upstream commit `db230fe8e8e4d297724b2eccdc38bdc21876696a`. A dedicated cross-build script configures the engine for the iOS device SDK, stages the iPhone 4 board sources, and produces an embeddable `libqemu-arm.dylib`. The engine build has succeeded and its SHA-256, architecture, release tag, and required ABI symbols are recorded in the `engine-binaries` branch manifest. This confirms compilation and publishing only; it does not confirm that the guest boots.

## Build an unsigned IPA

The manual **Build iOS IPA** workflow downloads the published engine using the `engine-binaries` manifest, verifies its SHA-256, arm64 architecture, and all eight required bridge symbols, then uses XcodeGen to build and package the app. IPA builds are manual-only while the engine and guest boot are being validated. The release-publication gate remains disabled until an actual guest boot is tested.

Open [Actions → Build iOS IPA](https://github.com/Nuclear616/qemu-legacy-ios/actions/workflows/build-ipa.yml) and run the workflow manually. Download the unsigned IPA artifact from a successful run; installation still requires a compatible signing method.

## Current app behavior

The app browses the IPSW.me v4 catalog, downloads IPSWs from Apple's CDN, and verifies the returned SHA-1 checksum before keeping a download. The catalog labels iPhone 2G, 3G, 4, and 4S firmware separately. The app accepts a FirmwareKit-prepared device folder containing `kboot.bin` and a populated `nand/` directory. New prepared bundles also carry `astra-firmware.json`; the importer validates its board/build identity, rejects unsafe symbolic links, and checks the selected iOS version against the bundle metadata. Import is staged and swapped into place only after validation, preserving the previous good bundle if a replacement fails. Older bundles without metadata remain importable but are explicitly reported as unverified.

**Only iPhone 4 GSM / A4 / n90ap is currently enabled for boot.** The iPhone 2G, 3G, and 4S/A5 choices are visible as experimental targets but Start is blocked for them because their separate QEMU board and firmware paths are not implemented. The app embeds the QEMU runtime, display/input bridge, readiness polling, and guest storage/shutdown status checks, but those paths still need real-device guest-boot testing. The QEMU build currently uses its TCG interpreter fallback; the separate Podium JIT allocator is not connected to QEMU's translated-code cache. The interpreter may be very slow. Audio output, guest jailbreak, and Cydia installation are not implemented.

The NAND geometry in an imported bundle is authoritative. The 1/2/4/8/16/32 GiB setting is only a preference and does not resize NAND images. New firmware metadata is checked against the selected iOS version; legacy bundles without metadata cannot be checked. The app target requires iOS 17.0 or later. The built-in StikJIT helper extension requires iOS 26 or later; importing a pairing file is the iOS 26 path, while on-device pairing from Developer Mode settings is available on iOS 27 or later.

**Guest iOS profiles shown in Settings:** the A4/iPhone 4 selector lists 4.2.1, 5.1.1, 6.1.3, 7.1.2, 8.4.1 and 9.3.6, but only versions with a matching prepared bundle can pass the new metadata check. The FirmwareKit preparation workflow currently prepares iOS 6.1.3 and 7.1.2 for iPhone 4 GSM. The iPhone 2G, 3G, and 4S profiles are informational/experimental only and cannot boot in the current engine.

## JIT and Cydia

Host JIT on iOS is separate from guest iOS compatibility. The app includes selectable JIT methods and a bundled StikJIT helper workflow, but the current QEMU engine is built with `tcg_interpreter=true`; Podium's separate JIT allocator is not connected to QEMU TCG. The app therefore does not block interpreter-mode startup on Podium JIT availability, and enabling host JIT does not accelerate the current QEMU build. A native QEMU JIT backend remains future work. See [JIT notes](docs/JIT-ON-IOS.md).

Cydia can only be installed inside a booted guest after a compatible jailbreak/bootstrap is applied. No Apple firmware, iBoot binary, NAND dump, IPSW, jailbreak payload or Cydia package is included.

## Credits and licensing

Project Astra is created and maintained by **Nuclear616**. See [AUTHORS.md](AUTHORS.md) for project and upstream credits, [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the license inventory and Apple firmware/device notices, and [PUBLIC-RELEASE-CHECKLIST.md](PUBLIC-RELEASE-CHECKLIST.md) before making this repository public. Project-authored code is offered under GPLv2; third-party components retain their own licenses and notices. QEMU-derived source notices are preserved in `vendor/qemu-iphone4/upstream/`.

**Apple firmware is not included or relicensed here.** Do not commit or publish IPSW files, extracted firmware, boot ROMs, or device dumps unless redistribution is expressly authorized by Apple. Project Astra is not affiliated with or endorsed by Apple.
