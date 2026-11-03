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

/// Type a coupon code and add it to the account. Shows what it gave, or
/// why it did not work, instead of failing silently.
class _CodeBox extends StatefulWidget {
  const _CodeBox();
  @override
  State<_CodeBox> createState() => _CodeBoxState();
}

class _CodeBoxState extends State<_CodeBox> {
  final _code = TextEditingController();
  var _busy = false;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final raw = _code.text.trim().toUpperCase();
    if (raw.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final r = await runReward(context, () => EconomyApi.call('claimTicket', {'code': raw}), title: 'Coupon');
    if (!mounted) return;
    setState(() => _busy = false);
    if (r == null) return;
    _code.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(couponClaimNote(r))));
    await EconomyMirror.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return GlassWrapper(
      radius: 18,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('coupon-code-field'),
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _add(),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Enter coupon code', hintStyle: TextStyle(color: Color(0x66FFFFFF)), border: InputBorder.none),
            ),
          ),
          TextButton(
            onPressed: _busy || _code.text.trim().isEmpty ? null : _add,
            child: Text(_busy ? 'Adding…' : 'Add coupon', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
