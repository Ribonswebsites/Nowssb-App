/// Reference link. One code, one parent. Level 2 is the parent's parent.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import 'economy_api.dart';
import 'economy_theme.dart';
import '../programs/program_kit.dart';
import '../programs/reference_program.dart';
import '../programs/program_heroes.dart';
import '../programs/program_router.dart';
import '../../widgets/four_banners.dart';
import '../../widgets/hub_rails.dart';
import '../../widgets/routine_deck.dart';
import '../../widgets/n_motion.dart';

class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key, this.initialTab});

  /// Opens scrolled to one programme tab (e.g. 'board').
  final String? initialTab;

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  final _code = TextEditingController();
  String? _note;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      goodToKnow: kReferenceDisclaimer,
      title: 'Reference',
      mark: NwsbMarks.reference,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const IdentityRails(RailKind.earn),
          RoutineDeck(
            title: 'Reference',
            banner: 'Your link',
            bannerSub: 'One code. A friend’s first valid link counts.',
            onBanner: () => _share(context),
            cards: [
              WorkCard(category: 'Code', title: 'Copy your code', meta: 'The code on this account', action: 'Copy', image: 'assets/rails/earn-05.jpg', onTap: () => _share(context)),
              WorkCard(category: 'Code', title: 'Apply a code', meta: 'Someone else’s code, once', action: 'Apply', image: 'assets/rails/earn-06.jpg', onTap: () => _applySheet(context)),
              WorkCard(category: 'Earn', title: 'NowssB Earn', meta: 'Cash on real sales', action: 'Open earn', image: 'assets/rails/gen-66.jpg', onTap: () => Programmes.open(context, Programme.earn)),
              WorkCard(category: 'Board', title: 'Your links', meta: 'Friends on this code', action: 'Open board', image: 'assets/rails/earn-07.jpg', onTap: () => _tabs('board')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final code = EconomyMirror.instance.code;
    if (code.isEmpty) {
      setState(() => _note = 'Your code shows once this account has one.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) setState(() => _note = 'Code copied.');
  }

  void _applySheet(BuildContext context) {
    showNSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10141C),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _code,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'Someone else’s code'),
            ),
            const SizedBox(height: 12),
            GoldButton(
              label: 'Apply code',
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await EconomyApi.call('applyReferralCode', {'code': _code.text.trim()});
                  if (mounted) setState(() => _note = 'Code saved. It cannot be changed.');
                } on EconomyException catch (e) {
                  if (mounted) setState(() => _note = EconomyApi.isMissing(e) ? EconomyApi.switchingOnMessage : e.message);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _tabs(String id) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Scaffold(
      backgroundColor: const Color(0xFF07070C),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [ProgramTabsBlock(spec: kReferenceSpec, initialTab: id, scrollTo: true, showDisclaimer: false)],
      )),
    )));
  }
}
