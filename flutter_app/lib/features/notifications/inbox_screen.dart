import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../data/notifications.dart';
import '../../screens/nwsb_sign_in_sheet.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/restyle_kit.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../circle/circle_screen.dart';

/// Account activity — the page form of the bell inbox (messages, request
/// replies, orders, offers and on-phone reminders). Opened from Journal,
/// the drawer and `inbox` links. Coins and payouts live in NowssB Earn,
/// which the banner opens.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KitPage(
      eyebrow: 'Account',
      title: 'Activity',
      trailing: const CoinBalancePill(),
      children: [
        KitHero(
          art: const KitWordArt(word: 'EARN'),
          cornerLabel: 'Earn',
          eyebrow: 'Coins and payouts',
          title: 'NowssB Earn',
          subline: 'Open your coins, sales and payouts.',
          buttonIcon: Icons.arrow_forward_rounded,
          buttonLabel: 'Open',
          onButton: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CircleScreen()),
          ),
        ),
        ListenableBuilder(
          listenable: EconomyMirror.instance,
          builder: (context, _) {
            final uid = EconomyMirror.instance.uid;
            if (!NwsbFirebase.ready || uid == null) {
              return _EmptyPane(
                title: 'No activity yet',
                body: 'Sign in and your messages, orders and updates will collect here.',
                action: 'Sign in',
                onAction: () => NwsbSignInPage.open(context),
              );
            }
            return ListenableBuilder(
              listenable: NotifStore.instance,
              builder: (context, _) {
                final store = NotifStore.instance;
                final list = store.feed;
                if (list.isEmpty) {
                  return const _EmptyPane(
                    title: 'You are caught up',
                    body: 'Messages, request replies, orders and reminders land here.',
                  );
                }
                return KitPane(
                  eyebrow: 'Inbox',
                  title: 'Your activity',
                  mark: NwsbMarks.bell,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < list.length; i++)
                        KitRow(
                          highlighted: i == 0 && !list[i].read,
                          leading: _kindArt(list[i].type),
                          title: list[i].title,
                          sub: list[i].body,
                          trailing: !list[i].read
                              ? const NwsbIcon(NwsbMarks.bell, size: 16, color: Colors.white)
                              : null,
                          onTap: !list[i].read ? () => store.markRead(i) : null,
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({required this.title, required this.body, this.action, this.onAction});
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return KitPane(
      eyebrow: 'Inbox',
      title: title,
      mark: NwsbMarks.bell,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(body, style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 13.5, height: 1.4)),
          if (action != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0B0B10),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: const StadiumBorder(),
                ),
                onPressed: onAction,
                child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0B0B10))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _kindArt(String type) {
  if (type == 'coins') {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFF1A1A1A)),
      child: Center(child: NwsbCoinDisc(size: 28)),
    );
  }
  final mark = switch (type) {
    'update' => NwsbMarks.word,
    'orders' || 'delivery' || 'cart' => NwsbMarks.bag,
    'subscription' => NwsbMarks.crown,
    'offers' => NwsbMarks.trending,
    'routine' => NwsbMarks.hourglass,
    'streak' => NwsbMarks.features,
    _ => NwsbMarks.bell,
  };
  return DecoratedBox(
    decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
    child: Center(child: NwsbIcon(mark, size: 22, color: Colors.white)),
  );
}
