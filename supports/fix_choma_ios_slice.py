#!/usr/bin/env python3
"""Validate / repair libchoma for iOS device apps.

Books is built as arm64. An arm64e-only libchoma will make dyld abort
before UI on iPadOS 15 (black-screen instant exit).

Mach-O constants (do NOT swap these):
  LC_VERSION_MIN_MACOSX   = 0x24
  LC_VERSION_MIN_IPHONEOS = 0x25
  LC_BUILD_VERSION        = 0x32
  PLATFORM_MACOS = 1, PLATFORM_IOS = 2

Keep every arm64 / arm64e slice that is iOS. Drop only true macOS slices.
Require a plain arm64 (cpusubtype 0) slice to remain.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

FAT_MAGIC = 0xCAFEBABE
FAT_CIGAM = 0xBEBAFECA
MH_MAGIC_64 = 0xFEEDFACF
LC_VERSION_MIN_MACOSX = 0x24
LC_VERSION_MIN_IPHONEOS = 0x25
LC_BUILD_VERSION = 0x32
PLATFORM_MACOS = 1
PLATFORM_IOS = 2
CPU_TYPE_ARM64 = 0x0100000C
CPU_SUBTYPE_ARM64_ALL = 0
CPU_SUBTYPE_ARM64E = 2


def u32(data: bytes, off: int, be: bool) -> int:
    return struct.unpack_from(">I" if be else "<I", data, off)[0]


def slice_platforms(data: bytes, offset: int) -> tuple[bool, bool]:
    """Return (has_ios, has_macos) for a thin mach-o at offset."""
    if u32(data, offset, False) != MH_MAGIC_64:
        return False, False
    ncmds = u32(data, offset + 16, False)
    p = offset + 32
    has_macos = False
    has_ios = False
    for _ in range(ncmds):
        cmd = u32(data, p, False)
        cmdsize = u32(data, p + 4, False)
        if cmdsize < 8:
            return False, False
        if cmd == LC_VERSION_MIN_MACOSX:
            has_macos = True
        elif cmd == LC_VERSION_MIN_IPHONEOS:
            has_ios = True
        elif cmd == LC_BUILD_VERSION or cmd == (LC_BUILD_VERSION | 0x80000000):
            platform = u32(data, p + 8, False)
            if platform == PLATFORM_IOS:
                has_ios = True
            elif platform == PLATFORM_MACOS:
                has_macos = True
        p += cmdsize
    return has_ios, has_macos


def is_ios_slice(data: bytes, offset: int) -> bool:
    has_ios, has_macos = slice_platforms(data, offset)
    return has_ios and not has_macos


def cpu_subtype(data: bytes, offset: int) -> int:
    # cpusubtype low 24 bits; ABI64 flag in high bits on some tools
    return u32(data, offset + 8, False) & 0x00FFFFFF


def align_up(value: int, align: int) -> int:
    return (value + align - 1) & ~(align - 1)


def write_fat(slices: list[tuple[int, int, bytes]]) -> bytes:
    """Build a fat mach-o from (cputype, cpusubtype, thin_bytes)."""
    n = len(slices)
    # header 8 + 20*n, then align each slice to 2^14 like Apple tools
    align_pow = 14
    align = 1 << align_pow
    offset = align_up(8 + 20 * n, align)
    parts: list[tuple[int, int, int, bytes]] = []
    for cputype, cpusub, blob in slices:
        parts.append((cputype, cpusub, offset, blob))
        offset = align_up(offset + len(blob), align)
    out = bytearray(offset)
    struct.pack_into(">II", out, 0, FAT_MAGIC, n)
    for i, (cputype, cpusub, off, blob) in enumerate(parts):
        base = 8 + i * 20
        struct.pack_into(">IIIII", out, base, cputype, cpusub, off, len(blob), align_pow)
        out[off : off + len(blob)] = blob
    return bytes(out)


def fix_choma(path: Path) -> bool:
    data = path.read_bytes()
    magic = u32(data, 0, True)

    kept: list[tuple[int, int, bytes, str]] = []
    dropped = 0

    if magic in (FAT_MAGIC, FAT_CIGAM):
        nfat = u32(data, 4, True)
        for i in range(nfat):
            base = 8 + i * 20
            cputype = u32(data, base, True)
            cpusub = u32(data, base + 4, True)
            offset = u32(data, base + 8, True)
            size = u32(data, base + 12, True)
            blob = data[offset : offset + size]
            raw_sub = cpusub & 0x00FFFFFF
            label = f"slice#{i} cputype=0x{cputype:x} cpusub=0x{cpusub:x}"
            if cputype != CPU_TYPE_ARM64:
                print(f"[fix_choma] drop non-arm64 {label}")
                dropped += 1
                continue
            if not is_ios_slice(data, offset):
                has_ios, has_macos = slice_platforms(data, offset)
                print(
                    f"[fix_choma] drop non-iOS {label} "
                    f"(ios={has_ios} macos={has_macos})"
                )
                dropped += 1
                continue
            kind = "arm64e" if raw_sub == CPU_SUBTYPE_ARM64E else "arm64"
            print(f"[fix_choma] keep iOS {kind} {label} size={size}")
            kept.append((cputype, cpusub, blob, kind))
    else:
        # thin
        if u32(data, 0, False) != MH_MAGIC_64:
            print(f"[fix_choma] ERROR: not mach-o: {path}", file=sys.stderr)
            return False
        cputype = u32(data, 4, False)
        cpusub = u32(data, 8, False)
        raw_sub = cpusub & 0x00FFFFFF
        if cputype != CPU_TYPE_ARM64 or not is_ios_slice(data, 0):
            has_ios, has_macos = slice_platforms(data, 0)
            print(
                f"[fix_choma] ERROR: thin non-iOS arm64 mach-o "
                f"(ios={has_ios} macos={has_macos}): {path}",
                file=sys.stderr,
            )
            return False
        kind = "arm64e" if raw_sub == CPU_SUBTYPE_ARM64E else "arm64"
        print(f"[fix_choma] thin iOS {kind} size={len(data)}")
        kept.append((cputype, cpusub, data, kind))

    if not kept:
        print(f"[fix_choma] ERROR: no usable iOS arm64/arm64e slice in {path}", file=sys.stderr)
        return False

    has_arm64 = any(k == "arm64" for *_, k in kept)
    has_arm64e = any(k == "arm64e" for *_, k in kept)
    if not has_arm64:
        print(
            "[fix_choma] ERROR: missing plain arm64 slice "
            "(arm64e-only cannot load into arm64 Books → iOS15 black-screen)",
            file=sys.stderr,
        )
        return False

    # Fat already valid: do not rewrite (alignment noise would churn the binary).
    if magic in (FAT_MAGIC, FAT_CIGAM) and dropped == 0:
        print(
            f"[fix_choma] OK unchanged ({len(data)} bytes, "
            f"arm64={has_arm64} arm64e={has_arm64e}): {path}"
        )
        return True

    # Prefer stable order: arm64 then arm64e
    kept.sort(key=lambda t: 0 if t[3] == "arm64" else 1)

    if len(kept) == 1:
        out = kept[0][2]
    else:
        out = write_fat([(c, s, b) for c, s, b, _ in kept])

    if out == data:
        print(
            f"[fix_choma] OK unchanged ({len(out)} bytes, "
            f"arm64={has_arm64} arm64e={has_arm64e}): {path}"
        )
        return True

    bak = path.with_suffix(path.suffix + ".fatbak")
    if not bak.exists():
        bak.write_bytes(data)
        print(f"[fix_choma] backup -> {bak}")
    path.write_bytes(out)
    print(
        f"[fix_choma] wrote ({len(out)} bytes, "
        f"arm64={has_arm64} arm64e={has_arm64e}): {path}"
    )
    return True


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    target = root / "dependencies" / "build" / "libchoma.dylib"
    if len(sys.argv) > 1:
        target = Path(sys.argv[1])
    if not target.is_file():
        print(f"[fix_choma] ERROR: missing {target}", file=sys.stderr)
        return 1
    return 0 if fix_choma(target) else 1


if __name__ == "__main__":
    raise SystemExit(main())
