/// Short first-use guide shown once, replayable from Settings > Help.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../nowssb_ui/nowssb_ui.dart';
import 'ms_widgets.dart';

const _kSeen = 'ms_guide_seen_v1';

const guideSteps = <(String, String)>[
  ('Breathe in', 'The menu holds four calm places: Practice, Learn, Rewards and You.'),
  ('Find your sound', 'Settings keep only what matters: sound, look, privacy and help.'),
  ('Always yours', 'Privacy, terms, sign out and delete account live under Privacy & account.'),
];

Future<void> showMsGuideOnce(BuildContext context) async {
  try {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_kSeen) ?? false) return;
    await p.setBool(_kSeen, true);
  } catch (_) {
    return;
  }
  if (context.mounted) await showMsGuide(context);
}

Future<void> showMsGuide(BuildContext context) => showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const MsGuideDialog(),
    );

class MsGuideDialog extends StatefulWidget {
  const MsGuideDialog({super.key});
  @override
  State<MsGuideDialog> createState() => _MsGuideDialogState();
}

class _MsGuideDialogState extends State<MsGuideDialog> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final (title, body) = guideSteps[_i];
    final last = _i == guideSteps.length - 1;
    return Dialog(
      key: const Key('ms_guide'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: NGlass(
        radius: NTokens.rHero,
        blur: kMsBlur,
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 6),
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .5), width: 2),
              color: Colors.white.withValues(alpha: .12),
            ),
            child: const Icon(Icons.self_improvement_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 16),
          NGlass(
            radius: NTokens.rCard,
            elevation: .3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(body, style: const TextStyle(color: kTextLo, fontSize: 12, height: 1.4)),
              const SizedBox(height: 14),
              Row(children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Skip', style: TextStyle(color: kTextLo, fontSize: 12)),
                ),
                const Spacer(),
                msPill(last ? 'Begin' : 'Next',
                    () => last ? Navigator.of(context).pop() : setState(() => _i++),
                    primary: last),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var d = 0; d < guideSteps.length; d++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: d == _i ? 16 : 6, height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.white.withValues(alpha: d == _i ? .95 : .4),
                    ),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
