/// The update prompt, the "Update available" banner and the required-update
/// screen. All three only display [NwsbUpdater]; closing any of them never
/// stops a download (see lib/app_update.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../admin/template/editable.dart';
import '../app_update.dart';
import '../theme/tokens.dart';
import 'app_thinking_loader.dart';
import 'nwsb_icon.dart';

const _panel = Color(0xFF000000);
const _bannerHeight = 34.0;

/// Wraps the app (MaterialApp.builder). While an update is pending a slim
/// banner sits under the status bar — the child's top inset grows by the
/// banner's height so nothing is covered — and a required update covers the
/// app completely. The child is always at the same place in the tree, so
/// showing or hiding the banner never rebuilds the navigator's state.
class NwsbUpdateLayer extends StatelessWidget {
  const NwsbUpdateLayer({super.key, required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final updater = NwsbUpdater.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: updater.blocking,
      builder: (context, blocking, _) => ValueListenableBuilder<bool>(
        valueListenable: updater.bannerVisible,
        builder: (context, banner, _) {
          final mq = MediaQuery.of(context);
          final inset = banner && !blocking ? _bannerHeight : 0.0;
          return Stack(children: [
            MediaQuery(
              data: inset == 0
                  ? mq
                  : mq.copyWith(
                      padding: mq.padding.copyWith(top: mq.padding.top + inset),
                      viewPadding: mq.viewPadding.copyWith(top: mq.viewPadding.top + inset),
                    ),
              child: child,
            ),
            if (inset > 0)
              Positioned(
                top: mq.padding.top,
                left: 0,
                right: 0,
                height: _bannerHeight,
                child: _UpdateBanner(onTap: () {
                  final ctx = navigatorKey.currentContext;
                  if (ctx != null) showNwsbUpdateDialog(ctx);
                }),
              ),
            if (blocking) const Positioned.fill(child: _RequiredUpdateScreen()),
          ]);
        },
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final updater = NwsbUpdater.instance;
    return Material(
      color: _panel,
      child: InkWell(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: updater,
          builder: (context, _) {
            final p = updater.progress;
            final String label;
            switch (updater.phase) {
              case NwsbUpdatePhase.downloading:
                label = p == null ? 'Downloading update…' : 'Downloading update · ${(p * 100).floor()}%';
              case NwsbUpdatePhase.retrying:
                label = 'Update paused — reconnecting…';
              case NwsbUpdatePhase.verifying:
                label = 'Checking update…';
              case NwsbUpdatePhase.ready:
              case NwsbUpdatePhase.installing:
                label = 'Update ready — tap to install';
              case NwsbUpdatePhase.failed:
                label = 'Update paused — tap to continue';
              case NwsbUpdatePhase.idle:
                label = 'Update available — tap to update';
            }
            return Stack(children: [
              if (updater.busy && p != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: p,
                    minHeight: 2,
                    color: NwsbColors.goldLight,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const NwsbIcon(NwsbMarks.earn, size: 12, color: Colors.black, strokeWidth: 1.6),
                  ),
                  const SizedBox(width: 8),
                  const AppThinkingLoader(size: 12, state: OrbState.composing, blackCircle: true, circlePad: 3),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

bool _dialogOpen = false;

/// Shows the update dialog (once at a time). Closing it any way other than
/// installing counts as "Later" — remembered in memory only.
Future<void> showNwsbUpdateDialog(BuildContext context) async {
  if (_dialogOpen || NwsbUpdater.instance.available == null) return;
  _dialogOpen = true;
  NwsbUpdater.instance.prompted();
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _UpdateDialog(),
    );
  } finally {
    _dialogOpen = false;
    NwsbUpdater.instance.dismissed();
  }
}

bool get nwsbUpdateDialogOpen => _dialogOpen;

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog();

  @override
  Widget build(BuildContext context) {
    final updater = NwsbUpdater.instance;
    return AnimatedBuilder(
      animation: updater,
      builder: (context, _) {
        final phase = updater.phase;
        final busy = updater.busy;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const NwsbIcon(NwsbMarks.earn, size: 18, color: Colors.black, strokeWidth: 1.6),
                    ),
                    const SizedBox(width: 8),
                    const AppThinkingLoader(size: 16, state: OrbState.composing, blackCircle: true, circlePad: 4),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        phase == NwsbUpdatePhase.ready || phase == NwsbUpdatePhase.installing
                            ? 'NowssB update downloaded'
                            : busy
                                ? 'Updating NowssB…'
                                : 'A new NowssB update is ready',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _UpdateBody(
                  idleText: 'The update downloads inside NowssB — it keeps going if you close this or leave the app — '
                      'then Android shows its install confirmation.',
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: busy ? const Text('Hide') : const EditableLabel('main.NowssbApp', 'Later'),
                    ),
                    const _PrimaryButton(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton();

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: NwsbUpdater.instance, builder: (context, _) => _build());

  Widget _build() {
    final updater = NwsbUpdater.instance;
    final phase = updater.phase;
    final String label;
    VoidCallback? action;
    switch (phase) {
      case NwsbUpdatePhase.idle:
        label = 'Update now';
        action = updater.download;
      case NwsbUpdatePhase.failed:
        label = 'Try again';
        action = updater.download;
      case NwsbUpdatePhase.downloading:
      case NwsbUpdatePhase.retrying:
      case NwsbUpdatePhase.verifying:
        label = 'Updating…';
      case NwsbUpdatePhase.ready:
        label = 'Install';
        action = updater.install;
      case NwsbUpdatePhase.installing:
        label = 'Opening…';
    }
    return FilledButton(
      style: FilledButton.styleFrom(backgroundColor: NwsbColors.goldLight, foregroundColor: NwsbColors.deep),
      onPressed: action,
      child: Text(label),
    );
  }
}

/// Status text and progress, shared by the dialog and the required screen.
class _UpdateBody extends StatelessWidget {
  const _UpdateBody({required this.idleText});

  final String idleText;

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: NwsbUpdater.instance, builder: (context, _) => _build());

  Widget _build() {
    final updater = NwsbUpdater.instance;
    final phase = updater.phase;
    final showProgress = updater.busy || phase == NwsbUpdatePhase.failed;
    final p = updater.progress;
    final text = phase == NwsbUpdatePhase.idle || updater.message.isEmpty ? idleText : updater.message;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showProgress) ...[
          SizedBox(
            width: 3,
            height: 64,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 3,
                height: 64 * ((p ?? 0.08).clamp(0.06, 1.0)),
                decoration: BoxDecoration(
                  color: NwsbColors.goldLight,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(color: Color(0xCCFFFFFF), height: 1.45)),
              if (showProgress) ...[
                const SizedBox(height: 8),
                Text(
                  p == null ? updater.sizeLabel : '${updater.sizeLabel} · ${(p * 100).floor()}%',
                  style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Covers the app when this build is below the manifest's minBuild.
class _RequiredUpdateScreen extends StatelessWidget {
  const _RequiredUpdateScreen();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NwsbColors.deep,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(24)),
                child: const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.system_update_rounded, color: NwsbColors.goldLight, size: 36),
                  SizedBox(height: 14),
                  Text(
                    'Update required',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 10),
                  _UpdateBody(
                    idleText: 'This version of NowssB is no longer supported. Download the update to keep using the app.',
                  ),
                  SizedBox(height: 16),
                  Align(alignment: Alignment.centerRight, child: _PrimaryButton()),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
