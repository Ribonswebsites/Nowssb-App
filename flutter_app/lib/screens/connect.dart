/// NowssB Connect — people, the feed, chat.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/intro_gate.dart';
import '../widgets/page_shell.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  static const people = [
    ('Healer One', 'On a 12-day streak'),
    ('Healer Two', 'Practicing AAROGYA'),
    ('Healer Three', 'Frequency X'),
    ('Healer Four', 'Just joined'),
  ];

  @override
  Widget build(BuildContext context) {
    return IntroGate(
      tag: 'Connect',
      eyebrow: 'The social space',
      title: 'Practice\ntogether.',
      body: 'People, a feed, and a chat. Same frequency, same words.',
      stats: const ['Live', 'Public profiles', 'Chat'],
      film: 'assets/video/connect-banner.mp4',
      enterLabel: 'ENTER CONNECT',
      onBack: () => Navigator.of(context).maybePop(),
      child: PageShell(
        eyebrow: 'NowssB',
        title: 'Connect',
        film: 'assets/video/connect-banner.mp4',
        onBack: () => Navigator.of(context).maybePop(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.list(children: [
              const DarkHead(
                eyebrow: 'Who is here',
                title: 'People',
                icon: Icons.groups_outlined,
              ),
              const SizedBox(height: 14),
              for (final (name, sub) in people)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x14FFFFFF)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF14141C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline,
                            color: NwsbColors.goldLight),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            Text(sub,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0x8CFFFFFF))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              const DarkHead(
                eyebrow: 'Say something',
                title: 'Chat',
                icon: Icons.chat_bubble_outline,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: const Text(
                  'Messages land in Firestore the same way they do on the website. Type below when you are signed in.',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xB3FFFFFF), height: 1.5),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
