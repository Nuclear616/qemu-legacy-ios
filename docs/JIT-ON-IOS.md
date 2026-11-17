# JIT on iOS

## Two separate requirements

1. **Host permission:** iOS must allow this app process to create executable JIT memory. This project includes a `MAP_JIT` mapping probe in `ios/Sources/JITProbe.c` and a built-in StikJIT helper/pairing integration branded as Project Astra (the upstream source and license attribution are retained in the vendor notices).
2. **QEMU TCG integration:** QEMU's translated-code cache must use Apple's supported JIT memory/write-protection mechanism. The probe alone does not make QEMU's TCG JIT work; that port is still outstanding.

If JIT is unavailable, the eventual runtime must use QEMU's interpreter/soft-MMU fallback where supported. Performance may be much lower.

## Supported host OS versions

- **Project Astra app:** deployment target iOS 17.0+.
- **Built-in StikJIT helper:** extension deployment target iOS 26.0+. On iOS 26, import a pairing file created for this device.
- **On-device pairing:** iOS 27.0+; pair from Settings → Privacy & Security → Developer Mode using the Project Astra pairing host.
- StikDebug, TrollStore and jailbreak-based JIT remain conditional on their own supported OS versions and signing/install methods.

## iOS 27 note

JIT activation on recent iOS releases is not a normal app permission. SideStore's current guide says iOS 26.6 and iOS 27 support is limited to a small set of apps; Project Astra is not currently listed among the supported apps. Therefore this project must not promise that StikDebug, SideStore or AltJIT can activate JIT for this particular build.

For supported apps and OS versions, consult the current [SideStore JIT guide](https://docs.sidestore.io/docs/advanced/jit) and [AltJIT guide](https://faq.altstore.io/altstore-classic/enabling-jit/altjit). Those tools attach a debugger / enable JIT externally; an ordinary app cannot reliably turn on JIT for itself.

## Current implementation status

- [x] Add a user preference to use JIT when available.
- [x] Add a runtime `MAP_JIT` mapping capability probe.
- [ ] Verify built-in StikJIT attachment and the probe on a physical iPhone running iOS 27.0.1 with the exact IPA signing method.
- [ ] Port QEMU TCG code-cache allocation and write-protection transitions to the iOS JIT API.
- [ ] Add interpreter fallback and report the active execution mode.
- [ ] Boot the N90AP guest and benchmark JIT versus interpreter mode.

A successful mapping probe is necessary but not sufficient evidence that QEMU's generated ARM code can execute.