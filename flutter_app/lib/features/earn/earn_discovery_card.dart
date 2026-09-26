import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import 'earn_hub_screen.dart';

class EarnDiscoveryCard extends StatefulWidget {
  const EarnDiscoveryCard({super.key, this.neumorphic = false});

  final bool neumorphic;

  @override
  State<EarnDiscoveryCard> createState() => _EarnDiscoveryCardState();
}

class _EarnDiscoveryCardState extends State<EarnDiscoveryCard> {
  static bool shownThisSession = false;

  @override
  void initState() {
    super.initState();
    shownThisSession = true;
  }

  bool get _hide {
    final w = EconomyMirror.instance;
    if (w.hasSeenEarn) return true;
    if (w.wordsSold > 0) return true;
    if (w.paidReferrals >= 5 || w.circleTier != 'Member') return true;
    return false;
  }

  Future<void> _open() async {
    try {
      await EconomyApi.call('dismissEarnCard');
    } catch (_) {}
    EconomyMirror.instance.hasSeenEarn = true;
    EconomyMirror.instance.notifyListeners();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarnHubScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        if (_hide) return const SizedBox.shrink();
        final child = Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Material(
            color: widget.neumorphic ? NwsbColors.surface : const Color(0xCC05070D),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _open,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Want to Earn? Try NowssB Earn.',
                      style: TextStyle(
                        color: widget.neumorphic ? NwsbColors.ink : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Turn your practice into rewards — because health is wealth.',
                      style: TextStyle(
                        color: widget.neumorphic ? NwsbColors.inkSoft : NwsbColors.mist,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Explore NowssB Earn',
                      style: TextStyle(
                        color: widget.neumorphic ? NwsbColors.ink : NwsbColors.goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        return child;
      },
    );
  }
}
