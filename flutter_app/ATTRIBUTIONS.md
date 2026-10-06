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

## Not yet traced

`assets/anim/thinking/` and `assets/anim/loaders/` (the admin orb picker's
Lottie gallery, added in c5564e52 as "NowssB gold recolor") have no source
URL or licence on record. They are not part of the editor's animation
library. Trace their origin and licence and record them here, or replace
them.
