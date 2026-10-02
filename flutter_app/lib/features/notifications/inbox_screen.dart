import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../data/notifications.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../../screens/nwsb_sign_in_sheet.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_theme.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'NowssB Earn — Activity',
      mark: NwsbMarks.bell,
      banner: const ColoredSplitPromoBanner(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
        spec: SplitPromoSpec(
          title: 'NowssB Earn\nActivity',
          cta: 'Rewards and payouts',
          leftColor: Color(0xFF1A2438),
          rightColor: Color(0xFFC8A96E),
          art: SplitPromoArts.egyptianGold,
        ),
      ),
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final uid = EconomyMirror.instance.uid;
          if (!NwsbFirebase.ready || uid == null) {
            return EconomyMessage(
              title: 'No activity yet',
              body: 'Sign in and your rewards will collect here.',
              action: 'Sign in',
              onAction: () => NwsbSignInPage.open(context),
            );
          }
          // The same inbox the bell opens (NotifStore merges this
          // account's Firestore notifications with on-phone reminders).
          return ListenableBuilder(
            listenable: NotifStore.instance,
            builder: (context, _) {
              final store = NotifStore.instance;
              final list = store.feed;
              if (list.isEmpty) {
                return const EconomyMessage(
                  title: 'You are caught up',
                  body: 'Daily coins, payouts, and referral updates land here.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final data = list[i];
                  final unread = !data.read;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(data.title, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(data.body, style: const TextStyle(color: NwsbColors.mist)),
                    trailing: unread ? const NwsbIcon(NwsbMarks.bell, size: 16, color: NwsbColors.gold) : null,
                    onTap: unread ? () => store.markRead(i) : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
