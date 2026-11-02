/// R27 — the four new home sections. Each has a NORMAL variant (white
/// neumorphic frame, greeting head, dark poster cards) and a FASHION variant
/// (`fashion: true`: full black, giant poster word bleeding off the edge).
/// Every card row auto-rotates; every tap is a required hook.
library;

import '../../../screens/concept/drop_v5.dart' show CornerPeel;
import 'package:flutter/material.dart';

import '../../../features/economy/reward_fx.dart' show rarityColor, rarityTitle;
import 'anims.dart';
import 'data.dart';
import 'kit.dart';
import '../normal/surface.dart';

String _shortDate(int ms) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.day} ${m[d.month - 1]}';
}

String _n(num v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

/// Shared outer shell: normal = neumorphic frame, fashion = black band.
class _Shell extends StatelessWidget {
  const _Shell({required this.fashion, required this.head, required this.row, required this.links, this.poster});
  final bool fashion;
  final Widget head, row;
  final List<Widget> links;
  final Widget? poster;
  @override
  Widget build(BuildContext context) {
    if (!fashion) {
      return R27NeuFrame(
          child: R27Tone(light: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(right: 18), child: head),
        const SizedBox(height: 16),
        ClipRect(child: row),
        const SizedBox(height: 4),
        ...links,
      ])));
    }
    return ColoredBox(
      color: r27Black,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 22, 0, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (poster != null) poster!,
          row,
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: head),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: links)),
        ]),
      ),
    );
  }
}

// ══ REWARDS — torn tiles drifting over hour posters ═══════════════════════
class R27RewardsSection extends StatelessWidget {
  const R27RewardsSection({super.key, required this.data, required this.onOpen, required this.onClaim, required this.onSignIn, this.fashion = false, this.debugPeel});
  final R27Rewards data;

  /// Shots: freeze every tile's corner peel.
  final double? debugPeel;
  final VoidCallback onOpen, onClaim, onSignIn;
  final bool fashion;

  List<R27TornData> tiles() => r27RewardTiles(data, onOpen: onOpen, onClaim: onClaim, onSignIn: onSignIn);

  @override
  Widget build(BuildContext context) {
    final t = tiles();
    final h = fashion ? r27H(context, 250, 40) : r27H(context, 196, 40);
    return _Shell(
      fashion: fashion,
      poster: fashion ? const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 0), child: SizedBox(height: 74, child: R27Word('REWARDS', color: r27Gold, outline: true))) : null,
      head: R27Head(dark: fashion, hello: 'Your rewards', title: '${data.coins} coins', sub: 'Day ${data.streak} streak · next chest in ${data.toChest} coins'),
      row: R27AutoRow(
        count: t.length,
        height: h,
        fraction: fashion ? .62 : .56,
        builder: (c, i, off) => R27TornTile(t[i], offset: off, peel: true, debugPeel: debugPeel),
      ),
      links: [R27Link('Open rewards', dark: fashion, onTap: onOpen)],
    );
  }
}

class R27TornData {
  const R27TornData({required this.hour, required this.tag, required this.value, required this.line, required this.onTap, required this.seed});
  final String hour, tag, value, line;
  final VoidCallback onTap;
  final int seed;
}

List<R27TornData> r27RewardTiles(R27Rewards d, {required VoidCallback onOpen, required VoidCallback onClaim, required VoidCallback onSignIn}) => [
      R27TornData(hour: 'surya', tag: 'Coins', value: '${d.coins}', line: 'In your vault', onTap: onOpen, seed: 3),
      R27TornData(hour: 'tejas', tag: 'Day streak', value: '${d.streak}', line: d.streak > 0 ? 'Keep the flame lit today' : 'Light day one today', onTap: onOpen, seed: 8),
      R27TornData(hour: 'soma', tag: 'To next chest', value: '${d.toChest}', line: 'A chest opens every ${d.chestEvery} coins', onTap: onOpen, seed: 13),
      if (!d.signedIn)
        R27TornData(hour: 'ananda', tag: 'Today', value: 'SIGN IN', line: 'Sign in to keep your coins', onTap: onSignIn, seed: 21)
      else
        R27TornData(
            hour: 'ananda',
            tag: 'Today',
            value: d.loginToday ? 'DONE' : 'CLAIM',
            line: d.loginToday ? "Today's coin is in" : "Today's coin is waiting",
            onTap: d.loginToday ? onOpen : onClaim,
            seed: 21),
    ];

class R27TornTile extends StatelessWidget {
  const R27TornTile(this.d, {super.key, this.offset = 0, this.peel = false, this.debugPeel});

  /// Home card: the auto corner peel (tap peels fully, then opens).
  final bool peel;
  final R27TornData d;

  /// Shots: freeze the corner peel.
  final double? debugPeel;
  final double offset;
  @override
  Widget build(BuildContext context) {
    final a = offset.abs().clamp(0.0, 1.0);
    final light = R27Tone.isLight(context);
    final Widget face = light ? _lightFace() : Stack(fit: StackFit.expand, children: [
      Transform.translate(offset: Offset(offset * -24, 0), child: Transform.scale(scale: 1.15, child: R27Img(d.hour))),
      const DecoratedBox(decoration: r27Scrim),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          R27TagLabel(d.tag),
          const Spacer(),
          Flexible(flex: 3, child: R27Word(d.value, align: Alignment.bottomLeft)),
          const SizedBox(height: 6),
          Text(d.line, style: dSub),
        ]),
      ),
    ]);
    final tilt = (d.seed.isOdd ? -.035 : .03) + offset * .05;
    return Transform.translate(
      offset: Offset(0, a * 14),
      child: Transform.rotate(
        angle: tilt,
        child: Opacity(
          opacity: 1 - a * .25,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
            // Ribon 11-02: the Drop Studio entry's corner peel, playing on a
            // loop; a tap peels it fully, then opens.
            child: ClipPath(
              clipper: R27Torn(seed: d.seed),
              child: !peel
                  ? NPress(onTap: d.onTap, label: '${d.tag} ${d.value}', child: face)
                  : CornerPeel(
                      key: ValueKey('rewards-peel-${d.seed}'),
                      label: '${d.tag} ${d.value}',
                      loop: Duration(milliseconds: 3000 + d.seed * 90),
                      debugPeel: debugPeel,
                      onOpen: d.onTap,
                      under: Stack(fit: StackFit.expand, children: [
                        if (light) const ColoredBox(color: Color(0xFFE6E9F0)) else ...[R27Img(d.hour), const ColoredBox(color: Color(0xB3000000))],
                        const Center(child: Icon(Icons.redeem_rounded, color: r27Gold, size: 40)),
                      ]),
                      child: face,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══ GIFTS — cream word posters in a coverflow, ribbon sweep ═══════════════
class R27GiftsSection extends StatelessWidget {
  const R27GiftsSection({super.key, required this.data, required this.onGift, required this.onRedeem, required this.onOpen, this.fashion = false});
  final R27Gifts data;
  final void Function(String id) onGift;
  final VoidCallback onRedeem, onOpen;
  final bool fashion;
  @override
  Widget build(BuildContext context) {
    final cards = data.cards;
    final low = cards.isEmpty ? 0 : cards.map((c) => c.priceInr).reduce((a, b) => a < b ? a : b);
    final h = r27H(context, fashion ? 300 : 270, 34);
    final row = R27AutoRow(
      count: cards.length,
      height: h,
      fraction: fashion ? .66 : .64,
      every: const Duration(milliseconds: 3200),
      builder: (c, i, off) => R27GiftPoster(cards[i], hour: r27Hours[(i + 4) % r27Hours.length], offset: off, onGift: () => onGift(cards[i].id)),
    );
    return _Shell(
      fashion: fashion,
      head: R27Head(dark: fashion, hello: 'NowssB Gifts', title: 'Give a word', sub: r27GiftsLine(data, low)),
      row: cards.isEmpty
          ? R27GiftsEmpty(dark: fashion)
          : fashion
          ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(
                  width: 58,
                  height: h,
                  child: const RotatedBox(quarterTurns: 3, child: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: R27Word('GIFTS', color: r27Gold, align: Alignment.center)))),
              Expanded(child: row),
            ])
          : row,
      links: [
        R27Link('Redeem a gift code', dark: fashion, onTap: onRedeem),
        R27Link('All gifts', dark: fashion, onTap: onOpen),
      ],
    );
  }
}

/// B034: the Gifts sub line from real counts only; zero parts are left out
/// (null when there is nothing to say).
String? r27GiftsLine(R27Gifts d, num low) {
  final parts = [
    if (d.cards.isNotEmpty) '${d.cards.length} gift cards from ₹$low',
    if (d.sent > 0) '${d.sent} sent',
    if (d.received > 0) '${d.received} received',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// B034: shown instead of the card row when there are no gift cards.
class R27GiftsEmpty extends StatelessWidget {
  const R27GiftsEmpty({super.key, this.dark = false});
  final bool dark;
  @override
  Widget build(BuildContext context) => Padding(
        key: const ValueKey('gifts-empty'),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: dark ? r27Line : const Color(0x1F000000)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('No gift cards right now', style: (dark ? dSub : nSub).copyWith(color: dark ? Colors.white : nInk, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Have a code someone sent you? Redeem it below.', style: dark ? dSub : nSub),
          ]),
        ),
      );
}

String r27GiftWord(String label) {
  final w = label.toUpperCase().split(' ');
  if (w.length <= 1) return w.join();
  return '${w.first}\n${w.skip(1).join(' ')}';
}

extension on R27TornTile {
  static const _icons = {'Coins': Icons.toll_rounded, 'Day streak': Icons.local_fire_department_rounded, 'To next chest': Icons.inventory_2_rounded};
  Widget _lightFace() => ColoredBox(
        color: r27LCard,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              R27IconWell(_icons[d.tag] ?? Icons.wb_sunny_rounded, size: 38, color: const Color(0xFFB07A1A)),
              const SizedBox(width: 8),
              Flexible(child: R27TagLabel(d.tag)),
            ]),
            const Spacer(),
            Flexible(flex: 3, child: R27Word(d.value, color: r27LInk, shadow: false, align: Alignment.bottomLeft)),
            const SizedBox(height: 6),
            Text(d.line, style: dSub.copyWith(color: r27LSub)),
          ]),
        ),
      );
}

class R27GiftPoster extends StatelessWidget {
  const R27GiftPoster(this.g, {super.key, required this.hour, required this.onGift, this.offset = 0});
  final R27Gift g;
  final String hour;
  final VoidCallback onGift;
  final double offset;
  @override
  Widget build(BuildContext context) {
    final a = offset.clamp(-1.0, 1.0);
    final m = Matrix4.identity()
      ..setEntry(3, 2, .0012)
      ..rotateY(-a * .55);
    return Transform(
      alignment: Alignment.center,
      transform: m,
      child: Transform.scale(
        scale: 1 - .12 * a.abs(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: NPress(
            onTap: onGift,
            label: 'Gift ${g.label}',
            child: Container(
              decoration: BoxDecoration(color: r27Paper, borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 10))]),
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(flex: 4, child: R27Word(r27GiftWord(g.label), color: r27PaperInk, shadow: false)),
                const SizedBox(height: 10),
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(200), bottom: Radius.circular(4)),
                    child: Stack(fit: StackFit.expand, children: [
                      if (R27Tone.isLight(context))
                        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9E4F7), Color(0xFFF6E3CF)])))
                      else
                        R27Img(hour, sat: .6),
                      R27Anim(period: const Duration(seconds: 5), builder: (_, t) => CustomPaint(painter: R27Ribbon(t))),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 6, children: [
                  Text('₹${g.priceInr}', style: nTitle.copyWith(color: r27PaperInk)),
                  R27Pill('Gift it', light: true, onTap: onGift),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ══ EARN — rising rank steps, spinning coin ═══════════════════════════════
class R27EarnSection extends StatelessWidget {
  const R27EarnSection({super.key, required this.data, required this.onOpen, required this.onRank, this.fashion = false});
  final R27Earn data;
  final VoidCallback onOpen;
  final void Function(int index) onRank;
  final bool fashion;
  @override
  Widget build(BuildContext context) {
    final cur = data.current;
    final next = cur + 1 < data.ranks.length ? data.ranks[cur + 1] : null;
    final h = r27H(context, fashion ? 250 : 220, 56);
    return _Shell(
      fashion: fashion,
      poster: fashion
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: SizedBox(height: 84, child: R27Word('${_n(data.topRate)}%', color: r27Gold, outline: true))),
                const R27Coin(size: 64),
              ]))
          : null,
      head: fashion ? _earnHead(true, next) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _earnHead(false, next)), const R27Coin(size: 56)]),
      row: R27AutoRow(
        count: data.ranks.length,
        height: h,
        fraction: fashion ? .5 : .46,
        initial: cur,
        every: const Duration(milliseconds: 2800),
        builder: (c, i, off) => R27RankStep(data.ranks[i], index: i, top: data.topRate, current: i == cur, offset: off, onTap: () => onRank(i)),
      ),
      links: [R27Link('Open NowssB Earn', dark: fashion, onTap: onOpen)],
    );
  }

  Widget _earnHead(bool dark, R27Rank? next) => R27Head(
        dark: dark,
        hello: 'NowssB Earn',
        title: '${_n(data.shownRate)}% on net',
        sub: 'Commission on net. Two levels. ${data.wordsSold} words sold'
            '${next == null ? ' · top rank' : ' · ${next.title} at ${next.minWords}'}',
      );
}

class R27RankStep extends StatelessWidget {
  const R27RankStep(this.r, {super.key, required this.index, required this.top, required this.current, required this.onTap, this.offset = 0});
  final R27Rank r;
  final int index;
  final num top;
  final bool current;
  final VoidCallback onTap;
  final double offset;
  @override
  Widget build(BuildContext context) {
    final rise = 1 - .3 * offset.abs().clamp(0.0, 1.0);
    final f = top <= 0 ? .4 : (.3 + .45 * (r.ratePct / top)) * rise;
    final light = R27Tone.isLight(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: NPress(
        onTap: onTap,
        label: '${r.title} ${_n(r.ratePct)} percent',
        child: Container(
          foregroundDecoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: current ? r27Gold : (light ? const Color(0x1F000000) : r27Line), width: current ? 2 : 1)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(fit: StackFit.expand, children: [
              if (light) const ColoredBox(color: r27LCard) else ...[R27Img(r27Hours[(index + 5) % r27Hours.length]), const ColoredBox(color: Color(0x99000000))],
              LayoutBuilder(
                  // B029: the name keeps its natural height; the bar takes
                  // f of the step but yields to it (no overflow at top rank).
                  builder: (c, box) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.end, children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            if (current) ...[const R27TagLabel('You'), const SizedBox(height: 8)],
                            Text(r.title, style: dSub.copyWith(color: light ? r27LInk : Colors.white, fontWeight: FontWeight.w800)),
                            Text('${r.minWords}+ words', style: light ? dSub.copyWith(color: r27LSub) : dSub),
                          ]),
                        ),
                        Flexible(
                            child: SizedBox(
                          height: box.maxHeight * f,
                          child: ClipPath(
                            clipper: R27Torn(seed: index + 4, bottom: false, depth: 6),
                            child: ColoredBox(
                              color: light ? (current ? const Color(0xFFF7F8FB) : const Color(0xFFE6E9F0)) : (current ? r27Gold : r27Paper),
                              child: Padding(padding: const EdgeInsets.fromLTRB(10, 12, 10, 8), child: R27Word('${_n(r.ratePct)}%', color: r27PaperInk, shadow: false, align: Alignment.bottomLeft)),
                            ),
                          ),
                        )),
                      ])),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══ COUPONS — perforated stubs and foil sealed cards ══════════════════════
class R27CouponsSection extends StatelessWidget {
  const R27CouponsSection({super.key, required this.data, required this.onScratch, required this.onOpen, required this.onCoupon, this.fashion = false});
  final R27Coupons data;
  final VoidCallback onScratch, onOpen;
  final void Function(int index) onCoupon;
  final bool fashion;

  @override
  Widget build(BuildContext context) {
    final items = r27CouponCards(data, onScratch: onScratch, onOpen: onOpen, onCoupon: onCoupon);
    final h = r27H(context, fashion ? 176 : 164, 80);
    final title =
        data.coupons.isNotEmpty ? '${data.coupons.length} ${data.coupons.length == 1 ? 'discount' : 'discounts'} ready' : (!data.scratchedToday ? "Today's card is ready" : 'Cards and discounts');
    return _Shell(
      fashion: fashion,
      poster: fashion
          ? const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: SizedBox(height: 66, child: ClipRect(child: Align(alignment: Alignment.topLeft, heightFactor: .72, child: SizedBox(height: 92, child: R27Word('SAVE', color: r27Gold))))))
          : null,
      head: R27Head(dark: fashion, hello: 'NowssB Coupons', title: title, sub: '${data.sealedTotal} sealed ${data.sealedTotal == 1 ? 'card' : 'cards'} waiting · discounts apply at checkout'),
      row: R27AutoRow(
        count: items.length,
        height: h,
        fraction: fashion ? .84 : .8,
        every: const Duration(milliseconds: 4000),
        builder: (c, i, off) {
          final a = off.abs().clamp(0.0, 1.0);
          return Transform.translate(
            offset: Offset(off * -18, a * 10),
            child: Transform.scale(scale: 1 - .08 * a, child: Opacity(opacity: 1 - .35 * a, child: items[i])),
          );
        },
      ),
      links: [
        if (!data.scratchedToday) R27Link("Scratch today's card", dark: fashion, onTap: onScratch),
        R27Link('Open coupons', dark: fashion, onTap: onOpen),
      ],
    );
  }
}

List<Widget> r27CouponCards(R27Coupons d, {required VoidCallback onScratch, required VoidCallback onOpen, required void Function(int) onCoupon}) => [
      if (!d.scratchedToday) R27FoilCard(tint: r27Gold, tag: 'Today', word: 'FREE', line: "Today's card is ready to scratch", onTap: onScratch),
      for (var i = 0; i < d.coupons.length; i++) R27Stub(d.coupons[i], onTap: () => onCoupon(i)),
      for (final e in d.sealed.entries) R27FoilCard(tint: rarityColor(e.key), tag: rarityTitle(e.key), word: '×${e.value}', line: 'Sealed · scratch to open', onTap: onOpen),
      if (d.scratchedToday && d.coupons.isEmpty && d.sealed.isEmpty)
        R27FoilCard(tint: const Color(0xFF8A8F9C), tag: 'Tomorrow', word: 'NEXT', line: 'Your next free card comes tomorrow', onTap: onOpen),
    ];

class R27Stub extends StatelessWidget {
  const R27Stub(this.c, {super.key, required this.onTap});
  final R27Coupon c;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: NPress(
          onTap: onTap,
          label: c.label.isEmpty ? '${c.pct}% off' : c.label,
          child: ClipPath(
            clipper: const R27Ticket(stubAt: .36),
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                flex: 36,
                child: ColoredBox(
                    color: R27Tone.isLight(context) ? r27Gold : r27Coal,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 8, 14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: R27Word('${c.pct}%', color: R27Tone.isLight(context) ? r27PaperInk : r27Gold, shadow: !R27Tone.isLight(context))),
                        const SizedBox(height: 6),
                        const R27TagLabel('Off'),
                      ]),
                    )),
              ),
              SizedBox(width: 0, child: OverflowBox(maxWidth: 10, child: CustomPaint(size: const Size(10, double.infinity), painter: const R27Perf(Color(0x66FFFFFF))))),
              Expanded(
                flex: 64,
                child: ColoredBox(
                    color: r27Paper,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(c.label.isEmpty ? '${c.pct}% off' : c.label, style: nSub.copyWith(color: r27PaperInk, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('On ${c.scope} · cap ₹${_n(c.capInr)}', style: nSub.copyWith(color: const Color(0xC7000000))),
                        if (c.expiresAt > 0) Text('Until ${_shortDate(c.expiresAt)}', style: nSub.copyWith(color: const Color(0xC7000000))),
                      ]),
                    )),
              ),
            ]),
          ),
        ),
      );
}

class R27FoilCard extends StatelessWidget {
  const R27FoilCard({super.key, required this.tint, required this.tag, required this.word, required this.line, required this.onTap});
  final Color tint;
  final String tag, word, line;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: NPress(
          onTap: onTap,
          label: '$tag $word',
          child: R27Tone.isLight(context) ? _light() : R27Anim(
            period: const Duration(seconds: 4),
            builder: (_, t) => CustomPaint(
              painter: R27Foil(t, tint),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: LayoutBuilder(builder: (_, box) {
                  final info = [
                    R27TagLabel(tag, color: Color.lerp(tint, Colors.white, .25)!),
                    const SizedBox(height: 6),
                    Text(line, style: dSub.copyWith(color: Colors.white)),
                  ];
                  if (box.maxWidth < 220) {
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: R27Word(word, color: Colors.white, align: Alignment.centerLeft)),
                      const SizedBox(height: 6),
                      ...info,
                    ]);
                  }
                  return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(flex: 5, child: R27Word(word, color: Colors.white, align: Alignment.centerLeft)),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 6,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: info),
                    ),
                  ]);
                }),
              ),
            ),
          ),
        ),
      );
}

extension on R27FoilCard {
  Widget _light() => Container(
        decoration: BoxDecoration(
          color: r27LCard,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: tint, width: 6)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: LayoutBuilder(builder: (_, box) {
          final info = [
            R27TagLabel(tag, color: Color.lerp(tint, Colors.white, .25)!),
            const SizedBox(height: 6),
            Text(line, style: dSub.copyWith(color: r27LSub)),
          ];
          final w = R27Word(word, color: r27LInk, shadow: false, align: Alignment.centerLeft);
          if (box.maxWidth < 220) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: w), const SizedBox(height: 6), ...info]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(flex: 5, child: w),
            const SizedBox(width: 14),
            Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: info)),
          ]);
        }),
      );
}
