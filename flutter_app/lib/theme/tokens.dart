/// The design tokens, lifted from nowssb-nm.css and app/app.css so the
/// Flutter app is the same app rather than a lookalike.
///
/// These are the values the website actually uses — not approximations.
/// Every one of them appears verbatim in the stylesheets; the comment on
/// each says where, so when a colour changes on the web it is obvious what
/// changes here.
library;

import 'package:flutter/material.dart';

class NwsbColors {
  NwsbColors._();

  // ── The dark surface (the Fashion home, every sub-screen) ──
  /// app.css `body { background:#060c18 }`
  static const deep = Color(0xFF060C18);

  /// app.css `.sub-screen { background:#060c18 }`, `.dev-*` frame plates
  static const plate = Color(0xFF05070D);

  // ── The light surface (the Normal home) ──
  /// app.css `#home-nm { background:#f0f2f7 }` — cards and the page itself
  static const surface = Color(0xFFF0F2F7);

  /// nowssb-nm.css `html.nwsb-lightbg { background:#e4e6ed }`
  static const surfaceDim = Color(0xFFE4E6ED);

  // ── The Normal home's dark mode (#home-nm.nm-dark) ──
  static const darkBg = Color(0xFF0C0C20);
  static const darkCard = Color(0xFF16163C);

  // ── Text ──
  /// app.css `.nmh-practice-word { color:#1a1a2e }`
  static const ink = Color(0xFF1A1A2E);
  static const inkSoft = Color(0x6B000000); // rgba(0,0,0,0.42)
  static const inkFaint = Color(0x66000000); // rgba(0,0,0,0.40)

  // ── The gold. Two of them, and they are not interchangeable ──
  /// The eyebrow gold — `.nmh-practice-label`, `.nmh-brand-sub`
  static const gold = Color(0xFFC8A96E);

  /// The lighter gold used on dark surfaces — `.nmh-practice-cta` in dark
  /// mode, the nav's active label, `.nwc-next`
  static const goldLight = Color(0xFFE8D5A3);

  /// The pale blue that carries secondary copy on dark
  /// app.css `--text-secondary` / `rgba(200,232,245,…)`
  static const mist = Color(0xFFC8E8F5);
}

/// The neumorphic shadow pair. It is two shadows, never one: a dark one
/// down-right and a white one up-left. Drop either and the surface stops
/// reading as raised — which is the whole language of the Normal home.
class NwsbShadows {
  NwsbShadows._();

  /// app.css `.nmh-practice`
  /// `box-shadow: 10px 10px 26px rgba(0,0,0,.14), -7px -7px 20px rgba(255,255,255,.98)`
  static const raised = <BoxShadow>[
    BoxShadow(
      color: Color(0x24000000),
      offset: Offset(10, 10),
      blurRadius: 26,
    ),
    BoxShadow(
      color: Color(0xFAFFFFFF),
      offset: Offset(-7, -7),
      blurRadius: 20,
    ),
  ];

  /// app.css `.nmh-tile` — the same idea, one step smaller
  static const raisedSm = <BoxShadow>[
    BoxShadow(
      color: Color(0x24000000),
      offset: Offset(7, 7),
      blurRadius: 18,
    ),
    BoxShadow(
      color: Color(0xF7FFFFFF),
      offset: Offset(-5, -5),
      blurRadius: 14,
    ),
  ];

  /// app.css `.nmh-streak-icon`, `.nmh-quick-btn` — the smallest
  static const raisedXs = <BoxShadow>[
    BoxShadow(
      color: Color(0x1C000000),
      offset: Offset(5, 5),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Color(0xF2FFFFFF),
      offset: Offset(-3, -3),
      blurRadius: 9,
    ),
  ];
}

/// Corner radii, straight off the stylesheet.
class NwsbRadius {
  NwsbRadius._();
  static const card = 26.0; // .nmh-practice
  static const tile = 22.0; // .nmh-tile
  static const bar = 16.0; // .nmh-streak-bar
  static const pill = 18.0; // .nmh-practice-icon
}

class NwsbSpace {
  NwsbSpace._();

  /// app.css `.nmh-wrap { padding: 16px 20px … ; gap: 14px }`
  static const pageX = 20.0;
  static const pageTop = 16.0;
  static const gap = 14.0;
}
