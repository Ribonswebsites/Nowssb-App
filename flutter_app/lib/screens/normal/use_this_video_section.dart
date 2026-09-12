import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/tokens.dart';
import 'glassmorphism_theme.dart';

/// Three circular destinations shown directly below Essentials on both homes.
class NmUseThisVideoSection extends StatelessWidget {
  const NmUseThisVideoSection({super.key, this.fashion = false});

  final bool fashion;

  static const _items = <(String, String, String)>[
    ('Player', 'assets/player/t-cosmic.jpg', 'image'),
    ('Sentence', 'assets/icons/icon_01.svg', 'svg'),
    ('Library', 'assets/player/lgp-library.png', 'image'),
  ];

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context) || fashion;
    final foreground = glass ? Colors.white : NwsbColors.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: glass ? const Color(0x66FFFFFF) : NwsbColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: glass
              ? Border.all(color: const Color(0xE6FFFFFF), width: 1.4)
              : null,
          boxShadow: glass
              ? null
              : const [
                  BoxShadow(
                      color: Color(0x24000000),
                      offset: Offset(7, 7),
                      blurRadius: 16),
                  BoxShadow(
                      color: Color(0xF7FFFFFF),
                      offset: Offset(-5, -5),
                      blurRadius: 12),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Use This Video',
                style: TextStyle(
                    color: foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final item in _items)
                  _CircleDestination(
                    title: item.$1,
                    asset: item.$2,
                    svg: item.$3 == 'svg',
                    glass: glass,
                    foreground: foreground,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleDestination extends StatelessWidget {
  const _CircleDestination({
    required this.title,
    required this.asset,
    required this.svg,
    required this.glass,
    required this.foreground,
  });

  final String title;
  final String asset;
  final bool svg;
  final bool glass;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: glass ? const Color(0x80FFFFFF) : const Color(0xFFECEEF2),
            border: glass ? Border.all(color: Colors.white, width: 1.5) : null,
            boxShadow: glass ? null : NwsbShadows.raised,
          ),
          child: ClipOval(
            child: svg
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(asset, fit: BoxFit.contain),
                  )
                : Image.asset(asset, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Text(title,
            style: TextStyle(
                color: foreground, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
