# Roadmap

Items remain incomplete until implemented and tested.

## Source integration and licensing

- [x] Add upstream QEMU-iOS as a pinned source dependency for the generic QEMU engine.
- [x] Copy the iPhone 4 GSM A4 board implementation (a4_n90 / iPhone-4) into vendor/qemu-iphone4.
- [x] Copy S5L8930 peripherals and reused A4-era iPod-family hardware models.
- [x] Copy iPhone 4 board documentation and upstream license notices.
- [ ] Wire the copied board files into a reproducible QEMU source build.
- [ ] Decide whether to vendor the entire generic QEMU engine too; the copied board files alone are not a complete QEMU tree.
- [ ] Audit all required upstream dependencies and licenses.

## iOS application

- [ ] Add a complete Xcode iOS application target.
- [ ] Wire contrib/ios-app/qemu-ios-entry.c and qemu-ios-ui.c into the app.
- [ ] Add launch screen and emulator status view.
- [ ] Add machine, memory, CPU, and storage configuration.
- [ ] Add safe import/export for user-supplied firmware and disk images.
- [ ] Keep firmware out of the repository.

## GitHub Actions / IPA

- [x] Add a GitHub-hosted macOS workflow skeleton.
- [x] Add manual workflow dispatch and unsigned IPA artifact packaging.
- [ ] Add the native iOS app project and scheme required by the workflow.
- [ ] Add signing/export support with user-provided Apple signing credentials.
- [ ] Verify the artifact installs on the target device.

## Guest boot validation

- [x] Identify the upstream iPhone 4 GSM machine as -M iPhone-4 / n90ap / S5L8930.
- [x] Record upstream's iOS 7.1.2 boot validation in docs/upstream/iphone-4-n90.md.
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
| iPhone 4 board source | Copied into vendor/qemu-iphone4 |
| Generic QEMU engine | Pinned submodule dependency |
| Native iOS app target | Not yet present |
| GitHub IPA workflow | Added; waits for Xcode project |
| iPhone 4 / iOS 7.1.2 boot in this fork | Not tested |
| Host JIT on iOS 27.0.1 | Not tested |
| Installable signed IPA | Not built |
