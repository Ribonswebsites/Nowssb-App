/// The bottom nav — #ig-bottomnav. Five destinations, the active one gold.
library;

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../screens/home_normal.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});
  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _i = 0;

  static const _tabs = [
    ('Connect', Icons.groups_outlined),
    ('Practice', Icons.headphones_outlined),
    ('Library', Icons.menu_book_outlined),
    ('Store', Icons.storefront_outlined),
    ('Profile', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NwsbColors.surface,
      body: Stack(
        children: [
          const HomeNormal(),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: Container(
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(33),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _i = i),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _tabs[i].$2,
                                size: 22,
                                color: i == _i
                                    ? NwsbColors.goldLight
                                    : const Color(0x99FFFFFF),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _tabs[i].$1,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      i == _i ? FontWeight.w700 : FontWeight.w400,
                                  color: i == _i
                                      ? NwsbColors.goldLight
                                      : const Color(0x99FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
