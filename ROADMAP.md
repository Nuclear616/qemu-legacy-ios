# Roadmap

Items remain incomplete until implemented and tested.

## Source integration and licensing

- [x] Pin the generic upstream QEMU engine checkout.
- [x] Copy the iPhone 4 GSM/A4 board and device-model source files into vendor/qemu-iphone4/.
- [x] Copy iBoot handoff, NAND image/ECC, H2FMI and NOR/SPI source support.
- [x] Add a staging script that overlays the copied board source into the generic QEMU engine.
- [x] Import the upstream iPhone 4 n90 board documentation.
- [x] Record the upstream commit and licensing location.
- [ ] Add a reproducible source build for iOS arm64.
- [ ] Compile the staged QEMU source and resolve any missing dependencies.
- [ ] Audit all required upstream dependencies and licenses.

## iOS application

- [ ] Add a complete Xcode iOS application target.
- [ ] Wire `contrib/ios-app/qemu-ios-entry.c` and `qemu-ios-ui.c` into the app.
- [ ] Add launch screen and emulator status view.
- [ ] Add machine, memory, CPU, and storage configuration.
- [ ] Add safe import/export for user-supplied KBoot, NAND, NOR and firmware assets.
- [ ] Add an optional user-supplied jailbreak/bootstrap import path for Cydia after guest boot.
- [ ] Keep firmware out of the repository.

## GitHub Actions / IPA

- [x] Add a GitHub-hosted macOS workflow skeleton.
- [x] Add manual workflow dispatch and unsigned IPA artifact packaging.
- [ ] Add the native iOS app project and scheme required by the workflow.
- [ ] Add signing/export support with user-provided Apple signing credentials.
- [ ] Verify the artifact installs on the target device.

## Guest boot validation

- [x] Identify the upstream iPhone 4 GSM machine as `-M iPhone-4` / n90ap / S5L8930.
- [x] Record upstream's iOS 7.1.2 boot validation in `docs/upstream/iphone-4-n90.md`.
- [ ] Reproduce the boot using this repository's build.
- [ ] Record console output and known limitations.
- [ ] Test reboot, shutdown, and persistence.

## Host JIT

- [ ] Determine supported JIT path for target iOS and install method.
- [ ] Document signing, pairing, and developer-mode prerequisites.
- [ ] Detect JIT availability at runtime.
- [ ] Provide clear fallback when JIT is unavailable.
- [ ] Verify on physical iOS 27.0.1 hardware.

## Current validation

| Item | Status |
|---|---|
| Generic QEMU engine | Pinned checkout |
| iPhone 4/A4 board and peripheral sources | Copied into vendor/qemu-iphone4; staging script added |
| Bootloader handoff and NAND/NOR loader source | Copied; Apple firmware/data images not included |
| iPhone 4 board docs | Imported |
| Native iOS app target | Not yet present |
| GitHub IPA workflow | Added; waits for Xcode project |
| iPhone 4 / iOS 7.1.2 boot in this fork | Not tested |
| Cydia | Deferred until guest boots and a compatible jailbreak/bootstrap is supplied |
| Host JIT on iOS 27.0.1 | Not tested |
| Installable signed IPA | Not built |
