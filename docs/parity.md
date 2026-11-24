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

## V18 verified character artwork publication
All 45 approved V9 Saafiya and V13 NPC/accessory PNGs are committed as their original exact bytes. The PNG integrity manifest and mandatory build checker validate their original SHA256 hashes, sizes and RGBA format before both native and browser builds. Older passages saying the textures are supplied separately are superseded by this section. Actual device performance and detailed animation transitions still require visual review.

## V19 NPC collapse rendering
All 12 NPC appearances now have eight-frame pre-rendered three-dimensional fall/down animations, created from the same VTK models as the other NPC art and verified by the main build. The encounter renderer switches from moving sprites into the animation and keeps the final pose. Original PNG and source are committed. The stylized ground-colour effects remain non-graphic and injury states are game abstractions.

## V21 visual/equipment and dialogue parity
A separate Beretta-inspired sprite and effects layer tracks Saafiya's facing angle, biased to the left; movement atlases remain untouched. The other equipment slots retain their existing generic artwork. Event-specific audio filenames for Beretta, CZ 75, AK-pattern reload, Saafiya's death cry and generic crowd shouting are mapped but await supplied clips. Legacy HTML callout captions have been restored. Shot velocities are fictional visual gameplay values rather than real-world weapon performance.


## V23 art and animation
Twelve backward-fall VTK sprite atlases supplement the original twelve forward/down atlases (8 frames each). Alternate fall direction is chosen on impact. Ambient pedestrians now respond to the same generic arcade hit interactions. Firearm tracer and line visuals are gone; thrown objects remain small unlit sprites. A capped contact-colour particle effect supplements stains. All twelve new atlases are checksum-tested in native and Web workflows.

The F4 character workbench can review both 3D collapse atlases: press N to switch front/back orientation, 8 to replay the down animation, and Up/Down to change the model. The scripted workbench smoke test checks that the alternate texture loads.


## V25 audio and pistol visual review
New Beretta and CZ reload recordings replace synthesized placeholders, and two distinct male-looter death-voice takes are available for explicitly cast male-voiced NPCs. Both import integrity and audio event presence are exercised by CI; F4 also supports listening tests. Beretta artwork has been recoloured as polished nickel with walnut-toned grips and reduced in 2D display scale by 20%; muzzle flash and haze are smaller/shorter. The existing gameplay and other weapon visuals are otherwise unchanged. Actual perceived mix levels and browser effects still need a live ear/visual check.

Reload timing follows the length of the chosen audio clip when available; completed reload playback no longer adds a placeholder tone. This is presentation timing only, not mechanical weapon simulation.\n