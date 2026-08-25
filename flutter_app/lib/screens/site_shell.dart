import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// The Flutter app uses the same deployed site surface as the webview build.
/// This keeps every page, section, image, video, interaction, and future site
/// fix in one source of truth instead of maintaining a partial native port.
class SiteShell extends StatefulWidget {
  const SiteShell({super.key});

  static final Uri homeUri = Uri.parse('https://nowssb-app.pages.dev/');

  @override
  State<SiteShell> createState() => _SiteShellState();
}

class _SiteShellState extends State<SiteShell> {
  late final WebViewController _controller;
  Timer? _autoplayPulse;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted)
              setState(() {
                _loading = true;
                _failed = false;
              });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
            _installVideoPolicy();
            _autoplayPulse?.cancel();
            _autoplayPulse = Timer.periodic(
              const Duration(seconds: 2),
              (_) => _installVideoPolicy(),
            );
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              if (mounted)
                setState(() {
                  _loading = false;
                  _failed = true;
                });
            }
          },
        ),
      )
      ..loadRequest(SiteShell.homeUri);

    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  Future<void> _installVideoPolicy() async {
    if (!mounted) return;
    try {
      await _controller.runJavaScript('''
        (function () {
          document.querySelectorAll('video').forEach(function (video) {
            video.muted = true;
            video.defaultMuted = true;
            video.autoplay = true;
            video.loop = true;
            video.playsInline = true;
            var attempt = video.play();
            if (attempt && attempt.catch) attempt.catch(function () {});
          });
        })();
      ''');
    } catch (_) {
      // The page can be between navigations. The periodic policy retries it.
    }
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _autoplayPulse?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _handleBack() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE7C978)),
                ),
              ),
            if (_failed)
              _RetryPanel(onRetry: () {
                setState(() {
                  _failed = false;
                  _loading = true;
                });
                _controller.reload();
              }),
          ],
        ),
      ),
    );
  }
}

class _RetryPanel extends StatelessWidget {
  const _RetryPanel({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'NowssB could not connect',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 14),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
