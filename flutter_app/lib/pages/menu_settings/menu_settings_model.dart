/// Data for the rebuilt Menu & Settings page. Pure Dart so it is testable.
library;

import 'package:flutter/widgets.dart';

enum SettingKind { link, toggle }

class SettingItem {
  const SettingItem({
    required this.id,
    required this.title,
    required this.icon,
    this.subtitle,
    this.kind = SettingKind.link,
    this.value = false,
    this.onTap,
    this.onChanged,
    this.destructive = false,
  });

  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final SettingKind kind;
  final bool value;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onChanged;
  final bool destructive;

  bool matches(String q) =>
      q.isEmpty ||
      title.toLowerCase().contains(q) ||
      (subtitle?.toLowerCase().contains(q) ?? false);
}

class SettingSection {
  const SettingSection(this.title, this.items);
  final String title;
  final List<SettingItem> items;

  SettingSection filtered(String q) =>
      SettingSection(title, items.where((i) => i.matches(q)).toList());
}

/// Filters sections by a search query and drops sections that become empty.
List<SettingSection> filterSections(List<SettingSection> all, String query) {
  final q = query.trim().toLowerCase();
  return all
      .map((s) => s.filtered(q))
      .where((s) => s.items.isNotEmpty)
      .toList();
}

enum MenuSettingsStatus { loading, ready, error, offline }
