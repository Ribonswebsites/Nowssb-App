/// Content tab — everything people read and hear: a new word (title, text,
/// meaning, description, stages, picture, video and the voice recorded right
/// here), the word library, the requests inbox with "answer → create the
/// word", quotes, and the UI Editor for every page's pictures and copy.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_kit.dart';
import 'editor/ui_editor_screen.dart';
import 'quotes_admin.dart';
import 'requests_admin.dart';
import 'template/all_slots_screen.dart';
import 'templates_admin.dart';
import 'words_admin.dart';

class ContentAdminScreen extends StatefulWidget {
  const ContentAdminScreen({super.key});
  @override
  State<ContentAdminScreen> createState() => _ContentAdminScreenState();
}

class _ContentAdminScreenState extends State<ContentAdminScreen> {
  final _db = FirebaseFirestore.instance;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _open =
      _db.collection('requests').where('status', isEqualTo: 'new').limit(200).snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _words =
      _db.collection('words').orderBy('updatedAt', descending: true).limit(6).snapshots();

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Words, voice, quotes, requests',
      title: 'Content',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 60),
        children: [
          Glass(
            radius: 28,
            glow: kGold.withValues(alpha: 0.18),
            padding: const EdgeInsets.all(18),
            onTap: () => pushAdmin(context, const WordEditorScreen()),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                  child: const Icon(Icons.add_rounded, color: kGold, size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('New word', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                ),
                const Tag('Record voice', icon: Icons.mic_rounded, color: kRose),
              ]),
              const SizedBox(height: 10),
              const Text('Title, text, meaning, description, stages, a picture, a video — and record the voice right here (record, stop, play, re-record), or pick an audio file. Save a draft or publish to every app.',
                  style: TextStyle(color: kDim, fontSize: 13, height: 1.35)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(99)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Write a word', style: TextStyle(color: kInk, fontWeight: FontWeight.w800)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: kInk, size: 18),
                ]),
              ),
            ]),
          ),
          SectionHead('Requests', 'What people asked for',
              trailing: Pill('All requests', dense: true, onTap: () => pushAdmin(context, const RequestsAdminScreen()))),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _open,
            builder: (context, snap) {
              if (snap.hasError) return AdminProblem(error: snap.error!);
              if (!snap.hasData) return const Padding(padding: EdgeInsets.all(20), child: OrbLoading(label: 'Reading requests…', size: 40));
              final docs = [...snap.data!.docs]..sort((a, b) => msOf(b.data()['at']).compareTo(msOf(a.data()['at'])));
              if (docs.isEmpty) return const EmptyNote('No open requests. When someone asks for a word it shows here (and in your Admin inbox).');
              return Column(children: [
                for (final d in docs.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Glass(
                      radius: 18,
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      onTap: () => pushAdmin(context, RequestDetailScreen(id: d.id)),
                      child: Row(children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: kAmber.withValues(alpha: 0.16), shape: BoxShape.circle),
                          child: const Icon(Icons.inbox_rounded, color: kAmber, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${d.data()['word'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
                            Text(
                              [
                                '${d.data()['name'] ?? d.data()['email'] ?? ''}',
                                fmtAgo(d.data()['at']),
                                if ('${d.data()['notes'] ?? ''}'.isNotEmpty) '${d.data()['notes']}',
                              ].where((e) => e.isNotEmpty).join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: kDim, fontSize: 11.5),
                            ),
                          ]),
                        ),
                        const Tag('Answer', color: kGold),
                        const Icon(Icons.chevron_right_rounded, color: kFaint),
                      ]),
                    ),
                  ),
                if (docs.length > 6)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Pill('${docs.length - 6} more open', dense: true, onTap: () => pushAdmin(context, const RequestsAdminScreen())),
                  ),
              ]);
            },
          ),
          const SectionHead('Library', 'Words and quotes'),
          TileGrid(children: [
            _Card(Icons.menu_book_rounded, 'Words', 'Every word: text, meanings, stages, voice, video, pictures; publish or archive', kSky,
                () => pushAdmin(context, const WordsAdminScreen())),
            _Card(Icons.format_quote_rounded, 'Quotes', 'Dated lines and the rotation queue', kViolet, () => pushAdmin(context, const QuotesAdminScreen())),
          ]),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _words,
            builder: (context, snap) {
              final docs = snap.data?.docs ?? const [];
              if (docs.isEmpty) return const SizedBox.shrink();
              return Glass(
                radius: 20,
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('RECENTLY PUBLISHED', style: TextStyle(color: kGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                  for (final d in docs)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon('${d.data()['audio'] ?? ''}'.isNotEmpty ? Icons.graphic_eq_rounded : Icons.text_fields_rounded,
                          color: '${d.data()['audio'] ?? ''}'.isNotEmpty ? kMint : kFaint, size: 18),
                      title: Text('${d.data()['word'] ?? d.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      subtitle: Text('${d.data()['status'] ?? ''} · v${d.data()['version'] ?? 1} · ${fmtAgo(d.data()['updatedAt'])}',
                          style: const TextStyle(color: kFaint, fontSize: 11)),
                      trailing: const Icon(Icons.edit_rounded, color: kGold, size: 18),
                      onTap: () => pushAdmin(context, WordEditorScreen(wordKey: d.id)),
                    ),
                ]),
              );
            },
          ),
          const SectionHead('Screens', 'Pictures, copy and layout of every page'),
          Glass(
            radius: 22,
            padding: const EdgeInsets.all(14),
            onTap: () => pushAdmin(context, const TemplatesAdminScreen()),
            child: const Row(children: [
              Icon(Icons.dashboard_customize_rounded, color: kGold, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Templates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(height: 2),
                  Text('Header through every section, and every banner. Deleting one never removes it from here.',
                      style: TextStyle(color: kDim, fontSize: 12, height: 1.3)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: kFaint),
            ]),
          ),
          const SizedBox(height: 10),
          TileGrid(children: [
            _Card(Icons.auto_awesome_mosaic_rounded, 'UI Editor', 'The real page in a phone frame — change, preview, publish', kGold, () {
              bigFeel();
              openUiEditor(context);
            }),
            _Card(Icons.grid_view_rounded, 'Every slot', 'Each picture, clip and line the app can swap', kMint, () => pushAdmin(context, const AllSlotsScreen())),
          ]),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(this.icon, this.title, this.sub, this.color, this.onTap);
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Glass(
        radius: 22,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 14)]),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          Text(sub, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 11.5)),
        ]),
      );
}
