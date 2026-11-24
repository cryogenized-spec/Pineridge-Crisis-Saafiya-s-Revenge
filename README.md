# Pineridge Crisis — Saafiya's Revenge

## Approved artwork now included in browser and Linux exports
The six original approved V9 Saafiya transparent atlases (including separate upper/lower walking and running layers), all 36 V13 NPC idle/walk/run atlases, and three detachable cosmetic accessory PNGs are committed in `assets/characters/`. This is the real code-rendered VTK art, not re-drawn/quantized replacements. Every push validates all 45 against original SHA256 hashes before building. Clone and run the project normally; no separate sprite-archive installation is needed.

First native Godot 4.4.1 / GDScript presentation prototype, derived from the existing HTML overhead game. This is not yet a full gameplay-equivalent port.

Open `project.godot` in Godot 4.4.1 and press F6/F5 (F5 runs the configured main scene), or use `godot --path .`.

WASD/arrows move, Q runs, C crouches, mouse rotates facing, E interacts with route markers, V previews stylized visual particles, F toggles fullscreen, Esc restarts.

The original browser edition is unchanged. See [migration contract](docs/parity.md) for exact scope and missing systems. Character sprites are procedural placeholders; no production-quality art or compiled export is claimed. GitHub Actions checks script import and scene startup.

## Approved Saafiya gait artwork

The native player renderer now supports the approved V8 transparent walking and running atlases. Copy both original PNGs into `assets/characters/saafiya/` (see that directory's README). When both files are present the character uses the approved art automatically. Without them the earlier procedural preview remains available. Crouch uses a temporary compressed walking pose; a dedicated crouch atlas and neutral idle are still outstanding. Travel-distance-driven playback prevents the gait from advancing against a wall.

V9 adds optional independent upper/lower gait atlases, rhythmic running motion and a landscaped retail-district backdrop. Q/C toggle their movement states. Extract the V9 asset pack into the project root; no new image-generation art was used. The separate upper-body orientation is a visual look state, not a new combat mechanic.

V10 replaces uniform ambient NPC art with twelve code-drawn adult streetwear variants. The same wardrobe renderer supports idle, walk and run poses and requires no additional binary assets. It is a presentation pass; no encounter mechanics were added.

Press **F2** to open the character workbench, which displays all twelve wardrobe presets. Use 1/2/3 for idle/walk/run, arrows to rotate, T for auto-turn, Z for native-scale comparison, Esc to return. V11 adds shaded garment detail and a separate automated review-scene test.

V12: extract the supplied NPC asset pack into the repository root to enable the twelve 3D-rendered crowd looks. The F2 workbench shows these atlases when installed, A toggles a cosmetic accessory. Missing assets retain the older vector renderer.

V14 adds 14 separately imported SVG prop textures (F3 gallery), scattered decorative roadside debris, discarded tyres and animated cinematic smoke. The equipment icons are fictional visual representations, not functional models. Road remains navigable; smoke is presentation only. V13 NPC PNGs may replace V12 without code changes. No image generator used.

V15 adds an F4 animation workbench with neutral object pickup/carry/set-down previews, alert symbols, generic reaction/down states, toggleable subtle decals and replaceable synthesized audio cues. Equipment icons can be inspected independently. The poses are interim whole-body transforms, not newly rigged limb animations; there is no targeting, damage, or combat AI in this pass.

## Browser preview (GitHub Pages)
The Godot Web preset uses the Compatibility renderer and disables thread support. The separate Godot Web preview workflow builds on the development branch and main, uploads the complete HTML/JS/WASM/PCK bundle, and publishes to Pages only from main. In Settings > Pages > Build and deployment select GitHub Actions. Merge the reviewed development PR into main to enable the first deployment. The approved character PNG atlases are now included in the repository and exported with the project. This preview is the existing exploration and animation workbench, not a completed game.


## Arcade encounters (V16)
The main Godot scene now includes actual fictional action gameplay: seven initial adversary characters (knife, cudgel, brick, slingshot, pistol, runner appearances), a return wave, player and NPC health, onscreen indicators, generic arcade projectiles, close-range actions, limited equipment slots, reload/refill, pickups and reward drops, reactions, defeat states and mission completion. Left mouse button acts; R refills, E collects, 1–3 selects unlocked equipment. Three health hearts and game-over/restart are enabled. Stats appear in the top-right HUD. The original HTML edition remains the behavioural reference, but there is not yet feature-for-feature parity (cutscenes, vehicle events, sound recording, grading and UI refinements remain). The NPC texture packages must be imported separately for detailed visual art. This is an intentionally stylized arcade simulation, not a representation of real weapon behaviour.