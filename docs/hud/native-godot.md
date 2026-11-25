# Pineridge Crisis — Saafiya's Revenge native HUD integration

This **Godot 4.4.1** patch targets `cryogenized-spec/Pineridge-Crisis-Saafiya-s-Revenge`, **not** Hero-shooter.

- The full 2048×1152 RGBA overlay anchors to the **exact four corners** of the Godot 16:9 game viewport (1280×720 logical) with zero margins. Desktop opens fullscreen; web fullscreen requires a user gesture (F).
- The top-right compass centre is transparent; a native mini-map shows actual scene road/building/obstacle data, rotated around the avatar. The chevron always points up.
- Hearts use `Encounter.player_hp` and ammunition directly reads `Encounter.rounds`, `spares`, `slot` and `reload_clock`. No counters or weapon thumbnails are baked into the artwork.
- The right bronze plate contains a proportional, custom seven-segment digital readout with dynamic digit fitting. It never overlaps the ornamental slashes. The adjacent left plate labels the selected weapon.
- The bottom-left selector cycles two pages of the eight supplied PNG icons. Only equipment wired to and unlocked by the existing arcade encounter can be selected. Beretta 84FS maps to slot 0; AKM to slot 2. Other new icons remain visibly locked because those weapons are not implemented in this repository's existing 3-item KIT. Existing CZ 75 P-07 is preserved by its pre-existing 1–3 controls (native KIT slot 1).
- The user's existing combat, NPC, inventory, sound and story scenes are preserved.

Godot scripts: `scripts/saafiya_hud.gd`, `scripts/saafiya_minimap.gd`, `scripts/saafiya_ammo_display.gd`. UI assets: `assets/ui/saafiya_hud_overlay.png` plus eight transparent PNGs under `assets/ui/icons/`.

The web version uses the project's existing Godot Pages workflow. Check GitHub Actions deployment status before asserting that the new link is live.
