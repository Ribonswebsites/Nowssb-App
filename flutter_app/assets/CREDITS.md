# Asset credits (flutter_app/assets)

Sources of the media bundled into the Flutter app. Add a row before bundling
anything new. Code/animation licences are in `../ATTRIBUTIONS.md`.

| Asset | Source | Notes |
|---|---|---|
| `flutter_video/signature_words.mp4` | Supplied by Ribon Patil (NowssB owner), Oct 23 2026 | Signature Store "Words & Meanings" door. Re-encoded 960×540, H.264, muted, ~2.7 MB |
| `tv/home-words-tv.mp4` | Supplied by Ribon Patil (NowssB owner), Oct 2026 | Home TV card "Words & meanings" clip |
| NowssB coin / NowssB store mark art | NowssB original brand art | Keep the original coin image |
| `video/*.mp4` and `*-poster.webp` | NowssB project videos (shared with the website, `../assets/video`) | Many are generated "grok_video" clips made for NowssB |
| Symlinked folders (`banners`, `store`, `signature`, `meanings`, `ebooks`, `fashion`, `footer`, `frames`, `gifts`, `player`, `progress`, `routine`, `certificates`) | NowssB project art in the repo root `assets/` | Shared with the website |
| `anim/thinking/`, `anim/loaders/` | Not yet traced | See `../ATTRIBUTIONS.md` |
| `fonts/Anton-Regular.ttf` | Anton by Vernon Adams, Google Fonts, SIL Open Font License 1.1 (`fonts/OFL-Anton.txt`) | Home "Daily Quote" poster type |
| `fonts/CormorantGaramond-Variable.ttf` | Cormorant Garamond by Christian Thalmann, Google Fonts, SIL OFL 1.1 (`fonts/OFL-CormorantGaramond.txt`) | Home "Breathe" card |
| `icons/notif/*.svg` | Original line icons drawn for NowssB (no third-party source) | In-app notification pop-up category icons |

## Meditation photos — `assets/home/ez/` (Oct 31, 2026)

Free photos under the [Pexels licence](https://www.pexels.com/license/): free to use, modification allowed, no attribution required (credited anyway). Resized to 720 px and re-encoded as WebP (each under 70 KB).

| File | Photo | Photographer |
|---|---|---|
| ez-med-beach.webp | [Man Meditating at the Beach](https://www.pexels.com/photo/man-meditating-at-the-beach-5992566/) | Tima Miroshnichenko |
| ez-med-lotus-white.webp | [Serene plus size female meditating in Lotus pose](https://www.pexels.com/photo/serene-plus-size-female-meditating-in-lotus-pose-6975413/) | SHVETS production |
| ez-med-candle.webp | [Lighted Candle Beside a Tibetan Singing Bowl](https://www.pexels.com/photo/lighted-candle-beside-a-tibetan-singing-bowl-7303281/) | Cup of Couple |

Used by the Editeaze-style cards (`lib/widgets/editeaze.dart`). `ez-med-*` are used by the Profile "Your practice mind" section.

## Home hero (assets/home/hc/) — Pexels License, colour-graded, cut-outs made in-house
- hc-a-breath — Ivan S, https://www.pexels.com/photo/6648599/
- hc-c-word — KATRIN BOLOVTSOVA, https://www.pexels.com/photo/7113566/
- hc-b-sound — Jan Kopřiva, https://www.pexels.com/photo/6593243/
- hc-b-sleep — RAVI LAGES, https://www.pexels.com/photo/6308172/
- hc-f-heal — https://www.pexels.com/photo/3822906/ (Pexels License; replaces hc-b-heal, whose source cropped the head)

## Meditation cut-outs (assets/meditation/) — CC0
| File | Source | Use |
|---|---|---|
| `meditation/meditation-morning.webp` | "Thai woman meditating" by Kochphon (Honey) Onshawee, Wikimedia Commons `File:Thai_woman_meditating.jpg` (from Pixabay 481902), CC0 1.0 | Background removed (cut-out). Ritual card MORNING model (Ribon Oct 27) |
| `meditation/meditation-evening.webp` | rawpixel 5912948 "Free woman doing yoga pose", https://www.rawpixel.com/image/5912948, CC0 1.0 | Cut-out. Ritual card EVENING model |
| `meditation/meditation-seated.webp` | StockSnap AYWO7QN7K7 by Matthew Henry, https://stocksnap.io/photo/people-woman-AYWO7QN7K7, CC0 1.0 | Cropped cut-out. Poster Trending hero |
| `meditation/meditation-stone-stack.webp` | rawpixel 6030800 "Balancing rock piles", https://www.rawpixel.com/image/6030800, CC0 1.0 | Cut-out. Poster Orbit centre |
| `meditation/meditation-singing-bowl.webp` | rawpixel 5925218 "Free singing bowl set", https://www.rawpixel.com/image/5925218, CC0 1.0 | Cut-out. Poster Signature hero |
| `meditation/meditation-stones-wave.webp` | rawpixel 6029827 "Stone stacked, zen mode", https://www.rawpixel.com/image/6029827, CC0 1.0 | Cut-out. Drop Studio featured drop |
| `meditation/meditation-bowls-pair.webp` | rawpixel 5912429 "Free standing bell image", https://www.rawpixel.com/image/5912429, CC0 1.0 | Cut-out. Drop Studio word deck |
| `meditation/meditation-lotus.webp` | StockSnap VC8IOCGVII "Lotus Flower", https://stocksnap.io/photo/lotus-flower-VC8IOCGVII, CC0 1.0 | Cut-out. Drop Studio word deck |
| `meditation/meditation-candle.webp` | rawpixel 5963227, https://www.rawpixel.com/image/5963227, CC0 1.0 | Cut-out. Enter-curve stage subject |
| `meditation/meditation-cairn.webp` | rawpixel 5902834 "Stacked wellness zen stones", https://www.rawpixel.com/image/5902834, CC0 1.0 | Cut-out. Hero-curve stage subject |
- rs-candle — Pexels (free licence), https://www.pexels.com/photo/3822622/ — Offers & earning image and ref-style sections
- Ribon 10-27: the Cleopatra / Egyptian / red-haired art files (banners/promo/split-*-{egyptian,red}*.png, banners/course-cleo-{a,b}.jpg, banners/brand-cleo*.png) now hold the meditation photos above (hc-*, rs-candle); same Pexels credits.

## Normal-home ref sections (assets/home/ref/) — Pexels License (free), resized to 480px webp
- ref-1 — https://www.pexels.com/photo/1051838/
- ref-2 — https://www.pexels.com/photo/3822864/
- ref-3 — https://www.pexels.com/photo/3772612/
- ref-4 — https://www.pexels.com/photo/3820380/
- ref-5 — https://www.pexels.com/photo/3822583/
- ref-6 — https://www.pexels.com/photo/1029604/
- ref-7 — https://www.pexels.com/photo/4057839/
- ref-8 — https://www.pexels.com/photo/4325484/
- ref-9 — https://www.pexels.com/photo/6787202/
- hc-d-breath — https://www.pexels.com/photo/3094215/ (Pexels License)
- hc-d-sound — https://www.pexels.com/photo/4056535/ (Pexels License)
- hc-d-sleep — https://www.pexels.com/photo/6698513/ (Pexels License)
- hc-e-word — https://www.pexels.com/photo/4040567/ (Pexels License)

## B043/B044 replacements (Nov 2, 2026) — original art generated in-house for NowssB (no third-party source, free to use)
Generated with Grok Bot image generation; white background removed in-house.
| File | Picture | Replaces |
|---|---|---|
| `banners/promo/split-blonde-lotus.png` | Woman in linen, lotus pose, mudra (cut-out) | Egyptian/Cleopatra cut-out (was byte-identical to pose-01) |
| `banners/promo/pose-01.png` | Older man in saffron kurta, seated namaste (cut-out) | Same Cleopatra cut-out |
| `banners/promo/split-robot-lotus.png` | Woman kneeling on sage cushion (cut-out) | Copy of pose-05 |
| `banners/promo/split-robot-lookback.png` | Man in tree pose, hands overhead (cut-out) | Copy of pose-04 |
| `banners/earn/hands-dark.webp` | Man, arms raised in breath, violet on black | Mirrored/recoloured hands-light |
| `banners/earn/sit-dark.webp` | Woman seated in spotlight on black | Recoloured red-haired sit-light |
| `banners/earn/sit-light.webp` | Man in white linen seated, white background | Red-haired figure |
| `banners/promo/split-red-lotus.png` | Older woman with silver hair, lotus pose (cut-out) | Red-haired figure |
| `banners/promo/split-red-hair-blazer.png` | Man in mustard blazer, hand-on-heart breathing (cut-out) | Red-haired figure |
| `gifts/coupon-hero.webp` | Man in navy turban meditating with a golden coupon, on black | Red-haired woman (Zen "In the spotlight / Coupons") |

Earn backs and coupon hero now WebP (q80); cut-outs palette-compressed PNG (<200 KB each).
