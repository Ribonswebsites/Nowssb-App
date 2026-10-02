/// Partner points. Perks only. They are not coins and they are not cash.
library;

import 'package:flutter/material.dart';

import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import 'economy_api.dart';
import 'economy_theme.dart';
import '../programs/partner_program.dart';

class PartnerScreen extends StatelessWidget {
  const PartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      goodToKnow: kPartnerDisclaimer,
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
              const CoinCollectCard(pageKey: 'partner', amount: 10, title: 'Partner coins'),
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
                  value: (points / 500).clamp(0, 1),
                  minHeight: 8,
                  color: const Color(0xFFE4C56A),
                  backgroundColor: const Color(0x22FFFFFF),
                ),
              ),
              const SizedBox(height: 16),
              // Points come only from cleared purchases through your links
              // (server partnerLedger). The full program has every track.
              _action(context, 'My progress and perks', 0),
              _action(context, 'Word Track', 1),
              _action(context, 'Plan Track', 2),
              _action(context, 'Buyer discount', 4),
            ],
          );
        },
      ),
    );
  }

  Widget _action(BuildContext context, String label, int tab) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GoldButton(
        label: label,
        filled: tab == 0,
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PartnerProgramPage(initialTab: tab))),
      ),
    );
  }
}
