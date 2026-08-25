/// NowssB — Shabdapathy.
///
/// This is the Flutter app: real widgets, no WebView and no HTML. It reads
/// the same Firestore content the website reads (content/library,
/// content/books, content/words, content/meanings), so a word published from
/// the studio appears here without a Play release — see FLUTTER.md.
///
/// Two things are true at once and both matter:
///
///   · Decorative and practice videos ship in the app bundle, so launch never
///     starts a background download pack or competes with playback for bandwidth.
///   · On-screen clips are opened by the small decoder pool for stability;
///     lib/media/video_pool.dart is where that ceiling is enforced.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/content.dart';
import 'data/firebase.dart';
import 'data/settings.dart';
import 'data/updater.dart';
import 'media/video_pool.dart';
import 'screens/login.dart';
import 'services/connect_service.dart';
import 'screens/splash.dart';
import 'widgets/motion.dart';
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

  // Nothing decodes underneath the start animation. The bundled video pool is
  // released by the splash when it finishes, and by the eight-second ceiling.
  VideoPool.instance.hold();
  VideoPool.instance.startHeartbeat();

  runApp(const NowssbApp());
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    // Firebase is intentionally optional for offline/local-content launches.
    // When it is ready, the auth stream becomes the single source of truth for
    // whether the user sees the branded login or the app shell.
    if (!NwsbFirebase.ready) return const NavShell();
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ColoredBox(color: NwsbColors.deep);
        }
        return snapshot.data == null ? const LoginScreen() : const NavShell();
      },
    );
  }
}

class NowssbApp extends StatefulWidget {
  const NowssbApp({super.key});

  @override
  State<NowssbApp> createState() => _NowssbAppState();
}

class _NowssbAppState extends State<NowssbApp> with WidgetsBindingObserver {
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (NwsbFirebase.ready) {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          ConnectService.instance.ensurePublicProfile().catchError((error) {
            debugPrint('NowssB Connect profile sync failed: $error');
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NowssB',
      debugShowCheckedModeBanner: false,
      theme: NwsbTheme.light,
      darkTheme: NwsbTheme.dark,
      themeMode: ThemeMode.light,
      color: NwsbColors.deep,
      scrollBehavior: const NwsbScrollBehavior(),
      home: Stack(
        children: [
          const _AuthGate(),
          if (!_splashDone)
            Splash(onDone: () {
              VideoPool.instance.unhold();
              setState(() => _splashDone = true);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final ctx = context;
                if (!ctx.mounted) return;
                NwsbUpdate.maybeShow(ctx);
              });
            }),
        ],
      ),
    );
  }
}
