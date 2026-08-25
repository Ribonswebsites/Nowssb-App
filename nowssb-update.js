/*
   NowssB in-app update checker.
   Native WebView: download the release APK through NowssBUpdater and open the
   Android installer without navigating away. Browser: refresh the web bundle.
*/
(function () {
  'use strict';
  var LIVE = 'https://raw.githubusercontent.com/Ribonswebsites/Nowssb-App/main/version.json';
  var PAGES = 'https://ribonswebsites.github.io/Nowssb-App/';
  var LOCAL_VERSION = '9.6.37';
  var LOCAL_BUILD = 2026082429;
  var SEEN = 'nwsb_seen_build';
  var SNOOZE = 'nwsb_update_snooze';

  function nativeUpdater() {
    var c = window.Capacitor;
    return c && c.Plugins && c.Plugins.NowssBUpdater && typeof c.Plugins.NowssBUpdater.download === 'function' ? c.Plugins.NowssBUpdater : null;
  }
  function parse(v) { var p = String(v || '0').split('.').map(function (n) { return parseInt(n, 10) || 0; }); return (p[0] || 0) * 10000 + (p[1] || 0) * 100 + (p[2] || 0); }
  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function setLs(k, v) { try { localStorage.setItem(k, String(v)); } catch (e) {} }
  function nativeShell() { try { return !!(window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform()); } catch (e) { return /capacitor|android.*wv|wv\)/i.test(navigator.userAgent || ''); } }

  function css() {
    if (document.getElementById('nwsbUpCss')) return;
    var s = document.createElement('style'); s.id = 'nwsbUpCss';
    s.textContent = '#nwsbUp{position:fixed;inset:0;z-index:99990;display:flex;align-items:flex-end;justify-content:center;padding:18px 18px calc(18px + env(safe-area-inset-bottom));background:rgba(4,6,12,.55);backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px)}#nwsbUp[hidden]{display:none}.nwsbUp-card{width:min(100%,400px);border-radius:28px;padding:22px 20px 18px;color:#fff;background:linear-gradient(180deg,rgba(18,28,48,.96),rgba(8,12,22,.98));box-shadow:0 0 0 1px rgba(215,242,255,.18),0 30px 80px rgba(0,0,0,.55),inset 0 1px 0 rgba(255,255,255,.16);animation:nwsbUpIn .38s cubic-bezier(.2,.8,.2,1)}@keyframes nwsbUpIn{from{transform:translateY(24px);opacity:0}to{transform:none;opacity:1}}.nwsbUp-new{display:inline-flex;align-items:center;height:22px;padding:0 10px;border-radius:99px;font-size:10px;font-weight:800;letter-spacing:.22em;background:rgba(215,242,255,.16);color:#d7f2ff}.nwsbUp-card h2{margin:12px 0 4px;font-size:26px;letter-spacing:-.03em}.nwsbUp-ver{margin:0;opacity:.55;font-size:13px}.nwsbUp-notes{margin:14px 0 10px;line-height:1.55;font-size:14px;color:rgba(255,255,255,.78)}.nwsbUp-status{min-height:18px;margin:0 0 16px;font-size:12px;color:rgba(255,255,255,.62)}.nwsbUp-row{display:flex;gap:10px}.nwsbUp-row button{flex:1;height:48px;border:0;border-radius:999px;font-weight:800;font-size:13px;cursor:pointer;font-family:inherit}.nwsbUp-row button:disabled{opacity:.55}.nwsbUp-later{background:transparent;color:rgba(255,255,255,.8);box-shadow:inset 0 0 0 1px rgba(255,255,255,.18)}.nwsbUp-go{background:#d7f2ff;color:#071018;box-shadow:0 0 24px rgba(215,242,255,.35)}';
    document.head.appendChild(s);
  }
  function browserRefresh() {
    try {
      var jobs = [];
      if (navigator.serviceWorker && navigator.serviceWorker.getRegistrations) jobs.push(navigator.serviceWorker.getRegistrations().then(function (rs) { rs.forEach(function (r) { r.update(); }); }));
      if (window.caches && caches.keys) jobs.push(caches.keys().then(function (keys) { return Promise.all(keys.filter(function (k) { return k.indexOf('nowsbansiu-') === 0; }).map(function (k) { return caches.delete(k); })); }));
      Promise.all(jobs).finally(function () { location.reload(); });
    } catch (e) { location.reload(); }
  }
  function hide() { var el = document.getElementById('nwsbUp'); if (el) el.hidden = true; }
  function show(info) {
    if (document.getElementById('nwsbUp')) return;
    css();
    var updater = nativeUpdater();
    var apk = info.webviewApk || info.apk || '';
    var el = document.createElement('div'); el.id = 'nwsbUp'; el.setAttribute('role', 'dialog'); el.setAttribute('aria-modal', 'true');
    el.innerHTML = '<div class="nwsbUp-card"><span class="nwsbUp-new">NEW</span><h2></h2><p class="nwsbUp-ver"></p><p class="nwsbUp-notes"></p><p class="nwsbUp-status">Ready to update inside the app.</p><div class="nwsbUp-row">' + (info.force ? '' : '<button type="button" class="nwsbUp-later">Later</button>') + '<button type="button" class="nwsbUp-go">' + (updater && apk ? 'Download update' : 'Refresh now') + '</button></div></div>';
    document.body.appendChild(el);
    var status = el.querySelector('.nwsbUp-status'); var go = el.querySelector('.nwsbUp-go'); var later = el.querySelector('.nwsbUp-later');
    el.querySelector('h2').textContent = info.title || 'Update available'; el.querySelector('.nwsbUp-ver').textContent = 'NowssB ' + (info.version || ''); el.querySelector('.nwsbUp-notes').textContent = info.notes || '';
    if (later) later.addEventListener('click', function () { setLs(SNOOZE, Date.now() + 12 * 60 * 60 * 1000); hide(); });
    go.addEventListener('click', function () {
      if (!updater || !apk) { setLs(SEEN, info.build || parse(info.version)); browserRefresh(); return; }
      go.disabled = true; go.textContent = 'Downloading…';
      var listener;
      try { if (updater.addListener) listener = updater.addListener('progress', function (event) { if (event && event.percent != null) status.textContent = 'Downloading update… ' + event.percent + '%'; }); } catch (e) {}
      Promise.resolve(updater.download({ url: apk, filename: 'nowssb-webview-update.apk' })).then(function () { setLs(SEEN, info.build || parse(info.version)); status.textContent = 'Opening Android installer…'; if (listener && listener.remove) listener.remove(); }).catch(function () { if (listener && listener.remove) listener.remove(); go.disabled = false; go.textContent = 'Try again'; status.textContent = 'The update could not be downloaded. Check your connection and try again.'; });
    });
  }
  function check(force) {
    var snooze = parseInt(ls(SNOOZE, '0'), 10) || 0;
    if (!force && snooze > Date.now()) return Promise.resolve(null);
    return fetch(LIVE + '?t=' + Date.now(), { cache: 'no-store', credentials: 'omit' }).then(function (r) { return r.ok ? r.json() : null; }).then(function (info) {
      if (!info) return null;
      var remote = Number(info.build) || parse(info.version); var seen = parseInt(ls(SEEN, String(LOCAL_BUILD)), 10) || LOCAL_BUILD;
      if (force || (remote > seen && parse(info.version) > parse(LOCAL_VERSION))) { show(info); return info; }
      return null;
    }).catch(function () { return null; });
  }
  window.nwsbCheckUpdate = function () { return check(true); };
  function boot() { setTimeout(function () { check(false); }, 1000); }
  if (document.readyState === 'complete') boot(); else window.addEventListener('load', boot);
})();
