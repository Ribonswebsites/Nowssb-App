import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../../screens/nwsb_sign_in_sheet.dart';
import '../../screens/subscription.dart';
import '../../widgets/app_thinking_loader.dart';
import '../../widgets/flip_portrait.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/hub_rails.dart';
import '../../widgets/routine_deck.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import '../../data/firebase.dart';
import '../earn/earn_topic_page.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../../admin/template/editable.dart';
import '../programs/program_kit.dart';
import '../programs/earn_program.dart';
import '../programs/program_router.dart';
import '../../widgets/n_motion.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key, this.initialTab});

  /// Opens scrolled to one programme tab (e.g. 'payouts').
  final String? initialTab;

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  final _code = TextEditingController();
  // The welcome note shows once per app run, not on every visit.
  static bool _welcomed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      final id = widget.initialTab!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openTabs(id);
      });
    } else if (!_welcomed) {
      _welcomed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _welcome();
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _act(BuildContext context, RailCard card, bool signedIn, String code, String referredBy) {
    switch (card.title) {
      case 'Sign in':
        NwsbSignInPage.open(context);
      break;
      case 'Your rank':
      case 'See plans':
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()));
      break;
      case 'Rewards':
        Programmes.open(context, Programme.rewards);
      break;
      case 'Coupons':
        Programmes.open(context, Programme.coupons);
      break;
      case 'Gifts':
        Programmes.open(context, Programme.gifts);
      break;
      case 'Earnings':
      case 'Payouts':
      case 'Sales':
        Programmes.open(context, Programme.earnings);
      break;
      case 'Reference':
        Programmes.open(context, Programme.reference);
      break;
      case 'Copy code':
        if (!signedIn || code.isEmpty) {
          NwsbSignInPage.open(context);
          return;
        }
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied.')));
      break;
      case 'Apply a code':
        _apply(context, signedIn, referredBy);
      break;
      case 'Partner':
      case 'Starter Agent':
      case 'Rising Agent':
      case 'Pro Agent':
      case 'Elite Agent':
      case 'Master Agent':
        _welcome();
      break;
      case 'Your legs':
      case 'My team':
        _openTabs('team');
      break;
      case 'Ledger':
        _openTabs('sales');
      break;
      case 'Rules':
        _openTabs('rules');
      break;
    }
  }

  void _openTabs(String id) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Scaffold(
      backgroundColor: const Color(0xFF07070C),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [ProgramTabsBlock(spec: kEarnSpec, initialTab: id, scrollTo: true, showDisclaimer: false)],
      )),
    )));
  }

  void _apply(BuildContext context, bool signedIn, String referredBy) {
    if (!signedIn) {
      NwsbSignInPage.open(context);
      return;
    }
    if (referredBy.isNotEmpty) return;
    showNSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10141C),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _code, textCapitalization: TextCapitalization.characters, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Enter a referral code')),
            const SizedBox(height: 12),
            GoldButton(label: 'Apply code', onTap: () { Navigator.pop(ctx); runPrivate(context, () => EconomyApi.call('applyReferralCode', {'code': _code.text.trim()})); }),
          ],
        ),
      ),
    );
  }

  void _welcome() {
    showNDialog<void>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassWrap(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(6),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    WhiteCircleOrb(size: 20, mark: NwsbMarks.piggy),
                    SizedBox(width: 10),
                    Expanded(
                      child: EditableLabel('circle_screen.CircleScreen',
                        'Welcome to NowssB Earn',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Become a Partner in our journey and make this journey your Earn.\n\n'
                  'Commission is a percent of NowssB’s net after the store fee, never the sticker price. '
                  'Master Agent stops at 30%. A direct recruit pays you 5% of their commission, and only while both paid plans are active. '
                  'There is no third level. An invite by itself pays nothing. Payouts wait for review before money moves.',
                  style: TextStyle(color: Color(0xCCFFFFFF), height: 1.4),
                ),
                Row(
                  children: [
                    const AppThinkingLoader(size: 14, state: OrbState.composing, blackCircle: true, circlePad: 3),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const EditableLabel('circle_screen.CircleScreen', 'Continue', style: TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      goodToKnow: kEarnDisclaimer,
      title: 'NowssB Earn',
      mark: NwsbMarks.piggy,
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
              const IdentityRails(RailKind.earn),
              RoutineDeck(
                title: 'Earn',
                banner: signedIn ? w.circleTier : 'NowssB Earn',
                bannerSub: signedIn ? '$units units · ${w.code.isEmpty ? 'code pending' : w.code}' : 'Sign in to see your rank',
                onBanner: () => Programmes.open(context, Programme.reference),
                cards: [
                  WorkCard(category: 'Rank', title: signedIn ? w.circleTier : 'Sign in', meta: signedIn ? '$units of $next to the next tier' : 'Your rank is on this account', action: signedIn ? 'See plans' : 'Sign in', image: 'assets/rails/gen-49.jpg', onTap: () { if (!signedIn) { NwsbSignInPage.open(context); } else { Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen())); } }),
                  WorkCard(category: 'Rewards', title: 'Rewards', meta: 'Coins you earn', action: 'Open rewards', image: 'assets/rails/gen-50.jpg', onTap: () => Programmes.open(context, Programme.rewards)),
                  WorkCard(category: 'Coupons', title: 'Coupons', meta: 'Scratch and codes', action: 'Open coupons', image: 'assets/rails/gen-51.jpg', onTap: () => Programmes.open(context, Programme.coupons)),
                  WorkCard(category: 'Gifts', title: 'Gifts', meta: 'Send or redeem', action: 'Open gifts', image: 'assets/rails/gen-52.jpg', onTap: () => Programmes.open(context, Programme.gifts)),
                  WorkCard(category: 'Cash', title: 'Earnings', meta: 'Sales and payouts', action: 'Open earnings', image: 'assets/rails/gen-53.jpg', onTap: () => Programmes.open(context, Programme.earnings)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

final _refLedgers = <String, Stream<QuerySnapshot<Map<String, dynamic>>>>{};
Stream<QuerySnapshot<Map<String, dynamic>>> _refLedger(String uid) => _refLedgers.putIfAbsent(
    uid, () => FirebaseFirestore.instance.collection('referralLedger').where('referrerUid', isEqualTo: uid).limit(20).snapshots().asBroadcastStream());

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
                                    child: const EditableLabel('circle_screen.TierRail',
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

