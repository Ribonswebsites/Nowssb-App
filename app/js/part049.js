
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

/* ══════════════════════════════════════════════════════════════════════════
   WORD / MEANING SEARCH — suggestion carousel + working Explore button.
   The "Focus on details" card is now a horizontal, auto-rotating strip of word
   suggestions (one word + a line of text per slide). It advances itself every
   ~3.8s and the user can also swipe through it. Explore searches whatever the
   user typed; if the input is empty it searches the suggestion on screen. */
(function () {
  function initCarousel(carId, screenId) {
    var car = document.getElementById(carId);
    if (!car || car._wsgInit) return;
    car._wsgInit = true;
    var slides = car.querySelectorAll('.wsg-slide');
    var n = slides.length; if (!n) return;
    var idx = 0, paused = false, programmatic = false, resumeT = null, progT = null;

    function slideW() { return slides[0] ? slides[0].getBoundingClientRect().width : car.clientWidth; }
    function go(i, smooth) {
      idx = (i % n + n) % n;
      var w = slideW(); if (!w) return;
      programmatic = true;
      car.scrollTo({ left: idx * w, behavior: smooth ? 'smooth' : 'auto' });
      clearTimeout(progT);
      progT = setTimeout(function () { programmatic = false; }, 700);
    }

    car.addEventListener('scroll', function () {
      var w = slideW(); if (w) idx = Math.round(car.scrollLeft / w);
      if (programmatic) return;               // ignore our own auto-advance scrolling
      paused = true;                          // a real user swipe pauses auto-rotate
      clearTimeout(resumeT);
      resumeT = setTimeout(function () { paused = false; }, 2600);
    }, { passive: true });

    car._currentWord = function () { var s = slides[idx]; return s ? s.getAttribute('data-word') : ''; };

    setInterval(function () {
      if (paused) return;
      var scr = document.getElementById(screenId);
      if (!scr || !scr.classList.contains('open')) return;  // only rotate when visible
      if (!slideW()) return;
      go(idx + 1, true);
    }, 3800);
  }

  function ready() {
    initCarousel('wsCarousel', 'sub-word-search');
    initCarousel('msCarousel', 'sub-meaning-search');
  }
  if (document.readyState !== 'loading') ready();
  else document.addEventListener('DOMContentLoaded', ready);

  // Explore opens the chooser page (Words store vs Meaning store), NOT a search.
  function openExploreChoice() {
    if (typeof openSub === 'function') openSub('explore-choice');
  }
  window.wsExplore = openExploreChoice;
  window.msExplore = openExploreChoice;
})();

/* Features menu — traveling light that moves from one icon to the next, ONE at
   a time. A single interval lights the next .feat-ico (plays one CSS sweep),
   only while the menu is open, so it never burns cycles in the background. */
(function () {
  var idx = 0;
  setInterval(function () {
    var scr = document.getElementById('sub-features');
    if (!scr || !scr.classList.contains('open')) return;
    var icons = scr.querySelectorAll('.feat-ico');
    if (!icons.length) return;
    for (var k = 0; k < icons.length; k++) icons[k].classList.remove('feat-anim');
    var ic = icons[idx % icons.length];
    void ic.offsetWidth;            // restart the animation
    ic.classList.add('feat-anim');
    idx++;
  }, 1600);
})();

/* Swipe between Word Search and Meaning Search — swipe left on Word Search to
   go to Meaning Search, swipe right on Meaning Search to go back. Ignores
   swipes that start on the carousel / inputs so those keep working. */
(function () {
  // Switch DIRECTLY between the two search screens with no home flash: slide the
  // target in ON TOP (raised z-index) while the current one stays behind, then
  // drop the old one once the slide finishes.
  window.wsgSwitch = function (fromId, toId) {
    var from = document.getElementById('sub-' + fromId);
    var to = document.getElementById('sub-' + toId);
    if (!from || !to || to.classList.contains('open')) return;
    to.style.zIndex = '650';
    if (typeof openSub === 'function') openSub(toId); else to.classList.add('open');
    setTimeout(function () {
      from.classList.remove('open');
      to.style.zIndex = '';
    }, 440);
  };

  // Open a STORE from the Explore chooser and land inside it (no intro). The
  // store screens sit EARLIER in the DOM than the search screens, so without a
  // raised z-index the still-open search page paints over them (looked like it
  // "went back to search"). Raise the store, open it, skip its intro, then drop
  // the search + chooser screens behind it.
  window.wsgToStore = function (storeId, enterFn) {
    var store = document.getElementById('sub-' + storeId);
    if (!store) return;
    store.style.zIndex = '820';
    if (typeof closeSub === 'function') closeSub('explore-choice');
    if (typeof openSub === 'function') openSub(storeId); else store.classList.add('open');
    setTimeout(function () { if (typeof window[enterFn] === 'function') window[enterFn](); }, 340);
    setTimeout(function () {
      ['sub-word-search', 'sub-meaning-search', 'sub-explore-choice'].forEach(function (id) {
        var e = document.getElementById(id); if (e) e.classList.remove('open');
      });
      store.style.zIndex = '';
    }, 520);
  };

  function addSwipe(bodyId, fromId, toId, dir) {
    var el = document.getElementById(bodyId);
    if (!el) return;
    var x0 = null, y0 = null, skip = false;
    el.addEventListener('touchstart', function (e) {
      var t = e.touches[0]; x0 = t.clientX; y0 = t.clientY;
      skip = !!(e.target.closest && e.target.closest('.wsg-carousel, input, button, .wsg-search'));
    }, { passive: true });
    el.addEventListener('touchend', function (e) {
      if (x0 === null || skip) { x0 = null; return; }
      var t = e.changedTouches[0], dx = t.clientX - x0, dy = t.clientY - y0;
      x0 = null;
      if (Math.abs(dx) > 65 && Math.abs(dx) > Math.abs(dy) * 1.6) {
        if ((dir === 'left' && dx < 0) || (dir === 'right' && dx > 0)) window.wsgSwitch(fromId, toId);
      }
    }, { passive: true });
  }
  function init() {
    addSwipe('wsPageBody', 'word-search', 'meaning-search', 'left');
    addSwipe('msPageBody', 'meaning-search', 'word-search', 'right');
  }
  if (document.readyState !== 'loading') init();
  else document.addEventListener('DOMContentLoaded', init);
})();
