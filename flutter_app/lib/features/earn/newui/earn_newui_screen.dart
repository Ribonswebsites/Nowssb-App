import 'package:flutter/material.dart';

import '../../../kit/app_routes.dart';
import '../../../kit/data_layer.dart';
import '../../../widgets/referral_share_sheet.dart';
import '../../economy/economy_api.dart';
import 'earn_downline_page.dart';
import 'earn_newui_page.dart';
import 'earn_view_data.dart';

/// Flag page key: `newui_earn` (see kit/feature_flags.dart).
const kEarnNewUiPage = 'earn';

/// Loads the hub from the shared [EarnRepository] and wires taps to [AppRoutes].
class EarnNewUiScreen extends StatefulWidget {
  const EarnNewUiScreen({super.key, this.load});

  /// Test seam; defaults to [EarnRepository.summary].
  final Future<KitResult<Json>> Function()? load;

  @override
  State<EarnNewUiScreen> createState() => _EarnNewUiScreenState();
}

class _EarnNewUiScreenState extends State<EarnNewUiScreen> {
  EarnViewData _data = const EarnViewData();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _data = const EarnViewData());
    final r = await (widget.load ?? EarnRepository.summary)();
    if (!mounted) return;
    setState(() {
      _data = switch (r) {
        KitOk(:final value) => EarnViewData.fromSummary(value, code: EconomyMirror.instance.code),
        KitErr() => EarnViewData.fromError(r),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return EarnNewUiPage(
      data: d,
      actions: EarnActions(
        onRetry: _fetch,
        onSignIn: _fetch,
        onHelp: () => showEarnHowItWorks(context),
        onEarnings: () => AppRoutes.open(context, AppPage.earnings, source: 'earn.newui'),
        onTeam: () => Navigator.of(context).push(MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/earn/downline'),
          builder: (_) => EarnDownlinePage(data: d),
        )),
        onTask: (_) => AppRoutes.open(context, AppPage.storeWords, source: 'earn.newui'),
        onShareCode: d.code.isEmpty ? null : () => showReferralShareSheet(context, code: d.code),
      ),
    );
  }
}
