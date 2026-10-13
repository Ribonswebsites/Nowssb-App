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
import 'gifts_visuals.dart';

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
    return GlassVideoScaffold(
      shapes: animate,
      // Video off when motion is off (tests, reduced effects handled by the kit).
      videoAsset: animate ? 'assets/video/7e4d709136dc254a_grok_video_2026-07-18-15-53-02_ubjx5b.mp4' : null,
      appBar: GlassTopBar(
        title: 'NowssB Gifts',
        actions: [
          if (snapshot.load == GiftsLoad.ready || snapshot.load == GiftsLoad.empty)
            CoinChip(key: const Key('gifts.coins'), balance: '${snapshot.coins}', onTap: onCoins),
          IconButton(tooltip: 'How gifts work', icon: const Icon(Icons.help_outline_rounded, color: Colors.white), onPressed: () => _showHelp(context)),
        ],
      ),
      body: Builder(
        builder: (context) => SafeArea(
          child: _AutoOpen(
            open: initialTab == 'redeem' && snapshot.load == GiftsLoad.ready,
            onOpen: _showRedeem,
            child: _body(context),
          ),
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
            children: const [GlassSkeleton(height: 150), SizedBox(height: 14), GlassSkeleton(height: 80), SizedBox(height: 14), GlassSkeleton(height: 160)]);
      case GiftsLoad.error:
      case GiftsLoad.offline:
        final off = snapshot.load == GiftsLoad.offline;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassStateCard(
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
            GiftsReveal(index: 0, animate: animate, child: _hero(context)),
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

  Widget _hero(BuildContext context) => NGlass(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Row(children: [
          GiftsHeroScene(size: 96, animate: animate),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Send a calm moment', style: TextStyle(color: GiftsPalette.text, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Pick a gift. Add a message. Send the link.', style: TextStyle(color: GiftsPalette.soft, fontSize: 13)),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('gifts.send'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showBuy(context);
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Send gift'),
                style: FilledButton.styleFrom(backgroundColor: GiftsPalette.pink, foregroundColor: GiftsPalette.bgBottom),
              ),
            ]),
          ),
        ]),
      );

  Widget _shortcuts(BuildContext context) => ShortcutTileRow(
        items: const [
          (Icons.shopping_bag_rounded, 'Buy a gift'),
          (Icons.self_improvement_rounded, 'Free gifts'),
          (Icons.inventory_2_rounded, 'My gifts'),
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
    return NGlass(
      tint: GiftsPalette.teal,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Free gifts by daily time spent', style: TextStyle(color: GiftsPalette.text, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: p, minHeight: 8, color: GiftsPalette.teal, backgroundColor: Colors.white12)),
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
                title: items[i].label, caption: 'Price shown in your currency at checkout', color: color, footer: 'Send gift', onTap: () => onBuy(items[i].id)),
          ),
        ),
      ),
    ]);
  }

  Widget _myGiftsPreview(BuildContext context) {
    if (snapshot.entries.isEmpty) {
      return NGlass(
        key: const Key('gifts.empty'),
        child: Column(children: [
          const Icon(Icons.card_giftcard_rounded, color: GiftsPalette.soft, size: 34),
          const SizedBox(height: 8),
          const Text('No gifts yet.', style: TextStyle(color: GiftsPalette.text, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Gifts you send or get show here.', style: TextStyle(color: GiftsPalette.soft, fontSize: 12)),
          TextButton(onPressed: () => _showBuy(context), child: const Text('Send your first gift', style: TextStyle(color: GiftsPalette.pink))),
        ]),
      );
    }
    return Row(children: [
      Expanded(
          child: Text('My gifts · ${snapshot.entries.length}', style: const TextStyle(color: GiftsPalette.text, fontSize: 16, fontWeight: FontWeight.w700))),
      TextButton(onPressed: () => _openMyGifts(context), child: const Text('See all', style: TextStyle(color: GiftsPalette.pink))),
    ]);
  }

  void _openMyGifts(BuildContext context) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GiftsMineView(entries: snapshot.entries, animate: animate)));

  Future<void> _showBuy(BuildContext context) => showGlassSheet<void>(
        context,
        accent: GiftsPalette.pink,
        builder: (c) => Padding(
          padding: const EdgeInsets.all(12),
          child: NGlass(
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
                      trailing: const Icon(Icons.chevron_right_rounded, color: GiftsPalette.pink),
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
        accent: GiftsPalette.amber,
        builder: (_) => GiftsRedeemSheet(onRedeem: onRedeem),
      );

  void _showHelp(BuildContext context) => showGlassSheet<void>(
        context,
        accent: GiftsPalette.pink,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(12),
          child: NGlass(
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
      child: GlassVideoScaffold(
        shapes: animate,
        videoAsset: null, // one video per screen stack: the hub already plays it
        appBar: const GlassTopBar(title: 'My gifts'),
        body: SafeArea(
          child: Column(children: [
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NGlass(
                radius: NTokens.rPill,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TabBar(
                    indicatorColor: GiftsPalette.pink,
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
                                  GlassStateCard(icon: Icons.redeem_rounded, title: 'Nothing here yet.', message: 'Gifts show here when you send or get one.')))
                      : GridView.count(
                          padding: const EdgeInsets.all(16),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: .95,
                          children: [
                            for (final e in t.$2)
                              GiftsCardTile(
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
        child: NGlass(
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
              style: FilledButton.styleFrom(backgroundColor: GiftsPalette.amber, foregroundColor: GiftsPalette.bgBottom),
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
