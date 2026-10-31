/// Normal home v3: the calm rebuild. Every section the brief did not ask to
/// keep is drawn here, new, in one quiet look: soft paper cards, a still
/// photo or a slow looping film behind them, and a gentle breathing ring.
/// Each card opens the same screen its old section opened, and reads the
/// same live data (practice progress, the word library, the economy mirror).
///
/// Media sources and licences: /workspace/team-plan/research/home-normal/MEDIA-LICENSES.md
library;

import '../../widgets/editeaze.dart';
import 'package:nowssb/data/day_part.dart';
import 'package:nowssb/data/today_ritual.dart';
import 'package:nowssb/widgets/concept/ritual_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'neomorphic_dashboard.dart' show FocusBlob;

import '../../admin/template/editable.dart' show EditableLabel;
import '../../data/content.dart';
import '../../data/firebase.dart';
import '../../data/models.dart';
import '../../data/practice_progress.dart';
import '../../features/circle/circle_screen.dart';
import '../../features/economy/economy_api.dart';
import '../../features/programs/partner_program.dart';
import '../../features/programs/reference_program.dart';
import '../../features/progress/progress_popup.dart';
import '../../features/vault/vault_screen.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../nwsb_sign_in_sheet.dart';
import '../practice.dart';
import 'sections_top.dart' show nmGreetHello;

const _ink = Color(0xFF26302C);
const _soft = Color(0xFF5E6B66);
const _sage = Color(0xFF6E8B7D);
const _paper = Color(0xFFF4F1EA);
const _mist = Color(0xFFE6ECE7);

bool _still(BuildContext c) =>
    (MediaQuery.maybeDisableAnimationsOf(c) ?? false) ||
    WidgetsBinding.instance.runtimeType.toString().contains('Test');

void _push(BuildContext c, Widget page) =>
    Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page));

Widget _lottie(BuildContext c, String asset, double size) => Lottie.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
      animate: !_still(c),
      errorBuilder: (_, __, ___) => SizedBox.square(dimension: size),
    );

const _h = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _ink, height: 1.2, letterSpacing: -.2);
const _sub = TextStyle(fontSize: 13.5, color: _soft, height: 1.35);
const _eyebrow = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _sage, letterSpacing: 1.6);

/// A slow in-and-out ring: the only motion besides the films and the Lottie.
class _Breathe extends StatefulWidget {
  const _Breathe({required this.child});
  final Widget child;
  @override
  State<_Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<_Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still(context)) {
      _c.stop();
      _c.value = .5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = Curves.easeInOut.transform(_c.value);
          return Transform.scale(scale: .94 + .08 * t, child: Opacity(opacity: .75 + .25 * t, child: child));
        },
        child: widget.child,
      );
}

/// The round sage button every calm card ends with.
class CalmGo extends StatelessWidget {
  const CalmGo({super.key, required this.label, required this.onTap, this.light = false});
  final String label;
  final VoidCallback? onTap;
  final bool light;
  @override
  Widget build(BuildContext context) => Material(
        color: light ? Colors.white : _ink,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(label,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: light ? _ink : Colors.white)),
          ),
        ),
      );
}

/// Paper card with optional photo or film behind a soft wash.
class _Calm extends StatelessWidget {
  const _Calm({
    super.key,
    required this.child,
    this.image,
    this.video,
    this.slot,
    this.dark = false,
    this.onTap,
    this.pad = const EdgeInsets.fromLTRB(20, 8, 20, 16),
  });
  final Widget child;
  final String? image;
  final String? video;
  final String? slot;
  final bool dark;
  final VoidCallback? onTap;
  final EdgeInsets pad;

  @override
  Widget build(BuildContext context) {
    final media = video != null
        ? NwsbVideo(asset: video!, priority: ClipPriority.decoration, slot: slot ?? 'calm_v3')
        : image != null
            ? Image.asset(image!, fit: BoxFit.cover, cacheWidth: 720)
            : null;
    return Padding(
      padding: pad,
      child: Material(
        color: dark ? _ink : _paper,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(children: [
            if (media != null) Positioned.fill(child: media),
            if (media != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dark
                          ? const [Color(0xCC111A16), Color(0x66111A16)]
                          : const [Color(0xF2F4F1EA), Color(0x99F4F1EA)],
                    ),
                  ),
                ),
              ),
            Padding(padding: const EdgeInsets.all(20), child: child),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────────── greet ─────────────────────────────

class CalmGreeting extends StatelessWidget {
  const CalmGreeting({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => _Calm(
        key: const ValueKey('cv3-greeting'),
        video: 'assets/video/nm-calm-clouds.mp4',
        slot: 'calm_v3.CalmGreeting',
        pad: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nmGreetHello(), style: const TextStyle(fontSize: 16, color: _soft)),
              const SizedBox(height: 2),
              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _ink, height: 1.15)),
              const SizedBox(height: 6),
              const EditableLabel('normal_sections_top.NmGreeting', "Ready for today's healing practice?", style: _sub),
            ]),
          ),
          const SizedBox(width: 8),
          Column(mainAxisSize: MainAxisSize.min, children: [
            _lottie(context, 'assets/home/nm-calm-breath.json', 72),
            const SizedBox(height: 4),
            const DecoratedBox(
              decoration: BoxDecoration(color: _ink, shape: BoxShape.circle),
              child: ProgressIconButton(),
            ),
          ]),
        ]),
      );
}

// ───────────────────────────── search ─────────────────────────────

class CalmSearch extends StatelessWidget {
  const CalmSearch({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        key: const ValueKey('cv3-search'),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Material(
          color: _mist,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(children: [
                Icon(Icons.spa_outlined, color: _sage, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Search words and meanings', style: TextStyle(fontSize: 15, color: _soft))),
                Icon(Icons.search_rounded, color: _ink, size: 22),
              ]),
            ),
          ),
        ),
      );
}

// ───────────────────────────── dashboard ─────────────────────────────

/// Meditation photos for the Normal home hero (Pexels licence, see CREDITS.md).
/// Hero cards: solid colour + a studio photo cut cleanly onto it.
const kEzHeroLooks = <(Color, String)>[
  (Color(0xFFF47A3C), 'assets/home/ez/ez-hero-orange.webp'),
  (Color(0xFF1F9E8F), 'assets/home/ez/ez-hero-teal.webp'),
  (Color(0xFFE9B23A), 'assets/home/ez/ez-hero-yellow.webp'),
  (Color(0xFFEE6C5E), 'assets/home/ez/ez-hero-coral.webp'),
  (Color(0xFF2F4F8F), 'assets/home/ez/ez-hero-blue.webp'),
];

typedef CalmLauncher = void Function(List<Word> words, String title);

/// The Today card. All its data and both actions come from
/// [TodayRitualModel]; this is only the look.
class CalmToday extends StatefulWidget {
  const CalmToday({super.key, this.onStart, this.onProgress});
  final CalmLauncher? onStart;
  final VoidCallback? onProgress;

  @override
  State<CalmToday> createState() => _CalmTodayState();
}

class _CalmTodayState extends State<CalmToday> {
  static const _likedWordsKey = 'nwsb_liked_words';
  late final TodayRitualModel _model = TodayRitualModel(
    onBegin: (words, title) => widget.onStart?.call(words, title),
    onSeeProgress: () => widget.onProgress?.call(),
  );
  Set<String> _liked = const {};

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() {
          _liked = (p.getStringList(_likedWordsKey) ?? const []).toSet();
          _sessions = (p.getStringList(_savedSessionsKey) ?? const []).toSet();
        });
      }
    });
  }

  static const _savedSessionsKey = 'nwsb_saved_sessions';
  Set<String> _sessions = const {};

  /// Saves (or unsaves) a word when the card has one, otherwise the session
  /// itself, so Save works for every user, and confirms either way.
  Future<void> _toggleSave({String? word, required String session}) async {
    final isWord = word != null;
    final key = isWord ? _likedWordsKey : _savedSessionsKey;
    final item = word ?? session;
    final next = {...(isWord ? _liked : _sessions)};
    final removed = next.remove(item);
    if (!removed) next.add(item);
    setState(() => isWord ? _liked = next : _sessions = next);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: const ValueKey('cv3-hero-saved'),
        content: Text(removed ? 'Removed "$item" from saved' : 'Saved "$item"'),
        duration: const Duration(seconds: 2),
      ));
    final p = await SharedPreferences.getInstance();
    await p.setStringList(key, next.toList());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _model,
        builder: (context, _) {
          final r = _model.value;
          final words = r.words.take(kEzHeroLooks.length).toList();
          return Padding(
            key: const ValueKey('cv3-today'),
            padding: const EdgeInsets.only(bottom: 8),
            child: EzHeroCarousel(
              key: const ValueKey('cv3-ez-hero'),
              onOpen: (_) => _model.begin(),
              cards: [
                for (var i = 0; i < kEzHeroLooks.length; i++)
                  EzHeroCard(
                    color: kEzHeroLooks[i].$1,
                    image: kEzHeroLooks[i].$2,
                    title: r.title,
                    subtitle: words.isEmpty ? null : words[i % words.length].word,
                    saved: words.isEmpty ? _sessions.contains(r.title) : _liked.contains(words[i % words.length].word),
                    onSave: () => _toggleSave(word: words.isEmpty ? null : words[i % words.length].word, session: r.title),
                  ),
              ],
            ),
          );
        },
      );
}

/// The shared day part (dayPartFor / DayClock) as the card's time.
RitualTime ritualTimeOf(DayPart p) => switch (p) {
      DayPart.morning => RitualTime.morning,
      DayPart.afternoon => RitualTime.afternoon,
      DayPart.evening => RitualTime.evening,
      DayPart.night => RitualTime.night,
    };

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xCCFFFFFF), borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$value ', style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
            TextSpan(text: label, style: const TextStyle(color: _soft)),
          ]), style: const TextStyle(fontSize: 13.5)),
        ),
      );
}

// ───────────────────────────── herovid ─────────────────────────────

class CalmStreakFilm extends StatelessWidget {
  const CalmStreakFilm({super.key, this.onTap, this.onStoreTap});
  final VoidCallback? onTap;
  final VoidCallback? onStoreTap;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PracticeProgress.instance,
        builder: (context, _) {
          final s = PracticeProgress.instance.streak;
          return _Calm(
            key: const ValueKey('cv3-streak'),
            video: 'assets/video/nm-calm-stream.mp4',
            slot: 'calm_v3.CalmStreakFilm',
            dark: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SIT BY THE WATER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFBFD3C8), letterSpacing: 1.6)),
              const SizedBox(height: 10),
              Text(s > 0 ? 'Day $s of your streak' : 'Start building your streak today',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, height: 1.2)),
              const SizedBox(height: 6),
              const Text('Practice daily to keep it alive, and unlock exclusive offers.',
                  style: TextStyle(fontSize: 13.5, color: Color(0xE6FFFFFF), height: 1.35)),
              const SizedBox(height: 16),
              Wrap(spacing: 10, runSpacing: 10, children: [
                CalmGo(label: 'Practice now', light: true, onTap: onTap),
                CalmGo(label: 'Exclusive offers', onTap: onStoreTap),
              ]),
            ]),
          );
        },
      );
}

// ───────────────────────────── store ─────────────────────────────

class CalmStoreAndEarn extends StatelessWidget {
  const CalmStoreAndEarn({super.key, required this.onStore});
  final VoidCallback onStore;
  @override
  Widget build(BuildContext context) {
    final spec = SplitPromoExtras.at(8, onTap: onStore);
    return Column(key: const ValueKey('cv3-store'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Calm(
        onTap: onStore,
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('MEANING STORE', style: _eyebrow),
              const SizedBox(height: 8),
              Text(spec.title.replaceAll('\n', ' '), style: _h),
              const SizedBox(height: 14),
              CalmGo(label: spec.cta, onTap: onStore),
            ]),
          ),
          const SizedBox(width: 12),
          _Breathe(
            child: ClipOval(
              child: SizedBox.square(
                dimension: 92,
                child: Image.asset(spec.art, fit: BoxFit.cover, cacheWidth: 300,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: _mist)),
              ),
            ),
          ),
        ]),
      ),
      _Calm(
        onTap: () => _push(context, const CircleScreen()),
        image: 'assets/home/nm-calm-zen-stone.webp',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('NOWSSB EARN', style: _eyebrow),
          const SizedBox(height: 8),
          const Text('Your share of the net.', style: _h),
          const SizedBox(height: 4),
          const Text('Commission on net. Two levels. Never a third.', style: _sub),
          const SizedBox(height: 14),
          CalmGo(label: 'Join today', onTap: () => _push(context, const CircleScreen())),
        ]),
      ),
    ]);
  }
}

// ───────────────────────────── reader + rewards ─────────────────────────────

class CalmReaderRewards extends StatelessWidget {
  const CalmReaderRewards({super.key, required this.onReader});
  final VoidCallback onReader;
  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('cv3-reader'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Calm(
            onTap: onReader,
            image: 'assets/home/nm-calm-calm-waters.webp',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('NOWSSB READER', style: _eyebrow),
              const SizedBox(height: 8),
              const Text('Read every meaning, and every eBook.', style: _h),
              const SizedBox(height: 4),
              const Text('Meanings and eBooks, in one place', style: _sub),
              const SizedBox(height: 14),
              CalmGo(label: 'Open Reader', onTap: onReader),
            ]),
          ),
          ListenableBuilder(
            listenable: EconomyMirror.instance,
            builder: (context, _) {
              final w = EconomyMirror.instance;
              final signedIn = NwsbFirebase.ready && w.uid != null;
              final nextChest = 40 - (w.coins % 40);
              return _Calm(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('NOWSSB REWARDS', style: _eyebrow),
                  const SizedBox(height: 8),
                  if (!signedIn) ...[
                    const Text('Sign in to see your rewards', style: _h),
                    const SizedBox(height: 4),
                    const Text('Your coins and streak stay on your account', style: _sub),
                    const SizedBox(height: 14),
                    CalmGo(label: 'Sign in', onTap: () => NwsbSignInPage.open(context)),
                  ] else ...[
                    Text('${w.coins} coins', style: _h),
                    const SizedBox(height: 4),
                    Text('Streak ${w.streak} · $nextChest coins to the next chest', style: _sub),
                    const SizedBox(height: 14),
                    CalmGo(label: 'Open rewards', onTap: () => _push(context, const VaultScreen())),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: _mist),
                  const SizedBox(height: 12),
                  _Row(
                    icon: Icons.favorite_outline_rounded,
                    title: 'Invite a friend',
                    sub: 'Share your link. Your friend gets a discount; you earn when they buy for real.',
                    onTap: () => _push(context, const ReferenceProgramPage()),
                  ),
                ]),
              );
            },
          ),
        ],
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.sub, this.onTap});
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: _sage),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 13, color: _soft, height: 1.35)),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10, left: 6),
              child: Icon(Icons.arrow_forward_rounded, size: 18, color: _sage),
            ),
          ]),
        ),
      );
}

// ───────────────────────────── trendwd ─────────────────────────────

class CalmTrending extends StatelessWidget {
  const CalmTrending({super.key, required this.onTap});
  final VoidCallback onTap;
  static const _places = [
    'assets/home/nm-calm-lotus.webp',
    'assets/home/nm-calm-calm-waters.webp',
    'assets/home/nm-calm-zen-stone.webp',
    'assets/home/nm-calm-mountain-reflection.webp',
  ];
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: ContentStore.instance,
        builder: (context, _) {
          final words = ContentStore.instance.library;
          final word = words.isEmpty ? '' : words[(DateTime.now().day + 3) % words.length].word;
          return _Calm(
            key: const ValueKey('cv3-trending'),
            onTap: onTap,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TRENDING NOW', style: _eyebrow),
              const SizedBox(height: 8),
              if (word.isNotEmpty) Text(word, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: _ink, letterSpacing: 1)),
              const SizedBox(height: 4),
              const Text('See which words are healing the most people right now', style: _sub),
              const SizedBox(height: 14),
              SizedBox(
                height: 84,
                child: Row(children: [
                  for (var i = 0; i < _places.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox.expand(child: Image.asset(_places[i], fit: BoxFit.cover, cacheWidth: 300)),
                      ),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 14),
              CalmGo(label: 'Open the library', onTap: onTap),
            ]),
          );
        },
      );
}

// ───────────────────────────── feed ─────────────────────────────

class CalmCommunity extends StatelessWidget {
  const CalmCommunity({super.key, required this.onTap});
  final VoidCallback onTap;
  static const _rows = [
    (Icons.dynamic_feed_outlined, 'Community Feed', 'Share your daily practice with the world'),
    (Icons.auto_awesome_outlined, 'Stories', 'Drop 24-hour frequency moments'),
    (Icons.play_circle_outline_rounded, 'Reels', 'Watch & post short healing reels'),
    (Icons.people_outline_rounded, 'Discover Creators', 'Find people worth following'),
    (Icons.verified_outlined, 'Verified', 'Earn your NowssB check-mark'),
  ];
  @override
  Widget build(BuildContext context) => _Calm(
        key: const ValueKey('cv3-community'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('NOWSSB CONNECT', style: _eyebrow),
          const SizedBox(height: 8),
          const Text('Practise together', style: _h),
          const SizedBox(height: 10),
          for (final r in _rows) _Row(icon: r.$1, title: r.$2, sub: r.$3, onTap: onTap),
        ]),
      );
}

// ───────────────────────────── quickrow ─────────────────────────────

class CalmQuickRow extends StatelessWidget {
  const CalmQuickRow({super.key, this.onCart, this.onWishlist, this.onOrders});
  final VoidCallback? onCart;
  final VoidCallback? onWishlist;
  final VoidCallback? onOrders;
  @override
  Widget build(BuildContext context) => _Calm(
        key: const ValueKey('cv3-quick'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('EVERYTHING YOU OWN', style: _eyebrow),
          const SizedBox(height: 8),
          const Text('On one screen', style: _h),
          const SizedBox(height: 10),
          _Row(icon: Icons.shopping_bag_outlined, title: 'Your Cart', sub: "Everything you're ready to buy", onTap: onCart),
          _Row(icon: Icons.bookmark_border_rounded, title: 'Your Wishlist', sub: 'The words you are saving for later', onTap: onWishlist),
          _Row(icon: Icons.receipt_long_outlined, title: 'Your Orders', sub: 'Everything you have unlocked so far', onTap: onOrders),
        ]),
      );
}

// ───────────────────────────── edition ─────────────────────────────

class CalmMembership extends StatelessWidget {
  const CalmMembership({super.key, required this.onEdition});
  final VoidCallback onEdition;
  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('cv3-edition'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Calm(
            onTap: onEdition,
            image: 'assets/home/nm-calm-mountain-reflection.webp',
            dark: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('FREE PLAN · UPGRADE ANY TIME',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFBFD3C8), letterSpacing: 1.6)),
              const SizedBox(height: 8),
              const Text('NowssB Edition', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Get your subscription today', style: TextStyle(fontSize: 13.5, color: Color(0xE6FFFFFF))),
              const SizedBox(height: 14),
              CalmGo(label: 'Join NowssB', light: true, onTap: onEdition),
            ]),
          ),
          ListenableBuilder(
            listenable: EconomyMirror.instance,
            builder: (context, _) => _Calm(
              child: _Row(
                icon: Icons.workspace_premium_outlined,
                title: '${EconomyMirror.instance.partnerPoints} partner points',
                sub: 'Spark · Glow · Radiant. Points come only from real purchases through your links.',
                onTap: () => _push(context, const PartnerProgramPage()),
              ),
            ),
          ),
        ],
      );
}

// ───────────────────────────── ebooks ─────────────────────────────

class CalmEbooks extends StatelessWidget {
  const CalmEbooks({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _Calm(
        key: const ValueKey('cv3-ebooks'),
        onTap: onTap,
        child: Row(children: [
          _Breathe(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.menu_book_outlined, color: _sage, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('NowssB eBooks', style: _h),
              const SizedBox(height: 4),
              const Text('Word science and sound healing, read anywhere.', style: _sub),
              const SizedBox(height: 12),
              CalmGo(label: 'Browse eBooks', onTap: onTap),
            ]),
          ),
        ]),
      );
}

// ───────────────────────────── healing ─────────────────────────────

class CalmHealing extends StatelessWidget {
  const CalmHealing({super.key, this.onTap, this.onFemale, this.onMale});
  final VoidCallback? onTap;
  final VoidCallback? onFemale;
  final VoidCallback? onMale;
  @override
  Widget build(BuildContext context) => _Calm(
        key: const ValueKey('cv3-healing'),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('HEALTH JOURNEY', style: _eyebrow),
          const SizedBox(height: 8),
          const Text('Customise your healing path', style: _h),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: [
            CalmGo(label: 'Her path', onTap: onFemale),
            CalmGo(label: 'His path', light: true, onTap: onMale),
          ]),
        ]),
      );
}

// ───────────────────────────── fashsw ─────────────────────────────

class CalmFashionSwitch extends StatelessWidget {
  const CalmFashionSwitch({super.key, this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => _Calm(
        key: const ValueKey('cv3-fashion'),
        dark: true,
        onTap: onTap,
        child: Row(children: [
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DISCOVER THE EXPERIENCE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFBFD3C8), letterSpacing: 1.6)),
              SizedBox(height: 8),
              Text('Fashion Mode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
              SizedBox(height: 4),
              Text('Dark · Cinematic · Editorial', style: TextStyle(fontSize: 13.5, color: Color(0xE6FFFFFF))),
            ]),
          ),
          const SizedBox(width: 12),
          _Breathe(
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: _ink),
            ),
          ),
        ]),
      );
}

// ───────────────────────────── footer ─────────────────────────────

class CalmFooter extends StatelessWidget {
  const CalmFooter({super.key, required this.onLink});
  final void Function(String key) onLink;
  static const _links = [
    ('About', 'about'),
    ('Word Science', 'word-science'),
    ('Sound Library', 'sound-library'),
    ('Meaning Store', 'meaning-store'),
    ('Practice', 'practice'),
    ('Profile', 'profile'),
  ];
  @override
  Widget build(BuildContext context) => Padding(
        key: const ValueKey('cv3-footer'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Divider(color: _mist),
          const SizedBox(height: 16),
          const Text('NowssB', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w300, color: _ink, letterSpacing: 4)),
          const SizedBox(height: 4),
          const Text('Different words. One root.', textAlign: TextAlign.center, style: _sub),
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
            for (final l in _links)
              ActionChip(
                label: Text(l.$1, style: const TextStyle(fontSize: 13, color: _ink)),
                backgroundColor: _paper,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                onPressed: () => onLink(l.$2),
              ),
          ]),
        ]),
      );
}

