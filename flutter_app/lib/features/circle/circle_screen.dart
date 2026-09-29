import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/nwsb_sign_in_sheet.dart';
import '../../screens/subscription.dart';
import '../../widgets/banner_mix.dart';
import '../../widgets/brand_top_banner.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/flip_portrait.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../earn/earn_topic_page.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';
import '../../admin/template/editable.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _welcome();
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _welcome() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14121A),
        title: const EditableLabel('circle_screen.CircleScreen',
          'Welcome to NowssB Earn',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Become a Partner in our journey and make this journey your Earn.\n\n'
          'Commission is a percent of NowssB’s net after the store fee, never the sticker price. '
          'Master Agent stops at 30%. A direct recruit pays you 5% of their commission, and only while both paid plans are active. '
          'There is no third level. An invite by itself pays nothing. Payouts wait for review before money moves.',
          style: TextStyle(color: Color(0xCCFFFFFF), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const EditableLabel('circle_screen.CircleScreen', 'Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'NowssB Earn',
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          final signedIn = NwsbFirebase.ready && w.uid != null;
          final units = w.unitsSold > 0 ? w.unitsSold : w.paidReferrals;
          final next = units >= 1000
              ? 1000
              : units >= 500
                  ? 1000
                  : units >= 300
                      ? 500
                      : units >= 100
                          ? 300
                          : 100;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              BrandTopBanner(
                bare: true,
                title: 'NowssB Earn',
                mark: NwsbMarks.piggy,
                art: 'assets/banners/earn/bag-blonde.jpg',
                artAlignment: const Alignment(0.12, -0.02),
                onTap: _welcome,
              ),
              const SizedBox(height: 12),
              const _EarnCardRail(),
              const SizedBox(height: 14),
              GlassWrap(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 86,
                          height: 108,
                          child: ColoredBox(
                            color: const Color(0xFFE6B325),
                            child: EditableImage.asset(
                              SplitPromoArts.egyptianLotus,
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              slot: 'circle_screen.CircleScreen',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EditableLabel('circle_screen.CircleScreen',
                              'Earning status',
                              style: TextStyle(color: NwsbColors.gold, fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              signedIn ? w.circleTier : 'Not signed in',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              signedIn ? '$units units · ${w.code.isEmpty ? 'code pending' : w.code}' : 'Sign in to see your tier, units, and code.',
                              style: const TextStyle(color: NwsbColors.mist, fontSize: 12, height: 1.3),
                            ),
                            if (signedIn) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  minHeight: 4,
                                  value: (units / next).clamp(0, 1).toDouble(),
                                  color: NwsbColors.gold,
                                  backgroundColor: const Color(0x22FFFFFF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('$units / $next to the next tier', style: const TextStyle(color: NwsbColors.mist, fontSize: 11)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ColoredSplitPromoBanner(
                margin: EdgeInsets.zero,
                spec: SplitPromoSpec(
                  title: 'NowssB Earn\nPartner',
                  cta: 'Welcome',
                  leftColor: const Color(0xFF3D2914),
                  rightColor: const Color(0xFFE6B325),
                  art: SplitPromoArts.egyptianGold,
                  onTap: _welcome,
                ),
              ),
              const SizedBox(height: 14),
              GlassWrap(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EditableLabel('circle_screen.CircleScreen', 'AGENT LADDER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      for (final step in const [
                        ('Starter Agent', '0–99 units · 10% of net'),
                        ('Rising Agent', '100 units · 15% of net'),
                        ('Pro Agent', '300 units · 20% of net'),
                        ('Elite Agent', '500 units · 25% of net'),
                        ('Master Agent', '1000 units · 30% of net'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              NwsbIcon(
                                NwsbMarks.verified,
                                size: 18,
                                color: signedIn && w.circleTier == step.$1 ? NwsbColors.goldLight : NwsbColors.mist,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${step.$1} · ${step.$2}',
                                  style: TextStyle(
                                    color: signedIn && w.circleTier == step.$1 ? Colors.white : NwsbColors.mist,
                                    fontWeight: signedIn && w.circleTier == step.$1 ? FontWeight.w700 : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (!signedIn)
                GoldButton(
                  label: 'Sign in to see your code',
                  onTap: () => NwsbSignInPage.open(context),
                )
              else if (!w.subscribed) ...[
                const EconomyNote('Your code stays paused until a paid plan is active. The count you already have is kept.'),
                const SizedBox(height: 8),
                GoldButton(
                  label: 'See plans',
                  filled: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()),
                  ),
                ),
              ] else ...[
                Text(w.code.isEmpty ? '—' : w.code, style: const TextStyle(fontSize: 32, color: NwsbColors.goldLight, fontWeight: FontWeight.w700, letterSpacing: 2)),
                Text('${w.circleTier} · $units units through your code', style: const TextStyle(color: NwsbColors.mist)),
                const SizedBox(height: 8),
                GoldButton(
                  label: 'Copy code',
                  filled: false,
                  onTap: w.code.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: w.code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: EditableLabel('circle_screen.CircleScreen', 'Code copied.')));
                          }
                        },
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Enter a referral code', hintStyle: TextStyle(color: NwsbColors.mist)),
              ),
              const SizedBox(height: 8),
              GoldButton(
                label: w.referredBy.isEmpty ? 'Apply code' : 'Code already applied',
                onTap: signedIn && w.referredBy.isEmpty
                    ? () => runPrivate(context, () => EconomyApi.call('applyReferralCode', {'code': _code.text.trim()}))
                    : signedIn
                        ? null
                        : () => NwsbSignInPage.open(context),
              ),
              const SizedBox(height: 18),
              const BannerMix(seed: 3),
              const SizedBox(height: 18),
              const EditableLabel('circle_screen.CircleScreen', 'YOUR LEGS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
              const SizedBox(height: 8),
              const EconomyNote(
                'You see yourself and the agents you recruited. Tap would open only that recruit’s own view, still capped at one level under them. A third level is never shown and never paid.',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x29FFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(signedIn ? 'You · ${w.circleTier}' : 'You', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      signedIn && units > 0
                          ? '$units units on your code. Direct recruits appear under you once they sell.'
                          : 'No legs yet. Share your agent code. This stays empty until someone you recruited makes a sale.',
                      style: const TextStyle(color: NwsbColors.mist, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const EditableLabel('circle_screen.CircleScreen', 'LEDGER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
              const SizedBox(height: 8),
              if (!NwsbFirebase.ready || w.uid == null)
                const EconomyNote('Sign in to see referral payments.')
              else
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('referralLedger')
                      .where('referrerUid', isEqualTo: w.uid)
                      .limit(20)
                      .snapshots(),
                  builder: (context, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return const EconomyNote('No referral payments yet.');
                    return Column(
                      children: [
                        for (final doc in docs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${doc.data()['kind'] == 'gift' ? 'Gift purchase · ' : ''}L${doc.data()['level']} · ${doc.data()['status']} · ${FxBook.instance.formatCents((doc.data()['commissionAmount'] as num?)?.toInt() ?? 0)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 18),
              const EditableLabel('circle_screen.CircleScreen', 'AGENT TIERS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
              const SizedBox(height: 8),
              const _TierRail(),
            ],
          );
        },
      ),
    );
  }
}

class _RailCard {
  const _RailCard(this.label, this.image, this.tint, this.open);
  final String label;
  final String image;
  final Color tint;
  final void Function(BuildContext) open;
}

class _EarnCardRail extends StatefulWidget {
  const _EarnCardRail();

  @override
  State<_EarnCardRail> createState() => _EarnCardRailState();
}

class _EarnCardRailState extends State<_EarnCardRail> {
  static const _loop = 80;
  late final PageController _pages = PageController(
    viewportFraction: 0.52,
    initialPage: _cards.length * (_loop ~/ 2),
  );
  Timer? _timer;

  static const _cards = <_RailCard>[
    _RailCard('NowssB Gifts', 'assets/banners/earn/sit-dark.png', Color(0xFF6A1B4D), openGifts),
    _RailCard('NowssB Rewards', 'assets/banners/earn/yoga-light.png', Color(0xFF1E3A8A), openRewards),
    _RailCard('Your Earning', 'assets/banners/earn/man-light.png', Color(0xFF8A5A12), openEarnings),
    _RailCard('NowssB coins earned', 'assets/banners/earn/yoga-dark.png', Color(0xFF0F6E56), openCoins),
  ];

  @override
  void initState() {
    super.initState();
    if (const bool.fromEnvironment('FLUTTER_TEST')) return;
    _timer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (!mounted || !_pages.hasClients) return;
      final current = _pages.page?.round() ?? _cards.length * (_loop ~/ 2);
      _pages.animateToPage(current + 1, duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: SizedBox(
        height: 172,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _plainPhoto(
              width: 108,
              height: 172,
              image: 'assets/banners/earn/hands-raise.png',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 118,
                child: PageView.builder(
                  controller: _pages,
                  padEnds: false,
                  itemCount: _cards.length * _loop,
                  itemBuilder: (_, i) {
                    final card = _cards[i % _cards.length];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _photoCard(
                        width: double.infinity,
                        height: 118,
                        label: card.label,
                        image: card.image,
                        tint: card.tint,
                        onTap: () => card.open(context),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _plainPhoto({
    required double width,
    required double height,
    required String image,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: width,
        height: height,
        child: EditableImage.asset(
          image,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.05),
          slot: 'circle_screen.EarnCardRail',
        ),
      ),
    );
  }

  Widget _photoCard({
    required double width,
    required double height,
    required String label,
    required String image,
    required Color tint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              EditableImage.asset(
                image,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.1),
                color: tint.withValues(alpha: 0.42),
                colorBlendMode: BlendMode.srcATop,
                slot: 'circle_screen.EarnCardRail',
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      tint.withValues(alpha: 0.05),
                      tint.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: EditableLabel('circle_screen.EarnCardRail',
                    label,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, height: 1.12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierRail extends StatefulWidget {
  const _TierRail();

  @override
  State<_TierRail> createState() => _TierRailState();
}

class _TierFace {
  const _TierFace({
    required this.name,
    required this.rate,
    required this.detail,
    required this.note,
    required this.front,
    required this.back,
    required this.accent,
    required this.wash,
    this.mark,
  });

  final String name;
  final String rate;
  final String detail;
  final String note;
  final String front;
  final String back;
  final Color accent;
  final Color wash;
  final String? mark;
}

class _TierRailState extends State<_TierRail> {
  static const _tiers = <_TierFace>[
    _TierFace(
      name: 'Starter Agent',
      rate: '10%',
      detail: '0–99 units · 10% of net',
      note: 'Your code works on any purchase. Commission is 10% of net after the store fee.',
      front: 'assets/banners/earn/hands-light.png',
      back: 'assets/banners/earn/hands-dark.png',
      accent: Color(0xFFE8D5A3),
      wash: Color(0xFF1A1024),
      mark: NwsbMarks.piggy,
    ),
    _TierFace(
      name: 'Rising Agent',
      rate: '15%',
      detail: '100 units · 15% of net',
      note: 'At 100 units the rate rises to 15% of net. The units you already have stay.',
      front: 'assets/banners/earn/sit-light.png',
      back: 'assets/banners/earn/sit-dark.png',
      accent: Color(0xFFE6B325),
      wash: Color(0xFF24180C),
    ),
    _TierFace(
      name: 'Pro Agent',
      rate: '20%',
      detail: '300 units · 20% of net',
      note: 'A direct recruit pays you 5% of their commission, only while both plans are active.',
      front: 'assets/banners/earn/yoga-light.png',
      back: 'assets/banners/earn/yoga-dark.png',
      accent: Color(0xFF7DDE92),
      wash: Color(0xFF0C1C20),
    ),
    _TierFace(
      name: 'Elite Agent',
      rate: '25%',
      detail: '500 units · 25% of net',
      note: 'Two levels only. There is no third. An invite by itself pays nothing.',
      front: 'assets/banners/earn/man-light.png',
      back: 'assets/banners/earn/man-dark.png',
      accent: Color(0xFF8EB4FF),
      wash: Color(0xFF12182A),
    ),
    _TierFace(
      name: 'Master Agent',
      rate: '30%',
      detail: '1000 units · 30% of net',
      note: 'Master is the cap: 30% of net. Payouts wait for review before money moves.',
      front: 'assets/banners/earn/sit-dark.png',
      back: 'assets/banners/earn/sit-light.png',
      accent: Color(0xFFFFD36A),
      wash: Color(0xFF1A1408),
    ),
  ];

  late final PageController _pages = PageController(viewportFraction: 0.88);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: PageView.builder(
        controller: _pages,
        itemCount: _tiers.length,
        itemBuilder: (_, i) {
          final tier = _tiers[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AgentTierPage(name: tier.name, detail: tier.detail, note: tier.note),
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tier.wash,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tier.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                          Text(tier.rate, style: TextStyle(color: tier.accent, fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 10,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FlipPortrait(
                                  front: tier.front,
                                  back: tier.back,
                                  mark: tier.mark,
                                  fit: BoxFit.cover,
                                  alignment: const Alignment(0, -0.15),
                                  markAt: const Alignment(0, -0.5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tier.detail,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11, height: 1.25, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    tier.note,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.25),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: tier.accent, borderRadius: BorderRadius.circular(99)),
                                    child: const Text(
                                      'Open this tier',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w800, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

