/// NowssB Admin — the admin's own app inside the same APK.
///
/// An admin account launches straight here (admin_mode.dart). Its own dark
/// shell: the NowssB Admin bar (inbox, switch to the user app, account) and
/// five tabs — Dashboard, People, Content, Money, Control. Everything opened
/// from a tab slides over the shell with a back arrow.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_inbox.dart';
import 'admin_kit.dart';
import 'admin_mode.dart';
import 'admin_state.dart';
import 'content_admin.dart';
import 'dashboard_admin.dart';
import 'earn_admin.dart';
import 'people_admin.dart';
import 'settings_admin.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  /// The open tab, kept across switches to the user app and back.
  static int lastTab = 0;

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _Tab {
  const _Tab(this.label, this.icon, this.iconOn);
  final String label;
  final IconData icon;
  final IconData iconOn;
}

const _tabs = [
  _Tab('Dashboard', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
  _Tab('People', Icons.people_alt_outlined, Icons.people_alt_rounded),
  _Tab('Content', Icons.auto_stories_outlined, Icons.auto_stories_rounded),
  _Tab('Money', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded),
  _Tab('Control', Icons.tune_outlined, Icons.tune_rounded),
];

class _AdminAppState extends State<AdminApp> {
  late int _tab = AdminApp.lastTab;
  final Set<int> _built = {};

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const DashboardAdminScreen();
      case 1:
        return const PeopleAdminScreen();
      case 2:
        return const ContentAdminScreen();
      case 3:
        return const EarnAdminScreen();
      default:
        return const SettingsAdminScreen();
    }
  }

  void _go(int i) {
    if (i == _tab) return;
    tapFeel();
    setState(() => _tab = AdminApp.lastTab = i);
  }

  @override
  Widget build(BuildContext context) {
    _built.add(_tab);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Theme(
      data: adminTheme(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: PopScope(
          canPop: _tab == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _tab != 0) _go(0);
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            extendBody: true,
            body: AdminBackdrop(
              dim: 0.25,
              child: Column(children: [
                const _AdminBar(),
                Expanded(
                  child: AdminTabScope(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: IndexedStack(
                        index: _tab,
                        children: [
                          for (var i = 0; i < _tabs.length; i++)
                            _built.contains(i)
                                ? Padding(padding: EdgeInsets.only(bottom: 74 + bottom), child: _page(i))
                                : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            bottomNavigationBar: _AdminNav(index: _tab, onTap: _go),
          ),
        ),
      ),
    );
  }
}

/// "NowssB Admin" bar: mark, title, inbox with unread count, switch to the
/// user app, account menu.
class _AdminBar extends StatelessWidget {
  const _AdminBar();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final a = AdminState.instance;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 8, 10, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF0070B16), Color(0x00070B16)],
        ),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFF3E5BD), Color(0xFFC9A961)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: kGold.withValues(alpha: 0.35), blurRadius: 16)],
          ),
          child: const Icon(Icons.shield_moon_rounded, color: kInk, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            RichText(
              text: const TextSpan(children: [
                TextSpan(text: 'NowssB ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                TextSpan(text: 'Admin', style: TextStyle(color: kGold, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              ]),
            ),
            Text(a.email ?? a.uid ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kFaint, fontSize: 10.5)),
          ]),
        ),
        const _InboxBell(),
        const SizedBox(width: 4),
        _SwitchPill(onTap: () {
          bigFeel();
          openMemberApp(context);
        }),
        PopupMenuButton<String>(
          tooltip: 'Account',
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
          color: const Color(0xFF111A2B),
          onSelected: (v) async {
            if (v == 'user') openMemberApp(context);
            if (v == 'out') {
              final ok = await confirmAction(context, 'Sign out?', 'You will need to sign in again to use NowssB or NowssB Admin.', yes: 'Sign out');
              if (ok) await FirebaseAuth.instance.signOut();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'user', child: Text('Open user app')),
            const PopupMenuItem(value: 'out', child: Text('Sign out')),
          ],
        ),
      ]),
    );
  }
}

class _SwitchPill extends StatelessWidget {
  const _SwitchPill({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Open the user app (switch back with the gold Admin pill)',
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: kGold.withValues(alpha: 0.55)),
              color: kGold.withValues(alpha: 0.10),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.swap_horiz_rounded, color: kGold, size: 16),
              SizedBox(width: 4),
              Text('User app', style: TextStyle(color: kGold, fontSize: 11.5, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );
}

/// Bell with the number of unseen admin alerts (adminAlerts.seen == false).
class _InboxBell extends StatefulWidget {
  const _InboxBell();
  @override
  State<_InboxBell> createState() => _InboxBellState();
}

class _InboxBellState extends State<_InboxBell> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _unseen =
      FirebaseFirestore.instance.collection('adminAlerts').where('seen', isEqualTo: false).limit(99).snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _unseen,
      builder: (context, snap) {
        final n = snap.data?.docs.length ?? 0;
        return IconButton(
          tooltip: 'Admin inbox',
          onPressed: () => pushAdmin(context, const AdminInboxScreen()),
          icon: Stack(clipBehavior: Clip.none, children: [
            Icon(n > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: n > 0 ? kGold : Colors.white70),
            if (n > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: kRose, borderRadius: BorderRadius.circular(99)),
                  child: Text(n > 98 ? '99+' : '$n', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
        );
      },
    );
  }
}

class _AdminNav extends StatelessWidget {
  const _AdminNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 10),
      child: Glass(
        radius: 26,
        blur: 24,
        fill: const Color(0xCC0B1222),
        edge: kGold.withValues(alpha: 0.22),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: i == index ? kGold.withValues(alpha: 0.14) : Colors.transparent,
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(i == index ? _tabs[i].iconOn : _tabs[i].icon, color: i == index ? kGold : Colors.white60, size: 22),
                    const SizedBox(height: 3),
                    Text(_tabs[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                            color: i == index ? kGold : Colors.white60,
                            fontSize: 10.5,
                            fontWeight: i == index ? FontWeight.w800 : FontWeight.w600)),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Opens what an admin alert points at (`route` on adminAlerts).
void openAdminRoute(BuildContext context, String route) {
  if (route.startsWith('person:')) {
    final uid = route.substring(7);
    if (uid.isNotEmpty) unawaited(openPerson(context, uid));
    return;
  }
  switch (route) {
    case 'requests':
      unawaited(openRequests(context));
      return;
    case 'payouts':
      unawaited(pushAdmin(context, const EarnAdminScreen()));
      return;
    default:
      unawaited(pushAdmin(context, const AdminInboxScreen()));
  }
}
