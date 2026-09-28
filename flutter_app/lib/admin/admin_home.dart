/// Admin mode — home.
///
/// Reached from App Settings → Admin or the floating Edit layout button,
/// both of which exist only for an account the SERVER marks as admin
/// (Firestore `admins/{uid}`, or the `admin` custom claim). Every write made
/// from here is also enforced by firestore.rules, so the switch in the app
/// is a convenience, not the security.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_state.dart';
import 'admin_ui.dart';
import 'quotes_admin.dart';
import 'requests_admin.dart';
import 'template/all_slots_screen.dart';
import 'template/ui_overrides.dart';
import 'words_admin.dart';

void openAdminHome(BuildContext context) {
  if (!AdminState.instance.isAdmin) return;
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdminHome()));
}

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context);
    final a = AdminState.instance;
    if (!a.isAdmin) {
      return const AdminScaffold(
        title: 'Admin',
        body: Center(child: Text('This account is not an admin.', style: TextStyle(color: kAdminDim))),
      );
    }
    final edit = EditMode.instance;
    void go(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    return AdminScaffold(
      title: 'Admin',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Text('Signed in as ${a.email ?? a.uid} · admin via ${a.how}',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 14),
          const _Head('Content'),
          _Row(Icons.menu_book_rounded, 'Words', 'Edit, record the voice, publish or archive',
              () => go(const WordsAdminScreen())),
          _Row(Icons.format_quote_rounded, 'Quotes', 'Dated lines and the rotation queue',
              () => go(const QuotesAdminScreen())),
          _Row(Icons.inbox_rounded, 'Requests', 'Word requests from the app and the website',
              () => go(const RequestsAdminScreen())),
          const SizedBox(height: 18),
          const _Head('Template editor'),
          AdminPanel(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(children: [
              SwitchListTile(
                value: edit.on,
                onChanged: edit.setOn,
                activeThumbColor: kAdminGold,
                title: const Text('Edit mode', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Pencils on every picture, clip and line — tap one to replace it',
                    style: TextStyle(color: kAdminDim, fontSize: 12)),
              ),
              SwitchListTile(
                value: edit.fabPreference,
                onChanged: (v) => edit.setFab(v),
                activeThumbColor: kAdminGold,
                title: const Text('Show Edit layout button', style: TextStyle(color: Colors.white)),
                subtitle: const Text('A floating button on every screen, only on this phone',
                    style: TextStyle(color: kAdminDim, fontSize: 12)),
              ),
              ListTile(
                leading: const Icon(Icons.grid_view_rounded, color: kAdminGold),
                title: const Text('All slots', style: TextStyle(color: Colors.white)),
                subtitle: Text('${UiOverrides.instance.all.length} changed',
                    style: const TextStyle(color: kAdminDim, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () => go(const AllSlotsScreen()),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          const _Head('Activity'),
          _Row(Icons.history_rounded, 'Activity log', 'Every admin change, newest first',
              () => go(const AdminLogScreen())),
          const SizedBox(height: 18),
          const _Head('Coming next'),
          const _Soon(Icons.insights_rounded, 'Dashboard'),
          const _Soon(Icons.people_alt_rounded, 'Users'),
          const _Soon(Icons.toll_rounded, 'Coins & gifts'),
        ],
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text.toUpperCase(),
            style: const TextStyle(color: kAdminGold, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.title, this.sub, this.onTap);
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AdminPanel(
          onTap: onTap,
          child: Row(children: [
            Icon(icon, color: kAdminGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: kAdminDim, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ]),
        ),
      );
}

class _Soon extends StatelessWidget {
  const _Soon(this.icon, this.title);
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AdminPanel(
          child: Row(children: [
            Icon(icon, color: Colors.white30),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 15))),
            const AdminChip('coming next', color: Colors.white38),
          ]),
        ),
      );
}

/// `adminLog`, newest first. Read-only: the rules allow no edits or deletes.
class AdminLogScreen extends StatelessWidget {
  const AdminLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance.collection('adminLog').orderBy('at', descending: true).limit(200);
    return AdminScaffold(
      title: 'Activity log',
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load: ${snap.error}', style: const TextStyle(color: kAdminDim)));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Nothing yet.', style: TextStyle(color: kAdminDim)));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final detail = d['detail'];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${d['action'] ?? ''} · ${d['target'] ?? ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 13.5)),
                subtitle: Text(
                  [
                    '${d['email'] ?? d['uid'] ?? ''}',
                    adminAgo(d['at']),
                    if (detail is Map && detail.isNotEmpty)
                      detail.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kAdminDim, fontSize: 11.5),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
