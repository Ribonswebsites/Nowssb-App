/* ═════════════════════════════════════════════════════════════
   NowssB — In-app update check (WebView + pure web)
   Fetches /version.json, compares with the baked-in client version,
   and shows a liquid-glass modal when a newer build is live.
═════════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  // Baked client version — bump this in the same commit as version.json
  var CLIENT_VERSION = '9.5.0';
  var STORAGE_KEY = 'nwsb_last_seen_version';
  var CHECK_INTERVAL_MS = 6 * 60 * 60 * 1000; // 6 hours
  var CHECKED_KEY = 'nwsb_last_update_check';

  function parseVer(v) {
    return String(v || '0').split('.').map(function (n) { return parseInt(n, 10) || 0; });
  }

  function isNewer(remote, local) {
    var a = parseVer(remote);
    var b = parseVer(local);
    for (var i = 0; i < Math.max(a.length, b.length); i++) {
      var x = a[i] || 0, y = b[i] || 0;
      if (x > y) return true;
      if (x < y) return false;
    }
    return false;
  }

  function shouldCheck() {
    try {
      var last = parseInt(localStorage.getItem(CHECKED_KEY) || '0', 10);
      return Date.now() - last > CHECK_INTERVAL_MS;
    } catch (e) { return true; }
  }

  function markChecked() {
    try { localStorage.setItem(CHECKED_KEY, String(Date.now())); } catch (e) {}
  }

  function showModal(info) {
    if (document.getElementById('nwsbUpdateModal')) return;

    var force = !!info.force;
    var notes = info.notes || 'A new version of NowssB is ready.';
    var title = info.title || 'Update available';

    var wrap = document.createElement('div');
    wrap.id = 'nwsbUpdateModal';
    wrap.innerHTML =
      '<div class="nwsb-upd-back"></div>' +
      '<div class="nwsb-upd-card">' +
        '<div class="nwsb-upd-badge">NEW</div>' +
        '<div class="nwsb-upd-title">' + title + '</div>' +
        '<div class="nwsb-upd-ver">v' + (info.version || '') + '</div>' +
        '<div class="nwsb-upd-notes">' + notes + '</div>' +
        '<div class="nwsb-upd-actions">' +
          (force ? '' : '<button type="button" class="nwsb-upd-later" id="nwsbUpdLater">Later</button>') +
          '<button type="button" class="nwsb-upd-go" id="nwsbUpdGo">Update now</button>' +
        '</div>' +
      '</div>';

    document.body.appendChild(wrap);
    requestAnimationFrame(function () { wrap.classList.add('open'); });

    var go = document.getElementById('nwsbUpdGo');
    var later = document.getElementById('nwsbUpdLater');

    if (go) {
      go.addEventListener('click', function () {
        try {
          if (navigator.serviceWorker && navigator.serviceWorker.getRegistrations) {
            navigator.serviceWorker.getRegistrations().then(function (regs) {
              regs.forEach(function (r) { r.update(); });
            });
          }
          if (window.caches && caches.keys) {
            caches.keys().then(function (keys) {
              return Promise.all(keys.filter(function (k) {
                return k.indexOf('nowsbansiu-') === 0;
              }).map(function (k) { return caches.delete(k); }));
            }).finally(function () {
              location.reload(true);
            });
          } else {
            location.reload(true);
          }
        } catch (e) {
          location.reload(true);
        }
      });
    }

    if (later) {
      later.addEventListener('click', function () {
        try { localStorage.setItem(STORAGE_KEY, info.version || ''); } catch (e) {}
        wrap.classList.remove('open');
        setTimeout(function () { wrap.remove(); }, 320);
      });
    }
  }

  function runCheck() {
    if (!shouldCheck()) return;

    var url = '/version.json?t=' + Date.now();
    fetch(url, { cache: 'no-store', credentials: 'omit' })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (info) {
        markChecked();
        if (!info || !info.version) return;

        var lastSeen = '';
        try { lastSeen = localStorage.getItem(STORAGE_KEY) || ''; } catch (e) {}

        if (isNewer(info.version, CLIENT_VERSION) && info.version !== lastSeen) {
          setTimeout(function () { showModal(info); }, 1800);
        }
      })
      .catch(function () {});
  }

  if (document.readyState === 'complete') {
    setTimeout(runCheck, 2500);
  } else {
    window.addEventListener('load', function () {
      setTimeout(runCheck, 2500);
    });
  }

  window.nwsbCheckForUpdate = function (forceShow) {
    fetch('/version.json?t=' + Date.now(), { cache: 'no-store' })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (info) {
        if (!info) return;
        if (forceShow || isNewer(info.version, CLIENT_VERSION)) {
          showModal(info);
        } else {
          console.log('[NowssB] Already on latest (' + CLIENT_VERSION + ')');
        }
      })
      .catch(function () {});
  };
})();
