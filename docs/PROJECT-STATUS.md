# Project status

Last organized against branch `work/ios-qemu-runtime`. This page is a status snapshot, not a claim that untested paths work.

## Target priority

1. **iPhone 4 GSM (N90AP / S5L8930 / A4): active target.**
2. iPhone 2G and 3G: future targets; separate machine/boot validation is required.
3. iPhone 4S (A5): future target; separate A5 machine and boot support is required.

## What exists

| Area | Current state | What that does not prove |
|---|---|---|
| QEMU source | Full engine source is pinned in `vendor/qemu-engine`; iPhone board/peripheral source is in `vendor/qemu-iphone4`. | That the staged N90 machine boots. |
| Engine build | A prior engine workflow successfully compiled an arm64 iOS dylib. | That the current IPA contains and loads the matching dylib. |
| App | SwiftUI app, firmware browser/importer, runtime bridge and status surfaces are present. | That all runtime calls work on-device. |
| Firmware prep | FirmwareKit preparation previously produced an iPhone 4 bundle. | That the bundle boots in this QEMU build. |
| IPA | Workflow can package the app; the current cost-saving edits have not been followed by a new build. | Installation, runtime launch, or guest boot. |
| JIT | StikJIT helper and host capability probe exist. QEMU is configured for TCG interpreter fallback. | QEMU TCG JIT acceleration; Podium JIT is not wired into QEMU. |
| Audio / jailbreak | Not implemented. | Audio playback, jailbreak, or Cydia. |

## Immediate work order

1. Keep the target fixed to N90AP and verify the board identity, machine name, firmware metadata and NAND geometry agree.
2. Audit the runtime ABI end-to-end: exported C symbols, Swift declarations, dylib architecture/platform, linker/embed settings and runtime loading.
3. Audit prepared-bundle validation and the exact boot inputs passed to QEMU.
4. Audit IPA packaging so the correct engine artifact is embedded and checked before packaging.
5. Only after those static checks, spend Actions minutes on one controlled IPA build and test it on the physical iPhone.
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
