# Pineridge Crisis — Saafiya's Revenge

## Approved artwork now included in browser and Linux exports
The six original approved V9 Saafiya transparent atlases (including separate upper/lower walking and running layers), all 36 V13 NPC idle/walk/run atlases, and three detachable cosmetic accessory PNGs are committed in `assets/characters/`. This is the real code-rendered VTK art, not re-drawn/quantized replacements. Every push validates all 57 approved PNGs against SHA256 hashes before building. Clone and run the project normally; no separate sprite-archive installation is needed.

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

## V19 code-rendered down animation
All 12 NPC wardrobes now include a separate 8-frame, 3D VTK-rendered collapse atlas, loaded by the in-game actor and displayed through the encounter and F4 review scenes. These are authored from the actual character meshes, not merely rotated versions of the standing sprite. The Python art-generation source is in `tools/render_crowd.py` and `tools/render_crowd_down.py` (requires vtk, numpy and Pillow). The sprite integrity check now enforces 57 exact PNGs.

V20: The arcade impact ground effects now use a pre-rendered, softly shaded stylized stain sprite, with controlled scatter and a strict pooled maximum; this replaces unshaded circular decals without introducing per-impact Node2D allocations. Blood remains a fictional gameplay visual, not a medical or ballistic simulation.


## V21 left-handed pistol and audio event hooks
Approved Saafiya sprites remain unchanged. A small independent Beretta 84FS-inspired cosmetic sprite sits left-of-centre, following the character’s upper-body facing angle, with a restrained transient flash/haze effect. The opening fiction inventory shows 13 rounds plus one preloaded. The second equipment slot is labeled CZ 75 P-07, in keeping with the original HTML source. The fictional travel speed is shortened visually, with segment collision preventing high-speed shots passing through a character between frames.

Dedicated recording hooks are ready for `saafiya_death`, `beretta_84fs_shot`, `cz75_shot`, `akm_reload`, and `crowd_shout` using WAV, OGG or MP3 files in `assets/audio/`. No actual audio recordings were attached or committed yet, so the sound system uses simple tones until replaced. The optional `crowd_shout` is deliberately an unintelligible ambient vocal cue, not authentic isiZulu. Captions `Nangu!`, `Baleka!`, and `Awu…` are taken from the original HTML game's existing dialogue.


## Supplied sound effects (V22)
All six audio recordings provided for the character and weapons are now committed and exported with the game: death cry, Beretta 84FS, CZ 75 P-07, AKM reload, AKM single shot, and ambient crowd shouting. The AKM single-shot recording is the original 1.63-second MP3 byte-for-byte, not a synthesized replacement. Former WAVs were converted to compact Ogg Vorbis and the crowd cue level was raised modestly. The third equipment slot is now labeled AKM and plays `akm_shot.mp3` when used. Both Linux and GitHub Pages builds verify audio checksums and test Godot asset importing. For details see `assets/audio/README.md`.


## V23 character reactions and projectile presentation
The gameplay now removes all bright firearm tracer lines and uses instantaneous abstract arcade interaction collisions against both enemies and ordinary ambient characters. All 13 background pedestrians are registered with the same contact-and-collapse system. A second set of twelve original-mesh, eight-frame VTK collapse animations adds alternate directions, chosen per character. Brief localized contact colour splashes are pooled and capped; ground stains remain capped. The audio files imported in V22 remain checked by CI. This is cinematic stylization, not ballistic or medical simulation.


## V24 visually layered left-handed equipment
The single straight-line arm placeholder was replaced by two independently drawn, shaded upper-limb costume overlays with sleeves, cuffs and hands, placed in front of the original approved Saafiya body sprites. The detachable Beretta visual is carried left-of-centre in front of the model. This is a top-down graphical posing treatment, not an instruction model for weapon handling. No animated projectile beam is rendered.


## V25 shotgun sound assets
Two user-provided clips are included as compressed stereo Vorbis in `assets/audio/shotgun_12ga_shot.ogg` and `assets/audio/shotgun_pump.ogg`. Press **F4** in the game, then **9** to preview both in sequence or **0** to preview the standalone pump cue. Both event IDs are available to a future shotgun character/equipment scene; no shotgun slot or real-world weapon cycle was added to Saafiya's established loadout. Their content is locked by the audio checksum verifier and checked by CI. Original-source license and attribution should be checked before public commercial distribution.


## V25 approved audio and compact nickel Beretta presentation
Four new user-supplied sounds are now in `assets/audio`: `beretta_reload.ogg`, `cz75_reload.ogg`, and two alternating male-looter death cries. Existing per-equipment reload events automatically play the new sounds; selected scripted male-voiced antagonists alternate the two cries. F4 workbench: H/L auditions Beretta/CZ reload, J/K auditions both vocal takes. The Beretta shot playback is raised by +5 dB relative to the other cues, without changing the master volume. Beretta artwork has a reflective nickel/silver finish with warmer grips, and its displayed length and width have been reduced together by 20% (13 → 10.4 display px); the supporting arms remain left-biased. The muzzle flash and smoke are brief, reduced visual effects only. Full sound credits: `assets/audio/CREDITS.md`.

The new Beretta and CZ reload events now use the real imported clip lengths (up to a 4-second visual cap) rather than the old 1-second placeholder timer, and no additional synthetic completion beep plays over the recorded reload.\n