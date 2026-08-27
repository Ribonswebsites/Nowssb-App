# Flutter iOS configuration

The **only icon source** is `../../assets/icons/app-icon-512.png`, the same image used by the installed webview and PWA. Run `node tools/flutter-icons.mjs` after changing that file; it writes the iOS `AppIcon.appiconset` here and the Android adaptive/legacy resources beside it.

To activate native Flutter login on iOS, register the iOS bundle ID `com.nowssb.app` in Firebase, download `GoogleService-Info.plist`, and place it in this folder locally. The file is deliberately not committed. After `flutter create --platforms=ios,android --org com.nowssb --project-name nowssb .`, run `node tools/flutter-ios.mjs`, then open `ios/Runner.xcworkspace` in Xcode and verify that `GoogleService-Info.plist` has **Runner target membership**. Configure the iOS OAuth client and **Sign in with Apple** in Firebase before attempting a signed `.ipa` archive.
