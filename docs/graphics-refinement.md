# Graphics and animation refinement

## Gameplay captures

These are fullscreen captures from the Godot 4.4.1 chapter scenes at their gameplay camera zoom. The Barricaded House capture includes the residents' dialogue.

| Chapter | 1280×720 | 1920×1080 |
| --- | --- | --- |
| Upper Pineridge | [Screenshot](screenshots/upper_pineridge-1280x720.png) | [Screenshot](screenshots/upper_pineridge-1920x1080.png) |
| Barricaded House | [Screenshot](screenshots/barricaded_house-1280x720.png) | |
| Mall Approach | [Screenshot](screenshots/mall_approach-1280x720.png) | |

## Art sources and regeneration

Use Python 3 with VTK, NumPy and Pillow. The HUD renderer also needs DejaVu Sans Bold and DejaVu Serif Bold. VTK needs an OpenGL display or an offscreen-capable build. Keep the project root as the working directory.

```sh
python3 tools/render_environment.py
python3 tools/render_crowd_reactions.py
python3 tools/render_hud_details.py
python3 tools/verify_refinement.py
```

- `assets/environment/vehicles` contains 14 orthographic renders for seven period-inspired vehicle slots. East and west are separate camera renders under the same light. Saafiya's car uses a generic burgundy sedan silhouette pending a canonical model. Its 108×43 footprint and boot position are unchanged.
- `assets/environment/architecture` and `assets/environment/roadside` hold modular façades, tiled roofs, shopfronts, retaining walls, gates, fences, parking bays, kerbs, shrubs, bins, a crate and asphalt grain. The sprites use the existing world placements, with overhangs and shadows drawn beyond the ground rectangles. The Mall Approach uses its original smaller parked-car footprint.
- `assets/props/rendered` contains three hand-scale sprites. The slingshot and club follow the NPC's displayed gait direction, with a shared pivot near the hand.
- `assets/characters/reactions` contains twelve crowd atlases from the original wardrobe renderer. Each has seven 10-frame strips of registered 176×176 cells. Six strips end in different resting poses and the stumble returns to the approved stance. At runtime the entry frame blends from the visible gait or active stumble while the actor's world position stays fixed. Press **N** in the action workbench to cycle the six collapse poses.
- `assets/ui/vitality` contains independent full, half and empty heart sprites and the ankh ornament. `assets/ui/nameplates` contains nine independent equipment labels, including CZ 75 P-07. The quick selector continues to use the encounter's unlock flags and ammunition counters.

The approved Saafiya and NPC sprite files are preserved. The original forward and backward collapse images remain available as fallback artwork. The final text bands and map rotation are implemented in Godot Controls.

## Validation

The validation workflow runs the approved-art, audio, legacy collapse and new artwork checks, imports the project with Godot 4.4.1, exercises the existing smoke scenes and exports Linux. The refinement smoke test checks all three chapter HUDs, ammunition fitting, unlocks, heading and collapse transitions.

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tools/refinement_smoke.gd --quit-after 300
```
