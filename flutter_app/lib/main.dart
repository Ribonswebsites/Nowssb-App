/// NowssB Flutter container.
///
/// The deployed website is the single source of truth for the Flutter surface.
/// It contains the complete 25 August page tree, styling, imagery, media,
/// navigation, authentication UI, and video behavior. Keeping that surface in
/// a WebView prevents the native app and webview from drifting apart.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/site_shell.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';
import 'widgets/motion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const NowssbApp());
}

class NowssbApp extends StatelessWidget {
  const NowssbApp({super.key});

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
      home: const SiteShell(),
    );
  }
}
