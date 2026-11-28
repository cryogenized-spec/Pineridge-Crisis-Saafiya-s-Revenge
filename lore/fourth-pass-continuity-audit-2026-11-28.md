# Fourth-pass lore audit — family objects, design lineage, chronology and consequences

**28 November 2026. Working archival supplement; no retcons.** This sweep reviews retrievable Nov 20–28 conversations, prior *Hero-shooter* source material, relevant Library art/document descriptions and the current *Pineridge Crisis — Saafiya's Revenge* lore. It is not an assertion that every past conversation can be recovered.

Status tags: **[D]** director-stated direction or request; **[P]** tentative concept; **[L]** previously recorded legacy story direction; **[V]** visual/art or technical prototype detail only, *not automatically story canon*; **[I]** assistant inference, not adopted canon; **[O]** unresolved; **[H]** personal recollection of historical social circumstances, not a fictional character's biography.

This file is deliberately additive to [the unified Saafiya notes](saafiya-unified-notes.md), [Sarah and Ambrosia](sarah-ambrosia-dark-mountain.md), [Farsha](farsha-character-fragments.md), the [second](recovered-fragments-2026-11-28.md) and [third](third-pass-fragments-2026-11-28.md) recovery passes, and [the continuity register](continuity-register.md).

## 1. Heather's identity and a previously unrecorded family-object lineage

- **[D/P] Heather's appearance**: adventurous in temperament, with suggested light **steel-blue or green eyes** and naturally straighter hair styled in a period-conscious **1960s/1970s fashion**. Her ancestry was explored as including white forebears, alongside her already established Afrikaans-speaking Cape Flats background. The exact genealogy, hair shade and eye colour are **not final**. Do not imply these visual traits dictate her beliefs or personality.
- **[D/P] Heather became a police officer**, possibly involved with dog/K9 work, in the earlier family backstory. The precise career dates, duties, later occupation and relationship to the relocation remain **[O]**.
- **[D] The direct father–daughter relationship matters**: Saafiya is intended to be **Faisal/Farrell's biological daughter**, not a character whose real parentage is revealed to be somebody else purely for a twist.
- **[D/P — CORRECTED 28 NOV] A separate family revolver**: The original 25 November director discussion assigns the proposed inexpensive **Rossi .38 Special to Heather herself**, Saafiya's **mother**. The earlier attribution to Heather's mother / Saafiya's grandmother was an incorrect summary. Saafiya's ownership or use of the Rossi has never been established. See [fifth-pass recovery](fifth-pass-recovery-and-corrections-2026-11-28.md).
- **[L] Saafiya's paternal heirloom remains distinct**: the ornate, engraved nickel/chrome-finished **Beretta 84FS Cheetah, .380 ACP** comes from **Faisal/Farrell**, with three spare magazines in the older story bible. Heather's Rossi, Saafiya's separately specified custom Smith & Wesson Model 640 as depicted in the poolside storyboard, and the father's Beretta are **three separately described strands** and should not be merged without an explicit decision. The poolside prop was depicted as a different revolver model.
- **[O]** Saafiya's dominant hand was floated as **possibly left-handed** ("just a thought" in an older discussion). Several game-art prototypes adopt a left-biased/left-hand equipment pose, but a technical pose **does not alone settle her innate handedness**. A separate poolside image depicts the phone in her left and revolver in her right; that visual variant is not evidence either way.
- **[D/P]** The Renault-5 car journey to Aunt Isadora, Heather's "follow your heart" advice, three bags, original Sandra cassette, Princeton cigarette and glass-ball metaphor were recovered in the second pass. Preserve maternal agency and a complicated but caring relationship. **The roughly two-hour duration still conflicts with an unbroken KZN-to-Cape-Town journey**.

## 2. Art development history — do not mistake one iteration for final biography

The older **Hero-shooter** repository has multiple Saafiya/Sophia renderer and sprite iterations. These are technical/artistic evidence of development choices, not a licence to rewrite her face or age whenever a new atlas appears.

- **[D/V]** The director preferred a *young-looking* heroine over a rejected version that looked substantially older (described as forties/fifties), with corrected complexion, hair shape and more suitable gothic clothing. Earlier visual corrections included **clearer irises/catchlights, fuller dark lips positioned more naturally** and more convincing walking animation. The approved direction was not "older, stern and generic".
- **[D/V]** A **PS1/Lara Croft or Ape Escape-like facial treatment** was accepted as a useful visual-development route: expressive **painted facial features on a true 3D head**, rather than unsatisfactory protruding geometry or a flat puppet. This is about a renderer's style, not a literal statement about Saafiya's personality or the historical world.
- **[D/V]** A deeper **sweetheart/V-shaped low-cut corset neckline** was explicitly requested during the 3D refinements. The Gothic outfit also contains lace/fishnets, hoop earrings, buckled boots, a crescent pendant, dark lipstick and a dark/burgundy hair treatment. Keep ordinary scene-appropriate costume changes possible.
- **[V]** Hero-shooter source \`tools/render/sophia_saafiya_v3_2_studio.py\` and \`sophia_saafiya_studio_v3_3_builder.py\` record a **1.72 m procedural model scale**, a V3.3 **2048×2048 painted facial UV**, several expression textures, and a lowered neckline. The standalone V3.3 builder labels its produced mesh **unrigged**; other subsequent integrated sprites/animations may be independently implemented. **1.72 m is an asset-unit prototype dimension until the director confirms her exact fictional height.**
- **[D/V]** A chrome or nickel-like appearance for the inherited Beretta was preferred, with proportions adjusted to look less oversized. Certain sprites and pose animations keep a left-side emphasis. These are **visual specifications**, not new biographical facts or mechanical instructions.
- **[O]** Earlier sprite sheets, 3D renderers and current Godot artwork may not depict identical hair, makeup, bust/corset silhouette or weapon. Store the **source, date and approval** before using any individual image as the master character reference.

## 3. Keep C and Saafiya unmistakably separate

- **[L]** The Hero-shooter *Home & More* prologue revolves around **C**, a character whose story responsibilities differ from those of adult Saafiya/Fay. Some historical code/asset references blur *Sophia* and *Saafiya* as search keys, but the narrative should not merge distinct characters due to a shared technical system.
- **[V]** A **separately approved C character reference** exists in the Library, dated 22 November 2026. It describes an auburn-brown voluminous ponytail, freckled face, flower/daisy headband, hoop earrings, brown eyes, a restrained smirk, practical layers, scarf/harness, trousers and boots. Another recalled rendition may appear lighter/blonder. **This character reference is for C, not proof Saafiya's hair or complexion should match C's.**
- **[D/O]** Saafiya's own main visual language is dark burgundy-black curly hair, warm tan skin, gothic outfits and distinctive makeup. Where a game scene uses a reused sprite or name alias, require an explicit identity decision at the story level.
- **[O]** Her potential temporary-companion role to C and the chronology of her separate Pine Ridge route remain distinct from playable-C or playable-Saafiya prototypes.

## 4. Sarah's introductory bridge, an easily lost social detail

- **[D]** The earlier McDonald's meeting is **not necessarily a first conversation**: Sarah, wearing alternative/Victorian-inspired clothing with an inherited ornamental hairpin, was with acquaintances **waiting to meet someone they knew through Dark Mountain**, potentially a face-to-face meet-up or "face exchange". Saafiya was accompanied by Aunt Isadora after a school incident.
- **[D/P]** Sarah may already be aware of Saafiya at school and later approach her in **art class**, where she first offers meaningful help, then asks the teacher to move her workspace alongside Saafiya. The McDonald's scene and the classroom story are separate beats that may both occur.
- **[D]** Friendships and online connections have a **two-way traffic**: older internet relationships can lead to face-to-face gatherings, while Ambrosia moves *offline -> online*. Farsha's clan has the contrasting *online -> later offline connections* trajectory.
- **[D/I]** Sarah's school friendships and her Oracle/coven custodianship mustn't turn her into an omniscient protector; she is still a teenage girl with private family pressures and significant emotional needs.

## 5. Game narrative choices that belong in the story bible even if no mechanic is final

These were previously discussed for the *Saafiya's Revenge / Pineridge Crisis* presentation and have **story implications**; however a requested UI sketch is not proof a feature was implemented.

- **[D/P] Character dispositions:** a selection concept included **Bruiser, Hitman, Gangster and Balanced** as playstyle/temperament archetypes. Their final narrative meanings, names and implementation status are **[O]**; never use one selection to rewrite her established family history.
- **[D/P] An optional trait** could give a meaningful **strength and weakness** together. Character-setup choices were to be **fixed after gameplay begins**; later earned traits/perks might follow significant story events. Distinguish menu concepts from implemented skill systems.
- **[D] Consequences are not simply a score:** individuals have their own schedules and agendas, and **some people may become impossible to save** when the player chooses one course of action or arrives after circumstances have moved on. That can make decisions emotionally weighty without imposing fake choice.
- **[D/P]** Narrative dispositions should not replace psychological accountability. The game explores haste, attention, empathy, restrained aggression, grief, betrayal, imperfect judgment, and the effects of decisions on particular people.
- **[D/V] HUD notes** included a **16:9 scalable gothic interface**, a character portrait near the upper left, a rotating minimap under a **fixed chevron**, context-sensitive heart/ammunition indicators that must remain **dynamic**, and an **ankh** rather than Christian-cross imagery for the preferred decorative treatment. These are presentation preferences, not religious testimony about the character and not proof the menu is implemented exactly as drafted.
- **[V]** Some earlier **character-setup concept images included gothic crosses**, while the director subsequently preferred an ankh and less extraneous regular-HUD clutter. Preserve supersession order; do not claim an older art prompt has final approval.
- **[O]** Exact chosen disposition, traits, character stats, UI screens and implementation are not fixed by this supplement.

## 6. Period-media guardrails, but not personal plot facts

- **[H/D]** MXit/Dark Mountain's real inspiration spans mid-2000s mobile GPRS and older MSN/Yahoo/forum generations. A possible "Moonlit Pixie" identity belongs to the relevant pre-WhatsApp period, not a modern social-video app.
- **[P/O]** Fantasy-media references from different years (console RPGs, tabletop, Tolkien-inspired elves, Celtic artwork, vampire media) can inform **different participants** and should not be retroactively assigned to school-era Saafiya as firsthand experiences.
- **[D]** The director recalled his own **PlayStation 2, Oblivion and anime-game** experiences as a primer for Dark Mountain. The fictional Saafiya is **not yet established as an intensive gamer**. Her earlier Nintendo-like console, Tazos and modest drawing/collecting remain tentative.
- **[O]** Earlier creative discussion placed school stories around **2005–2008** or more broadly late 2000s; the exact school grade/chronology and the timing of Dark Mountain's expansion remain unresolved. Avoid introducing media that had not yet been released in a given year without explaining the timeline.

## 7. Other explicitly unresolved matters

- **[O]** Heather's proposed Rossi .38 Special, Saafiya's father's inherited Beretta and the separate custom Model 640 poolside revolver should never be collapsed into a single source of inheritance.
- **[O]** C's approved art, Saafiya's various 3D and sprite prototypes, Sarah's costumed appearances, and the fictional *Oracle* persona are **distinct character/art provenance lines**.
- **[O]** Left-handedness versus a left-biased presentation, 1.72 m prototype scale versus final character height, and alternate black Mustang years and models all await independent decisions.
- **[O]** Some prior discussions describe Sarah's group as a **girls' private reading/makeup circle**; later brainstorming allows older participants and a diverse coven. Whether these are *two nested circles*, an evolving membership, or alternate stages is not settled.
- **[O]** The coven's exceptional senior practitioners have genuine abilities *in the fictional world*, but their exact gifts and limits, and Saafiya's elementary participation, are still not formally defined as gameplay mechanics.
- **[O]** The 2021 KZN crisis, Copperlane/Johannesburg chase, Rivermere/Pine Ridge naming conflict, Farsha school arc, and *Home & More* opening remain intentionally fragmented until a director-approved chronology exists.

## Source and archival caveats

- The original *Hero-shooter* lore snapshots remain preserved unedited under [source-hero-shooter](source-hero-shooter/).
- The **C canonical reference** is an approved artwork/library document, not a file copied into this repository.
- The Saafiya 3D scripts were inspected in the **older source repository**; they were not compiled or modified during this lore audit.
- Notes from recoverable prior conversation context can be partial; this is **not a transcript or claim of full historical-chat coverage**.
- No new game code, artwork binaries, props or mechanics are created by this file.
