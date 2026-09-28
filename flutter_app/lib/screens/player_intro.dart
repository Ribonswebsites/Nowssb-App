/// Player intro — native counterpart of website `renderPracticeIntro()`.
///
/// Full-bleed rotating practice art, white circular back, "{n} Natural
/// {slot} Sounds", Skip + Begin. Begin reveals the Now Playing player.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../media/nwsb_image.dart';
import '../theme/player_aura.dart';

/// Same rotating stills as `PI_ART` in app/js/part004.js.
const kPlayerIntroArt = <String>[
  // The same eight R2 paintings as PI_ART, bundled so
  // the intro opens with its picture instead of waiting on a 2MB download.
  'assets/player/intro/01.webp',
  'assets/player/intro/02.webp',
  'assets/player/intro/03.webp',
  'assets/player/intro/04.webp',
  'assets/player/intro/05.webp',
  'assets/player/intro/06.webp',
  'assets/player/intro/07.webp',
  'assets/player/intro/08.webp',
];

const _kArtIndexKey = 'nwsb_pi_art';

/// Persist so PlayerIntroScreen shows once per install.
const kPlayerIntroSeenKey = 'nwsb_player_intro_seen';

/// The painting the next Player Intro will show — the same rotation
/// [PlayerIntroScreen] advances — so it can be decoded ahead of time.
String playerIntroNextArt(SharedPreferences prefs) {
  final next =
      ((prefs.getInt(_kArtIndexKey) ?? -1) + 1) % kPlayerIntroArt.length;
  return kPlayerIntroArt[next];
}

class PlayerIntroScreen extends StatefulWidget {
  const PlayerIntroScreen({
    super.key,
    required this.sessionTitle,
    required this.wordCount,
    required this.onBegin,
    required this.onBack,
    this.onSettings,
  });

  final String sessionTitle;
  final int wordCount;
  final VoidCallback onBegin;
  final VoidCallback onBack;
  final VoidCallback? onSettings;

  @override
  State<PlayerIntroScreen> createState() => _PlayerIntroScreenState();
}

class _PlayerIntroScreenState extends State<PlayerIntroScreen> {
  /// Null for the instant before the rotation is read, so the intro never
  /// flashes painting #1 before swapping to the one it actually picked.
  String? _art;

  static const _descs = {
    'Morning':
        'Begin the day with natural origin sound. Each word activates a living frequency within your body.',
    'Midday':
        'Restore balance at the centre of the day. Natural sounds realign your healing flow.',
    'Afternoon':
        'Deepen your practice. Root sounds carry grounding, focusing resonance through the body.',
    'Evening':
        'Wind down with intention. These words calm the nervous system and restore inner balance.',
    'Night':
        'Deep healing begins at night. Root sounds work while your body rests and repairs.',
  };

  @override
  void initState() {
    super.initState();
    _pickArt();
  }

  Future<void> _pickArt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final art = playerIntroNextArt(prefs);
      if (mounted) setState(() => _art = art);
      await prefs.setInt(_kArtIndexKey, kPlayerIntroArt.indexOf(art));
    } catch (_) {
      if (mounted && _art == null) {
        setState(() => _art = kPlayerIntroArt.first);
      }
    }
  }

  String get _slot {
    final h = DateTime.now().hour;
    if (h < 10) return 'Morning';
    if (h < 13) return 'Midday';
    if (h < 17) return 'Afternoon';
    if (h < 20) return 'Evening';
    return 'Night';
  }

  String get _name {
    final t = widget.sessionTitle.trim();
    if (t.isEmpty || t.toLowerCase() == 'practice') return _slot;
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.wordCount > 0 ? '${widget.wordCount}' : '∞';
    final desc = _descs[_slot] ??
        'Every word has a natural origin vibration. Sound before definition. Vibration before meaning.';
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: const Color(0xFF060C18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_art != null)
            NwsbImage(
              url: _art!,
              fit: BoxFit.cover,
              fallback: const ColoredBox(color: Color(0xFF060C18)),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x1A040A18),
                  Color(0x05040A18),
                  Color(0x8C040A18),
                  Color(0xF7040A18),
                ],
                stops: [0, 0.20, 0.58, 1],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(28, 8, 28, 20 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PlayerAuraBackButton(onTap: widget.onBack),
                      const Spacer(),
                      Text(
                        'NOWSSB',
                        style: playerAuraText(
                          size: 9,
                          weight: FontWeight.w800,
                          letterSpacing: 6,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (widget.onSettings != null)
                        GestureDetector(
                          onTap: widget.onSettings,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0x6B060C18),
                              border:
                                  Border.all(color: const Color(0x2EFFFFFF)),
                            ),
                            child: const Icon(Icons.more_vert,
                                color: Color(0xB3FFFFFF), size: 18),
                          ),
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                  const Spacer(),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$count Natural ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        TextSpan(
                          text: '$_name Sounds',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            color: Color(0xFFF5C842),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      desc,
                      style: const TextStyle(
                        color: Color(0xB8FFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        height: 1.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onBegin,
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 15),
                          child: Text(
                            'SKIP',
                            style: TextStyle(
                              color: Color(0x73FFFFFF),
                              fontSize: 13,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 8,
                        shadowColor: Colors.black54,
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: widget.onBegin,
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(30, 15, 26, 15),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'BEGIN',
                                  style: TextStyle(
                                    color: Color(0xFF060C18),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded,
                                    size: 16, color: Color(0xFF060C18)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
