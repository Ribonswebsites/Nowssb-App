/// NowssB Coupons — the one Coupons page: today's free scratch (kept open
/// once scratched, from the server's own record), the coupon tickets, a
/// look at the paid cards, then the programme tabs (My Coupons · Scratch ·
/// Coupon Shop · History · Rules and Odds) below.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/tokens.dart';
import '../../widgets/four_banners.dart';
import '../../widgets/glass_system.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import '../../widgets/hype_rail.dart';
import '../../widgets/hub_rails.dart';
import '../../widgets/routine_deck.dart';
import '../../widgets/sections/coupon_banner_section.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guide());
  }

  Future<void> _guide() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('nwsb.guide.coupons') == true) return;
    if (!mounted) return;
    await PageGuide.show(context, title: 'My Coupons', lines: const [
      'A coupon is a scratch or a code. It is not cash.',
      'Tap Scratch to reveal today’s card.',
      'Add a code, then use it at checkout. Coins cover only part of the price.',
    ]);
    await prefs.setBool('nwsb.guide.coupons', true);
  }

  void _help() {
    PageGuide.show(context, title: 'My Coupons', lines: const [
      'A coupon is a scratch or a code. It is not cash.',
      'Tap Scratch to reveal today’s card.',
      'Add a code, then use it at checkout. Coins cover only part of the price.',
    ]);
  }

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

  void _detail(WideCouponData d) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(12),
        child: GlassWrapper(
          radius: 36,
          blur: true,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0B0B12), borderRadius: BorderRadius.circular(28)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.banner, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(d.line, style: const TextStyle(color: Color(0xB3FFFFFF))),
                const SizedBox(height: 8),
                Text(d.copy, style: const TextStyle(color: kTileGold, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Coins cover only part of the price. A coupon is not cash.', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await NowssbLoader.run(context, EconomyApi.call('claimTicket', {'code': d.copy}));
                    },
                    child: const Text('Apply now'),
                  ),
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
      goodToKnow: kCouponsDisclaimer,
      title: 'NowssB Coupons',
      mark: NwsbMarks.coupon,
      showBalance: false,
      header: CouponsPageHeader(trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(onPressed: _help, icon: const Icon(Icons.help_outline, color: Colors.white)),
        const CoinBalancePill(),
      ])),
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: NwsbColors.gold,
              onRefresh: () => EconomyMirror.instance.refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  RoutineDeck(
                    title: 'Coupons',
                    banner: 'NowssB Coupons',
                    bannerSub: 'Scratch, codes, shop',
                    onBanner: _showScratch,
                    cards: [
                      WorkCard(category: 'Scratch', title: 'Daily scratch', meta: 'One card on this account', action: 'Scratch', image: 'assets/rails/coupons-01.jpg', onTap: _showScratch),
                      WorkCard(category: 'Shop', title: 'Coupon shop', meta: 'Paid cards', action: 'Open shop', image: 'assets/rails/coupons-02.jpg', onTap: () => _tab('shop')),
                      WorkCard(category: 'Mine', title: 'My coupons', meta: 'Codes already on the account', action: 'Open mine', image: 'assets/rails/clear-02.jpg', onTap: () => _tab('mine')),
                      WorkCard(category: 'Help', title: 'How a coupon works', meta: 'It comes off the price. It is not cash.', action: 'Read', image: 'assets/rails/clear-03.jpg', onTap: _help),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _CodeBox(),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 168,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final d in kWideCoupons.take(6))
                          GlassCardD(name: d.kicker, offer: d.banner, color: d.coins > 0 ? kTileGold : kTileViolet),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < kWideCoupons.length && i < 6; i++)
                    GlassCardB(
                      title: kWideCoupons[i].banner,
                      line: kWideCoupons[i].line,
                      action: 'View details',
                      fresh: i.isEven,
                      onTap: () => _detail(kWideCoupons[i]),
                    ),
                  GlassCardA(title: 'How a coupon works', line: 'Scratch, or add a code. It comes off the price. It is not cash.', onNext: _help),
                  const SizedBox(height: 8),
                  KeyedSubtree(key: _scratch, child: const DailyScratchCard()),
                  const SizedBox(height: 12),
                  const CouponRails(),
                  const SizedBox(height: 12),
                  _PaidPeek(onOpen: () => _tab('shop')),
                  const SizedBox(height: 12),
                  const FourBanners(
                    current: Programme.coupons,
                    splitTitle: 'Coupons',
                    splitCta: 'Scratch',
                    blackTitle: 'Odds on the card',
                    blackSub: 'A free scratch, and three paid cards. Nothing is cash.',
                  ),
                  const SizedBox(height: 12),
                  ProgramTabsBlock(spec: kCouponsSpec, initialTab: widget.initialTab, scrollTo: widget.initialTab != null, goRef: _go, showDisclaimer: false),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(child: GlassWrapper(radius: 999, onTap: () => _tab('mine'), child: const Center(child: Text('All rewards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))))),
                const SizedBox(width: 10),
                Expanded(child: GlassWrapper(radius: 999, onTap: _showScratch, child: const Center(child: Text('Scratch cards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))))),
              ],
            ),
          ),
        ],
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
class _CodeBox extends StatefulWidget {
  const _CodeBox();
  @override
  State<_CodeBox> createState() => _CodeBoxState();
}

class _CodeBoxState extends State<_CodeBox> {
  final _code = TextEditingController();
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassWrapper(
      radius: 18,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _code,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Enter coupon code', hintStyle: TextStyle(color: Color(0x66FFFFFF)), border: InputBorder.none),
            ),
          ),
          TextButton(
            onPressed: () async {
              final raw = _code.text.trim();
              if (raw.isEmpty) return;
              await NowssbLoader.run(context, EconomyApi.call('claimTicket', {'code': raw}));
            },
            child: const Text('Add coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

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
