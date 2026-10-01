import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../../screens/nwsb_sign_in_sheet.dart';
import '../../widgets/app_thinking_loader.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import '../../theme/tokens.dart';
import 'economy_api.dart';
import 'money.dart';
import '../../admin/template/editable.dart';

class EconomyPage extends StatelessWidget {
  const EconomyPage({
    super.key,
    required this.title,
    required this.child,
    this.mark = NwsbMarks.word,
    this.action,
    this.banner,
  });

  final String title;
  final Widget child;
  final String mark;
  final Widget? action;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  _Mark(mark),
                  const SizedBox(width: 8),
                  const _BlackOrb(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: EditableLabel('economy_theme.EconomyPage',
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
            ),
            if (banner != null) banner!,
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark(this.mark);
  final String mark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: NwsbIcon(mark, size: 20, color: Colors.black, strokeWidth: 1.6),
    );
  }
}

class _BlackOrb extends StatelessWidget {
  const _BlackOrb();

  @override
  Widget build(BuildContext context) {
    return const AppThinkingLoader(
      size: 18,
      state: OrbState.composing,
      blackCircle: true,
      circlePad: 5,
    );
  }
}

class BlackOffer extends StatelessWidget {
  const BlackOffer({
    super.key,
    required this.title,
    required this.mark,
    required this.line,
    this.progress = 0,
    this.onTap,
    this.selected = false,
  });

  final String title;
  final String mark;
  final String line;
  final double progress;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassWrap(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? const Color(0xFFE4C56A) : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      WhiteCircleOrb(size: 16, mark: mark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: value),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        color: const Color(0xFFE4C56A),
                        backgroundColor: const Color(0x33FFFFFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const AppThinkingLoader(
                        size: 14,
                        state: OrbState.composing,
                        blackCircle: true,
                        circlePad: 3,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          line,
                          style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
            const NwsbIcon(NwsbMarks.word, color: NwsbColors.gold, size: 36),
            const SizedBox(height: 14),
            EditableLabel('economy_theme.EconomyMessage', title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            EditableLabel('economy_theme.EconomyMessage', body, textAlign: TextAlign.center, style: const TextStyle(color: NwsbColors.mist, height: 1.4)),
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
          backgroundColor: filled ? NwsbColors.gold : const Color(0xF0000000),
          foregroundColor: filled ? NwsbColors.ink : Colors.white,
          disabledForegroundColor: NwsbColors.mist.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: filled ? Colors.transparent : const Color(0x33FFFFFF),
            ),
          ),
        ),
        child: EditableLabel('economy_theme.GoldButton', label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class EconomyNote extends StatelessWidget {
  const EconomyNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return EditableLabel('economy_theme.EconomyNote', text, style: const TextStyle(color: NwsbColors.mist, fontSize: 13, height: 1.4));
  }
}

Future<void> runPrivate(BuildContext context, Future<void> Function() action) async {
  final ok = await NwsbSignInPage.open(context);
  if (!ok || !context.mounted) return;
  await runEconomy(context, action);
}

Future<void> runEconomy(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: EditableLabel('economy_theme.shared', 'Done.')),
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
        const SnackBar(content: EditableLabel('economy_theme.shared', 'That did not go through. Try again.')),
      );
    }
  }
}
