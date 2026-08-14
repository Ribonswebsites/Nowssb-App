# NowssB in Flutter

Real widgets. No WebView, no HTML, no service worker. The app draws itself.

This document is the state of the port and how to work on it.

---

## Why the app was slow, and what actually fixes it

Worth being exact about, because the fix is the architecture.

A phone has a **fixed, small number of hardware video decoders** — on most
Android devices somewhere between four and sixteen. The website had 106
`<video>` elements alive on one home screen. When you ask for more decoders
than the chip has, the request does not politely queue: playback stutters,
frames arrive late, surfaces come back black, and eventually the media server
gives up and takes the app down. **That is the lag, the black banners and the
crashes, all of them.**

Rebuilding in Flutter does not make a decoder faster. The same chip decodes
the same H.264 at the same speed whether the frame goes to a WebView or to an
ExoPlayer texture. What Flutter gives is the thing a browser never would:
**exact control over how many exist.** A `VideoPlayerController` is a real
ExoPlayer instance, created and destroyed when `lib/media/video_pool.dart`
says so — not when a garbage collector decides the page has moved on.

So the rule the whole app is built around:

> **At most four decoders exist at any moment.** Not "are playing" — exist.

Everything else shows its poster, which is a picture and costs nothing. This
is why every mp4 in `assets/video/` has a `-poster.webp` beside it, generated
from the clip itself: most clips are showing their poster most of the time,
and the app only looks right because that poster is the clip's own first
frame.

---

## What exists

| | |
|---|---|
| `lib/media/video_pool.dart` | The ceiling. Leases, eviction by distance from the middle of the screen, priority for clips that *are* their section. |
| `lib/media/nwsb_video.dart` | The one widget every clip goes through. Poster, then a crossfade to the moving picture if the pool grants a decoder. |
| `lib/data/models.dart` | `Word`, `WordPart`, `Book`, `Meaning`, `Shelf` — ported field for field from `nwsbNormWord` in `app/js/part073.js`. |
| `lib/data/content.dart` | The three-stage content contract: what ships → last copy seen → Firestore, watched. |
| `lib/data/firebase.dart` | Firebase, made optional. No `google-services.json` means bundled content, not a crash. |
| `lib/theme/` | Tokens lifted from the stylesheets, and the two surfaces as `ThemeData`. |
| `lib/widgets/` | `NeuCard`, `NwsbBanner`, `TvFrame`, and a debug-only decoder readout. |
| `lib/screens/` | The Normal home and the sections that carry a clip. |
| `test/` | 11 tests. The important ones count *players actually asked of the platform*, not the pool's opinion of itself. |

### The tests are the specification

`test/video_pool_test.dart` runs the real pool against a fake platform
standing in for ExoPlayer, so what it counts is how many players were created
and disposed. Among them:

- a hundred off-screen clips ask the phone for nothing at all
- a hundred clips on screen at once still only ask for four
- **scrolling a thirty-clip page never exceeds the ceiling at any point**
- scrolling past a clip gives its decoder back — disposed, not paused
- backgrounding hands every decoder back; returning takes them again

Three real bugs were found by these rather than by reading the code:

1. **Teardown is asynchronous.** Disposing a controller releases the Dart
   object immediately and the ExoPlayer a moment later. Handing back four and
   creating four in the same breath meant the phone briefly held eight. The
   pass now waits for the platform before it creates anything.
2. **A disposed widget's release was not counted.** `dispose()` cannot be
   awaited, so a widget scrolled out of a list started a teardown nobody
   waited for. Those are parked in `_draining` and waited on too.
3. **The measure/notify loop never settled.** The widget measures itself in a
   post-frame callback; reporting unconditionally notified it, which rebuilt
   it, which measured again. On a device that is a flat battery.

---

## Working on it

```bash
node tools/flutter-assets.mjs     # REQUIRED before pub get — see below
cd flutter_app
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

`tools/flutter-assets.mjs` copies `assets/video/` into the Flutter bundle and
writes the shipped content JSON. **It has to run before `flutter pub get`**:
`pubspec.yaml` declares `assets/video/`, and a declared asset directory that
does not exist fails pub get outright.

`flutter_app/assets/video/` is **not committed**. The clips are in this
repository once, at `assets/video/`, because the website and the app show the
same films and a second copy is a second copy to keep in step.

### Content

`tools/export-content.mjs` writes `flutter_app/assets/content/*.json` by
**evaluating the declarations out of the web app** — `MASTER_WORD_LIBRARY` in
`app/js/part004.js`, `EB_BOOKS` in `app/js/part017.js`. There is one list of
words in this repository and that is it. Re-run the tool after changing them.

At runtime Firestore overrides all of it, live, from the same four documents
the website reads: `content/library`, `content/books`, `content/words`,
`content/meanings`. A word published from the studio reaches this app the
moment it reaches the website, with no Play release.

---

## What is still to do

**Firebase on Android.** The config in `app/js/firebase.module.js` is for a
*web* app. An Android build needs its own app registered in the same project
(`nowssb-34f1b`) and its own `google-services.json`, which comes out of the
Firebase console and cannot be written from here. Until it lands the app runs
on bundled content — `lib/data/firebase.dart` makes that a fallback rather
than a crash. Drop the file at `flutter_app/android/app/google-services.json`
and follow the FlutterFire Android setup to switch live content, auth and
push on.

**The rest of the screens.** The Normal home is real. The other four
destinations are placeholders. Each screen ported from here on should follow
the same rule: any clip goes through `NwsbVideo`, never a raw `VideoPlayer` —
a controller the pool has never heard of is exactly the hole the website had,
and `test/home_test.dart` checks for it.

**The word player, the reader, the store, chat.** These are the big ones and
they carry the most behaviour. The content model they need is already here.

---

## What stays where it is

- **The studio** (`admin.html`) is a browser page and cannot be in the app.
- **`functions/api/push.js`** stays on Cloudflare. It already sends to FCM
  tokens as well as Web Push endpoints.
- **The website** is unaffected by any of this and keeps shipping.
