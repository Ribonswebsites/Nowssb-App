# Third-party asset credits

## Gifts page and gift unwrap (assets/gifts/)
- `assets/gifts/gift_box_open_gold.json`: "Gift Box Opening Animation" by Goodeisgn via LottieFiles, https://lottiefiles.com/free-animation/gift-box-opening-animation-unvQpnOiEv. Lottie Simple License (free for commercial use). Recoloured gold.
- `assets/gifts/sparkle_stars_loop_gold.json`: "Sparkle Stars" by Ben via LottieFiles, https://lottiefiles.com/free-animation/sparkle-stars-Z4URVaAq6R. Lottie Simple License. Recoloured gold.

## Earn page (newui_earn)
- Backdrop orbs: procedural CustomPainter, original code, no third-party assets.
- Icons: Flutter Material Icons (Apache 2.0).
- Polish round: 3D clay medal, floating clay spheres, light sweep, breathing progress glow, count-up numbers and staggered entrance are all procedural Flutter code (CustomPainter/tweens), original, no third-party files. Online references (Dribbble/Contra glass meditation concepts, clay medal packs) were looked at for mood only; none bundled (their licenses are premium or unclear).

## Progress page (newui_progress)
- Aura background, progress ring: procedural CustomPainter written in-repo. No third-party assets bundled.
- Polish round (Oct 13 2026): breathing 3D-style orb, floating sphere/torus/pill, milestone badges, count-up and entrance motion are all procedural Flutter code (CustomPainter/TweenAnimationBuilder). No Lottie, Rive, image, video or font assets added. Design inspiration only (no art copied): Stillwater meditation flow (swiftpieces.com), Sleek meditation template "Your Journey", Zenly on Behance, Dribbble "3D Concept - Meditation App".
## Gifts page (newui_gifts)
- Glass gift box hero (isometric 3D-style box, ribbon, bow, drifting petals, floor shadow), breathing glow, floating orbs, glass tiles, staggered reveals and coin chip: procedural CustomPainter / Flutter widgets, written for NowssB. No new third-party files.
- Reuses `assets/gifts/sparkle_stars_loop_gold.json` (credited above, Lottie Simple License, free commercial use) faintly behind the hero box.
- Ideas only, no art copied: Meditate app's earn-a-mandala reward loop (screensdesign.com, 60fps.design) and glass-card / particle styling seen in Flow - Mindfulness (App Store). Lottie Simple License checked at https://lottiefiles.com/page/license on Oct 13 2026.

## Signature Words (newui_signature)
- Golden mandala loop: procedural CustomPainter (lib/pages/signature_words/mandala_painter.dart), original code, no third-party assets.
- Aura background (aura_background.dart), card tilt + shine sweep (tilt_shine.dart), shaded mandala core: procedural code, original, no third-party assets.
- Researched only (not bundled): LottieFiles free animations under the Lottie Simple License (https://lottiefiles.com/page/license); flutter_holographic (github.com/xcc3641/flutter_holographic) as a technique reference. Nothing copied.
## Profile page (newui_profile)
- Aura backdrop (lib/pages/profile/aura_painter.dart): procedural CustomPainter, original, no third-party assets.
- 3D breathing orb with ring and moon (lib/pages/profile/breathing_orb.dart): drawn in code (lit-sphere gradients, rim light, specular highlight), original. Inspired by the general "breathing orb / glass meditation" trend (e.g. Dribbble meditation glassmorphism shots, sleek.design meditation template); nothing copied or bundled.
- Milestone badges (lib/pages/profile/milestones.dart + new_profile_page.dart): code-drawn gradients + Material Icons (Apache-2.0, bundled with Flutter).



## Partner page (newui_partner)
- Orbit rings hero: procedural CustomPainter, original code, no third-party assets.

## Rewards page (newui_rewards)
- Correction (Oct 13 2026): custom lotus coin and aura background removed. The page uses the app's original background video, the app's existing coin (NwsbCoinDisc) and existing circle photos; reference-matched frosted glass cards written in code. Icons: Flutter Material Icons (Apache 2.0).
- Ideas only, nothing copied or bundled: Meditate app's earn-a-mandala reward loop (screensdesign.com showcase), Dribbble "streak reward" search results for layout mood. Researched Oct 13 2026.
## NowssB Coins wallet (newui_coins)
- Golden lotus coin, water ripples, floating 3D orbs, breathing glow and sparkle burst are all drawn in code
  (CustomPainter, `lib/features/coins/wallet/coins_wallet_motion.dart`). No third-party assets bundled.
- Style references only (nothing copied): Dribbble meditation concepts
  https://dribbble.com/shots/26945891--Yoga-Meditation-App, https://dribbble.com/shots/23762839-MindHub-Meditation-App-UI-Kit
## Menu & Settings (newui_menu_settings)
- No third-party assets. Backdrop is a procedural CustomPainter (original work).
