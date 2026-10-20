// NowssB Earn, rebuilt: Home, Targets, Team, Tasks tabs, a payout entry,
// pop-ups and a first-use guide. Honest: every number is the server's.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../screens/store/word_atelier.dart';
import '../../economy/economy_api.dart';
import '../earnings_screen.dart';
import 'earn_data.dart';
import 'earn_ui.dart';

const _medal = {'bronze': Color(0xFFD9A066), 'silver': Color(0xFFCBD3E1), 'gold': Color(0xFFF2C94C), 'diamond': Color(0xFF9EE7FF)};
const kEarnDisclaimer = 'What you earn depends on real sales. Nothing is guaranteed.';

const kGuide = [
  ('Join as an agent', 'Earn is free to join. You earn only when real people buy.'),
  ('Sell words and plans', 'Share your link. When someone buys, part of the sale is yours.'),
  ('Grow your team', 'People who join through you form your team, up to 2 levels.'),
  ('Move up ranks', 'Sell more words to reach targets and a higher share.'),
];

class EarnApp extends StatefulWidget {
  const EarnApp({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  State<EarnApp> createState() => _EarnAppState();
}

class _EarnAppState extends State<EarnApp> {
  late int _tab = widget.initialTab;
  EarnData _d = const EarnData();

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGuide());
  }

  Future<void> _load() async {
    setState(() => _d = const EarnData());
    final d = await earnLoader();
    if (mounted) setState(() => _d = d);
  }

  Future<void> _maybeGuide() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool('earn.guide.seen') == true || !mounted) return;
    await p.setBool('earn.guide.seen', true);
    if (mounted) await showEarnGuide(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: EarnBackground(
        child: SafeArea(
          child: Column(children: [
            _TopBar(onHelp: () => showEarnGuide(context)),
            Expanded(child: _content()),
            if (_d.load == EarnLoad.ready) _Tabs(index: _tab, onTap: (i) => setState(() => _tab = i)),
          ]),
        ),
      ),
    );
  }

  Widget _content() {
    switch (_d.load) {
      case EarnLoad.loading:
        return const Center(key: Key('earn-loading'), child: CircularProgressIndicator(color: Colors.white));
      case EarnLoad.signedOut:
        return _state('earn-signedout', 0, 'Sign in to earn', 'Sign in to see your rank, team and money.', 'Try again');
      case EarnLoad.offline:
        return _state('earn-offline', 1, 'You are offline', 'Connect to the internet to see your rank and money.', 'Try again');
      case EarnLoad.error:
        return _state('earn-error', 2, 'Something went wrong', _d.message.isEmpty ? 'We could not load Earn.' : _d.message, 'Try again');
      case EarnLoad.ready:
        if (!_d.enabled) return _state('earn-paused', 3, 'Earn is paused', 'Earn is switched off right now. Please check back later.', 'Refresh');
        return RefreshIndicator(
          onRefresh: _load,
          child: switch (_tab) {
            1 => _TargetsTab(d: _d),
            2 => _TeamTab(d: _d),
            3 => _TasksTab(d: _d, goTab: (i) => setState(() => _tab = i)),
            _ => _HomeTab(d: _d, goTab: (i) => setState(() => _tab = i)),
          },
        );
    }
  }

  Widget _state(String key, int photo, String title, String body, String cta) => Center(
        key: Key(key),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: MeditationCard(photo: kEarnPhotos[photo], title: title, body: body, cta: cta, onCta: _load),
        ),
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onHelp});
  final VoidCallback onHelp;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Row(children: [
          if (Navigator.of(context).canPop())
            IconButton(tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kInk, size: 20))
          else
            const SizedBox(width: 48),
          const Expanded(child: Text('NowssB Earn', textAlign: TextAlign.center, style: TextStyle(color: kInk, fontSize: 18, fontWeight: FontWeight.w700))),
          IconButton(key: const Key('earn-help'), tooltip: 'How Earn works', onPressed: onHelp, icon: const Icon(Icons.help_outline_rounded, color: kInk)),
        ]),
      );
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;
  static const items = [(Icons.home_rounded, 'Home'), (Icons.flag_rounded, 'Targets'), (Icons.account_tree_rounded, 'Team'), (Icons.checklist_rounded, 'Tasks')];
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Frost(
          radius: 26,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  key: Key('earn-tab-$i'),
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onTap(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: i == index ? Colors.white : Colors.transparent),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(items[i].$1, size: 20, color: i == index ? const Color(0xFF1B1433) : kInk),
                      Text(items[i].$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: i == index ? const Color(0xFF1B1433) : kInk)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      );
}

Widget _list(List<Widget> children) =>
    ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: children);

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.d, required this.goTab});
  final EarnData d;
  final ValueChanged<int> goTab;

  @override
  Widget build(BuildContext context) {
    final c = _medal[d.metal.toLowerCase()] ?? _medal['bronze']!;
    final n = d.next;
    return _list([
      KeyedSubtree(
        key: const Key('earn-rank-card'),
        child: MeditationCard(
          top: Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x66FFFFFF), width: 2),
              gradient: RadialGradient(center: const Alignment(-.3, -.4), colors: [Color.lerp(c, Colors.white, .5)!, c, Color.lerp(c, Colors.black, .4)!]),
            ),
            child: const Icon(Icons.workspace_premium_rounded, size: 64, color: Color(0xFF1B1433)),
          ),
          title: d.rank.isEmpty ? 'Agent' : d.rank,
          body: d.metal.isEmpty ? 'Your rank' : '${d.metal} rank · ${d.ratePct}% of each sale',
          extra: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: d.progress, minHeight: 7, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation(c)),
            ),
            const SizedBox(height: 6),
            Text(n == null ? (d.targets.isEmpty ? 'Targets load from the server.' : 'You reached every target') : '${n.words - d.words} more words to ${n.words}',
                key: const Key('earn-next'), style: const TextStyle(color: kGrey, fontSize: 12)),
          ]),
          link: 'Skip',
          onLink: () => goTab(3),
          cta: 'Targets',
          onCta: () => goTab(1),
        ),
      ),
      const SectionTitle('Your numbers'),
      TicketCard(
        key: const Key('earn-numbers'),
        leading: RoundIcon(Icons.percent_rounded, text: '${d.ratePct}%'),
        pill: 'Money you earn',
        label: '${d.words} words sold · ${d.team.length} in your team',
        headline: 'Of each sale',
        link: 'See your money',
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarningsScreen())),
      ),
      if (d.invites.isNotEmpty) ...[
        const SectionTitle('Invites'),
        for (final i in d.invites)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TicketCard(
              leading: const RoundIcon(Icons.mail_rounded, color: Color(0xFFE879F9)),
              pill: 'Invite',
              badge: 'NEW',
              label: 'From ${i.from}',
              headline: 'Join as ${i.rank}',
              link: 'View invite',
              accent: const Color(0xFFE879F9),
              onTap: () => _invite(context, i),
            ),
          ),
      ],
      const SectionTitle('Go to'),
      for (final (k, photo, pill, label, head, link, onTap) in [
        ('payout', 0, 'Payout', 'Your country', 'Set up payouts', 'Open', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EarnPayoutPage(country: d.payoutCountry)))),
        ('team', 1, 'Team', '${d.direct.length} direct · ${d.second.length} level 2', 'Your team', 'See team', () => goTab(2)),
        ('tasks', 2, 'Tasks', 'Simple steps', 'Ways to earn', 'See tasks', () => goTab(3)),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TicketCard(key: Key('earn-go-$k'), leading: RoundPhoto(kEarnPhotos[photo]), pill: pill, label: label, headline: head, link: link, onTap: onTap),
        ),
      const SizedBox(height: 8),
      const Text(kEarnDisclaimer, key: Key('earn-honesty'), textAlign: TextAlign.center, style: TextStyle(color: kGrey, fontSize: 12)),
    ]);
  }

  void _invite(BuildContext context, EarnInvite i) => showEarnCard<void>(
        context,
        (ctx) => MeditationCard(
          photo: kEarnPhotos[3],
          title: 'Join as ${i.rank}',
          body: '${i.from} invited you. You can say yes or no. Nothing is charged.',
          link: 'Not now',
          onLink: () => _answer(ctx, i, false),
          cta: 'Accept',
          onCta: () => _answer(ctx, i, true),
        ),
      );

  Future<void> _answer(BuildContext ctx, EarnInvite i, bool yes) async {
    final m = ScaffoldMessenger.maybeOf(ctx);
    Navigator.of(ctx).pop();
    try {
      await EconomyApi.call('answerAppointment', {'id': i.id, 'accept': yes});
      m?.showSnackBar(SnackBar(content: Text(yes ? 'Invite accepted.' : 'Invite declined.')));
    } on EconomyException catch (e) {
      m?.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _TargetsTab extends StatelessWidget {
  const _TargetsTab({required this.d});
  final EarnData d;
  @override
  Widget build(BuildContext context) => _list([
        const SectionTitle('Targets'),
        if (d.targets.isEmpty)
          MeditationCard(photo: kEarnPhotos[1], title: 'No targets yet', body: 'Targets will show here when the server sends them.', cta: 'OK')
        else
          for (var i = 0; i < d.targets.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TicketCard(
                key: Key('earn-target-${d.targets[i].words}'),
                leading: RoundIcon(d.targets[i].reached ? Icons.check_rounded : Icons.flag_rounded, color: d.targets[i].reached ? kMint : const Color(0xFFF5B83D)),
                pill: d.targets[i].reached ? 'Reached' : 'Target',
                label: d.targets[i].title.isEmpty ? 'Words sold' : d.targets[i].title,
                headline: '${d.targets[i].words} words',
                link: d.targets[i].reached ? 'Done' : '${(d.targets[i].words - d.words).clamp(0, 1 << 30)} to go',
                accent: d.targets[i].reached ? kMint : const Color(0xFFF5B83D),
                onTap: () => showEarnCard<void>(
                  context,
                  (ctx) => MeditationCard(
                    photo: kEarnPhotos[i % kEarnPhotos.length],
                    title: '${d.targets[i].words} words',
                    body: d.targets[i].reached
                        ? 'You reached this target.'
                        : 'You have sold ${d.words}. Sell ${d.targets[i].words - d.words} more words to reach it. Rewards for each rank are set by NowssB and can change.',
                    cta: 'Close',
                    onCta: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ),
      ]);
}

class _TeamTab extends StatelessWidget {
  const _TeamTab({required this.d});
  final EarnData d;
  @override
  Widget build(BuildContext context) {
    if (d.team.isEmpty) {
      return _list([
        const SizedBox(height: 20),
        MeditationCard(
          key: const Key('earn-team-empty'),
          photo: kEarnPhotos[2],
          title: 'No team yet',
          body: 'People who join through your link show up here, up to 2 levels.',
          cta: 'Share link',
          onCta: () => shareEarnLink(context),
        ),
      ]);
    }
    Widget row(EarnMember m, int i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TicketCard(
            key: Key('earn-member-${m.id}'),
            leading: RoundIcon(Icons.person_rounded, text: m.name.isEmpty ? '?' : m.name.characters.first.toUpperCase(), color: m.level == 1 ? const Color(0xFF8B5CF6) : kMint),
            pill: m.level == 1 ? 'Direct' : 'Level 2',
            label: m.rank.isEmpty ? 'Team member' : m.rank,
            headline: m.name,
            link: '${m.words} words',
            accent: m.level == 1 ? const Color(0xFF8B5CF6) : kMint,
            onTap: () => showEarnCard<void>(
              context,
              (ctx) => MeditationCard(
                key: const Key('earn-member-card'),
                photo: kEarnPhotos[i % kEarnPhotos.length],
                title: m.name,
                body: 'Rank: ${m.rank.isEmpty ? '—' : m.rank}\nWords sold: ${m.words}\nLevel: ${m.level == 1 ? 'Direct (1)' : 'Through your team (2)'}',
                cta: 'Close',
                onCta: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        );
    return _list([
      Text('${d.direct.length} direct · ${d.second.length} level 2', key: const Key('earn-team-counts'), style: const TextStyle(color: kGrey)),
      const SectionTitle('Direct'),
      for (var i = 0; i < d.direct.length; i++) row(d.direct[i], i),
      if (d.second.isNotEmpty) const SectionTitle('Level 2'),
      for (var i = 0; i < d.second.length; i++) row(d.second[i], i + 1),
    ]);
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.d, required this.goTab});
  final EarnData d;
  final ValueChanged<int> goTab;
  @override
  Widget build(BuildContext context) => _list([
        const SectionTitle('Ways to earn'),
        for (final (k, photo, pill, label, head, link, onTap) in [
          ('share', 0, 'Share', 'Your link', 'Share your link', 'Copy link', () => shareEarnLink(context)),
          ('sell', 1, 'Sell', 'Words and plans', 'Open the word store', 'Open store', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WordAtelierScreen()))),
          ('team', 2, 'Team', 'Up to 2 levels', 'Grow your team', 'See team', () => goTab(2)),
          ('money', 3, 'Money', 'Pending and available', 'See your money', 'Open', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarningsScreen()))),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TicketCard(key: Key('earn-task-$k'), leading: RoundPhoto(kEarnPhotos[photo]), pill: pill, label: label, headline: head, link: link, onTap: onTap),
          ),
      ]);
}

/// Copies the user's real referral link. No link, no copy.
Future<void> shareEarnLink(BuildContext context) async {
  final code = EconomyMirror.instance.code;
  final m = ScaffoldMessenger.maybeOf(context);
  if (code.isEmpty) {
    m?.showSnackBar(const SnackBar(content: Text('Sign in to get your link.')));
    return;
  }
  await Clipboard.setData(ClipboardData(text: 'https://nowssb.com/r/$code'));
  m?.showSnackBar(const SnackBar(content: Text('Link copied.')));
}

Future<void> showEarnGuide(BuildContext context) => showEarnCard<void>(context, (_) => const _Guide());

class _Guide extends StatefulWidget {
  const _Guide();
  @override
  State<_Guide> createState() => _GuideState();
}

class _GuideState extends State<_Guide> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final last = _i == kGuide.length - 1;
    return MeditationCard(
      key: Key('earn-guide-$_i'),
      photo: kEarnPhotos[_i % kEarnPhotos.length],
      title: kGuide[_i].$1,
      body: kGuide[_i].$2,
      link: last ? null : 'Skip',
      onLink: () => Navigator.of(context).pop(),
      cta: last ? 'Done' : 'Next',
      onCta: () => last ? Navigator.of(context).pop() : setState(() => _i++),
      dots: kGuide.length,
      dotIndex: _i,
    );
  }
}

/// Payout entry. Global and country-aware: the payout provider runs identity
/// and tax checks for each country. Nothing India-only here.
class EarnPayoutPage extends StatefulWidget {
  const EarnPayoutPage({super.key, this.country = ''});
  final String country;
  @override
  State<EarnPayoutPage> createState() => _EarnPayoutPageState();
}

class _EarnPayoutPageState extends State<EarnPayoutPage> {
  late String _country = widget.country;
  static const countries = {
    'AE': 'United Arab Emirates', 'AU': 'Australia', 'BR': 'Brazil', 'CA': 'Canada', 'DE': 'Germany', 'ES': 'Spain', 'FR': 'France',
    'GB': 'United Kingdom', 'ID': 'Indonesia', 'IN': 'India', 'IT': 'Italy', 'JP': 'Japan', 'MX': 'Mexico', 'NG': 'Nigeria',
    'NL': 'Netherlands', 'PH': 'Philippines', 'SG': 'Singapore', 'US': 'United States', 'ZA': 'South Africa',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: EarnBackground(
          child: SafeArea(
            child: Column(children: [
              Row(children: [
                IconButton(tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kInk, size: 20)),
                const Expanded(child: Text('Payouts', textAlign: TextAlign.center, style: TextStyle(color: kInk, fontSize: 18, fontWeight: FontWeight.w700))),
                const SizedBox(width: 48),
              ]),
              Expanded(
                child: _list([
                  MeditationCard(
                    key: const Key('earn-payout-card'),
                    photo: kEarnPhotos[3],
                    title: 'Get paid where you live',
                    body: 'Payouts go through a global payout provider. They check your identity and tax details for your country, and pay in your local currency.',
                    extra: DropdownButtonFormField<String>(
                      key: const Key('earn-country'),
                      isExpanded: true,
                      value: countries.containsKey(_country) ? _country : null,
                      dropdownColor: const Color(0xFF241C4A),
                      style: const TextStyle(color: kInk),
                      decoration: const InputDecoration(labelText: 'Country', labelStyle: TextStyle(color: kGrey)),
                      items: [for (final e in countries.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                      onChanged: (v) => setState(() => _country = v ?? ''),
                    ),
                    cta: 'Continue',
                    onCta: _country.isEmpty ? null : _continue,
                  ),
                  const SizedBox(height: 14),
                  const Text('Money you earn shows as Pending first, then Available. You can withdraw Available money once you pass the provider checks.',
                      textAlign: TextAlign.center, style: TextStyle(color: kGrey, fontSize: 12)),
                ]),
              ),
            ]),
          ),
        ),
      );

  void _continue() => showEarnCard<void>(
        context,
        (ctx) => MeditationCard(
          key: const Key('earn-payout-pending'),
          photo: kEarnPhotos[0],
          title: 'Almost ready',
          body: 'Payouts for ${countries[_country]} open when NowssB connects its payout provider. We saved nothing yet and will tell you when it is live.',
          cta: 'OK',
          onCta: () => Navigator.of(ctx).pop(),
        ),
      );
}
