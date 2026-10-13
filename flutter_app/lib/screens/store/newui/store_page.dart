/// Rebuilt Store hub and the Words / Meanings store pages (spec 9/22/25).
///
/// Every card follows Ribon's approved designs (5:53 PM IST):
/// - approved-1: the kit `MeditationCard` (round photo, inner frosted panel,
///   bold title, grey body, Skip + white Next pill, page dots),
/// - approved-2: a frosted MeditationCard carousel above a "list" of frosted
///   `CouponListCard` tickets with rarity pills.
/// Background is the app's original video (`NAppBackdrop`), nothing added.
library;

import 'package:flutter/material.dart';

import '../../../kit/kit.dart';
import '../../../nowssb_ui/nowssb_ui.dart';
import 'store_feed.dart';

typedef StoreOpen = void Function(StoreDept dept, StoreItem? item);

void _defaultOpen(BuildContext context, StoreDept dept, StoreItem? item) {
  final page = switch (dept) {
    StoreDept.words => AppPage.storeWords,
    StoreDept.meanings => AppPage.storeMeanings,
    StoreDept.signature => AppPage.storeSignature,
    StoreDept.ebooks => AppPage.storeEbooks,
  };
  AppRoutes.open(context, page, source: 'store_newui', id: item?.id);
}

const _deptInfo = {
  StoreDept.words: ('Word Atelier', 'Own the words that calm you. Each one carries its sound and story.'),
  StoreDept.meanings: ('Meanings', 'Unlock the root and meaning behind every word you love.'),
  StoreDept.signature: ('Signature', 'Rare, one-of-a-kind words made into your signature.'),
  StoreDept.ebooks: ('Ebooks', 'Read the science of sound, one gentle chapter at a time.'),
};

/// Rarity pill for a product, from its price band (display only).
Rarity _rarityFor(int usdCents) => usdCents >= 400
    ? Rarity.legendary
    : usdCents >= 200
        ? Rarity.epic
        : usdCents >= 100
            ? Rarity.rare
            : Rarity.common;

/// A hub shortcut to a page outside the catalogue (Get Verified, Plans...).
class StoreShortcut {
  const StoreShortcut(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final void Function(BuildContext context) onTap;
}

/// Store hub (`/store`).
class NewStorePage extends StatelessWidget {
  const NewStorePage({super.key, this.loader, this.onOpen, this.locale, this.background, this.shortcuts = const []});
  final List<StoreShortcut> shortcuts;
  final StoreLoader? loader;
  final StoreOpen? onOpen;
  final String? locale;

  /// Override for tests/screenshots; defaults to the app's original video.
  final Widget? background;

  @override
  Widget build(BuildContext context) => _StoreScaffold(
        title: 'Store',
        subtitle: 'Breathe in. Choose words that stay with you.',
        loader: loader,
        background: background,
        builder: (context, rails) {
          final open = onOpen ?? (d, i) => _defaultOpen(context, d, i);
          final deals = [for (final r in rails) ...r.items.take(2)];
          return [
            _CardCarousel(
              railKey: 'depts',
              entries: [
                for (final d in StoreDept.values)
                  _Entry(
                    key: 'dept_${d.name}',
                    title: _deptInfo[d]!.$1,
                    body: _deptInfo[d]!.$2,
                    image: NCircles.at(d.index * 2),
                    semantics: 'Open ${_deptInfo[d]!.$1}',
                    onOpen: () => open(d, null),
                  ),
              ],
            ),
            if (shortcuts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final sc in shortcuts)
                    Semantics(
                      button: true,
                      label: sc.label,
                      child: GlassPill(key: ValueKey('shortcut_${sc.label}'), label: sc.label, icon: sc.icon, onTap: () => sc.onTap(context)),
                    ),
                ]),
              ),
            if (deals.isNotEmpty) _TicketList(title: 'Today\'s picks', items: deals, locale: locale, onOpen: open),
          ];
        },
      );
}

/// Words or Meanings store (`/store/words`, `/store/meanings`).
class StoreDeptPage extends StatelessWidget {
  const StoreDeptPage({super.key, required this.dept, this.loader, this.onOpen, this.locale, this.background});
  final StoreDept dept;
  final StoreLoader? loader;
  final StoreOpen? onOpen;
  final String? locale;
  final Widget? background;

  @override
  Widget build(BuildContext context) => _StoreScaffold(
        title: _deptInfo[dept]!.$1,
        subtitle: _deptInfo[dept]!.$2,
        loader: loader,
        background: background,
        back: true,
        builder: (context, rails) {
          final items = [for (final r in rails) if (r.dept == dept) ...r.items];
          final open = onOpen ?? (d, i) => _defaultOpen(context, d, i);
          if (items.isEmpty) {
            return const [_Notice(key: Key('store_empty'), icon: Icons.self_improvement_rounded, title: 'Nothing here yet', message: 'New pieces arrive soon.')];
          }
          return [
            _CardCarousel(
              railKey: dept.name,
              entries: [
                for (var i = 0; i < items.length && i < 6; i++)
                  _Entry(
                    key: 'item_${items[i].id}',
                    title: items[i].title,
                    body: '${items[i].subtitle} · ${formatStorePrice(items[i].priceMinor, locale: locale)}',
                    image: NCircles.at(i + dept.index * 3),
                    semantics: '${items[i].title}, ${formatStorePrice(items[i].priceMinor, locale: locale)}',
                    onOpen: () => open(dept, items[i]),
                  ),
              ],
            ),
            _TicketList(title: 'All ${_deptInfo[dept]!.$1.toLowerCase()}', items: items, locale: locale, onOpen: open),
          ];
        },
      );
}

class _StoreScaffold extends StatefulWidget {
  const _StoreScaffold({
    required this.title,
    required this.subtitle,
    required this.builder,
    this.loader,
    this.background,
    this.back = false,
  });
  final String title, subtitle;
  final StoreLoader? loader;
  final Widget? background;
  final bool back;
  final List<Widget> Function(BuildContext, List<StoreRail>) builder;

  @override
  State<_StoreScaffold> createState() => _StoreScaffoldState();
}

class _StoreScaffoldState extends State<_StoreScaffold> {
  late final StoreFeed _feed = StoreFeed(loader: widget.loader)..load();

  @override
  void dispose() {
    _feed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [
          Positioned.fill(child: widget.background ?? const NAppBackdrop()),
          SafeArea(
            child: ListenableBuilder(
              listenable: _feed,
              builder: (context, _) => RefreshIndicator(
                onRefresh: _feed.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    _Header(title: widget.title, subtitle: widget.subtitle, back: widget.back),
                    ..._body(context),
                  ],
                ),
              ),
            ),
          ),
        ]),
      );

  List<Widget> _body(BuildContext context) => switch (_feed.phase) {
        StorePhase.loading => const [
            Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(key: Key('store_loading'), color: Colors.white)),
            ),
          ],
        StorePhase.empty => const [
            _Notice(key: Key('store_empty'), icon: Icons.self_improvement_rounded, title: 'Nothing here yet', message: 'New words arrive soon.'),
          ],
        StorePhase.error => [
            _Notice(key: const Key('store_error'), icon: Icons.cloud_off_rounded, title: 'Something went wrong', message: _feed.message, onRetry: _feed.load),
          ],
        StorePhase.offline => [
            _Notice(key: const Key('store_offline'), icon: Icons.wifi_off_rounded, title: 'You are offline', message: _feed.message, onRetry: _feed.load),
          ],
        StorePhase.ready => widget.builder(context, _feed.rails),
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, required this.back});
  final String title, subtitle;
  final bool back;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (back && Navigator.of(context).canPop())
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassPill(label: 'Back', icon: Icons.arrow_back_rounded, dense: true, onTap: () => Navigator.of(context).maybePop()),
            ),
          Semantics(
            header: true,
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: NTokens.textLo, fontSize: 13)),
        ]),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.icon, required this.title, required this.message, this.onRetry});
  final IconData icon;
  final String title, message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassStateCard(icon: icon, title: title, message: message, action: onRetry == null ? null : 'Try again', onAction: onRetry),
      );
}

class _Entry {
  const _Entry({required this.key, required this.title, required this.body, required this.image, required this.semantics, required this.onOpen});
  final String key, title, body, semantics;
  final ImageProvider image;
  final VoidCallback onOpen;
}

/// approved-1 / approved-2 top: MeditationCard carousel with page dots.
class _CardCarousel extends StatefulWidget {
  const _CardCarousel({required this.railKey, required this.entries});
  final String railKey;
  final List<_Entry> entries;
  @override
  State<_CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<_CardCarousel> {
  final _pc = PageController(viewportFraction: .74);
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
    final e = widget.entries;
    return SizedBox(
      height: 470,
      child: PageView.builder(
        key: ValueKey('carousel_${widget.railKey}'),
        controller: _pc,
        padEnds: false,
        itemCount: e.length,
        onPageChanged: (i) => setState(() => _i = i),
        itemBuilder: (_, i) {
          final last = i == e.length - 1;
          return Padding(
            key: ValueKey(e[i].key),
            padding: EdgeInsets.only(left: i == 0 ? 20 : 6, right: 6, bottom: 8),
            child: Semantics(
              button: true,
              label: e[i].semantics,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: e[i].onOpen,
                child: MeditationCard(
                  title: e[i].title,
                  subtitle: e[i].body,
                  image: e[i].image,
                  secondary: last ? null : 'Skip',
                  cta: last ? 'Open' : 'Next',
                  onCta: last ? e[i].onOpen : () => _go(i + 1),
                  dots: e.length,
                  dotIndex: _i,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// approved-2 bottom: "COUPON LIST"-style frosted ticket rows with rarity pills.
class _TicketList extends StatelessWidget {
  const _TicketList({required this.title, required this.items, required this.onOpen, this.locale});
  final String title;
  final List<StoreItem> items;
  final StoreOpen onOpen;
  final String? locale;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Semantics(
              header: true,
              child: Text(title.toUpperCase(),
                  style: const TextStyle(color: NTokens.mint, fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
            ),
          ),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                button: true,
                label: '${items[i].title}, ${formatStorePrice(items[i].priceMinor, locale: locale)}',
                child: CouponListCard(
                  key: ValueKey('ticket_${items[i].id}'),
                  label: items[i].subtitle,
                  offer: '${items[i].title} · ${formatStorePrice(items[i].priceMinor, locale: locale)}',
                  image: NCircles.at(i),
                  isNew: i < 2,
                  rarity: _rarityFor(items[i].priceMinor),
                  onTap: () => onOpen(items[i].dept, items[i]),
                ),
              ),
            ),
        ]),
      );
}
