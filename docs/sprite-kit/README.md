# Saafiya’s Revenge sprite kit

[Cast and overhead weapon sheet](cast-and-weapons.jpg) · [1920×1080 wallpaper](wallpaper-1920x1080.jpg) · [Editable Blender kit](source/saafiya-sprite-kit.blend)

[Ready-to-use character sprites](../../assets/characters/sprite_kit) · [Overhead weapon layers](../../assets/weapons/overhead)

[In-engine workbench](workbench.png) · [Settled decals in gameplay](gameplay.png) · [Firing frame](discharge.png)

## In the game

- **K** or **F7** opens the sprite workbench. Choose **Cast** or **Equipment** and use the arrows to change the preview. In Cast, **1–3** switches idle, walk and run for the ten NPCs. In Equipment, **Space** cycles the selected prop and **R** previews servicing it. **Esc** returns to the same chapter.
- **V** or **F8** switches Saafiya between the approved campaign sprite and the alternate model. The choice follows the player through chapter changes during the session.
- Campaign weapon animations are wired to the Beretta, CZ and AKM slots. All nine props are available in the workbench. The pump shotgun model designation remains provisional.

The pistols use separate slide layers, the AKM uses an animated action layer, and the pump shotgun preview animates its fore-end. Brief muzzle sprites and smoke use the shot location. Brass falls and settles at a fixed world point. Contact splashes leave ground marks, and downed characters have an expanding puddle at their resting position. Settled brass, marks and pools stay with the chapter during the run. Restarting that chapter clears its decals.

## Reuse the models and atlases

The Blender file has slim, balanced and broad body template collections, Saafiya’s alternate rig, five male and five female adult presets, and nine overhead props with named layer objects. Hide the clothing, sleeves, trousers, footwear and accessories to work with the bare body. Hair is a separate collection. Saafiya has nine pose actions with keyframes for the ready, recoil, service and return silhouettes.

`tools/sprite_kit/presets.py` defines the reusable body proportions, costume palettes, hairstyles and art-space grip positions. Copy a preset and change those fields to generate matching sprites. Body sprites use 128×128 RGBA cells and a centered pivot. Turn atlases have four columns and two rows, beginning south and turning clockwise in screen space. Walk and run are eight-frame south-facing loops. Saafiya’s split locomotion uses 16 lower-body frames and four upper-body frames in each equipment row. The weapons use 256×96 cells for receiver, moving part and magazine.

To regenerate, use Python 3.10 or later with VTK, NumPy and Pillow, DejaVu fonts and an OpenGL display. The Blender file was built with Blender 4.3.2.

```sh
python3 tools/sprite_kit/generate.py --mesh-dump /tmp/saafiya-sprite-kit.json
blender --background --python tools/sprite_kit/export_blender.py -- /tmp/saafiya-sprite-kit.json "$PWD/docs/sprite-kit/source/saafiya-sprite-kit.blend"
python3 tools/sprite_kit/verify.py
godot --headless --path . --script tools/sprite_kit_smoke.gd --quit-after 300
```
