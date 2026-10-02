/// Six program cards (Earn, Rewards, Coupons, Gifts, Reference, Partner)
/// with live numbers from the server summary — Profile and anywhere else
/// that needs a compact door into every programme.
library;

import 'package:flutter/material.dart';

import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
import 'coupons_program.dart';
import 'earn_program.dart';
import 'gifts_program.dart';
import 'partner_program.dart';
import 'program_kit.dart';
import 'reference_program.dart';
import 'rewards_program.dart';

class ProgramCardsStrip extends StatelessWidget {
  const ProgramCardsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final m = EconomyMirror.instance;
        final s = m.summary;
        final earn = s['earn'] is Map ? s['earn'] as Map : const {};
        final cards = (s['scratchCards'] as List?)?.length ?? 0;
        final coupons = (s['coupons'] as List?)?.length ?? 0;
        final gifts = s['gifts'] is Map ? (((s['gifts'] as Map)['received'] as List?)?.length ?? 0) : 0;
        final items = <(String, String, String, Widget Function())>[
          ('NowssB Earn', '${earn['title'] ?? m.sellerTier} · ${earn['words'] ?? m.wordsSold} words', NwsbMarks.piggy, () => const EarnProgramPage()),
          ('Rewards', '${m.coins} coins · streak ${m.streak}', NwsbMarks.rewards, () => const RewardsProgramPage()),
          ('Coupons', '$cards sealed · $coupons coupons', NwsbMarks.coupon, () => const CouponsProgramPage()),
          ('Gifts', '$gifts received', NwsbMarks.gift, () => const GiftsProgramPage()),
          ('Reference', m.code.isEmpty ? 'Get your link' : 'Code ${m.code}', NwsbMarks.reference, () => const ReferenceProgramPage()),
          ('Partner', '${m.partnerPoints} points', NwsbMarks.crown, () => const PartnerProgramPage()),
        ];
        return SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final it = items[i];
              return GestureDetector(
                onTap: () => openProgram(context, it.$4()),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0x14FFFFFF),
                    border: Border.all(color: const Color(0x33E4C56A)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    NwsbIcon(it.$3, size: 22, color: const Color(0xFFE4C56A)),
                    const Spacer(),
                    Text(it.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(m.uid == null ? 'Sign in' : it.$2, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11.5)),
                  ]),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
