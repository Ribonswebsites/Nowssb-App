/// Store and subscription extras from the programmes (PDF-2 §9):
/// share links on item cards, the friend-discount badge, and the checkout
/// panel (coupon picker + coin slider + live server quote + Pay on Play).
/// Every number comes from the server quote; nothing is priced on the phone.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/tokens.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../economy/economy_api.dart';
import '../economy/play_billing.dart';
import '../economy/reward_fx.dart';
import '../../admin/template/editable.dart';

/// Gets (or mints) my link for one item from the server.
Future<String?> myLinkFor(BuildContext context, {required String kind, String id = '', String title = ''}) async {
  try {
    final r = await EconomyApi.call('getLink', {'kind': kind, 'id': id, 'title': title});
    final url = '${r['url'] ?? ''}';
    return url.isEmpty ? null : url;
  } on EconomyException catch (e) {
    if (context.mounted) showEconomyError(context, e);
    return null;
  }
}

/// Copy link / Share for a word, meaning, bundle, ebook or plan.
class ShareItemButtons extends StatelessWidget {
  const ShareItemButtons({super.key, required this.kind, this.id = '', this.title = '', this.dense = true, this.dark = false});
  final String kind;
  final String id;
  final String title;
  final bool dense;
  final bool dark;

  Future<void> _copy(BuildContext context) async {
    final url = await myLinkFor(context, kind: kind, id: id, title: title);
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    HapticFeedback.selectionClick();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: EditableLabel('store_extras.ShareItemButtons', 'Your link is copied. Friends get a discount; you earn when they buy.')));
  }

  Future<void> _share(BuildContext context) async {
    final url = await myLinkFor(context, kind: kind, id: id, title: title);
    if (url == null) return;
    final text = title.isEmpty ? 'Try NowssB with my link: $url' : '$title on NowssB — $url';
    final r = await SharePlus.instance.share(ShareParams(text: text, subject: title.isEmpty ? 'NowssB' : title));
    // First share of this item (server pays once per item, capped per day).
    if (r.status == ShareResultStatus.success && id.isNotEmpty) reportEarn('first_share', key: '$kind:$id');
  }

  @override
  Widget build(BuildContext context) {
    final fg = dark ? NwsbColors.ink : Colors.white;
    Widget b(IconData i, String l, VoidCallback onTap) => InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: dense ? 9 : 14, vertical: dense ? 5 : 9),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: fg.withValues(alpha: 0.35))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(i, size: dense ? 13 : 16, color: fg),
              const SizedBox(width: 5),
              Text(l, style: TextStyle(color: fg, fontSize: dense ? 11 : 13, fontWeight: FontWeight.w700)),
            ]),
          ),
        );
    return Wrap(spacing: 6, runSpacing: 6, children: [
      b(Icons.link_rounded, 'Copy link', () => _copy(context)),
      b(Icons.ios_share_rounded, 'Share', () => _share(context)),
    ]);
  }
}

/// "Friend −10%" while a friend's link holds this account.
class FriendDiscountBadge extends StatelessWidget {
  const FriendDiscountBadge({super.key, this.kind = 'word'});
  final String kind;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final s = EconomyMirror.instance.summary;
        final ref = s['referral'];
        if (ref is! Map || ref['held'] != true) return const SizedBox.shrink();
        final cfg = s['config'] is Map ? (s['config'] as Map)['reference'] : null;
        final fd = cfg is Map ? cfg['friendDiscount'] : null;
        final sub = kind == 'subscription' || kind == 'plan';
        final pct = fd is Map ? (sub ? fd['subscriptionPct'] : fd['wordPct']) : null;
        final firstN = fd is Map ? ((fd['wordFirstN'] as num?)?.toInt() ?? 0) : 0;
        final used = (ref['friendWordBuys'] as num?)?.toInt() ?? 0;
        if (pct == null || (!sub && firstN > 0 && used >= firstN)) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFFE4C56A), borderRadius: BorderRadius.circular(999)),
          child: Text('Friend −$pct%', style: const TextStyle(color: NwsbColors.ink, fontSize: 11, fontWeight: FontWeight.w800)),
        );
      },
    );
  }
}

/// Coupon picker + coin slider + the server's quote, then Pay on Google Play.
/// [items] are cart lines: {id, kind, title, price, qty}.
class CheckoutPanel extends StatefulWidget {
  const CheckoutPanel({super.key, required this.items, this.onPaid, this.payLabel = 'Pay on Google Play'});
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic> result)? onPaid;
  final String payLabel;

  @override
  State<CheckoutPanel> createState() => _CheckoutPanelState();
}

class _CheckoutPanelState extends State<CheckoutPanel> {
  Map<String, dynamic>? _q;
  String? _couponId;
  int? _coins; // null = as many as allowed
  int _maxCoins = 0;
  String? _error;
  bool _busy = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _quote(probeMax: true);
  }

  @override
  void didUpdateWidget(covariant CheckoutPanel old) {
    super.didUpdateWidget(old);
    if (old.items.toString() != widget.items.toString()) _quote(probeMax: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Map<String, dynamic> get _req => {
        'kind': 'cart',
        'items': widget.items,
        if (_couponId != null) 'couponId': _couponId,
        if (_coins != null) 'coins': _coins,
      };

  Future<void> _quote({bool probeMax = false}) async {
    if (widget.items.isEmpty) return;
    try {
      if (probeMax) {
        final m = await EconomyApi.call('quote', {'items': widget.items, if (_couponId != null) 'couponId': _couponId});
        _maxCoins = (m['coins'] as num?)?.toInt() ?? 0;
        if (_coins != null && _coins! > _maxCoins) _coins = _maxCoins;
      }
      final q = await EconomyApi.call('quote', _req);
      if (!mounted) return;
      setState(() {
        _q = q;
        _error = null;
      });
    } on EconomyException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _pay() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await PlayCheckout.purchase(_req);
      unawaited(EconomyMirror.instance.refresh());
      if (!mounted) return;
      await celebrate(context, r);
      widget.onPaid?.call(r);
    } on EconomyException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Google Play could not complete the purchase.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _inr(Object? v) {
    final n = (v as num?) ?? 0;
    return n == n.roundToDouble() ? '₹${n.round()}' : '₹${n.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final coupons = (EconomyMirror.instance.summary['coupons'] as List?)?.whereType<Map>().toList() ?? const [];
    final q = _q;
    final usedCoins = (q?['coins'] as num?)?.toInt() ?? 0;
    final shown = _coins ?? usedCoins;
    const label = TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5);
    const value = TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700);
    Widget row(String l, String v, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text(l, style: label)),
            Text(v, style: strong ? value.copyWith(fontSize: 16, color: const Color(0xFFE4C56A)) : value),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (coupons.isNotEmpty) ...[
        DropdownButtonFormField<String?>(
          initialValue: _couponId,
          dropdownColor: const Color(0xFF141820),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Coupon', labelStyle: TextStyle(color: NwsbColors.mist)),
          items: [
            const DropdownMenuItem<String?>(value: null, child: EditableLabel('store_extras.CheckoutPanel', 'No coupon')),
            for (final c in coupons) DropdownMenuItem<String?>(value: '${c['id']}', child: Text('${c['label'] ?? 'Coupon'}')),
          ],
          onChanged: (v) {
            setState(() => _couponId = v);
            _quote(probeMax: true);
          },
        ),
        const SizedBox(height: 8),
      ],
      if (_maxCoins > 0) ...[
        Row(children: [
          EditableImage.asset(NwsbCoinFly.disc, width: 18, height: 18, slot: 'store_extras.CheckoutPanel'),
          const SizedBox(width: 6),
          Expanded(child: Text('Use $shown of $_maxCoins coins', style: label)),
        ]),
        Slider(
          value: shown.clamp(0, _maxCoins).toDouble(),
          min: 0,
          max: _maxCoins.toDouble(),
          divisions: _maxCoins > 100 ? 100 : _maxCoins,
          activeColor: const Color(0xFFE4C56A),
          onChanged: (v) {
            setState(() => _coins = v.round());
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), _quote);
          },
        ),
      ],
      if (q != null) ...[
        row('List price', _inr(q['listINR'])),
        if (((q['linkOffINR'] as num?) ?? 0) > 0) row('Friend discount', '−${_inr(q['linkOffINR'])}'),
        if (((q['couponOffINR'] as num?) ?? 0) > 0) row('Coupon', '−${_inr(q['couponOffINR'])}'),
        if (((q['coinsINR'] as num?) ?? 0) > 0) row('Coins (${q['coins']})', '−${_inr(q['coinsINR'])}'),
        if (((q['absorbedINR'] as num?) ?? 0) > 0) row('NowssB rounds down', '−${_inr(q['absorbedINR'])}'),
        const Divider(color: Color(0x33FFFFFF)),
        row('You pay on Google Play', _inr(q['payINR']), strong: true),
        const SizedBox(height: 4),
        Text('Coins can cover up to ${q['coinCapPct'] ?? 30}% of this order. Play shows the final price with tax.', style: label.copyWith(fontSize: 11)),
      ],
      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(_error!, style: const TextStyle(color: NwsbColors.goldLight)),
      ],
      const SizedBox(height: 12),
      FilledButton(
        onPressed: widget.items.isEmpty || _busy ? null : _pay,
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE4C56A), foregroundColor: NwsbColors.ink, padding: const EdgeInsets.symmetric(vertical: 14)),
        child: Text(_busy ? 'Opening Google Play…' : widget.payLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    ]);
  }
}

/// Small round share control for item cards; opens Copy link / Share.
class ShareChip extends StatelessWidget {
  const ShareChip({super.key, required this.kind, this.id = '', this.title = ''});
  final String kind;
  final String id;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF0B0F16),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title.isEmpty ? 'Share NowssB' : 'Share $title', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const EditableLabel('store_extras.ShareChip', 'Your own link. A friend who buys through it gets a discount, and the sale counts for you.', style: TextStyle(color: Color(0xB3FFFFFF), height: 1.4)),
              const SizedBox(height: 14),
              ShareItemButtons(kind: kind, id: id, title: title, dense: false),
            ]),
          ),
        ),
      ),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: const Color(0x99060C18), shape: BoxShape.circle, border: Border.all(color: const Color(0x40FFFFFF))),
        child: const Icon(Icons.ios_share_rounded, size: 15, color: Colors.white),
      ),
    );
  }
}
