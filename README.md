# QEMU Legacy iOS

An experimental iOS front end and porting effort for emulating legacy Apple hardware with QEMU, initially targeting the **iPhone 4 GSM (n90ap) running iOS 7.1.2**.

> **Status: iPhone 4/A4 board sources copied; iOS app target and IPA build are not complete.** This repository does not yet contain a complete Xcode iOS application project or a tested IPA.

## iPhone 4 emulation source

The iPhone 4 GSM board implementation and its Apple-specific hardware models have been copied into vendor/qemu-iphone4/. The main board is QEMU's hw/arm/ipad1.c, which defines the a4_n90 profile and registers the iPhone-4 machine. The copied source set includes the S5L8930 peripherals, reused A4-era iPod touch hardware models, baseband/vibrator models, guest helpers, board documentation, and upstream licensing notices.

The copied files are pinned to upstream QEMU-iOS commit db230fe8e8e4d297724b2eccdc38bdc21876696a. See the vendored source manifest at vendor/qemu-iphone4/README.md.

**Important:** this is a copy of the iPhone 4 board/hardware source, not a copy of the entire QEMU engine. Generic QEMU CPU, device, memory, and build infrastructure is still provided by the pinned upstream source dependency below. The copied board sources have not yet been wired into a successful standalone build.

## Remaining upstream QEMU engine

The upstream project samhenrigold/qemu-ios remains at vendor/qemu-ios as a pinned Git submodule, commit db230fe8e8e4d297724b2eccdc38bdc21876696a. It supplies the generic QEMU engine and build infrastructure while the iPhone 4-specific hardware sources are kept as ordinary copied files in this repository.

Clone this repository with its engine dependency:

```sh
git clone --recurse-submodules https://github.com/Nuclear616/qemu-legacy-ios.git
```

If you already cloned it:

```sh
git submodule update --init --recursive
```

The upstream iPhone 4 board documentation is also copied to docs/upstream/iphone-4-n90.md. It records upstream validation of iOS 7.1.2 booting; that is upstream's result, not a test performed by this repository.

## Build without owning a Mac

The Build iOS IPA workflow runs on a GitHub-hosted macOS runner. Open **Actions → Build iOS IPA → Run workflow**. It checks out the engine dependency, invokes Xcode, packages an unsigned IPA, and uploads it as an artifact.

**Current limitation:** the workflow requires an Xcode project and scheme. The repository does not yet have the native iOS app project, so the workflow deliberately stops with a clear error until that target is added. The upstream contrib/ios-app/ files are an embedding bridge, not a complete standalone Xcode app. The generated IPA is unsigned; it must be signed before normal installation.

## Goals

- Integrate the QEMU engine and copied iPhone 4 board sources with a native iOS app.
- Start with the iPhone 4 GSM (n90ap) machine and iOS 7.1.2 guest.
- Provide virtual-device configuration and persistent storage.
- Investigate supported host JIT execution on iOS 27.0.1.
- Produce reproducible GitHub Actions builds and a signed IPA.

## Licensing and firmware

The upstream QEMU-iOS source is GPL-2.0; preserve its license, notices, and third-party licenses. The copied notices are in vendor/qemu-iphone4/upstream/; the engine dependency also retains vendor/qemu-ios/COPYING and vendor/qemu-ios/LICENSE. No Apple firmware or copyrighted iOS image is included. Users must supply firmware they are legally entitled to use.

## Host vs guest

The **guest** is the emulated iPhone 4 running iOS 7.1.2. The **host** is the physical device running iOS 27.0.1. Host JIT availability is separate from guest firmware compatibility.

See ROADMAP.md and docs/JIT-AND-SIGNING.md.
