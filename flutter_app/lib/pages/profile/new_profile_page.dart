/// Rebuilt Profile page (flag `newui_profile`). Sits on the app's original
/// background (AppBackdrop: the user's chosen video/image), with the shared
/// kit's frosted NGlass cards on top, matching card-reference-exact.png.
library;

import 'package:flutter/material.dart';

import '../../nowssb_ui/cards.dart';
import '../../nowssb_ui/glass_core.dart';
import '../../nowssb_ui/pills_chips.dart';
import '../../nowssb_ui/tokens.dart';
import '../../screens/app_settings.dart';
import '../../screens/progress/progress_screen.dart';
import '../../screens/saved_words.dart';
import '../../screens/subscription.dart';
import '../../widgets/app_backdrop.dart';
import 'milestones.dart';
import 'profile_data.dart';

const _ink = NTokens.textHi;
const _sub = NTokens.textLo;

/// Kit NGlass card plus a screen-reader label (no page-local glass).
Widget _card({Key? key, required Widget child, EdgeInsets padding = const EdgeInsets.all(16), VoidCallback? onTap, String? label}) => Semantics(
      key: key,
      button: onTap != null,
      label: label,
      child: NGlass(padding: padding, onTap: onTap, child: child),
    );

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
  const NewProfilePage({super.key, this.source = const LiveProfileSource(), this.onNavigate = defaultProfileNav, this.animate = true, this.backdrop});
  final ProfileSource source;
  final ProfileNav onNavigate;
  final bool animate;
  /// Tests pass a still frame; the app uses its original AppBackdrop.
  final Widget? backdrop;

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
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: widget.backdrop ?? const AppBackdrop()),
        SafeArea(child: _body()),
      ]),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: _ink)),
          SizedBox(height: 14),
          Text('Gathering your calm…', key: Key('profile-loading'), style: TextStyle(color: _sub)),
        ]));
      case _Phase.error:
        return _message(const Key('profile-error'), Icons.cloud_off_rounded, 'We couldn’t load your profile', 'Your practice is safe. Try again in a moment.');
      case _Phase.offline:
        return _message(const Key('profile-offline'), Icons.wifi_off_rounded, 'You’re offline', 'Connect to the internet to see your journey.');
      case _Phase.ready:
        return RefreshIndicator(onRefresh: _load, color: NTokens.violet, child: _ready(_data!));
    }
  }

  Widget _message(Key key, IconData icon, String title, String body) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _card(
            child: Column(key: key, mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: _ink, size: 36),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(body, style: const TextStyle(color: _sub), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              GlassPill(key: const Key('profile-retry'), label: 'Try again', style: PillStyle.white, onTap: _load),
            ]),
          ),
        ),
      );

  Widget _ready(ProfileData d) {
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
        _enter(0, Semantics(
          key: const Key('profile-hero'),
          label: 'Profile of ${d.name}',
          child: MeditationCard(
            image: d.avatarUrl != null ? NetworkImage(d.avatarUrl!) : null,
            title: d.name,
            subtitle: 'Level ${d.level} · ${d.signedIn ? 'Synced to your account' : 'Saved on this phone'}',
            cta: 'Progress',
            onCta: () => widget.onNavigate(context, 'progress'),
          ),
        )),
        const SizedBox(height: 14),
        if (d.isEmpty)
          _card(
            key: const Key('profile-empty'),
            onTap: () => widget.onNavigate(context, 'progress'),
            label: 'Start your first session',
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your journey starts with one breath', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('Finish a practice and your streak, minutes and week will appear here.', style: TextStyle(color: _sub)),
            ]),
          )
        else ...[
          _enter(1, Row(children: [
            Expanded(child: _stat('Day streak', '${d.streak}', const Key('stat-streak'))),
            const SizedBox(width: 10),
            Expanded(child: _stat('Minutes', '${d.minutes}', const Key('stat-minutes'))),
            const SizedBox(width: 10),
            Expanded(child: _stat('Sessions', '${d.sessions}', const Key('stat-sessions'))),
          ])),
          const SizedBox(height: 14),
          _enter(2, _week(d.week)),
        ],
        const SizedBox(height: 14),
        _enter(3, _milestones(d)),
        const SizedBox(height: 14),
        _link('progress', Icons.insights_rounded, 'My progress', 'See your full practice history'),
        _link('saved', Icons.bookmark_rounded, 'Saved words', 'Words you kept for later'),
        _link('subscription', Icons.workspace_premium_rounded, 'Subscription', 'Your plan and benefits'),
        _link('settings', Icons.settings_rounded, 'Settings', 'Sound, reminders and account'),
      ],
    );
  }

  bool get _motion => widget.animate && !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  /// Gentle staggered rise-in; skipped entirely under reduce-motion.
  Widget _enter(int i, Widget child) {
    if (!_motion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + 120 * i),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c)),
      child: child,
    );
  }

  Widget _milestones(ProfileData d) {
    final list = milestonesFor(d);
    final earned = list.where((m) => m.earned).length;
    return _card(
      key: const Key('profile-milestones'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Milestones · $earned of ${list.length}', style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final m in list)
            Semantics(
              label: '${m.title}, ${m.earned ? 'earned' : 'goal: ${m.goal}'}',
              child: Tooltip(
                message: m.earned ? m.title : m.goal,
                child: Container(
                  key: Key('milestone-${m.id}-${m.earned ? 'on' : 'off'}'),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: m.earned ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.06),
                    border: Border.all(color: const Color(0x44FFFFFF)),
                  ),
                  child: Icon(m.earned ? Icons.spa_rounded : Icons.lock_outline_rounded, color: m.earned ? const Color(0xFF2A2340) : _sub, size: 22),
                ),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _stat(String label, String value, Key key) => _card(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(children: [
          Text(value, key: key, style: const TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _sub, fontSize: 12)),
        ]),
      );

  Widget _week(List<bool> week) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return _card(
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (var i = 0; i < 7; i++)
          Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < week.length && week[i] ? Colors.white : Colors.transparent,
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
        child: _card(
          key: Key('profile-link-$target'),
          onTap: () => widget.onNavigate(context, target),
          label: title,
          child: Row(children: [
            Icon(icon, color: _ink),
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
