import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/app_control.dart';
import '../../../widgets/referral_share_sheet.dart';
import '../../economy/economy_api.dart';
import '../earnings_screen.dart';
import 'earn_newui_page.dart';
import 'earn_view_data.dart';

/// Feature flag key (rules: `newui_<page>`, OFF for users, ON for admins).
const kEarnNewUiFlag = 'newui_earn';

/// Shows [newUi] when `newui_earn` is on or the account is an admin,
/// otherwise the live [legacy] page. [debugOverride] is for tests.
class EarnNewUiGate extends StatefulWidget {
  const EarnNewUiGate({super.key, required this.legacy, required this.newUi, this.debugOverride});
  final Widget legacy;
  final Widget newUi;
  final bool? debugOverride;

  @override
  State<EarnNewUiGate> createState() => _EarnNewUiGateState();
}

class _EarnNewUiGateState extends State<EarnNewUiGate> {
  bool _admin = false;

  @override
  void initState() {
    super.initState();
    if (widget.debugOverride == null) _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) return;
      final s = await FirebaseFirestore.instance.collection('admins').doc(u.uid).get();
      if (mounted && s.exists) setState(() => _admin = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.debugOverride;
    if (o != null) return o ? widget.newUi : widget.legacy;
    return ListenableBuilder(
      listenable: AppControl.instance,
      builder: (_, __) {
        final on = _admin || AppControl.instance.flag(kEarnNewUiFlag, fallback: false);
        return on ? widget.newUi : widget.legacy;
      },
    );
  }
}

/// Connects [EarnNewUiPage] to the live economy data.
class EarnNewUiScreen extends StatefulWidget {
  const EarnNewUiScreen({super.key});

  @override
  State<EarnNewUiScreen> createState() => _EarnNewUiScreenState();
}

class _EarnNewUiScreenState extends State<EarnNewUiScreen> {
  EarnLoad _load = EarnLoad.loading;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _load = EarnLoad.loading);
    final m = EconomyMirror.instance;
    if (m.uid == null) {
      setState(() => _load = EarnLoad.empty);
      return;
    }
    try {
      await EconomyApi.call('summary');
      if (!mounted) return;
      setState(() => _load = EarnLoad.ready);
    } on SocketException {
      if (mounted) setState(() => _load = EarnLoad.offline);
    } catch (e) {
      if (mounted) {
        setState(() {
          _load = EarnLoad.error;
          _error = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final m = EconomyMirror.instance;
        final st = m.summary['earn'];
        final rate = st is Map ? (st['ratePct'] as num?)?.round() ?? 0 : 0;
        var data = EarnViewData(
          load: _load,
          signedIn: m.uid != null,
          rank: m.sellerTier,
          ratePct: rate,
          wordsSold: m.wordsSold,
          teamSize: m.paidReferrals,
          cashCents: m.cash,
          code: m.code,
          errorMessage: _error,
        );
        if (_load == EarnLoad.ready && data.isFresh) {
          data = EarnViewData(load: EarnLoad.empty, signedIn: true, code: m.code);
        }
        return EarnNewUiPage(
          data: data,
          actions: EarnActions(
            onRetry: _fetch,
            onHelp: () => showEarnHowItWorks(context),
            onEarnings: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarningsScreen())),
            onShareCode: m.code.isEmpty ? null : () => showReferralShareSheet(context, code: m.code),
          ),
        );
      },
    );
  }
}
