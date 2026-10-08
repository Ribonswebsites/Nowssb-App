/// Full Cart, Wishlist and Checkout pages opened from the Store bag sheets.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/billing_config.dart';
import '../../data/cart_bag.dart';
import '../../data/entitlements.dart';
import '../../data/store_prices.dart';
import '../../theme/tokens.dart';
import '../../widgets/cart_add_animation.dart';
import '../../widgets/page_shell.dart';
import '../../features/economy/money.dart';
import '../../features/programs/store_extras.dart';
import '../nwsb_sign_in_sheet.dart';
import '../subscription.dart';
import 'bag_ui.dart';
import 'store_routes.dart';
import 'store_select_sheet.dart';
import '../../admin/template/editable.dart';

String _inr(num value) {
  if (value <= 0) return 'Included';
  return FxBook.instance.formatRupees(value);
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _BagScaffold(
      title: 'Cart',
      eyebrow: 'NowssB Store',
      child: ListenableBuilder(
        listenable: Listenable.merge([CartBag.instance, Entitlements.instance]),
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
              _TotalRow(label: 'Subtotal', value: _inr(_payable(bag.cart))),
              const SizedBox(height: 16),
              _GoldBtn(
                label: 'Checkout on Google Play',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CheckoutPage()),
                ),
              ),
              const _PurchasesBlock(),
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

/// What the cart still costs: items not owned and not included in a plan.
num _payable(List<BagItem> items) {
  final e = Entitlements.instance;
  num total = 0;
  for (final it in items) {
    final price = StorePrices.instance.priceFor(it.id, shown: it.price);
    if (price <= 0 || e.ownsOrIncluded(it.id, price: price)) continue;
    total += price;
  }
  return total;
}

/// Checkout for digital items: every word, meaning, Signature piece and
/// ebook is bought on Google Play, one purchase per item (or ten words as a
/// bundle). There is no address, no card form and no order on the phone —
/// an item is yours when the server has confirmed the Play purchase and
/// written it to your account (users/{uid}/owned).
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, this.items});

  /// Buy just these (an "Unlock" button); null = the whole cart.
  final List<BagItem>? items;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _message;

  List<BagItem> get _items => widget.items ?? CartBag.instance.cart;

  bool _open(BagItem it) {
    final price = StorePrices.instance.priceFor(it.id, shown: it.price);
    return price <= 0 || Entitlements.instance.ownsOrIncluded(it.id, price: price);
  }

  String _priceLabel(BagItem it) {
    final price = StorePrices.instance.priceFor(it.id, shown: it.price);
    return price <= 0 ? 'Free' : _inr(price);
  }

  /// Cart lines for the server checkout: {id, kind, title, price, qty}.
  List<Map<String, dynamic>> _lines(List<BagItem> toBuy) => [
        for (final it in toBuy)
          {
            'id': it.id,
            'kind': contentKindOfItem(it.id) ?? it.kind.toLowerCase(),
            'title': it.title,
            'price': StorePrices.instance.priceFor(it.id, shown: it.price),
            'qty': 1,
          },
      ];

  void _paid(List<BagItem> bought, Map<String, dynamic> result) {
    for (final it in bought) {
      CartBag.instance.removeCart(it.id);
    }
    if (!mounted) return;
    setState(() => _message = bought.length == 1
        ? '${bought.first.title} is yours. It opens on every phone you sign in to.'
        : 'Your ${bought.length} items are yours. They open on every phone you sign in to.');
  }

  @override
  Widget build(BuildContext context) {
    return _BagScaffold(
      title: 'Checkout',
      eyebrow: 'NowssB Store',
      child: ListenableBuilder(
        listenable: Listenable.merge([
          CartBag.instance,
          Entitlements.instance,
          StorePrices.instance,
        ]),
        builder: (context, _) {
          final items = _items;
          final toBuy = [for (final it in items) if (!_open(it)) it];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: EditableLabel('cart_pages.CheckoutPage',
                    'Your cart is empty.',
                    style: TextStyle(color: Color(0x99FFFFFF)),
                  ),
                )
              else
                for (final it in items)
                  _CheckoutRow(
                    item: it,
                    price: _priceLabel(it),
                    state: _open(it)
                        ? (StorePrices.instance.priceFor(it.id, shown: it.price) <= 0
                            ? 'Free'
                            : Entitlements.instance.ownsItem(it.id)
                                ? 'Owned'
                                : 'In your plan')
                        : null,
                  ),
              const SizedBox(height: 10),
              const EditableLabel('cart_pages.CheckoutPage',
                'HOW YOU PAY',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: NwsbColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const EditableLabel('cart_pages.CheckoutPage',
                'Words, meanings and ebooks are digital: nothing is shipped. You pay securely on Google Play in your own currency; coupons and coins can lower the price. Items unlock on every phone you sign in to once Google confirms the payment.',
                style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 14),
              if (toBuy.isNotEmpty && !Entitlements.instance.signedIn)
                _GoldBtn(
                  label: 'Sign in to pay',
                  onTap: () => NwsbSignInPage.open(context),
                )
              else if (toBuy.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x52000000),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x17FFFFFF)),
                  ),
                  child: CheckoutPanel(
                    items: _lines(toBuy),
                    onPaid: (r) => _paid(toBuy, r),
                  ),
                ),
              if (_message != null) ...[
                const SizedBox(height: 14),
                Text(_message!, style: const TextStyle(color: Color(0xFFA5D6A7))),
              ],
              const SizedBox(height: 18),
              if (toBuy.isEmpty && items.isNotEmpty)
                _GoldBtn(
                  label: 'Done',
                  onTap: () => Navigator.of(context).pop(),
                )
              else if (toBuy.isNotEmpty)
                _GoldBtn(
                  label: 'See plans that include these',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CheckoutRow extends StatelessWidget {
  const _CheckoutRow({
    required this.item,
    required this.price,
    required this.state,
  });
  final BagItem item;
  final String price;

  /// 'Free' / 'Owned' / 'In your plan', or null when it still has to be bought.
  final String? state;

  @override
  Widget build(BuildContext context) {
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
          bagThumb(item.image),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                Text('${item.kind} · $price',
                    style: const TextStyle(fontSize: 11, color: Color(0x80FFFFFF))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (state != null)
            Text(state!, style: const TextStyle(color: Color(0xFFA5D6A7), fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BuyOnPlayPill extends StatelessWidget {
  const _BuyOnPlayPill({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: NwsbColors.goldLight,
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shop_rounded, size: 14, color: NwsbColors.ink),
              SizedBox(width: 5),
              EditableLabel('cart_pages.BuyOnPlayPill',
                'Buy on Google Play',
                style: TextStyle(color: NwsbColors.ink, fontWeight: FontWeight.w800, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The items this account really owns (server-confirmed), instead of the
/// old phone-only "orders".
class _PurchasesBlock extends StatelessWidget {
  const _PurchasesBlock();

  static String _label(String docId) {
    final i = docId.indexOf('_');
    if (i <= 0) return docId;
    final kind = docId.substring(0, i);
    final name = docId.substring(i + 1).replaceAll('_', ' ');
    final nice = name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
    return '$nice · ${kind[0].toUpperCase()}${kind.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Entitlements.instance,
      builder: (context, _) {
        final owned = Entitlements.instance.owned.toList()..sort();
        if (owned.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            const EditableLabel('cart_pages.CartPage',
              'YOUR PURCHASES',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: NwsbColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final id in owned.take(20))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_label(id), style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
              ),
          ],
        );
      },
    );
  }
}

/// Cart, wishlist and checkout wear the Store's own shell (PageShell: the
/// brand back control, "NowssB Store" heading, the bag and the store picker),
/// the same as the four departments.
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
    return PageShell(
      eyebrow: '',
      title: 'NowssB Store',
      subtitle: title,
      film: 'assets/video/player-bg-loop.mp4',
      usePageFilm: true,
      onBack: () => Navigator.of(context).pop(),
      onStorePicker: () => showStoreSelectSheet(
        context,
        onSelect: (id) => openStoreFromPicker(context, id, current: ''),
      ),
      slivers: [
        SliverFillRemaining(hasScrollBody: true, child: child),
      ],
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
                  '${item.kind} · ${_inr(StorePrices.instance.priceFor(item.id, shown: item.price))}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0x80FFFFFF),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ListenableBuilder(
                      listenable: Entitlements.instance,
                      builder: (context, _) {
                        final price = StorePrices.instance.priceFor(item.id, shown: item.price);
                        if (price <= 0 || Entitlements.instance.ownsOrIncluded(item.id, price: price)) {
                          return Text(
                            price <= 0 ? 'Free' : Entitlements.instance.ownsItem(item.id) ? 'Owned' : 'In your plan',
                            style: const TextStyle(color: Color(0xFFA5D6A7), fontWeight: FontWeight.w700, fontSize: 12),
                          );
                        }
                        return _BuyOnPlayPill(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => CheckoutPage(items: [item])),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => bag.removeCart(item.id),
                      child: const EditableLabel('cart_pages.CartTile',
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
                  '${item.kind} · ${_inr(StorePrices.instance.priceFor(item.id, shown: item.price))}',
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
                      child: const EditableLabel('cart_pages.WishTile',
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
                      child: const EditableLabel('cart_pages.WishTile',
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

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        EditableLabel('cart_pages.TotalRow', label, style: const TextStyle(color: Color(0x99FFFFFF))),
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
        child: EditableLabel('cart_pages.GoldBtn',
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
            EditableLabel('cart_pages.PageEmpty',
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            EditableLabel('cart_pages.PageEmpty',
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
