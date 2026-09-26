import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../screens/auth_gate.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_backdrop.dart';
import 'economy_api.dart';
import 'money.dart';

class EconomyPage extends StatelessWidget {
  const EconomyPage({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.banner,
    this.requireAuth = false,
  });

  final String title;
  final Widget child;
  final Widget? action;
  final Widget? banner;
  final bool requireAuth;

  @override
  Widget build(BuildContext context) {
    final body = requireAuth ? EconomyGate(child: child) : child;
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
                    colors: [Color(0x66060C18), Color(0x99060C18), Color(0xCC060C18)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, color: NwsbColors.goldLight),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (action != null) action!,
                    ],
                  ),
                ),
                if (banner != null) banner!,
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EconomyGate extends StatelessWidget {
  const EconomyGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!NwsbFirebase.ready) {
      return const EconomyMessage(
        title: 'Earn is not on this build yet',
        body: 'This phone has no Firebase connection, so coins and payouts stay closed.',
      );
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const EconomySkeleton();
        }
        if (snap.data == null) {
          return EconomyMessage(
            title: 'Sign in to open this',
            body: 'Rewards, resale, and payouts stay on your account.',
            action: 'Sign in',
            onAction: () => AuthGate.askForAccount(),
          );
        }
        return child;
      },
    );
  }
}

class EconomyMessage extends StatelessWidget {
  const EconomyMessage({super.key, required this.title, required this.body, this.action, this.onAction});
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: NwsbColors.gold, size: 36),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(color: NwsbColors.mist, height: 1.4)),
            if (action != null) ...[
              const SizedBox(height: 16),
              GoldButton(label: action!, onTap: onAction),
            ],
          ],
        ),
    );
  }
}

class EconomySkeleton extends StatelessWidget {
  const EconomySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0x18FFFFFF),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
      ],
    );
  }
}

class CoinCount extends StatelessWidget {
  const CoinCount({super.key, required this.value, this.style});
  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '${v.round()}',
        style: style ?? const TextStyle(fontSize: 42, color: NwsbColors.goldLight, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class MoneyCount extends StatelessWidget {
  const MoneyCount({super.key, required this.cents, this.style});
  final int cents;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FxBook.instance,
      builder: (context, _) => Text(
        FxBook.instance.formatCents(cents),
        style: style ?? const TextStyle(color: NwsbColors.goldLight, fontSize: 22, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: filled ? NwsbColors.gold : Colors.transparent,
          foregroundColor: filled ? NwsbColors.ink : NwsbColors.goldLight,
          disabledForegroundColor: NwsbColors.mist.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: filled ? BorderSide.none : const BorderSide(color: Color(0x55C8A96E)),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class EconomyNote extends StatelessWidget {
  const EconomyNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: NwsbColors.mist, fontSize: 13, height: 1.4));
  }
}

Future<void> runEconomy(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Done.')),
      );
    }
  } on EconomyException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          action: SnackBarAction(label: 'Retry', onPressed: () => runEconomy(context, action)),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That did not go through. Try again.')),
      );
    }
  }
}
