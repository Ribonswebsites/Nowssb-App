/// NowssB Partner Program (Plan B 8): My Progress · Word Track · Plan Track ·
/// Perks · Buyer Discount · Leaderboard · Rules. Points come only from
/// cleared purchases by other people through your links; perks are coins,
/// gifts, coupons and early access — never cash.
library;

import 'package:flutter/material.dart';

import '../../admin/layout/layout_sections.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/reward_fx.dart';
import 'program_kit.dart';
import 'program_heroes.dart';
import '../economy/partner_screen.dart';
import 'reference_program.dart';

const kPartnerDisclaimer =
    'Partner Program perks are coins, gifts, coupons and early access. They have no cash value. Points come only from '
    'completed, paid purchases by other people and are confirmed after the refund window. Levels and perks may change '
    'with notice.';

const kPartnerSpec = ProgramSpec(
  pageId: 'partner.program',
  title: 'Partner Program',
  mark: NwsbMarks.crown,
  disclaimer: kPartnerDisclaimer,
  accent: ProgramAccent.partner,
  tabs: [
    ProgramTab('progress', 'My Progress', _progress),
    ProgramTab('word', 'Word Track', _word),
    ProgramTab('plan', 'Plan Track', _plan),
    ProgramTab('perks', 'Perks', _perks),
    ProgramTab('discount', 'Buyer Discount', _discount),
    ProgramTab('board', 'Leaderboard', _board),
    ProgramTab('rules', 'Rules', _rules),
  ],
);

/// Kept for every existing entry point: opens the one Partner page.
class PartnerProgramPage extends StatelessWidget {
  const PartnerProgramPage({super.key, this.initialTab});
  final int? initialTab;

  @override
  Widget build(BuildContext context) => PartnerScreen(
        initialTab: initialTab == null ? null : kPartnerSpec.tabs[initialTab!.clamp(0, kPartnerSpec.tabs.length - 1)].id,
      );
}

Widget _ps(Widget Function(BuildContext, Map<String, dynamic>, VoidCallback) b) => ServerView(action: 'partnerSummary', builder: b);

String _perkLine(Map<String, dynamic> l) => [
      if (sInt(l['coins']) > 0) '${sInt(l['coins'])} coins',
      if (l['giftbox'] != null) '${l['giftbox']} gift box',
      if (l['coupon'] != null) '${rarityTitle('${l['coupon']}')} card',
      if (l['pass'] != null) '${sInt(sMap(l['pass'])['days'])}-day ${sMap(l['pass'])['tier']} pass',
      if (sInt(l['coinsBackPct']) > 0) '${sInt(l['coinsBackPct'])}% coins back',
      if (sInt(l['earlyHours']) > 0) '${sInt(l['earlyHours'])}h early access',
      if (l['fastTrack'] != null) 'fast track to ${l['fastTrack']}',
    ].join(' · ');

List<Widget> _progress(BuildContext context, Map<String, dynamic> s) => [
      LSection('path', 'Level path', _ps((context, r, _) {
        final levels = sList(r['levels']);
        final next = levels.firstWhere((l) => l['reached'] != true, orElse: () => const {});
        if (levels.isEmpty) return const PCard(children: [PEmpty('Levels are not set up yet. Your points still count and show here once they are.')]);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PCard(glow: const Color(0xFFC08BFF), children: [
            Text('${r['title'] ?? 'Starter'}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            CountUp(sInt(r['confirmed']), suffix: ' confirmed points', style: const TextStyle(color: NwsbColors.goldLight, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(partnerPendingLine(sInt(r['pending']), sInt(r['confirmDays'])), style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
            if (next.isNotEmpty) PProgress(value: sInt(r['confirmed']), goal: sInt(next['points']), label: '${sInt(r['confirmed'])} / ${sInt(next['points'])} to ${next['title']}'),
          ]),
          PCard(children: [
            for (final l in levels)
              PRow(title: 'Level ${sInt(l['level'])} · ${l['title']}', sub: '${sInt(l['points'])} points · ${_perkLine(l)}', mark: NwsbMarks.crown, trailing: l['reached'] == true ? const PPill('Reached', color: NwsbColors.goldLight) : const PPill('Locked')),
          ]),
        ]);
      })),
    ];

List<Widget> _track(String track, String title, List<String> kinds) => [
      LSection('track', title, _ps((context, r, _) {
        final pts = sMap(r['points']);
        final tracks = sMap(r['tracks']);
        final recent = sList(r['recent']).where((x) => track == 'plan' ? x['kind'] == 'subscription' : x['kind'] != 'subscription').toList();
        final total = sInt(tracks[track]);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PCard(children: [
            Text('$total points on the $title', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            for (final k in kinds) if (pts[k] != null) PRow(title: partnerKindLabel(k), sub: '${sInt(pts[k])} points per cleared purchase', mark: NwsbMarks.rewards),
          ]),
          PCard(children: [
            const PHeading('Recent', 'Points from your links', slot: 'partner_program.track'),
            if (recent.isEmpty) const PEmpty('No points on this track yet.'),
            for (final x in recent) PRow(title: '+${sInt(x['points'])} · ${partnerKindLabel('${x['kind']}')}', sub: '${shortDate(x['at'])} · ${x['confirmed'] == true ? 'confirmed' : 'pending'}', mark: NwsbMarks.rewards),
          ]),
        ]);
      })),
    ];

List<Widget> _word(BuildContext c, Map<String, dynamic> s) => _track('word', 'Word Track', const ['word', 'meaning', 'stage', 'bundle', 'signature', 'ebook', 'giftcard']);
List<Widget> _plan(BuildContext c, Map<String, dynamic> s) => _track('plan', 'Plan Track', const ['basic', 'plus', 'premium']);

List<Widget> _perks(BuildContext context, Map<String, dynamic> s) => [
      LSection('perks', 'Perks', _ps((context, r, reload) {
        final levels = sList(r['levels']);
        return PCard(children: [
          const PHeading('Claimed and locked', 'Perks', slot: 'partner_program.perks'),
          if (levels.isEmpty) const PEmpty('No perks yet. Reach your first level to unlock one.'),
          for (final l in levels)
            PRow(
              title: '${l['title']}',
              sub: _perkLine(l),
              mark: NwsbMarks.gift,
              trailing: l['claimed'] == true
                  ? const PPill('Claimed', color: NwsbColors.goldLight)
                  : PClaim(label: 'Claim', action: 'claimPartnerLevel', data: {'level': sInt(l['level'])}, enabled: l['reached'] == true, title: '${l['title']} perks', onDone: (_) => reload()),
            ),
        ]);
      })),
    ];

List<Widget> _discount(BuildContext context, Map<String, dynamic> s) {
  final fd = sMap(sMap(sMap(s['config'])['reference'])['friendDiscount']);
  if (!partnerDiscountReady(fd)) {
    return const [
      LSection('discount', 'Buyer discount', PCard(children: [
        PHeading('For the people you invite', 'Buyer discount', slot: 'partner_program.discount'),
        PEmpty('There is no buyer discount running right now. When there is one, it shows here.'),
      ])),
    ];
  }
  return [
    LSection('discount', 'Buyer discount', PCard(glow: NwsbColors.gold, children: [
      const PHeading('For the people you invite', 'Buyer discount', slot: 'partner_program.discount'),
      if (sInt(fd['wordPct']) > 0)
      PRow(title: '${sInt(fd['wordPct'])}% off', sub: sInt(fd['wordFirstN']) > 0 ? 'their first ${sInt(fd['wordFirstN'])} words and meanings' : 'words and meanings', mark: NwsbMarks.word),
      if (sInt(fd['subscriptionPct']) > 0)
      PRow(title: '${sInt(fd['subscriptionPct'])}% off', sub: 'the first period of a plan (Google Play offer)', mark: NwsbMarks.crown),
      const PEmpty('The discount comes off before coins, and Partner points count on what they actually paid.', slot: 'partner_program.discount'),
    ])),
  ];
}

List<Widget> _board(BuildContext context, Map<String, dynamic> s) => const [LSection('board', 'Leaderboard', SellersBoard())];

List<Widget> _rules(BuildContext context, Map<String, dynamic> s) => const [
      LSection('rules', 'Partner rules', PRules([
        'Points come only from completed, paid purchases by other people through your links.',
        'Points stay pending until the refund window ends. A refund or chargeback removes them.',
        'Gifted passes and the 3-day Signature card never unlock Partner levels.',
        'Perks are coins, gift boxes, scratch cards, passes and early access. None of them is cash.',
        'The Partner path also fast-tracks NowssB Earn: Radiant partners start Earn as an Officer once they qualify.',
      ], slot: 'partner_program.rules')),
    ];

/// Plain name for a purchase kind from the partner ledger.
String partnerKindLabel(String k) => switch (k) {
      'subscription' => 'Plan',
      'giftcard' => 'Gift card',
      'ebook' => 'eBook',
      '' || 'null' => 'Purchase',
      _ => k[0].toUpperCase() + k.substring(1),
    };

/// Pending line that never says "0 days".
String partnerPendingLine(int pending, int days) {
  if (pending <= 0) return 'Nothing waiting to be confirmed';
  final unit = pending == 1 ? 'point' : 'points';
  return days > 0 ? '$pending $unit waiting $days days for the refund window' : '$pending $unit waiting for the refund window';
}

/// A buyer discount is only shown when the server actually has one.
bool partnerDiscountReady(Map<String, dynamic> fd) => sInt(fd['wordPct']) > 0 || sInt(fd['subscriptionPct']) > 0;
