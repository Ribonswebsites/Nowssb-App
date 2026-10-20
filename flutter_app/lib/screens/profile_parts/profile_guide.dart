import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../nowssb_ui/nowssb_ui.dart';

/// First-use guide for the Profile page: a frosted card with a photo-free
/// icon, title, body, Skip link, page dots and a white Next pill.
class ProfileGuide extends StatefulWidget {
  static const prefKey = 'nwsb_profile_guide_seen';
  final VoidCallback onDone;
  const ProfileGuide({super.key, required this.onDone});

  static Future<bool> shouldShow() async {
    final p = await SharedPreferences.getInstance();
    return !(p.getBool(prefKey) ?? false);
  }

  static Future<void> reset() async =>
      (await SharedPreferences.getInstance()).remove(prefKey);

  @override
  State<ProfileGuide> createState() => _ProfileGuideState();
}

class _ProfileGuideState extends State<ProfileGuide> {
  static const _steps = [
    (
      Icons.person_outline,
      'Your profile',
      'Tap your photo to change it, and use Edit profile to set your name and motto.'
    ),
    (
      Icons.local_fire_department_outlined,
      'Progress & streak',
      'Your streak, score and words grow with every real practice session.'
    ),
    (
      Icons.apps_rounded,
      'Quick access',
      'Jump to sessions, saved words, your journal and settings in one tap.'
    ),
    (
      Icons.tune_rounded,
      'Preferences & plan',
      'Set practice length and a daily reminder, and manage your plan under Account.'
    ),
  ];
  int _i = 0;

  Future<void> _finish() async {
    (await SharedPreferences.getInstance()).setBool(ProfileGuide.prefKey, true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final s = _steps[_i];
    final last = _i == _steps.length - 1;
    return Material(
      color: Colors.black.withValues(alpha: .55),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: NGlass(
              key: const Key('profile-guide'),
              radius: 36,
              blur: 22,
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x22FFFFFF),
                        border: Border.all(color: const Color(0x55FFFFFF))),
                    child: Icon(s.$1, color: Colors.white, size: 38)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x33FFFFFF))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$2,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(s.$3,
                            style: const TextStyle(
                                color: Color(0xB3FFFFFF),
                                fontSize: 13.5,
                                height: 1.35)),
                        const SizedBox(height: 16),
                        Row(children: [
                          TextButton(
                              key: const Key('guide-skip'),
                              onPressed: _finish,
                              child: const Text('Skip',
                                  style: TextStyle(color: Color(0xB3FFFFFF)))),
                          const Spacer(),
                          for (var d = 0; d < _steps.length; d++)
                            Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: d == _i ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: d == _i
                                        ? Colors.white
                                        : const Color(0x55FFFFFF),
                                    borderRadius: BorderRadius.circular(3))),
                          const Spacer(),
                          GestureDetector(
                            key: const Key('guide-next'),
                            onTap: last ? _finish : () => setState(() => _i++),
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999)),
                                child: Text(last ? 'Done' : 'Next',
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13))),
                          ),
                        ]),
                      ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
