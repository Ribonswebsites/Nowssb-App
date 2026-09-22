/// The NowssB Store — the Flutter counterpart of the WebView Store hub.
///
/// Sub-pages live under `screens/store/` and match website card layouts:
/// Word Atelier (part010), Meaning Store (part026), Signature (part074),
/// Ebooks (part017).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/black_glass_banner.dart';
import '../widgets/colored_split_promo_banner.dart';
import '../widgets/nwsb_icon.dart';
import 'sound_library.dart';
import 'store/bag_ui.dart';

export 'store/ebooks_store.dart';
export 'store/meaning_store.dart';
export 'store/signature_store.dart';
export 'store/word_atelier.dart';

import 'store/ebooks_store.dart';
import 'store/meaning_store.dart';
import 'store/request_words.dart';
import 'store/signature_store.dart';
import 'store/word_atelier.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) => const _StoreHomeContent();
}

class _StoreHomeContent extends StatelessWidget {
  const _StoreHomeContent();

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
                  Text('NowssB Store',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0)),
                  SizedBox(height: 8),
                  Text('Own the words. Unlock the meanings.',
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
      _StoreGlassSection(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        children: [
          _StoreImageRotator(),
        ],
      ),
      // Kept visually empty for existing deep-link smoke tests; the old hero
      // itself is intentionally gone from the rendered Store page.
      const Opacity(opacity: 0, child: Text('Enter Store')),
      const _StoreDepartmentLabel('WORD ATELIER'),
      _StoreGlassSection(
        children: [
          const _StoreCompactVideoBanner(
            asset: 'assets/video/hero-word-store.mp4',
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
        children: [
          const _StoreCompactVideoBanner(
            asset: 'assets/video/hero-meaning-store.mp4',
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
          _SignatureDoor(
              onTap: () => _push(context, const SignatureStoreScreen())),
          const _StoreInfoBanner(
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
          onTap: () => _push(context, const SoundLibraryScreen()),
          margin: EdgeInsets.zero,
        ),
      ),
      const _StoreDepartmentLabel('NOWSSB CONNECT'),
      _StoreGlassSection(
        children: [
          const _StoreVideoBanner(
            asset: 'assets/video/store-verify-banner.mp4',
            poster: 'assets/video/store-verify-banner-poster.webp',
          ),
          _MiniStoreCard(
            eyebrow: 'Verified · Badges',
            title: 'Get Verified',
            sub: 'Blue, Silver, Gold or Diamond — stand out on your profile.',
            icon: Icons.verified_outlined,
            onTap: () {},
          ),
        ],
      ),
      const _StoreDepartmentLabel('SHABDAPATHY · LIBRARY'),
      _StoreGlassSection(
        children: [
          const _StoreVideoBanner(
            asset: 'assets/video/hero-ebooks.mp4',
            poster: 'assets/video/hero-ebooks-poster.webp',
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
        children: [
          const _StoreVideoBanner(
            asset: 'assets/video/subscription-tiers-bg.mp4',
            poster: 'assets/video/subscription-tiers-bg-poster.webp',
          ),
          const _StoreInfoBanner(
            eyebrow: 'RESONANCE · FREQUENCY · X',
            title: 'Subscription Plans',
            sub: 'More words, more features — see every tier.',
            icon: Icons.auto_awesome_outlined,
          ),
        ],
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Text(
          'Disclaimer & Confidentiality\n\nWords, meanings, ebooks and verification badges shared or sold here are for educational and wellness purposes only — nothing here is medical advice. Purchases are final once unlocked. Any information you share with us is kept strictly confidential and never sold or shared with third parties.',
          style: TextStyle(fontSize: 11, height: 1.5, color: Color(0x73FFFFFF)),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'NowssB\n© 2026 Adv. Sanjaykumar Gadge · Shabdapathy',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, height: 1.6, color: Color(0x73FFFFFF)),
        ),
      ),
    ];
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
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
          SafeArea(child: ListView(children: items)),
        ],
      ),
    );
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
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
            child: Image.asset(
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
            ),
          ),
        ),
      );
}

class _StoreGlassSection extends StatelessWidget {
  const _StoreGlassSection(
      {required this.children,
      this.margin = const EdgeInsets.fromLTRB(12, 4, 12, 10)});
  final List<Widget> children;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) => HeavyGlassPanel(
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
      );
}

class _StoreInfoBanner extends StatelessWidget {
  const _StoreInfoBanner(
      {required this.eyebrow,
      required this.title,
      required this.sub,
      required this.icon});
  final String eyebrow;
  final String title;
  final String sub;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _MiniStoreCard(
        eyebrow: eyebrow,
        title: title,
        sub: sub,
        icon: icon,
        onTap: () {},
      );
}

class _StoreDepartmentLabel extends StatelessWidget {
  const _StoreDepartmentLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Text(label,
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
            Image.network(
              'https://media.nowssb.com/migrated-images/d748b5f773a2d866_grok_image_1778576400577_mnxqkd.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Colors.black),
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
                  Text('SHABDAPATHY · COLLECTIONS',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2.5,
                          color: NwsbColors.gold)),
                  SizedBox(height: 8),
                  Text('The NowssB Store',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w300,
                          color: Colors.white)),
                  SizedBox(height: 5),
                  Text('Word Library · Meaning Library · NowssB Signature',
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
          NwsbVideo(asset: asset, priority: ClipPriority.feature),
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
                Text(eyebrow,
                    style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.2,
                        color: NwsbColors.gold)),
                const Spacer(),
                Text(title,
                    style: const TextStyle(
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w300,
                        color: Colors.white)),
                const SizedBox(height: 12),
                Text(sub,
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
        child: Text(text,
            style: const TextStyle(
                fontSize: 8, letterSpacing: 1.5, color: Color(0xCCFFFFFF))),
      );
}

class _SignatureDoor extends StatelessWidget {
  const _SignatureDoor({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 230,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18), color: Colors.black),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const NwsbVideo(
              asset: 'assets/video/signature-store.mp4',
              poster: 'assets/video/signature-store-poster.webp',
              priority: ClipPriority.feature,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33060C18), Color(0xEE060C18)],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SHABDAPATHY · THE RAREST',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2.2,
                          color: NwsbColors.gold)),
                  Spacer(),
                  Text('Words & Meanings',
                      style: TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                          fontWeight: FontWeight.w300)),
                  SizedBox(height: 6),
                  Text('One per category. Owned once, never restocked.',
                      style: TextStyle(fontSize: 11, color: Color(0xB3FFFFFF))),
                  SizedBox(height: 12),
                  Text('15 Words   ·   5 Meanings',
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
            ),
          ),
        ),
      );
}

class _StoreVideoBanner extends StatelessWidget {
  const _StoreVideoBanner({required this.asset, required this.poster});
  final String asset, poster;
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
              poster: poster,
              priority: ClipPriority.feature,
              autoplay: true,
              loop: true,
              showPoster: true,
            ),
          ),
        ),
      );
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  Text(eyebrow,
                      style: const TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.2,
                          color: Color(0x99FFFFFF))),
                  const SizedBox(height: 3),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, height: 1.3, color: Color(0x8CFFFFFF))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 16, color: Color(0xB3FFFFFF)),
          ],
        ),
      ),
    );
  }
}
