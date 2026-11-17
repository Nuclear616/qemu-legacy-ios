# Roadmap

Items remain incomplete until implemented and tested.

## Repository and licensing

- [x] Create project repository and scaffold.
- [ ] Import upstream source at a pinned commit.
- [ ] Preserve GPL-2.0 text, copyright notices, and third-party licenses.
- [ ] Record upstream commit and local patches.

## iOS application

- [ ] Add an Xcode iOS application target.
- [ ] Add launch screen and emulator status view.
- [ ] Add machine, memory, CPU, and storage configuration.
- [ ] Add safe import/export for user-supplied firmware and disk images.
- [ ] Keep firmware out of the repository.

## QEMU engine

- [ ] Identify minimum QEMU subsystems required by the iPhone 4 machine.
- [ ] Build dependencies for iOS arm64.
- [ ] Resolve macOS-only APIs in upstream app integration.
- [ ] Add a narrow native bridge to the QEMU C API.
- [ ] Add logging and safe shutdown.

## Guest boot validation

- [ ] Confirm exact iPhone 4 machine identifier and board configuration.
- [ ] Verify boot chain and image format.
- [ ] Attempt iOS 7.1.2 guest boot.
- [ ] Record console output and limitations.
- [ ] Test reboot, shutdown, and persistence.

## Host JIT

- [ ] Determine supported JIT path for target iOS and install method.
- [ ] Document signing, pairing, and developer-mode prerequisites.
- [ ] Detect JIT availability at runtime.
- [ ] Provide clear fallback when JIT is unavailable.
- [ ] Verify on physical iOS 27.0.1 hardware.

## Release

- [ ] Add reproducible Xcode build instructions.
- [ ] Add CI on a compatible macOS runner.
- [ ] Record Xcode and SDK versions.
- [ ] Produce and test a signed IPA.
- [ ] Publish checksums and release notes.

## Current validation

| Item | Status |
|---|---|
| Repository scaffold | Complete |
| Upstream source imported | Not yet |
| iOS app target | Not yet |
| iPhone 4 / iOS 7.1.2 boot | Not tested |
| Host JIT on iOS 27.0.1 | Not tested |
| IPA | Not built |