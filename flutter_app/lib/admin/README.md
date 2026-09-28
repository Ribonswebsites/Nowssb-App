# Admin mode and the live template editor

Free Firebase **Spark** plan: Firebase is used only for Auth + Firestore +
rules. No Cloud Functions, no Firebase Storage. **All media lives on
Cloudflare R2**; the site's Pages Function `functions/api/admin/upload-url.js`
hands an admin a one-time upload address (the R2 keys never reach the app).

## Who is an admin
A uid with a document at Firestore `admins/{uid}` (or the custom claim
`admin: true`). The app only *shows* admin mode to them (`AdminState`); the
real gate is `firestore.rules` (`isAdmin()`) and the upload endpoint, which
both check the same thing. Mark someone with
`node tools/firebase/admin-tool.mjs mark-admin <uid>`.

Open it: App Settings → **Admin**, or the floating **Edit layout** button
(tap = edit mode on/off, long-press = Admin home, drag to move). The Admin
home (`admin_home.dart`, Fashion-home look) leads to the **UI Editor**,
Content (Words / Quotes / Requests) and the later pages (People, Earn &
Gifts, Activity, Dashboard, Settings — marked "Next update").

## Data
| What | Where | Who writes |
|---|---|---|
| Published words | `words/{key}` (`status: published\|archived`, `version`, every Word field incl. `audio`, `description`, `meanings`, `stage`) | admins |
| Word drafts | `word_drafts/{key}` | admins (read too) |
| Quotes | `content/quotes` `{live, byDate: {yyyy-mm-dd: line}, queue: [...]}` | admins |
| Requests | `requests/{id}` (`kind, word, notes, uid, email, name, status, at, source`) | users create their own; admins update |
| Template overrides | `ui_overrides/{slotKey with / → ~}` `{slot, type, url, text, textSet, style, start, end, storagePath, default, updatedAt, updatedBy}` | admins |
| Page layouts (UI Editor) | `ui_layouts/{pageId}` `{page, version, sections: [{id, src, kind, visible, deleted, props, start, end}]}` | admins (everyone reads) |
| Editor history | `ui_history/{id}` `{page, kind: slot\|layout, target, default, before, after, at, by, note}` — append-only | admins |
| Activity | `adminLog` (create/read by admins, never edited) | admins |
| Media | R2: `ui/<slot>/…`, `audio/<wordKey>/…`, `images/words/<wordKey>/…` served from the public R2 domain | via upload-url |

`ContentStore` lays `words` over the shipped + `content/library` words (archived
removes a word). A word's `audio` plays with just_audio (cached on the phone);
without one the app falls back to text-to-speech.

## Template editor — RULE FOR NEW UI
Every fixed picture, clip, SVG and line of copy must go through a wrapper so
the owner can change it without a release. Default rendering is identical.

```dart
EditableLabel('store.MeaningStore', 'Meaning Store', style: …)   // instead of Text('…')
EditableImage.asset('assets/x.webp', slot: 'store.MeaningStore', fit: …) // Image.asset
EditableImage.network(kSomeUrl, slot: '…')                     // constant URLs only
EditableSvg.asset('assets/icons/x.svg', slot: '…')             // SvgPicture.asset
NwsbVideo(asset: 'assets/video/x.mp4', slot: '…')              // clips
NwsbImage(url: '…', slot: '…')
slotImageProvider(context, '…', asset, AssetImage(asset))      // DecorationImage
```

The slot is `<file>.<Class>` (or a section name). The element half of the key
is the file name (media) or a slug of the default text, never a list index —
see `template/slot_keys.dart`. Pass `id:` to pin a key if the default text
will change.

Do NOT wrap user or data content (profile photos, chat, word names from
content, prices, interpolated strings).

`tools/admin-slot-sweep.py` converts plain usages automatically and
regenerates `template/slot_manifest.g.dart` (what All slots lists). Run it
after adding screens: `python3 tools/admin-slot-sweep.py --report /tmp/r.md`.
It is idempotent. The last run's per-file counts are in
`template/SWEEP_REPORT.md`.

## UI Editor (`editor/`, `layout/`)
Admin → UI Editor shows the REAL page in a phone frame, one section at a
time (swipe sideways), with five tabs: Content (slots in the section; tap
them on the preview), Style, Animation, Layout, Publish. Edits wait on the
admin's phone (`EditorPreviewController.draftOverrides/draftLayouts`) and
`EditorStore.publish` writes them in one batch: `ui_overrides`,
`ui_layouts` and one `ui_history` row per change. Every app listens
(`UiOverrides`, `UiLayouts`, both cached in SharedPreferences), so a publish
shows for everyone within seconds with no blank flash.

Override `style` keys (all optional; see `template/style_apply.dart`):
text `color, font, size, weight, spacing, italic, gradient[], shadow,
shadowBlur, shadowDx, shadowDy`; box/button `shape (circle|pill|rounded|none),
bg, gradient[], border, borderW, glow, glowBlur, radius, padH, padV, glass`; orb `orb (OrbState name), orbSize,
orbCircle`. Section `props` (layout doc): `height, padTop, padBottom, padH,
transition, autoRotate, interval, entrance`, and for template sections
their content (`title, subtitle, body, cta, route, image, video, bg, height, cards[]`).

Thinking orbs: `AppThinkingLoader(slot: …)` looks up `slot` →
`orb.<pageId>.<sectionId>` → `orb.all`.

## Sections — RULE FOR NEW PAGES AND SECTIONS
A page's scrolling body must be a list of sections with **stable ids**
passed through the registry, or the editor sees the page as one block:

```dart
children: layoutChildren(context, 'store.meaning', [
  LSection('hero', 'Hero film', StorePixelsHero(...)),
  const SizedBox(height: 16),                       // glue: moves with the one above
  LSection.group('rows', 'Collections', [...], align: CrossAxisAlignment.start),
]),
// or, leaving the children untouched:
children: layoutIndexed(context, 'store.meaning', const {0: ('hero', 'Hero film'), 3: ('search', 'Search')}, [...]),
// or, for a keyed list you build yourself:
applyLayout(context, 'home.normal', items, hiddenByDefault: {...})
```

* Ids are forever — renaming one drops the owner's edits for it.
* With no saved layout the list comes back exactly as given, so the
  default look is pixel-identical.
* Add the page to `layout/app_pages.dart` (`kAppPages`, same page id) so it
  appears in the editor's page picker; sections then register themselves.
* A sideways carousel: pass `carousel: true` and use
  `carouselFxItem(context, controller, i, card)` (or `carouselFxChildren`)
  in its PageView and wrap it in `CarouselAutoRotate(...)`, so the
  Animation tab's transitions and auto-rotate apply.
* `LSection.group` must match the parent's crossAxisAlignment (a
  ListView/SliverList behaves like `stretch`).
* New generic templates go in `layout/template_sections.dart`
  (`kTemplateKinds`, `kTemplateNames`, `templateStarter`).
