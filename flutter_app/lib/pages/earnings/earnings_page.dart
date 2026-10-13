// Rebuilt Earnings page (flag `newui_earnings`). Cards follow the approved
// designs: kit MeditationCard carousel on top, notched frosted ticket rows with
// rarity-style pills below, over the app's original background video.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../kit/kit.dart';
import '../../nowssb_ui/nowssb_ui.dart';
import 'earnings_models.dart';

/// Flag page key: `newui_earnings`.
const kEarningsNewUiPage = 'earnings';

class EarningsNewUiScreen extends StatefulWidget {
  const EarningsNewUiScreen({super.key, this.source = const KitEarningsSource(), this.provider = const ServerPayoutProvider()});
  final EarningsSource source;
  final PayoutProvider provider;
  @override
  State<EarningsNewUiScreen> createState() => _EarningsNewUiScreenState();
}

class _EarningsNewUiScreenState extends State<EarningsNewUiScreen> {
  late Stream<EarningsData> _stream = widget.source.watch();
  void _retry() => setState(() => _stream = widget.source.watch());
  @override
  Widget build(BuildContext context) => StreamBuilder<EarningsData>(
        stream: _stream,
        builder: (context, snap) => EarningsNewUiPage(
            data: snap.data ?? const EarningsData(), provider: widget.provider, onRetry: _retry),
      );
}

class EarningsNewUiPage extends StatefulWidget {
  const EarningsNewUiPage({super.key, required this.data, required this.provider, this.onRetry, this.money = KitMoney.cents, this.background});
  final EarningsData data;
  /// Defaults to the app's original background video (NAppBackdrop).
  /// Tests pass that video's poster frame.
  final Widget? background;
  final PayoutProvider provider;
  final VoidCallback? onRetry;
  /// Formats USD cents in the user's local currency (test seam).
  final String Function(int cents, {String? locale}) money;
  @override
  State<EarningsNewUiPage> createState() => _EarningsNewUiPageState();
}

class _EarningsNewUiPageState extends State<EarningsNewUiPage> {
  final _pager = PageController(viewportFraction: .78);
  int _page = 0;
  int _filter = 0;
  static const _filters = ['All', 'Sales', 'Commission', 'Payouts'];

  @override
  void dispose() { _pager.dispose(); super.dispose(); }

  String _m(int c) => widget.money(c);

  void _toast(String t) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t)));

  Future<void> _openPayout() => showGlassPopup<void>(context, builder: (ctx) => PayoutSetupSheet(
      provider: widget.provider, onDone: (msg) { Navigator.of(ctx).pop(); if (msg.isNotEmpty) _toast(msg); }));

  Future<void> _withdraw() async {
    final r = await widget.provider.requestPayout();
    if (!mounted) return;
    _toast(switch (r) { KitOk() => 'Payout requested. ${widget.provider.name} will confirm it.', KitErr(:final message) => message });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final body = switch (d.status) {
        EarningsStatus.loading => ListView(key: const ValueKey('earnings-loading'), padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            children: const [GlassSkeleton(height: 380, radius: NTokens.rHero), SizedBox(height: 16), GlassSkeleton(height: 92), SizedBox(height: 12), GlassSkeleton(height: 92)]),
        EarningsStatus.error => _state(Icons.cloud_off_rounded, 'Could not load earnings', 'Try again in a moment.', 'Try again'),
        EarningsStatus.offline => _state(Icons.wifi_off_rounded, 'You are offline', 'Your earnings will appear when you reconnect.', 'Retry'),
        EarningsStatus.signedOut => _state(Icons.lock_outline_rounded, 'Sign in to see earnings', 'Your sales, commissions and payouts live in your account.', 'Sign in'),
        _ => _content(d),
      };
    return Scaffold(
      backgroundColor: NTokens.bgBottom,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white,
          title: const Text('Earnings', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Stack(fit: StackFit.expand, children: [
        widget.background ?? const NAppBackdrop(),
        SafeArea(bottom: false, child: body),
      ]),
    );
  }

  Widget _state(IconData i, String t, String m, String a) => Center(child: Padding(padding: const EdgeInsets.all(24),
      child: GlassStateCard(icon: i, title: t, message: m, action: a, onAction: widget.onRetry)));

  Widget _content(EarningsData d) {
    final cards = [
      (title: '${_m(d.balanceCents)}\navailable', sub: 'Sales ${_m(d.sum(EarningKind.sale))} · Commission ${_m(d.sum(EarningKind.commission))}',
          cta: 'Withdraw', act: d.balanceCents > 0 ? _withdraw : null, img: NCircles.of('lotus')),
      (title: 'Set up your payouts', sub: 'Pick your country. ${widget.provider.name} checks identity and tax details where you live.',
          cta: 'Next', act: _openPayout, img: NCircles.of('lake')),
      (title: 'How earnings work', sub: 'Earn from word sales and referral commission. Amounts show in your local currency.',
          cta: 'Next', act: () => _pager.animateToPage(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic),
          img: NCircles.of('stones')),
    ];
    final kinds = [null, EarningKind.sale, EarningKind.commission, EarningKind.payout];
    final rows = d.rows.where((r) => kinds[_filter] == null || r.kind == kinds[_filter]).toList();
    return ListView(key: const ValueKey('earnings-ready'), padding: const EdgeInsets.fromLTRB(0, 60, 0, 32), children: [
      SizedBox(height: 480, child: PageView.builder(controller: _pager, itemCount: cards.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final c = cards[i];
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(alignment: Alignment.topCenter, child: MeditationCard(title: c.title, subtitle: c.sub, image: c.img,
                    cta: c.cta, onCta: c.act, secondary: i == 0 ? null : 'Skip', dots: cards.length, dotIndex: _page)));
          })),
      const SizedBox(height: 18),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('EARNINGS LIST', style: TextStyle(color: NTokens.mint, fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800))),
      const SizedBox(height: 10),
      FilterChipRow(labels: _filters, selected: {_filter}, onSelect: (i) => setState(() => _filter = i)),
      const SizedBox(height: 12),
      if (d.status == EarningsStatus.empty || rows.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: GlassStateCard(icon: Icons.spa_outlined,
            title: 'No earnings yet', message: 'Sales and referral commissions will show up here.'))
      else
        for (var i = 0; i < rows.length; i++)
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: EarningTicketRow(row: rows[i], amount: _m(rows[i].cents), image: NCircles.at(i + 3))),
    ]);
  }
}

/// Earnings row in the approved coupon-ticket style, built from kit parts
/// (NotchClipper, NGlass, CircleImage, DashedLine, RarityChip, ExpiredOverlay).
class EarningTicketRow extends StatelessWidget {
  const EarningTicketRow({super.key, required this.row, required this.amount, this.image});
  final EarningRow row;
  final String amount;
  final ImageProvider? image;
  @override
  Widget build(BuildContext context) {
    final rarity = switch (row.kind) { EarningKind.sale => Rarity.rare, EarningKind.commission => Rarity.epic, EarningKind.payout => Rarity.legendary };
    final label = switch (row.kind) { EarningKind.sale => 'SALE', EarningKind.commission => 'COMMISSION', EarningKind.payout => 'PAYOUT' };
    Widget card = ClipPath(clipper: const NotchClipper(radius: 22, notch: 10), child: NGlass(
        radius: 22, accent: rarity.color, padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(children: [
          CircleImage(image: image, size: 64, ring: rarity.color),
          const SizedBox(width: 12),
          const SizedBox(height: 64, child: DashedLine(vertical: true)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [GlassBadge(label, color: rarity.color), if (row.isNew) ...[const SizedBox(width: 6), const GlassBadge('NEW')]]),
            const SizedBox(height: 6),
            Text(row.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(row.status.isEmpty ? 'Credited >' : '${row.status[0].toUpperCase()}${row.status.substring(1)} >',
                style: const TextStyle(color: NTokens.mint, fontSize: 12, fontWeight: FontWeight.w700)),
          ])),
        ])));
    if (row.inactive) card = ExpiredOverlay(label: row.status, child: card);
    return card;
  }
}

/// Country-aware payout onboarding. The app sends only the country; the
/// provider runs identity and tax checks for it (verify with payout provider / legal).
class PayoutSetupSheet extends StatefulWidget {
  const PayoutSetupSheet({super.key, required this.provider, required this.onDone});
  final PayoutProvider provider;
  final void Function(String message) onDone;
  @override
  State<PayoutSetupSheet> createState() => _PayoutSetupSheetState();
}

class _PayoutSetupSheetState extends State<PayoutSetupSheet> {
  String? _country;
  bool _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    final r = await widget.provider.onboard(_country!);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case KitOk(:final value):
        if (value.url != null) await launchUrl(Uri.parse(value.url!), mode: LaunchMode.externalApplication);
        widget.onDone(!value.supported ? 'Payouts are not available in this country yet. Your balance stays safe here.'
            : value.message.isNotEmpty ? value.message : 'Continue with ${widget.provider.name} to finish setup.');
      case KitErr(:final message):
        widget.onDone(message);
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('Where do you live?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('${widget.provider.name} handles identity and tax checks for your country. NowssB never asks for ID or tax numbers in the app.',
            style: const TextStyle(color: NTokens.textLo, fontSize: 12, height: 1.4)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in widget.provider.countries)
            GlassChip(key: ValueKey('country-${c.code}'), label: c.name, selected: _country == c.code, onTap: () => setState(() => _country = c.code)),
        ]),
        const SizedBox(height: 18),
        Align(alignment: Alignment.centerRight, child: GlassPill(key: const ValueKey('payout-continue'),
            label: _busy ? 'Opening…' : 'Continue with ${widget.provider.name}', style: PillStyle.white,
            onTap: _country == null || _busy ? null : _go)),
      ]);
}
