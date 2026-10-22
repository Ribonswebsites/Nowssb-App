/// Partner points. Perks only. They are not coins and they are not cash.
library;

import 'package:flutter/material.dart';

import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import '../../widgets/four_banners.dart';
import 'economy_api.dart';
import 'economy_theme.dart';
import '../programs/partner_program.dart';
import '../programs/program_heroes.dart';
import '../programs/program_kit.dart';
import '../programs/program_router.dart';

class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key, this.initialTab});

  /// Opens scrolled to one programme tab (e.g. 'perks').
  final String? initialTab;

  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  final _go = ValueNotifier<void Function(String)?>(null);

  @override
  void dispose() {
    _go.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      goodToKnow: kPartnerDisclaimer,
      title: 'Partner',
      mark: NwsbMarks.crown,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const PartnerHero(),
          const SizedBox(height: 12),
          const ProgramShelf(current: Programme.partner),
          const SizedBox(height: 12),
          const CoinCollectCard(pageKey: 'partner', amount: 10, title: 'Partner coins'),
          const SizedBox(height: 12),
          const GlassLine(
            text: 'Points buy a mark, an early listen, or a studio note. They never convert to money.',
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: EconomyMirror.instance,
            builder: (context, _) {
              final points = EconomyMirror.instance.partnerPoints;
              final perk = EconomyMirror.instance.partnerPerk;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '$points',
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
                ),
                Text(
                  perk.isEmpty ? 'No perk yet' : perk,
                  style: const TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w700),
                ),
              ]);
            },
          ),
          const SizedBox(height: 16),
          // Points come only from cleared purchases through your links
          // (server partnerLedger). Each button opens its own tab below.
          _action('My progress and perks', 'progress', true),
          _action('Word Track', 'word', false),
          _action('Plan Track', 'plan', false),
          _action('Buyer discount', 'discount', false),
          const SizedBox(height: 12),
          const FourBanners(
            current: Programme.partner,
            splitTitle: 'Partner perks',
            splitCta: 'Share a link',
            blackTitle: 'Points, not cash',
            blackSub: 'Coins, gifts, coupons and early access.',
          ),
          const SizedBox(height: 18),
          ProgramTabsBlock(spec: kPartnerSpec, initialTab: widget.initialTab, scrollTo: widget.initialTab != null, goRef: _go, showDisclaimer: false),
        ],
      ),
    );
  }

  Widget _action(String label, String tab, bool filled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GoldButton(
        label: label,
        filled: filled,
        onTap: () => _go.value?.call(tab),
      ),
    );
  }
}
