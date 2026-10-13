import 'package:flutter/material.dart';

import '../../../nowssb_ui/nowssb_ui.dart';

/// Gifts-only colours on top of the shared tokens. Gifts = pink everywhere.
class GiftsPalette {
  static const pink = NTokens.pink;
  static const violet = NTokens.violet;
  static const amber = NTokens.gold;
  static const teal = NTokens.mint;
  static const text = NTokens.textHi;
  static const soft = NTokens.textLo;
  static const bgBottom = NTokens.bgBottom;
}

/// A gift card in the catalog rails and My gifts. Built on the kit's [NGlass]
/// and [ExpiredOverlay]. Not the kit's GiftTile on purpose: that one says
/// "Won for …", which would be untrue for bought or sent gifts.
class GiftsCardTile extends StatelessWidget {
  const GiftsCardTile(
      {super.key, required this.title, required this.caption, this.footer = '', this.color = GiftsPalette.pink, this.expired = false, this.onTap});
  final String title, caption, footer;
  final Color color;
  final bool expired;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Semantics(
      button: onTap != null,
      label: '$title. $caption${expired ? '. Expired' : ''}',
      child: NGlass(
        radius: NTokens.rCard,
        accent: color,
        tint: color,
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 22, backgroundColor: color.withValues(alpha: .3), child: const Icon(Icons.redeem_rounded, color: Colors.white)),
              const SizedBox(height: 10),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: GiftsPalette.text, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: GiftsPalette.soft, fontSize: 12)),
            ]),
          ),
          Container(
            height: 26,
            color: color.withValues(alpha: .45),
            alignment: Alignment.center,
            child: Text(footer.isEmpty ? ' ' : footer, style: const TextStyle(color: GiftsPalette.text, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
    return expired ? ExpiredOverlay(child: t) : t;
  }
}
