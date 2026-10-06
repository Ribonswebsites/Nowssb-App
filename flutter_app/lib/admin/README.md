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

## NowssB Admin — a separate app inside the same install
An admin who opens the app lands in **NowssB Admin** (`admin_app.dart`), not
the member app. `AdminAppGate` (`admin_mode.dart`) decides before the first
frame from a cached answer (`AdminState.loadCache`, prefs `nwsb_admin_uid` /
`nwsb_member_uid`), so admins never see the member app flash; a never-checked
uid gets a neutral splash (max 4 s) while `admins/{uid}` is read.

- Bottom tabs: **Dashboard · People · Content · Money · Control**.
- Bell (top right) = **Admin inbox** (`admin_inbox.dart`, `adminAlerts`):
  new word requests, payout requests, purchases, sign-ups, feedback; tap →
  the request / person. Each alert is also an FCM push to every admin phone
  (`functions/_lib/admin_alerts.js`, channel `nowssb_alerts`).
- **User app** pill / ⋮ menu → the member app (`AdminMode`, prefs
  `nwsb_admin_side`). In the member app a gold **Admin** pill takes you back;
  long-press the floating Edit button also does.
- Promos are off for admins: `AdminPromoGuard` mutes promo notification kinds
  (`AdminState.promoKinds`), cancels the daily repeat reminder (local id
  88001) and the server's `broadcast` skips admin uids for promo audiences.

| Tab / screen | File | What it does |
|---|---|---|
| Dashboard | `dashboard_admin.dart`, `today_admin.dart` | Online now; **Signed in today = a list** (who, first/last time, opens, platform, OS, build; 14-day picker); daily active chart; sign-ups today/7d/30d; plans; payments 30 d by plan; gift cards; coins; live activity |
| People | `people_admin.dart`, `person_admin.dart` | Search; filters (signed in today = India-time day, seen 24h, …); profile with **sign-in days**; grant/extend/revoke plan, **give item** (word/meaning/ebook/signature picker), **send gift** (code to their inbox), coins ±, block, restrictions, reset streak, message/push, helper; network |
| Content | `content_admin.dart`, `requests_admin.dart`, `words_admin.dart`, `voice_recorder.dart` | New word, open requests → word editor → publish (requester told), words, quotes, UI Editor; voice recorder with timer, pause, listen back, re-record, discard, upload (word voice + stage audio) |
| Money | `earn_admin.dart` | Payouts, gift codes, **Prices** (store products + content prices, moved from Settings), coupons & odds, network, rewards |
| Control | `settings_admin.dart`, `control_admin.dart`, `broadcast_admin.dart` | Broadcast, UI Editor, activity, **audit log** (the one log screen), this-phone editor switches, server status, force update, maintenance, flags, team |

## Server routes (Cloudflare Pages Functions, admin-checked)
`/api/admin/<action>` — `functions/api/admin/[action].js` → `_lib/admin_core.js`.
Every call verifies the Firebase ID token and `admins/{uid}` (or `admin`
claim); writes go to `adminLog`. GET `health` / `whoami` list missing env
vars (no auth needed for the names only). POST actions: `stats, users, user,
grant-sub, extend-sub, revoke-sub, adjust-coins, block, restrict,
reset-streak, message, helper, fulfil-request, broadcast, payout-decide,
gift-codes, gift-void, earn, network, feed, ui-assets, today, grant-item,
send-gift, alerts`. One admin source everywhere: `admins/{uid}` (or the
claim) — `/api/push`, `/api/users` and `upload-url` no longer read an
`ADMIN_UIDS` env list. `/api/push` works out its targets on the server from
`pushSubs` (one uid, or everyone except admins); a client list is ignored.
`/api/admin-alert` (any signed-in member, verified against Firestore) raises
request / sign-up / feedback alerts; purchases and payout requests raise
theirs inside `_lib/play.js` and `api/economy`. Env:
`FIREBASE_SERVICE_ACCOUNT` (Firestore + Auth Admin REST), `FCM_SERVICE_ACCOUNT`
(push), R2 vars for `upload-url` (areas incl. `video`). Offline tests:
`node --test tests/admin-server.test.mjs`.

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
| Admin log | `adminLog` (create/read by admins, never edited) | admins / server |
| App events | `activity/{id}` `{type: signup\|login\|open, uid, at=server time, platform, build, app}` — append-only | users (own only), server |
| App control | `config/app` `{minBuild, updateMessage, updateUrl, maintenance{on,blocking,title,message}, flags{}, announcement{on,title,body,until}}` (public read) | admins |
| Economy settings | `config/economy` (payouts, coins, ranks, fastStart, topPool, scratch odds, coupons, gifts, switches) | admins |
| Config history | `configHistory/{id}` — append-only | admins |
| Push history | `broadcasts/{id}` | server |
| Gift codes | `gifts/{code}`, `giftLedger` | admins (create / void only) |
| Wallet adjust | `users/{uid}/wallet/main` coins/streak + `coinLedger` row (by = admin email, reason) | admins / server |
| Payout queue | `payoutRequests/{id}` status approved\|paid\|rejected | admins / server |
| Daily sign-ins | `presenceDays/{yyyy-mm-dd}/people/{uid}`, `users/{uid}/days/{day}` `{uid, day, first, last=server time, opens, platform, build, os[, email, name]}` | users (own only); admins read |
| Admin inbox | `adminAlerts/{kind_ref}` `{kind, ref, uid, title, body, route, seen, at}` | server; admins mark seen |
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
Admin → UI Editor shows the REAL page full screen, edge to edge, with
nothing permanent on it but a small handle at the top and a + button. The
handle opens a floating pill (back · page picker · undo/redo · publish ·
⋯ for Try it, live preview, pencils, every slot); the pill also opens for a
few seconds after each change. + opens a bottom drawer with tabs inside:
Add (ready-made sections), Effects, Orbs, Sections (page map). Touching an
element shows a small strip that opens its own sheet (style, words,
picture); there is no Style tab. Edits wait on the
admin's phone (`EditorPreviewController.draftOverrides/draftLayouts`) and
`EditorStore.publish` writes them in one batch: `ui_overrides`,
`ui_layouts` and one `ui_history` row per change. Every app listens
(`UiOverrides`, `UiLayouts`, both cached in SharedPreferences), so a publish
shows for everyone within seconds with no blank flash.

Override `style` keys (all optional; see `template/style_apply.dart`):
text `color, font, size, weight, spacing, italic, gradient[], shadow,
shadowBlur, shadowDx, shadowDy`; box/button `shape (circle|pill|rounded|none),
bg, gradient[], border, borderW, glow, glowBlur, radius, padH, padV, glass`; orb `orb (OrbState name), orbSize,
orbCircle`. Element placement (any slot): `dx, dy, scale, hidden`. Section `props`
(layout doc): `height, padTop, padBottom, padH, transition, autoRotate,
interval, entrance, orbs[]`, and for template sections
their content (`title, subtitle, body, cta, route, image, video, bg, height, cards[]`).

Pickers: **SVG library** (`editor/svg_picker.dart`, Content tab on any
`.svg` slot) — searchable grid of every bundled `assets/**.svg` (AssetManifest)
plus R2 `ui/` uploads (`/api/admin/ui-assets`) and SVG URLs already used in
overrides; a bundled pick is stored as `asset:<path>`. **Effects drawer**
(`editor/tab_animation.dart`) — live tiles for every entrance, page turn,
auto-rotate speed; hold one and drag it onto a section (`FxDrop` → the
page's `DragTarget` in `preview.dart`): it applies and plays at once.
**Placed orbs** (`layout/placed_orbs.dart`): drag an orb from the drawer's
Orbs tab to an exact spot; it becomes its own element, saved on the section
under it as `props.orbs` (`[{id, orb, x (fraction of width, centre), y (pt
from the section top, centre), size, circle}]`), so it publishes through
`ui_layouts` and `SectionFrame` draws it for everyone at the same spot.
The Loaders target in that tab sets `orb.all` (pinch to resize). The app ships no Lottie/Rive
files.

**Touch-only editing** (`editor/preview.dart`, `_TouchLayer`, over the
whole page): with nothing picked one finger scrolls the page. Tap picks a
section (or an element, or a placed orb). A picked section drags to a new
place (onto the trash at the bottom = delete, with Undo); dragging its
top/bottom edge sets `padTop/padBottom`; a pinch resizes it (`height`).
The selected element drags anywhere (override `style.dx/dy`), pinches to
resize (`style.size` for text, `style.scale` otherwise) and onto the trash
is removed (`style.hidden`, faded in the editor so it can be shown again);
see `elementPlacement` in `template/editable.dart`. Orbs drag, pinch (24 to
420 pt) and trash the same way. Long-press opens Put back · Duplicate ·
Hide · Delete (or, on an orb, circle · Delete). There are no move/size
buttons or sliders. Every draft change is an undo step
(`EditorController.undo/redo`; edits within 700 ms, such as one gesture,
merge into one step). The canvas only needs an `AppPage` and its section
ids, so any page in `kAppPages` works with it. **Live preview** (pill ⋯) — the whole page,
interactive, with every draft applied, before Publish.

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
  drawer's page-turn and auto-rotate effects apply.
* `LSection.group` must match the parent's crossAxisAlignment (a
  ListView/SliverList behaves like `stretch`).
* New generic templates go in `layout/template_sections.dart`
  (`kTemplateKinds`, `kTemplateNames`, `templateStarter`).
