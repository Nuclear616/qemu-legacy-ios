# QEMU Legacy iOS

An experimental iOS front end and porting effort for emulating legacy Apple hardware with QEMU, initially targeting the **iPhone 4 (n90ap) running iOS 7.1.2**.

> **Status: project scaffold only.** This repository does not yet contain a working iOS app, a validated iPhone 4 firmware boot, or a distributable IPA.

## Goals

- Bring a QEMU-based legacy-device emulator to a native iOS app.
- Start with the iPhone 4 machine target and iOS 7.1.2 guest.
- Provide virtual-device configuration and storage management.
- Investigate supported JIT execution paths on modern host iOS, including iOS 27.0.1.
- Produce a reproducible Xcode build and, eventually, a signed IPA.

## Upstream starting point

The intended engine starting point is [samhenrigold/qemu-ios](https://github.com/samhenrigold/qemu-ios), a QEMU-derived project documenting an `iPhone-4` machine target. Its existing app integration is macOS-oriented, so this project needs a real iOS port rather than simply repackaging the macOS app.

The upstream project is GPL-2.0. Preserve its license, notices, and third-party licenses when importing source. No Apple firmware or copyrighted iOS image is included; users must supply firmware they are legally entitled to use.

## Planned milestones

1. Import upstream QEMU source at a pinned commit, preserving licensing.
2. Create a native iOS app target and user-supplied firmware/disk-image workflow.
3. Compile required QEMU libraries for iOS arm64 and connect them to the app.
4. Validate booting the iPhone 4 machine with a compatible iOS 7.1.2 image.
5. Test host JIT availability on iOS 27.0.1 and provide a supported fallback if unavailable.
6. Automate an Xcode build and package a signed IPA using the user's signing identity.

## Host and guest

The **guest** is the emulated iPhone 4 running iOS 7.1.2. The **host** is the physical device running iOS 27.0.1 and the emulator app. Host JIT support is separate from guest firmware compatibility.

## Requirements (target)

- Physical iPhone/iPad running iOS 27.0.1 (compatibility not yet tested).
- A Mac with a compatible Xcode version to build and sign.
- Appropriate Apple signing identity and provisioning setup.
- Legally obtained guest firmware, when required.

See [ROADMAP.md](ROADMAP.md) and [JIT/signing notes](docs/JIT-AND-SIGNING.md).