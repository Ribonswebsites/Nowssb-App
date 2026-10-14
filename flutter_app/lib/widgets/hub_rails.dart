/// Three horizontal card rails.
///
/// Feature, list and challenge cards follow the glass references:
/// avatar pile, Active pill, clock / star / bookmark, Continue,
/// and the circular Skip / Next card. No fake status bar.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../features/programs/program_router.dart';

const kRailArt = <String>[
  'assets/rails/01.png',
  'assets/rails/02.png',
  'assets/rails/03.png',
  'assets/rails/04.png',
  'assets/rails/05.png',
  'assets/rails/06.png',
  'assets/rails/07.png',
  'assets/rails/08.png',
  'assets/rails/09.png',
  'assets/rails/10.png',
  'assets/rails/11.png',
];

const kProfileArt = <String>[
  'assets/profile/rails/01.jpg',
  'assets/profile/rails/02.jpg',
  'assets/profile/rails/03.jpg',
  'assets/profile/rails/04.jpg',
  'assets/profile/rails/05.jpg',
  'assets/profile/rails/06.jpg',
  'assets/profile/rails/07.jpg',
  'assets/profile/rails/08.jpg',
  'assets/profile/rails/09.jpg',
  'assets/profile/rails/10.jpg',
  'assets/profile/rails/11.jpg',
  'assets/profile/rails/12.jpg',
  'assets/profile/rails/13.jpg',
  'assets/profile/rails/14.jpg',
  'assets/profile/rails/15.jpg',
];

const kEarnArt = <String>[
  'assets/rails/earn-01.jpg',
  'assets/rails/earn-02.jpg',
  'assets/rails/earn-03.jpg',
  'assets/rails/earn-04.jpg',
  'assets/rails/earn-05.jpg',
  'assets/rails/earn-06.jpg',
  'assets/rails/earn-07.jpg',
];

const kRewardsArt = <String>[
  'assets/rails/rewards-01.jpg',
  'assets/rails/rewards-02.jpg',
  'assets/rails/rewards-03.jpg',
  'assets/rails/rewards-04.jpg',
  'assets/rails/rewards-05.jpg',
  'assets/rails/rewards-06.jpg',
  'assets/rails/rewards-07.jpg',
];

const kCouponArt = <String>[
  'assets/rails/coupons-01.jpg',
  'assets/rails/coupons-02.jpg',
  'assets/rails/coupons-03.jpg',
  'assets/rails/coupons-04.jpg',
  'assets/rails/coupons-05.jpg',
  'assets/rails/coupons-06.jpg',
  'assets/rails/coupons-07.jpg',
];

const kGiftArt = <String>[
  'assets/rails/gifts-01.jpg',
  'assets/rails/gifts-02.jpg',
  'assets/rails/gifts-03.jpg',
  'assets/rails/gifts-04.jpg',
  'assets/rails/gifts-05.jpg',
  'assets/rails/gifts-06.jpg',
  'assets/rails/gifts-07.jpg',
];

const kEarningsArt = <String>[
  'assets/rails/earnings-01.jpg',
  'assets/rails/earnings-02.jpg',
  'assets/rails/earnings-03.jpg',
  'assets/rails/earnings-04.jpg',
  'assets/rails/earnings-05.jpg',
  'assets/rails/earnings-06.jpg',
];

const kGlassArt = <String>[
  'assets/rails/glass-01.jpg',
  'assets/rails/glass-02.jpg',
  'assets/rails/glass-03.jpg',
  'assets/rails/glass-04.jpg',
];

const kClearArt = <String>[
  'assets/rails/clear-01.jpg',
  'assets/rails/clear-02.jpg',
  'assets/rails/clear-03.jpg',
  'assets/rails/clear-04.jpg',
];
const _dur = ['18h 9m', '12h 24m', '4 min', '8 min', '21 min'];
const _rate = ['4.7', '4.8', '4.9', '4.6', '5.0'];
const _saves = ['16', '12', '8', '24', '31'];
const _people = ['+12', '+8', '+2k', '+6', '+19'];

ImageProvider<Object> railImage(String art) => art.startsWith('http') ? NetworkImage(art) : AssetImage(art);

Widget railPicture(String art, {double? width, double? height, Alignment alignment = Alignment.center, BoxFit fit = BoxFit.cover}) {
  final broken = ColoredBox(color: const Color(0xFF2A1038), child: SizedBox(width: width, height: height));
  if (art.startsWith('http')) {
    return Image.network(art, width: width, height: height, fit: fit, alignment: alignment, errorBuilder: (_, __, ___) => broken);
  }
  return Image.asset(art, width: width, height: height, fit: fit, alignment: alignment, errorBuilder: (_, __, ___) => broken);
}

class RailCard {
  const RailCard(this.title, this.line, this.meta, {this.art = ''});
  final String title;
  final String line;
  final String meta;
  final String art;
}

List<RailCard> railSet(List<String> titles, String meta) => [
      for (var i = 0; i < titles.length; i++) RailCard(titles[i], '${i + 1} of ${titles.length}', meta),
    ];

List<RailCard> _pack(List<String> titles, List<String> about) => [
      for (var i = 0; i < titles.length; i++) RailCard(titles[i], '${i + 1} of ${titles.length}', about[i]),
    ];

enum RailKind { profile, settings, menu, earn, rewards, coupons, gifts, earnings }

/// One page's three rails, with that page's own pictures and titles.
class IdentityRails extends StatelessWidget {
  const IdentityRails(this.kind, {super.key});
  final RailKind kind;

  @override
  Widget build(BuildContext context) {
    final spec = switch (kind) {
      RailKind.profile => (
          labels: const ['Your practice', 'Saved seats', 'Challenges'],
          arts: kProfileArt,
          a: _pack(const ['Trusting the Breath', 'Quiet Inhale', 'Lotus at Dusk', 'Sheer Stillness', 'The First Breath'], const ['A short sit', 'Soft start', 'Evening', 'Still', 'Begin']),
          b: _pack(const ['Listening Room', 'Heart of Sound', 'Still Water', 'Violet Silk', 'Morning Seat'], const ['Saved', 'Sound', 'Lake', 'Cloth', 'Dawn']),
          c: _pack(const ['Seven Days of Breath', 'The Quiet Path', 'Rings of Sound', 'Night Shore', 'Shabdapathy'], const ['A week of sitting', 'Walk it slowly', 'Sound in circles', 'Night practice', 'The root of a word']),
        ),
      RailKind.settings => (
          labels: const ['Sound & play', 'Your account', 'Quick steps'],
          arts: kRailArt,
          a: _pack(const ['Sound', 'Player', 'Routine', 'Theme', 'Alerts'], const ['Keep', 'Keep', 'Keep', 'Look', 'Alerts']),
          b: _pack(const ['Account', 'Privacy', 'Downloads', 'Language', 'Help'], const ['You', 'You', 'On this phone', 'Words', 'Help']),
          c: _pack(const ['Reduce effects', 'Notifications', 'Backup', 'Sign out', 'About'], const ['Calm the motion', 'What can ping you', 'Keep a copy', 'Leave this phone', 'The build']),
        ),
      RailKind.menu => (
          labels: const ['Open', 'Go', 'Today'],
          arts: const [
            'assets/rails/06.png',
            'assets/rails/07.png',
            'assets/rails/08.png',
            'assets/rails/09.png',
            'assets/rails/10.png',
            'assets/rails/11.png',
            'assets/rails/01.png',
            'assets/rails/02.png',
            'assets/rails/03.png',
            'assets/rails/04.png',
            'assets/rails/05.png',
          ],
          a: _pack(const ['Earn', 'Rewards', 'Gifts', 'Coupons', 'Profile'], const ['Open', 'Open', 'Open', 'Open', 'You']),
          b: _pack(const ['Library', 'Store', 'Practice', 'Settings', 'Words'], const ['Sounds', 'Shop', 'Sit', 'Gear', 'Roots']),
          c: _pack(const ['Streak', 'Today', 'Saved', 'Invite', 'Rank'], const ['Come back tomorrow', 'What is open now', 'Hearted words', 'One person', 'Where you stand']),
        ),
      RailKind.earn => (
          labels: const ['Ranks', 'Your team', 'Challenges'],
          arts: kEarnArt,
          a: _pack(const ['Your rank', 'Team today', 'Fast start', 'Payout ready', 'Academy'], const ['Standing', 'People', 'Bonus', 'Money', 'Learn']),
          b: _pack(const ['Bronze', 'Silver', 'Gold', 'Diamond', 'Master'], const ['First metal', 'Next', 'Rate', 'Top', 'Hold']),
          c: _pack(const ['7 day push', 'First sale', 'Invite one', 'Hold rank', 'Request payout'], const ['Seven days of sales', 'One cleared purchase', 'A direct recruit', 'Keep the words', 'After the hold']),
        ),
      RailKind.rewards => (
          labels: const ['Active', 'Wallet', 'Streaks'],
          arts: kRewardsArt,
          a: _pack(const ['Daily login', 'Quest board', 'Streak flame', 'Season', 'Badges'], const ['Today', 'Quests', 'Fire', 'Season', 'Marks']),
          b: _pack(const ['Wallet', 'Spend', 'Freezes', 'League', 'Mastery'], const ['Coins', 'Shop', 'Saved days', 'Table', 'Skill']),
          c: _pack(const ['Day 7 streak', 'First quest', 'Come back', 'Claim box', 'Invite'], const ['A week of logins', 'One finished quest', 'Tomorrow’s coin', 'Open the box', 'One friend']),
        ),
      RailKind.coupons => (
          labels: const ['Scratch', 'My coupons', 'Shop'],
          arts: kCouponArt,
          a: _pack(const ['Scratch today', 'My coupons', 'Shop card', 'Expiring', 'Odds'], const ['Foil', 'Tickets', 'Buy', 'Soon', 'Rules']),
          b: _pack(const ['Common', 'Rare', 'Epic', 'Legendary', 'Mythic'], const ['Often', 'Less often', 'Thin', 'Rare', 'Rarest']),
          c: _pack(const ['First scratch', 'Daily card', 'Save one', 'Share odds', 'Set a limit'], const ['Uncover the first', 'One card a day', 'Keep it sealed', 'Read the odds', 'A monthly cap']),
        ),
      RailKind.gifts => (
          labels: const ['Send', 'Received', 'Redeem'],
          arts: kGiftArt,
          a: _pack(const ['Free box', 'Send a gift', 'Received', 'Redeem', 'Gift cards'], const ['Today', 'Give', 'Inbox', 'Code', 'Play']),
          b: _pack(const ['Stage', 'Word', 'Bundle', 'Opened', 'Waiting'], const ['Small', 'A word', 'Large', 'Done', 'Sealed']),
          c: _pack(const ['Today’s box', 'Send one', 'Redeem a code', 'History', 'Rules'], const ['Minutes open a better box', 'A real purchase', 'Paste the code', 'What you sent', 'What a gift is']),
        ),
      RailKind.earnings => (
          labels: const ['Sales', 'Pending', 'Payouts'],
          arts: kEarningsArt,
          a: _pack(const ['Lifetime', 'Available', 'Pending', 'This week', 'Paid out'], const ['All', 'Ready', 'Hold', 'Now', 'Sent']),
          b: _pack(const ['Sales', 'Referrals', 'UPI', 'Wise', 'PayPal'], const ['Ledger', 'People', 'India', 'Abroad', 'Abroad']),
          c: _pack(const ['First payout', 'Hold window', 'Add UPI', 'Invite sale', 'Review'], const ['When the minimum clears', 'Thirty days', 'India rail', 'A paid plan', 'A person checks it']),
        ),
    };
    return HubRails(
      a: spec.a,
      b: spec.b,
      c: spec.c,
      d: _pack(const ['Fog Practice', 'Lotus Hour', 'Sound Rings', 'Soft Cloth'], const ['A glass seat', 'Still water', 'In circles', 'Morning']),
      e: _pack(const ['30 days of breath', 'Forest pool', 'Night shore', 'The case'], const ['A month of sitting', 'One still hour', 'After dark', 'Keep it close']),
      arts: spec.arts,
      labels: [...spec.labels, 'Glass', 'Clear'],
    );
  }
}

class HubRails extends StatelessWidget {
  const HubRails({
    super.key,
    required this.a,
    required this.b,
    required this.c,
    this.d = const [],
    this.e = const [],
    this.arts = kRailArt,
    this.labels = const ['Continue', 'Your list', 'Challenges'],
    this.onOpen,
    this.openGuide = true,
  });

  final List<RailCard> a;
  final List<RailCard> b;
  final List<RailCard> c;
  final List<RailCard> d;
  final List<RailCard> e;
  final List<String> arts;
  final List<String> labels;
  final void Function(RailCard card)? onOpen;
  final bool openGuide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (a.isNotEmpty) ...[
          _label(labels[0]),
          _rail(context, 292, 332, a, 0),
        ],
        if (b.isNotEmpty) ...[
          _label(labels.length > 1 ? labels[1] : 'Your list'),
          _rail(context, 318, 168, b, 1),
        ],
        if (c.isNotEmpty) ...[
          _label(labels.length > 2 ? labels[2] : 'Challenges'),
          _rail(context, 214, 312, c, 2),
        ],
        if (d.isNotEmpty) ...[
          _label(labels.length > 3 ? labels[3] : 'Glass'),
          _rail(context, 300, 392, d, 3),
        ],
        if (e.isNotEmpty) ...[
          _label(labels.length > 4 ? labels[4] : 'Clear'),
          _rail(context, 250, 430, e, 4),
        ],
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      );

  Widget _rail(BuildContext context, double w, double h, List<RailCard> list, int rail) {
    return SizedBox(
      height: h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final card = list[i];
          final art = card.art.isNotEmpty ? card.art : _pick(rail, i);
          final child = switch (rail) {
            0 => _FeatureCard(card: card, art: art, index: i),
            1 => _RowCard(card: card, art: art, index: i),
            2 => _ChallengeCard(card: card, art: art, index: i),
            3 => _GlassCourseCard(card: card, art: art, index: i, total: list.length),
            _ => _ClearChallengeCard(card: card, art: art, index: i),
          };
          return SizedBox(
            width: w,
            child: GestureDetector(
              onTap: () {
                onOpen?.call(card);
                if (openGuide) openRailGuide(context, card, art);
              },
              child: child,
            ),
          );
        },
      ),
    );
  }

  String _pick(int rail, int i) {
    if (rail == 3) return kGlassArt[i % kGlassArt.length];
    if (rail == 4) return kClearArt[i % kClearArt.length];
    final n = arts.length;
    if (n == 0) return kRailArt[i % kRailArt.length];
    if (n >= 15) return arts[(rail * 5 + i) % n];
    if (rail == 0) return arts[i % n];
    if (rail == 1) return arts[(i + (n > 5 ? 5 : 2)) % n];
    return arts[(n - 1 - i) % n];
  }
}

class RailFaces extends StatelessWidget {
  const RailFaces({super.key, required this.count, this.size = 28});
  final String count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size;
    Widget face(String asset, double left) => Positioned(
          left: left,
          top: 0,
          child: Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
            ),
          ),
        );
    return SizedBox(
      width: s * 2.45,
      height: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          face('assets/profile/rails/avatar_a.jpg', 0),
          face('assets/profile/rails/avatar_b.jpg', s * 0.58),
          Positioned(
            left: s * 1.16,
            top: 0,
            child: Container(
              width: s,
              height: s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: const Color(0xFF161616),
                  fontWeight: FontWeight.w800,
                  fontSize: count.length > 2 ? s * 0.28 : s * 0.34,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.index, this.color = Colors.white});
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600);
    final dim = color.withValues(alpha: 0.92);
    return Row(
      children: [
        Icon(Icons.access_time, size: 14, color: dim),
        const SizedBox(width: 4),
        Text(_dur[index % _dur.length], style: style),
        const SizedBox(width: 8),
        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC857)),
        const SizedBox(width: 2),
        Text(_rate[index % _rate.length], style: style),
        const SizedBox(width: 8),
        Icon(Icons.bookmark_border_rounded, size: 14, color: dim),
        const SizedBox(width: 3),
        Text(_saves[index % _saves.length], style: style),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.card, required this.art, required this.index});
  final RailCard card;
  final String art;
  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            railPicture(art),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x33201030), Color(0xCC5A1878), Color(0xE0460F62)],
                  stops: [0.18, 0.48, 0.78, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RailFaces(count: _people[index % _people.length]),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Active', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, height: 1.05, letterSpacing: -0.4)),
                  const SizedBox(height: 8),
                  SizedBox(height: 18, width: double.infinity, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _MetaRow(index: index))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(card.line, style: const TextStyle(color: Color(0xC6FFFFFF), fontSize: 13)),
                      const Spacer(),
                      const Text('Continue  ›', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
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

class _RowCard extends StatelessWidget {
  const _RowCard({required this.card, required this.art, required this.index});
  final RailCard card;
  final String art;
  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF0121218),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: railPicture(art, width: 112, height: 148, alignment: const Alignment(0, -0.4)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(alignment: Alignment.centerRight, child: RailFaces(count: _people[(index + 2) % _people.length], size: 24)),
                  const SizedBox(height: 6),
                  Text(card.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.3)),
                  const Spacer(),
                  SizedBox(height: 16, width: double.infinity, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _MetaRow(index: index))),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Color(0xFF2A2A32), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.card, required this.art, required this.index});
  final RailCard card;
  final String art;
  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE01A102C),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x55FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        child: Column(
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x66FFFFFF), width: 2),
                image: DecorationImage(image: railImage(art), fit: BoxFit.cover, alignment: const Alignment(0, 0.35)),
              ),
            ),
            const SizedBox(height: 12),
            Text(card.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, height: 1.15)),
            const SizedBox(height: 6),
            Text(card.meta, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.25)),
            const Spacer(),
            Row(
              children: [
                const Text('Skip', style: TextStyle(color: Color(0xB3FFFFFF), fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: const Text('Next', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var dot = 0; dot < 3; dot++)
                  Container(
                    width: dot == index % 3 ? 7 : 5,
                    height: dot == index % 3 ? 7 : 5,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(color: dot == index % 3 ? Colors.white : const Color(0x55FFFFFF), shape: BoxShape.circle),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// The fourth and fifth rails. The first three card widgets are unchanged.
class _GlassCourseCard extends StatelessWidget {
  const _GlassCourseCard({required this.card, required this.art, required this.index, required this.total});
  final RailCard card;
  final String art;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x66FFFFFF)),
            color: const Color(0x1AFFFFFF),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              railPicture(art),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x33000000), Color(0xCC120818)],
                    stops: [0.35, 0.62, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RailFaces(count: _people[index % _people.length]),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Active', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, height: 1.05)),
                    const SizedBox(height: 8),
                    _MetaRow(index: index),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('${index + 1} of $total', style: const TextStyle(color: Color(0xC6FFFFFF), fontSize: 13)),
                        const Spacer(),
                        const Text('Continue  ›', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClearChallengeCard extends StatelessWidget {
  const _ClearChallengeCard({required this.card, required this.art, required this.index});
  final RailCard card;
  final String art;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x55FFFFFF)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x88FFFFFF), width: 2),
                    image: DecorationImage(image: railImage(art), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0x55FFFFFF)),
                          color: const Color(0x1AFFFFFF),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, height: 1.1)),
                              const SizedBox(height: 4),
                              Text(card.meta, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12, height: 1.25)),
                              const Spacer(),
                              Row(
                                children: [
                                  const Text('Skip', style: TextStyle(color: Color(0xE6FFFFFF), fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0x33FFFFFF),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0x88FFFFFF)),
                                    ),
                                    child: const Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var dot = 0; dot < 4; dot++)
                                    Container(
                                      width: dot == index % 4 ? 7 : 5,
                                      height: dot == index % 4 ? 7 : 5,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(color: dot == index % 4 ? Colors.white : const Color(0x66FFFFFF), shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

void openRailGuide(BuildContext context, RailCard card, String art) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Guide',
    barrierColor: const Color(0x99000000),
    pageBuilder: (ctx, _, __) => _RailGuide(card: card, art: art),
  );
}

class _RailGuide extends StatelessWidget {
  const _RailGuide({required this.card, required this.art});
  final RailCard card;
  final String art;

  Programme? _match() {
    final t = '${card.title} ${card.meta}'.toLowerCase();
    return Programmes.forPoster(card.title) ??
        (t.contains('earn') || t.contains('payout') || t.contains('rank') || t.contains('sale')
            ? Programme.earn
            : t.contains('reward') || t.contains('coin') || t.contains('streak') || t.contains('quest')
                ? Programme.rewards
                : t.contains('coupon') || t.contains('scratch')
                    ? Programme.coupons
                    : t.contains('gift')
                        ? Programme.gifts
                        : null);
  }

  @override
  Widget build(BuildContext context) {
    final next = _match();
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0x66FFFFFF)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x88FFFFFF), width: 2),
                        image: DecorationImage(image: railImage(art), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xF2FFFFFF), Color(0x99FFFFFF), Color(0x22FFFFFF)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(card.title, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(card.meta, style: const TextStyle(color: Color(0xFF333333), fontSize: 13, height: 1.35)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Skip', style: TextStyle(color: Color(0xFF333333)))),
                              const Spacer(),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  if (next != null) Programmes.open(context, next);
                                },
                                child: Text(next == null ? 'Close' : 'Next'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



