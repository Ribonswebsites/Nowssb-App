# Third-party asset credits

## Gifts page and gift unwrap (assets/gifts/)
- `assets/gifts/gift_box_open_gold.json`: "Gift Box Opening Animation" by Goodeisgn via LottieFiles, https://lottiefiles.com/free-animation/gift-box-opening-animation-unvQpnOiEv. Lottie Simple License (free for commercial use). Recoloured gold.
- `assets/gifts/sparkle_stars_loop_gold.json`: "Sparkle Stars" by Ben via LottieFiles, https://lottiefiles.com/free-animation/sparkle-stars-Z4URVaAq6R. Lottie Simple License. Recoloured gold.

## Coupons page (newui_coupons)
- All Coupons art (hero coupon, ticket notches, glass) is procedural `CustomPainter`/`CustomClipper` code written for NowssB. No third-party assets bundled.
- Round 2 motion (aura glow, floating glass orbs, tilted 3D ring, staggered entrances) is procedural code in `lib/pages/coupons/coupons_motion.dart`. Ideas only from Dribbble/Mobbin/Behance/Spline-style meditation UIs; nothing copied or bundled. LottieFiles free files are under the Lottie Simple License (commercial use OK, no attribution required) but none are bundled yet.
## Earn page (newui_earn)
- Backdrop orbs: procedural CustomPainter, original code, no third-party assets.
- Icons: Flutter Material Icons (Apache 2.0).
- Polish round: 3D clay medal, floating clay spheres, light sweep, breathing progress glow, count-up numbers and staggered entrance are all procedural Flutter code (CustomPainter/tweens), original, no third-party files. Online references (Dribbble/Contra glass meditation concepts, clay medal packs) were looked at for mood only; none bundled (their licenses are premium or unclear).

## Progress page (newui_progress)
- Aura background, progress ring: procedural CustomPainter written in-repo. No third-party assets bundled.
- Polish round (Oct 13 2026): breathing 3D-style orb, floating sphere/torus/pill, milestone badges, count-up and entrance motion are all procedural Flutter code (CustomPainter/TweenAnimationBuilder). No Lottie, Rive, image, video or font assets added. Design inspiration only (no art copied): Stillwater meditation flow (swiftpieces.com), Sleek meditation template "Your Journey", Zenly on Behance, Dribbble "3D Concept - Meditation App".
## Gifts page (newui_gifts)
- Background: the app's own AppBackdrop (original background video / still). No added backgrounds.
- Card style copied from /workspace/specs/card-reference-exact.png (card only). Built in Flutter, no new files.
- Photos: existing `assets/images/circles/` (NowssB UI Design kit). Coin: existing `NwsbCoinDisc` asset. No new assets.

## Signature Words (newui_signature)
- Golden mandala loop: procedural CustomPainter (lib/pages/signature_words/mandala_painter.dart), original code, no third-party assets.
- Aura background (aura_background.dart), card tilt + shine sweep (tilt_shine.dart), shaded mandala core: procedural code, original, no third-party assets.
- Researched only (not bundled): LottieFiles free animations under the Lottie Simple License (https://lottiefiles.com/page/license); flutter_holographic (github.com/xcc3641/flutter_holographic) as a technique reference. Nothing copied.
## Profile page (newui_profile)
- Glass cards use the shared kit NGlass (lib/nowssb_ui); flag via kit NewUiGate.
- Aura backdrop (lib/pages/profile/aura_painter.dart): procedural CustomPainter, original, no third-party assets.
- 3D breathing orb with ring and moon (lib/pages/profile/breathing_orb.dart): drawn in code (lit-sphere gradients, rim light, specular highlight), original. Inspired by the general "breathing orb / glass meditation" trend (e.g. Dribbble meditation glassmorphism shots, sleek.design meditation template); nothing copied or bundled.
- Milestone badges (lib/pages/profile/milestones.dart + new_profile_page.dart): code-drawn gradients + Material Icons (Apache-2.0, bundled with Flutter).



## Partner page (newui_partner)
- Orbit rings hero: procedural CustomPainter, original code, no third-party assets.

## Rewards page (newui_rewards)
- Golden lotus coin over still water with ripples and orbiting sparkles (lib/features/rewards_newui/lotus_coin.dart), aura background, glass tiles, count-up and calm staggered reveal: procedural CustomPainter / Flutter code, original. No Lottie, Rive, image, video or font files added. Icons: Flutter Material Icons (Apache 2.0).
- Ideas only, nothing copied or bundled: Meditate app's earn-a-mandala reward loop (screensdesign.com showcase), Dribbble "streak reward" search results for layout mood. Researched Oct 13 2026.
## NowssB Coins wallet (newui_coins)
- No new art. Uses only existing app assets: the NowssB coin `assets/icons/nwsb-coin.webp` (via `NwsbCoinDisc`)
  and the original background video `assets/video/7e4d709136dc254a_grok_video_2026-07-18-15-53-02_ubjx5b.mp4`
  (+ its poster) through the shared `GlassVideoScaffold`. Earlier code-drawn coin/orbs/ripples/sparkle were removed.
## Menu & Settings (newui_menu_settings)
- No third-party assets. Backdrop is a procedural CustomPainter (original work).
