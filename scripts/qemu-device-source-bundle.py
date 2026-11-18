#!/usr/bin/env python3
"""Create and safely extract Astra's supplemental QEMU device-source bundle."""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
import zipfile

ALLOWED_ROOTS = ("hw/", "include/", "upstream/")
MANIFEST = "ASTRA-SOURCE-MANIFEST.json"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def safe_name(name: str) -> str:
    path = pathlib.PurePosixPath(name)
    if path.is_absolute() or not path.parts or any(p in ("", ".", "..") for p in path.parts):
        raise ValueError(f"Unsafe archive path: {name!r}")
    if not name.startswith(ALLOWED_ROOTS):
        raise ValueError(f"Unexpected path outside device source roots: {name}")
    return name


def pack(source: pathlib.Path, archive: pathlib.Path) -> None:
    entries: dict[str, str] = {}
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for root in ("hw", "include", "upstream"):
            base = source / root
            if not base.is_dir():
                raise SystemExit(f"Required source directory is missing: {base}")
            for path in sorted(base.rglob("*")):
                if path.is_symlink():
                    raise SystemExit(f"Symlinks are not allowed in source bundle: {path}")
                if path.is_file():
                    name = path.relative_to(source).as_posix()
                    data = path.read_bytes()
                    entries[name] = digest(data)
                    zf.writestr(name, data)
        manifest = json.dumps(
            {"format": 1, "files": entries}, sort_keys=True, indent=2
        ).encode() + b"\n"
        zf.writestr(MANIFEST, manifest)
    print(f"Packaged {len(entries)} device source files into {archive}")


def extract(archive: pathlib.Path, destination: pathlib.Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as zf:
        infos = [i for i in zf.infolist() if not i.is_dir()]
        for info in infos:
            if info.filename == MANIFEST:
                continue
            safe_name(info.filename)
            # Reject Unix symlinks and other non-regular entries.
            mode = (info.external_attr >> 16) & 0xFFFF
            if mode and (mode & 0o170000) not in (0, 0o100000):
                raise SystemExit(f"Non-regular archive entry rejected: {info.filename}")
        try:
            manifest = json.loads(zf.read(MANIFEST))
        except (KeyError, json.JSONDecodeError) as exc:
            raise SystemExit(f"Missing or invalid {MANIFEST}: {exc}")
        if manifest.get("format") != 1 or not isinstance(manifest.get("files"), dict):
            raise SystemExit("Unsupported source bundle manifest format")
        expected = manifest["files"]
        actual = {i.filename for i in infos if i.filename != MANIFEST}
        if actual != set(expected):
            raise SystemExit("Source bundle manifest does not match archive contents")
        for info in infos:
            name = info.filename
            if name == MANIFEST:
                continue
            data = zf.read(info)
            if digest(data) != expected[name]:
                raise SystemExit(f"SHA-256 mismatch in source bundle: {name}")
            target = destination.joinpath(*pathlib.PurePosixPath(name).parts)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    required = (
        "hw/arm/ipad1.c",
        "hw/arm/s5l8930_display.c",
        "include/hw/arm/ipod_touch_sdio.h",
        "include/hw/net/bcm_fullmac.h",
        "upstream/hw/arm/trace-events",
    )
    missing = [name for name in required if not (destination / name).is_file()]
    if missing:
        raise SystemExit("Source bundle is incomplete; missing: " + ", ".join(missing))
    print(f"Verified and extracted {len(expected)} device source files into {destination}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("pack", "extract"))
    parser.add_argument("source_or_archive", type=pathlib.Path)
    parser.add_argument("archive_or_destination", type=pathlib.Path)
    args = parser.parse_args()
    if args.mode == "pack":
        pack(args.source_or_archive, args.archive_or_destination)
    else:
        extract(args.source_or_archive, args.archive_or_destination)


if __name__ == "__main__":
    main()
