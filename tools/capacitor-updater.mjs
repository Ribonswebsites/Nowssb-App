import { existsSync, mkdirSync, readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const root = process.cwd();
const android = join(root, 'android');
const app = join(android, 'app');
const main = join(app, 'src', 'main');
const manifestPath = join(main, 'AndroidManifest.xml');
if (!existsSync(manifestPath)) throw new Error(`missing ${manifestPath}; run npx cap add android first`);

function findFile(dir, name) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) { const found = findFile(full, name); if (found) return found; }
    if (entry.isFile() && entry.name === name) return full;
  }
  return null;
}

const activity = findFile(join(app, 'src', 'main'), 'MainActivity.java');
if (!activity) throw new Error('MainActivity.java was not found in the generated Capacitor project');
const packageName = (readFileSync(activity, 'utf8').match(/^package\s+([\w.]+);/m) || [])[1];
if (!packageName) throw new Error('could not read MainActivity.java package');

const pluginDir = join(main, 'java', ...packageName.split('.'));
mkdirSync(pluginDir, { recursive: true });
writeFileSync(join(pluginDir, 'NowssBUpdaterPlugin.java'), `package ${packageName};

import android.content.Intent;
import android.net.Uri;
import android.os.Environment;
import androidx.core.content.FileProvider;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

@CapacitorPlugin(name = "NowssBUpdater")
public class NowssBUpdaterPlugin extends Plugin {
  @PluginMethod
  public void download(PluginCall call) {
    String url = call.getString("url");
    String filename = call.getString("filename", "nowssb-update.apk");
    if (url == null || !url.startsWith("https://github.com/Ribonswebsites/Nowssb-App/releases/download/")) {
      call.reject("Update URL is not an approved NowssB release URL");
      return;
    }
    if (filename == null || !filename.matches("[A-Za-z0-9._-]+")) filename = "nowssb-update.apk";
    final String safeName = filename;
    new Thread(() -> {
      HttpURLConnection connection = null;
      try {
        connection = (HttpURLConnection) new URL(url).openConnection();
        connection.setConnectTimeout(15000);
        connection.setReadTimeout(120000);
        connection.setInstanceFollowRedirects(true);
        connection.setRequestProperty("User-Agent", "NowssB-Android-Updater");
        connection.connect();
        if (connection.getResponseCode() < 200 || connection.getResponseCode() >= 300) {
          throw new IllegalStateException("Update server returned HTTP " + connection.getResponseCode());
        }
        long total = connection.getContentLengthLong();
        File dir = new File(getContext().getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), "updates");
        if (!dir.exists() && !dir.mkdirs()) throw new IllegalStateException("Could not create update directory");
        File apk = new File(dir, safeName);
        long done = 0;
        try (InputStream input = connection.getInputStream(); FileOutputStream output = new FileOutputStream(apk)) {
          byte[] buffer = new byte[1024 * 64];
          int read;
          while ((read = input.read(buffer)) != -1) {
            output.write(buffer, 0, read);
            done += read;
            JSObject progress = new JSObject();
            progress.put("bytes", done);
            progress.put("total", total);
            progress.put("percent", total > 0 ? Math.min(99, (int) ((done * 100L) / total)) : 0);
            notifyListeners("progress", progress);
          }
        }
        Uri uri = FileProvider.getUriForFile(getContext(), getContext().getPackageName() + ".fileprovider", apk);
        Intent installer = new Intent(Intent.ACTION_VIEW);
        installer.setDataAndType(uri, "application/vnd.android.package-archive");
        installer.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
        getActivity().runOnUiThread(() -> getActivity().startActivity(installer));
        JSObject result = new JSObject();
        result.put("status", "installer_opened");
        call.resolve(result);
      } catch (Exception error) {
        call.reject("Could not download the NowssB update", error);
      } finally {
        if (connection != null) connection.disconnect();
      }
    }).start();
  }
}
`);

const activitySource = readFileSync(activity, 'utf8');
const registered = activitySource.includes('registerPlugin(NowssBUpdaterPlugin.class)');
if (!registered) {
  const replacement = activitySource.replace(/public class MainActivity extends BridgeActivity\s*\{\s*\}/s, `public class MainActivity extends BridgeActivity {
  @Override
  public void onCreate(android.os.Bundle savedInstanceState) {
    registerPlugin(NowssBUpdaterPlugin.class);
    super.onCreate(savedInstanceState);
  }
}`);
  if (replacement === activitySource) throw new Error('unexpected MainActivity.java shape; updater was not registered');
  writeFileSync(activity, replacement);
}

let manifest = readFileSync(manifestPath, 'utf8');
if (!manifest.includes('android.permission.REQUEST_INSTALL_PACKAGES')) {
  manifest = manifest.replace(/(<manifest[^>]*>)/, '$1\n    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />');
}
const xmlDir = join(main, 'res', 'xml');
mkdirSync(xmlDir, { recursive: true });
const defaultPaths = join(xmlDir, 'file_paths.xml');
const updatePaths = join(xmlDir, 'nowssb_file_paths.xml');
if (!manifest.includes('android:name="androidx.core.content.FileProvider"')) {
  const provider = `
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${packageName}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>`;
  manifest = manifest.replace('</application>', provider + '\n    </application>');
}
writeFileSync(manifestPath, manifest);
const pathsFile = existsSync(defaultPaths) ? defaultPaths : updatePaths;
let paths = existsSync(pathsFile) ? readFileSync(pathsFile, 'utf8') : '<?xml version="1.0" encoding="utf-8"?>\n<paths xmlns:android="http://schemas.android.com/apk/res/android">\n</paths>\n';
if (!paths.includes('nowssb_updates')) paths = paths.replace('</paths>', '    <external-files-path name="nowssb_updates" path="Download/updates/" />\n</paths>');
writeFileSync(pathsFile, paths);
console.log(`Capacitor updater configured for ${packageName}`);
