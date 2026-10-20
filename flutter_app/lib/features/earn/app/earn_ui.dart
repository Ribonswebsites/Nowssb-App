// Earn UI pieces in Ribon's approved design: frosted meditation card and
// frosted ticket card, on the app's original background video.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../nowssb_ui/nowssb_ui.dart';

export '../../../nowssb_ui/nowssb_ui.dart';

const kEarnPoster = 'assets/video/7e4d709136dc254a_grok_video_2026-07-18-15-53-02_ubjx5b-poster.webp';

/// Round photos: the app's own video posters (no new art).
const kEarnPhotos = [
  'assets/video/28eb0c85b5fd748e_grok_video_2026-07-24-15-42-55_lknomr-poster.webp',
  'assets/video/415dd447da33973b_grok_video_2026-07-30-14-35-05_q3tyzk-poster.webp',
  'assets/video/beaf11ea10561d43_grok_video_2026-07-30-15-35-40_xwm1ei-poster.webp',
  kEarnPoster,
];

/// Tests have no video plugin; they set this to true.
bool earnNoVideo = false;

const kInk = Colors.white;
const kGrey = Color(0xB3FFFFFF);
const kMint = Color(0xFF7FE7D6);

/// The app's original background (shared kit [NAppBackdrop], the same video
/// as every page). The old Earn-only video had a warm sunset on its right
/// side that the cards' backdrop blur smeared into a yellow-red blob.
class EarnBackground extends StatelessWidget {
  const EarnBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const NAppBackdrop(),
        const ColoredBox(color: Color(0x40000000)),
        child,
      ]);
}

/// Fade + rise in, staggered by [index]. Instant under reduced motion.
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + 60 * index.clamp(0, 8)),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: c)),
      child: child,
    );
  }
}

/// Progress ring with a value in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, required this.color, required this.center, this.size = 60});
  final double value;
  final Color color;
  final Widget center;
  final double size;
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: still ? value : 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Stack(alignment: Alignment.center, children: [
          SizedBox.expand(
              child: CircularProgressIndicator(
                  value: v, strokeWidth: 5, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(color))),
          center,
        ]),
      ),
    );
  }
}

/// Money in the balance's own currency, formatted for the user's locale.
/// Empty currency means the server sent none: show the number only.
String earnMoney(BuildContext context, num amount, String currency) {
  final locale = Localizations.maybeLocaleOf(context)?.toString();
  if (currency.isEmpty) return NumberFormat.decimalPattern(locale).format(amount);
  return NumberFormat.simpleCurrency(locale: locale, name: currency).format(amount);
}

/// Pop-up in the approved card style.
Future<T?> showEarnCard<T>(BuildContext context, Widget Function(BuildContext) builder) => showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black54,
      pageBuilder: (ctx, _, __) => SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            child: Material(type: MaterialType.transparency, child: builder(ctx)),
          ),
        ),
      ),
    );

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Text(text.toUpperCase(), style: const TextStyle(color: kMint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
      );
}

/// Ticket chip colour for an Earn ticket kind (the kit chip shows the rarity name).
Rarity earnRarity(String kind) => switch (kind) {
      'Money earned' || 'Payout' => Rarity.legendary,
      'Invite' || 'Sell' => Rarity.epic,
      'Direct' || 'Share' || 'Tasks' => Rarity.rare,
      _ => Rarity.common,
    };
