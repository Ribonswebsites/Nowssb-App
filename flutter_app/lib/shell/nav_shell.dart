/// The bottom nav — #ig-bottomnav. Five destinations, the active one gold.
library;

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../data/settings.dart';
import '../screens/home_fashion.dart';
import '../screens/home_normal.dart';
import '../screens/library.dart';
import '../screens/practice.dart';
import '../screens/profile.dart';
import '../screens/store.dart';
import '../widgets/pool_hud.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});
  @override
  State<NavShell> createState() => _NavShellState();
}

/// Lets any screen move the shell to another destination without knowing how
/// the shell is built. The home's sections use it: pressing "Enter the Store"
/// goes to the Store tab rather than nowhere.
class NavScope extends InheritedWidget {
  const NavScope({super.key, required this.go, required super.child});

  /// 0 Connect · 1 Practice · 2 Library · 3 Store · 4 Profile
  final void Function(int) go;

  static void goTo(BuildContext context, int i) {
    context.dependOnInheritedWidgetOfExactType<NavScope>()?.go(i);
  }

  @override
  bool updateShouldNotify(NavScope old) => false;
}

class _NavShellState extends State<NavShell> {
  int _i = 0;

  /// Which home. The website keeps both in the DOM and switches a class;
  /// here it is two different screens rather than two skins — see
  /// lib/screens/home_fashion.dart. The answer is remembered between
  /// launches, and Settings is the other place it can be changed, so this
  /// reads the setting rather than keeping a copy that could disagree.
  bool get _fashion => Settings.instance.fashionHome;

  @override
  void initState() {
    super.initState();
    Settings.instance.addListener(_onSettings);
  }

  @override
  void dispose() {
    Settings.instance.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  void _goToTab(int tab) {
    if (tab == _i) return;
    Settings.instance.fadeBackgroundForNavigation();
    setState(() => _i = tab);
  }

  static const _tabs = [
    ('Connect', Icons.groups_outlined),
    ('Practice', Icons.headphones_outlined),
    ('Library', Icons.menu_book_outlined),
    ('Store', Icons.storefront_outlined),
    ('Profile', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return NavScope(
      go: _goToTab,
      child: _build(context),
    );
  }

  Widget _build(BuildContext context) {
    return Scaffold(
      backgroundColor: NwsbColors.surface,
      body: Stack(
        children: [
          // IndexedStack rather than swapping the child: it keeps each tab's
          // scroll position and state alive, which is what the website does
          // (its screens are all in the DOM at once, one of them .active).
          IndexedStack(
            index: _i,
            children: [
              _fashion ? const HomeFashion() : const HomeNormal(),
              const PracticeScreen(),
              const LibraryScreen(),
              const StoreScreen(),
              const ProfileScreen(),
            ],
          ),
          // The switch between the two homes. On the website this lives in
          // Customize; until that screen is ported it is here, because a
          // home you cannot reach may as well not be built.
          if (_i == 0)
            Positioned(
              left: 14,
              bottom: 92,
              child: SafeArea(
                top: false,
                child: GestureDetector(
                  onTap: () => Settings.instance.setFashionHome(!_fashion),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _fashion ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _fashion ? Icons.light_mode : Icons.dark_mode,
                          size: 15,
                          color: _fashion ? Colors.black : Colors.white,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _fashion ? 'Normal home' : 'Fashion home',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _fashion ? Colors.black : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Debug only, and compiled out of a release build: the decoder
          // count, live, so the ceiling is something you can watch rather
          // than something you have to take on trust.
          const Positioned(top: 4, right: 8, child: SafeArea(child: PoolHud())),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      height: 66,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(33),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _goToTab(i),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _tabs[i].$2,
                                size: 22,
                                color: i == _i
                                    ? NwsbColors.goldLight
                                    : const Color(0x99FFFFFF),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _tabs[i].$1,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: i == _i
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: i == _i
                                      ? NwsbColors.goldLight
                                      : const Color(0x99FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
