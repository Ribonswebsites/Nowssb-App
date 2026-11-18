/// Normal Home "Your essentials": the signed-in account's own daily routine.
///
/// The top card is a colourful auto-rotating carousel — one card per step —
/// and the timeline under it stays in the original plain, neutral style.
/// Each step ticks itself from the real action ([DailyTasks.markEvent]):
/// finishing a word in the player, opening the player, opening a word's
/// meaning. The list resets at local midnight and is kept per account
/// (see [DailyTasks]).
library;

import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';

import '../../admin/template/editable.dart';
import '../../data/app_haptics.dart';
import '../../data/content.dart';
import '../../data/home_widget_sync.dart';
import '../../data/models.dart';
import '../../data/settings.dart';
import '../../shell/nav_shell.dart';
import '../../theme/tokens.dart';
import '../daily_tasks.dart';
import '../practice_player.dart';
import '../word_detail.dart';
import 'glassmorphism_theme.dart';
import 'home_v4.dart' show V4Lottie, kMeditateLottie;

/// One step's soft colour: [accent] for the chip and [fill] for the
/// carousel card's tinted gradient. Timeline rows under the carousel
/// stay plain.
@immutable
class EssentialTint {
  const EssentialTint(this.accent, this.fill);
  final Color accent;
  final List<Color> fill;

  static const word =
      EssentialTint(Color(0xFF7E57C2), [Color(0xFFF1E9FC), Color(0xFFDCCBF5)]);
  static const player =
      EssentialTint(Color(0xFF1D93A3), [Color(0xFFE4F5F6), Color(0xFFC6EAEE)]);
  static const read =
      EssentialTint(Color(0xFFDB7448), [Color(0xFFFDEEE4), Color(0xFFF7D7C3)]);
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

  /// Tests and screenshots: stop the 5 s auto-advance.
  static bool autoAdvance = true;
  static const every = Duration(seconds: 5);
  static const glide = Duration(milliseconds: 600);
  static const curve = Curves.easeInOutCubic;

  /// The colourful top carousel, so tests can jump to a card.
  @visibleForTesting
  static final carousel = GlobalKey<EssentialsCarouselState>();

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
      return HomeWidgetSync.wordFor(
          DateTime.now(), ContentStore.instance.library);
    } catch (_) {
      return null;
    }
  }

  static String _cap(String s) {
    final t = s.trim();
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    await DailyTasks.publish();
  }

  Future<void> _open(DailyTaskView t) async {
    AppHaptics.selection();
    final w = _today;
    switch (t.id) {
      case 'word':
        if (w == null) return NavScope.goTo(context, 1);
        await _push(PracticePlayerScreen(
            words: [w], title: "Today's word", showIntro: false));
      case 'player':
        final lib = ContentStore.instance.library;
        if (lib.isEmpty) return NavScope.goTo(context, 2);
        final at = w == null
            ? 0
            : lib.indexWhere((x) => x.key == w.key).clamp(0, lib.length - 1);
        await _push(PracticePlayerScreen(
            words: [...lib.skip(at), ...lib.take(at)], title: 'Player'));
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
        return name.isEmpty
            ? "Open any word's meaning"
            : 'The meaning of $name';
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

  List<Widget> _taskRows(List<DailyTaskView> all) {
    final shown = _expanded || all.length <= 4 ? all : all.take(4).toList();
    return [
      for (var i = 0; i < shown.length; i++)
        _TimelineEntry(
          key: ValueKey('essential-row-${shown[i].id}'),
          icon: _iconFor(shown[i].id),
          title: shown[i].title,
          done: shown[i].done,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Row(children: [
              const Expanded(
                child: EditableLabel(
                    'neomorphic_essentials.NmSuppliedEssentials',
                    'Your essentials',
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: _text)),
              ),
              if (all.isNotEmpty)
                Container(
                  key: const ValueKey('essentials-counter'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: glass ? const Color(0x66FFFFFF) : _base,
                    borderRadius: BorderRadius.circular(20),
                    border: glass
                        ? Border.all(color: const Color(0xF2FFFFFF), width: 1.5)
                        : null,
                    boxShadow: glass ? null : NwsbShadows.raisedXs,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(allDone ? Icons.check_rounded : Icons.timeline_rounded,
                        size: 15, color: _subtext),
                    const SizedBox(width: 6),
                    Text(
                        allDone
                            ? 'All $finished done'
                            : '$finished of ${all.length} done',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _text)),
                  ]),
                ),
            ]),
          ),
          if (all.isNotEmpty)
            EssentialsCarousel(
              key: NmSuppliedEssentials.carousel,
              tasks: all,
              infoFor: _info,
              iconFor: _iconFor,
              onOpen: _open,
            ),
          const SizedBox(height: 8),
          ..._taskRows(all),
          if (allDone)
            const Padding(
              padding: EdgeInsets.only(left: 40, bottom: 6),
              child: Row(children: [
                V4Lottie(kMeditateLottie, size: 44),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Your routine is done for today. It starts fresh tomorrow.',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _subtext)),
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
                        border: glass
                            ? Border.all(
                                color: const Color(0xF2FFFFFF), width: 1.5)
                            : null,
                        boxShadow: glass ? null : NwsbShadows.raisedXs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_expanded ? 'See less' : 'See more',
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: _subtext)),
                        const SizedBox(width: 10),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: glass ? const Color(0x66FFFFFF) : _base,
                              shape: BoxShape.circle,
                              border: glass
                                  ? Border.all(
                                      color: const Color(0xF2FFFFFF),
                                      width: 1.5)
                                  : null,
                              boxShadow: glass ? null : NwsbShadows.raisedXs),
                          child: Icon(
                              _expanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
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

/// Colourful auto-rotating top cards: one per routine step.
class EssentialsCarouselState extends State<EssentialsCarousel> {
  PageController? _page;
  final _pageHaptic = UserPageHapticGate();
  Timer? _tick;
  Timer? _resume;
  var _held = false;
  var _index = 0;
  var _length = 0;

  bool get _still => !Settings.instance.fashionPlus;
  bool get _canTick =>
      NmSuppliedEssentials.autoAdvance && !_still && !_held && _length > 1;

  int get index => _index;

  void jumpTo(int i) {
    if (_page == null || !_page!.hasClients || _length <= 0) return;
    final next = i.clamp(0, _length - 1);
    _page!.jumpToPage(next);
    setState(() => _index = next);
  }

  static int firstOpen(List<DailyTaskView> all) {
    final i = all.indexWhere((t) => !t.done);
    return i < 0 ? 0 : i;
  }

  static bool _anyFlipped(List<DailyTaskView> before, List<DailyTaskView> after,
      {required bool toDone}) {
    final byId = {for (final t in before) t.id: t.done};
    for (final t in after) {
      final was = byId[t.id];
      if (was == null) continue;
      if (toDone && t.done && !was) return true;
      if (!toDone && !t.done && was) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    Settings.instance.addListener(_onMotion);
    _length = widget.tasks.length;
    _index = firstOpen(widget.tasks);
    _page = PageController(initialPage: _index);
    _startTicking();
  }

  @override
  void didUpdateWidget(covariant EssentialsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextLen = widget.tasks.length;
    if (nextLen != _length) {
      final open = firstOpen(widget.tasks);
      _page?.dispose();
      _length = nextLen;
      _index = open;
      _page = PageController(initialPage: open);
      _startTicking();
      return;
    }
    // A new tick or a midnight reset should land on the first open
    // step. Auto-rotation through already-done cards is left alone.
    final open = firstOpen(widget.tasks);
    final completed = _anyFlipped(oldWidget.tasks, widget.tasks, toDone: true);
    final reset = _anyFlipped(oldWidget.tasks, widget.tasks, toDone: false);
    if ((completed || reset) && open != _index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        jumpTo(open);
      });
    }
  }

  @override
  void dispose() {
    Settings.instance.removeListener(_onMotion);
    _tick?.cancel();
    _resume?.cancel();
    _page?.dispose();
    super.dispose();
  }

  void _onMotion() {
    if (!mounted) return;
    if (_still) {
      _tick?.cancel();
      _resume?.cancel();
    } else if (!_held) {
      _startTicking();
    }
  }

  void _startTicking() {
    _tick?.cancel();
    if (!_canTick) return;
    _tick = Timer.periodic(NmSuppliedEssentials.every, (_) {
      if (!_canTick || !mounted || _page == null || !_page!.hasClients) return;
      final cur = (_page!.page ?? _index.toDouble()).round();
      _page!.animateToPage((cur + 1) % _length,
          duration: NmSuppliedEssentials.glide,
          curve: NmSuppliedEssentials.curve);
    });
  }

  void _hold() {
    _held = true;
    _resume?.cancel();
    _tick?.cancel();
  }

  void _release() {
    _resume?.cancel();
    _resume = Timer(NmSuppliedEssentials.every, () {
      _held = false;
      if (!_still) _startTicking();
    });
  }

  void _onPage(int i) {
    if (i != _index) setState(() => _index = i);
    _pageHaptic.onPageChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final narrow = _narrow(context);
    // Room for the card's text at large type. Indicators sit under
    // this box, so they are not included here. Grows with the text
    // scale so nothing is cut off at 360 / 1.3.
    final room = (narrow ? 216.0 : 200.0) * scale;
    final page = _page;
    if (page == null || _length == 0) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The day's word changes the card text ('The meaning of ...'), so
        // the page box also grows to the tallest card's real text height.
        LayoutBuilder(builder: (context, box) {
        final height = math.max(
            room,
            _HeroEssential.heightFor(context, box.maxWidth, [
                  for (final t in widget.tasks)
                    (t.title, widget.infoFor(t.id), t.done),
                ]) +
                4);
        return Listener(
          onPointerDown: (_) => _hold(),
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          child: SizedBox(
            height: height,
            child: NotificationListener<ScrollNotification>(
              onNotification: _pageHaptic.onScroll,
              child: PageView.builder(
                key: const ValueKey('essentials-pages'),
                controller: page,
                itemCount: _length,
                physics:
                    const PageScrollPhysics(parent: BouncingScrollPhysics()),
                onPageChanged: _onPage,
                itemBuilder: (context, i) {
                  final t = widget.tasks[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onOpen(t),
                      child: _HeroEssential(
                        key: ValueKey('essential-${t.id}'),
                        step: i + 1,
                        total: _length,
                        tint: EssentialTint.of(t.id, i),
                        icon: widget.iconFor(t.id),
                        title: t.title,
                        info: widget.infoFor(t.id),
                        done: t.done,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        }),
        if (_length > 1)
          _DashIndicators(
            count: _length,
            index: _index,
            accent: EssentialTint.of(
                    widget.tasks[_index.clamp(0, _length - 1)].id,
                    _index.clamp(0, _length - 1))
                .accent,
            onSelect: (i) {
              AppHaptics.selection();
              _hold();
              if (_page != null && _page!.hasClients) {
                _page!.animateToPage(i,
                    duration: NmSuppliedEssentials.glide,
                    curve: NmSuppliedEssentials.curve);
              }
              _release();
            },
          ),
      ],
    );
  }
}

class EssentialsCarousel extends StatefulWidget {
  const EssentialsCarousel({
    super.key,
    required this.tasks,
    required this.infoFor,
    required this.iconFor,
    required this.onOpen,
  });

  final List<DailyTaskView> tasks;
  final String Function(String id) infoFor;
  final IconData Function(String id) iconFor;
  final ValueChanged<DailyTaskView> onOpen;

  @override
  State<EssentialsCarousel> createState() => EssentialsCarouselState();
}

/// Small bars under the carousel — dashes, not circles.
class _DashIndicators extends StatelessWidget {
  const _DashIndicators({
    required this.count,
    required this.index,
    required this.accent,
    required this.onSelect,
  });
  final int count;
  final int index;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: i == index ? 18 : 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i == index ? accent : const Color(0xFFC7CDD9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    super.key,
    required this.icon,
    required this.title,
    required this.done,
    required this.last,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool done;
  final bool last;
  final VoidCallback onTap;

  static const _base = Color(0xFFECEEF2);
  static const _purple = Color(0xFF7E57C2);

  @override
  Widget build(BuildContext context) {
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
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: done
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFB794F6), _purple],
                              )
                            : null,
                        color: done ? null : _base,
                        boxShadow: done
                            ? const [
                                BoxShadow(
                                    color: Color(0x337E57C2),
                                    blurRadius: 7,
                                    spreadRadius: 3),
                                BoxShadow(
                                    color: Color(0x55000000),
                                    offset: Offset(3, 3),
                                    blurRadius: 6),
                                BoxShadow(
                                    color: Colors.white,
                                    offset: Offset(-2, -2),
                                    blurRadius: 6),
                              ]
                            : NwsbShadows.raisedXs,
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded,
                              size: 11, color: Colors.white)
                          : null,
                    ),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(
                        width: 3,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: done ? _purple : const Color(0xFFC7CDD9),
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
                  child: _PillEssential(icon: icon, title: title, done: done),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroEssential extends StatelessWidget {
  const _HeroEssential({
    super.key,
    required this.step,
    required this.total,
    required this.tint,
    required this.icon,
    required this.title,
    required this.info,
    required this.done,
  });
  final int step;
  final int total;
  final EssentialTint tint;
  final IconData icon;
  final String title;
  final String info;
  final bool done;

  static const _ink = Color(0xFF1E2233);
  static const _inkSoft = Color(0xFF4A4E63);

  /// Height [build] needs at [width] for the tallest of [cards]
  /// (title, info, done), measured with the same styles, so the carousel's
  /// fixed page box never cuts a card off at any word, width or text size.
  static double heightFor(BuildContext context, double width,
      List<(String, String, bool)> cards) {
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final base = DefaultTextStyle.of(context).style;
    final narrow = _narrow(context);
    double h(String text, TextStyle style, double maxW, {int? lines}) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: base.merge(style)),
        textDirection: dir,
        textScaler: scaler,
        maxLines: lines,
      )..layout(maxWidth: math.max(0.0, maxW));
      final out = tp.height;
      tp.dispose();
      return out;
    }

    // Padding 20 plus the 1px border on each side.
    final inner = width - 42 - (narrow ? 0 : 84);
    final pill = h('Step 9 of 9',
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            inner) +
        10;
    var tallest = 0.0;
    for (final (title, info, done) in cards) {
      final t = h(title,
          const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          inner - 50,
          lines: 3);
      final i = h(info,
          const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
          inner - 22);
      final d = h(done ? 'Done' : 'To do',
          const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
          inner);
      final col = math.max(pill, narrow ? 48.0 : 0.0) +
          14 +
          math.max(38.0, t) +
          12 +
          math.max(16.0, i) +
          6 +
          math.max(16.0, d);
      tallest = math.max(tallest, math.max(148.0, col + 42));
    }
    return tallest;
  }

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 148),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: tint.fill),
          border: Border.all(color: const Color(0xB3FFFFFF)),
          boxShadow: NwsbShadows.raised,
        ),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: const Color(0xCCFFFFFF),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('Step $step of $total',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: tint.accent,
                                fontWeight: FontWeight.w800)),
                      ),
                      const Spacer(),
                      if (narrow) const V4Lottie(kMeditateLottie, size: 48),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      _IconChip(
                          icon: icon,
                          color: Colors.white,
                          fill: tint.accent,
                          size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(title,
                            maxLines: 3,
                            softWrap: true,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _ink)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.graphic_eq_rounded,
                          size: 16, color: tint.accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(info,
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: _inkSoft)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const SizedBox(width: 22),
                      Text(done ? 'Done' : 'To do',
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: tint.accent)),
                      const SizedBox(width: 6),
                      Icon(
                          done
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 16,
                          color: tint.accent),
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

class _IconChip extends StatelessWidget {
  const _IconChip(
      {required this.icon, required this.color, this.fill, this.size = 44});
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

/// Original plain pill: grey surface, no per-step colour.
class _PillEssential extends StatelessWidget {
  const _PillEssential(
      {required this.icon, required this.title, required this.done});
  final IconData icon;
  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
          color: glass ? const Color(0x66FFFFFF) : const Color(0xFFECEEF2),
          borderRadius: BorderRadius.circular(20),
          border: glass
              ? Border.all(color: const Color(0xF2FFFFFF), width: 1.5)
              : null,
          boxShadow: glass ? null : NwsbShadows.raisedSm),
      child: Builder(builder: (context) {
        final narrow = _narrow(context);
        final marks = <Widget>[
          Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: Color(0xFFECEEF2),
                  shape: BoxShape.circle,
                  boxShadow: NwsbShadows.raisedXs),
              child: Icon(
                  done ? Icons.check_rounded : Icons.lock_outline_rounded,
                  color:
                      done ? const Color(0xFF2B2D33) : const Color(0xFF9AA0AB),
                  size: 18)),
          const SizedBox(width: 8),
          Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: Color(0xFFECEEF2),
                  shape: BoxShape.circle,
                  boxShadow: NwsbShadows.raisedXs),
              child: Icon(icon, color: const Color(0xFF9AA0AB), size: 20)),
        ];
        const titleStyle = TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2D33));
        final text =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          narrow
              ? Text(title, maxLines: 3, softWrap: true, style: titleStyle)
              : EditableLabel('neomorphic_essentials.PillEssential', title,
                  style: titleStyle),
          const SizedBox(height: 3),
          Text(done ? 'Done' : 'To do',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF8A8F9A))),
        ]);
        if (narrow) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: marks),
                const SizedBox(height: 10),
                text,
              ]);
        }
        return Row(children: [
          ...marks,
          const SizedBox(width: 14),
          Expanded(child: text)
        ]);
      }),
    );
  }
}

/// Narrow = the essentials cards would leave under ~ 18 em for the words.
bool _narrow(BuildContext context) =>
    MediaQuery.sizeOf(context).width <
    400 * MediaQuery.textScalerOf(context).scale(1);
