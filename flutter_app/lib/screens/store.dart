/// The NowssB Store — the Flutter counterpart of the WebView Store hub.
///
/// Sub-pages live under `screens/store/` and match website card layouts:
/// Word Atelier (part010), Meaning Store (part026), Signature (part074),
/// Ebooks (part017).
library;

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/intro_gate.dart';

export 'store/ebooks_store.dart';
export 'store/meaning_store.dart';
export 'store/signature_store.dart';
export 'store/word_atelier.dart';

import 'store/ebooks_store.dart';
import 'store/meaning_store.dart';
import 'store/signature_store.dart';
import 'store/word_atelier.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) => IntroGate(
        tag: 'Shabdapathy · Collections',
        eyebrow: '',
        title: 'The NowssB Store',
        body: 'Two libraries. One destination. Own the words that heal — unlock the origins that no dictionary ever told you.',
        stats: const ['Word Library', 'Meaning Library', 'AI-Decoded'],
        art: 'assets/store/intro-store.webp',
        fullBleed: true,
        enterLabel: 'Enter Store',
        onBack: () => Navigator.of(context).maybePop(),
        child: const _StoreHomeContent(),
      );
}

class _StoreHomeContent extends StatelessWidget {
  const _StoreHomeContent();

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _StoreBanner(),
      const _StoreRemoteBanner(
        url: 'https://media.nowssb.com/migrated-images/ccadecda89d460a6_grok_image_1778521152376_il2xkh.jpg',
        height: 190,
      ),
      _StoreVideoSection(
        asset: 'assets/video/store-section.mp4',
        eyebrow: 'THE WORD LIBRARY',
        title: 'Build Your\nPersonal Library',
        sub: 'Each word targets a specific organ. The more words you own, the more healing sentences you can build.',
        chips: const ['HEART HEALTH', 'IMMUNITY', 'MENTAL CLARITY', 'GUT HEALTH', 'SKIN & GLOW', 'LUNG & BREATH'],
        button: 'Browse The Word Atelier',
        onTap: () => _push(context, const WordAtelierScreen()),
      ),
      const _StoreRemoteBanner(
        url: 'https://media.nowssb.com/migrated-images/16c653d97f27f932_file_00000000c81c81fba2f7377fc71229be_uvvxfz.png',
        height: 160,
        margin: EdgeInsets.symmetric(vertical: 20),
      ),
      _StoreVideoSection(
        asset: 'assets/video/store-meaning-library.mp4',
        eyebrow: 'THE MEANING LIBRARY',
        title: 'Unlock the\nTruth Behind Words',
        sub: 'Base meanings · Your purchased words · AI-decoded origins',
        chips: const ['COUNTRY', 'EARTH', 'BODY', 'MIND', 'SOUL', 'BLOOD'],
        button: 'Browse Meaning Store',
        onTap: () => _push(context, const MeaningStoreScreen()),
      ),
      _SignatureDoor(onTap: () => _push(context, const SignatureStoreScreen())),
      const _StoreVideoBanner(asset: 'assets/video/store-verify-banner.mp4', poster: 'assets/video/store-verify-banner-poster.webp'),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 4),
        child: Text('Everything Else, In One Place', style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: NwsbColors.gold)),
      ),
      _MiniStoreCard(
        eyebrow: 'Verified · Badges',
        title: 'Get Verified',
        sub: 'Blue, Silver, Gold or Diamond — stand out on your profile.',
        icon: Icons.verified_outlined,
        onTap: () {},
      ),
      _MiniStoreCard(
        eyebrow: 'Read · Learn · Practice',
        title: 'NowssB Ebooks',
        sub: 'Deep-dive guides on word science and sound healing.',
        icon: Icons.menu_book_outlined,
        onTap: () => _push(context, const EbooksStoreScreen()),
      ),
      _MiniStoreCard(
        eyebrow: 'Resonance · Frequency · X',
        title: 'Subscription Plans',
        sub: 'More words, more features — see every tier.',
        icon: Icons.auto_awesome_outlined,
        onTap: () {},
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
    return Scaffold(backgroundColor: NwsbColors.deep, body: SafeArea(child: ListView(children: items)));
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _StoreBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network('https://media.nowssb.com/migrated-images/d748b5f773a2d866_grok_image_1778576400577_mnxqkd.jpg', fit: BoxFit.cover),
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
                  Text('SHABDAPATHY · COLLECTIONS', style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: NwsbColors.gold)),
                  SizedBox(height: 8),
                  Text('The NowssB Store', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300, color: Colors.white)),
                  SizedBox(height: 5),
                  Text('Word Library · Meaning Library · NowssB Signature', style: TextStyle(fontSize: 11, color: Color(0xB3FFFFFF))),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StoreRemoteBanner extends StatelessWidget {
  const _StoreRemoteBanner({required this.url, required this.height, this.margin = EdgeInsets.zero});
  final String url;
  final double height;
  final EdgeInsets margin;
  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        height: height,
        color: Colors.black,
        child: Image.network(url, fit: BoxFit.cover),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.black),
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
                Text(eyebrow, style: const TextStyle(fontSize: 10, letterSpacing: 2.2, color: NwsbColors.gold)),
                const Spacer(),
                Text(title, style: const TextStyle(fontSize: 28, height: 1.05, fontWeight: FontWeight.w300, color: Colors.white)),
                const SizedBox(height: 12),
                Text(sub, style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xCCFFFFFF))),
                const SizedBox(height: 12),
                Wrap(spacing: 7, runSpacing: 7, children: [for (final chip in chips) _StoreChip(chip)]),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    color: Colors.white,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(button, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NwsbColors.ink)),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward, size: 15, color: NwsbColors.ink),
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
        decoration: BoxDecoration(color: const Color(0x18FFFFFF), border: Border.all(color: const Color(0x26FFFFFF))),
        child: Text(text, style: const TextStyle(fontSize: 8, letterSpacing: 1.5, color: Color(0xCCFFFFFF))),
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
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.black),
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
                  Text('SHABDAPATHY · THE RAREST', style: TextStyle(fontSize: 10, letterSpacing: 2.2, color: NwsbColors.gold)),
                  Spacer(),
                  Text('Words & Meanings', style: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.w300)),
                  SizedBox(height: 6),
                  Text('One per category. Owned once, never restocked.', style: TextStyle(fontSize: 11, color: Color(0xB3FFFFFF))),
                  SizedBox(height: 12),
                  Text('15 Words   ·   5 Meanings', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Color(0xCCFFFFFF))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreVideoBanner extends StatelessWidget {
  const _StoreVideoBanner({required this.asset, required this.poster});
  final String asset, poster;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 5,
            child: NwsbVideo(asset: asset, poster: poster, priority: ClipPriority.decoration),
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
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x14FFFFFF)),
              child: Icon(icon, color: NwsbColors.gold, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow, style: const TextStyle(fontSize: 9, letterSpacing: 1.2, color: Color(0x99FFFFFF))),
                  const SizedBox(height: 3),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(sub, style: const TextStyle(fontSize: 11, height: 1.3, color: Color(0x8CFFFFFF))),
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
