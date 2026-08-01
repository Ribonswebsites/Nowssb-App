# NowssB in Flutter — how this repository is set up for the port

You asked for a Flutter app on the Play Store that looks **exactly** like
this one, with every image and every video already on the phone after the
download. This is the preparation for that. The Dart is not written yet, on
purpose — everything here is the work that has to exist first, and it is
done.

---

## One thing worth saying before you pick

There are two ways to get a Flutter app that looks like this, and the
difference is not a detail.

**A — bundle this HTML inside a Flutter app.** `flutter_inappwebview`
renders `assets/www/index.html`, Flutter owns everything native around it:
FCM notifications, splash, the back button, in-app purchases, the Play
release. It is a real Flutter app — Dart, `pubspec.yaml`, a signed `.aab` —
and it looks *exactly* like this app because it **is** this app. Nine
thousand lines of HTML and eight thousand of CSS carry over on day one.

**B — rebuild every screen as Flutter widgets.** Genuinely native
rendering, genuinely faster scrolling. It is also re-drawing every screen
in this repository by hand, and "exactly the same" will not survive it:
neumorphic shadows, backdrop blurs, the glass wrappers, the word player's
layered video and arc, the reader's rail — each is a fresh approximation
with its own drift.

I would ship **A**, and treat **B** as something to move screen by screen
later if the app ever needs it. But this is your product, and the
preparation below serves both — the assets, the content model and the
notification seam are needed either way.

---

## What is already done for the port

### 1. Every image and video, as a list

`tools/asset-manifest.mjs` scans the whole repository — `index.html`, all
seventy JS files, the three stylesheets — and finds every media URL,
however it is written. Right now that is:

| | |
|---|---|
| images | 487 |
| videos | 61 |
| audio | 5 |
| **total** | **553** |

```bash
node tools/asset-manifest.mjs              # write assets/media-manifest.json
node tools/asset-manifest.mjs --download   # fetch every file into assets/media/
node tools/asset-manifest.mjs --dart       # write assets/media_assets.dart
```

The download is sequential and resumable — stop it and run it again and it
picks up where it left off, because names are derived from the URL rather
than a counter. Run it on your machine, not in a sandbox; this environment
cannot reach Cloudinary.

`assets/media_assets.dart` is the map the port uses:

```dart
final local = nowssbAsset(url);      // 'assets/media/video/…mp4', or null
```

A URL that is in the map is read from the bundle. One that is not falls
through to the network, which is the right behaviour for anything added
after the last build rather than a crash.

**On size.** 553 files is a large app. Play's limit is 200 MB for an AAB's
base module, and Play Asset Delivery carries the rest as install-time
packs. Before you bundle, put the videos through Cloudinary's own
transforms — `f_auto,q_auto,vc_h264,w_720` is what the player already asks
for — so what you download is what the app actually shows, not the
originals. `assets/banners/` (71 MB) is not in the manifest at all, because
nothing in the app references it.

### 2. The content is already out of the code

This is the part that would otherwise sink the port. Words, meanings, the
teaching library and the eBooks are **not** hardcoded any more — they live
in Firestore and the app watches them:

| Firestore | What it holds | Read by |
|---|---|---|
| `content/words` | the Word Atelier's shelves | `app/js/part069.js` |
| `content/meanings` | the Meaning Store catalogue | `app/js/part069.js` |
| `content/library` | every word the app teaches, in full | `app/js/part073.js` |
| `content/books` | the eBooks | `app/js/part073.js` |

So the Dart port does not need a catalogue, a seed file or a migration. It
needs `cloud_firestore` and the same four documents. And an edit published
from the studio reaches the Flutter app the same moment it reaches the
website — no Play release.

The shape of a library word is defined in one place,
`nwsbNormWord` in `app/js/part073.js`. Port that function and you have the
model.

### 3. The notification seam

`app/js/part072.js` no longer knows what is hosting it. It asks, and
whoever is hosting answers. A Flutter host implements three methods:

```dart
// Registered as a JavaScript handler named NowssBHost
NowssBHost.permission()        // 'granted' | 'denied' | 'default'
NowssBHost.requestPermission() // the same, after asking
NowssBHost.token()             // the FCM token, or ''
```

and pushes things back in through one door:

```js
window.nwsbHostEvent({ kind: 'token',      token: '…' });
window.nwsbHostEvent({ kind: 'permission', value: 'granted' });
window.nwsbHostEvent({ kind: 'received',   type: 'offers', title: '…', body: '…' });
window.nwsbHostEvent({ kind: 'tapped',     type: 'offers' });
window.nwsbHostBack();   // returns true if the app consumed the back press
```

That is the whole contract. Implement it and the notifications page, the
master switch, all sixteen per-kind switches, the deep links and the
subscription record in `pushSubs` work unchanged — the same code that
already serves Capacitor. It is injected either before the page loads or
within ten seconds of it; both are handled.

The sending side needs nothing new: `functions/api/push.js` already sends
to FCM tokens as well as Web Push endpoints (see `CAPACITOR.md` §4 for
`FCM_SERVICE_ACCOUNT`).

### 4. Devanagari

Handled in the data, not in the port. A word carries four things at once —
`deva` (the word as it is actually written), `word` (a roman spelling to
read), `parts[]` (three to five pronunciation boxes, each with its own
Devanagari, roman, hold time, plain-English "how to make this sound" and
optional recording) and `audioMale` / `audioFemale`. Rendering is
system-font Devanagari via the `.nwsb-deva` stack; Android, iOS, Windows
and macOS all ship one, nothing is downloaded. In Flutter the equivalent is
a `TextStyle(fontFamily: 'Noto Sans Devanagari')` or a bundled font if you
want it identical across devices.

---

## The port, in order

1. `flutter create nowssb --org com.nowssb`
2. `node tools/asset-manifest.mjs --download --dart`
3. `node tools/build-native.mjs` → copy `www/` to `assets/www/` (the studio
   is excluded and the build fails if it is not — see `tools/build-native.mjs`)
4. Declare `assets/www/` and `assets/media/` in `pubspec.yaml`
5. `flutter_inappwebview` pointed at `assets/www/index.html`, with a
   request interceptor that swaps any URL in `kNowssbMedia` for its bundled
   file
6. `firebase_messaging` + the `NowssBHost` handler above
7. `flutter build appbundle` → Play Console

Step 5 is the one that makes "downloaded once, on the phone forever" true:
the interceptor is where a Cloudinary URL becomes a local file, so nothing
in the HTML has to be rewritten and the same files still work on the
website.

---

## What stays where it is

- **The studio** (`admin.html`) is not in the app and cannot be. It is a
  browser page at `https://<your-domain>/admin.html`, installable as its
  own PWA. `tools/build-native.mjs` verifies it did not leak into the
  bundle and fails the build if it did.
- **The service worker** does nothing useful inside a WebView — the files
  are already local. `app/js/part012.js` catches the failed registration
  and the app carries on.
- **`functions/api/push.js`** stays on Cloudflare. The Flutter app talks to
  Firestore and to that endpoint, exactly as the website does.
