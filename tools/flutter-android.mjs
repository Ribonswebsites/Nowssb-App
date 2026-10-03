// Configures the generated Android project, after `flutter create`.
//
// flutter_app/android/ is generated and not committed, so everything this app
// needs beyond the defaults has to be applied on the way into a build. Four
// things, each of which the build fails without:
//
//   1. THE APPLICATION ID.  google-services.json is issued for a package name,
//      and the one in the Firebase console is `com.nowssb.app`. flutter create
//      derives `com.nowssb.nowssb` from --org and --project-name, and the
//      google-services plugin refuses a mismatch outright. Only applicationId
//      is changed; the namespace stays as generated, because the manifest
//      resolves `.MainActivity` against the namespace and moving it would mean
//      moving the Kotlin file too, for nothing.
//
//   2. CORE LIBRARY DESUGARING.  flutter_local_notifications uses java.time,
//      which does not exist below API 26, so it requires desugaring and the
//      build says so by name.
//
//   3. minSdk 23.  firebase_auth's floor. The Flutter default is lower.
//
//   4. THE GOOGLE SERVICES PLUGIN, plus the json beside it. The FlutterFire
//      packages do not apply this for you — without it the json is inert and
//      Firebase.initializeApp() fails at runtime with no default options.
//
//   5. THE LAUNCHER ICON.  flutter create ships its own blue Flutter mark in
//      every mipmap folder, so the app installs on the home screen under
//      somebody else's logo. The app's icon is the same file the PWA is
//      installed under — assets/icons/app-icon-512.png, the one named in
//      manifest.json — cut to the five densities by tools/flutter-icons.mjs,
//      committed, and copied in here because android/res is generated and
//      would lose it otherwise.
//
//   6. THE INTERNET PERMISSION.  flutter create writes it into the debug and
//      profile manifests ONLY, so everything this app does over a network
//      works while you develop and is dead in the APK you ship: Firestore,
//      sign-in, notifications, and the R2 artwork the pages are drawn
//      from. It has to be in the main manifest, and the main manifest is
//      generated, so it has to be added here.
//
//   7. THE HOME-SCREEN WIDGET.  The streak + word-of-the-day widget
//      (home_widget package): its AppWidgetProvider, RemoteViews layout,
//      provider info and manifest receiver live in the generated android/
//      tree, so they are written here too.
//
// Run it AFTER `flutter create` and BEFORE `flutter build`. It is idempotent:
// running twice is a no-op, so a local android/ that is already configured is
// left alone.
//
//   node tools/flutter-android.mjs

import {
  readFileSync,
  writeFileSync,
  existsSync,
  copyFileSync,
  cpSync,
  mkdirSync,
} from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const android = join(root, 'flutter_app', 'android');

/** The package name Firebase issued the config for. Read from the file rather
 *  than written here twice — if the console ever issues a new one, this
 *  follows it. */
const configJson = join(root, 'flutter_app', 'android-config', 'google-services.json');
if (!existsSync(configJson)) {
  console.error(`missing ${configJson}`);
  process.exit(1);
}
const APP_ID = JSON.parse(readFileSync(configJson, 'utf8'))
  .client[0].client_info.android_client_info.package_name;
/** Public launcher label used by the website title and PWA short name. */
const DISPLAY_NAME = 'NowssB';

if (!existsSync(android)) {
  console.error(`missing ${android} — run \`flutter create --platforms=android\` first`);
  process.exit(1);
}

// Pinned deliberately. A build that quietly changes its toolchain between runs
// is a build that fails on a day nobody touched it.
const GOOGLE_SERVICES = '4.4.2';
const DESUGAR_LIBS = '2.1.4';

const appGradle = join(android, 'app', 'build.gradle.kts');
const settings = join(android, 'settings.gradle.kts');

for (const f of [appGradle, settings]) {
  if (!existsSync(f)) {
    console.error(`missing ${f} — this script expects the Kotlin DSL that ` +
      `flutter create writes; if Flutter has gone back to Groovy, update it`);
    process.exit(1);
  }
}

const done = [];
const already = [];

// ── settings.gradle.kts: declare the plugin ────────────────────────────
let s = readFileSync(settings, 'utf8');
if (s.includes('com.google.gms.google-services')) {
  already.push('google-services declared');
} else {
  const anchor = 'id("com.android.application")';
  const at = s.indexOf(anchor);
  if (at < 0) throw new Error('settings.gradle.kts: no com.android.application plugin line');
  const eol = s.indexOf('\n', at);
  s = s.slice(0, eol + 1) +
    `    id("com.google.gms.google-services") version "${GOOGLE_SERVICES}" apply false\n` +
    s.slice(eol + 1);
  writeFileSync(settings, s);
  done.push('declared google-services');
}

// ── app/build.gradle.kts ───────────────────────────────────────────────
let a = readFileSync(appGradle, 'utf8');

// 4. apply the plugin
if (a.includes('id("com.google.gms.google-services")')) {
  already.push('google-services applied');
} else {
  a = a.replace(
    'id("dev.flutter.flutter-gradle-plugin")',
    'id("dev.flutter.flutter-gradle-plugin")\n    id("com.google.gms.google-services")',
  );
  done.push('applied google-services');
}

// 1. the application id Firebase issued the config for
if (a.includes(`applicationId = "${APP_ID}"`)) {
  already.push(`applicationId ${APP_ID}`);
} else {
  const before = a;
  a = a.replace(/applicationId = "[^"]*"/, `applicationId = "${APP_ID}"`);
  if (a === before) throw new Error('app/build.gradle.kts: no applicationId line');
  done.push(`applicationId → ${APP_ID}`);
}

// 3. firebase_auth's floor
if (/minSdk = 23\b/.test(a)) {
  already.push('minSdk 23');
} else {
  const before = a;
  a = a.replace(/minSdk = flutter\.minSdkVersion/, 'minSdk = 23');
  if (a === before && !/minSdk = \d+/.test(a)) {
    throw new Error('app/build.gradle.kts: no minSdk line');
  }
  done.push('minSdk → 23');
}

// file_picker (and flutter_plugin_android_lifecycle) require compileSdk 36.
// Flutter's default is still 34/35 on this channel; the app and every
// plugin module have to match or assembleDebug dies in checkDebugAarMetadata.
if (/compileSdk = 36\b/.test(a)) {
  already.push('compileSdk 36');
} else {
  const before = a;
  a = a.replace(
    /compileSdk = flutter\.compileSdkVersion/,
    'compileSdk = 36',
  );
  if (a === before && !/compileSdk = \d+/.test(a)) {
    a = a.replace(/compileSdk = \d+/, 'compileSdk = 36');
  }
  if (!/compileSdk = 36\b/.test(a)) {
    throw new Error('app/build.gradle.kts: no compileSdk line');
  }
  done.push('compileSdk → 36');
}

// 2. desugaring: the flag, and the library that backs it
if (a.includes('isCoreLibraryDesugaringEnabled')) {
  already.push('desugaring enabled');
} else {
  const before = a;
  a = a.replace(
    /(compileOptions \{\n)/,
    `$1        isCoreLibraryDesugaringEnabled = true\n`,
  );
  if (a === before) throw new Error('app/build.gradle.kts: no compileOptions block');
  done.push('enabled core library desugaring');
}

if (a.includes('coreLibraryDesugaring(')) {
  already.push('desugar_jdk_libs present');
} else {
  a += `\n// Required by flutter_local_notifications, which uses java.time — a class\n` +
       `// that does not exist below API 26 and has to be desugared in.\n` +
       `dependencies {\n` +
       `    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:${DESUGAR_LIBS}")\n` +
       `}\n`;
  done.push('added desugar_jdk_libs');
}

writeFileSync(appGradle, a);

// ── launcher icon ──────────────────────────────────────────────────────
// Copy the WebView's complete adaptive-icon resource set, generated from the
// website mark. A legacy Flutter `mipmap/ic_launcher.png` is normalized and
// inset by Android launchers, which made the same artwork look visibly smaller
// than the WebView install. The v26 adaptive XML, foreground, background,
// round icon, and legacy fallbacks below are byte-for-byte the WebView set.
const ICON_SRC = join(root, 'flutter_app', 'android-config', 'adaptive-res');
const res = join(android, 'app', 'src', 'main', 'res');
{
  if (!existsSync(join(ICON_SRC, 'mipmap-anydpi-v26', 'ic_launcher.xml')) ||
      !existsSync(join(ICON_SRC, 'mipmap-xxxhdpi', 'ic_launcher_foreground.png'))) {
    console.error(
      `missing WebView-compatible adaptive launcher resources under ${ICON_SRC}`,
    );
    process.exit(1);
  }
  // Do not copy values/styles.xml. Capacitor's generated theme would replace
  // Flutter's Theme.SplashScreen and colors, preventing Android resource
  // linking. Launcher artwork lives entirely in these drawable/mipmap paths.
  for (const folder of [
    'drawable',
    'drawable-v24',
    'mipmap-anydpi-v26',
    'mipmap-ldpi',
    'mipmap-mdpi',
    'mipmap-hdpi',
    'mipmap-xhdpi',
    'mipmap-xxhdpi',
    'mipmap-xxxhdpi',
  ]) {
    cpSync(join(ICON_SRC, folder), join(res, folder), {
      recursive: true,
      force: true,
    });
  }
  done.push('copied WebView-compatible adaptive launcher resources');
}

// ── the manifest ───────────────────────────────────────────────────────
// Without INTERNET in the MAIN manifest a release build has no network at
// all. The TTS query makes the device speech engine discoverable on Android
// 11+ for the real native practice player.
const manifest = join(android, 'app', 'src', 'main', 'AndroidManifest.xml');
if (!existsSync(manifest)) {
  console.error(`missing ${manifest}`);
  process.exit(1);
}
let m = readFileSync(manifest, 'utf8');

// flutter create derives a lower-case label from the package name. Keep the
// Android home-screen label consistent with the website and PWA instead.
if (m.includes(`android:label="${DISPLAY_NAME}"`)) {
  already.push(`application label ${DISPLAY_NAME}`);
} else {
  const before = m;
  m = m.replace(/android:label="[^"]*"/, `android:label="${DISPLAY_NAME}"`);
  if (m === before) throw new Error('AndroidManifest.xml: no application label');
  done.push(`application label → ${DISPLAY_NAME}`);
}

if (m.includes('android.permission.INTERNET')) {
  already.push('INTERNET permission present');
} else {
  const open = m.match(/<manifest[^>]*>\s*/);
  if (!open) throw new Error('AndroidManifest.xml: no <manifest> element');
  m = m.replace(
    open[0],
    open[0] +
      '    <!-- flutter create puts these in the debug and profile manifests\n' +
      '         only. Without them a release build has no network: no\n' +
      '         Firestore, no sign-in, no notifications, and no artwork. -->\n' +
      '    <uses-permission android:name="android.permission.INTERNET"/>\n' +
      '    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>\n\n',
  );
  done.push('added INTERNET and ACCESS_NETWORK_STATE');
}

if (m.includes('android.speech.tts.engine.TTS_SERVICE')) {
  already.push('text-to-speech engine query present');
} else {
  const open = m.match(/<manifest[^>]*>\s*/);
  if (!open) throw new Error('AndroidManifest.xml: no <manifest> element');
  m = m.replace(
    open[0],
    open[0] +
      '    <queries>\n' +
      '        <intent>\n' +
      '            <action android:name="android.speech.tts.engine.TTS_SERVICE"/>\n' +
      '        </intent>\n' +
      '    </queries>\n\n',
  );
  done.push('declared text-to-speech engine query');
}
writeFileSync(manifest, m);

// ── in-app updater: installer, download service, release signing ─────
// The update prompt (lib/app_update.dart) downloads into the app sandbox
// and calls the `com.nowssb.app/update` channel:
//
//   installApk               hand the verified file to Android's installer.
//                            FileProvider is required because Android will
//                            not accept a file:// URI.
//   supportedAbis            Build.SUPPORTED_ABIS, so the smaller per-ABI
//                            APK can be chosen.
//   canInstallPackages       whether "Install unknown apps" is allowed yet.
//   startDownloadService     a small foreground service with a progress
//   updateDownloadProgress   notification. It keeps the process at
//   stopDownloadService      foreground priority while ~400 MB downloads, so
//                            leaving the app does not get the download killed.
//                            The bytes are fetched by Dart (HTTP Range resume,
//                            retries); the service only holds the process up.
if (!m.includes('android.permission.REQUEST_INSTALL_PACKAGES')) {
  m = m.replace(
    '<uses-permission android:name="android.permission.INTERNET"/>',
    '<uses-permission android:name="android.permission.INTERNET"/>\n' +
    '    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>',
  );
}
if (!m.includes('android.permission.POST_NOTIFICATIONS')) {
  m = m.replace(
    '<uses-permission android:name="android.permission.INTERNET"/>',
    '<uses-permission android:name="android.permission.INTERNET"/>\n' +
    '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n' +
    '    <uses-permission android:name="android.permission.VIBRATE"/>\n' +
    '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>\n' +
    '    <uses-permission android:name="android.permission.WAKE_LOCK"/>',
  );
}
if (!m.includes('default_notification_channel_id')) {
  m = m.replace(
    '<application',
    '<application',
  );
  m = m.replace(
    '</application>',
    `    <meta-data\n` +
    `        android:name="com.google.firebase.messaging.default_notification_channel_id"\n` +
    `        android:value="nowssb" />\n` +
    `    <meta-data\n` +
    `        android:name="com.google.firebase.messaging.default_notification_icon"\n` +
    `        android:resource="@drawable/ic_stat_nowssb" />\n` +
    `</application>`,
  );
}
// flutter_local_notifications draws scheduled notifications (word of the
// day, streak, daily spin, weekly summary, plan ending, Reader reminders —
// lib/features/notifications/notif_scheduler.dart) from these receivers.
// Without them Android fires the alarm into nothing: the older daily
// reminder never appeared for that reason. The boot receiver re-arms them
// after a restart or an app update.
if (m.includes('nowssb_alerts')) m = m.replace('android:value="nowssb_alerts"', 'android:value="nowssb"');
if (!m.includes('com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver')) {
  m = m.replace(
    '</application>',
    `    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />\n` +
    `    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">\n` +
    `        <intent-filter>\n` +
    `            <action android:name="android.intent.action.BOOT_COMPLETED" />\n` +
    `            <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />\n` +
    `            <action android:name="android.intent.action.QUICKBOOT_POWERON" />\n` +
    `            <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />\n` +
    `        </intent-filter>\n` +
    `    </receiver>\n` +
    `</application>`,
  );
  done.push('scheduled-notification receivers (flutter_local_notifications)');
}
if (!m.includes('android.permission.FOREGROUND_SERVICE_DATA_SYNC')) {
  m = m.replace(
    '<uses-permission android:name="android.permission.INTERNET"/>',
    '<uses-permission android:name="android.permission.INTERNET"/>\n' +
    '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>\n' +
    '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>',
  );
}
if (!m.includes('androidx.core.content.FileProvider')) {
  m = m.replace(
    '</application>',
    `    <provider\n` +
    `        android:name="androidx.core.content.FileProvider"\n` +
    `        android:authorities="${APP_ID}.fileprovider"\n` +
    `        android:exported="false"\n` +
    `        android:grantUriPermissions="true">\n` +
    `        <meta-data\n` +
    `            android:name="android.support.FILE_PROVIDER_PATHS"\n` +
    `            android:resource="@xml/update_paths" />\n` +
    `    </provider>\n` +
    `</application>`,
  );
}
if (!m.includes('.UpdateDownloadService')) {
  m = m.replace(
    '</application>',
    `    <service\n` +
    `        android:name=".UpdateDownloadService"\n` +
    `        android:exported="false"\n` +
    `        android:foregroundServiceType="dataSync" />\n` +
    `</application>`,
  );
}
writeFileSync(manifest, m);

const drawableDir = join(android, 'app', 'src', 'main', 'res', 'drawable');
mkdirSync(drawableDir, { recursive: true });
writeFileSync(join(drawableDir, 'ic_stat_nowssb.xml'),
  '<?xml version="1.0" encoding="utf-8"?>\n' +
  '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n' +
  '    android:width="24dp" android:height="24dp"\n' +
  '    android:viewportWidth="24" android:viewportHeight="24">\n' +
  '    <path android:fillColor="#FFFFFFFF"\n' +
  '        android:pathData="M12,22a2,2 0,0 0,2 -2h-4a2,2 0,0 0,2 2zM18,16v-5a6,6 0,0 0,-5 -5.91V4a1,1 0,0 0,-2 0v1.09A6,6 0,0 0,6 11v5l-2,2v1h16v-1z"/>\n' +
  '</vector>\n');

const xmlDir = join(android, 'app', 'src', 'main', 'res', 'xml');
mkdirSync(xmlDir, { recursive: true });
writeFileSync(join(xmlDir, 'update_paths.xml'),
  '<?xml version="1.0" encoding="utf-8"?>\n' +
  '<paths xmlns:android="http://schemas.android.com/apk/res/android">\n' +
  '    <files-path name="updates" path="." />\n' +
  '</paths>\n');

const kotlinDir = join(android, 'app', 'src', 'main', 'kotlin', 'com', 'nowssb', 'nowssb');
const activity = join(kotlinDir, 'MainActivity.kt');
mkdirSync(kotlinDir, { recursive: true });
writeFileSync(activity, `package com.nowssb.nowssb

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.nowssb.app/update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val file = File(call.argument<String>("path") ?: "")
                        if (!file.exists()) { result.error("MISSING_APK", "Downloaded APK is missing", null); return@setMethodCallHandler }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
                            startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
                            result.error("INSTALL_PERMISSION", "Allow NowssB to install updates, then try again", null)
                            return@setMethodCallHandler
                        }
                        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
                        startActivity(Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                        })
                        result.success(null)
                    }
                    "supportedAbis" -> result.success(Build.SUPPORTED_ABIS.toList())
                    "canInstallPackages" -> result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls()
                    )
                    "startDownloadService" -> {
                        result.success(UpdateDownloadService.start(this, call.argument<String>("text") ?: "Downloading update"))
                    }
                    "updateDownloadProgress" -> {
                        UpdateDownloadService.progress(
                            this,
                            call.argument<String>("text") ?: "Downloading update",
                            call.argument<Int>("percent") ?: -1,
                        )
                        result.success(null)
                    }
                    "stopDownloadService" -> {
                        UpdateDownloadService.stop(this, call.argument<String>("doneText"))
                        result.success(null)
                    }
                    "keepAwake" -> {
                        val on = call.argument<Boolean>("on") == true
                        runOnUiThread {
                            if (on) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
`);

writeFileSync(join(kotlinDir, 'UpdateDownloadService.kt'), `package com.nowssb.nowssb

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

/**
 * Holds the app process at foreground priority while the in-app updater
 * downloads, and shows the progress in a notification. It does no
 * networking itself: Dart streams the bytes (with Range resume and retries)
 * and pushes progress here. If the task is swiped away the service stops;
 * the partial file stays on disk and the next launch resumes from it.
 */
class UpdateDownloadService : Service() {
    companion object {
        private const val CHANNEL_ID = "nowssb_app_update"
        private const val NOTIFICATION_ID = 73017
        private const val EXTRA_TEXT = "text"

        private fun channel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(NotificationManager::class.java) ?: return
            if (manager.getNotificationChannel(CHANNEL_ID) != null) return
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "App updates", NotificationManager.IMPORTANCE_LOW).apply {
                    description = "Progress of NowssB update downloads"
                    setShowBadge(false)
                }
            )
        }

        private fun openApp(context: Context): PendingIntent? {
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
            launch.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            return PendingIntent.getActivity(
                context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        fun build(context: Context, text: String, percent: Int, ongoing: Boolean = true): Notification {
            channel(context)
            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(if (ongoing) android.R.drawable.stat_sys_download else android.R.drawable.stat_sys_download_done)
                .setContentTitle("NowssB update")
                .setContentText(text)
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setOngoing(ongoing)
                .setAutoCancel(!ongoing)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setContentIntent(openApp(context))
            if (ongoing) builder.setProgress(100, percent.coerceIn(0, 100), percent < 0)
            return builder.build()
        }

        private fun post(context: Context, notification: Notification) {
            try {
                context.getSystemService(NotificationManager::class.java)?.notify(NOTIFICATION_ID, notification)
            } catch (_: Exception) {
                // Notifications denied: the download carries on regardless.
            }
        }

        fun start(context: Context, text: String): Boolean = try {
            ContextCompat.startForegroundService(
                context,
                Intent(context, UpdateDownloadService::class.java).putExtra(EXTRA_TEXT, text),
            )
            true
        } catch (_: Exception) {
            // Android 12+ refuses to start a foreground service from the
            // background. The download still runs while the process lives.
            false
        }

        fun progress(context: Context, text: String, percent: Int) {
            post(context, build(context, text, percent))
        }

        fun stop(context: Context, doneText: String?) {
            try {
                context.stopService(Intent(context, UpdateDownloadService::class.java))
            } catch (_: Exception) {
            }
            val manager = context.getSystemService(NotificationManager::class.java)
            if (doneText.isNullOrEmpty()) {
                manager?.cancel(NOTIFICATION_ID)
            } else {
                post(context, build(context, doneText, 100, ongoing = false))
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = build(this, intent?.getStringExtra(EXTRA_TEXT) ?: "Downloading update", -1)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (_: Exception) {
            stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    // Android 15 caps dataSync services at six hours a day. Stop cleanly; the
    // Dart download keeps going while the app is open and resumes otherwise.
    override fun onTimeout(startId: Int, fgsType: Int) {
        stopSelf()
    }
}
`);
done.push('configured in-app updater (installer, ABI query, download service)');

// ── home-screen widget: streak + word of the day ───────────────────────
// lib/data/home_widget_sync.dart writes the data (home_widget package,
// SharedPreferences "HomeWidgetPreferences"): the streak, the last day you
// practised, and the word of the day for today and the next six days, so
// the widget rolls over at midnight on its own (the provider re-reads every
// hour, and the app also schedules an update just after each midnight).
// Tap the card → the app; tap "Practise" → the player on that word. All
// RemoteViews (TextView / ImageView / LinearLayout), no Compose.
{
  const res = join(android, 'app', 'src', 'main', 'res');
  for (const d of ['layout', 'xml', 'drawable', 'values']) mkdirSync(join(res, d), { recursive: true });

  writeFileSync(join(res, 'drawable', 'nowssb_widget_bg.xml'),
    '<?xml version="1.0" encoding="utf-8"?>\n' +
    '<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">\n' +
    '    <gradient android:angle="315" android:startColor="#FF050A16" android:centerColor="#FF0B1730" android:endColor="#FF14213D" android:type="linear"/>\n' +
    '    <corners android:radius="26dp"/>\n' +
    '    <stroke android:width="1dp" android:color="#40E8D5A3"/>\n' +
    '</shape>\n');
  writeFileSync(join(res, 'drawable', 'nowssb_widget_glass.xml'),
    '<?xml version="1.0" encoding="utf-8"?>\n' +
    '<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">\n' +
    '    <solid android:color="#1AFFFFFF"/>\n' +
    '    <corners android:radius="18dp"/>\n' +
    '    <stroke android:width="1dp" android:color="#26FFFFFF"/>\n' +
    '</shape>\n');
  writeFileSync(join(res, 'drawable', 'nowssb_widget_pill.xml'),
    '<?xml version="1.0" encoding="utf-8"?>\n' +
    '<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">\n' +
    '    <solid android:color="#FFFFFFFF"/>\n' +
    '    <corners android:radius="999dp"/>\n' +
    '</shape>\n');
  writeFileSync(join(res, 'drawable', 'nowssb_widget_flame.xml'),
    '<?xml version="1.0" encoding="utf-8"?>\n' +
    '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n' +
    '    android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">\n' +
    '    <path android:fillColor="#FFE8D5A3"\n' +
    '        android:pathData="M13.5,0.67s0.74,2.65 0.74,4.8c0,2.06 -1.35,3.73 -3.41,3.73 -2.07,0 -3.63,-1.67 -3.63,-3.73l0.03,-0.36C5.21,7.51 4,10.62 4,14c0,4.42 3.58,8 8,8s8,-3.58 8,-8C20,8.61 17.41,3.8 13.5,0.67zM11.71,19c-1.78,0 -3.22,-1.4 -3.22,-3.14 0,-1.62 1.05,-2.76 2.81,-3.12 1.77,-0.36 3.6,-1.21 4.62,-2.58 0.39,1.29 0.59,2.65 0.59,4.04 0,2.65 -2.15,4.8 -4.8,4.8z"/>\n' +
    '</vector>\n');
  writeFileSync(join(res, 'drawable', 'nowssb_widget_play.xml'),
    '<?xml version="1.0" encoding="utf-8"?>\n' +
    '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n' +
    '    android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">\n' +
    '    <path android:fillColor="#FF060C18" android:pathData="M8,5.14v13.72a1,1 0,0 0,1.52 0.85l10.29,-6.86a1,1 0,0 0,0 -1.7L9.52,4.29A1,1 0,0 0,8 5.14z"/>\n' +
    '</vector>\n');

  writeFileSync(join(res, 'layout', 'nowssb_widget.xml'),
`<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/nw_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/nowssb_widget_bg"
    android:orientation="horizontal"
    android:padding="14dp">

    <!-- Streak -->
    <LinearLayout
        android:id="@+id/nw_streak_box"
        android:layout_width="wrap_content"
        android:layout_height="match_parent"
        android:minWidth="84dp"
        android:background="@drawable/nowssb_widget_glass"
        android:gravity="center"
        android:orientation="vertical"
        android:paddingStart="12dp"
        android:paddingEnd="12dp">

        <ImageView
            android:layout_width="22dp"
            android:layout_height="22dp"
            android:contentDescription="@string/nowssb_widget_streak"
            android:src="@drawable/nowssb_widget_flame"/>

        <TextView
            android:id="@+id/nw_streak"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:fontFamily="sans-serif-medium"
            android:includeFontPadding="false"
            android:text="0"
            android:textColor="#FFFFFFFF"
            android:textSize="30sp"/>

        <TextView
            android:id="@+id/nw_streak_label"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:letterSpacing="0.12"
            android:text="@string/nowssb_widget_day_streak"
            android:textAllCaps="true"
            android:textColor="#B3E8D5A3"
            android:textSize="9sp"/>
    </LinearLayout>

    <!-- Word of the day -->
    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="match_parent"
        android:layout_marginStart="14dp"
        android:layout_weight="1"
        android:orientation="vertical">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:gravity="center_vertical"
            android:orientation="horizontal">

            <TextView
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                android:fontFamily="sans-serif-medium"
                android:letterSpacing="0.22"
                android:text="@string/nowssb_widget_wotd"
                android:textColor="#FFE8D5A3"
                android:textSize="9sp"/>

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:fontFamily="sans-serif-medium"
                android:letterSpacing="0.3"
                android:text="NOWSSB"
                android:textColor="#66FFFFFF"
                android:textSize="8sp"/>
        </LinearLayout>

        <TextView
            android:id="@+id/nw_word"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="4dp"
            android:ellipsize="end"
            android:fontFamily="sans-serif-medium"
            android:maxLines="1"
            android:text="NowssB"
            android:textColor="#FFFFFFFF"
            android:textSize="22sp"/>

        <TextView
            android:id="@+id/nw_line"
            android:layout_width="match_parent"
            android:layout_height="0dp"
            android:layout_weight="1"
            android:ellipsize="end"
            android:fontFamily="sans-serif-light"
            android:maxLines="2"
            android:text="@string/nowssb_widget_loading"
            android:textColor="#B3FFFFFF"
            android:textSize="12sp"/>

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:gravity="center_vertical"
            android:orientation="horizontal">

            <TextView
                android:id="@+id/nw_status"
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                android:ellipsize="end"
                android:maxLines="1"
                android:text="@string/nowssb_widget_start"
                android:textColor="#80FFFFFF"
                android:textSize="10sp"/>

            <LinearLayout
                android:id="@+id/nw_practice"
                android:layout_width="wrap_content"
                android:layout_height="30dp"
                android:background="@drawable/nowssb_widget_pill"
                android:gravity="center_vertical"
                android:orientation="horizontal"
                android:paddingStart="10dp"
                android:paddingEnd="14dp">

                <ImageView
                    android:layout_width="14dp"
                    android:layout_height="14dp"
                    android:contentDescription="@string/nowssb_widget_practise"
                    android:src="@drawable/nowssb_widget_play"/>

                <TextView
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:layout_marginStart="5dp"
                    android:fontFamily="sans-serif-medium"
                    android:letterSpacing="0.08"
                    android:text="@string/nowssb_widget_practise"
                    android:textColor="#FF060C18"
                    android:textSize="11sp"/>
            </LinearLayout>
        </LinearLayout>
    </LinearLayout>
</LinearLayout>
`);

  writeFileSync(join(res, 'values', 'nowssb_widget_strings.xml'),
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n' +
    '    <string name="nowssb_widget_name">NowssB streak &amp; word</string>\n' +
    '    <string name="nowssb_widget_description">Your practice streak and the word of the day</string>\n' +
    '    <string name="nowssb_widget_streak">Streak</string>\n' +
    '    <string name="nowssb_widget_day_streak">day streak</string>\n' +
    '    <string name="nowssb_widget_wotd">WORD OF THE DAY</string>\n' +
    '    <string name="nowssb_widget_loading">Open NowssB once to load today\\\'s word</string>\n' +
    '    <string name="nowssb_widget_start">Start a streak today</string>\n' +
    '    <string name="nowssb_widget_practise">Practise</string>\n' +
    '</resources>\n');

  writeFileSync(join(res, 'xml', 'nowssb_widget_info.xml'),
    '<?xml version="1.0" encoding="utf-8"?>\n' +
    '<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"\n' +
    '    android:minWidth="250dp"\n' +
    '    android:minHeight="110dp"\n' +
    '    android:minResizeWidth="250dp"\n' +
    '    android:minResizeHeight="110dp"\n' +
    '    android:targetCellWidth="4"\n' +
    '    android:targetCellHeight="2"\n' +
    '    android:resizeMode="horizontal|vertical"\n' +
    '    android:updatePeriodMillis="3600000"\n' +
    '    android:initialLayout="@layout/nowssb_widget"\n' +
    '    android:previewLayout="@layout/nowssb_widget"\n' +
    '    android:previewImage="@mipmap/ic_launcher"\n' +
    '    android:description="@string/nowssb_widget_description"\n' +
    '    android:widgetCategory="home_screen" />\n');

  writeFileSync(join(kotlinDir, 'NowssbHomeWidget.kt'), `package com.nowssb.nowssb

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/** Home-screen widget: practice streak + word of the day (see home_widget_sync.dart). */
class NowssbHomeWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val cal = Calendar.getInstance()
        val today = fmt.format(cal.time)
        cal.add(Calendar.DAY_OF_YEAR, -1)
        val yesterday = fmt.format(cal.time)

        val last = widgetData.getString("nw_last_day", "") ?: ""
        val saved = widgetData.getString("nw_streak", "0")?.toIntOrNull() ?: 0
        // A streak only survives if you practised today or yesterday.
        val streak = if (last == today || last == yesterday) saved else 0
        val status = when {
            last == today -> "Practised today · well done"
            streak > 0 -> "Practise today to keep it"
            else -> "Start a streak today"
        }
        val word = widgetData.getString("nw_word_" + today, null)
            ?: widgetData.getString("nw_word_fallback", null)
            ?: "NowssB"
        val line = widgetData.getString("nw_line_" + today, null)
            ?: widgetData.getString("nw_line_fallback", null)
            ?: "Open NowssB once to load today's word"

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.nowssb_widget)
            views.setTextViewText(R.id.nw_streak, streak.toString())
            views.setTextViewText(R.id.nw_streak_label, if (streak == 1) "day streak" else "days in a row")
            views.setTextViewText(R.id.nw_word, word)
            views.setTextViewText(R.id.nw_line, line)
            views.setTextViewText(R.id.nw_status, status)
            views.setOnClickPendingIntent(
                R.id.nw_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("nowssb://widget/home")),
            )
            views.setOnClickPendingIntent(
                R.id.nw_streak_box,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("nowssb://widget/streak")),
            )
            views.setOnClickPendingIntent(
                R.id.nw_practice,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("nowssb://widget/practice?word=" + Uri.encode(word)),
                ),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
`);

  let wm = readFileSync(manifest, 'utf8');
  if (wm.includes('.NowssbHomeWidget')) {
    already.push('home-screen widget receiver');
  } else {
    // Widget taps launch MainActivity with home_widget's LAUNCH action.
    const before = wm;
    wm = wm.replace(
      /(<activity[\s\S]*?android:name="\.MainActivity"[\s\S]*?)(\n\s*<\/activity>)/,
      `$1\n            <intent-filter>\n                <action android:name="es.antonborri.home_widget.action.LAUNCH" />\n            </intent-filter>$2`,
    );
    if (wm === before) throw new Error('AndroidManifest.xml: MainActivity not found for the widget launch filter');
    wm = wm.replace(
      '</application>',
      `    <receiver\n` +
      `        android:name=".NowssbHomeWidget"\n` +
      `        android:exported="true"\n` +
      `        android:label="@string/nowssb_widget_name">\n` +
      `        <intent-filter>\n` +
      `            <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />\n` +
      `        </intent-filter>\n` +
      `        <meta-data\n` +
      `            android:name="android.appwidget.provider"\n` +
      `            android:resource="@xml/nowssb_widget_info" />\n` +
      `    </receiver>\n` +
      `    <!-- Re-arms the after-midnight widget refresh on reboot / update. -->\n` +
      `    <receiver\n` +
      `        android:name="es.antonborri.home_widget.HomeWidgetScheduledUpdateReceiver"\n` +
      `        android:exported="false">\n` +
      `        <intent-filter>\n` +
      `            <action android:name="android.intent.action.BOOT_COMPLETED" />\n` +
      `            <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />\n` +
      `            <action android:name="android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED" />\n` +
      `        </intent-filter>\n` +
      `    </receiver>\n` +
      `</application>`,
    );
    writeFileSync(manifest, wm);
    done.push('home-screen widget (streak + word of the day): receiver, layout, provider info');
  }
}

// ── release signing for the update channel ─────────────────────────────
// Every GitHub runner generates a brand-new ~/.android/debug.keystore, so
// each CI build used to be signed by a different throwaway key and Android
// refused to install any build over another ("App not installed"). When the
// workflow writes android/key.properties (from repository secrets, on the
// runner only — .gitignore refuses key.properties and *.keystore) the
// release build is signed with that one stable key. Without the file the
// release build falls back to the debug key exactly as flutter create wrote.
// When the stable key is present the debug build uses it too, so Google
// sign-in keeps one certificate instead of a new debug keystore every run.
{
  let g = readFileSync(appGradle, 'utf8');
  if (g.includes('nwsbKeyProperties')) {
    already.push('release signing config');
  } else {
    g = 'import java.io.FileInputStream\nimport java.util.Properties\n\n' + g;
    g = g.replace(
      /\nandroid \{\n/,
      `\n// Stable release key, when the CI run provides one (see flutter-apk.yml).\n` +
      `val nwsbKeyProperties = Properties().apply {\n` +
      `    val file = rootProject.file("key.properties")\n` +
      `    if (file.exists()) FileInputStream(file).use { load(it) }\n` +
      `}\n` +
      `val nwsbHasReleaseKey = nwsbKeyProperties.getProperty("storeFile") != null\n\n` +
      `android {\n` +
      `    signingConfigs {\n` +
      `        create("nwsbRelease") {\n` +
      `            if (nwsbHasReleaseKey) {\n` +
      `                storeFile = file(nwsbKeyProperties.getProperty("storeFile"))\n` +
      `                storePassword = nwsbKeyProperties.getProperty("storePassword")\n` +
      `                keyAlias = nwsbKeyProperties.getProperty("keyAlias")\n` +
      `                keyPassword = nwsbKeyProperties.getProperty("keyPassword")\n` +
      `            }\n` +
      `        }\n` +
      `    }\n`,
    );
    const before = g;
    g = g.replace(
      /(release \{[\s\S]*?)signingConfig = signingConfigs\.getByName\("debug"\)/,
      `$1signingConfig = if (nwsbHasReleaseKey) signingConfigs.getByName("nwsbRelease") else signingConfigs.getByName("debug")`,
    );
    if (!g.includes('buildTypes {\n        debug {')) {
      g = g.replace(
        /buildTypes \{\n/,
        'buildTypes {\n        debug {\n            if (nwsbHasReleaseKey) {\n                signingConfig = signingConfigs.getByName("nwsbRelease")\n            }\n        }\n',
      );
    }
    if (g === before || !g.includes('val nwsbKeyProperties')) {
      throw new Error('app/build.gradle.kts: could not wire the release signing config');
    }
    writeFileSync(appGradle, g);
    done.push('release signing from key.properties (debug key fallback)');
  }
}

// ── gradle.properties: release builds that behave like the debug build ──
//   shrink=false                       no R8 on the release build: plugins
//                                      that reflect (notifications, audio,
//                                      recording) behave exactly as in the
//                                      unshrunk debug build. Costs ~2 MB of
//                                      dex on a ~400 MB APK.
//   force-version-code-ignoring-abi    per-ABI APKs keep the pubspec build
//                                      number as versionCode instead of
//                                      1000*abi+build, so the universal APK
//                                      from the website and the per-ABI APK
//                                      from the updater can replace each
//                                      other in either direction.
{
  const gp = join(android, 'gradle.properties');
  let p = existsSync(gp) ? readFileSync(gp, 'utf8') : '';
  const add = [];
  if (!/^shrink=/m.test(p)) add.push('shrink=false');
  if (!/^force-version-code-ignoring-abi=/m.test(p)) add.push('force-version-code-ignoring-abi=true');
  if (add.length) {
    p = p.replace(/\n?$/, '\n') + '# NowssB (tools/flutter-android.mjs)\n' + add.join('\n') + '\n';
    writeFileSync(gp, p);
    done.push(`gradle.properties: ${add.join(', ')}`);
  } else {
    already.push('gradle.properties release flags');
  }
}

// ── the config itself ──────────────────────────────────────────────────
// Not a secret: google-services.json ships inside every copy of the APK and
// identifies the project rather than authorising anything. The keystore and
// the service-account json are the secrets, and .gitignore refuses both.
const dest = join(android, 'app', 'google-services.json');
copyFileSync(configJson, dest);
done.push('copied google-services.json');

console.log('flutter_app/android/ configured for ' + APP_ID);
for (const d of done) console.log(`  + ${d}`);
for (const d of already) console.log(`  · ${d} (already)`);
