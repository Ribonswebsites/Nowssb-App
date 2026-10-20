// Pop-ups and sheets (spec §6): ONE blur per pop-up (outer wrapper), black
// card inside, lite-glass boxes/pills. Open 220ms easeOutBack, close 160ms.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'cards.dart';
import 'glass_core.dart';
import 'pills_chips.dart';
import 'tokens.dart';

/// Black card inside glass wrapper. This is the planned shared GlassBlackCard.
class GlassBlackCard extends StatelessWidget {
  const GlassBlackCard({super.key, required this.child, this.accent = NTokens.violet, this.onClose});
  final Widget child; final Color accent; final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85),
      child: NGlass(radius: NTokens.rPopupOuter, blur: NTokens.blurSheet, accent: accent, tint: accent, elevation: 1.3,
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(NTokens.rPopupInner),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B0B12), Color(0xFF05050A)]),
              border: Border.all(color: const Color(0x0FFFFFFF))),
          child: Stack(children: [
            SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 20), child: child),
            if (onClose != null) Positioned(right: 8, top: 8, child: IconButton(onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white70))),
          ]))));
}

/// Show a centered glass popup with the spec animation.
Future<T?> showGlassPopup<T>(BuildContext context, {required WidgetBuilder builder, Color accent = NTokens.violet, bool dismissible = true}) {
  HapticFeedback.lightImpact();
  return showGeneralDialog<T>(context: context, barrierDismissible: dismissible, barrierLabel: 'close',
      barrierColor: Colors.black.withValues(alpha: .55), transitionDuration: NTokens.popIn,
      pageBuilder: (ctx, _, __) => SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(16),
          child: Material(type: MaterialType.transparency, child: GlassBlackCard(accent: accent,
              onClose: () => Navigator.pop(ctx), child: builder(ctx)))))),
      transitionBuilder: (_, a, __, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
        return FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: .92, end: 1.0).animate(c), child: child));
      });
}

/// Bottom glass sheet (claim sheet, filters, apply coupon, terms).
Future<T?> showGlassSheet<T>(BuildContext context, {required WidgetBuilder builder, Color accent = NTokens.violet}) =>
    showModalBottomSheet<T>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(10), child: GlassBlackCard(accent: accent,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)))),
              builder(ctx),
            ])))));

/// Ready-made content: Claim sheet ("Claim offer using coins").
class ClaimSheetBody extends StatelessWidget {
  const ClaimSheetBody({super.key, required this.title, required this.points, required this.onClaim});
  final String title; final List<String> points; final VoidCallback onClaim;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final p in points) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle_rounded, color: NTokens.mint, size: 16), const SizedBox(width: 8),
          Expanded(child: Text(p, style: const TextStyle(color: NTokens.textLo, fontSize: 13))),
        ])),
        const SizedBox(height: 12),
        GlassPill(label: 'Claim now', style: PillStyle.white, onTap: onClaim),
      ]);
}

/// "Don't miss out" nudge: two stat boxes + Close (outlined) / Use now (white).
class NudgeBody extends StatelessWidget {
  const NudgeBody({super.key, required this.a, required this.b, required this.onUse});
  final (String, String) a, b; final VoidCallback onUse;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Don't miss out on offers like", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        NGlass(radius: NTokens.rBox, child: IntrinsicHeight(child: Row(children: [
          Expanded(child: _stat(a)), const VerticalDivider(color: Colors.white24), Expanded(child: _stat(b)),
        ]))),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: GlassPill(label: 'Close', style: PillStyle.outlined, onTap: () => Navigator.pop(context))),
          const SizedBox(width: 10),
          Expanded(child: GlassPill(label: 'Use now', style: PillStyle.white, onTap: onUse)),
        ]),
      ]);
  Widget _stat((String, String) s) => Column(children: [
        Text(s.$1, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(s.$2, textAlign: TextAlign.center, style: const TextStyle(color: NTokens.textLo, fontSize: 11)),
      ]);
}

/// Coupon detail popup body.
class CouponDetailBody extends StatelessWidget {
  const CouponDetailBody({super.key, required this.rarity, required this.offer, required this.code, required this.onApply, this.onTerms});
  final Rarity rarity; final String offer, code; final VoidCallback onApply; final VoidCallback? onTerms;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        RarityChip(rarity), const SizedBox(height: 10),
        Text(offer, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        NGlass(radius: NTokens.rBox, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Row(children: [
          Expanded(child: Text(code, style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w800))),
          GlassPill(label: 'Copy', dense: true, icon: Icons.copy_rounded, onTap: () => Clipboard.setData(ClipboardData(text: code))),
        ])),
        const SizedBox(height: 10),
        const InfoBox(title: 'Applies to', value: 'Words, Bundles', color: NTokens.rare),
        const SizedBox(height: 8),
        const InfoBox(title: 'Stacks with coins', value: 'Up to 35%', color: NTokens.gold),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: GlassPill(label: 'View terms', style: PillStyle.outlined, onTap: onTerms)),
          const SizedBox(width: 10),
          Expanded(child: GlassPill(label: 'Apply now', style: PillStyle.white, onTap: onApply)),
        ]),
      ]);
}

/// Glass toast / snackbar.
void showGlassToast(BuildContext context, String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: Colors.transparent, elevation: 0, behavior: SnackBarBehavior.floating,
    content: NGlass(radius: NTokens.rPill, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))));
