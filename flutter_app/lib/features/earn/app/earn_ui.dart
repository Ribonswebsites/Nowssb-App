// Earn UI pieces in Ribon's approved design: frosted meditation card and
// frosted ticket card, on the app's original background video.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

const kEarnVideo = 'assets/video/7e4d709136dc254a_grok_video_2026-07-18-15-53-02_ubjx5b.mp4';
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

class EarnBackground extends StatefulWidget {
  const EarnBackground({super.key, required this.child});
  final Widget child;
  @override
  State<EarnBackground> createState() => _EarnBackgroundState();
}

class _EarnBackgroundState extends State<EarnBackground> {
  VideoPlayerController? _c;

  @override
  void initState() {
    super.initState();
    if (earnNoVideo) return;
    final c = VideoPlayerController.asset(kEarnVideo, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    _c = c;
    c.setLooping(true);
    c.setVolume(0);
    c.initialize().then((_) {
      if (mounted) setState(c.play);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Stack(fit: StackFit.expand, children: [
      if (!earnNoVideo) Image.asset(kEarnPoster, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF14102A))),
      if (earnNoVideo) const ColoredBox(color: Color(0xFF241C4A)),
      if (c != null && c.value.isInitialized)
        FittedBox(fit: BoxFit.cover, child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c))),
      const ColoredBox(color: Color(0x55000000)),
      widget.child,
    ]);
  }
}

/// Frosted translucent glass with a soft white border and large radius.
class Frost extends StatelessWidget {
  const Frost({super.key, required this.child, this.radius = 30, this.padding = const EdgeInsets.all(18), this.onTap, this.tint});
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: r,
            child: Ink(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: r,
                border: Border.all(color: const Color(0x55FFFFFF)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [(tint ?? Colors.white).withValues(alpha: .24), (tint ?? Colors.white).withValues(alpha: .08)],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class WhitePill extends StatelessWidget {
  const WhitePill(this.label, {super.key, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: Material(
          color: Colors.white,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF1B1433), fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ),
        ),
      );
}

class Dots extends StatelessWidget {
  const Dots({super.key, required this.count, required this.index});
  final int count, index;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(color: i == index ? Colors.white : Colors.white38, borderRadius: BorderRadius.circular(3)),
          ),
      ]);
}

/// The approved meditation card: round top, inner frosted panel with bold
/// title, grey body, text link bottom-left, white pill bottom-right, dots.
class MeditationCard extends StatelessWidget {
  const MeditationCard({
    super.key,
    this.photo,
    this.top,
    required this.title,
    this.body,
    this.extra,
    this.link,
    this.onLink,
    required this.cta,
    this.onCta,
    this.dots,
    this.dotIndex = 0,
  });
  final String? photo;
  final Widget? top;
  final String title;
  final String? body;
  final Widget? extra;
  final String? link;
  final VoidCallback? onLink;
  final String cta;
  final VoidCallback? onCta;
  final int? dots;
  final int dotIndex;

  @override
  Widget build(BuildContext context) => Frost(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: const [Spacer(), Icon(Icons.favorite_rounded, color: Colors.white, size: 18)]),
          top ??
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x66FFFFFF), width: 2),
                  image: photo == null ? null : DecorationImage(image: AssetImage(photo!), fit: BoxFit.cover),
                  color: const Color(0x22FFFFFF),
                ),
              ),
          const SizedBox(height: 18),
          Frost(
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: kInk, fontSize: 22, height: 1.15, fontWeight: FontWeight.w800)),
              if (body != null) ...[const SizedBox(height: 8), Text(body!, style: const TextStyle(color: kGrey, fontSize: 12.5, height: 1.4))],
              if (extra != null) ...[const SizedBox(height: 10), extra!],
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: link == null
                      ? const SizedBox()
                      : GestureDetector(onTap: onLink, child: Text(link!, style: const TextStyle(color: kGrey, fontSize: 12.5))),
                ),
                WhitePill(cta, onTap: onCta),
              ]),
              if (dots != null) ...[const SizedBox(height: 10), Center(child: Dots(count: dots!, index: dotIndex))],
            ]),
          ),
        ]),
      );
}

/// Frosted ticket card (approved coupon list card layout).
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.leading, required this.pill, required this.label, required this.headline, required this.link, this.accent = kMint, this.onTap, this.badge});
  final Widget leading;
  final String pill, label, headline, link;
  final String? badge;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Frost(
        radius: 22,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(children: [
          SizedBox.square(dimension: 60, child: leading),
          const SizedBox(width: 12),
          Container(width: 1, height: 60, color: Colors.white24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: accent.withValues(alpha: .25), border: Border.all(color: accent.withValues(alpha: .6))),
                  child: Text(pill.toUpperCase(), style: TextStyle(color: Color.lerp(accent, Colors.white, .5), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: const Color(0xFFE879F9)),
                    child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: kGrey, fontSize: 12)),
              Text(headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kInk, fontSize: 17, fontWeight: FontWeight.w800)),
              Text('$link >', style: const TextStyle(color: kMint, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      );
}

class RoundPhoto extends StatelessWidget {
  const RoundPhoto(this.asset, {super.key});
  final String asset;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x66FFFFFF), width: 2),
          image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
        ),
      );
}

class RoundIcon extends StatelessWidget {
  const RoundIcon(this.icon, {super.key, this.color = kMint, this.text});
  final IconData icon;
  final Color color;
  final String? text;
  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2), color: color.withValues(alpha: .15)),
        child: text != null
            ? FittedBox(child: Padding(padding: const EdgeInsets.all(8), child: Text(text!, style: const TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 18))))
            : Icon(icon, color: kInk),
      );
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
