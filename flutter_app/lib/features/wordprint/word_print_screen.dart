import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';

class WordPrintScreen extends StatefulWidget {
  const WordPrintScreen({super.key, this.uid});

  final String? uid;

  @override
  State<WordPrintScreen> createState() => _WordPrintScreenState();
}

class _WordPrintScreenState extends State<WordPrintScreen> {
  final _handle = TextEditingController();
  final _bio = TextEditingController();
  final _search = TextEditingController();
  String? _found;

  @override
  void dispose() {
    _handle.dispose();
    _bio.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _found ?? widget.uid ?? EconomyMirror.instance.uid;
    final mine = uid != null && uid == EconomyMirror.instance.uid;
    return EconomyPage(
      title: 'Word Print',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          TextField(
            controller: _search,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Search a handle', hintStyle: TextStyle(color: NwsbColors.mist)),
            onSubmitted: (_) => _find(),
          ),
          const SizedBox(height: 8),
          GoldButton(label: 'Search', filled: false, onTap: _find),
          const SizedBox(height: 16),
          if (!NwsbFirebase.ready || uid == null)
            const EconomyNote('Sign in, or search a handle, to open a Word Print.')
          else
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.doc('profiles/$uid').snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data() ?? {};
                final stats = (data['publicStats'] as Map?) ?? {};
                final badges = (data['featuredBadges'] as List?)?.map((e) => '$e').toList() ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((data['handle'] as String?) ?? 'NowssB', style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text((data['bio'] as String?) ?? '', style: const TextStyle(color: NwsbColors.mist)),
                    const SizedBox(height: 10),
                    Text(
                      'Streak ${stats['streak'] ?? 0} · longest ${stats['longestStreak'] ?? 0} · owned ${stats['wordsOwned'] ?? 0} · sold ${stats['wordsSold'] ?? 0}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['sellerTier'] ?? 'Seller'} · ${data['circleTier'] ?? 'Member'} · ${data['followerCount'] ?? 0} followers · ${data['followingCount'] ?? 0} following',
                      style: const TextStyle(color: NwsbColors.mist),
                    ),
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(badges.join('  ·  '), style: const TextStyle(color: NwsbColors.goldLight)),
                    ],
                    const SizedBox(height: 14),
                    if (!mine)
                      GoldButton(
                        label: 'Follow',
                        onTap: () => runEconomy(context, () => EconomyApi.call('setFollow', {'targetUid': uid, 'follow': true})),
                      ),
                    if (mine) ...[
                      TextField(
                        controller: _handle,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(hintText: 'Handle', hintStyle: TextStyle(color: NwsbColors.mist)),
                      ),
                      TextField(
                        controller: _bio,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(hintText: 'Bio', hintStyle: TextStyle(color: NwsbColors.mist)),
                      ),
                      const SizedBox(height: 8),
                      GoldButton(
                        label: 'Save Word Print',
                        filled: false,
                        onTap: () => runEconomy(context, () => EconomyApi.call('updateWordPrint', {
                              if (_handle.text.trim().isNotEmpty) 'handle': _handle.text.trim(),
                              'bio': _bio.text.trim(),
                              'featuredBadges': badges.take(6).toList(),
                            })),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _find() async {
    if (!NwsbFirebase.ready) return;
    final handle = _search.text.trim();
    if (handle.isEmpty) return;
    final found = await FirebaseFirestore.instance.collection('profiles').where('handle', isEqualTo: handle).limit(1).get();
    if (!mounted) return;
    setState(() => _found = found.docs.isEmpty ? null : found.docs.first.id);
    if (found.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No Word Print with that handle.')));
    }
  }
}
