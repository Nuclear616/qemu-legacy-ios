# Podium A4 reference integration

Project Astra vendors the exact `sasobhabha/Podium` fork at the
`storage-8gib` branch as a pinned Git submodule in `vendor/podium-a4`.
The submodule is also the source of the Podium JIT allocator compiled by the
iOS app target. Its other emulator sources are retained as an engineering
reference; they are **not** compiled into, or substituted for, Astra's QEMU
runtime.

## What is being ported into QEMU

| Podium reference | Astra/QEMU integration point |
| --- | --- |
| `EmulatorCore` boot phases | QEMU readiness and guest-display state in `QEMURuntime` |
| `EmulationSession` lifecycle and persistent storage | `qemu_ios_main`, QEMU's one-VM-per-process lifecycle, and NAND/NOR overlays |
| `S5L8930XPlatform` A4 register behavior | Existing `hw/arm/s5l8930_*` devices in the pinned QEMU-iOS tree |
| `DisplayScanout` DART/display layer handling | QEMU A4 display devices and `contrib/ios-app/qemu-ios-ui.c` frame bridge |
| Podium's boot diagnostics | Targeted QEMU firmware, runtime-readiness, display, and storage tests |

Podium implements its own ARMv7 CPU, memory bus, and A4 peripheral stack.
Copying those implementations into QEMU would create a competing machine
model, so the A4 behavior is used as a reference for QEMU device fixes rather
than linked as a second emulator.

## Boot-state rule

A loaded dylib is not a running VM, and a running QEMU main loop is not proof
that iOS reached the lock screen. Astra now waits for QEMU's exported
`qemu_ios_ui_ready()` signal before reporting VM initialization, then waits
for a lit guest frame before reporting guest display activity. Neither state
claims that the guest OS has completed booting.

## Storage rule

Re-importing a prepared firmware bundle must not remove an existing bundle
that may contain a user's persistent NAND/NOR overlay. New imports are copied
to a staging directory, validated, and moved into a fresh destination.

## Audio

Podium's `NullAudioOutput` intentionally discards samples and is not an audio
implementation to port. Astra should keep the QEMU A4 I2S and codec devices and
connect QEMU's audio sample path to a native iOS output backend (AudioUnit or
AVAudioEngine). Microphone input is a separate follow-up.

## Validation still required

- Build the iOS ARM64 QEMU dylib and IPA.
- Verify the QEMU readiness symbol is present and callable on-device.
- Boot a supported iPhone 4 firmware bundle and capture the first lit guest
  frame and QEMU logs.
- Confirm NAND/NOR overlays survive app restarts and repeated firmware imports.
- Verify audio output on a physical iOS device.

The submodule import and source-level state/storage changes do not themselves
prove that any guest firmware boots.
