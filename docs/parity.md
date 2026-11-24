# Migration contract

Reference: recovered standalone Pine Ridge overhead HTML (1,122,501 bytes). This branch is a first native presentation milestone, not a complete port.

| System | Native status |
| --- | --- |
| 2,320 × 700 street, 640 × 360 logical camera | Implemented at 2× native viewport |
| WASD/arrows, Q run, C crouch, mouse-facing | Implemented |
| Original starting point, building rows, roadside geometry, taxi bay | Recreated |
| Pedestrian positions | Recreated; ambient motion is simplified |
| Out-and-return mission structure | Demonstrated with route markers, not original encounter logic |
| Layered character art | V8 walk/run atlas playback implemented; original PNGs supplied separately until binary import; fallback for missing assets. Idle/crouch use interim poses. |
| Visual effects | Presentation-only preview: flash, drifting smoke, sparks, brass-colored debris and muted red ground decals |
| Original inventory, encounters, audio, mission results | Not ported or verified |

The HTML reference is unchanged. Exact gameplay parity cannot be claimed until the original systems have been migrated and compared in playtests. Visual styling can evolve independently from game rules.

## Validation
Godot 4.4.1 is the pinned initial engine version. Run the headless scene smoke test, then visually verify at 1280 × 720 and check collision, camera, gait alignment and effects. The smoke test does not establish graphical quality.

## V9 animation and scenery pass

Run cadence: two brief speed troughs per 0.64 s cycle, positive speed throughout, preserving nominal average on unobstructed straight paths. Q and C are toggles as in the HTML reference. Animation phase advances on actual movement only. Layered V9 PNGs enable independent lower-body travel and upper-body look orientation for the unarmed character; fallback retains existing whole-body sprite. Scenery is a fictional non-navigable retail backdrop with roadside planting and southern greenbelt, not a building or security layout. Existing street obstacle arrangement is intentionally revised. Audio and model-specific weapon effects not ported. Visual playtesting remains required.

## V10 general-purpose adult crowd art

Twelve runtime-rendered wardrobe presets, varied body builds, hair, headwear, short/long trousers and footwear. Existing ambient pedestrians use these instead of uniform placeholders. Generic walk, idle and run pose rendering shares the existing motion interface; only ambient walking is wired into the scene. No external sprite downloads or image generation. Narrative-role assignment and combat behaviour are not implemented in this pass. Visual inspection in the running Godot scene remains outstanding.

## V11 crowd review

NPC art gains tonal shading, garment and headwear details. A dedicated F2 workbench renders all twelve wardrobe presets using the same actor renderer as the street and allows gait and direction review at gameplay scale. CI includes a review-scene smoke test. Visual approval and full encounter parity are still outstanding.


## V12 crowd asset import
Runtime support for twelve VTK NPC idle/walk/run sprite sets, with optional separate cosmetic backpack overlay. PNGs and source are supplied as a separate archive; they are not in the Git tree. Automated validation without the archive exercises fallback rendering only. Encounter logic and UI redesign are not included.


## V14 prop and atmosphere pass
The main street gains seeded decorative litter and tyre scenery, plus a separate animated haze node. No new road barricades, tactical cover or visibility rules. The F3 prop gallery contains 14 independent SVG assets including nonfunctional equipment icons and environmental objects. CI checks texture import and gallery startup. Attachment/encounter systems and final UI are not implemented in this pass. Visual review pending.

## V15 animation feedback workbench
F4 opens a presentation-only review scene, using the current NPC renderer and separately rendered prop art. Includes neutral object handling, alert symbols, startled/stumble/down previews, non-graphic colour decals, replaceable audio cues and deterministic state-transition smoke test. Whole-body pose transforms and simple object interpolation are provisional. Weapon-specific action animation, projectile mechanics, damage and encounter AI remain unimplemented. No real-world tactical behaviour is simulated.

## V16 restored arcade gameplay
Combat is now functional in the Godot main scene: role-based NPCs, alert bubbles, melee contact, stylized shots, thrown objects, player and NPC health, damage and down states, pickups, equipment slots, and two encounter phases. Original HTML route layout and overall mission structure were used as references. Not reproduced: real weapon mechanics, advanced tactics, detailed animations, original sounds, taxi sequences, scoring screen, and the exact legacy enemy timing. Noncombat civilians remain separate from combat NPCs; wardrobe appearance does not determine faction. A dedicated smoke test runs on CI. The Web build still relies on fallback graphics until the approved PNG packs are included in the repository.