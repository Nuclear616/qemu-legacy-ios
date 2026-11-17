# iPhone 4 GSM: Wi-Fi and NAND profile

## Wi-Fi

The N90AP board profile wires the soldered Broadcom BCM4329 revision B1
through the S5L8930 IOP SDIO path. Its board identity is `P=N90 V=u`, with
the N90 firmware version and a locally administered synthetic MAC. The card
model is shared with the SDIO transport and Broadcom full-MAC protocol code.

The pinned QEMU build fragment compiles these files under `CONFIG_IPAD1`:

- `hw/arm/ipod_touch_sdio.c`
- `hw/arm/bcm_fullmac.c`
- `hw/arm/mrvl8686.c`

Their headers are vendored under `include/hw/arm` and `include/hw/net`.
Keep the pinned `hw/arm/trace-events` entries when merging into a full QEMU
source tree.

Wi-Fi is enabled by default by the iPhone 4 machine. The board creates a user
network backend named `wifi0` if none was supplied. The equivalent explicit
launch option is:

```sh
-M iPhone-4,wifi=on
```

To provide a backend explicitly, use `-netdev user,id=wifi0`. The emulated
access point is an open network named `qemu-ios`; WPA/WPA2 authentication is
not claimed. Host user-mode networking is NATed and does not bridge the guest
onto the host's physical LAN.

## Storage

The iPhone 4 default NAND ID is Samsung `0x7294D7EC`, the pinned iBoot-817
16 GB part: 2 buses × 2 chip selects, 0x1038 blocks per CE, 128 pages per
block, 8 KiB data pages plus spare bytes. The NAND directory uses
`geometry.json` and one sparse `bus<b>-ce<c>.pages` file per chip select.
An existing NAND image must have matching geometry and chip ID; do not mix it
with the 8 GB `0xB614D5AD` layout.

The NAND emulation is writable file-backed storage. It does not include an
Apple NAND dump, iBoot, IPSW, or a preformatted filesystem image. Guest
firmware assets must be supplied separately.

## Status

The board defaults, Wi-Fi source registration and NAND chip ID are committed.
This is not a claim that the full generic QEMU tree has been built or that
iOS 7.1.2 has booted with Wi-Fi. Verify SDIO enumeration, association, DHCP
and Safari traffic in a built emulator.
