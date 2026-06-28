/* ═══════════════════════════════════════════════════════════════
   NowssB — Liquid Glass Player controller
   Applies the liquid-glass skin to the practice player and rotates one
   of 6 themes per word. Subscriber-gated (free users keep the normal UI).
═══════════════════════════════════════════════════════════════ */
(function () {
  // While dialing in the look, show it to everyone. Flip ONLY_SUBSCRIBERS to
  // true to gate it behind a paid/trial plan.
  var ONLY_SUBSCRIBERS = false;

  function isSubscribed() {
    try {
      if (window.GATE && typeof window.GATE.tier === 'function') {
        var t = window.GATE.tier();
        if (t && t !== 'free' && t !== 'starter') return true;
      }
    } catch (e) {}
    var ud = window._userDataCache;
    if (ud && (ud.isPro || ud.trial || (ud.tier && /pro|trial|resonance|frequency/i.test(ud.tier)))) return true;
    return false;
  }

  function shouldApply() { return ONLY_SUBSCRIBERS ? isSubscribed() : true; }

  function applyLG() {
    var on = shouldApply();
    document.body.classList.toggle('nwsb-lg', on);
    if (!on) return;
    var player = document.querySelector('#sub-practice .sp-player');
    if (!player) return;
    var idx = (typeof window._pwIdx !== 'undefined') ? window._pwIdx
            : (typeof _pwIdx !== 'undefined') ? _pwIdx : 0;
    var t = (Math.abs(idx) % 6) + 1;
    for (var i = 1; i <= 6; i++) player.classList.remove('lg-t' + i);
    player.classList.add('lg-t' + t);
  }
  window.nwsbApplyLGPlayer = applyLG;

  /* Re-apply after every practice render so the theme follows the word */
  (function wrapRender() {
    if (typeof window.renderPractice !== 'function') { return setTimeout(wrapRender, 200); }
    var orig = window.renderPractice;
    window.renderPractice = function () {
      var r = orig.apply(this, arguments);
      try { applyLG(); } catch (e) {}
      return r;
    };
  })();
})();
