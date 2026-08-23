/// FOLLOW THE STEPS — app/js/part084.js.
///
/// The white disc in the hero's bottom right corner, the one with `LEARN`
/// beside it. Tapping it does not open a page and does not push anything
/// down the home: IT TAKES OVER THE RAIL THE HERO ALREADY HAS. The six video
/// banners that slide in from the right are replaced by fifteen black cards
/// that slide in from the right in exactly the same way, and tapping the
/// disc again puts the banners back.
///
/// That is why this file is small. The deck — the slide, the height, the
/// swipe — belongs to hero.dart and stays there. This file only ever says
/// WHAT is passing through it.
///
/// Three rules the cards are built on (:19):
///
///   1. A step card is BLACK. No clip in it, no tablet round it, no glass.
///      Everything else in that rail is footage inside a frame, so the one
///      thing meant to be read is the one thing with nothing moving in it.
///
///   2. It is exactly as tall as the hero card, because it IS a cell of the
///      hero's deck.
///
///   3. The auto-advance stops being the clip's and becomes its own — 7s,
///      wrapping from the last step back to the title, and standing down
///      for 14s whenever a finger touches it. A step you are half-way
///      through leaving on a timer is the guide fighting you.
///
/// Cell 0 is not step one. It is the TITLE CARD: the television's own screen
/// changes — the wordmark goes blonde, "Follow the steps" comes up under it,
/// and the tagline, the word and the two buttons go. The thing you tapped is
/// the thing that answers.
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';

/// The guide's own marks — part084.js:50-63.
///
/// Drawn, not fetched, and its own set rather than [NwsbMarks]: "fifteen
/// cards is fifteen icons, and fifteen more image requests on a home that
/// already carries a dozen clips is not a trade worth making for something
/// this small." Transcribed verbatim, the same as every other mark in this
/// app.
class FstMarks {
  FstMarks._();

  static const play = '<path d="M8 5.2 19 12 8 18.8z"/>';
  static const sun = '<circle cx="12" cy="12" r="4.2"/>'
      '<path d="M12 2.6v2.6M12 18.8v2.6M2.6 12h2.6M18.8 12h2.6M5.4 5.4l1.9 '
      '1.9M16.7 16.7l1.9 1.9M18.6 5.4l-1.9 1.9M7.3 16.7l-1.9 1.9"/>';
  static const clock =
      '<circle cx="12" cy="12" r="8.6"/><path d="M12 6.8V12l3.4 2"/>';
  static const book =
      '<path d="M4 5.4h6.4a2 2 0 0 1 2 2v11.2a2.4 2.4 0 0 0-2-1H4z"/>'
      '<path d="M20 5.4h-6.4a2 2 0 0 0-2 2v11.2a2.4 2.4 0 0 1 2-1H20z"/>';
  static const bag =
      '<path d="M4.4 7.6h15.2l-1.1 12.2a1.5 1.5 0 0 1-1.5 1.4H7a1.5 1.5 0 0 '
      '1-1.5-1.4z"/><path d="M8.7 10V6.6a3.3 3.3 0 0 1 6.6 0V10"/>';
  static const pages = '<path d="M7.4 3.6h7l4 4v12.8h-11z"/>'
      '<path d="M14.4 3.6v4h4"/><path d="M9.6 12.4h6M9.6 15.6h4"/>';
  static const sig =
      '<path d="M3.6 16.6c3-.4 5-2.2 6.6-5.4 1.2-2.4 2-4.6 3.2-4.6 1 0 1.4 1 '
      '1 2.4-.5 1.8-2 3-3.4 3.6-1.4.6-2 1.4-1.6 2.2.4.8 1.8.9 3.2.4 1.6-.6 '
      '2.8-1.6 4-3"/><path d="M4 20h16"/>';
  static const sound = '<path d="M11.4 4.6 6.8 8.6H3.6v6.8h3.2l4.6 4V4.6z"/>'
      '<path d="M15.6 8.8a4.6 4.6 0 0 1 0 6.4M18.4 6a8.6 8.6 0 0 1 0 12"/>';
  static const atom = '<circle cx="12" cy="12" r="2.4"/>'
      '<ellipse cx="12" cy="12" rx="9" ry="4" />'
      '<ellipse cx="12" cy="12" rx="9" ry="4" transform="rotate(60 12 12)"/>'
      '<ellipse cx="12" cy="12" rx="9" ry="4" transform="rotate(120 12 12)"/>';
  static const search =
      '<circle cx="10.6" cy="10.6" r="6.4"/><path d="M15.4 15.4 20.4 20.4"/>';
  static const heart = '<path d="M12 20.4S3.8 15.2 3.8 9.6A4.4 4.4 0 0 1 12 '
      '7.2a4.4 4.4 0 0 1 8.2 2.4c0 5.6-8.2 10.8-8.2 10.8z"/>';
  static const chart =
      '<path d="M4 20h16"/><path d="M6.8 20V13M11.4 20V7.2M16 20v-4.6"/>';
  static const people = '<circle cx="9.4" cy="8.4" r="3.4"/>'
      '<path d="M3.4 19.4a6 6 0 0 1 12 0"/>'
      '<path d="M16.4 5.4a3.4 3.4 0 0 1 0 6M17.6 19.4a6 6 0 0 0-1.6-4.1"/>';
  static const crown = '<path d="M4 8.4l3.6 3.2L12 5.4l4.4 6.2L20 8.4l-1.6 '
      '9.2H5.6z"/><path d="M5.6 19.6h12.8"/>';
  static const spark =
      '<path d="M12 3.4l1.9 5.3 5.3 1.9-5.3 1.9-1.9 5.3-1.9-5.3-5.3-1.9 '
      '5.3-1.9z"/><path d="M18.6 16.4l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 '
      '2.2-.8z"/>';

  /// The row's own three — part084.js:288, :303.
  static const back = '<path d="M19 12H5M12 19l-7-7 7-7"/>';
  static const forward = '<path d="M5 12h14M12 5l7 7-7 7"/>';
  static const close = '<path d="M6 6l12 12M18 6L6 18"/>';
}

/// One step. `go` is optional: "where a step has a door the card carries it;
/// where it is describing something you are already looking at, it does not,
/// because a button that scrolls you three inches is noise" (:76).
class FstStep {
  const FstStep({
    required this.mark,
    required this.title,
    required this.lead,
    required this.points,
    this.goLabel,
    this.goTab,
  });

  final String mark;
  final String title;
  final String lead;

  /// Term and gloss, one line each.
  final List<(String, String)> points;

  final String? goLabel;

  /// Which tab the door opens. The web calls `openSub('practice')` and the
  /// like; this app's five tabs are the nearest real destination, and a step
  /// whose screen does not exist yet gets no door rather than a dead one.
  final int? goTab;
}

/// THE STEPS — part084.js:88-225, verbatim.
///
/// "Player first, then outward: what you practise with, what you practise
/// from, where the words come from, what they do to you, and what the app
/// becomes once it is yours. Every line describes something that is actually
/// in the app — the copy is drawn from the pages themselves, so a step never
/// promises a screen that is not there."
const kFstSteps = <FstStep>[
  FstStep(
    mark: FstMarks.play,
    title: 'The Word Player',
    goLabel: 'Find a word',
    goTab: 1,
    lead: 'Every word opens the same way — one screen, five tabs, no '
        'scrolling.',
    points: [
      ('Listen', 'The word plays, each syllable lighting as it sounds.'),
      ('Record', 'Speak it back and it is scored 0–100.'),
      ('Repeat', 'Count your reps — 3, 7 or 21.'),
      ('Meaning', 'The organ it targets and where the sound comes from.'),
      ('Guide', 'Mouth position, resonance, and the common mistake.'),
    ],
  ),
  FstStep(
    mark: FstMarks.sun,
    title: "Today's Practice",
    goLabel: 'Open practice',
    goTab: 1,
    lead: 'The card at the top of your home already knows the hour.',
    points: [
      ('Five windows', 'Morning, midday, afternoon, evening, night.'),
      ('One tap starts it', 'The words queue up and the session runs itself.'),
      ('It closes itself', 'A healing sentence from everything you practised.'),
    ],
  ),
  FstStep(
    mark: FstMarks.clock,
    title: 'My Routines',
    goLabel: 'Open routines',
    goTab: 1,
    lead: 'Five slots you own — rename any of them, set any time.',
    points: [
      ('The NOW badge', 'Marks whichever routine matches this hour.'),
      ('Words and Library', 'Build the list, tap + to add from what you own.'),
      ('History', 'Every session, its word count and how much you finished.'),
    ],
  ),
  FstStep(
    mark: FstMarks.book,
    title: 'The Reader',
    goLabel: 'Open the Reader',
    goTab: 2,
    lead: 'Meanings and eBooks in one place — the word science, read.',
    points: [
      ('Any meaning', 'Origin, organ and frequency, laid out as a page.'),
      ('It keeps your place', 'So a long piece survives being put down.'),
    ],
  ),
  FstStep(
    mark: FstMarks.bag,
    title: 'The NowssB Store',
    goLabel: 'Enter the store',
    goTab: 3,
    lead: 'Two libraries under one roof. You own what you buy.',
    points: [
      ('Word Library', 'Sounds that heal, each with its organ and frequency.'),
      ('Meaning Library', 'The natural meaning under the dictionary one.'),
      ('Organ targeting', 'Shop by the part of the body, not by the word.'),
    ],
  ),
  FstStep(
    mark: FstMarks.pages,
    title: 'eBooks',
    goLabel: 'Open eBooks',
    goTab: 2,
    lead: 'Where a meaning card gives the answer, an eBook gives the working.',
    points: [
      ('Yours to keep', 'Bought once, read offline, kept in your library.'),
      ('Linked through', 'Every word in them opens in the player.'),
    ],
  ),
  FstStep(
    mark: FstMarks.sig,
    title: 'The Signature',
    goLabel: 'See the Signature',
    goTab: 3,
    lead: 'Your name, in sound — the word science turned on the one word you '
        'answer to.',
    points: [
      ('Your own frequency', 'What your name activates, and where it lands.'),
      ('Made once', 'Generated for you, and then it is yours.'),
    ],
  ),
  FstStep(
    mark: FstMarks.sound,
    title: 'Sound Library',
    goLabel: 'Open the library',
    goTab: 2,
    lead: 'Everything you own, arranged to be listened to.',
    points: [
      ('Sentences', 'Healing sentences built from your words. Tap to play.'),
      ('Words', 'The phonetic breakdown and organ tag on every one.'),
      ('Straight through', 'Tap any word and it opens where you practise it.'),
    ],
  ),
  FstStep(
    mark: FstMarks.atom,
    title: 'Word Science',
    goLabel: 'Open Word Science',
    goTab: 2,
    lead: 'The system underneath all of it. Ten letters, ten organs.',
    points: [
      ('N O W S B A N S I U', 'Every letter maps to a target in the body.'),
      ('Tap a letter', 'Its organ, the science, and the words that show it.'),
    ],
  ),
  FstStep(
    mark: FstMarks.search,
    title: 'Real Meaning',
    goLabel: 'Search a word',
    goTab: 2,
    lead: 'Any word, any language — its origin as a sound, before any '
        'dictionary.',
    points: [
      (
        'Before the dictionary',
        'What it meant as a sound, not as a definition.'
      ),
      (
        'What it activates',
        'The organ it reaches and the frequency it carries.'
      ),
      ('How to say it', 'The correct pronunciation, in the same player.'),
    ],
  ),
  FstStep(
    mark: FstMarks.heart,
    title: 'Personalised Healing',
    goLabel: 'Choose your path',
    goTab: 1,
    lead: 'Words chosen for a body, not for a vocabulary.',
    points: [
      ('Choose your path', 'Female or male, ten health categories each.'),
      (
        'Every category is a set',
        'Chosen for that organ system, not by topic.'
      ),
    ],
  ),
  FstStep(
    mark: FstMarks.chart,
    title: 'My Progress',
    goLabel: 'See your progress',
    goTab: 4,
    lead: 'What the practice has added up to.',
    points: [
      ('Streak and sessions', 'Days in a row, and everything you finished.'),
      ('Mastered words', 'Scored 90 or above three sessions running.'),
      ('Body map', 'Organs light as you practise the words that reach them.'),
    ],
  ),
  FstStep(
    mark: FstMarks.people,
    title: 'NowssB Connect',
    goLabel: 'Open Connect',
    goTab: 0,
    lead: 'The social side — share the practice, find the people doing the '
        'same work.',
    points: [
      ('Follow and react', 'Creators and practitioners further along.'),
      ('Your own space', 'A profile about the practice rather than about you.'),
    ],
  ),
  FstStep(
    mark: FstMarks.crown,
    title: 'Subscription',
    goLabel: 'See the plans',
    goTab: 4,
    lead: 'Every word and every frequency at once, instead of a piece at a '
        'time.',
    points: [
      ('The full library', 'Both stores open, nothing held back.'),
      ('Your Edition', 'The card on your home shows the plan you are on.'),
    ],
  ),
  FstStep(
    mark: FstMarks.spark,
    title: 'Make it yours',
    goLabel: 'Change the hero header',
    goTab: 4,
    lead: 'The last step is the app itself. Almost nothing here is fixed.',
    points: [
      ('Hero header', 'Three ways the top can look — this is one of them.'),
      (
        'Fashion Plus',
        'Turns the app to film. The tiles and cards start '
            'moving.'
      ),
      ('Your layout', 'Sections go on and off, and the home remembers it.'),
    ],
  ),
];

/// `.fst-nav` — part084.js:293. Close, the count, the bar, back, forward.
///
/// EVERY CARD CARRIES ITS OWN. It used to live in the strip under the set,
/// and the strip belongs to cell 0 — which slides out of the deck the moment
/// a step is on, so from step one there was no way forward, back or out
/// (:325).
class FstNav extends StatelessWidget {
  const FstNav({
    super.key,
    required this.index,
    required this.onClose,
    required this.onStep,
  });

  /// The deck's index. 0 is the title card, so it is not step one — "it is
  /// what comes before step one, and the counter says so rather than lying"
  /// (:319).
  final int index;
  final VoidCallback onClose;
  final void Function(int delta) onStep;

  @override
  Widget build(BuildContext context) {
    final n = kFstSteps.length;
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          _Disc(
            mark: FstMarks.close,
            onTap: onClose,
            size: 30,
            label: 'Close the steps',
          ),
          const SizedBox(width: 10),
          // `.fst-count` is a `<b>` and a `<span>`, and they stay two
          // elements here — one rich string reads the same on screen and
          // cannot be found by either half.
          Text(
            index < 1 ? 'Start' : '$index',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            index < 1 ? '$n steps' : 'of $n',
            style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 11),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    const ColoredBox(
                      color: Color(0x1FFFFFFF),
                      child: SizedBox.expand(),
                    ),
                    FractionallySizedBox(
                      widthFactor: (index / n).clamp(0.0, 1.0),
                      child: const ColoredBox(color: NwsbColors.goldLight),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _Disc(
            mark: FstMarks.back,
            label: 'Previous step',
            onTap: index <= 0 ? null : () => onStep(-1),
          ),
          const SizedBox(width: 8),
          _Disc(
            mark: FstMarks.forward,
            label: 'Next step',
            filled: true,
            onTap: index >= n ? null : () => onStep(1),
          ),
        ],
      ),
    );
  }
}

/// `.fst-arrow` / `.fst-x`. Forward is the white one — it is the thing you
/// are meant to press.
class _Disc extends StatelessWidget {
  const _Disc({
    required this.mark,
    required this.label,
    this.onTap,
    this.filled = false,
    this.size = 34,
  });

  final String mark;
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final off = onTap == null;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: off ? 0.32 : 1,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: filled ? Colors.white : const Color(0x14FFFFFF),
              shape: BoxShape.circle,
              border:
                  filled ? null : Border.all(color: const Color(0x2EFFFFFF)),
            ),
            child: Center(
              child: NwsbIcon(
                mark,
                size: size * 0.46,
                strokeWidth: 2,
                color: filled ? NwsbColors.ink : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.fst-cell` — part084.js:238. A step, shaped like a banner.
///
/// "Same outer element as .hs-ban and the same head — a disc with a mark, a
/// light line and a heavy one — because it is running through the same rail
/// and has to belong to it. What is under the head is where they part: a
/// banner has a tablet with a clip in it, and this has words."
class FstCard extends StatelessWidget {
  const FstCard({
    super.key,
    required this.step,
    required this.index,
    required this.onClose,
    required this.onStep,
    this.onGo,
  });

  final FstStep step;

  /// 1-based: the step number, which is also the deck's index.
  final int index;
  final VoidCallback onClose;
  final void Function(int delta) onStep;
  final void Function(int tab)? onGo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The banners' own margin, so the card sits exactly where they sit.
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // RULE 1: black. Nothing moving in the one thing meant to be read.
          color: Colors.black,
          borderRadius: BorderRadius.circular(NwsbRadius.tile),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // `.hs-head` — the disc, then eyebrow over title.
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x24FFFFFF)),
                  ),
                  child: Center(
                    child: NwsbIcon(step.mark,
                        size: 19,
                        strokeWidth: 1.6,
                        color: NwsbColors.goldLight),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Step $index of ${kFstSteps.length}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w600,
                          color: Color(0x8CFFFFFF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // `.fst-body`. The card is a fixed rectangle — the hero's own —
            // and the longest step carries five points, so the body scrolls
            // inside the card rather than the card growing and dragging the
            // whole deck's height with it.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.lead,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 9),
                    for (final p in step.points)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${p.$1} — ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: p.$2,
                                style: const TextStyle(
                                  color: Color(0x99FFFFFF),
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(fontSize: 11.5, height: 1.4),
                        ),
                      ),
                    if (step.goLabel != null && step.goTab != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => onGo?.call(step.goTab!),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0x1FFFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0x40FFFFFF)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  step.goLabel!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const NwsbIcon(FstMarks.forward,
                                    size: 14, strokeWidth: 1.9),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            FstNav(index: index, onClose: onClose, onStep: onStep),
          ],
        ),
      ),
    );
  }
}

/// `.fst-title` — part084.js:403. What the television's screen becomes when
/// the disc is tapped: the wordmark, and "Follow the steps" under it. The
/// tagline, the big word and the picture rail go.
class FstTitle extends StatelessWidget {
  const FstTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 34,
                color: NwsbColors.goldLight,
                height: 1.05,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: 'Nowss',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: 'B',
                  style: TextStyle(fontWeight: FontWeight.w200),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Follow the steps',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w600,
              color: Color(0xB3FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
