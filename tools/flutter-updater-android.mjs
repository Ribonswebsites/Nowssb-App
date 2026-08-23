import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const root = process.cwd();
const android = join(root, 'flutter_app', 'android');
const main = join(android, 'app', 'src', 'main');
const manifestPath = join(main, 'AndroidManifest.xml');
if (!existsSync(manifestPath)) throw new Error(`missing ${manifestPath}; run flutter create first`);

function findFile(dir, name) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) { const found = findFile(full, name); if (found) return found; }
    if (entry.isFile() && entry.name === name) return full;
  }
  return null;
}
const activity = findFile(main, 'MainActivity.kt');
if (!activity) throw new Error('MainActivity.kt was not found in the generated Flutter project');
const kotlin = readFileSync(activity, 'utf8');
const packageName = (kotlin.match(/^package\s+([\w.]+)/m) || [])[1];
if (!packageName) throw new Error('could not read MainActivity.kt package');
const gradle = readFileSync(join(android, 'app', 'build.gradle.kts'), 'utf8');
const appId = (gradle.match(/applicationId\s*=\s*"([^"]+)"/) || [])[1];
if (!appId) throw new Error('could not read Flutter applicationId');

const pluginDir = join(main, 'kotlin', ...packageName.split('.'));
mkdirSync(pluginDir, { recursive: true });
writeFileSync(join(pluginDir, 'NowssBUpdater.kt'), `package ${packageName}

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Environment
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

class NowssBUpdater(private val activity: Activity) : MethodChannel.MethodCallHandler {
  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    if (call.method != "downloadAndInstall") { result.notImplemented(); return }
    val url = call.argument<String>("url")
    val filename = (call.argument<String>("filename") ?: "nowssb-update.apk").replace(Regex("[^A-Za-z0-9._-]"), "_")
    if (url == null || !url.startsWith("https://github.com/Ribonswebsites/Nowssb-App/releases/download/")) {
      result.error("BAD_URL", "Update URL is not an approved NowssB release URL", null); return
    }
    Thread {
      var connection: HttpURLConnection? = null
      try {
        connection = URL(url).openConnection() as HttpURLConnection
        connection.connectTimeout = 15000
        connection.readTimeout = 120000
        connection.instanceFollowRedirects = true
        connection.setRequestProperty("User-Agent", "NowssB-Android-Updater")
        connection.connect()
        if (connection.responseCode !in 200..299) error("Update server returned HTTP \${connection.responseCode}")
        val total = connection.contentLengthLong
        val dir = File(activity.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), "updates")
        if (!dir.exists() && !dir.mkdirs()) error("Could not create update directory")
        val apk = File(dir, filename)
        var done = 0L
        connection.inputStream.use { input -> FileOutputStream(apk).use { output ->
          val buffer = ByteArray(64 * 1024)
          while (true) {
            val count = input.read(buffer)
            if (count < 0) break
            output.write(buffer, 0, count)
            done += count
            val percent = if (total > 0) minOf(99, (done * 100 / total).toInt()) else 0
            activity.runOnUiThread { updaterChannel?.invokeMethod("progress", mapOf("bytes" to done, "total" to total, "percent" to percent)) }
          }
        }}
        val uri = FileProvider.getUriForFile(activity, "${appId}.fileprovider", apk)
        activity.runOnUiThread {
          val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
          }
          activity.startActivity(intent)
          result.success(mapOf("status" to "installer_opened"))
        }
      } catch (error: Exception) {
        activity.runOnUiThread { result.error("UPDATE_FAILED", "Could not download the NowssB update", error.message) }
      } finally { connection?.disconnect() }
    }.start()
  }

  companion object { var updaterChannel: MethodChannel? = null }
}
`);

const replacement = `package ${packageName}

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    NowssBUpdater.updaterChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nowssb/updater")
    NowssBUpdater.updaterChannel?.setMethodCallHandler(NowssBUpdater(this))
  }
}
`;
writeFileSync(activity, replacement);

let manifest = readFileSync(manifestPath, 'utf8');
if (!manifest.includes('android.permission.REQUEST_INSTALL_PACKAGES')) manifest = manifest.replace(/(<manifest[^>]*>)/, '$1\n    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />');
if (!manifest.includes(`android:authorities="${appId}.fileprovider"`)) {
  manifest = manifest.replace('</application>', `
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${appId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data android:name="android.support.FILE_PROVIDER_PATHS" android:resource="@xml/nowssb_file_paths" />
        </provider>
    </application>`);
}
writeFileSync(manifestPath, manifest);
const xmlDir = join(main, 'res', 'xml');
mkdirSync(xmlDir, { recursive: true });
writeFileSync(join(xmlDir, 'nowssb_file_paths.xml'), `<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-files-path name="nowssb_updates" path="Download/updates/" />
</paths>
`);
console.log(`Flutter updater configured for ${appId}`);
