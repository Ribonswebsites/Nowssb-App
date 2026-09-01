/// Profile — the exact integrated NowssB website profile experience.
library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.black)
    ..setNavigationDelegate(NavigationDelegate(
      onPageFinished: (_) => _openProfile(),
    ))
    ..loadRequest(Uri.parse('https://ribonswebsites.github.io/Nowssb-App/'));

  Future<void> _openProfile() async {
    await _controller.runJavaScript('''
      (function openProfile(){
        if (typeof window.openSub === 'function') {
          window.openSub('profile');
        } else {
          setTimeout(openProfile, 120);
        }
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}
