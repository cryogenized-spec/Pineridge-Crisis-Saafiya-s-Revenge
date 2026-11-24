# Approved V8 sprite inputs

Place the existing code-rendered PNGs here without rescaling or trimming:

- `walk_atlas.png` — SHA-256 `88d381ae82e9bbf39fd55ebc0a4f46e1dc7b113f7db43ef8871d129affc7d942`
- `run_atlas.png` — SHA-256 `faf8c15252f4431546bca6766dc18041a063e0b150ba6f2cd54e3e2156034f15`

Each is 512 × 512 RGBA, 4 × 4 cells, 128 × 128 per frame, row-major. Center pivot (64,64); artwork faces screen-down. Original walk cycle is 1.12 s; run cycle 0.64 s. No new artwork generated. The runtime loads these files only when both are valid. Missing files retain the previous preview renderer. No dedicated idle/crouch asset yet.

V9 optional layers: `walk_lower_atlas.png`, `walk_upper_atlas.png`, `run_lower_atlas.png`, `run_upper_atlas.png`. Same 512×512 atlas format and center pivot. All four are required for independent look/travel orientation; otherwise the V8 composite remains in use. Exported from the approved V8 mesh with unchanged poses and texture source.
