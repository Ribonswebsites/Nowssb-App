
window.showFashionHomeIntro = function() {
  if (!window._splashDone) return;
  var el = document.getElementById('fashionHomeIntro');
  if (!el) return;
  // Unlock the CSS lock — without this body class, !important keeps it hidden
  document.body.classList.add('fi-ready');
  el.style.display = 'block';
  el.style.opacity = '0';
  el.style.transition = 'opacity 0.5s ease';
  requestAnimationFrame(function(){ requestAnimationFrame(function(){ el.style.opacity = '1'; }); });
};
window.fashionHomeIntroEnter = function() {
  var el = document.getElementById('fashionHomeIntro');
  if (!el) return;
  el.style.transition = 'opacity 0.38s ease';
  el.style.opacity = '0';
  setTimeout(function(){
    el.style.display = 'none';
    document.body.classList.remove('fi-ready');
    localStorage.setItem('nwsb_home_mode', 'home');
    document.querySelectorAll('.sub-screen.open').forEach(function(s){ s.classList.remove('open'); });
    if (typeof goTo === 'function') goTo('home');
  }, 400);
};

;

/* ── Radial / Meaning helpers added for redesigned player ── */
window.pwToggleRadial = function() {
  var w = document.getElementById('spRadialWrap');
  if (w) w.classList.toggle('open');
};
window.pwCycleRepTarget = function() {
  var t = [3,7,21]; var i = t.indexOf(_pwRepTarget);
  _pwRepTarget = t[(i+1)%t.length];
  var rv = document.getElementById('ssRepsVal');
  if (rv) rv.textContent = _pwRepTarget + '×';
};
window.pwExpandMeaning = function() {
  var s = document.getElementById('spMeaningSheet');
  if (!s) return;
  var w = PRACTICE_WORDS[_pwIdx]; if (!w) return;
  s.innerHTML = '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;"><div style="font-size:16px;font-weight:700;color:#fff;font-family:\'DM Sans\',sans-serif;">' + w.word + '</div><button onclick="pwCloseMeaning()" style="background:none;border:none;color:rgba(255,255,255,0.5);font-size:20px;cursor:pointer;line-height:1;">×</button></div>' +
    '<div style="font-size:13px;color:rgba(255,255,255,0.75);line-height:1.7;font-family:\'DM Sans\',sans-serif;margin-bottom:10px;">' + w.meaning + '</div>' +
    '<div style="font-size:10px;letter-spacing:1px;color:rgba(232,213,163,0.65);margin-bottom:6px;text-transform:uppercase;">' + w.organ + '</div>' +
    '<div style="font-size:12px;color:rgba(255,255,255,0.55);line-height:1.65;font-family:\'DM Sans\',sans-serif;">' + (w.benefit||'') + '</div>';
  s.classList.add('open');
};
window.pwCloseMeaning = function() {
  var s = document.getElementById('spMeaningSheet');
  if (s) s.classList.remove('open');
};

/* ══════════════════════════════════════════════════════════════════════════
   SESSION RESUME — make an installed PWA come back to where the user left off.
   Android kills backgrounded PWA processes under memory pressure, so returning
   cold-starts the page (splash + lost screen). We can't stop the kill, but we
   can make it invisible: on background, save the current screen + open overlays
   + scroll to localStorage; on next boot, once we land on home, silently reopen
   them. A fresh resume also shortens the splash (see firebase.module.js).
   Window: 30 min. sessionStorage is NOT used — it is wiped on a cold start. */
(function () {
  var KEY = 'nwsb_resume';
  var WINDOW_MS = 30 * 60 * 1000;
  // Overlays that reopen cleanly (simple content/list screens only — skip the
  // heavy player/store intros that do their own async setup).
  var SAFE = { 'word-search':1,'meaning-search':1,'cart':1,'wishlist':1,
               'orders':1,'order-history':1,'social':1,'routines':1,'word-science':1 };
  var SKIP_SCREENS = { splash:1, login:1, signup1:1, signup2:1, onboarding:1,
                       'ob-intro':1, 'ob-normal':1, 'profile-setup':1, landing:1, analysis:1 };

  function curScreen() {
    try { return (typeof currentScreen !== 'undefined') ? currentScreen : null; } catch (e) { return null; }
  }

  function save() {
    try {
      var sc = curScreen();
      if (!sc || SKIP_SCREENS[sc]) return;
      var subs = [];
      document.querySelectorAll('.sub-screen.open').forEach(function (el) {
        var id = (el.id || '').replace(/^sub-/, '');
        var st = 0; try { st = el.scrollTop || 0; } catch (e) {}
        subs.push({ id: id, scroll: st });
      });
      localStorage.setItem(KEY, JSON.stringify({ screen: sc, subs: subs, ts: Date.now() }));
    } catch (e) {}
  }

  function read() {
    try {
      var st = JSON.parse(localStorage.getItem(KEY) || 'null');
      if (!st || (Date.now() - st.ts) > WINDOW_MS) return null;
      return st;
    } catch (e) { return null; }
  }

  // Expose freshness so the splash timer can shorten itself on resume.
  window._nwsbHasFreshResume = function () { return !!read(); };

  // Save the instant we go to background (no reliable "about to be killed" event).
  document.addEventListener('visibilitychange', function () {
    if (document.visibilityState === 'hidden') save();
  });
  window.addEventListener('pagehide', save);

  // Restore once, the first time we settle on a home screen after boot.
  var restored = false;
  function tryRestore(landed) {
    if (restored) return;
    if (landed !== 'home' && landed !== 'home-nm') return;
    restored = true;
    var st = read();
    if (!st || !st.subs || !st.subs.length) return;
    var toOpen = st.subs.filter(function (s) { return SAFE[s.id]; });
    if (!toOpen.length) return;
    // Reopen after the home transition has settled, without the slide animation.
    setTimeout(function () {
      toOpen.forEach(function (s) {
        try {
          var el = document.getElementById('sub-' + s.id);
          if (!el || typeof openSub !== 'function') return;
          el.style.transition = 'none';
          openSub(s.id);
          if (s.scroll) { try { el.scrollTop = s.scroll; } catch (e) {} }
          requestAnimationFrame(function () { el.style.transition = ''; });
        } catch (e) {}
      });
    }, 420);
  }

  // Wrap the (already-wrapped) global goTo to detect the first landing on home.
  if (typeof window.goTo === 'function') {
    var _prevGoTo = window.goTo;
    window.goTo = function (id) {
      var r = _prevGoTo.apply(this, arguments);
      try { tryRestore(id); } catch (e) {}
      return r;
    };
  }
})();
