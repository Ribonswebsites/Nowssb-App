import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = EconomyMirror.instance.uid;
    return EconomyPage(
      title: 'Activity',
      requireAuth: true,
      child: !NwsbFirebase.ready || uid == null
          ? const EconomyMessage(title: 'No activity yet', body: 'Sign in and your rewards will collect here.')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                  return const EconomyMessage(title: 'You are caught up', body: 'Login coins, payouts, and Circle updates land here.');
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
                      trailing: unread ? const Icon(Icons.circle, size: 8, color: NwsbColors.gold) : null,
                      onTap: unread
                          ? () => docs[i].reference.set({'read': true}, SetOptions(merge: true))
                          : null,
                    );
                  },
                );
              },
            ),
    );
  }
}
