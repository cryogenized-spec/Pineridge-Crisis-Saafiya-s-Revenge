# Hero Shooter — narrative presentation, dialogue identity and music (November 2026)

> **Status:** Creative-direction notes, not an implemented feature or final screenplay. **[D]** = director-specified preference, **[P]** = proposal to test, **[O]** = open design choice.
> **Scope:** The comic/motion-comic cutscenes, Nintendo DS-inspired portrait conversations, reflective visual language, dialogue typography, Saafiya's heart motif, music, moral-choice presentation and continuity considerations.

## Guiding visual language

Three presentation modes can coexist without turning the game into a full-motion-video project:

1. **Major scenes — motion comics:** comic-strip panels, selective movement, sound, strong framing and editing inspired by **XIII (2003)**, the cel-shaded comic-styled PlayStation 2-era shooter.
2. **Conversations — bust portraits:** left/right **waist-up or mid-torso-up** characters, expressive eyes, clothing and gestures, inspired by the **Nintendo DS Shin Megami Tensei: Devil Survivor** conversation presentation. The playable protagonist/point-of-view character anchors the left, conversation partner the right; avoid assuming C and Saafiya are always the same player character.
3. **Exploration/action — existing game rendering:** normal top-down view and HUD, with cinematic letterbox bars appearing for scripted sequences and receding as control returns.

**[D]** This must feel like handmade illustrated cinema using a few good frames rather than an expensive, continuous animation. **[P]** Animate crops, position, scale, masks, light, rain, eye blinks, minor head movements and illustrated sound effects, but don't shift static character artwork so far it becomes visually inconsistent.

## Conversation portraits

- **[D]** Use **large character images**, not tiny circular face icons, with enough torso visible to show hands, posture, jewellery, clothing and interpersonal distance.
- **[P]** Source portrait art: transparent-background **900 × 1400** or **1000 × 1600 px**, with safe crop zones; in a 16:9 game, each side can occupy roughly 30–38% of the width while the text/dialogue pane covers approximately 20–25% of screen height, to be tuned against actual layout.
- **[D/P]** Speaking figure sharp/bright; listener slightly dimmed; natural expression swaps, optional subtle slide or forward emphasis. Avoid overanimated idle motion.
- **[P]** Core Saafiya portraits: neutral, suspicious, annoyed, angry, wounded/sad, startled, resolute and cold/dissociated. Russian, Domino, Fayeem and other characters need their own limited expression sets.
- **[P]** Allow accessible speaker labels and ordinary text alternatives. Speech/text reveal speed should be selectable; dialogue must work even when advanced visual effects are disabled.
- **[O]** Whether characters ever change sides is scene-dependent. A consistent camera/left-right rule helps the player but should not override dramatic framing.

## Saafiya's mood-dependent lettering

**[D]** Saafiya requires a distinct gothic visual voice, not generic high-fantasy **Cinzel**. Different moods may call for different typefaces. The goal is **modern, succinct, black, elegant**, with restrained pagan/manuscript accents rather than uniformly medieval or overtly Satanic styling.

| Profile | Working typeface | Usage | Status |
|---|---|---|---|
| **B0** | **Texturina** | Regular readable dialogue, conversation with friends and Fayeem | [P] |
| **B1** | **Grenze Gotisch** | Severe, serious, angry, determined speech; blackletter-inflected profile the director explicitly called **B1** | [D] category, [P] exact font |
| **B2** | **Almendra Display** (or italic) | Spiritual inwardness, mythology, nature/pagan associations and ritual-inflected reflection | [P] |
| **B3** | **Fondamento Italic** | Quiet tenderness, mourning, singing, memory, intimate reflections | [P] |
| **B4** | **UnifrakturCook** | Very rare major declaration, ominous emblem or title; not long body copy | [P] |

Also considered **Uncial Antiqua** for ancient manuscript/ritual markers and **Cormorant Garamond** for readable literary dialogue. Neither is settled as her primary typeface.

- **[D]** Blackletter is not meant to be pasted indiscriminately over every dialogue sentence.
- **[P]** Use dramatic faces on nameplates, key words, captions or short lines; regular text needs readable fallback, adjustable size, support for Afrikaans/English and good contrast.
- **[P]** Character identity should stay stable even if font temporarily changes: nameplate, tone, layout and colour support recognition. Never imply an emotion solely through typography.
- **Implementation / licensing:** verify a font's exact OFL or other embedding licence and its redistribution conditions before bundling, especially for WebFonts; record licence and authors in the game's credits.

## Japanese-film-inspired pillow shots and pauses

**[D]** Borrow the quiet, contemplative rhythm associated with Japanese cinema, especially **“pillow shots”**: an empty room, a glass of water, rain on a window, a teacup, shoes by the door, a curtain breathing in wind, an evening street or the still surface of the aunt's communal pool.

These moments should **not** be treated as filler. They create room for the audience to feel a loss or think about what just happened, and contrast with the relentlessly fast action and electronic soundtrack.

**[P]** Example for Saafiya's Cape Town flashback: Ambrosia girls make a joke about immortality; the conversation resumes. Cut to streetlights and leaves moving along pavement while Sophia wonders privately whether immortality is a blessing. No explanatory speech required.

**[P]** Example after a frightening encounter: a lamp illuminates an untouched cup, the outside world continues; a short **B3** thought in her voice appears. Let environmental audio carry the meaning.

## Small cinematic decisions during gameplay

- **[D]** Player-selectable dramatic actions can have short illustrated cut-ins, not a bland stock execution animation. Use only a few frames with expressive drawing, sound cues and camera pans.
- **[P]** Keep these skippable/replayable and non-obstructive during immediate danger; never make required decisions ambiguous because an animation hides relevant information.
- **[D]** Opening confrontation with hostile people at the mall should convey Saafiya's **hesitation, anger, disbelief and increasing fear**. She goes forward because of a disturbing personal lead from Russian concerning Fayeem.
- **[P]** Do not flatten together a real immediate threat, an unarmed bystander and a person fleeing. If the game lets the player harm a non-threatening person, that is a consequential branch, not automatic legitimisation.
- **[D]** Cinematic bars withdraw when free movement starts; a private thought such as **“I need to proceed. Must find Fayeem.”** grounds the return to control.
- **[P]** First proof of concept: a **15–20-second** scene built from existing artwork and 3–5 modestly animated layers, with a mood-specific portrait or text moment; no full video pipeline required.

## Heart / pulse motif

**[D]** Consider a short screen or HUD motif containing a **lifelike red beating heart**, expanding and contracting, seemingly suspended from thin empty tendrils or vines. Initial emotional state is metaphorically “red”, relatively intact and good-leaning; increasing darkness should feel mournful rather than a superficial demon transformation.

**[P]** Separate at least three concepts:
- **Pulse / BPM:** transient physiological stress, surprise and exertion (not a moral judgment).
- **Psychological burden:** grief, fear, shock and emotional exhaustion; can change with narrative events.
- **Humanity / conduct:** durable choices involving mercy, cruelty, vulnerability and conscience; does not directly track heart rate.

The artwork is an evocative metaphor, not a medical measurement. Do not imply a graphic BPM display predicts someone's goodness.

**[P]** Use the detailed heart mostly at major choices, introspections and transitions; use a much subtler pulse indicator in active gameplay. Accessibility option to disable pulsing/flash animation.

## Morality, institutions and long-running consequences

**[D]** The world should not have an arcade-like police five-star meter as the sole consequence system. Distinguish, possibly through hidden narrative variables:
- Russian alignment / affinity with his worldview and tactics;
- public legitimacy / trust;
- scrutiny by police, investigators, intelligence bodies and rival groups;
- regional stability and consequences for civilians and communities.

**[P]** Choices should affect later dialogue, witnesses, relationships, opportunities, investigation and geographical power balances rather than only immediate combat rewards.

**[D]** A bleak branching ending, **“But None of Us Will Win,”** has Saafiya succeed Russian through increasingly brutal acts only to preside over shattered autonomy, political fragmentation, exploitable land/resources and ultimately her own death. Treat as a tragedy and warning, not a victory screen or an ethnic/political “kill list.”

**[O]** The specific thresholds, faction names, institutions and choices remain to be designed once the storyline chronology is locked.

## Soundtrack: established taste and exploration directions

**[D]** The director responds strongly to **“Highwaymen Anthem”** from **Far Cry New Dawn**, especially the **distorted, dirty synth** and **driving foreground beat** associated with the Highwaymen aesthetic. This is a stylistic reference, **not** a licence to package that commercially released track.
**[D]** A complementary reference is **“Courage Reborn”** (a Dragon Ball / Budokai Tenkaichi-related fan remix), for its emotionally urgent melodic breakbeat/drum-and-bass side. A fan remix is **not** thereby royalty-free.

Suggested music identity:
- **Industrial darksynth / electro-industrial trap** for chaotic danger, menace, hard rhythm.
- **Melodic breakbeat / fast drum & bass / dramatic action trance** for momentum and emotional intensity.
- **Dark ambient or restrained synth** for exploration, domestic scenes, contemplation.
- **Brief cues / stingers** for choices and letterbox transitions.

Possible scene mapping:
- Main menu: ominous darksynth;
- **Home & More** quiet chapter: subdued environmental music and authentic workplace ambience;
- mounting unrest: rhythmic pulse;
- chase/combat: selected aggressive electronic tracks;
- Saafiya's grief or Ambrosia memories: soft ambient/female-voice or folk-inspired textures, if fitting;
- mission completion: concise electronic stinger rather than an oversized fanfare.

**[D/P]** Seek actual licensable stock/game music, preferably CC0 or CC BY where commercial/game embedding is allowed. Check full terms of each track before reuse, including attribution, derivatives, redistribution or extra platform restrictions. **YouTube discovery alone does not establish game rights.** Preserve title, author, download source, licence, retrieval date and required credits in a dedicated music manifest. Do not copy protected soundtrack audio, or imitate a particular track's melody.

Candidate discovery sources previously discussed: OpenGameArt, itch.io music packs, Pixabay Music (individual Content Licence terms), and YouTube as a search/listening aid. No candidate is yet **approved** as an in-game asset.

## Tooling / production

**[P]** CapCut (ByteDance) offers mobile image/keyframe editing, but desktop **Kdenlive** on Linux is an attractive fully editable timeline. A simple engine-side scene renderer may ultimately be more economical: framed sprites/panels, opacity, masks, image layers, audio cues, timed captions and state transitions.

Build a reusable **scene data model** (panel IDs, illustration assets, camera transform, animation duration, sound cue, caption, portrait expression, skip/choice handling), so the same storytelling language works across C's Home & More opening and Saafiya's later scenes.

**[O]** Exact engine implementation, video vs live layers, texture budgets, font embedding, dialogue localisation and portrait source art require experiments. **No gameplay code or asset pipeline is changed by this document.**

## Cross-references and continuity

- Main character and family expansion: [Saafiya development notes](../../lore/saafiya-development-notes-2026-11-24.md).
- Earlier established character continuity: [Saafiya history](../../lore/saafiya-history.md).
- C's established Home & More early chapter: [Chapter 1 opening](chapter-01-sunday-opening.md).
- Keep **C**, **Saafiya/Sophia**, **Fayeem**, **Russian**, **Domino**, and **Justin** distinct until chronology assigns their roles. Existing character/asset naming conventions must not be silently overwritten by speculative scene prose.

*Compiled from director discussions through 24 November 2026. Proposed designs need director review before implementation.*
