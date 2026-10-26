/// Live wiring for the designer's door screens (df678da): each picker reads
/// and writes the real [Settings].
library;

import 'package:flutter/material.dart';

import '../../data/settings.dart';
import '../quick_access.dart';
import '../concept/doors/door_access.dart';
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

/// Per-feature rolodex art (local, text-free posters) and socket icons.
const _accessArt = <String, String>{
  'connect': 'assets/video/nm-calm-clouds-poster.webp',
  'practice': 'assets/video/practice-halo-poster.webp',
  'library': 'assets/video/player-box-wave-poster.webp',
  'store': 'assets/video/player-box-liquid-poster.webp',
  'profile': 'assets/video/normal-glass-background-poster.webp',
  'progress': 'assets/video/my-progress-scene-1-poster.webp',
  'wordscience': 'assets/video/practice-orb-poster.webp',
  'meaningstore': 'assets/video/nm-calm-stream-poster.webp',
  'search': 'assets/video/earth-morning-poster.webp',
  'cart': 'assets/video/earth-afternoon-poster.webp',
  'wishlist': 'assets/video/player-aura-bg-poster.webp',
  'routines': 'assets/video/earth-morning-poster.webp',
  'chat': 'assets/hero-curve/listen.webp',
  'ai': 'assets/video/orb-loop-poster.webp',
  'streak': 'assets/video/earth-evening-poster.webp',
  'journal': 'assets/hero-curve/stillness.webp',
  'settings': 'assets/video/player-box-rings-poster.webp',
  'everything': 'assets/video/hero-bg-poster.webp',
};
const _accessIcon = <String, IconData>{
  'connect': Icons.people_outline,
  'practice': Icons.mic_none_rounded,
  'library': Icons.library_music_outlined,
  'store': Icons.storefront_outlined,
  'profile': Icons.person_outline,
  'progress': Icons.insights_outlined,
  'wordscience': Icons.science_outlined,
  'meaningstore': Icons.menu_book_outlined,
  'search': Icons.search,
  'cart': Icons.shopping_cart_outlined,
  'wishlist': Icons.favorite_border,
  'routines': Icons.event_repeat,
  'chat': Icons.chat_bubble_outline,
  'ai': Icons.auto_awesome,
  'streak': Icons.local_fire_department_outlined,
  'journal': Icons.edit_note,
  'settings': Icons.settings_outlined,
  'everything': Icons.apps,
};

/// Access door → socket bar + rolodex. Features are QuickAccessScreen's real
/// list; writes Settings nav slots (nwsb_nav_slots).
class DoorAccessScreen extends StatelessWidget {
  const DoorAccessScreen({super.key});

  static List<DoorFeature> get features => [
        for (final f in quickAccessFeatures)
          DoorFeature(
              id: f['id']!,
              label: f['label']!,
              icon: _accessIcon[f['id']] ?? Icons.apps,
              art: _accessArt[f['id']],
              image: f['img']),
      ];

  /// Puts [id] in socket [i]; if it already sits in another socket the two swap.
  static List<String> place(List<String> slots, int i, String id) {
    final next = [...slots];
    if (i < 0 || i >= next.length) return next;
    final was = next.indexOf(id);
    if (was >= 0) next[was] = next[i];
    next[i] = id;
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => DoorAccessPicker(
        features: features,
        slots: s.navSlots,
        onSetSlot: (i, id) => s.setNavConfig(slots: place(s.navSlots, i, id)),
        onBack: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
