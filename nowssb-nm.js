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
  /* Day/night mode + glass theme removed — normal home is always light neumorphism */
  try { localStorage.removeItem('nwsb_nm_dark'); localStorage.removeItem('nwsb_nm_theme'); } catch (e) {}
  document.body && document.body.classList.remove('nm-glass');

  /* Restore a locally-saved avatar/banner (guests, and before Firebase loads) */
  (function restoreLocalMedia() {
    var photo, banner;
    try { photo = localStorage.getItem('nwsb_local_photo'); banner = localStorage.getItem('nwsb_local_banner'); } catch (e) {}
    if (!photo && !banner) return;
    function apply() {
      window._userDataCache = window._userDataCache || {};
      if (photo && !window._userDataCache.photoURL) window._userDataCache.photoURL = photo;
      if (banner && !window._userDataCache.bannerURL) window._userDataCache.bannerURL = banner;
      if (window.IG && typeof IG.refreshNavAvatar === 'function') { try { IG.refreshNavAvatar(); } catch (e) {} }
    }
    apply();
    setTimeout(apply, 1500); /* re-apply after auth/data settles */
  })();
  function syncNmBody() {
    var mode = localStorage.getItem('nwsb_home_mode') || 'nm';
    var nm   = mode !== 'home';
    document.body.classList.toggle('nm-mode', nm);
    document.body.classList.remove('nm-night');           // night mode killed
    document.body.classList.remove('nm-glass');           // theme switcher removed — neumorphism only
    var hm = document.getElementById('home-nm');
    if (hm) hm.classList.remove('nm-dark');                // force light home
    /* Social profile THEME — manual switch (NowssB = neumorphism, NowssB Fashion
       = glass), independent of home mode. Default neumorphism until changed. */
    var soc = 'neu';
    try { soc = localStorage.getItem('nwsb_social_theme') || 'neu'; } catch (e) {}
    document.body.classList.toggle('nwsb-soc-glass', soc === 'glass');
    /* Settings view-switch — JS-driven so it can't be beaten by CSS/cache */
    var main = document.getElementById('ss-main-view');
    var nv   = document.getElementById('nm-settings-view');
    if (nm) { if (main) main.style.display = 'none'; if (nv) nv.style.display = 'block'; }
    else    { if (main) main.style.display = 'flex'; if (nv) nv.style.display = 'none'; }  /* restore flex so Fashion settings scrolls */
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
        /* My Progress + Word Science now behave exactly like the Fashion page
           (glass styling, intro shown normally) — no nm-mode special-casing. */
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
    window.shouldShowIntro = function (key) {
      /* Daily Practice (routine) intro is exempt — it must behave identically
         in normal home and Fashion home, not get silently skipped here. */
      if (key !== 'routine' && document.body.classList.contains('nm-mode')) return false; /* skip straight to content */
      var mode; try { mode = localStorage.getItem('nwsb_intros'); } catch (e) {}
      if (mode === 'off') return false;
      /* Show each intro ONCE per app session (resets only on full close + reopen) */
      if (!window._introSeen) window._introSeen = {};
      if (window._introSeen[key]) return false;
      window._introSeen[key] = true;
      return true;
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

  var STORE_ICON_URL = 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563284/ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png';
  var _trendVidTimer = null;
  var _trendShopTimer = null;
  window._nwsbTrendPicks = [];

  function trendEyebrow(w) {
    return 'Heals ' + (w.organ || w.benefit || '');
  }

  /* Video banner — one trending word at a time, paired with the store icon.
     Runs on its own timer (see renderTrending) so it drifts independently
     from the Shop Now banner below it. */
  function paintTrendVideo(targets, picks, idx) {
    var w = picks[idx % picks.length];
    var wordSafe = String(w.word).replace(/'/g, '');
    targets.forEach(function (t) {
      t.box.innerHTML = '<div class="nmh-trend-banner-item" onclick="event.stopPropagation();nwsbOpenStoreWord(\'' + wordSafe + '\')">' +
        '<div class="nmh-trend-banner-word">' + (w.word || '') + '</div>' +
        '<img class="nmh-trend-banner-icon" decoding="async" loading="lazy" src="' + STORE_ICON_URL + '" alt="">' +
      '</div>';
      var item = t.box.querySelector('.nmh-trend-banner-item');
      if (item) {
        item.style.opacity = '0';
        requestAnimationFrame(function () { item.style.opacity = '1'; });
      }
    });
  }

  /* Shop Now banner — dots let a person jump straight to any word's store
     page; the active dot also tracks whichever word is currently showing. */
  function paintTrendShop(shopTargets, picks, idx) {
    var w = picks[idx % picks.length];
    shopTargets.forEach(function (t) {
      if (t.label) t.label.textContent = trendEyebrow(w);
      if (t.word) {
        t.word.textContent = w.word || '';
        t.word.classList.remove('dash-in');
        void t.word.offsetWidth;
        t.word.classList.add('dash-in');
      }
      if (t.dots) {
        var dots = t.dots.querySelectorAll('.nmh-trend-shop-dot');
        for (var i = 0; i < dots.length; i++) dots[i].classList.toggle('on', i === (idx % picks.length));
      }
    });
  }

  /* Tap a dot → jump every Shop Now banner to that word and open its store page. */
  window.nwsbTrendDotTap = function (dotEl) {
    var i = parseInt(dotEl.getAttribute('data-i'), 10);
    var picks = window._nwsbTrendPicks || [];
    var w = picks[i];
    if (!w) return;
    document.querySelectorAll('.nmh-trend-shop-banner').forEach(function (banner) {
      var label = banner.querySelector('.nmh-trend-shop-label');
      var word = banner.querySelector('.nmh-trend-shop-word');
      var dots = banner.querySelector('.nmh-trend-shop-dots');
      if (label) label.textContent = trendEyebrow(w);
      if (word) { word.textContent = w.word || ''; word.classList.remove('dash-in'); void word.offsetWidth; word.classList.add('dash-in'); }
      if (dots) {
        var ds = dots.querySelectorAll('.nmh-trend-shop-dot');
        for (var j = 0; j < ds.length; j++) ds[j].classList.toggle('on', j === i);
      }
    });
    if (window.nwsbOpenStoreWord) nwsbOpenStoreWord(w.word);
  };

  function renderTrending() {
    var targets = [
      { sec: document.getElementById('nmh-trending-section'),      box: document.getElementById('nmh-trending-text') },
      { sec: document.getElementById('nmh-trending-section-fash'), box: document.getElementById('nmh-trending-text-fash') }
    ].filter(function (t) { return t.sec && t.box; });
    var shopTargets = [
      { sec: document.getElementById('nmh-trending-shop-banner'),      label: document.getElementById('nmh-trending-shop-label'),      word: document.getElementById('nmh-trending-shop-word'),      dots: document.getElementById('nmh-trending-shop-dots') },
      { sec: document.getElementById('nmh-trending-shop-banner-fash'), label: document.getElementById('nmh-trending-shop-label-fash'), word: document.getElementById('nmh-trending-shop-word-fash'), dots: document.getElementById('nmh-trending-shop-dots-fash') }
    ].filter(function (t) { return t.sec && t.word; });
    if (!targets.length && !shopTargets.length) return;
    if (_trendVidTimer)  { clearInterval(_trendVidTimer);  _trendVidTimer = null; }
    if (_trendShopTimer) { clearInterval(_trendShopTimer); _trendShopTimer = null; }
    var picks = rotate(getLib(), 5, 0);
    window._nwsbTrendPicks = picks;
    if (!picks.length) {
      targets.forEach(function (t) { t.sec.style.display = 'none'; });
      shopTargets.forEach(function (t) { t.sec.style.display = 'none'; });
      return;
    }
    targets.forEach(function (t) { t.sec.style.display = ''; });
    shopTargets.forEach(function (t) {
      t.sec.style.display = '';
      if (t.dots && !t.dots.dataset.built) {
        t.dots.innerHTML = picks.map(function (_, i) {
          return '<span class="nmh-trend-shop-dot" data-i="' + i + '" onclick="event.stopPropagation();nwsbTrendDotTap(this)"></span>';
        }).join('');
        t.dots.dataset.built = '1';
      }
    });

    var vidIdx = 0;
    paintTrendVideo(targets, picks, vidIdx);
    _trendVidTimer = setInterval(function () { vidIdx++; paintTrendVideo(targets, picks, vidIdx); }, 2400);

    var shopIdx = 0;
    paintTrendShop(shopTargets, picks, shopIdx);
    _trendShopTimer = setInterval(function () { shopIdx++; paintTrendShop(shopTargets, picks, shopIdx); }, 3000);
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

      sec('App',
        rowNav('download', 'Download App', 'Install NowssB on your device', 'openDlPopup()')) +

      sec('Storage &amp; Data',
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
    /* Ensure the cache exists (guests have a null/minimal cache) and persist
       so the social profile re-render + reloads pick up the new photo */
    window._userDataCache = window._userDataCache || {};
    window._userDataCache.photoURL = url;
    try { localStorage.setItem('nwsb_local_photo', url); } catch (e) {}
    /* Edit-profile panel avatar (first img in that panel) */
    var panel = document.getElementById('ss-panel-profile-edit');
    if (panel) { var pimg = panel.querySelector('img'); if (pimg) pimg.src = url; }
    var c = document.getElementById('profile-edit-avatar-circle');
    if (c) { c.style.backgroundImage = 'url(' + url + ')'; c.style.backgroundSize = 'cover'; c.style.backgroundPosition = 'center'; c.innerHTML = ''; }
    /* IG profile avatar */
    var pa = document.getElementById('ig-prof-avatar');
    if (pa) { pa.style.display = 'block'; pa.src = url; }
    var init = document.querySelector('#sub-ig-profile .ig-prof-initials');
    if (init && init.parentNode) init.parentNode.removeChild(init);
    if (window.IG && typeof IG.refreshNavAvatar === 'function') IG.refreshNavAvatar();
    /* Full re-render of the IG profile if it's open (reads updated cache) */
    var igp = document.getElementById('sub-ig-profile');
    if (window.IG && igp && igp.classList.contains('open') && typeof IG.openMyProfile === 'function') {
      try { IG.openMyProfile(); } catch (e) {}
    }
    if (typeof profileUpdateAvatarDisplay === 'function') { try { profileUpdateAvatarDisplay(url, null); } catch (e) {} }
    nwsbToast('Photo updated ✓');
  }
  function nwsbToast(msg) {
    var t = document.createElement('div');
    t.textContent = msg;
    t.style.cssText = 'position:fixed;left:50%;bottom:90px;transform:translateX(-50%);background:#1a1a2e;color:#e8d5a3;font-family:DM Sans,sans-serif;font-size:13px;font-weight:700;padding:11px 20px;border-radius:24px;z-index:99999;box-shadow:0 6px 20px rgba(0,0,0,.3);';
    document.body.appendChild(t);
    setTimeout(function () { if (t.parentNode) t.parentNode.removeChild(t); }, 2200);
  }
  window.nwsbToast = nwsbToast;

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

  /* Photo chooser's "Pick from library" → reliable on-the-fly picker */
  window.profilePickFromLibrary = function () {
    if (typeof profileClosePhotoSheet === 'function') profileClosePhotoSheet();
    window.nwsbPickImage('photo');
  };

  /* "Use This Avatar" (preset avatar) → reliable refresh (works for guests too) */
  window.profileConfirmAvatar = function () {
    var url = window._papSelectedUrl;
    if (!url) { if (window.nwsbToast) nwsbToast('Pick an avatar first'); return; }
    if (typeof profileCloseAvatarPicker === 'function') profileCloseAvatarPicker();
    if (typeof profileClosePhotoSheet === 'function') profileClosePhotoSheet();
    nwsbRefreshAvatars(url);
    if (window._fbSetDoc && window._currentUid) window._fbSetDoc(window._currentUid, { photoURL: url }).catch(function () {});
  };

  window.profileHandlePhotoFile = function (file) {
    nwsbResize(file, 320, function (dataUrl) {
      nwsbRefreshAvatars(dataUrl);
      if (window._fbSetDoc && window._currentUid) window._fbSetDoc(window._currentUid, { photoURL: dataUrl }).catch(function () {});
    });
  };

  /* Apply a banner URL/dataURL everywhere + persist (works for guests too) */
  function nwsbApplyBanner(url) {
    window._userDataCache = window._userDataCache || {};
    window._userDataCache.bannerURL = url;
    try { localStorage.setItem('nwsb_local_banner', url); } catch (e) {}
    var b = document.getElementById('ig-prof-banner');
    if (b) { b.style.backgroundImage = 'url(' + url + ')'; b.style.backgroundSize = 'cover'; b.style.backgroundPosition = 'center'; }
    var pv = document.getElementById('profile-edit-banner-preview');
    if (pv) { pv.style.backgroundImage = 'url(' + url + ')'; pv.style.backgroundSize = 'cover'; pv.style.backgroundPosition = 'center'; pv.innerHTML = ''; }
    /* If the IG profile is open, re-render so the banner shows there immediately */
    var igp = document.getElementById('sub-ig-profile');
    if (window.IG && igp && igp.classList.contains('open') && typeof IG.openMyProfile === 'function') {
      try { IG.openMyProfile(); } catch (e) {}
    }
    if (window._fbSetDoc && window._currentUid) window._fbSetDoc(window._currentUid, { bannerURL: url }).catch(function () {});
    nwsbToast('Banner updated ✓');
  }
  window.nwsbApplyBanner = nwsbApplyBanner;

  window.profileHandleBannerFile = function (file) {
    nwsbResize(file, 1000, function (dataUrl) { nwsbApplyBanner(dataUrl); });
  };

  /* ── Prebuilt banner library (in-built banners, matched to the avatars) ── */
  var NWSB_BANNERS = [
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592067/grok_image_1782591933705_qq3l9g.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592067/grok_image_1782591857840_tbznap.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592067/grok_image_1782592051446_womamz.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592067/grok_image_1782591669371_kqnaf9.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592066/grok_image_1782591627828_lmde11.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592066/grok_image_1782591559591_yxgud5.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592066/grok_image_1782591561380_ytpn3b.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592260/grok_image_1782591732123_epmpiu.jpg'
  ];
  window.NWSB_BANNERS = NWSB_BANNERS;

  function nwsbCloseBannerUI() {
    var s = document.getElementById('nwsb-banner-sheet'); if (s) s.remove();
    var p = document.getElementById('nwsb-banner-picker'); if (p) p.remove();
  }
  window.nwsbCloseBannerUI = nwsbCloseBannerUI;

  /* Bottom chooser: Upload your own  /  Pick a prebuilt banner —
     mirrors the Change Photo sheet (#profilePhotoSheet) exactly: same
     .pps-* classes, same full-bleed auto-height banner, same dark theme. */
  window.nwsbBannerChooser = function () {
    nwsbCloseBannerUI();
    var navH = 'calc(44px + var(--nav-height,58px) + env(safe-area-inset-bottom,0px))';
    var w = document.createElement('div');
    w.id = 'nwsb-banner-sheet';
    w.style.cssText = 'position:fixed;inset:0;z-index:10000;';
    w.innerHTML =
      '<div class="pps-backdrop" onclick="nwsbCloseBannerUI()"></div>' +
      '<div class="pps-card" style="padding-bottom:' + navH + ';">' +
        '<img class="pps-banner" decoding="async" loading="lazy" src="https://res.cloudinary.com/eenvubod/image/upload/v1784368347/grok_image_1784368231258_qti4xe.jpg" alt="">' +
        '<div class="pps-inner">' +
          '<div class="pps-handle"></div>' +
          '<div class="pps-title">Change Banner</div>' +
          '<button onclick="nwsbCloseBannerUI();nwsbPickImage(\'banner\')" class="pps-btn">' +
            '<div class="pps-btn-icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="rgba(200,232,245,0.75)" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg></div>' +
            '<div><div class="pps-btn-label">Upload Photo</div><div class="pps-btn-sub">Choose from your phone\'s gallery</div></div>' +
          '</button>' +
          '<button onclick="nwsbBannerPicker()" class="pps-btn">' +
            '<div class="pps-btn-icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="rgba(200,232,245,0.75)" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 15l5-5 4 4 3-3 6 6"/></svg></div>' +
            '<div><div class="pps-btn-label">Prebuilt Banner</div><div class="pps-btn-sub">Pick from ready-made banners</div></div>' +
          '</button>' +
        '</div>' +
      '</div>';
    document.body.appendChild(w);
  };

  /* Grid of prebuilt banners */
  window.nwsbBannerPicker = function () {
    nwsbCloseBannerUI();
    var navH = 'calc(var(--nav-height,58px) + env(safe-area-inset-bottom,0px) + 24px)';
    var cells = NWSB_BANNERS.map(function (u) {
      return '<div onclick="nwsbApplyBanner(\'' + u + '\');nwsbCloseBannerUI();" style="width:100%;height:84px;border-radius:14px;background:#f0f2f7 url(' + u + ') center/cover no-repeat;cursor:pointer;box-shadow:5px 5px 12px rgba(0,0,0,.13),-3px -3px 9px rgba(255,255,255,.92);"></div>';
    }).join('');
    var w = document.createElement('div');
    w.id = 'nwsb-banner-picker';
    w.style.cssText = 'position:fixed;inset:0;z-index:10001;display:flex;align-items:flex-end;justify-content:center;';
    w.innerHTML =
      '<div onclick="nwsbCloseBannerUI()" style="position:absolute;inset:0;background:rgba(20,22,34,.5);backdrop-filter:blur(3px);"></div>' +
      '<div style="position:relative;width:100%;max-width:520px;max-height:82vh;display:flex;flex-direction:column;background:#f0f2f7;border-radius:28px 28px 0 0;padding:18px 18px ' + navH + ';box-shadow:0 -10px 40px rgba(0,0,0,.25);">' +
        '<div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;flex-shrink:0;">' +
          '<button onclick="nwsbBannerChooser()" style="display:flex;align-items:center;gap:6px;background:none;border:none;cursor:pointer;font-family:DM Sans,sans-serif;font-size:13px;font-weight:700;color:#c8a96e;"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#c8a96e" stroke-width="2"><path d="M15 18l-6-6 6-6"/></svg>Back</button>' +
          '<div style="font-family:DM Sans,sans-serif;font-size:16px;font-weight:800;color:#1a1a2e;">Choose Banner</div>' +
          '<div style="width:44px;"></div>' +
        '</div>' +
        '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;overflow-y:auto;-webkit-overflow-scrolling:touch;">' + cells + '</div>' +
      '</div>';
    document.body.appendChild(w);
  };

  /* ══════════════════════════════════════════════════════════
     SOCIAL PROFILE NAVIGATION FIX
     normal/fashion home → social profile → (edit) → back → social profile
                                                    → back → the home you came from
  ══════════════════════════════════════════════════════════ */
  function nwsbHomeScreen() {
    return (localStorage.getItem('nwsb_home_mode') || 'nm') === 'home' ? 'home' : 'home-nm';
  }

  /* Edit Profile: open the edit panel cleanly, remember we came from social */
  (function patchEditProfile() {
    if (!window.IG) return setTimeout(patchEditProfile, 150);
    window.IG.editProfile = function () {
      window._nwsbEditFromSocial = true;
      var igp = document.getElementById('sub-ig-profile');
      var ppl = document.getElementById('sub-people');
      var hub = document.getElementById('sub-connect-hub');
      var social = document.getElementById('sub-social');
      /* All four of these are .sub-screen overlays sharing the same slide
         transition. Closing one (igp/ppl/hub) while opening another
         (sub-social) at the same time — both animating in the same
         direction — briefly uncovers the app's home screen mid-transition,
         same root cause as the bottom-nav tab-switch flash. Snap instantly
         instead: disable the transition for the group, toggle, then restore
         it a couple of frames later so a genuine slide-in from elsewhere
         still animates normally. */
      var group = [igp, ppl, hub, social].filter(Boolean);
      group.forEach(function (el) { el.style.transition = 'none'; });
      if (igp) igp.classList.remove('open');
      if (ppl) ppl.classList.remove('open');
      /* sub-connect-hub is later in DOM than sub-social too (same z-index),
         so if Edit Profile is opened FROM the Connect hub, the hub's own
         header/video banner render on top of the Edit Profile panel unless
         it's explicitly closed here as well. */
      if (hub) hub.classList.remove('open');
      if (typeof openSub === 'function') openSub('social');
      requestAnimationFrame(function () {
        requestAnimationFrame(function () {
          group.forEach(function (el) { el.style.transition = ''; });
        });
      });
      /* Hide ALL settings content so only the Edit Profile panel shows —
         the social section must never reveal the app settings/site */
      var main = document.getElementById('ss-main-view');
      var nv   = document.getElementById('nm-settings-view');
      if (main) main.style.display = 'none';
      if (nv)   nv.style.display = 'none';
      /* populate fields, then show the panel instantly (no slide/flash) */
      if (typeof ssOpenPanel === 'function') { try { ssOpenPanel('profile-edit'); } catch (e) {} }
      var panel = document.getElementById('ss-panel-profile-edit');
      if (panel) {
        panel.style.transition = 'none';
        panel.style.transform  = 'translateX(0)';
        panel.style.display     = 'block';
        panel.style.visibility  = 'visible';
      }
      /* reflect the current theme on the switcher buttons */
      if (typeof nwsbSyncThemeButtons === 'function') { try { nwsbSyncThemeButtons(); } catch (e) {} }
    };
  })();

  /* Theme switcher removed — neumorphism only. Kept as a no-op for safety. */
  window.nwsbSetNmTheme = function () {};

  /* ── Manual social-profile theme switch: NowssB (neumorphism) / NowssB Fashion (glass) ── */
  window.nwsbSetSocTheme = function (theme) {
    theme = (theme === 'glass') ? 'glass' : 'neu';
    try { localStorage.setItem('nwsb_social_theme', theme); } catch (e) {}
    document.body.classList.toggle('nwsb-soc-glass', theme === 'glass');
    nwsbSyncThemeButtons();
    /* re-render the IG profile if it's open so inline banner/avatar refresh under the new theme */
    var igp = document.getElementById('sub-ig-profile');
    if (window.IG && igp && igp.classList.contains('open') && typeof IG.openMyProfile === 'function') {
      try { IG.openMyProfile(); } catch (e) {}
    }
    if (window.nwsbToast) nwsbToast(theme === 'glass' ? 'NowssB Fashion theme ✓' : 'NowssB theme ✓');
  };
  function nwsbSyncThemeButtons() {
    var theme = 'neu';
    try { theme = localStorage.getItem('nwsb_social_theme') || 'neu'; } catch (e) {}
    var neu = document.getElementById('nwsb-theme-neu');
    var gl  = document.getElementById('nwsb-theme-glass');
    if (neu) neu.classList.toggle('active', theme === 'neu');
    if (gl)  gl.classList.toggle('active', theme === 'glass');
  }
  window.nwsbSyncThemeButtons = nwsbSyncThemeButtons;

  /* Close the Edit Profile panel and return to the social profile (never the
     blank SS settings screen) */
  window.nwsbCloseEditProfile = function () {
    var panel = document.getElementById('ss-panel-profile-edit');
    if (panel) {
      panel.style.transition = 'transform .3s cubic-bezier(.4,0,.2,1)';
      panel.style.transform = 'translateX(100%)';
      setTimeout(function () { panel.style.display = 'none'; panel.style.transform = ''; panel.style.transition = ''; }, 320);
    }
    /* restore the settings views that editProfile hid */
    var main = document.getElementById('ss-main-view');
    var nv   = document.getElementById('nm-settings-view');
    if (main) main.style.display = '';
    if (nv)   nv.style.display = '';
    if (window._nwsbEditFromSocial) {
      window._nwsbEditFromSocial = false;
      if (typeof closeSub === 'function') closeSub('social');
      var mainNav = document.getElementById('ig-bottomnav');
      var sn      = document.getElementById('ig-social-nav');
      if (mainNav) mainNav.style.display = 'none';
      if (sn)      sn.style.display = 'flex';
      var igp = document.getElementById('sub-ig-profile');
      if (igp) igp.classList.add('open');
      if (window.IG && typeof IG.openMyProfile === 'function') { try { IG.openMyProfile(); } catch (e) {} }
    } else {
      if (window.nwsbSyncNmBody) window.nwsbSyncNmBody();
    }
  };

  /* Back / Save from Edit Profile → return to the social profile (re-rendered) */
  (function patchClosePanel() {
    if (typeof window.ssClosePanel !== 'function') return setTimeout(patchClosePanel, 150);
    var orig = window.ssClosePanel;
    window.ssClosePanel = function (id) {
      var fromSocial = (id === 'profile-edit' && window._nwsbEditFromSocial);
      var r = orig.apply(this, arguments);
      if (fromSocial) {
        window._nwsbEditFromSocial = false;
        if (typeof closeSub === 'function') closeSub('social');
        var mainNav = document.getElementById('ig-bottomnav');
        var sn      = document.getElementById('ig-social-nav');
        if (mainNav) mainNav.style.display = 'none';
        if (sn)      sn.style.display = 'flex';
        var igp = document.getElementById('sub-ig-profile');
        if (igp) igp.classList.add('open');
        if (window.IG && typeof IG.openMyProfile === 'function') { try { IG.openMyProfile(); } catch (e) {} }
        if (typeof setSocialNavActive === 'function') {} /* noop */
      }
      return r;
    };
  })();

  /* Social-nav Home → the home you actually came from (normal or fashion) */
  (function patchSocialHome() {
    if (!window.IG || typeof window.IG.socialNav !== 'function') return setTimeout(patchSocialHome, 150);
    var orig = window.IG.socialNav;
    window.IG.socialNav = function (which) {
      if (which === 'home') {
        /* Close EVERY open sub-screen overlay (social + anything else lingering)
           so nothing covers the home screen → no more blank dark screen */
        var subs = document.querySelectorAll('.sub-screen.open');
        for (var i = 0; i < subs.length; i++) subs[i].classList.remove('open');
        var sn = document.getElementById('ig-social-nav');
        var mainNav = document.getElementById('ig-bottomnav');
        if (sn) sn.style.display = 'none';
        if (mainNav) mainNav.style.display = '';
        window._nwsbEditFromSocial = false;
        if (typeof setActiveNav === 'function') setActiveNav('home');
        var target = nwsbHomeScreen();
        /* The social section is an OVERLAY, so `currentScreen` is still the home
           we came from. Calling goTo(target) when currentScreen === target hits
           goTo's self-exit bug (it strips .active from the very screen it just
           activated 500ms later → blank screen). Nudge currentScreen to the
           OTHER home first so goTo does a clean cross-fade onto `target`. */
        try {
          if (typeof currentScreen !== 'undefined' && currentScreen === target) {
            currentScreen = (target === 'home') ? 'home-nm' : 'home';
          }
        } catch (e) {}
        if (typeof goTo === 'function') goTo(target);
        if (typeof nmhRefresh === 'function' && target === 'home-nm') { try { nmhRefresh(); } catch (e) {} }
        syncNmBody();
        return;
      }
      return orig.apply(this, arguments);
    };
  })();

  /* ── Bulletproof settings view-switch: whenever #sub-social opens in nm-mode,
     hide the old fashion settings list and render the curated neumorphic one,
     no matter which entry point opened it ── */
  (function observeSocialOpen() {
    var el = document.getElementById('sub-social');
    if (!el) return setTimeout(observeSocialOpen, 200);
    function apply() {
      if (!el.classList.contains('open')) return;
      if (!document.body.classList.contains('nm-mode')) return;
      /* Editing from the social profile → show ONLY the Edit Profile panel,
         never the settings list (that caused the flash + back-to-settings bug) */
      if (window._nwsbEditFromSocial) {
        var m2 = document.getElementById('ss-main-view');
        var n2 = document.getElementById('nm-settings-view');
        if (m2) m2.style.display = 'none';
        if (n2) n2.style.display = 'none';
        return;
      }
      var main = document.getElementById('ss-main-view');
      var nv   = document.getElementById('nm-settings-view');
      if (main) main.style.display = 'none';
      if (nv)   nv.style.display = 'block';
      if (window.nwsbRenderSettings) window.nwsbRenderSettings();
    }
    new MutationObserver(apply).observe(el, { attributes: true, attributeFilter: ['class'] });
    apply();
  })();

})();
