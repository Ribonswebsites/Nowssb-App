/// Cart / Wishlist header chips and the notifications-style glass sheets.
library;

import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/cart_bag.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import 'cart_pages.dart';
import 'store_cards.dart';

enum BagKind { cart, wishlist }

Widget bagThumb(String src, {double size = 46}) {
  Widget child;
  if (src.startsWith('assets/')) {
    child = Image.asset(
      src,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
    );
  } else if (src.startsWith('http://') || src.startsWith('https://')) {
    child = CachedNetworkImage(
      imageUrl: src,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black),
    );
  } else {
    child = const ColoredBox(color: Colors.black);
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(11),
    child: SizedBox(width: size, height: size, child: child),
  );
}

class StoreBagBar extends StatelessWidget {
  const StoreBagBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartBag.instance,
      builder: (_, __) {
        final bag = CartBag.instance;
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              decoration: BoxDecoration(
                color: const Color(0x0FFFFFFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x24FFFFFF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BagCircle(
                    mark: NwsbMarks.wishlist,
                    count: bag.wishCount,
                    onTap: () => showBagSheet(context, BagKind.wishlist),
                  ),
                  const SizedBox(width: 8),
                  _BagCircle(
                    mark: NwsbMarks.cart,
                    count: bag.cartCount,
                    onTap: () => showBagSheet(context, BagKind.cart),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BagCircle extends StatelessWidget {
  const _BagCircle({
    required this.mark,
    required this.count,
    required this.onTap,
  });

  final String mark;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: NwsbIcon(
              mark,
              size: 18,
              color: NwsbColors.ink,
              strokeWidth: 1.7,
              viewBox: 22,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: NwsbColors.goldLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: NwsbColors.deep,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showBagSheet(BuildContext context, BagKind kind) {
  HapticFeedback.lightImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: kind == BagKind.cart ? 'Cart' : 'Wishlist',
    barrierColor: const Color(0xB7040812),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim, secondary) => _BagSheet(kind: kind),
    transitionBuilder: (context, anim, secondary, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: const Cubic(0.4, 0, 0.2, 1),
      );
      return FadeTransition(
        opacity: curved,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

class _BagSheet extends StatelessWidget {
  const _BagSheet({required this.kind});
  final BagKind kind;

  void _openAll(BuildContext context) {
    final nav = Navigator.of(context);
    nav.pop();
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => kind == BagKind.cart
              ? const CartPage()
              : const WishlistPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = kind == BagKind.cart;
    final maxH = MediaQuery.sizeOf(context).height * 0.8;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420, maxHeight: maxH),
            child: ListenableBuilder(
              listenable: CartBag.instance,
              builder: (context, _) {
                final bag = CartBag.instance;
                final items = cart ? bag.cart : bag.wishlist;
                return Material(
                  type: MaterialType.transparency,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0x0FFFFFFF),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0x24FFFFFF)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x8C000000),
                              blurRadius: 60,
                              offset: Offset(0, 26),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SheetHead(
                              title: cart ? 'Cart' : 'Wishlist',
                              subtitle: cart
                                  ? (items.isEmpty
                                      ? 'Your bag is empty'
                                      : '${bag.cartCount} item${bag.cartCount == 1 ? '' : 's'} · ${inr(bag.cartTotal)}')
                                  : (items.isEmpty
                                      ? 'Nothing saved yet'
                                      : '${bag.wishCount} saved'),
                              onClose: () => Navigator.of(context).pop(),
                            ),
                            Flexible(
                              child: items.isEmpty
                                  ? SingleChildScrollView(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 12, 12, 6),
                                      child: _Empty(
                                        cart: cart,
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 12, 12, 6),
                                      shrinkWrap: true,
                                      itemCount: items.length,
                                      itemBuilder: (context, i) {
                                        final it = items[i];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: _SheetRow(item: it, cart: cart),
                                        );
                                      },
                                    ),
                            ),
                            _SheetFoot(
                              secondary: cart ? 'CLEAR' : 'CLEAR',
                              onSecondary: () {
                                if (cart) {
                                  for (final e in List<BagItem>.from(bag.cart)) {
                                    bag.removeCart(e.id);
                                  }
                                } else {
                                  for (final e
                                      in List<BagItem>.from(bag.wishlist)) {
                                    bag.removeWishlist(e.id);
                                  }
                                }
                                HapticFeedback.mediumImpact();
                              },
                              primary: 'VIEW ALL',
                              onPrimary: () => _openAll(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHead extends StatelessWidget {
  const _SheetHead({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });
  final String title, subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w300,
                    color: Color(0x99FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration:
                  const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 16, color: NwsbColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetFoot extends StatelessWidget {
  const _SheetFoot({
    required this.secondary,
    required this.onSecondary,
    required this.primary,
    required this.onPrimary,
  });
  final String secondary, primary;
  final VoidCallback onSecondary, onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSecondary,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x21FFFFFF)),
                ),
                child: Text(
                  secondary,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Color(0x99FFFFFF),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onPrimary,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  primary,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: NwsbColors.deep,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.cart});
  final bool cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        children: [
          NwsbIcon(
            cart ? NwsbMarks.cart : NwsbMarks.wishlist,
            size: 28,
            color: const Color(0x4DFFFFFF),
            viewBox: 22,
          ),
          const SizedBox(height: 12),
          Text(
            cart ? 'Your cart is empty' : 'Your wishlist is empty',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0x9EFFFFFF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cart
                ? 'Add a word, meaning or ebook from the Store — it will land here.'
                : 'Tap the heart on anything you want to keep. View all opens the full list.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w300,
              color: Color(0x61FFFFFF),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.item, required this.cart});
  final BagItem item;
  final bool cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x52000000),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x17FFFFFF)),
      ),
      child: Row(
        children: [
          bagThumb(item.image),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  cart
                      ? '${item.kind} · ×${item.qty} · ${inr(item.lineTotal)}'
                      : '${item.kind} · ${inr(item.price)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0x80FFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
