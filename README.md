# QEMU Legacy iOS

An experimental iOS front end and porting effort for emulating legacy Apple hardware with QEMU, initially targeting the **iPhone 4 GSM (n90ap) running iOS 7.1.2**.

> **Status: source integrated; iOS app target and IPA build are not complete.** The upstream emulator source is tracked as a pinned Git submodule. This repository does not yet contain a complete Xcode iOS application project or a tested IPA.

## Upstream source

The upstream project [samhenrigold/qemu-ios](https://github.com/samhenrigold/qemu-ios) is included at `vendor/qemu-ios` as a Git submodule, pinned to commit `db230fe8e8e4d297724b2eccdc38bdc21876696a`. It contains the QEMU engine, Apple legacy-device models, the `iPhone-4` machine target, and the upstream iOS embedding bridge in `contrib/ios-app/`.

Clone this repository with its source:

```sh
git clone --recurse-submodules https://github.com/Nuclear616/qemu-legacy-ios.git
```

If you already cloned it:

```sh
git submodule update --init --recursive
```

The iPhone 4 board documentation is also copied to [docs/upstream/iphone-4-n90.md](docs/upstream/iphone-4-n90.md). It documents the A4/S5L8930 n90ap machine and reports upstream validation of iOS 7.1.2 booting. That is upstream's result, not a test performed by this repository.

## Build without owning a Mac

The [Build iOS IPA workflow](.github/workflows/build-ipa.yml) runs on a GitHub-hosted macOS runner. Open **Actions → Build iOS IPA → Run workflow**. It checks out the submodule, invokes Xcode, packages an unsigned IPA, and uploads it as an artifact.

**Current limitation:** the workflow requires an Xcode project and scheme. The repository does not yet have the native iOS app project, so the workflow deliberately stops with a clear error until that target is added. The upstream `contrib/ios-app/` files are an embedding bridge, not a complete standalone Xcode app. The generated IPA is unsigned; it must be signed before normal installation.

## Goals

- Integrate the upstream QEMU engine with a native iOS app.
- Start with the iPhone 4 GSM (n90ap) machine and iOS 7.1.2 guest.
- Provide virtual-device configuration and persistent storage.
- Investigate supported host JIT execution on iOS 27.0.1.
- Produce reproducible GitHub Actions builds and a signed IPA.

## Licensing and firmware

The upstream QEMU-iOS source is GPL-2.0; preserve its license, notices, and third-party licenses. See `vendor/qemu-ios/COPYING` and `vendor/qemu-ios/LICENSE`. No Apple firmware or copyrighted iOS image is included. Users must supply firmware they are legally entitled to use.

## Host vs guest

The **guest** is the emulated iPhone 4 running iOS 7.1.2. The **host** is the physical device running iOS 27.0.1. Host JIT availability is separate from guest firmware compatibility.

See [ROADMAP.md](ROADMAP.md) and [JIT/signing notes](docs/JIT-AND-SIGNING.md).
