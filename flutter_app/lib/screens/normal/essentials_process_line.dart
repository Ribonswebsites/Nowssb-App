import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// The same raised 18px marker and 3px connector language used by Essentials,
/// laid out horizontally so it can track the horizontal routine carousel.
class NmEssentialsProcessLine extends StatelessWidget {
  const NmEssentialsProcessLine(
      {super.key, required this.active, this.glass = false});

  final int active;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 6; i++) ...[
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: i == active
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFB44D), Color(0xFFFF8A3D)],
                    )
                  : null,
              color: i == active
                  ? null
                  : (glass ? const Color(0xCCFFFFFF) : const Color(0xFFECEEF2)),
              border: glass && i != active
                  ? Border.all(color: Colors.white, width: 1.2)
                  : null,
              boxShadow: i == active
                  ? const [
                      BoxShadow(
                          color: Color(0x339C6B30),
                          blurRadius: 7,
                          spreadRadius: 3),
                      BoxShadow(
                          color: Color(0x55000000),
                          offset: Offset(3, 3),
                          blurRadius: 6),
                      BoxShadow(
                          color: Colors.white,
                          offset: Offset(-2, -2),
                          blurRadius: 6),
                    ]
                  : (glass ? null : NwsbShadows.raisedXs),
            ),
          ),
          if (i != 5)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                color:
                    glass ? const Color(0x99FFFFFF) : const Color(0xFFC7CDD9),
              ),
            ),
        ],
      ],
    );
  }
}
