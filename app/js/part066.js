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
    { open: 'sound-library', vid: 'https://res.cloudinary.com/eenvubod/video/upload/v1785402438/grok_video_2026-07-30-14-35-20_lju6u7.mp4' },
    { open: 'my-progress',   vid: 'https://res.cloudinary.com/eenvubod/video/upload/v1785402440/grok_video_2026-07-30-14-35-18_kucgwh.mp4' },
    { open: 'word-science',  img: 'https://res.cloudinary.com/eenvubod/image/upload/v1785402429/grok_image_1785402330575_bbykvf.jpg' },
    { open: 'profile',       vid: 'https://res.cloudinary.com/eenvubod/video/upload/v1785402435/grok_video_2026-07-30-14-35-16_j5tr1g.mp4' }
  ];
  var PRACTICE_VID = 'https://res.cloudinary.com/eenvubod/video/upload/v1785403502/grok_video_2026-07-30-14-54-07_ddjmrr.mp4';

  function on() { try { return localStorage.getItem(K) === '1'; } catch (e) { return false; } }
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
    /* Videos that are not on screen should not be decoding frames. */
    document.querySelectorAll('#home video.fp-media').forEach(function (v) {
      if (isOn) { var pr = v.play(); if (pr && pr.catch) pr.catch(function () {}); }
      else { try { v.pause(); } catch (e) {} }
    });
    if (window.cuPaintModes) window.cuPaintModes();
  }
  window.fpApply = apply;

  window.fpToggle = function () {
    try { localStorage.setItem(K, on() ? '0' : '1'); } catch (e) {}
    apply();
    haptic(on() ? [30, 55, 30] : 28);
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
