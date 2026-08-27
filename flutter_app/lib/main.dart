/// NowssB — Shabdapathy.
///
/// This is the Flutter app: real widgets, no WebView and no HTML. It reads
/// the same Firestore content the website reads (content/library,
/// content/books, content/words, content/meanings), so a word published from
/// the studio appears here without a Play release — see FLUTTER.md.
///
/// Two things are true at once and both matter:
///
///   · The clips are all on the phone. Nothing streams, nothing buffers,
///     nothing depends on Cloudinary being up or the signal being good.
///   · At most four of them decode at any moment. A phone has a handful of
///     hardware decoders and the website was asking for a hundred, which is
///     what the lag, the black banners and the crashes actually were.
///     lib/media/video_pool.dart is where that ceiling is enforced.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_update.dart';
import 'data/content.dart';
import 'data/firebase.dart';
import 'data/settings.dart';
import 'media/video_pool.dart';
import 'screens/auth_gate.dart';
import 'screens/splash.dart';
import 'shell/nav_shell.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Firebase first, but it is allowed to fail: an Android build has no
  // Firebase until google-services.json lands, and that must be an app that
  // shows the words it shipped with, not a crash on launch.
  await NwsbFirebase.start();

  // Stages one and two of the content contract — what ships, and the last
  // copy seen — are local, so the first screen has something real to draw
  // whether or not the network ever answers. This sets those up and leaves
  // the Firestore watch running behind them when there is one.
  await Settings.instance.load();
  await ContentStore.instance.start();

  // Nothing decodes underneath the start animation. Released by the splash
  // when it finishes, and by the eight-second ceiling if it never does.
  VideoPool.instance.hold();
  VideoPool.instance.startHeartbeat();

  runApp(const NowssbApp());
}

class NowssbApp extends StatefulWidget {
  const NowssbApp({super.key});

  @override
  State<NowssbApp> createState() => _NowssbAppState();
}

class _NowssbAppState extends State<NowssbApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _checkingForUpdate = false;
  int _shownUpdateBuild = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Every decoder goes back when the app leaves the foreground. Android
  /// reclaims them from a background app anyway, and a controller still
  /// holding one when that happens comes back to a dead surface — which on
  /// the website was the black-banner-after-switching-apps bug.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      VideoPool.instance.resume();
      _checkForUpdate();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      VideoPool.instance.releaseAll();
    }
  }

  /// The start animation plays once per launch, and the app is built behind
  /// it rather than after it — so by the time the clip ends the first screen
  /// is already laid out and there is no second wait.
  bool _splashDone = false;

  Future<void> _checkForUpdate() async {
    if (_checkingForUpdate || !_splashDone) return;
    _checkingForUpdate = true;
    try {
      final update = await NwsbAppUpdate.findNewer();
      if (!mounted || update == null || update.build <= _shownUpdateBuild) return;
      final context = _navigatorKey.currentContext;
      if (context == null) return;
      _shownUpdateBuild = update.build;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF102037),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('A new NowssB update is ready', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: const Text('Open the official NowssB download page to get the latest Android package.', style: TextStyle(color: Color(0xCCFFFFFF), height: 1.45)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Later')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: NwsbColors.goldLight, foregroundColor: NwsbColors.deep),
              onPressed: () async {
                Navigator.of(context).pop();
                final opened = await launchUrl(update.apkUrl, mode: LaunchMode.externalApplication);
                if (!opened && mounted) {
                  final root = _navigatorKey.currentContext;
                  if (root != null) {
                    ScaffoldMessenger.of(root).showSnackBar(
                      const SnackBar(content: Text('Could not open the update. Please try again when you are online.')),
                    );
                  }
                }
              },
              child: const Text('Get update'),
            ),
          ],
        ),
      );
    } finally {
      _checkingForUpdate = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'NowssB',
      debugShowCheckedModeBanner: false,
      theme: NwsbTheme.light,
      darkTheme: NwsbTheme.dark,
      themeMode: ThemeMode.light,
      color: NwsbColors.deep,
      home: Stack(
        children: [
          const AuthGate(child: NavShell()),
          if (!_splashDone)
            Splash(onDone: () {
              VideoPool.instance.unhold();
              setState(() => _splashDone = true);
              unawaited(_checkForUpdate());
            }),
        ],
      ),
    );
  }
}
