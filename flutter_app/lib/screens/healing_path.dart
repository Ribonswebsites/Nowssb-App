import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import 'practice_player.dart';

class HealingPathScreen extends StatefulWidget {
  const HealingPathScreen({super.key, this.initialGender});
  final HealingGender? initialGender;

  @override
  State<HealingPathScreen> createState() => _HealingPathScreenState();
}

enum HealingGender { male, female }

enum _HealingStage { gender, categories, intro, category }

enum _HealingIcon {
  fitness,
  heart,
  skin,
  gut,
  liver,
  mind,
  hormone,
  shield,
  lung,
  kidney,
  bone,
  sleep,
  hair,
  eye,
  explorer,
  power
}

class _HealingCategory {
  const _HealingCategory(
      {required this.name,
      required this.sub,
      required this.organ,
      required this.description,
      required this.icon,
      this.maleImage,
      this.femaleImage,
      this.sharedImage});
  final String name;
  final String sub;
  final String organ;
  final String description;
  final _HealingIcon icon;
  final String? maleImage;
  final String? femaleImage;
  final String? sharedImage;
  String image(HealingGender gender) =>
      (gender == HealingGender.male ? maleImage : femaleImage) ??
      sharedImage ??
      _banner;
}

const _banner = 'assets/healing/01.jpg';
const _maleHero = 'assets/healing/02.jpg';
const _femaleHero = 'assets/healing/03.jpg';
const _malePath = 'assets/healing/04.jpg';
const _femalePath = 'assets/healing/05.jpg';

final _categories = <_HealingCategory>[
  _HealingCategory(
      name: 'Fitness & Muscle',
      sub: 'Build strength through phonetic vibration',
      organ: 'Muscular System',
      description:
          'Words that activate muscular frequency, physical strength, and endurance through correct phonetic resonance.',
      icon: _HealingIcon.fitness,
      sharedImage: 'assets/healing/06.jpg'),
  _HealingCategory(
      name: 'Fitness & Tone',
      sub: 'Toning through phonetic vibration',
      organ: 'Muscular System',
      description:
          'Words that activate toning frequency and body composition through targeted phonetic vibration.',
      icon: _HealingIcon.fitness,
      sharedImage: 'assets/healing/07.jpg'),
  _HealingCategory(
      name: 'Heart Health',
      sub: 'Cardiac resonance & circulation',
      organ: 'Cardiovascular System',
      description:
          'Words that resonate with cardiac frequency, supporting circulation, rhythm, and heart vitality.',
      icon: _HealingIcon.heart,
      maleImage: 'assets/healing/08.jpg',
      femaleImage: 'assets/healing/09.jpg'),
  _HealingCategory(
      name: 'Skin & Glow',
      sub: 'Cellular renewal through sound',
      organ: 'Integumentary System',
      description:
          'Words that stimulate cellular renewal, collagen vibration, and radiant skin through sound science.',
      icon: _HealingIcon.skin,
      maleImage: 'assets/healing/10.jpg',
      femaleImage: 'assets/healing/11.jpg'),
  _HealingCategory(
      name: 'Glass Skin',
      sub: 'Poreless clarity through sound',
      organ: 'Integumentary System',
      description:
          'Words that activate poreless skin clarity, deep hydration and mirror-like luminosity through phonetic sound resonance.',
      icon: _HealingIcon.skin,
      maleImage: 'assets/healing/12.jpg',
      femaleImage: 'assets/healing/13.jpg'),
  _HealingCategory(
      name: 'Gut Health',
      sub: 'Digestive microbiome harmony',
      organ: 'Digestive System',
      description:
          'Words that harmonize the gut microbiome and digestive organs through specific phonetic patterns.',
      icon: _HealingIcon.gut,
      maleImage: 'assets/healing/14.jpg',
      femaleImage: 'assets/healing/15.jpg'),
  _HealingCategory(
      name: 'Liver Detox',
      sub: 'Purification frequency activation',
      organ: 'Hepatic System',
      description:
          'Words that activate detoxification frequency, supporting liver purification and metabolic clarity.',
      icon: _HealingIcon.liver,
      maleImage: 'assets/healing/16.jpg',
      femaleImage: 'assets/healing/17.jpg'),
  _HealingCategory(
      name: 'Mental Clarity',
      sub: 'Focus & cognitive resonance',
      organ: 'Nervous System',
      description:
          'Words that enhance cognitive resonance, focus, and neural clarity through phonetic activation.',
      icon: _HealingIcon.mind,
      maleImage: 'assets/healing/18.jpg',
      femaleImage: 'assets/healing/19.jpg'),
  _HealingCategory(
      name: 'Testosterone & Hormones',
      sub: 'Endocrine balance through syllables',
      organ: 'Endocrine System',
      description:
          'Words that support endocrine balance, testosterone production, and hormonal harmony through syllabic frequency.',
      icon: _HealingIcon.hormone,
      sharedImage: 'assets/healing/20.jpg'),
  _HealingCategory(
      name: 'Hormonal Balance',
      sub: 'Cycle harmony through syllables',
      organ: 'Endocrine System',
      description:
          'Words that support cycle harmony, hormonal regulation, and endocrine balance through sound vibration.',
      icon: _HealingIcon.hormone,
      sharedImage: 'assets/healing/21.jpg'),
  _HealingCategory(
      name: 'Anti-Aging',
      sub: 'Youth frequency restoration',
      organ: 'Integumentary System',
      description:
          'Words that activate cellular regeneration, collagen renewal and youth-frequency restoration through phonetic vibration.',
      icon: _HealingIcon.skin,
      sharedImage: 'assets/healing/22.jpg'),
  _HealingCategory(
      name: 'Dark Spot & Pigmentation',
      sub: 'Even skin tone through sound',
      organ: 'Integumentary System',
      description:
          'Words that balance melanin production and support even skin tone through targeted sound resonance.',
      icon: _HealingIcon.skin,
      sharedImage: 'assets/healing/23.jpg'),
  _HealingCategory(
      name: 'Immunity Boost',
      sub: 'Immune resonance activation',
      organ: 'Immune System',
      description:
          'Words that activate immune resonance, strengthening the body’s defense through phonetic frequency.',
      icon: _HealingIcon.shield,
      maleImage: 'assets/healing/24.jpg',
      femaleImage: 'assets/healing/25.jpg'),
  _HealingCategory(
      name: 'Lung & Breath',
      sub: 'Respiratory phonetic healing',
      organ: 'Respiratory System',
      description:
          'Words that expand breath capacity and activate bronchial pathways through resonant phonetics.',
      icon: _HealingIcon.lung,
      sharedImage: 'assets/healing/26.jpg'),
  _HealingCategory(
      name: 'Kidney & Bladder',
      sub: 'Water-element sound science',
      organ: 'Urinary System',
      description:
          'Words that resonate with water-element organs, supporting kidney filtration and fluid balance.',
      icon: _HealingIcon.kidney,
      sharedImage: 'assets/healing/27.jpg'),
  _HealingCategory(
      name: 'Bone & Joint',
      sub: 'Skeletal frequency strengthening',
      organ: 'Skeletal System',
      description:
          'Words that strengthen bone density and joint resilience through deep phonetic vibration.',
      icon: _HealingIcon.bone,
      maleImage: 'assets/healing/28.jpg',
      femaleImage: 'assets/healing/29.jpg'),
  _HealingCategory(
      name: 'Sleep & Recovery',
      sub: 'Deep rest through word rituals',
      organ: 'Nervous System',
      description:
          'Words that induce deep rest states, cellular recovery, and parasympathetic activation through sound.',
      icon: _HealingIcon.sleep,
      maleImage: 'assets/healing/30.jpg',
      femaleImage: 'assets/healing/31.jpg'),
  _HealingCategory(
      name: 'Hair Health',
      sub: 'Scalp & follicle frequency care',
      organ: 'Follicular System',
      description:
          'Words that stimulate scalp circulation and follicle activation through vibrational sound patterns.',
      icon: _HealingIcon.hair,
      maleImage: 'assets/healing/32.jpg',
      femaleImage: 'assets/healing/33.jpg'),
  _HealingCategory(
      name: 'Eye Sight Health',
      sub: 'Vision frequency activation',
      organ: 'Visual System',
      description:
          'Words that activate ocular frequency, strengthen vision clarity and support eye health through targeted phonetic resonance.',
      icon: _HealingIcon.eye,
      maleImage: 'assets/healing/34.png',
      femaleImage: 'assets/healing/35.png'),
  _HealingCategory(
      name: 'Explorer & Courage',
      sub: 'Words that ignite boldness & direction',
      organ: 'Adrenal · Nervous System',
      description:
          'Words that activate boldness, fearless direction, and the primal drive to move into the unknown.',
      icon: _HealingIcon.explorer,
      sharedImage: 'assets/healing/36.jpg'),
  _HealingCategory(
      name: 'Power & Conquest',
      sub: 'Words that activate dominance & will',
      organ: 'Muscular · Adrenal System',
      description:
          'Words that activate raw dominance, primal authority, and unbreakable will.',
      icon: _HealingIcon.power,
      sharedImage: 'assets/healing/37.jpg'),
  _HealingCategory(
      name: 'Feminine Radiance',
      sub: 'Inner glow & divine confidence',
      organ: 'Endocrine · Skin System',
      description:
          'Words that unlock inner glow, divine confidence and feminine luminosity through deep vibrational sound activation.',
      icon: _HealingIcon.hormone,
      sharedImage: 'assets/healing/38.png'),
];

class _HealingPathScreenState extends State<HealingPathScreen> {
  late _HealingStage _stage;
  HealingGender? _gender;
  _HealingCategory? _category;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender;
    _stage = _gender == null ? _HealingStage.gender : _HealingStage.categories;
  }

  void _choose(HealingGender gender) => setState(() {
        _gender = gender;
        _stage = _HealingStage.categories;
      });
  void _back() {
    if (_stage == _HealingStage.category) {
      setState(() {
        _stage = _HealingStage.categories;
        _category = null;
      });
      return;
    }
    if (_stage == _HealingStage.intro) {
      setState(() {
        _stage = _HealingStage.categories;
        _category = null;
      });
      return;
    }
    if (_stage == _HealingStage.categories) {
      setState(() => _stage = _HealingStage.gender);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF060C18),
        body: Stack(children: [
          Positioned.fill(
              child: _Background(
                  image: _stage == _HealingStage.gender
                      ? 'assets/video/healing-path-bg-poster.webp'
                      : _stage == _HealingStage.category
                          ? _category!.image(_gender!)
                          : (_gender == HealingGender.male
                              ? _maleHero
                              : _femaleHero))),
          SafeArea(
              child: Column(children: [
            _Header(
                title: _stage == _HealingStage.gender
                    ? 'Healing Path'
                    : _stage == _HealingStage.categories
                        ? '${_gender == HealingGender.male ? 'Male' : 'Female'} · Healing'
                        : _category!.name,
                onBack: _back),
            Expanded(
                child: _stage == _HealingStage.gender
                    ? _genderPage()
                    : _stage == _HealingStage.categories
                        ? _categoriesPage()
                        : _stage == _HealingStage.intro
                            ? _categoryIntroPage()
                            : _categoryPage()),
          ])),
        ]));
  }

  Widget _genderPage() =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 42, 20, 40), children: [
        const Text('PERSONALISED FOR YOU',
            style: TextStyle(
                color: Color(0xB3E8D5A3), fontSize: 11, letterSpacing: 2.4)),
        const SizedBox(height: 12),
        const Text('Choose Your\nPath',
            style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                height: .98,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 32),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(.08),
                border: Border.all(color: Colors.white.withOpacity(.15)),
                borderRadius: BorderRadius.circular(26)),
            child: Column(children: [
              _GenderCard(
                  gender: HealingGender.male,
                  image: _malePath,
                  title: 'Male',
                  subtitle: 'Strength · Vitality',
                  onTap: () => _choose(HealingGender.male)),
              const SizedBox(height: 12),
              _GenderCard(
                  gender: HealingGender.female,
                  image: _femalePath,
                  title: 'Female',
                  subtitle: 'Balance · Radiance',
                  onTap: () => _choose(HealingGender.female)),
            ])),
        const SizedBox(height: 12),
        const Center(
            child: Text('Tap to explore your categories',
                style: TextStyle(
                    color: Color(0x4DFFFFFF), fontSize: 10, letterSpacing: 1))),
      ]);

  Widget _categoriesPage() {
    final gender = _gender!;
    final list = _categories
        .where((c) => gender == HealingGender.male
            ? !{
                'Fitness & Tone',
                'Hormonal Balance',
                'Anti-Aging',
                'Dark Spot & Pigmentation',
                'Feminine Radiance',
              }.contains(c.name)
            : c.name != 'Fitness & Muscle' &&
                c.name != 'Testosterone & Hormones' &&
                c.name != 'Explorer & Courage' &&
                c.name != 'Power & Conquest' &&
                c.name != 'Lung & Breath' &&
                c.name != 'Kidney & Bladder')
        .toList();
    return ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 36),
        children: [
          _CategoryHero(gender: gender),
          const SizedBox(height: 20),
          const Text('CHOOSE YOUR FOCUS',
              style: TextStyle(
                  color: Color(0xB3E8D5A3), fontSize: 11, letterSpacing: 2.2)),
          const SizedBox(height: 12),
          ...list.map((category) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CategoryCard(
                  category: category,
                  gender: gender,
                  onTap: () => setState(() {
                        _category = category;
                        _tab = 0;
                        _stage = _HealingStage.intro;
                      })))),
        ]);
  }

  Widget _categoryIntroPage() {
    final category = _category!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 36),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 360,
            child: Stack(fit: StackFit.expand, children: [
              Image.network(category.image(_gender!), fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xF0060C18)],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.organ.toUpperCase(),
                        style: const TextStyle(
                            color: Color(0xB3E8D5A3),
                            fontSize: 10,
                            letterSpacing: 1.8)),
                    const SizedBox(height: 8),
                    Text(category.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            height: 1.05,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(category.description,
                        style: const TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontSize: 13,
                            height: 1.5)),
                  ],
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _stage = _HealingStage.category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFE8D5A3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tap to enter',
                      style: TextStyle(
                          color: Color(0x99060C18),
                          fontSize: 10,
                          letterSpacing: 1.6)),
                  const SizedBox(height: 4),
                  Text('Enter ${category.name}',
                      style: const TextStyle(
                          color: Color(0xFF060C18),
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                ]),
                const Icon(Icons.arrow_forward,
                    color: Color(0xFF060C18), size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryPage() {
    final category = _category!;
    final words = ContentStore.instance.library
        .where((w) =>
            w.categories.contains(category.name) &&
            (w.gender.isEmpty ||
                w.gender == 'both' ||
                w.gender == (_gender == HealingGender.male ? 'M' : 'F')))
        .toList();
    return Stack(children: [
      ListView(padding: const EdgeInsets.only(bottom: 110), children: [
        SizedBox(
            height: 220,
            child: Stack(fit: StackFit.expand, children: [
              Image.network(_banner,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox()),
              const DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xD9060C18)]))),
              Positioned(
                  left: 18,
                  right: 18,
                  bottom: 14,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.organ.toUpperCase(),
                            style: const TextStyle(
                                color: Color(0xB3E8D5A3),
                                fontSize: 10,
                                letterSpacing: 1.8)),
                        const SizedBox(height: 6),
                        Text(category.description,
                            style: const TextStyle(
                                color: Color(0xD9FFFFFF),
                                fontSize: 13,
                                height: 1.45))
                      ]))
            ])),
        Row(children: [
          _tabButton('Words', 0),
          _tabButton('About', 1),
          _tabButton('Sessions', 2)
        ]),
        Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: _tab == 0
                ? _wordsTab(words)
                : _tab == 1
                    ? _aboutTab(category)
                    : _sessionsTab()),
      ]),
      Positioned(
          left: 18,
          right: 18,
          bottom: 16,
          child: FilledButton(
              onPressed: words.isEmpty
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PracticePlayerScreen(
                          words: words, title: category.name))),
              style: FilledButton.styleFrom(
                  backgroundColor: NwsbColors.goldLight,
                  foregroundColor: const Color(0xFF07101F),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: Text(words.isEmpty
                  ? 'Words Coming Soon'
                  : 'Start Session · ${words.length} Words'))),
    ]);
  }

  Widget _tabButton(String label, int index) => Expanded(
      child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: _tab == index
                              ? NwsbColors.goldLight
                              : Colors.white12,
                          width: _tab == index ? 2 : 1))),
              child: Center(
                  child: Text(label,
                      style: TextStyle(
                          color: _tab == index ? Colors.white : Colors.white54,
                          fontSize: 13,
                          fontWeight: _tab == index
                              ? FontWeight.w600
                              : FontWeight.w400))))));
  Widget _wordsTab(List<Word> words) => words.isEmpty
      ? const _EmptyState(
          title: 'Words being crafted',
          body:
              'The client is personally crafting words for this category. They will appear here once ready.')
      : Column(
          children: words
              .map((word) => ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                  title: Text(word.word,
                      style: const TextStyle(
                          color: NwsbColors.goldLight,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  subtitle: Text('${word.phonetic}  ·  ${word.organ}',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PracticePlayerScreen(
                          words: words, title: categoryName(words, word))))))
              .toList());
  String categoryName(List<Word> _, Word word) =>
      word.categories.isNotEmpty ? word.categories.first : 'Practice';
  Widget _aboutTab(_HealingCategory category) => Column(children: [
        const _InfoCard(label: 'WHAT THIS TARGETS', color: Color(0xFFE8D5A3)),
        _InfoCard(
            label: 'ORGAN SYSTEM',
            value: '',
            body: category.organ,
            color: Color(0xFFC8E8F5)),
        _InfoCard(
            label: 'HOW IT WORKS',
            value: '',
            body:
                'Each word in this category carries a natural origin vibration tuned to this system. Correct pronunciation — with the exact mouth position, breath, and resonance — creates the specific frequency that activates and supports these organs.',
            color: Colors.white54,
            last: true,
            firstBody: category.description)
      ]);
  Widget _sessionsTab() => const _EmptyState(
      title: 'No sessions yet',
      body:
          'Complete your first session in this category and your history will appear here.');
}

class _Background extends StatelessWidget {
  const _Background({required this.image});
  final String image;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          color: const Color(0xFF060C18),
          image: DecorationImage(
              image: image.startsWith('assets/')
                  ? AssetImage(image)
                  : NetworkImage(image),
              fit: BoxFit.cover,
              opacity: .17)));
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Row(children: [
        IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white)),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700))
      ]));
}

class _GenderCard extends StatelessWidget {
  const _GenderCard(
      {required this.gender,
      required this.image,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final HealingGender gender;
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: SizedBox(
          height: 150,
          child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(fit: StackFit.expand, children: [
                Image.network(image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFF121A2A))),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xE6060C18)]))),
                const Positioned(
                    left: 16,
                    right: 16,
                    bottom: 15,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('For You',
                              style: TextStyle(
                                  color: Color(0xFFE8D5A3),
                                  fontSize: 10,
                                  letterSpacing: 1.6)),
                          Icon(Icons.arrow_forward,
                              color: Colors.white70, size: 17)
                        ])),
                Positioned(
                    left: 16,
                    bottom: 38,
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w700))),
                Positioned(
                    left: 17,
                    bottom: 17,
                    child: Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)))
              ]))));
}

class _CategoryHero extends StatelessWidget {
  const _CategoryHero({required this.gender});
  final HealingGender gender;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 220,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(fit: StackFit.expand, children: [
            Image.network(
                gender == HealingGender.male ? _maleHero : _femaleHero,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox()),
            const DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xE6060C18)]))),
            Positioned(
                left: 16,
                bottom: 16,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'SHABDAPATHY · ${gender == HealingGender.male ? 'MALE' : 'FEMALE'}',
                          style: const TextStyle(
                              color: Color(0xB3E8D5A3),
                              fontSize: 10,
                              letterSpacing: 1.7)),
                      const SizedBox(height: 6),
                      Text(
                          gender == HealingGender.male
                              ? 'Strength &\nVitality'
                              : 'Balance &\nRadiance',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              height: .94,
                              fontWeight: FontWeight.w800))
                    ]))
          ])));
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard(
      {required this.category, required this.gender, required this.onTap});
  final _HealingCategory category;
  final HealingGender gender;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(.045),
              border: Border.all(color: Colors.white.withOpacity(.11)),
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: const Color(0x14E8D5A3),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(_icon(category.icon),
                    color: NwsbColors.goldLight, size: 20)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(category.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(category.sub,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11))
                ])),
            const Icon(Icons.arrow_forward, color: Colors.white54, size: 17)
          ])));
}

IconData _icon(_HealingIcon icon) => switch (icon) {
      _HealingIcon.fitness => Icons.fitness_center,
      _HealingIcon.heart => Icons.favorite_border,
      _HealingIcon.skin => Icons.wb_sunny_outlined,
      _HealingIcon.gut => Icons.blur_circular,
      _HealingIcon.liver => Icons.auto_awesome,
      _HealingIcon.mind => Icons.psychology_outlined,
      _HealingIcon.hormone => Icons.bolt_outlined,
      _HealingIcon.shield => Icons.shield_outlined,
      _HealingIcon.lung => Icons.air,
      _HealingIcon.kidney => Icons.water_drop_outlined,
      _HealingIcon.bone => Icons.accessibility_new,
      _HealingIcon.sleep => Icons.nightlight_outlined,
      _HealingIcon.hair => Icons.auto_fix_high,
      _HealingIcon.eye => Icons.visibility_outlined,
      _HealingIcon.explorer => Icons.public,
      _HealingIcon.power => Icons.star_border
    };

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.label,
      required this.color,
      this.body = '',
      this.value = '',
      this.last = false,
      this.firstBody});
  final String label;
  final String body;
  final String value;
  final Color color;
  final bool last;
  final String? firstBody;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: last ? 0 : 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(.055),
          border: Border.all(color: color.withOpacity(.15)),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: color.withOpacity(.7),
                fontSize: 10,
                letterSpacing: 1.7)),
        const SizedBox(height: 8),
        Text(firstBody ?? body,
            style: const TextStyle(
                color: Color(0xD9FFFFFF), fontSize: 14, height: 1.6))
      ]));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.access_time, color: Colors.white38, size: 38),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(body,
            style: const TextStyle(
                color: Colors.white54, fontSize: 13, height: 1.6))
      ]));
}
