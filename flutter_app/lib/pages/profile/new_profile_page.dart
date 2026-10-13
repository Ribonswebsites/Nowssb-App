/// Rebuilt Profile page (flag `newui_profile`). Soft violet glass, meditative,
/// one clear action per card (spec 0.5, 14-16, 19-20).
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../screens/app_settings.dart';
import '../../screens/progress/progress_screen.dart';
import '../../screens/saved_words.dart';
import '../../screens/subscription.dart';
import 'aura_painter.dart';
import 'profile_data.dart';

const _ink = Color(0xFFF4F1FF);
const _sub = Color(0xB3E6E0FF);
const _violet = Color(0xFFB79CFF);

/// Glass pane used by every item (spec 0.5). Page-local stand-in for the
/// shared kit's GlassWrapper (14.2); swap when Bug Hunter's kit lands.
class ProfileGlass extends StatelessWidget {
  const ProfileGlass({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.semanticLabel});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(22);
    Widget body = ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x26FFFFFF), Color(0x0FFFFFFF)]),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (onTap != null) {
      body = Material(type: MaterialType.transparency, child: InkWell(borderRadius: r, onTap: onTap, child: body));
    }
    return Semantics(button: onTap != null, label: semanticLabel, child: body);
  }
}

typedef ProfileNav = void Function(BuildContext context, String target);

void defaultProfileNav(BuildContext context, String target) {
  final Widget page = switch (target) {
    'progress' => const PracticeProgressScreen(),
    'saved' => const SavedWordsScreen(),
    'subscription' => const SubscriptionScreen(),
    _ => const AppSettingsScreen(),
  };
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class NewProfilePage extends StatefulWidget {
  const NewProfilePage({super.key, this.source = const LiveProfileSource(), this.onNavigate = defaultProfileNav, this.animate = true});
  final ProfileSource source;
  final ProfileNav onNavigate;
  final bool animate;

  @override
  State<NewProfilePage> createState() => _NewProfilePageState();
}

enum _Phase { loading, ready, error, offline }

class _NewProfilePageState extends State<NewProfilePage> {
  _Phase _phase = _Phase.loading;
  ProfileData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _phase = _Phase.loading);
    try {
      final d = await widget.source.load();
      if (!mounted) return;
      setState(() {
        _data = d;
        _phase = _Phase.ready;
      });
    } on ProfileOffline {
      if (mounted) setState(() => _phase = _Phase.offline);
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0A16),
      body: Stack(children: [
        Positioned.fill(child: widget.animate ? const ProfileAura() : CustomPaint(painter: AuraPainter(0))),
        SafeArea(child: _body()),
      ]),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: _violet)),
          SizedBox(height: 14),
          Text('Gathering your calm…', key: Key('profile-loading'), style: TextStyle(color: _sub)),
        ]));
      case _Phase.error:
        return _message(const Key('profile-error'), Icons.cloud_off_rounded, 'We couldn’t load your profile', 'Your practice is safe. Try again in a moment.');
      case _Phase.offline:
        return _message(const Key('profile-offline'), Icons.wifi_off_rounded, 'You’re offline', 'Connect to the internet to see your journey.');
      case _Phase.ready:
        return RefreshIndicator(onRefresh: _load, color: _violet, child: _ready(_data!));
    }
  }

  Widget _message(Key key, IconData icon, String title, String body) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ProfileGlass(
            child: Column(key: key, mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: _violet, size: 36),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(body, style: const TextStyle(color: _sub), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('profile-retry'),
                style: FilledButton.styleFrom(backgroundColor: _violet, foregroundColor: const Color(0xFF1B1530), minimumSize: const Size(140, 48)),
                onPressed: _load,
                child: const Text('Try again'),
              ),
            ]),
          ),
        ),
      );

  Widget _ready(ProfileData d) {
    final initial = d.name.isNotEmpty ? d.name.characters.first.toUpperCase() : '·';
    return ListView(
      key: const Key('profile-ready'),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Row(children: [
          const Expanded(child: Text('You', style: TextStyle(color: _ink, fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: 1))),
          IconButton(
            key: const Key('profile-settings'),
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded, color: _ink),
            onPressed: () => widget.onNavigate(context, 'settings'),
          ),
        ]),
        const SizedBox(height: 12),
        ProfileGlass(
          child: Row(children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0x55B79CFF),
              foregroundImage: d.avatarUrl != null ? NetworkImage(d.avatarUrl!) : null,
              child: Text(initial, style: const TextStyle(color: _ink, fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name, key: const Key('profile-name'), style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Level ${d.level} · ${d.signedIn ? 'Synced' : 'On this phone'}', style: const TextStyle(color: _sub)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        if (d.isEmpty)
          ProfileGlass(
            key: const Key('profile-empty'),
            onTap: () => widget.onNavigate(context, 'progress'),
            semanticLabel: 'Start your first session',
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your journey starts with one breath', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('Finish a practice and your streak, minutes and week will appear here.', style: TextStyle(color: _sub)),
            ]),
          )
        else ...[
          Row(children: [
            Expanded(child: _stat('Day streak', '${d.streak}', const Key('stat-streak'))),
            const SizedBox(width: 10),
            Expanded(child: _stat('Minutes', '${d.minutes}', const Key('stat-minutes'))),
            const SizedBox(width: 10),
            Expanded(child: _stat('Sessions', '${d.sessions}', const Key('stat-sessions'))),
          ]),
          const SizedBox(height: 14),
          _week(d.week),
        ],
        const SizedBox(height: 14),
        _link('progress', Icons.insights_rounded, 'My progress', 'See your full practice history'),
        _link('saved', Icons.bookmark_rounded, 'Saved words', 'Words you kept for later'),
        _link('subscription', Icons.workspace_premium_rounded, 'Subscription', 'Your plan and benefits'),
        _link('settings', Icons.settings_rounded, 'Settings', 'Sound, reminders and account'),
      ],
    );
  }

  Widget _stat(String label, String value, Key key) => ProfileGlass(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(children: [
          Text(value, key: key, style: const TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _sub, fontSize: 12)),
        ]),
      );

  Widget _week(List<bool> week) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return ProfileGlass(
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (var i = 0; i < 7; i++)
          Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < week.length && week[i] ? _violet : Colors.transparent,
                border: Border.all(color: const Color(0x55FFFFFF)),
              ),
            ),
            const SizedBox(height: 6),
            Text(days[i], style: const TextStyle(color: _sub, fontSize: 12)),
          ]),
      ]),
    );
  }

  Widget _link(String target, IconData icon, String title, String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ProfileGlass(
          key: Key('profile-link-$target'),
          onTap: () => widget.onNavigate(context, target),
          semanticLabel: title,
          child: Row(children: [
            Icon(icon, color: _violet),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w500)),
                Text(hint, style: const TextStyle(color: _sub, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: _sub),
          ]),
        ),
      );
}
