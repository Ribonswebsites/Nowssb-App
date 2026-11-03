/// The store research sheet from the website (`nwsb-fs` / part077.js).
///
/// Each store asks once. Agreeing in one does not agree for the others.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../admin/template/editable.dart';

Future<void> askStoreTerms(
  BuildContext context, {
  required String which,
  required String head,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'nwsb_terms_$which';
  if (prefs.getString(key) == '1') return;
  if (!context.mounted) return;
  final agreed = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Store terms',
    barrierColor: const Color(0xF008080A),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, __) => _StoreTermsSheet(head: head),
  );
  if (agreed == true) {
    await prefs.setString(key, '1');
    return;
  }
  if (context.mounted) Navigator.of(context).maybePop();
}

class StoreTermsHost extends StatefulWidget {
  const StoreTermsHost({
    super.key,
    required this.which,
    required this.head,
    required this.child,
  });

  final String which;
  final String head;
  final Widget child;

  @override
  State<StoreTermsHost> createState() => _StoreTermsHostState();
}

class _StoreTermsHostState extends State<StoreTermsHost> {
  bool _asked = false;

  /// The Store tab is kept mounted (off-stage, tickers muted) inside the nav
  /// shell's IndexedStack from the first frame. Asking from initState put
  /// the Store's research sheet over the HOME on every fresh launch. Ask
  /// only once this page is really on screen: TickerMode is a dependency, so
  /// this runs again the moment the tab is selected.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked || !TickerMode.of(context)) return;
    _asked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!TickerMode.of(context)) {
        _asked = false;
        return;
      }
      askStoreTerms(context, which: widget.which, head: widget.head);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _StoreTermsSheet extends StatelessWidget {
  const _StoreTermsSheet({required this.head});
  final String head;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: ColoredBox(
          color: const Color(0xF508080A),
          child: Stack(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(20, pad.top + 72, 20, pad.bottom + 24),
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const SizedBox(
                        width: 280,
                        height: 360,
                        child: EditableImage.asset(
                          'assets/notifications/hands-offer.png',
                          fit: BoxFit.cover,
                          alignment: Alignment(0, -0.05),
                          slot: 'store.StoreTermsSheet',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    head.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const EditableLabel('store_terms_sheet.StoreTermsSheet',
                    'Read this before you buy. Agreeing records that you have.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0x8CFFFFFF),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const EditableLabel('store_terms_sheet.StoreTermsSheet',
                    'RESEARCH PROPOSAL',
                    style: TextStyle(
                      color: Color(0xCCE8D5A3),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const EditableLabel('store_terms_sheet.StoreTermsSheet',
                    'Natural-Origin Word Science (NOWS): a framework for exploring the origin of human language.',
                    style: TextStyle(
                      color: Color(0xEBFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const EditableLabel('store_terms_sheet.StoreTermsSheet',
                    'This store describes words and meanings by their sounds, under a hypothesis offered for testing. It is not an established finding of historical linguistics, and it is not medical advice. Purchases unlock written work produced under that framework.',
                    style: TextStyle(
                      color: Color(0x9EFFFFFF),
                      fontSize: 13,
                      height: 1.75,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Pill(
                    label: 'I Agree · Continue',
                    filled: true,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                  const SizedBox(height: 12),
                  _Pill(
                    label: 'Not Now',
                    filled: false,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              Positioned(
                top: pad.top + 12,
                right: 16,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 8,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(false),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.close, color: Color(0xFF0B0B0B), size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: const Color(0x55FFFFFF)),
          ),
          child: EditableLabel('store_terms_sheet.Pill',
            label,
            style: TextStyle(
              color: filled ? const Color(0xFF0B0B0B) : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
