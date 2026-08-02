/* ══════════════════════════════════════════════════════════
   FASHION PLUS — the switch that makes the still pages move.

   What it does, exactly: the app's photographic backgrounds are replaced
   by one looping clip. Nothing else. Not the layout, not the theme, not
   the tiles — the mode has one job and this file keeps it to that job.

   How it gets there
   -----------------
   One video element, #fpBgVideo, fixed behind everything, in the same
   place .app-bg sits. Turning the mode on shows it and fades .app-bg out,
   which covers every top-level screen at once (home, login, onboarding,
   analysis) because they all share that one background layer.

   Sub-screens are the awkward half. Each is `position:fixed;
   background:#060c18` at z-index 600, so it hides the fixed clip
   completely. A page can only show the clip if it is made transparent —
   and making ALL of them transparent would put the clip behind pages that
   were never photographic, which is not what was asked for. So
   markImageBacked() walks the sub-screens once, finds the ones whose own
   .sub-screen-bg is actually carrying a background image, and tags those
   with data-fp-img. The CSS opens up exactly the tagged ones.

   That is also what keeps the promise about video: a page already running
   its own clip has no photographic background layer to find, so it is
   never tagged and never touched.

   The cost
   --------
   A decoding video is the most expensive thing a phone can be asked to do
   in the background, which is why the page carries a warning and why this
   file spends most of its length being careful: the clip pauses when the
   app is not visible, pauses below 15% battery unless charging, and never
   starts at all when the phone asks for reduced motion.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var KEY = 'nwsb_fashion_plus';
  var VID = './assets/video/fashion-plus-bg.mp4';

  /* The wallpapers that move through the phone on the page. These are the
     app's own photographs — the same files the still backgrounds use — so
     the demonstration is literally what the mode replaces. */
  var WALLS = [
    'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto,w_900/v1777584943/grok_image_1777580530017_nftrrb.jpg',
    'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto,w_900/v1777591568/grok_image_1777591433417_rx2whb.jpg',
    'https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto,w_900/v1778309102/grok_image_1778309033334_fza02n.jpg',
    'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto,w_900/v1777615898/grok_image_1777615621529_xdxfj6.jpg',
    'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto,w_900/v1777616006/grok_image_1777615631154_yddgyh.jpg'
  ];
  /* One line per wallpaper for the glass card, so the widget changes with
     the picture the way the real lockscreen does. */
  var LINES = [
    ['Instant Style Check', 'Get quick style tips'],
    ['Find Matching Looks', 'Spot it, snap it, shop it'],
    ['Featured Picks',      'Curated for you, today only'],
    ['Rate My Look',        'Ask the room before you leave'],
    ['Tonight’s Fit',  'Built around what you own']
  ];

  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  function isOn() { return ls(KEY, '0') === '1'; }
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
    /* Behind everything: .app-bg is the first child of body and z-index 0,
       and this sits with it. */
    document.body.insertBefore(v, document.body.firstChild);
    return v;
  }

  /* ── Which pages were wearing a photograph ────────────────────────
     Read once and cached on the element, because getComputedStyle over
     every sub-screen is not something to repeat on each toggle. A page
     qualifies only if its own background layer has a real image URL. */
  function markImageBacked() {
    var subs = document.querySelectorAll('.sub-screen');
    var n = 0;
    for (var i = 0; i < subs.length; i++) {
      var s = subs[i];
      if (s.id === 'sub-fashion-plus') continue;     // this page runs its own clip

      /* Already decided. This is not an optimisation, it is required: the
         CSS answer to being tagged is `background-image: none` on that very
         layer, so re-reading a tagged page would find no image and untag
         it — the tag would erase its own evidence and flicker off on the
         next pass. Positives are therefore permanent; only pages that have
         never qualified get looked at again. */
      if (s.hasAttribute('data-fp-img')) { n++; continue; }

      /* A page that already has a moving background keeps it. That means a
         video sitting where the background sits — inside the background
         layer, or a direct child of the page behind its content — not a
         clip inside a card further down, which is content, not background. */
      if (s.querySelector(':scope > video, :scope > .sub-screen-bg video')) continue;

      /* The rest are re-read on each pass, because several of these layers
         are filled by their own page's code the first time it opens
         (rmBg, msBg, ebBg…) and have no image at all before that. */
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
     The warning on the page is not decoration, so the mode acts on it:
     under 15% and off the charger the clip stops until it is plugged in.
     navigator.getBattery is absent on iOS and on desktop Firefox, in which
     case there is nothing to check and the clip simply runs. */
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

  function apply() {
    var on = isOn() && !reducedMotion();
    document.body.classList.toggle('fashion-plus', on);
    if (on) { bgVideo(true); markImageBacked(); }
    playState();
  }

  /* ── The page ─────────────────────────────────────────────────────── */
  function paint() {
    var sw = document.getElementById('fpSwitch');
    var line = document.getElementById('fpStateLine');
    var note = document.getElementById('fpNote');
    var sub = document.getElementById('fpEntrySub');
    var on = isOn();
    if (sw) sw.classList.toggle('on', on);
    if (line) {
      line.textContent = on
        ? 'On — photographic backgrounds are playing'
        : 'Off — pages keep their photographs';
    }
    if (sub) {
      sub.textContent = on
        ? 'On · still photographs are playing as film'
        : 'Still photographs become film · uses more battery';
    }
    if (note) {
      var msg = '';
      if (reducedMotion()) {
        msg = 'Your phone is set to reduce motion, so Fashion Plus is staying off ' +
              'whatever this switch says. Turn Reduce Motion off in your phone’s ' +
              'accessibility settings to use it.';
      } else if (on && batteryLow) {
        msg = 'Paused — your battery is under 15% and you are not charging. ' +
              'It will start again when you plug in.';
      } else if (on) {
        msg = 'Running. If the app feels slow or the phone gets warm, turn this back off.';
      }
      note.textContent = msg;
      note.classList.toggle('show', !!msg);
    }
  }

  /* ── The phone on the page ─────────────────────────────────────────
     The frame never moves. Only the two wallpaper layers cross-fade, the
     side phones follow one step behind and ahead, and the glass card takes
     the line that belongs to the picture. */
  var idx = 0, spin = null, useA = true;

  function shift(step) {
    var A = document.getElementById('fpWallA'), B = document.getElementById('fpWallB');
    if (!A || !B) return;
    idx = ((idx + step) % WALLS.length + WALLS.length) % WALLS.length;
    var next = useA ? B : A, cur = useA ? A : B;
    next.style.backgroundImage = 'url("' + WALLS[idx] + '")';
    next.classList.add('on'); cur.classList.remove('on');
    useA = !useA;

    var L = document.getElementById('fpSideL'), R = document.getElementById('fpSideR');
    if (L) L.style.backgroundImage = 'url("' + WALLS[(idx - 1 + WALLS.length) % WALLS.length] + '")';
    if (R) R.style.backgroundImage = 'url("' + WALLS[(idx + 1) % WALLS.length] + '")';

    var h = document.getElementById('fpGlassHead'), s = document.getElementById('fpGlassSub'),
        t = document.getElementById('fpGlassThumb');
    if (h) h.textContent = LINES[idx][0];
    if (s) s.textContent = LINES[idx][1];
    if (t) t.style.backgroundImage = 'url("' + WALLS[(idx + 2) % WALLS.length] + '")';
  }

  function startStage() {
    var A = document.getElementById('fpWallA');
    if (!A) return;
    if (!A.style.backgroundImage) { idx = -1; useA = false; shift(1); }
    stopStage();
    if (reducedMotion()) return;
    spin = setInterval(function () { shift(1); }, 3200);
  }
  function stopStage() { if (spin) { clearInterval(spin); spin = null; } }

  /* ── Doors ────────────────────────────────────────────────────────── */
  window.fpOpen = function () {
    var s = document.getElementById('sub-fashion-plus');
    if (!s) return;
    s.classList.add('open');
    paint(); startStage();
    var v = document.getElementById('fpPageVid');
    if (v && !reducedMotion()) { v.muted = true; v.play().catch(function () {}); }
  };
  window.fpClose = function () {
    var s = document.getElementById('sub-fashion-plus');
    if (s) s.classList.remove('open');
    stopStage();
    var v = document.getElementById('fpPageVid');
    if (v) { try { v.pause(); } catch (e) {} }
  };
  function flip() {
    lsSet(KEY, isOn() ? '0' : '1');
    apply(); paint();
  }

  /* Turning it OFF is instant — nobody needs a warning to stop spending
     battery. Turning it ON goes through the caution first, full screen,
     because that is the only moment the warning is actually relevant. */
  function caution(actions) {
    window.nwsbSheet({
      art: './assets/fashion/caution-art.webp',
      head: 'This will cost you battery',
      sub: 'Fashion Plus keeps video decoding while you use the app',
      body:
        '<p>On a phone with a powerful processor it is smooth and it is the best the app looks. ' +
        'On a slower one it can stutter, warm up, or hang.</p>' +
        '<p><b>Only turn this on if your phone can carry it.</b> If anything feels heavy, ' +
        'come back and switch it off — nothing else in the app changes when you do.</p>' +
        '<div class="nwsb-fs-keys">' +
          '<span class="nwsb-fs-key">Higher battery use</span>' +
          '<span class="nwsb-fs-key">More heat</span>' +
          '<span class="nwsb-fs-key">More data on first play</span>' +
        '</div>' +
        '<div class="nwsb-fs-rule"></div>' +
        '<p class="nwsb-fs-note">It pauses itself when the app is not in front of you, and again ' +
        'below 15% battery unless you are charging. Seven things change when it is on — they are ' +
        'listed on the page behind this.</p>',
      actions: actions
    });
  }

  function toList() {
    var b = document.getElementById('fpBody'), l = document.querySelector('.fp-list-head');
    if (b && l) b.scrollTop = l.offsetTop - 70;
  }

  /* Turning it OFF is instant — nobody needs a warning to stop spending
     battery. Turning it ON goes through the caution first, full screen,
     because that is the only moment the warning is actually relevant. */
  window.fpToggle = function () {
    if (reducedMotion()) { paint(); return; }   // the note explains why
    if (isOn()) { flip(); return; }
    if (typeof window.nwsbSheet !== 'function') { flip(); return; }
    caution([
      { label: 'Turn It On', go: flip },
      { label: 'What Changes', ghost: true, go: toList }
    ]);
  };

  /* The card on the page opens the same sheet with nothing to agree to. */
  window.fpCaution = function () {
    if (typeof window.nwsbSheet !== 'function') return;
    caution([{ label: 'Got It', go: function () {} },
             { label: 'What Changes', ghost: true, go: toList }]);
  };
  window.fpIsOn = isOn;
  window.fpApply = apply;

  /* ── Boot ─────────────────────────────────────────────────────────── */
  function boot() {
    apply(); paint(); watchBattery();
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
    setTimeout(function () { if (isOn()) markImageBacked(); }, 1500);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
