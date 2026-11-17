# JIT on iOS

## Two separate requirements

1. **Host permission:** iOS must allow this app process to create executable JIT memory. This project now includes a `MAP_JIT` mapping probe in `ios/Sources/JITProbe.c`.
2. **QEMU TCG integration:** QEMU's translated-code cache must use Apple's supported JIT memory/write-protection mechanism. The probe alone does not make QEMU's TCG JIT work; that port is still outstanding.

If JIT is unavailable, the eventual runtime must use QEMU's interpreter/soft-MMU fallback where supported. Performance may be much lower.

## iOS 27 note

JIT activation on recent iOS releases is not a normal app permission. SideStore's current guide says iOS 26.6 and iOS 27 support is limited to a small set of apps; QEMU Legacy is not among the listed apps. Therefore this project must not promise that StikDebug, SideStore or AltJIT can activate JIT for this particular build.

For supported apps and OS versions, consult the current [SideStore JIT guide](https://docs.sidestore.io/docs/advanced/jit) and [AltJIT guide](https://faq.altstore.io/altstore-classic/enabling-jit/altjit). Those tools attach a debugger / enable JIT externally; an ordinary app cannot reliably turn on JIT for itself.

## Current implementation status

- [x] Add a user preference to use JIT when available.
- [x] Add a runtime `MAP_JIT` mapping capability probe.
- [ ] Verify the probe on a physical iPhone running iOS 27.0.1 with the exact IPA signing method.
- [ ] Port QEMU TCG code-cache allocation and write-protection transitions to the iOS JIT API.
- [ ] Add interpreter fallback and report the active execution mode.
- [ ] Boot the N90AP guest and benchmark JIT versus interpreter mode.

A successful mapping probe is necessary but not sufficient evidence that QEMU's generated ARM code can execute.