/// Full Cart, Wishlist and Checkout pages opened from the Store bag sheets.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/cart_bag.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_backdrop.dart';
import '../../widgets/cart_add_animation.dart';
import 'bag_ui.dart';

String _inr(num value) {
  if (value <= 0) return 'Included';
  final n = value is int ? value : value.round();
  return '₹$n';
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _BagScaffold(
      title: 'Cart',
      eyebrow: 'NowssB Store',
      child: ListenableBuilder(
        listenable: CartBag.instance,
        builder: (context, _) {
          final bag = CartBag.instance;
          if (bag.cart.isEmpty) {
            return _PageEmpty(
              title: 'Nothing in the bag',
              body: 'Add a word, meaning or ebook from the Store.',
              action: 'Back to Store',
              onAction: () => Navigator.of(context).pop(),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              for (final it in bag.cart) _CartTile(item: it),
              const SizedBox(height: 12),
              _TotalRow(label: 'Subtotal', value: _inr(bag.cartTotal)),
              const SizedBox(height: 16),
              _GoldBtn(
                label: 'Checkout',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CheckoutPage()),
                ),
              ),
              if (bag.orders.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text(
                  'RECENT ORDERS',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: NwsbColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final o in bag.orders.take(5)) _OrderTile(order: o),
              ],
            ],
          );
        },
      ),
    );
  }
}

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _BagScaffold(
      title: 'Wishlist',
      eyebrow: 'NowssB Store',
      child: ListenableBuilder(
        listenable: CartBag.instance,
        builder: (context, _) {
          final bag = CartBag.instance;
          if (bag.wishlist.isEmpty) {
            return _PageEmpty(
              title: 'Nothing saved',
              body: 'Tap the heart on a word, meaning or ebook.',
              action: 'Back to Store',
              onAction: () => Navigator.of(context).pop(),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [for (final it in bag.wishlist) _WishTile(item: it)],
          );
        },
      ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  String _pay = 'UPI';
  BagOrder? _placed;
  String? _error;

  @override
  void initState() {
    super.initState();
    final bag = CartBag.instance;
    _name = TextEditingController(text: bag.shipName);
    _phone = TextEditingController(text: bag.shipPhone);
    _address = TextEditingController(text: bag.shipAddress);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    final bag = CartBag.instance;
    if (bag.cart.isEmpty) {
      setState(() => _error = 'Your cart is empty.');
      return;
    }
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().length < 8 ||
        _address.text.trim().isEmpty) {
      setState(() => _error = 'Add your name, phone and address.');
      return;
    }
    HapticFeedback.mediumImpact();
    final order = await bag.checkout(
      name: _name.text,
      phone: _phone.text,
      address: _address.text,
      payMethod: _pay,
    );
    if (!mounted) return;
    setState(() {
      _placed = order;
      _error = order == null ? 'Could not place the order.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_placed != null) {
      final o = _placed!;
      return _BagScaffold(
        title: 'Order placed',
        eyebrow: 'Checkout',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            Text(
              o.id,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${o.items.length} item${o.items.length == 1 ? '' : 's'} · ${_inr(o.total)} · ${o.payMethod}',
              style: const TextStyle(fontSize: 13, color: Color(0x99FFFFFF)),
            ),
            const SizedBox(height: 16),
            for (final it in o.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${it.title}  ×${it.qty}  ${_inr(it.lineTotal)}',
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${o.name}\n${o.phone}\n${o.address}',
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0x99FFFFFF),
              ),
            ),
            const SizedBox(height: 24),
            _GoldBtn(
              label: 'Back to Store',
              onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ],
        ),
      );
    }

    return _BagScaffold(
      title: 'Checkout',
      eyebrow: 'NowssB Store',
      child: ListenableBuilder(
        listenable: CartBag.instance,
        builder: (context, _) {
          final bag = CartBag.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              if (bag.cart.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Your cart is empty.',
                    style: TextStyle(color: Color(0x99FFFFFF)),
                  ),
                )
              else ...[
                for (final it in bag.cart)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        bagThumb(it.image),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${it.title}  ×${it.qty}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _inr(it.lineTotal),
                          style: const TextStyle(color: NwsbColors.goldLight),
                        ),
                      ],
                    ),
                  ),
                _TotalRow(label: 'To pay', value: _inr(bag.cartTotal)),
              ],
              const SizedBox(height: 22),
              const Text(
                'DELIVER TO',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: NwsbColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _Field(controller: _name, hint: 'Full name'),
              _Field(
                controller: _phone,
                hint: 'Phone',
                keyboard: TextInputType.phone,
              ),
              _Field(controller: _address, hint: 'Address', maxLines: 3),
              const SizedBox(height: 18),
              const Text(
                'PAY WITH',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: NwsbColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in const ['UPI', 'Card', 'Cash on delivery'])
                    ChoiceChip(
                      label: Text(p),
                      selected: _pay == p,
                      onSelected: (_) => setState(() => _pay = p),
                      selectedColor: NwsbColors.goldLight,
                      labelStyle: TextStyle(
                        color: _pay == p ? NwsbColors.ink : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      backgroundColor: const Color(0x14FFFFFF),
                      side: const BorderSide(color: Color(0x24FFFFFF)),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: Color(0xFFFF8A80))),
              ],
              const SizedBox(height: 22),
              _GoldBtn(label: 'Place order', onTap: _place),
            ],
          );
        },
      ),
    );
  }
}

class _BagScaffold extends StatelessWidget {
  const _BagScaffold({
    required this.eyebrow,
    required this.title,
    required this.child,
  });
  final String eyebrow, title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x88060C18), Color(0xAA060C18)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 19,
                            color: NwsbColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eyebrow.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w700,
                                color: NwsbColors.gold,
                              ),
                            ),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const StoreBagBar(),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item});
  final BagItem item;

  @override
  Widget build(BuildContext context) {
    final bag = CartBag.instance;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x52000000),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x17FFFFFF)),
      ),
      child: Row(
        children: [
          bagThumb(item.image, size: 56),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${item.kind} · ${_inr(item.price)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0x80FFFFFF),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QtyBtn(
                      icon: Icons.remove,
                      onTap: () => bag.setQty(item.id, item.qty - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.qty}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    _QtyBtn(
                      icon: Icons.add,
                      onTap: () => bag.setQty(item.id, item.qty + 1),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => bag.removeCart(item.id),
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WishTile extends StatelessWidget {
  const _WishTile({required this.item});
  final BagItem item;

  @override
  Widget build(BuildContext context) {
    final bag = CartBag.instance;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x52000000),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x17FFFFFF)),
      ),
      child: Row(
        children: [
          bagThumb(item.image, size: 56),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${item.kind} · ${_inr(item.price)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0x80FFFFFF),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await bag.moveWishToCart(item.id);
                        if (!context.mounted) return;
                        CartAddAnimation.play(
                          context,
                          fromContext: context,
                          item: item,
                        );
                      },
                      child: const Text(
                        'Add to cart',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: NwsbColors.goldLight,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => bag.removeWishlist(item.id),
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final BagOrder order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '${order.id} · ${_inr(order.total)} · ${order.payMethod}',
        style: const TextStyle(fontSize: 12, color: Color(0x80FFFFFF)),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x24FFFFFF)),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Color(0x99FFFFFF))),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _GoldBtn extends StatelessWidget {
  const _GoldBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xF2E8D5A3), Color(0xE6C8A96E)],
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: NwsbColors.ink,
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboard,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
          filled: true,
          fillColor: const Color(0x14FFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x24FFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x24FFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: NwsbColors.goldLight),
          ),
        ),
      ),
    );
  }
}

class _PageEmpty extends StatelessWidget {
  const _PageEmpty({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });
  final String title, body, action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0x99FFFFFF), height: 1.5),
            ),
            const SizedBox(height: 20),
            _GoldBtn(label: action, onTap: onAction),
          ],
        ),
      ),
    );
  }
}
