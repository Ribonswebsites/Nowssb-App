/// NowssB — Shabdapathy.
///
/// This is the Flutter app: real widgets, no WebView and no HTML. It reads
/// the same Firestore content the website reads (content/words,
/// content/meanings, content/library, content/books), so a word published
/// from the studio appears here without a Play release — see FLUTTER.md.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';
import 'shell/nav_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
      home: const NavShell(),
    );
  }
}
