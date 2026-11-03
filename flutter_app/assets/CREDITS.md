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

### Red-hair / Cleopatra sweep 3 (in-house generated art, free to use; each figure distinct)

| File | New figure | Replaced |
|---|---|---|
| `footer/tab-breathe-new-noise.webp` | Bald bearded South Asian man, saffron kurta, on yellow ("NEW NOISE") | Red-haired woman |
| `banners/promo/pose-02.webp` | Elderly Black woman, grey afro, teal linen, lotus (cut-out) | Red-haired woman ("A word for the body now") |
| `banners/promo/pose-06.webp` | Korean man, grey hoodie, kneeling, prayer hands (cut-out) | Red-haired woman |
| `banners/promo/split-blonde-blazer.webp` | Latina woman, black braid, olive linen, arms overhead (cut-out) | Red-haired woman |
| `banners/stories/prana.webp` | Ethiopian man in white linen, on black | Red-haired woman |
| `banners/stories/soma.webp` | Japanese woman, black bob, navy wrap | Cleopatra figure |
| `footer/tab-ancient-calm-new-sound.webp` | Tibetan monk on pink | Cleopatra figure |
| `footer/tab-find-your-frequency.webp` (+ root `file_…ad2f6542de.webp`) | Polynesian man, top bun, on red | Red-haired woman |
| `gifts/coupon-banner.webp` | Grey-bearded man holding coupons | Red-haired woman |
| `hero-curve/cleopatra.webp` (root) | Black woman, shaved head, purple robe, seated (cut-out) | Cleopatra figure |
| `player/guide/03.webp` | Brazilian man, curly hair, floating lotus | Red-haired woman |
| `store/signature-portrait.jpg` | Older South Indian man, salt-and-pepper hair, black kurta | Red-haired woman |
| `banners/course-bubble.jpg` | Young woman, curly black hair, white linen | Red-haired woman |
| `banners/programs/bonus.webp` | Pakistani bearded man, purple kurta | Cleopatra figure |
| `banners/programs/gift.webp` | Chinese grandmother, silver bun, black jacket | Red-haired woman |
| root `file_…674c…79f.webp` | Andean woman, black braids, woven poncho | Red-haired woman |
| root `file_…acd4…257.webp` | Malaysian man, purple baju melayu | Cleopatra figure |
| root `subscription/tier-{bag,nile,sun}-{back,front}.png` | Synced to the clean flutter_app versions | Red-haired / Cleopatra figures |

## Sweep 4 – dedupe blonde / text fixes (Nov 2026)

All images below are original AI-generated artwork made for NowssB (Grok Bot image generation, free to use); tagline-only edits re-typeset in Inter (SIL OFL) and NATURAL/ORIGIN in Oswald (SIL OFL).

| File | Change |
|---|---|
| flutter_app/assets/subscription/tier-sun-front.webp | new distinct meditation figure (gen f11fc68f) |
| assets/subscription/tier-sun-front.webp | new distinct meditation figure (gen f11fc68f) |
| flutter_app/assets/banners/programs/bonus.webp | new distinct meditation figure (gen 47809ad7) |
| flutter_app/assets/gifts/coupon-banner.webp | new distinct meditation figure (gen 7fca5658) |
| file_00000000674c820889c49845ef98b79f.webp | new distinct meditation figure (gen 4f3cf888) |
| flutter_app/assets/banners/banner-gold.webp | new distinct meditation figure (gen 2cabe3f4) |
| flutter_app/assets/banners/banner-sit.webp | new distinct meditation figure (gen cd6541f6) |
| flutter_app/assets/banners/banner-store.webp | new distinct meditation figure (gen e5f63937) |
| flutter_app/assets/banners/earn/bag-blonde.jpg | new distinct meditation figure (gen a96949e9) |
| flutter_app/assets/banners/earn/hands-light.webp | new distinct meditation figure (gen d9758618) |
| flutter_app/assets/banners/earn/hands-raise.webp | new distinct meditation figure (gen 9d32c7bf) |
| flutter_app/assets/banners/programs/earn.webp | new distinct meditation figure (gen c68e58b1) |
| flutter_app/assets/banners/promo/pose-04.webp | new distinct meditation figure (gen ddcc58e8) |
| flutter_app/assets/banners/promo/pose-05.webp | new distinct meditation figure (gen e54ff8f0) |
| flutter_app/assets/banners/stories/pitta.webp | new distinct meditation figure (gen c4ab3feb) |
| flutter_app/assets/footer/tab-calm-new-loud.webp | new distinct meditation figure (gen 209de98e) |
| flutter_app/assets/footer/tab-still-mind-still-style.webp | new distinct meditation figure (gen 3fddd0cc) |
| flutter_app/assets/gifts/gift-hero.webp | new distinct meditation figure (gen 75cb876b) |
| flutter_app/assets/hero-curve/tab-stool.webp | new distinct meditation figure (gen e751022b) |
| flutter_app/assets/player/intro/02.webp | new distinct meditation figure (gen 5c41bc21) |
| flutter_app/assets/player/intro/03.webp | new distinct meditation figure (gen 866db098) |
| flutter_app/assets/player/intro/07.webp | new distinct meditation figure (gen a1f7835e) |
| flutter_app/assets/player/guide/06.webp | new distinct meditation figure (gen 622adcac) |
| flutter_app/assets/player/guide/08.webp | new distinct meditation figure (gen 0b97b61e) |
| flutter_app/assets/login/login-neon.webp | new distinct meditation figure (gen 9ec8b3d1) |
| flutter_app/assets/notifications/hands-offer.webp | new distinct meditation figure (gen 7f3a6c18) |
| flutter_app/assets/routine/positive-self-talk.webp | new distinct meditation figure (gen 0a5c0aca) |
| flutter_app/assets/routine/quiet-within.webp | new distinct meditation figure (gen eea04887) |
| flutter_app/assets/routine/softer-voice.webp | new distinct meditation figure (gen 4f6f1da9) |
| flutter_app/assets/routine/stillness.webp | new distinct meditation figure (gen ce766410) |
| flutter_app/assets/routine/trusting-the-breath.webp | new distinct meditation figure (gen f9bcc1a3) |
| flutter_app/assets/routine/your-body-knows.webp | new distinct meditation figure (gen a57105bf) |
| file_00000000acd48211be9d4c5ef0f99257.webp | composited: Oswald headline above figure (no overlap) |
| flutter_app/assets/store/collections/cosmos.webp | new distinct meditation figure (gen e47f77ed) |
| flutter_app/assets/store/collections/mythical.webp | new distinct meditation figure (gen 141b656c) |
| flutter_app/assets/store/collections/nature.webp | new distinct meditation figure (gen a7cc1c7e) |
| flutter_app/assets/store/collections/peace.webp | new distinct meditation figure (gen 40aa9654) |
| flutter_app/assets/store/collections/sacred.webp | new distinct meditation figure (gen 9260ae94) |
| file_00000000813081f594f7597ac46978d6.webp | italic tagline repainted in plain Inter |
| file_00000000b77c82119c4127cc603420a8.webp | italic tagline repainted in plain Inter |
| file_00000000b56c820aade81ceee1d06ccf.webp | italic tagline repainted in plain Inter |
| file_000000005f8881f48b6867d03c79a021.webp | italic tagline repainted in plain Inter |
| flutter_app/assets/footer/tab-ancient-calm-new-sound.webp | italic tagline repainted in plain Inter |
| flutter_app/assets/footer/tab-breathe-new-noise.webp | italic tagline repainted in plain Inter |
| flutter_app/assets/footer/tab-find-your-frequency.webp | italic tagline repainted in plain Inter |
| file_00000000500081f4924f93ad2f6542de.webp | italic tagline repainted in plain Inter |
| flutter_app/assets/footer/tab-sound-of-stillness.webp | italic tagline repainted in plain Inter |
| assets/gifts/coupon-banner.webp | garbled 'Moanit' earcup logo removed (local retouch) |


_Nov 3 2026: the flutter_app copies of hero-curve, flip_brand, login cards and profile/rails/avatar_a were restored to their Oct 21 versions, so their Nov 2 replacement rows were removed. Root `file_…` webp edits noted above still apply to the root assets._

## Sound-healing section photos (Nov 3, home/sh/) — real photos, warm cinematic grade, ~1600px webp
- sh-bowl-hands — Anastasia Shuraeva, Pexels (Pexels licence), https://www.pexels.com/photo/a-person-playing-a-singing-bowl-6013481/ — Normal home "Offers and earning / Words that carry meaning" card
- sh-bowls-candle — Daka, Pexels (Pexels licence), https://www.pexels.com/photo/metal-singing-bowls-20278603/ — Normal home "Your programmes" large tile
