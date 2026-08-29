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
import 'app_backdrop.dart';

class PageShell extends StatefulWidget {
  const PageShell({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.film,
    required this.slivers,
    this.onBack,
  });

  final String eyebrow;
  final String title;

  /// The page's own film. It IS the page rather than decoration on it, so it
  /// takes a feature lease and holds its decoder while the cards below come
  /// and go.
  final String film;

  final List<Widget> slivers;
  final VoidCallback? onBack;

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
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          Positioned.fill(
            child: const AppBackdrop(),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC060C18),
                    Color(0xF0060C18),
                    Color(0xFA060C18),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: CustomScrollView(
                  slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    child: Row(
                      children: [
                        if (widget.onBack != null) ...[
                          GestureDetector(
                            onTap: widget.onBack,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back,
                                  size: 19, color: NwsbColors.ink),
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.eyebrow.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w700,
                                  color: NwsbColors.gold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ...widget.slivers,
                // Clear of the bottom nav.
                  const SliverToBoxAdapter(child: SizedBox(height: 108)),
                ],
              ),
            ),
          ),
          ),
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
              Text(
                eyebrow,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0x99FFFFFF),
                ),
              ),
              Text(
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
                    Text(
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
