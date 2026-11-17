# Podium A4 engine reuse assessment

## Source repository

- Repository: [Nuclear616/Podium](https://github.com/Nuclear616/Podium)
- Reference branch inspected: `storage-8gib`
- Intended reference device: iPod touch 4 (A4 / S5L8930)
- Our target remains: iPhone 4 GSM (`n90ap`) with an iOS 7.1.2 guest

The repository owner has explicitly authorized reuse of code from their Podium fork in this project. Keep original file headers, notices, and third-party attributions when files are ported. Before importing a file, inspect its header and any applicable license or dependency terms; authorization from the fork owner does not replace third-party licensing obligations.

## What was verified in the source

The inspected Podium source contains a substantial Swift implementation rather than only a thin wrapper:

- `Podium/Emulator/CPU/ARMv7/ARMv7CPU.swift`: ARMv7 interpreter, ARM/Thumb execution paths, CPU state, MMU integration points, and optional DBT attachment.
- `Podium/Emulator/CPU/DBT/DBTEngine.swift`: ARMv7-to-AArch64 dynamic binary translation, translated block dispatch, guest memory fast paths, and invalidation.
- `Podium/Emulator/CPU/DBT/JITMemory.swift`: executable memory allocation abstraction. On iOS it calls the Podium JIT bridge; on macOS it uses `MAP_JIT`.
- `Podium/Emulator/Platform/S5L8930XPlatform.swift`: A4-specific MMIO platform wiring, interrupt controller, timer, power manager, IOP/SWI, CDMA, I2C, audio, display, GPIO, SPI, and touch controller.
- `project.yml`: the existing app is configured for iOS 17.0 or later and uses a Swift bridging header.

These files are evidence that Podium has reusable A4 CPU, DBT, and SoC code. They do not, by themselves, establish that every guest peripheral or boot path required by iOS 7.1.2 is complete.

## Important compatibility finding

The inspected Podium README currently lists iPod touch (4th generation) with iOS 6.1.6 as its supported configuration. It does not claim iOS 7.1.2 support. Therefore, we must not assume that switching the board identifier from the iPod touch 4 to `n90ap` is sufficient to boot iOS 7.1.2.

The A4 is shared, but the boards are not identical. The iPhone 4 target needs its own device-tree values, board identity, display/touch configuration, storage/NOR/NAND expectations, and boot arguments as applicable. Each difference must be grounded in the relevant device-tree/firmware data and tested.

## Recommended integration strategy

1. **Prefer a Podium-derived Swift engine path for the A4 guest** over trying to force the Swift CPU/DBT implementation into QEMU's C CPU internals. Keep QEMU as a separately evaluated alternative until a working integration proves otherwise.
2. Port the minimum coherent set of Podium engine files and their dependencies, not isolated classes. Preserve source attribution and keep the imported code in a clearly identified directory.
3. Extract board-specific configuration so the existing iPod touch 4 profile and new iPhone 4 GSM `n90ap` profile can coexist.
4. Keep the current iOS app and GitHub Actions work separate from guest hardware emulation. First make the app compile, then run firmware-independent CPU/platform tests, then attempt guest boot.
5. Treat JIT as optional. The Podium iOS allocator depends on its JIT bridge and an externally prepared executable-memory region; this is not proof that JIT will be available to our app on iOS 27.0.1. Provide an interpreter fallback and report the actual runtime mode.
6. Validate iOS 7.1.2 boot independently. Do not mark it supported based only on iOS 6.1.6 boot success or shared A4 silicon.

## Current status

This is an architecture and source audit only. No Podium source files have been copied into this repository yet, no app target has been linked to the Podium engine, and no iPhone 4 guest boot has been tested here.
