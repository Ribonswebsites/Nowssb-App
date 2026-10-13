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
import 'partner_models.dart';
import 'payout_provider.dart';

/// Card tokens from /workspace/specs/card-reference-exact.png.
const _muted = NTokens.textLo;
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
                        GlassSkeleton(height: 320, radius: NTokens.rHero),
                        SizedBox(height: 12),
                        GlassSkeleton(height: 110, radius: NTokens.rHero),
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

class _Hub extends StatefulWidget {
  const _Hub({required this.data, this.countryCode, this.onOpenEarnings});
  final PartnerData data;
  final String? countryCode;
  final VoidCallback? onOpenEarnings;
  @override
  State<_Hub> createState() => _HubState();
}

/// Approved design: a carousel of the kit's MeditationCard (approved-1) and
/// frosted coupon-ticket cards with rarity pills (approved-2).
class _HubState extends State<_Hub> {
  final _pages = PageController(viewportFraction: .86);
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (!_pages.hasClients) return;
    _pages.animateToPage((_page + 1) % 3, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  void _copy() {
    final link = widget.data.referralLink;
    if (link.isEmpty) return;
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final locale = Localizations.localeOf(context);
    final cc = widget.countryCode ?? locale.countryCode ?? 'US';
    final payout = payoutInfoFor(cc);
    final localeTag = '${locale.languageCode}_$cc';
    final hasLink = data.referralLink.isNotEmpty;
    final discount = data.buyerDiscountUsdCents > 0
        ? ' Buyers through your link get ${localMoney(data.buyerDiscountUsdCents, cc, localeTag)} off.'
        : '';
    final cards = <Widget>[
      MeditationCard(
        key: const Key('partner-hero'),
        image: NCircles.of('stones'),
        title: '${data.points} partner points',
        subtitle: data.isEmpty
            ? 'Pick a target, share your link, and points appear here when friends complete paid purchases.'
            : '${data.tier}. ${data.toNextTier > 0 ? '${data.toNextTier} more subscriptions to the next level.' : 'Keep sharing to level up.'}',
        secondary: 'Skip',
        cta: 'Next',
        onCta: _next,
        dots: 3,
        dotIndex: _page,
      ),
      MeditationCard(
        key: const Key('partner-share'),
        image: NCircles.of('lake'),
        title: 'Share your link',
        subtitle: '${hasLink ? data.referralLink : 'Your link is being prepared.'}$discount',
        secondary: 'Skip',
        cta: 'Copy',
        onCta: hasLink ? _copy : null,
        dots: 3,
        dotIndex: _page,
      ),
      MeditationCard(
        key: const Key('partner-payout'),
        image: NCircles.of('waterfall'),
        title: 'Perks are not cash',
        subtitle: 'Cash commissions from Earn are paid in your local currency through ${payout.provider.label}, '
            'which runs the identity and tax checks for your country (${payout.countryCode}). '
            '$kVerifyNote.',
        secondary: 'Skip',
        cta: 'Earnings',
        onCta: widget.onOpenEarnings,
        dots: 3,
        dotIndex: _page,
      ),
    ];
    const rarities = [Rarity.rare, Rarity.epic, Rarity.legendary];
    return ListView(
      key: const Key('partner-hub'),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
      children: [
        SizedBox(
          height: 425,
          child: PageView.builder(
            controller: _pages,
            itemCount: cards.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Align(alignment: Alignment.topCenter, child: cards[i]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _Head('PARTNER TARGETS'),
            for (var i = 0; i < data.targets.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CouponListCard(
                  image: NCircles.at(i + 4),
                  rarity: rarities[i % rarities.length],
                  isNew: i == 0 && !data.isEmpty,
                  label: '${data.targets[i].label} · ${data.targets[i].reward}',
                  offer: '${data.targets[i].done} / ${data.targets[i].goal}',
                ),
              ),
            const _Head('LEADERBOARD'),
            if (data.leaders.isEmpty)
              const CouponListCard(
                rarity: Rarity.common,
                label: 'Leaderboard',
                offer: 'Opens once partners earn points',
              )
            else
              for (var i = 0; i < data.leaders.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CouponListCard(
                    image: NCircles.at(i + 8),
                    rarity: i == 0 ? Rarity.legendary : Rarity.rare,
                    label: '#${i + 1} ${data.leaders[i].name}',
                    offer: '${data.leaders[i].points} points',
                  ),
                ),
            const SizedBox(height: 14),
            Text(kPartnerDisclaimer, style: _body.copyWith(fontSize: 11, color: Colors.white60)),
          ]),
        ),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Text(text,
            style: const TextStyle(color: NTokens.mint, fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
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
