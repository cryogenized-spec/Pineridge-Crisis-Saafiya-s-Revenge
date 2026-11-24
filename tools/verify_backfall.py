#!/usr/bin/env python3
"""Check the twelve approved alternate 3D collapse atlases."""
from pathlib import Path
from hashlib import sha256
import struct

root=Path(__file__).resolve().parent.parent
hashes = ["2fcb79ca7ce39d9cbb30696bcd26c2ee1c0fc7e1c7fd97b957bc809f99184d16","a0a92b1acc414f42d51abe0791b7e05935eccf58db27e3dd9e73ba8e26982e61","99f97ae28ab322b8c2f62997c8691d1e6d83f19c12f9a0ace2b07b0a5075c6bd","d0bd615105406327de698da393461bc122a2445e7c438f9b84d146ca5f2b1540","55e160753a0638f7a9be62f90e221687171a4dd42e39258a446b96ab7b6d71ed","0999e0f173f555baca6f0d0882760d6c0aa42b4f7e62e6a66a54b9b777c0aca5","4232f0cebfb03419aad5dfb32b161dbc693a02ef9377dfe5d10072468bcca1e0","3c7024fb668fd7bad5bf1b1bb099253c52e13336e64d9ef3b1cc27041087863c","6113906ecfefe0a8b11357c4bda835a60e58a800465df4b4bb38b0f937a2916a","72e9013c56bab3f62c596c3caadf3ca17a8d20e6421fcce4615a7443e56066c5","ea085f321e00a607223c1fec2e4ff65414a23a56e01f2ebd3c2d7a5e2855446c","edde1e6092da62d300c091320d524ca631df059b608a07729e64d904d520534d"]
for i, expected in enumerate(hashes):
    path=root/"assets"/"characters"/"crowd"/f"npc_{i:02d}_down_back.png"
    data=path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"Invalid PNG: {path}")
    if struct.unpack(">II",data[16:24]) != (512,256):
        raise SystemExit(f"Invalid atlas dimensions: {path}")
    if sha256(data).hexdigest() != expected:
        raise SystemExit(f"Unexpected sprite bytes: {path}")
print("Validated 12 alternate 3D collapse atlases.")
