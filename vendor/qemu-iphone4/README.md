# Vendored QEMU iPhone 4 / A4 machine sources

This directory contains source-file copies from `samhenrigold/qemu-ios` at upstream commit:

`db230fe8e8e4d297724b2eccdc38bdc21876696a`

The iPhone 4 GSM machine is implemented in upstream `hw/arm/ipad1.c` as the `a4_n90` board profile and registered as `iPhone-4`. The same source file also contains the related iPad 1 and iPod touch 4 A4 board profiles. The S5L8930 peripheral models and reused iPod-family devices are copied under their original upstream-relative paths here.

## Contents

- `hw/arm/ipad1.c`: A4 board definitions, including the iPhone 4 GSM `a4_n90` profile, machine registration, boot and device wiring.
- `hw/arm/s5l8930_*.c` and `include/hw/arm/s5l8930.h`: S5L8930 SoC peripheral implementations and declarations.
- `hw/arm/s5l8920_pwm.c`: shared PWM model used by the iPhone 4.
- `hw/arm/ipod_touch_*.c` and matching headers: reused peripheral models (touch, USB, SPI, audio, GPIO, sensors, PMU, timers, and related devices).
- `hw/misc/ios_*.c` and matching headers: baseband and vibration support.
- `hw/arm/guest-*.c`, `hw/arm/ipod-agent.c`, `hw/arm/it_iboot.c`, and headers: guest services, graphics, packaging, and boot helpers used by this QEMU machine.
- `upstream/docs/n90/README.md`: upstream board notes and boot-validation record.
- `upstream/COPYING`, `upstream/LICENSE`: upstream licensing notices.
- `upstream/hw/arm/Kconfig`, `upstream/hw/arm/meson.build`: upstream machine build-registration context.

## Important build note

These are copied hardware/board sources, not a complete standalone QEMU source tree. They include references to QEMU core headers, CPU execution, device infrastructure, and other shared QEMU subsystems. The pinned QEMU source dependency is still needed for those generic components until the full engine is vendored and the build is wired to this copy. The copied board sources are not yet compiled by the iOS app target.

No iPhone firmware, IPSW, NAND image, NOR image, or other Apple firmware payload is included. Supply legally obtained guest firmware separately.

Preserve the upstream GPL and other applicable notices when modifying or redistributing these files. The user's authorization to reuse their Podium fork does not change the separate licensing obligations for QEMU source.
