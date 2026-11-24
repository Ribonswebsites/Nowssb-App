# Scorer robustness — Nov 24, 2026

Each stage is scored against its **clean** recording
(`assets/words/<word>/<word>_stage<N>_ref_clean.wav`, 16 kHz, made from the
mastered `_clean.m4a`). The "take" is the teacher's ORIGINAL raw take of the
same stage (`_ref.wav`), degraded with ffmpeg the way a phone in a room
would (`scorer_eval_clips.sh`). Scores are the calibrated numbers the app
shows; `*` = did not pass (pass = 70+ and the whole word said).

Other words = every other word's stages scored against this stage (must stay
under 50). Clips: `CLIPS=<dir> bash scorer_eval_clips.sh`.

```
stage               orig  noise20  noise15  noise10   reverb    phone  gain+12  gain-12tempo0.75tempo0.85tempo1.15 tempo1.3  pitch-2   pitch2  silence    combo   | other words (max)
america_s1            95       96       96       96       88       92       91       95       95       94       96       94       86       82       95      67*   | max 45 ~america_s2:67
america_s2            97       97       97       97       88       92       98       97       97       97       97       94       89       87       97       74   | max 46 ~america_s1:62
ramram_s1             98       98       98       98       84       91       96       98       97       97       97       97       86       86       98       84   | max 38 ~ramram_s2:35 ~ramram_s3:47
ramram_s2             96       96       97       97       85       91       96       96       95       96       95       94       85       80       96       75   | max 39 ~ramram_s1:34 ~ramram_s3:44
ramram_s3             97       97       97       97       87       94       96       97       96       96       96       95       89       89       97       87   | max 45 ~ramram_s1:42 ~ramram_s2:39
washington_s1         83       83       83       85       75      60*       71       83       89       93       93       79       87       80       84      56*   | max 49 ~washington_s2:39
washington_s2         90       89       92       90       82      61*       92       90       84       79       74       92       87       82       88      62*   | max 37 ~washington_s1:45
same word degraded: min 56  median 93  >=75: 104/112
other words: max 49  median 33  <50: 64/64
same word other stage: [67, 62, 35, 47, 34, 44, 42, 39, 39, 45]

```

Summary: same word degraded — min 56, median 93, 104 of 112 at 75+.
Different words — max 49, median 33, 64 of 64 under 50.

Weak spots (honest): the "combo" clip (everything at once: delay, 15 %
faster, 1 semitone up, phone band, echo, noise, compressor) for America 1
and both Washington stages, and the telephone band (300–3400 Hz) for
Washington — the long word loses its "sh" and final "n" there. A real phone
records the full band, so this is the worst case.

The committed CI check is `test/scorer_robustness_test.dart` (the same idea,
degradations made in Dart: gain ±12 dB, noise 15 dB, echo, silence,
speed 0.9×/1.1×, plus all cross-word pairs).
