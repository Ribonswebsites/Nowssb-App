/* ══════════════════════════════════════════════════════════
   FASHION PLUS — motion on the Fashion home.

   Switched from the Customize hub (or the Customize panel on the home).
   While it is on, four of the Fashion home's still images become moving
   ones and Today's Practice gets a video behind it with its Enter pill
   moved to the middle of the right edge, plus a black banner above.

   Fashion home only — the Normal home is a light neumorphic surface and
   video behind those tiles would read as noise, so nothing here touches it.

   The media is layered in rather than swapped into the existing <img>
   tags: the originals stay exactly as they are underneath, so switching
   the mode off restores the shipped look with nothing to undo.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var K = 'nwsb_fashplus';

  /* One entry per tile, keyed by the sub-screen it opens — that is the only
     stable handle the markup gives us. `img` means a still, `vid` a loop. */
  var TILES = [
    { open: 'sound-library', vid: './assets/video/remote-09aedc60417dbf0a7d47d40262c3c5d53e69ec86d17a7bc5642c4262d1f9785c.mp4' },
    { open: 'my-progress',   vid: './assets/video/remote-4e7c79be023083831bdb8c61e162c8a5657b4154d83222d0ac00294c1aa9bd7f.mp4' },
    /* Word Science was the one tile still showing a still while the other
       three played — so with Fashion Plus on, three tiles moved and one
       sat there. Its clip lives in the repo rather than on Cloudinary
       because it was supplied as a file; mediaEl() already builds a
       <video> for `vid` and an <img> for `img`, so this is the only line
       that had to change. */
    { open: 'word-science',  vid: './assets/video/fp-word-science.mp4' },
    { open: 'profile',       vid: './assets/video/remote-8d7a2d4192fa1dfd59096dad44674769aad32216c50b00c3ba29893dd0ceefe9.mp4' }
  ];
  var PRACTICE_VID = './assets/video/remote-09a50041065bdeabacf4eab4564a84f0cfdc253c14d302b1656aa70ed32ba527.mp4';

  /* The clip above My Routines. It belongs to this file rather than the
     banner table in part067.js because it is a Fashion Plus concern: on the
     Fashion home only, and only while this mode is ON — it is part of what
     the mode puts on the home, and goes away with the rest of the motion
     when it is off. That is a CSS rule, so it costs nothing either way.

     Three of them, one step further on each time the banner is built and
     the position kept in localStorage, so it alternates from one session
     to the next instead of being the same clip forever. */
  var RT_VIDS = [
    './assets/video/remote-49d09283f71e97f0af7e3adef30c889de81105663a40b7ba13b88a4eea8c14d3.mp4',
    './assets/video/remote-4b99766dec9f4c4081e153c1f7f8a806976e45579a1529ee53765499c87a9940.mp4',
    './assets/video/remote-b1e2c78385f45657a14cdb868324167b2b2c449d9660e390118e119022bed65b.mp4'
  ];
  var RT_KEY = 'nwsb_rtvid_i';
  /* Only whichever one is playing is ever in the document, so the other two
     have to be registered or they would each be downloaded on the spot the
     moment their turn came. */
  window.NWSB_EXTRA_VIDEO_URLS = (window.NWSB_EXTRA_VIDEO_URLS || [])
    .concat(RT_VIDS)
    .concat(TILES.filter(function (t) { return t.vid && t.vid.charAt(0) === '.'; })
                 .map(function (t) { return t.vid; }));

  var rtIdx = 0;
  try { rtIdx = (parseInt(localStorage.getItem(RT_KEY), 10) || 0) % RT_VIDS.length; } catch (e) {}

  /* The three run as one set, not one per app launch. Handing out a single
     clip per launch meant the banner never changed while you were looking
     at it — the same one every time, unless the app was fully restarted.
     So it does not loop: when a clip ends the next takes over, and all
     three are seen in a sitting. Where it left off is kept, so it does not
     always open on the same one either.

     The playback controller in part051.js only restarts a video that is
     paused and on screen, and this handler runs synchronously on `ended`,
     so the source is already swapped before that pass can look at it. */
  function rtRotate(v) {
    if (!v || v._rtRot) return;
    v._rtRot = true;
    v.addEventListener('ended', function () {
      rtIdx = (rtIdx + 1) % RT_VIDS.length;
      try { localStorage.setItem(RT_KEY, String(rtIdx)); } catch (e) {}
      v.setAttribute('src', RT_VIDS[rtIdx]);
      try { v.load(); } catch (e) {}
      var p = v.play(); if (p && p.catch) p.catch(function () {});
    });
  }

  /* ── Fashion Plus ships ON ─────────────────────────────────────────
     It used to be opt-in, and almost nobody found it: the mode is what the
     app looks like, not an extra. So an unset key now means ON, and only
     an explicit '0' — someone actually turning it off — means off. Every
     switch already writes '1' or '0', so a reader who has chosen either way
     keeps their choice; the change only reaches people who never touched
     it. Which is the whole point. */
  function on() {
    try { return localStorage.getItem(K) !== '0'; } catch (e) { return true; }
  }

  /* ── The pieces ────────────────────────────────────────────────────
     The master switch turns the mode on; these say which parts of it you
     actually want. All four ship ON, so switching Fashion Plus on without
     touching anything gives you the whole thing — they exist for the phone
     that can carry the tiles but not four backgrounds at once.

     Each is its own key rather than one packed value, so a part added later
     defaults to on for everybody instead of being absent from a saved blob. */
  var PARTS = [
    { k: 'tiles',    key: 'nwsb_fp_tiles',    label: 'The four home tiles',
      sub: 'Sound Library, My Progress, Word Science and Profile play clips' },
    { k: 'practice', key: 'nwsb_fp_practice', label: 'Today’s Practice',
      sub: 'A clip behind the card, and its Enter on the right edge' },
    { k: 'routines', key: 'nwsb_fp_routines', label: 'The routines clip',
      sub: 'The banner above My Routines' },
    { k: 'bg',       key: 'nwsb_fp_bg',       label: 'Page backgrounds',
      sub: 'Every screen wearing a photograph plays the film instead' }
  ];
  window.NWSB_FP_PARTS = PARTS;

  function partOn(k) {
    var p = null;
    PARTS.forEach(function (x) { if (x.k === k) p = x; });
    if (!p) return true;
    try { return localStorage.getItem(p.key) !== '0'; } catch (e) { return true; }
  }
  window.fpPartOn = partOn;
  window.fpPartToggle = function (k) {
    var p = null;
    PARTS.forEach(function (x) { if (x.k === k) p = x; });
    if (!p) return;
    try { localStorage.setItem(p.key, partOn(k) ? '0' : '1'); } catch (e) {}
    apply();
    haptic(22);
  };
  function haptic(ms) { try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) {} }

  function mediaEl(spec) {
    if (spec.vid) {
      var v = document.createElement('video');
      v.className = 'fp-media';
      v.muted = true; v.loop = true; v.playsInline = true; v.preload = 'none';
      v.setAttribute('data-nwsb-auto', '');
      v.setAttribute('playsinline', '');
      v.src = spec.vid;
      return v;
    }
    var i = document.createElement('img');
    i.className = 'fp-media';
    i.loading = 'lazy'; i.decoding = 'async'; i.alt = '';
    i.src = spec.img;
    return i;
  }

  /* Put the layers in place once. They are inert until body.fashplus is set,
     so this can run whether the mode is on or off. */
  function mount() {
    var home = document.getElementById('home');
    if (!home) return;

    TILES.forEach(function (t) {
      var tile = home.querySelector('.home-tile[onclick*="' + t.open + '"]');
      if (!tile || tile.querySelector('.fp-media')) return;
      tile.insertBefore(mediaEl(t), tile.firstChild);
      tile.classList.add('fp-tile');
    });

    /* Inside the routines wrapper, at the top of it — the clip, the card
       and the black banner are one block now, so the layout editor moves
       them together as the wrapper's contents and the clip needs no entry
       of its own. It borrows .vb-banner for its frame, which is the
       Fashion home's own banner treatment, and adds a marker class for the
       Fashion Plus rule to hide it by.

       The clip carries a vertical rule down its middle; the words go just
       past it, arriving one after another. */
    var rt = home.querySelector('.fash-routines-wrap');
    if (rt && !document.getElementById('rtVidBanner')) {
      var rv = document.createElement('div');
      rv.id = 'rtVidBanner';
      rv.className = 'vb-banner rt-vid-banner';
      rv.innerHTML =
        /* No `loop` — rtRotate hands over to the next clip on `ended`. */
        '<video data-nwsb-auto muted playsinline preload="none" src="' + RT_VIDS[rtIdx] + '"></video>' +
        '<div class="rtv-txt">' +
          '<span class="rtv-w">Set</span>' +
          '<span class="rtv-w">Your</span>' +
          '<span class="rtv-w">Routine</span>' +
        '</div>';
      rt.insertBefore(rv, rt.firstChild);
      rtRotate(rv.querySelector('video'));
    }

    var card = document.getElementById('todayPracticeCard');
    if (card && !card.querySelector('.fp-media')) {
      card.insertBefore(mediaEl({ vid: PRACTICE_VID }), card.firstChild);
      card.classList.add('fp-card');
    }

    /* The card's own Enter pill lives inside .home-card-bottom, which this
       mode has to make a positioned element so its text clears the scrim —
       which then becomes the pill's containing block, so it can't be moved
       to the card's own right edge. Rather than restyle or relocate the
       original, this mode brings its own pill as a direct child of the card
       and hides theirs; switching off needs no unwinding. */
    if (card && !card.querySelector('.fp-enter')) {
      var e = document.createElement('div');
      e.className = 'tp-enter fp-enter';
      e.innerHTML = '<span class="tp-enter-lbl">Enter</span>' +
        '<span class="tp-enter-go"><svg viewBox="0 0 12 12" fill="none">' +
        '<path d="M2 6H10M7 3L10 6L7 9" stroke="#060c18" stroke-width="1.9" stroke-linecap="square"/></svg></span>';
      card.appendChild(e);
    }

    /* The Fashion Plus banner, below the player and inside the player's
       wrapper. It carries the switch that turns the mode on and off, so
       unlike the rest of this file it is present whether the mode is on or
       not — otherwise there would be nothing here to switch it back on with.
       cuPaintModes() keeps the knob in step with every other copy of the
       switch, because it paints any [data-k="fashplus"]. */
    if (card && !document.getElementById('fpBanner')) {
      var b = document.createElement('div');
      b.id = 'fpBanner';
      b.className = 'nmh-sec-banner fp-banner';
      b.setAttribute('onclick', 'fpToggle()');
      b.innerHTML =
        '<div class="nmh-sec-banner-icon"><svg viewBox="0 0 22 22" fill="none">' +
          '<path d="M4 3.5 17 11 4 18.5z" stroke="#fff" stroke-width="1.6" stroke-linejoin="round"/>' +
        '</svg></div>' +
        '<div class="nmh-sec-banner-divider"></div>' +
        '<div class="nmh-sec-banner-txt">' +
          '<div class="nmh-sec-banner-title">Fashion Plus</div>' +
          '<div class="nmh-sec-banner-sub">Your practice, in motion</div>' +
        '</div>' +
        '<div class="cust-mode-sw" data-k="fashplus"><div class="cust-mode-knob"></div></div>';
      (card.parentNode || home).appendChild(b);
    }
  }

  function apply() {
    mount();
    var isOn = on();
    document.body.classList.toggle('fashplus', isOn);

    /* Every rule for a piece is written `body.fashplus #home .fp-tile …`,
       so taking the marker class off the element reverts all of them at
       once — the tile goes back to exactly what it ships as, with nothing
       to unwind. That is why the switch-off is a class removal rather than
       a pile of override rules. */
    var home2 = document.getElementById('home');
    if (home2) {
      var wantTiles = isOn && partOn('tiles');
      TILES.forEach(function (t) {
        var tile = home2.querySelector('.home-tile[onclick*="' + t.open + '"]');
        if (tile) tile.classList.toggle('fp-tile', wantTiles);
      });
      var c2 = document.getElementById('todayPracticeCard');
      if (c2) c2.classList.toggle('fp-card', isOn && partOn('practice'));
    }
    document.body.classList.toggle('fpoff-routines', isOn && !partOn('routines'));
    /* Videos that are not on screen should not be decoding frames. */
    document.querySelectorAll('#home video.fp-media').forEach(function (v) {
      /* A clip inside a piece that is switched off must not be decoding —
         hidden is not the same as stopped, and stopped is the point. */
      var live = isOn && v.parentElement &&
                 (v.parentElement.classList.contains('fp-tile') ||
                  v.parentElement.classList.contains('fp-card'));
      if (live) { var pr = v.play(); if (pr && pr.catch) pr.catch(function () {}); }
      else { try { v.pause(); } catch (e) {} }
    });
    var rtv = document.querySelector('#rtVidBanner video');
    if (rtv) {
      if (isOn && partOn('routines')) { var p2 = rtv.play(); if (p2 && p2.catch) p2.catch(function () {}); }
      else { try { rtv.pause(); } catch (e) {} }
    }
    /* The second half of the mode — the photographic backgrounds becoming
       the film — is app/js/part076.js, which registers itself here rather
       than owning a switch of its own. One key, one body class, one
       toggle: the Customize card, the banner below the player and the
       switch in the Fashion Plus section are all this same function. */
    if (typeof window.nwsbFpBackgrounds === 'function') {
      try { window.nwsbFpBackgrounds(isOn && partOn('bg')); } catch (e) {}
    }
    if (window.cuPaintModes) window.cuPaintModes();
    if (typeof window.nwsbFpPaint === 'function') { try { window.nwsbFpPaint(); } catch (e) {} }
  }
  window.fpApply = apply;

  /* Turning it OFF is instant. Turning it ON goes through the caution
     first, full screen, because that is the only moment a battery warning
     is worth reading — part076.js puts it up and calls back here. The
     fallback keeps the switch working if that file ever fails to load. */
  function flip() {
    try { localStorage.setItem(K, on() ? '0' : '1'); } catch (e) {}
    apply();
    haptic(on() ? [30, 55, 30] : 28);
  }
  window.fpFlip = flip;

  window.fpToggle = function () {
    if (!on() && typeof window.fpCaution === 'function') { window.fpCaution(true); return; }
    flip();
  };
  window.fpOn = on;

  function boot() {
    apply();
    /* Today's Practice and the tiles are re-rendered by other files after
       first paint, which drops the layers — one late pass puts them back. */
    setTimeout(apply, 1400);
    setTimeout(apply, 3200);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
