/// Subscription — Resonance / Frequency / Frequency X.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/page_shell.dart';

class SubscribeScreen extends StatelessWidget {
  const SubscribeScreen({super.key});

  static const tiers = [
    ('Resonance', '\$4.99 / mo', '5 new words a week'),
    ('Frequency', '\$9.99 / mo', '10 new words a week'),
    ('Frequency X', '\$19.99 / mo', '20 new words a week + Blue'),
  ];

  @override
  Widget build(BuildContext context) {
    return PageShell(
      eyebrow: 'The full library',
      title: 'Subscription',
      film: 'assets/video/subscription-a.mp4',
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.list(children: [
            const Text(
              '15 days of Frequency, no card. After that, a plan keeps the words coming.',
              style: TextStyle(
                  fontSize: 14, color: Color(0xB3FFFFFF), height: 1.5),
            ),
            const SizedBox(height: 18),
            for (final (name, price, sub) in tiers)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: name == 'Frequency'
                        ? const Color(0x59C8A96E)
                        : const Color(0x14FFFFFF),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(price,
                        style: const TextStyle(
                            fontSize: 13, color: NwsbColors.goldLight)),
                    const SizedBox(height: 8),
                    Text(sub,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0x99FFFFFF))),
                  ],
                ),
              ),
          ]),
        ),
      ],
    );
  }
}
