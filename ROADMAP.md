# Roadmap

Items remain incomplete until implemented and tested.

## Source integration

- [x] Copy iPhone 4 GSM/A4 board and peripheral source files into `vendor/qemu-iphone4/`.
- [x] Copy additional S5L8920-era peripheral models and dependency headers.
- [x] Add remaining source files referenced by the pinned `CONFIG_IPAD1` Meson registration (`s5l8950.c`, `cs42l65.c`, `cs35l19.c`, `tsl2561.c`).
- [x] Document the shared `ipad1.c` board profiles and select the GSM iPhone 4 using `-M iPhone-4`.
- [x] Register the BCM4329 SDIO/full-MAC Wi-Fi implementation in the iPhone 4 machine build.
- [x] Configure N90 as an 8 GiB raw NAND SKU using Samsung `0xB614D5AD`, two CEs per bus, and a matching KBoot `#ce` patch.
- [x] Add a sparse blank 8 GiB NAND store generator with geometry validation and overwrite protection.
- [x] Copy selected Podium ARMv7, memory, boot and UI source files.
- [x] Remove the upstream QEMU Git submodule link; keep board files as ordinary vendored source.
- [x] Add a staging script for overlaying board source into a separately obtained QEMU tree.
- [x] Pin the complete QEMU-iOS engine as `vendor/qemu-engine` at `db230fe8e8e4d297724b2eccdc38bdc21876696a`.
- [ ] Build the QEMU engine for the iOS device SDK with a supported dependency set.
- [ ] Compile the staged N90 source and resolve any overlay/build conflicts.

## iOS application

- [x] Add a SwiftUI iOS app target definition using XcodeGen.
- [x] Add a firmware file picker and emulator status shell.
- [ ] Connect IPSW parsing and prepared KBoot/NAND/NOR inputs.
- [ ] Link the iOS-targeted QEMU engine and app-facing C ABI to the app.
- [ ] Add a Swift/Objective-C bridge for display, touch, lifecycle and storage.
- [ ] Connect the Start action to the emulator runtime.
- [x] Add settings UI for NAND capacity, guest iOS version, experimental/unsigned firmware and post-jailbreak Cydia preference (preferences only; not yet wired to runtime).\n- [ ] Apply selected storage capacity to NAND creation and machine configuration.
- [ ] Implement firmware compatibility checks and experimental unsigned-boot path; UI toggle does not bypass signature checks.\n- [ ] Add optional user-supplied jailbreak/bootstrap import for Cydia after guest boot and implement Cydia package installation.

## GitHub Actions / IPA

- [x] Add macOS workflow with XcodeGen project generation and unsigned IPA packaging.
- [x] Successfully build the current SwiftUI scaffold and upload an unsigned IPA artifact.
- [ ] Verify the artifact installs on a physical device.
- [ ] Add signing/export support using user-provided Apple signing credentials.

## Guest boot validation

- [x] Identify upstream iPhone 4 GSM machine as `-M iPhone-4` / n90ap / S5L8930.
- [ ] Reproduce iOS 7.1.2 boot using this fork.
- [ ] Record console output, reboot, shutdown and persistence behavior.

## Host JIT

- [x] Add a `MAP_JIT` host memory capability probe and a user preference to use JIT when available.
- [ ] Determine a supported JIT activation path for this app on iOS 27.0.1.
- [ ] Port QEMU TCG code-cache allocation/write-protection to Apple's iOS JIT API.
- [ ] Detect active QEMU JIT execution at runtime and provide interpreter fallback.
- [ ] Verify on physical hardware.

## Current validation

| Item | Status |
|---|---|
| iPhone 4/A4 board source | Copied and N90 Wi-Fi/8 GiB NAND settings added; not compiled in this fork |
| BCM4329 Wi-Fi | SDIO/full-MAC models registered; guest networking not validated in this fork |
| 8 GiB NAND | Geometry preset and sparse-store generator added; guest formatting/boot not tested |
| Generic QEMU engine | Pinned as submodule; not built for iOS or linked |
| Podium ARMv7/DBT source | Selected files copied; not integrated |
| Native iOS app target | SwiftUI/XcodeGen scaffold |
| IPA workflow | Successful unsigned scaffold build |
| iPhone 4 / iOS 7.1.2 boot | Not tested |
| Cydia | Deferred until guest boot and jailbreak/bootstrap |
| Host JIT on iOS 27.0.1 | `MAP_JIT` probe added; physical-device result and QEMU TCG integration not tested |
| Signed IPA | Not built |
