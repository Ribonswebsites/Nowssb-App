/// The NowssB Store — the Flutter counterpart of the WebView Store hub.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../theme/tokens.dart';
import '../widgets/intro_gate.dart';
import '../widgets/page_shell.dart';
import 'word_detail.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      eyebrow: 'Own the sounds that heal',
      title: 'NowssB Store',
      film: 'assets/video/store-section.mp4',
      slivers: [
        SliverToBoxAdapter(child: _StoreHero()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverList.list(children: [
            const _StoreSectionLabel('THE LIBRARY'),
            _DepartmentCard(
              art: 'assets/store/intro-words.webp',
              eyebrow: 'Word Atelier',
              title: 'Words that heal',
              body: 'Explore pronunciation, origin, organ and sound — one word at a time.',
              onTap: (c) => _open(c, const WordAtelierScreen()),
            ),
            _DepartmentCard(
              art: 'assets/store/intro-meanings.webp',
              eyebrow: 'Meaning Store',
              title: 'What a word truly means',
              body: 'Unlock the origin, vibration and hidden meaning behind every word.',
              onTap: (c) => _open(c, const MeaningStoreScreen()),
            ),
            _DepartmentCard(
              art: 'assets/store/intro-signature.webp',
              eyebrow: 'Signature Store',
              title: 'The rarest collection',
              body: 'Signature words and meanings gathered into one premium shelf.',
              onTap: (c) => _open(c, const SignatureStoreScreen()),
            ),
            _DepartmentCard(
              art: 'assets/store/intro-ebooks.webp',
              eyebrow: 'Shabdapathy · Library',
              title: 'Read, learn, practice',
              body: 'Deep-dive guides on word science, phonetic origin and sound healing.',
              onTap: (c) => _open(c, const EbooksStoreScreen()),
            ),
            const SizedBox(height: 8),
            const _StoreFooter(),
          ]),
        ),
      ],
    );
  }

  static void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _StoreHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 220,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/store/intro-store.webp', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22060C18), Color(0xEE060C18)],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('WORDS · MEANINGS · BOOKS', style: TextStyle(fontSize: 9, letterSpacing: 2.5, color: NwsbColors.gold)),
                  SizedBox(height: 6),
                  Text('Everything that helps you heal in one place.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.12)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StoreSectionLabel extends StatelessWidget {
  const _StoreSectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: const TextStyle(fontSize: 9, letterSpacing: 3, fontWeight: FontWeight.w700, color: NwsbColors.gold)),
      );
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({required this.art, required this.eyebrow, required this.title, required this.body, required this.onTap});
  final String art, eyebrow, title, body;
  final void Function(BuildContext) onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onTap(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 142,
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x1FFFFFFF))),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(art, fit: BoxFit.cover),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xF0060C18), Color(0xB0060C18), Color(0x33060C18)]))),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                Text(eyebrow.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, letterSpacing: 2.0, color: NwsbColors.gold)),
                const SizedBox(height: 4),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text(body, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.25, color: Color(0xB3FFFFFF))),
              ]),
            ),
            const Positioned(right: 18, bottom: 18, child: Icon(Icons.arrow_forward, size: 18, color: Color(0xD9FFFFFF))),
          ]),
        ),
      );
}

class _StoreFooter extends StatelessWidget {
  const _StoreFooter();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Text('NowssB · Shabdapathy · Own the sounds that heal', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: Color(0x66FFFFFF))),
      );
}

class WordAtelierScreen extends StatelessWidget {
  const WordAtelierScreen({super.key});
  @override
  Widget build(BuildContext context) => IntroGate(
        tag: 'Shabdapathy · Word Science',
        eyebrow: 'The Word Atelier',
        title: 'Explore the\norigin of words.',
        body: 'Every word carries a vibrational signature that predates all dictionaries. Explore the phonetic origin of any word in any language.',
        stats: const ['Unlimited words', 'AI-powered', 'Every language'],
        art: 'assets/store/intro-words.webp',
        enterLabel: 'Enter The Word Atelier',
        onBack: () => Navigator.of(context).pop(),
        child: _StoreContentPage(title: 'The Word Atelier', child: _WordsShelf()),
      );
}

class MeaningStoreScreen extends StatelessWidget {
  const MeaningStoreScreen({super.key});
  @override
  Widget build(BuildContext context) => IntroGate(
        tag: 'Shabdapathy · True Origin',
        eyebrow: 'The Meaning Store',
        title: 'Unlock what\nwords truly mean.',
        body: 'Every word you know has a meaning you were never told. Before the dictionary — there was only vibration.',
        stats: const ['Any language', 'AI-decoded', 'One-time unlock'],
        art: 'assets/store/intro-meanings.webp',
        enterLabel: 'Explore Meanings',
        onBack: () => Navigator.of(context).pop(),
        child: _StoreContentPage(title: 'The Meaning Store', child: _MeaningsShelf()),
      );
}

class SignatureStoreScreen extends StatelessWidget {
  const SignatureStoreScreen({super.key});
  @override
  Widget build(BuildContext context) => IntroGate(
        tag: 'NowssB · Signature',
        eyebrow: 'The Signature Store',
        title: 'The rarest\nthings we carry.',
        body: 'A premium shelf of signature words and meanings, chosen from the deepest collections in NowssB.',
        stats: const ['Rare collection', 'Premium words', 'Yours forever'],
        art: 'assets/store/intro-signature.webp',
        enterLabel: 'Browse Signatures',
        onBack: () => Navigator.of(context).pop(),
        child: _StoreContentPage(title: 'Signature Store', child: const _SignatureShelf()),
      );
}

class EbooksStoreScreen extends StatelessWidget {
  const EbooksStoreScreen({super.key});
  @override
  Widget build(BuildContext context) => IntroGate(
        tag: 'Shabdapathy · Library',
        eyebrow: 'Read · Learn · Practice',
        title: 'The NowssB\nEbooks.',
        body: 'Deep-dive guides on word science, phonetic origin and sound healing — yours to keep, read anywhere, forever.',
        stats: const ['Two titles', 'Instant access', 'Read forever'],
        art: 'assets/store/intro-ebooks.webp',
        enterLabel: 'Browse Ebooks',
        onBack: () => Navigator.of(context).pop(),
        child: _StoreContentPage(title: 'The NowssB Ebooks', child: _BooksShelf()),
      );
}

class _StoreContentPage extends StatelessWidget {
  const _StoreContentPage({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => PageShell(
        eyebrow: 'NowssB Store',
        title: title,
        film: 'assets/video/store-section.mp4',
        onBack: () => Navigator.of(context).pop(),
        slivers: [SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverList.list(children: [child]))],
      );
}

class _WordsShelf extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final words = ContentStore.instance.library;
    return Column(children: [
      const _ShelfHeading('Your words', 'Pronunciation, origin and sound'),
      if (words.isEmpty) const _Await('No words on the shelf yet.') else ...[
        for (final w in words)
          WordRow(word: w.word, deva: w.deva, sub: w.meaning.isNotEmpty ? w.meaning : w.organ, trailing: _Price(w.price), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WordDetail(word: w)))),
      ],
    ]);
  }
}

class _MeaningsShelf extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = ContentStore.instance.meanings;
    return Column(children: [
      const _ShelfHeading('Meanings & origins', 'The truth behind the sound'),
      if (items.isEmpty) const _Await('The Meaning Store is published from the studio — nothing has been put on this shelf yet.') else ...[
        for (final m in items) WordRow(word: m.name, deva: '', sub: m.sub, trailing: _Price(m.price)),
      ],
    ]);
  }
}

class _SignatureShelf extends StatelessWidget {
  const _SignatureShelf();
  @override
  Widget build(BuildContext context) => Column(children: [
        const _ShelfHeading('Signature collection', 'The rarest words and meanings'),
        _SignatureRow('NOWSSB', 'The signature sound', 'assets/signature/nowssb-signature.webp'),
        _SignatureRow('SOUND', 'A rare word collection', 'assets/signature/sig-words-icon.webp'),
        _SignatureRow('ORIGIN', 'Meaning, held forever', 'assets/signature/sig-meanings-icon.webp'),
      ]);
}

class _SignatureRow extends StatelessWidget {
  const _SignatureRow(this.title, this.sub, this.art);
  final String title, sub, art;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x1FFFFFFF))), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(art, width: 64, height: 64, fit: BoxFit.cover)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)), const SizedBox(height: 4), Text(sub, style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF))), const SizedBox(height: 8), const Text('Signature item', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: NwsbColors.gold))])), const Icon(Icons.arrow_forward, size: 17, color: Color(0xB3FFFFFF))]));
}

class _BooksShelf extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = ContentStore.instance.books;
    return Column(children: [
      const _ShelfHeading('The library', 'Read anywhere, forever'),
      if (items.isEmpty) const _Await('No eBooks yet.') else ...[
        for (final b in items) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x14FFFFFF))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 58, height: 76, decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), image: const DecorationImage(image: AssetImage('assets/store/intro-ebooks.webp'), fit: BoxFit.cover))), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(b.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)), if (b.sub.isNotEmpty) ...[const SizedBox(height: 5), Text(b.sub, style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0x8CFFFFFF)))], const SizedBox(height: 10), _Price(b.price)]))]))
      ],
    ]);
  }
}

class _ShelfHeading extends StatelessWidget {
  const _ShelfHeading(this.title, this.sub);
  final String title, sub;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)), const SizedBox(height: 4), Text(sub, style: const TextStyle(fontSize: 12, color: Color(0x8CFFFFFF)))])), const Icon(Icons.auto_awesome, size: 18, color: NwsbColors.gold)]));
}

class _Price extends StatelessWidget {
  const _Price(this.value);
  final num value;
  @override
  Widget build(BuildContext context) => Text(value <= 0 ? 'Included' : '₹$value', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NwsbColors.goldLight));
}

class _Await extends StatelessWidget {
  const _Await(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20), child: Column(children: [const Icon(Icons.storefront_outlined, size: 32, color: Color(0x66FFFFFF)), const SizedBox(height: 14), Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.55, color: Color(0x8CFFFFFF)))]));
}
