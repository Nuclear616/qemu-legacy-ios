# Project Astra

Experimental iOS front end and porting effort targeting the **iPhone 4 GSM (n90ap)** and **iOS 7.1.2** guest.

> **Current state:** The project has a pinned QEMU-iOS engine source, a dedicated iPhone 4 board-source overlay, an iOS app shell, firmware preparation/import paths, and manual IPA packaging workflows. Engine compilation has succeeded in a prior engine workflow, but a complete iOS guest boot has **not** been demonstrated. Treat the iPhone 4 as the only active boot target; other device profiles remain experimental.

## Start here

- [Project status and next milestones](docs/PROJECT-STATUS.md)
- [Repository map](docs/REPOSITORY-MAP.md)
- [Roadmap](ROADMAP.md)
- [Release policy](RELEASE-POLICY.md)
- [Public-repository checklist](PUBLIC-RELEASE-CHECKLIST.md)

## Active target: iPhone 4 GSM

The first target is **iPhone 4 GSM / N90AP / S5L8930 / A4**, using the QEMU machine type:

```sh
-M iPhone-4
```

Do not substitute `-M ipad1`: the shared upstream `ipad1.c` file defines several board profiles, including the iPhone 4. The copied board and peripheral sources are under `vendor/qemu-iphone4/`; the complete QEMU-iOS source is pinned under `vendor/qemu-engine`. See [QEMU source integration](docs/QEMU-SOURCE-INTEGRATION.md), [Wi-Fi and storage](docs/WIFI-AND-STORAGE.md), and [upstream N90 notes](docs/upstream/iphone-4-n90.md).

Selected Podium ARMv7/boot/UI source is kept separately in `vendor/podium-a4/`. It is not a complete boot implementation and its JIT allocator is not connected to QEMU TCG. See [Podium reuse notes](docs/PODIUM-A4-REUSE.md).

## App and firmware flow

The iOS app browses firmware catalogs, downloads IPSWs, verifies the returned checksum, and imports a separately prepared firmware bundle. The prepared bundle contains boot-chain and NAND content that is not supplied by the repository. Import validation checks bundle identity and metadata, and stages replacement before swapping it into the app's data area.

Only the iPhone 4 GSM/A4 path is currently enabled for boot attempts. iPhone 2G, 3G, and 4S/A5 are experimental/informational and must not be represented as supported. Firmware preparation is not proof of a bootable guest.

## Build and workflow policy

- IPA packaging is a **manual** workflow while boot validation is outstanding.
- QEMU engine and StikJIT build workflows should be run deliberately, not as routine side effects of documentation changes.
- The IPA release-publication gate remains disabled until an actual guest boot is tested.
- The app's iOS deployment target is 17.0+; the bundled StikJIT helper has a higher OS requirement. See [JIT on iOS](docs/JIT-ON-IOS.md).
- Never put Apple IPSWs, extracted firmware, boot ROMs, NAND dumps, signing credentials, or private keys in the repository.

Open [Build iOS IPA](https://github.com/Nuclear616/qemu-legacy-ios/actions/workflows/build-ipa.yml) only when a deliberate build is intended and Actions budget is available. A successful workflow or IPA package does not establish that the guest boots.

## Current limitations

- QEMU currently uses its TCG interpreter fallback; the Podium JIT allocator is not integrated with QEMU's translated-code cache.
- Audio output, guest jailbreak/bootstrap, and Cydia installation are not implemented.
- iPhone 2G, 3G, and 4S board/boot support is not complete.
- A prepared firmware bundle and a compiled engine are separate prerequisites; neither alone proves guest boot.

## Credits, licensing, and firmware

See [AUTHORS.md](AUTHORS.md), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), and [LICENSE](LICENSE). Project-authored code is offered under GPLv2; third-party components retain their own licenses. Apple firmware is not included or relicensed. Project Astra is not affiliated with or endorsed by Apple.
