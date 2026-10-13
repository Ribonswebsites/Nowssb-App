/// Page-local glass pieces. Replace with Bug Hunter's GlassWrapper kit
/// (spec 14.2) once it is on main; APIs kept small for an easy swap.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'signature_models.dart';
import 'tilt_shine.dart';

const kGold = Color(0xFFE8C46A);
const kViolet = Color(0xFF8B7CF6);

Color rarityGlow(Rarity r) => const [
      Color(0xFF9FB3C8),
      Color(0xFF5EA8FF),
      Color(0xFFB57CFF),
      Color(0xFFFFC857),
    ][r.index];

class SigGlass extends StatelessWidget {
  const SigGlass({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.glow});
  final Widget child;
  final EdgeInsets padding;
  final Color? glow;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [if (glow != null) BoxShadow(color: glow!.withValues(alpha: 0.35), blurRadius: 24)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: child,
            ),
          ),
        ),
      );
}

/// Tall portrait premium card with gold inner frame and rarity glow.
class SignatureCard extends StatelessWidget {
  const SignatureCard({super.key, required this.word, required this.onTap, this.effects = true});
  final bool effects;
  final SignatureWord word;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final glow = rarityGlow(word.rarity);
    return Semantics(
      button: true,
      label: '${word.word}, ${word.rarity.label}${word.locked ? ', locked' : ''}',
      child: GestureDetector(
        key: ValueKey('sig-card-${word.id}'),
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 3 / 4.6,
          child: TiltShine(
            enabled: effects && !word.locked,
            child: SigGlass(
            glow: glow,
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kGold.withValues(alpha: 0.7), width: 1.2),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.rarity.label.toUpperCase(),
                      style: TextStyle(color: glow, fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Center(
                    child: word.locked
                        ? const Icon(Icons.lock_rounded, color: kGold, size: 40)
                        : Text(word.word,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Text(word.locked ? _dropLabel(word.dropAt) : word.sound,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  const SizedBox(height: 8),
                  _PriceStrip(word: word),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}

String _dropLabel(DateTime? d) =>
    d == null ? 'Upcoming drop' : 'Drops ${d.day}/${d.month}/${d.year}';

class _PriceStrip extends StatelessWidget {
  const _PriceStrip({required this.word});
  final SignatureWord word;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (word.owned ? kViolet : kGold).withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          word.owned ? 'Collected' : '${word.priceCoins} coins',
          style: TextStyle(color: word.owned ? Colors.white : kGold, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
}
