#!/usr/bin/env python3
"""Fail the build if the approved Saafiya/NPC sprites are missing or replaced."""
from pathlib import Path
import hashlib, json, struct, sys

ROOT = Path(__file__).resolve().parents[1]
manifest_path = ROOT / "assets/characters/approved-manifest.json"
manifest = json.loads(manifest_path.read_text())['sha256']
assert len(manifest)==45, f"Expected 45 approved PNGs, got {len(manifest)}"
for name, digest in manifest.items():
    path = ROOT / name
    if not path.is_file():
        sys.exit(f"Missing approved character art: {name}")
    contents = path.read_bytes()
    if not contents.startswith(b'\x89PNG\r\n\x1a\n'):
        sys.exit(f"Not PNG: {name}")
    dimensions = struct.unpack('>II', contents[16:24])
    expected = (512, 512) if '/saafiya/' in name else (128, 128) if '/accessories/' in name or name.endswith('_idle.png') else (512, 256)
    if dimensions != expected or contents[25] != 6:
        sys.exit(f"Wrong atlas size or format: {name}: {dimensions}")
    if hashlib.sha256(contents).hexdigest()!=digest:
        sys.exit(f"Approved asset checksum mismatch: {name}")
print(f"Approved artwork verified: {len(manifest)} original sprites, SHA256 and dimensions OK.")