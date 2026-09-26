import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'economy_api.dart';

class EconomyPage extends StatelessWidget {
  const EconomyPage({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      appBar: AppBar(
        backgroundColor: const Color(0xFF05070D),
        foregroundColor: NwsbColors.goldLight,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [if (action != null) action!],
      ),
      body: child,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
