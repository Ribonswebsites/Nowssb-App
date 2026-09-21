/// Quick access — glass + background video + TV-frame nav preview.
///
/// Nav customize (shape / colour / icons) kept; chrome matches the
/// notifications-tab language (glass cards, gold accents, soft film).
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../data/settings.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/app_thinking_loader.dart';
import '../widgets/tv_frame.dart';

class QuickAccessScreen extends StatefulWidget {
  const QuickAccessScreen({super.key});
  @override
  State<QuickAccessScreen> createState() => _QuickAccessScreenState();
}

class _QuickAccessScreenState extends State<QuickAccessScreen> {
  late String shape, color, corner;
  late List<String> slots;

  /// Available-features pool is hidden until the user opens +.
  bool _picking = false;

  static const int maxSlots = 5;

  @override
  void initState() {
    super.initState();
    final s = Settings.instance;
    shape = s.navShape;
    color = s.navColor;
    corner = s.navCorner;
    slots = [...s.navSlots];
  }

  static const features = <Map<String, String>>[
    {
      'id': 'connect',
      'label': 'Connect',
      'img':
          'https://media.nowssb.com/migrated-images/ea559460014dd8d9_file_00000000b84c7209ab496862cacd6a7f_kagsie.png'
    },
    {
      'id': 'practice',
      'label': 'Practice',
      'img':
          'https://media.nowssb.com/migrated-images/44ed38a222535b9c_38538b80-56d8-11f1-8fad-095787cce754_xam2bb.png'
    },
    {
      'id': 'library',
      'label': 'Library',
      'img':
          'https://media.nowssb.com/migrated-images/62e5d0908e54a2a6_c500a990-56cf-11f1-8fad-095787cce754_1_zqzbal.png'
    },
    {
      'id': 'store',
      'label': 'Store',
      'img':
          'https://media.nowssb.com/migrated-images/86a1283688196499_ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png'
    },
    {
      'id': 'profile',
      'label': 'Profile',
      'img':
          'https://media.nowssb.com/migrated-images/3979b9fa35b579e6_62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png'
    },
    {
      'id': 'progress',
      'label': 'Progress',
      'img':
          'https://media.nowssb.com/migrated-images/0480c10b8a8d79dd_file_00000000ae607208aa51504989648920_ml2czc.png'
    },
    {
      'id': 'wordscience',
      'label': 'Word Sci',
      'img':
          'https://media.nowssb.com/migrated-images/dd44cf9fc35b783c_file_0000000086d872089ce376674620d5f3_mtfftb.png'
    },
    {
      'id': 'meaningstore',
      'label': 'Meaning',
      'img':
          'https://media.nowssb.com/migrated-images/1a5f669e63dbae9d_file_00000000854881fa9a548a68fae59c15_w1utya.png'
    },
    {
      'id': 'search',
      'label': 'Search',
      'img':
          'https://media.nowssb.com/migrated-images/8d85320f63c3e176_file_00000000029c7208b5e915d9af2c480c_tuccwo.png'
    },
    {
      'id': 'cart',
      'label': 'Cart',
      'img':
          'https://media.nowssb.com/migrated-images/311c26afee2bc52c_file_00000000f02c72088cd128f3f4b08af5_vskoom.png'
    },
    {
      'id': 'wishlist',
      'label': 'Wishlist',
      'img':
          'https://media.nowssb.com/migrated-images/a74a9935fb237eb8_file_0000000055d8720895f7ba98c4a7bf4a_s2lzab.png'
    },
    {
      'id': 'routines',
      'label': 'Routines',
      'img':
          'https://media.nowssb.com/migrated-images/307233cd22669455_file_00000000f740820ba6aaa761133e8889_fitm0p.png'
    },
    {
      'id': 'chat',
      'label': 'Chat',
      'img':
          'https://media.nowssb.com/migrated-images/db15f3026ea179dc_1ae1b990-5bf2-11f1-8248-b91d5cd919c2_z3xi3j.png'
    },
    {
      'id': 'ai',
      'label': 'AI Rx',
      'img':
          'https://media.nowssb.com/migrated-images/41c9ed21b2822c90_file_0000000062a882089abd27eb90ea3945_ngqyu6.png'
    },
    {
      'id': 'streak',
      'label': 'Streak',
      'img':
          'https://media.nowssb.com/migrated-images/f82047a0e727766b_file_0000000010fc820891f9e15a38316d2b_ffffhq.png'
    },
    {
      'id': 'settings',
      'label': 'Settings',
      'img':
          'https://media.nowssb.com/migrated-images/523b5889d13cb14a_260480b0-56d8-11f1-8fad-095787cce754_rz6zbi.png'
    },
    {
      'id': 'everything',
      'label': 'Everything',
      'img':
          'https://media.nowssb.com/migrated-images/47f9e2c9fad5a78f_file_00000000be547207aaa56f43cfef4f67_nxhvw0.png'
    },
  ];

  Map<String, String> getById(String id) =>
      features.firstWhere((x) => x['id'] == id, orElse: () => features.first);

  List<String> get _availableIds => features
      .map((f) => f['id']!)
      .where((id) => !slots.contains(id))
      .toList();

  void _removeSlot(String id) {
    setState(() {
      if (slots.length > 1) slots.remove(id);
    });
  }

  void _addFromPool(String id) {
    setState(() {
      if (slots.contains(id)) return;
      if (slots.length >= maxSlots) {
        slots.removeAt(0); // swap oldest when full
      }
      slots.add(id);
      if (slots.length >= maxSlots) _picking = false;
    });
  }

  void _openPicker() {
    HapticFeedback.selectionClick();
    setState(() => _picking = true);
  }

  void _closePicker() => setState(() => _picking = false);

  void _reset() {
    setState(() {
      shape = 'default';
      color = 'glass';
      corner = 'rounded';
      slots = ['connect', 'practice', 'library', 'store', 'profile'];
      _picking = false;
    });
  }

  Future<void> _apply() async {
    HapticFeedback.mediumImpact();
    await Settings.instance.setNavConfig(
      shape: shape,
      color: color,
      corner: corner,
      slots: slots,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Applied to your nav ✓')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.1),
                    radius: 0.88,
                    colors: [
                      Color(0x00000000),
                      Color(0x24000000),
                      Color(0x57000000),
                      Color(0x94000000),
                    ],
                    stops: [0.30, 0.58, 0.80, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Soft looping film under glass cards (notification-tab language).
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.35,
                child: NwsbVideo(
                  asset: 'assets/video/hero-bg.mp4',
                  priority: ClipPriority.decoration,
                  autoplay: true,
                  loop: true,
                  showPoster: true,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(onReset: _reset),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 28 + bottom),
                    children: [
                      const _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CUSTOMIZE YOUR NAVIGATION',
                              style: TextStyle(
                                color: NwsbColors.mist,
                                letterSpacing: 2.5,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Quick access',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Reshape your bottom navigation — shape, colour, and the icons it shows.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 14),
                            Row(
                              children: [
                                AppThinkingLoader(
                                  size: 30,
                                  state: OrbState.solving,
                                  circlePad: 7,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Live preview updates as you pick tiles',
                                    style: TextStyle(
                                      color: Color(0xCCFFFFFF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SecLabel('Nav preview'),
                            const SizedBox(height: 10),
                            TvFrame(
                              asset: 'assets/video/tv-screen.mp4',
                              frame: DeviceFrame.tvLandscape,
                              showPoster: true,
                              overlay: _NavPreviewOverlay(
                                shape: shape,
                                color: color,
                                corner: corner,
                                slots: slots,
                                getById: getById,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SecLabel('Shape'),
                            const SizedBox(height: 10),
                            _Options(
                              values: const {
                                'default': 'Default',
                                'pill': 'Floating Pill',
                                'rect': 'Floating Rectangle',
                              },
                              selected: shape,
                              onTap: (v) => setState(() => shape = v),
                            ),
                            if (shape == 'rect') ...[
                              const SizedBox(height: 10),
                              _Options(
                                values: const {
                                  'rounded': 'Rounded Corners',
                                  'edge': 'Edge Corners',
                                },
                                selected: corner,
                                onTap: (v) => setState(() => corner = v),
                              ),
                            ],
                            const SizedBox(height: 18),
                            const _SecLabel('Colour'),
                            const SizedBox(height: 10),
                            _Options(
                              values: const {
                                'glass': 'Default Glass',
                                'black': 'Black',
                              },
                              selected: color,
                              onTap: (v) => setState(() => color = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SecLabel(
                                'In your nav · ${slots.length} / $maxSlots'),
                            const SizedBox(height: 8),
                            const Text(
                              'Up to five destinations plus a + slot. Tap a black tile to remove it. Tap + to open the available set in a separate panel.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _InNavRow(
                              slots: slots,
                              getById: getById,
                              onRemove: _removeSlot,
                              onAddTap: _openPicker,
                              picking: _picking,
                            ),
                          ],
                        ),
                      ),
                      if (_picking) ...[
                        const SizedBox(height: 14),
                        _PoolCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: _SecLabel('Available features'),
                                  ),
                                  TextButton(
                                    onPressed: _closePicker,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Pick a feature to fill the + slot.',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _FeatureGrid(
                                ids: _availableIds,
                                slots: slots,
                                getById: getById,
                                onToggle: _addFromPool,
                                blackTiles: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _apply,
                          icon: const Icon(Icons.check),
                          label: const Text('Apply Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NwsbColors.goldLight,
                            foregroundColor: NwsbColors.deep,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Quick access',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onReset,
            child: const Text(
              'Reset',
              style: TextStyle(color: NwsbColors.goldLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            color: const Color(0x28FFFFFF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x33FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SecLabel extends StatelessWidget {
  const _SecLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: NwsbColors.goldLight,
        letterSpacing: 2,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({
    required this.values,
    required this.selected,
    required this.onTap,
  });
  final Map<String, String> values;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    // Custom pills — ChoiceChip M3 was painting white surfaces with white
    // labels (invisible). Dark text on white / gold keeps every label readable.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.entries.map((e) {
        final on = e.key == selected;
        return GestureDetector(
          onTap: () => onTap(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: on ? NwsbColors.goldLight : Colors.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: on ? NwsbColors.goldLight : const Color(0x22000000),
              ),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                color: NwsbColors.deep,
                fontSize: 12,
                fontWeight: on ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NavPreviewOverlay extends StatelessWidget {
  const _NavPreviewOverlay({
    required this.shape,
    required this.color,
    required this.corner,
    required this.slots,
    required this.getById,
  });
  final String shape;
  final String color;
  final String corner;
  final List<String> slots;
  final Map<String, String> Function(String) getById;

  @override
  Widget build(BuildContext context) {
    final radius = shape == 'pill'
        ? 40.0
        : shape == 'rect'
            ? (corner == 'rounded' ? 20.0 : 2.0)
            : 28.0;
    final bg =
        color == 'black' ? Colors.black : const Color(0xDD182033);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0x44FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              for (final id in slots)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _NetIcon(getById(id)['img']!, 26),
                      const SizedBox(height: 3),
                      Text(
                        getById(id)['label']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// In-nav row: compact black tiles inside the glass card + trailing +.
class _InNavRow extends StatelessWidget {
  const _InNavRow({
    required this.slots,
    required this.getById,
    required this.onRemove,
    required this.onAddTap,
    required this.picking,
  });
  final List<String> slots;
  final Map<String, String> Function(String) getById;
  final ValueChanged<String> onRemove;
  final VoidCallback onAddTap;
  final bool picking;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < slots.length; i++)
          _BlackTile(
            label: getById(slots[i])['label']!,
            img: getById(slots[i])['img']!,
            badge: '${i + 1}',
            onTap: () => onRemove(slots[i]),
          ),
        _PlusTile(active: picking, onTap: onAddTap),
      ],
    );
  }
}

class _BlackTile extends StatelessWidget {
  const _BlackTile({
    required this.label,
    required this.img,
    required this.badge,
    required this.onTap,
  });
  final String label;
  final String img;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NetIcon(img, 22),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 6,
              child: Text(
                badge,
                style: const TextStyle(
                  color: NwsbColors.goldLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlusTile extends StatelessWidget {
  const _PlusTile({required this.onTap, required this.active});
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A1520) : Colors.black,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? NwsbColors.goldLight : const Color(0x55E8D5A3),
            width: active ? 1.4 : 1,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: NwsbColors.goldLight, size: 26),
            SizedBox(height: 2),
            Text(
              'Add',
              style: TextStyle(
                color: NwsbColors.goldLight,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Available pool wrapper — visually distinct from the in-nav glass card.
class _PoolCard extends StatelessWidget {
  const _PoolCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xF00A0E18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x55E8D5A3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({
    required this.ids,
    required this.slots,
    required this.getById,
    required this.onToggle,
    this.blackTiles = false,
  });
  final List<String> ids;
  final List<String> slots;
  final Map<String, String> Function(String) getById;
  final ValueChanged<String> onToggle;
  final bool blackTiles;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'All features are in your nav',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }
    if (blackTiles) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final id in ids)
            _BlackTile(
              label: getById(id)['label']!,
              img: getById(id)['img']!,
              badge: '+',
              onTap: () => onToggle(id),
            ),
        ],
      );
    }
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.95,
      children: ids.map((id) {
        final f = getById(id);
        final on = slots.contains(id);
        return GestureDetector(
          onTap: () => onToggle(id),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: on
                    ? const Color(0x88E8D5A3)
                    : const Color(0x33FFFFFF),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _NetIcon(f['img']!, 22),
                      const SizedBox(height: 4),
                      Text(
                        f['label']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: on ? NwsbColors.goldLight : Colors.white70,
                          fontSize: 9,
                          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (on)
                  Positioned(
                    top: 4,
                    right: 6,
                    child: Text(
                      '${slots.indexOf(id) + 1}',
                      style: const TextStyle(
                        color: NwsbColors.goldLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NetIcon extends StatelessWidget {
  const _NetIcon(this.url, this.size);
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.circle_outlined, size: size, color: Colors.white54),
    );
  }
}
