/// A stand-in for a screen that has not been ported yet.
///
/// It exists so the bottom nav does not lie. Tapping a tab used to leave the
/// Normal home on screen with a gold label above it, which reads as a broken
/// app rather than an unfinished one — and when this APK goes to a client
/// for a look, the difference matters.
library;

import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: const Color(0xFF10141F),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 34, color: NwsbColors.goldLight),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This screen is still on the web app.\nIt is being ported here next.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Color(0xB3C8E8F5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
