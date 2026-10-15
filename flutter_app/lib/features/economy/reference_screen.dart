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
          HubRails(
            labels: const ['Your link', 'Open', 'Share', 'Glass', 'Clear'],
            openGuide: false,
            onOpen: (card) {
              switch (card.title) {
                case 'NowssB Earn':
                  Programmes.open(context, Programme.earn);
                break;
                case 'Rewards':
                  Programmes.open(context, Programme.rewards);
                break;
                case 'Gifts':
                  Programmes.open(context, Programme.gifts);
                break;
                case 'Coupons':
                  Programmes.open(context, Programme.coupons);
                break;
                case 'Copy your code':
                  _share(context);
                break;
                case 'Apply a code':
                  _applySheet(context);
                break;
                case 'Your links':
                  _tabs('board');
                break;
                case 'Friends':
                  _tabs('friends');
                break;
                case 'Share cards':
                  _tabs('cards');
                break;
                case 'Rules':
                  _tabs('rules');
                break;
              }
            },
            a: const [
              RailCard('Copy your code', 'The code on this account', 'Copy', art: 'assets/rails/earn-05.jpg'),
              RailCard('Apply a code', 'Someone else’s code, once', 'Apply', art: 'assets/rails/earn-06.jpg'),
              RailCard('Your links', 'Friends on this code', 'Board', art: 'assets/rails/earn-07.jpg'),
            ],
            b: const [
              RailCard('NowssB Earn', 'Cash on real sales', 'Open', art: 'assets/rails/earn-02.jpg'),
              RailCard('Rewards', 'Coins you spend', 'Open', art: 'assets/rails/art-coins.jpg'),
              RailCard('Gifts', 'Send a plan', 'Open', art: 'assets/rails/art-gift-red.jpg'),
              RailCard('Coupons', 'Scratch and codes', 'Open', art: 'assets/rails/art-scratch.jpg'),
            ],
            c: const [
              RailCard('Friends', 'People on your link', 'Board', art: 'assets/rails/gen-30.jpg'),
              RailCard('Share cards', 'Cards you can send', 'Share', art: 'assets/rails/gen-31.jpg'),
              RailCard('Rules', 'One code. One parent.', 'Read', art: 'assets/rails/gen-32.jpg'),
            ],
            d: const [
              RailCard('Copy your code', 'Hold it, then send it', 'Copy', art: 'assets/rails/gen-33.jpg'),
              RailCard('Apply a code', 'It cannot be changed later', 'Apply', art: 'assets/rails/gen-34.jpg'),
            ],
            e: const [
              RailCard('Your links', 'The board for this code', 'Open', art: 'assets/rails/gen-35.jpg'),
              RailCard('NowssB Earn', 'Ranks behind the code', 'Open', art: 'assets/rails/gen-36.jpg'),
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
    showModalBottomSheet<void>(
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
