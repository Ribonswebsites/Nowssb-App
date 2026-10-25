/// The normal home, essentials → footer, in the calm kit.
///
/// Each class is one admin layout key (see kNormalSectionOrder). Copy and
/// destinations are the ones the previous widgets used; taps report an
/// action id that HomeNormal routes (`_calm`).
library;

import 'package:flutter/material.dart';

import '../../../data/content.dart';
import '../../../data/daily_quotes.dart';
import '../../../data/quotes_remote.dart';
import '../../../features/earn/earn_home_sections.dart';
import '../../../features/economy/economy_api.dart';
import '../../../widgets/nwsb_icon.dart';
import '../../daily_tasks.dart';
import 'calm_kit.dart';

Key _k(String a) => ValueKey('calm:$a');

CalmTile _tile(CalmAct act, String a, String title, CalmTone tone, {String? sub, String? mark, String? badge, bool dense = false}) =>
    CalmTile(key: _k(a), title: title, sub: sub, mark: mark, badge: badge, tone: tone, dense: dense, onTap: () => act(a));

// ── essentials ────────────────────────────────────────────────────────────

/// Today's real task list as small check cards in one wrapper.
class CalmEssentials extends StatelessWidget {
  const CalmEssentials({super.key, required this.onAct});
  final CalmAct onAct;

  static const _tones = [CalmTone.sage, CalmTone.lilac, CalmTone.sky, CalmTone.peach, CalmTone.sand];

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<DailyTaskView>>(
        valueListenable: DailyTasks.items,
        builder: (context, items, _) {
          final done = items.where((t) => t.done).length;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CalmHead('Your essentials',
                eyebrow: '$done of ${items.length} done today', more: 'See all', onMore: () => onAct('tasks')),
            CalmWrap(
              child: CalmGrid(cols: 2, children: [
                for (var i = 0; i < items.length && i < 4; i++)
                  _tile(onAct, 'tasks', items[i].title, _tones[i % _tones.length],
                      mark: items[i].mark, sub: items[i].done ? 'Done' : 'Still open', badge: items[i].done ? '✓' : null, dense: true),
              ].map((w) => KeyedSubtree(child: w)).toList()),
            ),
          ]);
        },
      );
}

// ── routineCards ──────────────────────────────────────────────────────────

class CalmRoutines extends StatelessWidget {
  const CalmRoutines({super.key, required this.onAct, this.now});
  final CalmAct onAct;
  final DateTime? now;

  static const routines = [
    ('Get Started', 'Trusting the Breath', 'Mindfulness · 4 min', Color(0xFFE9C1A5)),
    ('Life Coaching', 'Positive Self-Talk & Power', 'Life Coaching · 4 mins', Color(0xFFB9D5E8)),
    ('Story', 'What Your Body Knows', 'Story · 8 min', Color(0xFFCBBBE8)),
    ('Breathwork', 'Return to Stillness', 'Breathwork · 6 min', Color(0xFFBFE2D1)),
    ('Sounds', 'A Softer Inner Voice', 'Sounds · 5 min', Color(0xFFF0D39B)),
    ('Meditation', 'A Quiet Place Within', 'Meditation · 10 min', Color(0xFFD4C5E8)),
  ];

  static const doors = [
    ('practice', 'Practice', NwsbMarks.play24, Color(0xFFE07A32)),
    ('library', 'Library', NwsbMarks.sound, Color(0xFF7C4DFF)),
    ('store', 'Store', NwsbMarks.bag, Color(0xFF2EC4B6)),
    ('reader', 'Reader', NwsbMarks.reader, Color(0xFFE85D9A)),
    ('healing', 'Healing', NwsbMarks.people, Color(0xFF3D8BDB)),
    ('subscription', 'Subscribe', NwsbMarks.crown, Color(0xFFD4A017)),
    ('player', 'Player', NwsbMarks.sliders, Color(0xFF27AE60)),
    ('progress', 'Progress', NwsbMarks.bars, Color(0xFF9B59B6)),
    ('quotes', 'Quotes', NwsbMarks.meaning, Color(0xFFE67E22)),
  ];

  static (String, String, String) daypart(DateTime t) {
    final h = t.hour;
    if (h < 12) return ('Morning', 'The first light. Begin here.', NwsbMarks.dawn);
    if (h < 17) return ('Afternoon', 'A quieter hour to sit with the sound.', NwsbMarks.sun);
    if (h < 21) return ('Evening', 'Let the day finish in one word.', NwsbMarks.sun);
    return ('Night', 'Rest is a practice. Stay with the tone.', NwsbMarks.moon);
  }

  @override
  Widget build(BuildContext context) {
    final p = daypart(now ?? DateTime.now());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 14),
      CalmBand(
        key: _k('library-today'),
        eyebrow: 'Sound Library',
        title: "Open today's Sound Library.",
        cta: 'Open Sound Library',
        mark: NwsbMarks.sound,
        tone: CalmTone.lilac,
        onTap: () => onAct('library-today'),
      ),
      const CalmHead('Get Started', eyebrow: 'Short sessions'),
      CalmRail(height: 150, width: 152, children: [
        for (final r in routines)
          _tile(onAct, 'routine', r.$2, CalmTone(r.$4.withValues(alpha: 0.55), Color.lerp(r.$4, Colors.black, 0.62)!),
              badge: r.$1, sub: r.$3, mark: NwsbMarks.play),
      ]),
      const SizedBox(height: 14),
      // Time-of-day well (copy of the old earth film, no video).
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          key: _k('daypart'),
          onTap: () => onAct('daypart'),
          child: Container(
          padding: const EdgeInsets.all(16),
          decoration: calmInset(26),
          child: Row(children: [
            CalmDisc(p.$3, color: const Color(0xFFB7791F), size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.$1.toUpperCase(), style: const TextStyle(fontSize: 10.5, letterSpacing: 1.6, fontWeight: FontWeight.w700, color: calmSoft)),
                const SizedBox(height: 2),
                Text(p.$2, style: const TextStyle(fontSize: 15.5, height: 1.25, fontWeight: FontWeight.w700, color: calmInk)),
                const SizedBox(height: 10),
                CalmPill('Start your practice', onTap: () => onAct('daypart')),
              ]),
            ),
          ]),
        ),
        ),
      ),
      const CalmHead('Open a door', eyebrow: 'Nine ways in'),
      CalmWrap(
        child: CalmGrid(cols: 3, children: [
          for (final d in doors) _tile(onAct, 'grid:${d.$1}', d.$2, CalmTone.of(d.$4), mark: d.$3, dense: true),
        ]),
      ),
    ]);
  }
}

// ── herovid ───────────────────────────────────────────────────────────────

class CalmToday extends StatelessWidget {
  const CalmToday({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CalmHead('Today', eyebrow: 'Your line'),
        CalmWrap(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InkWell(
              key: _k('today'),
              onTap: () => onAct('today'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('The line moves when a task is done.',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: calmInk)),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<double>(
                    valueListenable: DailyTasks.progress,
                    builder: (_, v, __) => Container(
                      height: 12,
                      decoration: calmInset(99),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: v.clamp(0.03, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: const LinearGradient(colors: [Color(0xFF9AD0B5), Color(0xFF5FA88A)]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            CalmGrid(children: [
              _tile(onAct, 'streak', 'Daily Streak', CalmTone.peach,
                  mark: NwsbMarks.flame, sub: 'Start Building Your Streak Today', dense: true),
              _tile(onAct, 'streak-store', 'The Store', CalmTone.mint,
                  mark: NwsbMarks.bag, sub: 'Words and meanings, open anytime', dense: true),
            ]),
          ]),
        ),
      ]);
}

// ── practice ──────────────────────────────────────────────────────────────

class CalmPractice extends StatelessWidget {
  const CalmPractice({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: CalmBand(
          key: _k('practice'),
          eyebrow: "Today's Practice",
          title: 'Begin your healing path',
          sub: 'Your daily word ritual',
          cta: 'Begin',
          tone: CalmTone.sage,
          onTap: () => onAct('practice'),
          trailing: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: Color(0x332F5D45), blurRadius: 18, offset: Offset(0, 8)),
            ]),
            child: const Icon(Icons.play_arrow_rounded, size: 34, color: Color(0xFF2F5D45)),
          ),
        ),
      );
}

// ── mainops ───────────────────────────────────────────────────────────────

class CalmWhereToBegin extends StatelessWidget {
  const CalmWhereToBegin({super.key, required this.onAct});
  final CalmAct onAct;

  static const words = [
    ('MEDITATION', 'Daily practice, begin anytime', CalmTone.lilac),
    ('STORE', 'Words and meanings, open anytime', CalmTone.sand),
    ('PRACTICE', 'Five quiet minutes, one word', CalmTone.sage),
  ];
  static const options = [
    ('Practice', 1, NwsbMarks.play24, CalmTone.sage),
    ('Sound Library', 2, NwsbMarks.sound, CalmTone.lilac),
    ('Word Science', 2, NwsbMarks.word, CalmTone.sky),
    ('The Store', 3, NwsbMarks.bag, CalmTone.sand),
    ('Connect', 0, NwsbMarks.connectPair, CalmTone.rose),
    ('My Progress', 4, NwsbMarks.bars, CalmTone.mint),
  ];

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CalmHead('Where to Begin', eyebrow: 'Everything, one tap away'),
        CalmRail(height: 76, width: 196, children: [
          for (final w in words)
            Material(
              key: _k('flip:${w.$1}'),
              color: w.$3.fill,
              borderRadius: BorderRadius.circular(99),
              child: InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: () => onAct('flip'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(w.$1, style: TextStyle(fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w800, color: w.$3.ink)),
                    Text(w.$2, style: TextStyle(fontSize: 11.5, color: w.$3.ink.withValues(alpha: 0.75))),
                  ]),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 10),
        CalmWrap(
          child: Column(children: [
            CalmGrid(cols: 3, children: [
              for (final o in options) _tile(onAct, 'main:${o.$1}:${o.$2}', o.$1, o.$4, mark: o.$3, dense: true),
            ]),
            const SizedBox(height: 4),
            CalmRow(
              key: _k('wayaround'),
              title: 'Find Your Way Around',
              mark: NwsbMarks.menu,
              onTap: () => onAct('wayaround'),
            ),
          ]),
        ),
      ]);
}

// ── actionbar ─────────────────────────────────────────────────────────────

class CalmHelp extends StatelessWidget {
  const CalmHelp({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CalmHead('How can we help today?'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CalmGrid(children: [
            _round(context, 'support', 'Help and support', Icons.support_agent_rounded),
            _round(context, 'coach', 'Personal Coach', Icons.self_improvement_rounded),
          ]),
        ),
      ]);

  Widget _round(BuildContext context, String a, String label, IconData icon) => GestureDetector(
        key: _k(a),
        onTap: () => onAct(a),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: calmRaised(24),
          child: Column(children: [
            Container(
              width: 52,
              height: 52,
              decoration: calmInset(99),
              child: Icon(icon, color: const Color(0xFF5B5BD6), size: 26),
            ),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: calmInk)),
          ]),
        ),
      );
}

// ── catTiles ──────────────────────────────────────────────────────────────

class CalmCategories extends StatefulWidget {
  const CalmCategories({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  State<CalmCategories> createState() => _CalmCategoriesState();
}

class _CalmCategoriesState extends State<CalmCategories> {
  static const chips = ['Popular', 'New', 'Coupons', 'Budget picks'];
  var _on = 0;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CalmHead('Little extras', eyebrow: 'Coupons · Gifts · Store'),
        CalmWrap(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CalmGrid(cols: 3, children: [
              _tile(widget.onAct, 'cta:coupons', 'Coupons', CalmTone.of(const Color(0xFFE8A23A)), sub: 'Scratch & save', mark: NwsbMarks.coupon, dense: true),
              _tile(widget.onAct, 'cta:gifts', 'Gifts', CalmTone.of(const Color(0xFFE07070)), sub: 'Daily spin', mark: NwsbMarks.gift, dense: true),
              _tile(widget.onAct, 'cta:store', 'Store', CalmTone.of(const Color(0xFFC8A96E)), sub: 'Shop words', mark: NwsbMarks.bag, dense: true),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (var i = 0; i < chips.length; i++)
                ChoiceChip(
                  label: Text(chips[i]),
                  selected: _on == i,
                  showCheckmark: false,
                  labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _on == i ? Colors.white : calmInk),
                  selectedColor: const Color(0xFF5B5BD6),
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onSelected: (_) => setState(() => _on = i),
                ),
            ]),
          ]),
        ),
      ]);
}

// ── spotlight ─────────────────────────────────────────────────────────────

class CalmSpotlight extends StatelessWidget {
  const CalmSpotlight({super.key, required this.onAct});
  final CalmAct onAct;

  static const cards = [
    ('coupons', 'NowssB Coupons', 'Scratch today', 'Sale is live', NwsbMarks.coupon, CalmTone.peach),
    ('gifts', 'NowssB Gifts', 'Daily spin', 'Today', NwsbMarks.gift, CalmTone.rose),
    ('earn', 'NowssB Earn', 'Coins on real sales', 'Featured', NwsbMarks.earn, CalmTone.sand),
    ('signature', 'Signature', 'The rarest words', null, NwsbMarks.signature, CalmTone.lilac),
  ];

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CalmHead('In the spotlight'),
        CalmRail(height: 150, width: 160, children: [
          for (final c in cards) _tile(onAct, 'hype:${c.$1}', c.$2, c.$6, sub: c.$3, badge: c.$4, mark: c.$5),
        ]),
      ]);
}

// ── tiles ─────────────────────────────────────────────────────────────────

class CalmEnter extends StatelessWidget {
  const CalmEnter({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CalmHead('Begin your healing', eyebrow: 'Four rooms'),
        CalmWrap(
          tint: const Color(0xFFE7EAF2),
          child: CalmGrid(children: [
            _tile(onAct, 'enter:player', 'Player', CalmTone.sage, mark: NwsbMarks.play24),
            _tile(onAct, 'enter:library', 'Sound Library', CalmTone.lilac, mark: NwsbMarks.sound, sub: 'Hear a word'),
            _tile(onAct, 'enter:store', 'Store', CalmTone.sand, mark: NwsbMarks.bag, sub: 'Shop words'),
            _tile(onAct, 'enter:reader', 'Reader', CalmTone.sky, mark: NwsbMarks.reader, sub: 'Meanings and eBooks'),
          ]),
        ),
      ]);
}

// ── storiesFind ───────────────────────────────────────────────────────────

class CalmStories extends StatelessWidget {
  const CalmStories({super.key, required this.onAct});
  final CalmAct onAct;

  static const stories = [
    ('PRANA', 'Sound Ritual', CalmTone.mint),
    ('PITTA', 'Light Body', CalmTone.peach),
    ('SOMA', 'Word Science', CalmTone.sky),
    ('AURA', 'The Future', CalmTone.lilac),
  ];

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CalmHead('Sound that finds you', eyebrow: 'There are no limitations to the frequency'),
        CalmRail(height: 112, width: 124, children: [
          for (final s in stories)
            Material(
              key: _k('stories:${s.$1}'),
              color: s.$3.fill,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => onAct('stories'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(s.$1, style: TextStyle(fontSize: 11, letterSpacing: 2.2, fontWeight: FontWeight.w800, color: s.$3.ink.withValues(alpha: 0.7))),
                    Text(s.$2, style: TextStyle(fontSize: 15, height: 1.15, fontWeight: FontWeight.w700, color: s.$3.ink)),
                  ]),
                ),
              ),
            ),
        ]),
      ]);
}

// ── buddhaGyro ────────────────────────────────────────────────────────────

class CalmQuote extends StatelessWidget {
  const CalmQuote({super.key, required this.onAct, this.now});
  final CalmAct onAct;
  final DateTime? now;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: QuoteStore.instance,
        builder: (context, _) {
          final n = now ?? DateTime.now();
          final today = DateTime(n.year, n.month, n.day);
          final store = QuoteStore.instance;
          final q = weekQuotes(n, override: (d) {
            if (d == today && store.live.trim().isNotEmpty) return store.live;
            return store.byDate[quoteDayKey(d)] ?? '';
          }).first.quote.text;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const CalmHead("Today's Quotes", eyebrow: 'One line to carry'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                key: _k('quotes'),
                onTap: () => onAct('quotes'),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE9E4F7), Color(0xFFF6EEF3)],
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('“', style: TextStyle(fontSize: 44, height: 0.8, color: Color(0xFF8C7BC7))),
                    Text(q,
                        style: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 21, height: 1.3, fontWeight: FontWeight.w600, color: Color(0xFF3B3366))),
                    const SizedBox(height: 14),
                    const Text('See the week  →', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF4B3F8C))),
                  ]),
                ),
              ),
            ),
          ]);
        },
      );
}

// ── store: rare drop + NowssB Earn + How you get paid ─────────────────────

class CalmEarn extends StatelessWidget {
  const CalmEarn({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final tiers = earnTierSummaries();
          final code = EconomyMirror.instance.code.trim();
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 18),
            CalmBand(
              key: _k('raredrop'),
              eyebrow: 'Signature',
              title: 'A rare drop, once only.',
              cta: 'View signatures',
              tone: const CalmTone(Color(0xFFF3E7C8), Color(0xFF5A3A12)),
              onTap: () => onAct('raredrop'),
              trailing: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC9A227), width: 2),
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                child: const Center(child: NwsbIcon(NwsbMarks.signature, size: 26, color: Color(0xFF8A6A12))),
              ),
            ),
            CalmHead('NowssB Earn', eyebrow: 'Your share of the net', more: 'Open Earn', onMore: () => onAct('earn')),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Text('Commission on net. Two levels. Never a third.', style: TextStyle(fontSize: 13, color: calmSoft)),
            ),
            CalmRail(height: 128, width: 132, children: [
              for (var i = 0; i < tiers.length; i++)
                Material(
                  key: _k('tier:$i'),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => onAct('earn'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tiers[i].$2, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color.lerp(const Color(0xFF5FA88A), const Color(0xFF4B3F8C), i / 5)!)),
                        const SizedBox(height: 4),
                        Text(tiers[i].$1, style: const TextStyle(fontSize: 12.5, height: 1.2, fontWeight: FontWeight.w700, color: calmInk)),
                        const Spacer(),
                        Text(tiers[i].$3.split(' · ').first, style: const TextStyle(fontSize: 11, color: calmSoft)),
                      ]),
                    ),
                  ),
                ),
            ]),
            const CalmHead('How you get paid'),
            CalmWrap(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _step('1', 'Your code.', code.isEmpty ? 'Share it with a friend.' : 'Yours is $code', CalmTone.sky),
                _step('2', 'Paid on net.', 'Net after the store fee. Not the sticker price.', CalmTone.sage),
                _step('3', 'Two levels.', 'Never a third.', CalmTone.lilac),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CalmPill('Join today', key: _k('earn-join'), onTap: () => onAct('earn'), fill: const Color(0xFF2F5D45), color: Colors.white),
                ),
              ]),
            ),
          ]);
        },
      );

  Widget _step(String n, String title, String sub, CalmTone tone) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tone.fill, shape: BoxShape.circle),
            child: Text(n, style: TextStyle(fontWeight: FontWeight.w800, color: tone.ink)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: calmInk)),
              Text(sub, style: const TextStyle(fontSize: 12.5, height: 1.3, color: calmSoft)),
            ]),
          ),
        ]),
      );
}

// ── reader: Reader + rewards / gifts / coupons ────────────────────────────

class CalmReader extends StatelessWidget {
  const CalmReader({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 18),
        CalmBand(
          key: _k('reader'),
          eyebrow: 'Reader',
          title: 'Meanings and eBooks, in one place',
          sub: 'Read every meaning, and every eBook.',
          mark: NwsbMarks.reader,
          tone: CalmTone.sky,
          onTap: () => onAct('reader'),
        ),
        const CalmHead('Rewards, gifts and coupons', eyebrow: 'Coins and streak'),
        CalmRail(height: 136, width: 138, children: [
          _tile(onAct, 'rewards', 'Open rewards', CalmTone.sand, mark: NwsbMarks.rewards, sub: 'Coins and streak'),
          _tile(onAct, 'invite', 'Invite a friend', CalmTone.rose, mark: NwsbMarks.reference),
          _tile(onAct, 'gift-send', 'Send a gift', CalmTone.peach, mark: NwsbMarks.gift),
          _tile(onAct, 'gift-redeem', 'Redeem a code', CalmTone.mint, mark: NwsbMarks.update),
          _tile(onAct, 'gift-rules', 'Gift rules and history', CalmTone.mist, mark: NwsbMarks.book),
          _tile(onAct, 'coupon-free', "Today's free card", CalmTone.lilac, mark: NwsbMarks.coupon),
          _tile(onAct, 'coupons', 'Your coupons and odds', CalmTone.sky, mark: NwsbMarks.bars),
        ]),
      ]);
}

// ── trendwd ───────────────────────────────────────────────────────────────

class CalmTrending extends StatelessWidget {
  const CalmTrending({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) {
    final words = ContentStore.instance.library;
    final word = words.isEmpty ? 'NowssB' : words[(DateTime.now().day + 3) % words.length].word;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const CalmHead("Today's Trending"),
      CalmWrap(
        padding: const EdgeInsets.all(14),
        child: InkWell(
          key: _k('trending'),
          onTap: () => onAct('trending'),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: calmInset(20),
              child: Text(word, style: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF4B3F8C))),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('See which words are healing the most people right now',
                  style: TextStyle(fontSize: 13, height: 1.3, color: calmSoft)),
            ),
            const NwsbIcon(NwsbMarks.trending, size: 22, color: Color(0xFF5FA88A)),
          ]),
        ),
      ),
    ]);
  }
}

// ── routines ──────────────────────────────────────────────────────────────

class CalmMyRoutines extends StatelessWidget {
  const CalmMyRoutines({super.key, required this.onAct});
  final CalmAct onAct;

  static const parts = [
    ('Morning', NwsbMarks.dawn, CalmTone.peach),
    ('Midday', NwsbMarks.sun, CalmTone.sand),
    ('Afternoon', NwsbMarks.sun, CalmTone.sage),
    ('Evening', NwsbMarks.moon, CalmTone.lilac),
    ('Night', NwsbMarks.moon, CalmTone.sky),
  ];

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CalmHead('My Routines', eyebrow: 'Five routines — build your healing schedule'),
        CalmWrap(
          child: Row(children: [
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  key: _k('routines:${parts[i].$1}'),
                  onTap: () => onAct('routines'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: parts[i].$3.fill, borderRadius: BorderRadius.circular(18)),
                    child: Column(children: [
                      NwsbIcon(parts[i].$2, size: 20, color: parts[i].$3.ink),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(parts[i].$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: parts[i].$3.ink)),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ]);
}

// ── condisc + feed + connectban ───────────────────────────────────────────

class CalmConnectNotes extends StatelessWidget {
  const CalmConnectNotes({super.key, required this.onAct});
  final CalmAct onAct;

  static const notes = [
    ('Your circle just got bigger.', 'Connect with learners like you.', CalmTone.sky),
    ('Stand out with a badge.', 'Blue, Silver, Gold or Diamond — your pick.', CalmTone.sand),
    ('New voices, new stories.', 'Discover creators worth following.', CalmTone.rose),
  ];

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CalmHead('NowssB Connect', eyebrow: 'The social space'),
        CalmRail(height: 112, width: 220, children: [
          for (final n in notes) _tile(onAct, 'connect', n.$1, n.$3, sub: n.$2, dense: true),
        ]),
      ]);
}

class CalmFeed extends StatelessWidget {
  const CalmFeed({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final code = EconomyMirror.instance.code.trim();
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const CalmHead('In your circle'),
            CalmWrap(
              child: Column(children: [
                CalmRow(key: _k('feed:feed'), title: 'Community Feed', sub: 'Share your daily practice with the world', mark: NwsbMarks.feed, tone: CalmTone.sky, onTap: () => onAct('connect')),
                CalmRow(key: _k('feed:stories'), title: 'Stories', sub: 'Drop 24-hour frequency moments', mark: NwsbMarks.stories, tone: CalmTone.peach, onTap: () => onAct('connect')),
                CalmRow(key: _k('feed:reels'), title: 'Reels', sub: 'Watch & post short healing reels', mark: NwsbMarks.reels, tone: CalmTone.rose, onTap: () => onAct('connect')),
                CalmRow(key: _k('feed:discover'), title: 'Discover Creators', sub: 'Find people worth following', mark: NwsbMarks.discover, tone: CalmTone.mint, onTap: () => onAct('connect')),
                CalmRow(key: _k('feed:verified'), title: 'Verified', sub: 'Earn your NowssB check-mark', mark: NwsbMarks.verified, tone: CalmTone.lilac, onTap: () => onAct('connect')),
              ]),
            ),
            const SizedBox(height: 14),
            CalmBand(
              key: _k('reference'),
              eyebrow: 'NowssB Reference',
              title: 'Share a link',
              cta: code.isEmpty ? 'Get your link' : 'Your code $code',
              mark: NwsbMarks.reference,
              tone: CalmTone.mint,
              onTap: () => onAct('reference'),
            ),
          ]);
        },
      );
}

class CalmConnectChips extends StatelessWidget {
  const CalmConnectChips({super.key, required this.onAct});
  final CalmAct onAct;

  static const items = [
    ('Community Feed', NwsbMarks.feed),
    ('Stories', NwsbMarks.stories),
    ('Reels', NwsbMarks.reels),
    ('Discover Creators', NwsbMarks.discover),
    ('Verified', NwsbMarks.verified),
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: CalmWrap(
          tint: const Color(0xFFDDE9F6),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Enter Connect', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF285A85))),
            const SizedBox(height: 4),
            const Text('Share your practice, follow creators, grow together.', style: TextStyle(fontSize: 12.5, color: Color(0xFF4A6F92))),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final i in items)
                ActionChip(
                  key: _k('connectban:${i.$1}'),
                  avatar: NwsbIcon(i.$2, size: 15, color: const Color(0xFF285A85)),
                  label: Text(i.$1),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF285A85)),
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onPressed: () => onAct('connect'),
                ),
            ]),
          ]),
        ),
      );
}

// ── quickrow ──────────────────────────────────────────────────────────────

class CalmQuick extends StatelessWidget {
  const CalmQuick({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CalmHead('Your things'),
        CalmWrap(
          child: CalmGrid(cols: 3, children: [
            _tile(onAct, 'cart', 'Your Cart', CalmTone.sand, mark: NwsbMarks.cart, dense: true),
            _tile(onAct, 'wishlist', 'Your Wishlist', CalmTone.rose, mark: NwsbMarks.wishlist, dense: true),
            _tile(onAct, 'orders', 'Your Orders', CalmTone.sky, mark: NwsbMarks.order, dense: true),
          ]),
        ),
      ]);
}

// ── trendshop ─────────────────────────────────────────────────────────────

class CalmTrendShop extends StatelessWidget {
  const CalmTrendShop({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) {
    final words = ContentStore.instance.library;
    final w = words.isEmpty ? null : words[(DateTime.now().day + 1) % words.length];
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: CalmBand(
        key: _k('trendshop'),
        eyebrow: w == null ? 'Heals' : 'Heals ${w.organ}',
        title: w?.word ?? 'The Store',
        cta: 'Shop Now',
        mark: NwsbMarks.wordBag,
        tone: CalmTone.peach,
        onTap: () => onAct('trendshop'),
      ),
    );
  }
}

// ── edition ───────────────────────────────────────────────────────────────

class CalmEdition extends StatelessWidget {
  const CalmEdition({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CalmHead('NowssB Edition', eyebrow: 'Join NowssB'),
          CalmWrap(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Material(
                color: const Color(0xFF3B3366),
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  key: _k('subscribe'),
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => onAct('subscribe'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        CalmDisc(NwsbMarks.crown, color: Color(0xFF3B3366), size: 42),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Get your subscription today',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      CalmPill('Upgrade Now', onTap: () => onAct('subscribe'), color: const Color(0xFF3B3366)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CalmRow(
                key: _k('partner'),
                title: '${EconomyMirror.instance.partnerPoints} partner points',
                sub: 'Spark · Glow · Radiant',
                mark: NwsbMarks.rewards,
                tone: CalmTone.sand,
                onTap: () => onAct('partner'),
              ),
            ]),
          ),
        ]),
      );
}

// ── ebooks ────────────────────────────────────────────────────────────────

class CalmEbooks extends StatelessWidget {
  const CalmEbooks({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: CalmBand(
          key: _k('ebooks'),
          eyebrow: 'Deep-dive guides, yours to keep',
          title: 'eBooks',
          sub: 'Word science and sound healing, read anywhere.',
          cta: 'Enter',
          mark: NwsbMarks.ebook,
          tone: CalmTone.mint,
          onTap: () => onAct('ebooks'),
        ),
      );
}

// ── healing ───────────────────────────────────────────────────────────────

class CalmHealing extends StatelessWidget {
  const CalmHealing({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const CalmHead('Your Health Journey', eyebrow: 'Choose your path'),
        CalmWrap(
          child: Column(children: [
            CalmRow(key: _k('healing'), title: 'Open your healing path', mark: NwsbMarks.people, tone: CalmTone.sage, onTap: () => onAct('healing')),
            const SizedBox(height: 6),
            CalmGrid(children: [
              _tile(onAct, 'healing-f', 'Female', CalmTone.rose, mark: NwsbMarks.gender, dense: true),
              _tile(onAct, 'healing-m', 'Male', CalmTone.sky, mark: NwsbMarks.gender, dense: true),
            ]),
          ]),
        ),
      ]);
}

// ── fashsw ────────────────────────────────────────────────────────────────

class CalmFashionSwitch extends StatelessWidget {
  const CalmFashionSwitch({super.key, required this.onAct});
  final CalmAct onAct;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: GestureDetector(
          key: _k('fashion'),
          onTap: () => onAct('fashion'),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            decoration: calmRaised(99),
            child: const Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Discover the experience', style: TextStyle(fontSize: 11.5, color: calmSoft)),
                  Text('Fashion Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: calmInk)),
                  Text('Dark · Cinematic · Editorial', style: TextStyle(fontSize: 11.5, color: calmSoft)),
                ]),
              ),
              CircleAvatar(radius: 20, backgroundColor: Color(0xFF1C1C24), child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20)),
            ]),
          ),
        ),
      );
}

// ── footer ────────────────────────────────────────────────────────────────

class CalmFooter extends StatelessWidget {
  const CalmFooter({super.key, required this.onAct});
  final CalmAct onAct;

  static const links = [
    ('About', 'about'),
    ('Word Science', 'word-science'),
    ('Sound Library', 'sound-library'),
    ('Meaning Store', 'meaning-store'),
    ('Practice', 'practice'),
    ('Profile', 'profile'),
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          decoration: const BoxDecoration(
            color: Color(0xFFE6E8EF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Across Every Language', style: TextStyle(fontFamily: 'CormorantGaramond', fontSize: 24, fontWeight: FontWeight.w700, color: calmInk)),
            const SizedBox(height: 4),
            const Text('Every civilization heard the same original sound.', style: TextStyle(fontSize: 13, height: 1.3, color: calmSoft)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final l in links) CalmPill(l.$1, key: _k('footer:${l.$2}'), onTap: () => onAct('footer:${l.$2}')),
            ]),
            const SizedBox(height: 20),
            const Text('© 2026 Adv. Sanjaykumar Gadge · Shabdapathy', style: TextStyle(fontSize: 11, color: calmSoft)),
          ]),
        ),
      );
}
