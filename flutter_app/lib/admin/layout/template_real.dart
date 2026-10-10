/// The app's own cards, films and store rows, as pieces the owner can drop
/// on a page. Not invented banners — the same Word Atelier card, the same
/// store row, the same films.
library;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../media/nwsb_video.dart';
import '../../screens/fashion/sections_bottom.dart';
import '../../screens/fashion/sections_top.dart';
import '../../screens/store/store_cards.dart';
import '../../widgets/buddha_gyro_stage.dart';
import '../../widgets/home_skin.dart';

const kAppPieceNames = <String, String>{
  'pieceWord': 'Word type card',
  'pieceWords': 'Word type row',
  'pieceLibrary': 'Library card',
  'pieceMeaning': 'Meaning card',
  'pieceSignature': 'Signature card',
  'pieceBooks': 'Ebook card',
  'piecePlans': 'Plan card',
  'pieceVerify': 'Verify card',
  'pieceFilmWord': 'Word film',
  'pieceFilmMean': 'Meaning film',
  'pieceFilmSign': 'Signature film',
  'pieceFilmBook': 'Book film',
  'pieceFilmPlan': 'Plan film',
  'pieceFilmCheck': 'Verify film',
  'pieceCoupon': 'Coupon picture',
  'pieceHalf': 'Half-off row',
  'pieceHype': 'Hype posters',
  'pieceSplit': 'Store offer',
  'cardPractice': 'Today\'s practice',
  'cardReader': 'Reader block',
  'cardStreak': 'Streak block',
  'cardOffer': 'Offer card',
  'cardQuote': 'Quotes stage',
  'cardQuoteSoft': 'Quotes stage, raised',
};

const kAppPieceBlurbs = <String, String>{
  'pieceWord': 'One Word Atelier card, the real one',
  'pieceWords': 'Three Word Atelier cards in a row',
  'pieceLibrary': 'The store card for the word library',
  'pieceMeaning': 'The store card for meanings',
  'pieceSignature': 'The store card for signature words',
  'pieceBooks': 'The store card for ebooks',
  'piecePlans': 'The store card for plans',
  'pieceVerify': 'The store card for verification',
  'pieceFilmWord': 'The word-store film',
  'pieceFilmMean': 'The meaning-store film',
  'pieceFilmSign': 'The signature-store film',
  'pieceFilmBook': 'The ebook film',
  'pieceFilmPlan': 'The plans film',
  'pieceFilmCheck': 'The verify film',
  'pieceCoupon': 'The coupon picture, not full width',
  'pieceHalf': 'The store half-off row',
  'pieceHype': 'The hyped-words posters',
  'pieceSplit': 'The store offer banner',
  'cardPractice': 'The practice card, black inside glass',
  'cardReader': 'The reader card, black inside glass',
  'cardStreak': 'The streak card, black inside glass',
  'cardOffer': 'The offer card, black inside glass',
  'cardQuote': 'The quotes stage, black inside glass. The Buddha stays. The pictures change.',
  'cardQuoteSoft': 'The same quotes stage, raised, for the normal home',
};

/// Where a piece opens. Only a route string — the words on the card are fixed.
Map<String, dynamic> appPieceStarter(String kind) => {
      'route': switch (kind) {
        'pieceWord' || 'pieceWords' || 'pieceLibrary' || 'pieceFilmWord' => 'page:store.atelier',
        'pieceMeaning' || 'pieceFilmMean' => 'page:store.meaning',
        'pieceSignature' || 'pieceFilmSign' => 'page:store.signature',
        'pieceBooks' || 'pieceFilmBook' => 'page:store.ebooks',
        'piecePlans' || 'pieceFilmPlan' => 'page:subscription',
        'pieceCoupon' => 'page:coupons.program',
        'pieceHalf' || 'pieceHype' => 'page:store.atelier',
        'pieceSplit' => 'page:subscription',
        'pieceVerify' || 'pieceFilmCheck' => 'page:profile',
        _ => 'tab:3',
      },
    };

/// Draws one app piece. [onTap] opens [appPieceStarter]'s route.
Widget buildAppPiece(String kind, {VoidCallback? onTap}) {
  switch (kind) {
    case 'pieceWord':
      return _wordPad(SizedBox(
        height: 220,
        child: RmWordCard(name: 'Aarogya', root: 'Immune system', imgUrl: kRmWordImg, price: 199, onTap: onTap, onAddCart: onTap),
      ));
    case 'pieceWords':
      return _wordPad(SizedBox(
        height: 220,
        child: Row(children: [
          for (final (w, r) in [('Aarogya', 'Immune system'), ('Prana', 'Lungs · Heart'), ('Soma', 'Body · Mind')]) ...[
            Expanded(child: RmWordCard(name: w, root: r, imgUrl: kRmWordImg, price: 199, onTap: onTap, onAddCart: onTap)),
            if (w != 'Soma') const SizedBox(width: 8),
          ],
        ]),
      ));
    case 'pieceLibrary':
      return AppStoreCard(
        eyebrow: 'THE WORD LIBRARY · PERSONAL COLLECTIONS',
        title: 'Build Your Personal Library',
        sub: 'Heart Health · Immunity · Mental Clarity · Gut Health · Skin & Glow · Lung & Breath.',
        icon: Icons.menu_book_outlined,
        onTap: onTap,
      );
    case 'pieceMeaning':
      return AppStoreCard(
        eyebrow: 'THE MEANING LIBRARY · AI-DECODED ORIGINS',
        title: 'Meanings beneath every word',
        sub: 'Country · Earth · Body · Mind · Soul · Blood — unlock the origins no dictionary told you.',
        icon: Icons.language_outlined,
        onTap: onTap,
      );
    case 'pieceSignature':
      return AppStoreCard(
        eyebrow: 'SIGNATURE STORE · LIMITED COLLECTIONS',
        title: 'Words & Meanings',
        sub: '15 Words · 5 Meanings. Owned once, never restocked.',
        icon: Icons.headphones_outlined,
        onTap: onTap,
      );
    case 'pieceBooks':
      return AppStoreCard(
        eyebrow: 'Read · Learn · Practice',
        title: 'NowssB Ebooks',
        sub: 'Deep-dive guides on word science and sound healing.',
        icon: Icons.menu_book_outlined,
        onTap: onTap,
      );
    case 'piecePlans':
      return AppStoreCard(
        eyebrow: 'RESONANCE · FREQUENCY · X',
        title: 'Subscription Plans',
        sub: 'More words, more features — see every tier.',
        icon: Icons.auto_awesome_outlined,
        onTap: onTap,
      );
    case 'pieceVerify':
      return AppStoreCard(
        eyebrow: 'Verified · Badges',
        title: 'Get Verified',
        sub: 'Blue, Silver, Gold or Diamond — stand out on your profile.',
        icon: Icons.verified_outlined,
        onTap: onTap,
      );
    case 'pieceFilmWord':
      return _film('assets/video/hero-word-store.mp4', 'Word store', onTap);
    case 'pieceFilmMean':
      return _film('assets/video/hero-meaning-store.mp4', 'Meaning store', onTap);
    case 'pieceFilmSign':
      return _film('assets/video/signature-store-hero.mp4', 'Signature store', onTap);
    case 'pieceFilmBook':
      return _film('assets/video/hero-ebooks.mp4', 'Ebooks', onTap);
    case 'pieceFilmPlan':
      return _film('assets/video/subscription-a.mp4', 'Plans', onTap);
    case 'pieceFilmCheck':
      return _film('assets/video/store-verify-banner.mp4', 'Verify', onTap);
    case 'pieceCoupon':
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: GestureDetector(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 280),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/gifts/coupon-hero.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 140,
                    width: 160,
                    child: ColoredBox(
                      color: Color(0xFF111111),
                      child: Center(child: Text('Coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    case 'cardPractice':
      return _home(const FashPractice(), fashion: true);
    case 'cardReader':
      return _home(const FashReader(), fashion: true);
    case 'cardStreak':
      return _home(const FashStreak(), fashion: true);
    case 'cardOffer':
      return _home(const FashOffer(), fashion: true);
    case 'cardQuote':
      return _home(const BuddhaGyroStage(), fashion: true);
    case 'cardQuoteSoft':
      return _home(const BuddhaGyroStage(neumorphic: true), fashion: false);
    default:
      return const SizedBox.shrink();
  }
}

Widget _home(Widget child, {required bool fashion}) {
  return ColoredBox(
    color: fashion ? const Color(0xFF07080C) : const Color(0xFFF0F2F7),
    child: HomeSkinScope(
      skin: fashion ? HomeSkin.fashion : HomeSkin.normal,
      child: child,
    ),
  );
}

Widget _wordPad(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );

Widget _film(String asset, String caption, VoidCallback? onTap) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(fit: StackFit.expand, children: [
            NwsbVideo(asset: asset, fit: BoxFit.cover, loop: true, autoplay: true),
            Positioned(
              left: 10,
              bottom: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(color: const Color(0xCC000000), borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ),
      ),
    ),
  );
}

/// The dark glass store row: icon disc, eyebrow, title, line.
class AppStoreCard extends StatelessWidget {
  const AppStoreCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.sub,
    required this.icon,
    this.onTap,
  });

  final String eyebrow;
  final String title;
  final String sub;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x33FFFFFF)),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 4), blurRadius: 0)],
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0A0A0A),
                boxShadow: [
                  BoxShadow(color: Color(0xFF000000), offset: Offset(2, 2), blurRadius: 0),
                  BoxShadow(color: Color(0x22FFFFFF), offset: Offset(-1, -1), blurRadius: 0),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(eyebrow, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, letterSpacing: 1.2, color: Color(0x99FFFFFF))),
                const SizedBox(height: 3),
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 3),
                Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.3, color: Color(0x8CFFFFFF))),
              ]),
            ),
            const Icon(Icons.arrow_forward, size: 16, color: Color(0xB3FFFFFF)),
          ]),
        ),
      ),
    );
  }
}
