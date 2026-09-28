/// Shared look for the admin screens: dark glass, gold accent — the same
/// palette the Request Words and settings pages already use.
library;

import 'package:flutter/material.dart';

const kAdminBg = Color(0xFF060C18);
const kAdminPanel = Color(0xFF0F1828);
const kAdminGold = Color(0xFFE8D5A3);
const kAdminDim = Color(0x99FFFFFF);

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.fab,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: kAdminBg,
        colorScheme: const ColorScheme.dark(primary: kAdminGold, secondary: kAdminGold),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white54),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kAdminGold)),
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kAdminBg,
          foregroundColor: Colors.white,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          actions: actions,
        ),
        floatingActionButton: fab,
        body: body,
      ),
    );
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kAdminPanel,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: padding ?? const EdgeInsets.all(14), child: child),
      ),
    );
  }
}

class AdminChip extends StatelessWidget {
  const AdminChip(this.label, {super.key, this.color = kAdminGold});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}

void adminToast(BuildContext context, String msg) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}

String adminAgo(dynamic v) {
  DateTime? t;
  if (v is int) t = DateTime.fromMillisecondsSinceEpoch(v);
  if (v is DateTime) t = v;
  try {
    // Firestore Timestamp without importing cloud_firestore here.
    if (t == null && v != null) t = (v as dynamic).toDate() as DateTime;
  } catch (_) {}
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  if (d.inDays < 30) return '${d.inDays}d ago';
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}
