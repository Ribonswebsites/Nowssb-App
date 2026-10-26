/// Live wiring for the designer's door screens (df678da): each picker reads
/// and writes the real [Settings].
library;

import 'package:flutter/material.dart';

import '../../data/settings.dart';
import '../concept/doors/door_background.dart';
import '../concept/doors/door_start_art.dart';

/// Background door → film picker. Writes Settings.fashionVideoIndex and the
/// Fashion Plus motion flag.
class DoorBackgroundScreen extends StatelessWidget {
  const DoorBackgroundScreen({super.key});

  static String _poster(String mp4) => mp4.replaceFirst(RegExp(r'\.mp4$'), '-poster.webp');

  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => DoorBackgroundPicker(
        videos: [
          for (var i = 0; i < Settings.fashionVideos.length; i++)
            DoorVideo(
                id: '$i',
                name: Settings.fashionVideoNames[i],
                poster: _poster(Settings.fashionVideos[i]),
                asset: Settings.fashionVideos[i]),
        ],
        selectedId: '${s.fashionVideoIndex}',
        motionOn: s.fashionPlus,
        onPickVideo: (id) => s.setFashionVideo(int.parse(id)),
        onToggleMotion: s.setFashionPlus,
        onBack: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// Start art door → still picker. "Black" (-1) clears the saved still.
class DoorStartArtScreen extends StatelessWidget {
  const DoorStartArtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => DoorStartArtPicker(
        stills: [
          const DoorStill(id: '-1', name: 'NowssB Black'),
          for (var i = 0; i < Settings.fashionImages.length; i++)
            DoorStill(id: '$i', name: Settings.fashionImageName(i), asset: Settings.fashionImages[i]),
        ],
        selectedId: '${s.fashionImageIndex}',
        onPickImage: (id) {
          final i = int.parse(id);
          s.setFashionImage(i < 0 ? null : i);
        },
        onBack: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
