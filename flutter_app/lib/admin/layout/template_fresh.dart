/// Thirty more banners for Admin → Templates.
///
/// Layout ideas only: a moving line, a specimen word, a paper ticket,
/// a ledger, a dial, a seal. Black, cream, gold, white. NowssB words.
/// Every string in the starter is drawn, so a tap can edit it.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'template_more.dart';
import 'template_motion.dart';

const kFreshTemplates = <String, (String, String, String)>{
  'marqueeLine': ('Moving line', 'A line of words that travels', 'Top banners'),
  'giantWord': ('Giant word', 'One word, set very large', 'Words'),
  'newsColumns': ('Field notes', 'Two short columns of type', 'Words'),
  'indexSheet': ('Word index', 'A numbered list, one row lit', 'Words'),
  'tornTicket': ('Paper ticket', 'A ticket with a torn edge and a code', 'Offers & coupons'),
  'ledgerRows': ('Price ledger', 'Names, dotted leaders, prices', 'Numbers'),
  'sealTurn': ('Turning seal', 'A round seal that turns', 'Cards'),
  'filmFrames': ('Film frames', 'Three frames with sprocket holes', 'Top banners'),
  'breathLine': ('Breathing line', 'A line that lengthens and shortens', 'Features'),
  'splitTone': ('Split tone', 'Cream over black, one moving bar', 'Picture + words'),
  'orbitRing': ('Orbit words', 'Three words travelling a ring', 'Buttons & banners'),
  'peekStack': ('Card stack', 'Three cards, the top one sliding', 'Cards'),
  'drawRule': ('Drawing rule', 'A gold line that draws itself', 'Top banners'),
  'meterPill': ('Week meter', 'A pill that fills', 'Numbers'),
  'dialFace': ('Session dial', 'A clock face with one hand', 'Numbers'),
  'ribbonSlash': ('Slash ribbon', 'A ribbon across a dark panel', 'Offers & coupons'),
  'typeSteps': ('Three verbs', 'Three words, one lit at a time', 'Features'),
  'dashedCode': ('Dashed code', 'A dashed box with the code on the right', 'Offers & coupons'),
  'arcFill': ('Arc meter', 'A half circle that fills', 'Numbers'),
  'whisperBand': ('Quiet band', 'A wide-spaced line that breathes', 'Top banners'),
  'blockFour': ('Four blocks', 'Four squares, the gold one moves', 'Cards'),
  'verticalType': ('Vertical word', 'A word set down the side', 'Words'),
  'discStack': ('Coin discs', 'Three discs that rise and settle', 'Offers & coupons'),
  'cornerNote': ('Folded note', 'A note with a folded corner', 'Cards'),
  'ruleQuote': ('Ruled quote', 'A quote beside a gold rule', 'Reviews'),
  'statSplit': ('Split number', 'A huge figure and a sentence', 'Numbers'),
  'beadPath': ('Bead path', 'A bead that walks four steps', 'Features'),
  'squareBadges': ('Four badges', 'Four small badges, one outlined', 'Features'),
  'slashPrice': ('Slashed price', 'The old figure crossed, the new one plain', 'Offers & coupons'),
  'crossMark': ('You are here', 'Two lines crossing on a word', 'Buttons & banners'),
  'letterPop': ('Letters pop', 'Each letter springs up and settles', 'Words'),
  'letterDrop': ('Letters fall', 'Letters drop in and land', 'Top banners'),
  'maskWipe': ('Mask wipe', 'A line uncovers from the left', 'Top banners'),
  'typeOn': ('Type on', 'Letters appear one after another', 'Words'),
  'flapWord': ('Flap word', 'Letters swing in like a board', 'Buttons & banners'),
  'waveType': ('Wave type', 'A wave travels along the line', 'Top banners'),
  'trackOpen': ('Open tracking', 'The letters step apart, then close', 'Words'),
  'spinColumn': ('Spin column', 'Three words turn like a drum', 'Cards'),
  'glassLine': ('Glass line', 'White type on a glass panel', 'Picture + words'),
  'scatterSet': ('Scatter set', 'Letters fly in and find their place', 'Features'),
};

const kFreshKinds = <String>[
  'marqueeLine', 'giantWord', 'newsColumns', 'indexSheet', 'tornTicket',
  'ledgerRows', 'sealTurn', 'filmFrames', 'breathLine', 'splitTone',
  'orbitRing', 'peekStack', 'drawRule', 'meterPill', 'dialFace',
  'ribbonSlash', 'typeSteps', 'dashedCode', 'arcFill', 'whisperBand',
  'blockFour', 'verticalType', 'discStack', 'cornerNote', 'ruleQuote',
  'statSplit', 'beadPath', 'squareBadges', 'slashPrice', 'crossMark',
  'letterPop', 'letterDrop', 'maskWipe', 'typeOn', 'flapWord',
  'waveType', 'trackOpen', 'spinColumn', 'glassLine', 'scatterSet',
];

bool isFreshKind(String kind) => kFreshKinds.contains(kind);

Map<String, dynamic> freshStarter(String kind) => switch (kind) {
      'marqueeLine' => {'title': 'NowssB keeps moving', 'line': 'Words · Sounds · Practice · Store'},
      'giantWord' => {'word': 'STILLNESS', 'line': 'A word you can own'},
      'newsColumns' => {'title': 'Field notes', 'left': 'Read one word slowly.', 'right': 'Then hear it once.'},
      'indexSheet' => {'title': 'Index', 'a': '01  Prana', 'b': '02  Soma', 'c': '03  Aura', 'd': '04  Pitta'},
      'tornTicket' => {'amount': '₹150', 'title': 'Off the catalogue', 'code': 'PAPER150'},
      'ledgerRows' => {'title': 'Ledger', 'a': 'Word card', 'ap': '₹199', 'b': 'Meaning', 'bp': '₹499', 'c': 'Signature', 'cp': '₹1499'},
      'sealTurn' => {'title': 'Owned once', 'line': 'Never restocked'},
      'filmFrames' => {'a': 'Morning', 'b': 'Noon', 'c': 'Night'},
      'breathLine' => {'title': 'One breath', 'line': 'In, then out'},
      'splitTone' => {'kicker': 'TODAY', 'title': 'Keep the word', 'line': 'Leave the noise'},
      'orbitRing' => {'title': 'NowssB', 'a': 'Read', 'b': 'Hear', 'c': 'Save'},
      'peekStack' => {'a': 'First card', 'b': 'Second card', 'c': 'Third card'},
      'drawRule' => {'title': 'Draw the line', 'line': 'Then begin'},
      'meterPill' => {'title': 'This week', 'value': '62%', 'line': 'Of your quiet goal'},
      'dialFace' => {'title': 'Session', 'value': '12', 'line': 'minutes'},
      'ribbonSlash' => {'title': 'This week only', 'line': 'Catalogue prices'},
      'typeSteps' => {'a': 'Pick', 'b': 'Play', 'c': 'Keep'},
      'dashedCode' => {'title': 'Your code', 'code': 'QUIET10', 'line': 'Ten percent off'},
      'arcFill' => {'title': 'Rank path', 'value': '45%', 'line': 'Toward the next rate'},
      'whisperBand' => {'line': 'WORD WITHOUT DICTIONARY'},
      'blockFour' => {'a': 'Words', 'b': 'Sounds', 'c': 'Books', 'd': 'Plans'},
      'verticalType' => {'word': 'PRANA', 'line': 'Breath, said slowly'},
      'discStack' => {'title': 'Coins', 'a': '10', 'b': '20', 'c': '50', 'line': 'Ten coins are one rupee'},
      'cornerNote' => {'title': 'A note', 'line': 'Come back tomorrow'},
      'ruleQuote' => {'body': 'Healing is a return, not a race.', 'title': 'NowssB notes'},
      'statSplit' => {'title': 'The shelf', 'value': '1,200', 'line': 'Healing words in the catalogue'},
      'beadPath' => {'title': 'The path', 'a': 'Start', 'b': 'Today', 'c': 'Again', 'd': 'Stay'},
      'squareBadges' => {'a': 'Daily', 'b': 'Offline', 'c': 'Private', 'd': 'Spoken'},
      'slashPrice' => {'title': 'Year plan', 'old': '₹2399', 'price': '₹1499', 'line': 'Same shelf, lower figure'},
      'crossMark' => {'title': 'You are here', 'line': 'The practice is open'},
      'letterPop' => {'word': 'OWN IT', 'line': 'One word at a time'},
      'letterDrop' => {'title': 'Drop in', 'line': 'Then it settles'},
      'maskWipe' => {'title': 'Read this slowly', 'line': 'The line uncovers'},
      'typeOn' => {'title': 'Type on', 'line': 'Letter after letter'},
      'flapWord' => {'word': 'STILL', 'line': 'It turns into place'},
      'waveType' => {'title': 'Wave', 'line': 'A wave along the line'},
      'trackOpen' => {'word': 'QUIET', 'line': 'The letters step apart'},
      'spinColumn' => {'title': 'Turn', 'a': 'Read', 'b': 'Hear', 'c': 'Keep'},
      'glassLine' => {'title': 'Glass type', 'line': 'Black on white'},
      'scatterSet' => {'word': 'FOCUS', 'line': 'They find their place'},
      _ => const {},
    };

const _ink = Color(0xFF14120E);
const _cream = Color(0xFFF6F1E6);
const _gold = Color(0xFFE8D5A3);
const _muted = Color(0xFF8A8175);

TextStyle _creamS(double s, {FontWeight w = FontWeight.w700, double tracking = 0}) =>
    TextStyle(color: _cream, fontSize: s, fontWeight: w, letterSpacing: tracking, height: 1.15);

TextStyle _inkS(double s, {FontWeight w = FontWeight.w700, double tracking = 0}) =>
    TextStyle(color: _ink, fontSize: s, fontWeight: w, letterSpacing: tracking, height: 1.15);

TextStyle _goldS(double s, {FontWeight w = FontWeight.w800, double tracking = 1.2}) =>
    TextStyle(color: _gold, fontSize: s, fontWeight: w, letterSpacing: tracking, height: 1.1);

Widget _loop(Widget Function(double t) builder, {int ms = 2800}) =>
    MotionLoop(milliseconds: ms, builder: builder);

enum _Kin { pop, drop, type, flap, wave, scatter }

/// Per-letter motion. The full string stays in [TplKit.label] so a tap
/// still edits it and the registry can see the words.
Widget _kin(TplKit k, String id, TextStyle style, double t, _Kin mode) {
  final text = k.s(id);
  if (text.isEmpty) return k.label(id, style);
  return ClipRect(
    child: Stack(
      alignment: Alignment.centerLeft,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < text.length; i++) _glyph(text[i], style, i, text.length, t, mode),
          ],
        ),
        k.label(id, style.copyWith(color: const Color(0x00000000))),
      ],
    ),
  );
}

Widget _glyph(String ch, TextStyle style, int i, int n, double t, _Kin mode) {
  if (ch == ' ') return const SizedBox(width: 8);
  final stagger = i / math.max(1, n);
  final local = ((t * 1.2) - stagger * 0.55).clamp(0.0, 1.0);
  final wave = math.sin((t * math.pi * 2) + i * 0.6);
  Widget child = Text(ch, style: style);
  switch (mode) {
    case _Kin.pop:
      child = Transform.scale(scale: Curves.easeOutBack.transform(local), alignment: Alignment.bottomCenter, child: child);
    case _Kin.drop:
      final y = (1 - Curves.bounceOut.transform(local)) * -26;
      child = Transform.translate(offset: Offset(0, y), child: child);
    case _Kin.type:
      child = Opacity(opacity: local > 0.12 ? 1 : 0, child: child);
    case _Kin.flap:
      final a = (1 - Curves.easeOutCubic.transform(local)) * -1.35;
      child = Transform(
        alignment: Alignment.topCenter,
        transform: Matrix4.identity()..setEntry(3, 2, 0.006)..rotateX(a),
        child: child,
      );
    case _Kin.wave:
      child = Transform.translate(offset: Offset(0, wave * 6), child: child);
    case _Kin.scatter:
      final left = 1 - Curves.easeOutCubic.transform(local);
      final dir = i.isEven ? 1.0 : -1.0;
      child = Opacity(
        opacity: local.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(dir * 16 * left, -20 * left), child: child),
      );
  }
  return child;
}

Widget _pad(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: child,
    );

Widget _panel({required Widget child, Color bg = const Color(0xFF14120E), Color? border}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border ?? const Color(0x33E8D5A3)),
    ),
    child: child,
  );
}

Widget buildFreshTemplate(String kind, TplKit k) {
  final L = k.label;
  switch (kind) {
    case 'marqueeLine':
      return _pad(_panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          L('title', _goldS(11, tracking: 1.6)),
          const SizedBox(height: 12),
          ClipRect(
            child: SizedBox(
              height: 28,
              child: _loop((t) {
                return OverflowBox(
                  maxWidth: 1400,
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(-t * 280, 0),
                    child: Row(children: [
                      for (var i = 0; i < 4; i++) ...[
                        L('line', _creamS(16, w: FontWeight.w600)),
                        const SizedBox(width: 28),
                      ],
                    ]),
                  ),
                );
              }),
            ),
          ),
        ]),
      ));
    case 'giantWord':
      return _pad(_panel(
        bg: _cream,
        border: _ink,
        child: _loop((t) {
          final track = 1 + 6 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: L('word', _inkS(54, w: FontWeight.w900, tracking: track)),
            ),
            const SizedBox(height: 8),
            Container(width: 48, height: 2, color: const Color(0xFF8A6A32)),
            const SizedBox(height: 8),
            L('line', _inkS(13, w: FontWeight.w500)),
          ]);
        }, ms: 3200),
      ));
    case 'newsColumns':
      return _pad(_panel(
        bg: _cream,
        border: const Color(0xFFD9D0C2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          L('title', _inkS(12, tracking: 2.4)),
          const SizedBox(height: 10),
          Container(height: 1, color: _ink),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: L('left', _inkS(15, w: FontWeight.w500))),
            Container(width: 1, height: 64, color: const Color(0xFFD9D0C2), margin: const EdgeInsets.symmetric(horizontal: 12)),
            Expanded(child: L('right', _inkS(15, w: FontWeight.w500))),
          ]),
        ]),
      ));
    case 'indexSheet':
      return _pad(_panel(
        bg: _cream,
        border: const Color(0xFFD9D0C2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          L('title', _inkS(11, tracking: 2.2)),
          const SizedBox(height: 8),
          _loop((t) {
            final on = (t * 4).floor() % 4;
            Widget row(int i, String id) {
              final lit = i == on;
              return Container(
                width: double.infinity,
                color: lit ? _ink : Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: L(id, TextStyle(color: lit ? _cream : _ink, fontSize: 16, fontWeight: FontWeight.w700)),
              );
            }
            return Column(children: [row(0, 'a'), row(1, 'b'), row(2, 'c'), row(3, 'd')]);
          }),
        ]),
      ));
    case 'tornTicket':
      return _pad(_panel(
        bg: _cream,
        border: _ink,
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('amount', _inkS(32, w: FontWeight.w900)),
              const SizedBox(height: 4),
              L('title', _inkS(13, w: FontWeight.w500)),
            ]),
          ),
          SizedBox(
            width: 16,
            height: 72,
            child: CustomPaint(painter: _TearPainter()),
          ),
          const SizedBox(width: 8),
          L('code', _inkS(13, w: FontWeight.w800, tracking: 0.6)),
        ]),
      ));
    case 'ledgerRows': {
      Widget line(String name, String price) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              L(name, _creamS(14, w: FontWeight.w600)),
              const Expanded(child: Text('  · · · · · · · ·', maxLines: 1, overflow: TextOverflow.clip, style: TextStyle(color: Color(0x55E8D5A3), fontSize: 12))),
              L(price, _goldS(14, tracking: 0)),
            ]),
          );
      return _pad(_panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          L('title', _goldS(11)),
          const SizedBox(height: 6),
          line('a', 'ap'),
          line('b', 'bp'),
          line('c', 'cp'),
        ]),
      ));
    }
    case 'sealTurn':
      return _pad(_panel(
        child: Row(children: [
          _loop((t) => Transform.rotate(
                angle: t * math.pi * 2,
                child: Container(
                  width: 74,
                  height: 74,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold, width: 2),
                  ),
                  child: Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold)),
                    child: Text('NW', style: _goldS(12, tracking: 1)),
                  ),
                ),
              )),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _creamS(18, w: FontWeight.w800)),
              const SizedBox(height: 4),
              L('line', _goldS(12, tracking: 0.4, w: FontWeight.w600)),
            ]),
          ),
        ]),
      ));
    case 'filmFrames': {
      Widget frame(String id) => Container(
            width: 92,
            height: 78,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1A16),
              border: Border.symmetric(
                horizontal: const BorderSide(color: _gold, width: 6),
              ),
            ),
            alignment: Alignment.center,
            child: L(id, _creamS(13)),
          );
      return _pad(ClipRect(
        child: SizedBox(
          height: 86,
          width: double.infinity,
          child: _loop((t) => OverflowBox(
                maxWidth: 520,
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  offset: Offset(-t * 40, 0),
                  child: Row(children: [frame('a'), frame('b'), frame('c')]),
                ),
              )),
        ),
      ));
    }
    case 'breathLine':
      return _pad(_panel(
        child: _loop((t) {
          final w = 0.25 + 0.7 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            L('title', _creamS(18)),
            const SizedBox(height: 12),
            FractionallySizedBox(
              widthFactor: w,
              child: Container(height: 3, color: _gold),
            ),
            const SizedBox(height: 10),
            L('line', _goldS(12, tracking: 0.6, w: FontWeight.w600)),
          ]);
        }, ms: 3600),
      ));
    case 'splitTone':
      return _pad(ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: [
          Container(
            width: double.infinity,
            color: _cream,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('kicker', _inkS(11, tracking: 2)),
              const SizedBox(height: 4),
              L('title', _inkS(26, w: FontWeight.w900)),
            ]),
          ),
          _loop((t) => Container(height: 3, color: _gold, alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: t, child: const ColoredBox(color: _ink)))),
          Container(
            width: double.infinity,
            color: _ink,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: L('line', _creamS(16, w: FontWeight.w500)),
          ),
        ]),
      ));
    case 'orbitRing':
      return _pad(_panel(
        child: SizedBox(
          height: 150,
          child: _loop((t) {
            const ids = ['a', 'b', 'c'];
            return Stack(alignment: Alignment.center, children: [
              Container(width: 116, height: 116, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x55E8D5A3)))),
              L('title', _goldS(13)),
              for (var i = 0; i < 3; i++)
                Transform.translate(
                  offset: Offset(58 * math.cos(t * math.pi * 2 + i * 2.1), 58 * math.sin(t * math.pi * 2 + i * 2.1)),
                  child: L(ids[i], _creamS(13)),
                ),
            ]);
          }),
        ),
      ));
    case 'peekStack':
      return _pad(SizedBox(
        height: 132,
        child: _loop((t) {
          final shift = 8 * math.sin(t * math.pi * 2);
          Widget card(String id, double dy, Color bg, TextStyle style) => Positioned(
                left: 24,
                right: 24,
                top: dy,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x33E8D5A3))),
                  child: L(id, style),
                ),
              );
          return Stack(children: [
            card('c', 48, const Color(0xFF2A261F), _creamS(14)),
            card('b', 26, const Color(0xFF1C1A16), _creamS(14)),
            card('a', 4 + shift, _cream, _inkS(16)),
          ]);
        }),
      ));
    case 'drawRule':
      return _pad(_panel(
        bg: _cream,
        border: _ink,
        child: _loop((t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _inkS(28, w: FontWeight.w900)),
              const SizedBox(height: 8),
              FractionallySizedBox(widthFactor: 0.15 + 0.85 * t, child: Container(height: 3, color: const Color(0xFF8A6A32))),
              const SizedBox(height: 8),
              L('line', _inkS(14, w: FontWeight.w500)),
            ]), ms: 2400),
      ));
    case 'meterPill':
      return _pad(_panel(
        child: _loop((t) {
          final v = 0.2 + 0.65 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: L('title', _creamS(16))),
              L('value', _goldS(16, tracking: 0)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 14,
                child: Stack(fit: StackFit.expand, children: [
                  const ColoredBox(color: Color(0xFF2A261F)),
                  FractionallySizedBox(widthFactor: v, alignment: Alignment.centerLeft, child: const ColoredBox(color: _gold)),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            L('line', _creamS(12, w: FontWeight.w500)),
          ]);
        }),
      ));
    case 'dialFace':
      return _pad(_panel(
        child: Row(children: [
          SizedBox(
            width: 92,
            height: 92,
            child: _loop((t) => CustomPaint(
                  painter: _DialPainter(t),
                  child: Center(child: L('value', _goldS(18, tracking: 0))),
                )),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _creamS(16)),
              L('line', _goldS(13, tracking: 0.4, w: FontWeight.w600)),
            ]),
          ),
        ]),
      ));
    case 'ribbonSlash':
      return _pad(ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: _ink,
          child: SizedBox(
            height: 96,
            child: Stack(children: [
              Positioned(
                left: -20,
                right: -20,
                top: 28,
                child: Transform.rotate(
                  angle: -0.12,
                  child: Container(
                    color: _gold,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: L('title', _inkS(16, w: FontWeight.w900), align: TextAlign.center),
                  ),
                ),
              ),
              Positioned(left: 16, bottom: 8, child: L('line', _creamS(12, w: FontWeight.w500))),
            ]),
          ),
        ),
      ));
    case 'typeSteps':
      return _pad(_panel(
        bg: _cream,
        border: _ink,
        child: _loop((t) {
          final on = (t * 3).floor() % 3;
          Widget bit(int i, String id) {
            final lit = i == on;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                color: lit ? _ink : Colors.transparent,
                child: L(id, TextStyle(color: lit ? _cream : _ink, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            );
          }
          return Row(children: [bit(0, 'a'), bit(1, 'b'), bit(2, 'c')]);
        }),
      ));
    case 'dashedCode':
      return _pad(Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _ink, width: 1.4),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _inkS(12, tracking: 1.2)),
              const SizedBox(height: 4),
              L('line', _inkS(13, w: FontWeight.w500)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(border: Border.all(color: _ink)),
            child: L('code', _inkS(14, w: FontWeight.w900, tracking: 0.8)),
          ),
        ]),
      ));
    case 'arcFill':
      return _pad(_panel(
        child: Row(children: [
          SizedBox(
            width: 110,
            height: 70,
            child: _loop((t) => CustomPaint(painter: _ArcPainter(0.25 + 0.6 * t))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _creamS(14)),
              L('value', _goldS(22, tracking: 0)),
              L('line', _creamS(12, w: FontWeight.w500)),
            ]),
          ),
        ]),
      ));
    case 'whisperBand':
      return _pad(_loop((t) {
        final fade = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
        return Opacity(
          opacity: fade,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: L('line', _creamS(13, w: FontWeight.w600, tracking: 3.2), align: TextAlign.center),
          ),
        );
      }, ms: 4000));
    case 'blockFour':
      return _pad(_loop((t) {
        final on = (t * 4).floor() % 4;
        Widget block(int i, String id) {
          final lit = i == on;
          return Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.all(4),
                alignment: Alignment.center,
                color: lit ? _gold : _ink,
                child: L(id, TextStyle(color: lit ? _ink : _cream, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          );
        }
        return Column(children: [
          Row(children: [block(0, 'a'), block(1, 'b')]),
          Row(children: [block(2, 'c'), block(3, 'd')]),
        ]);
      }));
    case 'verticalType':
      return _pad(_panel(
        bg: _cream,
        border: _ink,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RotatedBox(quarterTurns: 3, child: L('word', _inkS(18, w: FontWeight.w900, tracking: 4))),
          const SizedBox(width: 12),
          Container(width: 2, height: 88, color: const Color(0xFF8A6A32)),
          const SizedBox(width: 12),
          Expanded(child: L('line', _inkS(16, w: FontWeight.w500))),
        ]),
      ));
    case 'discStack':
      return _pad(_panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          L('title', _goldS(11)),
          const SizedBox(height: 8),
          _loop((t) {
            final bob = 6 * math.sin(t * math.pi * 2);
            Widget disc(String id, double dy) => Transform.translate(
                  offset: Offset(0, dy),
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold, width: 2), color: const Color(0xFF1A140C)),
                    child: L(id, _goldS(16, tracking: 0)),
                  ),
                );
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(children: [disc('a', bob), disc('b', -bob), disc('c', bob * 0.5)]),
            );
          }),
          const SizedBox(height: 8),
          L('line', _creamS(12, w: FontWeight.w500)),
        ]),
      ));
    case 'cornerNote':
      return _pad(ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: ColoredBox(
          color: _cream,
          child: SizedBox(
            height: 110,
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 36, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  L('title', _inkS(20, w: FontWeight.w800)),
                  const SizedBox(height: 6),
                  L('line', _inkS(14, w: FontWeight.w500)),
                ]),
              ),
              const Positioned(
                right: 0,
                top: 0,
                child: CustomPaint(size: Size(28, 28), painter: _FoldPainter()),
              ),
            ]),
          ),
        ),
      ));
    case 'ruleQuote':
      return _pad(_panel(
        bg: _cream,
        border: const Color(0xFFD9D0C2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 3, height: 72, color: const Color(0xFF8A6A32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('body', _inkS(18, w: FontWeight.w600)),
              const SizedBox(height: 8),
              L('title', _inkS(12, tracking: 1.1, w: FontWeight.w700)),
            ]),
          ),
        ]),
      ));
    case 'statSplit':
      return _pad(_panel(
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          L('value', _goldS(36, tracking: 0, w: FontWeight.w900)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _creamS(12, tracking: 1.4)),
              const SizedBox(height: 4),
              L('line', _creamS(13, w: FontWeight.w500)),
            ]),
          ),
        ]),
      ));
    case 'beadPath':
      return _pad(_panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          L('title', _goldS(11)),
          const SizedBox(height: 12),
          _loop((t) {
            final on = (t * 4).floor() % 4;
            const ids = ['a', 'b', 'c', 'd'];
            return Row(children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Column(children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == on ? _gold : const Color(0xFF2A261F),
                        border: Border.all(color: _gold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    L(ids[i], _creamS(11, w: FontWeight.w600), align: TextAlign.center, maxLines: 1),
                  ]),
                ),
            ]);
          }),
        ]),
      ));
    case 'squareBadges':
      return _pad(_loop((t) {
        final on = (t * 4).floor() % 4;
        const ids = ['a', 'b', 'c', 'd'];
        return Row(children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: i == on ? _gold : const Color(0x33FFFFFF), width: i == on ? 1.6 : 1),
                ),
                child: L(ids[i], _creamS(12), align: TextAlign.center, maxLines: 1),
              ),
            ),
        ]);
      }));
    case 'slashPrice':
      return _pad(_panel(
        bg: _cream,
        border: _ink,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          L('title', _inkS(12, tracking: 1.6)),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Stack(alignment: Alignment.center, children: [
              L('old', TextStyle(color: _muted, fontSize: 18, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough, decorationColor: _ink)),
            ]),
            const SizedBox(width: 12),
            L('price', _inkS(32, w: FontWeight.w900)),
          ]),
          const SizedBox(height: 6),
          L('line', _inkS(13, w: FontWeight.w500)),
        ]),
      ));
    case 'crossMark':
      return _pad(SizedBox(
        height: 120,
        width: double.infinity,
        child: _loop((t) {
          final s = 0.85 + 0.15 * math.sin(t * math.pi * 2);
          return Stack(fit: StackFit.expand, children: [
            CustomPaint(painter: _CrossPainter(s)),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                L('title', _creamS(20, w: FontWeight.w800)),
                const SizedBox(height: 4),
                L('line', _goldS(12, tracking: 0.4, w: FontWeight.w600)),
              ]),
            ),
          ]);
        }),
      ));
    case 'letterPop':
      return _pad(_panel(
        child: _loop((t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _kin(k, 'word', _creamS(36, w: FontWeight.w900), t, _Kin.pop),
          const SizedBox(height: 8),
          L('line', _goldS(12, tracking: 0.6, w: FontWeight.w600)),
        ])),
      ));
    case 'letterDrop':
      return _pad(_panel(
        bg: _cream,
        border: _ink,
        child: _loop((t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _kin(k, 'title', _inkS(34, w: FontWeight.w900), t, _Kin.drop),
          const SizedBox(height: 8),
          L('line', _inkS(13, w: FontWeight.w500)),
        ])),
      ));
    case 'maskWipe':
      return _pad(_panel(
        bg: Colors.white,
        border: _ink,
        child: _loop((t) {
          final reveal = t < 0.62 ? (t / 0.62) : 1.0;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: reveal.clamp(0.04, 1.0),
                child: L('title', _inkS(26, w: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
            L('line', _inkS(13, w: FontWeight.w500)),
          ]);
        }),
      ));
    case 'typeOn':
      return _pad(_panel(
        child: _loop((t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _kin(k, 'title', _creamS(32, w: FontWeight.w800), t, _Kin.type),
          const SizedBox(height: 8),
          L('line', _creamS(13, w: FontWeight.w500)),
        ]), ms: 2200),
      ));
    case 'flapWord':
      return _pad(_panel(
        child: _loop((t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _kin(k, 'word', _creamS(36, w: FontWeight.w900, tracking: 2), t, _Kin.flap),
          const SizedBox(height: 8),
          L('line', _goldS(12, tracking: 0.4, w: FontWeight.w600)),
        ])),
      ));
    case 'waveType':
      return _pad(_panel(
        bg: Colors.white,
        border: _ink,
        child: _loop((t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          L('title', _inkS(11, tracking: 2.2)),
          const SizedBox(height: 6),
          _kin(k, 'line', _inkS(22, w: FontWeight.w800), t, _Kin.wave),
        ])),
      ));
    case 'trackOpen':
      return _pad(_panel(
        child: _loop((t) {
          final open = 1 + 10 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: L('word', _creamS(34, w: FontWeight.w900, tracking: open)),
            ),
            const SizedBox(height: 8),
            L('line', _goldS(12, tracking: 0.4, w: FontWeight.w600)),
          ]);
        }),
      ));
    case 'spinColumn':
      return _pad(_panel(
        child: _loop((t) {
          const row = 42.0;
          final shift = (t * 3) * row;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            L('title', _goldS(11)),
            const SizedBox(height: 8),
            ClipRect(
              child: SizedBox(
                height: row,
                width: double.infinity,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minHeight: row * 4,
                  maxHeight: row * 4,
                  child: Transform.translate(
                    offset: Offset(0, -shift),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      for (final id in ['a', 'b', 'c', 'a'])
                        SizedBox(height: row, child: Align(alignment: Alignment.centerLeft, child: L(id, _creamS(28, w: FontWeight.w900)))),
                    ]),
                  ),
                ),
              ),
            ),
          ]);
        }, ms: 3200),
      ));
    case 'glassLine':
      return _pad(ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            decoration: BoxDecoration(
              color: const Color(0xE8FFFFFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF14120E)),
            ),
            child: _loop((t) {
              final y = math.sin(t * math.pi * 2) * 3;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Transform.translate(offset: Offset(0, y), child: L('title', _inkS(30, w: FontWeight.w800))),
                const SizedBox(height: 6),
                L('line', _inkS(14, w: FontWeight.w700)),
              ]);
            }),
          ),
        ),
      ));
    case 'scatterSet':
      return _pad(_panel(
        bg: Colors.white,
        border: _ink,
        child: _loop((t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _kin(k, 'word', _inkS(34, w: FontWeight.w900), t, _Kin.scatter),
          const SizedBox(height: 10),
          L('line', _inkS(13, w: FontWeight.w500)),
        ])),
      ));
    default:
      return const SizedBox.shrink();
  }
}

class _TearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _ink
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    for (var y = 0.0; y < size.height; y += 8) {
      path.lineTo(y % 16 == 0 ? 0 : size.width, y);
    }
    path.lineTo(size.width / 2, size.height);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 2;
    final ring = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(c, r, ring);
    final ang = -math.pi / 2 + t * math.pi * 2;
    final hand = Paint()
      ..color = _cream
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, c + Offset(math.cos(ang), math.sin(ang)) * (r - 10), hand);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) => oldDelegate.t != t;
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(4, 4, size.width - 8, (size.width - 8));
    final bg = Paint()
      ..color = const Color(0xFF2A261F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, bg);
    canvas.drawArc(rect, math.pi, math.pi * v.clamp(0.0, 1.0), false, fg);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) => oldDelegate.v != v;
}

class _FoldPainter extends CustomPainter {
  const _FoldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fold = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(fold, Paint()..color = const Color(0xFF8A6A32));
    final back = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(back, Paint()..color = const Color(0xFFE4D8C4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrossPainter extends CustomPainter {
  _CrossPainter(this.scale);
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x55E8D5A3)
      ..strokeWidth = 1;
    final c = Offset(size.width / 2, size.height / 2);
    final h = 36.0 * scale;
    canvas.drawLine(Offset(c.dx - h, c.dy), Offset(c.dx + h, c.dy), p);
    canvas.drawLine(Offset(c.dx, c.dy - 28 * scale), Offset(c.dx, c.dy + 28 * scale), p);
    canvas.drawCircle(c, 22 * scale, Paint()..color = const Color(0x22E8D5A3)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _CrossPainter oldDelegate) => oldDelegate.scale != scale;
}
