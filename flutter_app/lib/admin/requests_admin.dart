/// Word requests — `requests/{id}` from the app and the website, live.
/// Filter by status, open one, and create the requested word right there
/// (text, meanings, stages, description, voice, video, pictures → R2 →
/// `words/`). Publishing marks the request fulfilled and tells the person
/// (bell + inbox, and a phone push when the server has FCM).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/content.dart';
import 'admin_data.dart';
import 'admin_kit.dart';
import 'admin_log.dart';
import 'person_admin.dart';
import 'words_admin.dart';

class RequestsAdminScreen extends StatefulWidget {
  const RequestsAdminScreen({super.key});

  @override
  State<RequestsAdminScreen> createState() => _RequestsAdminScreenState();
}

class _RequestsAdminScreenState extends State<RequestsAdminScreen> {
  String _status = 'new';
  final _db = FirebaseFirestore.instance;
  final _q = TextEditingController();

  static const _statuses = {'new': 'Open', 'done': 'Fulfilled', 'declined': 'Declined', 'all': 'All'};

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _db.collection('requests').orderBy('at', descending: true).limit(400);
    return AdminPage(
      eyebrow: 'Content',
      title: 'Word requests',
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        child: Column(children: [
          SizedBox(
            height: 34,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final e in _statuses.entries)
                Padding(padding: const EdgeInsets.only(right: 6), child: Pill(e.value, dense: true, selected: _status == e.key, onTap: () => setState(() => _status = e.key))),
            ]),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded, color: kGold), hintText: 'Word, name or email'),
          ),
        ]),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return AdminProblem(error: snap.error!);
          if (!snap.hasData) return const OrbLoading(label: 'Reading requests…');
          final needle = _q.text.trim().toLowerCase();
          final all = snap.data!.docs;
          final docs = all.where((d) {
            final r = d.data();
            final st = '${r['status'] ?? 'new'}';
            if (_status != 'all' && st != _status) return false;
            if (needle.isEmpty) return true;
            return ['word', 'name', 'email', 'notes'].any((k) => '${r[k] ?? ''}'.toLowerCase().contains(needle));
          }).toList();
          final open = all.where((d) => (d.data()['status'] ?? 'new') == 'new').length;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 60), children: [
            Text('$open open · ${all.length} total', style: const TextStyle(color: kDim, fontSize: 12)),
            const SizedBox(height: 8),
            if (docs.isEmpty) EmptyNote(_status == 'new' ? 'No open requests. Nice.' : 'Nothing here.', icon: Icons.inbox_rounded),
            for (final d in docs) _RequestCard(id: d.id, r: d.data()),
          ]);
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.id, required this.r});
  final String id;
  final Map<String, dynamic> r;

  @override
  Widget build(BuildContext context) {
    final st = '${r['status'] ?? 'new'}';
    final who = [r['name'], r['email']].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    final color = st == 'done' ? kMint : (st == 'declined' ? kRose : kAmber);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Glass(
        radius: 20,
        onTap: () => pushAdmin(context, RequestDetailScreen(id: id)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${r['word'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800))),
            Tag('${r['kind'] ?? 'word'}', color: kSky),
            const SizedBox(width: 6),
            Tag(st == 'new' ? 'open' : st, color: color),
          ]),
          if ('${r['notes'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('${r['notes']}', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 12.5)),
          ],
          const SizedBox(height: 6),
          Text([who.isEmpty ? 'signed-out / unknown' : who, fmtAgo(r['at']), '${r['source'] ?? 'web'}'].join(' · '),
              style: const TextStyle(color: kFaint, fontSize: 11)),
        ]),
      ),
    );
  }
}

/// One request: who asked, what for, and the three ways to answer it.
class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key, required this.id});
  final String id;

  Future<void> _fulfil(BuildContext context, String key, String word, {String note = ''}) async {
    final r = await AdminData.run('fulfil-request', {'id': id, 'wordKey': key, 'word': word, 'note': note});
    final push = (r['push'] as Map?) ?? const {};
    if (context.mounted) {
      adminSnack(context, r['told'] == true ? 'Fulfilled — they were told in the app${(push['sent'] ?? 0) > 0 ? ' and by push' : ''}.' : 'Fulfilled (no account to tell).');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('requests').doc(id);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final r = snap.data?.data();
        return AdminPage(
          eyebrow: 'Word request',
          title: r == null ? 'Request' : '${r['word'] ?? ''}',
          body: snap.hasError
              ? AdminProblem(error: snap.error!)
              : r == null
                  ? const OrbLoading()
                  : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 60), children: [
                      Glass(
                        radius: 22,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          KV('Asked for', '${r['word'] ?? ''}'),
                          KV('Kind', '${r['kind'] ?? 'word'}'),
                          KV('Status', '${r['status'] ?? 'new'}'),
                          KV('Notes', '${r['notes'] ?? ''}'),
                          KV('From', [r['name'], r['email']].whereType<String>().where((s) => s.isNotEmpty).join(' · ')),
                          KV('Sent', fmtDate(r['at'], time: true)),
                          KV('Where', '${r['source'] ?? 'web'}'),
                          if ('${r['price'] ?? ''}'.isNotEmpty) KV('Offered', '${r['price']} ${r['currency'] ?? ''}'),
                          if ('${r['fulfilledWord'] ?? ''}'.isNotEmpty) KV('Fulfilled with', '${r['fulfilledWord']} · ${r['fulfilledBy'] ?? ''}'),
                          if ('${r['uid'] ?? ''}'.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Pill('Open their profile', icon: Icons.person_rounded, dense: true, onTap: () => pushAdmin(context, PersonAdminScreen(uid: '${r['uid']}'))),
                          ],
                        ]),
                      ),
                      const SectionHead('Answer', 'Create the word'),
                      Glass(
                        radius: 24,
                        glow: kGold.withValues(alpha: 0.15),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Write it, record the voice, add a video and pictures, then Publish. Publishing puts it in every app and tells them.',
                              style: TextStyle(color: kDim, fontSize: 12.5, height: 1.35)),
                          const SizedBox(height: 12),
                          GoldButton('Create “${r['word'] ?? ''}”', icon: Icons.auto_awesome_rounded, onTap: () {
                            final word = '${r['word'] ?? ''}'.trim();
                            final existing = ContentStore.instance.baseLibrary.where((w) => w.key == wordKeyFor(word));
                            pushAdmin(
                              context,
                              WordEditorScreen(
                                wordKey: existing.isNotEmpty ? existing.first.key : null,
                                prefill: {'word': word, 'notes': '', 'description': ''},
                                requestNote: 'Request from ${r['name'] ?? r['email'] ?? 'someone'}: “$word”${'${r['notes'] ?? ''}'.isNotEmpty ? ' — ${r['notes']}' : ''}',
                                onPublished: (key, w) => _fulfil(context, key, w),
                              ),
                            );
                          }),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        Pill('It already exists — link a word', icon: Icons.link_rounded, onTap: () async {
                          final key = await _pickWord(context, '${r['word'] ?? ''}');
                          if (key == null || !context.mounted) return;
                          try {
                            await _fulfil(context, key, '${r['word'] ?? key}');
                          } catch (e) {
                            if (context.mounted) adminSnack(context, '$e', error: true);
                          }
                        }),
                        if (r['status'] != 'declined' && r['status'] != 'done')
                          Pill('Decline', icon: Icons.close_rounded, color: kRose, onTap: () async {
                            final why = await askReason(context, 'Decline this request?', hint: 'Why (they will see this)', yes: 'Decline');
                            if (why == null) return;
                            try {
                              await ref.update({'status': 'declined', 'declinedAt': DateTime.now().millisecondsSinceEpoch, 'adminNote': why});
                              final uid = '${r['uid'] ?? ''}';
                              if (uid.isNotEmpty) {
                                await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').add({
                                  'title': 'About “${r['word']}”', 'body': why, 'kind': 'request', 'type': 'request', 'read': false,
                                  'at': Timestamp.now(), 'createdAt': FieldValue.serverTimestamp(),
                                });
                              }
                              await adminLog('request.decline', id, {'word': r['word'], 'reason': why});
                              if (context.mounted) adminSnack(context, 'Declined.');
                            } catch (e) {
                              if (context.mounted) adminSnack(context, '$e', error: true);
                            }
                          }),
                        if (r['status'] == 'done' || r['status'] == 'declined')
                          Pill('Reopen', icon: Icons.undo_rounded, onTap: () async {
                            await ref.update({'status': 'new'});
                            await adminLog('request.reopen', id);
                          }),
                      ]),
                    ]),
        );
      },
    );
  }

  Future<String?> _pickWord(BuildContext context, String hint) async {
    final words = ContentStore.instance.library;
    final c = TextEditingController(text: hint);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Theme(
        data: adminTheme(),
        child: StatefulBuilder(builder: (ctx, set) {
          final q = c.text.trim().toLowerCase();
          final shown = words.where((w) => q.isEmpty || w.word.toLowerCase().contains(q) || w.key.contains(q)).take(60).toList();
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(controller: c, onChanged: (_) => set(() {}), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Find the word')),
              ),
              Expanded(
                child: ListView(children: [
                  for (final w in shown)
                    ListTile(
                      title: Text(w.word, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(w.key, style: const TextStyle(color: kFaint, fontSize: 11)),
                      onTap: () => Navigator.pop(ctx, w.key),
                    ),
                ]),
              ),
            ]),
          );
        }),
      ),
    );
  }
}
