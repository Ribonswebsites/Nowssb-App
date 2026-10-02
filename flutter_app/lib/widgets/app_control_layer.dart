/// The screens and banners the admin console can raise in every app
/// (data/app_control.dart): account blocked, force update (remote minimum
/// build), maintenance (banner or blocking screen) and the announcement
/// banner. Sits in MaterialApp.builder above every route. Fixed copy goes
/// through EditableLabel so the owner can reword it in the UI Editor.
library;

import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../admin/template/editable.dart';
import '../app_update.dart';
import '../data/app_control.dart';
import 'update_prompt.dart';

const _gold = Color(0xFFE8D5A3);
const _ink = Color(0xFF060C18);

class AppControlLayer extends StatelessWidget {
  const AppControlLayer({super.key, required this.child, this.navigatorKey});
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final c = AppControl.instance;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        Widget? cover;
        if (c.blocked) {
          cover = const BlockedScreen();
        } else if (c.mustUpdate) {
          cover = ForceUpdateScreen(navigatorKey: navigatorKey);
        } else if (c.maintenanceBlocks) {
          cover = const MaintenanceScreen();
        }
        final banner = cover != null
            ? null
            : (c.maintenance.on && !c.maintenance.blocking)
                ? _TopBanner(
                    child: AnnouncementBanner(
                      a: AppAnnouncement(on: true, title: c.maintenance.title.isEmpty ? 'Maintenance' : c.maintenance.title, body: c.maintenance.message, tone: 'rose', dismissible: false),
                    ),
                  )
                : c.showAnnouncement
                    ? _TopBanner(child: AnnouncementBanner(a: c.announcement, onClose: c.announcement.dismissible ? c.dismissAnnouncement : null))
                    : null;
        return Stack(children: [
          child,
          if (banner != null) banner,
          if (cover != null) Positioned.fill(child: cover),
        ]);
      },
    );
  }
}

class _TopBanner extends StatelessWidget {
  const _TopBanner({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Positioned(
      left: 10,
      right: 10,
      top: top + 6,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (_, v, w) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * -18), child: w)),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

Color _tone(String t) => switch (t) {
      'mint' => const Color(0xFF34D399),
      'rose' => const Color(0xFFFF7A90),
      'sky' => const Color(0xFF7CC4FF),
      _ => _gold,
    };

/// Frosted banner. Its text is the admin's own (data), so it is not a slot.
class AnnouncementBanner extends StatelessWidget {
  const AnnouncementBanner({super.key, required this.a, this.onClose});
  final AppAnnouncement a;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tone = _tone(a.tone);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          decoration: BoxDecoration(
            color: const Color(0xCC0B1222),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tone.withValues(alpha: 0.6)),
            boxShadow: [BoxShadow(color: tone.withValues(alpha: 0.18), blurRadius: 24)],
          ),
          child: Row(children: [
            Icon(Icons.campaign_rounded, color: tone, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                if (a.title.isNotEmpty) Text(a.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                if (a.body.isNotEmpty) Text(a.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, height: 1.3)),
              ]),
            ),
            if (a.cta.isNotEmpty && a.link.startsWith('http'))
              TextButton(
                onPressed: () => launchUrl(Uri.parse(a.link), mode: LaunchMode.externalApplication),
                child: Text(a.cta, style: TextStyle(color: tone, fontWeight: FontWeight.w800)),
              ),
            if (onClose != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onClose!();
                },
                icon: const Icon(Icons.close_rounded, color: Color(0x99FFFFFF), size: 18),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.icon, required this.color, required this.children});
  final IconData icon;
  final Color color;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black,
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, -0.4), radius: 1.2, colors: [Color(0xFF1A2440), Color(0xFF05080F)]),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(28),
          child: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 40)]),
                child: Icon(icon, color: color, size: 38),
              ),
              const SizedBox(height: 22),
              ...children,
            ]),
          ),
        ),
      );
}

const _h = TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4, decoration: TextDecoration.none);
const _p = TextStyle(color: Color(0xB3FFFFFF), fontSize: 14, height: 1.45, decoration: TextDecoration.none, fontWeight: FontWeight.w400);

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final reason = AppControl.instance.blockedReason;
    return _Cover(icon: Icons.lock_rounded, color: const Color(0xFFFF7A90), children: [
      const EditableLabel('app_control_layer.BlockedScreen', 'This account is paused', style: _h, textAlign: TextAlign.center),
      const SizedBox(height: 10),
      const EditableLabel('app_control_layer.BlockedScreen', 'NowssB has paused this account. If you think this is a mistake, write to us and we will look at it.',
          style: _p, textAlign: TextAlign.center),
      if (reason.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(reason, textAlign: TextAlign.center, style: _p.copyWith(color: Colors.white)),
      ],
      const SizedBox(height: 24),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _ink, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13)),
        onPressed: () => launchUrl(Uri.parse('mailto:nowssbonline@gmail.com?subject=Account%20paused')),
        child: const EditableLabel('app_control_layer.BlockedScreen', 'Contact support', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      TextButton(
        onPressed: () => FirebaseAuth.instance.signOut(),
        child: const EditableLabel('app_control_layer.BlockedScreen', 'Sign out', style: TextStyle(color: Color(0x99FFFFFF))),
      ),
    ]);
  }
}

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, this.navigatorKey});
  final GlobalKey<NavigatorState>? navigatorKey;
  @override
  Widget build(BuildContext context) {
    final c = AppControl.instance;
    return _Cover(icon: Icons.system_update_rounded, color: _gold, children: [
      const EditableLabel('app_control_layer.ForceUpdateScreen', 'Update NowssB', style: _h, textAlign: TextAlign.center),
      const SizedBox(height: 10),
      c.updateMessage.isNotEmpty
          ? Text(c.updateMessage, style: _p, textAlign: TextAlign.center)
          : const EditableLabel('app_control_layer.ForceUpdateScreen', 'This version is no longer supported. Update to keep practising.', style: _p, textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text('Build ${NwsbAppUpdate.currentBuild} → ${c.minBuild}', style: _p.copyWith(fontSize: 11, color: const Color(0x66FFFFFF))),
      const SizedBox(height: 24),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _ink, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13)),
        onPressed: () async {
          final u = NwsbUpdater.instance;
          if (u.supported) {
            await u.check(force: true);
            final ctx = navigatorKey?.currentContext;
            if (u.available != null && ctx != null && ctx.mounted) {
              await showNwsbUpdateDialog(ctx);
              return;
            }
          }
          final url = kNwsbPlayBuild
              ? 'https://play.google.com/store/apps/details?id=com.nowssb.app'
              : (c.updateUrl.startsWith('http') ? c.updateUrl : 'https://nowssb.com');
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        child: const EditableLabel('app_control_layer.ForceUpdateScreen', 'Update now', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    ]);
  }
}

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final m = AppControl.instance.maintenance;
    return _Cover(icon: Icons.construction_rounded, color: const Color(0xFF7CC4FF), children: [
      m.title.isNotEmpty
          ? Text(m.title, style: _h, textAlign: TextAlign.center)
          : const EditableLabel('app_control_layer.MaintenanceScreen', 'Back in a moment', style: _h, textAlign: TextAlign.center),
      const SizedBox(height: 10),
      m.message.isNotEmpty
          ? Text(m.message, style: _p, textAlign: TextAlign.center)
          : const EditableLabel('app_control_layer.MaintenanceScreen', 'NowssB is getting an upgrade. Please check back shortly.', style: _p, textAlign: TextAlign.center),
      if (m.until > 0) ...[
        const SizedBox(height: 10),
        Text('Expected back ${DateTime.fromMillisecondsSinceEpoch(m.until).toLocal().toString().substring(0, 16)}', style: _p.copyWith(fontSize: 12)),
      ],
    ]);
  }
}
