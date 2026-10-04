/// Opens a hyped poster without the rail importing every screen.
library;

import 'package:flutter/material.dart';

import '../features/earn/earn_hub_screen.dart';
import '../screens/profile.dart';
import '../shell/nwsb_links.dart';
import 'hype_rail.dart';

void ensureHypeRoutes() {
  openHypeCard = (context, id) {
    switch (id) {
      case 'coupons':
      case 'scratch':
        NwsbLinks.cta(context, 'coupon');
      case 'gifts':
        NwsbLinks.cta(context, 'gift');
      case 'earn':
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarnHubScreen()));
      case 'rewards':
        NwsbLinks.cta(context, 'reward');
      case 'signature':
        NwsbLinks.signatures(context);
      case 'library':
        NwsbLinks.tab(context, 2);
      case 'profile':
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
    }
  };
}
