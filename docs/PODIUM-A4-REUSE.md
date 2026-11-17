# Podium A4 engine reuse assessment

## Source repository

- Repository: [Nuclear616/Podium](https://github.com/Nuclear616/Podium)
- Reference branch inspected: `storage-8gib`
- Reference hardware: iPod touch 4 (A4 / S5L8930)
- Target hardware: iPhone 4 GSM (`n90ap`) with an iOS 7.1.2 guest

The repository owner authorized reuse of code from their Podium fork. Preserve original headers, notices and third-party attributions. Authorization from the fork owner does not replace third-party licensing obligations.

## Reusable source areas

The copied `vendor/podium-a4/` tree contains ARMv7 CPU/interpreter files, DBT/JIT components, memory and interrupt primitives, boot helpers, and selected UI components. The source audit also identified `S5L8930XPlatform.swift` as the important A4 hardware wiring reference in the Podium source.

These files are not yet integrated as a coherent build target. The selected UI files are not proof of a working emulator screen or a connected boot pipeline.

## Compatibility

The inspected Podium project documents iPod touch 4 with iOS 6.1.6, not iOS 7.1.2. Shared A4 silicon does not make the boards identical. The iPhone 4 profile needs its own board identity, device-tree values, display/touch configuration, storage expectations and boot arguments.

## Integration strategy

1. Finish a compilable iOS front end independently of the guest engine.
2. Port the Podium CPU/platform dependency closure into a build target, preserving attribution.
3. Add a distinct `n90ap` board profile rather than relabeling the iPod touch 4 profile.
4. Keep JIT optional and retain interpreter fallback. Podium's iOS JIT bridge requires a prepared executable-memory region; its presence does not prove availability on iOS 27.0.1.
5. Validate iOS 7.1.2 boot on this fork before claiming support.

## Current status

A selection of Podium CPU, DBT, memory, boot and UI source files has been copied. The app scaffold added in `ios/` does not yet link those files or start the emulator. No iPhone 4 guest boot has been tested here.
