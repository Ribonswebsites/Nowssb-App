/* ═══════════════════════════════════════════════════════════════
   NowssB Normal-Home (Neumorphism) controller
   - body.nm-mode  : active when the normal home is the chosen home
                     (localStorage nwsb_home_mode !== 'home')
   - body.nm-night : active when nm-mode AND the day/night toggle is dark
   - Suppresses the cinematic intros while in normal-home mode
   - Renders Today Trending + Today Offers on the normal home
   Inner-page neumorphism lives in nowssb-nm.css under body.nm-mode.
═══════════════════════════════════════════════════════════════ */
(function () {

  /* ── Body-class sync ── */
  /* Day/night mode removed — normal home is always light cream */
  try { localStorage.removeItem('nwsb_nm_dark'); } catch (e) {}
  function syncNmBody() {
    var mode = localStorage.getItem('nwsb_home_mode') || 'nm';
    var nm   = mode !== 'home';
    document.body.classList.toggle('nm-mode', nm);
    document.body.classList.remove('nm-night');           // night mode killed
    var hm = document.getElementById('home-nm');
    if (hm) hm.classList.remove('nm-dark');                // force light home
    /* Settings view-switch — JS-driven so it can't be beaten by CSS/cache */
    var main = document.getElementById('ss-main-view');
    var nv   = document.getElementById('nm-settings-view');
    if (nm) { if (main) main.style.display = 'none'; if (nv) nv.style.display = 'block'; }
    else    { if (main) main.style.display = '';     if (nv) nv.style.display = 'none'; }
  }
  window.nwsbSyncNmBody = syncNmBody;
  syncNmBody();

  /* ── Wrap a global fn so `after` runs once it finishes (retries until defined) ── */
  function wrapAfter(name, after) {
    var orig = window[name];
    if (typeof orig !== 'function') { return setTimeout(function () { wrapAfter(name, after); }, 150); }
    window[name] = function () {
      var r = orig.apply(this, arguments);
      try { after(); } catch (e) {}
      return r;
    };
  }
  wrapAfter('goTo', syncNmBody);

  /* openSub: sync body + auto-skip intros that aren't gated by shouldShowIntro */
  (function patchOpenSub() {
    if (typeof window.openSub !== 'function') { return setTimeout(patchOpenSub, 150); }
    var orig = window.openSub;
    window.openSub = function (id) {
      var r = orig.apply(this, arguments);
      try {
        syncNmBody();
        if (document.body.classList.contains('nm-mode') && id === 'nowssb-store') {
          /* Store intro isn't wired to shouldShowIntro — dismiss it directly */
          setTimeout(function () { if (typeof nssEnterStore === 'function') nssEnterStore(); }, 40);
        }
        if (document.body.classList.contains('nm-mode') && id === 'sound-bath') {
          /* Sound Bath intro isn't wired to shouldShowIntro — enter directly */
          setTimeout(function () { if (typeof sbEnter === 'function') sbEnter(); }, 40);
        }
        if (document.body.classList.contains('nm-mode') && id === 'my-progress') {
          /* My Progress always shows its intro — skip it directly */
          setTimeout(function () { if (typeof mpEnterFromIntro === 'function') mpEnterFromIntro(); }, 60);
        }
        if (document.body.classList.contains('nm-mode') && id === 'word-science') {
          /* Word Science intro isn't wired to shouldShowIntro — enter directly */
          setTimeout(function () { if (typeof wsEnterFromIntro === 'function') wsEnterFromIntro(); }, 60);
        }
        if (document.body.classList.contains('nm-mode') && id === 'social') {
          setTimeout(function () { if (window.nwsbRenderSettings) window.nwsbRenderSettings(); }, 30);
        }
      } catch (e) {}
      return r;
    };
  })();

  /* ── Suppress cinematic intros while in normal-home mode ── */
  function patchIntros() {
    if (typeof window.shouldShowIntro !== 'function') { return setTimeout(patchIntros, 150); }
    var orig = window.shouldShowIntro;
    window.shouldShowIntro = function (key) {
      if (document.body.classList.contains('nm-mode')) return false; /* skip straight to content */
      return orig.apply(this, arguments);
    };
  }
  patchIntros();

  /* ══════════════════════════════════════════════════════════
     TODAY TRENDING + TODAY OFFERS  (auto-rotate daily by date)
  ══════════════════════════════════════════════════════════ */

  function dayIndex() {
    var now   = new Date();
    var start = new Date(now.getFullYear(), 0, 0);
    return Math.floor((now - start) / 86400000);
  }

  /* Deterministic daily slice of an array */
  function rotate(arr, count, offset) {
    if (!arr || !arr.length) return [];
    var out = [], n = arr.length, base = (dayIndex() + (offset || 0)) % n;
    if (base < 0) base += n;
    for (var i = 0; i < Math.min(count, n); i++) out.push(arr[(base + i) % n]);
    return out;
  }

  function getLib()      { try { return (typeof MASTER_WORD_LIBRARY !== 'undefined') ? MASTER_WORD_LIBRARY : []; } catch (e) { return []; } }
  function getTiers()    { try { return (typeof RM_TIERS         !== 'undefined') ? RM_TIERS         : {}; } catch (e) { return {}; } }
  function getWordTier() { try { return (typeof RM_WORD_TIER     !== 'undefined') ? RM_WORD_TIER     : {}; } catch (e) { return {}; } }

  function renderTrending() {
    var box = document.getElementById('nmh-trending-row');
    if (!box) return;
    var picks = rotate(getLib(), 6, 0);
    if (!picks.length) { var s = document.getElementById('nmh-trending-section'); if (s) s.style.display = 'none'; return; }
    box.innerHTML = picks.map(function (w) {
      return '<div class="nmh-trend-card" onclick="nwsbOpenStoreWord(\'' + String(w.word).replace(/'/g, '') + '\')">' +
        '<div class="nmh-trend-badge">Trending</div>' +
        '<div class="nmh-trend-word">' + (w.word || '') + '</div>' +
        '<div class="nmh-trend-organ">' + (w.organ || '') + '</div>' +
        '<div class="nmh-trend-benefit">' + (w.benefit || '') + '</div>' +
        '<div class="nmh-trend-cta">View in Store →</div>' +
      '</div>';
    }).join('');
  }

  function renderOffers() {
    var box = document.getElementById('nmh-offers-row');
    if (!box) return;
    var tiers = getTiers(), wordTier = getWordTier();
    var discounted = Object.keys(wordTier).filter(function (word) {
      var t = tiers[wordTier[word]];
      return t && t.discount;
    });
    var picks = rotate(discounted, 5, 3);
    var section = document.getElementById('nmh-offers-section');
    if (!picks.length) { if (section) section.style.display = 'none'; return; }
    if (section) section.style.display = '';
    box.innerHTML = picks.map(function (word) {
      var t = tiers[wordTier[word]] || {};
      return '<div class="nmh-offer-card" onclick="nwsbOpenStoreWord(\'' + String(word).replace(/'/g, '') + '\')">' +
        (t.discount ? '<div class="nmh-offer-badge">' + t.discount + '</div>' : '') +
        '<div class="nmh-offer-word">' + word + '</div>' +
        '<div class="nmh-offer-price">' +
          '<span class="nmh-offer-now">' + (t.price || '') + '</span>' +
          (t.origPrice ? '<span class="nmh-offer-was">' + t.origPrice + '</span>' : '') +
        '</div>' +
        '<div class="nmh-offer-cta">Grab Deal →</div>' +
      '</div>';
    }).join('');
  }

  /* Tap a trending/offer card → open the store */
  window.nwsbOpenStoreWord = function (word) {
    window._nwsbStoreTargetWord = word || null;
    if (typeof openSub === 'function') openSub('nowssb-store');
  };

  function renderHomeExtras() { renderTrending(); renderOffers(); }
  window.nwsbRenderHomeExtras = renderHomeExtras;

  /* Re-render the storefront whenever the normal home refreshes */
  wrapAfter('nmhRefresh', function () { syncNmBody(); renderHomeExtras(); });

  if (document.readyState !== 'loading') setTimeout(renderHomeExtras, 350);
  else document.addEventListener('DOMContentLoaded', function () { setTimeout(renderHomeExtras, 350); });

  /* ══════════════════════════════════════════════════════════
     SETTINGS — purpose-built neumorphic UI renderer
     Reuses every existing handler; reads live values from the
     original (hidden) settings elements.
  ══════════════════════════════════════════════════════════ */
  var ICN = {
    crown:'<path d="M3 17l2-9 4 5 3-7 3 7 4-5 2 9z"/>',
    award:'<circle cx="12" cy="9" r="6"/><path d="M9 14l-1 7 4-2 4 2-1-7"/>',
    lock:'<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 018 0v4"/>',
    message:'<path d="M21 15a2 2 0 01-2 2H8l-4 4V6a2 2 0 012-2h13a2 2 0 012 2z"/>',
    eye:'<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/>',
    mic:'<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0014 0M12 18v3"/>',
    volume:'<path d="M4 9v6h4l5 4V5L8 9z"/><path d="M17 8a5 5 0 010 8"/>',
    gauge:'<path d="M4 18a8 8 0 1116 0"/><path d="M12 14l4-4"/>',
    waves:'<path d="M2 12c2-4 4-4 6 0s4 4 6 0 4-4 6 0"/>',
    list:'<path d="M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01"/>',
    repeat:'<path d="M17 2l4 4-4 4"/><path d="M3 11V9a4 4 0 014-4h14M7 22l-4-4 4-4"/><path d="M21 13v2a4 4 0 01-4 4H3"/>',
    target:'<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
    forward:'<path d="M5 4l8 8-8 8M13 4l8 8-8 8"/>',
    sun:'<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.5 1.5M17.5 17.5L19 19M19 5l-1.5 1.5M6.5 17.5L5 19"/>',
    zap:'<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>',
    play:'<path d="M5 3l16 9-16 9z"/>',
    layout:'<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M9 21V9"/>',
    type:'<path d="M4 7V5h16v2M9 19h6M12 5v14"/>',
    activity:'<path d="M22 12h-4l-3 9-6-18-3 9H2"/>',
    bold:'<path d="M7 5h7a4 4 0 010 8H7zM7 13h8a4 4 0 010 8H7z"/>',
    bell:'<path d="M18 8a6 6 0 00-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 01-3.4 0"/>',
    sparkle:'<path d="M12 3l2 6 6 2-6 2-2 6-2-6-6-2 6-2z"/>',
    download:'<path d="M12 3v12M7 11l5 5 5-5M5 21h14"/>',
    database:'<ellipse cx="12" cy="5" rx="8" ry="3"/><path d="M4 5v14c0 1.7 3.6 3 8 3s8-1.3 8-3V5M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"/>',
    trash:'<path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6"/>',
    info:'<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/>',
    file:'<path d="M14 3H6a2 2 0 00-2 2v14a2 2 0 002 2h12a2 2 0 002-2V9z"/><path d="M14 3v6h6"/>'
  };

  function svg(key) {
    return '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">' + (ICN[key] || ICN.info) + '</svg>';
  }
  function pv(id) { var el = document.getElementById(id); return el ? (el.textContent || '').trim() : ''; }
  function tglOn(key) {
    var el = document.getElementById('tgl-' + key); if (!el) return false;
    var k = el.querySelector('.stgl-knob'); if (!k) return false;
    return parseInt(k.style.left || '4', 10) > 10;
  }

  /* delegated handlers */
  window.nwsbCycle = function (fnName) { try { if (typeof window[fnName] === 'function') window[fnName](); } catch (e) {} window.nwsbRenderSettings(); };
  window.nwsbToggleSet = function (key) { var el = document.getElementById('tgl-' + key); try { if (el && typeof ssToggle === 'function') ssToggle(key, el); } catch (e) {} window.nwsbRenderSettings(); };

  function rowVal(icon, label, sub, pillId, fnName) {
    return '<div class="nmset-row" onclick="nwsbCycle(\'' + fnName + '\')">' +
      '<div class="nmset-ico">' + svg(icon) + '</div>' +
      '<div class="nmset-text"><div class="nmset-label">' + label + '</div>' + (sub ? '<div class="nmset-sub">' + sub + '</div>' : '') + '</div>' +
      '<div class="nmset-val">' + (pv(pillId) || '—') + '</div></div>';
  }
  function rowTgl(icon, label, sub, key) {
    var on = tglOn(key);
    return '<div class="nmset-row" onclick="nwsbToggleSet(\'' + key + '\')">' +
      '<div class="nmset-ico">' + svg(icon) + '</div>' +
      '<div class="nmset-text"><div class="nmset-label">' + label + '</div>' + (sub ? '<div class="nmset-sub">' + sub + '</div>' : '') + '</div>' +
      '<div class="nmset-tgl' + (on ? ' on' : '') + '"><div class="nmset-knob"></div></div></div>';
  }
  function rowNav(icon, label, sub, onclick, danger) {
    return '<div class="nmset-row' + (danger ? ' danger' : '') + '" onclick="' + onclick + '">' +
      '<div class="nmset-ico">' + svg(icon) + '</div>' +
      '<div class="nmset-text"><div class="nmset-label">' + label + '</div>' + (sub ? '<div class="nmset-sub">' + sub + '</div>' : '') + '</div>' +
      '<div class="nmset-chev"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M9 18l6-6-6-6"/></svg></div></div>';
  }
  function sec(label, rows) { return '<div class="nmset-sec-label">' + label + '</div><div class="nmset-card">' + rows + '</div>'; }

  window.nwsbRenderSettings = function () {
    var v = document.getElementById('nm-settings-view');
    if (!v) return;
    var name  = pv('ss-prof-name')  || 'Practitioner';
    var email = pv('ss-prof-email') || '';
    var badge = pv('ss-prof-badge') || 'FREE';
    var initial = (name.charAt(0) || 'N').toUpperCase();
    var cacheSub = pv('ss-cache-size') || 'Free up space';

    /* Force the view-switch every render (cache/CSS-proof) */
    var _main = document.getElementById('ss-main-view');
    if (_main) _main.style.display = 'none';
    v.style.display = 'block';

    v.innerHTML =
      '<div class="nmset-top">' +
        '<button class="nmset-back" onclick="closeSub(\'social\')"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5M12 5l-7 7 7 7"/></svg></button>' +
        '<div class="nmset-title">Settings</div>' +
      '</div>' +

      '<div class="nmset-hero" onclick="ssOpenPanel(\'profile-edit\')">' +
        '<div class="nmset-hero-av">' + initial + '</div>' +
        '<div class="nmset-hero-info">' +
          '<div class="nmset-hero-name">' + name + '</div>' +
          (email ? '<div class="nmset-hero-email">' + email + '</div>' : '') +
          '<span class="nmset-hero-badge">' + badge + '</span>' +
        '</div>' +
        '<div class="nmset-hero-chev"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M9 18l6-6-6-6"/></svg></div>' +
      '</div>' +

      '<div class="nmset-quick">' +
        '<div class="nmset-qtile" onclick="ssOpenPanel(\'subscription\')"><div class="nmset-qtile-ico">' + svg('crown') + '</div><div class="nmset-qtile-label">Plans</div></div>' +
        '<div class="nmset-qtile" onclick="ssOpenPanel(\'certificates\')"><div class="nmset-qtile-ico">' + svg('award') + '</div><div class="nmset-qtile-label">Certificates</div></div>' +
        '<div class="nmset-qtile" onclick="ssOpenPanel(\'privacy\')"><div class="nmset-qtile-ico">' + svg('lock') + '</div><div class="nmset-qtile-label">Privacy</div></div>' +
        '<div class="nmset-qtile" onclick="ssOpenPanel(\'chatsettings\')"><div class="nmset-qtile-ico">' + svg('message') + '</div><div class="nmset-qtile-label">Chat</div></div>' +
      '</div>' +

      sec('Audio &amp; Playback',
        rowVal('mic', 'Voice Preference', 'ElevenLabs voice', 'ss-voice-pill', 'ssCycleVoice') +
        rowTgl('volume', 'UI Sound Feedback', 'Interaction sounds', 'sound') +
        rowVal('gauge', 'Playback Speed', 'Speech speed', 'ss-speed-pill', 'ssCycleSpeed') +
        rowVal('waves', 'Ambient Sound', 'Background during practice', 'ss-ambient-pill', 'ssCycleAmbient')) +

      sec('Practice',
        rowVal('list', 'Words per Session', '', 'ss-wps-pill', 'ssCycleWordsPerSession') +
        rowVal('repeat', 'Repetitions per Word', '', 'ss-reps-pill', 'ssCycleReps') +
        rowVal('target', 'Scoring Sensitivity', '', 'ss-sens-pill', 'ssCycleSensitivity') +
        rowTgl('forward', 'Auto-Advance Words', 'Next word after reps complete', 'autoadvance') +
        rowTgl('sun', 'Keep Screen Awake', 'Prevent sleep during practice', 'screenwake')) +

      sec('Experience',
        rowTgl('zap', 'Haptic Feedback', 'Vibration on interactions', 'haptic') +
        rowTgl('play', 'Auto-Play Next Session', 'Continue routines automatically', 'autoplay')) +

      sec('Accessibility',
        rowVal('type', 'Text Size', '', 'ss-textsize-pill', 'ssCycleTextSize') +
        rowTgl('activity', 'Reduce Motion', 'Minimize transitions', 'reducemotion') +
        rowTgl('bold', 'Bold Text', 'Heavier font weight', 'boldtext')) +

      sec('Notifications',
        rowTgl('bell', 'Practice Reminders', 'Daily routine alerts', 'notif') +
        rowTgl('sparkle', 'New Words Alerts', 'When library updates', 'newword')) +

      sec('Privacy &amp; Social',
        rowTgl('eye', 'Appear in Discover', 'Others can find your profile', 'visible') +
        rowNav('lock', 'Privacy Settings', 'Who can see your stats', "ssOpenPanel('privacy')") +
        rowNav('message', 'Chat Settings', 'Who can message you', "ssOpenPanel('chatsettings')")) +

      sec('Storage &amp; Data',
        rowNav('download', 'Download My Data', 'Export sessions & progress as JSON', 'ssDownloadData()') +
        rowNav('database', 'Cached Data', cacheSub, 'ssClearCache()') +
        rowNav('trash', 'Clear Practice History', 'Remove session logs — cannot be undone', 'ssConfirmClearHistory()', true)) +

      sec('About',
        rowNav('info', 'About NowssB', 'v2.6.0 · nowssb.com', "ssOpenPanel('about')") +
        rowNav('file', 'Terms &amp; Privacy Policy', '', "ssOpenPanel('terms')")) +

      '<button class="nmset-signout" onclick="ssSignOut()">Sign Out</button>' +
      '<div class="nmset-foot">NowssB · Nowsbansiu · Healing through Word Science</div>';
  };

  /* ══════════════════════════════════════════════════════════
     RELIABLE avatar / banner upload — resize → save to Firestore
     (works without Cloudinary; overrides the existing handlers)
  ══════════════════════════════════════════════════════════ */
  function nwsbResize(file, maxW, cb) {
    var ALLOWED = ['image/jpeg','image/png','image/webp','image/gif'];
    if (!file || ALLOWED.indexOf(file.type) === -1) { alert('Please choose a JPG, PNG or WebP image'); return; }
    var reader = new FileReader();
    reader.onload = function (e) {
      var img = new Image();
      img.onload = function () {
        var scale = Math.min(1, maxW / img.width);
        var w = Math.max(1, Math.round(img.width * scale));
        var h = Math.max(1, Math.round(img.height * scale));
        var canvas = document.createElement('canvas');
        canvas.width = w; canvas.height = h;
        canvas.getContext('2d').drawImage(img, 0, 0, w, h);
        try { cb(canvas.toDataURL('image/jpeg', 0.85)); }
        catch (err) { cb(e.target.result); } /* fallback: original data url */
      };
      img.onerror = function () { cb(e.target.result); };
      img.src = e.target.result;
    };
    reader.readAsDataURL(file);
  }

  function nwsbRefreshAvatars(url) {
    if (window._userDataCache) window._userDataCache.photoURL = url;
    var c = document.getElementById('profile-edit-avatar-circle');
    if (c) { c.style.backgroundImage = 'url(' + url + ')'; c.style.backgroundSize = 'cover'; c.style.backgroundPosition = 'center'; c.innerHTML = ''; }
    var pa = document.getElementById('ig-prof-avatar');
    if (pa) { pa.style.display = 'block'; pa.src = url; }
    var init = document.querySelector('#sub-ig-profile .ig-prof-initials');
    if (init && init.parentNode) init.parentNode.removeChild(init);
    if (window.IG && typeof IG.refreshNavAvatar === 'function') IG.refreshNavAvatar();
    if (typeof profileUpdateAvatarDisplay === 'function') { try { profileUpdateAvatarDisplay(url, null); } catch (e) {} }
  }

  /* Open a fresh, clickable file input (avoids hidden-input click being
     blocked by some Android browsers) and route to the right handler */
  window.nwsbPickImage = function (kind) {
    var input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.setAttribute('aria-hidden', 'true');
    input.style.cssText = 'position:fixed;top:0;left:0;width:1px;height:1px;opacity:0;z-index:-1;';
    input.addEventListener('change', function () {
      var f = input.files && input.files[0];
      if (f) {
        if (kind === 'banner') window.profileHandleBannerFile(f);
        else                   window.profileHandlePhotoFile(f);
      }
      setTimeout(function () { if (input.parentNode) input.parentNode.removeChild(input); }, 1500);
    });
    document.body.appendChild(input);
    input.click();
  };

  window.profileHandlePhotoFile = function (file) {
    nwsbResize(file, 320, function (dataUrl) {
      nwsbRefreshAvatars(dataUrl);
      if (window._fbSetDoc && window._currentUid) window._fbSetDoc(window._currentUid, { photoURL: dataUrl }).catch(function () {});
    });
  };

  window.profileHandleBannerFile = function (file) {
    nwsbResize(file, 1000, function (dataUrl) {
      if (window._userDataCache) window._userDataCache.bannerURL = dataUrl;
      var b = document.getElementById('ig-prof-banner');
      if (b) { b.style.backgroundImage = 'url(' + dataUrl + ')'; b.style.backgroundSize = 'cover'; b.style.backgroundPosition = 'center top'; }
      var pv = document.getElementById('profile-edit-banner-preview');
      if (pv) { pv.style.backgroundImage = 'url(' + dataUrl + ')'; pv.style.backgroundSize = 'cover'; pv.style.backgroundPosition = 'center'; }
      if (window._fbSetDoc && window._currentUid) window._fbSetDoc(window._currentUid, { bannerURL: dataUrl }).catch(function () {});
    });
  };

})();
