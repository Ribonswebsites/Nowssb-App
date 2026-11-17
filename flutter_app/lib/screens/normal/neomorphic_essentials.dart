/// Normal Home "Your essentials": the signed-in account's own daily routine
/// as a timeline. Each step ticks itself from the real action
/// ([DailyTasks.markEvent]): finishing a word in the player, opening the
/// player, opening a word's meaning. The next step then becomes the open
/// card and the line fills down to it. The list resets at local midnight
/// and is kept per account (see [DailyTasks]).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/home_widget_sync.dart';
import '../../data/models.dart';
import '../../shell/nav_shell.dart';
import '../../theme/tokens.dart';
import '../daily_tasks.dart';
import '../practice_player.dart';
import '../word_detail.dart';
import 'glassmorphism_theme.dart';
import 'home_v4.dart' show V4Lottie, kMeditateLottie;
import '../../admin/template/editable.dart';

/// One step's soft colour: [accent] for the chip, node and line, [fill]
/// for the card's tinted gradient.
@immutable
class EssentialTint {
  const EssentialTint(this.accent, this.fill);
  final Color accent;
  final List<Color> fill;

  static const word = EssentialTint(Color(0xFF7E57C2), [Color(0xFFF1E9FC), Color(0xFFDCCBF5)]);
  static const player = EssentialTint(Color(0xFF1D93A3), [Color(0xFFE4F5F6), Color(0xFFC6EAEE)]);
  static const read = EssentialTint(Color(0xFFDB7448), [Color(0xFFFDEEE4), Color(0xFFF7D7C3)]);
  static const _pool = <EssentialTint>[
    EssentialTint(Color(0xFFC8558A), [Color(0xFFFCE9F1), Color(0xFFF5D0E1)]),
    EssentialTint(Color(0xFF3C9466), [Color(0xFFE6F5EC), Color(0xFFC9E9D5)]),
    EssentialTint(Color(0xFF4A6FD6), [Color(0xFFE8EEFC), Color(0xFFCCDAF7)]),
  ];

  static EssentialTint of(String id, int index) => switch (id) {
        'word' => word,
        'player' => player,
        'read' => read,
        _ => _pool[index % _pool.length],
      };
}

class NmSuppliedEssentials extends StatefulWidget {
  const NmSuppliedEssentials({super.key});

  @override
  State<NmSuppliedEssentials> createState() => _NmSuppliedEssentialsState();
}

class _NmSuppliedEssentialsState extends State<NmSuppliedEssentials>
    with WidgetsBindingObserver {
  var _expanded = false;
  Timer? _midnight;

  static const _base = Color(0xFFECEEF2);
  static const _text = Color(0xFF2B2D33);
  static const _subtext = Color(0xFF8A8F9A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DailyTasks.items.addListener(_tick);
    ContentStore.instance.addListener(_tick);
    DailyTasks.watchAccount();
    unawaited(DailyTasks.publish());
    _armMidnight();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DailyTasks.items.removeListener(_tick);
    ContentStore.instance.removeListener(_tick);
    _midnight?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(DailyTasks.publish());
      _armMidnight();
    }
  }

  /// A fresh routine at local midnight, even with the home left open.
  void _armMidnight() {
    _midnight?.cancel();
    final now = DailyTasks.clock();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), () {
      unawaited(DailyTasks.publish());
      _armMidnight();
    });
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  Word? get _today {
    try {
      return HomeWidgetSync.wordFor(DateTime.now(), ContentStore.instance.library);
    } catch (_) {
      return null;
    }
  }

  static String _cap(String s) {
    final t = s.trim();
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    await DailyTasks.publish();
  }

  Future<void> _open(DailyTaskView t) async {
    final w = _today;
    switch (t.id) {
      case 'word':
        if (w == null) return NavScope.goTo(context, 1);
        await _push(PracticePlayerScreen(words: [w], title: "Today's word", showIntro: false));
      case 'player':
        final lib = ContentStore.instance.library;
        if (lib.isEmpty) return NavScope.goTo(context, 2);
        final at = w == null ? 0 : lib.indexWhere((x) => x.key == w.key).clamp(0, lib.length - 1);
        await _push(PracticePlayerScreen(words: [...lib.skip(at), ...lib.take(at)], title: 'Player'));
      case 'read':
        if (w == null) return NavScope.goTo(context, 2);
        await _push(WordDetail(word: w));
      default:
        await _push(const DailyTasksPage());
    }
  }

  String _info(String id) {
    final w = _today;
    final name = w == null ? '' : _cap(w.word);
    switch (id) {
      case 'word':
        return name.isEmpty ? 'Any word you like' : "Today's word · $name";
      case 'player':
        return name.isEmpty ? 'Press play on any word' : 'Press play on $name';
      case 'read':
        return name.isEmpty ? "Open any word's meaning" : 'The meaning of $name';
      default:
        return 'Tick it off when it is done';
    }
  }

  IconData _iconFor(String id) => switch (id) {
        'word' => Icons.self_improvement_rounded,
        'player' => Icons.play_arrow_rounded,
        'read' => Icons.auto_stories_outlined,
        _ => Icons.task_alt_outlined,
      };

  List<Widget> _taskEntries(List<DailyTaskView> all) {
    final active = all.indexWhere((t) => !t.done);
    final shown = _expanded || all.length <= 4 ? all : all.take(4).toList();
    return [
      for (var i = 0; i < shown.length; i++)
        _TimelineEntry(
          key: ValueKey('essential-${shown[i].id}'),
          step: i + 1,
          total: all.length,
          tint: EssentialTint.of(shown[i].id, i),
          nextTint: i + 1 < shown.length ? EssentialTint.of(shown[i + 1].id, i + 1) : null,
          icon: _iconFor(shown[i].id),
          title: shown[i].title,
          info: _info(shown[i].id),
          state: shown[i].done
              ? _StepState.done
              : (i == active ? _StepState.active : _StepState.locked),
          last: i == shown.length - 1,
          onTap: () => _open(shown[i]),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
    final all = DailyTasks.items.value;
    final finished = all.where((t) => t.done).length;
    final allDone = all.isNotEmpty && finished == all.length;
    final counterTint = allDone
        ? EssentialTint.of(all.last.id, all.length - 1)
        : EssentialTint.of(all.isEmpty ? 'word' : all[all.indexWhere((t) => !t.done)].id,
            all.isEmpty ? 0 : all.indexWhere((t) => !t.done));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 18),
            child: Row(children: [
              const Expanded(
                child: EditableLabel('neomorphic_essentials.NmSuppliedEssentials', 'Your essentials',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: _text)),
              ),
              if (all.isNotEmpty)
                AnimatedContainer(
                  key: const ValueKey('essentials-counter'),
                  duration: const Duration(milliseconds: 320),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: counterTint.fill),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: glass ? null : NwsbShadows.raisedXs,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(allDone ? Icons.check_rounded : Icons.timeline_rounded,
                        size: 15, color: counterTint.accent),
                    const SizedBox(width: 6),
                    Text(allDone ? 'All $finished done' : '$finished of ${all.length} done',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800, color: counterTint.accent)),
                  ]),
                ),
            ]),
          ),
          ..._taskEntries(all),
          if (allDone)
            const Padding(
              padding: EdgeInsets.only(left: 40, bottom: 6),
              child: Row(children: [
                V4Lottie(kMeditateLottie, size: 44),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Your routine is done for today. It starts fresh tomorrow.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _subtext)),
                ),
              ]),
            ),
          if (all.length > 4)
            Padding(
              padding: const EdgeInsets.only(left: 38, top: 4, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
                    decoration: BoxDecoration(
                        color: glass ? const Color(0x66FFFFFF) : _base,
                        borderRadius: BorderRadius.circular(22),
                        border: glass ? Border.all(color: const Color(0xF2FFFFFF), width: 1.5) : null,
                        boxShadow: glass ? null : NwsbShadows.raisedXs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_expanded ? 'See less' : 'See more',
                            style: const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w700, color: _subtext)),
                        const SizedBox(width: 10),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: glass ? const Color(0x66FFFFFF) : _base,
                              shape: BoxShape.circle,
                              border: glass
                                  ? Border.all(color: const Color(0xF2FFFFFF), width: 1.5)
                                  : null,
                              boxShadow: glass ? null : NwsbShadows.raisedXs),
                          child: Icon(
                              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 18,
                              color: _subtext),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _StepState { done, active, locked }

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    super.key,
    required this.step,
    required this.total,
    required this.tint,
    required this.nextTint,
    required this.icon,
    required this.title,
    required this.info,
    required this.state,
    required this.last,
    required this.onTap,
  });

  final int step;
  final int total;
  final EssentialTint tint;
  final EssentialTint? nextTint;
  final IconData icon;
  final String title;
  final String info;
  final _StepState state;
  final bool last;
  final VoidCallback onTap;

  static const _base = Color(0xFFECEEF2);
  static const _fade = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    final done = state == _StepState.done;
    final card = state == _StepState.active
        ? _HeroEssential(step: step, total: total, tint: tint, icon: icon, title: title, info: info)
        : _PillEssential(tint: tint, icon: icon, title: title, done: done);
    return Semantics(
      button: true,
      label: '$title, ${done ? 'done' : 'to do'}',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 26),
                    child: AnimatedContainer(
                      duration: _fade,
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: state == _StepState.locked
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: done
                                    ? [Color.lerp(tint.accent, Colors.white, .25)!, tint.accent]
                                    : [tint.fill.last, Color.lerp(tint.accent, Colors.white, .35)!],
                              ),
                        color: state == _StepState.locked ? _base : null,
                        boxShadow: NwsbShadows.raisedXs,
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                          : null,
                    ),
                  ),
                  if (!last)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        // The line fills down to the next step once this one is done.
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: done ? 1 : 0),
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => CustomPaint(
                            size: const Size(3, 0),
                            painter: _LinePainter(v, tint.accent, (nextTint ?? tint).accent),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeOutCubic,
                    child: KeyedSubtree(key: ValueKey(state), child: card),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter(this.fill, this.from, this.to);
  final double fill;
  final Color from;
  final Color to;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 3.0;
    final x = (size.width - w) / 2;
    final track = RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, w, size.height), const Radius.circular(2));
    canvas.drawRRect(track, Paint()..color = const Color(0xFFC7CDD9));
    if (fill <= 0) return;
    final rect = Rect.fromLTWH(x, 0, w, size.height * fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [from, to],
        ).createShader(Rect.fromLTWH(x, 0, w, size.height)),
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.fill != fill || old.from != from || old.to != to;
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.color, this.fill, this.size = 44});
  final IconData icon;
  final Color color;
  final Color? fill;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill ?? const Color(0xFFF6F7FA),
          borderRadius: BorderRadius.circular(size * .34),
          boxShadow: NwsbShadows.raisedXs,
        ),
        child: Icon(icon, color: color, size: size * .48),
      );
}

class _HeroEssential extends StatelessWidget {
  const _HeroEssential({
    required this.step,
    required this.total,
    required this.tint,
    required this.icon,
    required this.title,
    required this.info,
  });
  final int step;
  final int total;
  final EssentialTint tint;
  final IconData icon;
  final String title;
  final String info;

  static const _ink = Color(0xFF1E2233);
  static const _inkSoft = Color(0xFF4A4E63);

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 148),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tint.fill),
          border: Border.all(color: const Color(0xB3FFFFFF)),
          boxShadow: NwsbShadows.raised,
        ),
        // No LayoutBuilder here: the timeline row sizes us with
        // IntrinsicHeight. On narrow phones / large text the art moves into
        // the top row and the words take the full card width.
        child: Builder(builder: (context) {
          final narrow = _narrow(context);
          return Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(right: narrow ? 0 : 84),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: const Color(0xCCFFFFFF),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('Step $step of $total',
                            style: TextStyle(
                                fontSize: 12.5, color: tint.accent, fontWeight: FontWeight.w800)),
                      ),
                      const Spacer(),
                      if (narrow) const V4Lottie(kMeditateLottie, size: 48),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      _IconChip(icon: icon, color: Colors.white, fill: tint.accent, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(title,
                            maxLines: 3,
                            softWrap: true,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.graphic_eq_rounded, size: 16, color: tint.accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(info,
                            style: const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w600, color: _inkSoft)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const SizedBox(width: 22),
                      Text('To do',
                          style: TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w800, color: tint.accent)),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: tint.accent),
                    ]),
                  ],
                ),
              ),
              if (!narrow)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: V4Lottie(kMeditateLottie, size: 64),
                ),
            ],
          );
        }),
      );
}

class _PillEssential extends StatelessWidget {
  const _PillEssential(
      {required this.tint, required this.icon, required this.title, required this.done});
  final EssentialTint tint;
  final IconData icon;
  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
          gradient: done
              ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tint.fill)
              : null,
          color: done ? null : (glass ? const Color(0x66FFFFFF) : const Color(0xFFECEEF2)),
          borderRadius: BorderRadius.circular(20),
          border: glass && !done ? Border.all(color: const Color(0xF2FFFFFF), width: 1.5) : null,
          boxShadow: glass && !done ? null : NwsbShadows.raisedSm),
      // On narrow phones / large text the chips go on top so the title gets
      // the full width (no LayoutBuilder: IntrinsicHeight).
      child: Builder(builder: (context) {
        final narrow = _narrow(context);
        final chips = <Widget>[
          done
              ? _IconChip(icon: Icons.check_rounded, color: Colors.white, fill: tint.accent)
              : const _IconChip(icon: Icons.lock_outline_rounded, color: Color(0xFF9AA0AB)),
          const SizedBox(width: 8),
          _IconChip(
              icon: icon,
              color: done ? tint.accent : Color.lerp(tint.accent, const Color(0xFFECEEF2), .25)!,
              fill: done ? const Color(0xE6FFFFFF) : tint.fill.first),
        ];
        final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              maxLines: 3,
              softWrap: true,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2B2D33))),
          const SizedBox(height: 3),
          Text(done ? 'Done' : 'To do',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: done ? FontWeight.w800 : FontWeight.w500,
                  color: done ? tint.accent : const Color(0xFF8A8F9A))),
        ]);
        if (narrow) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: chips),
            const SizedBox(height: 10),
            text,
          ]);
        }
        return Row(children: [...chips, const SizedBox(width: 14), Expanded(child: text)]);
      }),
    );
  }
}

/// Narrow = the essentials cards would leave under ~ 18 em for the words.
bool _narrow(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 400 * MediaQuery.textScalerOf(context).scale(1);
