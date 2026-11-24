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

| `shotgun_12ga_shot.ogg` | 12-gauge shotgun audio event / F4 sound preview | Provided `shotgun-spas_12-RA_The_Sun_God-503834910.wav`, transcoded to stereo Vorbis 44.1 kHz, -2.4 dB level |
| `shotgun_pump.ogg` | Pump-action audio event / F4 sound preview | Provided `Pump Shotgun-SoundBible.com-1653268682.wav`, transcoded to stereo Vorbis 44.1 kHz |

The user-supplied recordings replace the earlier synthesized tones for these eight events. Additional missing cues (`pickup`, `reaction`, `alert`, `beretta_reload`, `cz75_reload` and others) still use placeholder tones until recordings are supplied.

The shout is intentionally fictional, unintelligible vocal material, not a translation or authentic dialogue. The reloading clip is one complete sound sequence, and its timing may be adjusted during audio playtesting.

The shotgun sounds are separate assets rather than baked into a character animation. In F4, press **9** to preview a shot followed by the pump sound, or **0** to audition the pump sound alone. These are audio previews; the current main-story equipment list remains unchanged.

Run `python3 tools/verify_audio.py` to check all eight byte-for-byte checksums. CI verifies both binary integrity and Godot import. Keep source rights/attribution information with any commercial release.
