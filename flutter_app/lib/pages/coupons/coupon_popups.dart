/// Pop-up shell (spec 6) and the Coupon Detail / filter / terms pop-ups.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../nowssb_ui/nowssb_ui.dart';
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
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Material(
                type: MaterialType.transparency,
                child: GlassBlackCard(
                  accent: accent,
                  onClose: () => Navigator.of(context).pop(),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 36),
                      child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                    ),
                    const SizedBox(height: 12),
                    ...body,
                    if (footer.isNotEmpty) ...[const SizedBox(height: 14), ...footer],
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

Widget _tinted(String head, String text, Color tint) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NGlass(
        radius: NTokens.rBox,
        accent: tint,
        tint: tint,
        elevation: .3,
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(head, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
      ),
    );

/// Full-width violet primary pill (kit solid style).
Widget primaryPill(String label, VoidCallback onTap, {Key? key}) =>
    SizedBox(key: key, width: double.infinity, child: GlassPill(label: label, style: PillStyle.solid, onTap: onTap));

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
    Align(alignment: Alignment.centerLeft, child: RarityChip(Rarity.values[c.rarity.index])),
    const SizedBox(height: 10),
    Text(c.offer, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
    Text(c.scope, style: const TextStyle(color: Colors.white60)),
    const SizedBox(height: 12),
    NGlass(
      radius: NTokens.rBox,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        Expanded(child: Text(c.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.2))),
        GlassPill(
          label: 'Copy',
          dense: true,
          icon: Icons.copy_rounded,
          onTap: () {
            Clipboard.setData(ClipboardData(text: c.code));
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Code copied')));
          },
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
    TextButton(onPressed: () => showCouponTerms(context), child: const Text('View terms', style: TextStyle(color: NTokens.textLo))),
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
        child: NGlass(
          radius: NTokens.rHero,
          blur: NTokens.blurSheet,
          padding: const EdgeInsets.all(16),
          child: Material(type: MaterialType.transparency, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
            for (final o in options)
              CheckboxListTile(
                value: pick.contains(o),
                title: Text(o, style: const TextStyle(color: Colors.white)),
                activeColor: NTokens.violet,
                checkColor: Colors.white,
                onChanged: (v) => set(() => v == true ? pick.add(o) : pick.remove(o)),
              ),
            primaryPill('Show coupons', () => Navigator.of(ctx).pop(pick)),
          ])),
        ),
      ),
    ),
  );
}
