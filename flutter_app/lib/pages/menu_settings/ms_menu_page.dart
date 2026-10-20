/// Rebuilt hamburger menu: four calm groups instead of 20 cards.
library;

import 'package:flutter/material.dart';

import 'ms_widgets.dart';

class MsEntry {
  const MsEntry(this.id, this.icon, this.title, this.subtitle, this.onTap);
  final String id;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
}

class MsGroup {
  const MsGroup(this.title, this.entries);
  final String title;
  final List<MsEntry> entries;
}

class MsMenuPage extends StatelessWidget {
  const MsMenuPage({super.key, required this.groups, this.greeting});
  final List<MsGroup> groups;
  final String? greeting;
  @override
  Widget build(BuildContext context) => MsScaffold(
        title: 'Menu',
        subtitle: greeting ?? 'Where would you like to rest today?',
        children: [
          for (final g in groups)
            MsSection(title: g.title, rows: [
              for (final e in g.entries)
                MsRow(key: Key('ms_menu_${e.id}'), icon: e.icon, title: e.title, subtitle: e.subtitle, onTap: e.onTap),
            ]),
        ],
      );
}

/// A sub-page that gathers related places (Rewards, Community).
class MsHubPage extends StatelessWidget {
  const MsHubPage({super.key, required this.title, required this.subtitle, required this.entries});
  final String title, subtitle;
  final List<MsEntry> entries;
  @override
  Widget build(BuildContext context) => MsScaffold(title: title, subtitle: subtitle, children: [
        MsSection(title: title, rows: [
          for (final e in entries)
            MsRow(key: Key('ms_hub_${e.id}'), icon: e.icon, title: e.title, subtitle: e.subtitle, onTap: e.onTap),
        ]),
      ]);
}
