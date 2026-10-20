// Ribon's official circle images (512px webp) in assets/images/circles/.
// To add one: drop <name>.webp into the folder and add '<name>' to [names].
import 'package:flutter/widgets.dart';

class NCircles {
  NCircles._();
  static const dir = 'assets/images/circles/';
  static const names = <String>[
    'yoga_deck', 'sea_face', 'stones', 'lake', 'singing_bowl', 'mudra_hands',
    'mudra_closeup', 'candle_incense', 'waterfall', 'lotus', 'milky_way',
  ];
  static AssetImage of(String name) => AssetImage('$dir$name.webp');
  static List<AssetImage> get all => [for (final n in names) of(n)];
  /// Stable pick for lists: NCircles.at(index).
  static AssetImage at(int i) => of(names[i % names.length]);
  static const yogaDeck = AssetImage('${dir}yoga_deck.webp');
}
