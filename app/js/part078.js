/* ══════════════════════════════════════════════════════════
   CERTIFICATE DESIGNS — the four printed ones, filled in.

   The app already had one certificate: a card built out of CSS in
   #cert-overlay, drawn by app/js/part036.js when a word is mastered. This
   adds four printed designs beside it and lets you pick.

     Ivory · Words      Ivory · Meanings      — the store's two
     Onyx · Words       Onyx · Meanings       — the requested ones

   Everybody gets all four. The pairing is only what a certificate OPENS
   on: a word or meaning bought from the store opens on its ivory one, a
   word you requested and were sent opens on its onyx one, and the rail
   under the card changes it to any of the five at any time.

   How the filling works
   ---------------------
   The artwork carries printed blanks — a long rule for the name, then
   "Word Studied", "Meaning Explored", "Date" and "Certificate ID:
   NWB-WM-". Nothing is drawn onto the image; the text sits in absolutely
   positioned boxes over it, one per blank, at coordinates measured off the
   files themselves rather than eyeballed:

       every number in DESIGNS below is a fraction of the image, taken by
       scanning each file for its horizontal rules and reading back where
       they actually are. The four designs do NOT share a layout — the
       onyx pair sit lower than the ivory pair — which is exactly why they
       are measured per design instead of shared.

   Sizes are in `em` against a font-size set from the card's own width, so
   the whole thing scales with the card and never needs a second set of
   numbers for a bigger screen.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var KEY = 'nwsb_cert_design';

  /* y is the rule's line; the text sits just above it. x0/x1 are the
     rule's ends, so a long name is centred in the space the blank
     actually has rather than in the page. */
  var DESIGNS = [
    { k: 'classic', name: 'Classic', sub: 'The app card', built: 1 },

    { k: 'ivory-words', name: 'Ivory · Words', sub: 'Store words', kind: 'word', tone: 'light',
      img: './assets/certificates/cert-ivory-words.webp',
      f: { name: [0.4746, 0.1992, 0.8018], word: [0.6068, 0.4395, 0.7998],
           mean: [0.6439, 0.4189, 0.8008], date: [0.7956, 0.4014, 0.6621],
           id:   [0.8301, 0.5332, 0.6943] } },

    { k: 'ivory-meanings', name: 'Ivory · Meanings', sub: 'Store meanings', kind: 'meaning', tone: 'light',
      img: './assets/certificates/cert-ivory-meanings.webp',
      f: { name: [0.4769, 0.2014, 0.7996], word: [0.6103, 0.3734, 0.7967],
           mean: [0.6474, 0.4184, 0.7967], date: [0.7983, 0.4027, 0.6618],
           id:   [0.8334, 0.5327, 0.6931] } },

    { k: 'onyx-words', name: 'Onyx · Words', sub: 'Requested words', kind: 'word', tone: 'dark',
      img: './assets/certificates/cert-onyx-words.webp',
      f: { name: [0.4967, 0.2002, 0.7998], word: [0.6712, 0.3789, 0.7998],
           mean: [0.7096, 0.4238, 0.8008], date: [0.8594, 0.3848, 0.6660],
           id:   [0.8893, 0.5352, 0.7129] } },

    { k: 'onyx-meanings', name: 'Onyx · Meanings', sub: 'Requested meanings', kind: 'meaning', tone: 'dark',
      img: './assets/certificates/cert-onyx-meanings.webp',
      f: { name: [0.5130, 0.1963, 0.8037], word: [0.6790, 0.3555, 0.8027],
           mean: [0.7122, 0.4023, 0.8047], date: [0.8529, 0.3887, 0.6621],
           id:   [0.8783, 0.5469, 0.7314] } }
  ];
  window.NWSB_CERT_DESIGNS = DESIGNS;

  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  function byKey(k) {
    var d = null;
    DESIGNS.forEach(function (x) { if (x.k === k) d = x; });
    return d;
  }
  function chosen() { return byKey(ls(KEY, '')) || DESIGNS[0]; }

  /* The name on every certificate is the profile's, not a typed-in one —
     it is the same person the app already knows. */
  function userName() {
    return (typeof window.nwsbUserName === 'function')
      ? window.nwsbUserName('Practitioner') : 'Practitioner';
  }

  /* Stable per word so the same certificate keeps the same number, and
     short enough to read off a printed line. */
  function certId(design, word) {
    var seed = String(word || '') + '|' + userName();
    var h = 0;
    for (var i = 0; i < seed.length; i++) { h = (h * 31 + seed.charCodeAt(i)) >>> 0; }
    var pre = (design && design.kind === 'meaning') ? 'MN' : 'WM';
    return pre + '-' + ('00000' + (h % 100000)).slice(-5);
  }

  var state = { word: '', meaning: '', date: '' };

  function fill(design) {
    fillOne(document.getElementById('certDesignCard'), design);
    fillOne(document.getElementById('certPanelCard'), design);
  }
  function fillOne(host, design) {
    if (!host) return;
    if (!design || design.built) { host.style.display = 'none'; return; }
    host.style.display = 'block';
    host.className = 'certd certd-' + design.tone;

    var f = design.f;
    function box(cls, spec, text, big) {
      var top = (spec[0] * 100), l = (spec[1] * 100), r = (100 - spec[2] * 100);
      return '<div class="certd-f ' + cls + '" style="top:' + top.toFixed(2) + '%;left:' +
             l.toFixed(2) + '%;right:' + r.toFixed(2) + '%;' +
             (big ? 'font-size:1.5em;' : '') + '">' + text + '</div>';
    }
    var d = state.date || new Date().toLocaleDateString('en', { day: 'numeric', month: 'long', year: 'numeric' });
    host.innerHTML =
      '<img class="certd-art" src="' + design.img + '" alt="" decoding="async">' +
      box('certd-name', f.name, esc(userName()), 1) +
      box('certd-word', f.word, esc(state.word || '—')) +
      box('certd-mean', f.mean, esc(state.meaning || '—')) +
      box('certd-date', f.date, esc(d)) +
      box('certd-id',   f.id,   esc(certId(design, state.word)));
  }

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
    });
  }

  /* The card and the built-in one are two views of the same certificate,
     so exactly one of them is ever on screen. */
  function paint() {
    var d = chosen();
    var classic = document.getElementById('certCard');
    if (classic) classic.style.display = d.built ? '' : 'none';
    fill(d);
    document.querySelectorAll('.certd-chip').forEach(function (c) {
      c.classList.toggle('on', c.getAttribute('data-k') === d.k);
    });
  }
  window.nwsbCertPaint = paint;

  window.nwsbCertPick = function (k) {
    if (!byKey(k)) return;
    lsSet(KEY, k);
    paint();
    try { if (navigator.vibrate) navigator.vibrate(18); } catch (e) {}
  };

  /* Called by part036.js when it opens the overlay, and by anything that
     awards a certificate for a bought or requested word. `source` is
     'store' or 'request'; `kind` is 'word' or 'meaning'. */
  window.nwsbCertShow = function (o) {
    o = o || {};
    state.word = o.word || '';
    state.meaning = o.meaning || '';
    state.date = o.date || '';
    /* Open on the design that belongs to where the word came from, unless
       one has been picked by hand — a choice, once made, is kept. */
    if (!ls(KEY, '')) {
      var tone = o.source === 'request' ? 'onyx' : 'ivory';
      var kind = o.kind === 'meaning' ? 'meanings' : 'words';
      var d = byKey(tone + '-' + kind);
      if (d) lsSet(KEY, d.k);
    }
    buildRail();
    paint();
  };

  function buildRail() {
    var host = document.getElementById('certDesignRail');
    if (!host || host.children.length) return;
    host.innerHTML = DESIGNS.map(function (d) {
      return '<div class="certd-chip" data-k="' + d.k + '" onclick="nwsbCertPick(\'' + d.k + '\')">' +
               (d.img ? '<img class="certd-chip-art" src="' + d.img + '" alt="" loading="lazy" decoding="async">'
                      : '<span class="certd-chip-built"></span>') +
               '<span class="certd-chip-name">' + d.name + '</span>' +
               '<span class="certd-chip-sub">' + d.sub + '</span>' +
             '</div>';
    }).join('');
  }

  /* ── The designs, visible without earning one first ────────────────
     The rail lived only inside #cert-overlay, and that overlay only opens
     from an earned certificate — so with nothing mastered yet there was no
     way to reach the four designs at all. That is why you could not find
     them. My Certificates now carries its own copy: the four, a live
     preview filled with your name, and the same picker. ── */
  function mountPanel() {
    var box = document.getElementById('ss-cert-list');
    if (!box || document.getElementById('certPanelPick')) return;
    var host = document.createElement('div');
    host.id = 'certPanelPick';
    host.innerHTML =
      '<div class="certd-rail-head">Certificate design</div>' +
      '<div class="certd-panel-note">Pick the one your certificates are issued on. ' +
      'Words and meanings from the store open on the ivory pair, requested ones on the onyx pair — ' +
      'this overrides both.</div>' +
      '<div class="certd-rail" id="certPanelRail"></div>' +
      '<div class="certd" id="certPanelCard"></div>';
    box.parentNode.insertBefore(host, box);

    var rail = document.getElementById('certPanelRail');
    rail.innerHTML = DESIGNS.map(function (d) {
      return '<div class="certd-chip" data-k="' + d.k + '" onclick="nwsbCertPick(\'' + d.k + '\')">' +
               (d.img ? '<img class="certd-chip-art" src="' + d.img + '" alt="" loading="lazy" decoding="async">'
                      : '<span class="certd-chip-built"></span>') +
               '<span class="certd-chip-name">' + d.name + '</span>' +
               '<span class="certd-chip-sub">' + d.sub + '</span>' +
             '</div>';
    }).join('');
    paint();
  }
  window.nwsbCertPanel = mountPanel;

  /* part036.js owns the overlay. Wrap its open so a certificate raised the
     old way still gets the rail and the chosen design. */
  function boot() {
    /* Anything that renders My Certificates should also mount the picker. */
    var pr = window.ssRenderCertificates;
    if (typeof pr === 'function' && !pr._nwsbCert) {
      var wrapped = function () {
        var r = pr.apply(this, arguments);
        setTimeout(mountPanel, 0);
        return r;
      };
      wrapped._nwsbCert = 1;
      window.ssRenderCertificates = wrapped;
    }
    setTimeout(mountPanel, 600);
    buildRail();
    var C = window.CERT;
    if (C && typeof C.open === 'function' && !C._nwsbWrapped) {
      var prev = C.open;
      C.open = function (wordName) {
        var r = prev.apply(this, arguments);
        window.nwsbCertShow({ word: wordName });
        return r;
      };
      C._nwsbWrapped = 1;
    }
    /* The overlay can also be opened by mastering a word, which does not go
       through open() — so repaint whenever it becomes visible. */
    var ov = document.getElementById('cert-overlay');
    if (ov && window.MutationObserver) {
      new MutationObserver(function () {
        if (ov.classList.contains('open')) {
          var w = document.getElementById('certWord');
          if (w && w.textContent && w.textContent !== '—' && !state.word) state.word = w.textContent;
          buildRail(); paint();
        }
      }).observe(ov, { attributes: true, attributeFilter: ['class'] });
    }
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else setTimeout(boot, 400);

})();

/* ══════════════════════════════════════════════════════════════════════
   INSTALLED WEBVIEW UPDATE CHECK

   Android packages are static once installed. The bundle carries a concrete
   build number; the stable release manifest is uploaded only after the new
   APK asset is available. A newer manifest therefore means there is a real
   newer download, not merely a refreshed banner or cached script.
   ══════════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var MANIFEST = 'https://github.com/Ribonswebsites/Nowssb-App/releases/download/nowssb-android/NowssB-WebView-update.json';
  var shownBuild = 0;
  var checking = false;

  function nativeWebView() {
    try {
      return !!(window.nwsbIsNative ||
        (window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform()));
    } catch (e) { return false; }
  }

  function buildOf(v) {
    var n = Number.parseInt(v && v.build, 10);
    return Number.isFinite(n) ? n : 0;
  }

  function removeDialog() {
    var el = document.getElementById('nwsbUpdateDialog');
    if (el) el.remove();
  }

  function openUpdatePage(url) {
    /* Capacitor Browser opens the public update page outside the application
       shell. A fallback makes this usable if a host deliberately omits that
       optional native plugin. */
    try {
      var browser = window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.Browser;
      if (browser && typeof browser.open === 'function') {
        browser.open({ url: url, toolbarColor: '#060c18' }).catch(function () { window.location.assign(url); });
        return;
      }
    } catch (e) {}
    window.location.assign(url);
  }

  function showUpdate(remote) {
    removeDialog();
    var el = document.createElement('div');
    el.id = 'nwsbUpdateDialog';
    el.setAttribute('role', 'dialog');
    el.setAttribute('aria-modal', 'true');
    el.setAttribute('aria-label', 'NowssB update available');
    el.style.cssText = 'position:fixed;inset:0;z-index:2147483646;display:flex;align-items:center;justify-content:center;padding:24px;background:rgba(3,7,16,.78);font-family:DM Sans,system-ui,sans-serif;';
    el.innerHTML =
      '<div style="width:min(100%,360px);padding:26px 22px 20px;border:1px solid rgba(255,255,255,.24);border-radius:25px;background:linear-gradient(145deg,#14233a,#080f1d);box-shadow:0 24px 72px rgba(0,0,0,.58);color:#fff;text-align:center;">' +
        '<div style="width:48px;height:48px;margin:0 auto 14px;border-radius:50%;display:grid;place-items:center;background:#e8d5a3;color:#07101f;font-size:27px;font-weight:900;">↑</div>' +
        '<div style="font-size:21px;font-weight:800;letter-spacing:-.3px;">A new NowssB update is ready</div>' +
        '<p style="margin:10px 4px 21px;color:rgba(255,255,255,.72);font-size:13px;line-height:1.5;">Open the official NowssB download page to get the latest Android package.</p>' +
        '<div style="display:flex;gap:10px;">' +
          '<button data-update-later style="flex:1;border:1px solid rgba(255,255,255,.22);border-radius:13px;padding:13px 8px;background:transparent;color:#fff;font:700 13px DM Sans,sans-serif;">Later</button>' +
          '<button data-update-now style="flex:1;border:0;border-radius:13px;padding:13px 8px;background:#e8d5a3;color:#07101f;font:800 13px DM Sans,sans-serif;">Get update</button>' +
        '</div>' +
      '</div>';
    document.body.appendChild(el);
    el.querySelector('[data-update-later]').addEventListener('click', function () {
      try { localStorage.setItem('nwsb_update_later_webview', String(buildOf(remote))); } catch (e) {}
      removeDialog();
    });
    el.querySelector('[data-update-now]').addEventListener('click', function () {
      removeDialog();
      openUpdatePage(String(remote.websiteUrl || remote.apkUrl || 'https://ribonswebsites.github.io/Nowssb-App/'));
    });
  }

  async function checkForUpdates() {
    if (checking || !nativeWebView()) return false;
    checking = true;
    try {
      var pair = await Promise.all([
        fetch('./app-build.json', { cache: 'no-store' }).then(function (r) { return r.ok ? r.json() : { build: 0 }; }),
        fetch(MANIFEST + '?t=' + Date.now(), { cache: 'no-store', headers: { 'Cache-Control': 'no-cache' } }).then(function (r) { if (!r.ok) throw new Error('manifest unavailable'); return r.json(); })
      ]);
      var local = buildOf(pair[0]);
      var remote = pair[1] || {};
      var next = buildOf(remote);
      var deferred = 0;
      try { deferred = Number.parseInt(localStorage.getItem('nwsb_update_later_webview') || '0', 10) || 0; } catch (e) {}
      if (next > local && next > shownBuild && next > deferred) {
        shownBuild = next;
        showUpdate(remote);
        return true;
      }
    } catch (e) {
      /* Offline leaves the installed package usable; a later foreground
         return performs another lightweight check. */
    } finally {
      checking = false;
    }
    return false;
  }

  window.nwsbCheckForUpdates = checkForUpdates;
  window.addEventListener('load', function () { setTimeout(checkForUpdates, 2400); });
  document.addEventListener('visibilitychange', function () {
    if (!document.hidden) setTimeout(checkForUpdates, 700);
  });
})();
