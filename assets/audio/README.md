# Replaceable audio recordings

Place your own licensed sound clips here, then commit them. Each event supports WAV, OGG or MP3 (checked in that order).

| Filename (without extension) | Trigger |
| --- | --- |
| `saafiya_death` | Saafiya loses her final health point |
| `beretta_84fs_shot` | Beretta 84FS action |
| `cz75_shot` | CZ 75 / P-07 action |
| `akm_reload` | AK-pattern reload sequence, one complete clip |
| `crowd_shout` | Occasional ambient NPC shouting, rate-limited |

Other supported cues: `fire`, `beretta_reload`, `cz75_reload`, `pickup`, `set_down`, `alert`, `reaction`, `reset`, `down`.

The supplied sounds were not present as audio files when these event hooks were added. The loader falls back to short synthesized tones, not simulated weapon reports or authentic isiZulu speech. `crowd_shout` can use your deliberately nonsensical vocal clip; it is not presented as real dialogue. Seven sound channels allow overlap, while loaded clips are cached.
