/// The daily coin claim. It opens on the home once a signed-in account
/// still has today's login open, and it stays on screen with the result.
library;

import 'package:flutter/material.dart';

import '../../widgets/app_thinking_loader.dart';
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
      if (!mirror.capsReady || mirror.uid == null || mirror.loginToday) return;
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
      final result = await EconomyApi.call('claimDailyLogin');
      final gained = (result['coins'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      setState(() => _note = gained > 0
          ? '+$gained coins landed on this wallet.'
          : 'Today’s login is already on the wallet.');
      if (gained > 0) {
        await NwsbCoinFly.show(
          context,
          coins: gained,
          from: before,
          to: before + gained,
        );
      }
    } on EconomyException catch (e) {
      if (!mounted) return;
      setState(() => _note = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _note = 'Could not reach the wallet. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = EconomyMirror.instance;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 18),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x33FFFFFF)),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 12)),
          ],
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
                  child: Image.asset('assets/icons/logo-disc.webp', fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                const AppThinkingLoader(
                  size: 18,
                  state: OrbState.composing,
                  circlePad: 5,
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
              icon: const NwsbIcon(NwsbMarks.earn, size: 16, color: Colors.white),
              label: const Text('Open today’s coupon'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0x55FFFFFF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
