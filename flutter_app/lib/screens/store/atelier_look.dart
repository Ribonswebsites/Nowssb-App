/// Word Atelier looks. The current one and the previous one both stay in
/// the list, so a later update does not throw the last page away.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AtelierLook { ink, paper }

class AtelierLooks extends ChangeNotifier {
  AtelierLooks._();
  static final instance = AtelierLooks._();

  static const _key = 'nwsb_atelier_look_v1';

  AtelierLook current = AtelierLook.ink;
  var _ready = false;

  /// Newest first. [current] is the one on screen.
  List<({AtelierLook look, String name, String note})> get list => const [
        (look: AtelierLook.ink, name: 'White cards on black', note: 'Current'),
        (look: AtelierLook.paper, name: 'Dark cards on white', note: 'Previous'),
      ];

  Future<void> load() async {
    if (_ready) return;
    _ready = true;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == 'paper') current = AtelierLook.paper;
    if (raw == 'ink') current = AtelierLook.ink;
    notifyListeners();
  }

  Future<void> use(AtelierLook look) async {
    current = look;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, look.name);
  }
}

class AtelierScope extends InheritedWidget {
  const AtelierScope({super.key, required this.whiteCards, required super.child});
  final bool whiteCards;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AtelierScope>()?.whiteCards ?? false;

  @override
  bool updateShouldNotify(AtelierScope oldWidget) => oldWidget.whiteCards != whiteCards;
}

void showAtelierLooks(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF101114),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (ctx) => ListenableBuilder(
      listenable: AtelierLooks.instance,
      builder: (_, __) {
        final now = AtelierLooks.instance.current;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Looks', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Pick the current page or bring the previous one back.',
                  style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 13)),
              const SizedBox(height: 12),
              for (final item in AtelierLooks.instance.list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  subtitle: Text(item.note, style: const TextStyle(color: Color(0xFFE8D5A3))),
                  trailing: now == item.look ? const Icon(Icons.check, color: Color(0xFFE8D5A3)) : null,
                  onTap: () {
                    AtelierLooks.instance.use(item.look);
                    Navigator.of(ctx).pop();
                  },
                ),
            ]),
          ),
        );
      },
    ),
  );
}
