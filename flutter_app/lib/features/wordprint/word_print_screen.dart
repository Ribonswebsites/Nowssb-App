import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import '../../admin/template/editable.dart';

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

  // X1: keep one profile stream per uid instead of a new one every build.
  String? _profileUid;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profile;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _profileFor(String uid) {
    if (_profile == null || _profileUid != uid) {
      _profileUid = uid;
      _profile = FirebaseFirestore.instance.doc('profiles/$uid').snapshots();
    }
    return _profile!;
  }

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
      goodToKnow: 'Your Word Print shows only what you choose to make public. Money and payout details are never on it.',
      title: 'Word Print',
      mark: NwsbMarks.signature,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          const ProgramShelf(),
          const SizedBox(height: 12),
          const CoinCollectCard(pageKey: 'print', amount: 8, title: 'Word Print coins'),
          const SizedBox(height: 12),
          const GlassLine(text: 'A public print. Coins and cash stay off this page.'),
          const SizedBox(height: 12),
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
              stream: _profileFor(uid),
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
                        onTap: () => runPrivate(context, () => EconomyApi.call('setFollow', {'targetUid': uid, 'follow': true})),
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
                        onTap: () => runPrivate(context, () => EconomyApi.call('updateWordPrint', {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: EditableLabel('word_print_screen.WordPrintScreen', 'No Word Print with that handle.')));
    }
  }
}
