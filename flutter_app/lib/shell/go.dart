/// Open a destination from a home section without each block knowing how
/// the shell is built.
library;

import 'package:flutter/material.dart';

import '../screens/cart.dart';
import '../screens/connect.dart';
import '../screens/fashion_plus.dart';
import '../screens/healing.dart';
import '../screens/login.dart';
import '../screens/player.dart';
import '../screens/routines.dart';
import '../screens/sound_library.dart';
import '../screens/subscribe.dart';
import '../screens/widgets_page.dart';
import 'nav_shell.dart';

class Dest {
  Dest._();

  static const connectTab = 0;
  static const practice = 1;
  static const library = 2;
  static const store = 3;
  static const profile = 4;

  static const player = 'player';
  static const routines = 'routines';
  static const connect = 'connect';
  static const cart = 'cart';
  static const wishlist = 'wishlist';
  static const orders = 'orders';
  static const subscribe = 'subscribe';
  static const healing = 'healing';
  static const fashionPlus = 'fashionPlus';
  static const settings = 'settings';
  static const sound = 'sound';
  static const login = 'login';
  static const searchWords = 'searchWords';
  static const searchMeanings = 'searchMeanings';

  static void open(BuildContext context, Object dest) {
    if (dest is int) {
      NavScope.goTo(context, dest);
      return;
    }
    final key = '$dest';
    if (key == searchWords || key == searchMeanings) {
      NavScope.goTo(context, library);
      return;
    }
    final page = _page(key);
    if (page == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  static Widget? _page(String dest) {
    return switch (dest) {
      player => const PlayerScreen(),
      routines => const RoutinesScreen(),
      connect => const ConnectScreen(),
      cart => const CartScreen(kind: CartKind.cart),
      wishlist => const CartScreen(kind: CartKind.wishlist),
      orders => const CartScreen(kind: CartKind.orders),
      subscribe => const SubscribeScreen(),
      healing => const HealingScreen(),
      fashionPlus => const FashionPlusScreen(),
      settings => const WidgetsPage(),
      sound => const SoundLibraryScreen(),
      login => const LoginScreen(),
      _ => null,
    };
  }
}
