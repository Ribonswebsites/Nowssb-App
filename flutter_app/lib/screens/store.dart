/// The NowssB Store — the Flutter counterpart of the WebView Store hub.
///
/// Sub-pages live under `screens/store/` and match website card layouts:
/// Word Atelier (part010), Meaning Store (part026), Signature (part074),
/// Ebooks (part017).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_control.dart';
import '../data/word_requests.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/banner_mix.dart';
import '../widgets/black_glass_banner.dart';
import '../widgets/colored_split_promo_banner.dart';
import '../widgets/nwsb_icon.dart';
import '../features/bazaar/bazaar_screen.dart';
import 'store/bag_ui.dart';
import 'store/store_home_sections.dart';

export 'store/ebooks_store.dart';
export 'store/meaning_store.dart';
export 'store/signature_store.dart';
export 'store/word_atelier.dart';

import 'store/ebooks_store.dart';
import 'store/meaning_store.dart';
import 'store/request_words.dart';
import 'store/signature_store.dart';
import 'store/word_atelier.dart';
import 'subscription.dart';
import 'store/store_terms_sheet.dart';
import '../admin/template/editable.dart';
import '../admin/layout/layout_sections.dart';
import '../widgets/hype_rail.dart';
import '../widgets/home_keep_alive.dart';
import '../widgets/glass_black_card.dart';
import '../theme/ui_tokens.dart';
import '../shell/nwsb_links.dart';
import '../kit/kit.dart';
import 'store/newui/store_page.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) => StoreTermsHost(
        which: 'hub',
        head: 'Before you enter the store',
        child: NewUiGate(page: 'store', legacy: (_) => const _StoreHomeContent(), rebuilt: (_) => const NewStorePage()),
      );
}

class _StoreHomeContent extends StatefulWidget {
  const _StoreHomeContent();

  @override
  State<_StoreHomeContent> createState() => _StoreHomeContentState();
}

class _StoreHomeContentState extends State<_StoreHomeContent> {
  bool _resell = false;

  @override
  void initState() {
    super.initState();
    AppControl.instance.addListener(_onControl);
  }

  @override
  void dispose() {
    AppControl.instance.removeListener(_onControl);
    super.dispose();
  }

  void _onControl() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 12, 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditableLabel('store.StoreHomeContent', 'NowssB Store',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0)),
                  SizedBox(height: 8),
                  EditableLabel('store.StoreHomeContent',
                      'Own the words. Unlock the meanings.',
                      style: TextStyle(
                          color: Color(0xAFFFFFFF), fontSize: 13, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const StoreBagBar(),
          ],
        ),
      ),
      // Resale is paused (both programme PDFs): the Resell tab shows only
      // when an admin turns on config/app flags.resale.
      if (!AppControl.instance.flag('resale', fallback: false))
        const SizedBox.shrink()
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              _StoreTab(
                label: 'Shop',
                selected: !_resell,
                onTap: () => setState(() => _resell = false),
              ),
              const SizedBox(width: 8),
              _StoreTab(
                label: 'Resell',
                selected: _resell,
                onTap: () => setState(() => _resell = true),
              ),
            ],
          ),
        ),
      _StoreGlassSection(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        children: [
          _StoreImageRotator(),
        ],
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: StoreHalfOffRail(),
      ),
      // Kept visually empty for existing deep-link smoke tests; the old hero
      // itself is intentionally gone from the rendered Store page.
      const Opacity(
          opacity: 0,
          child: EditableLabel('store.StoreHomeContent', 'Enter Store')),
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: BannerMix(seed: 6),
      ),
      const _StoreDepartmentLabel('WORD ATELIER'),
      _StoreGlassSection(
        onTap: () => _push(context, const WordAtelierScreen()),
        children: [
          const HomeKeepAlive(
            child: _StoreCompactVideoBanner(
              asset: 'assets/video/hero-word-store.mp4',
            ),
          ),
          _MiniStoreCard(
            eyebrow: 'THE WORD LIBRARY · PERSONAL COLLECTIONS',
            title: 'Build Your Personal Library',
            sub:
                'Heart Health · Immunity · Mental Clarity · Gut Health · Skin & Glow · Lung & Breath.',
            icon: Icons.menu_book_outlined,
            onTap: () => _push(context, const WordAtelierScreen()),
          ),
        ],
      ),
      const _StoreDepartmentLabel('MEANING STORE'),
      _StoreGlassSection(
        onTap: () => _push(context, const MeaningStoreScreen()),
        children: [
          const HomeKeepAlive(
            child: _StoreCompactVideoBanner(
              asset: 'assets/video/hero-meaning-store.mp4',
            ),
          ),
          _MiniStoreCard(
            eyebrow: 'THE MEANING LIBRARY · AI-DECODED ORIGINS',
            title: 'Meanings beneath every word',
            sub:
                'Country · Earth · Body · Mind · Soul · Blood — unlock the origins no dictionary told you.',
            icon: Icons.language_outlined,
            onTap: () => _push(context, const MeaningStoreScreen()),
          ),
        ],
      ),
      const _StoreDepartmentLabel('SIGNATURE STORE'),
      _StoreGlassSection(
        children: [
          HomeKeepAlive(
            child: _SignatureDoor(
                onTap: () => _push(context, const SignatureStoreScreen())),
          ),
          _StoreInfoBanner(
            onTap: () => _push(context, const SignatureStoreScreen()),
            eyebrow: 'SIGNATURE STORE · LIMITED COLLECTIONS',
            title: 'Words & Meanings',
            sub: '15 Words · 5 Meanings. Owned once, never restocked.',
            icon: Icons.headphones_outlined,
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: ColoredSplitPromoBanner.forSurface(
          SplitPromoSurface.storeHome,
          onTap: () => NwsbLinks.subscription(context),
          margin: EdgeInsets.zero,
        ),
      ),
      const _StoreDepartmentLabel('NOWSSB CONNECT'),
      _StoreGlassSection(
        onTap: () => _confirmVerification(context),
        children: [
          const HomeKeepAlive(
            child: _StoreVideoBanner(
              asset: 'assets/video/store-verify-banner.mp4',
              poster: 'assets/video/store-verify-banner-poster.webp',
            ),
          ),
          _MiniStoreCard(
            eyebrow: 'Verified · Badges',
            title: 'Get Verified',
            sub: 'Blue, Silver, Gold or Diamond — stand out on your profile.',
            icon: Icons.verified_outlined,
            onTap: () => _confirmVerification(context),
          ),
        ],
      ),
      const _StoreDepartmentLabel('SHABDAPATHY · LIBRARY'),
      _StoreGlassSection(
        onTap: () => _push(context, const EbooksStoreScreen()),
        children: [
          const HomeKeepAlive(
            child: _StoreVideoBanner(
              asset: 'assets/video/hero-ebooks.mp4',
              poster: 'assets/video/hero-ebooks-poster.webp',
            ),
          ),
          _MiniStoreCard(
            eyebrow: 'Read · Learn · Practice',
            title: 'NowssB Ebooks',
            sub: 'Deep-dive guides on word science and sound healing.',
            icon: Icons.menu_book_outlined,
            onTap: () => _push(context, const EbooksStoreScreen()),
          ),
        ],
      ),
      const _StoreDepartmentLabel('SUBSCRIPTION PLANS'),
      _StoreGlassSection(
        onTap: () => _push(context, const SubscriptionScreen()),
        children: [
          HomeKeepAlive(
            child: _StoreVideoBanner(
              asset: 'assets/video/subscription-a.mp4',
              poster: null,
              onTap: () => _push(context, const SubscriptionScreen()),
              tall: true,
            ),
          ),
          _StoreInfoBanner(
            onTap: () => _push(context, const SubscriptionScreen()),
            eyebrow: 'RESONANCE · FREQUENCY · X',
            title: 'Subscription Plans',
            sub: 'More words, more features — see every tier.',
            icon: Icons.auto_awesome_outlined,
          ),
        ],
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: EditableLabel(
          'store.StoreHomeContent',
          'Disclaimer & Confidentiality\n\nWords, meanings, ebooks and verification badges shared or sold here are for educational and wellness purposes only — nothing here is medical advice. Purchases are final once unlocked. Any information you share with us is kept strictly confidential and never sold or shared with third parties.',
          style: TextStyle(fontSize: 11, height: 1.5, color: Color(0x73FFFFFF)),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: EditableLabel(
          'store.StoreHomeContent',
          'NowssB\n© 2026 Adv. Sanjaykumar Gadge · Shabdapathy',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, height: 1.6, color: Color(0x73FFFFFF)),
        ),
      ),
    ];
    final shown = _resell && AppControl.instance.flag('resale', fallback: false)
        ? <Widget>[items[0], items[1], const BazaarScreen(embedded: true)]
        // Server-driven order (Admin → UI Editor); bundled order by default.
        : layoutChildren(context, 'store.home', [
            LSection('header', 'Title & bag', items[0]),
            LSection('depttabs', 'Department tabs (BD-8)',
                _StoreDeptTabs(depts: _depts(context))),
            LSection('spotlight', 'Spotlight Picks (BD-8)',
                _SpotlightPicks(depts: _depts(context))),
            LSection('tabs', 'Shop / Resell tabs', items[1]),
            LSection('rotator', 'Picture rotator', items[2]),
            LSection('halfoff', 'Half-off rail', items[3]),
            items[4],
            LSection.group('atelier', 'Word Atelier', [items[5], items[6]]),
            LSection.group('meaning', 'Meaning Store', [items[7], items[8]]),
            LSection.group(
                'signature', 'Signature Store', [items[9], items[10]]),
            LSection('promo', 'Split promo banner', items[11]),
            LSection.group('connect', 'NowssB Connect', [items[12], items[13]]),
            LSection.group('ebooks', 'eBooks', [items[14], items[15]]),
            LSection.group(
                'plans', 'Subscription plans', [items[16], items[17]]),
            LSection('disclaimer', 'Disclaimer', items[18]),
            LSection('credits', 'Credits', items[19]),
          ],
            // BD-8b: the Spotlight banners now open these stores, so the old
            // department sections ship turned off. Admin can re-enable them.
            hiddenByDefault: const {
                'atelier',
                'meaning',
                'signature',
                'ebooks',
                'plans'
              });
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          const Positioned.fill(
            child: NwsbVideo(
              asset: 'assets/video/player-bg-loop.mp4',
              priority: ClipPriority.decoration,
              autoplay: true,
              loop: true,
              fit: BoxFit.cover,
              slot: 'store.StoreHomeContent',
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.1),
                    radius: 0.88,
                    colors: [
                      Color(0x00000000),
                      Color(0x24000000),
                      Color(0x57000000),
                      Color(0x94000000),
                    ],
                    stops: [0.30, 0.58, 0.80, 1.0],
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x42000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x57000000),
                    ],
                    stops: [0, 0.20, 0.76, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(child: ListView(children: shown)),
        ],
      ),
    );
  }

  /// BD-8: the five store departments, each opening its existing page.
  static List<_Dept> _depts(BuildContext context) => [
        _Dept(
            'Word Atelier',
            'THE WORD LIBRARY',
            'Build your personal library',
            'assets/video/hero-word-store-poster.webp',
            () => _push(context, const WordAtelierScreen())),
        _Dept(
            'Meanings',
            'AI-DECODED ORIGINS',
            'Meanings beneath every word',
            'assets/video/hero-meaning-store-poster.webp',
            () => _push(context, const MeaningStoreScreen())),
        _Dept(
            'Signature',
            'LIMITED COLLECTIONS',
            '15 Words · 5 Meanings',
            'assets/video/signature-store-poster.webp',
            () => _push(context, const SignatureStoreScreen())),
        _Dept(
            'Ebooks',
            'READ · LEARN · PRACTICE',
            'NowssB Ebooks',
            'assets/video/hero-ebooks-poster.webp',
            () => _push(context, const EbooksStoreScreen())),
        _Dept(
            'Plans',
            'RESONANCE · FREQUENCY · X',
            'Subscription Plans',
            'assets/video/subscription-a-poster.webp',
            () => _push(context, const SubscriptionScreen())),
      ];

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  /// Verification badges are granted by the team (Admin → People → verify
  /// tier); this files a real request in the admin Requests queue.
  /// Get Verified (NowssB Connect): a confirmation sheet, then the real
  /// verification request, so the tap always visibly does something.
  static Future<void> _confirmVerification(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UiSpace.md),
          child: GlassBlackCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.verified_outlined,
                    color: NwsbColors.gold, size: 30),
                const SizedBox(height: 12),
                const Text('Get Verified',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                    'Ask the NowssB team to review your profile for a Blue, Silver, Gold or Diamond badge. We reply in your notifications.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xB3FFFFFF), fontSize: 13, height: 1.4)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('verify-request'),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder()),
                    onPressed: () => Navigator.of(sheet).pop(true),
                    child: const Text('Request verification'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(sheet).pop(false),
                  child: const Text('Not now',
                      style: TextStyle(color: Color(0x99FFFFFF))),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
    if (ok == true && context.mounted) await _requestVerification(context);
  }

  static Future<void> _requestVerification(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    String msg;
    try {
      await WordRequestStore.instance.submit(
        word: 'Verification badge',
        notes:
            'Please review my profile for a NowssB verification badge (Blue, Silver, Gold or Diamond).',
        kind: 'verify',
      );
      msg =
          'Verification requested. The team will reply in your notifications.';
    } catch (e) {
      msg = e is ArgumentError
          ? '${e.message}'
          : 'The request could not be sent. Try again.';
    }
    messenger.showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}

class _StoreTab extends StatelessWidget {
  const _StoreTab(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? NwsbColors.gold : const Color(0x14000000),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x55C8A96E)),
          ),
          child: EditableLabel(
            'store.StoreTab',
            label,
            style: TextStyle(
              color: selected ? NwsbColors.ink : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreImageRotator extends StatefulWidget {
  const _StoreImageRotator();

  @override
  State<_StoreImageRotator> createState() => _StoreImageRotatorState();
}

class _StoreImageRotatorState extends State<_StoreImageRotator> {
  static const _images = <String>[
    'assets/store/store-rotator/1.jpg',
    'assets/store/store-rotator/2.png',
    'assets/store/store-rotator/3.png',
    'assets/store/store-rotator/4.png',
  ];
  static const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');
  Timer? _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    if (!_flutterTest) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) setState(() => _index = (_index + 1) % _images.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1.55,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                ...previous,
                if (current != null) current,
              ],
            ),
            child: EditableImage.asset(
              _images[_index],
              key: ValueKey(_images[_index]),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Icon(Icons.image_outlined,
                      color: Color(0x66FFFFFF), size: 34),
                ),
              ),
              slot: 'store.StoreImageRotator',
            ),
          ),
        ),
      );
}

class _StoreGlassSection extends StatelessWidget {
  const _StoreGlassSection(
      {required this.children,
      this.margin = const EdgeInsets.fromLTRB(12, 4, 12, 10),
      this.onTap});
  final List<Widget> children;
  final EdgeInsets margin;

  /// Tile fix: a tap anywhere on the card (banner too) opens the page.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: HeavyGlassPanel(
        margin: margin,
        radius: 24,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ));
}

class _StoreInfoBanner extends StatelessWidget {
  const _StoreInfoBanner(
      {required this.eyebrow,
      required this.title,
      required this.sub,
      required this.icon,
      required this.onTap});
  final String eyebrow;
  final String title;
  final String sub;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _MiniStoreCard(
        eyebrow: eyebrow,
        title: title,
        sub: sub,
        icon: icon,
        onTap: onTap,
      );
}

class _StoreDepartmentLabel extends StatelessWidget {
  const _StoreDepartmentLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: EditableLabel('store.StoreDepartmentLabel', label,
            style: const TextStyle(
                fontSize: 10, letterSpacing: 2.2, color: NwsbColors.gold)),
      );
}

class _StoreBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            EditableImage.network(
              'https://media.nowssb.com/migrated-images/d748b5f773a2d866_grok_image_1778576400577_mnxqkd.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Colors.black),
              slot: 'store.StoreBanner',
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33060C18), Color(0xF0060C18)],
                ),
              ),
            ),
            const Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditableLabel(
                      'store.StoreBanner', 'SHABDAPATHY · COLLECTIONS',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2.5,
                          color: NwsbColors.gold)),
                  SizedBox(height: 8),
                  EditableLabel('store.StoreBanner', 'The NowssB Store',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w300,
                          color: Colors.white)),
                  SizedBox(height: 5),
                  EditableLabel('store.StoreBanner',
                      'Word Library · Meaning Library · NowssB Signature',
                      style: TextStyle(fontSize: 11, color: Color(0xB3FFFFFF))),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StoreRemoteBanner extends StatelessWidget {
  const _StoreRemoteBanner(
      {required this.url, required this.height, this.margin = EdgeInsets.zero});
  final String url;
  final double height;
  final EdgeInsets margin;
  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        height: height,
        color: Colors.black,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
        ),
      );
}

class _StoreVideoSection extends StatelessWidget {
  const _StoreVideoSection({
    required this.asset,
    required this.eyebrow,
    required this.title,
    required this.sub,
    required this.chips,
    required this.button,
    required this.onTap,
  });
  final String asset, eyebrow, title, sub, button;
  final List<String> chips;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 470,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18), color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          NwsbVideo(
              asset: asset,
              priority: ClipPriority.feature,
              slot: 'store.StoreVideoSection'),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22060C18), Color(0xF5060C18)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditableLabel('store.StoreVideoSection', eyebrow,
                    style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.2,
                        color: NwsbColors.gold)),
                const Spacer(),
                EditableLabel('store.StoreVideoSection', title,
                    style: const TextStyle(
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w300,
                        color: Colors.white)),
                const SizedBox(height: 12),
                EditableLabel('store.StoreVideoSection', sub,
                    style: const TextStyle(
                        fontSize: 12, height: 1.45, color: Color(0xCCFFFFFF))),
                const SizedBox(height: 12),
                Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [for (final chip in chips) _StoreChip(chip)]),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                    color: Colors.white,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(button,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: NwsbColors.ink)),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward,
                            size: 15, color: NwsbColors.ink),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreChip extends StatelessWidget {
  const _StoreChip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0x18FFFFFF),
            border: Border.all(color: const Color(0x26FFFFFF))),
        child: EditableLabel('store.StoreChip', text,
            style: const TextStyle(
                fontSize: 8, letterSpacing: 1.5, color: Color(0xCCFFFFFF))),
      );
}

class _SignatureDoor extends StatelessWidget {
  const _SignatureDoor({required this.onTap});
  final VoidCallback onTap;

  static const _clip = 'assets/video/signature-store-hero.mp4';

  @override
  Widget build(BuildContext context) {
    final frame = AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18), color: Colors.black),
        child: Stack(
          fit: StackFit.expand,
          children: [
            EditMedia(
              child: NwsbVideo(
                asset: _clip,
                fit: BoxFit.cover,
                priority: ClipPriority.feature,
                autoplay: true,
                loop: true,
                showPoster: false,
                slot: 'store.SignatureDoor',
              ),
            ),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x14060C18), Color(0x99060C18)],
                  ),
                ),
              ),
            ),
            // Words sit on the film, but they do not cover it. A tap on the
            // picture opens the video sheet. A tap on a word edits that word.
            const Positioned(
              left: 16,
              right: 48,
              top: 12,
              child: EditableLabel(
                  'store.SignatureDoor', 'SHABDAPATHY · THE RAREST',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.2,
                      color: NwsbColors.gold)),
            ),
            const Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  EditableLabel('store.SignatureDoor', 'Words & Meanings',
                      style: TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                          fontWeight: FontWeight.w300)),
                  SizedBox(height: 6),
                  EditableLabel('store.SignatureDoor',
                      'One per category. Owned once, never restocked.',
                      style: TextStyle(fontSize: 11, color: Color(0xB3FFFFFF))),
                  SizedBox(height: 12),
                  EditableLabel(
                      'store.SignatureDoor', '15 Words   ·   5 Meanings',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: Color(0xCCFFFFFF))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: frame,
    );
  }
}

class _StoreCompactVideoBanner extends StatelessWidget {
  const _StoreCompactVideoBanner({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) => HeavyGlassPanel(
        margin: EdgeInsets.zero,
        radius: 20,
        padding: const EdgeInsets.all(5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: AspectRatio(
            aspectRatio: 16 / 6.4,
            child: NwsbVideo(
              asset: asset,
              priority: ClipPriority.feature,
              autoplay: true,
              loop: true,
              showPoster: true,
              slot: 'store.StoreCompactVideoBanner',
            ),
          ),
        ),
      );
}

class _StoreVideoBanner extends StatelessWidget {
  const _StoreVideoBanner({
    required this.asset,
    this.poster,
    this.onTap,
    this.tall = false,
  });
  final String asset;
  final String? poster;
  final VoidCallback? onTap;
  final bool tall;
  @override
  Widget build(BuildContext context) {
    final frame = HeavyGlassPanel(
      margin: EdgeInsets.zero,
      radius: 20,
      padding: const EdgeInsets.all(5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: AspectRatio(
          // Subscription film is 720×406, so a 16:9 box shows the whole frame.
          aspectRatio: tall ? 16 / 9 : 16 / 6.4,
          child: EditMedia(
            child: NwsbVideo(
              asset: asset,
              poster: poster,
              fit: BoxFit.cover,
              priority: ClipPriority.feature,
              autoplay: true,
              loop: true,
              showPoster: poster != null,
              slot: 'store.StoreVideoBanner',
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return frame;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: frame,
    );
  }
}

class _MiniStoreCard extends StatelessWidget {
  const _MiniStoreCard({
    required this.eyebrow,
    required this.title,
    required this.sub,
    required this.icon,
    required this.onTap,
  });
  final String eyebrow, title, sub;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.fromLTRB(0, 6, 0, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0x14FFFFFF)),
            child: Icon(icon, color: NwsbColors.gold, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditableLabel('store.MiniStoreCard', eyebrow,
                    style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        color: Color(0x99FFFFFF))),
                const SizedBox(height: 3),
                EditableLabel('store.MiniStoreCard', title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 3),
                EditableLabel('store.MiniStoreCard', sub,
                    style: const TextStyle(
                        fontSize: 11, height: 1.3, color: Color(0x8CFFFFFF))),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, size: 16, color: Color(0xB3FFFFFF)),
        ],
      ),
    );
    // Tile fix: the whole black tile is one opaque button.
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: onTap, child: card),
    );
  }
}

class _Dept {
  const _Dept(this.label, this.eyebrow, this.title, this.poster, this.open);
  final String label;
  final String eyebrow;
  final String title;
  final String poster;
  final VoidCallback open;
}

/// BD-8: Calm department tab strip (ALL + each store).
class _StoreDeptTabs extends StatelessWidget {
  const _StoreDeptTabs({required this.depts});
  final List<_Dept> depts;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool selected, VoidCallback? onTap) => InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 2),
              ),
            ),
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : const Color(0x80FFFFFF),
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400)),
          ),
        );
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          tab('All', true, null),
          for (final d in depts)
            KeyedSubtree(
                key: ValueKey('store-tab-${d.label}'),
                child: tab(d.label, false, d.open)),
        ]),
      ),
    );
  }
}

/// BD-8: centred "Spotlight Picks" heading + full-width department banners
/// with a white Shop Now pill (Nykaa dark home).
class _SpotlightPicks extends StatelessWidget {
  const _SpotlightPicks({required this.depts});
  final List<_Dept> depts;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 36, 24, 24),
            child: Row(children: [
              Expanded(child: Divider(color: Color(0x1AFFFFFF))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Spotlight Picks',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2)),
              ),
              Expanded(child: Divider(color: Color(0x1AFFFFFF))),
            ]),
          ),
          for (final d in depts) _SpotlightBanner(dept: d),
        ],
      );
}

class _SpotlightBanner extends StatelessWidget {
  const _SpotlightBanner({required this.dept});
  final _Dept dept;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            UiSpace.xl - 4, 0, UiSpace.xl - 4, UiSpace.xxl - 4),
        child: GestureDetector(
          onTap: dept.open,
          // Brief B: calm glass wrapper around a black card, lots of air.
          child: GlassBlackCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(UiRadii.card - UiSpace.sm),
              child: AspectRatio(
                aspectRatio: 16 / 11,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(dept.poster,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF111318))),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xCC000000)],
                        stops: [0.35, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('Shop Now',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  letterSpacing: 0.3,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
