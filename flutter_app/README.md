# NowssB — the Flutter app

Real Flutter. Dart widgets, no WebView, no HTML inside. It reads the same
Firestore content the website reads, so a word published from the studio
appears here without a Play release.

## Getting the APK without installing anything

Push to `main`, then **Actions → Flutter APK → the latest run → Artifacts →
`nowssb-flutter-debug-apk`**. That is an installable Android app. Enable
"install unknown apps" on the phone and open it.

For the Play upload, run the workflow by hand (**Run workflow**) once the
signing secrets are set — it produces the `.aab` Play wants.

## Building it locally instead

```bash
cd flutter_app
flutter create --platforms=android --org com.nowssb --project-name nowssb .
flutter pub get
flutter run
```

`flutter create` only writes the platform folders; it leaves `lib/` and
`pubspec.yaml` alone.

## What is here

```
lib/
  main.dart              the app, the themes, the entry point
  theme/tokens.dart      colours, shadows, radii — lifted from the CSS,
                         with the rule each one came from in a comment
  theme/theme.dart       the two surfaces: light neumorphic, deep navy
  widgets/neumorphic.dart the raised-card language and the black banner
  shell/nav_shell.dart   the five-tab bottom nav
  screens/home_normal.dart  the Normal home, section for section
```

## What is not here yet

The Normal home is done. The other 73 screens are not — the Fashion home,
the store, the word player, the reader, the library, Connect, the health
journey, checkout, profile. They come next, screen by screen.

## Signing, for Play

```bash
keytool -genkey -v -keystore nowssb.keystore -keyalg RSA \
        -keysize 2048 -validity 10000 -alias nowssb
```

Back that file up in two places. **Lose it and the app can never be updated
on Play again** — only republished as a new listing under a new package name.

Then base64 it (`base64 -w0 nowssb.keystore`) and put it, with the three
passwords, in **Settings → Secrets and variables → Actions**:
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
`ANDROID_KEY_PASSWORD`. The keystore never enters this repository —
`.gitignore` refuses `*.keystore`, `*.jks` and `key.properties`.
