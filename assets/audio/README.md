# Game recordings — imported

These twelve sound files are included directly in the repository and shipped with both browser and Linux exports. File names are also event IDs for `scripts/preview_audio.gd`.

| File | Trigger | Source |
| --- | --- | --- |
| `saafiya_death.ogg` | Saafiya's defeat/death | Supplied ElevenLabs Generation 2 |
| `beretta_84fs_shot.ogg` | Beretta 84FS fire | Supplied ElevenLabs Generation 4 |
| `cz75_shot.ogg` | CZ 75 P-07 fire | Supplied CZ 75 WAV, converted to Vorbis |
| `akm_reload.ogg` | AKM reload | Supplied AKM reload WAV, converted to Vorbis |
| `akm_shot.mp3` | AKM fire | Original supplied 1.63-second stereo MP3, unchanged |
| `crowd_shout.ogg` | Periodic ambient NPC shouting | Supplied vocal WAV, converted to Vorbis, level increased for intelligibility |

| `shotgun_12ga_shot.ogg` | 12-gauge shotgun audio event / F4 sound preview | Provided `shotgun-spas_12-RA_The_Sun_God-503834910.wav`, transcoded to stereo Vorbis 44.1 kHz, -2.4 dB level |
| `shotgun_pump.ogg` | Pump-action audio event / F4 sound preview | Provided `Pump Shotgun-SoundBible.com-1653268682.wav`, transcoded to stereo Vorbis 44.1 kHz |
| `beretta_reload.mp3` | Beretta 84FS reload | **Physon712**, [Freesound 580869](https://freesound.org/s/580869/), **Creative Commons Zero (CC0)** — original uploaded MP3 retained unchanged |
| `cz75_reload.ogg` | CZ 75 P-07 reload | User-provided 9×19 pistol reload WAV take #4, transcoded to OGG |
| `male_looter_death_1.ogg` | First fictional adult male NPC death vocal take | User-provided generated vocal WAV take #3, transcoded to OGG |
| `male_looter_death_2.ogg` | Second fictional adult male NPC death vocal take | User-provided generated vocal WAV take #4, transcoded to OGG |

The user-supplied recordings replace earlier synthesized tones for these twelve events. Remaining missing cues (`pickup`, `reaction`, `alert` and others) still use placeholder tones.

The shout is intentionally fictional, unintelligible vocal material, not a translation or authentic dialogue. The reloading clip is one complete sound sequence, and its timing may be adjusted during audio playtesting.

The shotgun sounds are separate assets rather than baked into a character animation. In F4, press **9** to preview a shot followed by the pump sound, or **0** to audition the pump sound alone. These are audio previews; the current main-story equipment list remains unchanged.

Run `python3 tools/verify_audio.py` to check all twelve byte-for-byte checksums. CI verifies both binary integrity and Godot import. Keep source rights/attribution information with any commercial release.

The Beretta reload sound was replaced with the Physon712 recording supplied on 25 November 2026. The previous `beretta_reload.ogg` was removed to prevent the loader from selecting it first. The existing `beretta_reload` event and the F4 **H** audio preview now use the new MP3. The reload duration follows the loaded clip's reported length.
