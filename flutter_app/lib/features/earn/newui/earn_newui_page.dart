import 'package:flutter/material.dart';

import '../../../nowssb_ui/nowssb_ui.dart';

import 'earn_motion.dart';
import 'earn_view_data.dart';

/// Taps the Earn hub hands back to its host, so routing stays in one place
/// (swap to AppRoutes from the shared kit when it lands).
class EarnActions {
  const EarnActions({
    this.onRetry,
    this.onSignIn,
    this.onEarnings,
    this.onTeam,
    this.onShareCode,
    this.onTask,
    this.onHelp,
  });
  final VoidCallback? onRetry;
  final VoidCallback? onSignIn;
  final VoidCallback? onEarnings;
  final VoidCallback? onTeam;
  final VoidCallback? onShareCode;
  final void Function(String taskId)? onTask;
  final VoidCallback? onHelp;
}

const _ink = Color(0xFFF4F0FF);
const _soft = Color(0xB3F4F0FF);
const _big = TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w700);
const _medals = [Color(0xFFD9A066), Color(0xFFCBD3E1), Color(0xFFF2C94C), Color(0xFF9EE7FF)];
const _medalNames = ['Bronze', 'Silver', 'Gold', 'Diamond'];

/// The kit's default video; tests set [earnVideoOff] (no video plugin there).
bool earnVideoOff = false;

/// First frame of the kit's default video, shown until it plays.
const kEarnVideoPoster = 'assets/video/7e4d709136dc254a_grok_video_2026-07-18-15-53-02_ubjx5b-poster.webp';
String? earnVideoAsset() => earnVideoOff ? null : const GlassVideoScaffold(body: SizedBox()).videoAsset;

/// Glass card from the shared kit (spec 14.2).
class EarnGlass extends StatelessWidget {
  const EarnGlass({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => NGlass(padding: padding, child: child);
}

class EarnNewUiPage extends StatelessWidget {
  const EarnNewUiPage({super.key, required this.data, this.actions = const EarnActions()});
  final EarnViewData data;
  final EarnActions actions;

  @override
  Widget build(BuildContext context) {
    // The app's original video background behind see-through glass (rules).
    return GlassVideoScaffold(
      videoAsset: earnVideoAsset(),
      posterAsset: kEarnVideoPoster,
      body: Column(children: [
        _TopBar(onHelp: actions.onHelp),
        Expanded(child: _body()),
      ]),
    );
  }

  Widget _body() {
    switch (data.load) {
      case EarnLoad.loading:
        return const _Loading();
      case EarnLoad.error:
        return _Message(
          key: const Key('earn-error'),
          icon: Icons.cloud_off_rounded,
          title: 'Something went wrong',
          body: data.errorMessage.isEmpty ? 'We could not load your Earn page.' : data.errorMessage,
          action: 'Try again',
          onTap: actions.onRetry,
        );
      case EarnLoad.offline:
        return _Message(
          key: const Key('earn-offline'),
          icon: Icons.wifi_off_rounded,
          title: 'You are offline',
          body: 'Connect to the internet to see your rank and money.',
          action: 'Try again',
          onTap: actions.onRetry,
        );
      case EarnLoad.empty:
        return _Message(
          key: const Key('earn-empty'),
          icon: Icons.spa_rounded,
          title: data.signedIn ? 'Start earning' : 'Sign in to earn',
          body: data.signedIn
              ? 'Share your link. When someone buys, you earn money.'
              : 'Join as an agent. Sell words and plans. Move up ranks.',
          action: data.signedIn ? 'Share my link' : 'Sign in',
          onTap: data.signedIn ? actions.onShareCode : actions.onSignIn,
        );
      case EarnLoad.ready:
        return _Ready(data: data, actions: actions);
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.onHelp});
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.maybeOf(context)?.canPop() ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(children: [
        if (canPop)
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          )
        else
          const SizedBox(width: 48),
        const Expanded(
          child: Text('NowssB Earn',
              textAlign: TextAlign.center, style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
        ),
        IconButton(
          key: const Key('earn-help'),
          tooltip: 'How it works',
          icon: const Icon(Icons.help_outline_rounded, color: _ink),
          onPressed: onHelp,
        ),
      ]),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    Widget bar(double h) => Padding(padding: const EdgeInsets.only(bottom: 14), child: GlassSkeleton(height: h));
    return ListView(
      key: const Key('earn-loading'),
      padding: const EdgeInsets.all(16),
      children: [bar(170), bar(90), bar(70), bar(70), bar(70)],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.icon, required this.title, required this.body, required this.action, this.onTap});
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassStateCard(icon: icon, title: title, message: body, action: action, onAction: onTap),
        ),
      );
}

class _Ready extends StatelessWidget {
  const _Ready({required this.data, required this.actions});
  final EarnViewData data;
  final EarnActions actions;

  @override
  Widget build(BuildContext context) {
    final next = data.nextTarget;
    return ListView(
      key: const Key('earn-ready'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        EarnEntrance(index: 0, child: _RankHero(data: data)),
        const SizedBox(height: 14),
        EarnEntrance(
            index: 1,
            child: Row(children: [
              Expanded(
                  child: _Stat(label: 'Money you earn', value: data.ratePct > 0 ? data.ratePct : null, suffix: '%', hint: 'of each sale')),
              const SizedBox(width: 12),
              Expanded(child: _Stat(label: 'Words sold', value: data.wordsSold, hint: next == null ? 'All targets done' : 'Next: $next')),
              const SizedBox(width: 12),
              Expanded(child: _Stat(label: 'Your team', value: data.teamSize, hint: 'people')),
            ])),
        const SizedBox(height: 22),
        const _Heading('Ways to earn'),
        EarnEntrance(
            index: 2,
            child:
                _Task(id: 'share', icon: Icons.ios_share_rounded, title: 'Share your link', cta: 'Share now', onTap: actions.onShareCode)),
        EarnEntrance(
            index: 3,
            child: _Task(
                id: 'sell',
                icon: Icons.auto_awesome_rounded,
                title: 'Sell words and plans',
                cta: 'Earn now',
                onTap: () => actions.onTask?.call('sell'))),
        EarnEntrance(
            index: 4,
            child: _Task(id: 'team', icon: Icons.account_tree_rounded, title: 'Grow your team', cta: 'See team', onTap: actions.onTeam)),
        EarnEntrance(
            index: 5,
            child: _Task(
                id: 'earnings',
                icon: Icons.account_balance_wallet_rounded,
                title: 'See your money',
                cta: 'Open',
                onTap: actions.onEarnings)),
        const SizedBox(height: 18),
        const Text(
          'What you earn depends on real sales. Nothing is guaranteed.',
          key: Key('earn-honesty-note'),
          textAlign: TextAlign.center,
          style: TextStyle(color: _soft, fontSize: 12),
        ),
      ],
    );
  }
}

class _RankHero extends StatelessWidget {
  const _RankHero({required this.data});
  final EarnViewData data;

  @override
  Widget build(BuildContext context) {
    final i = data.rankIndex;
    final next = data.nextTarget;
    return EarnGlass(
      key: const Key('earn-rank-hero'),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        EarnMedal(color: _medals[i]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_medalNames[i]} rank', style: const TextStyle(color: _soft, fontSize: 12, letterSpacing: 1.2)),
            const SizedBox(height: 2),
            Text(data.rank.isEmpty ? 'Agent' : data.rank, style: const TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            EarnBreathingBar(value: data.targetProgress, color: _medals[i]),
            const SizedBox(height: 6),
            Text(next == null ? 'You reached every target' : '${data.wordsToNext} more words to $next',
                style: const TextStyle(color: _soft, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.suffix = '', required this.hint});
  final String label;
  final int? value;
  final String suffix;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return EarnGlass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _soft, fontSize: 11)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: value == null ? const Text('—', style: _big) : EarnCountUp(value: value!, suffix: suffix, style: _big),
        ),
        Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _soft, fontSize: 11)),
      ]),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text.toUpperCase(), style: const TextStyle(color: _soft, fontSize: 11, letterSpacing: 2.2)),
      );
}

/// "Free Coins" banner-row style task (spec 15, Earn).
class _Task extends StatelessWidget {
  const _Task({required this.id, required this.icon, required this.title, required this.cta, this.onTap});
  final String id;
  final IconData icon;
  final String title;
  final String cta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        key: Key('earn-task-$id'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: EarnGlass(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(children: [
            Icon(icon, color: _ink),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w600))),
            Text('$cta ›', style: const TextStyle(color: Color(0xFFB9A4FF), fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

/// "How it works" slides for Earn (spec 19.1, wording from the table).
const kEarnHowItWorks = <String>[
  'Join as an agent',
  'Sell words and plans',
  'Grow your team',
  'Move up ranks',
];

const _howImages = ['yoga_deck', 'mudra_hands', 'lotus', 'milky_way'];
const _howBodies = [
  'Sign up in the app. It is free to start.',
  'Share words and plans. You earn on real sales.',
  'Invite people to join. Your team grows.',
  'Sell more words to reach the next rank.',
];

/// "How it works" as the reference meditation cards: round photo, inner
/// glass panel, bold title, small body, Skip left, Next pill right, dots.
Future<void> showEarnHowItWorks(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'close',
    barrierColor: Colors.black54,
    pageBuilder: (ctx, _, __) => const _HowItWorks(),
  );
}

class _HowItWorks extends StatefulWidget {
  const _HowItWorks();
  @override
  State<_HowItWorks> createState() => _HowItWorksState();
}

class _HowItWorksState extends State<_HowItWorks> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final last = _i == kEarnHowItWorks.length - 1;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Material(
            type: MaterialType.transparency,
            child: MeditationCard(
              key: Key('earn-how-$_i'),
              image: NCircles.of(_howImages[_i]),
              title: kEarnHowItWorks[_i],
              subtitle: _howBodies[_i],
              secondary: last ? null : 'Skip',
              cta: last ? 'Done' : 'Next',
              dots: kEarnHowItWorks.length,
              dotIndex: _i,
              onCta: () => last ? Navigator.of(context).pop() : setState(() => _i++),
            ),
          ),
        ),
      ),
    );
  }
}
