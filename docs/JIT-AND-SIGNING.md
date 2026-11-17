# Host JIT and signing notes

## Scope

The physical device is the **host** (initial target: iOS 27.0.1). The virtual iPhone 4 running iOS 7.1.2 is the **guest**. Guest firmware and host JIT availability are separate concerns.

## JIT is not an entitlement an app can grant itself

An ordinary iOS app cannot grant itself unrestricted executable-memory/JIT privileges. Whether QEMU can use JIT on a particular host depends on the OS version, signing and installation path, developer configuration, and supported launch/debug mechanism.

Linking a JIT-capable emulator engine does not prove JIT is available. The app should detect the required execution mode and explain limitations instead of crashing or pretending it is enabled.

## Validation plan

1. Build and launch a minimal signed iOS app on the target device.
2. Record exact iOS build, Xcode version, signing method, and installation path.
3. Test the supported JIT workflow for that environment.
4. Add a runtime capability check around JIT-dependent code.
5. If JIT cannot be enabled, test a slower interpreter or another supported execution mode.

## Signing and IPA

A distributable IPA must be built with Xcode and signed using an appropriate Apple signing identity and provisioning profile. GitHub can automate compilation and packaging, but a commit alone cannot create an IPA signed for a specific device.

Never commit certificates, private keys, provisioning secrets, or personal firmware images to this repository.