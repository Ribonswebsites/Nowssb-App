/// Live wiring for the designer's door screens (df678da): each picker reads
/// and writes the real [Settings].
library;

import 'package:flutter/material.dart';

import '../../data/settings.dart';
import '../concept/doors/door_background.dart';

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
