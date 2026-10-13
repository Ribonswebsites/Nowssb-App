/// Rebuilt Menu & Settings page (behind `newui_menu_settings`).
///
/// Soft violet glassmorphism, a slow procedural backdrop (CustomPainter, no
/// bundled assets), one search field and grouped glass sections. Page-local
/// widgets until NowssB Bug Hunter's shared kit lands on main.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../widgets/app_backdrop.dart';
import 'menu_settings_model.dart';

typedef SectionLoader = Future<List<SettingSection>> Function();

class GlassMenuSettingsPage extends StatefulWidget {
  const GlassMenuSettingsPage({
    super.key,
    required this.load,
    this.isOnline,
    this.displayName,
    this.reduceEffects = false,
    this.background,
  });

  /// Behind the glass. Defaults to the app's original [AppBackdrop]
  /// (Fashion Plus film / saved still). Tests pass a poster frame.
  final Widget? background;

  final SectionLoader load;
  final Future<bool> Function()? isOnline;
  final String? displayName;
  final bool reduceEffects;

  @override
  State<GlassMenuSettingsPage> createState() => _GlassMenuSettingsPageState();
}

class _GlassMenuSettingsPageState extends State<GlassMenuSettingsPage> {
  final _search = TextEditingController();
  MenuSettingsStatus _status = MenuSettingsStatus.loading;
  List<SettingSection> _sections = const [];
  String _q = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _q = _search.text));
    _reload();
  }

  @override
  void didUpdateWidget(covariant GlassMenuSettingsPage old) {
    super.didUpdateWidget(old);
    // Parent rebuilt (e.g. a toggle changed): refresh rows without a spinner.
    if (_status == MenuSettingsStatus.ready ||
        _status == MenuSettingsStatus.offline) {
      widget.load().then((s) {
        if (mounted) setState(() => _sections = s);
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _status = MenuSettingsStatus.loading);
    try {
      final online = await (widget.isOnline?.call() ?? Future.value(true));
      final s = await widget.load();
      if (!mounted) return;
      setState(() {
        _sections = s;
        _status =
            online ? MenuSettingsStatus.ready : MenuSettingsStatus.offline;
      });
    } catch (_) {
      if (mounted) setState(() => _status = MenuSettingsStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = widget.reduceEffects ||
        MediaQuery.maybeOf(context)?.disableAnimations == true;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: widget.background ?? const AppBackdrop()),
        SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Header(name: widget.displayName),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _Glass(
                blur: !reduce,
                child: TextField(
                  key: const Key('ms_search'),
                  controller: _search,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search settings',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white70),
                  ),
                ),
              ),
            ),
            Expanded(child: _body(!reduce)),
          ]),
        ),
      ]),
    );
  }

  Widget _body(bool blur) {
    switch (_status) {
      case MenuSettingsStatus.loading:
        return const Center(
            key: Key('ms_loading'),
            child: CircularProgressIndicator(color: Colors.white));
      case MenuSettingsStatus.error:
        return _Message(
          key: const Key('ms_error'),
          icon: Icons.cloud_off_rounded,
          text: "Settings couldn't load.",
          action: 'Try again',
          onAction: _reload,
        );
      case MenuSettingsStatus.ready:
      case MenuSettingsStatus.offline:
        final list = filterSections(_sections, _q);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            if (_status == MenuSettingsStatus.offline)
              const Padding(
                key: Key('ms_offline'),
                padding: EdgeInsets.only(bottom: 12),
                child: Text("You're offline. Changes save on this device.",
                    style: TextStyle(color: Color(0xFFFFD6A5))),
              ),
            if (list.isEmpty)
              _Message(
                key: const Key('ms_empty'),
                icon: Icons.spa_outlined,
                text: _q.isEmpty ? 'Nothing here yet.' : 'No settings match "$_q".',
              ),
            for (final s in list) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
                child: Text(s.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              _Glass(
                blur: blur,
                child: Column(children: [
                  for (var i = 0; i < s.items.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: Colors.white12),
                    _ItemTile(item: s.items[i]),
                  ]
                ]),
              ),
            ],
          ],
        );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({this.name});
  final String? name;
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(children: [
        if (canPop)
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          )
        else
          const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Settings',
                style: TextStyle(
                    color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
            if (name != null && name!.isNotEmpty)
              Text(name!, style: const TextStyle(color: Colors.white60)),
          ]),
        ),
      ]),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});
  final SettingItem item;
  @override
  Widget build(BuildContext context) {
    final color = item.destructive ? const Color(0xFFFFA3B1) : Colors.white;
    final isToggle = item.kind == SettingKind.toggle;
    return ListTile(
      key: Key('ms_item_${item.id}'),
      leading: Icon(item.icon, color: color.withValues(alpha: 0.85)),
      title: Text(item.title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      subtitle: item.subtitle == null
          ? null
          : Text(item.subtitle!, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5)),
      trailing: isToggle
          ? Switch(
              value: item.value,
              activeTrackColor: const Color(0xFF9C86FF),
              onChanged: item.onChanged,
            )
          : const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      onTap: isToggle ? () => item.onChanged?.call(!item.value) : item.onTap,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(
      {super.key, required this.icon, required this.text, this.action, this.onAction});
  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white54, size: 40),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          if (action != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A1A1A),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              ),
              child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      );
}

/// Frosted card per /workspace/specs/card-reference-exact.png: white tint
/// ~17%, strong blur, 26px corners, 1px white border at 30%, soft shadow.
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.blur = true});
  final Widget child;
  final bool blur;
  static const _r = BorderRadius.all(Radius.circular(26));
  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: blur ? 0.17 : 0.24),
        borderRadius: _r,
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(borderRadius: _r, boxShadow: [
        BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10)),
      ]),
      child: ClipRRect(
        borderRadius: _r,
        child: blur
            ? RepaintBoundary(
                child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: box))
            : box,
      ),
    );
  }
}
