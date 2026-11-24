# Attributions

Third-party animation code and assets used by the app, with their source
and licence. Add a row here before bundling any new Lottie/Rive file, and
only bundle files whose licence is MIT, Apache-2.0, CC0 or CC-BY (credit
below). Anything with unclear terms stays out.

## UI Editor animation library (`lib/admin/layout/anims/`)

All 87 drawn animations (orbs, loaders, backgrounds, particles,
celebrations) are original procedural Flutter code written for this app
(CustomPainter + Ticker). No Lottie or Rive files were added for them.

| What | Source | Licence |
|---|---|---|
| The 6 thinking orbs (Composing, Listening, Solving, Working, Searching, Shaping) | [`flutter_thinking_orbs`](https://pub.dev/packages/flutter_thinking_orbs) 0.1.0 by Bright Sunu, a port of [thinking-orbs](https://github.com/Jakubantalik/thinking-orbs) | MIT |
| Entrance and loop effects | [`flutter_animate`](https://pub.dev/packages/flutter_animate) by Grant Skinner | BSD-3-Clause |

## Practice stage music (`assets/words/america/*_music.m4a`)

The "With music" version of each America stage plays the client's own
recording over a soft drone, ducked under the voice. The voice is the
client's recording only; nothing synthetic.

| What | Source | Licence |
|---|---|---|
| Background drone | “meditationdrone1.wav” by Jim-Bretherick, [freesound.org/s/674255](https://freesound.org/s/674255/) | CC0 1.0 |
| Background “Warm pad” and “Singing bowl” (stage `_music2` / `_music3` versions) | Synthesised from sine waves for NowssB by `tool/audio/make_beds.py`; mixed and ducked by `tool/audio/mix.py` | CC0 1.0 (own work) |
| Background “Bansuri” and “Tanpura” (stage `_music4` / `_music5` versions) | Synthesised for NowssB (flute tone with breath and vibrato; four plucked strings with jawari brightness) by `tool/audio/make_beds.py`; all five beds re-mastered by `tool/audio/master.py` (voice −14 LUFS, bed about 12 dB under, ducked) | CC0 1.0 (own work) |
| Sound picker photo “Drone” (`assets/images/sound_beds/drone.webp`) | [Himalaya Mountains seen at sunset in Kaule Nepal](https://commons.wikimedia.org/wiki/File:Himalaya_Mountains_seen_at_sunset_in_Kaule_Nepal.jpg) by julesair, cropped | CC BY-SA 2.0 |
| Sound picker photo “Warm pad” (`pad.webp`) | [Light in Darkness](https://commons.wikimedia.org/wiki/File:Light_in_Darkness.jpg) by Susmitad830, cropped | CC BY-SA 3.0 |
| Sound picker photo “Singing bowl” (`bowl.webp`) | [Playing a hand-forged Nepalese singing bowl with a felt mallet during studio recording in Bratislava](https://commons.wikimedia.org/wiki/File:Playing_a_hand-forged_Nepalese_singing_bowl_with_a_felt_mallet_during_studio_recording_in_Bratislava.jpg) by JAMBATI eu, cropped | CC BY 4.0 |
| Sound picker photo “Bansuri” (`bansuri.webp`) | [All scales of Bansuris in a set](https://commons.wikimedia.org/wiki/File:All_scales_of_Bansuris_in_a_set.jpg) by Vamsivadrevu, cropped | CC BY-SA 4.0 |
| Sound picker photo “Tanpura” (`tanpura.webp`) | [A pair of female vocal tanpuras](https://commons.wikimedia.org/wiki/File:A_pair_of_female_vocal_tanpuras.jpg) by Martin spaink, cropped | CC BY-SA 3.0 |
| Sound picker photo “Voice only” (`voice.webp`) | [Studio microphone with pop-shield crop](https://commons.wikimedia.org/wiki/File:Studio_microphone_with_pop-shield_crop.jpg) by Galak76, cropped | CC BY-SA 3.0 |
| Voice noise reduction (build time only, not shipped) | ffmpeg `arnndn` with `std.rnnn` from [richardpl/arnndn-models](https://github.com/richardpl/arnndn-models) | BSD-3-Clause |

## Not yet traced

`assets/anim/thinking/` and `assets/anim/loaders/` (the admin orb picker's
Lottie gallery, added in c5564e52 as "NowssB gold recolor") have no source
URL or licence on record. They are not part of the editor's animation
library. Trace their origin and licence and record them here, or replace
them.
