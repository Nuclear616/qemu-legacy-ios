#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 OUTPUT_DIRECTORY" >&2
  echo "Creates a new, blank, sparse 8 GB iPhone 4 GSM NAND store." >&2
  exit 2
fi

OUT="$1"
mkdir -p "$OUT"

python3 - "$OUT" <<'PY'
import json
import os
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
if any(out.iterdir()):
    raise SystemExit(
        f"{out}: directory is not empty; refusing to overwrite an existing NAND store"
    )

geometry = {
    "storage_format": "nand-xor-ff-v2",
    "chip_id": "b614d5ad",
    "buses": 2,
    "ce_per_bus": 2,
    "blocks_per_ce": 4096,
    "pages_per_block": 128,
    "page_bytes": 4096,
    "spare_bytes": 12,
}

# Four 2-GiB NAND dies (two CEs on each of the two H2FMI buses) provide
# 8 GiB of raw data pages. Sparse files start as zeroes; the QEMU NAND model
# XORs those bytes with 0xFF, so untouched pages read as erased NAND.
(out / "geometry.json").write_text(
    json.dumps(geometry, indent=2) + "\n", encoding="utf-8"
)

page_stride = geometry["page_bytes"] + geometry["spare_bytes"]
pages_per_ce = geometry["blocks_per_ce"] * geometry["pages_per_block"]
file_size = pages_per_ce * page_stride

for bus in range(geometry["buses"]):
    for ce in range(geometry["ce_per_bus"]):
        path = out / f"bus{bus}-ce{ce}.pages"
        fd = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        try:
            os.ftruncate(fd, file_size)
        finally:
            os.close(fd)

capacity = (
    geometry["buses"]
    * geometry["ce_per_bus"]
    * pages_per_ce
    * geometry["page_bytes"]
)
print(f"Created blank iPhone 4 GSM NAND store: {out}")
print(f"Raw data-page capacity: {capacity:,} bytes ({capacity / 1024**3:.0f} GiB)")
print(f"Chip ID: 0x{geometry['chip_id']}; CEs: 2 per bus; page size: 4096 + 12 bytes")
print("Files are sparse; disk space is allocated as NAND pages are written.")
PY
