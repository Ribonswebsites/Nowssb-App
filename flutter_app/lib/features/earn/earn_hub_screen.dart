import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../bazaar/bazaar_screen.dart';
import '../circle/circle_screen.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';
import 'earnings_screen.dart';
import '../social/echo_wall_screen.dart';
import '../gifts/gifts_screen.dart';
import '../vault/vault_screen.dart';
import '../wordprint/word_print_screen.dart';
import '../../screens/nwsb_sign_in_sheet.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/referral_share_sheet.dart';
import '../economy/coupon_screen.dart';
import '../economy/partner_screen.dart';
import '../economy/reference_screen.dart';
import '../../widgets/program_shelf.dart';
import '../../admin/template/editable.dart';
import '../../admin/layout/layout_sections.dart';
import '../programs/coupons_program.dart';
import '../programs/earn_program.dart';
import '../programs/gifts_program.dart';
import '../programs/partner_program.dart';
import '../programs/program_kit.dart';
import '../programs/program_router.dart';
import '../programs/reference_program.dart';
import '../programs/rewards_program.dart';

class EarnHubScreen extends StatelessWidget {
  const EarnHubScreen({super.key});

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
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            // Server-driven order (Admin → UI Editor); bundled order by default.
      children: layoutChildren(context, 'earn', [
              _CoinHero(w: w),
              const SizedBox(height: 20),
              // Info card (reference: "coins on the way" box) with real cash + privacy.
              LSection('note', 'Privacy note', _InfoCard(w: w)),
              // Real referral code: users/{uid}/referral/main.code (EconomyMirror.code).
              if (w.uid != null && w.code.isNotEmpty) ...[
                const SizedBox(height: 12),
                LSection('share', 'Share your code', _ShareRow(code: w.code)),
              ],
              const SizedBox(height: 16),
              if (w.uid != null)
                GoldButton(
                  label: 'Use coins',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RewardsProgramPage(initialTab: 6))),
                ),
              const SizedBox(height: 24),
              const LSection('coins', 'Coin ledger', EditableLabel('earn_hub_screen.EarnHubScreen', 'COIN HISTORY', style: TextStyle(color: _kCalmAccent, letterSpacing: 2.4, fontSize: 11, fontWeight: FontWeight.w500))),
              const SizedBox(height: 8),
              _ledger('coinLedger', w.uid),
              const SizedBox(height: 24),
              const LSection('cash', 'Cash ledger', EditableLabel('earn_hub_screen.EarnHubScreen', 'CASH HISTORY', style: TextStyle(color: _kCalmAccent, letterSpacing: 2.4, fontSize: 11, fontWeight: FontWeight.w500))),
              const SizedBox(height: 8),
              _ledger('commissionLedger', w.uid),
              const SizedBox(height: 24),
              const CoinCollectCard(pageKey: 'hub', amount: 8, title: 'Earn hub coins'),
              // Coin pages (Free coins, Coinback, Multiplier), opened by the
              // router's names; rows appear once the router knows them.
              if (_coinZone.isNotEmpty) ...[
                const SizedBox(height: 24),
                LSection.group('coinzone', 'Coin pages', [
                  const EditableLabel('earn_hub_screen.EarnHubScreen', 'MORE COINS', style: TextStyle(color: _kCalmAccent, letterSpacing: 2.4, fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  for (final z in _coinZone)
                    ProgramLink(title: z.title, sub: '', mark: z.mark, page: () => Programmes.page(z.programme)),
                ]),
              ],
              const SizedBox(height: 24),
              // The six programs from the plan, each with its full tab set.
              LSection.group('programs', 'Programs', [
                const EditableLabel('earn_hub_screen.EarnHubScreen', 'THE PROGRAMS', style: TextStyle(color: _kCalmAccent, letterSpacing: 2.4, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ProgramLink(title: 'NowssB Earn', sub: '', mark: NwsbMarks.piggy, page: () => const EarnProgramPage()),
                ProgramLink(title: 'NowssB Rewards', sub: '', mark: NwsbMarks.rewards, page: () => const RewardsProgramPage()),
                ProgramLink(title: 'NowssB Coupons', sub: '', mark: NwsbMarks.coupon, page: () => const CouponsProgramPage()),
                ProgramLink(title: 'NowssB Gifts', sub: '', mark: NwsbMarks.gift, page: () => const GiftsProgramPage()),
                ProgramLink(title: 'NowssB Reference', sub: '', mark: NwsbMarks.reference, page: () => const ReferenceProgramPage()),
                ProgramLink(title: 'Partner Program', sub: '', mark: NwsbMarks.crown, page: () => const PartnerProgramPage()),
              ]),
              const SizedBox(height: 24),
              LSection.group('more', 'More', [
                ProgramLink(title: 'Your earning', sub: '', mark: NwsbMarks.bars, page: () => const EarningsScreen()),
                ProgramLink(title: 'Word Print', sub: '', mark: NwsbMarks.word, page: () => WordPrintScreen(uid: w.uid)),
                ProgramLink(title: 'Echo Wall', sub: '', mark: NwsbMarks.verified, page: () => const EchoWallScreen()),
              ]),
            ]),
          );
        },
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _ledger(String collection, String? uid) {
    if (uid == null) return const EconomyNote('Sign in to see the ledger.');
    if (!NwsbFirebase.ready) return const EconomyNote('Offline right now.');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).where('uid', isEqualTo: uid).limit(15).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const EconomyNote('Nothing here yet.');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final doc in docs)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  collection == 'commissionLedger'
                      ? '${doc.data()['note'] ?? doc.data()['type'] ?? ''}  ₹${(((doc.data()['paise'] as num?) ?? 0) / 100).toStringAsFixed(2)}'
                      : '${doc.data()['reason'] ?? ''}  ${doc.data()['delta'] ?? 0}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One calm accent for the Rewards page (sage), per the Oct 12 brief.
const Color _kCalmAccent = NwsbColors.gold;

/// The one bold moment on Rewards: a huge, thin coin number inside a slow
/// glowing orbit. Reads the server mirror only (EconomyMirror); grants nothing.
class _CoinHero extends StatefulWidget {
  const _CoinHero({required this.w});
  final EconomyMirror w;
  @override
  State<_CoinHero> createState() => _CoinHeroState();
}

class _CoinHeroState extends State<_CoinHero> with SingleTickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  String _group(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return n < 0 ? '-$b' : '$b';
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    final signedIn = w.uid != null;
    const soft = TextStyle(color: Color(0x99FFFFFF), fontSize: 13, height: 1.4);
    final progress = w.nextSellerTarget <= 0 ? 0.0 : (w.wordsSold / w.nextSellerTarget).clamp(0, 1).toDouble();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      AspectRatio(
        aspectRatio: 1.08,
        child: Stack(alignment: Alignment.center, children: [
          // Deep glass well.
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x59000000),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                ),
              ),
            ),
          ),
          // Slow orbit glow.
          FractionallySizedBox(
            widthFactor: 0.82,
            heightFactor: 0.82 / 1.08 * 1.08,
            child: AnimatedBuilder(
              animation: _orbit,
              builder: (context, _) => CustomPaint(painter: _OrbitPainter(_orbit.value)),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            FittedBox(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                NwsbCoinDisc(size: 56),
                const SizedBox(width: 12),
                signedIn
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: w.coins.toDouble()),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text(_group(v.round()),
                          style: const TextStyle(color: Colors.white, fontSize: 84, fontWeight: FontWeight.w200, letterSpacing: -3, height: 1)),
                    )
                  : const Text('\u2014', style: TextStyle(color: Colors.white, fontSize: 84, fontWeight: FontWeight.w200, height: 1)),
              ]),
            ),
            const SizedBox(height: 10),
            Text(signedIn ? 'Available balance' : 'Your balance', style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 15)),
          ]),
        ]),
      ),
      if (!signedIn) ...[
        const SizedBox(height: 20),
        GoldButton(label: 'Sign in', onTap: () => NwsbSignInPage.open(context)),
      ],
    ]);
  }
}

/// A thin ring with a travelling sage-to-gold glow and a few slow motes.
class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    final angle = t * 2 * math.pi;
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x1FFFFFFF));
    final sweep = SweepGradient(
      transform: GradientRotation(angle),
      colors: const [Color(0x00C9CCD1), Color(0xFFC9CCD1), Color(0xFFE4C56A), Color(0x00E4C56A)],
      stops: const [0.0, 0.18, 0.28, 0.42],
    );
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..shader = sweep.createShader(rect));
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = sweep.createShader(rect));
    for (var i = 0; i < 6; i++) {
      final a = -angle * 0.6 + i * math.pi / 3;
      final rr = r * (0.62 + 0.08 * math.sin(angle * 2 + i));
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * rr, 1.6,
          Paint()..color = const Color(0x66E4C56A));
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t;
}

/// Reference layout's tinted info box, filled with NowssB's real cash
/// balance and the privacy line.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.w});
  final EconomyMirror w;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Row(children: [
          const Text('Cash', style: TextStyle(color: _kCalmAccent, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          if (w.uid != null)
            MoneyCount(cents: w.cash, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))
          else
            const Text('\u2014', style: TextStyle(color: Colors.white)),
          const Spacer(),
          IconButton(
            tooltip: 'Privacy',
            icon: const Icon(Icons.info_outline, size: 18, color: Color(0x99E4C56A)),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (c) => AlertDialog(
                backgroundColor: Colors.black,
                content: const Text('This page is only yours. Coin and cash balances are not on the public Word Print.', style: TextStyle(color: Colors.white70)),
                actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
              ),
            ),
          ),
        ]),
      );
}

class _CoinLink {
  const _CoinLink(this.title, this.mark, this.programme);
  final String title;
  final String mark;
  final Programme programme;
}

/// Resolved through Programmes.forPoster so this compiles before the
/// freeCoins / coinback / multiplier routes land, and links once they do.
List<_CoinLink> get _coinZone => [
      for (final e in const [
        ('Free coins', NwsbMarks.rewards),
        ('Coinback', NwsbMarks.bag),
        ('Multiplier', NwsbMarks.bars),
      ])
        if (Programmes.forPoster(e.$1) case final p?) _CoinLink(e.$1, e.$2, p),
    ];


class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showReferralShareSheet(context, code: code),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0x66000000),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x26FFFFFF)),
          ),
          child: Row(children: [
            const Icon(Icons.ios_share, size: 18, color: _kCalmAccent),
            const SizedBox(width: 12),
            const Expanded(child: Text('Share your code', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
            Text(code, style: const TextStyle(color: _kCalmAccent, fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Color(0x99FFFFFF)),
          ]),
        ),
      );
}
