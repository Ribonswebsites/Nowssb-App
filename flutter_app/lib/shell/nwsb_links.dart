/// Named in-app destinations, so every banner, shelf tile and button can
/// open its real page (no dead taps, no "opens the same page twice").
/// Tab switches go through [NavScope.goTo], which works from pushed pages.
library;

import 'package:flutter/material.dart';

import '../features/notifications/inbox_screen.dart';
import '../features/programs/program_router.dart';
import '../features/social/echo_wall_screen.dart';
import '../screens/daily_tasks.dart';
import '../screens/personal_coach.dart';
import '../screens/reader/reader_hub.dart';
import '../screens/saved_words.dart';
import '../screens/store/cart_pages.dart';
import '../screens/store/ebooks_store.dart';
import '../screens/store/meaning_store.dart';
import '../screens/store/request_words.dart';
import '../screens/store/signature_store.dart';
import '../screens/subscription.dart';
import 'nav_shell.dart';

abstract final class NwsbLinks {
  static Future<void> push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  static void tab(BuildContext context, int i) => NavScope.goTo(context, i);

  static void subscription(BuildContext context) => push(context, const SubscriptionScreen());
  static void meanings(BuildContext context) => push(context, const MeaningStoreScreen());
  static void signatures(BuildContext context) => push(context, const SignatureStoreScreen());
  static void ebooks(BuildContext context) => push(context, const EbooksStoreScreen());
  static void reader(BuildContext context) => push(context, const ReaderHubScreen());
  static void requestWord(BuildContext context) => push(context, const RequestWordsScreen());
  static void connect(BuildContext context) => push(context, const EchoWallScreen());
  static void cart(BuildContext context) => push(context, const CartPage());
  static void wishlist(BuildContext context) => push(context, const WishlistPage());
  static void activity(BuildContext context) => push(context, const InboxScreen());
  static void coach(BuildContext context) => push(context, const PersonalCoachScreen());
  static void saved(BuildContext context) => push(context, const SavedWordsScreen());
  static void tasks(BuildContext context) => push(context, const DailyTasksPage());

  /// The destination a banner's own button text promises.
  static void cta(BuildContext context, String cta) {
    final c = cta.toLowerCase();
    if (c.contains('sound library') || c.contains('open library')) return tab(context, 2);
    if (c.contains('signature')) return signatures(context);
    if (c.contains('ebook')) return ebooks(context);
    if (c.contains('meaning')) return meanings(context);
    if (c.contains('reader') || c.contains('science')) return reader(context);
    if (c.contains('request')) return requestWord(context);
    if (c.contains('redeem')) {
      Programmes.open(context, Programme.gifts, tab: 'redeem');
      return;
    }
    if (c.contains('gift')) {
      Programmes.open(context, Programme.gifts);
      return;
    }
    if (c.contains('share') || c.contains('link')) {
      Programmes.open(context, Programme.reference);
      return;
    }
    if (c.contains('coupon') || c.contains('scratch')) {
      Programmes.open(context, Programme.coupons);
      return;
    }
    if (c.contains('payout') || c.contains('sales') || c.contains('agents')) {
      Programmes.open(context, Programme.earn);
      return;
    }
    if (c.contains('reward')) {
      Programmes.open(context, Programme.rewards);
      return;
    }
    if (c.contains('practice') || c.contains('keep going') || c.contains('begin')) return tab(context, 1);
    if (c.contains('store') || c.contains('browse') || c.contains('shop')) return tab(context, 3);
    if (c.contains('editor') || c.contains('customi')) return tab(context, 4);
    return subscription(context);
  }
}
