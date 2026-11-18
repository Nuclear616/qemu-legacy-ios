# Project status

Last organized against branch `work/device-emulation-generator`. This page is a status snapshot, not a claim that untested paths work.

## Target priority

1. **iPhone 4 GSM (N90AP / S5L8930 / A4): active target.**
2. **Original iPhone 2G (M68AP / S5L8900): engine source is present and now enabled in the iOS engine build configuration.** App firmware import/boot integration and a device-specific boot test remain outstanding.
3. iPhone 3G (N82AP) and iPhone 4S (A5): future targets; separate board/machine and boot support is required.

## What exists

| Area | Current state | What that does not prove |
|---|---|---|
| QEMU source | Full engine source is pinned in `vendor/qemu-engine`; iPhone 4 board/peripheral source is in `vendor/qemu-iphone4`; the pinned fork also contains an original-iPhone 2G (`-M iPhone-2G`) S5L8900 machine. | That either machine boots in the current IPA. |
| S5L8900 engine config | The iOS build script now enables `CONFIG_IPOD_TOUCH_1G` alongside `CONFIG_IPAD1`, so the original-iPhone 2G machine is included in the next engine build. | The build has not yet been run; the app importer still only accepts the A4 N90AP bundle. |
| Engine build | A prior engine workflow successfully compiled an arm64 iOS dylib. | That the current IPA contains and loads the matching dylib. |
| App | SwiftUI app, firmware browser/importer, runtime bridge and status surfaces are present. | That all runtime calls work on-device. |
| Firmware prep | FirmwareKit preparation previously produced an iPhone 4 bundle. | That the bundle boots in this QEMU build. |
| IPA | Workflow can package the app; the app now includes a GitHub Releases IPA checker/downloader. | Downloading does not install the IPA; installation and guest boot remain unverified. |
| JIT | StikJIT helper and host capability probe exist. QEMU is configured for TCG interpreter fallback. | QEMU TCG JIT acceleration; Podium JIT is not wired into QEMU. |
| Audio / jailbreak | Not implemented. | Audio playback, jailbreak, or Cydia. |

## Immediate work order

1. Keep the target fixed to N90AP and verify the board identity, machine name, firmware metadata and NAND geometry agree.
2. Audit the runtime ABI end-to-end: exported C symbols, Swift declarations, dylib architecture/platform, linker/embed settings and runtime loading.
3. Audit prepared-bundle validation and the exact boot inputs passed to QEMU.
4. Audit IPA packaging so the correct engine artifact is embedded and checked before packaging.
5. Validate the in-app updater against a published IPA release, then spend Actions minutes on one controlled IPA build and test it on the physical iPhone.
6. Record boot logs and observed behavior before calling the emulator functional.

## Evidence rules

Use these terms precisely:

- **Source integrated:** source files and build registration are present.
- **Engine compiled:** the engine build produced a compatible binary.
- **IPA packaged:** Xcode produced an IPA artifact.
- **Installed/launched:** the IPA installed and the app opened on hardware.
- **Guest booted:** the emulated guest reached a demonstrable boot state.

Do not promote one state to the next without direct evidence. A firmware-preparation success, workflow green check, or IPA download is not guest-boot evidence.

## Cost / workflow guardrails

- Documentation and static source review should not trigger Actions workflows.
- Keep IPA packaging manual while boot is unverified.
- Do not start duplicate workflows or cancel active runs without an explicit request.
- Do not merge this work branch into `main` without explicit approval.
- Prefer one consolidated change and one deliberate build at a time.


## Recent app improvements

- App Updates screen checks GitHub Releases and downloads the unsigned IPA; installation still requires a compatible signing tool.
- Firmware selection persistence stores an IPSW security bookmark rather than duplicating a multi-gigabyte IPSW, and restores the selection on launch.
- The prepared n90ap bundle remains in Application Support and is revalidated/restored on launch.
- Liquid Glass is an optional appearance setting on iOS 26+; older supported OS versions fall back to material styling.
