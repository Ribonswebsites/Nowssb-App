/// Today's Practice — one card. The film is the halo player.
library;

import '../shell/tablet.dart';
import 'package:flutter/material.dart';

class PracticeCarousel extends StatelessWidget {
  const PracticeCarousel({
    super.key,
    required this.playerCard,
    this.onTap,
    this.fashion = false,
    this.aspectRatio = 16 / 9,
    this.height,
  });

  final Widget playerCard;
  final VoidCallback? onTap;
  final bool fashion;
  final double aspectRatio;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (height != null) return SizedBox(height: height, child: playerCard);
    return TabletAspectRatio(aspectRatio: aspectRatio, child: playerCard);
  }
}
