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
