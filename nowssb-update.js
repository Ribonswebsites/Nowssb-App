/* NowssB in-app update.
   The phone already has the app. We ask GitHub what the latest build is,
   show a glass "NEW" sheet, and apply it inside this same install.
   Later snoozes. Update now reloads the live site (no APK download). */
(function () {
  var LIVE = 'https://raw.githubusercontent.com/Ribonswebsites/Nowssb-App/main/version.json';
  var PAGES = 'https://ribonswebsites.github.io/Nowssb-App/';
  var LOCAL = 2026082114;
  var SEEN = 'nwsb_seen_build';
  var SNOOZE = 'nwsb_update_snooze';

  function css() {
    if (document.getElementById('nwsbUpCss')) return;
    var s = document.createElement('style');
    s.id = 'nwsbUpCss';
    s.textContent =
      '#nwsbUp{position:fixed;inset:0;z-index:99990;display:flex;align-items:flex-end;justify-content:center;padding:18px 18px calc(18px + env(safe-area-inset-bottom));background:rgba(4,6,12,.55);backdrop-filter:blur(18px);-webkit-backdrop-filter:blur(18px)}' +
      '#nwsbUp[hidden]{display:none}' +
      '.nwsbUp-card{width:min(100%,400px);border-radius:28px;padding:22px 20px 18px;color:#fff;background:linear-gradient(180deg,rgba(18,28,48,.92),rgba(8,12,22,.96));box-shadow:0 0 0 1px rgba(215,242,255,.18),0 30px 80px rgba(0,0,0,.55),inset 0 1px 0 rgba(255,255,255,.16);animation:nwsbUpIn .38s cubic-bezier(.2,.8,.2,1)}' +
      '@keyframes nwsbUpIn{from{transform:translateY(24px);opacity:0}to{transform:none;opacity:1}}' +
      '.nwsbUp-new{display:inline-flex;align-items:center;height:22px;padding:0 10px;border-radius:99px;font-size:10px;font-weight:800;letter-spacing:.22em;background:rgba(215,242,255,.16);color:#d7f2ff;box-shadow:0 0 16px rgba(215,242,255,.35)}' +
      '.nwsbUp-card h2{margin:12px 0 4px;font-size:26px;letter-spacing:-.03em}' +
      '.nwsbUp-ver{margin:0;opacity:.55;font-size:13px}' +
      '.nwsbUp-notes{margin:14px 0 18px;line-height:1.55;font-size:14px;color:rgba(255,255,255,.78)}' +
      '.nwsbUp-row{display:flex;gap:10px}' +
      '.nwsbUp-row button{flex:1;height:48px;border:0;border-radius:999px;font-weight:800;font-size:13px;cursor:pointer;font-family:inherit}' +
      '.nwsbUp-later{background:transparent;color:rgba(255,255,255,.8);box-shadow:inset 0 0 0 1px rgba(255,255,255,.18)}' +
      '.nwsbUp-go{background:#d7f2ff;color:#071018;box-shadow:0 0 24px rgba(215,242,255,.35)}';
    document.head.appendChild(s);
  }

  function parse(v) {
    var p = String(v || '0').split('.').map(function (n) { return parseInt(n, 10) || 0; });
    return (p[0] || 0) * 10000 + (p[1] || 0) * 100 + (p[2] || 0);
  }

  function nativeShell() {
    try {
      if (window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform()) return true;
    } catch (e) {}
    return /capacitor|android.*wv|wv\)/i.test(navigator.userAgent || '');
  }

  function apply(info) {
    try { localStorage.setItem(SEEN, String(info.build || 0)); } catch (e) {}
    hide();
    var remote = Number(info.build) || 0;
    var dest = info.web || PAGES;
    if (nativeShell() && remote > LOCAL && dest) {
      location.href = dest.replace(/\/?$/, '/') + '?v=' + remote;
      return;
    }
    try {
      if (navigator.serviceWorker) {
        navigator.serviceWorker.getRegistrations().then(function (rs) {
          return Promise.all(rs.map(function (r) {
            if (r.waiting) r.waiting.postMessage({ type: 'SKIP_WAITING' });
            return r.update();
          }));
        }).finally(function () { location.reload(); });
        return;
      }
    } catch (e) {}
    location.reload();
  }

  function hide() {
    var el = document.getElementById('nwsbUp');
    if (el) el.hidden = true;
  }

  function show(info, opts) {
    css();
    var el = document.getElementById('nwsbUp');
    if (!el) {
      el = document.createElement('div');
      el.id = 'nwsbUp';
      el.setAttribute('role', 'dialog');
      el.setAttribute('aria-modal', 'true');
      el.innerHTML =
        '<div class="nwsbUp-card">' +
          '<span class="nwsbUp-new">NEW</span>' +
          '<h2></h2>' +
          '<p class="nwsbUp-ver"></p>' +
          '<p class="nwsbUp-notes"></p>' +
          '<div class="nwsbUp-row">' +
            '<button type="button" class="nwsbUp-later">Later</button>' +
            '<button type="button" class="nwsbUp-go">Update now</button>' +
          '</div>' +
        '</div>';
      document.body.appendChild(el);
      el.querySelector('.nwsbUp-later').addEventListener('click', function () {
        try { localStorage.setItem(SNOOZE, String(Date.now() + 12 * 60 * 60 * 1000)); } catch (e) {}
        hide();
      });
      el.querySelector('.nwsbUp-go').addEventListener('click', function () { apply(info); });
    }
    el.querySelector('h2').textContent = info.title || 'Update available';
    el.querySelector('.nwsbUp-ver').textContent = 'NowssB ' + (info.version || '');
    el.querySelector('.nwsbUp-notes').textContent = info.notes || '';
    el.querySelector('.nwsbUp-later').hidden = !!info.force;
    el.querySelector('.nwsbUp-go').onclick = function () { apply(info); };
    el.hidden = false;
    window._nwsbUpdateInfo = info;
  }

  function check(force) {
    var snooze = 0;
    try { snooze = parseInt(localStorage.getItem(SNOOZE) || '0', 10) || 0; } catch (e) {}
    if (!force && snooze > Date.now()) return Promise.resolve(null);
    return fetch(LIVE + '?t=' + Date.now(), { cache: 'no-store' })
      .then(function (r) { return r.json(); })
      .then(function (info) {
        var remote = Number(info.build) || parse(info.version);
        var seen = 0;
        try { seen = parseInt(localStorage.getItem(SEEN) || '0', 10) || 0; } catch (e) {}
        if (force || remote > seen) {
          show(info, { force: force });
          return info;
        }
        return null;
      })
      .catch(function () {
        if (force) {
          show({
            version: '9.6.1',
            build: LOCAL,
            title: 'Update available',
            notes: 'The player is a real watch-bezel now. Wind the knurled ring. This update installs inside the app — no new download.',
            web: PAGES
          });
        }
        return null;
      });
  }

  window.nwsbCheckUpdate = function () { return check(true); };

  function boot() {
    var n = 0;
    function wait() {
      n += 1;
      var home = document.getElementById('screen-home') || document.getElementById('homeScreen') || document.querySelector('[data-screen="home"]');
      var splash = document.getElementById('startAnim') || document.querySelector('.start-anim, #loadingScreen');
      var splashUp = splash && splash.offsetParent !== null && getComputedStyle(splash).display !== 'none';
      if (splashUp && n < 40) {
        setTimeout(wait, 400);
        return;
      }
      setTimeout(function () { check(false); }, 600);
    }
    wait();
  }

  if (document.readyState === 'complete') boot();
  else window.addEventListener('load', boot);
})();
