# Seventh lore audit — residential approach, narrative economies and playable-role provenance

**Recorded 28 November 2026.** This supplements [Saafiya's character bible](saafiya-unified-notes.md), the [continuity register](continuity-register.md), the [sixth-pass audit](sixth-pass-recovery-2026-11-28.md), and the original [Hero-shooter material](source-hero-shooter/). A seventh sweep found that the **Nov 25 Pineridge residential story** and **its inventory/consequence rules** had largely been reduced to chapter names. This document restores *narrative and design intentions*, clearly separating them from files observed in the **current Godot code**.

**Evidence classes:**
- **[U]** user/director's prior explicit story/game direction (may still be changeable).
- **[G]** fact checked against current Godot repository documentation or source *in this sweep*; does not imply the game was freshly run or playtested.
- **[H]** previous implementation/prototype or old art history; not the present game's canonical story.
- **[P]** assistant/story proposal, not a locked user decision.
- **[O]** open question or alternate treatment. An item can have multiple labels.

## I. Why Saafiya is away from the mall — the missing initial cause and approach

- **[U]** The intended *Pineridge Crisis* approach starts with Saafiya **parking several blocks uphill/away from the mall** because access closer to it is obstructed.
- **[U]** She observes a **long procession of people carrying goods between the mall and nearby residences/streets**. These are disturbances in the wider fictional neighbourhood, not proof every person on the street is a looter or a valid target.
- **[U]** Saafiya moves **downhill** through residential streets and encounters **roughly three houses or house-related episodes** before reaching the mall-side route. This is a sequence of civilian stories as well as action encounters; its emotional logic is a community being disrupted, not a sequence of anonymous rooms to clear.
- **[O]** The narrative purpose of her mall visit may be tied to information about **Fayeem / Mr Fahim**, an earlier lead from **Russian**, or a separate scenario. **Rivermere Mall / Pine Ridge Mall** and **KZN-first 2021 / Copperlane Johannesburg** remain unresolved names/chronologies. Do not use a physically implemented street to claim those plot threads are reconciled.
- **[U/G]** The current playable opening is a residential segment named **Upper Pineridge** leading to **House One (the barricaded house)**, then the existing **mall feeder road**. The sequence is shown in the current code and versioned README; the full intended chain of *three house stories* is not yet implemented.

## II. The three house-story fragments — intended dramatic structure versus implementation

### First house — residents sheltering

- **[U]** A house with **occupants barricaded inside**. The player's first contact includes checking on or speaking to the residents; the house should register as a home with people making choices under pressure, not a disposable encounter backdrop.
- **[G]** The actual \`scenes/house_one.tscn\` / \`scripts/house_one.gd\` currently shows an **exterior, gate, closed shutters and a family voice**. Interacting at the gate yields: **"We're safe inside. Please warn the neighbours."** This advances a chapter objective. **The house has no playable interior**.
- **[G]** The V29 documentation mentions ordinary gardens/fences, a **two-car carport**, street people and a later exit. These are existing *visual/stage components*, not evidence a separately scripted second-house confrontation exists. In earlier director conversation, a two-car open carport was associated with **House Two**; this naming/placement may have evolved in implementation.
- **[O]** Does this first household offer meaningful further assistance or receive a later follow-up? The family voice exists; deeper relationships and the consequence of warning neighbours are not yet written.

### Second house — a street-side incident

- **[U]** A **second residential encounter outdoors** involving residents or people under immediate pressure. A **steel/open carport and two proportionate parked cars** were among the scene-design elements.
- **[O]** It has not been verified as a separate *House Two* scene in current Godot. Some carport/fence elements appear in the implemented House One exterior. Avoid counting one rendered prop twice as two distinct completed chapters.
- **[P/O]** Characters' safety and reactions, which residents Saafiya helps, and whether anyone later recognises her are story opportunities, not established dialogue or guaranteed rescue outcomes.

### Third house — a breached home and family upstairs

- **[U]** A more involved later **residential interior** involves a home already breached by hostile people, with a **family sheltering in an upstairs room**. This contrast between ordinary domestic rooms and frightened inhabitants is more narratively important than the number of opponents.
- **[U/P]** Early outline included **a foyer, living/TV room, corridor, kitchen, back garden access, utility/bathroom space, stairs, an upper landing, two bedrooms and a balcony**. An earlier assistant laid out a possible L-shaped hallway and suggested around five looter characters; **the geometry, roster/count and encounter flow were proposals**, not an approved or implemented level.
- **[O]** Their names, relationships, whether anyone is injured, whether Saafiya can help them, and how those events affect the later mall chapters remain open. Preserve the *civilian story* before designing antagonistic gameplay.
- **[G]** Neither the current README nor the examined \`house_one.gd\` contains a playable third-house interior; **do not claim it has been built or tested**.

## III. Survival, inventory and consequences — director's grounded continuity rules

- **[U]** **Health, ammunition, equipped items and carried possessions persist between scenes.** A chapter transition should not inexplicably reset Saafiya's condition or magically refill supplies. Distinguish a *temporary scene-transition snapshot* from a real save-game slot.
- **[U]** **No arbitrary health packs, ammunition or newly unlocked weapons appearing from defeated characters.** If an ordinary resident offers supplies after being helped, those are **specific, finite objects with an in-world source**. This also means meaningful noncombat interactions can matter.
- **[U]** Use **South African rand** for any money; keep **wallet/pocket inventory, a backpack and the starting car's boot/stash** intelligible. She should not carry an unlimited number of visible large objects.
- **[U]** A possible later **ornate ritual-themed knife with a special narrative/trait significance** was mentioned. Its eventual appearance and effects are **[O]**; it is **not automatically a supernatural weapon** or an action-game loot item that materialises on demand. Sarah's separate ceremonial dagger is *not* automatically the same object.
- **[U/P]** Some ordinary noncombatants have jobs, families, possessions and routines. Consequences of an intervention or delay can become irreversible; that does **not** imply that every protagonist action can save everyone. The intent is meaningful human stakes, not only arbitrary morality points.
- **[U]** Driving may exist but should be **sparse rather than dominating** an on-foot, character-centred story. Keep a physical relationship between the parked car, the neighbourhood and what Saafiya can carry.

### What is demonstrably implemented in the inspected Godot build?

- **[G]** \`scripts/inventory_model.gd\` declares **eight basic carried slots**, **eighteen with an equipped backpack**, and **forty boot-storage slots**; a cash wallet and separate boot cash both use **rand**. It provides inventory data export/import methods.
- **[G]** The project README says the starting car's boot holds the **backpack**, water, torch and jacket, and that progression carries **inventory, cash, equipment, health, rounds and reserve magazines**. The model itself starts with phone and keys in the carried bag.
- **[G]** \`scripts/upper_ridge.gd\` and \`scripts/house_one.gd\` use chapter transitions; \`scripts/house_one.gd\` calls \`ChapterState.store\` at exit, and checks an occupied house gate in the exterior scene.
- **[G]** V30 says arbitrary health, ammunition and automatic weapon rewards on defeat were removed. A few NPCs may leave **finite cash wallets**, which are different from fantasy-style automatic restorative drops.
- **[G]** V29's scene-state transfer is a **SceneTree metadata/snapshot mechanism**, **not a verified durable save file**. No claim of persistence through app restart is supported solely by this.
- **[G]** The inventory UI includes **ten ring slots** and various equipment positions. Their presence in the interface does **not** establish functioning ring bonuses, an equipment economy, or a supernatural magic system.
- **[O]** The README's historical **V28** section says health and supplies were *not yet* carried over, whereas later **V29/V30** sections explicitly implement carryover. This is a **version-history progression**, not a live contradiction to 'resolve' by deleting the earlier paragraph.
- **[G/O]** The boot scene is visually associated in the current README with a **black 1967 Mustang**; other discussions leave the final car model open. The code's rendered car/boot isn't conclusive authority over Saafiya's definitive lifelong vehicle history.

## IV. What kind of protagonist is Saafiya here? The artwork/prototype role ambiguity

- **[H]** Older *Hero Shooter* visual sprite sheets (including \`Saafiya Hero Shooter Sprite Sheet.png\` and \`Saafiya Gothic Sprite Sheet Reference.png\`) label her **"NPC / Temporary Ally"**. This is evidence of one sprite-art/role direction, **not** immutable main-series canon.
- **[H]** The **Pine Ridge at Dawn** standalone playable HTML/Tkinter adaptation explicitly uses **Saafiya as the playable protagonist**, and the newer Godot project is directly centred on her as the player character.
- **[H]** Separately, the original *Hero-shooter* features **C**, whose character artwork has its own 22 November approved canonical reference; do not force all appearances of C/Sophia/Saafiya to refer to a single protagonist simply because of overlapping early asset paths.
- **[O]** She may be a **guest/temporary ally in C's chapter** and playable in **her own**, or those labels may belong to different abandoned scopes. Do not assert a single resolved role across both games without explicit screenplay treatment.
- **[G]** The existing Godot equipment data names the sidearm Beretta 84FS and a left-hand visual slot; prior lore carefully treats *true left-handedness* as undecided despite some left-side poses.
- **[H]** A prior *Saafiya* art pass accepted a sweetheart-neckline/painted 3D face, then made additional rollbacks to approved sprite directions. A model, sprite or NPC role label must be attributed to its **date/version/artifact**, not merged into one final character contract.

## V. An earlier Fayeem setting-detail and art-approval changes

- **[U]** The older Fayeem family-house introduction describes a **modest 1950s mine-worker-era home**, with domestic signs of rushed departure. The period describes the **house's architecture/age**, not the year of the game.
- **[U]** In a specific **22 November eight-panel comic art revision**, the user requested rear garment/necklace changes and later **removed two rear straps and the collar ring**. These are **panel/wardrobe-revision details**, **not** a final prohibition on her wearing a choker, collar or gothic garments throughout the story.
- **[O]** The illustrated eight-panel Copperlane story, later KZN/Pine Ridge start, and earlier Rivermere/Mr Fahim concept still await a single chronology. Neither image timestamps nor an old video-game opening should be treated as definitive chronology.
- **[O]** The *older* Hero-shooter story notes also envision a larger **Russian/Fayeem/Domino** network. The residential houses do **not** automatically connect to those characters just because they occur along the same fictional mall approach.

## VI. Fragments still deliberately unjoined

1. Are the three residential stories a strict main-story sequence, optional moral/empathy branches, or partly alternative levels?
2. If the first family asks Saafiya to warn neighbours, who specifically are the neighbours and does that create further objectives?
3. Is the House Two carport in the current exterior a consolidation of two originally distinct house designs?
4. Whose family is sheltered upstairs in the House Three treatment, and which of the household outcomes can legitimately vary?
5. Will the early playable Godot chapters be rewritten as a flash-forward, kept as-is, or linked to the older Fayeem/Copperlane mystery?
6. Does C's playable prologue overlap Saafiya's path chronologically, and is Saafiya ever a temporary NPC companion within that strand?
7. How should a future persistent save-file system coexist with present *in-session* ChapterState snapshots?

**Boundaries:** This seventh audit **does not change** level scenes, weapon mechanics, original source archives, images, current NPC behaviour, character identity assignments, or previously unapproved story branches. It records user-described creative goals and what existing implementation files actually show, without claiming fresh runtime playtesting.
