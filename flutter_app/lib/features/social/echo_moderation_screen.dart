import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';

class EchoModerationScreen extends StatelessWidget {
  const EchoModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'Echo reports',
      child: !NwsbFirebase.ready
          ? const EconomyNote('Firebase is not connected.')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('echoReports')
                  .where('status', isEqualTo: 'pending')
                  .limit(40)
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: EconomyNote('No pending reports.'),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final doc in docs)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x33C8A96E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${doc.data()['targetType']} · ${doc.data()['reason']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text('${doc.data()['targetId']}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
                            const SizedBox(height: 8),
                            GoldButton(
                              label: 'Remove',
                              onTap: () => runEconomy(context, () => EconomyApi.call('reviewEchoReport', {
                                    'reportId': doc.id,
                                    'remove': true,
                                  })),
                            ),
                            const SizedBox(height: 6),
                            GoldButton(
                              label: 'Restore',
                              filled: false,
                              onTap: () => runEconomy(context, () => EconomyApi.call('reviewEchoReport', {
                                    'reportId': doc.id,
                                    'remove': false,
                                  })),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
