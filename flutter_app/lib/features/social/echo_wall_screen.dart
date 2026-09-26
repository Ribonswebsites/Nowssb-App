import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import 'echo_moderation_screen.dart';

class EchoWallScreen extends StatefulWidget {
  const EchoWallScreen({super.key});

  @override
  State<EchoWallScreen> createState() => _EchoWallScreenState();
}

class _EchoWallScreenState extends State<EchoWallScreen> {
  final _text = TextEditingController();
  String? _imageRef;
  bool _following = false;
  bool _busy = false;
  bool _admin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final uid = EconomyMirror.instance.uid;
    if (!NwsbFirebase.ready || uid == null) return;
    final doc = await FirebaseFirestore.instance.doc('admins/$uid').get();
    if (mounted) setState(() => _admin = doc.exists);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'Echo Wall',
      action: _admin
          ? IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const EchoModerationScreen()),
              ),
              icon: const Icon(Icons.shield_outlined),
            )
          : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _tab('Trending', false),
                const SizedBox(width: 8),
                _tab('Following', true),
              ],
            ),
          ),
          Expanded(child: _feed()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _text,
                  maxLength: 280,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'A short reflection',
                    hintStyle: const TextStyle(color: NwsbColors.mist),
                    counterStyle: const TextStyle(color: NwsbColors.mist),
                    suffixIcon: IconButton(
                      onPressed: _pick,
                      icon: Icon(Icons.image_outlined, color: _imageRef == null ? NwsbColors.mist : NwsbColors.gold),
                    ),
                  ),
                ),
                GoldButton(
                  label: _busy ? 'Posting…' : 'Post',
                  onTap: _busy ? null : _post,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool following) {
    final on = _following == following;
    return Expanded(
      child: GoldButton(
        label: label,
        filled: on,
        onTap: () => setState(() => _following = following),
      ),
    );
  }

  Widget _feed() {
    if (!NwsbFirebase.ready) return const Center(child: EconomyNote('Firebase is not connected.'));
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('echoPosts')
          .where('status', isEqualTo: 'live')
          .limit(40)
          .snapshots(),
      builder: (context, snap) {
        var docs = snap.data?.docs ?? [];
        if (_following) {
          return FutureBuilder<Set<String>>(
            future: _followingIds(),
            builder: (context, ids) {
              final allow = ids.data ?? {};
              final filtered = docs.where((d) => allow.contains(d.data()['authorUid'])).toList();
              return _list(filtered);
            },
          );
        }
        docs = [...docs]..sort((a, b) {
          final scoreA = (a.data()['likeCount'] as num?)?.toInt() ?? 0;
          final scoreB = (b.data()['likeCount'] as num?)?.toInt() ?? 0;
          return scoreB.compareTo(scoreA);
        });
        return _list(docs);
      },
    );
  }

  Widget _list(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) return const Center(child: EconomyNote('Nothing on the wall yet.'));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [for (final doc in docs) _PostCard(doc: doc)],
    );
  }

  Future<Set<String>> _followingIds() async {
    final uid = EconomyMirror.instance.uid;
    if (uid == null) return {};
    final snap = await FirebaseFirestore.instance.collection('follows/$uid/following').get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<void> _pick() async {
    final uid = EconomyMirror.instance.uid;
    if (uid == null) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'echo/$uid/$name';
      await FirebaseStorage.instance.ref(path).putFile(
            File(picked.path),
            SettableMetadata(contentType: 'image/jpeg'),
          );
      if (mounted) setState(() => _imageRef = path);
    } on EconomyException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _post() async {
    setState(() => _busy = true);
    try {
      await EconomyApi.call('createEchoPost', {
        'text': _text.text.trim(),
        'imageRef': _imageRef ?? '',
      });
      _text.clear();
      setState(() => _imageRef = null);
    } on EconomyException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final imageRef = (data['imageRef'] as String?) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22C8A96E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((data['text'] as String?) ?? '', style: const TextStyle(color: Colors.white, height: 1.35)),
          if (imageRef.isNotEmpty) ...[
            const SizedBox(height: 8),
            _EchoImage(path: imageRef),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => runEconomy(context, () => EconomyApi.call('toggleEchoLike', {'postId': doc.id})),
                child: Text('Like ${data['likeCount'] ?? 0}', style: const TextStyle(color: NwsbColors.goldLight)),
              ),
              TextButton(
                onPressed: () => _comment(context),
                child: Text('Comment ${data['commentCount'] ?? 0}', style: const TextStyle(color: NwsbColors.mist)),
              ),
              TextButton(
                onPressed: () => runEconomy(context, () => EconomyApi.call('reportEcho', {
                      'targetType': 'post',
                      'targetId': doc.id,
                      'reason': 'report',
                    })),
                child: const Text('Report', style: TextStyle(color: NwsbColors.mist)),
              ),
            ],
          ),
          TextButton(
            onPressed: () => runEconomy(context, () => EconomyApi.call('blockEchoUser', {'targetUid': data['authorUid']})),
            child: const Text('Block author', style: TextStyle(color: NwsbColors.mist, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _comment(BuildContext context) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NwsbColors.plate,
        title: const Text('Comment', style: TextStyle(color: Colors.white)),
        content: TextField(controller: controller, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Send')),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty || !context.mounted) return;
    await runEconomy(context, () => EconomyApi.call('commentOnPost', {'postId': doc.id, 'text': text}));
  }
}

class _EchoImage extends StatelessWidget {
  const _EchoImage({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: FirebaseStorage.instance.ref(path).getDownloadURL(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 8);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(snap.data!, height: 160, width: double.infinity, fit: BoxFit.cover),
        );
      },
    );
  }
}
