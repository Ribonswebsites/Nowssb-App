/// Get Started: seven real first steps through NowssB, one card each.
///
/// 1 today's word (Word detail) · 2 practise it (the player) · 3 the player
/// guide · 4 the Sound Library · 5 save a word (Saved words) · 6 today's
/// tasks · 7 NowssB Connect. Every card opens that page. The stepper above
/// shows which steps the person has really done ([GetStartedProgress]) and
/// jumps to a card when tapped.
///
/// The cards are black Store-style cards inside the Zen home glass
/// ([GlassWrap]). Their art is word-only: the day's word, its sound parts,
/// the Sound Library's categories, the saved words, today's task list.
/// The row moves every 5 s over 600 ms (easeInOutCubic), holds while a
/// finger is on it and carries on 5 s after the finger lifts.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../admin/template/editable.dart';
import '../../data/content.dart';
import '../../data/home_widget_sync.dart';
import '../../data/models.dart';
import '../../media/onboarding_warmup.dart';
import '../../shell/nav_shell.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import '../daily_tasks.dart';
import '../player_guide.dart';
import '../practice_player.dart';
import '../saved_words.dart';
import '../sound_library.dart';
import '../word_detail.dart';
import 'essentials_process_line.dart';
import 'glassmorphism_theme.dart';
import 'get_started_progress.dart';

class NmHorizontalRoutineCards extends StatefulWidget {
  const NmHorizontalRoutineCards({super.key, this.fashion = false});

  /// Zen home (dark glass). Off: the light surface of the Normal home.
  final bool fashion;

  /// Tests and screenshots: stop the 5 s auto-advance.
  static bool autoAdvance = true;

  static const every = Duration(seconds: 5);
  static const glide = Duration(milliseconds: 600);
  static const curve = Curves.easeInOutCubic;

  @override
  State<NmHorizontalRoutineCards> createState() => _NmHorizontalRoutineCardsState();
}

class _NmHorizontalRoutineCardsState extends State<NmHorizontalRoutineCards> {
  final _cards = ScrollController();
  final _progress = GetStartedProgress.instance;
  var _active = 0;
  var _stride = 314.0;
  Timer? _tick;
  Timer? _resume;
  var _held = false;
  List<String> _saved = const [];
  List<String> _tasks = const [];
  Set<String> _tasksDone = const {};

  @override
  void initState() {
    super.initState();
    _cards.addListener(_onScroll);
    _progress.addListener(_onChange);
    ContentStore.instance.addListener(_onChange);
    unawaited(_progress.load());
    unawaited(_loadLists());
    _startTicking();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _resume?.cancel();
    _progress.removeListener(_onChange);
    ContentStore.instance.removeListener(_onChange);
    _cards
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadLists() async {
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getStringList(GetStartedProgress.likedWordsKey) ?? const <String>[];
      final tasks = await DailyTasks.template();
      final ticked = await DailyTasks.done();
      if (!mounted) return;
      setState(() {
        _saved = saved;
        _tasks = [for (final t in tasks) t.title];
        _tasksDone = {for (final t in tasks) if (ticked.contains(t.id)) t.title};
      });
    } catch (_) {}
  }

  // ── carousel ──────────────────────────────────────────────────────
  void _startTicking() {
    _tick?.cancel();
    if (!NmHorizontalRoutineCards.autoAdvance) return;
    _tick = Timer.periodic(NmHorizontalRoutineCards.every, (_) {
      if (!_held && mounted) _scrollTo((_active + 1) % GetStartedProgress.steps.length);
    });
  }

  void _hold() {
    _held = true;
    _resume?.cancel();
    _tick?.cancel();
  }

  void _release() {
    _resume?.cancel();
    _resume = Timer(NmHorizontalRoutineCards.every, () {
      _held = false;
      _startTicking();
    });
  }

  void _onScroll() {
    final next = (_cards.offset / _stride).round().clamp(0, GetStartedProgress.steps.length - 1);
    if (next != _active && mounted) setState(() => _active = next);
  }

  void _scrollTo(int i) {
    setState(() => _active = i);
    if (!_cards.hasClients) return;
    final max = _cards.position.maxScrollExtent;
    _cards.animateTo((i * _stride).clamp(0.0, max),
        duration: NmHorizontalRoutineCards.glide, curve: NmHorizontalRoutineCards.curve);
  }

  /// A dot was tapped: jump there and pause like a touch.
  void _jump(int i) {
    _hold();
    _scrollTo(i);
    _release();
  }

  // ── where each card goes ──────────────────────────────────────────
  Word? get _today => HomeWidgetSync.wordFor(DateTime.now(), ContentStore.instance.library);

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    if (!mounted) return;
    await _progress.refresh();
    await _loadLists();
  }

  Future<void> _open(String id) async {
    _hold();
    _release();
    final w = _today;
    switch (id) {
      case 'word':
        if (w == null) {
          NavScope.goTo(context, 2);
          return;
        }
        unawaited(_progress.mark('word'));
        await _push(WordDetail(word: w));
      case 'practise':
        if (w == null) {
          NavScope.goTo(context, 2);
          return;
        }
        await _push(PracticePlayerScreen(words: [w], title: "Today's word"));
      case 'guide':
        unawaited(_progress.mark('guide'));
        unawaited(OnboardingWarmup.playerGuide(context, firstOnly: true));
        await _push(Builder(
            builder: (c) => PlayerGuideScreen(onDone: () => Navigator.of(c).maybePop())));
      case 'sounds':
        unawaited(_progress.mark('sounds'));
        await _push(const SoundLibraryScreen());
      case 'save':
        await _push(const SavedWordsScreen());
      case 'tasks':
        await _push(const DailyTasksPage());
      case 'connect':
        unawaited(_progress.mark('connect'));
        NavScope.goTo(context, 0);
    }
  }

  // ── what each card says ───────────────────────────────────────────
  List<_Step> _steps() {
    final w = _today;
    final lib = ContentStore.instance.library;
    final name = w == null ? '' : _cap(w.word);
    final meaning = w == null ? '' : _firstOf([w.meaning, w.benefit, w.origin]);
    final parts = w == null ? const <String>[] : [for (final p in w.parts) p.deva.isNotEmpty ? p.deva : p.roman];
    final cats = <String>[];
    for (final x in lib) {
      for (final c in x.categories) {
        if (c.trim().isNotEmpty && !cats.contains(c.trim())) cats.add(c.trim());
      }
    }
    final tasks = _tasks.isEmpty ? const ['Sit with one word', 'Open the player', 'Read one meaning'] : _tasks;
    return [
      _Step(
        'word',
        "Today's word",
        "Meet today's word",
        w == null
            ? 'A new NowssB word every day. Open the Library to see all of them.'
            : meaning.isEmpty
                ? 'Today it is $name. See how it is written, hear it said and read what it does.'
                : 'Today it is $name: ${_trim(meaning, 70)}. See how it is written and hear it said.',
        w == null ? 'Open the Library' : 'Open $name',
        _WordArt(word: w),
      ),
      _Step(
        'practise',
        'Practise',
        'Say it in the player',
        w == null
            ? 'Practise a word sound by sound. Record your voice and get a score.'
            : 'Say $name sound by sound${parts.length > 1 ? ' (${parts.join(' · ')})' : ''}. Record your voice and get a score.',
        w == null ? 'Open the Library' : 'Practise $name',
        _PartsArt(word: w),
      ),
      const _Step(
        'guide',
        'Player guide',
        'Learn the player buttons',
        'A short tour: play and replay, record and score, your library, word info and voice settings.',
        'Open the player guide',
        _WordsArt(['Listen', 'Record', 'Score', 'Repeat']),
      ),
      _Step(
        'sounds',
        'Sound Library',
        'Explore the Sound Library',
        lib.isEmpty
            ? 'Every NowssB word and sound, sorted by what it helps. Pick one and listen.'
            : 'All ${lib.length} NowssB words, sorted by what they help. Pick one and listen.',
        'Open the Sound Library',
        _ChipsArt(cats.take(4).toList(), lead: lib.isEmpty ? 'Sounds' : '${lib.length} words'),
      ),
      _Step(
        'save',
        'Save',
        'Save a word you like',
        'In the player, tap the heart to keep a word. Your saved words wait for you in one place.',
        'See saved words',
        _SavedArt(_saved, fallback: name),
      ),
      _Step(
        'tasks',
        "Today's tasks",
        "Do today's ${_count(tasks.length)} tasks",
        '${_sentence(tasks)}. Tick each one when it is done.',
        "Open today's tasks",
        _TasksArt(tasks, done: _tasksDone),
      ),
      const _Step(
        'connect',
        'NowssB Connect',
        'Join NowssB Connect',
        'Share a thought, a quote or an image with others who practise. Posts are anonymous.',
        'Open Connect',
        _WordsArt(['Thought', 'Quote', 'Image']),
      ),
    ];
  }

  static String _cap(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  static String _firstOf(List<String> xs) =>
      xs.map((x) => x.trim()).firstWhere((x) => x.isNotEmpty, orElse: () => '');

  static String _trim(String s, int n) {
    final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    final first = t[0].toLowerCase() + t.substring(1);
    return first.length <= n ? first : '${first.substring(0, n).trimRight()}…';
  }

  static String _count(int n) => const ['no', 'one', 'two', 'three', 'four', 'five', 'six'].elementAtOrNull(n) ?? '$n';

  static String _sentence(List<String> xs) {
    final low = [for (var i = 0; i < xs.length; i++) i == 0 ? xs[i] : xs[i][0].toLowerCase() + xs[i].substring(1)];
    if (low.length <= 1) return low.join();
    return '${low.sublist(0, low.length - 1).join(', ')} and ${low.last}';
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps();
    final done = <int>{
      for (var i = 0; i < steps.length; i++)
        if (_progress.isDone(steps[i].id)) i
    };
    final dark = widget.fashion || NormalGlassMode.of(context);
    final ink = dark ? Colors.white : const Color(0xFF2B2D33);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: dark ? const Color(0x14FFFFFF) : const Color(0xFFECEEF2),
              shape: BoxShape.circle,
              border: Border.all(color: dark ? const Color(0x2EFFFFFF) : const Color(0x14000000)),
            ),
            child: Center(child: NwsbIcon(NwsbMarks.book, size: 21, color: ink)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${done.length} of ${steps.length} done',
                    key: const ValueKey('getstarted-count'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, color: ink.withValues(alpha: .6), height: 1.2)),
                EditableLabel('horizontal_routine_cards.NmHorizontalRoutineCards', 'Get Started',
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, color: ink, height: 1.2, letterSpacing: -0.4)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        NmEssentialsProcessLine(
            glass: dark, active: _active, count: steps.length, done: done, onTap: _jump),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, box) {
          final cardW = (box.maxWidth - 30).clamp(240.0, 330.0);
          _stride = cardW + 12;
          return Listener(
            onPointerDown: (_) => _hold(),
            onPointerUp: (_) => _release(),
            onPointerCancel: (_) => _release(),
            child: SizedBox(
              height: 346 + (MediaQuery.textScalerOf(context).scale(10) / 10 - 1).clamp(0.0, 1.0) * 80,
              child: ListView.separated(
                key: const ValueKey('getstarted-row'),
                controller: _cards,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: steps.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => SizedBox(
                  width: cardW,
                  child: _StepCard(
                    step: steps[i],
                    index: i,
                    total: steps.length,
                    done: done.contains(i),
                    onOpen: () => _open(steps[i].id),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );

    if (dark) {
      return GlassWrap(
        key: const ValueKey('getstarted-section'),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: ClipRect(child: body),
      );
    }
    return Container(
      key: const ValueKey('getstarted-section'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
          color: const Color(0xFFECEEF2), borderRadius: BorderRadius.circular(kGlassRadius), boxShadow: NwsbShadows.raised),
      child: ClipRect(child: body),
    );
  }
}

class _Step {
  const _Step(this.id, this.kicker, this.title, this.body, this.action, this.art);
  final String id;
  final String kicker;
  final String title;
  final String body;
  final String action;
  final Widget art;
}

/// One black Store-style card: step label, word art, title, plain copy, CTA.
class _StepCard extends StatelessWidget {
  const _StepCard(
      {required this.step, required this.index, required this.total, required this.done, required this.onOpen});
  final _Step step;
  final int index;
  final int total;
  final bool done;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('getstarted-card-${step.id}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
           height: 22,
           child: Row(children: [
            Expanded(
              child: Text('STEP ${index + 1} OF $total · ${step.kicker.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: NmEssentialsProcessLine.gold)),
            ),
            if (done)
              Container(
                key: ValueKey('getstarted-done-${step.id}'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0x26E2BD72), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_rounded, size: 12, color: NmEssentialsProcessLine.gold),
                  SizedBox(width: 3),
                  Text('Done',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NmEssentialsProcessLine.gold)),
                ]),
              ),
          ])),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x14FFFFFF)),
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1712), Color(0xFF0E0E10), Color(0xFF15120D)]),
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  // Big text takes room from the art, which scales down whole.
                  child: LayoutBuilder(
                      builder: (_, box) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                              width: box.maxWidth,
                              height: box.maxHeight < 132 ? 132 : box.maxHeight,
                              // The art is a picture made of words: it scales as a whole.
                              child: MediaQuery.withNoTextScaling(child: step.art))))),
            ),
          ),
          const SizedBox(height: 12),
          Text(step.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.3)),
          const SizedBox(height: 6),
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(13.5) * 1.35 * 3 + 2,
            child: Text(step.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, color: Color(0xC7FFFFFF), height: 1.35)),
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: step.action,
            child: GestureDetector(
              key: ValueKey('getstarted-cta-${step.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23)),
                child: Row(children: [
                  Expanded(
                    child: Text(step.action,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.black),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── word-only art ───────────────────────────────────────────────────

const _devaFallback = ['Noto Sans Devanagari'];
const _gold = NmEssentialsProcessLine.gold;

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 2, color: Color(0x99FFFFFF)));
}

/// The day's word, big: Devanagari when it exists, the roman spelling under it.
class _WordArt extends StatelessWidget {
  const _WordArt({required this.word});
  final Word? word;
  @override
  Widget build(BuildContext context) {
    final w = word;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Label('Word of the day'),
        const Spacer(),
        if (w != null && w.deva.trim().isNotEmpty)
          Text(w.deva.trim(),
              maxLines: 1,
              style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w600, color: Colors.white, fontFamilyFallback: _devaFallback)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(w == null ? 'NOWSSB' : w.word.toUpperCase(),
              maxLines: 1,
              style: TextStyle(
                  fontSize: w != null && w.deva.trim().isNotEmpty ? 22 : 44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 5,
                  height: 1.05,
                  color: w != null && w.deva.trim().isNotEmpty ? _gold : Colors.white)),
        ),
        const SizedBox(height: 6),
        Container(width: 36, height: 2, color: _gold),
      ]),
    );
  }
}

/// The word's sound parts as tiles, each with how long to hold it.
class _PartsArt extends StatelessWidget {
  const _PartsArt({required this.word});
  final Word? word;
  @override
  Widget build(BuildContext context) {
    final parts = word?.parts ?? const <WordPart>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label(word == null ? 'Sound by sound' : '${word!.word} · ${parts.length} sounds'),
        const Spacer(),
        if (parts.isEmpty)
          const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Listen · Say · Hold',
                  maxLines: 1, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)))
        else
          Flexible(
            child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < parts.length && i < 5; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('·', style: TextStyle(fontSize: 20, color: _gold)),
                ),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x10FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x24FFFFFF)),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                          parts[i].deva.isNotEmpty ? parts[i].deva : parts[i].roman.toUpperCase(),
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamilyFallback: _devaFallback)),
                    const SizedBox(height: 2),
                    Text('${_secs(parts[i].hold)} s',
                        style: const TextStyle(fontSize: 10.5, color: _gold, fontWeight: FontWeight.w600)),
                  ]),
                ),
            ],
          ]))),
      ]),
    );
  }

  static String _secs(double h) => h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1);
}

/// A short stack of plain words (player actions, kinds of Connect post).
class _WordsArt extends StatelessWidget {
  const _WordsArt(this.words);
  final List<String> words;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < words.length; i++)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(words[i].toUpperCase(),
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: words.length > 3 ? 23 : 28,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: i == 0 ? Colors.white : (i == 1 ? _gold : Color.lerp(Colors.white, Colors.black, .2 + i * .12)))),
            ),
        ],
      ),
    );
  }
}

/// The Sound Library's own categories as chips.
class _ChipsArt extends StatelessWidget {
  const _ChipsArt(this.chips, {required this.lead});
  final List<String> chips;
  final String lead;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(lead.toUpperCase(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 3, color: Colors.white)),
        const SizedBox(height: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            clipBehavior: Clip.hardEdge,
            children: [
              for (final c in chips)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0x40E2BD72))),
                  child: Text(c,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xE6FFFFFF), fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

/// The words already saved, or the day's word waiting for its heart.
class _SavedArt extends StatelessWidget {
  const _SavedArt(this.saved, {required this.fallback});
  final List<String> saved;
  final String fallback;
  @override
  Widget build(BuildContext context) {
    final words = saved.isNotEmpty ? saved.take(3).toList() : [if (fallback.isNotEmpty) fallback];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label(saved.isEmpty ? 'Nothing saved yet' : '${saved.length} saved'),
        const Spacer(),
        for (final w in words)
          Row(children: [
            Icon(saved.isEmpty ? Icons.favorite_border_rounded : Icons.favorite_rounded, size: 18, color: _gold),
            const SizedBox(width: 8),
            Flexible(
              child: Text(w.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: words.length > 1 ? 20 : 30,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: Colors.white)),
            ),
          ]),
      ]),
    );
  }
}

/// Today's task list, as the Tasks page has it.
class _TasksArt extends StatelessWidget {
  const _TasksArt(this.tasks, {this.done = const {}});
  final List<String> tasks;
  final Set<String> done;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Label('Today'),
        const Spacer(),
        for (final t in tasks.take(3))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                    color: done.contains(t) ? _gold : null,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _gold, width: 1.4)),
                child: done.contains(t) ? const Icon(Icons.check_rounded, size: 12, color: Colors.black) : null,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(t,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ]),
          ),
      ]),
    );
  }
}
