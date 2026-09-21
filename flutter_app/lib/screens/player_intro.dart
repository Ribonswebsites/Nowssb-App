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
  'https://media.nowssb.com/migrated-images/177c353c491b0de9_file_00000000210881fabda4b62a827e2b7d_shsdnw.png',
  'https://media.nowssb.com/migrated-images/1208f305864e171f_file_000000005c28820693e31425ac03a99a_myqo9z.png',
  'https://media.nowssb.com/migrated-images/d45a2ad961881f1a_file_00000000fbb481fa897d6c4b800c7abc_x0fmja.png',
  'https://media.nowssb.com/migrated-images/0a886e63010f07db_file_0000000013088209a33ed2b6c15a7dfe_l6j2wf.png',
  'https://media.nowssb.com/migrated-images/0bcdf699fbd0626d_file_00000000868081fa8048698268ae60bb_rw97tp.png',
  'https://media.nowssb.com/migrated-images/d9d911700ddae27c_file_00000000112882069935a3c4bce3b4ca_r6awjq.png',
  'https://media.nowssb.com/migrated-images/1e84950d507185ec_file_00000000fdb08207a6e3e5e768f47448_apuryf.png',
  'https://media.nowssb.com/migrated-images/583f4d21147adb19_file_00000000280082069ad442c609cdd790_ci1kbd.png',
];

const _kArtIndexKey = 'nwsb_pi_art';

/// Persist so PlayerIntroScreen shows once per install.
const kPlayerIntroSeenKey = 'nwsb_player_intro_seen';

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
  String _art = kPlayerIntroArt.first;

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
      final next =
          ((prefs.getInt(_kArtIndexKey) ?? -1) + 1) % kPlayerIntroArt.length;
      await prefs.setInt(_kArtIndexKey, next);
      if (mounted) setState(() => _art = kPlayerIntroArt[next]);
    } catch (_) {}
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
          NwsbImage(url: _art, fit: BoxFit.cover),
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
                  const SizedBox(height: 24),
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
