/* ══════════════════════════════════════════════════════════
   QUICK LINKS SHEET — the glassmorphism box the "Quick Links" banner
   under the store section lifts up. It holds the app's black banners as
   one-tap shortcuts; every destination is an existing screen, nothing new.

   qlGo() closes the sheet BEFORE running the action: several destinations
   are .sub-screen overlays that would otherwise open underneath this one,
   which is exactly the stacking trap the Shabdapathy eBook button hit —
   openSub() only toggles a class and does nothing with z-index.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  window.qlOpen = function () {
    var ov = document.getElementById('qlOverlay');
    if (!ov) return;
    ov.classList.add('open');
    var sc = ov.querySelector('.ql-scroll');
    if (sc) sc.scrollTop = 0;
  };

  window.qlClose = function (e) {
    // When used as the overlay's own handler, only a tap on the backdrop closes.
    if (e && e.target && e.target.id !== 'qlOverlay') return;
    var ov = document.getElementById('qlOverlay');
    if (ov) ov.classList.remove('open');
  };

  window.qlGo = function (fn) {
    var ov = document.getElementById('qlOverlay');
    if (ov) ov.classList.remove('open');
    // let the close paint before the destination opens over it
    setTimeout(function () { try { fn(); } catch (err) {} }, 180);
  };

})();
