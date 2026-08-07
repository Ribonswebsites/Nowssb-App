/* ══════════════════════════════════════════════════════════
   START PAGE IMAGE — picker for the art behind the start animation.

   Three ways to set it:
     auto     — a different image every launch (the default, and what the
                app shipped with)
     default  — always the original art
     fixed    — one image you picked from the carousel

   The carousel is the same 3D language as the Fashion Background picker in
   part047.js (swipe to browse, tap to centre, tap again to apply), so the
   two Appearance pickers behave identically.

   The pool itself lives in index.html as window.NWSB_SPLASH_ART, set inline
   right after the splash element — the splash is the first thing painted, so
   that choice can't wait on a file like this one to load. This panel only
   records the preference; the inline script is what reads it at startup.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  function art() { return window.NWSB_SPLASH_ART || []; }
  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  function savedMode() {
    /* No stored value means a fresh install, and a fresh install starts on
       the clip — the same default the inline splash script applies. */
    var m = ls('nwsb_splash_mode', 'clip');
    return (m === 'default' || m === 'fixed' || m === 'auto') ? m : 'clip';
  }
  function savedPick() {
    var i = parseInt(ls('nwsb_splash_pick', '0'), 10);
    return (i >= 0 && i < art().length) ? i : 0;
  }

  var sbgActive = 0, sbgItems = null, sbgDotEls = null, SBG_N = 0;
  var sbgStagedMode = null;   // 'auto' | 'default' | null (= the centred photo)

  function cfg(s) {
    var a = Math.abs(s), d = s < 0 ? -1 : 1;
    if (a === 0) return { tx: 0,      tz: 200,  ry: 0,      sc: 1.00, op: 1.00, zi: 20 };
    if (a === 1) return { tx: d * 172, tz: -10,  ry: d * -28, sc: 0.78, op: 0.68, zi: 15 };
    if (a === 2) return { tx: d * 290, tz: -155, ry: d * -50, sc: 0.52, op: 0.22, zi: 10 };
    return              { tx: 0,      tz: -600, ry: 0,      sc: 0.10, op: 0.00, zi: 0  };
  }

  function paint() {
    if (!sbgItems) return;
    sbgItems.forEach(function (el, i) {
      var off = ((i - sbgActive) % SBG_N + SBG_N) % SBG_N;
      var s = off > Math.floor(SBG_N / 2) ? off - SBG_N : off;
      var c = cfg(s);
      el.style.transform     = 'translateX(' + c.tx + 'px) translateZ(' + c.tz + 'px) rotateY(' + c.ry + 'deg) scale(' + c.sc + ')';
      el.style.opacity       = String(c.op);
      el.style.zIndex        = String(c.zi);
      el.style.pointerEvents = c.op > 0.05 ? 'auto' : 'none';
      el.style.borderColor   = (!sbgStagedMode && i === sbgActive) ? '#e8d5a3' : 'rgba(255,255,255,0.08)';
    });
    if (sbgDotEls) sbgDotEls.forEach(function (d, i) { d.classList.toggle('active', i === sbgActive); });
    var label = document.getElementById('sbgSelectedLabel');
    if (label) {
      label.textContent = sbgStagedMode === 'clip' ? 'Start Clip — the animation NowssB opens with'
                        : sbgStagedMode === 'auto' ? 'Auto Rotate — a different image every launch'
                        : sbgStagedMode === 'default' ? 'Default — always the original art'
                        : 'Start image ' + (sbgActive + 1) + ' of ' + SBG_N;
    }
    var prev = document.getElementById('sbgPreviewBg');
    if (prev) prev.style.backgroundImage = "url('" + art()[sbgActive] + "')";
    /* #sbgHeadArt is this page's identity icon, like the Fashion Background
       panel's, so it is NOT repainted with whatever is centred — the carousel
       and the full-bleed preview behind it already show the selection. */
  }

  function go(n) { sbgActive = ((n % SBG_N) + SBG_N) % SBG_N; paint(); }

  function syncModeCards() {
    var c = document.getElementById('sbgModeCardClip');
    var a = document.getElementById('sbgModeCardAuto');
    var d = document.getElementById('sbgModeCardDefault');
    if (c) c.classList.toggle('on', sbgStagedMode === 'clip');
    if (a) a.classList.toggle('on', sbgStagedMode === 'auto');
    if (d) d.classList.toggle('on', sbgStagedMode === 'default');
  }

  window.sbgInit = function () {
    var carousel = document.getElementById('sbgCarousel');
    var inner    = document.getElementById('sbgCarouselInner');
    var dotsEl   = document.getElementById('sbgDots');
    if (!carousel || !inner || !dotsEl || !art().length) return;

    if (!inner.dataset.built) {
      inner.dataset.built = '1';
      inner.innerHTML = art().map(function (url) {
        return '<div class="fbgci" style="background-image:url(\'' + url + '\')"></div>';
      }).join('');
      dotsEl.innerHTML = art().map(function () { return '<div class="becd"></div>'; }).join('');
    }
    sbgItems  = Array.from(inner.querySelectorAll('.fbgci'));
    sbgDotEls = Array.from(dotsEl.querySelectorAll('.becd'));
    SBG_N = sbgItems.length;

    // Seed from what's actually committed, so reopening shows the truth.
    var mode = savedMode();
    sbgStagedMode = (mode === 'fixed') ? null : mode;   // 'clip' | 'auto' | 'default'
    sbgActive = savedPick();

    sbgItems.forEach(function (el) {
      el.style.transition = 'none';
      el.style.transform  = 'translateX(0px) translateZ(-600px) rotateY(0deg) scale(0.1)';
      el.style.opacity    = '0';
    });
    void carousel.offsetHeight;
    requestAnimationFrame(function () {
      requestAnimationFrame(function () {
        var T = 'transform 0.78s cubic-bezier(0.34,1.08,0.64,1),opacity 0.78s ease,border-color 0.3s ease,box-shadow 0.3s ease';
        sbgItems.forEach(function (el) { el.style.transition = T; });
        paint();
      });
    });

    // Same belt-and-braces as the Fashion picker: Android WebViews can start
    // their native edge-swipe-back on a horizontal drag unless touchmove is
    // actively prevented, even with touch-action:pan-y set.
    if (!carousel._sbgBound) {
      carousel._sbgBound = true;
      var tx0 = 0, ty0 = 0;
      carousel.addEventListener('touchstart', function (e) { tx0 = e.touches[0].clientX; ty0 = e.touches[0].clientY; }, { passive: true });
      carousel.addEventListener('touchmove', function (e) {
        var dx = e.touches[0].clientX - tx0, dy = e.touches[0].clientY - ty0;
        if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 8 && e.cancelable) e.preventDefault();
      }, { passive: false });
      carousel.addEventListener('touchend', function (e) {
        var dx = e.changedTouches[0].clientX - tx0;
        if (Math.abs(dx) > 40) { sbgStagedMode = null; syncModeCards(); go(sbgActive + (dx < 0 ? 1 : -1)); }
      }, { passive: true });
    }

    sbgItems.forEach(function (el, i) {
      el.onclick = function (e) {
        e.stopPropagation();
        sbgStagedMode = null;
        syncModeCards();
        if (i !== sbgActive) go(i);
        else window.sbgApply();
      };
    });
    syncModeCards();
  };

  window.sbgSelectMode = function (mode) {
    sbgStagedMode = (mode === 'clip' || mode === 'default') ? mode : 'auto';
    syncModeCards();
    paint();
  };

  window.sbgApply = function () {
    if (sbgStagedMode === 'clip') { lsSet('nwsb_splash_mode', 'clip'); }
    else if (sbgStagedMode === 'auto') { lsSet('nwsb_splash_mode', 'auto'); }
    else if (sbgStagedMode === 'default') { lsSet('nwsb_splash_mode', 'default'); }
    else { lsSet('nwsb_splash_mode', 'fixed'); lsSet('nwsb_splash_pick', String(sbgActive)); }
    syncModeCards();
    paint();
    var btn = document.getElementById('sbgApplyBtn');
    if (btn) {
      btn.textContent = 'APPLIED!';
      btn.style.background = '#fff';
      setTimeout(function () {
        btn.textContent = 'APPLY THIS START IMAGE';
        btn.style.background = '#e8d5a3';
      }, 1400);
    }
  };

})();
