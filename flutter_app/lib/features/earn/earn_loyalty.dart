/// NowssB Earn, shown like a membership card: who you are, which rank,
/// the word target, then what this rank pays and what the next one adds.
///
/// No film behind it. Each rank opens its own page. Commission is a share
/// of Net on cleared sales — not cash in hand, and not something you buy.
library;

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../programs/rewards_program.dart';

class EarnStep {
  const EarnStep(this.title, this.shortName, this.minWords, this.rate, this.leg1, this.leg2);
  final String title;
  final String shortName;
  final int minWords;
  final int rate;
  final double leg1;
  final double leg2;

  String get article {
    final c = title.isEmpty ? 'a' : title[0].toLowerCase();
    return 'aeiou'.contains(c) ? 'an' : 'a';
  }
}

String _pct(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

const kEarnSteps = <EarnStep>[
  EarnStep('Assistant Officer', 'Start', 0, 15, 0, 0),
  EarnStep('Officer', 'Officer', 100, 22, 3, 0),
  EarnStep('Executive Officer I', 'Exec I', 500, 30, 5, 1.5),
  EarnStep('Executive Officer II', 'Exec II', 1000, 38, 5, 1.5),
  EarnStep('Diamond I', 'Dia I', 2000, 45, 7, 3),
  EarnStep('Diamond II', 'Dia II', 3000, 50, 7, 3),
];

List<EarnStep> earnStepsFrom(Map<String, dynamic> summary) {
  final cfg = summary['config'];
  final earn = cfg is Map ? cfg['earn'] : null;
  final raw = earn is Map ? earn['ranks'] : null;
  if (raw is! List || raw.isEmpty) return kEarnSteps;
  final out = <EarnStep>[];
  for (final r in raw) {
    if (r is! Map) continue;
    final title = '${r['title'] ?? ''}'.trim();
    if (title.isEmpty) continue;
    final leg = r['leg'] is List ? r['leg'] as List : const [0, 0];
    int n(Object? v) => v is num ? v.round() : int.tryParse('$v') ?? 0;
    double d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    final known = kEarnSteps.where((s) => s.title == title);
    final short = known.isEmpty ? (title.length <= 8 ? title : title.split(' ').first) : known.first.shortName;
    out.add(EarnStep(title, short, n(r['minWords']), n(r['ratePct']), leg.isEmpty ? 0 : d(leg.first), leg.length > 1 ? d(leg[1]) : 0));
  }
  return out.isEmpty ? kEarnSteps : out;
}

class EarnStanding {
  const EarnStanding({required this.steps, required this.words, required this.index, required this.name});
  final List<EarnStep> steps;
  final int words;
  final int index;
  final String name;

  EarnStep get step => steps[index.clamp(0, steps.length - 1)];
  EarnStep? get next => index + 1 < steps.length ? steps[index + 1] : null;

  static EarnStanding of(EconomyMirror w) {
    final steps = earnStepsFrom(w.summary);
    final earn = w.summary['earn'];
    var words = w.wordsSold;
    String? title;
    if (earn is Map) {
      if (earn['words'] is num) words = (earn['words'] as num).round();
      final t = '${earn['title'] ?? ''}'.trim();
      if (t.isNotEmpty) title = t;
    }
    var index = title == null ? -1 : steps.indexWhere((s) => s.title == title);
    if (index < 0) {
      index = 0;
      for (var i = 0; i < steps.length; i++) {
        if (words >= steps[i].minWords) index = i;
      }
    }
    var name = '';
    if (NwsbFirebase.ready) {
      final n = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
      if (n.isNotEmpty) name = n.split(RegExp(r'\s+')).first;
    }
    return EarnStanding(steps: steps, words: words, index: index, name: name);
  }
}

/// The membership front of NowssB Earn.
class EarnLoyaltyBoard extends StatelessWidget {
  const EarnLoyaltyBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final stand = EarnStanding.of(EconomyMirror.instance);
        return _Board(stand: stand, focus: stand.index, yours: true, openSame: true);
      },
    );
  }
}

class EarnRankPage extends StatelessWidget {
  const EarnRankPage({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final stand = EarnStanding.of(EconomyMirror.instance);
        final i = index.clamp(0, stand.steps.length - 1);
        final step = stand.steps[i];
        return EconomyPage(
          film: false,
          title: step.title,
          mark: NwsbMarks.earn,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Board(stand: stand, focus: i, yours: i == stand.index),
            ],
          ),
        );
      },
    );
  }
}

class _Board extends StatefulWidget {
  const _Board({required this.stand, required this.focus, required this.yours, this.openSame = false});
  final EarnStanding stand;
  final int focus;
  final bool yours;

  /// The home board opens a rank page. A rank page does not open itself again.
  final bool openSame;

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> {
  var _nextTab = false;

  @override
  Widget build(BuildContext context) {
    final stand = widget.stand;
    final step = stand.steps[widget.focus.clamp(0, stand.steps.length - 1)];
    final next = widget.focus + 1 < stand.steps.length ? stand.steps[widget.focus + 1] : null;
    final hello = stand.name.isEmpty ? 'Hello' : 'Hello ${stand.name}';
    final status = widget.yours
        ? "You're ${step.article} ${step.title}"
        : widget.focus < stand.index
            ? 'You passed ${step.title}'
            : '${step.title} starts at ${step.minWords} words';
    final goal = next?.minWords ?? step.minWords;
    final into = next == null ? 1.0 : ((stand.words - step.minWords) / math.max(1, next.minWords - step.minWords)).clamp(0.0, 1.0);
    final need = next == null ? 0 : math.max(0, next.minWords - stand.words);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      Text(hello, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE8E6E1), fontSize: 16)),
      const SizedBox(height: 4),
      Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.15)),
      const SizedBox(height: 16),
      _MetalCard(step: step, words: stand.words, goal: goal, yours: widget.yours),
      const SizedBox(height: 18),
      _Track(steps: stand.steps, focus: widget.focus, onTap: (i) {
        if (i == widget.focus && !widget.openSame) return;
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EarnRankPage(index: i)));
      }),
      const SizedBox(height: 12),
      Text(
        next == null
            ? 'Top rank. ${step.rate}% of Net on your own cleared sales.'
            : widget.yours
                ? '$need more words to ${next.title}. That rank pays ${next.rate}% of Net.'
                : 'You have ${stand.words} words. This page is ${step.title}.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: NwsbColors.mist, fontSize: 13, height: 1.35),
      ),
      const SizedBox(height: 16),
      _balance(context),
      const SizedBox(height: 12),
      _redeem(context),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: _tab('Your benefits', !_nextTab, () => setState(() => _nextTab = false))),
        Expanded(child: _tab('Next rank', _nextTab, () => setState(() => _nextTab = true))),
      ]),
      const SizedBox(height: 12),
      if (!_nextTab) ..._now(step) else ..._later(step, next, need),
      const SizedBox(height: 8),
      const Text(
        'Paid only on cleared sales, after tax and the store fee. Not guaranteed. A line under ₹15 is not paid. The chain stops at 55% of Net. Gifted passes do not raise a rank. 10 coins = ₹1 in the catalogue, not cash.',
        style: TextStyle(color: NwsbColors.mist, fontSize: 11, height: 1.4),
      ),
      if (widget.yours) const SizedBox(height: 4) else const SizedBox(height: 8),
      if (!widget.yours)
        TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EarnRankPage(index: stand.index))),
          child: Text('Open your rank · ${stand.step.title}', style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w700)),
        ),
    ]);
  }

  Widget _balance(BuildContext context) {
    final w = EconomyMirror.instance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Expanded(
          child: Text('Coin balance', style: TextStyle(color: Color(0xFF3A4048), fontWeight: FontWeight.w700, fontSize: 15)),
        ),
        if (w.uid == null)
          const Text('Sign in', style: TextStyle(color: Color(0xFF3A4048), fontWeight: FontWeight.w800))
        else
          CoinCount(value: w.coins, style: const TextStyle(color: Color(0xFF1A1D22), fontSize: 22, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _redeem(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RewardsProgramPage())),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [Color(0xFF4A4E56), Color(0xFF2A2E34), Color(0xFF6A707A)]),
          ),
          child: const Text('SHOP & REDEEM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
        ),
      );

  Widget _tab(String label, bool on, VoidCallback tap) => GestureDetector(
        onTap: tap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(children: [
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: on ? Colors.white : NwsbColors.mist, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.4)),
            const SizedBox(height: 8),
            AnimatedContainer(duration: const Duration(milliseconds: 180), height: 2, color: on ? Colors.white : Colors.transparent),
          ]),
        ),
      );

  List<Widget> _now(EarnStep step) => [
        _perk('Your rate', '${step.rate}% of Net on your own cleared sales'),
        if (step.leg1 > 0) _perk('Team', 'Level 1: ${_pct(step.leg1)}% of Net on their sales.${step.leg2 > 0 ? ' Level 2: ${_pct(step.leg2)}%.' : ''} The chain stops at 55% of Net.'),
        if (step.leg1 == 0) _perk('Team', 'No team share yet. Officer adds one level.'),
        _perk('Plan', 'A paid plan you bought must be active. A gifted pass does not unlock the rank.'),
        _perk('Coins', 'Spend them in the catalogue. They are not a cash balance.'),
      ];

  List<Widget> _later(EarnStep step, EarnStep? next, int need) {
    if (next == null) {
      return [_perk('Top', 'Diamond II is the last rank. The rate stays ${step.rate}% of Net.')];
    }
    return [
      _perk('Target', '$need words to ${next.title} (${next.minWords} sold).'),
      _perk('Rate', 'Becomes ${next.rate}% of Net. Still only on cleared sales.'),
      if (next.leg1 != step.leg1 || next.leg2 != step.leg2)
        _perk('Team', next.leg1 == 0 ? 'Team share stays off.' : 'Level 1 becomes ${_pct(next.leg1)}%.${next.leg2 > 0 ? ' Level 2: ${_pct(next.leg2)}%.' : ''}'),
      _perk('Not for sale', 'Buying a plan does not skip the word target.'),
    ];
  }

  Widget _perk(String title, String line) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 10),
            child: Icon(Icons.auto_awesome, size: 16, color: Color(0xFFE8D5A3)),
          ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 2),
            Text(line, style: const TextStyle(color: NwsbColors.mist, fontSize: 13, height: 1.35)),
          ])),
        ]),
      );
}

class _MetalCard extends StatefulWidget {
  const _MetalCard({required this.step, required this.words, required this.goal, required this.yours});
  final EarnStep step;
  final int words;
  final int goal;
  final bool yours;

  @override
  State<_MetalCard> createState() => _MetalCardState();
}

class _MetalCardState extends State<_MetalCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metal = _metal(widget.step);
    final progress = widget.goal <= 0 ? 1.0 : (widget.words / widget.goal).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Container(
          height: 176,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(-1.3 + t * 2.6, -0.8),
              end: Alignment(0.2 + t * 2.6, 1),
              colors: metal,
            ),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('NOWSSB EARN', style: TextStyle(color: Color(0xFF2A261C), fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
            const Spacer(),
            Text(widget.step.title.toUpperCase(), style: const TextStyle(color: Color(0xFF1A170F), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: const Color(0xFF1A170F),
                backgroundColor: const Color(0x33000000),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.yours ? '${widget.words} / ${widget.goal} words' : 'Opens at ${widget.step.minWords} words · ${widget.step.rate}% of Net',
              style: const TextStyle(color: Color(0xFF3A3428), fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ]),
        );
      },
    );
  }

  List<Color> _metal(EarnStep step) {
    if (step.rate >= 45) {
      return const [Color(0xFFE7FBFF), Color(0xFFB9D7E4), Color(0xFFF8FFFF), Color(0xFF8FB4C4)];
    }
    if (step.rate >= 30) {
      return const [Color(0xFFF8E7B0), Color(0xFFC8A96E), Color(0xFFFFF6D8), Color(0xFF8A6A32)];
    }
    return const [Color(0xFFF4F6F8), Color(0xFFC5CCD4), Color(0xFFFFFFFF), Color(0xFF8E97A3)];
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.steps, required this.focus, required this.onTap});
  final List<EarnStep> steps;
  final int focus;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final n = steps.length;
    return LayoutBuilder(builder: (context, box) {
      final inset = n == 0 ? 0.0 : box.maxWidth / n / 2;
      final span = (n - 1).clamp(1, 99);
      return Stack(children: [
        Positioned(
          left: inset,
          right: inset,
          top: 7,
          child: const SizedBox(height: 2, child: ColoredBox(color: Color(0x33FFFFFF))),
        ),
        Positioned(
          left: inset,
          right: inset,
          top: 7,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (focus / span).clamp(0.0, 1.0),
              child: const SizedBox(height: 2, child: ColoredBox(color: Color(0xFFE8D5A3))),
            ),
          ),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < n; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(children: [
                  SizedBox(
                    height: 16,
                    child: Center(
                      child: Container(
                        width: i == focus ? 16 : 11,
                        height: i == focus ? 16 : 11,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= focus ? const Color(0xFFE8D5A3) : const Color(0xFF2A2E34),
                          border: Border.all(color: i <= focus ? const Color(0xFFE8D5A3) : const Color(0x66FFFFFF), width: 1.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[i].shortName,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i == focus ? Colors.white : NwsbColors.mist,
                      fontSize: 10,
                      fontWeight: i == focus ? FontWeight.w800 : FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                ]),
              ),
            ),
        ]),
      ]);
    });
  }
}

