import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/nwsb_sign_in_sheet.dart';
import '../../screens/subscription.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';

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
        title: const Text(
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
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'NowssB Earn',
      banner: Column(
        children: [
          ColoredSplitPromoBanner(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            spec: SplitPromoSpec(
              title: 'NowssB Earn\nPartner',
              cta: 'Welcome',
              leftColor: const Color(0xFF3D2914),
              rightColor: const Color(0xFFE6B325),
              art: SplitPromoArts.egyptianGold,
              onTap: _welcome,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              height: 148,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _toneCard(
                      'Partner',
                      const Color(0xFFE07A32),
                      'assets/banners/promo/pose-01.png',
                      _welcome,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _toneCard(
                      'Your status',
                      const Color(0xFF7C4DFF),
                      'assets/banners/promo/pose-02.png',
                      _welcome,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
                            child: Image.asset(
                              SplitPromoArts.egyptianLotus,
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
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
                      const Text('AGENT LADDER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.w700)),
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
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied.')));
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
              const Text('YOUR LEGS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
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
              const Text('LEDGER', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
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
            ],
          );
        },
      ),
    );
  }
}

Widget _toneCard(String label, Color color, String art, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: color),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
            child: Image.asset(art, fit: BoxFit.contain, alignment: Alignment.bottomCenter),
          ),
          Positioned(
            left: 10,
            right: 8,
            bottom: 8,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    ),
  );
}
