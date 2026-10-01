/// Partner points. Perks only. They are not coins and they are not cash.
library;

import 'package:flutter/material.dart';

import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import 'economy_api.dart';
import 'economy_theme.dart';

class PartnerScreen extends StatelessWidget {
  const PartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'Partner',
      mark: NwsbMarks.crown,
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final points = EconomyMirror.instance.partnerPoints;
          final perk = EconomyMirror.instance.partnerPerk;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const ProgramShelf(),
              const SizedBox(height: 12),
              const GlassLine(
                text: 'Points buy a mark, an early listen, or a studio note. They never convert to money.',
              ),
              const SizedBox(height: 16),
              Text(
                '$points',
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
              ),
              Text(
                perk.isEmpty ? 'No perk yet' : perk,
                style: const TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (points / 100).clamp(0, 1),
                  minHeight: 8,
                  color: const Color(0xFFE4C56A),
                  backgroundColor: const Color(0x22FFFFFF),
                ),
              ),
              const SizedBox(height: 16),
              _action(context, 'Log today’s practice · 1', 'practice'),
              _action(context, 'Log a purchase day · 5', 'purchase'),
              _action(context, 'Log a referral day · 10', 'referral'),
            ],
          );
        },
      ),
    );
  }

  Widget _action(BuildContext context, String label, String kind) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GoldButton(
        label: label,
        filled: false,
        onTap: () => runPrivate(context, () => EconomyApi.call('logPartnerAction', {'kind': kind})),
      ),
    );
  }
}
