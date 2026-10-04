/// NowssB Coupons — the one Coupons page: today's free scratch (kept open
/// once scratched, from the server's own record), the coupon tickets, a
/// look at the paid cards, then the programme tabs (My Coupons · Scratch ·
/// Coupon Shop · History · Rules and Odds) below.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/four_banners.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import '../../widgets/hype_rail.dart';
import 'economy_api.dart';
import 'reward_fx.dart';
import 'economy_theme.dart';
import 'scratch_card.dart';
import 'coupon_tickets.dart';
import '../programs/program_kit.dart';
import '../programs/program_heroes.dart';
import '../programs/program_router.dart';
import '../programs/coupons_program.dart';
import '../../admin/template/editable.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key, this.initialTab});

  /// Open at one of the programme tabs (scrolls to it).
  final String? initialTab;

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  final _go = ValueNotifier<void Function(String)?>(null);
  final _scratch = GlobalKey();

  @override
  void dispose() {
    _go.dispose();
    super.dispose();
  }

  void _tab(String id) => _go.value?.call(id);

  void _showScratch() {
    final ctx = _scratch.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 380), alignment: 0.08);
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      goodToKnow: kCouponsDisclaimer,
      title: 'NowssB Coupons',
      mark: NwsbMarks.coupon,
      showBalance: false,
      header: const CouponsPageHeader(trailing: CoinBalancePill()),
      child: RefreshIndicator(
        color: NwsbColors.gold,
        onRefresh: () => EconomyMirror.instance.refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          cacheExtent: 1600,
          children: [
            CouponTicketPromo(onPressed: _showScratch),
            const NowssbHypeRail(),
            const CouponsHero(),
            const GlassLine(
              text: 'A free scratch every day. Paid cards show every prize before you draw. Expected value stays under the price.',
              mark: NwsbMarks.coupon,
            ),
            const SizedBox(height: 16),
            const EditableLabel('coupon_screen.CouponScreen', 'FREE SCRATCH', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            KeyedSubtree(key: _scratch, child: const DailyScratchCard()),
            const SizedBox(height: 18),
            const EditableLabel('coupon_screen.CouponScreen', 'COUPON TICKETS', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const EditableLabel('coupon_screen.CouponScreen', 'Tap a ticket to flip it. Claim puts the coupon on your account and in the checkout picker.',
                style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.35)),
            const SizedBox(height: 10),
            const CouponRails(),
            const SizedBox(height: 18),
            const EditableLabel('coupon_screen.CouponScreen', 'PAID CARDS', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const EditableLabel('coupon_screen.CouponScreen',
              'Odds are fixed until a published change. A Signature prize does not unlock a rank rate.',
              style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 8),
            _PaidPeek(onOpen: () => _tab('shop')),
            const SizedBox(height: 18),
            const FourBanners(
              current: Programme.coupons,
              splitTitle: 'Coupons',
              splitCta: 'Scratch',
              blackTitle: 'Odds on the card',
              blackSub: 'A free scratch, and three paid cards. Nothing is cash.',
            ),
            const SizedBox(height: 18),
            ProgramTabsBlock(spec: kCouponsSpec, initialTab: widget.initialTab, scrollTo: widget.initialTab != null, goRef: _go, showDisclaimer: false),
          ],
        ),
      ),
    );
  }
}

/// Today's free scratch. Seeded from the server (summary.today.scratchCard)
/// so a scratched card stays open — it never re-seals on scroll or on a
/// new visit, and a replay never shows a second win.
class DailyScratchCard extends StatefulWidget {
  const DailyScratchCard({super.key});

  @override
  State<DailyScratchCard> createState() => _DailyScratchCardState();
}

class _DailyScratchCardState extends State<DailyScratchCard> with AutomaticKeepAliveClientMixin {
  /// Opened this session (before the summary catches up), by IST day.
  static final _session = <String, String>{};
  var _busy = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  String get _day {
    final n = DateTime.now().toUtc().add(const Duration(minutes: 330));
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  /// What today's card already holds, or null if it's still sealed.
  String? _openedLabel(Map<String, dynamic> s) {
    final t = sMap(s['today']);
    final card = sMap(t['scratchCard']);
    if (card['status'] == 'revealed') {
      final g = sMap(card['granted']);
      return '${card['label'] ?? ''}'.isNotEmpty ? '${card['label']}' : '${g['label'] ?? 'Your prize'}';
    }
    return _session[_day];
  }

  Future<void> _cleared() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await EconomyApi.call('scratchCoupon');
      final label = '${r['label'] ?? (r['granted'] is Map ? (r['granted'] as Map)['label'] : null) ?? 'Your prize'}';
      _session[_day] = label;
      if (mounted) setState(() {});
      // A replay (already scratched today) shows the card, never a new win.
      if (r['already'] != true) unawaited(celebrate(context, r, title: 'Today\u2019s scratch'));
    } on EconomyException catch (e) {
      if (mounted) setState(() => _error = EconomyApi.isMissing(e) ? EconomyApi.switchingOnMessage : e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final s = EconomyMirror.instance.summary;
        final opened = _openedLabel(s);
        if (opened != null) return _OpenedCard(label: opened, scratchedToday: true);
        if (EconomyMirror.instance.scratchToday && s.isEmpty) return const _OpenedCard(label: 'Scratched today', scratchedToday: true);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NwsbScratchCard(
              onCleared: _cleared,
              prize: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EditableImage.asset(NwsbCoinFly.disc, width: 36, height: 36, fit: BoxFit.contain, slot: 'coupon_screen.CouponScreen'),
                  const SizedBox(height: 6),
                  Text(_busy ? 'Opening…' : (_session[_day] ?? 'Today\'s prize'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const EditableLabel('coupon_screen.CouponScreen', 'DRAWN BY NOWSSB', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 2, fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: NwsbColors.goldLight)),
            ],
          ],
        );
      },
    );
  }
}

/// A scratched card, shown open: what it held, and when the next one comes.
class _OpenedCard extends StatelessWidget {
  const _OpenedCard({required this.label, required this.scratchedToday});
  final String label;
  final bool scratchedToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A1408), Colors.black, Color(0xFF14100A)]),
        border: Border.all(color: const Color(0x99E4C56A)),
        boxShadow: const [BoxShadow(color: Color(0x33E4C56A), blurRadius: 22, spreadRadius: -6)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EditableImage.asset(NwsbCoinFly.disc, width: 34, height: 34, fit: BoxFit.contain, slot: 'coupon_screen.OpenedCard'),
          const SizedBox(height: 6),
          const EditableLabel('coupon_screen.OpenedCard', 'ALREADY SCRATCHED TODAY', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.6, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('You won $label', textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const EditableLabel('coupon_screen.OpenedCard', 'Next free card at midnight · it\u2019s on your account', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11.5)),
        ],
      ),
    );
  }
}

/// The paid cards from the server's own odds table, with a jump to the
/// Coupon Shop tab (where each card is bought directly on Play).
class _PaidPeek extends StatelessWidget {
  const _PaidPeek({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final paid = sList(sMap(sMap(EconomyMirror.instance.summary['config'])['odds'])['paid']);
        if (paid.isEmpty) {
          return const PEmpty('Paid cards and their odds load from your account.', slot: 'coupon_screen.PaidPeek');
        }
        return Column(
          children: [
            for (final c in paid)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: onOpen,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: rarityColor('${c['id']}').withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${c['title'] ?? c['id']}'.toUpperCase(), style: TextStyle(color: rarityColor('${c['id']}'), fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                              const SizedBox(height: 3),
                              Text('Rarest: ${c['rarest'] ?? '—'} · ${sList(c['odds']).length} prizes listed', style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(inr(sNum(c['priceINR'])), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right, color: NwsbColors.goldLight),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The home Coupons section: a contained glass block of normal height —
/// two tickets you can claim right here, and the way into the full page.
/// No sideways strip, so it never traps the home scroll.
class HomeCouponShelf extends StatelessWidget {
  const HomeCouponShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GlassWrap(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18)),
          child: LayoutBuilder(
            builder: (context, c) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EditableLabel('coupon_screen.HomeCouponShelf',
                  'NOWSSB COUPONS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.2, color: Color(0xFFE4C56A)),
                ),
                const SizedBox(height: 6),
                const EditableLabel('coupon_screen.HomeCouponShelf',
                  'Coupons',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, height: 1.05, color: Color(0xFFF4F4F5)),
                ),
                const SizedBox(height: 4),
                const EditableLabel('coupon_screen.HomeCouponShelf', 'Tap a ticket to claim it. A free scratch waits every day.',
                    style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xB3FFFFFF))),
                const SizedBox(height: 12),
                for (final d in kWideCoupons.take(2)) ...[
                  WideCoupon(data: d, width: c.maxWidth, expires: couponExpiry(d.copy), scissorsLeft: d == kWideCoupons.first),
                  const SizedBox(height: 10),
                ],
                GoldButton(
                  label: 'Scratch, tickets and paid cards',
                  filled: false,
                  onTap: () => Programmes.open(context, Programme.coupons),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
