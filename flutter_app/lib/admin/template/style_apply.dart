/// Applies the look overrides the UI Editor's Style tab saves. The keys:
///
///   text  color (ARGB int)  font (family name)  size  weight (100..900)
///         spacing  italic (bool)  gradient ([ARGB, ARGB, …])
///         shadow (ARGB int)  shadowBlur  shadowDx  shadowDy
///   box   shape: circle|pill|rounded|none   bg (ARGB)  bg2 (ARGB, gradient)
///         border (ARGB)  borderW  glow (ARGB)  glowBlur  glass (bool)
///         padH  padV  radius
///   orb   orb (OrbState name)  orbSize  orbCircle (bool)
///
/// Every function returns its input untouched for an empty map, so the
/// default look stays pixel-identical.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Families the Style tab offers. The first group ships with the app (or
/// the platform); the rest are Google Fonts fetched once and cached.
const kBundledFonts = <String>['Georgia', 'DM Sans', 'SF Pro Display', 'monospace'];
const kGoogleFonts = <String>[
  'DM Sans',
  'Outfit',
  'Anton',
  'Lora',
  'Libre Baskerville',
  'Noto Serif',
  'Playfair Display',
  'Cormorant Garamond',
  'Cinzel',
  'Montserrat',
  'Poppins',
  'Bebas Neue',
  'Space Grotesk',
  'Great Vibes',
];

Color? _c(dynamic v) => v is num ? Color(v.toInt()) : null;
double? _d(dynamic v) => v is num ? v.toDouble() : null;

bool hasTextLook(Map<String, dynamic> s) => s.keys.any(_textKeys.contains);
bool hasBoxLook(Map<String, dynamic> s) =>
    s['shape'] != null && s['shape'] != 'none' ||
    s.keys.any(const {'bg', 'border', 'glow', 'glass'}.contains);

const _textKeys = {
  'color', 'font', 'size', 'weight', 'spacing', 'italic', 'gradient', 'shadow',
};

FontWeight _weight(int w) {
  final i = ((w.clamp(100, 900) / 100).round() - 1).clamp(0, 8);
  return FontWeight.values[i];
}

TextStyle? applyTextLook(TextStyle? base, Map<String, dynamic> s) {
  if (!hasTextLook(s)) return base;
  var t = (base ?? const TextStyle()).copyWith(
    color: _c(s['color']),
    fontSize: _d(s['size']),
    fontWeight: s['weight'] is num ? _weight((s['weight'] as num).toInt()) : null,
    letterSpacing: _d(s['spacing']),
    fontStyle: s['italic'] == true ? FontStyle.italic : (s['italic'] == false ? FontStyle.normal : null),
    shadows: _c(s['shadow']) == null
        ? null
        : [
            Shadow(
              color: _c(s['shadow'])!,
              blurRadius: _d(s['shadowBlur']) ?? 8,
              offset: Offset(_d(s['shadowDx']) ?? 0, _d(s['shadowDy']) ?? 2),
            ),
          ],
  );
  final font = s['font'];
  if (font is String && font.isNotEmpty) {
    if (kGoogleFonts.contains(font)) {
      try {
        t = GoogleFonts.getFont(font, textStyle: t);
      } catch (_) {
        t = t.copyWith(fontFamily: font);
      }
    } else {
      t = t.copyWith(fontFamily: font);
    }
  }
  return t;
}

/// Gradient ink, then the button wrapper, around an already-styled text.
Widget applyTextDecor(Widget text, Map<String, dynamic> s) {
  var w = text;
  final g = s['gradient'];
  if (g is List && g.length >= 2) {
    final colors = [for (final c in g) if (c is num) Color(c.toInt())];
    if (colors.length >= 2) {
      w = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => LinearGradient(colors: colors).createShader(r),
        child: w,
      );
    }
  }
  return applyBoxLook(w, s);
}

/// The wrapper shape around a CTA/chip/button label.
Widget applyBoxLook(Widget child, Map<String, dynamic> s) {
  if (!hasBoxLook(s)) return child;
  final shape = '${s['shape'] ?? 'pill'}';
  final bg = _c(s['bg']);
  final bg2 = _c(s['bg2']);
  final border = _c(s['border']);
  final glow = _c(s['glow']);
  final glass = s['glass'] == true;
  final radius = shape == 'pill' || shape == 'circle'
      ? 999.0
      : (shape == 'rounded' ? (_d(s['radius']) ?? 14) : 0.0);
  final padH = _d(s['padH']) ?? (shape == 'circle' ? 12 : 16);
  final padV = _d(s['padV']) ?? (shape == 'circle' ? 12 : 8);
  final deco = BoxDecoration(
    shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
    borderRadius: shape == 'circle' ? null : BorderRadius.circular(radius),
    color: bg2 == null ? (bg ?? (glass ? const Color(0x22FFFFFF) : null)) : null,
    gradient: bg2 != null && bg != null ? LinearGradient(colors: [bg, bg2]) : null,
    border: border == null ? null : Border.all(color: border, width: _d(s['borderW']) ?? 1),
    boxShadow: glow == null
        ? null
        : [BoxShadow(color: glow, blurRadius: _d(s['glowBlur']) ?? 18, spreadRadius: 0.5)],
  );
  Widget box = Container(
    padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
    decoration: deco,
    child: child,
  );
  if (glass) {
    final clip = shape == 'circle'
        ? ClipOval(child: _blur(box))
        : ClipRRect(borderRadius: BorderRadius.circular(radius), child: _blur(box));
    box = glow == null
        ? clip
        : DecoratedBox(
            decoration: BoxDecoration(
              shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: shape == 'circle' ? null : BorderRadius.circular(radius),
              boxShadow: [BoxShadow(color: glow, blurRadius: _d(s['glowBlur']) ?? 18)],
            ),
            child: clip,
          );
  }
  return box;
}

Widget _blur(Widget c) => BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: c,
    );

/// Ready-made text looks for the Style tab's gallery. Each is a style map.
const kTextPresets = <String, Map<String, dynamic>>{
  'Gold foil': {
    'gradient': [0xFFF6E7B0, 0xFFE8D5A3, 0xFFB8904A],
    'weight': 800,
    'spacing': 0.6,
    'shadow': 0x66000000,
    'shadowBlur': 6,
  },
  'Neon mint': {
    'color': 0xFF7CFFCB,
    'weight': 700,
    'shadow': 0xCC34D399,
    'shadowBlur': 16,
    'shadowDy': 0,
  },
  'Editorial serif': {
    'font': 'Playfair Display',
    'italic': true,
    'weight': 600,
    'spacing': -0.2,
  },
  'Poster': {
    'font': 'Bebas Neue',
    'spacing': 2.4,
    'weight': 400,
  },
  'Sunset': {
    'gradient': [0xFFFF7A59, 0xFFFFC857, 0xFFFF4D8D],
    'weight': 800,
  },
  'Aurora': {
    'gradient': [0xFF7F5AF0, 0xFF2CB1FF, 0xFF34D399],
    'weight': 700,
  },
  'Soft glow': {
    'color': 0xFFFFFFFF,
    'shadow': 0xAAE8D5A3,
    'shadowBlur': 20,
    'shadowDy': 0,
  },
  'Temple': {
    'font': 'Cinzel',
    'weight': 700,
    'spacing': 1.8,
    'color': 0xFFE8D5A3,
  },
  'Handwritten': {
    'font': 'Great Vibes',
    'size': 26,
  },
  'Tech': {
    'font': 'Space Grotesk',
    'weight': 600,
    'spacing': 0.4,
    'color': 0xFF9BE7FF,
  },
  'Quiet caps': {
    'weight': 700,
    'spacing': 2.2,
    'color': 0xB3FFFFFF,
  },
  'Ruby': {
    'gradient': [0xFFFF9A9E, 0xFFE0115F],
    'weight': 800,
    'shadow': 0x55E0115F,
    'shadowBlur': 12,
  },
};

/// Ready-made button looks.
const kBoxPresets = <String, Map<String, dynamic>>{
  'Gold pill': {'shape': 'pill', 'bg': 0xFFE8D5A3, 'color': 0xFF060C18, 'weight': 700},
  'Glass pill': {'shape': 'pill', 'glass': true, 'border': 0x55FFFFFF, 'color': 0xFFFFFFFF},
  'Neon outline': {'shape': 'pill', 'border': 0xFF34D399, 'borderW': 1.5, 'glow': 0x8834D399, 'color': 0xFF7CFFCB},
  'Black chip': {'shape': 'rounded', 'bg': 0xFF000000, 'border': 0x33FFFFFF, 'color': 0xFFFFFFFF},
  'Sunset': {'shape': 'pill', 'bg': 0xFFFF7A59, 'bg2': 0xFFFF4D8D, 'color': 0xFFFFFFFF, 'weight': 700},
  'Circle': {'shape': 'circle', 'bg': 0xFF0F1828, 'border': 0x66E8D5A3},
};
