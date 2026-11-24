#!/usr/bin/env python3
"""Validate the generated sideways-collapse atlases before Godot import."""
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]/"assets/characters/crowd"
for idx in range(12):
    filename=root/f"npc_{idx:02d}_down_side.png"
    assert filename.is_file(),f"Missing {filename}"
    atlas=Image.open(filename).convert("RGBA")
    assert atlas.size==(512,256),f"Wrong size: {filename}"
    for frame in range(8):
        x=(frame%4)*128;y=(frame//4)*128
        alpha=atlas.crop((x,y,x+128,y+128)).getchannel("A")
        box=alpha.getbbox()
        assert box and box[0]>0 and box[1]>0 and box[2]<128 and box[3]<128,(filename,frame,box)
print("Validated 12 sideways fall atlases, 96 nonempty/unclipped frames.")
