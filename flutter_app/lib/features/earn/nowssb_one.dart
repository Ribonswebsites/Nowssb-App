/// One page for NowssB Earn, Rewards, Coupons, Gifts and Reference.
///
/// A rank is explained the way a card offer is: the rate, three lines,
/// then the steps and the questions. The full list is its own tab.
library;

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import '../economy/money.dart';
import 'package:flutter/material.dart';
import '../economy/coupon_screen.dart';
import '../economy/economy_api.dart';
import '../economy/reference_screen.dart';
import '../gifts/gifts_screen.dart';
import 'earn_loyalty.dart';

class NowssbOnePage extends StatefulWidget {
  const NowssbOnePage({super.key, this.focus});

  /// ranks, coupons, gifts, links. Anything else opens the ranks.
  final String? focus;

  @override
  State<NowssbOnePage> createState() => _NowssbOnePageState();
}

class _NowssbOnePageState extends State<NowssbOnePage> {
  late int _tab = _tabOf(widget.focus);

  static int _tabOf(String? focus) => switch (focus) {
        'coupons' => 1,
        'gifts' => 2,
        'links' || 'reference' => 3,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07080C),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text('NowssB', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _TabRow(index: _tab, onPick: (i) => setState(() => _tab = i)),
            const SizedBox(height: 8),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  _Ranks(),
                  _Door(
                    title: 'Coupons',
                    line: 'A ticket you scratch. It is not cash, and it does not move your rank.',
                    color: Color(0xFF7C5CFF),
                    page: CouponScreen(),
                  ),
                  _Door(
                    title: 'Gifts',
                    line: 'Send the item itself. A gifted pass does not raise a rank.',
                    color: Color(0xFFE85D4C),
                    page: GiftsScreen(),
                  ),
                  _Door(
                    title: 'Your link',
                    line: 'One code. A friend who buys through it counts. Buying through your own link does not.',
                    color: Color(0xFF3DDC97),
                    page: ReferenceScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({required this.index, required this.onPick});
  final int index;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    const labels = ['Ranks', 'Coupons', 'Gifts', 'Links'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = i == index;
          return GestureDetector(
            onTap: () => onPick(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? Colors.white : const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: on ? Colors.white : const Color(0x22FFFFFF)),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: on ? const Color(0xFF111111) : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Ranks extends StatefulWidget {
  const _Ranks();
  @override
  State<_Ranks> createState() => _RanksState();
}

class _RanksState extends State<_Ranks> {
  late final PageController _pages = PageController();
  var _i = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) {
    setState(() => _i = i);
    _pages.animateToPage(i, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final steps = kEarnSteps;
    final yours = EarnStanding.of(EconomyMirror.instance).index;
    return Column(
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: steps.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final on = i == _i;
              return GestureDetector(
                onTap: () => _go(i),
                child: Text(
                  steps[i].shortName.toUpperCase(),
                  style: TextStyle(
                    color: on ? Colors.white : const Color(0x66FFFFFF),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    decoration: on ? TextDecoration.underline : null,
                    decorationColor: Colors.white,
                    decorationThickness: 2,
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: steps.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (_, i) => _TierBody(step: steps[i], index: i, yours: i == yours, last: i == steps.length - 1, next: i + 1 < steps.length ? steps[i + 1] : null),
          ),
        ),
      ],
    );
  }
}

class _TierBody extends StatelessWidget {
  const _TierBody({required this.step, required this.index, required this.yours, required this.last, required this.next});
  final EarnStep step;
  final int index;
  final bool yours;
  final bool last;
  final EarnStep? next;

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(index);
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _Hero(step: step, color: color, yours: yours),
            const SizedBox(height: 14),
            _RateCard(step: step, color: color),
            const SizedBox(height: 8),
            Text(
              'Paid only on a cleared sale, after tax and the store fee. The chain stops at 55% of Net.',
              textAlign: TextAlign.center,
              style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _BenefitCard(
              title: 'Your sales',
              line: '${step.rate}% of Net on words and plans you sold.',
              color: color,
            ),
            _BenefitCard(
              title: 'Level 1',
              line: step.leg1 == 0 ? 'No team share yet. The next rank adds it.' : '${_pct(step.leg1)}% of Net on sales by people you brought in.',
              color: const Color(0xFF5B8CFF),
            ),
            _BenefitCard(
              title: 'Level 2',
              line: step.leg2 == 0 ? 'Not at this rank.' : '${_pct(step.leg2)}% of Net on their people.',
              color: const Color(0xFFE85D4C),
            ),
            _BenefitCard(
              title: 'Coins',
              line: '10 coins = ${FxBook.instance.formatRupees(1)} in the catalogue. They are not a cash balance.',
              color: const Color(0xFFFFC857),
            ),
            const SizedBox(height: 8),
            _Steps(step: step, next: next),
            const SizedBox(height: 12),
            _Facts(step: step, next: next, last: last),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _FullList())),
                child: const Text('See every rank  ›', style: TextStyle(color: Color(0xFFFF4D6A), fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _FullList())),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                yours ? 'This is your rank' : 'See the full list',
                style: const TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatefulWidget {
  const _Hero({required this.step, required this.color, required this.yours});
  final EarnStep step;
  final Color color;
  final bool yours;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: SweepGradient(
                      transform: GradientRotation(t * math.pi * 2),
                      colors: [
                        const Color(0xFF0B1020),
                        widget.color.withValues(alpha: 0.85),
                        const Color(0xFF101018),
                        Colors.white.withValues(alpha: 0.35),
                        widget.color.withValues(alpha: 0.45),
                        const Color(0xFF0B1020),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    children: [
                      Text(
                        widget.yours ? 'YOUR RANK' : 'RANK ${widget.step.shortName.toUpperCase()}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.step.rate}%',
                        style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w800, height: 0.9),
                      ),
                      const Text('of Net', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _GlassPill(text: widget.step.title),
                      const SizedBox(height: 8),
                      Text(
                        widget.step.minWords == 0 ? 'Where you start' : '${widget.step.minWords} words sold to reach it',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x55FFFFFF)),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.step, required this.color});
  final EarnStep step;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      child: Column(
        children: [
          _rateRow('${step.rate}%', 'On your own cleared sales', color),
          const Divider(height: 18, color: Color(0x18FFFFFF)),
          _rateRow(step.leg1 == 0 ? '—' : '${_pct(step.leg1)}%', 'On level 1', const Color(0xFF8EB4FF)),
          const Divider(height: 18, color: Color(0x18FFFFFF)),
          _rateRow(step.leg2 == 0 ? '—' : '${_pct(step.leg2)}%', 'On level 2', const Color(0xFFFF8A7A)),
        ],
      ),
    );
  }

  Widget _rateRow(String n, String line, Color mark) {
    return Row(
      children: [
        Text(n, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(width: 12),
        Expanded(child: Text(line, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 14, fontWeight: FontWeight.w600))),
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: mark, borderRadius: BorderRadius.circular(10)),
          child: const Text('N', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.title, required this.line, required this.color});
  final String title;
  final String line;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFF16181E), fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(line, style: const TextStyle(color: Color(0xFF3A4048), fontSize: 13, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.step, required this.next});
  final EarnStep step;
  final EarnStep? next;

  @override
  Widget build(BuildContext context) {
    final goal = next == null ? 'You are at the last rank. The rate stays ${step.rate}%.' : 'Sell ${next!.minWords} words to reach ${next!.title}.';
    return _Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text('How a rank works', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
          const SizedBox(height: 12),
          _step('1', 'Share your link'),
          _step('2', 'Someone else buys a real plan'),
          _step('3', goal),
        ],
      ),
    );
  }

  Widget _step(String n, String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Text(n, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(line, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3))),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.step, required this.next, required this.last});
  final EarnStep step;
  final EarnStep? next;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('In plain words', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _q('What does this rank pay?', '${step.rate}% of Net on your own cleared sales.${step.leg1 == 0 ? '' : ' Plus ${_pct(step.leg1)}% on level 1${step.leg2 == 0 ? '' : ' and ${_pct(step.leg2)}% on level 2'}.'}'),
          _q('Can I buy the rank?', 'No. A plan you bought must be active, but the word target is what moves you up. A gifted pass does not.'),
          _q('What is Net?', 'The sale after tax and the store fee. A line under ${FxBook.instance.formatRupees(15)} is not paid. Refunds are reversed.'),
          _q(last ? 'Is this the top?' : 'What is next?', last ? 'Diamond II is the last rank.' : '${next!.title} pays ${next!.rate}% once ${next!.minWords} words have sold.'),
        ],
      ),
    );
  }

  Widget _q(String title, String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 3),
          Text(line, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.35)),
        ],
      ),
    );
  }
}

class _FullList extends StatelessWidget {
  const _FullList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07080C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07080C),
        foregroundColor: Colors.white,
        title: const Text('Every rank', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'Each rank is a share of Net on cleared sales. Not cash in hand. Not something you buy.',
            style: TextStyle(color: Color(0xB3FFFFFF), height: 1.35),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < kEarnSteps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BenefitCard(
                title: kEarnSteps[i].title,
                line: '${kEarnSteps[i].rate}% of Net · ${kEarnSteps[i].minWords} words'
                    '${kEarnSteps[i].leg1 == 0 ? '' : ' · team ${_pct(kEarnSteps[i].leg1)}%${kEarnSteps[i].leg2 == 0 ? '' : ' / ${_pct(kEarnSteps[i].leg2)}%'}'}',
                color: _tierColor(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Door extends StatelessWidget {
  const _Door({required this.title, required this.line, required this.color, required this.page});
  final String title;
  final String line;
  final Color color;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _HeroPlain(title: title, line: line, color: color),
        const SizedBox(height: 14),
        _BenefitCard(title: title, line: line, color: color),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page)),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Text('Open $title', style: const TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

class _HeroPlain extends StatefulWidget {
  const _HeroPlain({required this.title, required this.line, required this.color});
  final String title;
  final String line;
  final Color color;
  @override
  State<_HeroPlain> createState() => _HeroPlainState();
}

class _HeroPlainState extends State<_HeroPlain> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 180,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: SweepGradient(
                transform: GradientRotation(_c.value * math.pi * 2),
                colors: [const Color(0xFF0B1020), widget.color, Colors.white, const Color(0xFF0B1020)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(widget.line, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x28FFFFFF)),
          ),
          child: child,
        ),
      ),
    );
  }
}

Color _tierColor(int i) => switch (i) {
      0 => const Color(0xFFE8E8E8),
      1 => const Color(0xFFCD8B54),
      2 => const Color(0xFF5B8CFF),
      3 => const Color(0xFF3DDC97),
      4 => const Color(0xFFFFC857),
      _ => const Color(0xFF9EE7FF),
    };

String _pct(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';
