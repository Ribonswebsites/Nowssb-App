/// Rebuilt Partner hub (spec Part C "Partner Program"), behind
/// `newui_partner`. Original app background video (AppBackdrop) behind
/// see-through kit glass (nowssb_ui). No added backgrounds.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../features/economy/money.dart';
import '../../features/programs/partner_program.dart';
import '../../nowssb_ui/nowssb_ui.dart';
import '../../widgets/app_backdrop.dart';
import '../../widgets/nwsb_coin_fly.dart';
import 'partner_models.dart';
import 'payout_provider.dart';

/// Card tokens from /workspace/specs/card-reference-exact.png.
const _cardRadius = 28.0;
const _cardTint = Color(0xFFE9E4FF); // lavender-white
const _muted = NTokens.textLo;
const _title = TextStyle(color: Colors.white, fontSize: 20, height: 1.15, fontWeight: FontWeight.w800);
const _body = TextStyle(color: _muted, fontSize: 12.5, height: 1.4);

class PartnerHomePage extends StatefulWidget {
  const PartnerHomePage({
    super.key,
    this.repository = const MirrorPartnerRepository(),
    this.countryCode,
    this.onOpenEarnings,
    this.background,
  });

  final PartnerRepository repository;

  /// Overrides the device region (tests, admin preview).
  final String? countryCode;
  final VoidCallback? onOpenEarnings;

  /// The app's original background. Defaults to [AppBackdrop] (the user's
  /// chosen background video); tests pass its poster frame.
  final Widget? background;

  @override
  State<PartnerHomePage> createState() => _PartnerHomePageState();
}

class _PartnerHomePageState extends State<PartnerHomePage> {
  late Future<PartnerData> _future = widget.repository.load();

  void _retry() => setState(() {
        _future = widget.repository.load();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        widget.background ?? const AppBackdrop(),
        SafeArea(
          bottom: false,
          child: Column(children: [
            _TopRow(onBack: Navigator.of(context).canPop() ? () => Navigator.of(context).maybePop() : null),
            Expanded(
              child: FutureBuilder<PartnerData>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return ListView(
                      key: const Key('partner-loading'),
                      padding: const EdgeInsets.all(16),
                      children: const [
                        GlassSkeleton(height: 320, radius: _cardRadius),
                        SizedBox(height: 12),
                        GlassSkeleton(height: 110, radius: _cardRadius),
                      ],
                    );
                  }
                  if (snap.hasError) {
                    final offline = snap.error is PartnerOfflineException;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: GlassStateCard(
                          key: Key(offline ? 'partner-offline' : 'partner-error'),
                          icon: offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                          title: offline ? 'You are offline' : 'Something went wrong',
                          message: offline
                              ? 'Your partner progress will appear when you reconnect.'
                              : 'We could not load your partner progress.',
                          action: 'Try again',
                          onAction: _retry,
                        ),
                      ),
                    );
                  }
                  return _Hub(data: snap.data!, countryCode: widget.countryCode, onOpenEarnings: widget.onOpenEarnings);
                },
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Status-bar-style top row with a heart, as in the reference.
class _TopRow extends StatelessWidget {
  const _TopRow({this.onBack});
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
        child: Row(children: [
          if (onBack != null)
            IconButton(
                onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18))
          else
            const SizedBox(width: 12),
          const Text('Partner', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
        ]),
      );
}

/// Frosted see-through card from the shared kit, tuned to the reference.
class _Card extends StatelessWidget {
  const _Card({super.key, required this.child, this.blur = 0, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final double blur;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => NGlass(
        radius: _cardRadius,
        blur: blur,
        accent: _cardTint,
        tint: _cardTint,
        elevation: .2,
        padding: padding,
        child: child,
      );
}

class _Hub extends StatelessWidget {
  const _Hub({required this.data, this.countryCode, this.onOpenEarnings});
  final PartnerData data;
  final String? countryCode;
  final VoidCallback? onOpenEarnings;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: data.referralLink));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final cc = countryCode ?? locale.countryCode ?? 'US';
    final payout = payoutInfoFor(cc);
    final localeTag = '${locale.languageCode}_$cc';
    final hasLink = data.referralLink.isNotEmpty;
    return ListView(
      key: const Key('partner-hub'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Tall hero card: round photo near the top, inner frosted panel below.
        _Card(
          blur: NTokens.blurLarge,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 6),
            CircleImage(image: NCircles.at(2), size: 150, ring: Colors.white24),
            const SizedBox(height: 18),
            _Card(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.tier, style: _body),
                const SizedBox(height: 6),
                Row(children: [
                  const NwsbCoinDisc(size: 30),
                  const SizedBox(width: 8),
                  Text('${data.points}',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  const Text('partner points', style: _body),
                ]),
                const SizedBox(height: 6),
                Text(
                  data.isEmpty
                      ? 'Pick a target, share your link, and points appear here when friends complete paid purchases.'
                      : data.toNextTier > 0
                          ? '${data.toNextTier} more subscriptions to the next level.'
                          : 'Keep sharing to reach the next level.',
                  key: data.isEmpty ? const Key('partner-empty') : null,
                  style: _body,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  const Text('Rules', style: _body),
                  const Spacer(),
                  GlassPill(
                    label: 'Share link',
                    style: PillStyle.solid,
                    dense: true,
                    onTap: hasLink ? () => _copy(context) : null,
                  ),
                ]),
              ]),
            ),
          ]),
        ),
        const _Head('Pick a target'),
        for (final t in data.targets) Padding(padding: const EdgeInsets.only(bottom: 10), child: _TargetCard(t)),
        const _Head('Perks'),
        const _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Coins, gifts, coupons, early access', style: _title),
            SizedBox(height: 6),
            Text('Perks have no cash value.', style: _body),
          ]),
        ),
        const _Head('Share your link'),
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(hasLink ? data.referralLink : 'Your link is being prepared',
                style: _title.copyWith(fontSize: 16), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            if (data.buyerDiscountUsdCents > 0)
              Text(
                'Buyers through your link get ${localMoney(data.buyerDiscountUsdCents, cc, localeTag)} off',
                key: const Key('partner-discount'),
                style: _body,
              ),
            const SizedBox(height: 12),
            Row(children: [
              const Spacer(),
              GlassPill(
                key: const Key('partner-copy'),
                label: 'Copy',
                style: PillStyle.white,
                dense: true,
                onTap: hasLink ? () => _copy(context) : null,
              ),
            ]),
          ]),
        ),
        const _Head('Leaderboard'),
        if (data.leaders.isEmpty)
          const _Card(child: Text('The leaderboard opens once partners start earning points.', style: _body))
        else
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.leaders.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(
                width: 120,
                child: _Card(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('#${i + 1} ${data.leaders[i].name}', style: _title.copyWith(fontSize: 15)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const NwsbCoinDisc(size: 16),
                      const SizedBox(width: 4),
                      Text('${data.leaders[i].points}', style: _body),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        const _Head('Cash earnings'),
        _Card(
          key: const Key('partner-payout'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Perks are not cash', style: _title),
            const SizedBox(height: 6),
            Text(
              'Cash commissions from Earn are paid in your local currency through ${payout.provider.label}, '
              'which runs the identity and tax checks for your country (${payout.countryCode}).',
              style: _body,
            ),
            const SizedBox(height: 6),
            for (final c in payout.checks) Text('• $c', style: _body.copyWith(fontSize: 11.5)),
            const SizedBox(height: 12),
            Row(children: [
              const Spacer(),
              GlassPill(label: 'Open Earnings', style: PillStyle.white, dense: true, onTap: onOpenEarnings),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        Text(kPartnerDisclaimer, style: _body.copyWith(fontSize: 11, color: Colors.white60)),
      ],
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard(this.t);
  final PartnerTarget t;
  @override
  Widget build(BuildContext context) => _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${t.goal} ${t.label.toLowerCase()}', style: _title.copyWith(fontSize: 17)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
                value: t.progress, minHeight: 6, color: Colors.white, backgroundColor: Colors.white24),
          ),
          const SizedBox(height: 8),
          Text('${t.done} / ${t.goal} · ${t.reward}', style: _body),
        ]),
      );
}

class _Head extends StatelessWidget {
  const _Head(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      );
}

const _eur = {
  'AT',
  'BE',
  'HR',
  'CY',
  'EE',
  'FI',
  'FR',
  'DE',
  'GR',
  'IE',
  'IT',
  'LV',
  'LT',
  'LU',
  'MT',
  'NL',
  'PT',
  'SK',
  'SI',
  'ES',
};
const _byCountry = {
  'US': 'USD',
  'GB': 'GBP',
  'JP': 'JPY',
  'CA': 'CAD',
  'AU': 'AUD',
  'SG': 'SGD',
  'AE': 'AED',
  'IN': 'INR',
};

/// Formats USD cents in the viewer's local currency (by region), using the
/// app's FX rates. Falls back to USD when the region or rate is unknown.
String localMoney(int usdCents, String countryCode, String localeTag) {
  final cc = countryCode.toUpperCase();
  var code = _eur.contains(cc) ? 'EUR' : (_byCountry[cc] ?? 'USD');
  final rate = FxBook.instance.rates[code];
  if (rate == null) code = 'USD';
  final loc = NumberFormat.localeExists(localeTag) ? localeTag : 'en';
  return NumberFormat.simpleCurrency(name: code, locale: loc, decimalDigits: code == 'JPY' ? 0 : 2)
      .format(usdCents / 100 * (rate ?? 1));
}
