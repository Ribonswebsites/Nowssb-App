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
import '../../widgets/routine_deck.dart';

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
          RoutineDeck(
            title: 'Reference',
            banner: 'Your link',
            bannerSub: 'One code. A friend’s first valid link counts.',
            onBanner: () => Programmes.open(context, Programme.earn),
            cards: [
              WorkCard(category: 'Earn', title: 'NowssB Earn', meta: 'Cash on real sales', action: 'Open earn', image: 'assets/rails/gen-66.jpg', onTap: () => Programmes.open(context, Programme.earn)),
              WorkCard(category: 'Rewards', title: 'Rewards', meta: 'Coins you spend', action: 'Open rewards', image: 'assets/rails/gen-67.jpg', onTap: () => Programmes.open(context, Programme.rewards)),
              WorkCard(category: 'Gifts', title: 'Gifts', meta: 'Send a plan', action: 'Open gifts', image: 'assets/rails/gen-68.jpg', onTap: () => Programmes.open(context, Programme.gifts)),
              WorkCard(category: 'Coupons', title: 'Coupons', meta: 'Scratch and codes', action: 'Open coupons', image: 'assets/rails/gen-69.jpg', onTap: () => Programmes.open(context, Programme.coupons)),
            ],
          ),
          const SizedBox(height: 12),
          const GlassLine(
            text: 'Your code attributes a sale. Their parent takes a small second level. Both must hold a plan.',
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                w.code.isEmpty ? 'Your code shows on this account' : w.code,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${w.circleTier} · ${w.unitsSold} sales · parent ${w.referredBy.isEmpty ? 'none' : w.referredBy}',
                style: const TextStyle(color: Color(0xB3FFFFFF)),
              ),
              const SizedBox(height: 12),
              GoldButton(
                label: 'Copy reference code',
                filled: false,
                onTap: w.code.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: w.code));
                        if (context.mounted) setState(() => _note = 'Code copied.');
                      },
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _code,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Someone else’s code',
                  hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                ),
              ),
              const SizedBox(height: 8),
              GoldButton(
                label: 'Apply code',
                onTap: () async {
                  try {
                    await EconomyApi.call('applyReferralCode', {'code': _code.text.trim()});
                    if (mounted) setState(() => _note = 'Code saved. It cannot be changed.');
                  } on EconomyException catch (e) {
                    if (!EconomyApi.isMissing(e)) {
                      if (mounted) setState(() => _note = e.message);
                      return;
                    }
                    if (mounted) setState(() => _note = EconomyApi.switchingOnMessage);
                  }
                },
              ),
              if (_note != null) ...[
                const SizedBox(height: 10),
                Text(_note!, style: const TextStyle(color: Colors.white)),
              ],
            ],
          );
        },
          ),
          const SizedBox(height: 18),
          const FourBanners(
            current: Programme.reference,
            splitTitle: 'Share a word you love',
            splitCta: 'Share a link',
            blackTitle: 'Your links',
            blackSub: 'One link per word, plan and meaning.',
          ),
          const SizedBox(height: 18),
          ProgramTabsBlock(spec: kReferenceSpec, initialTab: widget.initialTab, scrollTo: widget.initialTab != null, showDisclaimer: false),
        ],
      ),
    );
  }
}
