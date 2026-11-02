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
- hc-b-breath — Tima Miroshnichenko, https://www.pexels.com/photo/5928625/
- hc-b-sound — Jan Kopřiva, https://www.pexels.com/photo/6593243/
- hc-b-sleep — RAVI LAGES, https://www.pexels.com/photo/6308172/
- hc-b-heal — Pavel Danilyuk, https://www.pexels.com/photo/7596969/

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
