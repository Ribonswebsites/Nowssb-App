import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';
import '../economy/play_billing.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import '../../screens/store/store_terms_sheet.dart';
import '../../screens/subscription.dart';
import '../../widgets/program_shelf.dart';
import '../../widgets/four_banners.dart';
import '../../admin/template/editable.dart';

class BazaarScreen extends StatelessWidget {
  const BazaarScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final listening = ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) => ListView(
        shrinkWrap: embedded,
        physics: embedded ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: const [
          // Both programme PDFs keep peer-to-peer resale paused: no listings,
          // no boosts, no resale commission. Words you own stay in your library.
          GlassLine(text: 'Resale is paused. You cannot list, boost or buy resold words right now — the words you own stay in your library.'),
          SizedBox(height: 12),
          EconomyNote('When resale opens it will run through Google Play with the price band and the resale fee shown before you list.'),
        ],
      ),
    );
    if (embedded) return listening;
    return StoreTermsHost(
      which: 'bazaar',
      head: 'Before you resell',
      child: EconomyPage(
      goodToKnow: 'Peer-to-peer resale is paused. Nothing here is charged or paid out.',
        title: 'Resell',
        mark: NwsbMarks.bag,
        child: listening,
      ),
    );
  }
}
