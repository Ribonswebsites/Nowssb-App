/// Your day (Ribon, Nov 18): one row of three big buttons under the home
/// greeting — Quick, Today x/5 done and Your Earnings. Each opens the same
/// liquid-glass sheet on its own tab (swipe between them):
///
///   Quick          the user's own quick actions (Settings.quickActions)
///   Today          today's goals (ProgressPanel, the same live tiles)
///   Your Earnings  coins, cash earned, words and meanings sold, target and
///                  Your position — every number from the server through
///                  EconomyMirror (wallet/main, payout/main,
///                  sellerStats/main incl. teamCount) or the monthly sellers
///                  board. Coins are only shown here, never collected.
///
/// The section is additive: the greeting's own Quick button and the Begin
/// Your Healing Path card's Today button stay where they are.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot, FirebaseFirestore;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../data/app_haptics.dart';
import '../../data/firebase.dart';
import '../../data/notifications.dart';
import '../../data/settings.dart';
import '../../screens/normal/header_actions_sheet.dart' show showCustomizeQuickActions;
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../circle/circle_screen.dart' show EarnTabsPage;
import '../coins/coins_screen.dart';
import '../earn/earnings_screen.dart';
import '../economy/economy_api.dart';
import '../economy/money.dart';
import '../programs/reference_program.dart' show monthKeyIst;
import '../progress/progress_center.dart';
import '../progress/progress_kit.dart' show GoalMarks;
import '../progress/progress_popup.dart';
import '../progress/progress_sources.dart';

// ─── palette ────────────────────────────────────────────────────────────────

const _night = Color(0xFF0D0820);
const _gold = NwsbColors.goldLight;
const _mist = Color(0xB3FFFFFF);
const _faint = Color(0x8CFFFFFF);

/// Tabs of the sheet, in order.
enum YourDayTab { quick, today, earnings }

/// What the Quick tab's shortcuts do on this home.
class YourDayActions {
  const YourDayActions({
    required this.onNotifications,
    required this.onStore,
    required this.onPlayer,
    this.onGlassToggle,
    this.glassOn,
  });
  final VoidCallback onNotifications;
  final VoidCallback onStore;
  final VoidCallback onPlayer;

  /// Only the Normal home has a real glass mode; without it the Glass
  /// shortcut is not offered (no dead switch).
  final VoidCallback? onGlassToggle;
  final bool Function()? glassOn;
}

bool _still(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

// ─── liquid glass ───────────────────────────────────────────────────────────

/// Deep blur, violet-tinted fill, a gradient hairline and a soft top glow.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({super.key, required this.child, this.radius = 24, this.padding = const EdgeInsets.all(12), this.blur = 22, this.strong = false});
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double blur;

  /// Denser fill for the sheet, which floats over busy content.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(color: const Color(0x66000000), blurRadius: strong ? 50 : 34, offset: const Offset(0, 18)),
          const BoxShadow(color: Color(0x332A1650), blurRadius: 28, spreadRadius: -6),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            foregroundPainter: _GlassEdge(radius),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: r,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: strong
                      ? const [Color(0xE62A1650), Color(0xEB160C30), Color(0xF20D0820)]
                      : const [Color(0x3D8C6CFF), Color(0x1F2A1650), Color(0x380D0820)],
                ),
              ),
              child: Stack(children: [
                // Soft inner glow along the top edge.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: r,
                        gradient: const RadialGradient(
                          center: Alignment(-0.6, -1.25),
                          radius: 1.1,
                          colors: [Color(0x26FFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(padding: padding, child: child),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassEdge extends CustomPainter {
  _GlassEdge(this.radius);
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect.deflate(0.6), Radius.circular(radius - 0.6));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x80FFFFFF), Color(0x40B9A2FF), Color(0x14FFFFFF), Color(0x40E8D5A3)],
        stops: [0, .35, .7, 1],
      ).createShader(rect);
    canvas.drawRRect(rr, p);
  }

  @override
  bool shouldRepaint(_GlassEdge old) => old.radius != radius;
}

// ─── count-up ───────────────────────────────────────────────────────────────

/// Counts up to [value] (from its last value on change); still under
/// reduced motion.
class YourDayCount extends StatelessWidget {
  const YourDayCount(this.value, {super.key, required this.format, this.style});
  final int value;
  final String Function(int v) format;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    if (_still(context)) return Text(format(value), maxLines: 1, style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format(v.round()), maxLines: 1, style: style),
    );
  }
}

String _coins(int v) => '$v';
String _cents(int v) => FxBook.instance.formatCents(v);

// ─── the home section ───────────────────────────────────────────────────────

class YourDaySection extends StatelessWidget {
  const YourDaySection({super.key, required this.actions, this.light = false});
  final YourDayActions actions;

  /// The Normal home's raised neumorphic look instead of dark glass.
  final bool light;

  void _open(BuildContext context, YourDayTab tab) {
    AppHaptics.medium();
    showYourDaySheet(context, tab: tab, actions: actions);
  }

  @override
  Widget build(BuildContext context) {
    final row = ListenableBuilder(
      listenable: Listenable.merge([Settings.instance, ProgressCenter.instance, EconomyMirror.instance, FxBook.instance]),
      builder: (context, _) {
        final shortcuts = _quickIds(actions).length;
        final items = ProgressCenter.instance.items;
        final done = items.where((e) => e.complete).length;
        final m = EconomyMirror.instance;
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: _DayButton(
                key: const ValueKey('your-day-quick'),
                light: light,
                disc: const _Disc(fill: [Colors.white, Color(0xFFE9E4FF)], child: NwsbIcon(NwsbMarks.features, size: 19, color: Colors.black, strokeWidth: 1.9)),
                label: 'Quick',
                sub: Text('$shortcuts shortcut${shortcuts == 1 ? '' : 's'}'),
                semantics: 'Quick, $shortcuts shortcuts',
                onTap: () => _open(context, YourDayTab.quick),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DayButton(
                key: const ValueKey('your-day-today'),
                light: light,
                disc: const _Disc(fill: [Color(0xFFF3E6BF), Color(0xFFD9B970)], child: NwsbIcon(GoalMarks.check, size: 19, color: Colors.black, strokeWidth: 2)),
                label: 'Today',
                sub: Text('$done/${items.length} done', key: const ValueKey('your-day-today-count')),
                semantics: 'Today, $done of ${items.length} done',
                onTap: () => _open(context, YourDayTab.today),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DayButton(
                key: const ValueKey('your-day-earnings'),
                light: light,
                disc: const _Disc(fill: [Color(0xFFB9A2FF), Color(0xFF6A4BD8)], child: Icon(Icons.toll_rounded, size: 20, color: Colors.white)),
                label: 'Your Earnings',
                sub: Row(mainAxisSize: MainAxisSize.min, children: [
                  YourDayCount(m.coins, format: (v) => '$v coins'),
                ]),
                semantics: 'Your Earnings, ${m.coins} coins, ${_cents(m.lifetimeCents)} earned',
                onTap: () => _open(context, YourDayTab.earnings),
              ),
            ),
          ]),
        );
      },
    );
    final body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text('YOUR DAY',
            style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800, color: light ? const Color(0xFF9A7B3F) : _gold)),
      ),
      row,
    ]);
    if (light) {
      return Container(
        key: const ValueKey('your-day-section'),
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(color: NwsbColors.surface, borderRadius: BorderRadius.circular(22), boxShadow: NwsbShadows.raisedSm),
        child: body,
      );
    }
    return Padding(
      key: const ValueKey('your-day-section'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: LiquidGlass(radius: 22, padding: const EdgeInsets.fromLTRB(10, 12, 10, 10), child: body),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.fill, required this.child});
  final List<Color> fill;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: fill),
          boxShadow: [BoxShadow(color: fill.last.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: child,
      );
}

class _DayButton extends StatefulWidget {
  const _DayButton({super.key, required this.light, required this.disc, required this.label, required this.sub, required this.semantics, required this.onTap});
  final bool light;
  final Widget disc;
  final String label;
  final Widget sub;
  final String semantics;
  final VoidCallback onTap;
  @override
  State<_DayButton> createState() => _DayButtonState();
}

class _DayButtonState extends State<_DayButton> {
  var _down = false;
  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final light = widget.light;
    final ink = light ? NwsbColors.ink : Colors.white;
    final sub = light ? const Color(0x99000000) : _mist;
    final r = BorderRadius.circular(18);
    return Semantics(
      button: true,
      label: widget.semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.95 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 11),
            decoration: light
                ? BoxDecoration(color: _down ? NwsbColors.surfaceDim : NwsbColors.surface, borderRadius: r, boxShadow: _down ? const <BoxShadow>[] : NwsbShadows.raisedXs)
                : BoxDecoration(
                    borderRadius: r,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _down ? const [Color(0x33FFFFFF), Color(0x1AFFFFFF)] : const [Color(0x1FFFFFFF), Color(0x0AFFFFFF)],
                    ),
                    border: Border.all(color: const Color(0x2EFFFFFF)),
                  ),
            child: ExcludeSemantics(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                widget.disc,
                const SizedBox(height: 9),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(widget.label, maxLines: 1, style: TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.15)),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: sub, fontSize: 11, fontWeight: FontWeight.w700, height: 1.2),
                    child: widget.sub,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── the sheet ──────────────────────────────────────────────────────────────

/// A critically-damped-ish spring as a Curve (slight settle, no wobble).
class _SpringCurve extends Curve {
  const _SpringCurve();
  static final _sim = SpringSimulation(const SpringDescription(mass: 1, stiffness: 170, damping: 19), 0, 1, 0);
  @override
  double transformInternal(double t) => t >= 1 ? 1 : _sim.x(t * 0.9);
}

Future<void> showYourDaySheet(BuildContext context, {required YourDayTab tab, required YourDayActions actions}) {
  if (tab == YourDayTab.today) {
    ProgressSources.instance.sync();
    unawaited(ProgressSources.instance.refresh());
  }
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Your day',
    barrierColor: const Color(0x8C05020F),
    transitionDuration: const Duration(milliseconds: 520),
    pageBuilder: (ctx, _, __) => YourDaySheet(initial: tab, actions: actions),
    transitionBuilder: (ctx, a, _, child) {
      if (_still(ctx)) return FadeTransition(opacity: a, child: child);
      final fade = CurvedAnimation(parent: a, curve: const Interval(0, .45), reverseCurve: Curves.easeIn);
      final slide = CurvedAnimation(parent: a, curve: const _SpringCurve(), reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .35), end: Offset.zero).animate(slide),
          child: child,
        ),
      );
    },
  );
}

class YourDaySheet extends StatefulWidget {
  const YourDaySheet({super.key, required this.initial, required this.actions});
  final YourDayTab initial;
  final YourDayActions actions;
  @override
  State<YourDaySheet> createState() => _YourDaySheetState();
}

class _YourDaySheetState extends State<YourDaySheet> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initial.index);
  double _drag = 0;
  int _last = 0;

  @override
  void initState() {
    super.initState();
    _last = _tabs.index;
    _tabs.addListener(() {
      if (_tabs.index != _last) {
        _last = _tabs.index;
        AppHaptics.selection();
        if (_tabs.index == YourDayTab.today.index) {
          ProgressSources.instance.sync();
          unawaited(ProgressSources.instance.refresh());
        }
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = math.min(size.height * 0.78, 640.0);
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520, maxHeight: height),
            child: Transform.translate(
              offset: Offset(0, _drag),
              child: Material(
                type: MaterialType.transparency,
                child: LiquidGlass(
                  key: const ValueKey('your-day-sheet'),
                  radius: 28,
                  blur: 30,
                  strong: true,
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    height: height,
                    child: Column(children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (d) => setState(() => _drag = math.max(0, _drag + d.delta.dy)),
                        onVerticalDragEnd: (d) {
                          if (_drag > 90 || (d.primaryVelocity ?? 0) > 700) {
                            _close();
                          } else {
                            setState(() => _drag = 0);
                          }
                        },
                        child: _head(),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                        child: _GlassTabs(controller: _tabs),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _QuickTab(actions: widget.actions),
                            const _TodayTab(),
                            const _EarningsTab(),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _head() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 12, 8),
        child: Column(children: [
          Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0x40FFFFFF), borderRadius: BorderRadius.circular(9))),
          const SizedBox(height: 10),
          Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('YOUR DAY', style: TextStyle(fontSize: 10.5, letterSpacing: 2.2, fontWeight: FontWeight.w800, color: _gold)),
                SizedBox(height: 2),
                Text('Shortcuts, goals and earnings',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
              ]),
            ),
            Semantics(
              button: true,
              label: 'Close',
              child: GestureDetector(
                key: const ValueKey('your-day-close'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  AppHaptics.light();
                  _close();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x1FFFFFFF), border: Border.all(color: const Color(0x33FFFFFF))),
                  child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                ),
              ),
            ),
          ]),
        ]),
      );
}

/// Pill tab bar; the white indicator follows the swipe.
class _GlassTabs extends StatelessWidget {
  const _GlassTabs({required this.controller});
  final TabController controller;

  static const _tabs = [
    ('Quick', NwsbMarks.features),
    ('Today', GoalMarks.check),
    ('Your Earnings', NwsbMarks.earn),
  ];

  @override
  Widget build(BuildContext context) {
    final anim = controller.animation!;
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth / _tabs.length;
        return AnimatedBuilder(
          animation: anim,
          builder: (context, _) {
            final v = anim.value;
            return Stack(children: [
              Positioned(
                left: v * w,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(colors: [Colors.white, Color(0xFFEDE7FF)]),
                    boxShadow: const [BoxShadow(color: Color(0x598C6CFF), blurRadius: 16, offset: Offset(0, 4))],
                  ),
                ),
              ),
              Row(children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: controller.index == i,
                      label: _tabs[i].$1,
                      child: GestureDetector(
                        key: ValueKey('your-day-tab-$i'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => controller.animateTo(i),
                        child: ExcludeSemantics(
                          child: Builder(builder: (context) {
                            final on = (1 - (v - i).abs()).clamp(0.0, 1.0);
                            final color = Color.lerp(_mist, const Color(0xFF14102A), on)!;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    NwsbIcon(_tabs[i].$2, size: 15, color: color, strokeWidth: 1.9),
                                    const SizedBox(width: 6),
                                    Text(_tabs[i].$1, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w800)),
                                  ]),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
              ]),
            ]);
          },
        );
      }),
    );
  }
}

// ─── Quick tab ──────────────────────────────────────────────────────────────

List<String> _quickIds(YourDayActions a) => [
      for (final id in Settings.sanitizeQuickActions(Settings.instance.quickActions))
        if (id != 'glass' || a.onGlassToggle != null) id,
    ];

class _QuickTab extends StatefulWidget {
  const _QuickTab({required this.actions});
  final YourDayActions actions;
  @override
  State<_QuickTab> createState() => _QuickTabState();
}

class _QuickTabState extends State<_QuickTab> {
  void _run(String id) {
    final a = widget.actions;
    final nav = Navigator.of(context);
    AppHaptics.medium();
    switch (id) {
      case 'notifications':
        nav.pop();
        Future<void>.delayed(const Duration(milliseconds: 220), a.onNotifications);
      case 'store':
        nav.pop();
        a.onStore();
      case 'player':
        nav.pop();
        a.onPlayer();
      case 'glass':
        a.onGlassToggle?.call();
        setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Settings.instance, NotifStore.instance]),
      builder: (context, _) {
        final unread = NotifStore.instance.unreadRaw;
        final glassOn = widget.actions.glassOn?.call() ?? false;
        final tiles = <Widget>[
          for (final id in _quickIds(widget.actions))
            switch (id) {
              'notifications' => _ActionCard(
                  key: const ValueKey('your-day-qa-notifications'),
                  mark: NwsbMarks.bell,
                  title: 'Alerts',
                  sub: unread > 0 ? '$unread unread' : 'All caught up',
                  badge: unread,
                  onTap: () => _run(id)),
              'store' => _ActionCard(key: const ValueKey('your-day-qa-store'), mark: NwsbMarks.bag, title: 'Store', sub: 'Words, meanings, eBooks', onTap: () => _run(id)),
              'player' => _ActionCard(key: const ValueKey('your-day-qa-player'), mark: NwsbMarks.play, title: 'Player', sub: 'Start a session', onTap: () => _run(id)),
              _ => _ActionCard(
                  key: const ValueKey('your-day-qa-glass'),
                  mark: NwsbMarks.sliders,
                  title: 'Glass look',
                  sub: glassOn ? 'On · tap to turn off' : 'Off · tap to turn on',
                  active: glassOn,
                  onTap: () => _run(id)),
            },
          _ActionCard(
            key: const ValueKey('your-day-qa-customize'),
            mark: '<path d="M12 5v14M5 12h14"/>',
            title: 'Customize',
            sub: 'Pick your shortcuts',
            dashed: true,
            onTap: () => showCustomizeQuickActions(context),
          ),
        ];
        return _TabScroll(children: [
          const _TabLead('Your shortcuts', 'One tap to where you go most'),
          _Grid(extent: 92, children: tiles),
        ]);
      },
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({super.key, required this.mark, required this.title, required this.sub, required this.onTap, this.badge = 0, this.active = false, this.dashed = false});
  final String mark;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final int badge;
  final bool active;
  final bool dashed;
  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  var _down = false;
  @override
  Widget build(BuildContext context) {
    final w = widget;
    return Semantics(
      button: true,
      label: '${w.title}, ${w.sub}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: w.onTap,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 110),
          child: _Card(
            highlight: w.active,
            child: ExcludeSemantics(
              child: Row(children: [
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: w.active ? _gold : (w.dashed ? Colors.transparent : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: w.dashed ? Border.all(color: const Color(0x66FFFFFF), width: 1.2) : null,
                    ),
                    child: NwsbIcon(w.mark, size: 20, color: w.dashed ? Colors.white : Colors.black, strokeWidth: 1.9),
                  ),
                  if (w.badge > 0)
                    Positioned(
                      top: -5,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(color: const Color(0xFFE8434F), borderRadius: BorderRadius.circular(99), border: Border.all(color: _night, width: 1.5)),
                        child: Text(w.badge > 99 ? '99+' : '${w.badge}', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ]),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(w.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(w.sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _faint, fontSize: 11, fontWeight: FontWeight.w600, height: 1.25)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Today tab ──────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  const _TodayTab();
  @override
  Widget build(BuildContext context) => const _TabScroll(children: [
        _TabLead('Today\u2019s goals', 'Tap a goal to do it now'),
        ProgressPanel(bare: true),
      ]);
}

// ─── Your Earnings tab ──────────────────────────────────────────────────────

class _EarningsTab extends StatelessWidget {
  const _EarningsTab();

  void _push(BuildContext context, Widget page) {
    AppHaptics.medium();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  /// The rank whose word mark is [words], from the server's rank ladder.
  static String? _rankAt(EconomyMirror m, int words) {
    final earn = m.summary['earn'];
    final ranks = earn is Map ? earn['ranks'] : null;
    if (ranks is! List) return null;
    for (final r in ranks) {
      if (r is Map && (r['minWords'] as num?)?.toInt() == words) {
        final t = '${r['title'] ?? ''}';
        return t.isEmpty ? null : t;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([EconomyMirror.instance, FxBook.instance]),
      builder: (context, _) {
        final m = EconomyMirror.instance;
        final signedIn = m.live;
        final sold = m.wordsSold;
        final target = m.nextSellerTarget;
        final top = signedIn && sold > 0 && target <= sold;
        final next = _rankAt(m, target);
        const big = TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1);
        return _TabScroll(children: [
          const _TabLead('Your Earnings', 'Live from your NowssB account'),
          _Grid(extent: 118, children: [
            _Stat(
              key: const ValueKey('your-day-coins'),
              icon: const Icon(Icons.toll_rounded, size: 17, color: _gold),
              label: 'Coins',
              value: YourDayCount(m.coins, format: _coins, style: big),
              sub: signedIn ? 'In your wallet' : 'Sign in to see coins',
              onTap: () => _push(context, const CoinsScreen()),
            ),
            _Stat(
              key: const ValueKey('your-day-cash'),
              icon: const NwsbIcon(NwsbMarks.earn, size: 17, color: _gold),
              label: 'Cash earned',
              value: YourDayCount(m.lifetimeCents, format: _cents, style: big),
              sub: '${_cents(m.cash)} available',
              onTap: () => _push(context, const EarningsScreen()),
            ),
            _Stat(
              key: const ValueKey('your-day-sold'),
              icon: const NwsbIcon(NwsbMarks.wordBag, size: 17, color: _gold),
              label: 'Sold',
              value: YourDayCount(sold, format: _coins, style: big),
              sub: sold == 0 ? 'No sales yet' : 'Words & meanings',
              onTap: () => _push(context, const EarnTabsPage(initialTab: 'sales')),
            ),
            _Stat(
              key: const ValueKey('your-day-target'),
              icon: const NwsbIcon(NwsbMarks.trending, size: 17, color: _gold),
              label: 'Target',
              value: Text(signedIn ? '$sold / $target' : '0', maxLines: 1, style: big),
              progress: !signedIn || target <= 0 ? 0 : (sold / target).clamp(0.0, 1.0),
              sub: !signedIn
                  ? 'Sign in to see your target'
                  : top
                      ? 'Top rank reached'
                      : '${math.max(0, target - sold)} more to ${next ?? 'the next rank'}',
              onTap: () => _push(context, const EarnTabsPage(initialTab: 'targets')),
            ),
          ]),
          const SizedBox(height: 10),
          _Position(onTap: () => _push(context, const EarnTabsPage(initialTab: 'team'))),
        ]);
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.icon, required this.label, required this.value, required this.sub, required this.onTap, this.progress});
  final Widget icon;
  final String label;
  final Widget value;
  final String sub;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$label, $sub',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: _Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                icon,
                const SizedBox(width: 6),
                Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _mist, fontSize: 11.5, fontWeight: FontWeight.w700))),
                const Icon(Icons.chevron_right_rounded, size: 16, color: _faint),
              ]),
              const Spacer(),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
              if (progress != null) ...[
                const SizedBox(height: 7),
                _Bar(progress!),
              ],
              const SizedBox(height: 5),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _faint, fontSize: 10.5, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}

class _Bar extends StatelessWidget {
  const _Bar(this.value);
  final double value;
  @override
  Widget build(BuildContext context) {
    Widget bar(double v) => LayoutBuilder(
          builder: (context, c) => Stack(children: [
            Container(height: 5, decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(9))),
            Container(
              height: 5,
              width: c.maxWidth * v,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(colors: [Color(0xFFF3E6BF), Color(0xFFB9A2FF)]),
              ),
            ),
          ]),
        );
    if (_still(context)) return bar(value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => bar(v),
    );
  }
}

/// Your position: rank, place on this month's sellers board, people under you.
class _Position extends StatelessWidget {
  const _Position({required this.onTap});
  final VoidCallback onTap;

  static final _boards = <String, Stream<DocumentSnapshot<Map<String, dynamic>>>>{};
  static Stream<DocumentSnapshot<Map<String, dynamic>>> _board(String month) =>
      _boards.putIfAbsent(month, () => FirebaseFirestore.instance.doc('leaderboards/sellers_$month').snapshots().asBroadcastStream());

  /// (place, sellers on the board), or null when you are not on it.
  static (int, int)? _placeOf(Map<String, dynamic>? doc, String uid) {
    final raw = doc?['entries'];
    if (raw is! Map) return null;
    int words(Object? v) => v is Map ? ((v['words'] as num?)?.toInt() ?? 0) : 0;
    final ids = raw.keys.map((e) => '$e').toList()..sort((a, b) => words(raw[b]).compareTo(words(raw[a])));
    final i = ids.indexOf(uid);
    return i < 0 ? null : (i + 1, ids.length);
  }

  @override
  Widget build(BuildContext context) {
    final m = EconomyMirror.instance;
    final uid = m.uid;
    if (!NwsbFirebase.ready || uid == null) return _body(m, null);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _board(monthKeyIst()),
      builder: (context, snap) => _body(m, _placeOf(snap.data?.data(), uid)),
    );
  }

  Widget _body(EconomyMirror m, (int, int)? place) {
    final under = m.teamCount;
    final title = m.live ? m.sellerTier : 'Not ranked yet';
    Widget chip(String k, String v) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x1FFFFFFF))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _faint, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .4)),
              const SizedBox(height: 2),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(v, maxLines: 1, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))),
            ]),
          ),
        );
    return Semantics(
      button: true,
      label: 'Your position, $title',
      child: GestureDetector(
        key: const ValueKey('your-day-position'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _Card(
          highlight: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFF3E6BF), Color(0xFFD9B970)]),
                  boxShadow: [BoxShadow(color: Color(0x66D9B970), blurRadius: 14, offset: Offset(0, 4))],
                ),
                child: const NwsbIcon(NwsbMarks.crown, size: 20, color: Colors.black, strokeWidth: 1.9),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Your position', style: TextStyle(color: _mist, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, size: 22, color: _mist),
            ]),
            const SizedBox(height: 10),
            if (!m.live)
              const Text('Sign in to see your rank, your place and your team', style: TextStyle(color: _faint, fontSize: 11, fontWeight: FontWeight.w600))
            else
              Row(children: [
                chip('THIS MONTH', place == null ? 'Not on board' : '#${place.$1} of ${place.$2}'),
                const SizedBox(width: 8),
                chip('UNDER YOU', '$under ${under == 1 ? 'person' : 'people'}'),
              ]),
          ]),
        ),
      ),
    );
  }
}

// ─── shared bits ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child, this.highlight = false});
  final Widget child;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: highlight ? const [Color(0x338C6CFF), Color(0x0FFFFFFF)] : const [Color(0x1AFFFFFF), Color(0x08FFFFFF)],
          ),
          border: Border.all(color: highlight ? const Color(0x4DB9A2FF) : const Color(0x24FFFFFF)),
        ),
        child: child,
      );
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children, required this.extent});
  final List<Widget> children;
  final double extent;
  @override
  Widget build(BuildContext context) => GridView(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: extent),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      );
}

class _TabLead extends StatelessWidget {
  const _TabLead(this.title, this.sub);
  final String title;
  final String sub;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: _faint, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _TabScroll extends StatelessWidget {
  const _TabScroll({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
        children: children,
      );
}
