# iPhone 4 GSM: Wi-Fi and 8 GB NAND

## Wi-Fi

The N90AP board profile models the soldered Broadcom BCM4329 revision B1
through the S5L8930 IOP SDIO path. Its board identity is `P=N90 V=u`, with
the N90 firmware identity and a locally administered synthetic MAC.

The `CONFIG_IPAD1` build registration includes the shared card and full-MAC
models:

- `hw/arm/ipod_touch_sdio.c`
- `hw/arm/bcm_fullmac.c`
- `hw/arm/mrvl8686.c`

Their headers are vendored under `include/hw/arm` and `include/hw/net`.
The pinned `hw/arm/trace-events` entry `ipod_touch_sdio_log` must be present
in the full QEMU source tree. The staging script adds the SDIO/full-MAC Meson
registration for `CONFIG_IPAD1` if it is missing.

Wi-Fi is enabled by default by the iPhone 4 machine. When no `wifi0` netdev
exists, the board creates a QEMU user-mode NAT backend named `wifi0`. The
guest sees an emulated open access point named `qemu-ios`; this is not
pass-through access to the host's physical Wi-Fi radio or arbitrary nearby
networks. WPA/WPA2 is not claimed. The equivalent explicit machine option is:

```sh
-M iPhone-4,wifi=on
```

## 8 GB NAND

The N90 8 GB profile uses Hynix NAND ID `0xB614D5AD`: 4096 data bytes and
128 physical spare bytes per page, 128 pages per block, and 4096 blocks per CE. The
profile exposes two populated chip enables on each of the two H2FMI buses:

```
2 buses × 2 CEs × 4096 blocks/CE × 128 pages/block × 4096 data bytes/page
= 8,589,934,592 bytes = 8 GiB raw NAND data capacity
```

Four 2 GiB dies provide the raw data-page capacity. Each sparse NAND record
stores the full 4096-byte data area and 128-byte physical spare area; the IOP
metadata interface consumes the first 10 spare bytes. The N90 board sets IOP
`nand-ce-mask=0x03` and patches the KBoot NAND node's `#ce` property to 2.
The per-die block count and page geometry stay unchanged. iOS-usable capacity
is lower after bad-block reserve, FTL reserve, metadata and partitions.

Create a new blank sparse NAND store (the script refuses a non-empty target
directory):

```sh
sh scripts/create-iphone4-8gb-nand.sh /path/to/n90-8gb-nand
```

Pass it to the machine with the N90 KBoot bundle:

```sh
qemu-system-arm \
  -M iPhone-4,kboot=/path/to/kboot.bin,nand=/path/to/n90-8gb-nand,wifi=on \
  -serial stdio
```

The NAND store contains blank flash and must be initialized by the guest.
It does not include Apple firmware, iBoot, a NAND dump or a preformatted
filesystem. Supply a compatible N90 KBoot/firmware bundle separately.

## Validation status

These changes configure the QEMU board sources and provide an 8 GiB raw NAND
store generator. The complete generic QEMU engine is not included in this
repository, the iOS app scaffold does not yet launch QEMU, and this exact 8 GiB
profile has not been built or boot-tested in this fork. A successful SwiftUI
IPA build does not validate the C board models.
