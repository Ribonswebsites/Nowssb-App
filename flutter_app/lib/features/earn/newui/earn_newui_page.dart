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
          image: 'stones',
          title: 'Something went wrong',
          body: data.errorMessage.isEmpty ? 'We could not load your Earn page.' : data.errorMessage,
          action: 'Try again',
          onTap: actions.onRetry,
        );
      case EarnLoad.offline:
        return _Message(
          key: const Key('earn-offline'),
          image: 'lake',
          title: 'You are offline',
          body: 'Connect to the internet to see your rank and money.',
          action: 'Try again',
          onTap: actions.onRetry,
        );
      case EarnLoad.empty:
        return _Message(
          key: const Key('earn-empty'),
          image: 'lotus',
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

/// State card in the approved meditation-card design (kit MeditationCard).
class _Message extends StatelessWidget {
  const _Message({super.key, required this.image, required this.title, required this.body, required this.action, this.onTap});
  final String image;
  final String title;
  final String body;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: MeditationCard(image: NCircles.of(image), title: title, subtitle: body, cta: action, onCta: onTap),
        ),
      );
}

/// Meditation-card shell with a custom top (the kit card takes only an image).
/// Same structure: outer frosted card (rHero), round top, inner frosted panel
/// with bold title, grey body, text link left, white pill right, dots.
class EarnMeditationShell extends StatelessWidget {
  const EarnMeditationShell({
    super.key,
    required this.top,
    required this.title,
    this.subtitle,
    this.extra,
    this.secondary,
    this.onSecondary,
    required this.cta,
    this.onCta,
    this.dots,
    this.dotIndex = 0,
  });
  final Widget top;
  final String title;
  final String? subtitle;
  final Widget? extra;
  final String? secondary;
  final VoidCallback? onSecondary;
  final String cta;
  final VoidCallback? onCta;
  final int? dots;
  final int dotIndex;

  @override
  Widget build(BuildContext context) => NGlass(
        radius: NTokens.rHero,
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          top,
          const SizedBox(height: 20),
          NGlass(
            radius: NTokens.rCard,
            elevation: .3,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.15, fontWeight: FontWeight.w800)),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!, style: const TextStyle(color: NTokens.textLo, fontSize: 12, height: 1.4)),
              ],
              if (extra != null) ...[const SizedBox(height: 10), extra!],
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: secondary == null
                      ? const SizedBox.shrink()
                      : GestureDetector(
                          onTap: onSecondary,
                          child: Text(secondary!,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
                        ),
                ),
                const SizedBox(width: 8),
                GlassPill(label: cta, style: PillStyle.white, dense: true, onTap: onCta),
              ]),
              if (dots != null) ...[const SizedBox(height: 10), Center(child: PageDots(count: dots!, index: dotIndex))],
            ]),
          ),
        ]),
      );
}

/// Frosted ticket row in the approved coupon-card design (kit CouponListCard
/// layout: notched glass, round image, dashed divider, chip, label, bold line, mint link).
class EarnTicket extends StatelessWidget {
  const EarnTicket(
      {super.key,
      required this.leading,
      required this.chip,
      required this.label,
      required this.headline,
      required this.link,
      this.accent = NTokens.violet,
      this.onTap});
  final Widget leading;
  final String chip;
  final String label;
  final String headline;
  final String link;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: const NotchClipper(radius: 22, notch: 10),
        child: NGlass(
          radius: 22,
          accent: accent,
          onTap: onTap,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(children: [
            SizedBox.square(dimension: 64, child: leading),
            const SizedBox(width: 12),
            const SizedBox(height: 64, child: DashedLine(vertical: true)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                NGlass(
                  radius: NTokens.rPill,
                  accent: accent,
                  tint: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(chip.toUpperCase(),
                      style: TextStyle(
                          color: Color.lerp(accent, Colors.white, .5), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
                Text(headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                Text('$link >', style: const TextStyle(color: NTokens.mint, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
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
    final tasks = [
      ('share', 'yoga_deck', 'Share', 'Your link', 'Share your link', 'Share now', actions.onShareCode, NTokens.rare),
      (
        'sell',
        'singing_bowl',
        'Sell',
        'Words and plans',
        'Sell words and plans',
        'Earn now',
        () => actions.onTask?.call('sell'),
        NTokens.epic
      ),
      ('team', 'lotus', 'Team', '${data.teamSize} people', 'Grow your team', 'See team', actions.onTeam, NTokens.mint),
      ('earnings', 'lake', 'Money', 'Your earnings', 'See your money', 'Open', actions.onEarnings, NTokens.legendary),
    ];
    return ListView(
      key: const Key('earn-ready'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        EarnEntrance(index: 0, child: _RankHero(data: data, actions: actions)),
        const SizedBox(height: 22),
        const _Heading('Your numbers'),
        EarnEntrance(
          index: 1,
          child: EarnTicket(
            key: const Key('earn-stats'),
            accent: NTokens.mint,
            leading: _NumberCircle(value: data.ratePct > 0 ? data.ratePct : null, suffix: '%'),
            chip: 'Money you earn',
            label: 'Your share',
            headline: 'Of each sale',
            link: next == null ? 'All targets done' : 'Next: $next',
            onTap: actions.onEarnings,
          ),
        ),
        const SizedBox(height: 12),
        EarnEntrance(
          index: 2,
          child: Row(children: [
            Expanded(child: _MiniStat(label: 'Words sold', value: data.wordsSold)),
            const SizedBox(width: 12),
            Expanded(child: _MiniStat(label: 'Your team', value: data.teamSize)),
          ]),
        ),
        const SizedBox(height: 22),
        const _Heading('Ways to earn'),
        for (var i = 0; i < tasks.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EarnEntrance(
              index: i + 3,
              child: EarnTicket(
                key: Key('earn-task-${tasks[i].$1}'),
                leading: CircleImage(image: NCircles.of(tasks[i].$2), size: 64, ring: tasks[i].$8),
                chip: tasks[i].$3,
                label: tasks[i].$4,
                headline: tasks[i].$5,
                link: tasks[i].$6,
                accent: tasks[i].$8,
                onTap: tasks[i].$7,
              ),
            ),
          ),
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

class _NumberCircle extends StatelessWidget {
  const _NumberCircle({required this.value, this.suffix = ''});
  final int? value;
  final String suffix;

  @override
  Widget build(BuildContext context) => Container(
        decoration:
            BoxDecoration(shape: BoxShape.circle, border: Border.all(color: NTokens.mint, width: 2), color: const Color(0x22FFFFFF)),
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: value == null ? const Text('—', style: _big) : EarnCountUp(value: value!, suffix: suffix, style: _big),
          ),
        ),
      );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => NGlass(
        radius: NTokens.rCard,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
          const SizedBox(height: 4),
          EarnCountUp(value: value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ]),
      );
}

/// Rank hero as the approved meditation card: medal in the round top,
/// rank title, progress, "How it works" link left, "See team" pill right.
class _RankHero extends StatelessWidget {
  const _RankHero({required this.data, required this.actions});
  final EarnViewData data;
  final EarnActions actions;

  @override
  Widget build(BuildContext context) {
    final i = data.rankIndex;
    final next = data.nextTarget;
    return KeyedSubtree(
      key: const Key('earn-rank-hero'),
      child: EarnMeditationShell(
        top: Container(
          width: 140,
          height: 140,
          decoration:
              BoxDecoration(shape: BoxShape.circle, border: Border.all(color: NTokens.border, width: 2), color: const Color(0x1AFFFFFF)),
          alignment: Alignment.center,
          child: EarnMedal(color: _medals[i], size: 104),
        ),
        title: data.rank.isEmpty ? 'Agent' : data.rank,
        subtitle: '${_medalNames[i]} rank',
        extra: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EarnBreathingBar(value: data.targetProgress, color: _medals[i]),
          const SizedBox(height: 6),
          Text(next == null ? 'You reached every target' : '${data.wordsToNext} more words to $next',
              style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
        ]),
        secondary: 'How it works',
        onSecondary: actions.onHelp,
        cta: 'See team',
        onCta: actions.onTeam,
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(color: NTokens.mint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2.2)),
      );
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
