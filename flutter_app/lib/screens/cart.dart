/// Cart, wishlist and orders — three faces of the same shelf.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/intro_gate.dart';
import '../widgets/page_shell.dart';

enum CartKind { cart, wishlist, orders }

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.kind});
  final CartKind kind;

  @override
  Widget build(BuildContext context) {
    final (tag, title, film, empty) = switch (kind) {
      CartKind.cart => (
          'Cart',
          'Your cart',
          'assets/video/store-banner.mp4',
          'Nothing in the cart yet. Words you pick up in the store land here.'
        ),
      CartKind.wishlist => (
          'Wishlist',
          'Saved for later',
          'assets/video/signature-banner.mp4',
          'Tap the heart on a word and it waits here.'
        ),
      CartKind.orders => (
          'Orders',
          'Your orders',
          'assets/video/store-section.mp4',
          'Orders appear here after a purchase lands.'
        ),
    };

    return IntroGate(
      tag: tag,
      eyebrow: 'The shelf',
      title: title,
      body: empty,
      stats: const ['Razorpay', 'Studio published'],
      film: film,
      enterLabel: 'OPEN $tag'.toUpperCase(),
      onBack: () => Navigator.of(context).maybePop(),
      child: PageShell(
        eyebrow: tag,
        title: title,
        film: film,
        onBack: () => Navigator.of(context).maybePop(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.list(children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                ),
                child: Text(
                  empty,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xB3FFFFFF),
                    height: 1.55,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
