/// The hero header that sits on the LEFT half of the Home TV
/// (assets/video/tv-split.mp4 — its left half is black on purpose).
library;

import 'package:flutter/material.dart';

class TvSplitHeader extends StatefulWidget {
  const TvSplitHeader({super.key});

  @override
  State<TvSplitHeader> createState() => _TvSplitHeaderState();
}

class _TvSplitHeaderState extends State<TvSplitHeader> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    // Fade in once the TV is on screen (next frame).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return LayoutBuilder(builder: (context, c) {
      // Type scales off the TV's own width so it reads the same on any phone.
      final u = c.maxWidth / 100;
      const shadow = [Shadow(color: Color(0xCC000000), blurRadius: 10)];
      TextStyle s(double size, FontWeight w, {double ls = 0}) => TextStyle(
            color: Colors.white,
            fontSize: size,
            fontWeight: w,
            letterSpacing: ls,
            height: 1.1,
            shadows: shadow,
          );
      return AnimatedOpacity(
        key: const Key('tv-split-header'),
        opacity: still || _shown ? 1 : 0,
        duration: still ? Duration.zero : const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 1,
            child: Padding(
              padding: EdgeInsets.fromLTRB(6 * u, 4 * u, 2 * u, 4 * u),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('NowssB', style: s(11 * u, FontWeight.w900, ls: -0.5)),
                    SizedBox(height: 1.2 * u),
                    Text('RESONANCE', style: s(3.4 * u, FontWeight.w700, ls: 3.4 * u * 0.45)),
                    SizedBox(height: 2.4 * u),
                    Text('Natural Origin of Word Science',
                        style: s(2.7 * u, FontWeight.w500).copyWith(color: const Color(0xD9FFFFFF))),
                    SizedBox(height: 0.8 * u),
                    Text('FREQUENCIES',
                        style: s(2.5 * u, FontWeight.w700, ls: 2.5 * u * 0.5).copyWith(color: const Color(0xB3FFFFFF))),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
