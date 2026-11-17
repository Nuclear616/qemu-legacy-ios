# Roadmap

Items remain incomplete until implemented and tested.

## Source integration

- [x] Copy iPhone 4 GSM/A4 board and peripheral source files into `vendor/qemu-iphone4/`.
- [x] Copy additional S5L8920-era peripheral models and dependency headers.
- [x] Add remaining source files referenced by the pinned `CONFIG_IPAD1` Meson registration (`s5l8950.c`, `cs42l65.c`, `cs35l19.c`, `tsl2561.c`).
- [x] Document the shared `ipad1.c` board profiles and select the GSM iPhone 4 using `-M iPhone-4`.
- [x] Register the BCM4329 SDIO/full-MAC Wi-Fi implementation in the iPhone 4 machine build.
- [x] Set the default NAND chip ID to Samsung 16 GB `0x7294D7EC` and document matching image geometry.
- [x] Copy selected Podium ARMv7, memory, boot and UI source files.
- [x] Remove the upstream QEMU Git submodule link; keep board files as ordinary vendored source.
- [x] Add a staging script for overlaying board source into a separately obtained QEMU tree.
- [ ] Vendor or otherwise reproducibly provision the generic QEMU engine and all required dependencies.
- [ ] Compile the staged QEMU source and resolve missing dependencies/licenses.

## iOS application

- [x] Add a SwiftUI iOS app target definition using XcodeGen.
- [x] Add a firmware file picker and emulator status shell.
- [ ] Connect IPSW parsing and prepared KBoot/NAND/NOR inputs.
- [ ] Link a complete A4 CPU/platform implementation to the app.
- [ ] Connect the Start action to the emulator runtime.
- [ ] Add machine, memory, CPU and storage configuration.
- [ ] Add optional user-supplied jailbreak/bootstrap import for Cydia after guest boot.

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

- [ ] Determine a supported JIT path for iOS 27.0.1.
- [ ] Detect JIT availability at runtime and provide interpreter fallback.
- [ ] Verify on physical hardware.

## Current validation

| Item | Status |
|---|---|
| iPhone 4/A4 board source | Copied; not compiled in this fork |
| Generic QEMU engine | Not vendored; submodule removed |
| Podium ARMv7/DBT source | Selected files copied; not integrated |
| Native iOS app target | SwiftUI/XcodeGen scaffold |
| IPA workflow | Successful unsigned scaffold build |
| iPhone 4 / iOS 7.1.2 boot | Not tested |
| Cydia | Deferred until guest boot and jailbreak/bootstrap |
| Host JIT on iOS 27.0.1 | Not tested |
| Signed IPA | Not built |
