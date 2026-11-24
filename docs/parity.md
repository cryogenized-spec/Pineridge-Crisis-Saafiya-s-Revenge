# Migration contract

Reference: recovered standalone Pine Ridge overhead HTML (1,122,501 bytes). This branch is a first native presentation milestone, not a complete port.

| System | Native status |
| --- | --- |
| 2,320 × 700 street, 640 × 360 logical camera | Implemented at 2× native viewport |
| WASD/arrows, Q run, C crouch, mouse-facing | Implemented |
| Original starting point, building rows, roadside geometry, taxi bay | Recreated |
| Pedestrian positions | Recreated; ambient motion is simplified |
| Out-and-return mission structure | Demonstrated with route markers, not original encounter logic |
| Layered character art | Procedural placeholders; no production sprite atlas yet |
| Visual effects | Presentation-only preview: flash, drifting smoke, sparks, brass-colored debris and muted red ground decals |
| Original inventory, encounters, audio, mission results | Not ported or verified |

The HTML reference is unchanged. Exact gameplay parity cannot be claimed until the original systems have been migrated and compared in playtests. Visual styling can evolve independently from game rules.

## Validation
Godot 4.4.1 is the pinned initial engine version. Run the headless scene smoke test, then visually verify at 1280 × 720 and check collision, camera, gait alignment and effects. The smoke test does not establish graphical quality.
