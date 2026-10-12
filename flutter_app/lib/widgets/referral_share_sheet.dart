/// RB-referral (Oct 12): a calm bottom sheet that shows the user's referral
/// code big in a glass pill, with one Copy and one Share action.
///
/// Layout comes from the RB-plans design (be23004): a single focus, page
/// dots, one big pill button. Original NowssB colours and GlassBlackCard
/// glass (8:22 PM rule). The caller passes the code (Rewards owns where it
/// comes from); sharing uses share_plus like ShareItemButtons does.
///
///   import 'package:nowssb/widgets/referral_share_sheet.dart';
///   showReferralShareSheet(context, code: 'ABC123');
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../admin/template/editable.dart';
import '../theme/tokens.dart';
import 'glass_black_card.dart';

const _slot = 'referral_share_sheet.ReferralShareSheet';

Future<void> showReferralShareSheet(BuildContext context,
    {required String code}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000),
    builder: (_) => ReferralShareSheet(code: code),
  );
}

class ReferralShareSheet extends StatelessWidget {
  const ReferralShareSheet({super.key, required this.code});
  final String code;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.selectionClick();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Code copied')));
    }
  }

  Future<void> _share() => SharePlus.instance.share(ShareParams(
        text: 'Try NowssB with my code $code',
        subject: 'NowssB',
      ));

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(UiSpace.md, 0, UiSpace.md, UiSpace.md + bottom),
      child: GlassBlackCard(
        radius: 32,
        intensity: 0.9,
        padding: const EdgeInsets.fromLTRB(
            UiSpace.xl, UiSpace.lg, UiSpace.xl, UiSpace.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: UiSpace.xl),
          const EditableLabel(_slot, 'INVITE A FRIEND',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color: NwsbColors.gold)),
          const SizedBox(height: UiSpace.sm),
          const EditableLabel(_slot, 'Share your code',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: UiSpace.xl),
          // The code, big, in a glass pill. Tap copies too.
          Semantics(
            button: true,
            label: 'Copy code $code',
            child: GestureDetector(
              onTap: () => _copy(context),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(UiRadii.pill),
                  border: Border.all(color: const Color(0x4DE8D5A3)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SelectableText(code,
                        style: const TextStyle(
                            fontSize: 30,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w800,
                            color: NwsbColors.goldLight)),
                    const SizedBox(width: UiSpace.md),
                    const Icon(Icons.copy_rounded,
                        color: Color(0x99E8D5A3), size: 20),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: UiSpace.lg),
          // Page dots (RB-plans rhythm): one step, in focus.
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: i == 0 ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color:
                      i == 0 ? NwsbColors.goldLight : const Color(0x33FFFFFF),
                ),
              ),
          ]),
          const SizedBox(height: UiSpace.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: NwsbColors.goldLight,
                foregroundColor: NwsbColors.deep,
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
              ),
              onPressed: _share,
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              label: const Text('Share',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: UiSpace.sm),
          TextButton(
            onPressed: () => _copy(context),
            child: const Text('Copy code',
                style: TextStyle(
                    color: NwsbColors.goldLight, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
