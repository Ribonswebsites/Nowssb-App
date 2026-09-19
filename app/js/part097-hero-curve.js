/* Lesmana-style 3D curve on both homes: subject stays, stills orbit. */
(function () {
  'use strict';

  var ICONS = [
    { id: 'player',  svg: '<path d="M8 5.2 19 12 8 18.8z"/>' },
    { id: 'library', svg: '<path d="M11.4 4.6 6.8 8.6H3.6v6.8h3.2l4.6 4V4.6z"/><path d="M15.6 8.8a4.6 4.6 0 0 1 0 6.4M18.4 6a8.6 8.6 0 0 1 0 12"/>' },
    { id: 'store',   svg: '<path d="M4.4 7.6h15.2l-1.1 12.2a1.5 1.5 0 0 1-1.5 1.4H7a1.5 1.5 0 0 1-1.5-1.4z"/><path d="M8.7 10V6.6a3.3 3.3 0 0 1 6.6 0V10"/>' },
    { id: 'reader',  svg: '<path d="M3 4.5A1.4 1.4 0 0 1 4.4 3H10v16H4.4A1.4 1.4 0 0 1 3 17.6z"/><path d="M19 4.5A1.4 1.4 0 0 0 17.6 3H12v16h5.6a1.4 1.4 0 0 0 1.4-1.4z" stroke-opacity="0.55"/>' },
    { id: 'ebook',   svg: '<path d="M4 5.2h9.5a2 2 0 0 1 2 2V18H6a2 2 0 0 1-2-2z"/><path d="M8 3h9.2a1.8 1.8 0 0 1 1.8 1.8V15" stroke-opacity="0.55"/>' },
    { id: 'healing', svg: '<path d="M12 3.2v17.6"/><circle cx="12" cy="12" r="3"/>' }
  ];

  function go(id) {
    if (typeof openSub !== 'function') return;
    if (id === 'player') openSub('practice');
    else if (id === 'library') openSub('sound-library');
    else if (id === 'store') openSub('nowssb-store');
    else if (id === 'reader') openSub('reader');
    else if (id === 'ebook') openSub('ebooks-store');
    else if (id === 'healing') openSub('health-journey');
  }

  function fillRail(rail, cardGo) {
    if (!rail || rail.getAttribute('data-ready')) return;
    rail.setAttribute('data-ready', '1');
    var compact = rail.getAttribute('data-compact') === '1';
    var html = '';
    if (compact) {
      var one = ICONS.filter(function (x) { return x.id === cardGo; })[0] || ICONS[0];
      html += '<button type="button" class="nwsb-enter-ic" data-go="' + one.id + '"><svg viewBox="0 0 24 24">' + one.svg + '</svg></button>';
    } else {
      html += '<span class="nwsb-enter-icons">';
      ICONS.forEach(function (ic) {
        html += '<button type="button" class="nwsb-enter-ic" data-go="' + ic.id + '"><svg viewBox="0 0 24 24">' + ic.svg + '</svg></button>';
      });
      html += '</span>';
    }
    html += '<span class="nwsb-enter-rule"></span>';
    html += '<span class="nwsb-enter-pill" data-go="' + cardGo + '">Enter<svg viewBox="0 0 12 12"><path d="M2 6H10M7 3L10 6L7 9" stroke-width="1.9" stroke-linecap="square"/></svg></span>';
    rail.innerHTML = html;
    rail.addEventListener('click', function (e) {
      var t = e.target.closest('[data-go]');
      if (!t) return;
      e.preventDefault();
      e.stopPropagation();
      go(t.getAttribute('data-go'));
    });
  }

  function bind(root) {
    var ring = root.querySelector('.nwsb-curve-ring');
    if (!ring) return;
    var n = root.querySelectorAll('.nwsb-curve-card').length || 7;
    var STEP = 360 / n;
    var rot = 0;
    var dragging = false;
    var lastX = 0;
    var auto = !window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    var heldUntil = 0;

    Array.prototype.forEach.call(root.querySelectorAll('.nwsb-enter-card'), function (card) {
      fillRail(card.querySelector('.nwsb-enter-rail'), card.getAttribute('data-go') || 'player');
    });

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
        if (e.target.closest('[data-go]')) return;
        var goId = card.getAttribute('data-go');
        if (goId && Math.abs(((rot % 360) + 360) % 360 - ((360 - i * STEP) % 360)) < 18) {
          go(goId);
          return;
        }
        if (Math.abs(rot) < 0.01 && !goId) return;
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
