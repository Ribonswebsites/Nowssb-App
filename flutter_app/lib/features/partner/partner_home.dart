/// Partner Program v2: hub, targets, perks, referral link tools, buyer
/// discount, leaderboard. Perks only: points are never cash and never coins.
/// Pages sit on a transparent Scaffold so the app's original background
/// video shows through. Money is shown through FxBook (local currency).
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../economy/economy_api.dart';
import '../economy/money.dart';
import '../programs/reference_program.dart' show SellersBoard;

/// Injectable data source (tests swap these).
class PartnerData {
  static Future<Map<String, dynamic>> Function() summary = () => EconomyApi.call('partnerSummary');

  /// Null = the live monthly board (Firestore stream in SellersBoard).
  static Future<Map<String, dynamic>> Function()? board;
  static Future<Map<String, dynamic>> Function(int level) claim = (level) => EconomyApi.call('claimPartnerLevel', {'level': level});
  static Future<Map<String, dynamic>> Function(String kind, String title) link =
      (kind, title) => EconomyApi.call('getLink', {'kind': kind, 'id': title.toLowerCase(), 'title': title});
  static String Function(int usdCents) money = (c) => FxBook.instance.formatCents(c);
  static Future<void> Function(String text) share = (t) async {
    await SharePlus.instance.share(ShareParams(text: t));
  };
}

const kGuideKey = 'partner_v2_guide_seen';
const _coinAsset = 'assets/icons/nwsb-coin.webp';
const kPartnerNote = 'Partner perks are coins, gift boxes, scratch cards, passes and early access. They have no cash value. '
    'Points come only from completed, paid purchases by other people through your links and are confirmed '
    'after the refund window. Cash commission, if offered, lives on the Earnings page and is paid by a global '
    'payout provider with identity and tax checks per country (verify with payout provider / legal).';

int _i(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
Map<String, dynamic> _m(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> _l(Object? v) => v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];

String perkLine(Map<String, dynamic> l) => [
      if (_i(l['coins']) > 0) '${_i(l['coins'])} coins',
      if (l['giftbox'] != null) '${l['giftbox']} gift box',
      if (l['coupon'] != null) '${l['coupon']} scratch card',
      if (l['pass'] != null) '${_i(_m(l['pass'])['days'])}-day ${_m(l['pass'])['tier']} pass',
      if (_i(l['coinsBackPct']) > 0) '${_i(l['coinsBackPct'])}% coins back',
      if (_i(l['earlyHours']) > 0) '${_i(l['earlyHours'])}h early access',
    ].join(' · ');

bool _isOffline(Object e) => e is SocketException || e is TimeoutException || '$e'.toLowerCase().contains('network') || '$e'.toLowerCase().contains('offline');

// ───────────────────────── glass pieces (approved cards) ─────────────────

class PGlass extends StatelessWidget {
  const PGlass({super.key, required this.child, this.radius = 28, this.padding = const EdgeInsets.all(16), this.opacity = .14});
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double opacity;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha: .35)),
            ),
            child: child,
          ),
        ),
      );
}

class PPillButton extends StatelessWidget {
  const PPillButton(this.label, {super.key, required this.onTap, this.light = true});
  final String label;
  final VoidCallback? onTap;
  final bool light;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: onTap == null ? Colors.white24 : (light ? Colors.white : Colors.white.withValues(alpha: .18)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white54),
          ),
          child:
              Text(label, style: TextStyle(color: light && onTap != null ? const Color(0xFF241A3A) : Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      );
}

class PTag extends StatelessWidget {
  const PTag(this.label, {super.key, this.color = const Color(0xFF7FD6D0)});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration:
            BoxDecoration(color: color.withValues(alpha: .28), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: .7))),
        child: Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      );
}

class PCoin extends StatelessWidget {
  const PCoin({super.key, this.size = 22});
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(_coinAsset, width: size, height: size, errorBuilder: (_, __, ___) => SizedBox(width: size, height: size));
}

/// Meditation-style card (approved-1): round art top, inner frosted panel.
class PMeditationCard extends StatelessWidget {
  const PMeditationCard({super.key, required this.icon, required this.title, required this.body, required this.cta, required this.onTap, this.onSkip});
  final IconData icon;
  final String title, body, cta;
  final VoidCallback onTap;
  final VoidCallback? onSkip;
  @override
  Widget build(BuildContext context) => PGlass(
        padding: const EdgeInsets.all(12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .16), border: Border.all(color: Colors.white54, width: 2)),
            child: Icon(icon, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 12),
          PGlass(
            radius: 20,
            opacity: .12,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, maxLines: 2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, height: 1.15)),
              const SizedBox(height: 6),
              Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 10),
              Row(children: [
                if (onSkip != null) GestureDetector(onTap: onSkip, child: const Text('Info', style: TextStyle(color: Colors.white70, fontSize: 12))),
                const Spacer(),
                PPillButton(cta, onTap: onTap),
              ]),
            ]),
          ),
        ]),
      );
}

/// Coupon-ticket card (approved-2): art circle, dashed divider, tags, title.
class PTicket extends StatelessWidget {
  const PTicket(
      {super.key, required this.icon, required this.kicker, required this.title, this.tags = const [], this.link, this.onTap, this.trailing, this.dim = false});
  final IconData icon;
  final String kicker, title;
  final List<Widget> tags;
  final String? link;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool dim;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Opacity(
          opacity: dim ? .55 : 1,
          child: GestureDetector(
            onTap: onTap,
            child: PGlass(
              radius: 18,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(children: [
                Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .15), border: Border.all(color: Colors.white38)),
                    child: Icon(icon, color: Colors.white)),
                Container(width: 1, height: 52, margin: const EdgeInsets.symmetric(horizontal: 12), color: Colors.white30),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (tags.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 4), child: Wrap(spacing: 6, children: tags)),
                    Text(kicker, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    if (link != null) Text('$link >', style: const TextStyle(color: Color(0xFF7FD6D0), fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
                if (trailing != null) trailing!,
              ]),
            ),
          ),
        ),
      );
}

Widget _sectionLabel(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(t.toUpperCase(), style: const TextStyle(color: Color(0xFF7FD6D0), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
    );

/// Transparent page shell: the original background video stays visible.
class PartnerShell extends StatelessWidget {
  const PartnerShell({super.key, required this.title, required this.child, this.actions = const []});
  final String title;
  final Widget child;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          actions: actions,
        ),
        body: SafeArea(top: false, child: child),
      );
}

// ───────────────────────── sheets and pop-ups ─────────────────────────

Future<T?> _sheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => Padding(padding: const EdgeInsets.all(12), child: PGlass(opacity: .2, child: SafeArea(top: false, child: child))),
    );

Future<void> showPartnerInfo(BuildContext context, String title, List<String> lines) => _sheet(
      context,
      Column(key: const Key('partner.info'), mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (final l in lines) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('•  $l', style: const TextStyle(color: Colors.white70))),
        Align(alignment: Alignment.centerRight, child: PPillButton('Got it', onTap: () => Navigator.pop(context))),
      ]),
    );

Future<void> showShareSheet(BuildContext context, String url, String title) => _sheet(
      context,
      Column(key: const Key('partner.share'), mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Share $title', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SelectableText(url, style: const TextStyle(color: Color(0xFF7FD6D0))),
        const SizedBox(height: 6),
        const Text('Tell people it is your partner link. They get the buyer discount; you get perk points after their purchase clears.',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          PPillButton('Copy', key: const Key('partner.copy'), light: false, onTap: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Link copied')));
            }
          }),
          const SizedBox(width: 8),
          PPillButton('Share', key: const Key('partner.shareNow'), onTap: () async {
            Navigator.pop(context);
            await PartnerData.share('$title on NowssB: $url');
          }),
        ]),
      ]),
    );

Future<bool> confirmClaim(BuildContext context, Map<String, dynamic> level) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        key: const Key('partner.confirm'),
        backgroundColor: const Color(0xEE2A2340),
        title: Text('Claim ${level['title']} perks?', style: const TextStyle(color: Colors.white)),
        content: Text('${perkLine(level)}\n\nPerks have no cash value.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Claim')),
        ],
      ),
    ) ??
    false;

// ───────────────────────── first-use guide ─────────────────────────

class PartnerGuide extends StatefulWidget {
  const PartnerGuide({super.key});
  static const steps = [
    (Icons.link, 'Share your link', 'Make a link for any word, plan or the app, and say it is your partner link.'),
    (Icons.self_improvement, 'They save, you grow', 'Buyers get a discount. When a paid purchase clears the refund window, you get points.'),
    (Icons.card_giftcard, 'Claim perks', 'Reach a level to claim coins, gift boxes, passes and early access. Perks are never cash.'),
  ];
  static Future<void> showIfNeeded(BuildContext context) async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(kGuideKey) ?? false) return;
    if (!context.mounted) return;
    await show(context);
  }

  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
        context: context, barrierDismissible: false, builder: (_) => const Dialog(backgroundColor: Colors.transparent, child: PartnerGuide()));
    final p = await SharedPreferences.getInstance();
    await p.setBool(kGuideKey, true);
  }

  @override
  State<PartnerGuide> createState() => _PartnerGuideState();
}

class _PartnerGuideState extends State<PartnerGuide> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    final s = PartnerGuide.steps[i];
    final last = i == PartnerGuide.steps.length - 1;
    return PGlass(
      key: const Key('partner.guide'),
      opacity: .2,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .15), border: Border.all(color: Colors.white54, width: 2)),
            child: Icon(s.$1, color: Colors.white, size: 40)),
        const SizedBox(height: 14),
        Text(s.$2, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(s.$3, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var d = 0; d < PartnerGuide.steps.length; d++)
            AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(3),
                width: d == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(color: d == i ? Colors.white : Colors.white38, borderRadius: BorderRadius.circular(3))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          TextButton(
              key: const Key('partner.guide.skip'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip', style: TextStyle(color: Colors.white70))),
          const Spacer(),
          PPillButton(last ? 'Start' : 'Next', key: const Key('partner.guide.next'), onTap: () => last ? Navigator.pop(context) : setState(() => i++)),
        ]),
      ]),
    );
  }
}

// ───────────────────────── async state view ─────────────────────────

class PLoad extends StatefulWidget {
  const PLoad({super.key, required this.load, required this.builder, this.isEmpty});
  final Future<Map<String, dynamic>> Function() load;
  final Widget Function(BuildContext, Map<String, dynamic>, VoidCallback reload) builder;
  final bool Function(Map<String, dynamic>)? isEmpty;
  @override
  State<PLoad> createState() => _PLoadState();
}

class _PLoadState extends State<PLoad> {
  late Future<Map<String, dynamic>> f = widget.load();
  void reload() => setState(() => f = widget.load());
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: f,
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(
                key: Key('partner.loading'), child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Colors.white)));
          }
          if (s.hasError) {
            final off = _isOffline(s.error!);
            return _state(
                off ? const Key('partner.offline') : const Key('partner.error'),
                off ? Icons.wifi_off : Icons.error_outline,
                off ? 'You are offline' : 'Something went wrong',
                off ? 'Connect to the internet and try again.' : 'We could not load the Partner Program.',
                'Retry',
                reload);
          }
          final d = s.data ?? const {};
          if (widget.isEmpty?.call(d) ?? false) {
            return _state(const Key('partner.empty'), Icons.spa_outlined, 'Nothing here yet', 'Share a link to start your Partner path.', 'Refresh', reload);
          }
          return widget.builder(c, d, reload);
        },
      );

  Widget _state(Key k, IconData icon, String t, String b, String cta, VoidCallback on) => Center(
        key: k,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: PGlass(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text(t, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(b, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            PPillButton(cta, onTap: on),
          ])),
        ),
      );
}

// ───────────────────────── hub ─────────────────────────

class PartnerHome extends StatefulWidget {
  const PartnerHome({super.key, this.initialTab, this.showGuide = true});
  final String? initialTab;
  final bool showGuide;
  static const tabs = ['hub', 'targets', 'perks', 'refer', 'board'];
  static const labels = ['Hub', 'Targets', 'Perks', 'Refer', 'Leaderboard'];
  @override
  State<PartnerHome> createState() => _PartnerHomeState();
}

class _PartnerHomeState extends State<PartnerHome> {
  late int tab = () {
    final t = switch (widget.initialTab) { 'progress' || 'word' || 'plan' => 'targets', 'discount' => 'refer', final x => x };
    final i = PartnerHome.tabs.indexOf(t ?? 'hub');
    return i < 0 ? 0 : i;
  }();
  final _key = GlobalKey<_PLoadState>();

  @override
  void initState() {
    super.initState();
    if (widget.showGuide)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) PartnerGuide.showIfNeeded(context);
      });
  }

  void go(int i) => setState(() => tab = i);

  @override
  Widget build(BuildContext context) => PartnerShell(
        title: 'Partner Program',
        actions: [
          IconButton(
              key: const Key('partner.help'), icon: const Icon(Icons.help_outline), tooltip: 'How it works', onPressed: () => PartnerGuide.show(context)),
          IconButton(
              key: const Key('partner.rulesBtn'),
              icon: const Icon(Icons.gavel_outlined),
              tooltip: 'Rules',
              onPressed: () => _push(context, const PartnerRulesPage())),
        ],
        child: Column(children: [
          SizedBox(
            height: 44,
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  for (var i = 0; i < PartnerHome.tabs.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                      child: PPillButton(PartnerHome.labels[i], key: Key('partner.tab.${PartnerHome.tabs[i]}'), light: i == tab, onTap: () => go(i)),
                    ),
                ])),
          ),
          Expanded(
            child: PLoad(
              key: _key,
              load: PartnerData.summary,
              isEmpty: (d) => _l(d['levels']).isEmpty,
              builder: (c, d, reload) => RefreshIndicator(
                onRefresh: () async => reload(),
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: switch (tab) {
                      0 => _hub(c, d),
                      1 => _targets(c, d),
                      2 => _perks(c, d, reload),
                      3 => _refer(c, d),
                      _ => [const PartnerBoard()],
                    }),
              ),
            ),
          ),
        ]),
      );

  Map<String, dynamic>? _next(Map<String, dynamic> d) {
    for (final l in _l(d['levels'])) {
      if (l['reached'] != true) return l;
    }
    return null;
  }

  List<Widget> _hub(BuildContext c, Map<String, dynamic> d) {
    final next = _next(d);
    final conf = _i(d['confirmed']);
    return [
      PGlass(
          child: Row(children: [
        const PCoin(size: 40),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${d['title'] ?? 'Starter'} partner', style: const TextStyle(color: Colors.white70)),
          Text('$conf points', key: const Key('partner.points'), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          Text('${_i(d['pending'])} pending · confirmed after ${_i(d['confirmDays'])} days', style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ])),
      ])),
      const SizedBox(height: 14),
      SizedBox(
        height: 290,
        child: PageView(controller: PageController(viewportFraction: .78), padEnds: false, children: [
          _pad(PMeditationCard(
              key: const Key('partner.card.target'),
              icon: Icons.self_improvement,
              title: next == null ? 'Top level reached' : 'Next: ${next['title']}',
              body: next == null ? 'Every level is yours.' : '${_i(next['points']) - conf} points to go. ${perkLine(next)}',
              cta: 'Targets',
              onTap: () => go(1),
              onSkip: () =>
                  showPartnerInfo(c, 'Targets', const ['Points come from cleared purchases through your links.', 'Each level unlocks a perk bundle.']))),
          _pad(PMeditationCard(
              key: const Key('partner.card.share'),
              icon: Icons.ios_share,
              title: 'Share your link',
              body: 'Buyers save, you collect perk points.',
              cta: 'Link tools',
              onTap: () => _push(c, const PartnerLinkToolsPage()))),
          _pad(PMeditationCard(
              key: const Key('partner.card.discount'),
              icon: Icons.local_offer_outlined,
              title: 'Buyer discount',
              body: 'What the people you invite get.',
              cta: 'View',
              onTap: () => _push(c, PartnerDiscountPage(summary: d)))),
        ]),
      ),
      _sectionLabel('Quick actions'),
      PTicket(
          key: const Key('partner.q.activity'),
          icon: Icons.timeline,
          kicker: 'Word and Plan tracks',
          title: 'Points activity',
          link: 'Open',
          onTap: () => _push(c, PartnerActivityPage(summary: d))),
      PTicket(
          key: const Key('partner.q.perks'), icon: Icons.card_giftcard, kicker: 'Claim what you reached', title: 'My perks', link: 'Open', onTap: () => go(2)),
      PTicket(
          key: const Key('partner.q.board'), icon: Icons.emoji_events_outlined, kicker: 'This month', title: 'Leaderboard', link: 'Open', onTap: () => go(4)),
      const SizedBox(height: 8),
      const Text(kPartnerNote, style: TextStyle(color: Colors.white54, fontSize: 11)),
    ];
  }

  List<Widget> _targets(BuildContext c, Map<String, dynamic> d) {
    final conf = _i(d['confirmed']);
    return [
      _sectionLabel('Level path'),
      for (final l in _l(d['levels']))
        PTicket(
          key: Key('partner.level.${_i(l['level'])}'),
          icon: Icons.workspace_premium_outlined,
          kicker: 'Level ${_i(l['level'])} · ${_i(l['points'])} points',
          title: '${l['title']}',
          tags: [PTag(l['reached'] == true ? 'Reached' : 'Locked', color: l['reached'] == true ? const Color(0xFFE4C56A) : const Color(0xFF9AA0B4))],
          link: 'Details',
          dim: l['reached'] != true,
          trailing: l['reached'] == true
              ? null
              : SizedBox(
                  width: 44,
                  child: Text('${((conf / (_i(l['points']).clamp(1, 1 << 30))) * 100).clamp(0, 100).round()}%', style: const TextStyle(color: Colors.white))),
          onTap: () => _push(c, PartnerLevelPage(level: l, confirmed: conf)),
        ),
    ];
  }

  List<Widget> _perks(BuildContext c, Map<String, dynamic> d, VoidCallback reload) => [
        _sectionLabel('Perks'),
        for (final l in _l(d['levels']))
          PTicket(
            key: Key('partner.perk.${_i(l['level'])}'),
            icon: Icons.card_giftcard,
            kicker: perkLine(l),
            title: '${l['title']} perks',
            tags: [
              if (l['claimed'] == true)
                const PTag('Claimed', color: Color(0xFFE4C56A))
              else if (l['reached'] == true)
                const PTag('Ready', color: Color(0xFFC08BFF))
            ],
            dim: l['reached'] != true,
            trailing: l['claimed'] != true && l['reached'] == true
                ? PPillButton('Claim', key: Key('partner.claim.${_i(l['level'])}'), onTap: () => _claim(c, l, reload))
                : null,
            onTap: () => _push(c, PartnerLevelPage(level: l, confirmed: _i(d['confirmed']))),
          ),
      ];

  Future<void> _claim(BuildContext c, Map<String, dynamic> l, VoidCallback reload) async {
    if (!await confirmClaim(c, l)) return;
    try {
      await PartnerData.claim(_i(l['level']));
      if (c.mounted) ScaffoldMessenger.maybeOf(c)?.showSnackBar(SnackBar(content: Text('${l['title']} perks claimed')));
      reload();
    } catch (e) {
      if (c.mounted) ScaffoldMessenger.maybeOf(c)?.showSnackBar(SnackBar(content: Text(_isOffline(e) ? 'You are offline' : 'Could not claim: $e')));
    }
  }

  List<Widget> _refer(BuildContext c, Map<String, dynamic> d) => [
        _sectionLabel('Referral link tools'),
        PTicket(
            key: const Key('partner.r.tools'),
            icon: Icons.link,
            kicker: 'App, word or plan',
            title: 'Make a partner link',
            link: 'Open tools',
            onTap: () => _push(c, const PartnerLinkToolsPage())),
        PTicket(
            key: const Key('partner.r.discount'),
            icon: Icons.local_offer_outlined,
            kicker: 'For your buyers',
            title: _discountHeadline(d),
            tags: const [PTag('Buyer'), PTag('New', color: Color(0xFFC08BFF))],
            link: 'See details',
            onTap: () => _push(c, PartnerDiscountPage(summary: d))),
        PTicket(
            key: const Key('partner.r.rules'),
            icon: Icons.gavel_outlined,
            kicker: 'Fair-use and disclosure',
            title: 'Partner rules',
            link: 'Read',
            onTap: () => _push(c, const PartnerRulesPage())),
      ];
}

String _discountHeadline(Map<String, dynamic> d) {
  final fd = _m(_m(_m(d['config'])['reference'])['friendDiscount']);
  final w = _i(fd['wordPct']);
  return w > 0 ? '$w% off first words' : 'Buyer discount';
}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.only(right: 12), child: w);
// Opaque route: the previous Partner page is not painted underneath, while
// the shell's background video (below the Navigator) still shows through.
Future<void> _push(BuildContext c, Widget page) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => page));

// ───────────────────────── sub-pages ─────────────────────────

class PartnerLevelPage extends StatelessWidget {
  const PartnerLevelPage({super.key, required this.level, required this.confirmed});
  final Map<String, dynamic> level;
  final int confirmed;
  @override
  Widget build(BuildContext context) {
    final goal = _i(level['points']).clamp(1, 1 << 30);
    final v = (confirmed / goal).clamp(0.0, 1.0);
    return PartnerShell(
      title: '${level['title']}',
      child: ListView(key: const Key('partner.page.level'), padding: const EdgeInsets.all(16), children: [
        PGlass(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Level ${_i(level['level'])}', style: const TextStyle(color: Colors.white70)),
          Text('$confirmed / ${_i(level['points'])} points', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: v, minHeight: 8, color: Colors.white, backgroundColor: Colors.white24)),
          const SizedBox(height: 14),
          const Text('Perks at this level', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          Text(perkLine(level).isEmpty ? 'No perks listed' : perkLine(level), style: const TextStyle(color: Colors.white70)),
        ])),
        const SizedBox(height: 12),
        PTicket(
            icon: Icons.ios_share,
            kicker: 'Get closer',
            title: 'Share a partner link',
            link: 'Link tools',
            onTap: () => _push(context, const PartnerLinkToolsPage())),
      ]),
    );
  }
}

class PartnerLinkToolsPage extends StatefulWidget {
  const PartnerLinkToolsPage({super.key});
  @override
  State<PartnerLinkToolsPage> createState() => _LinkToolsState();
}

class _LinkToolsState extends State<PartnerLinkToolsPage> {
  String kind = 'app';
  final c = TextEditingController();
  bool busy = false;
  final made = <(String, String)>[];
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> make() async {
    final t = c.text.trim();
    if (kind != 'app' && t.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Type a word or plan name first')));
      return;
    }
    setState(() => busy = true);
    try {
      final r = await PartnerData.link(kind, t.isEmpty ? 'NowssB' : t);
      final url = '${r['url'] ?? ''}';
      final title = '${r['title'] ?? (t.isEmpty ? 'NowssB' : t)}';
      if (!mounted) return;
      setState(() {
        made.insert(0, (title, url));
        busy = false;
      });
      await showShareSheet(context, url, title);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(_isOffline(e) ? 'You are offline. Try again when connected.' : 'Could not make a link')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PartnerShell(
        title: 'Link tools',
        child: ListView(key: const Key('partner.page.links'), padding: const EdgeInsets.all(16), children: [
          PGlass(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('What do you want to share?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              for (final k in const ['app', 'word', 'plan'])
                PPillButton(k[0].toUpperCase() + k.substring(1), key: Key('partner.kind.$k'), light: kind == k, onTap: () => setState(() => kind = k)),
            ]),
            if (kind != 'app')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextField(
                    key: const Key('partner.linkField'),
                    controller: c,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: kind == 'word' ? 'Word, e.g. Serenity' : 'Plan, e.g. Plus',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
              ),
            const SizedBox(height: 12),
            Align(
                alignment: Alignment.centerRight,
                child: busy ? const CircularProgressIndicator(color: Colors.white) : PPillButton('Make link', key: const Key('partner.make'), onTap: make)),
          ])),
          _sectionLabel('Your links this session'),
          if (made.isEmpty) const Text('No links yet. Make one above.', style: TextStyle(color: Colors.white60)),
          for (final m in made) PTicket(icon: Icons.link, kicker: m.$2, title: m.$1, link: 'Copy or share', onTap: () => showShareSheet(context, m.$2, m.$1)),
          const SizedBox(height: 8),
          const Text('Always tell people it is your partner link (disclosure). No spam, no paid ads on the NowssB name.',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      );
}

class PartnerDiscountPage extends StatelessWidget {
  const PartnerDiscountPage({super.key, required this.summary});
  final Map<String, dynamic> summary;
  @override
  Widget build(BuildContext context) {
    final fd = _m(_m(_m(summary['config'])['reference'])['friendDiscount']);
    final example = _i(fd['exampleCents']) > 0 ? _i(fd['exampleCents']) : 499;
    final save = (example * _i(fd['wordPct']) / 100).round();
    return PartnerShell(
      title: 'Buyer discount',
      child: ListView(key: const Key('partner.page.discount'), padding: const EdgeInsets.all(16), children: [
        PTicket(
            icon: Icons.local_offer_outlined,
            kicker: 'Words and meanings',
            title: '${_i(fd['wordPct'])}% off the first ${_i(fd['wordFirstN'])}',
            tags: const [PTag('Buyer')]),
        PTicket(
            icon: Icons.workspace_premium_outlined,
            kicker: 'Plans (Google Play offer)',
            title: '${_i(fd['subscriptionPct'])}% off the first period',
            tags: const [PTag('Plan', color: Color(0xFFC08BFF))]),
        PGlass(
            child: Text(
                'Example: on a ${PartnerData.money(example)} word your buyer saves ${PartnerData.money(save)}. Prices show in the buyer\'s local currency. Partner points count on what they actually paid.',
                key: const Key('partner.discount.example'),
                style: const TextStyle(color: Colors.white70))),
      ]),
    );
  }
}

class PartnerActivityPage extends StatelessWidget {
  const PartnerActivityPage({super.key, required this.summary});
  final Map<String, dynamic> summary;
  @override
  Widget build(BuildContext context) {
    final recent = _l(summary['recent']);
    final tracks = _m(summary['tracks']);
    return PartnerShell(
      title: 'Points activity',
      child: ListView(key: const Key('partner.page.activity'), padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(
              child: PGlass(child: Text('Word track\n${_i(tracks['word'])} pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 10),
          Expanded(
              child: PGlass(child: Text('Plan track\n${_i(tracks['plan'])} pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
        ]),
        _sectionLabel('Recent'),
        if (recent.isEmpty)
          const Text('No points yet. Share a link to get started.', key: Key('partner.activity.empty'), style: TextStyle(color: Colors.white60)),
        for (final x in recent)
          PTicket(
              icon: Icons.add_circle_outline,
              kicker: '${x['kind']} · ${x['confirmed'] == true ? 'confirmed' : 'pending'}',
              title: '+${_i(x['points'])} points',
              tags: [
                PTag(x['confirmed'] == true ? 'Confirmed' : 'Pending', color: x['confirmed'] == true ? const Color(0xFFE4C56A) : const Color(0xFF9AA0B4))
              ]),
      ]),
    );
  }
}

class PartnerRulesPage extends StatelessWidget {
  const PartnerRulesPage({super.key});
  static const rules = [
    'Points come only from completed, paid purchases by other people through your links.',
    'Points stay pending for the refund window. A refund or chargeback removes them.',
    'Your own purchases and gifted passes never earn Partner points.',
    'Perks are coins, gift boxes, scratch cards, passes and early access. None of them is cash.',
    'Say it is your partner link when you share it. No spam and no paid ads on the NowssB name.',
    'Any cash commission is shown on the Earnings page and paid by a global payout provider; identity and tax checks depend on your country (verify with payout provider / legal).',
    'Levels and perks may change with notice.',
  ];
  @override
  Widget build(BuildContext context) => PartnerShell(
        title: 'Partner rules',
        child: ListView(key: const Key('partner.page.rules'), padding: const EdgeInsets.all(16), children: [
          PGlass(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < rules.length; i++)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('${i + 1}.  ${rules[i]}', style: const TextStyle(color: Colors.white70))),
          ])),
          const SizedBox(height: 12),
          PPillButton('Replay the guide', key: const Key('partner.replayGuide'), onTap: () => PartnerGuide.show(context)),
        ]),
      );
}

class PartnerBoard extends StatelessWidget {
  const PartnerBoard({super.key});
  @override
  Widget build(BuildContext context) => PartnerData.board == null
      ? const PGlass(child: SellersBoard())
      : SizedBox(
          height: 520,
          child: PLoad(
            load: PartnerData.board!,
            isEmpty: (d) => _l(d['rows']).isEmpty,
            builder: (c, d, _) => ListView(key: const Key('partner.board'), children: [
              _sectionLabel('Leaderboard · ${d['period'] ?? 'this month'}'),
              for (final (i, r) in _l(d['rows']).indexed)
                PTicket(
                  icon: i < 3 ? Icons.emoji_events : Icons.person_outline,
                  kicker: 'Rank ${i + 1}',
                  title: '${r['name'] ?? 'Partner'}',
                  tags: [if (r['me'] == true) const PTag('You', color: Color(0xFFC08BFF))],
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${_i(r['points'])}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    const PCoin(size: 16)
                  ]),
                ),
              const Text('Ranks show perk points only. Names are display names; no earnings are shown.', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          ),
        );
}
