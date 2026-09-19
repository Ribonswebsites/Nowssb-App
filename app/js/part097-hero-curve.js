/* Lesmana-style 3D curve on both homes: subject stays, stills orbit. */
(function () {
  'use strict';
  var STEP = 360 / 7;

  function bind(root) {
    var ring = root.querySelector('.nwsb-curve-ring');
    if (!ring) return;
    var rot = 0;
    var dragging = false;
    var lastX = 0;
    var auto = !window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    var heldUntil = 0;

    function apply() {
      ring.style.setProperty('--rot', rot + 'deg');
      var y = root.getBoundingClientRect().top;
      var para = Math.max(-90, Math.min(90, (180 - y) * 0.12));
      root.style.setProperty('--para', para + 'px');
      root.style.setProperty('--para-s', para * 0.35 + 'px');
    }

    function tick() {
      if (!dragging && auto && Date.now() > heldUntil) rot += 0.22;
      apply();
      requestAnimationFrame(tick);
    }

    function onDown(x) {
      dragging = true;
      lastX = x;
      heldUntil = Date.now() + 2400;
    }
    function onMove(x) {
      if (!dragging) return;
      rot += (x - lastX) * 0.42;
      lastX = x;
    }
    function onUp() { dragging = false; }

    root.addEventListener('pointerdown', function (e) {
      onDown(e.clientX);
      root.setPointerCapture(e.pointerId);
    });
    root.addEventListener('pointermove', function (e) { onMove(e.clientX); });
    root.addEventListener('pointerup', onUp);
    root.addEventListener('pointercancel', onUp);

    Array.prototype.forEach.call(root.querySelectorAll('.nwsb-curve-card'), function (card, i) {
      card.addEventListener('click', function (e) {
        if (Math.abs(rot) < 0.01) return;
        e.stopPropagation();
        var current = ((rot % 360) + 360) % 360;
        var target = (360 - i * STEP) % 360;
        var delta = target - current;
        if (delta > 180) delta -= 360;
        if (delta < -180) delta += 360;
        rot += delta;
        heldUntil = Date.now() + 2800;
      });
    });

    requestAnimationFrame(tick);
  }

  function start() {
    document.querySelectorAll('[data-nwsb-curve]').forEach(bind);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
})();
