# Pineridge Crisis — Saafiya's Revenge

## Native Saafiya Gothic HUD (16:9)
The game now uses the 2048×1152 Gothic HUD across Godot story chapters. It fills the four corners of the game viewport. Fullscreen is enabled on desktop; press **F** to toggle it where the browser requires a user gesture. The bronze ammunition panel displays real rounds and reserve magazines without clipping, and the minimap rotates beneath its fixed chevron. Four numbered quick slots show the weapons assigned in Saafiya's inventory. The current arcade ammunition and inventory remain the source of truth. More details: [docs/hud/native-godot.md](docs/hud/native-godot.md).


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

V14 introduced scattered roadside debris, discarded tyres and animated cinematic smoke. The equipment icons are fictional visual representations, not functional models. Road remains navigable; smoke is presentation only. V13 NPC PNGs may replace V12 without code changes. No image generator used.


## Browser preview (GitHub Pages)
The Godot Web preset uses the Compatibility renderer and disables thread support. The separate Godot Web preview workflow builds on the development branch and main, uploads the complete HTML/JS/WASM/PCK bundle, and publishes to Pages only from main. In Settings > Pages > Build and deployment select GitHub Actions. Merge the reviewed development PR into main to enable the first deployment. The approved character PNG atlases are now included in the repository and exported with the project. This preview is the existing exploration and animation workbench, not a completed game.


## Arcade encounters (V16)
The main Godot scene now includes actual fictional action gameplay: seven initial adversary characters (knife, cudgel, brick, slingshot, pistol, runner appearances), a return wave, player and NPC health, onscreen indicators, generic arcade projectiles, close-range actions, limited equipment slots, reload/refill, pickups and reward drops, reactions, defeat states and mission completion. Left mouse button acts; R refills, E collects, 1–3 selects unlocked equipment. Three health hearts and game-over/restart are enabled. Stats appear in the top-right HUD. The original HTML edition remains the behavioural reference, but there is not yet feature-for-feature parity (cutscenes, vehicle events, sound recording, grading and UI refinements remain). The NPC texture packages must be imported separately for detailed visual art. This is an intentionally stylized arcade simulation, not a representation of real weapon behaviour.

## V19 code-rendered down animation
All 12 NPC wardrobes now include a separate 8-frame, 3D VTK-rendered collapse atlas, loaded by the in-game actor and played in encounters. These are authored from the actual character meshes, not merely rotated versions of the standing sprite. The Python art-generation source is in `tools/render_crowd.py` and `tools/render_crowd_down.py` (requires vtk, numpy and Pillow). The sprite integrity check now enforces 57 exact PNGs.

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
Two user-provided clips are included as compressed stereo Vorbis in `assets/audio/shotgun_12ga_shot.ogg` and `assets/audio/shotgun_pump.ogg`. Both recordings remain available to the project. Their content is locked by the audio checksum verifier and checked by CI. Original-source license and attribution should be checked before public commercial distribution.


## V25 approved audio and compact nickel Beretta presentation
Four new user-supplied sounds are now in `assets/audio`: `beretta_reload.ogg`, `cz75_reload.ogg`, and two alternating male-looter death cries. Existing per-equipment reload events automatically play the new sounds; selected scripted male-voiced antagonists alternate the two cries. The Beretta shot playback is raised by +5 dB relative to the other cues, without changing the master volume. Beretta artwork has a reflective nickel/silver finish with warmer grips, and its displayed length and width have been reduced together by 20% (13 → 10.4 display px); the supporting arms remain left-biased. The muzzle flash and smoke are brief, reduced visual effects only. Full sound credits: `assets/audio/CREDITS.md`.

The new Beretta and CZ reload events now use the real imported clip lengths (up to a 4-second visual cap) rather than the old 1-second placeholder timer, and no additional synthetic completion beep plays over the recorded reload.\n

## V25 sound and animation revisions
Weapon shot events now play only supplied recordings. The generated-tone fallback has been removed; missing cues stay silent. Existing Beretta, CZ 75 and AKM recordings have been raised by approximately four decibels (about 60% amplitude increase); NPC pistol cues play at a quieter relative gain. The nickel Beretta overlay is narrower and slightly shorter, keeping the approved character art and left-biased pose. Every character impact creates a unique small local mark instead of the same fixed decal. Existing 12 forward and 12 backward collapse atlases now support six visual timing/settling variations with alternating mirroring and slight motion, without adding texture memory or rendering thousands of particles.


**V25 audio correction:** Two supplied audio files used the Opus codec inside an Ogg container. Godot failed importing these and played old electronic placeholders. Both are now properly encoded Ogg Vorbis. The synthesized fallback is disabled and the CI now rejects import errors. The Beretta recording has the revised +4 dB shot gain.


**V26 additional rendered collapse sprites:** The build now renders 12 more transparent NPC side-fall atlases (96 frames) from the existing VTK procedural models. The renderer runs automatically on CI before Godot import, and its output is packed into the Linux and browser builds alongside the previous forward/backward variants. The new files are generated build assets, not new binary files checked into Git. For offline local development, run `python3 -m pip install vtk numpy Pillow && python3 tools/render_crowd_side.py` once. Encounters choose among six mixed fall variants.


## V27 crowd response and exit simulation
Gunfire now triggers shared character reactions instead of leaving ambient walkers unaffected. Civilians within the fictional sound radius startle, shout one of the game's existing callout captions, and run along the roadway toward a west/east level exit. They remain instantiated and animated beyond camera range until they actually cross the end boundary; escaped characters are then hidden and counted. The ordinary pedestrian wander loop yields control to the escape simulation. Some improvised-prop antagonists flee; others become alerted. The opening encounter includes an additional visible pistol NPC, and armed enemies can respond to nearby audio events using the existing abstract arcade actions. The HUD reports the escaped count. This is non-tactical stage AI and does not model real-world pursuit or cover behaviour.


## V28 — Segment 1: Upper Pineridge (playable)
The game now starts in a separate `Upper Pineridge` residential hill-approach chapter before the existing mall feeder road. The first chapter contains code-drawn, top-down houses, gardens, fences, retaining/contour details, driveways, roadside trees, traffic lines and three properly scaled parked cars (108 × 43 game pixels). Saafiya uses the approved 3D-rendered 2D sprite atlases. Eleven travelling/loitering NPCs share the already implemented gunfire-panic system, and five opening-stage arcade actors give the walk some fictional tension. The existing encounter system is reused without realistic tactical mechanics.

Walk east toward the junction; press E at the glowing destination to load the existing feeder-road chapter. Q toggles run, C crouches, R reloads, click performs the existing arcade action, and Esc restarts the chapter. The main chapter remains playable directly from `scenes/main.tscn`. NPCs react to existing audio events, and stage-one NPC escapes remain in the level simulation beyond camera bounds. Automated CI covers map scale/blocked regions, NPCs, sprite loading, encounter initialization and scene handoff eligibility. No 3D camera orbit is implied: the current figures are 2D atlases rendered from 3D meshes.

Story houses 1–3, their interiors, and the final mall building are subsequent segments, not part of this initial hill-spawn chapter. Health and supplies are not yet carried across the scene transition.


## V29 — Segment 2: Barricaded House (playable)
A second standalone Godot scene (`scenes/house_one.tscn`) follows the Upper Pineridge introductory road. The scene shows a closed residential home and barred shutters, a fenced garden and accessible open gate, an open two-car carport, bins, parcels, tree verges, familiar hillside houses, and an active road. Each sedan measures approximately 108×43 display pixels as in Segment 1. Press E at the gate to speak to the family, then walk through the yard and press E at the porch to visit the front room. The next E interaction at the east junction continues to the existing mall-side road.

Segment 2 includes eight neutral roaming characters, six abstract arcade NPCs near the property and road, the existing gunfire/panic reactions, the approved Saafiya and crowd atlases, and the established audio system. An inventory snapshot preserves health, ammunition and unlocked slots between all three chapters. Headless tests cover yard collision, the gate interaction, the completed objective, the road transition and progress persistence. More detailed exterior interaction and the next two house stories remain separate future segments.


## Inventory and street interaction

- Press **I** to open Saafiya’s equipment and 6×4 carried grid. Drag items to rearrange them, swap compatible outfit pieces, or assign a weapon to one of four clockwise shortcuts. **1** is up, **2** right, **3** down, and **4** left. **Q** still toggles running.
- Press **E** near a downed opponent to open loot. Click to take one item, press **E** again to take what fits and close, or press **Q** to close immediately. Spend one carried magazine per reload. Each spare takes one grid square, and magazines stored in the Mustang don’t count toward carried reserves.
- In Upper Pineridge, follow the lawn around the last house before the junction and look for Mr. Jacobs by the tree. His key opens the ground floor, patio and upstairs hallway. Press **E** to advance the conversations and interact with doors and stairs. Both floors and the second chapter's front room use orthographic renders of 3D interiors.
- If a car is held up, its driver honks, then steps out to gesture after six more seconds. Cars speed away from nearby gunfire. Body hits leave puncture decals, three windscreen hits swap in shattered glass artwork, and stalled traffic emits gray vapor from the hood.

## Campaign animation and taxi arrival

- **C** uses dedicated crouched stance, gait and equipment layers. **X** uses the knife in the equipment slot for a close-range arcade swipe.
- Three player-credited looter takedowns unlock a scripted minibus encounter on the road in Chapter 2. The minibus brakes, leaves skid marks and opens its sliding door for three passengers. The rifle opponent uses dodgeable arcade bursts that can also hit allies.
- Each visible side pane tracks its own crack and shatter state. Lawns are walkable around the rendered buildings and fences. Chapter 3 caches static scenery and uses the same full-size parked-vehicle art as the residential chapters.
- F3 and F4 previews have been removed from the campaign.

## Reusable sprite kit

The campaign uses the redesigned Saafiya sprite throughout, including a new animated collapse. Pistol shots resolve immediately without tracers on either side. Knife opponents use a full-body overhead swing, and ground effects include persistent impact marks, pools and smaller bouncing casings.

Press **K** or **F7** to inspect the cast and overhead equipment in any chapter. The sprite kit includes three rigged body templates, ten adult NPC looks, the Saafiya model and nine equipment props. [Sprite kit, wallpaper, and Blender source](docs/sprite-kit/README.md)

## Story bible and consolidated lore

The project's living story bible is in **[lore/README.md](lore/README.md)**. It consolidates Saafiya/Sophia's family, Cape Town school years, Sarah, Ambrosia, tabletop/LARP and Dark Mountain development, and the existing Fayeem/Russian/Pine Ridge threads. The original Hero-shooter story documents are preserved there as source snapshots. **Unresolved names, geography, dates and competing scenarios remain explicitly open**; prose-only ideas are not implemented game features.
