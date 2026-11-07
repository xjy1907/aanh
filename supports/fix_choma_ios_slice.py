#!/usr/bin/env python3
"""Keep only the iOS arm64 slice of libchoma (drop LC_VERSION_MIN_MACOSX fat slice)."""
from __future__ import annotations

import struct
import sys
from pathlib import Path

FAT_MAGIC = 0xCAFEBABE
FAT_CIGAM = 0xBEBAFECA
MH_MAGIC_64 = 0xFEEDFACF
LC_VERSION_MIN_MACOSX = 0x25
LC_BUILD_VERSION = 0x32
PLATFORM_IOS = 2


def u32(data: bytes, off: int, be: bool) -> int:
    fmt = ">I" if be else "<I"
    return struct.unpack_from(fmt, data, off)[0]


def is_ios_slice(data: bytes, offset: int) -> bool:
    if u32(data, offset, False) != MH_MAGIC_64:
        return False
    ncmds = u32(data, offset + 16, False)
    p = offset + 32
    has_macos = False
    has_ios = False
    for _ in range(ncmds):
        cmd = u32(data, p, False)
        cmdsize = u32(data, p + 4, False)
        if cmdsize < 8:
            return False
        if cmd == LC_VERSION_MIN_MACOSX:
            has_macos = True
        if cmd == LC_BUILD_VERSION or cmd == (LC_BUILD_VERSION | 0x80000000):
            platform = u32(data, p + 8, False)
            if platform == PLATFORM_IOS:
                has_ios = True
        p += cmdsize
    return has_ios and not has_macos


def thin_to_ios(path: Path) -> bool:
    data = path.read_bytes()
    magic = u32(data, 0, True)
    if magic not in (FAT_MAGIC, FAT_CIGAM):
        # Already thin: accept only if iOS
        if is_ios_slice(data, 0):
            print(f"[fix_choma] already thin iOS: {path}")
            return True
        print(f"[fix_choma] ERROR: thin non-iOS mach-o: {path}", file=sys.stderr)
        return False

    nfat = u32(data, 4, True)
    ios_slices = []
    for i in range(nfat):
        base = 8 + i * 20
        cputype = u32(data, base, True)
        offset = u32(data, base + 8, True)
        size = u32(data, base + 12, True)
        if is_ios_slice(data, offset):
            ios_slices.append((cputype, offset, size))
            print(f"[fix_choma] ios slice#{i} cputype=0x{cputype:x} off={offset} size={size}")
        else:
            print(f"[fix_choma] drop slice#{i} cputype=0x{cputype:x} off={offset} size={size}")

    if not ios_slices:
        print(f"[fix_choma] ERROR: no iOS slice in {path}", file=sys.stderr)
        return False
    if len(ios_slices) > 1:
        print(f"[fix_choma] WARN: multiple iOS slices, keeping first")

    _, offset, size = ios_slices[0]
    thin = data[offset : offset + size]
    bak = path.with_suffix(path.suffix + ".fatbak")
    if not bak.exists():
        bak.write_bytes(data)
        print(f"[fix_choma] backup -> {bak}")
    path.write_bytes(thin)
    print(f"[fix_choma] wrote thin iOS dylib ({len(thin)} bytes): {path}")
    return True


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    target = root / "dependencies" / "build" / "libchoma.dylib"
    if len(sys.argv) > 1:
        target = Path(sys.argv[1])
    if not target.is_file():
        print(f"[fix_choma] ERROR: missing {target}", file=sys.stderr)
        return 1
    return 0 if thin_to_ios(target) else 1


if __name__ == "__main__":
    raise SystemExit(main())
