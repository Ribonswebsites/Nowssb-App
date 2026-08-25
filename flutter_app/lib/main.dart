/// NowssB — Shabdapathy.
///
/// This is the Flutter app: real widgets, no WebView and no HTML. It reads
/// the same Firestore content the website reads (content/library,
/// content/books, content/words, content/meanings), so a word published from
/// the studio appears here without a Play release — see FLUTTER.md.
///
/// Two things are true at once and both matter:
///
///   · Decorative videos download into private app storage in a controlled
///     one-file-at-a-time pack. The launch animation remains bundled locally.
///   · On-screen clips play from the private cache. Off-screen clips are
///     posters, and the decoder ceiling is deliberately small for stability.
///     lib/media/video_pool.dart is where that ceiling is enforced.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/content.dart';
import 'data/firebase.dart';
import 'data/settings.dart';
import 'data/updater.dart';
import 'media/video_cache.dart';
import 'media/video_pool.dart';
import 'screens/splash.dart';
import 'widgets/video_pack_dialog.dart';
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
  await VideoCache.instance.init();

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
          const NavShell(),
          if (!_splashDone)
            Splash(onDone: () {
              VideoPool.instance.unhold();
              setState(() => _splashDone = true);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final ctx = context;
                if (!ctx.mounted) return;
                NwsbUpdate.maybeShow(ctx);
                if (VideoCache.instance.accepted && !VideoCache.instance.isComplete) {
                  unawaited(VideoCache.instance.downloadAll());
                } else if (!VideoCache.instance.hasPrompted && !VideoCache.instance.isComplete) {
                  showDialog<void>(
                    context: ctx,
                    barrierDismissible: false,
                    builder: (_) => const VideoPackDialog(),
                  );
                }
              });
            }),
        ],
      ),
    );
  }
}
