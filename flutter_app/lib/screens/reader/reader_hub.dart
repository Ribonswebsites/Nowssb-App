/// Reader chooser — `#sub-reader` / `.rd-hub` in index.html:8382.
///
/// Two cards, Meaning Reader and eBook Reader, over the Reader film. The
/// home section used to jump to the Library tab; this is the page that
/// actually opens.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/reader_store.dart';
import '../../media/nwsb_image.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/home_parts.dart';
import 'reader_book.dart';

class ReaderHubScreen extends StatefulWidget {
  const ReaderHubScreen({super.key});

  @override
  State<ReaderHubScreen> createState() => _ReaderHubScreenState();
}

class _ReaderHubScreenState extends State<ReaderHubScreen> {
  @override
  void initState() {
    super.initState();
    unawaitedLoad();
  }

  void unawaitedLoad() {
    ReaderStore.instance.ensureLoaded();
  }

  void _open(ReaderKind kind) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderBookScreen(kind: kind),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NwsbVideo(
            asset: 'assets/video/reader-section.mp4',
            poster: 'assets/video/reader-section-poster.webp',
            fit: BoxFit.cover,
            priority: ClipPriority.decoration,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x73040810),
                  Color(0x8C040810),
                  Color(0xCC040810),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18, top + 8, 18, 16),
                child: Row(
                  children: [
                    _BackDisc(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(left: 14),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Color(0x29FFFFFF)),
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reader',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Two ways to read what NowssB holds',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w300,
                                color: Color(0x80FFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0x14FFFFFF)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const AspectRatio(
                        aspectRatio: 16 / 9,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.fromBorderSide(
                              BorderSide(color: Color(0x1AFFFFFF)),
                            ),
                          ),
                          child: NwsbVideo(
                            asset: 'assets/video/reader-section.mp4',
                            poster: 'assets/video/reader-section-poster.webp',
                            fit: BoxFit.cover,
                            priority: ClipPriority.decoration,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _HubCard(
                      image:
                          'https://media.nowssb.com/migrated-images/330ccc47138f8ce6_file_00000000c4b481f4b128fbab24a3b51b_fjaec0.png',
                      title: 'Meaning Reader',
                      sub:
                          'Every meaning in the catalogue, read as one book — grouped into chapters by category.',
                      onTap: () => _open(ReaderKind.meaning),
                    ),
                    const SizedBox(height: 14),
                    _HubCard(
                      image:
                          'https://media.nowssb.com/migrated-images/77925f7681dd8ee7_file_000000006f5481f4bbc8be77aa9ac96a_kslzw1.png',
                      title: 'eBook Reader',
                      sub:
                          'Open any title from the NowssB library and read it chapter by chapter.',
                      onTap: () => _open(ReaderKind.ebook),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackDisc extends StatelessWidget {
  const _BackDisc({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back, size: 18, color: NwsbColors.deep),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.image,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  final String image;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x1AFFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x6B000000),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 68,
              height: 68,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0x1AE8D5A3),
                border: Border.all(color: const Color(0x47E8D5A3)),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: NwsbImage(url: image),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              sub,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                height: 1.55,
                color: Color(0x80FFFFFF),
              ),
            ),
            const SizedBox(height: 18),
            EnterPill(onTap: onTap),
          ],
        ),
      ),
    );
  }
}
