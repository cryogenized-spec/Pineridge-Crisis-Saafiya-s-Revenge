#!/usr/bin/env python3
"""Check the six supplied game audio assets against the approved import bytes."""
from pathlib import Path
from hashlib import sha256

ROOT = Path(__file__).resolve().parent.parent
EXPECTED = {
    "assets/audio/akm_reload.ogg": ("bacd2ba5abf5dc7c654f42552cc1ba7c78fb2bacbe0f1eee47ffeffc95c37ecc", 50645),
    "assets/audio/akm_shot.mp3": ("a1771f4e3dd34c1f9a6f19d933eac4ce4b3c31d774d6d349459415538b1ea273", 41212),
    "assets/audio/beretta_84fs_shot.ogg": ("bd470d22494938d3b563ca3f8c712f4be47fc6f9461e55f9ed55e351e1c4d895", 68860),
    "assets/audio/crowd_shout.ogg": ("819ab2bd87a9e19178d3c273a2eedcd505b488eff61f30f673191f512f14f73a", 53716),
    "assets/audio/cz75_shot.ogg": ("adba3386aaf3593ede53c26e293c7462df4a93d5206f0673e880a4458a0adf57", 65862),
    "assets/audio/saafiya_death.ogg": ("7dea5dfd7cc13d8fd46b6174f1981be0c8b3ed23f59d8f6c05944b996b083dc8", 123606),
}
for name, (digest, size) in EXPECTED.items():
    path = ROOT / name
    if not path.is_file():
        raise SystemExit(f"Missing required audio: {name}")
    contents = path.read_bytes()
    if len(contents) != size or sha256(contents).hexdigest() != digest:
        raise SystemExit(f"Audio checksum mismatch: {name}")
    if name.endswith(".ogg") and not contents.startswith(b"OggS"):
        raise SystemExit(f"Invalid Ogg header: {name}")
print(f"Validated {len(EXPECTED)} supplied audio assets.")
