/// R27 — stand-alone black pages for Rewards, Gifts, NowssB Earn, Coupons.
/// Shape: Hero poster with a giant Anton word breaking its bottom edge →
/// greeting head → the section's auto row (large) → real-data detail.
library;

import 'package:flutter/material.dart';

import '../../../features/economy/reward_fx.dart' show rarityColor, rarityTitle;
import '../normal/surface.dart';
import 'data.dart';
import 'kit.dart';
import 'sections.dart';
import 'anims.dart';

class R27PageShell extends StatelessWidget {
  const R27PageShell({super.key, required this.hour, required this.word, required this.head, required this.children, required this.onBack, this.wordColor = Colors.white, this.badge});
  final String hour, word;
  final Widget head;
  final List<Widget> children;
  final VoidCallback onBack;
  final Color wordColor;
  final Widget? badge;
  @override
  Widget build(BuildContext context) => ColoredBox(
        color: r27Black,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: .95,
            child: Stack(fit: StackFit.expand, clipBehavior: Clip.none, children: [
              R27Img(hour, sat: .6),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0x00000000), Color(0xFF000000)], stops: [0, .35, 1]))),
              Positioned(left: 8, top: 8, child: NPress(onTap: onBack, label: 'Back',
                  child: const SizedBox.square(dimension: 48, child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24)))),
              if (badge != null) Positioned(right: 18, top: 14, child: badge!),
              Positioned(left: 14, right: 14, bottom: -18, height: 150, child: R27Word(word, color: wordColor, align: Alignment.bottomLeft)),
            ]),
          ),
          const SizedBox(height: 34),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: head),
          const SizedBox(height: 18),
          ...children,
          const SizedBox(height: 28),
        ]),
      );
}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: w);
Widget _label(String s) => _pad(Padding(padding: const EdgeInsets.only(top: 26, bottom: 12), child: Text(s, style: dHello)));

// ── Rewards page ──────────────────────────────────────────────────────────
class R27RewardsPage extends StatelessWidget {
  const R27RewardsPage({super.key, required this.data, required this.onBack, required this.onClaim, required this.onVault, required this.onSignIn, required this.onHowItWorks});
  final R27Rewards data;
  final VoidCallback onBack, onClaim, onVault, onSignIn, onHowItWorks;
  @override
  Widget build(BuildContext context) {
    final t = r27RewardTiles(data, onOpen: onVault, onClaim: onClaim, onSignIn: onSignIn);
    final lit = data.streak <= 0 ? 0 : ((data.streak - 1) % 7) + 1;
    final inChest = data.coins % data.chestEvery;
    return R27PageShell(
      hour: 'surya', word: '${data.coins}', wordColor: r27Gold, onBack: onBack,
      head: R27Head(dark: true, hello: 'NowssB Rewards', title: '${data.coins} coins', sub: 'Day ${data.streak} streak · next chest in ${data.toChest} coins'),
      children: [
        R27AutoRow(count: t.length, height: r27H(context, 270, 40), fraction: .64, builder: (c, i, off) => R27TornTile(t[i], offset: off)),
        _label('This week'),
        _pad(Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ClipPath(
                clipper: R27Torn(seed: 30 + i, depth: 4),
                child: Container(height: 64, color: i < lit ? r27Gold : r27Coal,
                    alignment: Alignment.center,
                    child: Padding(padding: const EdgeInsets.all(12), child: R27Word('${i + 1}', color: i < lit ? r27PaperInk : const Color(0x99FFFFFF), shadow: false, align: Alignment.center))),
              ),
            )),
        ])),
        const SizedBox(height: 8),
        _pad(Text('$lit of 7 lit this week', style: dSub)),
        _label('Next chest'),
        _pad(ClipPath(
          clipper: const R27Torn(seed: 44, depth: 6),
          child: Container(
            color: r27Coal,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(height: 64, child: R27Word('$inChest / ${data.chestEvery}', color: Colors.white)),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                  value: inChest / data.chestEvery, minHeight: 8, color: r27Gold, backgroundColor: const Color(0x33FFFFFF))),
              const SizedBox(height: 10),
              Text('${data.toChest} more coins open the chest', style: dSub),
            ]),
          ),
        )),
        const SizedBox(height: 22),
        _pad(Wrap(spacing: 10, runSpacing: 10, children: [
          if (!data.signedIn) R27Pill('Sign in', onTap: onSignIn)
          else if (!data.loginToday) R27Pill("Claim today's coin", onTap: onClaim),
          R27Pill('Open the vault', filled: data.signedIn && data.loginToday, onTap: onVault),
        ])),
        _pad(R27Link('How rewards work', dark: true, onTap: onHowItWorks)),
      ],
    );
  }
}

// ── Gifts page ────────────────────────────────────────────────────────────
class R27GiftsPage extends StatelessWidget {
  const R27GiftsPage({super.key, required this.data, required this.onBack, required this.onGift, required this.onRedeem, required this.onHistory});
  final R27Gifts data;
  final VoidCallback onBack, onRedeem, onHistory;
  final void Function(String id) onGift;
  @override
  Widget build(BuildContext context) {
    final cards = data.cards;
    return R27PageShell(
      hour: 'ananda', word: 'GIVE', onBack: onBack,
      head: R27Head(dark: true, hello: 'NowssB Gifts', title: 'Give a word', sub: '${cards.length} gift cards · paid in your own currency at checkout'),
      children: [
        R27AutoRow(count: cards.length, height: r27H(context, 340, 34), fraction: .7, every: const Duration(milliseconds: 3200),
            builder: (c, i, off) => R27GiftPoster(cards[i], hour: r27Hours[(i + 4) % r27Hours.length], offset: off, onGift: () => onGift(cards[i].id))),
        _label('Have a code?'),
        _pad(NPress(
          onTap: onRedeem,
          label: 'Redeem a gift code',
          child: ClipPath(
            clipper: const R27Ticket(stubAt: .3),
            child: Container(
              color: r27Paper,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Row(children: [
                const Expanded(flex: 3, child: SizedBox(height: 54, child: R27Word('CODE', color: r27PaperInk, shadow: false))),
                const SizedBox(width: 26),
                Expanded(flex: 7, child: Text('Redeem a gift code someone sent you', style: nSub.copyWith(color: r27PaperInk, fontWeight: FontWeight.w800))),
              ]),
            ),
          ),
        )),
        _label('Your gifts'),
        _pad(Row(children: [
          Expanded(child: _count('${data.sent}', 'Sent', 'kapha', onHistory)),
          const SizedBox(width: 12),
          Expanded(child: _count('${data.received}', 'Received', 'chandra', onHistory)),
        ])),
        _pad(R27Link('Gift history', dark: true, onTap: onHistory)),
      ],
    );
  }

  Widget _count(String n, String tag, String hour, VoidCallback onTap) => NPress(
        onTap: onTap,
        label: '$tag $n',
        child: ClipPath(
          clipper: R27Torn(seed: tag.length * 7),
          child: SizedBox(height: 150, child: Stack(fit: StackFit.expand, children: [
            R27Img(hour),
            const DecoratedBox(decoration: r27Scrim),
            Padding(padding: const EdgeInsets.fromLTRB(14, 18, 14, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              R27TagLabel(tag),
              const SizedBox(height: 8),
              Expanded(child: R27Word(n, align: Alignment.bottomLeft)),
            ])),
          ])),
        ),
      );
}

// ── Earn page ─────────────────────────────────────────────────────────────
class R27EarnPage extends StatelessWidget {
  const R27EarnPage({super.key, required this.data, required this.onBack, required this.onHub, required this.onInvite, required this.onRank});
  final R27Earn data;
  final VoidCallback onBack, onHub, onInvite;
  final void Function(int) onRank;
  @override
  Widget build(BuildContext context) {
    final cur = data.current;
    final next = cur + 1 < data.ranks.length ? data.ranks[cur + 1] : null;
    final from = data.ranks.isEmpty ? 0 : data.ranks[cur].minWords;
    final prog = next == null ? 1.0 : ((data.wordsSold - from) / (next.minWords - from)).clamp(0.0, 1.0);
    final rate = data.shownRate;
    return R27PageShell(
      hour: 'tejas', word: 'EARN', onBack: onBack,
      badge: const R27Coin(size: 72),
      head: R27Head(dark: true, hello: 'NowssB Earn', title: '${rate == rate.roundToDouble() ? rate.round() : rate}% on net',
          sub: 'Commission on net. Two levels. Paid from net after tax and the Play fee.'),
      children: [
        R27AutoRow(count: data.ranks.length, height: r27H(context, 280, 56), fraction: .52, initial: cur, every: const Duration(milliseconds: 2800),
            builder: (c, i, off) => R27RankStep(data.ranks[i], index: i, top: data.topRate, current: i == cur, offset: off, onTap: () => onRank(i))),
        _label('Your climb'),
        _pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 64, child: R27Word('${data.wordsSold}', color: r27Gold)),
          const SizedBox(height: 4),
          Text(next == null ? 'Words sold · you are at the top rank' : 'Words sold · ${next.title} at ${next.minWords}', style: dSub),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
              value: prog, minHeight: 8, color: r27Gold, backgroundColor: const Color(0x33FFFFFF))),
        ])),
        const SizedBox(height: 22),
        _pad(Wrap(spacing: 10, runSpacing: 10, children: [
          R27Pill('Open NowssB Earn', onTap: onHub),
          R27Pill(data.code.isEmpty ? 'Invite a friend' : 'Invite with ${data.code}', filled: false, onTap: onInvite),
        ])),
      ],
    );
  }
}

// ── Coupons page ──────────────────────────────────────────────────────────
class R27CouponsPage extends StatelessWidget {
  const R27CouponsPage({super.key, required this.data, required this.onBack, required this.onScratch, required this.onCoupon, required this.onSealed, required this.onRules});
  final R27Coupons data;
  final VoidCallback onBack, onScratch, onRules;
  final void Function(int) onCoupon;
  final void Function(String rarity) onSealed;
  @override
  Widget build(BuildContext context) {
    final items = r27CouponCards(data, onScratch: onScratch, onOpen: onScratch, onCoupon: onCoupon);
    return R27PageShell(
      hour: 'soma', word: 'SAVE', wordColor: r27Gold, onBack: onBack,
      head: R27Head(dark: true, hello: 'NowssB Coupons',
          title: data.scratchedToday ? 'Cards and discounts' : "Today's card is ready",
          sub: '${data.sealedTotal} sealed · ${data.coupons.length} ${data.coupons.length == 1 ? 'discount' : 'discounts'} · use them at checkout'),
      children: [
        R27AutoRow(count: items.length, height: r27H(context, 180, 52), fraction: .86, every: const Duration(milliseconds: 4000),
            builder: (c, i, off) => Transform.scale(scale: 1 - .08 * off.abs().clamp(0.0, 1.0), child: items[i])),
        if (data.sealed.isNotEmpty) ...[
          _label('Sealed cards'),
          _pad(Wrap(spacing: 0, runSpacing: 0, children: [
            for (final e in data.sealed.entries)
              FractionallySizedBox(widthFactor: .5, child: SizedBox(height: r27H(context, 118, 52),
                  child: R27FoilCard(tint: rarityColor(e.key), tag: rarityTitle(e.key), word: '×${e.value}', line: 'Tap to scratch', onTap: () => onSealed(e.key)))),
          ])),
        ],
        if (data.coupons.isNotEmpty) ...[
          _label('Discounts'),
          for (var i = 0; i < data.coupons.length; i++)
            _pad(SizedBox(height: r27H(context, 120, 52), child: R27Stub(data.coupons[i], onTap: () => onCoupon(i)))),
        ],
        const SizedBox(height: 14),
        _pad(Wrap(spacing: 10, runSpacing: 10, children: [
          if (!data.scratchedToday) R27Pill("Scratch today's card", onTap: onScratch),
        ])),
        _pad(R27Link('Rules and odds', dark: true, onTap: onRules)),
      ],
    );
  }
}
