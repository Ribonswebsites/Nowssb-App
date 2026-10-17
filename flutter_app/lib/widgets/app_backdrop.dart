/// Every primary page uses the profile film.
library;

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: NwsbColors.deep),
        NwsbVideo(
          asset: 'assets/video/subscription-bg.mp4',
          priority: ClipPriority.feature,
          autoplay: true,
          loop: true,
          slot: 'app_backdrop.AppBackdrop',
        ),
      ],
    );
  }
}