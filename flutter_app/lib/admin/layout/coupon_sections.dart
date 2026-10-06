/// Coupon template sections for the UI Editor (Layout → Add section):
///
///   couponTicket  — wide ticket coupons stacked one under another: dashed
///                   cut line with side notches, scissors, a big amount on
///                   the left, headline / ribbon / code / expiry on the
///                   right and a vertical barcode at the far end.
///   couponCards   — portrait coupon cards two side by side: coloured
///                   ribbon tag, huge amount, a code box, terms, barcode
///                   and expiry.
///
/// Plain white background, dark ink — no waves, gradients or glows. Every
/// word, code and colour comes from the entry's props (edited in the
/// editor's Content tab), so nothing here is hard-coded copy.
///
/// props: coupons: [ {amount, unit, note, headline, ribbon, body, codeLabel,
///                    code, expiry, barcode, tag, tagColor (ARGB)} … ],
///        ink (ARGB, optional), height (optional, scales the section)
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kCouponInk = 0xFF111111;
const kCouponRed = 0xFFD71920;
const kCouponYellow = 0xFFF5C518;

/// Starting props for the two coupon templates.
Map<String, dynamic> couponStarter(String kind) => switch (kind) {
      'couponTicket' => {
          'coupons': [
            {
              'amount': '20%',
              'unit': 'OFF',
              'note': '',
              'headline': 'DISCOUNT COUPON',
              'ribbon': '20% OFF YOUR PURCHASE',
              'body': 'Valid on all items storewide.',
              'codeLabel': 'CODE:',
              'code': 'SAVE20',
              'expiry': 'EXPIRES: 06/30/2025',
              'barcode': '102030405060',
            },
            {
              'amount': r'$10',
              'unit': 'OFF',
              'note': r'ON ORDERS OF $50 OR MORE',
              'headline': 'SAVE MORE',
              'ribbon': r'TAKE $10 OFF TODAY!',
              'body': '',
              'codeLabel': 'CODE:',
              'code': 'TENOFF',
              'expiry': 'EXPIRES: 06/30/2025',
              'barcode': '506040302010',
            },
          ],
        },
      'couponCards' => {
          'coupons': [
            {
              'tag': 'LIMITED TIME OFFER!',
              'tagColor': kCouponRed,
              'amount': '20%',
              'unit': 'OFF',
              'note': 'YOUR NEXT PURCHASE',
              'codeLabel': 'COUPON CODE:',
              'code': 'SAVE20',
              'body': 'Valid in-store & online. Exclusions apply.\nSee back for details.',
              'barcode': '102938475620',
              'expiry': 'EXPIRES: 06/30/2025',
            },
            {
              'tag': 'SPECIAL OFFER!',
              'tagColor': kCouponYellow,
              'amount': r'$10',
              'unit': 'OFF',
              'note': r'WHEN YOU SPEND $50 OR MORE',
              'codeLabel': 'COUPON CODE:',
              'code': 'SAVE10',
              'body': 'Valid in-store & online. Exclusions apply.\nSee back for details.',
              'barcode': '847392756103',
              'expiry': 'EXPIRES: 06/30/2025',
            },
          ],
        },
      _ => const {},
    };

/// The per-coupon fields the Content tab offers, in order: (key, label, lines).
List<(String, String, int)> couponFields(String kind) => kind == 'couponCards'
    ? const [
        ('tag', 'Ribbon words', 1),
        ('amount', 'Amount (e.g. 20% or \$10)', 1),
        ('unit', 'Next to the amount (e.g. OFF)', 1),
        ('note', 'Line under the amount', 1),
        ('codeLabel', 'Code label', 1),
        ('code', 'Coupon code', 1),
        ('body', 'Terms', 3),
        ('barcode', 'Barcode number', 1),
        ('expiry', 'Expiry line', 1),
      ]
    : const [
        ('amount', 'Amount (e.g. 20% or \$10)', 1),
        ('unit', 'Next to the amount (e.g. OFF)', 1),
        ('note', 'Line under the amount (optional)', 1),
        ('headline', 'Headline', 1),
        ('ribbon', 'Ribbon words', 1),
        ('body', 'Small description (optional)', 2),
        ('codeLabel', 'Code label', 1),
        ('code', 'Coupon code', 1),
        ('expiry', 'Expiry line', 1),
        ('barcode', 'Barcode number', 1),
      ];

/// A blank coupon added from the Content tab.
Map<String, dynamic> couponBlank(String kind, int index) {
  final list = couponStarter(kind)['coupons'] as List;
  return Map<String, dynamic>.from(list[index % list.length] as Map);
}

List<Map<String, dynamic>> couponsOf(Map<String, dynamic> props) => props['coupons'] is List
    ? [for (final m in props['coupons'] as List) if (m is Map) Map<String, dynamic>.from(m)]
    : <Map<String, dynamic>>[];

Color _readableOn(Color bg) =>
    ThemeData.estimateBrightnessForColor(bg) == Brightness.dark ? Colors.white : const Color(kCouponInk);

void _copyCode(BuildContext context, String code) {
  if (code.trim().isEmpty) return;
  Clipboard.setData(ClipboardData(text: code.trim()));
  HapticFeedback.selectionClick();
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
    content: Text('Code ${code.trim()} copied'),
  ));
}

/// The coupon section itself (both kinds), on plain white.
class CouponSection extends StatelessWidget {
  const CouponSection({super.key, required this.kind, required this.props});
  final String kind;
  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final coupons = couponsOf(props);
    final ink = Color(props['ink'] is num ? (props['ink'] as num).toInt() : kCouponInk);
    Widget body;
    if (coupons.isEmpty) {
      body = const SizedBox(height: 40);
    } else if (kind == 'couponCards') {
      final rows = <Widget>[];
      for (var i = 0; i < coupons.length; i += 2) {
        rows.add(Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: CouponCard(data: coupons[i], ink: ink)),
            const SizedBox(width: 12),
            Expanded(child: i + 1 < coupons.length ? CouponCard(data: coupons[i + 1], ink: ink) : const SizedBox()),
          ]),
        ));
      }
      body = Column(mainAxisSize: MainAxisSize.min, children: rows);
    } else {
      body = Column(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < coupons.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: CouponTicket(data: coupons[i], ink: ink, scissorsAtEnd: i.isOdd),
          ),
      ]);
    }
    final h = props['height'] is num ? (props['height'] as num).toDouble() : null;
    if (h != null && h > 0) {
      // Pinched in the editor: the whole block scales to the chosen height.
      body = SizedBox(
        height: h,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(width: MediaQuery.sizeOf(context).width - 32, child: body),
        ),
      );
    }
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: body,
    );
  }
}

String _s(Map<String, dynamic> m, String k) => '${m[k] ?? ''}';

// ── Ticket ───────────────────────────────────────────────────────────

class CouponTicket extends StatelessWidget {
  const CouponTicket({super.key, required this.data, this.ink = const Color(kCouponInk), this.scissorsAtEnd = false});
  final Map<String, dynamic> data;
  final Color ink;
  final bool scissorsAtEnd;

  static const _w = 460.0;
  static const _h = 168.0;

  @override
  Widget build(BuildContext context) {
    final code = _s(data, 'code');
    final ribbon = _s(data, 'ribbon');
    final body = _s(data, 'body');
    final note = _s(data, 'note');
    final accent = data['tagColor'] is num ? Color((data['tagColor'] as num).toInt()) : ink;
    final ticket = SizedBox(
      width: _w,
      height: _h,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: CustomPaint(painter: _TicketBorderPainter(color: ink))),
        Positioned(
          left: scissorsAtEnd ? null : 4,
          right: scissorsAtEnd ? 4 : null,
          top: scissorsAtEnd ? null : -10,
          bottom: scissorsAtEnd ? -10 : null,
          child: _Scissors(color: ink, flip: scissorsAtEnd),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 22, 16),
          child: Row(children: [
            // Amount
            Expanded(
              flex: 9,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _Amount(amount: _s(data, 'amount'), unit: _s(data, 'unit'), ink: ink, size: 92),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(note.toUpperCase(),
                        style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                  ],
                ]),
              ),
            ),
            Container(width: 1.4, margin: const EdgeInsets.symmetric(horizontal: 14), color: ink),
            // Words
            Expanded(
              flex: 10,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 210,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_s(data, 'headline'),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(color: ink, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5, height: 1.05)),
                    ),
                    if (ribbon.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      FittedBox(fit: BoxFit.scaleDown, child: CouponRibbon(text: ribbon, color: accent, fontSize: 12.5)),
                    ],
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(body,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(color: ink.withValues(alpha: 0.85), fontSize: 10.5)),
                    ],
                    if (code.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      GestureDetector(
                        onTap: () => _copyCode(context, code),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(border: Border.all(color: ink, width: 1.4)),
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: '${_s(data, 'codeLabel')}  ', style: const TextStyle(fontWeight: FontWeight.w500)),
                              TextSpan(text: code, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                            ]),
                            style: TextStyle(color: ink, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    if (_s(data, 'expiry').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(_s(data, 'expiry'), style: TextStyle(color: ink.withValues(alpha: 0.85), fontSize: 9.5, letterSpacing: 0.4)),
                    ],
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Vertical barcode with its number.
            SizedBox(
              height: 120,
              child: RotatedBox(
                quarterTurns: 3,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 120, height: 30, child: CustomPaint(painter: BarcodePainter(seed: _s(data, 'barcode'), color: ink))),
                  const SizedBox(height: 2),
                  Text(_s(data, 'barcode'), style: TextStyle(color: ink, fontSize: 9, letterSpacing: 1.2)),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AspectRatio(
        aspectRatio: _w / _h,
        child: FittedBox(fit: BoxFit.contain, child: ticket),
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────

class CouponCard extends StatelessWidget {
  const CouponCard({super.key, required this.data, this.ink = const Color(kCouponInk)});
  final Map<String, dynamic> data;
  final Color ink;

  static const _w = 240.0;
  static const _h = 336.0;

  @override
  Widget build(BuildContext context) {
    final tagColor = Color(data['tagColor'] is num ? (data['tagColor'] as num).toInt() : kCouponRed);
    final code = _s(data, 'code');
    final note = _s(data, 'note');
    final tag = _s(data, 'tag');
    final body = _s(data, 'body');
    final card = SizedBox(
      width: _w,
      height: _h,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: CustomPaint(painter: _DashedRRectPainter(color: ink, radius: 12))),
        Positioned(left: -2, top: -12, child: _Scissors(color: ink)),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
          child: Column(children: [
            if (tag.isNotEmpty) CouponRibbon(text: tag, color: tagColor, fontSize: 12),
            const SizedBox(height: 4),
            SizedBox(
              height: 84,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _Amount(amount: _s(data, 'amount'), unit: _s(data, 'unit'), ink: ink, size: 84),
              ),
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: Container(height: 1.2, color: ink)),
                Flexible(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(note.toUpperCase(),
                          style: TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1.2, color: ink)),
              ]),
            ],
            const SizedBox(height: 10),
            if (code.isNotEmpty)
              GestureDetector(
                onTap: () => _copyCode(context, code),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: ink, width: 1.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_s(data, 'codeLabel'), style: TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      Text(code,
                          style: TextStyle(
                            // Yellow on white is unreadable: darken light ribbon colours for the code.
                            color: _codeInk(tagColor),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          )),
                    ]),
                  ),
                ),
              ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Flexible(
                child: Text(body,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink.withValues(alpha: 0.85), fontSize: 9.5, height: 1.3)),
              ),
            ],
            const Spacer(),
            if (_s(data, 'barcode').isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 3),
                decoration: BoxDecoration(
                  border: Border.all(color: ink.withValues(alpha: 0.35), width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(children: [
                  SizedBox(height: 26, width: double.infinity, child: CustomPaint(painter: BarcodePainter(seed: _s(data, 'barcode'), color: ink))),
                  const SizedBox(height: 2),
                  Text(_s(data, 'barcode'), style: TextStyle(color: ink, fontSize: 9, letterSpacing: 1.4)),
                ]),
              ),
            if (_s(data, 'expiry').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(_s(data, 'expiry'), style: TextStyle(color: ink, fontSize: 9.5, letterSpacing: 0.4)),
            ],
          ]),
        ),
      ]),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: AspectRatio(
        aspectRatio: _w / _h,
        child: FittedBox(fit: BoxFit.contain, child: card),
      ),
    );
  }

  static Color _codeInk(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.lightness > 0.45 && ThemeData.estimateBrightnessForColor(c) == Brightness.light
        ? hsl.withLightness(0.42).toColor()
        : c;
  }
}

// ── Parts ────────────────────────────────────────────────────────────

/// "20%" huge with "OFF" beside it, bottom-aligned.
class _Amount extends StatelessWidget {
  const _Amount({required this.amount, required this.unit, required this.ink, required this.size});
  final String amount;
  final String unit;
  final Color ink;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(amount,
          style: TextStyle(color: ink, fontSize: size, fontWeight: FontWeight.w900, height: 0.95, letterSpacing: -2)),
      if (unit.isNotEmpty) ...[
        const SizedBox(width: 4),
        Padding(
          padding: EdgeInsets.only(bottom: size * 0.06),
          child: Text(unit,
              style: TextStyle(color: ink, fontSize: size * 0.38, fontWeight: FontWeight.w900, height: 1)),
        ),
      ],
    ]);
  }
}

class _Scissors extends StatelessWidget {
  const _Scissors({required this.color, this.flip = false});
  final Color color;
  final bool flip;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Transform.rotate(
          angle: flip ? math.pi : 0,
          child: Icon(Icons.content_cut_rounded, color: color, size: 22),
        ),
      );
}

/// A banner ribbon: a filled band with V-cut ends.
class CouponRibbon extends StatelessWidget {
  const CouponRibbon({super.key, required this.text, required this.color, this.fontSize = 12});
  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RibbonPainter(color),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: fontSize * 1.6, vertical: fontSize * 0.42),
        child: Text(text,
            maxLines: 1,
            style: TextStyle(color: _readableOn(color), fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final cut = s.height * 0.38;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width - cut, s.height / 2)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..lineTo(cut, s.height / 2)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.color != color;
}

Path _dashed(Path source, {double dash = 7, double gap = 5}) {
  final out = Path();
  for (final m in source.computeMetrics()) {
    var d = 0.0;
    while (d < m.length) {
      out.addPath(m.extractPath(d, math.min(d + dash, m.length)), Offset.zero);
      d += dash + gap;
    }
  }
  return out;
}

/// Ticket outline: rounded corners, a half-circle notch in the middle of
/// each short side, drawn as a dashed cut line.
class _TicketBorderPainter extends CustomPainter {
  _TicketBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    const r = 14.0;
    const notch = 13.0;
    final my = s.height / 2;
    final p = Path()
      ..moveTo(r, 0)
      ..lineTo(s.width - r, 0)
      ..arcToPoint(Offset(s.width, r), radius: const Radius.circular(r))
      ..lineTo(s.width, my - notch)
      ..arcToPoint(Offset(s.width, my + notch), radius: const Radius.circular(notch), clockwise: false)
      ..lineTo(s.width, s.height - r)
      ..arcToPoint(Offset(s.width - r, s.height), radius: const Radius.circular(r))
      ..lineTo(r, s.height)
      ..arcToPoint(Offset(0, s.height - r), radius: const Radius.circular(r))
      ..lineTo(0, my + notch)
      ..arcToPoint(Offset(0, my - notch), radius: const Radius.circular(notch), clockwise: false)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..close();
    canvas.drawPath(
      _dashed(p),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TicketBorderPainter old) => old.color != color;
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, this.radius = 12});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(radius)));
    canvas.drawPath(
      _dashed(p),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) => old.color != color || old.radius != radius;
}

/// A decorative barcode: bar widths derived from [seed], so the same
/// number always draws the same bars. Not a scannable symbology.
class BarcodePainter extends CustomPainter {
  BarcodePainter({required this.seed, required this.color});
  final String seed;
  final Color color;

  List<int> get _pattern {
    final src = seed.isEmpty ? '0' : seed;
    final out = <int>[1, 1, 1, 1]; // guard
    var h = 7;
    for (final c in src.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
      for (var k = 0; k < 4; k++) {
        out.add(1 + ((h >> (k * 3)) % 3));
      }
    }
    out.addAll(const [1, 1, 1, 1]);
    return out;
  }

  @override
  void paint(Canvas canvas, Size s) {
    final pat = _pattern;
    final units = pat.fold<int>(0, (a, b) => a + b);
    final u = s.width / units;
    final paint = Paint()..color = color;
    var x = 0.0;
    for (var i = 0; i < pat.length; i++) {
      final w = pat[i] * u;
      if (i.isEven) canvas.drawRect(Rect.fromLTWH(x, 0, w, s.height), paint);
      x += w;
    }
  }

  @override
  bool shouldRepaint(BarcodePainter old) => old.seed != seed || old.color != color;
}
