/// Concept-art backgrounds for Store word pages: one photoreal still per
/// live word, in the approved sage / stone / cream campaign style.
/// These sit first in [wordPageBackgrounds]; older posters and photos
/// still follow when a word has more than one picture.
library;

import 'word_art.dart';

const kWordBackgroundDir = 'assets/word_backgrounds';

/// Words with a bundled concept-art background, keyed by [WordArt.keyOf].
const kWordBackgrounds = <String, String>{
  'abyss': '$kWordBackgroundDir/abyss.webp',
  'alba': '$kWordBackgroundDir/alba.webp',
  'apex': '$kWordBackgroundDir/apex.webp',
  'archer': '$kWordBackgroundDir/archer.webp',
  'ash': '$kWordBackgroundDir/ash.webp',
  'aura': '$kWordBackgroundDir/aura.webp',
  'axiom': '$kWordBackgroundDir/axiom.webp',
  'belief': '$kWordBackgroundDir/belief.webp',
  'birth': '$kWordBackgroundDir/birth.webp',
  'blade': '$kWordBackgroundDir/blade.webp',
  'blank': '$kWordBackgroundDir/blank.webp',
  'blessing': '$kWordBackgroundDir/blessing.webp',
  'blood': '$kWordBackgroundDir/blood.webp',
  'bloom': '$kWordBackgroundDir/bloom.webp',
  'body': '$kWordBackgroundDir/body.webp',
  'breath': '$kWordBackgroundDir/breath.webp',
  'breathe': '$kWordBackgroundDir/breathe.webp',
  'brother': '$kWordBackgroundDir/brother.webp',
  'calm': '$kWordBackgroundDir/calm.webp',
  'cardinal': '$kWordBackgroundDir/cardinal.webp',
  'child': '$kWordBackgroundDir/child.webp',
  'cipher': '$kWordBackgroundDir/cipher.webp',
  'clan': '$kWordBackgroundDir/clan.webp',
  'clarity': '$kWordBackgroundDir/clarity.webp',
  'clean': '$kWordBackgroundDir/clean.webp',
  'cliff': '$kWordBackgroundDir/cliff.webp',
  'cosmos': '$kWordBackgroundDir/cosmos.webp',
  'crown': '$kWordBackgroundDir/crown.webp',
  'crystal': '$kWordBackgroundDir/crystal.webp',
  'dark': '$kWordBackgroundDir/dark.webp',
  'dawn': '$kWordBackgroundDir/dawn.webp',
  'death': '$kWordBackgroundDir/death.webp',
  'depth': '$kWordBackgroundDir/depth.webp',
  'desert': '$kWordBackgroundDir/desert.webp',
  'destiny': '$kWordBackgroundDir/destiny.webp',
  'divine': '$kWordBackgroundDir/divine.webp',
  'dream': '$kWordBackgroundDir/dream.webp',
  'dusk': '$kWordBackgroundDir/dusk.webp',
  'dust': '$kWordBackgroundDir/dust.webp',
  'earth': '$kWordBackgroundDir/earth.webp',
  'eclipse': '$kWordBackgroundDir/eclipse.webp',
  'ocean': '$kWordBackgroundDir/ocean.webp',
  'peace': '$kWordBackgroundDir/peace.webp',
  'serenity': '$kWordBackgroundDir/serenity.webp',
  'shield': '$kWordBackgroundDir/shield.webp',
};

/// [word]'s concept-art background, or null if none is bundled yet.
String? wordBackgroundFor(String word) => kWordBackgrounds[WordArt.keyOf(word)];
