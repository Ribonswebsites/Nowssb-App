/// Profile — who you are, and what the app is currently doing.
///
/// The account half is deliberately honest rather than decorative: it says
/// whether Firebase actually came up, whether content is live or bundled, and
/// how many words are loaded. On the website those answers are buried in a
/// console; here they are the first thing on the page, because "is this
/// showing me live content or the copy it shipped with" is a question with a
/// real answer and no way to guess it from the outside.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/firebase.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/page_shell.dart';
import 'fashion_plus.dart';
import 'sound_library.dart';
import 'widgets_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_onContent);
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    super.dispose();
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = ContentStore.instance;
    final live = NwsbFirebase.ready;

    return PageShell(
      eyebrow: 'Settings and account',
      title: 'Profile',
      film: 'assets/video/signature-banner.mp4',
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.list(children: [
            const _Identity(),
            const SizedBox(height: 22),
            const DarkHead(
              eyebrow: 'Everything, one tap away',
              title: 'Your pages',
              icon: Icons.apps,
            ),
            const SizedBox(height: 14),
            _Go(
              title: 'Settings',
              sub: 'Widgets and shortcuts',
              icon: Icons.tune,
              go: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WidgetsPage()),
              ),
            ),
            _Go(
              title: 'Sound Library',
              sub: 'Root frequencies',
              icon: Icons.graphic_eq,
              go: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SoundLibraryScreen()),
              ),
            ),
            _Go(
              title: 'Fashion Plus',
              sub: 'Open the motion mode',
              icon: Icons.auto_awesome_motion_outlined,
              go: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FashionPlusScreen()),
              ),
            ),
            const SizedBox(height: 22),
            const DarkHead(
              eyebrow: 'What the app is running on',
              title: 'Content',
              icon: Icons.cloud_outlined,
            ),
            const SizedBox(height: 14),
            _Stat(
              label: 'Source',
              value: live ? 'Live from the studio' : 'Bundled with the app',
              good: live,
            ),
            if (!live)
              _Note(NwsbFirebase.unavailableReason ??
                  'Firebase did not start, so published edits will not '
                      'arrive until it does.'),
            _Stat(label: 'Words', value: '${store.library.length}'),
            _Stat(label: 'Meanings', value: '${store.meanings.length}'),
            _Stat(label: 'eBooks', value: '${store.books.length}'),
            const SizedBox(height: 22),
            const DarkHead(
              eyebrow: 'How the films are managed',
              title: 'Video',
              icon: Icons.movie_outlined,
            ),
            const SizedBox(height: 14),
            _Stat(
              label: 'Decoders in use',
              value: '${VideoPool.instance.liveCount} of ${VideoPool.maxLive}',
            ),
            _Stat(
                label: 'Clips on this screen',
                value: '${VideoPool.instance.leaseCount}'),
            const _Note(
              'Every clip is on the phone — nothing streams. At most four '
              'decode at once, which is what keeps the app from stuttering '
              'the way the website did.',
            ),
            const SizedBox(height: 22),
            const DarkHead(
              eyebrow: 'Not built yet',
              title: 'Coming',
              icon: Icons.construction_outlined,
            ),
            const SizedBox(height: 14),
            const _Soon('Sign in and your account'),
            const _Soon('My Routines'),
            const _Soon('Cart, wishlist and orders'),
            const _Soon('NowssB Connect and chat'),
            const _Soon('Notifications'),
            const _Soon('Word audio — hearing a word, not only reading it'),
          ]),
        ),
      ],
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: const Icon(Icons.person_outline,
              size: 30, color: NwsbColors.goldLight),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Healer',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Not signed in',
                style: TextStyle(fontSize: 13, color: Color(0x8CFFFFFF)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Go extends StatelessWidget {
  const _Go({
    required this.title,
    required this.sub,
    required this.icon,
    required this.go,
  });

  final String title;
  final String sub;
  final IconData icon;
  final VoidCallback go;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: go,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF14141C),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: NwsbColors.goldLight),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0x8CFFFFFF)),
                  ),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.good});
  final String label;
  final String value;
  final bool? good;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xB3FFFFFF)),
            ),
          ),
          if (good != null) ...[
            Icon(
              good! ? Icons.check_circle : Icons.info_outline,
              size: 15,
              color: good! ? const Color(0xFF6BCB77) : NwsbColors.gold,
            ),
            const SizedBox(width: 7),
          ],
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          color: Color(0x8CFFFFFF),
          height: 1.55,
        ),
      ),
    );
  }
}

class _Soon extends StatelessWidget {
  const _Soon(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x0FFFFFFF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 15, color: Color(0x66FFFFFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0x8CFFFFFF)),
            ),
          ),
        ],
      ),
    );
  }
}
