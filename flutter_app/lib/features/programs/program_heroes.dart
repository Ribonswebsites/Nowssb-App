/// Each programme's own first impression. The six programme pages share a
/// shell (back button, coin pill, tabs, Good to know) but open on a
/// different hero, art and accent so they never look like copies:
/// Earn = rank ladder, Rewards = streak flame, Coupons = scratch deck,
/// Gifts = gift box, Reference = link card, Partner = tier crown.
/// Every number is the server's (summary); nothing is invented.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../admin/template/editable.dart';
import '../../widgets/glass_wrap.dart';
import '../economy/economy_api.dart';
import 'program_kit.dart';

/// Programme accents (chips, glows, hero art).
abstract final class ProgramAccent {
  static const earn = Color(0xFF2ECC9A);
  static const rewards = Color(0xFFFFA24C);
  static const coupons = Color(0xFFE85D9A);
  static const gifts = Color(0xFFE4C56A);
  static const reference = Color(0xFF5BA8E8);
  static const partner = Color(0xFFB388FF);
}

class _HeroShell extends StatelessWidget {
  const _HeroShell({
    required this.slot,
    required this.accent,
    required this.eyebrow,
    required this.title,
    required this.line,
    required this.art,
    required this.stats,
    this.artLeft = false,
  });

  final String slot;
  final Color accent;
  final String eyebrow;
  final String title;
  final String line;
  final Widget art;
  final List<(String, String)> stats;
  final bool artLeft;

  @override
  Widget build(BuildContext context) {
    final text = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          EditableLabel(slot, eyebrow, style: TextStyle(color: accent, fontSize: 10.5, letterSpacing: 2, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          EditableLabel(slot, title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 24, height: 1.05, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          EditableLabel(slot, line, maxLines: 3, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5, height: 1.35)),
        ],
      ),
    );
    final artBox = SizedBox(width: 118, height: 118, child: art);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassWrap(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: artLeft ? Alignment.topLeft : Alignment.topRight,
              end: artLeft ? Alignment.bottomRight : Alignment.bottomLeft,
              colors: [Color.lerp(Colors.black, accent, 0.28)!, Colors.black, Colors.black],
              stops: const [0, 0.55, 1],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 26, spreadRadius: -4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: artLeft ? [artBox, const SizedBox(width: 14), text] : [text, const SizedBox(width: 10), artBox],
              ),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) Container(width: 1, height: 30, color: const Color(0x22FFFFFF)),
                      Expanded(
                        child: Column(
                          children: [
                            Text(stats[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(stats[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 10.5, letterSpacing: 0.4)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Rebuilds only the hero when the summary changes.
class _Live extends StatelessWidget {
  const _Live(this.build_);
  final Widget Function(Map<String, dynamic> s) build_;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (_, __) => build_(EconomyMirror.instance.summary),
      );
}

String _n(Object? v) => sInt(v).toString();

// ── Earn: rank ladder ───────────────────────────────────────────────
class EarnHero extends StatelessWidget {
  const EarnHero({super.key});
  @override
  Widget build(BuildContext context) => _Live((s) {
        final e = sMap(s['earn']);
        final ranks = sList(sMap(sMap(s['config'])['earn'])['ranks']);
        final title = '${e['title'] ?? (ranks.isNotEmpty ? ranks.first['title'] : 'Assistant Officer')}';
        var at = ranks.indexWhere((r) => r['title'] == title);
        if (at < 0) at = 0;
        return _HeroShell(
          slot: 'program_heroes.EarnHero',
          accent: ProgramAccent.earn,
          eyebrow: 'NOWSSB EARN',
          title: title,
          line: 'Cash on real, cleared sales through your links. Climb by words sold.',
          art: CustomPaint(painter: _LadderPainter(steps: ranks.isEmpty ? 6 : ranks.length.clamp(3, 8), at: at, color: ProgramAccent.earn)),
          stats: [(_n(e['words']), 'words sold'), (_n(e['friends']), 'friends'), ('${at + 1}/${ranks.isEmpty ? '—' : ranks.length}', 'rank')],
        );
      });
}

class _LadderPainter extends CustomPainter {
  _LadderPainter({required this.steps, required this.at, required this.color});
  final int steps;
  final int at;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / steps;
    for (var i = 0; i < steps; i++) {
      final h = size.height * (0.22 + 0.78 * (i + 1) / steps);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(i * w + 2, size.height - h, w - 4, h), const Radius.circular(5));
      final on = i <= at;
      canvas.drawRRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: on ? [color, color.withValues(alpha: 0.35)] : [const Color(0x33FFFFFF), const Color(0x0DFFFFFF)],
          ).createShader(r.outerRect),
      );
      if (i == at) {
        canvas.drawCircle(Offset(i * w + w / 2, size.height - h - 9), 5, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(i * w + w / 2, size.height - h - 9), 11, Paint()..color = color.withValues(alpha: 0.25));
      }
    }
  }

  @override
  bool shouldRepaint(_LadderPainter o) => o.at != at || o.steps != steps;
}

// ── Rewards: streak flame ───────────────────────────────────────────
class RewardsHero extends StatelessWidget {
  const RewardsHero({super.key});
  @override
  Widget build(BuildContext context) => _Live((s) {
        final w = sMap(s['wallet']);
        final t = sMap(s['today']);
        final streak = sInt(w['streak']);
        return _HeroShell(
          slot: 'program_heroes.RewardsHero',
          accent: ProgramAccent.rewards,
          eyebrow: 'NOWSSB REWARDS',
          title: streak > 0 ? '$streak-day streak' : 'Start your streak',
          line: t['login'] == true ? 'Today is counted. Come back tomorrow to keep the flame.' : 'Collect today\u2019s login below to light today.',
          artLeft: true,
          art: CustomPaint(painter: _FlamePainter(streak: streak)),
          stats: [(_n(w['coins']), 'coins'), (_n(w['bestStreak']), 'best streak'), ('${sInt(t['freeCoins'])}/${sInt(t['ceiling'])}', 'free today')],
        );
      });
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.streak});
  final int streak;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.58);
    canvas.drawCircle(c, size.width * 0.46, Paint()..shader = RadialGradient(colors: [ProgramAccent.rewards.withValues(alpha: 0.35), Colors.transparent]).createShader(Rect.fromCircle(center: c, radius: size.width * 0.46)));
    Path flame(double s) {
      final w = size.width * s, h = size.height * s;
      final b = Offset(size.width / 2, size.height * 0.92);
      return Path()
        ..moveTo(b.dx, b.dy)
        ..cubicTo(b.dx - w * 0.48, b.dy - h * 0.05, b.dx - w * 0.38, b.dy - h * 0.55, b.dx - w * 0.05, b.dy - h * 0.86)
        ..cubicTo(b.dx - w * 0.02, b.dy - h * 0.6, b.dx + w * 0.18, b.dy - h * 0.55, b.dx + w * 0.16, b.dy - h * 0.7)
        ..cubicTo(b.dx + w * 0.42, b.dy - h * 0.45, b.dx + w * 0.46, b.dy - h * 0.08, b.dx, b.dy)
        ..close();
    }
    final outer = flame(0.95);
    canvas.drawPath(outer, Paint()..shader = const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFFFF5A1F), Color(0xFFFFA24C), Color(0xFFFFE08A)]).createShader(outer.getBounds()));
    final inner = flame(0.55);
    canvas.drawPath(inner, Paint()..shader = const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFFFFF4C2), Colors.white]).createShader(inner.getBounds()));
    final tp = TextPainter(
      text: TextSpan(text: '$streak', style: const TextStyle(color: Color(0xFF7A2A00), fontWeight: FontWeight.w900, fontSize: 20)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height * 0.68 - tp.height / 2));
  }

  @override
  bool shouldRepaint(_FlamePainter o) => o.streak != streak;
}

// ── Coupons: scratch deck ───────────────────────────────────────────
class CouponsHero extends StatelessWidget {
  const CouponsHero({super.key});
  @override
  Widget build(BuildContext context) => _Live((s) {
        final cards = sList(s['scratchCards']);
        final coupons = sList(s['coupons']);
        final t = sMap(s['today']);
        return _HeroShell(
          slot: 'program_heroes.CouponsHero',
          accent: ProgramAccent.coupons,
          eyebrow: 'NOWSSB COUPONS',
          title: cards.isEmpty ? 'Your scratch deck' : '${cards.length} card${cards.length == 1 ? '' : 's'} to scratch',
          line: t['scratch'] == true ? 'Today\u2019s free card is scratched. A new one comes at midnight.' : 'One free card every day. The server draws it; scratching shows it.',
          art: CustomPaint(painter: _DeckPainter(count: cards.length)),
          stats: [(_n(cards.length), 'sealed'), (_n(coupons.length), 'discounts'), (t['scratch'] == true ? 'Done' : 'Ready', 'free card')],
        );
      });
}

class _DeckPainter extends CustomPainter {
  _DeckPainter({required this.count});
  final int count;
  @override
  void paint(Canvas canvas, Size size) {
    const colors = [Color(0xFF7C4DFF), Color(0xFFE85D9A), Color(0xFFE4C56A)];
    final c = Offset(size.width / 2, size.height * 0.56);
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate((i - 1) * 0.28);
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset((i - 1) * 6.0, 0), width: size.width * 0.52, height: size.height * 0.74), const Radius.circular(10));
      canvas.drawRRect(r.shift(const Offset(0, 4)), Paint()..color = const Color(0x66000000));
      canvas.drawRRect(r, Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colors[i], Color.lerp(colors[i], Colors.black, 0.55)!]).createShader(r.outerRect));
      if (i == 2) {
        final silver = RRect.fromRectAndRadius(r.outerRect.deflate(10), const Radius.circular(6));
        canvas.drawRRect(silver, Paint()..shader = const LinearGradient(colors: [Color(0xFFBFC3C9), Color(0xFFF2F4F7), Color(0xFF9EA3AA)]).createShader(silver.outerRect));
        final scratch = Paint()
          ..color = colors[2]
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final p = Path()
          ..moveTo(silver.left + 8, silver.top + 14)
          ..quadraticBezierTo(silver.center.dx, silver.top + 4, silver.right - 10, silver.top + 22)
          ..quadraticBezierTo(silver.center.dx, silver.center.dy, silver.left + 12, silver.center.dy + 8);
        canvas.drawPath(p, scratch);
      }
      canvas.restore();
    }
    if (count > 0) {
      canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.14), 13, Paint()..color = Colors.white);
      final tp = TextPainter(text: TextSpan(text: '$count', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(size.width * 0.86 - tp.width / 2, size.height * 0.14 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_DeckPainter o) => o.count != count;
}

// ── Gifts: gift box ─────────────────────────────────────────────────
class GiftsHero extends StatelessWidget {
  const GiftsHero({super.key});
  @override
  Widget build(BuildContext context) => _Live((s) {
        final g = sMap(s['gifts']);
        final boxes = sList(s['boxes']);
        return _HeroShell(
          slot: 'program_heroes.GiftsHero',
          accent: ProgramAccent.gifts,
          eyebrow: 'NOWSSB GIFTS',
          title: boxes.isEmpty ? 'Give the thing itself' : '${boxes.length} box${boxes.length == 1 ? '' : 'es'} waiting',
          line: 'Free boxes for time spent, a daily spin, and real gift cards you can send to a friend.',
          artLeft: true,
          art: const CustomPaint(painter: _GiftBoxPainter()),
          stats: [(_n(boxes.length), 'boxes'), (_n(sList(g['received']).length), 'received'), (_n(sList(g['sent']).length), 'sent')],
        );
      });
}

class _GiftBoxPainter extends CustomPainter {
  const _GiftBoxPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final glow = Offset(w / 2, h * 0.55);
    canvas.drawCircle(glow, w * 0.48, Paint()..shader = RadialGradient(colors: [ProgramAccent.gifts.withValues(alpha: 0.32), Colors.transparent]).createShader(Rect.fromCircle(center: glow, radius: w * 0.48)));
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.16, h * 0.44, w * 0.68, h * 0.46), const Radius.circular(8));
    final lid = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.1, h * 0.32, w * 0.8, h * 0.16), const Radius.circular(6));
    const black = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A2A2A), Color(0xFF050505)]);
    canvas.drawRRect(body, Paint()..shader = black.createShader(body.outerRect));
    canvas.drawRRect(lid, Paint()..shader = black.createShader(lid.outerRect));
    const gold = LinearGradient(colors: [Color(0xFFB8892E), Color(0xFFFFE6A0), Color(0xFFB8892E)]);
    final ribbonV = Rect.fromLTWH(w * 0.44, h * 0.32, w * 0.12, h * 0.58);
    canvas.drawRect(ribbonV, Paint()..shader = gold.createShader(ribbonV));
    final ribbonH = Rect.fromLTWH(w * 0.1, h * 0.37, w * 0.8, h * 0.06);
    canvas.drawRect(ribbonH, Paint()..shader = gold.createShader(ribbonH));
    final bow = Paint()..shader = gold.createShader(Rect.fromLTWH(w * 0.2, h * 0.08, w * 0.6, h * 0.26));
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.36, h * 0.25), width: w * 0.26, height: h * 0.15), bow);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.64, h * 0.25), width: w * 0.26, height: h * 0.15), bow);
    canvas.drawCircle(Offset(w * 0.5, h * 0.29), w * 0.06, bow);
    canvas.drawRRect(body, Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x55E4C56A));
  }

  @override
  bool shouldRepaint(_GiftBoxPainter o) => false;
}

// ── Reference: link card ────────────────────────────────────────────
class ReferenceHero extends StatelessWidget {
  const ReferenceHero({super.key});
  @override
  Widget build(BuildContext context) => _Live((s) {
        final r = sMap(s['referral']);
        final code = '${r['code'] ?? ''}';
        return _HeroShell(
          slot: 'program_heroes.ReferenceHero',
          accent: ProgramAccent.reference,
          eyebrow: 'NOWSSB REFERENCE',
          title: code.isEmpty ? 'Your personal link' : code,
          line: 'One link per word, plan or meaning. A friend\u2019s first valid link in 30 days is the one that counts.',
          art: CustomPaint(painter: _LinkPainter()),
          stats: [(_n(r['friendWordBuys']), 'friend buys'), (r['held'] == true ? 'Held' : '—', 'a link on you'), (r['locked'] == true ? 'Locked' : 'Open', 'your account')],
        );
      });
}

class _LinkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final a = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width * 0.38, size.height * 0.56), width: size.width * 0.5, height: size.height * 0.3), Radius.circular(size.height * 0.15));
    final b = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width * 0.62, size.height * 0.44), width: size.width * 0.5, height: size.height * 0.3), Radius.circular(size.height * 0.15));
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 7);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRRect(a, p..shader = const LinearGradient(colors: [Color(0xFF2B6CB0), Color(0xFF9FD3FF)]).createShader(a.outerRect));
    canvas.drawRRect(b, p..shader = const LinearGradient(colors: [Color(0xFFE6F3FF), Color(0xFF5BA8E8)]).createShader(b.outerRect));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LinkPainter o) => false;
}

// ── Partner: tier crown ─────────────────────────────────────────────
class PartnerHero extends StatelessWidget {
  const PartnerHero({super.key});
  @override
  Widget build(BuildContext context) => _Live((s) {
        final p = sMap(s['partner']);
        final perk = '${p['perk'] ?? ''}';
        return _HeroShell(
          slot: 'program_heroes.PartnerHero',
          accent: ProgramAccent.partner,
          eyebrow: 'PARTNER PROGRAM',
          title: perk.isEmpty ? 'Points become perks' : perk,
          line: 'Points come from cleared purchases by other people through your links. Perks, never cash.',
          artLeft: true,
          art: const CustomPaint(painter: _CrownPainter()),
          stats: [(_n(p['points']), 'points'), (_n(p['pending']), 'pending'), (perk.isEmpty ? '—' : 'On', 'perk')],
        );
      });
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h * 0.55);
    canvas.drawCircle(c, w * 0.48, Paint()..shader = RadialGradient(colors: [ProgramAccent.partner.withValues(alpha: 0.35), Colors.transparent]).createShader(Rect.fromCircle(center: c, radius: w * 0.48)));
    final crown = Path()
      ..moveTo(w * 0.14, h * 0.74)
      ..lineTo(w * 0.1, h * 0.34)
      ..lineTo(w * 0.32, h * 0.52)
      ..lineTo(w * 0.5, h * 0.22)
      ..lineTo(w * 0.68, h * 0.52)
      ..lineTo(w * 0.9, h * 0.34)
      ..lineTo(w * 0.86, h * 0.74)
      ..close();
    canvas.drawPath(crown, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9DDFF), Color(0xFFB388FF), Color(0xFF5B2FB0)]).createShader(crown.getBounds()));
    final band = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.14, h * 0.72, w * 0.72, h * 0.1), const Radius.circular(4));
    canvas.drawRRect(band, Paint()..color = const Color(0xFF3B1F78));
    for (final x in [0.1, 0.5, 0.9]) {
      canvas.drawCircle(Offset(w * x, x == 0.5 ? h * 0.2 : h * 0.32), w * 0.05, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_CrownPainter o) => false;
}
