/// Admin → Templates. Every shipped section (header through the last one)
/// and every banner. This list is the app's, not the page's: deleting a
/// section never removes it from here. Open a page to put one back.
library;

import 'package:flutter/material.dart';

import '../screens/home_fashion.dart';
import '../screens/home_normal.dart';
import 'admin_kit.dart';
import 'editor/ui_editor_screen.dart';
import 'layout/template_sections.dart';

class TemplatesAdminScreen extends StatefulWidget {
  const TemplatesAdminScreen({super.key});

  @override
  State<TemplatesAdminScreen> createState() => _TemplatesAdminScreenState();
}

class _TemplatesAdminScreenState extends State<TemplatesAdminScreen> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _hit(String s) {
    final q = _q.trim().toLowerCase();
    return q.isEmpty || s.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final homes = <(String, String, List<(String, String)>)>[
      (
        'home.normal',
        'Normal home',
        [for (final id in kNormalSectionOrder) (id, kNormalSectionTitles[id] ?? id)],
      ),
      (
        'home.fashion',
        'Fashion home',
        [for (final id in kFashionSectionOrder) (id, kFashionSectionTitles[id] ?? id)],
      ),
      (
        'store.home',
        'Store',
        const [
          ('header', 'Title & bag'),
          ('hype', 'Most hyped'),
          ('tabs', 'Shop / Resell tabs'),
          ('rotator', 'Picture rotator'),
          ('halfoff', 'Half-off rail'),
          ('atelier', 'Word Atelier'),
          ('meaning', 'Meaning Store'),
          ('signature', 'Signature Store'),
          ('promo', 'Split promo banner'),
          ('connect', 'NowssB Connect'),
          ('ebooks', 'eBooks'),
          ('plans', 'Subscription plans'),
          ('disclaimer', 'Disclaimer'),
          ('credits', 'Credits'),
        ],
      ),
    ];
    return AdminPage(
      eyebrow: 'Always here',
      title: 'Templates',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
        children: [
          const Text(
            'Every section from the header down, and every banner. Deleting one on a page does not remove it from Templates. Open the page, then Put back.',
            style: TextStyle(color: kDim, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _q = v),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search templates',
              hintStyle: const TextStyle(color: kFaint),
              prefixIcon: const Icon(Icons.search, color: kGold, size: 20),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF111A2B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          for (final (page, title, rows) in homes) ...[
            if (rows.any((r) => _hit(r.$2) || _hit(r.$1))) ...[
              SectionHead('On this page', title),
              for (final (id, name) in rows)
                if (_hit(name) || _hit(id))
                  _Row(
                    title: name,
                    sub: 'Put back on $title',
                    onTap: () {
                      bigFeel();
                      openUiEditor(context, page: page, openTemplates: true, putBack: id);
                    },
                  ),
            ],
          ],
          for (final (name, kinds) in kTemplateCategories) ...[
            if (kinds.any((k) => _hit(kTemplateNames[k] ?? k))) ...[
              SectionHead('Add again', name),
              for (final k in kinds)
                if (_hit(kTemplateNames[k] ?? k))
                  _Row(
                    title: kTemplateNames[k] ?? k,
                    sub: 'Adds a new one on Normal home',
                    onTap: () {
                      bigFeel();
                      openUiEditor(context, openTemplates: true, addKind: k);
                    },
                  ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.sub, required this.onTap});
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        onTap: onTap,
        child: Row(children: [
          const Icon(Icons.dashboard_customize_rounded, color: kGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 11.5)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: kFaint),
        ]),
      ),
    );
  }
}
