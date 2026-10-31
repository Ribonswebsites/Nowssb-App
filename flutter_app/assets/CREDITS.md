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
| ez-hero-orange.webp | [Woman sitting on white background in studio](https://www.pexels.com/photo/woman-sitting-on-white-background-in-studio-6311504/) | Monstera Production |
| ez-hero-teal.webp | [Woman in Gray T Shirt Doing Yoga Pose](https://www.pexels.com/photo/woman-in-gray-t-shirt-doing-yoga-pose-8152402/) | RDNE Stock project |
| ez-hero-yellow.webp | [Graceful young ethnic woman sitting on floor with crossed legs in studio](https://www.pexels.com/photo/graceful-young-ethnic-woman-sitting-on-floor-with-crossed-legs-in-studio-5311795/) | Roberto Hund |
| ez-hero-coral.webp | [Woman in Beige Crop Tank Top Sitting in Yoga Position Meditating with Eyes Closed](https://www.pexels.com/photo/woman-in-beige-crop-tank-top-sitting-in-yoga-position-meditating-with-eyes-closed-4723097/) | Polina Tankilevitch |
| ez-hero-blue.webp | [Serene plus size female meditating in Lotus pose](https://www.pexels.com/photo/serene-plus-size-female-meditating-in-lotus-pose-6975413/) | SHVETS production |
| ez-med-candle.webp | [Lighted Candle Beside a Tibetan Singing Bowl](https://www.pexels.com/photo/lighted-candle-beside-a-tibetan-singing-bowl-7303281/) | Cup of Couple |

Used by the Editeaze-style cards (`lib/widgets/editeaze.dart`). `ez-hero-*` are the Normal home hero cards: the studio backdrop was removed (cut-out) so each person stands on the card's solid colour; the photos are otherwise unedited. `ez-med-*` are used by the Profile "Your practice mind" section.
