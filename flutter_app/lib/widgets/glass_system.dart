/// Heavy frosted glass, the four card families, the strip banner, the
/// thinking-orb loader and the black phone guide.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'app_thinking_loader.dart';

bool nwsbReduce(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

class GlassWrapper extends StatelessWidget {
  const GlassWrapper({
    super.key,
    required this.child,
    this.radius = 22,
    this.accent = kTileViolet,
    this.blur = false,
    this.padding = const EdgeInsets.all(12),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  final Widget child;
  final double radius;
  final Color accent;
  final bool blur;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = nwsbReduce(context);
    final useBlur = blur && !reduce;
    final r = BorderRadius.circular(radius);
    final fill = Color.lerp(Colors.white.withValues(alpha: kGlassFill), accent.withValues(alpha: 0.22), 0.45)!;
    Widget pane = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: useBlur ? 0.16 : 0.22), fill],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: child,
    );
    if (useBlur) {
      pane = ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kGlassBlurLarge, sigmaY: kGlassBlurLarge),
          child: pane,
        ),
      );
    } else {
      pane = ClipRRect(borderRadius: r, child: pane);
    }
    pane = Padding(padding: margin, child: pane);
    if (onTap == null) return pane;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap!();
      },
      child: pane,
    );
  }
}

class GlassCardA extends StatelessWidget {
  const GlassCardA({super.key, required this.title, required this.line, this.onNext});
  final String title;
  final String line;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return GlassWrapper(
      radius: 28,
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [kTileViolet, kTilePink])),
            alignment: Alignment.center,
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(line, maxLines: 2, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
              ],
            ),
          ),
          GlassWrapper(
            radius: 999,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onTap: onNext,
            child: const Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class GlassCardB extends StatelessWidget {
  const GlassCardB({super.key, required this.title, required this.line, required this.action, this.onTap, this.fresh = false});
  final String title;
  final String line;
  final String action;
  final VoidCallback? onTap;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    return GlassWrapper(
      radius: 24,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xFF2A1B4D), Color(0xFF7B4DFF)]),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (fresh)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF2874F0), borderRadius: BorderRadius.circular(8)),
                    child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                const Icon(Icons.confirmation_number, color: Colors.white),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0x00FFFFFF)]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Text(line, style: const TextStyle(color: Color(0xFF5C5C5C), fontSize: 12)),
                const SizedBox(height: 8),
                GlassWrapper(
                  radius: 999,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(999)),
                    child: Text(action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlassCardD extends StatelessWidget {
  const GlassCardD({super.key, required this.name, required this.offer, required this.color, this.onTap});
  final String name;
  final String offer;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 128,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(child: ColoredBox(color: color, child: const Center(child: Icon(Icons.auto_awesome, color: Colors.white)))),
            Container(
              width: double.infinity,
              color: const Color(0xE605050A),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(offer, style: const TextStyle(color: kTileGold, fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StripBanner extends StatelessWidget {
  const StripBanner({super.key, required this.title, required this.line, this.onTap});
  final String title;
  final String line;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassWrapper(
      radius: 32,
      blur: true,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text(line, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class NowssbLoader {
  static Future<T> run<T>(BuildContext context, Future<T> future) async {
    show(context);
    try {
      return await future;
    } finally {
      hide(context);
    }
  }

  static void show(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x59000000),
      pageBuilder: (_, __, ___) => const Center(child: _LoaderPill()),
    );
  }

  static void hide(BuildContext context) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }
}

class _LoaderPill extends StatelessWidget {
  const _LoaderPill();
  @override
  Widget build(BuildContext context) {
    return GlassWrapper(
      radius: 999,
      blur: true,
      padding: const EdgeInsets.fromLTRB(10, 10, 22, 10),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 56, height: 56, child: AppThinkingLoader(size: 56, blackCircle: false)),
          SizedBox(width: 12),
          Text('Loading, please wait', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class PageGuide {
  static Future<void> show(BuildContext context, {required String title, required List<String> lines}) {
    return showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _Guide(title: title, lines: lines),
    );
  }
}

class _Guide extends StatefulWidget {
  const _Guide({required this.title, required this.lines});
  final String title;
  final List<String> lines;
  @override
  State<_Guide> createState() => _GuideState();
}

class _GuideState extends State<_Guide> {
  var _i = 0;
  @override
  Widget build(BuildContext context) {
    final last = _i >= widget.lines.length - 1;
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
            ),
            const Spacer(),
            Container(
              width: MediaQuery.sizeOf(context).width * 0.62,
              height: MediaQuery.sizeOf(context).height * 0.52,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(36)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: ColoredBox(
                  color: const Color(0xFF0B0B12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 12),
                        Text(widget.lines[_i], textAlign: TextAlign.center, style: const TextStyle(color: Color(0xCCFFFFFF), height: 1.35)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var n = 0; n < widget.lines.length; n++)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: n == _i ? Colors.white : Colors.white24),
                  ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: const StadiumBorder()),
                  onPressed: () {
                    if (last) {
                      Navigator.pop(context);
                    } else {
                      setState(() => _i++);
                    }
                  },
                  child: Text(last ? 'Got it' : 'Next', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip all guides', style: TextStyle(color: Colors.white70))),
          ],
        ),
      ),
    );
  }
}
