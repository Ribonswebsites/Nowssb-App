/// Drop Studio v4 — ROUGH concepts for review (not wired, not polished).
///
/// "Make this home yours" (replaces the arched four doors):
///   A [DoorsFoldingScreen]  4-panel lacquer folding screen, tap to unfold
///   B [DoorsPrism]          turning 4-face prism, one setting per face
///   C [DoorsTagStack]       four garment swing tags on one pin, pull one down
/// Fashion-home entry card (opens Drop Studio):
///   A [EntryBackstagePass]  lanyard backstage pass, holographic foil sweep
///   B [EntryPeelPoster]     fly-poster whose corner peels to the next hour
///   C [EntrySplitFlap]      split-flap board spelling this hour's word
///
/// Each door previews its REAL effect from [Settings]: hero style
/// (plain/full/tv), a frame of the chosen background film, the saved start
/// still, the nav bar slots/shape/colour. Type: [V4Type] (greeting ramp);
/// only giant poster words use the poster serif.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/content.dart';
import '../../data/models.dart';
import '../../data/settings.dart';
import '../../widgets/concept/stillwater.dart';
import 'drop_v4_type.dart';

const _gold = Color(0xFFC8A96E);
const _goldSoft = Color(0xFFE8D5A3);
const _violet = Color(0xFF7C4DDB);
const _plum = Color(0xFF2A1450);
const _deep = Color(0xFF060C18);
const _ink = Color(0xFF0B0B10);
const _paper = Color(0xFFF3EADB);
const _serif = 'CormorantGaramond';

enum DoorKind { background, startArt, access }

class DoorHooks {
  const DoorHooks({this.onOpenBackground, this.onOpenStartArt, this.onOpenAccess});
  final VoidCallback? onOpenBackground;
  final VoidCallback? onOpenStartArt;
  final VoidCallback? onOpenAccess;
  VoidCallback? of(DoorKind k) => switch (k) {
        DoorKind.background => onOpenBackground,
        DoorKind.startArt => onOpenStartArt,
        DoorKind.access => onOpenAccess,
      };
}

String doorTitle(DoorKind k) => switch (k) {
      DoorKind.background => 'Background',
      DoorKind.startArt => 'Start art',
      DoorKind.access => 'Access',
    };

/// What is set right now (real Settings values).
String doorState(DoorKind k) {
  final s = Settings.instance;
  return switch (k) {
    DoorKind.background => s.fashionPlus ? Settings.fashionVideoNames[s.fashionVideoIndex] : 'Motion off',
    DoorKind.startArt => s.fashionImageIndex < 0 ? 'NowssB black' : Settings.fashionImageName(s.fashionImageIndex),
    DoorKind.access => '${s.navSlots.length} tabs, ${s.navShape} bar',
  };
}

String _poster(String mp4) => mp4.replaceAll('.mp4', '-poster.webp');

IconData _navIcon(String id) => switch (id) {
      'connect' => Icons.home_rounded,
      'practice' => Icons.self_improvement_rounded,
      'library' => Icons.library_music_rounded,
      'store' => Icons.shopping_bag_rounded,
      'profile' => Icons.person_rounded,
      'player' => Icons.play_circle_rounded,
      _ => Icons.circle,
    };

/// A miniature of the home with ONE setting applied — its real effect.
class SettingPreview extends StatelessWidget {
  const SettingPreview({super.key, required this.kind, this.t = 0});
  final DoorKind kind;
  final double t;

  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;
    final film = _poster(Settings.fashionVideos[s.fashionVideoIndex]);
    final still = s.fashionImageAsset ?? Settings.fashionImages.first;
    final drift = 1.06 + .05 * Stillwater.lungs(t);
    Widget img(String a, {Alignment al = Alignment.center, double scale = 1}) => Transform.scale(
        scale: scale,
        child: Image.asset(a, fit: BoxFit.cover, alignment: al, width: double.infinity, height: double.infinity));
    const lbl = TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, shadows: [Shadow(blurRadius: 4)]);
    final Widget body = switch (kind) {
      DoorKind.background => Stack(fit: StackFit.expand, children: [img(film, scale: drift), const _Scrim()]),
      DoorKind.startArt =>
        Stack(fit: StackFit.expand, children: [img(still, al: Alignment.topCenter, scale: drift), const _Scrim()]),
      DoorKind.access => Stack(fit: StackFit.expand, children: [
          img(film),
          Container(color: Colors.black45),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: s.navColor == 'black' ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(s.navShape == 'pill' ? 40 : 10),
                    border: Border.all(color: _gold.withValues(alpha: .7))),
                child: FittedBox(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < s.navSlots.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(_navIcon(s.navSlots[i]),
                            size: 18,
                            color: i == (t * 5).floor() % s.navSlots.length
                                ? _gold
                                : (s.navColor == 'black' ? Colors.white : _ink)),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
    };
    return ClipRect(child: body);
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xCC000000)],
              stops: [.45, 1])));
}

/// Title + live state (+ action) in the greeting ramp, on a solid surface.
class _Plate extends StatelessWidget {
  const _Plate(this.kind, {this.dark = true, this.cta = false});
  final DoorKind kind;
  final bool dark;
  final bool cta;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(doorTitle(kind), maxLines: 1, style: V4Type.title(dark: dark).copyWith(fontSize: 22))),
        const SizedBox(height: 2),
        Text(doorState(kind), style: V4Type.sub(dark: dark)),
        if (cta) ...[
          const SizedBox(height: 6),
          Text('Change ${doorTitle(kind).toLowerCase()}', style: V4Type.action(dark: dark)),
        ],
      ]);
}

/// Section heading in the greeting ramp: light line, bold title, grey sub.
class V4Heading extends StatelessWidget {
  const V4Heading(this.greet, this.title, this.sub, {super.key, this.dark = true});
  final String greet;
  final String title;
  final String sub;
  final bool dark;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(greet, style: V4Type.greet(dark: dark)),
          Text(title, style: V4Type.title(dark: dark)),
          const SizedBox(height: 3),
          Text(sub, style: V4Type.sub(dark: dark)),
        ]),
      );
}

mixin _Pick<T extends StatefulWidget> on State<T> {
  int get initial;
  late int open = initial;
  void pick(int i, DoorHooks h) {
    HapticFeedback.selectionClick();
    if (open == i) {
      h.of(DoorKind.values[i])?.call();
    } else {
      setState(() => open = i);
    }
  }
}

// ─── DOORS A · folding screen ───────────────────────────────────────────

// ─── DOORS B · prism ────────────────────────────────────────────────────

// ─── DOORS C · garment tags on one pin ──────────────────────────────────

// ─── ENTRY CARD (Fashion home → Drop Studio) ────────────────────────────

/// This hour's word: same rotation as Builder's dropWordsFor (first of five).
Word? hourWord(DateTime at) {
  final pool = ContentStore.instance.library.where((w) => w.meaning.isNotEmpty).toList();
  if (pool.isEmpty) return null;
  final hour = DateTime.utc(at.year, at.month, at.day, at.hour).millisecondsSinceEpoch ~/ Duration.millisecondsPerHour;
  return pool[(hour * 5) % pool.length];
}

String _hh(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// Giant poster word: ALWAYS whole — scales down, never crops or ellipsises.
class _WholeWord extends StatelessWidget {
  const _WholeWord(this.text, {this.color = Colors.white, this.size = 88});
  final String text;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(text.toUpperCase(),
            maxLines: 1,
            softWrap: false,
            textScaler: TextScaler.noScaling,
            style: TextStyle(fontFamily: _serif, fontWeight: FontWeight.w700, fontSize: size, height: .95, color: color)),
      );
}

abstract class _EntryBase extends StatelessWidget {
  const _EntryBase({super.key, this.onOpen, this.now});
  final VoidCallback? onOpen;
  final DateTime? now;
  Widget card(BuildContext context, Word? w, DateTime at, double t);
  @override
  Widget build(BuildContext context) {
    final at = now ?? DateTime.now();
    return ListenableBuilder(
      listenable: ContentStore.instance,
      builder: (context, _) => Semantics(
        button: true,
        label: 'Open Drop Studio',
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onOpen?.call();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Breath(builder: (context, t) => card(context, hourWord(at), at, t)),
          ),
        ),
      ),
    );
  }
}

/// A — backstage pass on a lanyard; holographic foil sweeps each breath.
class EntryBackstagePass extends _EntryBase {
  const EntryBackstagePass({super.key, super.onOpen, super.now});
  @override
  Widget card(BuildContext context, Word? w, DateTime at, double t) {
    final word = w?.word ?? 'NowssB';
    return Transform.rotate(
      angle: -.02 + .02 * math.sin(2 * math.pi * t),
      alignment: Alignment.topCenter,
      child: Column(children: [
        Container(
          width: 46,
          height: 24,
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_violet, _plum]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(6))),
          alignment: Alignment.center,
          child: Container(width: 22, height: 6, decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(3))),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: _paper,
            child: Stack(children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-2 + 4 * t, -1),
                      end: Alignment(-1 + 4 * t, 1),
                      colors: const [Colors.transparent, Color(0x66B39CFF), Color(0x77FFE3A3), Colors.transparent],
                    ),
                  ),
                ),
              ),
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Backstage pass', style: V4Type.greet(dark: false)),
                        Text('Drop Studio', style: V4Type.title(dark: false)),
                        Text('Valid ${_hh(at)} to ${_hh(at.add(const Duration(hours: 1)))}', style: V4Type.sub(dark: false)),
                        const SizedBox(height: 8),
                        _WholeWord(word, color: _plum),
                        if (w != null) Text(w.meaning, style: V4Type.sub(dark: false).copyWith(color: _ink)),
                        const SizedBox(height: 10),
                        SizedBox(height: 24, width: double.infinity, child: CustomPaint(painter: _BarcodePainter(word))),
                      ]),
                    ),
                  ),
                  Container(
                    width: 60,
                    decoration: const BoxDecoration(
                        color: _ink, border: Border(left: BorderSide(color: _gold, width: 2, style: BorderStyle.solid))),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Center(child: Text('Tear to enter', style: V4Type.action())),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.seed);
  final String seed;
  @override
  void paint(Canvas c, Size s) {
    final r = math.Random(seed.hashCode);
    var x = 0.0;
    final p = Paint()..color = _ink;
    while (x < s.width * .7) {
      final bw = 1.0 + r.nextInt(3);
      c.drawRect(Rect.fromLTWH(x, 0, bw, s.height), p);
      x += bw + 1 + r.nextInt(3);
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter o) => o.seed != seed;
}

/// B — a fly-poster on the wall; its corner peels with the breath, showing
/// the next hour's sheet beneath. The word sits clear of the peel.
class EntryPeelPoster extends _EntryBase {
  const EntryPeelPoster({super.key, super.onOpen, super.now});
  @override
  Widget card(BuildContext context, Word? w, DateTime at, double t) {
    final word = w?.word ?? 'NowssB';
    final next = hourWord(at.add(const Duration(hours: 1)));
    final peel = .26 + .14 * Stillwater.lungs(t);
    return LayoutBuilder(builder: (context, outer) => AspectRatio(
      aspectRatio: outer.maxWidth < 320 ? .78 : 1.1,
      child: LayoutBuilder(builder: (context, c) {
        final s = c.biggest;
        final d = s.shortestSide * peel;
        return Stack(children: [
          Positioned.fill(
            child: Container(
              color: _violet,
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: d * .9,
                child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.bottomRight, child: Text('Next, ${_hh(at.add(const Duration(hours: 1)))}\n${next?.word ?? ''}',
                    textAlign: TextAlign.right, style: V4Type.sub().copyWith(color: Colors.white, fontWeight: FontWeight.w800))),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipPath(
              clipper: _CornerCut(d),
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(_poster(Settings.fashionVideos[Settings.instance.fashionVideoIndex]), fit: BoxFit.cover),
                Container(color: _deep.withValues(alpha: .55)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('This hour, ${_hh(at)}', style: V4Type.greet()),
                    Text('Drop Studio', style: V4Type.title()),
                    const Spacer(),
                    _WholeWord(word, size: 96),
                    if (w != null)
                      Padding(padding: EdgeInsets.only(right: d * .8), child: Text(w.meaning, style: V4Type.sub().copyWith(color: Colors.white))),
                    SizedBox(height: d * .5),
                  ]),
                ),
              ]),
            ),
          ),
          Positioned(right: 0, bottom: 0, width: d, height: d, child: CustomPaint(painter: _FlapPainter())),
          Positioned(left: 16, bottom: 14, child: Text('Peel into the studio', style: V4Type.action())),
        ]);
      }),
    ));
  }
}

class _CornerCut extends CustomClipper<Path> {
  _CornerCut(this.d);
  final double d;
  @override
  Path getClip(Size s) => Path()
    ..lineTo(s.width, 0)
    ..lineTo(s.width, s.height - d)
    ..lineTo(s.width - d, s.height)
    ..lineTo(0, s.height)
    ..close();
  @override
  bool shouldReclip(_CornerCut o) => o.d != d;
}

class _FlapPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Path()
      ..moveTo(s.width, 0)
      ..lineTo(0, s.height)
      ..lineTo(0, 0)
      ..close();
    c.drawShadow(p, Colors.black, 8, false);
    c.drawPath(
        p,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFFFFF), _paper, Color(0xFFB9AA8E)])
              .createShader(Offset.zero & s));
  }

  @override
  bool shouldRepaint(_FlapPainter o) => false;
}

/// C — a split-flap board; each letter tile flips into place in turn every
/// breath. Tile size comes from the width, so the word always fits whole.
class EntrySplitFlap extends _EntryBase {
  const EntrySplitFlap({super.key, super.onOpen, super.now});
  @override
  Widget card(BuildContext context, Word? w, DateTime at, double t) {
    final word = (w?.word ?? 'NowssB').toUpperCase();
    return Container(
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A36), width: 2),
        boxShadow: [BoxShadow(color: _violet.withValues(alpha: .35), blurRadius: 30)],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Color.lerp(_gold, Colors.amber, Stillwater.lungs(t)))),
          const SizedBox(width: 8),
          Expanded(child: Text('Now boarding', style: V4Type.greet())),
        ]),
        Text('Drop Studio', style: V4Type.title()),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, c) {
          const gap = 4.0;
          final tw = math.min(44.0, (c.maxWidth - gap * (word.length - 1)) / word.length);
          return Row(children: [
            for (var i = 0; i < word.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              _FlapTile(ch: word[i], w: tw, flip: ((t * 1.6 - i * .08) % 1).clamp(0.0, 1.0)),
            ],
          ]);
        }),
        const SizedBox(height: 12),
        Table(columnWidths: const {0: IntrinsicColumnWidth()}, children: [
          _row('Time', '${_hh(at)} to ${_hh(at.add(const Duration(hours: 1)))}'),
          if (w != null) _row('Meaning', w.meaning),
          if (w != null) _row('From', w.price > 0 ? 'Rs ${w.price}' : 'Free this hour'),
        ]),
        const SizedBox(height: 8),
        Text('Board the drop', style: V4Type.action()),
      ]),
    );
  }

  TableRow _row(String k, String v) => TableRow(children: [
        Padding(padding: const EdgeInsets.only(right: 12, bottom: 4), child: Text(k, style: V4Type.sub())),
        Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(v, style: V4Type.sub().copyWith(color: Colors.white))),
      ]);
}

class _FlapTile extends StatelessWidget {
  const _FlapTile({required this.ch, required this.w, required this.flip});
  final String ch;
  final double w;
  final double flip;
  @override
  Widget build(BuildContext context) {
    final h = w * 1.45;
    final fall = (flip / .25).clamp(0.0, 1.0);
    Widget face() => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: const Color(0xFF1C1C26), borderRadius: BorderRadius.circular(4)),
          alignment: Alignment.center,
          child: Text(ch,
              textScaler: TextScaler.noScaling,
              style: TextStyle(fontFamily: _serif, fontWeight: FontWeight.w700, color: _paper, fontSize: h * .72, height: 1)),
        );
    return SizedBox(
      width: w,
      height: h,
      child: Stack(children: [
        face(),
        if (fall < 1)
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: .5,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, .004)
                  ..rotateX(-fall * math.pi / 2),
                child: face(),
              ),
            ),
          ),
        Positioned(left: 0, right: 0, top: h / 2 - .5, child: Container(height: 1, color: Colors.black)),
      ]),
    );
  }
}
