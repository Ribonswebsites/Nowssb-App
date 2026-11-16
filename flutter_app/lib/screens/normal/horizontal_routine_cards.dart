/// Get Started: seven real first steps through NowssB, one card each.
///
/// The look is the original Get Started carousel (dark glass on the Zen home,
/// poster image, store badges, black action banner, 18px orange stepper).
/// The steps and destinations are the real first path through the app:
/// 1 today's word · 2 practise it in the player · 3 the player guide ·
/// 4 the Sound Library · 5 save a word · 6 today's tasks · 7 NowssB Connect.
/// Completion is kept on the phone ([GetStartedProgress]). The row moves
/// every 5 s over 600 ms (easeInOutCubic), holds while a finger is on it
/// and carries on 5 s after the finger lifts.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../admin/template/editable.dart';
import '../../data/content.dart';
import '../../data/home_widget_sync.dart';
import '../../data/models.dart';
import '../../media/onboarding_warmup.dart';
import '../../shell/nav_shell.dart';
import '../../theme/tokens.dart';
import '../daily_tasks.dart';
import '../player_guide.dart';
import '../practice_player.dart';
import '../saved_words.dart';
import '../sound_library.dart';
import '../word_detail.dart';
import 'essentials_process_line.dart';
import 'get_started_progress.dart';
import 'glassmorphism_theme.dart';

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
  State<NmHorizontalRoutineCards> createState() =>
      _NmHorizontalRoutineCardsState();
}

class _NmHorizontalRoutineCardsState extends State<NmHorizontalRoutineCards> {
  late final ScrollController _cardsController;
  final _progress = GetStartedProgress.instance;
  var _activeCard = 0;
  Timer? _tick;
  Timer? _resume;
  var _held = false;

  static const _stride = 344.0; // card width 330 + separator 14

  @override
  void initState() {
    super.initState();
    _cardsController = ScrollController()..addListener(_onCardsScroll);
    _progress.addListener(_onChange);
    ContentStore.instance.addListener(_onChange);
    unawaited(_progress.load());
    _startTicking();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _resume?.cancel();
    _progress.removeListener(_onChange);
    ContentStore.instance.removeListener(_onChange);
    _cardsController
      ..removeListener(_onCardsScroll)
      ..dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _startTicking() {
    _tick?.cancel();
    if (!NmHorizontalRoutineCards.autoAdvance) return;
    _tick = Timer.periodic(NmHorizontalRoutineCards.every, (_) {
      if (!_held && mounted) {
        _scrollTo((_activeCard + 1) % GetStartedProgress.steps.length);
      }
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

  void _onCardsScroll() {
    final next = (_cardsController.offset / _stride)
        .round()
        .clamp(0, GetStartedProgress.steps.length - 1);
    if (next != _activeCard && mounted) setState(() => _activeCard = next);
  }

  void _scrollTo(int i) {
    setState(() => _activeCard = i);
    if (!_cardsController.hasClients) return;
    final max = _cardsController.position.maxScrollExtent;
    _cardsController.animateTo((i * _stride).clamp(0.0, max),
        duration: NmHorizontalRoutineCards.glide,
        curve: NmHorizontalRoutineCards.curve);
  }

  /// A dot was tapped: jump there and pause like a touch.
  void _select(int i) {
    _hold();
    _scrollTo(i);
    _release();
  }

  Word? get _today =>
      HomeWidgetSync.wordFor(DateTime.now(), ContentStore.instance.library);

  Future<void> _push(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (!mounted) return;
    await _progress.refresh();
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
            builder: (c) =>
                PlayerGuideScreen(onDone: () => Navigator.of(c).maybePop())));
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

  static String _cap(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  List<_EssentialCardData> _cards() {
    final w = _today;
    final name = w == null ? '' : _cap(w.word);
    final lib = ContentStore.instance.library;
    return [
      _EssentialCardData(
        'word',
        "Today's word",
        "Meet today's word",
        w == null
            ? 'Word of the day'
            : (name.isEmpty ? 'Word of the day' : name),
        w == null ? 'Open the Library' : 'Open $name',
        'assets/routine/gs-todays-word.png',
        const Color(0xFFE9C1A5),
      ),
      _EssentialCardData(
        'practise',
        'Practise',
        'Say it in the player',
        'In the player',
        w == null ? 'Open the Library' : 'Practise $name',
        'assets/routine/gs-practise.png',
        const Color(0xFFB9D5E8),
      ),
      const _EssentialCardData(
        'guide',
        'Player guide',
        'Learn the player buttons',
        'A short tour',
        'Open the player guide',
        'assets/routine/gs-player-guide.png',
        Color(0xFFCBBBE8),
      ),
      _EssentialCardData(
        'sounds',
        'Sound Library',
        'Explore the Sound Library',
        lib.isEmpty ? 'Every NowssB word' : '${lib.length} NowssB words',
        'Open the Sound Library',
        'assets/routine/gs-sound-library.png',
        const Color(0xFFBFE2D1),
      ),
      const _EssentialCardData(
        'save',
        'Save a word',
        'Save a word you like',
        'Tap the heart',
        'See saved words',
        'assets/routine/gs-saved-words.png',
        Color(0xFFF0D39B),
      ),
      const _EssentialCardData(
        'tasks',
        "Today's tasks",
        "Do today's tasks",
        'Sit, play, read',
        "Open today's tasks",
        'assets/routine/gs-todays-tasks.png',
        Color(0xFFD4C5E8),
      ),
      const _EssentialCardData(
        'connect',
        'NowssB Connect',
        'Join NowssB Connect',
        'A thought, a quote, an image',
        'Open Connect',
        'assets/routine/gs-connect.png',
        Color(0xFFE8C9C1),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
    final cards = _cards();
    final done = <int>{
      for (var i = 0; i < cards.length; i++)
        if (_progress.isDone(cards[i].id)) i
    };
    final dark = glass || widget.fashion;
    return Padding(
      key: const ValueKey('getstarted-section'),
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 14),
            child: Row(
              children: [
                Expanded(
                    child: EditableLabel(
                        'horizontal_routine_cards.NmHorizontalRoutineCards',
                        'Get Started',
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: dark
                                ? Colors.white
                                : const Color(0xFF2B2D33)))),
                Text('${done.length} of ${cards.length} done',
                    key: const ValueKey('getstarted-count'),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (dark ? Colors.white : const Color(0xFF2B2D33))
                            .withValues(alpha: .55))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 16, top: 4),
            child: NmEssentialsProcessLine(
                glass: dark,
                active: _activeCard,
                count: cards.length,
                done: done,
                onTap: _select),
          ),
          Listener(
            onPointerDown: (_) => _hold(),
            onPointerUp: (_) => _release(),
            onPointerCancel: (_) => _release(),
            child: SizedBox(
              height: 392,
              child: ListView.separated(
                key: const ValueKey('getstarted-row'),
                controller: _cardsController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 20, bottom: 4),
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) => _EssentialCard(
                    card: cards[index],
                    glass: glass,
                    fashion: widget.fashion,
                    done: done.contains(index),
                    onSelect: () => _select(index),
                    onStart: () => _open(cards[index].id)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EssentialCardData {
  const _EssentialCardData(this.id, this.category, this.title, this.meta,
      this.action, this.image, this.circleColor);
  final String id;
  final String category;
  final String title;
  final String meta;
  final String action;
  final String image;
  final Color circleColor;
}

class _EssentialCard extends StatelessWidget {
  const _EssentialCard(
      {required this.card,
      required this.glass,
      required this.fashion,
      required this.done,
      this.onSelect,
      this.onStart});
  final _EssentialCardData card;
  final VoidCallback? onSelect;
  final VoidCallback? onStart;
  final bool glass;
  final bool fashion;
  final bool done;

  /// Fashion My Routine — GlassWrap / Notifications dark glass, not white.
  static const _darkGlassFill = Color(0x0EFFFFFF); // rgba(255,255,255,0.055)
  static const _darkGlassLine = Color(0x21FFFFFF); // rgba(255,255,255,0.13)
  static const _darkGlassBlur = 9.0; // CSS blur(18px) → sigma 9

  @override
  Widget build(BuildContext context) {
    final darkGlass = fashion;
    final foreground = darkGlass ? Colors.white : const Color(0xFF263142);
    final surface = darkGlass
        ? _darkGlassFill
        : (glass ? const Color(0xD9FFFFFF) : const Color(0xFFECEEF2));
    final border = darkGlass
        ? _darkGlassLine
        : (glass ? const Color(0xFFFFFFFF) : Colors.transparent);
    final radius = BorderRadius.circular(24);

    Widget face = Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(
              child: Text(card.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color:
                          foreground.withValues(alpha: darkGlass ? .78 : .72),
                      fontSize: 12))),
          if (done) ...[
            const SizedBox(width: 8),
            Text('Done',
                key: ValueKey('getstarted-done-${card.id}'),
                style: TextStyle(
                    color: foreground.withValues(alpha: .7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ]),
        const SizedBox(height: 10),
        // B030: art gives way (cover-cropped) when big text wraps meta/title.
        Flexible(
            child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: EditableImage.asset(card.image,
                    height: 152,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    slot: 'horizontal_routine_cards.EssentialCard'))),
        const SizedBox(height: 12),
        Text(card.meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: foreground.withValues(alpha: darkGlass ? .75 : .7),
                fontSize: 12)),
        const SizedBox(height: 4),
        Text(card.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: foreground,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.15)),
      ]),
    );

    Widget cardPane;
    if (darkGlass) {
      cardPane = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
                color: Color(0x57000000),
                blurRadius: 40,
                offset: Offset(0, 16)),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: _darkGlassBlur, sigmaY: _darkGlassBlur),
            child: Container(
              height: 297,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: radius,
                border: Border.all(color: border),
              ),
              child: face,
            ),
          ),
        ),
      );
    } else {
      cardPane = Container(
        height: 297,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: radius,
          border: Border.all(color: border, width: glass ? 1.2 : 0),
          boxShadow: glass
              ? const [
                  BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 18,
                      offset: Offset(0, 9))
                ]
              : NwsbShadows.raised,
        ),
        child: ClipRRect(borderRadius: radius, child: face),
      );
    }

    return SizedBox(
      width: 330,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              GestureDetector(
                  key: ValueKey('routine-card-${card.id}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onSelect,
                  child: cardPane),
              const SizedBox(height: 38),
              GestureDetector(
                  key: ValueKey('getstarted-cta-${card.id}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onStart,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      Expanded(
                          child: Text(card.action,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600))),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18)
                    ]),
                  )),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 74,
              height: 74,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .82),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 12,
                      offset: Offset(0, 5)),
                ],
              ),
              child: EditableImage.asset('assets/banners/promo/store.png',
                  fit: BoxFit.contain,
                  slot: 'horizontal_routine_cards.EssentialCard'),
            ),
          ),
          Positioned(
            left: 135,
            top: 269,
            child: Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: card.circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 12,
                        offset: Offset(0, 5))
                  ]),
              child: EditableImage.asset('assets/banners/promo/store.png',
                  fit: BoxFit.contain,
                  slot: 'horizontal_routine_cards.EssentialCard'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Optional white-glass wrapper for callers that want the section framed.
class EssentialsGlassFrame extends StatelessWidget {
  const EssentialsGlassFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: const Color(0x40FFFFFF),
                border: Border.all(color: Colors.white70),
                borderRadius: BorderRadius.circular(28)),
            child: child,
          ),
        ),
      );
}
