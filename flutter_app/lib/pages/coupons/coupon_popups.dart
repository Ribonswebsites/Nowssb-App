/// Pop-up shell (spec 6) and the Coupon Detail / filter / terms pop-ups.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'coupon_models.dart';
import 'coupons_glass.dart';

Future<T?> showCouponPopup<T>(BuildContext context, {required String title, required Color accent, required List<Widget> body, List<Widget> footer = const []}) {
  HapticFeedback.lightImpact();
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => _PopupShell(title: title, accent: accent, body: body, footer: footer),
    transitionBuilder: (ctx, a, _, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(c), child: child));
    },
  );
}

class _PopupShell extends StatelessWidget {
  const _PopupShell({required this.title, required this.accent, required this.body, required this.footer});
  final String title;
  final Color accent;
  final List<Widget> body, footer;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.85;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: h, maxWidth: 440),
            child: Material(
              type: MaterialType.transparency,
              child: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36),
                        gradient: LinearGradient(colors: [accent.withValues(alpha: 0.30), accent.withValues(alpha: 0.18)]),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B0B12), Color(0xFF05050A)]),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Row(children: [
                            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
                            Semantics(
                              button: true,
                              label: 'Close',
                              child: InkResponse(
                                onTap: () => Navigator.of(context).pop(),
                                child: CircleAvatar(radius: 16, backgroundColor: Colors.white.withValues(alpha: 0.12), child: const Icon(Icons.close, size: 18, color: Colors.white)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Flexible(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: body))),
                          if (footer.isNotEmpty) ...[const SizedBox(height: 14), ...footer],
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _tinted(String head, String text, Color tint) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CouponGlass(
        radius: 18,
        tint: tint,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(head, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
      ),
    );

Widget primaryPill(String label, VoidCallback onTap, {Key? key}) => CouponGlass(
      key: key,
      radius: 26,
      padding: EdgeInsets.zero,
      tint: kCouponViolet,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
        ),
      ),
    );

const kCouponTerms = [
  'Each coupon is valid until the date shown.',
  'One coupon per order.',
  'Coupons are non-transferable and have no cash value.',
  'Coins can cover at most 35% of a price (cap depends on the price band).',
  'Some offers depend on your region.',
  'Google Play fees and taxes may apply to paid coupons.',
  'NowssB can change or end offers.',
];

Future<void> showCouponTerms(BuildContext context) => showCouponPopup(context,
    title: 'Terms & Disclaimers', accent: kCouponViolet, body: [for (final t in kCouponTerms) _tinted('Rule', t, kCouponViolet)]);

Future<void> showCouponDetail(BuildContext context, NwCoupon c, {VoidCallback? onApply}) {
  final a = rarityAccent(c.rarity);
  return showCouponPopup(context, title: 'Coupon details', accent: a, body: [
    Align(
      alignment: Alignment.centerLeft,
      child: CouponGlass(radius: 14, tint: a, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: Text(rarityName(c.rarity), style: const TextStyle(color: Colors.white, fontSize: 12))),
    ),
    const SizedBox(height: 10),
    Text(c.offer, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
    Text(c.scope, style: const TextStyle(color: Colors.white60)),
    const SizedBox(height: 12),
    CouponGlass(
      radius: 18,
      tint: a,
      child: Row(children: [
        Expanded(child: Text(c.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: c.code));
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Code copied')));
          },
          child: const Text('Copy'),
        ),
      ]),
    ),
    const SizedBox(height: 8),
    _tinted('Applies to', c.category, a),
    _tinted('Stacks with coins', 'Up to 35% of the price', a),
    _tinted('Expires in', '${c.expiresInDays} days', a),
  ], footer: [
    primaryPill('Apply now', () {
      Navigator.of(context).pop();
      onApply?.call();
    }),
    TextButton(onPressed: () => showCouponTerms(context), child: const Text('View terms', style: TextStyle(color: Colors.white70))),
  ]);
}

/// Multi-select glass bottom sheet for the filter chips.
Future<Set<String>?> showCouponFilter(BuildContext context, String title, List<String> options, Set<String> selected) {
  final pick = {...selected};
  return showModalBottomSheet<Set<String>>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: const EdgeInsets.all(12),
        child: CouponGlass(
          lite: false,
          radius: 28,
          tint: kCouponViolet,
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
            for (final o in options)
              CheckboxListTile(
                value: pick.contains(o),
                title: Text(o, style: const TextStyle(color: Colors.white)),
                onChanged: (v) => set(() => v == true ? pick.add(o) : pick.remove(o)),
              ),
            primaryPill('Show coupons', () => Navigator.of(ctx).pop(pick)),
          ]),
        ),
      ),
    ),
  );
}
