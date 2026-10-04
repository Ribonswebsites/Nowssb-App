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
///     nothing depends on R2 being up or the signal being good.
///   · At most four of them decode at any moment. A phone has a handful of
///     hardware decoders and the website was asking for a hundred, which is
///     what the lag, the black banners and the crashes actually were.
///     lib/media/video_pool.dart is where that ceiling is enforced.
library;

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin/admin_state.dart';
import 'admin/edit_fab.dart';
import 'admin/layout/ui_layouts.dart';
import 'admin/template/ui_overrides.dart';
import 'app_update.dart';
import 'data/app_control.dart';
import 'data/content.dart';
import 'data/word_art.dart';
import 'data/earn_wallet.dart';
import 'data/firebase.dart';
import 'features/economy/economy_api.dart';
import 'features/economy/money.dart';
import 'features/economy/play_billing.dart';
import 'features/economy/reward_overlay.dart';
import 'data/device_flags.dart';
import 'data/notifications.dart';
import 'data/phone_notifications.dart';
import 'data/presence.dart';
import 'data/quotes_remote.dart';
import 'data/word_requests.dart';
import 'data/cart_bag.dart';
import 'data/home_widget_sync.dart';
import 'data/play_subscriptions.dart';
import 'data/settings.dart';
import 'media/video_pool.dart';
import 'screens/auth_gate.dart';
import 'screens/splash.dart';
import 'widgets/app_control_layer.dart';
import 'widgets/motion.dart';
import 'widgets/notification_popup.dart';
import 'widgets/update_prompt.dart';
import 'shell/nav_shell.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';
import 'widgets/hype_open.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureHypeRoutes();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Firebase first, but it is allowed to fail: an Android build has no
  // Firebase until google-services.json lands, and that must be an app that
  // shows the words it shipped with, not a crash on launch.
  await NwsbFirebase.start();
  if (NwsbFirebase.ready) {
    FirebaseMessaging.onBackgroundMessage(nwsbFcmBackground);
  }
  // "Remember me" unticked at the last sign-in: start signed out.
  await AuthGate.forgetUnremembered();

  // Stages one and two of the content contract — what ships, and the last
  // copy seen — are local, so the first screen has something real to draw
  // whether or not the network ever answers. This sets those up and leaves
  // the Firestore watch running behind them when there is one.
  await Settings.instance.load();
  await NotifStore.instance.load();
  await CartBag.instance.load();
  await EarnWallet.instance.start();
  await EconomyMirror.instance.start();
  await FxBook.instance.start();
  // Google Play subscriptions: listen for purchases Play delivers at launch.
  unawaited(PlaySubscriptions.instance.start());
  await ContentStore.instance.start();
  await WordArt.instance.start();
  // Android home-screen widget: streak + word of the day (no-op elsewhere).
  unawaited(HomeWidgetSync.instance.start());

  // Admin mode and the live template layer (lib/admin). Overrides load from
  // the phone before the first frame, so a replaced picture or line shows
  // at once instead of flashing the default; the Firestore watch follows.
  await UiOverrides.instance.start();
  await UiLayouts.instance.start();
  await EditMode.instance.load();
  await SlotRegistry.instance.load();
  AdminState.instance.start();
  QuoteStore.instance.addListener(Settings.instance.remoteChanged);
  await QuoteStore.instance.start();
  WordRequestStore.instance.startSync();
  Presence.instance.start();
  // Admin console switches: force update, maintenance, announcement,
  // blocked / restricted account (data/app_control.dart).
  unawaited(AppControl.instance.start());

  // Nothing decodes underneath the start animation. Released by the splash
  // when it finishes, and by the eight-second ceiling if it never does.
  if (Settings.instance.showSplash) VideoPool.instance.hold();
  VideoPool.instance.startHeartbeat();
  // Prefetch feature UI loops (tab / orb / page bg / login / progress /
  // fashion) into the page cache while the splash plays — throwaway
  // controllers, not pool slots — so Level 1 / orb / tab are not blank on
  // first open.
  unawaited(VideoPool.instance.warm());

  runApp(const NowssbApp());
}

class NowssbApp extends StatefulWidget {
  const NowssbApp({super.key});

  @override
  State<NowssbApp> createState() => _NowssbAppState();
}

class _NowssbAppState extends State<NowssbApp> with WidgetsBindingObserver {
  // Shared with the reward overlay so wins play on the root navigator.
  final _navigatorKey = RewardOverlay.navigatorKey;
  final _popupRoutes = HomePopupRouteObserver();
  bool _checkingForUpdate = false;
  Timer? _beat;

  /// Foreground time for Rewards (server counts minutes between beats and
  /// caps them; nothing is counted on the phone).
  void _startBeat() {
    _beat?.cancel();
    _beat = Timer.periodic(const Duration(seconds: 60), (_) {
      final u = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser : null;
      if (u == null || u.isAnonymous) return;
      unawaited(EconomyApi.call('heartbeat').then((_) {}, onError: (_) {}));
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startBeat();
    if (NwsbFirebase.ready) {
      FirebaseAuth.instance.authStateChanges().listen((u) {
        if (u != null && !u.isAnonymous) unawaited(PlayCheckout.start().catchError((_) {}));
      });
    }
    // Read the manifest while the splash plays, so the prompt is ready when
    // it ends; this also resumes a download a previous launch left partial.
    unawaited(NwsbUpdater.instance.check(force: true));
    if (_splashDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForUpdate(coldStart: true);
        unawaited(PhoneNotifications.instance.announceAfterLaunch());
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _beat?.cancel();
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
      _startBeat();
      EconomyMirror.instance.onForeground();
      unawaited(NwsbUpdater.instance.onResumed());
      _checkForUpdate();
      if (NwsbFirebase.ready && FirebaseAuth.instance.currentUser != null) {
        unawaited(EarnWallet.instance.onSignedIn());
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      NwsbUpdater.instance.setForeground(false);
      VideoPool.instance.releaseAll();
      _beat?.cancel();
    }
  }

  /// The start animation plays once per launch, and the app is built behind
  /// it rather than after it — so by the time the clip ends the first screen
  /// is already laid out and there is no second wait.
  bool _splashDone = !Settings.instance.showSplash;

  /// Update check and prompt (lib/app_update.dart). Cold start: always
  /// re-reads the manifest and always prompts. Back in the app: re-reads at
  /// most every few minutes and prompts again once the reminder interval
  /// since the last "Later" has passed. Nothing about a dismissal is saved.
  Future<void> _checkForUpdate({bool coldStart = false}) async {
    if (_checkingForUpdate || !_splashDone) return;
    _checkingForUpdate = true;
    try {
      final updater = NwsbUpdater.instance;
      await updater.check(force: coldStart);
      if (!mounted || updater.available == null || updater.required) return;
      if (nwsbUpdateDialogOpen || !updater.shouldPrompt(coldStart: coldStart)) return;
      final context = _navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      unawaited(showNwsbUpdateDialog(context));
    } finally {
      _checkingForUpdate = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return UiScope(
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        navigatorObservers: [_popupRoutes],
        builder: (context, child) => NwsbUpdateLayer(
            navigatorKey: _navigatorKey,
            child: AppControlLayer(
              navigatorKey: _navigatorKey,
              child: AdminEditFab(
                navigatorKey: _navigatorKey,
                child: NotificationPopupHost(child: child ?? const SizedBox()),
              ),
            )),
        title: 'NowssB',
        debugShowCheckedModeBanner: false,
        theme: NwsbTheme.light,
        darkTheme: NwsbTheme.dark,
        themeMode: ThemeMode.light,
        color: NwsbColors.deep,
        scrollBehavior: const NwsbScrollBehavior(),
        home: Stack(
          children: [
            const AuthGate(child: NavShell()),
            if (!_splashDone)
              Splash(onDone: () {
                VideoPool.instance.unhold();
                setState(() => _splashDone = true);
                unawaited(_checkForUpdate(coldStart: true));
                unawaited(PhoneNotifications.instance.announceAfterLaunch());
                unawaited(DeviceFlags.applySaved());
              }),
          ],
        ),
      ),
    );
  }
}
