# Game recordings — imported

These six sound files are included directly in the repository and shipped with both browser and Linux exports. File names are also event IDs for `scripts/preview_audio.gd`.

| File | Trigger | Source |
| --- | --- | --- |
| `saafiya_death.ogg` | Saafiya's defeat/death | Supplied ElevenLabs Generation 2 |
| `beretta_84fs_shot.ogg` | Beretta 84FS fire | Supplied ElevenLabs Generation 4 |
| `cz75_shot.ogg` | CZ 75 P-07 fire | Supplied CZ 75 WAV, converted to Vorbis |
| `akm_reload.ogg` | AKM reload | Supplied AKM reload WAV, converted to Vorbis |
| `akm_shot.mp3` | AKM fire | Original supplied 1.63-second stereo MP3, unchanged |
| `crowd_shout.ogg` | Periodic ambient NPC shouting | Supplied vocal WAV, converted to Vorbis, level increased for intelligibility |

The user-supplied recordings replace the earlier synthesized tones for these six events. Additional missing cues (`pickup`, `reaction`, `alert`, `beretta_reload`, `cz75_reload` and others) still use placeholder tones until recordings are supplied.

The shout is intentionally fictional, unintelligible vocal material, not a translation or authentic dialogue. The reloading clip is one complete sound sequence, and its timing may be adjusted during audio playtesting.

Run `python3 tools/verify_audio.py` to check all six byte-for-byte checksums. CI verifies both binary integrity and Godot import. Keep source rights/attribution information with any commercial release.
