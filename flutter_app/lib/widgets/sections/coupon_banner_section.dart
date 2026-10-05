/// Auto-sliding NowssB coupon ticket banner (MK-1).
///
/// Dark panel, gold glow, ticket notches, CTA, page dots. Reads
/// [SectionConfig] when provided; otherwise falls back to [kWideCoupons].
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../admin/template/editable.dart';
import '../../features/economy/coupon_tickets.dart';
import '../../theme/tokens.dart';
import 'section_config.dart';

/// One slide shown inside the ticket.
class _Slide {
  const _Slide({
    required this.id,
    required this.kicker,
    required this.offer,
    required this.subtitle,
    required this.ctaLabel,
    this.badge = 'LIMITED',
  });

  final String id;
  final String kicker;
  final String offer;
  final String subtitle;
  final String ctaLabel;
  final String badge;
}

List<_Slide> _slidesFromConfig(SectionConfig? config) {
  final items = config?.items ?? const <SectionMediaItem>[];
  if (items.isNotEmpty) {
    final cap = config?.behavior.itemCount;
    final list = cap == null ? items : items.take(cap).toList();
    return [
      for (final it in list)
        _Slide(
          id: it.id,
          kicker: (it.meta['kicker'] as String?)?.trim().isNotEmpty == true
              ? '${it.meta['kicker']}'
              : 'NOWSSB COUPON',
          offer: (it.title ?? '').trim().isEmpty ? 'OFFER' : it.title!.trim(),
          subtitle: (it.subtitle ?? '').trim().isEmpty
              ? 'Catalogue prize · not cash'
              : it.subtitle!.trim(),
          ctaLabel: (it.ctaLabel ?? '').trim().isEmpty ? 'Scratch now' : it.ctaLabel!.trim(),
          badge: (it.meta['badge'] as String?)?.trim().isNotEmpty == true
              ? '${it.meta['badge']}'
              : 'LIMITED',
        ),
    ];
  }
  // First 6 non-chance wide coupons (kWideCoupons has no chance flag; take head).
  final wide = kWideCoupons.take(config?.behavior.itemCount ?? 6).toList();
  return [
    for (final c in wide)
      _Slide(
        id: c.code,
        kicker: c.kicker,
        offer: '${c.big}${c.mark} ${c.side}'.trim(),
        subtitle: c.line.isNotEmpty ? c.line : c.banner,
        ctaLabel: 'Scratch now',
        badge: c.kicker.contains('EPIC') ? 'EPIC' : 'LIMITED',
      ),
  ];
}

/// Ticket-shaped coupon banner that auto-slides NowssB offers.
class CouponBannerSection extends StatefulWidget {
  const CouponBannerSection({
    super.key,
    this.config,
    this.onCta,
  });

  final SectionConfig? config;
  final VoidCallback? onCta;

  @override
  State<CouponBannerSection> createState() => _CouponBannerSectionState();
}

class _CouponBannerSectionState extends State<CouponBannerSection> {
  late final PageController _page;
  Timer? _timer;
  var _index = 0;
  var _userPaging = false;

  List<_Slide> get _slides => _slidesFromConfig(widget.config);

  bool get _autoplay {
    final b = widget.config?.behavior;
    // Standalone (no config) always autoplays; config opts in via autoplay.
    if (b == null) return true;
    return b.autoplay;
  }

  int get _autoplayMs {
    final ms = widget.config?.behavior.autoplayMs ?? 4000;
    return ms.clamp(1800, 20000);
  }

  bool get _loop => widget.config?.behavior.loop ?? true;

  @override
  void initState() {
    super.initState();
    final start = widget.config?.behavior.startIndex ?? 0;
    final n = _slides.length;
    _index = n == 0 ? 0 : start.clamp(0, n - 1);
    _page = PageController(initialPage: _index);
    _armTimer();
  }

  @override
  void didUpdateWidget(covariant CouponBannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _armTimer();
    }
  }

  void _armTimer() {
    _timer?.cancel();
    _timer = null;
    if (!_autoplay) return;
    _timer = Timer.periodic(Duration(milliseconds: _autoplayMs), (_) {
      if (!mounted || _userPaging) return;
      if (!TickerMode.valuesOf(context).enabled) return;
      if (!_page.hasClients) return;
      final n = _slides.length;
      if (n <= 1) return;
      final next = _index + 1;
      if (next >= n) {
        if (!_loop) return;
        _page.animateToPage(0, duration: const Duration(milliseconds: 480), curve: Curves.easeOutCubic);
      } else {
        _page.animateToPage(next, duration: const Duration(milliseconds: 480), curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  Color get _glow {
    final raw = widget.config?.style.glowColor;
    if (raw != null) return Color(raw);
    return const Color(0x66E8A23A);
  }

  Color get _accent {
    final raw = widget.config?.style.accent;
    if (raw != null) return Color(raw);
    return const Color(0xFFE8A23A);
  }

  double get _radius => widget.config?.layout.radius ?? 18;

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    if (slides.isEmpty) return const SizedBox.shrink();

    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: ColoredBox(
        color: const Color(0xFF071018),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _WavePainter())),
            // Soft gold glow behind the ticket area.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.05),
                      radius: 0.85,
                      colors: [
                        _glow.withValues(alpha: 0.35),
                        _glow.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollStartNotification && n.dragDetails != null) {
                  _userPaging = true;
                } else if (n is ScrollEndNotification) {
                  _userPaging = false;
                }
                return false;
              },
              child: SizedBox(
                height: widget.config?.layout.height ?? 248,
                child: PageView.builder(
                  controller: _page,
                  itemCount: slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _TicketPage(
                    slide: slides[i],
                    sectionId: widget.config?.id ?? 'coupon_banner',
                    accent: _accent,
                    onCta: widget.onCta,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          panel,
          if (slides.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final on = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: on ? 16 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: on ? Colors.white : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _TicketPage extends StatelessWidget {
  const _TicketPage({
    required this.slide,
    required this.sectionId,
    required this.accent,
    this.onCta,
  });

  final _Slide slide;
  final String sectionId;
  final Color accent;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final slot = '$sectionId.${slide.id}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EditableLabel(
                '$slot.brand',
                'NOWSSB',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              const Text('✦', style: TextStyle(color: NwsbColors.goldLight, fontSize: 14)),
              const SizedBox(width: 8),
              EditableLabel(
                '$slot.brandSub',
                'COUPONS',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Glow halo behind the ticket.
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipPath(
              clipper: _TicketClip(),
              child: ColoredBox(
                color: const Color(0xFF0C0C0C),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: EditableLabel(
                          '$slot.kicker',
                          slide.kicker,
                          style: const TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      EditableLabel(
                        '$slot.badge',
                        slide.badge,
                        style: const TextStyle(
                          color: Color(0xFFE23B3B),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      EditableLabel(
                        '$slot.offer',
                        slide.offer,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accent,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      EditableLabel(
                        '$slot.subtitle',
                        slide.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: editModeOn(context) ? null : onCta,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EditableLabel(
                    '$slot.cta',
                    slide.ctaLabel,
                    style: const TextStyle(
                      color: Color(0xFF1A1206),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF1A1206)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notch = 12.0;
    final mid = size.height / 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)));
    path.addOval(Rect.fromCircle(center: Offset(0, mid), radius: notch));
    path.addOval(Rect.fromCircle(center: Offset(size.width, mid), radius: notch));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x33E8D5A3);
    for (var i = 0; i < 5; i++) {
      final path = Path();
      final y = size.height * (0.15 + i * 0.16);
      path.moveTo(0, y);
      path.quadraticBezierTo(size.width * 0.25, y - 28, size.width * 0.5, y);
      path.quadraticBezierTo(size.width * 0.75, y + 28, size.width, y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
