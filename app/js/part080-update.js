/*
 * NowssB in-app update checker.
 * Browser: refreshes the web bundle. Capacitor Android: downloads the signed
 * release APK through the native bridge and opens Android's installer on top
 * of the app; the page itself never navigates away.
 */
(function () {
  'use strict';

  var CLIENT_VERSION = '9.6.20';
  var STORAGE_KEY = 'nwsb_last_seen_version';
  var CHECK_INTERVAL_MS = 6 * 60 * 60 * 1000;
  var CHECKED_KEY = 'nwsb_last_update_check';

  function parseVer(v) { return String(v || '0').split('.').map(function (n) { return parseInt(n, 10) || 0; }); }
  function isNewer(remote, local) {
    var a = parseVer(remote), b = parseVer(local);
    for (var i = 0; i < Math.max(a.length, b.length); i++) { var x = a[i] || 0, y = b[i] || 0; if (x > y) return true; if (x < y) return false; }
    return false;
  }
  function esc(value) { return String(value == null ? '' : value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;'); }
  function ls(key, fallback) { try { var value = localStorage.getItem(key); return value == null ? fallback : value; } catch (e) { return fallback; } }
  function setLs(key, value) { try { localStorage.setItem(key, String(value)); } catch (e) {} }
  function nativeUpdater() {
    var c = window.Capacitor;
    return c && c.Plugins && c.Plugins.NowssBUpdater && typeof c.Plugins.NowssBUpdater.download === 'function' ? c.Plugins.NowssBUpdater : null;
  }
  function browserRefresh() {
    try {
      var tasks = [];
      if (navigator.serviceWorker && navigator.serviceWorker.getRegistrations) tasks.push(navigator.serviceWorker.getRegistrations().then(function (regs) { regs.forEach(function (r) { r.update(); }); }));
      if (window.caches && caches.keys) tasks.push(caches.keys().then(function (keys) { return Promise.all(keys.filter(function (k) { return k.indexOf('nowsbansiu-') === 0; }).map(function (k) { return caches.delete(k); })); }));
      Promise.all(tasks).finally(function () { location.reload(); });
    } catch (e) { location.reload(); }
  }
  function showModal(info) {
    if (document.getElementById('nwsbUpdateModal')) return;
    var force = !!info.force;
    var native = nativeUpdater();
    var apkUrl = info.webviewApk || info.apk || '';
    var notes = esc(info.notes || 'A new version of NowssB is ready.');
    var title = esc(info.title || 'Update available');
    var wrap = document.createElement('div');
    wrap.id = 'nwsbUpdateModal';
    wrap.innerHTML = '<div class="nwsb-upd-back"></div><div class="nwsb-upd-card">' +
      '<div class="nwsb-upd-badge">NEW</div><div class="nwsb-upd-title">' + title + '</div><div class="nwsb-upd-ver">NowssB v' + esc(info.version || '') + '</div>' +
      '<div class="nwsb-upd-notes">' + notes + '</div><div class="nwsb-upd-status" id="nwsbUpdStatus">Ready to update inside the app.</div>' +
      '<div class="nwsb-upd-actions">' + (force ? '' : '<button type="button" class="nwsb-upd-later" id="nwsbUpdLater">Later</button>') + '<button type="button" class="nwsb-upd-go" id="nwsbUpdGo">' + (native ? 'Download update' : 'Refresh now') + '</button></div></div>';
    document.body.appendChild(wrap);
    requestAnimationFrame(function () { wrap.classList.add('open'); });
    var go = document.getElementById('nwsbUpdGo');
    var later = document.getElementById('nwsbUpdLater');
    var status = document.getElementById('nwsbUpdStatus');
    if (go) go.addEventListener('click', function () {
      if (!native || !apkUrl) { setLs(STORAGE_KEY, info.version || ''); browserRefresh(); return; }
      go.disabled = true; go.textContent = 'Downloading…'; if (status) status.textContent = 'Downloading the update securely…';
      var progressListener = null;
      try {
        if (native.addListener) progressListener = native.addListener('progress', function (event) { if (status && event && event.percent != null) status.textContent = 'Downloading update… ' + event.percent + '%'; });
      } catch (e) {}
      Promise.resolve(native.download({ url: apkUrl, filename: 'nowssb-update.apk' })).then(function () {
        setLs(STORAGE_KEY, info.version || ''); if (status) status.textContent = 'Opening Android installer…';
      }).catch(function (error) {
        if (progressListener && progressListener.remove) progressListener.remove();
        go.disabled = false; go.textContent = 'Try again'; if (status) status.textContent = 'The update could not be downloaded. Check your connection and try again.'; console.warn('[NowssB] update failed', error);
      });
    });
    if (later) later.addEventListener('click', function () { setLs(STORAGE_KEY, info.version || ''); setLs(CHECKED_KEY, Date.now()); wrap.classList.remove('open'); setTimeout(function () { wrap.remove(); }, 320); });
  }
  function shouldCheck() { return Date.now() - parseInt(ls(CHECKED_KEY, '0'), 10) > CHECK_INTERVAL_MS; }
  function runCheck(forceShow) {
    if (!forceShow && !shouldCheck()) return;
    fetch('/version.json?t=' + Date.now(), { cache: 'no-store', credentials: 'omit' }).then(function (r) { return r.ok ? r.json() : null; }).then(function (info) {
      setLs(CHECKED_KEY, Date.now());
      if (!info || !info.version || !isNewer(info.version, CLIENT_VERSION)) return;
      if (!info.webviewApk && !info.apk && !nativeUpdater()) return;
      if (forceShow || info.version !== ls(STORAGE_KEY, '')) setTimeout(function () { showModal(info); }, 1200);
    }).catch(function () {});
  }
  if (document.readyState === 'complete') setTimeout(function () { runCheck(false); }, 2500); else window.addEventListener('load', function () { setTimeout(function () { runCheck(false); }, 2500); });
  window.nwsbCheckForUpdate = function (forceShow) { runCheck(!!forceShow); };
})();
