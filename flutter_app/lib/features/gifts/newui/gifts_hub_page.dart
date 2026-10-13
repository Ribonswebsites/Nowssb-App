import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter/material.dart';

import '../../../kit/kit.dart';
import '../../../nowssb_ui/nowssb_ui.dart';
import '../../economy/economy_api.dart';
import '../gift_unwrap.dart';
import '../gifts_screen.dart';
import 'package:flutter/services.dart';

import '../../coins/free_coins_page.dart';
import 'gifts_kit.dart';

/// What the hub is showing.
enum GiftsLoad { loading, ready, empty, error, offline }

/// One row of "My gifts" in the rebuilt page.
class GiftsEntry {
  const GiftsEntry({required this.title, required this.note, required this.direction, required this.status, this.at = 0});
  final String title;
  final String note;
  final String direction; // received | sent
  final String status; // active | redeemed | expired
  final int at;
  bool get expired => status == 'expired';
}

/// Everything the page renders, in one plain value (easy to test).
class GiftsSnapshot {
  const GiftsSnapshot(
      {this.load = GiftsLoad.loading, this.entries = const [], this.catalog = const [], this.minutesToday = 0, this.minutesTarget = 0, this.coins = 0});
  final int coins;
  final GiftsLoad load;
  final List<GiftsEntry> entries;
  final List<GiftItem> catalog;
  final int minutesToday;
  final int minutesTarget;
}

typedef GiftsRedeem = Future<String> Function(String code);

/// Reads the live economy summary; never mints anything on the phone.
GiftsSnapshot readGiftsSnapshot({Object? error}) {
  if (error != null) return GiftsSnapshot(load: error is SocketException ? GiftsLoad.offline : GiftsLoad.error, catalog: kGiftCatalog);
  if (!GiftBook.instance.ready) return GiftsSnapshot(catalog: kGiftCatalog);
  final g = (EconomyMirror.instance.summary['gifts'] as Map?) ?? const {};
  final entries = [
    for (final r in GiftBook.instance.items) GiftsEntry(title: r.label, note: r.note, direction: r.direction, status: r.status, at: r.createdAt),
  ];
  return GiftsSnapshot(
    load: GiftsLoad.ready,
    entries: entries,
    catalog: kGiftCatalog,
    minutesToday: (g['minutesToday'] as num?)?.toInt() ?? 0,
    minutesTarget: (g['minutesTarget'] as num?)?.toInt() ?? 0,
    coins: EconomyMirror.instance.coins,
  );
}

/// Live wrapper: binds the hub view to GiftBook / EconomyMirror.
class GiftsNewUiPage extends StatefulWidget {
  const GiftsNewUiPage({super.key, this.initialTab});
  final String? initialTab;

  @override
  State<GiftsNewUiPage> createState() => _GiftsNewUiPageState();
}

class _GiftsNewUiPageState extends State<GiftsNewUiPage> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    GiftBook.instance.addListener(_changed);
    _load();
  }

  @override
  void dispose() {
    GiftBook.instance.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _error = null);
    // Kit refresh swallows errors; an empty summary afterwards means it failed.
    await CoinsRepository.refresh();
    if (mounted && !GiftBook.instance.ready) setState(() => _error = 'load');
  }

  Future<String> _redeem(String code) async {
    final res = await GiftsRepository.redeemGift({'code': code});
    final r = switch (res) {
      KitOk(:final value) => value,
      KitErr(:final message) => throw EconomyException(message),
    };
    if (mounted) {
      final g = r['granted'];
      unawaited(GiftUnwrapMoment.show(context, title: '${r['title'] ?? 'A gift for you'}', items: g is Map ? [Map<String, dynamic>.from(g)] : const []));
    }
    return '${r['title'] ?? 'Gift opened'}';
  }

  @override
  Widget build(BuildContext context) => GiftsHubView(
        snapshot: readGiftsSnapshot(error: _error),
        onRetry: _load,
        onBuy: (id) => showGiftCardSheet(context, id),
        onRedeem: _redeem,
        initialTab: widget.initialTab,
        onCoins: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FreeCoinsPage())),
      );
}

/// The rebuilt Gifts hub (spec Part B, Gifts): hero, shortcut tiles,
/// free-gifts progress, occasion rails and My gifts. Pure view.
class GiftsHubView extends StatelessWidget {
  const GiftsHubView(
      {super.key,
      required this.snapshot,
      required this.onRetry,
      required this.onBuy,
      required this.onRedeem,
      this.initialTab,
      this.animate = true,
      this.onCoins});
  final VoidCallback? onCoins;
  final GiftsSnapshot snapshot;
  final VoidCallback onRetry;
  final void Function(String cardId) onBuy;
  final GiftsRedeem onRedeem;
  final String? initialTab;
  final bool animate;

  static const occasions = <(String, Color)>[
    ('Birthday', GiftsPalette.pink),
    ('Calm', GiftsPalette.violet),
    ('Study', GiftsPalette.teal),
    ('Thank you', GiftsPalette.amber)
  ];

  @override
  Widget build(BuildContext context) {
    return GiftsPageShell(
      title: 'NowssB Gifts',
      backdrop: animate,
      actions: [
        if (snapshot.load == GiftsLoad.ready || snapshot.load == GiftsLoad.empty) GiftsCoinPill(coins: snapshot.coins, onTap: onCoins),
        IconButton(tooltip: 'How gifts work', icon: const Icon(Icons.help_outline_rounded, color: Colors.white), onPressed: () => _showHelp(context)),
      ],
      body: Builder(
        builder: (context) => _AutoOpen(
          open: initialTab == 'redeem' && snapshot.load == GiftsLoad.ready,
          onOpen: _showRedeem,
          child: _body(context),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (snapshot.load) {
      case GiftsLoad.loading:
        return ListView(
            key: const Key('gifts.loading'),
            padding: const EdgeInsets.all(16),
            children: const [GiftsFrost(child: SizedBox(height: 300)), SizedBox(height: 14), GiftsFrost(child: SizedBox(height: 60))]);
      case GiftsLoad.error:
      case GiftsLoad.offline:
        final off = snapshot.load == GiftsLoad.offline;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GiftsStateCard(
              key: Key(off ? 'gifts.offline' : 'gifts.error'),
              icon: off ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
              title: off ? 'You are offline.' : 'Gifts did not load.',
              message: off ? 'Connect, then try again.' : 'Please try again.',
              action: 'Try again',
              onAction: onRetry,
            ),
          ),
        );
      case GiftsLoad.ready:
      case GiftsLoad.empty:
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
          children: [
            _hero(context),
            const SizedBox(height: 18),
            GiftsReveal(index: 1, animate: animate, child: _shortcuts(context)),
            const SizedBox(height: 18),
            if (snapshot.minutesTarget > 0) ...[GiftsReveal(index: 2, animate: animate, child: _freeProgress()), const SizedBox(height: 18)],
            for (final (i, o) in occasions.indexed) ...[
              GiftsReveal(index: 3 + i, animate: animate, child: _occasionRail(context, o.$1, o.$2)),
              const SizedBox(height: 14)
            ],
            const SizedBox(height: 4),
            GiftsReveal(index: 7, animate: animate, child: _myGiftsPreview(context)),
          ],
        );
    }
  }

  Widget _hero(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _HowItWorks(),
        const SizedBox(height: 14),
        Center(
          child: GiftsPill(
            key: const Key('gifts.send'),
            label: 'Send gift',
            primary: true,
            icon: Icons.send_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              _showBuy(context);
            },
          ),
        ),
      ]);

  Widget _shortcuts(BuildContext context) => GiftsShortcuts(
        items: const [
          (Icons.shopping_bag_outlined, 'Buy a gift'),
          (Icons.self_improvement_rounded, 'Free gifts'),
          (Icons.inventory_2_outlined, 'My gifts'),
          (Icons.redeem_rounded, 'Redeem'),
        ],
        onTap: (i) => switch (i) {
          0 => _showBuy(context),
          1 => _showHelp(context),
          2 => _openMyGifts(context),
          _ => _showRedeem(context),
        },
      );

  Widget _freeProgress() {
    final p = (snapshot.minutesToday / snapshot.minutesTarget).clamp(0.0, 1.0);
    final left = (snapshot.minutesTarget - snapshot.minutesToday).clamp(0, snapshot.minutesTarget);
    return GiftsFrost(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Free gifts by daily time spent', style: TextStyle(color: GiftsPalette.text, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: p, minHeight: 8, color: Colors.white, backgroundColor: Colors.white24)),
        const SizedBox(height: 8),
        Text(left == 0 ? 'Today\'s free gift is ready.' : '$left more minutes for today\'s free gift.',
            key: const Key('gifts.free'), style: const TextStyle(color: GiftsPalette.soft, fontSize: 12)),
      ]),
    );
  }

  Widget _occasionRail(BuildContext context, String name, Color color) {
    final items = snapshot.catalog;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: const TextStyle(color: GiftsPalette.text, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      SizedBox(
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => SizedBox(
            width: 140,
            child: GiftsCardTile(
                photo: i,
                title: items[i].label,
                caption: 'Price shown in your currency at checkout',
                color: color,
                footer: 'Send gift',
                onTap: () => onBuy(items[i].id)),
          ),
        ),
      ),
    ]);
  }

  Widget _myGiftsPreview(BuildContext context) {
    if (snapshot.entries.isEmpty) {
      return GiftsFrost(
        key: const Key('gifts.empty'),
        child: Column(children: [
          const Icon(Icons.card_giftcard_rounded, color: GiftsPalette.soft, size: 34),
          const SizedBox(height: 8),
          const Text('No gifts yet.', style: TextStyle(color: GiftsPalette.text, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Gifts you send or get show here.', style: TextStyle(color: GiftsPalette.soft, fontSize: 12)),
          TextButton(onPressed: () => _showBuy(context), child: const Text('Send your first gift', style: TextStyle(color: Colors.white))),
        ]),
      );
    }
    return Row(children: [
      Expanded(
          child: Text('My gifts · ${snapshot.entries.length}', style: const TextStyle(color: GiftsPalette.text, fontSize: 16, fontWeight: FontWeight.w700))),
      TextButton(onPressed: () => _openMyGifts(context), child: const Text('See all', style: TextStyle(color: Colors.white))),
    ]);
  }

  void _openMyGifts(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GiftsMineView(entries: snapshot.entries, animate: animate)));

  Future<void> _showBuy(BuildContext context) => showGlassSheet<void>(
        context,
        accent: Colors.white,
        builder: (c) => Padding(
          padding: const EdgeInsets.all(12),
          child: _SheetBody(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pick a gift', style: TextStyle(color: GiftsPalette.text, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Paid with Google Play in your currency. You get a link to share.', style: TextStyle(color: GiftsPalette.soft, fontSize: 12)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(shrinkWrap: true, children: [
                  for (final g in snapshot.catalog)
                    ListTile(
                      title: Text(g.label, style: const TextStyle(color: GiftsPalette.text)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                      onTap: () {
                        Navigator.of(c).pop();
                        onBuy(g.id);
                      },
                    ),
                ]),
              ),
            ]),
          ),
        ),
      );

  Future<void> _showRedeem(BuildContext context) => showGlassSheet<void>(
        context,
        accent: Colors.white,
        builder: (_) => GiftsRedeemSheet(onRedeem: onRedeem),
      );

  void _showHelp(BuildContext context) => showGlassSheet<void>(
        context,
        accent: Colors.white,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(12),
          child: _SheetBody(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('How gifts work', style: TextStyle(color: GiftsPalette.text, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              for (final s in [
                '1. Pick a gift.',
                '2. Add a message.',
                '3. Send the link.',
                '4. They open it.',
                'Free gifts: spend calm time in the app each day.'
              ])
                Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(s, style: const TextStyle(color: GiftsPalette.soft))),
            ]),
          ),
        ),
      );
}

/// My gifts: received / sent / expired, 2-column grid, expired greyed.
class GiftsMineView extends StatelessWidget {
  const GiftsMineView({super.key, required this.entries, this.animate = true});
  final List<GiftsEntry> entries;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final tabs = <(String, List<GiftsEntry>)>[
      ('Received', entries.where((e) => e.direction == 'received' && !e.expired).toList()),
      ('Sent', entries.where((e) => e.direction == 'sent' && !e.expired).toList()),
      ('Expired', entries.where((e) => e.expired).toList()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: GiftsPageShell(
        title: 'My gifts',
        backdrop: animate,
        body: Column(children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GiftsFrost(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TabBar(
                  indicatorColor: Colors.white,
                  labelColor: GiftsPalette.text,
                  unselectedLabelColor: GiftsPalette.soft,
                  dividerColor: Colors.transparent,
                  tabs: [for (final t in tabs) Tab(text: t.$1)]),
            ),
          ),
          Expanded(
            child: TabBarView(children: [
              for (final t in tabs)
                t.$2.isEmpty
                    ? const Center(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child:
                                GiftsStateCard(icon: Icons.redeem_rounded, title: 'Nothing here yet.', message: 'Gifts show here when you send or get one.')))
                    : GridView.count(
                        padding: const EdgeInsets.all(16),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: .9,
                        children: [
                          for (final e in t.$2)
                            GiftsCardTile(
                              photo: t.$2.indexOf(e),
                              title: e.title,
                              caption: e.note.isEmpty ? (e.direction == 'sent' ? 'You sent this' : 'A gift for you') : e.note,
                              footer: e.status == 'redeemed' ? 'Opened' : (e.expired ? '' : 'Not opened'),
                              expired: e.expired,
                            ),
                        ],
                      ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class GiftsRedeemSheet extends StatefulWidget {
  const GiftsRedeemSheet({super.key, required this.onRedeem});
  final GiftsRedeem onRedeem;
  @override
  State<GiftsRedeemSheet> createState() => _GiftsRedeemSheetState();
}

class _GiftsRedeemSheetState extends State<GiftsRedeemSheet> {
  final _c = TextEditingController();
  bool _busy = false;
  String? _msg;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final code = _c.text.trim();
    if (code.isEmpty) return setState(() => _msg = 'Type the gift code.');
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final t = await widget.onRedeem(code);
      if (mounted) setState(() => _msg = 'Opened: $t');
    } on EconomyException catch (e) {
      if (mounted) setState(() => _msg = e.message);
    } catch (_) {
      if (mounted) setState(() => _msg = 'That did not work. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.of(context).viewInsets.bottom),
        child: _SheetBody(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Redeem a gift', style: TextStyle(color: GiftsPalette.text, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(
              key: const Key('gifts.code'),
              controller: _c,
              style: const TextStyle(color: GiftsPalette.text),
              decoration: const InputDecoration(hintText: 'Gift code', hintStyle: TextStyle(color: GiftsPalette.soft)),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('gifts.redeem'),
              onPressed: _busy ? null : _go,
              style: FilledButton.styleFrom(backgroundColor: GiftsPalette.cta, foregroundColor: Colors.white, shape: const StadiumBorder()),
              child: Text(_busy ? 'Opening…' : 'Open gift'),
            ),
            if (_msg != null)
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_msg!, key: const Key('gifts.redeem.msg'), style: const TextStyle(color: GiftsPalette.soft))),
          ]),
        ),
      );
}

/// Opens a sheet once (deep link to Redeem), after the first frame.
class _AutoOpen extends StatefulWidget {
  const _AutoOpen({required this.open, required this.onOpen, required this.child});
  final bool open;
  final Future<void> Function(BuildContext) onOpen;
  final Widget child;
  @override
  State<_AutoOpen> createState() => _AutoOpenState();
}

class _AutoOpenState extends State<_AutoOpen> {
  bool _done = false;

  void _maybe() {
    if (_done || !widget.open) return;
    _done = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onOpen(context);
    });
  }

  @override
  void initState() {
    super.initState();
    _maybe();
  }

  @override
  void didUpdateWidget(_AutoOpen old) {
    super.didUpdateWidget(old);
    _maybe();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Sheet content sits straight in the kit sheet's black card (no second glass box).
class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

/// "How gifts work" in the reference card: circle photo, inner panel,
/// Skip / Next, page dots. Photos are the app's existing circle images.
class _HowItWorks extends StatefulWidget {
  const _HowItWorks();
  @override
  State<_HowItWorks> createState() => _HowItWorksState();
}

class _HowItWorksState extends State<_HowItWorks> {
  int _i = 0;
  static const _steps = [
    ('singing_bowl', 'Send a calm moment', 'Pick a gift for someone you care about. Words, bundles, e-books or a few calm days.'),
    ('lotus', 'Add a message', 'Write a short note. It opens with the gift.'),
    ('lake', 'Send the link', 'Pay with Google Play in your currency. Share the link any way you like.'),
    ('sea_face', 'They open it', 'They tap the link and the gift unwraps. You see it in My gifts.'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = _steps[_i];
    return GiftsRefCard(
      image: NCircles.of(s.$1),
      title: s.$2,
      body: s.$3,
      index: _i,
      count: _steps.length,
      onSkip: () => setState(() => _i = _steps.length - 1),
      onNext: () => setState(() => _i = (_i + 1) % _steps.length),
      cta: 'Start again',
    );
  }
}
