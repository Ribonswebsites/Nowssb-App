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

  var VID = './assets/video/fashion-plus-bg-6.mp4';

  /* What moves through the phone.

     OFF — the app's intro artwork, which is what those pages are wearing
     right now: the Store, the Word Atelier, the Meaning Store, the eBooks,
     the Signature and this page's own.

     ON — the clips. One today; this is a list so adding the next one is a
     line, not a rewrite, and the phone starts showing it the moment it is
     here. That is the whole demonstration: the same phone, the same frame,
     stills before the switch and film after it.

     Both lists are walked by the same code, so they can never fall out of
     step with each other. */
  var STILLS = [
    { img: './assets/store/intro-store.webp',     t: ['The NowssB Store', 'Still, today'] },
    { img: './assets/store/intro-words.webp',     t: ['The Word Atelier', 'Still, today'] },
    { img: './assets/store/intro-meanings.webp',  t: ['The Meaning Store', 'Still, today'] },
    { img: './assets/store/intro-ebooks.webp',    t: ['NowssB eBooks', 'Still, today'] },
    { img: './assets/store/intro-signature.webp', t: ['The Signature', 'Still, today'] },
    { img: './assets/fashion/fp-intro.webp',      t: ['Fashion Plus', 'Still, today'] }
  ];
  /* These are the only two backgrounds available in Fashion Plus. */
  var FILMS = [
    { vid: './assets/video/fashion-plus-bg-5.mp4', name: 'Falling Diamonds' },
    { vid: './assets/video/fashion-plus-bg-6.mp4', name: 'Violet Silk' }
  ];
  /* What a first-time reader gets. Not index 0 — Violet Silk is the one
     that should introduce the mode, and it is one of the two encoded for
     it. Kept as a name rather than a number so it survives the list
     changing again. */
  var BG_DEFAULT = (function () {
    for (var i = 0; i < FILMS.length; i++) if (FILMS[i].name === 'Violet Silk') return i;
    return 0;
  })();
  FILMS.forEach(function (f, i) {
    f.t = [f.name, 'Background ' + (i + 1) + ' of ' + FILMS.length];
  });
  /* Registered so the idle prefetcher can warm them; only the chosen one is
     ever in the document, so without this each would download the moment
     it was swiped to. */
  window.NWSB_EXTRA_VIDEO_URLS = (window.NWSB_EXTRA_VIDEO_URLS || [])
    .concat(FILMS.map(function (f) { return f.vid; }));

  /* Which one is the app's background. The phone is the picker: whatever
     film you swipe to becomes the choice, so there is no separate Apply to
     forget to press. */
  var BGKEY = 'nwsb_fp_bgvid_v2';
  // Do not reinterpret a selection saved for the removed background set.
  try { localStorage.removeItem('nwsb_fp_bgvid'); } catch (e) {}
  function bgChoice() {
    var raw = null;
    try { raw = localStorage.getItem(BGKEY); } catch (e) {}
    if (raw === null || raw === '') return BG_DEFAULT;   // never chosen
    var i = parseInt(raw, 10);
    return (isFinite(i) && i >= 0 && i < FILMS.length) ? i : BG_DEFAULT;
  }
  function syncFashionPageVideo(autoplay) {
    var v = document.getElementById('fpPageVid');
    if (!v) return;
    var src = isOn() ? FILMS[bgChoice()].vid : FILMS[0].vid;
    if (v.getAttribute('src') !== src) {
      v.setAttribute('src', src);
      try { v.load(); } catch (e) {}
    }
    if (autoplay && isOn()) {
      v.muted = true;
      var p = v.play(); if (p && p.catch) p.catch(function () {});
    }
  }

  function setBgChoice(i) {
    if (i < 0 || i >= FILMS.length || i === bgChoice()) return;
    try { localStorage.setItem(BGKEY, String(i)); } catch (e) {}
    var v = document.getElementById('fpBgVideo');
    if (v) { v.setAttribute('src', FILMS[i].vid); try { v.load(); } catch (e) {} playState(); }
    syncFashionPageVideo(isOn());
    paintPicker();
  }
  window.fpBgChoice = bgChoice;
  /* Which file the mode is actually playing. A page that wants the same
     film behind its own content asks for it here rather than naming a URL
     of its own — pick a different background and that page follows. */
  window.fpBgVid = function () { return FILMS[bgChoice()].vid; };

  function slides() { return isOn() ? FILMS : STILLS; }

  function isOn() { return typeof window.fpOn === 'function' ? window.fpOn() : false; }
  /* The mode has a master switch and four part switches, and Page
     backgrounds is one of the parts. playState() only ever asked the master
     one, so turning Page backgrounds off left the film playing — the switch
     said off and the phone kept running the clip. */
  /* The master Fashion Plus switch owns the shared film. Page-specific
     appearance switches must never turn the hamburger or another open page
     back into a still frame. */
  function bgPartOn() { return isOn(); }
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
    v.src = FILMS[bgChoice()].vid;
    v.addEventListener('loadeddata', function () {
      if (isOn() && document.visibilityState === 'visible') {
        var p = v.play(); if (p && p.catch) p.catch(function () {});
      }
    });
    document.body.insertBefore(v, document.body.firstChild);
    /* The vignette. A fixed veil immediately after the clip — the clip is at
       z-index 0 and every .screen is at 10, so this sits between them at 1
       and darkens the frame's edges without touching anything on top of it.
       It also earns its keep on the older backgrounds: those are 0.03-0.11
       bits per pixel and it is the edges of the frame where that shows. */
    var veil = document.getElementById('fpBgVeil');
    if (!veil) {
      veil = document.createElement('div');
      veil.id = 'fpBgVeil';
      veil.setAttribute('aria-hidden', 'true');
      v.parentNode.insertBefore(veil, v.nextSibling);
    }
    return v;
  }

  function isStoreScreen(screen) {
    return !!screen && /^(sub-real-meaning|sub-nowssb-store|sub-meaning-store|sub-ebooks-store|sub-signature-store)$/.test(screen.id);
  }

  function restoreStoreIntroArtwork() {
    var artwork = {
      'nssIntroPage .nss-intro-img': './assets/store/intro-store.webp',
      'rmIntroPage .rm-intro-bg': './assets/store/intro-words.webp',
      'msIntroPage .ms-intro-bg': './assets/store/intro-meanings.webp',
      'ebIntroPage .ms-intro-bg': './assets/store/intro-ebooks.webp',
      'sigIntroPage .sig-intro-bg': './assets/store/intro-signature.webp'
    };
    Object.keys(artwork).forEach(function (selector) {
      var parts = selector.split(' ');
      var layer = document.querySelector('#' + parts[0] + ' ' + parts[1]);
      if (!layer) return;
      layer.style.setProperty('background-image', "url('" + artwork[selector] + "')", 'important');
      layer.style.setProperty('background-color', '#000', 'important');
      layer.style.setProperty('background-repeat', 'no-repeat', 'important');
      layer.style.setProperty('background-position', 'center top', 'important');
      layer.style.setProperty('background-size', 'contain', 'important');
    });
  }

  function restoreIntroArtwork() {
    var fallback = {
      'rm-intro-bg': './assets/store/intro-words.webp',
      'ms-intro-bg': './assets/store/intro-meanings.webp',
      'sl-intro-bg': 'https://media.nowssb.com/migrated-images/88671556b2e1fc0b_grok_image_1778224339812_jhranv.jpg'
    };
    var selectors = '.sub-screen-bg, .rm-intro-bg, .ms-intro-bg, .eb-intro-bg, ' +
      '.sig-intro-bg, .sl-intro-bg, .st-bg, .qa-page-bg, .fpp-intro-bg, ' +
      '.cart-intro-bg, .wish-intro-bg, .orders-intro-bg, .oh-intro-bg';
    document.querySelectorAll('.sub-screen.open:not(#sub-real-meaning):not(#sub-nowssb-store):not(#sub-meaning-store):not(#sub-ebooks-store):not(#sub-signature-store) :is(' + selectors + ')').forEach(function (layer) {
      if (layer.querySelector(':scope > .fp-intro-art') || layer.querySelector(':scope > video')) return;
      var raw = '';
      try { raw = layer.style.backgroundImage || ''; } catch (e) {}
      var match = raw.match(/url\(["']?([^"')]+)["']?\)/i);
      var src = match ? match[1] : fallback[layer.className.split(/\s+/).find(function (c) { return fallback[c]; })];
      if (!src) return;
      var art = document.createElement('img');
      layer.setAttribute('data-fp-original-bg', raw);
      art.className = 'fp-intro-art';
      art.src = src;
      art.alt = '';
      art.setAttribute('aria-hidden', 'true');
      layer.appendChild(art);
      layer.classList.add('fp-intro-layer');
      layer.style.backgroundImage = 'none';
    });
  }

  function clearIntroArtwork() {
    document.querySelectorAll('.fp-intro-layer').forEach(function (layer) {
      var art = layer.querySelector(':scope > .fp-intro-art');
      if (art) art.remove();
      var original = layer.getAttribute('data-fp-original-bg');
      if (original !== null) layer.style.backgroundImage = original;
      layer.removeAttribute('data-fp-original-bg');
      layer.classList.remove('fp-intro-layer');
    });
  }

  function markImageBacked() {
    if (isOn() && bgPartOn() && !batteryLow) restoreIntroArtwork();
    else clearIntroArtwork();
    var subs = document.querySelectorAll('.sub-screen');
    var n = 0;
    for (var i = 0; i < subs.length; i++) {
      var s = subs[i];
      if (isStoreScreen(s)) {
        s.removeAttribute('data-fp-img');
        s.removeAttribute('data-fp-solid');
        continue;
      }

      /* Already decided. This is not an optimisation, it is required: the
         CSS answer to being tagged is `background-image: none` on that very
         layer, so re-reading a tagged page would find no image and untag
         it — the tag would erase its own evidence. Positives are therefore
         permanent; only pages that have never qualified are looked at again. */
      if (s.hasAttribute('data-fp-img')) { n++; continue; }

      /* A page that already has a moving background keeps it: a video where
         the background sits, not a clip inside a card further down. */
      if (s.querySelector(':scope > video, :scope > .sub-screen-bg video')) {
        s.removeAttribute('data-fp-solid');
        continue;
      }

      /* Re-read each pass, because several of these layers are filled by
         their own page's code the first time it opens (rmBg, msBg, ebBg…)
         and hold no image at all before that. */
      var layers = s.querySelectorAll(
        '.sub-screen-bg, .rm-intro-bg, .ms-intro-bg, .eb-intro-bg, ' +
        '.sig-intro-bg, .sl-intro-bg, .st-bg'
      );
      var hit = null;
      for (var j = 0; j < layers.length; j++) {
        var bg = '';
        try { bg = getComputedStyle(layers[j]).backgroundImage || ''; } catch (e) {}
        if (bg && bg !== 'none' && bg.indexOf('url(') === 0) { hit = layers[j]; break; }
      }
      if (hit) {
        s.removeAttribute('data-fp-solid');
        s.setAttribute('data-fp-img', '1');
        hit.setAttribute('data-fp-img', '1');
        n++;
      } else {
        /* No photograph of its own — a solid page. These are the ones the
           mode used to stop at: opaque #060c18 at z-index 600, so the fixed
           clip never reached them. They are opened up too now, and their own
           colour was also their contrast, so the CSS hands them a scrim.

           Deliberately NOT permanent, unlike the tag above. That one has to
           be, because its own CSS answer erases the evidence it was read
           from; this one reads nothing and removes nothing, so a page whose
           background is filled by its own code the first time it opens is
           still seen on a later pass and upgraded to a photograph page. */
        s.setAttribute('data-fp-solid', '1');
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
    var want = isOn() && bgPartOn() && !batteryLow &&
               !document.body.classList.contains('nwsb-settings-open') &&
               !document.body.classList.contains('nwsb-store-open') &&
               document.visibilityState === 'visible';
    if (want) { v.play().catch(function () {}); }
    else { try { v.pause(); } catch (e) {} }
  }

  /* A sub-screen may create or fill its own backdrop only when it opens.
     Reclassify at that moment so the selected Fashion Plus film reaches every
     page, instead of only the pages that existed when the switch first ran.
     The body class avoids relying on CSS :has support in older WebViews. */
  function syncOpenPageBackdrop() {
    var on = isOn() && bgPartOn() && !batteryLow;
    var settingsOpen = !!document.querySelector('#sub-social.sub-screen.open');
    var storeOpen = !!document.querySelector('#sub-real-meaning.sub-screen.open, #sub-nowssb-store.sub-screen.open, #sub-meaning-store.sub-screen.open, #sub-ebooks-store.sub-screen.open, #sub-signature-store.sub-screen.open');
    var hasOpenPage = !!document.querySelector('.sub-screen.open');
    document.body.classList.toggle('nwsb-settings-open', settingsOpen);
    document.body.classList.toggle('nwsb-store-open', storeOpen);
    document.body.classList.toggle('nwsb-sub-open', hasOpenPage);
    if (storeOpen) restoreStoreIntroArtwork();
    document.body.classList.toggle(
      'fp-sub-open',
      on && hasOpenPage
    );
    // Marking has no visual effect by itself. Doing it in both states lets
    // the off-mode black/image rules make the same decision for a page whose
    // own backdrop was created only when it opened.
    markImageBacked();
    if (on && !settingsOpen && !storeOpen) {
      restoreIntroArtwork();
      bgVideo(true);
      playState();
    } else if (settingsOpen || storeOpen) {
      // Settings is the normal white neumorphic surface, never a Fashion Plus
      // cinema. Stop the shared decoder while this screen is open.
      bgVideo(false);
    }
  }
  window.nwsbFpSyncPageBackdrop = syncOpenPageBackdrop;

  /* Some older page scripts open their sub-screen by toggling the class
     directly instead of going through part012's openSub(). Observe that
     single state change so every Settings, Fashion and hamburger-linked page
     gets the same selected-film/image decision. */
  function observePageOpenState() {
    if (!window.MutationObserver || !document.body) return;
    var queued = false;
    new MutationObserver(function (records) {
      for (var i = 0; i < records.length; i++) {
        var target = records[i].target;
        if (!target || !target.classList ||
            (!target.classList.contains('sub-screen') &&
             target.id !== 'menuDrawer')) continue;
        if (queued) return;
        queued = true;
        requestAnimationFrame(function () {
          queued = false;
          syncOpenPageBackdrop();
        });
        return;
      }
    }).observe(document.body, {
      subtree: true,
      attributes: true,
      attributeFilter: ['class'],
    });
  }
  observePageOpenState();

  /* Fade only the fixed background layers during a route change. Page content
     stays live while the old frame dips away and the selected film/image comes
     back, so navigation feels deliberate without blocking a tap. */
  var fadeTimer = null;
  window.nwsbFpFadeBackground = function () {
    document.body.classList.remove('nwsb-bg-fade-in');
    document.body.classList.add('nwsb-bg-fade-out');
    if (fadeTimer) clearTimeout(fadeTimer);
    fadeTimer = setTimeout(function () {
      document.body.classList.remove('nwsb-bg-fade-out');
      document.body.classList.add('nwsb-bg-fade-in');
      fadeTimer = setTimeout(function () {
        document.body.classList.remove('nwsb-bg-fade-in');
        fadeTimer = null;
      }, 380);
    }, 150);
  };

  /* Called by part066.js's apply(), which is the single source of truth. */
  window.nwsbFpBackgrounds = function (on) {
    /* part066.js passes `isOn && partOn('bg')`, so this covers both the
       master being off and Page backgrounds being off on its own. The class
       is what lets the sheet hide the film and the vignette, and give the
       tagged pages their photographs back — pausing alone left a frozen
       frame covering them. */
    document.body.classList.toggle('fp-bg-off', !on);
    if (on) { bgVideo(true); markImageBacked(); }
    playState();
    syncOpenPageBackdrop();
    /* The phone shows the stills when the mode is off and the clips when it
       is on, so the switch has to restage it. */
    if (typeof window.nwsbFpRestage === 'function') {
      try { window.nwsbFpRestage(); } catch (e) {}
    }
  };

  /* ── The section's own copy ───────────────────────────────────────── */
  function paint() {
    var on = isOn();
    /* The switch, the state line and the note exist twice — once in the
       section on the home and once on the page behind its Enter — so these
       are classes rather than ids and every copy is painted. */
    /* The master switches only — the per-piece ones carry data-part and
       are painted by paintParts() from their own keys. */
    document.querySelectorAll('.fp-switch:not([data-part])').forEach(function (sw) {
      sw.classList.toggle('on', on);
    });
    paintParts();
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
    var SL = slides();
    idx = ((idx + step) % SL.length + SL.length) % SL.length;
    var w = SL[idx];

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
      A.classList.remove('on'); B.classList.remove('on');
    }

    function side(el, k) {
      if (!el) return;
      var s2 = SL[((idx + k) % SL.length + SL.length) % SL.length];
      el.style.backgroundImage = 'url("' + (s2.img || STILLS[0].img) + '")';
    }
    side(document.getElementById('fpSideL'), -1);
    side(document.getElementById('fpSideR'), 1);

    var h = document.getElementById('fpGlassHead'), sb = document.getElementById('fpGlassSub'),
        t = document.getElementById('fpGlassThumb');
    if (h) h.textContent = w.t[0];
    if (sb) sb.textContent = w.t[1];
    if (t) {
      var nx = SL[(idx + 2) % SL.length];
      t.style.backgroundImage = 'url("' + (nx.img || STILLS[0].img) + '")';
    }
  }

  /* Flipping the switch changes which list is playing, so the phone has to
     be told to start again from the top of the other one. */
  window.nwsbFpRestage = function () {
    idx = -1; useA = false;
    if (isOn()) idx = bgChoice() - 1;   // open on the background actually in use
    shift(1); paintPicker();
  };

  /* ── Swiping the phone ────────────────────────────────────────────
     The phone is the picker. A drag moves it one slide, and while the mode
     is on every slide is a background — so landing on one selects it. No
     Apply button, because the thing you are looking at IS the choice. */
  function bindSwipe() {
    var stage = document.getElementById('fpStage');
    if (!stage || stage._fpSwipe) return;
    stage._fpSwipe = true;
    var x0 = null, y0 = null;
    stage.addEventListener('touchstart', function (e) {
      var t = e.touches[0]; x0 = t.clientX; y0 = t.clientY;
    }, { passive: true });
    stage.addEventListener('touchend', function (e) {
      if (x0 == null) return;
      var t = e.changedTouches[0], dx = t.clientX - x0, dy = t.clientY - y0;
      x0 = null;
      /* Horizontal only — this sits in a vertical scroller and a swipe that
         was meant to scroll the page must not change the background. */
      if (Math.abs(dx) < 40 || Math.abs(dx) < Math.abs(dy) * 1.4) return;
      hold(); shift(dx < 0 ? 1 : -1); commit();
    }, { passive: true });
  }
  /* A finger beats the timer: pause the rotation for a few seconds after a
     swipe so the slide you chose does not slide away under you. */
  var holdT = null;
  function hold() {
    if (spin) { clearInterval(spin); spin = null; }
    clearTimeout(holdT);
    holdT = setTimeout(function () { startSpin(); }, 6000);
  }
  /* A swipe PREVIEWS, it does not choose. It used to call setBgChoice here,
     which meant the app's background changed the moment your finger left
     the phone — you could not look through them without wearing each one on
     the way past. The Apply button under the picker is what chooses. */
  function commit() {
    paintPicker();
  }
  function startSpin() {
    if (spin || reducedMotion()) return;
    /* The rotation PREVIEWS; it must never select. Committing from the
       timer meant the app's background quietly changed itself every 3.2
       seconds — you would have picked one and watched it drift. Only a
       swipe or a tap chooses. */
    spin = setInterval(function () { shift(1); paintPicker(); }, 3200);
  }

  /* The caption under the phone: what it is, which one of how many, and —
     while the mode is on — whether it is the background you are using. */
  function paintPicker() {
    var host = document.getElementById('fpPick');
    if (!host) return;
    var SL = slides(), w = SL[idx] || SL[0], film = isOn();
    var dots = SL.map(function (_, i) {
      return '<span class="fpp-dot' + (i === idx ? ' on' : '') + '"></span>';
    }).join('');
    /* slides() returns FILMS or STILLS, never both — so with the mode on,
       the slide index IS the index into FILMS, and with it off there are no
       films on the phone at all and nothing to apply. */
    var isFilm = film;
    var applied = isFilm && idx === bgChoice();
    host.innerHTML =
      '<div class="fp-pick-name">' + (w && w.t ? w.t[0] : '') + '</div>' +
      '<div class="fp-pick-dots">' + dots + '</div>' +
      '<div class="fp-pick-sub">' +
        (film
          ? (applied
              ? '<span class="fp-pick-live">In use</span> · swipe to try another'
              : 'Swipe to preview · Apply to use it')
          : 'Swipe through the pages that change') +
      '</div>' +
      (isFilm
        ? '<button class="fp-pick-apply' + (applied ? ' on' : '') + '" id="fpApplyBtn"' +
          (applied ? ' disabled' : '') + '>' +
          (applied ? 'In use' : 'Apply this background') + '</button>'
        : '');
    host.onclick = null;
    var btn = document.getElementById('fpApplyBtn');
    if (btn && !applied) btn.onclick = function () { setBgChoice(idx); paintPicker(); };
  }
  window.nwsbFpPaintPicker = paintPicker;

  /* Only while the section is actually on screen — a cross-fade nobody can
     see is the exact cost this mode is warning people about. */
  function watchStage() {
    var stage = document.getElementById('fpStage');
    if (!stage) return;
    if (!document.getElementById('fpWallA').style.backgroundImage) {
      idx = -1; useA = false; shift(1);
    }
    bindSwipe(); paintPicker();
    if (reducedMotion() || !window.IntersectionObserver) return;
    new IntersectionObserver(function (es) {
      var vis = es[0] && es[0].isIntersecting;
      if (vis) startSpin();
      else if (spin) { clearInterval(spin); spin = null; }
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
    ['Every page background moves', 'Photo-backed pages and solid pages both become transparent over the same live Fashion Plus film.'],
    ['Every open page gets the same film', 'The hamburger, stores, progress, profile, settings and every other screen use the exact Fashion Plus background while it is on.'],
    ['It stops when you are not looking', 'Everything pauses the moment the app goes to the background or the screen locks, and starts again when you come back.'],
          ['It gets out of the way on low battery', 'Below 15% and not charging, the backgrounds pause themselves until you plug in.']

  ];

  /* ── The page behind the section's Enter ──────────────────────────
     Intro first, then the body — the same two-step every shop in the app
     uses. The list is built from the same CHANGES table the caution sheet
     uses, so the two can never drift apart. */
  function fillList() {
    var host = document.getElementById('fpPageList');
    if (!host || host.children.length) return;
    host.innerHTML = CHANGES.map(function (c, i) {
      return '<div class="fpp-card"><span class="fpp-card-n">' + (i + 1) + '</span>' +
               '<div class="fpp-card-t">' + c[0] + '</div>' +
               '<div class="fpp-card-s">' + c[1] + '</div></div>';
    }).join('');

    var dots = document.getElementById('fpRailDots');
    if (dots) {
      dots.innerHTML = CHANGES.map(function (_, i) {
        return '<span class="fpp-dot' + (i ? '' : ' on') + '"></span>';
      }).join('');
    }
    /* The counter and the dots follow the rail rather than the rail
       following them — it is a scroller, not a slideshow, so the finger is
       in charge and this only reports where it got to. */
    host.addEventListener('scroll', function () {
      var card = host.querySelector('.fpp-card');
      if (!card) return;
      var step = card.getBoundingClientRect().width + 12;
      var i = Math.round(host.scrollLeft / step);
      i = Math.max(0, Math.min(CHANGES.length - 1, i));
      var cnt = document.getElementById('fpRailCount');
      if (cnt) cnt.textContent = (i + 1) + ' of ' + CHANGES.length;
      if (dots) {
        [].forEach.call(dots.children, function (d, k) { d.classList.toggle('on', k === i); });
      }
    }, { passive: true });
  }

  /* The per-piece switches, built from part066.js's own table so the two
     can never list different things. Each row is a switch, not a door. */
  function fillParts() {
    var host = document.getElementById('fpParts');
    var parts = window.NWSB_FP_PARTS;
    if (!host || !parts) return;
    if (!host.children.length) {
      host.innerHTML = parts.map(function (p) {
        return '<div class="fpp-part" onclick="fpPartToggle(\'' + p.k + '\')" role="button">' +
                 '<div class="fpp-part-txt">' +
                   '<div class="fpp-part-t">' + p.label + '</div>' +
                   '<div class="fpp-part-s">' + p.sub + '</div>' +
                 '</div>' +
                 '<div class="fp-switch fp-switch-sm" data-part="' + p.k + '"><span class="fp-switch-knob"></span></div>' +
               '</div>';
      }).join('');
    }
    paintParts();
  }
  function paintParts() {
    if (typeof window.fpPartOn !== 'function') return;
    var master = isOn();
    document.querySelectorAll('.fpp-part').forEach(function (row) {
      var sw = row.querySelector('[data-part]');
      if (!sw) return;
      var live = window.fpPartOn(sw.getAttribute('data-part'));
      sw.classList.toggle('on', live);
      /* Dimmed, not disabled: you can set these up before turning the mode
         on, and they should look like settings rather than dead controls. */
      row.classList.toggle('fpp-part-idle', !master);
    });
  }

  window.fpOpenPage = function () {
    var sc = document.getElementById('sub-fashion-plus');
    if (!sc) return;
    fillList(); fillParts(); paint();
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
    syncFashionPageVideo(true);
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
