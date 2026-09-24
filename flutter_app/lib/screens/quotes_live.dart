/// "Today quotes to live by" tab, the week page, and the admin editor.
library;

import 'dart:ui' show ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/firebase.dart';
import '../data/settings.dart';
import '../widgets/app_thinking_loader.dart';
import '../widgets/colored_split_promo_banner.dart';
import '../widgets/glass_wrap.dart';
import '../widgets/neumorphic.dart';
import '../widgets/scroll_progress_rail.dart';
import 'healing_path.dart';
import 'player_settings.dart';
import 'practice.dart';
import 'reader/reader_hub.dart';
import 'sound_library.dart';
import 'store.dart';
import 'subscription.dart';

const _days = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _kBuddhaQuote =
    'Without a weapon in hand, the enlightened Mahaveer Buddha guided the world, not by the sword, but by the power of Natural Origin Words';

const _kQuoteMarks = 'nwsb_quote_marks';
const _kHomeQuoteHidden = 'nwsb_home_quote_hidden_day';

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<({Set<String> likes, Set<String> saves})> _readMarks() async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getStringList(_kQuoteMarks) ?? const <String>[];
  final likes = <String>{};
  final saves = <String>{};
  for (final item in raw) {
    final i = item.indexOf('|');
    if (i <= 0) continue;
    final day = item.substring(0, i);
    final kind = item.substring(i + 1);
    if (kind == 'like') likes.add(day);
    if (kind == 'save') saves.add(day);
  }
  return (likes: likes, saves: saves);
}

Future<void> _writeMarks(Set<String> likes, Set<String> saves) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList(_kQuoteMarks, [
    for (final d in likes) '$d|like',
    for (final d in saves) '$d|save',
  ]);
}

class LiveQuoteTab extends StatefulWidget {
  const LiveQuoteTab({super.key});

  @override
  State<LiveQuoteTab> createState() => _LiveQuoteTabState();
}

class _LiveQuoteTabState extends State<LiveQuoteTab> {
  var _hidden = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final day = p.getString(_kHomeQuoteHidden);
    if (!mounted) return;
    setState(() => _hidden = day == _dayKey(DateTime.now()));
  }

  Future<void> _hide() async {
    setState(() => _hidden = true);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kHomeQuoteHidden, _dayKey(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Settings.instance,
      builder: (context, _) {
        final live = Settings.instance.liveQuote.trim();
        final quote = live.isNotEmpty ? live : _kBuddhaQuote;
        final banner = Dismissible(
          key: const ValueKey('home-today-quote'),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => _hide(),
          child: GlassWrap(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 28, 4),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const QuotesWeekScreen()),
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppThinkingLoader(
                        size: 34,
                        state: OrbState.composing,
                        blackCircle: true,
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 36, color: const Color(0x33FFFFFF)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today quotes to live by',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFE8D5A3),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              quote,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _hide,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return banner;
      },
    );
  }
}

class QuotesWeekScreen extends StatefulWidget {
  const QuotesWeekScreen({super.key});

  @override
  State<QuotesWeekScreen> createState() => _QuotesWeekScreenState();
}

class _QuotesWeekScreenState extends State<QuotesWeekScreen> {
  final _rail = ScrollController();
  final _thought = TextEditingController();
  final _daysPager = PageController(viewportFraction: 0.46);
  List<_SharedLine> _remote = const [];

  @override
  void initState() {
    super.initState();
    _loadThoughts();
  }

  @override
  void dispose() {
    _rail.dispose();
    _thought.dispose();
    _daysPager.dispose();
    super.dispose();
  }

  /// Same dark glass on Normal and Fashion. Not a second skin.
  bool get _neu => false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = now.weekday - 1;
    final last = (today + 6) % 7;
    final ink = _neu ? const Color(0xFF2B2D33) : Colors.white;
    final bg = _neu ? const Color(0xFFECEEF2) : const Color(0xFF07060C);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Settings.instance,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: Icon(Icons.arrow_back_rounded, color: ink),
                      ),
                      Expanded(
                        child: Text(
                          "Today's Quotes",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _openMonth,
                        icon: Icon(Icons.edit_outlined, color: ink),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Today · ${_days[today]}    Last day · ${_days[last]}',
                    style: TextStyle(
                      color: _neu ? const Color(0xFF6B7280) : const Color(0xB3FFFFFF),
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_neu) ...[
                          ScrollProgressRail(controller: _rail),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: ListView(
                            controller: _rail,
                            children: [
                              ColoredSplitPromoBanner(
                                spec: SplitPromoExtras.at(
                                  4,
                                  onTap: () => _push(const PracticeScreen()),
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                              ),
                              _calendarStrip(),
                              const SizedBox(height: 8),
                              const _WeekQuotesBox(),
                              const SizedBox(height: 8),
                              ColoredSplitPromoBanner(
                                spec: SplitPromoExtras.at(
                                  8,
                                  onTap: () => _push(const PracticeScreen()),
                                ),
                                margin: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 8),
                              _shareBox(),
                              const SizedBox(height: 12),
                              _blackOption(
                                'Practice',
                                'Open today’s session',
                                () => _push(const PracticeScreen()),
                              ),
                              _blackOption(
                                'Sound Library',
                                'Hear the frequency',
                                () => _push(const SoundLibraryScreen()),
                              ),
                              _blackOption(
                                'The Store',
                                'Words and meanings',
                                () => _push(const StoreScreen()),
                              ),
                              _blackOption(
                                'Player settings',
                                'Equalizer, clock, quality',
                                () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const PlayerSettingsScreen(),
                                  ),
                                ),
                              ),
                              _blackOption(
                                'Reader',
                                'Meanings and ebooks',
                                () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ReaderHubScreen(),
                                  ),
                                ),
                              ),
                              _blackOption(
                                'Healing path',
                                'Choose where to begin',
                                () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const HealingPathScreen(),
                                  ),
                                ),
                              ),
                              _blackOption(
                                'Subscription',
                                'Free, then 50% off',
                                () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SubscriptionScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _skin(Widget child) {
    if (_neu) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: NeuCard(
          padding: const EdgeInsets.all(6),
          radius: 18,
          elevation: NwsbElevation.sm,
          child: child,
        ),
      );
    }
    return GlassWrap(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(6),
      child: child,
    );
  }

  Widget _dayCard(int i, {required int today, required int last, bool big = false}) {
    final shown = i == today && Settings.instance.liveQuote.trim().isNotEmpty
        ? Settings.instance.liveQuote
        : Settings.instance.quoteFor(_dateForWeekday(i + 1));
    final tag = i == today
        ? 'Today'
        : i == last
            ? 'Last day'
            : null;
    return _skin(Container(
      padding: EdgeInsets.fromLTRB(12, big ? 16 : 10, 12, big ? 16 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B12),
        borderRadius: BorderRadius.circular(big ? 20 : 16),
      ),
      child: Row(
        children: [
          AppThinkingLoader(
            size: big ? 42 : 28,
            state: OrbState.composing,
            blackCircle: true,
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: big ? 44 : 28, color: const Color(0x33FFFFFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _days[i],
                      style: TextStyle(
                        color: const Color(0xFFE8D5A3),
                        fontWeight: FontWeight.w800,
                        fontSize: big ? 16 : 13,
                      ),
                    ),
                    if (tag != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        tag,
                        style: TextStyle(color: Colors.white, fontSize: big ? 13 : 11),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  shown,
                  maxLines: big ? 4 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: big ? 18 : 13,
                    height: 1.3,
                    fontWeight: big ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  DateTime _dateForWeekday(int weekday) {
    final now = DateTime.now();
    return now.add(Duration(days: weekday - now.weekday));
  }

  static const _strip = <(String, Color)>[
    ('assets/banners/promo/pose-01.png', Color(0xFFE07A32)),
    ('assets/banners/promo/pose-02.png', Color(0xFF7C4DFF)),
    ('assets/banners/promo/pose-03.png', Color(0xFF2EC4B6)),
    ('assets/banners/promo/pose-04.png', Color(0xFFE85D9A)),
    ('assets/banners/promo/pose-06.png', Color(0xFFD4A017)),
    ('assets/banners/promo/pose-09.png', Color(0xFFE67E22)),
    ('assets/banners/promo/pose-10.png', Color(0xFF3D8BDB)),
  ];

  Widget _calendarStrip() {
    final ink = _neu ? const Color(0xFF2B2D33) : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text(
            'This week',
            style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final art = _strip[i];
              final wide = i == 0;
              return GestureDetector(
                onTap: _openCalendar,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: wide ? 228 : 132,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: art.$2),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 8, 6, 28),
                          child: Image.asset(
                            art.$1,
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 8,
                          bottom: 8,
                          child: Text(
                            _days[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openMonth() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QuoteMonthSheet(),
    );
  }

  void _openCalendar() {
    final today = DateTime.now().weekday - 1;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.35,
          maxChildSize: 0.94,
          builder: (_, scroll) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFF14121A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 4, 4),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Which day, which quote',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      itemCount: 7,
                      itemBuilder: (_, i) {
                        final line = Settings.instance.quoteFor(_dateForWeekday(i + 1));
                        final live = i == today ? Settings.instance.todayQuote : line;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B0B12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  i == today ? '${_days[i]} · Today' : _days[i],
                                  style: const TextStyle(
                                    color: Color(0xFFE8D5A3),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  live,
                                  style: const TextStyle(color: Colors.white, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _otherDays(int today) {
    final order = <int>[
      for (var i = today - 1; i >= 0; i--) i,
      for (var i = today + 1; i < 7; i++) i,
    ];
    final last = (today + 6) % 7;
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _daysPager,
        scrollDirection: Axis.vertical,
        itemCount: order.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _daysPager,
            builder: (context, child) {
              var delta = 0.0;
              if (_daysPager.hasClients && _daysPager.position.haveDimensions) {
                delta = (_daysPager.page ?? index.toDouble()) - index;
              }
              final tilt = (delta * 0.85).clamp(-0.9, 0.9);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0016)
                  ..rotateX(tilt)
                  ..translateByDouble(0, 0, -delta.abs() * 40, 1),
                child: Opacity(opacity: (1 - delta.abs() * 0.35).clamp(0.45, 1), child: child),
              );
            },
            child: _dayCard(order[index], today: today, last: last),
          );
        },
      ),
    );
  }

  Future<void> _loadThoughts() async {
    if (!NwsbFirebase.ready) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .where('visibility', isEqualTo: 'public')
          .limit(40)
          .get();
      final out = <_SharedLine>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['kind'] != 'thought') continue;
        final text = (data['text'] ?? '').toString().trim();
        if (text.isEmpty) continue;
        out.add(_SharedLine((data['displayName'] ?? 'NowssB').toString(), text));
      }
      if (mounted) setState(() => _remote = out);
    } catch (_) {}
  }

  Future<void> _shareThought() async {
    final text = _thought.text.trim();
    if (text.isEmpty) return;
    await Settings.instance.addSharedThought(text);
    var shared = false;
    if (NwsbFirebase.ready) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('posts').add({
            'uid': user.uid,
            'visibility': 'public',
            'kind': 'thought',
            'text': text,
            'displayName': (user.displayName ?? '').trim().isEmpty
                ? 'NowssB'
                : user.displayName,
            'createdAt': FieldValue.serverTimestamp(),
          });
          shared = true;
          await _loadThoughts();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    _thought.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shared
              ? 'Shared with everyone.'
              : 'Saved on this phone. Sign in to share it with everyone.',
        ),
      ),
    );
  }

  Widget _shareBox() {
    final mine = Settings.instance.sharedThoughts;
    return _skin(Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Share your thoughts',
            style: TextStyle(
              color: Color(0xFFE8D5A3),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'The day’s quotes are written by us. Type a line of your own and share it with everyone.',
            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _thought,
            minLines: 1,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Type a quote',
              hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
              filled: true,
              fillColor: const Color(0xFF14121A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _shareThought,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5A3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Share your thoughts',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (mine.isNotEmpty || _remote.isNotEmpty) const SizedBox(height: 12),
          for (final line in mine.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line, style: const TextStyle(color: Colors.white, height: 1.3)),
            ),
          for (final line in _remote.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${line.name} · ${line.text}',
                style: const TextStyle(color: Color(0xB3FFFFFF), height: 1.3),
              ),
            ),
        ],
      ),
    ));
  }

  Widget _blackOption(String title, String sub, VoidCallback onTap) {
    return _skin(GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0B12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const AppThinkingLoader(
                size: 28,
                state: OrbState.composing,
                blackCircle: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFE8D5A3)),
            ],
          ),
        ),
    ));
  }
}

class _WeekQuotesBox extends StatefulWidget {
  const _WeekQuotesBox();

  @override
  State<_WeekQuotesBox> createState() => _WeekQuotesBoxState();
}

class _WeekQuotesBoxState extends State<_WeekQuotesBox> {
  Set<String> _likes = {};
  Set<String> _saves = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final marks = await _readMarks();
    if (!mounted) return;
    setState(() {
      _likes = marks.likes;
      _saves = marks.saves;
    });
  }

  Future<void> _toggle(String kind) async {
    final id = _dayKey(DateTime.now());
    final set = kind == 'like' ? _likes : _saves;
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    await _writeMarks(_likes, _saves);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = now.weekday - 1;
    final id = _dayKey(now);
    final live = Settings.instance.liveQuote.trim();
    final headline = (today == DateTime.thursday - 1 && live.isEmpty)
        ? _kBuddhaQuote
        : (live.isNotEmpty && today == now.weekday - 1
            ? Settings.instance.todayQuote
            : Settings.instance.quoteFor(now));
    return GlassWrap(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppThinkingLoader(
                  size: 42,
                  state: OrbState.composing,
                  blackCircle: true,
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 48, color: const Color(0x33FFFFFF)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_days[today]} · Today',
                        style: const TextStyle(
                          color: Color(0xFFE8D5A3),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _mark('Like', Icons.favorite_border, _likes.contains(id), () => _toggle('like')),
                const SizedBox(width: 8),
                _mark('Save', Icons.bookmark_border, _saves.contains(id), () => _toggle('save')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mark(String label, IconData icon, bool on, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFE8D5A3) : const Color(0xFF14121A),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: on ? const Color(0xFF1A1A2E) : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: on ? const Color(0xFF1A1A2E) : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteMonthSheet extends StatefulWidget {
  const _QuoteMonthSheet();

  @override
  State<_QuoteMonthSheet> createState() => _QuoteMonthSheetState();
}

class _QuoteMonthSheetState extends State<_QuoteMonthSheet> {
  late DateTime _month;
  late DateTime _selected;
  Set<String> _likes = {};
  Set<String> _saves = {};

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    final marks = await _readMarks();
    if (!mounted) return;
    setState(() {
      _likes = marks.likes;
      _saves = marks.saves;
    });
  }

  Future<void> _toggle(String kind) async {
    final id = _dayKey(_selected);
    final set = kind == 'like' ? _likes : _saves;
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    await _writeMarks(_likes, _saves);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = DateTime(_month.year, _month.month, 1).weekday % 7;
    final cells = lead + days;
    final rows = (cells / 7).ceil();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final live = Settings.instance.liveQuote.trim();
    final quote = _selected == today && live.isNotEmpty
        ? Settings.instance.todayQuote
        : Settings.instance.quoteFor(_selected);
    final id = _dayKey(_selected);
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 48),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xF0101018),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0x55FFFFFF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Text(
                    'Calendar',
                    style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        _month = DateTime(_month.year, _month.month - 1);
                      }),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        _months[_month.month - 1],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _month = DateTime(_month.year, _month.month + 1);
                      }),
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                      Expanded(
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                for (var r = 0; r < rows; r++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        for (var c = 0; c < 7; c++)
                          Expanded(child: _cell(r * 7 + c, lead, days)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0B12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppThinkingLoader(
                            size: 32,
                            state: OrbState.composing,
                            blackCircle: true,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_days[_selected.weekday - 1]} · ${_selected.day} ${_months[_selected.month - 1]}',
                              style: const TextStyle(
                                color: Color(0xFFE8D5A3),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        quote,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _pill('Like', _likes.contains(id), () => _toggle('like')),
                          const SizedBox(width: 8),
                          _pill('Save', _saves.contains(id), () => _toggle('save')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'This week',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _days[i],
                            style: const TextStyle(color: Color(0xFFE8D5A3), fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Settings.instance.quoteFor(now.add(Duration(days: i - (now.weekday - 1)))),
                            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(int index, int lead, int days) {
    final day = index - lead + 1;
    if (day < 1 || day > days) return const SizedBox(height: 44);
    final date = DateTime(_month.year, _month.month, day);
    final id = _dayKey(date);
    final on = _selected.year == date.year &&
        _selected.month == date.month &&
        _selected.day == date.day;
    final liked = _likes.contains(id);
    final saved = _saves.contains(id);
    return GestureDetector(
      onTap: () => setState(() => _selected = date),
      child: SizedBox(
        height: 46,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? const Color(0xFF111111) : Colors.transparent,
              border: Border.all(
                color: on
                    ? const Color(0xFFFFB020)
                    : (liked || saved)
                        ? const Color(0xFFE8D5A3)
                        : const Color(0x66FFFFFF),
                width: on ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: Colors.white,
                fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, bool on, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFE8D5A3) : const Color(0xFF14121A),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: on ? const Color(0xFF1A1A2E) : Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SharedLine {
  const _SharedLine(this.name, this.text);
  final String name;
  final String text;
}

class QuoteAdminScreen extends StatefulWidget {
  const QuoteAdminScreen({super.key});

  @override
  State<QuoteAdminScreen> createState() => _QuoteAdminScreenState();
}

class _QuoteAdminScreenState extends State<QuoteAdminScreen> {
  late final TextEditingController _live;
  late final List<TextEditingController> _days;

  @override
  void initState() {
    super.initState();
    final s = Settings.instance;
    _live = TextEditingController(text: s.liveQuote);
    _days = List.generate(7, (i) {
      final custom = i < s.weekQuotes.length ? s.weekQuotes[i] : '';
      return TextEditingController(text: custom);
    });
  }

  @override
  void dispose() {
    _live.dispose();
    for (final c in _days) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await Settings.instance.setLiveQuote(_live.text);
    for (var i = 0; i < 7; i++) {
      await Settings.instance.setWeekQuote(i, _days[i].text);
    }
    if (mounted) Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07060C),
        foregroundColor: Colors.white,
        title: const Text("Quotes to live by"),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Text(
            'Type the line. It shows on the home tab and on that day of the week. Leave a day blank to keep the built-in line.',
            style: TextStyle(color: Color(0xB3FFFFFF), height: 1.35),
          ),
          const SizedBox(height: 14),
          _field('Today’s live line', _live),
          for (var i = 0; i < 7; i++) _field(_daysName(i), _days[i]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _save,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5A3),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Save quotes',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _daysName(int i) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[i];
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: 2,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFE8D5A3)),
          filled: true,
          fillColor: const Color(0xFF14121A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
