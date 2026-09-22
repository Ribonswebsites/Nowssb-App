import 'package:flutter/material.dart';

/// Editorial campaign spread inspired by the supplied website references.
/// Each spread uses three of the uploaded NowssB campaign images and keeps the
/// typography/layout separate from the artwork so the copy can evolve safely.
class EditorialBanner extends StatelessWidget {
  const EditorialBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.note,
    required this.images,
    required this.background,
  });

  const EditorialBanner.connect({super.key})
      : eyebrow = 'NOWSSB / CONNECT',
        title = 'SOUND\nTHAT\nFINDS YOU',
        body =
            'A daily language for the way you listen, move and meet the world.',
        note = 'CONNECT · WORDS · PRESENCE',
        images = const [
          'assets/editorial/connect.png',
          'assets/editorial/library.png',
          'assets/editorial/player.png',
        ],
        background = const Color(0xFFF4F0EB);

  const EditorialBanner.science({super.key})
      : eyebrow = 'NOWSSB / WORD SCIENCE',
        title = 'WORDS\nTHAT\nMOVE YOU',
        body =
            'Discover the sound beneath every word and let meaning become practice.',
        note = 'SPEAK · FEEL · TRANSFORM',
        images = const [
          'assets/editorial/science.png',
          'assets/editorial/profile.png',
          'assets/editorial/progress.png',
        ],
        background = const Color(0xFF8DB6CA);

  const EditorialBanner.healing({super.key})
      : eyebrow = 'NOWSSB / THE DAILY RITUAL',
        title = 'HEALING\nIN A\nNEW FORM',
        body =
            'Pronunciation, sound and stillness — carried with you wherever you are.',
        note = 'LISTEN · PRACTICE · HEAL',
        images = const [
          'assets/editorial/reader.png',
          'assets/editorial/store.png',
          'assets/editorial/subscribe.png',
        ],
        background = const Color(0xFFEAD8D1);

  final String eyebrow;
  final String title;
  final String body;
  final String note;
  final List<String> images;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final darkText = const Color(0xFF101010);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
              color: Color(0x30000000), blurRadius: 22, offset: Offset(0, 12)),
        ],
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: darkText, fontFamily: 'DM Sans'),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _micro(eyebrow),
                _micro('EDITORIAL / NOWSSB'),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: darkText.withValues(alpha: .3)),
            const SizedBox(height: 14),
            SizedBox(
              height: 300,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 84,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 34,
                              height: .84,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            body,
                            style: const TextStyle(
                              fontSize: 9,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                              height: 1,
                              width: 78,
                              color: darkText.withValues(alpha: .4)),
                          const SizedBox(height: 7),
                          Text(note,
                              style: const TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .7)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 136,
                    child: _Mosaic(images: images),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: darkText.withValues(alpha: .3)),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _micro('NOWSSB.'),
                _micro('THE NEW FASHION TREND OF MEDITATION'),
                _micro('ENTER  →'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _micro(String value) => Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 1),
      );
}

class _Mosaic extends StatelessWidget {
  const _Mosaic({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = BorderRadius.circular(12);
        return Row(
          children: [
            Expanded(
              flex: 105,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: radius.topLeft,
                  bottomLeft: radius.bottomLeft,
                ),
                child: Image.asset(images[0], fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 95,
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.only(topRight: radius.topRight),
                      child: Image.asset(images[1], fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.only(bottomRight: radius.bottomRight),
                      child: Image.asset(images[2], fit: BoxFit.cover),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
