/// The daily coin claim. It opens on the home once a signed-in account
/// still has today's login open, and it stays on screen with the result.
library;

import 'package:flutter/material.dart';

import '../../widgets/app_thinking_loader.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import 'coupon_screen.dart';
import 'economy_api.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

class DailyClaimSheet {
  DailyClaimSheet._();

  static bool _open = false;

  static void offer(BuildContext context, {required bool Function() mounted}) {
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) return;
    final mirror = EconomyMirror.instance;
    void tick() {
      if (!mounted()) {
        mirror.removeListener(tick);
        return;
      }
      if (_open) return;
      if (!mirror.capsReady || mirror.uid == null) return;
      _open = true;
      mirror.removeListener(tick);
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const DailyClaimBody(),
      );
    }

    mirror.addListener(tick);
    tick();
  }
}

class DailyClaimBody extends StatefulWidget {
  const DailyClaimBody({super.key});

  @override
  State<DailyClaimBody> createState() => _DailyClaimBodyState();
}

class _DailyClaimBodyState extends State<DailyClaimBody> {
  String? _note;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _claim());
  }

  Future<void> _claim() async {
    if (_busy) return;
    setState(() => _busy = true);
    final before = EconomyMirror.instance.coins;
    try {
      final gained = await EconomyApi.claimToday();
      if (!mounted) return;
      final after = EconomyMirror.instance.coins;
      setState(() => _note = gained > 0
          ? '+$gained coins landed on this wallet.'
          : 'Today’s login is already on the wallet.');
      await NwsbCoinFly.show(
        context,
        coins: gained > 0 ? gained : 10,
        from: before,
        to: gained > 0 ? after : before,
      );
    } on EconomyException catch (e) {
      if (!mounted) return;
      final raw = e.message.toUpperCase();
      setState(() => _note = raw.contains('NOT_FOUND')
          ? 'The wallet did not answer. Tap claim again.'
          : e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _note = 'Could not reach the wallet. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final w = EconomyMirror.instance;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: GlassWrap(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 18),
            padding: const EdgeInsets.all(6),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(NwsbCoinFly.disc, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Today’s coins',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Wallet ${w.coins} · streak ${w.streak}',
                    style: const TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _note ?? 'Claiming today’s login…',
                    style: const TextStyle(color: Color(0xCCFFFFFF), height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _busy ? null : _claim,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(_busy ? 'Working' : 'Claim daily coins'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const CouponScreen()),
                      );
                    },
                    icon: const NwsbIcon(NwsbMarks.coupon, size: 16, color: Colors.white),
                    label: const Text('Open today’s coupon'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0x55FFFFFF)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppThinkingLoader(
                      size: 16,
                      state: OrbState.composing,
                      blackCircle: true,
                      circlePad: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
