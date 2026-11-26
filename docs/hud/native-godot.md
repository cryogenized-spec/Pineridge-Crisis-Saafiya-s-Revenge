# Saafiya's Revenge HUD

The ornamental overlay fills the 16:9 logical viewport. The four corner groups, central chapter text, lower dialogue and control hint use anchors derived from the overlay's 2048×1152 coordinates. The desktop build starts fullscreen. The web build can enter fullscreen with **F**.

- Health reads `Encounter.player_hp` and displays RGBA heart sprites. The artwork provides full, half and empty states.
- The minimap draws chapter scenery and obstacles through the transparent compass aperture. The map rotates with Saafiya's heading and the chevron remains stationary.
- The equipment nameplate changes with `Encounter.slot`. The fitted seven-segment readout uses the current rounds, reserve magazines and reload clock.
- The quick selector shows the eight equipment icons across two pages. Its buttons check the encounter's unlock flags. CZ 75 P-07 keeps its game slot, key binding and nameplate.
- Upper Pineridge, the Barricaded House and the Mall Approach share the same story text regions. Inventory remains a separate modal overlay.

See the graphics refinement notes for the gameplay captures and source renderers. [Graphics and animation refinement](../graphics-refinement.md)
