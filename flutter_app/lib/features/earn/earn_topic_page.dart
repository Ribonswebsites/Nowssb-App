import 'package:flutter/material.dart';

import '../../widgets/brand_top_banner.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_theme.dart';
import '../gifts/gifts_screen.dart';
import '../vault/vault_screen.dart';
import 'earnings_screen.dart';
import '../../admin/template/editable.dart';

/// Same shell as NowssB Earn: scrolling black banner, glass, a black card.
class EarnTopicPage extends StatelessWidget {
  const EarnTopicPage({
    super.key,
    required this.title,
    required this.mark,
    required this.headline,
    required this.body,
    this.actionLabel,
    this.action,
  });

  final String title;
  final String mark;
  final String headline;
  final String body;
  final String? actionLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: title,
      mark: mark,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          BrandTopBanner(bare: true, title: title, mark: mark, onTap: () {}),
          const SizedBox(height: 14),
          GlassWrap(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditableLabel('earn_topic_page.EarnTopicPage', headline, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  EditableLabel('earn_topic_page.EarnTopicPage', body, style: const TextStyle(color: Color(0xCCFFFFFF), height: 1.4)),
                  if (actionLabel != null && action != null) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => action!),
                        ),
                        child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AgentTierPage extends StatelessWidget {
  const AgentTierPage({super.key, required this.name, required this.detail, required this.note});
  final String name;
  final String detail;
  final String note;

  @override
  Widget build(BuildContext context) {
    return EarnTopicPage(
      title: name,
      mark: NwsbMarks.piggy,
      headline: detail,
      body: note,
    );
  }
}

void openRewards(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VaultScreen()));
}

void openGifts(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GiftsScreen()));
}

void openEarnings(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarningsScreen()));
}

void openCoins(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const EarnTopicPage(
        title: 'NowssB coins earned',
        mark: NwsbMarks.rewards,
        headline: 'Coins you earned',
        body: 'Coins come from practice, daily login, and quests. They cover at most 30% of a Play purchase. They cannot be bought, gifted, or cashed out.',
        actionLabel: 'Open rewards',
        action: VaultScreen(),
      ),
    ),
  );
}
