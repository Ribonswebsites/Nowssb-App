/// Admin — Requests. Streams Firestore `requests` (the website and the app
/// both write there). Marking one done tells the person through their
/// `users/{uid}/inbox` (what the website raises) and
/// `users/{uid}/notifications`.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_log.dart';
import 'admin_ui.dart';

class RequestsAdminScreen extends StatefulWidget {
  const RequestsAdminScreen({super.key});

  @override
  State<RequestsAdminScreen> createState() => _RequestsAdminScreenState();
}

class _RequestsAdminScreenState extends State<RequestsAdminScreen> {
  bool _showDone = false;
  final _db = FirebaseFirestore.instance;

  Future<void> _fulfil(String id, Map<String, dynamic> r) async {
    final word = '${r['word'] ?? ''}';
    final uid = r['uid'] is String ? r['uid'] as String : '';
    try {
      await _db.collection('requests').doc(id).update({'status': 'done', 'doneAt': DateTime.now().millisecondsSinceEpoch});
      var told = 'no account to tell';
      if (uid.isNotEmpty) {
        final title = '“$word” is ready';
        const body = 'The word you asked for is now in NowssB.';
        final at = DateTime.now().millisecondsSinceEpoch;
        final results = await Future.wait<bool>([
          _db
              .collection('users')
              .doc(uid)
              .collection('inbox')
              .add({'type': 'arrivals', 'title': title, 'body': body, 'at': at, 'read': false})
              .then((_) => true, onError: (_) => false),
          _db
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .add({
                'type': 'request_done',
                'title': title,
                'body': body,
                'word': word,
                'requestId': id,
                'at': at,
                'createdAt': FieldValue.serverTimestamp(),
                'read': false,
              })
              .then((_) => true, onError: (_) => false),
        ]);
        told = results.any((x) => x) ? 'they will see it in the app' : 'could not reach them';
      }
      await adminLog('request.done', id, {'word': word, 'uid': uid});
      if (mounted) adminToast(context, 'Done — $told.');
    } catch (e) {
      if (mounted) adminToast(context, 'Could not update: $e');
    }
  }

  Future<void> _reopen(String id) async {
    try {
      await _db.collection('requests').doc(id).update({'status': 'new'});
      await adminLog('request.reopen', id);
    } catch (e) {
      if (mounted) adminToast(context, 'Could not update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _db.collection('requests').orderBy('at', descending: true).limit(300);
    return AdminScaffold(
      title: 'Requests',
      actions: [
        Row(children: [
          const Text('Done', style: TextStyle(color: kAdminDim, fontSize: 12)),
          Switch(value: _showDone, onChanged: (v) => setState(() => _showDone = v)),
        ]),
      ],
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load: ${snap.error}', style: const TextStyle(color: kAdminDim)));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.where((d) => _showDone || d.data()['status'] != 'done').toList();
          if (docs.isEmpty) {
            return Center(
              child: Text(_showDone ? 'No requests.' : 'No open requests.', style: const TextStyle(color: kAdminDim)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final id = docs[i].id;
              final r = docs[i].data();
              final done = r['status'] == 'done';
              final kind = '${r['kind'] ?? 'word'}';
              final who = [r['name'], r['email']].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
              return AdminPanel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text('${r['word'] ?? ''}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    AdminChip(kind),
                    const SizedBox(width: 6),
                    AdminChip(done ? 'done' : 'open',
                        color: done ? const Color(0xFF81C784) : const Color(0xFFFFB74D)),
                  ]),
                  if ('${r['notes'] ?? ''}'.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('${r['notes']}', style: const TextStyle(color: kAdminDim, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    [who.isEmpty ? 'signed-out / unknown' : who, adminAgo(r['at']), '${r['source'] ?? 'web'}'].join(' · '),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: done
                        ? TextButton(onPressed: () => _reopen(id), child: const Text('Reopen'))
                        : FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: kAdminGold, foregroundColor: kAdminBg),
                            onPressed: () => _fulfil(id, r),
                            child: const Text('Mark done & tell them'),
                          ),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
