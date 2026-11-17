# iPhone 4 GSM Wi-Fi and 8 GB NAND

This profile targets the N90AP GSM iPhone 4 (`-M iPhone-4`).

## Wi-Fi

The board instantiates the N90 Broadcom BCM4329 SDIO card profile (`P=N90 V=u`, firmware identity 4.221.38.1). The board's `wifi` machine property defaults to on. The guest sees the emulated open access point `qemu-ios`; the card's Ethernet frames are bridged to QEMU user-mode networking through `wifi0`. When no `wifi0` netdev is supplied, the machine creates a user-mode NAT backend itself (`lan=off`).

This is guest-visible emulated Wi-Fi, not pass-through control of the iPhone host's physical Wi-Fi radio and not a scanner for arbitrary nearby access points. The guest's AppleBCMWLAN stack and matching guest firmware are still required.

The copied card model and shared full-MAC support are registered for `CONFIG_IPAD1` in `vendor/qemu-iphone4/upstream/hw/arm/meson.build`. The staging script also adds that registration to a compatible QEMU tree when it is absent. It stages `ipod_touch_sdio.c`, `bcm_fullmac.c`, `mrvl8686.c`, and the `bcm_fullmac.h` header.

## 8 GB NAND geometry

The N90 profile uses the Samsung NAND ID `0xB614D5AD`: 4096 data bytes + 12 spare bytes per page, 128 pages per block, and 4096 blocks per CE. The 8 GB configuration has two populated CEs on each of the two H2FMI buses:

- 2 buses × 2 CEs × 4096 blocks/CE × 128 pages/block × 4096 data bytes/page
- 8,589,934,592 bytes = **8 GiB raw NAND data capacity**

The N90 board sets the IOP chip-enable mask to `0x03` and patches the KBoot device tree's NAND `#ce` property to 2. The block count and per-chip geometry remain unchanged. The OS-formatted capacity is lower after NAND metadata, bad-block reserve, FTL reserve and partitions.

Create a new blank sparse NAND store (the script refuses a non-empty destination):

```sh
sh scripts/create-iphone4-8gb-nand.sh /path/to/n90-8gb-nand
```

Then pass that directory as the machine's `nand` property:

```sh
qemu-system-arm \
  -M iPhone-4,kboot=/path/to/kboot.bin,nand=/path/to/n90-8gb-nand,wifi=on \
  -serial stdio
```

The machine creates `wifi0` automatically when no `wifi0` netdev is supplied. The NAND files are sparse; their logical size includes 12 spare bytes per page, while the 8 GiB figure above counts guest data bytes only.

The generated NAND is blank and must be initialized by the guest. Supply a compatible N90 KBoot/firmware bundle separately. The QEMU app scaffold still does not launch the emulator runtime, and this 8 GiB configuration has not yet been boot-tested in this fork.
