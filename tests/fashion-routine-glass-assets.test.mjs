import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const cards = readFileSync(
  join(root, "flutter_app/lib/screens/normal/horizontal_routine_cards.dart"),
  "utf8",
);
const line = readFileSync(
  join(root, "flutter_app/lib/screens/normal/essentials_process_line.dart"),
  "utf8",
);
const pubspec = readFileSync(join(root, "flutter_app/pubspec.yaml"), "utf8");
const flutterAssets = readFileSync(join(root, "tools/flutter-assets.mjs"), "utf8");

assert.match(cards, /_darkGlassFill = Color\(0x0EFFFFFF\)/, "Fashion cards use dark glass fill");
assert.doesNotMatch(
  cards,
  /fashion \? const Color\(0xD9FFFFFF\)/,
  "Fashion must not use opaque white glass",
);
assert.match(cards, /height: 340/, "carousel height leaves 1px headroom");
assert.match(line, /boxShadow: glass\s*\n\s*\? null/, "glass process line has no drop-shadow");

const names = [
  "trusting-the-breath.png",
  "positive-self-talk.png",
  "stillness.png",
  "your-body-knows.png",
  "softer-voice.png",
  "quiet-within.png",
];
for (const name of names) {
  assert.match(cards, new RegExp(`assets/routine/${name.replace(".", "\\.")}`));
  for (const base of ["assets/routine", "flutter_app/assets/routine"]) {
    assert.ok(existsSync(join(root, base, name)), `missing ${base}/${name}`);
  }
}
assert.match(pubspec, /assets\/routine\//);
assert.match(flutterAssets, /'routine'/);

console.log("Fashion My Routine dark glass + editorial assets verified.");
