/// Top Progress pop-up, the top-bar progress icon and the progress panel.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../widgets/swipe_away.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart';
import 'progress_center.dart';
import 'progress_kit.dart' show GoalMarks;
import 'progress_sources.dart';
import 'today_progress_screen.dart';
import '../../widgets/nwsb_icon.dart';

/// Hero-header glass (GlassWrap tokens) with a deeper blur and a light dark
/// tint so white text reads over any page.
class ProgressGlass extends StatelessWidget {
  const ProgressGlass({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 10)});
  final Widget child;
  final EdgeInsets padding;
  static const double blurSigma = GlassWrap.blurSigma * 2; // deep blur

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(kGlassRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: const [BoxShadow(color: Color(0x57000000), offset: Offset(0, 16), blurRadius: 40)],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x2E000000),
              gradient: const LinearGradient(colors: [GlassWrap.fill, Color(0x05FFFFFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: r,
              border: Border.all(color: GlassWrap.line),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// The app's progress bar (Daily Tasks styling).
class ProgressBarLine extends StatelessWidget {
  const ProgressBarLine({super.key, required this.value, this.height = 8});
  final double value;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(value: value, minHeight: height, color: NwsbColors.gold, backgroundColor: const Color(0x33FFFFFF)),
      );
}

const _ink = TextStyle(color: Colors.white, decoration: TextDecoration.none);

class ProgressPopupHost extends StatefulWidget {
  const ProgressPopupHost({super.key, required this.child, this.center, this.render = true});
  final Widget child;
  final ProgressCenter? center;

  /// False when NotificationPopupHost shows the pop-up inside its one
  /// horizontal row (the app shell); this host then only runs the timer.
  final bool render;
  @override
  State<ProgressPopupHost> createState() => _ProgressPopupHostState();
}

class _ProgressPopupHostState extends State<ProgressPopupHost> with SingleTickerProviderStateMixin {
  late final AnimationController _slide =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420), reverseDuration: const Duration(milliseconds: 220));
  ProgressItem? _shown;
  Timer? _hide;

  ProgressCenter get _c => widget.center ?? ProgressCenter.instance;

  @override
  void initState() {
    super.initState();
    _c.popup.addListener(_on);
    if (_c.popup.value != null) WidgetsBinding.instance.addPostFrameCallback((_) => _on());
  }

  @override
  void dispose() {
    _hide?.cancel();
    _c.popup.removeListener(_on);
    _slide.dispose();
    super.dispose();
  }

  void _on() {
    final item = _c.popup.value;
    if (!mounted) return;
    if (item == null) {
      _close();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _shown = item;
    });
    _slide.forward(from: 0);
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () => _c.dismiss());
  }

  Future<void> _close() async {
    _hide?.cancel();
    if (_shown == null) return;
    await _slide.reverse();
    if (mounted) setState(() => _shown = null);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.render ? _shown : null;
    return Stack(children: [
      widget.child,
      if (item != null)
        Positioned(
          left: 12,
          right: 12,
          top: MediaQuery.paddingOf(context).top + 8,
          child: SwipeAway(
            key: ValueKey('progress-popup-${item.kind}'),
            onTap: _c.dismiss,
            onDismissed: _c.dismiss,
            child: AnimatedBuilder(
              animation: _slide,
              builder: (context, child) {
                final t = Curves.easeOutBack.transform(_slide.value.clamp(0.0, 1.0));
                return Transform.translate(
                  offset: Offset(0, -110 * (1 - t)),
                  child: Opacity(opacity: _slide.value.clamp(0.0, 1.0), child: child),
                );
              },
              child: ProgressPopupCard(item: item),
            ),
          ),
        ),
    ]);
  }
}

/// The compact card itself (also used by screenshots/tests).
class ProgressPopupCard extends StatelessWidget {
  const ProgressPopupCard({super.key, required this.item, this.bare = false});
  final ProgressItem item;

  /// Without its own glass (inside the shared notification row).
  final bool bare;
  @override
  Widget build(BuildContext context) {
    final body = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Text(item.line,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: _ink.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800, letterSpacing: 0.1)),
            ),
            const SizedBox(width: 8),
            Text('${(item.value * 100).round()}%', style: _ink.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          SizedBox(height: bare ? 5 : 7),
          ProgressBarLine(value: item.value, height: 6),
          SizedBox(height: bare ? 6 : 8),
          Container(
            // Inside the 86 px notification row the strip is compact so it fits.
            height: bare ? 32 : 52,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              SizedBox(width: bare ? 26 : 40, height: bare ? 26 : 40, child: ProgressDoneAnim(kind: item.kind)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.subtitle.isNotEmpty ? item.subtitle : _cheer(item.kind),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: _ink.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xCCFFFFFF))),
              ),
            ]),
          ),
        ]);
    return Material(
      type: MaterialType.transparency,
      child: bare
          ? Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), child: body)
          : ProgressGlass(child: body),
    );
  }

  static String _cheer(ProgressKind k) => switch (k) {
        ProgressKind.tasks => 'Checklist complete',
        ProgressKind.routine => 'Practice done for today',
        ProgressKind.coins => 'All coins collected',
        ProgressKind.quest => 'Quest complete',
        ProgressKind.checkin => 'Checked in · see you tomorrow',
      };
}

/// Path-draw "done" animation, one per kind.
class ProgressDoneAnim extends StatefulWidget {
  const ProgressDoneAnim({super.key, required this.kind, this.progress});
  final ProgressKind kind;

  /// Fixed frame (0..1) for screenshots; null animates.
  final double? progress;
  @override
  State<ProgressDoneAnim> createState() => _ProgressDoneAnimState();
}

class _ProgressDoneAnimState extends State<ProgressDoneAnim> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  @override
  void initState() {
    super.initState();
    if (widget.progress == null) _a.forward();
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        final t = widget.progress ?? Curves.easeOutCubic.transform(_a.value);
        final paint = CustomPaint(painter: DonePainter(widget.kind, t), size: const Size.square(40));
        if (widget.kind != ProgressKind.coins) return paint;
        final pop = Curves.elasticOut.transform((t * 1.4).clamp(0.0, 1.0));
        return Stack(alignment: Alignment.center, children: [
          paint,
          Transform.scale(scale: 0.2 + 0.8 * pop, child: const NwsbCoinDisc(size: 24)),
        ]);
      },
    );
  }
}

class DonePainter extends CustomPainter {
  DonePainter(this.kind, this.t);
  final ProgressKind kind;
  final double t;

  static double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  void _drawPart(Canvas c, Path p, double f, Paint paint) {
    if (f <= 0) return;
    for (final m in p.computeMetrics()) {
      c.drawPath(m.extractPath(0, m.length * f), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    canvas.scale(s);
    final gold = Paint()
      ..color = NwsbColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    switch (kind) {
      case ProgressKind.tasks:
        for (var i = 0; i < 3; i++) {
          final y = 9.0 + i * 11;
          final f = _seg(t, i * 0.25, i * 0.25 + 0.35);
          _drawPart(canvas, Path()..moveTo(4, y)..lineTo(7.5, y + 3.5)..lineTo(13, y - 3), f, gold);
          _drawPart(canvas, Path()..moveTo(18, y)..lineTo(36, y), _seg(t, i * 0.25 + 0.1, i * 0.25 + 0.4), white..color = Color.fromRGBO(255, 255, 255, 0.4 + 0.6 * f));
        }
      case ProgressKind.coins:
        final f = _seg(t, 0.2, 1);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final r0 = 13 + 4 * f, r1 = 15 + 5 * f;
          final ray = Path()
            ..moveTo(20 + r0 * math.cos(a), 20 + r0 * math.sin(a))
            ..lineTo(20 + r1 * math.cos(a), 20 + r1 * math.sin(a));
          _drawPart(canvas, ray, f, gold..color = NwsbColors.gold.withValues(alpha: 1 - 0.5 * f));
        }
      case ProgressKind.quest:
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? 16.0 : 7.0;
          final a = -math.pi / 2 + i * math.pi / 5;
          final p = Offset(20 + r * math.cos(a), 21 + r * math.sin(a));
          i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
        }
        star.close();
        _drawPart(canvas, star, _seg(t, 0, 0.8), gold);
        if (t > 0.8) {
          canvas.drawPath(star, Paint()..color = NwsbColors.gold.withValues(alpha: 0.35 * _seg(t, 0.8, 1)));
        }
      case ProgressKind.routine:
      case ProgressKind.checkin:
        final ring = Path()..addArc(Rect.fromCircle(center: const Offset(20, 20), radius: 16), -math.pi / 2, 2 * math.pi - 0.001);
        _drawPart(canvas, ring, _seg(t, 0, 0.55), white);
        _drawPart(canvas, Path()..moveTo(12, 20.5)..lineTo(18, 26.5)..lineTo(28.5, 14), _seg(t, 0.45, 1), gold);
    }
  }

  @override
  bool shouldRepaint(DonePainter old) => old.t != t || old.kind != kind;
}

const _progressSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
<circle cx="12" cy="12" r="9" stroke-opacity="0.35"/>
<path d="M12 3a9 9 0 0 1 9 9" stroke="#E4C56A"/>
<path d="M8 12.5l2.5 2.5L16 9.5"/>
</svg>''';

/// Small top-bar button that opens the progress panel.
class ProgressIconButton extends StatelessWidget {
  const ProgressIconButton({super.key});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Progress',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          ProgressPanel.open(context);
        },
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x44FFFFFF)),
          ),
          child: SvgPicture.string(_progressSvg, width: 18, height: 18),
        ),
      ),
    );
  }
}

/// Obvious button: solid gold pill, icon + label, ripple, press scale and a
/// soft pulse ring so it reads as tappable.
class ProgressPillButton extends StatefulWidget {
  const ProgressPillButton({super.key, this.label = 'Progress'});
  final String label;
  @override
  State<ProgressPillButton> createState() => _ProgressPillButtonState();
}

class _ProgressPillButtonState extends State<ProgressPillButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  var _down = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pill = Material(
      color: NwsbColors.gold,
      shape: const StadiumBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const StadiumBorder(),
        splashColor: const Color(0x55FFFFFF),
        onHighlightChanged: (v) => setState(() => _down = v),
        onTap: () {
          HapticFeedback.mediumImpact();
          ProgressPanel.open(context);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 13, 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: SvgPicture.string(_progressSvg, width: 14, height: 14),
            ),
            const SizedBox(width: 6),
            Text(widget.label,
                style: const TextStyle(color: Colors.black, fontSize: 12.5, fontWeight: FontWeight.w800, decoration: TextDecoration.none)),
          ]),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: widget.label,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = _pulse.value;
          return DecoratedBox(
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              shadows: [BoxShadow(color: NwsbColors.gold.withValues(alpha: 0.45 * (1 - t)), blurRadius: 4 + 14 * t, spreadRadius: 6 * t)],
            ),
            child: child,
          );
        },
        child: AnimatedScale(scale: _down ? 0.92 : 1, duration: const Duration(milliseconds: 110), child: pill),
      ),
    );
  }
}

/// Glass sheet: notification-glance header + Quick Access style grid of
/// black tiles, each with its own bar.
class ProgressPanel extends StatelessWidget {
  const ProgressPanel({super.key, this.center});
  final ProgressCenter? center;

  static Future<void> open(BuildContext context) {
    ProgressSources.instance.sync();
    unawaited(ProgressSources.instance.refresh());
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Progress',
      barrierColor: const Color(0x66000000),
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (ctx, _, __) => const SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(padding: EdgeInsets.fromLTRB(12, 8, 12, 0), child: ProgressPanel()),
        ),
      ),
      transitionBuilder: (ctx, a, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, -0.3), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
        child: FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = center ?? ProgressCenter.instance;
    return Material(
      type: MaterialType.transparency,
      child: ProgressGlass(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            final items = c.items;
            final done = items.where((e) => e.complete).length;
            return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Row(children: [
                  Text('PROGRESS', style: _ink.copyWith(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('$done of ${items.length} today',
                        key: const ValueKey('progress-panel-count'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _ink.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xB3FFFFFF))),
                  ),
                  _ViewAll(onTap: () {
                    final nav = Navigator.of(context);
                    if (ModalRoute.of(context) is PopupRoute) nav.pop();
                    nav.push(MaterialPageRoute<void>(builder: (_) => const TodayProgressScreen()));
                  }),
                ]),
              ),
              GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 82),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: [for (final e in items) _Tile(item: e, onTap: () => ProgressRoutes.open(context, e.kind))],
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({required this.item, required this.onTap});
  final ProgressItem item;
  final VoidCallback onTap;
  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  var _down = false;
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hint = item.kind == ProgressKind.checkin && !item.complete ? 'Tap to check in' : item.complete ? 'Done' : 'Open';
    return Semantics(
      button: true,
      label: '${item.title} ${item.done.clamp(0, item.total)} of ${item.total}',
      child: GestureDetector(
        key: ValueKey('progress-tile-${item.kind.name}'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 110),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1FFFFFFF))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                NwsbIcon(goalMark(item.kind), size: 20, color: item.complete ? NwsbColors.goldLight : Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ink.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700))),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0x80FFFFFF)),
              ]),
              Row(children: [
                Text('${item.done.clamp(0, item.total)}/${item.total}',
                    key: ValueKey('progress-count-${item.kind.name}'),
                    style: _ink.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: item.complete ? NwsbColors.goldLight : const Color(0xB3FFFFFF))),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: _ink.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0x80FFFFFF))),
                ),
              ]),
              ProgressBarLine(value: item.value, height: 6),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ViewAll extends StatelessWidget {
  const _ViewAll({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: NwsbColors.goldLight,
        shape: const StadiumBorder(),
        child: InkWell(
          key: const ValueKey('progress-view-all'),
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 9, 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('View all', style: _ink.copyWith(color: Colors.black, fontSize: 11.5, fontWeight: FontWeight.w800)),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.black),
            ]),
          ),
        ),
      );
}

/// "Today 0/5" — the button that opens the Progress pop-up. [light] is the
/// raised white neumorphic pill of the normal home; otherwise it is the
/// Zen home's dark glass (GlassWrap tokens). Presses in on touch.
class TodayProgressButton extends StatefulWidget {
  const TodayProgressButton({super.key, this.light = true, this.compact = false, this.center});
  final bool light;

  /// Stacked tile (mark over "Today" over the count) for tight spots such
  /// as the right side of the Zen home's Begin Your Healing Path banner.
  final bool compact;
  final ProgressCenter? center;
  @override
  State<TodayProgressButton> createState() => _TodayProgressButtonState();
}

class _TodayProgressButtonState extends State<TodayProgressButton> {
  var _down = false;

  ProgressCenter get _c => widget.center ?? ProgressCenter.instance;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final light = widget.light;
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final items = _c.items;
        final done = items.where((e) => e.complete).length;
        final ink = light ? NwsbColors.ink : Colors.white;
        final sub = light ? const Color(0x8C1A1A2E) : const Color(0xB3FFFFFF);
        final mark = Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: light ? NwsbColors.ink : NwsbColors.goldLight,
            borderRadius: BorderRadius.circular(9),
          ),
          child: NwsbIcon(GoalMarks.check, size: 16, strokeWidth: 2, color: light ? Colors.white : Colors.black),
        );
        final count = Text('$done/${items.length} done',
            key: const ValueKey('today-button-count'),
            maxLines: 1,
            style: TextStyle(color: sub, fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.2, decoration: TextDecoration.none));
        final body = widget.compact
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                mark,
                const SizedBox(height: 6),
                Text('Today', style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w800, height: 1.1, decoration: TextDecoration.none)),
                const SizedBox(height: 1),
                count,
              ])
            : Row(mainAxisSize: MainAxisSize.min, children: [
          mark,
          const SizedBox(width: 8),
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today', style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w800, height: 1.1, decoration: TextDecoration.none)),
            count,
          ]),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 18, color: sub),
        ]);
        final r = BorderRadius.circular(widget.compact ? 18 : 999);
        final pill = AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: widget.compact ? const EdgeInsets.fromLTRB(10, 10, 10, 9) : const EdgeInsets.fromLTRB(6, 6, 8, 6),
          decoration: light
              ? BoxDecoration(
                  color: _down ? NwsbColors.surfaceDim : NwsbColors.surface,
                  borderRadius: r,
                  boxShadow: _down
                      ? const [BoxShadow(color: Color(0x1A000000), offset: Offset(1, 1), blurRadius: 3)]
                      : NwsbShadows.raisedSm,
                )
              : BoxDecoration(
                  color: _down ? const Color(0x33FFFFFF) : GlassWrap.fill,
                  borderRadius: r,
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
          child: body,
        );
        final glass = light
            ? pill
            : ClipRRect(
                borderRadius: r,
                child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: GlassWrap.blurSigma, sigmaY: GlassWrap.blurSigma), child: pill),
              );
        return Semantics(
          button: true,
          label: 'Today\'s progress, $done of ${items.length} done',
          child: GestureDetector(
            key: const ValueKey('today-progress-button'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _set(true),
            onTapCancel: () => _set(false),
            onTapUp: (_) => _set(false),
            onTap: () {
              HapticFeedback.mediumImpact();
              ProgressPanel.open(context);
            },
            child: AnimatedScale(scale: _down ? 0.94 : 1, duration: const Duration(milliseconds: 110), child: glass),
          ),
        );
      },
    );
  }
}
