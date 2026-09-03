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
import '../screens/quick_access.dart';
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
  int _i = Settings.instance.lastTab;

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
    Settings.instance.setLastTab(tab);
  }

  static const _navFeatures = <String, Map<String, String>>{
    'connect': {'label': 'Connect', 'img': 'https://media.nowssb.com/migrated-images/ea559460014dd8d9_file_00000000b84c7209ab496862cacd6a7f_kagsie.png'},
    'practice': {'label': 'Practice', 'img': 'https://media.nowssb.com/migrated-images/44ed38a222535b9c_38538b80-56d8-11f1-8fad-095787cce754_xam2bb.png'},
    'library': {'label': 'Library', 'img': 'https://media.nowssb.com/migrated-images/62e5d0908e54a2a6_c500a990-56cf-11f1-8fad-095787cce754_1_zqzbal.png'},
    'store': {'label': 'Store', 'img': 'https://media.nowssb.com/migrated-images/86a1283688196499_ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png'},
    'profile': {'label': 'Profile', 'img': 'https://media.nowssb.com/migrated-images/3979b9fa35b579e6_62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png'},
    'progress': {'label': 'Progress', 'img': 'https://media.nowssb.com/migrated-images/0480c10b8a8d79dd_file_00000000ae607208aa51504989648920_ml2czc.png'},
    'wordscience': {'label': 'Word Sci', 'img': 'https://media.nowssb.com/migrated-images/dd44cf9fc35b783c_file_0000000086d872089ce376674620d5f3_mtfftb.png'},
    'meaningstore': {'label': 'Meaning', 'img': 'https://media.nowssb.com/migrated-images/1a5f669e63dbae9d_file_00000000854881fa9a548a68fae59c15_w1utya.png'},
    'search': {'label': 'Search', 'img': 'https://media.nowssb.com/migrated-images/8d85320f63c3e176_file_00000000029c7208b5e915d9af2c480c_tuccwo.png'},
    'cart': {'label': 'Cart', 'img': 'https://media.nowssb.com/migrated-images/311c26afee2bc52c_file_00000000f02c72088cd128f3f4b08af5_vskoom.png'},
    'wishlist': {'label': 'Wishlist', 'img': 'https://media.nowssb.com/migrated-images/a74a9935fb237eb8_file_0000000055d8720895f7ba98c4a7bf4a_s2lzab.png'},
    'routines': {'label': 'Routines', 'img': 'https://media.nowssb.com/migrated-images/307233cd22669455_file_00000000f740820ba6aaa761133e8889_fitm0p.png'},
    'chat': {'label': 'Chat', 'img': 'https://media.nowssb.com/migrated-images/db15f3026ea179dc_1ae1b990-5bf2-11f1-8248-b91d5cd919c2_z3xi3j.png'},
    'ai': {'label': 'AI Rx', 'img': 'https://media.nowssb.com/migrated-images/41c9ed21b2822c90_file_0000000062a882089abd27eb90ea3945_ngqyu6.png'},
    'streak': {'label': 'Streak', 'img': 'https://media.nowssb.com/migrated-images/f82047a0e727766b_file_0000000010fc820891f9e15a38316d2b_ffffhq.png'},
    'settings': {'label': 'Settings', 'img': 'https://media.nowssb.com/migrated-images/523b5889d13cb14a_260480b0-56d8-11f1-8fad-095787cce754_rz6zbi.png'},
    'everything': {'label': 'Everything', 'img': 'https://media.nowssb.com/migrated-images/47f9e2c9fad5a78f_file_00000000be547207aaa56f43cfef4f67_nxhvw0.png'},
  };
  int? _primaryTab(String id) => const {'connect': 0, 'practice': 1, 'library': 2, 'store': 3, 'profile': 4}[id];
  void _goToSlot(String id) {
    final tab = _primaryTab(id);
    if (tab != null) { _goToTab(tab); return; }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuickAccessScreen()));
  }

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
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Builder(builder: (context) {
                      final settings = Settings.instance;
                      final radius = settings.navShape == 'pill'
                          ? 40.0
                          : settings.navShape == 'rect'
                              ? (settings.navCorner == 'rounded' ? 20.0 : 2.0)
                              : 33.0;
                      final background = settings.navColor == 'black'
                          ? Colors.black
                          : const Color(0xDD182033);
                      return Container(
                        height: 66,
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(color: const Color(0x22FFFFFF)),
                        ),
                        child: Row(children: [
                          for (final id in settings.navSlots)
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _goToSlot(id),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      _navFeatures[id]?['img'] ?? '',
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.circle_outlined,
                                        size: 22,
                                        color: id == 'connect' || _primaryTab(id) == _i
                                            ? NwsbColors.goldLight
                                            : const Color(0x99FFFFFF),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _navFeatures[id]?['label'] ?? id,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: _primaryTab(id) == _i ? FontWeight.w700 : FontWeight.w400,
                                        color: _primaryTab(id) == _i ? NwsbColors.goldLight : const Color(0x99FFFFFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ]),
                      );
                    }),
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
