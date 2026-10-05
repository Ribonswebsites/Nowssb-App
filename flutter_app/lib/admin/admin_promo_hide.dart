/// Hides member promo chrome when [AdminState.mutes] promo.
///
/// Prefer this over bare [AdminState.isAdmin] so cached-admin phones never
/// flash member upsell banners before the live admin check finishes.
library;

import 'package:flutter/material.dart';

import 'admin_state.dart';

class AdminPromoHide extends StatelessWidget {
  const AdminPromoHide({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminState.instance,
      builder: (context, _) {
        if (AdminState.instance.mutes('promo')) {
          return const SizedBox.shrink();
        }
        return child;
      },
    );
  }
}
