# Pineridge Crisis — Saafiya's Revenge

First native Godot 4.4.1 / GDScript presentation prototype, derived from the existing HTML overhead game. This is not yet a full gameplay-equivalent port.

Open `project.godot` in Godot 4.4.1 and press F6/F5 (F5 runs the configured main scene), or use `godot --path .`.

WASD/arrows move, Q runs, C crouches, mouse rotates facing, E interacts with route markers, V previews stylized visual particles, F toggles fullscreen, Esc restarts.

The original browser edition is unchanged. See [migration contract](docs/parity.md) for exact scope and missing systems. Character sprites are procedural placeholders; no production-quality art or compiled export is claimed. GitHub Actions checks script import and scene startup.

## Approved Saafiya gait artwork

The native player renderer now supports the approved V8 transparent walking and running atlases. Copy both original PNGs into `assets/characters/saafiya/` (see that directory's README). When both files are present the character uses the approved art automatically. Without them the earlier procedural preview remains available. Crouch uses a temporary compressed walking pose; a dedicated crouch atlas and neutral idle are still outstanding. Travel-distance-driven playback prevents the gait from advancing against a wall.
