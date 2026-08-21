/// My Routines — five slots, same as the website.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/page_shell.dart';
import 'player.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  static const slots = [
    ('Morning', '05:00 – 11:59', 'Morning Ritual'),
    ('Midday', '12:00 – 16:59', 'Afternoon Session'),
    ('Evening', '17:00 – 20:59', 'Evening Practice'),
    ('Night', '21:00 – 04:59', 'Night Restoration'),
    ('Custom', 'Any hour', 'Your fifth slot'),
  ];

  @override
  Widget build(BuildContext context) {
    return PageShell(
      eyebrow: 'Daily system',
      title: 'My Routines',
      film: 'assets/video/player-liquid-splash.mp4',
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.list(children: [
            for (final (name, hours, sub) in slots)
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlayerScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x14FFFFFF)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFF14141C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.schedule,
                            size: 20, color: NwsbColors.goldLight),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            const SizedBox(height: 2),
                            Text('$hours · $sub',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0x8CFFFFFF))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 16, color: Color(0xB3FFFFFF)),
                    ],
                  ),
                ),
              ),
          ]),
        ),
      ],
    );
  }
}
