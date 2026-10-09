/// The shell every destination other than the homes wears.
///
/// A film behind, a scrim over it so white type stays readable, a title row,
/// and the page's own content on top. Written once because four screens want
/// exactly this and four hand-built copies is four things to keep in step —
/// which is the mistake the website's stylesheet is still paying for.
library;

import 'package:flutter/material.dart';

import '../data/settings.dart';
import '../theme/tokens.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import 'app_backdrop.dart';
import '../screens/store/bag_ui.dart';
import '../admin/template/editable.dart';
import 'glass_wrap.dart';

class PageShell extends StatefulWidget {
  const PageShell({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.film,
    required this.slivers,
    this.subtitle,
    this.onBack,
    this.usePageFilm = false,
    this.onStorePicker,
    this.background,
    this.actions = const [],
    this.plain = false,
    this.canvas,
    this.bodyMax = 860,
  });

  /// Extra controls at the end of the title row (e.g. Quick access Reset).
  final List<Widget> actions;

  /// Optional page-specific backdrop in place of [AppBackdrop] (same scrim
  /// and header on top) — e.g. Widgets keeps its Fashion photo.
  final Widget? background;

  final String eyebrow;
  final String title;
  /// Optional secondary line under [title] (e.g. Word Atelier under NowssB Store).
  final String? subtitle;

  /// The page's own film. When [usePageFilm] is true the film loops behind
  /// the page (Store / Meaning / Ebooks). Otherwise AppBackdrop stays
  /// (Fashion-home film via Settings).
  final String film;

  /// Store pages set this so the looping NwsbVideo page film is visible
  /// again under a light scrim — never wipe store films for a flat backdrop.
  final bool usePageFilm;

  final List<Widget> slivers;
  final VoidCallback? onBack;

  /// Top button — opens AJIO-style “Please select the store” sheet.
  final VoidCallback? onStorePicker;

  /// White page, no film. Store uses this. Cards stay dark glass.
  final bool plain;

  /// Flat page colour, no film. Word Atelier's black look uses this.
  final Color? canvas;

  /// Cap on the scrolling column. Phone width is unaffected.
  final double bodyMax;

  @override
  State<PageShell> createState() => _PageShellState();
}

class _PageShellState extends State<PageShell> {
  @override
  void initState() {
    super.initState();
    Settings.instance.addListener(_onSettings);
  }

  @override
  void dispose() {
    Settings.instance.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bare = widget.canvas != null;
    final plain = widget.plain && !bare;
    final titleColor = plain ? NwsbColors.ink : Colors.white;
    final subColor = plain ? const Color(0xFF5C564E) : const Color(0xCCFFFFFF);
    return Scaffold(
      backgroundColor: widget.canvas ?? (plain ? const Color(0xFFF6F4EF) : NwsbColors.deep),
      body: StoreSurface(
        light: plain,
        child: Stack(
        children: [
          if (!plain && !bare)
          Positioned.fill(
            child: widget.usePageFilm && widget.film.isNotEmpty
                ? NwsbVideo(
                    asset: widget.film,
                    priority: ClipPriority.decoration,
                    autoplay: true,
                    loop: true,
                    slot: 'page_shell.PageShell',
                  )
                : (widget.background ?? const AppBackdrop()),
          ),
          if (!plain && !bare && widget.usePageFilm)
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66060C18),
                        Color(0x88060C18),
                        Color(0xAA060C18),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (!plain && !bare) ...[
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
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x42000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x57000000),
                      ],
                      stops: [0, 0.20, 0.76, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.bodyMax),
                child: CustomScrollView(
                  slivers: [
                SliverToBoxAdapter(child: _header(plain, titleColor, subColor)),
                ...widget.slivers,
                const SliverToBoxAdapter(child: SizedBox(height: 108)),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
      ),
    );
  }

  /// Controls on one row. The name on the next, full width — a title beside
  /// the bag and Stores was being crushed into a column of syllables.
  Widget _header(bool plain, Color titleColor, Color subColor) {
    final back = widget.onBack == null
        ? null
        : GestureDetector(
            onTap: widget.onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.arrow_back, size: 19, color: NwsbColors.ink),
            ),
          );
    final stores = widget.onStorePicker == null
        ? null
        : GestureDetector(
            onTap: widget.onStorePicker,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                color: plain ? const Color(0xFF16181E) : const Color(0xE616181E),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_outlined, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Stores',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (back != null) back,
              const Spacer(),
              if (widget.actions.isNotEmpty) ...widget.actions,
              if (widget.onStorePicker != null) ...[
                if (widget.actions.isNotEmpty) const SizedBox(width: 8),
                const StoreBagBar(),
                const SizedBox(width: 8),
                stores!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (widget.eyebrow.trim().isNotEmpty) ...[
            Text(
              widget.eyebrow.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w700,
                color: NwsbColors.gold,
              ),
            ),
            const SizedBox(height: 4),
          ],
          EditableLabel(
            'page_shell.PageShell',
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: titleColor,
              height: 1.05,
              letterSpacing: -0.4,
            ),
          ),
          if (widget.subtitle != null && widget.subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              widget.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: subColor,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The row of white-disc + two lines that introduces a block on a dark page.
class DarkHead extends StatelessWidget {
  const DarkHead({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: NwsbColors.ink),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              EditableLabel('page_shell.DarkHead',
                eyebrow,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0x99FFFFFF),
                ),
              ),
              EditableLabel('page_shell.DarkHead',
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A word, as a row you can press. Used by Practice, Library and the Store,
/// so the same word looks the same wherever it turns up.
class WordRow extends StatelessWidget {
  const WordRow({
    super.key,
    required this.word,
    required this.deva,
    required this.sub,
    this.trailing,
    this.onTap,
  });

  final String word;
  final String deva;
  final String sub;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF14141C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                deva.isNotEmpty ? deva.characters.first : word.characters.first,
                style: const TextStyle(
                  fontSize: 20,
                  color: NwsbColors.goldLight,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    word,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    EditableLabel('page_shell.WordRow',
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0x8CFFFFFF),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.arrow_forward,
                    size: 17, color: Color(0xB3FFFFFF)),
          ],
        ),
      ),
    );
  }
}
