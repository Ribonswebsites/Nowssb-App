# NowssB on Google Play — the Android shell

Step 5. The app already runs everywhere a browser does; this puts the same
app in the Play Store as an installable Android app, with notifications that
reach the phone when it is fully closed.

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
  `assets/icons/app-icon-512.png`.
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
