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
| ez-med-pillar.webp | [Man Meditating at Sunset in Assos, Türkiye](https://www.pexels.com/photo/man-meditating-at-sunset-in-assos-turkiye-34044030/) | Emrecan Dora |
| ez-med-lotus-room.webp | [Woman in Lotus Position Meditating](https://www.pexels.com/photo/woman-in-lotus-position-meditating-7596969/) | Pavel Danilyuk |
| ez-med-home.webp | [Woman Sitting in Lotus Position Meditating Inside a House](https://www.pexels.com/photo/woman-sitting-in-lotus-position-meditating-inside-a-house-6246588/) | KoolShooters |
| ez-med-lotus-white.webp | [Serene plus size female meditating in Lotus pose](https://www.pexels.com/photo/serene-plus-size-female-meditating-in-lotus-pose-6975413/) | SHVETS production |
| ez-med-candle.webp | [Lighted Candle Beside a Tibetan Singing Bowl](https://www.pexels.com/photo/lighted-candle-beside-a-tibetan-singing-bowl-7303281/) | Cup of Couple |

Used by the Editeaze-style cards (`lib/widgets/editeaze.dart`): Normal home hero carousel, Normal home footer card, Healing path strip, and the Profile "Your practice mind" section (`ez-med-lotus-white` is that section's meditation image).
