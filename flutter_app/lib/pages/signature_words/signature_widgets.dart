/// Signature cards in the approved design: frosted coupon-ticket rows
/// (approved-2) built from the shared nowssb_ui pieces, priced with the
/// app's original coin (NwsbCoinDisc).
library;

import 'package:flutter/material.dart';
import '../../nowssb_ui/nowssb_ui.dart' as ui;
import '../../widgets/nwsb_coin_fly.dart' show NwsbCoinDisc;
import 'signature_models.dart';

ui.Rarity kitRarity(Rarity r) => ui.Rarity.values[r.index];

class SignatureCard extends StatelessWidget {
  const SignatureCard({super.key, required this.word, required this.index, required this.onTap});
  final SignatureWord word;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = kitRarity(word.rarity);
    Widget card = ClipPath(
      clipper: const ui.NotchClipper(radius: 22, notch: 10),
      child: ui.NGlass(
        radius: 22,
        accent: r.color,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(children: [
          ui.CircleImage(image: ui.NCircles.at(index), size: 64, ring: r.color),
          const SizedBox(width: 12),
          const SizedBox(height: 64, child: ui.DashedLine(vertical: true)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, runSpacing: 4, children: [
                ui.RarityChip(r),
                if (word.owned) const ui.GlassBadge('OWNED', color: ui.NTokens.mint),
              ]),
              const SizedBox(height: 6),
              Text(word.locked ? 'Upcoming drop' : word.sound,
                  style: const TextStyle(color: ui.NTokens.textLo, fontSize: 12)),
              Text(word.locked ? 'Locked' : word.word,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              if (word.locked)
                Text(_dropLabel(word.dropAt), style: const TextStyle(color: ui.NTokens.mint, fontSize: 12, fontWeight: FontWeight.w700))
              else if (word.owned)
                const Text('In your collection', style: TextStyle(color: ui.NTokens.mint, fontSize: 12, fontWeight: FontWeight.w700))
              else
                Row(children: [
                  const NwsbCoinDisc(size: 16),
                  const SizedBox(width: 4),
                  Flexible(child: Text('${word.priceCoins} coins', overflow: TextOverflow.ellipsis, style: const TextStyle(color: ui.NTokens.mint, fontSize: 12, fontWeight: FontWeight.w700))),
                ]),
            ]),
          ),
          if (word.locked) const Icon(Icons.lock_rounded, color: Colors.white70, size: 20),
        ]),
      ),
    );
    return Semantics(
      button: true,
      label: '${word.locked ? 'Locked drop' : word.word}, ${word.rarity.label}',
      child: KeyedSubtree(key: ValueKey('sig-card-${word.id}'), child: card),
    );
  }
}

String _dropLabel(DateTime? d) => d == null ? 'Drop date to be announced' : 'Drops ${d.day}/${d.month}/${d.year}';
