/* ══════════════════════════════════════════════════════════════════════
   THE PLAIN HERO — the greeting, the glass, and the rail

   The hero has three looks (app/js/part082.js): inside the television,
   full-screen behind the five photographs, or plain. This file is the
   third one's furniture, and it only exists while that look is chosen —
   turn the television back on and everything here is taken out again.

   Three parts:

     1. A greeting ABOVE the card, the way the Normal home opens: a light
        line that reads the clock and a heavy one with your name. It sits
        clear of the fixed header, which is what --home-header-h measures.

     2. The card itself is glass — the blur, the border and the highlight
        are in nowssb-nm.css. Behind it is either the Fashion Plus film or
        the home's own artwork, and both are worth seeing through.

     3. A rail inside it, where the five-photograph strip used to be. One
        banner at a time, each sliding in FROM THE RIGHT, playing ONCE, and
        handing over to the next as it ends. Four of them, and each is a
        door: the player, the Meaning store, the Word store and the Sound
        Library, every clip the one that page opens with.

   What it costs. Only the clip on screen has a src at all — the others
   are empty <video> elements until their turn — so nothing downloads
   ahead of being seen, and the one playing is the only one decoding. The
   whole rail stops when the home is not the screen you are on, when the
   app goes to the background, and when the look is switched away.
   ══════════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  /* Each banner is the clip its own page opens with, so the rail is a
     window onto the app rather than a set of adverts made for it. */
  var RAIL = [
    { k: 'player',
      t: 'The Player',      s: 'Your daily word ritual',
      v: './assets/video/practice-row.mp4',
      go: function () { if (typeof openPracticeIntro === 'function') openPracticeIntro(); } },
    { k: 'meaning',
      t: 'Meaning Store',   s: 'What a word truly means',
      v: './assets/video/fashion-hero-meaning-store.mp4',
      go: function () { if (typeof openSub === 'function') openSub('meaning-search'); } },
    { k: 'word',
      t: 'Word Store',      s: 'Where a word begins',
      v: './assets/video/fashion-hero-word-store.mp4',
      go: function () { if (typeof openSub === 'function') openSub('word-search'); } },
    { k: 'library',
      t: 'Sound Library',   s: 'Every word you own',
      v: './assets/video/sound-library-banner.mp4?v=1',
      go: function () { if (typeof openSub === 'function') openSub('sound-library'); } }
  ];

  /* Registered so the idle pre-warmer fetches them. Three of the four are
     only ever in the document one at a time — without this each would
     download the moment it was its turn, which is the one moment it must
     not. */
  window.NWSB_EXTRA_VIDEO_URLS = (window.NWSB_EXTRA_VIDEO_URLS || [])
    .concat(RAIL.map(function (r) { return r.v; }));

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#x27;');
  }
  function haptic(ms) { try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) {} }

  function hello() {
    var h = new Date().getHours();
    if (h < 5)  return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }
  /* The same name the rest of the app greets you by, asked for in the same
     order — a profile name if there is one, then the login name, then the
     brand, which is what a reader who has not told us anything sees. */
  function who() {
    var n = '';
    try {
      n = (window.nwsbUserName && window.nwsbUserName()) ||
          localStorage.getItem('nwsb_profile_name') ||
          localStorage.getItem('nwsb_user_name') || '';
    } catch (e) {}
    n = (n || '').trim();
    return n || 'NowssB';
  }

  /* ── The rail ─────────────────────────────────────────────────────── */
  var cur = 0, timer = null, running = false, shownAt = 0;
  /* No banner leaves before it has been readable. `ended` is the handover,
     but a clip that cannot decode — no codec, a source that fails — ends
     the instant it starts, and the rail would then flick through all four
     in half a second. Nothing moves on before this long, whatever the
     reason it finished. */
  var MIN_DWELL = 2600;

  function slides() { return document.querySelectorAll('#hsRail .hs-slide'); }

  function stop() {
    running = false;
    if (timer) { clearTimeout(timer); timer = null; }
    slides().forEach(function (sl) {
      var v = sl.querySelector('video');
      if (v && !v.paused) { try { v.pause(); } catch (e) {} }
    });
  }

  /* A clip is given its source only when it is about to be seen, and the
     NEXT one is given its source at the same time so it is decoded and
     ready to move rather than starting from nothing. */
  function arm(i) {
    var sl = slides()[i];
    if (!sl) return null;
    var v = sl.querySelector('video');
    if (!v) return null;
    if (!v.getAttribute('src')) {
      v.setAttribute('src', RAIL[i].v);
      v.preload = 'auto';
      try { v.load(); } catch (e) {}
    }
    return v;
  }

  function show(i, why) {
    var all = slides();
    if (!all.length) return;
    i = ((i % all.length) + all.length) % all.length;
    cur = i;
    all.forEach(function (sl, j) {
      /* `prev` leaves to the LEFT, everything unseen waits on the RIGHT —
         so the rail always travels one way and never rewinds past you. */
      sl.classList.toggle('on', j === i);
      sl.classList.toggle('out', j === (i - 1 + all.length) % all.length && why !== 'first');
      var v = sl.querySelector('video');
      if (v && j !== i && !v.paused) { try { v.pause(); } catch (e) {} }
    });
    var dots = document.querySelectorAll('#hsRail .hs-dots i');
    dots.forEach(function (d, j) { d.classList.toggle('on', j === i); });

    shownAt = Date.now();
    var v = arm(i);
    arm((i + 1) % all.length);          /* the next one, ready to move */
    if (!running || !v) return;
    try { v.currentTime = 0; } catch (e) {}
    var p = v.play();
    if (p && p.catch) p.catch(function () {});

    /* `ended` is the handover, and this is the net under it: a clip that
       never starts — no codec, autoplay refused, a source that 404s —
       would otherwise stop the rail dead on its first slide. */
    if (timer) clearTimeout(timer);
    var wait = 9000;
    if (v.duration && isFinite(v.duration) && v.duration > 0.4) wait = (v.duration * 1000) + 900;
    wait = Math.max(MIN_DWELL, Math.min(wait, 14000));
    timer = setTimeout(function () { if (running) show(cur + 1); }, wait);
  }

  function start() {
    if (running) return;
    running = true;
    show(cur, 'first');
  }

  window._hsGo = function (i) {
    var r = RAIL[i];
    if (!r) return;
    haptic(18);
    try { r.go(); } catch (e) {}
  };
  window._hsDot = function (i) { haptic(12); show(i); };

  function railHtml() {
    return '<div class="hs-rail" id="hsRail">' +
        '<div class="hs-track">' +
          RAIL.map(function (r, i) {
            /* the first one is on from the moment the rail is built, so the
               box is never a blank rectangle waiting for a frame */
            return '<button class="hs-slide' + (i === 0 ? ' on' : '') + '" data-i="' + i + '" onclick="window._hsGo(' + i + ')" ' +
                     'aria-label="' + esc(r.t) + ' — ' + esc(r.s) + '">' +
                     /* data-nwsb-vis: the app's global video controller
                        (app/js/part051.js) skips anything already marked,
                        and this rail must not be one of its up-to-N
                        players — three of these four are off to the right
                        at any moment and it would start them there. The
                        rail decides what runs. */
                     '<video class="hs-vid" muted playsinline preload="none" ' +
                            'data-nwsb-vis="1" aria-hidden="true" tabindex="-1"></video>' +
                     '<span class="hs-shade"></span>' +
                     '<span class="hs-cap">' +
                       '<span class="hs-cap-t">' + esc(r.t) + '</span>' +
                       '<span class="hs-cap-s">' + esc(r.s) + '</span>' +
                     '</span>' +
                     '<span class="hs-open">' +
                       '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" ' +
                       'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
                       '<path d="M5 12h13M12 5l7 7-7 7"/></svg>' +
                     '</span>' +
                   '</button>';
          }).join('') +
        '</div>' +
        '<div class="hs-dots">' +
          RAIL.map(function (r, i) {
            return '<i class="' + (i === 0 ? 'on' : '') + '" onclick="window._hsDot(' + i + ')"></i>';
          }).join('') +
        '</div>' +
      '</div>';
  }

  /* ── Putting it in and taking it out ──────────────────────────────── */
  function build(hero) {
    if (!hero) return;
    var home = hero.parentNode;
    if (!home) return;

    /* the greeting, immediately before the card */
    var g = document.getElementById('hsGreet');
    if (!g) {
      g = document.createElement('div');
      g.id = 'hsGreet';
      g.className = 'hs-greet';
      g.innerHTML = '<div class="hs-hello"></div><div class="hs-name"></div>';
      home.insertBefore(g, hero);
    }
    g.querySelector('.hs-hello').textContent = hello() + ',';
    g.querySelector('.hs-name').textContent = who();

    /* the rail, where the five photographs used to be */
    if (!document.getElementById('hsRail')) {
      var bottom = hero.querySelector('.hero-bottom');
      var glass = hero.querySelector('.hero-glass');
      if (bottom) {
        var box = document.createElement('div');
        box.innerHTML = railHtml();
        var rail = box.firstChild;
        if (glass && glass.parentNode === bottom) bottom.insertBefore(rail, glass);
        else bottom.insertBefore(rail, bottom.firstChild);
      }
    }
    cur = 0;
  }

  function tearDown() {
    stop();
    var g = document.getElementById('hsGreet');
    if (g) g.remove();
    var r = document.getElementById('hsRail');
    if (r) {
      /* let go of the clips rather than leaving four decoders parked
         behind a look nobody is using */
      r.querySelectorAll('video').forEach(function (v) {
        try { v.pause(); v.removeAttribute('src'); v.load(); } catch (e) {}
      });
      r.remove();
    }
  }

  /* Called by app/js/part082.js every time the hero's look is applied, so
     there is one owner of which look is on and this file only answers. */
  window.nwsbPlainHero = function (on) {
    var hero = document.querySelector('#home .hero-section');
    if (!hero) return;
    if (!on) { tearDown(); return; }
    build(hero);
    pump();
  };

  /* ── When it is allowed to run ────────────────────────────────────── */
  function visible() {
    if (document.hidden) return false;
    var hero = document.querySelector('#home .hero-section.hero-simple');
    if (!hero) return false;
    var home = document.getElementById('home');
    if (!home || !home.classList.contains('active')) return false;
    /* a sub-screen over the top means nobody is looking at this */
    if (document.querySelector('.sub-screen.open')) return false;
    var r = hero.getBoundingClientRect();
    return r.bottom > 0 && r.top < (window.innerHeight || 800);
  }
  var pending = false;
  function pump() {
    if (pending) return;
    pending = true;
    requestAnimationFrame(function () {
      pending = false;
      if (!document.getElementById('hsRail')) return;
      if (visible()) start(); else stop();
    });
  }
  window._hsPump = pump;

  document.addEventListener('visibilitychange', pump);
  window.addEventListener('scroll', pump, { passive: true });
  document.addEventListener('scroll', pump, { passive: true, capture: true });
  /* A heartbeat as well as the events, because the things that decide
     whether this should be running — the home becoming the active screen,
     a page closing over it — do not all announce themselves. It reads a
     class and a rectangle; it is cheaper than being wrong. */
  setInterval(function () { if (document.getElementById('hsRail')) pump(); }, 1200);

  /* The clip that ends is the one that hands over. Delegated, because the
     rail is built and thrown away as the look is switched. */
  document.addEventListener('ended', function (e) {
    var sl = e.target && e.target.closest ? e.target.closest('.hs-slide') : null;
    if (!sl || !running) return;
    if (!sl.classList.contains('on')) return;
    var left = MIN_DWELL - (Date.now() - shownAt);
    if (left > 0) {
      if (timer) clearTimeout(timer);
      timer = setTimeout(function () { if (running) show(cur + 1); }, left);
      return;
    }
    show(cur + 1);
  }, true);

  /* ── First run ────────────────────────────────────────────────────
     part082.js applies the look the moment it parses, and this file is
     loaded after it — so at that moment nwsbPlainHero did not exist yet
     and the call was skipped. It applies itself once here, retrying while
     the home is still being parsed, and from then on part082 drives it. */
  (function boot(n) {
    var hero = document.querySelector('#home .hero-section');
    if (hero && typeof window.heroStyle === 'function') {
      try { window.nwsbPlainHero(window.heroStyle() === 'plain'); } catch (e) {}
      return;
    }
    if (n > 60) return;
    setTimeout(function () { boot(n + 1); }, 150);
  })(0);

  /* The greeting reads the clock, so it is re-read when the app comes back
     — someone who left it open overnight should not still be told good
     evening in the morning. */
  setInterval(function () {
    var g = document.getElementById('hsGreet');
    if (!g) return;
    g.querySelector('.hs-hello').textContent = hello() + ',';
    g.querySelector('.hs-name').textContent = who();
  }, 120000);
})();
