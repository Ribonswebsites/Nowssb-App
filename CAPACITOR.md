# NowssB as a real app — Google Play and the App Store

The app already runs everywhere a browser does; this puts the same app in the
Play Store and the App Store as an installable app, with notifications that
reach the phone when it is fully closed.

Android and iOS are both set up. `capacitor.config.json` carries a block for
each, `package.json` has `android:*` and `ios:*` scripts, and
`app/js/part072.js` — the native bridge — gates on `isNativePlatform()`
rather than on Android, so it takes over the notification plumbing, the back
button and the status bar on both platforms with no fork.

**The one thing that is not symmetric:** an Android APK can be built on any
machine, and CI builds one for you on every push (see "Getting a file you can
install", below). An App Store build cannot be produced without an Apple
Developer account — the signing certificate and provisioning profile are
issued to you, not generated from the code. CI compiles the iOS app on every
push to prove it builds, but the installable `.ipa` needs that account.

Nothing here forks the code. The Android app is `index.html` and every file
beside it, bundled into the APK, with one extra script — `app/js/part072.js`
— that does nothing at all in a browser and takes over the notification
plumbing inside the shell. There is one codebase and one deploy of the
website; the app is a second package of the same thing.

---

## Before you start

| | |
|---|---|
| Node | 20 or newer (`node -v`) |
| JDK | 21 (Android Gradle Plugin 8.7+ wants 21) |
| Android Studio | Ladybug or newer, with the Android SDK and Platform Tools |
| A Google Play developer account | one-off $25 |

Set `JAVA_HOME` to the JDK 21 Android Studio ships with if you have no other.

---

## 1. Install and create the Android project

```bash
npm install
npm run android:add        # builds www/, then `npx cap add android`
```

`npm run android:add` runs `tools/build-native.mjs` first. That script is the
boundary between the website and the app: it assembles `www/` from the
repository and **deliberately leaves the studio out** — `admin.html`,
`admin-sw.js`, `admin-manifest.json`, `admin-dev.html`, and
`app/js/part070.js`, the five-tap door that opens it. It then walks what it
actually wrote and fails the build if any of them are there, rather than
trusting its own exclusion list.

It also skips `assets/banners/` — 71 MB of images that nothing in the app
references (every banner comes from Cloudinary). Bundled it would be most of
the download. With it out, `www/` is about 4.4 MB.

`www/` and `android/` are both generated and both git-ignored. Rebuild them
whenever you like; nothing of yours lives there.

After any change to the web app:

```bash
npm run android:sync       # rebuild www/ and copy it into android/
```

---

## 2. Firebase, so notifications work

The web app is reached through Web Push with a VAPID key. **Android's WebView
has no Notification API, no service worker and no push service**, so none of
that reaches the shipped app. Android is reached through Firebase Cloud
Messaging instead. Both paths already exist and both are sent from the same
place — see step 4.

1. Firebase console → your project (`nowssb-34f1b`) → **Add app → Android**.
   - Package name: **`com.nowssb.app`** (must match `capacitor.config.json`).
   - Register, then download **`google-services.json`**.
2. Put it at **`android/app/google-services.json`**.
3. Open `android/build.gradle` and add to `dependencies` in `buildscript`:

   ```gradle
   classpath 'com.google.gms:google-services:4.4.2'
   ```

4. At the **bottom** of `android/app/build.gradle`:

   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

5. Create the notification channel the sender addresses. In
   `android/app/src/main/res/values/strings.xml` nothing is needed, but add to
   `android/app/src/main/AndroidManifest.xml`, inside `<application>`:

   ```xml
   <meta-data
       android:name="com.google.firebase.messaging.default_notification_channel_id"
       android:value="nowssb" />
   <meta-data
       android:name="com.google.firebase.messaging.default_notification_color"
       android:resource="@color/nowssb_gold" />
   ```

   and `android/app/src/main/res/values/colors.xml`:

   ```xml
   <color name="nowssb_gold">#E8D5A3</color>
   ```

6. The small status-bar icon must be a white-on-transparent silhouette or
   Android draws a grey square. `assets/icons/notif-badge.png` is exactly
   that — import it in Android Studio via **res → New → Image Asset →
   Notification Icons** and name it `ic_stat_notify`.

`@capacitor/push-notifications` adds the `POST_NOTIFICATIONS` permission
Android 13+ requires; `part072.js` asks for it from the same **Turn on**
button as the web app, on the Notifications page.

---

## 3. Icons, splash and name

- App name: `android/app/src/main/res/values/strings.xml` → `app_name`.
- Launcher icon: **res → New → Image Asset → Launcher Icons**, from
  `assets/icons/app-icon-512.png`. This is the canonical image shared with
  the Flutter app; do not substitute `logo-disc.webp` or a copied crop.
- Splash background is `#060c18`, already set in `capacitor.config.json`.

---

## 4. The sending side

`functions/api/push.js` now sends both ways from one call. It decides per
subscription: an FCM token goes to FCM, a push endpoint goes to the push
service with the VAPID signing that was already there. The studio's **Send to
every phone** button needs no change — both kinds of phone are in the same
`pushSubs` collection, and both are identified by `endpoint` (an Android one
is stored as `fcm:<token>`), so the retire-dead-subscriptions cleanup works
for both.

One new secret, and only once the Android app exists:

1. Firebase console → **Project settings → Service accounts → Generate new
   private key**. A JSON file downloads.
2. Cloudflare dashboard → Pages → `nowssb-app` → **Settings → Environment
   variables** → add **`FCM_SERVICE_ACCOUNT`**, encrypted, with the entire
   contents of that JSON file pasted as the value.
3. Redeploy.

Until it is set, Web Push keeps working exactly as it does now and Android
subscriptions come back in the send report as unsent with a plain reason.
Nothing breaks in the meantime.

**Never commit that JSON.** `.gitignore` already refuses `*service-account*.json`.

---

## 5. Build and ship

```bash
npm run android:sync
npm run android:open        # opens Android Studio
```

In Android Studio:

1. **Build → Generate Signed App Bundle** → *Android App Bundle*.
2. Create a keystore the first time and **keep it and its passwords safe** —
   Play will not accept an update signed with a different one, ever. Store it
   outside this repository; `.gitignore` refuses `*.keystore` and `*.jks` so
   a stray copy cannot be committed.
3. Release build variant → the `.aab` lands in `android/app/release/`.
4. Play Console → your app → **Production → Create new release** → upload.

For each later release, bump `versionCode` (an integer, must increase) and
`versionName` in `android/app/build.gradle`.

---

## What is different inside the shell

Worth knowing, because it is not obvious from the code:

- **Service worker.** `app/js/part012.js` registers `sw.js` and catches the
  failure. Inside the shell the files are already local, so the caching layer
  it provides is not needed; the idle video pre-warm in `part051.js` becomes
  a no-op and videos stream from Cloudinary as normal.
- **Notifications** go through FCM, not Web Push — `part072.js`. The
  notifications page, the master switch and all sixteen per-kind switches are
  the same page driving a different pipe.
- **Hardware back** closes the topmost open thing, via the same handler the
  browser's back button uses (`window.nwsbCloseTop`, `part049.js`).
- **Content still updates without a release.** Words and meanings come from
  Firestore through `part069.js`, so publishing from the studio reaches the
  installed app immediately. Only changes to the HTML, CSS or JS need a new
  Play release.
- **The studio is not in the app** and cannot be opened from it. Use
  `https://<your-domain>/admin.html` in a browser, where it also installs as
  its own PWA.

---

## The alternative, stated once

A **Trusted Web Activity** (Bubblewrap, `npx @bubblewrap/cli init`) would ship
this same app to Play while keeping the Web Push path already built and
tested — no FCM, no second sender, no `google-services.json`, and content
updates the moment the website deploys. The cost is that it requires the site
to be a fully passing PWA on a verified domain, and the app is a thin wrapper
around the live site rather than a self-contained bundle.

Capacitor is what is set up here, as asked, and it works. If you would rather
have the TWA, nothing above is wasted — `part072.js` no-ops off a native
check, and the FCM branch in `push.js` sits idle when no FCM tokens exist.


---

# iOS — the App Store

Everything above about `www/`, the studio exclusion and the one-codebase rule
is identical on iOS. Only the toolchain and the store differ.

## Before you start

| | |
|---|---|
| A Mac | Xcode does not run on anything else. There is no way around this for the final build. |
| Xcode | 15 or newer, with the iOS SDK and the command line tools |
| CocoaPods | `sudo gem install cocoapods` |
| An Apple Developer account | $99/year, and the thing that gates everything below |

## 1. Create the iOS project

```bash
npm install
npm run ios:add            # builds www/, then `npx cap add ios`
```

`ios/` is generated and git-ignored, exactly like `android/`. Rebuild it
whenever you like; nothing of yours lives there.

Before each Android or iOS asset generation, the packaging scripts copy the
single canonical mark at `assets/icons/app-icon-512.png` into
`resources/icon.png`. Capacitor then creates the platform asset catalog from
that exact source. This keeps the webview, PWA, Flutter adaptive icon, and
iOS AppIcon visually aligned; never replace the generated `resources/icon.png`
with `logo-disc.webp` or a manually cropped variation.

After any change to the web app:

```bash
npm run ios:sync           # rebuild www/ and copy it into ios/
```

## 2. Firebase, so notifications work

iOS is reached through APNs, with Firebase Cloud Messaging in front of it —
the same FCM the Android app uses, so `/api/push` and the studio's one
notification screen serve all three platforms without changes.

1. Firebase console → your project (`nowssb-34f1b`) → **Add app → iOS**.
   - Bundle ID: **`com.nowssb.app`** (must match `capacitor.config.json`).
   - Register, then download **`GoogleService-Info.plist`**.
2. Drag it into `ios/App/App/` **in Xcode** (not in Finder — it has to be
   added to the target, or it ships without being read).
3. Apple Developer portal → **Certificates, Identifiers & Profiles → Keys**
   → create an **APNs Auth Key** (`.p8`). Download it once; it cannot be
   downloaded again.
4. Firebase console → Project settings → **Cloud Messaging** → iOS app →
   upload that `.p8` with its Key ID and your Team ID.
5. In Xcode, select the App target → **Signing & Capabilities** → **+
   Capability** → add **Push Notifications** and **Background Modes**, and
   tick *Remote notifications* under Background Modes.

`GoogleService-Info.plist` is not secret in the way a service account is, but
it identifies your project — it is covered by the same rule as
`google-services.json`: it lives in the generated `ios/` folder, which git
never sees.

The iOS wrapper deliberately does **not** use App-Bound Domains. Firebase's
Google sign-in redirect must be able to navigate to Google and the configured
Firebase auth handler; restricting the embedded browser to an app-bound list
causes an otherwise valid iOS login to fail before the credential returns.

## 3. Signing

Xcode → App target → **Signing & Capabilities** → tick **Automatically manage
signing** and pick your team. Xcode creates the certificate and profile for
you the first time.

## 4. Build and upload

```bash
npm run ios:sync
npm run ios:open           # opens the generated iOS project in Xcode
```

In Xcode: choose **Any iOS Device (arm64)** as the destination, then
**Product → Archive**. When the Organiser opens, **Distribute App → App Store
Connect → Upload**.

Then App Store Connect → your app → TestFlight for testers, or submit for
review to go live.

## What Apple will ask for that Google does not

- **A privacy manifest.** `PrivacyInfo.xcprivacy` declaring what the app
  collects. The app collects an account email, a display name and practice
  data, and uses a push token.
- **App Tracking Transparency** — only if you ever add tracking. Today the
  app does not track across other companies' apps, so declare that and there
  is no prompt to add.
- **Sign in with Apple.** This is the one that catches people out: if an app
  offers third-party sign-in — and this one offers Google — Apple requires
  Sign in with Apple alongside it. Firebase Auth supports it
  (`OAuthProvider('apple.com')`), and it has to be added to the login screen
  before review, not after a rejection.
- **A demo account** in App Review notes, or reviewers cannot get past login.

---

# Getting a file you can install, without a toolchain

`android/` and `ios/` are generated, so building locally means installing
Android Studio or Xcode. Two workflows in `.github/workflows/` do it on
GitHub's runners instead.

**`android-apk.yml`** — on every push to `main`, and on demand from the
Actions tab. It builds a **debug APK** and attaches it to the run as an
artifact: download it from the run page and sideload it on any phone with
"install unknown apps" enabled. That is a real, installable Android app, with
no toolchain on your machine.

It has a second job for the **signed release bundle** Play needs. That one
runs only when you trigger it by hand AND the signing secrets are set, because
a release build cannot be signed without them:

| Secret | What it is |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | your `.keystore`, base64-encoded (`base64 -w0 nowssb.keystore`) |
| `ANDROID_KEYSTORE_PASSWORD` | the store password |
| `ANDROID_KEY_ALIAS` | the key alias |
| `ANDROID_KEY_PASSWORD` | the key password |

Add them in **Settings → Secrets and variables → Actions**. The keystore is
written into the runner for that one run and never enters the repository —
`.gitignore` refuses `*.keystore`, `*.jks` and `key.properties` so it cannot,
even by accident. **Keep your own copy of the keystore somewhere safe: lose it
and you can never update the app on Play again**, only publish a new listing.

**`ios-build.yml`** — compiles the iOS app on a macOS runner on every push, so
a broken iOS build is caught immediately. It builds **unsigned**, which means
it proves the project is sound but does not hand you something installable.
Turning it into a TestFlight upload needs your Apple certificate and profile
in secrets; until the developer account exists there is nothing to put there.
