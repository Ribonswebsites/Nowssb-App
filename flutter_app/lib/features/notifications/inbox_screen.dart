import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
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
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users/$uid/notifications')
                .orderBy('at', descending: true)
                .limit(40)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const EconomyMessage(title: 'Activity did not load', body: 'Try again in a moment.');
              }
              if (!snap.hasData) return const EconomySkeleton();
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const EconomyMessage(
                  title: 'You are caught up',
                  body: 'Login coins, payouts, and referral updates land here.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data();
                  final unread = data['read'] != true;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${data['title'] ?? 'NowssB'}', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${data['body'] ?? ''}', style: const TextStyle(color: NwsbColors.mist)),
                    trailing: unread ? const NwsbIcon(NwsbMarks.earn, size: 16, color: NwsbColors.gold) : null,
                    onTap: unread ? () => docs[i].reference.set({'read': true}, SetOptions(merge: true)) : null,
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
