/// Daily lucky draw and its winners page, in the liked dark-glass style
/// (subscription film backdrop, KitHero, badge-headed glass panes, white
/// pills, the app coin).
/// Free to enter. Odds, the draw, winners and reviews all come from the server.
library;

import '../../widgets/concept/r27/how_it_works.dart';
import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/restyle_kit.dart';
import '../../data/app_control.dart';
import '../economy/economy_api.dart';
import '../programs/program_kit.dart';
import 'draw_models.dart';
import 'draw_repository.dart';
import 'lucky_draw_gate.dart';

const kDrawRules = <String>[
  'Free to enter. No purchase and no coins are needed, and entering never costs anything.',
  'One free entry per person per day.',
  'Odds of winning are about 1 in 150 per entry (the exact odds shown come from the server).',
  'Winners are picked at random by NowssB\'s server. The odds shown come from the server.',
  'Prizes are gifts or coupons. They have no cash value and cannot be exchanged for money.',
  'Coins are never cashable and a coupon covers only part of a price.',
  'Only winners who agree are listed, as first name and last initial (for example "Asha R."). Reviews are written by winners.',
];

String _errText(Object e) => e is EconomyException ? e.message : 'That did not load. Try again.';

String _when(DateTime? t) {
  if (t == null) return '';
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '${t.day}/${t.month} $h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

class _DrawPage extends StatelessWidget {
  const _DrawPage({required this.title, required this.children, this.onRefresh});
  final String title;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) =>
      KitPage(eyebrow: 'Rewards', title: title, onRefresh: onRefresh, children: children);
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.onTap, this.primary = true, this.busy = false});
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool busy;
  @override
  Widget build(BuildContext context) => KitActionPill(label, onTap: onTap, primary: primary, busy: busy);
}

/// Side padding for loose rows between panes.
Widget _side(Widget child) => Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: child);

class _ErrorCard extends StatelessWidget {
  const _ErrorCard(this.text, this.onRetry);
  final String text;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => KitPane(
    eyebrow: 'Something went wrong',
    title: 'Not loaded',
    mark: NwsbMarks.shield,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6B6B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, height: 1.4)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _Pill('Try again', onTap: onRetry, primary: false),
    ]),
  );
}

/// Shown instead of the draw while `lucky_draw_enabled` is off.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon();
  @override
  Widget build(BuildContext context) => const _DrawPage(
    title: 'Lucky draw',
    children: [
      KitPane(
        key: Key('draw-coming-soon'),
        eyebrow: 'Daily lucky draw',
        title: 'Coming soon',
        mark: NwsbMarks.gift,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'The free daily draw isn\'t open yet. It will show up here when it is.',
            style: TextStyle(color: kKitMuted, height: 1.4),
          ),
        ]),
      ),
    ],
  );
}

/// Gates a draw page: the real page when on, the coming-soon card when off.
class _Gated extends StatelessWidget {
  const _Gated(this.child);
  final Widget child;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppControl.instance,
    builder: (_, __) => isLuckyDrawEnabled() ? child : const _ComingSoon(),
  );
}

void showDrawRules(BuildContext context, {String serverText = ''}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0B0B12),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PHeading('Lucky draw', 'Official rules', slot: 'draw.rules'),
                for (final l in kDrawRules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('•  $l', style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 13)),
                  ),
                if (serverText.isNotEmpty)
                  Text(serverText, style: const TextStyle(color: NwsbColors.mist, height: 1.4, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The daily lucky draw. Open it from anywhere with
/// `Navigator.push(MaterialPageRoute(builder: (_) => const LuckyDrawScreen()))`.
class LuckyDrawScreen extends StatelessWidget {
  const LuckyDrawScreen({super.key, this.repository = const EconomyDrawRepository()});
  final DrawRepository repository;

  static const routeName = '/rewards/lucky-draw';

  @override
  Widget build(BuildContext context) =>
      r27Guide('lucky_draw', r27DrawGuide, _Gated(_LuckyDrawScreenBody(repository: repository)));
}

class _LuckyDrawScreenBody extends StatefulWidget {
  const _LuckyDrawScreenBody({required this.repository});
  final DrawRepository repository;

  @override
  State<_LuckyDrawScreenBody> createState() => _LuckyDrawScreenState();
}

class _LuckyDrawScreenState extends State<_LuckyDrawScreenBody> {
  DrawStatus? _status;
  Object? _error;
  bool _loading = true;
  bool _entering = false;
  String? _enterError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await widget.repository.status();
      if (mounted) setState(() => _status = s);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enter() async {
    final s = _status;
    if (s == null) return;
    setState(() {
      _entering = true;
      _enterError = null;
    });
    try {
      final next = await widget.repository.enter(s.drawId);
      if (mounted) setState(() => _status = next);
    } catch (e) {
      if (mounted) setState(() => _enterError = _errText(e));
    } finally {
      if (mounted) setState(() => _entering = false);
    }
  }

  void _winners() =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => LuckyDrawWinnersScreen(repository: widget.repository)));

  @override
  Widget build(BuildContext context) {
    final s = _status;
    final children = <Widget>[];
    if (_loading && s == null) {
      children.add(
        const Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    } else if (_error != null && s == null) {
      children.add(_ErrorCard(_errText(_error!), _load));
    } else if (s != null) {
      children.addAll(_body(s));
    }
    return _DrawPage(title: 'Lucky draw', onRefresh: _load, children: children);
  }

  List<Widget> _body(DrawStatus s) {
    final result = s.result;
    final odds = s.oddsLine;
    return [
      KitHero(
        key: const ValueKey('draw-hero'),
        art: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1C1C22), Color(0xFF0A0A0D)]),
          ),
          child: Center(child: NwsbCoinDisc(size: 76)),
        ),
        cornerLabel: 'Free',
        eyebrow: 'Daily lucky draw',
        title: 'Win a gift or a coupon',
        subline: 'Free to enter. No purchase or coins needed.',
        footer: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (odds.isNotEmpty)
            Text(odds, key: const Key('draw-odds'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          if (s.closesAt != null && !s.entered && s.open) ...[
            const SizedBox(height: 4),
            Text('Entries close ${_when(s.closesAt)}', style: const TextStyle(color: kKitMuted, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          if (result != null)
            _resultView(result)
          else if (s.entered)
            Text(
              s.resultsAt == null
                  ? 'You\'re in today\'s draw. Results show here.'
                  : 'You\'re in. Results at ${_when(s.resultsAt)}.',
              key: const Key('draw-entered'),
              style: const TextStyle(color: Color(0xFF6FE3C1), fontWeight: FontWeight.w700),
            )
          else if (!s.open)
            const Text('Today\'s draw is closed. Come back tomorrow.', style: TextStyle(color: kKitMuted))
          else
            _Pill('Enter free', onTap: _enter, busy: _entering),
          if (_enterError != null) ...[
            const SizedBox(height: 8),
            Text(_enterError!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
          ],
        ]),
      ),
      if (s.prizes.isNotEmpty)
        KitPane(
          eyebrow: 'Today',
          title: 'Prizes in the draw',
          mark: NwsbMarks.gift,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final p in s.prizes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    KitIconBadge(p.kind == 'coupon' ? Icons.confirmation_number_outlined : Icons.card_giftcard),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          if (p.detail.isNotEmpty) Text(p.detail, style: const TextStyle(color: kKitMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: const ShapeDecoration(
                        color: Color(0x24FFFFFF),
                        shape: StadiumBorder(side: BorderSide(color: Color(0x40FFFFFF))),
                      ),
                      child: const Text('Prize', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            const Text('Prizes have no cash value.', style: TextStyle(color: kKitMuted, fontSize: 12)),
          ]),
        ),
      _side(Row(
        children: [
          Expanded(child: _Pill('Winners', onTap: _winners, primary: false)),
          const SizedBox(width: 10),
          Expanded(
            child: _Pill(
              'Official rules',
              onTap: () => showDrawRules(context, serverText: s.rulesText),
              primary: false,
            ),
          ),
        ],
      )),
    ];
  }

  Widget _resultView(DrawResult r) {
    if (!r.won) {
      return const Text(
        'Not this time. A new free draw opens tomorrow.',
        key: Key('draw-lost'),
        style: TextStyle(color: kKitMuted, fontWeight: FontWeight.w700),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'You won${r.prize == null ? '' : ': ${r.prize!.title}'}',
          key: const Key('draw-won'),
          style: const TextStyle(color: Color(0xFF6FE3C1), fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          r.prize?.kind == 'coupon' ? 'It\'s in your coupons.' : 'It\'s in your gifts.',
          style: const TextStyle(color: Colors.white),
        ),
        if (r.claimId.isNotEmpty) ...[
          const SizedBox(height: 10),
          _Pill(
            'Write a review',
            primary: false,
            onTap: () => showDrawReviewSheet(context, widget.repository, r.claimId),
          ),
        ],
      ],
    );
  }
}

/// Only the winner (by claimId) can review; the server holds it for moderation.
Future<void> showDrawReviewSheet(BuildContext context, DrawRepository repo, String claimId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0B0B12),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _ReviewSheet(repo: repo, claimId: claimId),
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.repo, required this.claimId});
  final DrawRepository repo;
  final String claimId;
  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _text = TextEditingController();
  int _stars = 0;
  bool _busy = false;
  String? _msg;
  bool _done = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_text.text.trim().length < 3) {
      setState(() => _msg = 'Write a few words first.');
      return;
    }
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      await widget.repo.submitReview(
        claimId: widget.claimId,
        text: _text.text.trim(),
        stars: _stars == 0 ? null : _stars,
      );
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) setState(() => _msg = _errText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PHeading('Your prize', 'Write a review', slot: 'draw.review'),
            if (_done)
              const Text(
                'Thanks. It shows on the winners page once it\'s checked.',
                style: TextStyle(color: Color(0xFF6FE3C1)),
              )
            else ...[
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      tooltip: '$i stars',
                      onPressed: () => setState(() => _stars = i),
                      icon: Icon(i <= _stars ? Icons.star : Icons.star_border, color: NwsbColors.gold),
                    ),
                ],
              ),
              TextField(
                controller: _text,
                maxLength: 280,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'How was your prize?',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                ),
              ),
              if (_msg != null) Text(_msg!, style: const TextStyle(color: Color(0xFFFF6B6B))),
              const SizedBox(height: 8),
              _Pill('Send review', onTap: _send, busy: _busy),
            ],
          ],
        ),
      ),
    );
  }
}

/// Real winners published by the server, newest first, with their reviews.
class LuckyDrawWinnersScreen extends StatelessWidget {
  const LuckyDrawWinnersScreen({super.key, this.repository = const EconomyDrawRepository()});
  final DrawRepository repository;

  static const routeName = '/rewards/lucky-draw/winners';

  @override
  Widget build(BuildContext context) => _Gated(_LuckyDrawWinnersScreenBody(repository: repository));
}

class _LuckyDrawWinnersScreenBody extends StatefulWidget {
  const _LuckyDrawWinnersScreenBody({required this.repository});
  final DrawRepository repository;

  @override
  State<_LuckyDrawWinnersScreenBody> createState() => _LuckyDrawWinnersScreenState();
}

class _LuckyDrawWinnersScreenState extends State<_LuckyDrawWinnersScreenBody> {
  final _winners = <DrawWinner>[];
  String? _cursor;
  bool _loading = true;
  bool _more = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.winners(cursor: reset ? null : _cursor);
      if (!mounted) return;
      setState(() {
        if (reset) _winners.clear();
        _winners.addAll(page.winners);
        _cursor = page.nextCursor;
        _more = page.nextCursor != null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (_loading && _winners.isEmpty) {
      rows.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    } else if (_error != null && _winners.isEmpty) {
      return _DrawPage(title: 'Winners', onRefresh: () => _load(reset: true), children: [_ErrorCard(_errText(_error!), () => _load(reset: true))]);
    } else if (_winners.isEmpty) {
      rows.add(const PEmpty('No winners yet. The first winners show here after the next draw.', slot: 'draw.winners.empty'));
    } else {
      for (var i = 0; i < _winners.length; i++) {
        final w = _winners[i];
        if (i > 0) rows.add(const Divider(height: 22, color: Color(0x1AFFFFFF)));
        rows.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const KitIconBadge(Icons.emoji_events_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        Text(w.prizeTitle, style: const TextStyle(color: kKitMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (w.wonAt != null)
                    Text(shortDate(w.wonAt!.millisecondsSinceEpoch), style: const TextStyle(color: kKitMuted, fontSize: 12)),
                ],
              ),
              if (w.review != null && w.review!.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                if ((w.review!.stars ?? 0) > 0)
                  Row(
                    children: [
                      for (var i = 0; i < w.review!.stars!.clamp(0, 5); i++) const Icon(Icons.star, size: 16, color: NwsbColors.gold),
                    ],
                  ),
                Text('“${w.review!.text}”', style: const TextStyle(color: Colors.white, height: 1.4)),
              ],
            ],
          ),
        );
      }
    }
    final children = <Widget>[
      KitPane(
        eyebrow: 'Lucky draw',
        title: 'Recent winners',
        mark: NwsbMarks.rewards,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
      ),
      if (_more && _winners.isNotEmpty) _side(_Pill('Load more', primary: false, busy: _loading, onTap: () => _load())),
    ];
    return _DrawPage(title: 'Winners', onRefresh: () => _load(reset: true), children: children);
  }
}
