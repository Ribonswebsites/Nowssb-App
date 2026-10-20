/// Coupons sub-pages and pop-ups: Hub (tabs), Coupon Detail, Apply Coupon,
/// Terms, How It Works and the Button Guide. Transparent scaffolds so the
/// app's original background video stays visible. No made-up amounts.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/glass_wrap.dart';
import '../economy/coupon_tickets.dart';
import '../economy/economy_api.dart';
import '../programs/coupons_program.dart';
import '../programs/program_kit.dart';

const _card = Color(0xFF0B0B12);
const _gold = Color(0xFFE4C56A);

/// Shared glass pop-up shell (section 6): glass wrapper + black card.
Future<T?> showCouponSheet<T>(BuildContext context, {required String title, required List<Widget> Function(BuildContext) body}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C000000),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GlassWrap(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0x0FFFFFFF))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                  InkWell(
                    key: const Key('sheet_close'),
                    onTap: () => Navigator.pop(ctx),
                    customBorder: const CircleBorder(),
                    child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0x22FFFFFF), shape: BoxShape.circle), child: const Icon(Icons.close, size: 18, color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 12),
                ...body(ctx),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _box(String label, String value, {Color tint = const Color(0x22E4C56A)}) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x22FFFFFF))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35)),
      ]),
    );

Widget _pill(String label, VoidCallback? onTap, {bool filled = true, Key? key}) => SizedBox(
      height: 46,
      child: TextButton(
        key: key,
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: filled ? Colors.white : Colors.transparent,
          foregroundColor: filled ? Colors.black : Colors.white,
          shape: StadiumBorder(side: filled ? BorderSide.none : const BorderSide(color: Color(0x55FFFFFF))),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );

/// Claims a code with the Worker and shows the result (success or friendly error).
Future<void> claimCouponCode(BuildContext context, String code) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final r = await EconomyApi.call('claimTicket', {'code': code});
    HapticFeedback.mediumImpact();
    messenger?.showSnackBar(SnackBar(content: Text('${r['label'] ?? 'Coupon'} is on your account.')));
  } on EconomyException catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    messenger?.showSnackBar(const SnackBar(content: Text('Could not reach the server. Check your connection and try again.')));
  }
}

/// Pop-up 1: Coupon Detail.
Future<void> showCouponDetail(BuildContext context, WideCouponData d) => showCouponSheet<void>(context, title: d.banner, body: (ctx) => [
      Text(d.kicker, style: const TextStyle(color: _gold, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Container(
        key: const Key('detail_code'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x66E4C56A))),
        child: Row(children: [
          Expanded(child: Text(d.copy, style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.4, fontWeight: FontWeight.w800))),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: d.copy));
              ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(const SnackBar(content: Text('Code copied')));
            },
            child: const Text('Copy', style: TextStyle(color: _gold, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      _box('APPLIES TO', d.foot.isEmpty ? d.line : '${d.foot[0]}${d.foot.substring(1).toLowerCase()}. ${d.line}'),
      _box('STACKS WITH COINS', 'Coins cover only part of the price. A coupon is not cash.', tint: const Color(0x2266C6FF)),
      _box('VALIDITY', 'One coupon per order. Expires 30 days after you claim it.', tint: const Color(0x22B07CFF)),
      const SizedBox(height: 6),
      _pill('Apply now', () async {
        Navigator.pop(ctx);
        await claimCouponCode(context, d.copy);
      }, key: const Key('detail_apply')),
      const SizedBox(height: 8),
      _pill('View terms', () {
        Navigator.pop(ctx);
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CouponTermsPage()));
      }, filled: false, key: const Key('detail_terms')),
    ]);

/// Pop-up 3: Apply Coupon. Pick one coupon from the list, then apply it.
Future<void> showApplyCoupon(BuildContext context) {
  WideCouponData? picked = kWideCoupons.isEmpty ? null : kWideCoupons.first;
  return showCouponSheet<void>(context, title: 'Apply a coupon', body: (ctx) => [
        StatefulBuilder(builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Pick one coupon. Only one applies per order.', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
              const SizedBox(height: 8),
              for (final d in kWideCoupons)
                GestureDetector(
                  key: Key('apply_${d.code}'),
                  onTap: () => set(() => picked = d),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: picked == d ? const Color(0x33E4C56A) : const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: picked == d ? _gold : const Color(0x22FFFFFF)),
                    ),
                    child: Row(children: [
                      Icon(picked == d ? Icons.radio_button_checked : Icons.radio_button_off, color: picked == d ? _gold : Colors.white54, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.banner, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        Text(d.line, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                      ])),
                    ]),
                  ),
                ),
              const SizedBox(height: 6),
              _pill('Apply', picked == null
                  ? null
                  : () async {
                      final code = picked!.copy;
                      Navigator.pop(ctx);
                      await claimCouponCode(context, code);
                    }, key: const Key('apply_go')),
            ])),
      ]);
}

/// The coupon hub: the five programme tabs on one page with a real tab bar.
class CouponHubPage extends StatelessWidget {
  const CouponHubPage({super.key, this.initialTab});
  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    final tabs = kCouponsSpec.tabs;
    final start = tabs.indexWhere((t) => t.id == initialTab);
    return DefaultTabController(
      length: tabs.length,
      initialIndex: start < 0 ? 0 : start,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text('My Coupons'),
          actions: [
            IconButton(tooltip: 'Apply a coupon', onPressed: () => showApplyCoupon(context), icon: const Icon(Icons.local_offer_outlined)),
            IconButton(tooltip: 'Terms', onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CouponTermsPage())), icon: const Icon(Icons.gavel_outlined)),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: _gold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [for (final t in tabs) Tab(text: t.title)],
          ),
        ),
        body: TabBarView(children: [
          for (final t in tabs)
            ListView(padding: const EdgeInsets.all(16), children: [
              ProgramTabsBlock(key: ValueKey('hub_${t.id}'), spec: kCouponsSpec, initialTab: t.id, showDisclaimer: false),
            ]),
        ]),
      ),
    );
  }
}

/// Pop-up 9 as a page: Terms & Disclaimers.
class CouponTermsPage extends StatelessWidget {
  const CouponTermsPage({super.key});
  static const items = [
    ('VALIDITY', 'Coupons and free cards expire 30 days after they are issued.'),
    ('ONE PER ORDER', 'Only one coupon applies to an order. Coupons do not stack with each other.'),
    ('NOT CASH', 'Coupons and prizes have no cash value and cannot be transferred or sold.'),
    ('COINS', 'Coins cover only part of a price. The rest is paid in your local currency.'),
    ('REGION', 'Some offers and paid cards are not available in every country.'),
    ('GOOGLE PLAY', 'Paid items are charged by Google Play in your local currency, including any taxes.'),
    ('PAID CARDS', 'Paid cards are 18+ and have a monthly limit you can set in Settings.'),
    ('CHANGES', 'NowssB can change or end offers. Anything already on your account stays valid until it expires.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, title: const Text('Terms')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final (k, v) in items) _box(k, v),
          const SizedBox(height: 8),
          Text(kCouponsDisclaimer, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12, height: 1.4)),
        ]),
      );
}

/// How It Works (section 7): four slides, Next / Got it.
class CouponHowItWorks extends StatefulWidget {
  const CouponHowItWorks({super.key});
  static const slides = [
    ('Earn', 'Earn free coupons', 'Streaks, quests, gift boxes and purchases can give you a sealed card.', Icons.card_giftcard),
    ('Scratch', 'Scratch to reveal', 'The prize is drawn by the server when the card is issued. Scratching shows it.', Icons.auto_awesome),
    ('Use', 'Apply at checkout', 'Pick one coupon in Apply a coupon, or type a code you were given.', Icons.local_offer_outlined),
    ('Stack', 'Coins plus a coupon', 'Coins cover part of the price; a coupon takes some off. Neither is cash.', Icons.layers_outlined),
  ];

  @override
  State<CouponHowItWorks> createState() => _CouponHowItWorksState();
}

class _CouponHowItWorksState extends State<CouponHowItWorks> {
  final _page = PageController();
  var _i = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == CouponHowItWorks.slides.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(children: [
          Align(alignment: Alignment.topRight, child: IconButton(key: const Key('hiw_close'), onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))),
          Expanded(
            child: PageView(
              controller: _page,
              onPageChanged: (i) => setState(() => _i = i),
              children: [
                for (final (tag, title, body, icon) in CouponHowItWorks.slides)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: GlassWrap(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xCC0B0B12), borderRadius: BorderRadius.circular(28)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(icon, size: 64, color: _gold),
                          const SizedBox(height: 18),
                          Text(tag.toUpperCase(), style: const TextStyle(color: _gold, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xB3FFFFFF), height: 1.4)),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var k = 0; k < CouponHowItWorks.slides.length; k++)
              AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.all(4), width: k == _i ? 18 : 7, height: 7, decoration: BoxDecoration(color: k == _i ? Colors.white : Colors.white38, borderRadius: BorderRadius.circular(9))),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: SizedBox(
              width: double.infinity,
              child: _pill(last ? 'Got it' : 'Next', () {
                if (last) {
                  Navigator.pop(context);
                } else {
                  _page.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
                }
              }, key: const Key('hiw_next')),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Button Guide (section 8): short step-by-step cards explaining each button.
Future<void> showCouponButtonGuide(BuildContext context) async {
  const steps = [
    ('Daily scratch', 'Tap the banner or the Scratch card to open today’s free card.'),
    ('My coupons', 'Every tab lives here: My Coupons, Scratch, Shop, History, Rules and Odds.'),
    ('Apply a coupon', 'Pick a coupon you hold, or type a code, and claim it.'),
    ('Coupon tickets', 'Tap a ticket for its details, code and terms.'),
    ('? button', 'Replays How It Works and this guide any time.'),
  ];
  for (var i = 0; i < steps.length; i++) {
    if (!context.mounted) return;
    final next = await showCouponSheet<bool>(context, title: steps[i].$1, body: (ctx) => [
          Text('${i + 1} / ${steps.length}', style: const TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(steps[i].$2, style: const TextStyle(color: Color(0xCCFFFFFF), height: 1.4)),
          const SizedBox(height: 14),
          Row(children: [
            TextButton(key: const Key('guide_skip'), onPressed: () => Navigator.pop(ctx, false), child: const Text('Skip', style: TextStyle(color: Colors.white70))),
            const Spacer(),
            _pill(i == steps.length - 1 ? 'Done' : 'Next', () => Navigator.pop(ctx, true), key: const Key('guide_next')),
          ]),
        ]);
    if (next != true) return;
  }
}

/// First visit: How It Works, then the Button Guide. Remembered on this device.
Future<void> runCouponsFirstUse(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('coupons_howitworks_seen') == true) return;
  await prefs.setBool('coupons_howitworks_seen', true);
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CouponHowItWorks()));
  if (!context.mounted) return;
  await showCouponButtonGuide(context);
}
