/// Shared hamburger menu — website `#menuDrawer` / `openMenu` (part012.js).
///
/// Full-screen slide-in from the right, same sections and copy as index.html,
/// same CDN icons. Fashion mirrors App Settings styling (solid deep + gold
/// wash, HeavyGlassPanel groups, NestedDarkWrap rows). Normal opens the
/// neumorphic light look (`body.nm-mode #menuDrawer`). Quick Links (part061)
/// is a different sheet — this is only the hamburger.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import 'app_destinations.dart';
import 'glass_list_card.dart';
import '../admin/template/editable.dart';

/// Opens the website hamburger (`#menuDrawer`) over the current route.
Future<void> showHomeMenuDrawer(
  BuildContext context, {
  required void Function(int tab) goTab,
}) {
  HapticFeedback.lightImpact();
  // Both homes open the same dark menu. The pale drawer was a different page.
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Menu',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (ctx, anim, secondary) {
      return HomeMenuDrawer(
        light: false,
        goTab: goTab,
      );
    },
    transitionBuilder: (ctx, anim, secondary, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: const Cubic(0.4, 0, 0.2, 1),
      );
      return Stack(
        children: [
          FadeTransition(
            opacity: curved,
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Color(0x00000000)),
            ),
          ),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ],
      );
    },
  );
}

class HomeMenuDrawer extends StatefulWidget {
  const HomeMenuDrawer({
    super.key,
    required this.light,
    required this.goTab,
  });

  /// `true` = Normal / neumorphic home (`body.nm-mode`).
  final bool light;
  final void Function(int tab) goTab;

  @override
  State<HomeMenuDrawer> createState() => _HomeMenuDrawerState();
}

class _HomeMenuDrawerState extends State<HomeMenuDrawer> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim();
      if (q != _q) setState(() => _q = q);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _close(BuildContext context) => Navigator.of(context).maybePop();

  void _open(AppDest d) {
    HapticFeedback.selectionClick();
    // Pages replace the drawer route so the home never flashes underneath.
    openDest(context, d, goTab: widget.goTab, replace: d.action == null);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final all = _q.isEmpty
        ? menuDestinations
        : [...menuDestinations, ...settingsDestinations]
            .where((d) => d.matches(_q))
            .toList();

    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: NwsbVideo(
                asset: 'assets/video/subscription-bg.mp4',
                priority: ClipPriority.decoration,
                autoplay: true,
                loop: true,
                fit: BoxFit.cover,
                slot: 'home_menu_drawer.HomeMenuDrawer',
              ),
            ),
            // Quieter film: the cards lead, the purple sits behind them.
            const Positioned.fill(child: QuietFilmVeil()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(12, top + 10, 16, 14),
                  decoration: const BoxDecoration(
                    color: Color(0x66060C18),
                    border: Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
                  ),
                  child: Row(
                    children: [
                      _BackBtn(light: false, onTap: () => _close(context)),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'NOWSSB',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: NwsbColors.goldLight,
                                ),
                              ),
                              TextSpan(text: '  '),
                              TextSpan(
                                text: 'Your Menu',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 40),
                    children: [
                      GlassSearchField(controller: _search, hint: 'Search pages and settings'),
                      const SizedBox(height: 16),
                      if (all.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Text('Nothing called "$_q" in NowssB.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: kGlassMuted, fontSize: 13)),
                        ),
                      for (final d in all)
                        GlassItemCard(
                          key: ValueKey('menu-${d.id}'),
                          icon: d.icon,
                          overline: d.overline,
                          title: d.title,
                          pill: d.pill,
                          pillSub: d.sub,
                          onTap: () => _open(d),
                        ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 26, 4, 0),
                        child: EditableLabel('home_menu_drawer.HomeMenuDrawer',
                          'Shabdapathy · v9.5',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 3,
                            color: Color(0x4DFFFFFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.light, required this.onTap});
  final bool light;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: light
              ? const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(3, 3),
                  ),
                ]
              : null,
        ),
        child: Icon(
          light ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back,
          size: light ? 16 : 19,
          color: NwsbColors.ink,
        ),
      ),
    );
  }
}

