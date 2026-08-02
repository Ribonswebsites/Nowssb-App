/* ══════════════════════════════════════════════════════════
   FASHION PLUS, PART TWO — the backgrounds, the phone, the caution.

   Fashion Plus is app/js/part066.js. That file owns the mode: the key
   (nwsb_fashplus), the body class (fashplus), fpToggle, and the motion it
   already put on the Fashion home — the four tiles, Today's Practice, the
   routines clip. Nothing here owns a switch. This file adds three things
   to the mode it already has:

     1. the backgrounds — every page wearing a photograph wears the film
     2. the phone in the Fashion Plus section, which is the mode explaining
        itself: a frame that never moves and a picture that does
     3. the caution, full screen, in front of anyone about to turn it on

   part066.js calls nwsbFpBackgrounds(on) from its apply(), so there is one
   key, one class and one toggle no matter which of the three switches is
   tapped (the section's, the banner below the player, the Customize card).

   The backgrounds
   ---------------
   One video element, #fpBgVideo, fixed behind everything where .app-bg
   sits. Turning the mode on shows it and fades .app-bg out, which covers
   every top-level screen at once because they share that one layer.

   Sub-screens are the awkward half: each is position:fixed,
   background:#060c18, z-index 600, so it hides the fixed clip completely.
   A page can only show it if it is made transparent — and making all of
   them transparent would put film behind pages that were never
   photographic. markImageBacked() finds the ones whose own .sub-screen-bg
   is actually carrying an image and tags those. A page already running its
   own clip has no such layer, so it is never tagged and never touched.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var VID = './assets/video/fashion-plus-bg.mp4';

  /* What moves through the phone: the app's OWN background photographs —
     the exact files setBg() puts behind the login, the signup, onboarding,
     the analysis and the home — and then the clip. That is the whole mode
     in one loop: these are the stills it replaces, and that is what it
     replaces them with. A demo made of anything else would be a lie about
     what the switch does. */
  var CDN = 'https://res.cloudinary.com/';
  var WALLS = [
    { img: CDN + 'dfc8lwj22/image/upload/q_auto/f_auto,w_900/v1777584943/grok_image_1777580530017_nftrrb.jpg', t: ['Sign In', 'The background you meet first'] },
    { img: CDN + 'dfc8lwj22/image/upload/q_auto/f_auto,w_900/v1777591568/grok_image_1777591433417_rx2whb.jpg', t: ['Create Account', 'Still, today'] },
    { img: CDN + 'ds6duqabl/image/upload/q_auto/f_auto,w_900/v1779804089/3cca01a0-590b-11f1-8540-43cf58c6068c_ke31me.png', t: ['Onboarding', 'One photograph per screen'] },
    { img: CDN + 'dfc8lwj22/image/upload/q_auto/f_auto,w_900/v1777615898/grok_image_1777615621529_xdxfj6.jpg', t: ['Your Answers', 'Still, today'] },
    { img: CDN + 'dkzxw33ln/image/upload/q_auto/f_auto,w_900/v1776850607/1000033084-ezremove_ybzuzs.png', t: ['Analysis', 'Still, today'] },
    { img: CDN + 'dkzxw33ln/image/upload/q_auto/f_auto,w_900/v1776850550/1000033096-ezremove_eb2gnu.png', t: ['Your Home', 'Still, today'] },
    /* The one that moves. Last in the loop on purpose — five stills, then
       the answer. */
    { vid: VID, t: ['Fashion Plus', 'This, behind all of them'] }
  ];

  function isOn() { return typeof window.fpOn === 'function' ? window.fpOn() : false; }
  function reducedMotion() {
    try { return window.matchMedia('(prefers-reduced-motion: reduce)').matches; } catch (e) { return false; }
  }

  /* ── The one fixed video ──────────────────────────────────────────
     Created on first use rather than sitting in the HTML, so a reader who
     never turns the mode on never downloads a frame of it. */
  function bgVideo(make) {
    var v = document.getElementById('fpBgVideo');
    if (v || !make) return v;
    v = document.createElement('video');
    v.id = 'fpBgVideo';
    v.muted = true; v.loop = true; v.playsInline = true;
    v.setAttribute('muted', ''); v.setAttribute('loop', '');
    v.setAttribute('playsinline', ''); v.setAttribute('preload', 'auto');
    v.src = VID;
    document.body.insertBefore(v, document.body.firstChild);
    return v;
  }

  function markImageBacked() {
    var subs = document.querySelectorAll('.sub-screen');
    var n = 0;
    for (var i = 0; i < subs.length; i++) {
      var s = subs[i];

      /* Already decided. This is not an optimisation, it is required: the
         CSS answer to being tagged is `background-image: none` on that very
         layer, so re-reading a tagged page would find no image and untag
         it — the tag would erase its own evidence. Positives are therefore
         permanent; only pages that have never qualified are looked at again. */
      if (s.hasAttribute('data-fp-img')) { n++; continue; }

      /* A page that already has a moving background keeps it: a video where
         the background sits, not a clip inside a card further down. */
      if (s.querySelector(':scope > video, :scope > .sub-screen-bg video')) continue;

      /* Re-read each pass, because several of these layers are filled by
         their own page's code the first time it opens (rmBg, msBg, ebBg…)
         and hold no image at all before that. */
      var layers = s.querySelectorAll('.sub-screen-bg');
      var hit = null;
      for (var j = 0; j < layers.length; j++) {
        var bg = '';
        try { bg = getComputedStyle(layers[j]).backgroundImage || ''; } catch (e) {}
        if (bg && bg !== 'none' && bg.indexOf('url(') === 0) { hit = layers[j]; break; }
      }
      if (hit) {
        s.setAttribute('data-fp-img', '1');
        hit.setAttribute('data-fp-img', '1');
        n++;
      }
    }
    return n;
  }
  window.nwsbFpMark = markImageBacked;

  /* ── Battery ──────────────────────────────────────────────────────
     The warning is not decoration, so the mode acts on it: under 15% and
     off the charger the clip stops until it is plugged in. getBattery is
     absent on iOS and desktop Firefox, where there is nothing to check. */
  var batteryLow = false;
  function watchBattery() {
    if (!navigator.getBattery) return;
    navigator.getBattery().then(function (b) {
      function read() {
        var low = !b.charging && b.level <= 0.15;
        if (low !== batteryLow) { batteryLow = low; playState(); paint(); }
      }
      b.addEventListener('levelchange', read);
      b.addEventListener('chargingchange', read);
      read();
    }).catch(function () {});
  }

  /* Play only when it can be seen and can be afforded. */
  function playState() {
    var v = bgVideo(false);
    if (!v) return;
    var want = isOn() && !reducedMotion() && !batteryLow &&
               document.visibilityState === 'visible';
    if (want) { v.play().catch(function () {}); }
    else { try { v.pause(); } catch (e) {} }
  }

  /* Called by part066.js's apply(), which is the single source of truth. */
  window.nwsbFpBackgrounds = function (on) {
    if (on && !reducedMotion()) { bgVideo(true); markImageBacked(); }
    playState();
  };

  /* ── The section's own copy ───────────────────────────────────────── */
  function paint() {
    var on = isOn();
    /* The switch, the state line and the note exist twice — once in the
       section on the home and once on the page behind its Enter — so these
       are classes rather than ids and every copy is painted. */
    document.querySelectorAll('.fp-switch').forEach(function (sw) {
      sw.classList.toggle('on', on);
    });
    document.querySelectorAll('.fp-state-line').forEach(function (line) {
      line.textContent = on
        ? 'On — the tiles, the practice card and every photo background are playing'
        : 'Off — pages keep their photographs';
    });
    document.querySelectorAll('.fp-note').forEach(function (note) {
      var msg = '';
      if (reducedMotion()) {
        msg = 'Your phone is set to reduce motion, so the backgrounds stay still ' +
              'whatever this switch says. Turn Reduce Motion off in your phone’s ' +
              'accessibility settings to see them.';
      } else if (on && batteryLow) {
        msg = 'Backgrounds paused — your battery is under 15% and you are not charging. ' +
              'They start again when you plug in.';
      } else if (on) {
        msg = 'Running. If the app feels slow or the phone gets warm, turn this back off.';
      }
      note.textContent = msg;
      note.classList.toggle('show', !!msg);
    });
  }
  window.nwsbFpPaint = paint;

  /* ── The phone ────────────────────────────────────────────────────
     The frame never moves. Only the two wallpaper layers cross-fade, the
     side phones follow one step behind and ahead, and the glass card takes
     the line that belongs to the picture. It runs whether the mode is on
     or off, because it is the argument for turning it on. */
  var idx = 0, spin = null, useA = true;

  function shift(step) {
    var A = document.getElementById('fpWallA'), B = document.getElementById('fpWallB'),
        V = document.getElementById('fpWallVid');
    if (!A || !B) return;
    idx = ((idx + step) % WALLS.length + WALLS.length) % WALLS.length;
    var w = WALLS[idx];

    /* The clip is its own layer rather than a background-image, so the
       cross-fade is the same fade either way and nothing has to be told
       which kind of slide is arriving. */
    if (V) {
      var showVid = !!w.vid;
      if (showVid && V.getAttribute('src') !== w.vid) V.setAttribute('src', w.vid);
      V.classList.toggle('on', showVid);
      if (showVid) { V.muted = true; V.play().catch(function () {}); }
      else { try { V.pause(); } catch (e) {} }
    }

    var next = useA ? B : A, cur = useA ? A : B;
    if (w.img) {
      next.style.backgroundImage = 'url("' + w.img + '")';
      next.classList.add('on'); cur.classList.remove('on');
      useA = !useA;
    } else {
      /* A video slide: fade both stills out and let the clip stand alone. */
      A.classList.remove('on'); B.classList.remove('on');
    }

    function side(el, k) {
      if (!el) return;
      var s2 = WALLS[((idx + k) % WALLS.length + WALLS.length) % WALLS.length];
      el.style.backgroundImage = 'url("' + (s2.img || WALLS[0].img) + '")';
    }
    side(document.getElementById('fpSideL'), -1);
    side(document.getElementById('fpSideR'), 1);

    var h = document.getElementById('fpGlassHead'), sb = document.getElementById('fpGlassSub'),
        t = document.getElementById('fpGlassThumb');
    if (h) h.textContent = w.t[0];
    if (sb) sb.textContent = w.t[1];
    if (t) {
      var nx = WALLS[(idx + 2) % WALLS.length];
      t.style.backgroundImage = 'url("' + (nx.img || WALLS[0].img) + '")';
    }
  }

  /* Only while the section is actually on screen — a cross-fade nobody can
     see is the exact cost this mode is warning people about. */
  function watchStage() {
    var stage = document.getElementById('fpStage');
    if (!stage) return;
    if (!document.getElementById('fpWallA').style.backgroundImage) {
      idx = -1; useA = false; shift(1);
    }
    if (reducedMotion() || !window.IntersectionObserver) return;
    new IntersectionObserver(function (es) {
      var vis = es[0] && es[0].isIntersecting;
      if (vis && !spin) spin = setInterval(function () { shift(1); }, 3200);
      else if (!vis && spin) { clearInterval(spin); spin = null; }
    }, { threshold: 0.25 }).observe(stage);
  }

  /* ── The caution, full screen ─────────────────────────────────────
     Everything the mode does and everything it costs, in one sheet. It is
     the page that used to exist, in front of the decision instead of
     behind it. `gate` is true when it was opened by the switch, in which
     case the primary button is the one that turns it on. */
  var CHANGES = [
    ['The four home tiles start moving', 'Sound Library, My Progress, Word Science and Profile play their own clips instead of showing a still.'],
    ['Today’s Practice becomes a film', 'The card gets a clip behind it, its Enter pill moves to the right edge, and the routines banner runs above it.'],
    ['The app background becomes the film', 'Home, login, onboarding, analysis — every screen whose background is a still photograph plays the clip instead.'],
    ['Photo-backed pages move too', 'The inside pages carrying a photograph — My Progress, Word Science, Health, the Signature — take the same clip.'],
    ['Pages already running video are untouched', 'The Word Atelier, the Meaning Store and every section with its own clip keep exactly what they have. Nothing is replaced twice.'],
    ['It stops when you are not looking', 'Everything pauses the moment the app goes to the background or the screen locks, and starts again when you come back.'],
    ['It gets out of the way on low battery', 'Below 15% and not charging, the backgrounds pause themselves until you plug in — and Reduce Motion keeps them still however this switch is set.']
  ];

  /* ── The page behind the section's Enter ──────────────────────────
     Intro first, then the body — the same two-step every shop in the app
     uses. The list is built from the same CHANGES table the caution sheet
     uses, so the two can never drift apart. */
  function fillList() {
    var host = document.getElementById('fpPageList');
    if (!host || host.children.length) return;
    host.innerHTML = CHANGES.map(function (c, i) {
      return '<div class="fp-item"><span class="fp-item-n">' + (i + 1) + '</span><div>' +
               '<div class="fp-item-t">' + c[0] + '</div>' +
               '<div class="fp-item-s">' + c[1] + '</div></div></div>';
    }).join('');
  }

  window.fpOpenPage = function () {
    var sc = document.getElementById('sub-fashion-plus');
    if (!sc) return;
    fillList(); paint();
    var intro = document.getElementById('fppIntro');
    if (intro) { intro.style.display = ''; intro.style.opacity = ''; intro.style.pointerEvents = ''; }
    sc.classList.add('open');
  };
  window.fpEnterPage = function () {
    var intro = document.getElementById('fppIntro');
    if (intro) {
      intro.style.opacity = '0'; intro.style.pointerEvents = 'none';
      setTimeout(function () { intro.style.display = 'none'; }, 460);
    }
    var v = document.getElementById('fpPageVid');
    if (v && !reducedMotion()) { v.muted = true; v.play().catch(function () {}); }
  };
  window.fpClosePage = function () {
    var sc = document.getElementById('sub-fashion-plus');
    if (sc) sc.classList.remove('open');
    var v = document.getElementById('fpPageVid');
    if (v) { try { v.pause(); } catch (e) {} }
  };

  window.fpCaution = function (gate) {
    if (typeof window.nwsbSheet !== 'function') {
      if (gate && typeof window.fpFlip === 'function') window.fpFlip();
      return;
    }
    var list = CHANGES.map(function (c, i) {
      return '<div class="fp-item"><span class="fp-item-n">' + (i + 1) + '</span><div>' +
               '<div class="fp-item-t">' + c[0] + '</div>' +
               '<div class="fp-item-s">' + c[1] + '</div></div></div>';
    }).join('');

    window.nwsbSheet({
      art: './assets/fashion/caution-art.webp',
      head: 'This will cost you battery',
      sub: 'Fashion Plus keeps video decoding while you use the app',
      body:
        '<p>On a phone with a powerful processor it is smooth, and it is the best the app looks. ' +
        'On a slower one it can stutter, warm up, or hang.</p>' +
        '<p><b>Only turn this on if your phone can carry it.</b> If anything feels heavy, ' +
        'come back and switch it off — nothing else in the app changes when you do.</p>' +
        '<div class="nwsb-fs-keys">' +
          '<span class="nwsb-fs-key">Higher battery use</span>' +
          '<span class="nwsb-fs-key">More heat</span>' +
          '<span class="nwsb-fs-key">More data on first play</span>' +
        '</div>' +
        '<div class="nwsb-fs-h">What changes when it is on</div>' +
        '<div class="fp-list">' + list + '</div>' +
        '<div class="nwsb-fs-rule"></div>' +
        '<p class="nwsb-fs-note">Your layout, your theme, your tiles, your words and every setting ' +
        'stay exactly as you left them. This switch only changes what is behind them.</p>',
      actions: gate
        ? [{ label: 'Turn It On', go: function () { if (window.fpFlip) window.fpFlip(); } },
           { label: 'Not Now', ghost: true, go: function () {} }]
        : [{ label: 'Got It', go: function () {} }]
    });
  };

  function boot() {
    paint(); watchStage(); watchBattery();
    document.addEventListener('visibilitychange', playState);

    /* A page whose background layer is filled in by its own code only
       becomes recognisable once it has been opened, so the scan is redone
       on every open rather than once at boot. */
    var prevOpen = window.openSub;
    if (typeof prevOpen === 'function') {
      window.openSub = function () {
        var r = prevOpen.apply(this, arguments);
        if (isOn()) { try { markImageBacked(); } catch (e) {} }
        return r;
      };
    }
    /* part066.js boots first and has already called apply() by now, before
       this file existed to answer it — so catch up once. */
    if (typeof window.fpApply === 'function') { try { window.fpApply(); } catch (e) {} }
    setTimeout(function () { if (isOn()) markImageBacked(); }, 1500);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
