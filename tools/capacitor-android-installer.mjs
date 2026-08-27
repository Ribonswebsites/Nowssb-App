import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';

const root = process.cwd();
const androidRoot = join(root, 'android');
const javaDir = join(androidRoot, 'app/src/main/java/com/nowssb/app');
const pluginPath = join(javaDir, 'NativeInstallerPlugin.java');
const activityPath = join(javaDir, 'MainActivity.java');
const manifestPath = join(androidRoot, 'app/src/main/AndroidManifest.xml');

if (!existsSync(androidRoot)) throw new Error('android/ does not exist; run npx cap add android first');
mkdirSync(javaDir, { recursive: true });

writeFileSync(pluginPath, `package com.nowssb.app;

import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "NativeInstaller")
public class NativeInstallerPlugin extends Plugin {
  private static final String PREFS = "nowssb_native_installer";
  private static final String PENDING_ID = "pending_download_id";
  private BroadcastReceiver receiver;

  @Override
  public void load() {
    receiver = new BroadcastReceiver() {
      @Override
      public void onReceive(Context context, Intent intent) {
        if (!DownloadManager.ACTION_DOWNLOAD_COMPLETE.equals(intent.getAction())) return;
        long id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L);
        if (id < 0L) return;
        SharedPreferences prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        if (prefs.getLong(PENDING_ID, -1L) != id) return;
        DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
        if (manager == null) return;
        DownloadManager.Query query = new DownloadManager.Query().setFilterById(id);
        android.database.Cursor cursor = manager.query(query);
        boolean successful = false;
        try {
          if (cursor != null && cursor.moveToFirst()) {
            int status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS));
            successful = status == DownloadManager.STATUS_SUCCESSFUL;
          }
        } finally {
          if (cursor != null) cursor.close();
        }
        prefs.edit().remove(PENDING_ID).apply();
        if (!successful) return;
        Uri apkUri = manager.getUriForDownloadedFile(id);
        if (apkUri == null) return;
        Intent install = new Intent(Intent.ACTION_VIEW);
        install.setDataAndType(apkUri, "application/vnd.android.package-archive");
        install.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_GRANT_READ_URI_PERMISSION);
        try { context.startActivity(install); } catch (Exception ignored) {}
      }
    };
    IntentFilter filter = new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE);
    if (Build.VERSION.SDK_INT >= 33) {
      getContext().registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED);
    } else {
      getContext().registerReceiver(receiver, filter);
    }
  }

  @Override
  protected void handleOnDestroy() {
    if (receiver != null) {
      try { getContext().unregisterReceiver(receiver); } catch (Exception ignored) {}
      receiver = null;
    }
    super.handleOnDestroy();
  }

  @PluginMethod
  public void downloadAndInstall(PluginCall call) {
    String url = call.getString("url");
    String filename = call.getString("filename", "NowssB-Flutter-Android.apk");
    if (url == null || url.trim().isEmpty()) {
      call.reject("APK URL is missing");
      return;
    }
    DownloadManager manager = (DownloadManager) getContext().getSystemService(Context.DOWNLOAD_SERVICE);
    if (manager == null) {
      call.reject("Android DownloadManager is unavailable");
      return;
    }
    DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
    request.setTitle("NowssB update");
    request.setDescription("Downloading NowssB for installation");
    request.setMimeType("application/vnd.android.package-archive");
    request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
    request.setAllowedOverMetered(true);
    request.setAllowedOverRoaming(true);
    request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, filename);
    long downloadId = manager.enqueue(request);
    getContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE)
      .edit().putLong(PENDING_ID, downloadId).apply();

    JSObject result = new JSObject();
    result.put("downloadId", downloadId);
    result.put("filename", filename);
    result.put("installerPermissionRequired", Build.VERSION.SDK_INT >= 26 &&
      !getContext().getPackageManager().canRequestPackageInstalls());
    call.resolve(result);
  }
}
`);

let activity = readFileSync(activityPath, 'utf8');
if (!activity.includes('NativeInstallerPlugin')) {
  activity = activity.replace(
    /import com\.getcapacitor\.BridgeActivity;/,
    'import com.getcapacitor.BridgeActivity;\n\nimport android.os.Bundle;'
  );
  activity = activity.replace(
    /public class MainActivity extends BridgeActivity \{\s*\}/,
    'public class MainActivity extends BridgeActivity {\n  @Override\n  public void onCreate(Bundle savedInstanceState) {\n    registerPlugin(NativeInstallerPlugin.class);\n    super.onCreate(savedInstanceState);\n  }\n}'
  );
  writeFileSync(activityPath, activity);
}

let manifest = readFileSync(manifestPath, 'utf8');
if (!manifest.includes('android.permission.REQUEST_INSTALL_PACKAGES')) {
  manifest = manifest.replace(
    /<manifest([^>]*)>/,
    '<manifest$1>\n    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />'
  );
  writeFileSync(manifestPath, manifest);
}

console.log('NativeInstaller plugin installed: DownloadManager → Android package installer');
console.log(`  ${pluginPath}`);
console.log(`  ${activityPath}`);
console.log(`  ${manifestPath}`);
