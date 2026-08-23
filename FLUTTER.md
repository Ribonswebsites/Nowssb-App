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

> **On-screen clips play. Off-screen clips are posters.**
> At most 24 decoders exist at any moment — the same number the website
> (`MAX_PLAYING` in `app/js/part051.js`) and the Capacitor WebView use.

That is why the backgrounds, televisions and banners all move together, and
why a clip that has scrolled away costs nothing. Every mp4 in `assets/video/`
has a `-poster.webp` beside it, generated from the clip itself: what you see
while a clip waits is its own first frame.

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
| `lib/screens/splash.dart` | The start animation. Plays once, three ways out, and the pool is held to zero underneath it. |
| `lib/screens/` | Both homes, all five destinations, and the word page. |
| `lib/widgets/page_shell.dart` | The film-backed shell the non-home destinations share. |
| `lib/widgets/tv_frame.dart` | The real device bezels out of `assets/frames/`, with the aperture percentages lifted verbatim from `.nwsb-inframe.dev-*`. |
| `lib/widgets/intro_gate.dart` | The intro page every store and library wears. Nine hand-built copies on the web, one widget here. |
| `lib/data/settings.dart` | Fashion Plus and which home, remembered between launches. |
| `test/` | 17 tests. The important ones count *players actually asked of the platform*, not the pool's opinion of itself. |

### The artwork is the repository's own

Nothing here is drawn by hand or stood in for. `assets/frames/*.webp` are the
device renders the website uses, and they work the way they do there: the
bezel is a TRANSPARENT-APERTURE PICTURE OVER the content, and the clip is
inset behind it by the exact percentages the artwork occupies — so it lands
correctly at any size with no second set of numbers to keep in step.

`assets/store/intro-*.webp` are the intro-page paintings,
`assets/icons/logo-disc.webp` is the mark in both headers,
`assets/player/liquid-splash.webp` sits behind a word, and
`assets/banners/` and `assets/store/collections/` are ready for the shelves.
`tools/flutter-assets.mjs` copies all of it in; `test/assets_test.dart`
fails if the code ever names a file that is not there — a wrong asset path
does not throw, it just shows nothing, which is how a typo ships.

### The screens

| | |
|---|---|
| **Splash** | `start-animation.mp4`, once per launch. The app is built behind it so there is no second wait, and the pool grants nothing while it runs. |
| **Connect** | Both homes. A switch above the nav moves between the pale neumorphic one and the dark Fashion one. |
| **Practice** | Today's session, chosen by the hour the same way `getTimeSlot` does on the web, filtered on each word's own `time` field. |
| **Library** | Every word, searchable across roman spelling, Devanagari, meaning and organ. The category filters are built FROM the data — add one in the studio and it appears here. |
| **Store** | Words, Meanings and eBooks as three tabs over the three documents. |
| **Profile** | Says plainly whether content is live or bundled, how many words are loaded, and how many decoders are in use. |
| **Word** | The screen the content model was built for — Devanagari, roman, the pronunciation boxes with hold times, and every fact the record carries. |

Every section on both homes is wired to a destination, and a test asserts
that no black bar exists without one.

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
flutter create --platforms=android --org com.nowssb --project-name nowssb .
cd .. && node tools/flutter-android.mjs && cd flutter_app
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
node ../tools/flutter-ios.mjs     # only after generating an iOS project
```

The native Record tab uses `record` to capture an AAC/M4A file and sends it to
`https://nowssb-api.ribonpatil2.workers.dev/api/groq/score`. The Groq key is
never included in the Flutter bundle. `tools/flutter-android.mjs` adds
`RECORD_AUDIO` to the generated Android manifest; `tools/flutter-ios.mjs` adds
`NSMicrophoneUsageDescription` to the generated iOS Info.plist.

`tools/flutter-assets.mjs` copies `assets/video/` into the Flutter bundle and
writes the shipped content JSON. **It has to run before `flutter pub get`**:
`pubspec.yaml` declares `assets/video/`, and a declared asset directory that
does not exist fails pub get outright.

`flutter_app/assets/video/` is **not committed**. The clips are in this
repository once, at `assets/video/`, because the website and the app show the
same films and a second copy is a second copy to keep in step.

### Firebase and the Android project

`flutter_app/android/` is generated by `flutter create` and not committed, so
everything this app needs beyond the defaults is applied on the way into a
build by `tools/flutter-android.mjs`. Four things, each of which the build
fails without:

| | why |
|---|---|
| `applicationId = com.nowssb.app` | the package name Firebase issued the config for. `flutter create` derives `com.nowssb.nowssb` from `--org`, and the google-services plugin refuses a mismatch. |
| core library desugaring | `flutter_local_notifications` uses `java.time`, which does not exist below API 26. |
| `minSdk 23` | `firebase_auth`'s floor. |
| the google-services plugin | the FlutterFire packages do not apply it, and without it `google-services.json` is inert and `Firebase.initializeApp()` fails with no default options. |

The config lives at `flutter_app/android-config/google-services.json` and is
copied into the generated project by the same script. It is committed on
purpose: it ships inside every copy of the APK and identifies the project
rather than authorising anything. The signing keystore and the FCM
service-account json ARE secrets, and `.gitignore` refuses both.

`lib/data/firebase.dart` still treats Firebase as optional. That is not
leftover scaffolding — an app whose Firebase is misconfigured, offline on
first run, or refused by the rules should show the words it shipped with
rather than a white screen.

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

**The remaining icons.** The app's own marks — the logo disc, the device
bezels, the intro paintings, the collection banners — were in this
repository all along and are bundled now. What is still Material is the
small furniture: the section head marks, the tile icons, the nav. Those come
from the ~446 Cloudinary images, which `tools/asset-manifest.mjs --download`
fetches and `tools/localise-media.mjs` rewrites the web app to match; that
download cannot run from a sandbox with no route to Cloudinary.

**Audio.** The Flutter player plays a published `audioMale`, `audioFemale`, or
per-part recording when one exists. The Record tab captures an AAC/M4A sample
locally and sends it to the deployed Groq Worker for transcription and scoring;
server-side scoring is now the native practice path.

**Sign-in, routines, cart, chat, notifications.** Listed on the Profile
screen so the app is honest about its own edges rather than showing dead
buttons. The native pronunciation Record tab and Groq score path are now
implemented; payments and generated word audio still require their own provider
credentials and platform-specific wiring.

Any screen added from here follows one rule: a clip goes through `NwsbVideo`,
never a raw `VideoPlayer` — a controller the pool has never heard of is
exactly the hole the website had, and `test/home_test.dart` checks for it.

---

## What stays where it is

- **The studio** (`admin.html`) is a browser page and cannot be in the app.
- **`functions/api/push.js`** stays on Cloudflare. It already sends to FCM
  tokens as well as Web Push endpoints.
- **The website** is unaffected by any of this and keeps shipping.


## Home dashboard and time-aware banner films

Both native home modes now share the same Focus / Your Progress / Up next hierarchy. Normal Home uses the pale raised neumorphic surface system, while Fashion Home uses translucent dark glass panels and preserves the existing cinematic hero, Fashion Plus, and healing-path language. The Focus film is selected from the device’s local clock: morning is 05:00–11:59, afternoon is 12:00–16:59, evening is 17:00–20:59, and night is 21:00–04:59.

The four optimized MP4s and their posters live in the repository under `assets/video/` and are copied to Flutter by `node tools/flutter-assets.mjs`. The native video pool prefers the R2-backed Worker media route for these four files and falls back to the bundled asset, then the legacy CDN origins. The production media route is `https://nowssb-api.ribonpatil2.workers.dev/media/home-banners/{file}` and supports byte ranges for video playback. A successful native pronunciation score increments the local dashboard session, streak, and unique-word counters.

Before building a native target, run `node tools/flutter-assets.mjs`, then `flutter pub get`. Android microphone permission is applied by `node tools/flutter-android.mjs`; iOS microphone permission is applied by `node tools/flutter-ios.mjs`.
