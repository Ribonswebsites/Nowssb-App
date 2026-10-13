/// Rebuilt Store hub (spec 9 / 22 / 25) behind `newui_store`.
/// Calm glass rails on a breathing aura. Page-local until the shared kit lands.
library;

import 'package:flutter/material.dart';

import '../../../widgets/app_backdrop.dart';
import 'store_card.dart';
import 'store_feed.dart';
import '../../../nowssb_ui/nowssb_ui.dart';

typedef StoreOpen = void Function(StoreDept dept, StoreItem? item);

class NewStorePage extends StatefulWidget {
  const NewStorePage({super.key, this.loader, this.onOpen, this.currency = 'USD', this.locale, this.background});
  final StoreLoader? loader;
  final StoreOpen? onOpen;

  /// Localized display currency (global app: never hardcode one country).
  final String currency;
  final String? locale;

  /// The app's original background (video/still). Tests pass a plain one.
  final Widget? background;

  @override
  State<NewStorePage> createState() => _NewStorePageState();
}

class _NewStorePageState extends State<NewStorePage> {
  late final StoreFeed _feed = StoreFeed(loader: widget.loader)..load();

  @override
  void dispose() {
    _feed.dispose();
    super.dispose();
  }

  static const _depts = [
    (StoreDept.words, 'Words', Icons.spa_rounded, NTokens.violet),
    (StoreDept.meanings, 'Meanings', Icons.menu_book_rounded, NTokens.mint),
    (StoreDept.signature, 'Signature', Icons.draw_rounded, NTokens.pink),
    (StoreDept.ebooks, 'E-books', Icons.auto_stories_rounded, NTokens.gold),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        Positioned.fill(child: widget.background ?? const AppBackdrop()),
        SafeArea(
          child: ListenableBuilder(
            listenable: _feed,
            builder: (context, _) => RefreshIndicator(
              onRefresh: _feed.load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: _Header()),
                  SliverToBoxAdapter(child: _deptGrid()),
                  ..._body(),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _deptGrid() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [
            for (final d in _depts)
              Semantics(
               button: true,
               label: 'Open ${d.$2}',
               child: NGlass(
                key: ValueKey('dept_${d.$1.name}'),
                accent: d.$4,
                onTap: () => widget.onOpen?.call(d.$1, null),
                child: Row(children: [
                  Icon(d.$3, color: d.$4),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(d.$2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: NTokens.textHi, fontWeight: FontWeight.w600)),
                  ),
                ]),
              )),
          ],
        ),
      );

  List<Widget> _body() {
    switch (_feed.phase) {
      case StorePhase.loading:
        return const [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(key: Key('store_loading'), color: NTokens.mint)),
            ),
          ),
        ];
      case StorePhase.empty:
        return [_notice(const Key('store_empty'), Icons.self_improvement_rounded, 'Nothing here yet. New words arrive soon.', retry: false)];
      case StorePhase.error:
        return [_notice(const Key('store_error'), Icons.cloud_off_rounded, _feed.message)];
      case StorePhase.offline:
        return [_notice(const Key('store_offline'), Icons.wifi_off_rounded, _feed.message)];
      case StorePhase.ready:
        return [for (final r in _feed.rails) SliverToBoxAdapter(child: _rail(r))];
    }
  }

  Widget _notice(Key key, IconData icon, String text, {bool retry = true}) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: NGlass(
            key: key,
            radius: NTokens.rHero,
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Icon(icon, color: NTokens.mint, size: 36),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center, style: const TextStyle(color: NTokens.textLo)),
              if (retry) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: _feed.load, style: TextButton.styleFrom(foregroundColor: NTokens.mint), child: const Text('Try again')),
              ],
            ]),
          ),
        ),
      );

  Widget _rail(StoreRail r) => _RefRail(
        rail: r,
        price: (m) => formatStorePrice(m, locale: widget.locale, currency: widget.currency),
        onOpen: (it) => widget.onOpen?.call(it.dept, it),
      );
}

class _RefRail extends StatefulWidget {
  const _RefRail({required this.rail, required this.price, required this.onOpen});
  final StoreRail rail;
  final String Function(int) price;
  final void Function(StoreItem) onOpen;
  @override
  State<_RefRail> createState() => _RefRailState();
}

class _RefRailState extends State<_RefRail> {
  final _pc = PageController(viewportFraction: .62);
  int _i = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _go(int i) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _pc.jumpToPage(i);
    } else {
      _pc.animateToPage(i, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.rail.items;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Semantics(
            header: true,
            child: Text(widget.rail.title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _pc,
            padEnds: false,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (_, i) {
              final it = items[i];
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 20 : 6, right: 6),
                child: StoreRefCard(
                  key: ValueKey('item_${it.id}'),
                  title: it.title,
                  body: it.subtitle,
                  price: widget.price(it.priceMinor),
                  image: NCircles.at(i + widget.rail.dept.index * 3),
                  isLast: i == items.length - 1,
                  onOpen: () => widget.onOpen(it),
                  onNext: () => _go(i + 1),
                  onSkip: () => _go(items.length - 1),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        StorePageDots(count: items.length, index: _i),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Store', style: TextStyle(color: NTokens.textHi, fontSize: 30, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('Breathe in. Choose words that stay with you.', style: TextStyle(color: NTokens.textLo)),
        ]),
      );
}
