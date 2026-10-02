/// NowssB Reference (Plan B 7): Link Hub · Friends · Rewards · Share Cards ·
/// Leaderboard · Rules. One personal link per person per word / plan /
/// meaning; first valid link in 30 days wins, locked at the first purchase.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../admin/layout/layout_sections.dart';
import '../../admin/template/editable.dart';
import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
import '../economy/reward_fx.dart';
import 'program_kit.dart';

const kReferenceDisclaimer =
    'Rewards are given only after a friend completes a real purchase or 3 active days. Buying through your own link, or '
    'through accounts you control, never counts. Discounts and rewards may change with notice. Your link contains only a '
    'code, not personal details.';

class ReferenceProgramPage extends StatelessWidget {
  const ReferenceProgramPage({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) => ProgramPage(
        pageId: 'reference.program',
        title: 'NowssB Reference',
        mark: NwsbMarks.reference,
        initialTab: initialTab,
        disclaimer: kReferenceDisclaimer,
        tabs: const [
          ProgramTab('hub', 'Link Hub', _hub),
          ProgramTab('friends', 'Friends', _friends),
          ProgramTab('rewards', 'Rewards', _rewards),
          ProgramTab('cards', 'Share Cards', _cards),
          ProgramTab('board', 'Leaderboard', _board),
          ProgramTab('rules', 'Rules', _rules),
        ],
      );
}

void _copy(BuildContext context, String text, [String done = 'Link copied.']) {
  Clipboard.setData(ClipboardData(text: text));
  RewardHaptics.tick();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
}

List<Widget> _hub(BuildContext context, Map<String, dynamic> s) => [
      LSection('hub', 'Link hub', ServerView(
        action: 'linkHub',
        builder: (context, r, reload) {
          final links = sList(r['links']);
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PCard(glow: NwsbColors.gold, children: [
              const EditableLabel('reference_program.shared', 'Your NowssB link', style: TextStyle(color: NwsbColors.mist, fontSize: 12)),
              SelectableText('${r['url'] ?? ''}', style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w800)),
              Text('Code ${r['code'] ?? ''}${r['hold'] != null ? ' · you joined through a friend (${sInt(sMap(r['hold'])['days'])} days left on the hold)' : ''}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                TextButton(
                  onPressed: () => _copy(context, '${r['url']}'),
                  style: TextButton.styleFrom(backgroundColor: NwsbColors.goldLight, foregroundColor: Colors.black, shape: const StadiumBorder()),
                  child: const EditableLabel('reference_program.shared', 'Copy link', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                TextButton(onPressed: () => _copy(context, '${r['code']}', 'Code copied.'), child: const EditableLabel('reference_program.shared', 'Copy code', style: TextStyle(color: NwsbColors.goldLight))),
              ]),
            ]),
            _MakeLink(onMade: reload),
            PCard(children: [
              const PHeading('Per word, plan and meaning', 'Your links', slot: 'reference_program.hub'),
              if (links.isEmpty) const PEmpty('Make a link for a word, a plan or a meaning and its opens, installs and buyers show here.'),
              for (final l in links)
                PRow(
                  title: '${l['title'] ?? l['kind']}',
                  sub: '${sInt(l['opens'])} opens · ${sInt(l['installs'])} installs · ${sInt(l['signups'])} sign-ups · ${sInt(l['buyers'])} buyers',
                  mark: NwsbMarks.reference,
                  trailing: IconButton(onPressed: () => _copy(context, '${l['url']}'), icon: const Icon(Icons.copy, size: 18, color: Colors.white70)),
                ),
            ]),
          ]);
        },
      )),
      const LSection('enter', 'Enter a friend\u2019s code', _EnterCode()),
    ];

class _MakeLink extends StatefulWidget {
  const _MakeLink({required this.onMade});
  final VoidCallback onMade;
  @override
  State<_MakeLink> createState() => _MakeLinkState();
}

class _MakeLinkState extends State<_MakeLink> {
  final _c = TextEditingController();
  var _kind = 'word';
  var _busy = false;
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _make() async {
    final title = _c.text.trim();
    if (title.isEmpty && _kind != 'app') return;
    setState(() => _busy = true);
    try {
      final r = await EconomyApi.call('getLink', {'kind': _kind, 'id': title.toLowerCase(), 'title': title.isEmpty ? 'NowssB' : title});
      if (!mounted) return;
      _copy(context, '${r['url']}', 'Link for ${r['title']} copied.');
      widget.onMade();
    } catch (e) {
      if (mounted) showEconomyError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PCard(children: [
        const PHeading('Make a link', 'For a word, plan or meaning', slot: 'reference_program.hub'),
        Wrap(spacing: 8, children: [
          for (final k in const ['word', 'meaning', 'plan', 'bundle', 'ebook'])
            ChoiceChip(label: Text(k[0].toUpperCase() + k.substring(1)), selected: _kind == k, onSelected: (_) => setState(() => _kind = k)),
        ]),
        TextField(
          controller: _c,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: _kind == 'plan' ? 'Resonance, Frequency or Frequency X' : 'Which $_kind? e.g. Love', hintStyle: const TextStyle(color: NwsbColors.mist)),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _busy ? null : _make,
            style: TextButton.styleFrom(backgroundColor: NwsbColors.goldLight, foregroundColor: Colors.black, shape: const StadiumBorder()),
            child: Text(_busy ? 'Making…' : 'Make and copy', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ),
      ]);
}

class _EnterCode extends StatefulWidget {
  const _EnterCode();
  @override
  State<_EnterCode> createState() => _EnterCodeState();
}

class _EnterCodeState extends State<_EnterCode> {
  final _c = TextEditingController();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PCard(children: [
        const PHeading('Invited by a friend?', 'Enter their code', slot: 'reference_program.hub'),
        TextField(
          controller: _c,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white, letterSpacing: 1.2),
          decoration: const InputDecoration(hintText: 'Friend\u2019s code', hintStyle: TextStyle(color: NwsbColors.mist)),
        ),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: PClaim(label: 'Apply', action: 'attachReferral', data: {'code': _c.text.trim(), 'source': 'typed'}, title: 'Welcome gift')),
        const PEmpty('Your friend\u2019s discount applies to your first purchases. A code can be added once, within 30 days of joining.', slot: 'reference_program.hub'),
      ]);
}

List<Widget> _friends(BuildContext context, Map<String, dynamic> s) => [
      LSection('friends', 'Friends', ServerView(
        action: 'linkHub',
        builder: (context, r, _) {
          final f = sList(r['friends']);
          final links = sList(r['links']);
          int sum(String k) => links.fold(0, (a, l) => a + sInt(l[k]));
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PCard(children: [
              const PHeading('Funnel', 'From open to purchase', slot: 'reference_program.friends'),
              PRow(title: 'Opens', trailing: Text('${sum('opens')}', style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w800))),
              PRow(title: 'Installs', trailing: Text('${sum('installs')}', style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w800))),
              PRow(title: 'Sign-ups', trailing: Text('${sum('signups')}', style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w800))),
              PRow(title: 'Buyers', trailing: Text('${sInt(r['friendsCount'])}', style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w800))),
            ]),
            PCard(children: [
              const PHeading('People', 'Friends who joined', slot: 'reference_program.friends'),
              if (f.isEmpty) const PEmpty('No friends yet. Share a link from the Link Hub.'),
              for (final x in f) PRow(title: '${x['name']}', sub: sInt(x['purchases']) > 0 ? '${sInt(x['purchases'])} purchases' : 'Joined · no purchase yet', mark: NwsbMarks.user),
            ]),
          ]);
        },
      )),
    ];

List<Widget> _rewards(BuildContext context, Map<String, dynamic> s) => [
      LSection('ladder', 'Sharer ladder', ServerView(
        action: 'linkHub',
        builder: (context, r, reload) {
          final ladder = sList(r['ladder']);
          final n = sInt(r['friendsCount']);
          return PCard(children: [
            const PHeading('Friends who bought', 'Sharer ladder', slot: 'reference_program.rewards'),
            PProgress(value: n, goal: ladder.isEmpty ? 1 : sInt(ladder.last['friends']), label: '$n friends bought through your links'),
            for (final st in ladder)
              PRow(
                title: '${sInt(st['friends'])} friends',
                sub: [if (sInt(st['coins']) > 0) '${sInt(st['coins'])} coins', if (st['coupon'] != null) '${rarityTitle('${st['coupon']}')} card', if (st['passOr'] != null) '${sInt(sMap(st['passOr'])['days'])}-day pass', if (st['badge'] != null) 'badge', if (st['early'] != null) 'early access'].join(' · '),
                mark: NwsbMarks.rewards,
                trailing: st['claimed'] == true
                    ? const PPill('Claimed', color: NwsbColors.goldLight)
                    : PClaim(label: 'Claim', action: 'claimSharerStep', data: {'friends': sInt(st['friends'])}, enabled: st['reached'] == true, title: 'Sharer reward', onDone: (_) => reload()),
              ),
            const PEmpty('Each friend also gets a welcome gift (coins and a Rare card) and their first words at a discount. When a friend is active 3 days you get coins too.', slot: 'reference_program.rewards'),
          ]);
        },
      )),
    ];

List<Widget> _cards(BuildContext context, Map<String, dynamic> s) {
  final code = '${sMap(s['referral'])['code'] ?? ''}';
  final base = '${sMap(sMap(s['config'])['reference'])['linkBase'] ?? 'https://nowssb.com/w/'}';
  final url = code.isEmpty ? '' : '${base}app?r=$code';
  const lines = [
    'I practise one word a day on NowssB. Try it with my link — your first words are cheaper:',
    'Sound, meaning and a daily streak. Join me on NowssB:',
    'This word changed my morning. Hear it on NowssB:',
  ];
  return [
    for (var i = 0; i < lines.length; i++)
      LSection('card_$i', 'Share card ${i + 1}', PCard(glow: i == 0 ? NwsbColors.gold : null, children: [
        EditableLabel('reference_program.cards', lines[i], style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(url.isEmpty ? 'Open the Link Hub once to make your link.' : url, style: const TextStyle(color: NwsbColors.goldLight, fontSize: 12)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: url.isEmpty ? null : () => _copy(context, '${lines[i]} $url', 'Card copied. Paste it anywhere.'), child: const EditableLabel('reference_program.shared', 'Copy card', style: TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w800))),
        ),
      ])),
  ];
}

String monthKeyIst() {
  final d = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  return '${d.year}${'${d.month}'.padLeft(2, '0')}';
}

/// Monthly sellers board (first names and words only).
class SellersBoard extends StatelessWidget {
  const SellersBoard({super.key, this.metric = 'words'});
  final String metric;
  @override
  Widget build(BuildContext context) {
    if (!NwsbFirebase.ready) return const PEmpty('The board loads once you are online.');
    final me = EconomyMirror.instance.uid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.doc('leaderboards/sellers_${monthKeyIst()}').snapshots(),
      builder: (context, snap) {
        final entries = sMap(snap.data?.data()?['entries']).entries.map((e) => (e.key, sMap(e.value))).toList()
          ..sort((a, b) => sInt(b.$2[metric]).compareTo(sInt(a.$2[metric])));
        return PCard(children: [
          const PHeading('This month', 'Leaderboard', slot: 'reference_program.board'),
          if (entries.isEmpty) const PEmpty('No sales cleared this month yet. The board fills as real purchases clear.'),
          for (var i = 0; i < entries.length && i < 20; i++)
            PRow(
              title: '#${i + 1} ${entries[i].$2['name'] ?? 'Seller'}${entries[i].$1 == me ? ' (you)' : ''}',
              trailing: Text('${sInt(entries[i].$2[metric])} words', style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w800)),
            ),
        ]);
      },
    );
  }
}

List<Widget> _board(BuildContext context, Map<String, dynamic> s) => const [LSection('board', 'Leaderboard', SellersBoard())];

List<Widget> _rules(BuildContext context, Map<String, dynamic> s) {
  final fd = sMap(sMap(sMap(s['config'])['reference'])['friendDiscount']);
  return [
    LSection('rules', 'Reference rules', PRules([
      'Every person has one link per word, plan and meaning. The link carries only a code.',
      'The first valid link a friend opens within 30 days is theirs; it locks at their first purchase.',
      'Friend discount: ${sInt(fd['wordPct'])}% off their first ${sInt(fd['wordFirstN'])} words, ${sInt(fd['subscriptionPct'])}% off the first plan period.',
      'Your own purchases, accounts you control, the same device or the same payout identity never count.',
      'Rewards land only when a real Google Play purchase clears. Refunds and chargebacks reverse them.',
    ], slot: 'reference_program.rules')),
  ];
}
