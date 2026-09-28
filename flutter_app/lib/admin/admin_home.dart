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
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import 'admin_state.dart';
import 'admin_ui.dart';
import 'editor/glass.dart';
import 'editor/ui_editor_screen.dart';
import 'quotes_admin.dart';
import 'requests_admin.dart';
import 'template/all_slots_screen.dart';
import 'template/ui_overrides.dart';
import 'words_admin.dart';

void openAdminHome(BuildContext context) {
  if (!AdminState.instance.isAdmin) return;
  Navigator.of(context).push(PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (_, __, ___) => const AdminHome(),
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
  ));
}

/// Admin home in the Fashion home's look: the film behind frosted glass,
/// a thinking orb in the hero, one card per admin page. Pages that come
/// in a later update show as real cards marked "Next update" — no numbers
/// are invented for them.
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
    void go(Widget w) {
      tapFeel();
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    }

    final top = MediaQuery.of(context).padding.top;
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(primary: kGold, secondary: kGold),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AdminBackdrop(
          dim: 0.4,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, top + 6, 16, 48),
            children: [
              Row(children: [
                IconButton(
                  tooltip: 'Back to the app',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
                const Spacer(),
                Pill(EditMode.instance.on ? 'Pencils on' : 'Pencils off',
                    icon: Icons.edit_rounded,
                    dense: true,
                    selected: EditMode.instance.on,
                    tooltip: 'Show a pencil on every picture, clip and line in the live app',
                    onTap: () => EditMode.instance.setOn(!EditMode.instance.on)),
              ]),
              const SizedBox(height: 6),
              const _Hero(),
              const SizedBox(height: 4),
              Text('Signed in as ${a.email ?? a.uid} · admin via ${a.how}',
                  textAlign: TextAlign.center, style: const TextStyle(color: kFaint, fontSize: 11)),
              const SizedBox(height: 18),
              _BigCard(
                title: 'UI Editor',
                sub: 'Change any page live — pictures, words, colours, fonts, animations, the order of sections — then publish to everyone.',
                icon: Icons.auto_awesome_mosaic_rounded,
                cta: 'Open editor',
                onTap: () {
                  bigFeel();
                  openUiEditor(context);
                },
              ),
              const Eyebrow('Content'),
              _Card(Icons.menu_book_rounded, 'Words', 'Edit, record the voice, publish or archive',
                  () => go(const WordsAdminScreen())),
              _Card(Icons.format_quote_rounded, 'Quotes', 'Dated lines and the rotation queue',
                  () => go(const QuotesAdminScreen())),
              _Card(Icons.inbox_rounded, 'Requests', 'Word requests from the app and the website',
                  () => go(const RequestsAdminScreen())),
              const Eyebrow('Run the app'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.25,
                children: [
                  const _Soon(Icons.people_alt_rounded, 'People', 'Look up members, plans and access'),
                  const _Soon(Icons.redeem_rounded, 'Earn & Gifts', 'Coins, rewards and gift codes'),
                  _Soon(Icons.timeline_rounded, 'Activity', 'Every admin change, newest first',
                      extra: 'Open log', onTap: () => go(const AdminLogScreen())),
                  const _Soon(Icons.insights_rounded, 'Dashboard', 'Members, sales and usage at a glance'),
                  const _Soon(Icons.tune_rounded, 'Settings', 'Admin team, keys and app switches'),
                ],
              ),
              const Eyebrow('This phone'),
              Glass(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(children: [
                  SwitchListTile(
                    value: EditMode.instance.on,
                    onChanged: EditMode.instance.setOn,
                    activeThumbColor: kGold,
                    title: const Text('Pencils on the live app', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Tap a pencil on any picture, clip or line to replace it',
                        style: TextStyle(color: kDim, fontSize: 12)),
                  ),
                  SwitchListTile(
                    value: EditMode.instance.fabPreference,
                    onChanged: (v) => EditMode.instance.setFab(v),
                    activeThumbColor: kGold,
                    title: const Text('Floating Edit button', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('A small button on every screen, only on this phone',
                        style: TextStyle(color: kDim, fontSize: 12)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.grid_view_rounded, color: kGold),
                    title: const Text('Every slot in the app', style: TextStyle(color: Colors.white)),
                    subtitle: Text('${UiOverrides.instance.all.length} changed',
                        style: const TextStyle(color: kDim, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: kFaint),
                    onTap: () => go(const AllSlotsScreen()),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          boxShadow: [BoxShadow(color: kGold.withValues(alpha: 0.28), blurRadius: 40, spreadRadius: 2)],
        ),
        alignment: Alignment.center,
        child: const ThinkingOrb(state: OrbState.composing, size: 70, theme: OrbTheme.dark),
      ),
      const SizedBox(height: 12),
      const Text('Admin',
          style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
      const SizedBox(height: 2),
      const Text('Shape what everyone sees', style: TextStyle(color: kGold, fontSize: 13, letterSpacing: 0.4)),
    ]);
  }
}

class _BigCard extends StatelessWidget {
  const _BigCard({required this.title, required this.sub, required this.icon, required this.cta, required this.onTap});
  final String title;
  final String sub;
  final IconData icon;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 28,
      padding: const EdgeInsets.all(18),
      glow: kGold.withValues(alpha: 0.18),
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
            child: Icon(icon, color: kGold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          ),
          if (UiOverrides.instance.all.isNotEmpty)
            AdminChip('${UiOverrides.instance.all.length} live edits', color: kMint),
        ]),
        const SizedBox(height: 10),
        Text(sub, style: const TextStyle(color: kDim, fontSize: 13, height: 1.35)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(99)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(cta, style: const TextStyle(color: kInk, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, color: kInk, size: 18),
          ]),
        ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(this.icon, this.title, this.sub, this.onTap);
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Glass(
          radius: 20,
          onTap: onTap,
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
              child: Icon(icon, color: kGold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: kDim, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: kFaint),
          ]),
        ),
      );
}

/// A page that arrives in a later update: a real card with a plain
/// description and the "Next update" tag — never placeholder numbers.
class _Soon extends StatelessWidget {
  const _Soon(this.icon, this.title, this.sub, {this.extra, this.onTap});
  final IconData icon;
  final String title;
  final String sub;
  final String? extra;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Glass(
        radius: 20,
        padding: const EdgeInsets.all(12),
        onTap: onTap ??
            () {
              tapFeel();
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('$title arrives in the next update.'),
              ));
            },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: kGold, size: 22),
            const Spacer(),
            const AdminChip('Next update', color: Colors.white54),
          ]),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 11)),
          if (extra != null) ...[
            const SizedBox(height: 4),
            Text('$extra ›', style: const TextStyle(color: kGold, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ],
        ]),
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
