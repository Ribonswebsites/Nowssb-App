/// Every animation the editor offers, by category. Ids are saved in
/// published layouts, so never rename or remove one.
library;

import 'anim_core.dart';
import 'anims_backgrounds.dart';
import 'anims_celebrations.dart';
import 'anims_loaders.dart';
import 'anims_more.dart';
import 'anims_orbs.dart';
import 'anims_particles.dart';

export 'anim_core.dart';
export 'anims_orbs.dart' show thinkingOrbOf;

final List<AnimSpec> kAnimLibrary = List.unmodifiable([
  ...kOrbAnims,
  ...kLoaderAnims,
  ...kBackgroundAnims,
  ...kParticleAnims,
  ...kCelebrationAnims,
  ...kMoreAnims,
]);

final Map<String, AnimSpec> _byId = {for (final s in kAnimLibrary) s.id: s};

AnimSpec? animById(String? id) => id == null ? null : _byId[id];

List<AnimSpec> animsIn(AnimCategory c) => [for (final s in kAnimLibrary) if (s.category == c) s];
