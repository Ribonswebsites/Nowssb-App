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
(tap = edit mode on/off, long-press = Admin home, drag to move).

## Data
| What | Where | Who writes |
|---|---|---|
| Published words | `words/{key}` (`status: published\|archived`, `version`, every Word field incl. `audio`, `description`, `meanings`, `stage`) | admins |
| Word drafts | `word_drafts/{key}` | admins (read too) |
| Quotes | `content/quotes` `{live, byDate: {yyyy-mm-dd: line}, queue: [...]}` | admins |
| Requests | `requests/{id}` (`kind, word, notes, uid, email, name, status, at, source`) | users create their own; admins update |
| Template overrides | `ui_overrides/{slotKey with / → ~}` `{slot, type, url, text, storagePath, default, updatedAt, updatedBy}` | admins |
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
