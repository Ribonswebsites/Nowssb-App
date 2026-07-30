/* ══════════════════════════════════════════════════════════
   CUSTOMIZE — one hub for every appearance control.

   The customize icon used to lead straight into the Fashion Background
   picker, so background was the only thing reachable from the home. This
   puts all seven appearance controls behind that one tap instead:

     Themes · Background · Start Image · Quick Access
     Quick Links · Home Tiles · Set As You Like

   Every card just calls the opener that already exists — nothing here
   reimplements a picker, it only routes to them. The hub closes itself
   first, because three of those targets (Themes, Background, Start Image)
   are panels inside #sub-social at z-index 600 and would otherwise open
   underneath this overlay, which reads as "the button does nothing".
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var IMG = 'width:100%;height:100%;object-fit:cover;display:block;';

  var CARDS = [
    { k: 'themes',  label: 'Themes',         sub: 'Black Edition',        run: "SS.open('blackedition')",
      icon: '<svg viewBox="0 0 24 24" fill="none">' +
              '<rect x="2" y="2" width="20" height="20" rx="5" fill="#000" stroke="rgba(255,255,255,0.35)" stroke-width="1.5"/>' +
              '<rect x="6" y="6" width="5" height="5" rx="1.5" fill="rgba(255,255,255,0.12)" stroke="rgba(255,255,255,0.25)" stroke-width="1"/>' +
              '<rect x="13" y="6" width="5" height="5" rx="1.5" fill="rgba(232,213,163,0.3)" stroke="rgba(232,213,163,0.6)" stroke-width="1"/>' +
              '<rect x="6" y="13" width="5" height="5" rx="1.5" fill="rgba(255,255,255,0.06)" stroke="rgba(255,255,255,0.15)" stroke-width="1"/>' +
              '<rect x="13" y="13" width="5" height="5" rx="1.5" fill="rgba(200,232,245,0.12)" stroke="rgba(200,232,245,0.3)" stroke-width="1"/>' +
            '</svg>' },
    { k: 'bg',      label: 'Background',     sub: 'Fashion backdrop',     run: 'nwsbOpenFashionBgOverlay()',
      icon: '<img loading="lazy" decoding="async" alt="" style="' + IMG + '" src="https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784318203/file_00000000b11472098a225d3703b04a60_phr6ph.png">' },
    { k: 'startbg', label: 'Start Image',    sub: 'Art behind the start', run: "SS.open('startbg')",
      icon: '<img loading="lazy" decoding="async" alt="" style="' + IMG + '" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1785014506/file_000000009f10820bb6872a5ed8007148_pvqjaa.png">' },
    { k: 'qa',      label: 'Quick Access',   sub: 'Bottom nav bar',       run: "openSub('quick-access')",
      icon: '<img loading="lazy" decoding="async" alt="" style="' + IMG + ';border-radius:50%;" src="https://res.cloudinary.com/eenvubod/image/upload/v1784911241/file_000000002cf4820b865caf6fc0554959_k7drqx.png">' },
    { k: 'qlinks',  label: 'Quick Links',    sub: 'One-tap shortcuts',    run: 'qlOpen()',
      icon: '<svg viewBox="0 0 22 22" fill="none"><path d="M12 2 4 13h6l-1 7 9-11h-6l1-7Z" stroke="#fff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>' },
    { k: 'tiles',   label: 'Home Tiles',     sub: 'The four buttons',     run: 'htOpen()',
      icon: '<img loading="lazy" decoding="async" alt="" style="' + IMG + '" src="https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718779/f90f56e0-7386-11f1-ac66-23a66b2b6053_n5ahnk.png">' },
    { k: 'layout',  label: 'Set As You Like', sub: 'Order the sections',  run: 'hlOpen()',
      icon: '<svg viewBox="0 0 22 22" fill="none">' +
              '<rect x="3" y="2.5" width="16" height="4.2" rx="1" stroke="#fff" stroke-width="1.5"/>' +
              '<rect x="3" y="8.9" width="16" height="4.2" rx="1" stroke="rgba(255,255,255,0.5)" stroke-width="1.5"/>' +
              '<rect x="3" y="15.3" width="16" height="4.2" rx="1" stroke="rgba(255,255,255,0.5)" stroke-width="1.5"/>' +
            '</svg>' },
    /* A mode, not a destination — it toggles rather than opening anything,
       so it carries a switch instead of an Enter pill. Fashion home only. */
    { k: 'fashplus', label: 'Fashion Plus', sub: 'Motion on the Fashion home', run: 'fpToggle()', mode: 1,
      icon: '<svg viewBox="0 0 24 24" fill="none">' +
              '<path d="M5 5.5A1.5 1.5 0 0 1 6.5 4h11A1.5 1.5 0 0 1 19 5.5v13a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 5 18.5z" stroke="#fff" stroke-width="1.5"/>' +
              '<path d="M10.4 9.3 15 12l-4.6 2.7z" fill="#e8d5a3"/>' +
            '</svg>' }
  ];
  window.CU_CARDS = CARDS;

  var MARKUP =
    '<div class="cu-overlay" id="cuOverlay" onclick="if(event.target===this)cuClose()">' +
      '<div class="cu-box">' +
        '<div class="cu-head">' +
          '<div class="cu-head-icon"><img loading="lazy" decoding="async" alt="" style="' + IMG + '" ' +
            'src="https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784318203/file_00000000b11472098a225d3703b04a60_phr6ph.png"></div>' +
          '<div class="cu-head-txt">' +
            '<div class="cu-head-title">Customize</div>' +
            '<div class="cu-head-sub">Everything you can change, in one place</div>' +
          '</div>' +
          '<div class="cu-close" onclick="cuClose()"><svg viewBox="0 0 24 24" fill="none">' +
            '<path d="M6 6l12 12M18 6L6 18" stroke="rgba(255,255,255,0.75)" stroke-width="1.7" stroke-linecap="round"/></svg></div>' +
        '</div>' +
        '<div class="cu-grid">' +
          CARDS.map(function (c) {
            return '<div class="cu-card' + (c.mode ? ' cu-card-mode' : '') + '" onclick="cuGo(\'' + c.k + '\')">' +
                     '<div class="cu-card-icon">' + c.icon + '</div>' +
                     '<div class="cu-card-label">' + c.label + '</div>' +
                     '<div class="cu-card-sub">' + c.sub + '</div>' +
                     (c.mode
                       ? '<div class="cu-mode-sw" data-k="' + c.k + '"><div class="cu-mode-knob"></div></div>'
                       : '<div class="tp-enter cu-card-enter">' +
                           '<span class="tp-enter-lbl">Enter</span>' +
                           '<span class="tp-enter-go"><svg viewBox="0 0 12 12" fill="none">' +
                             '<path d="M2 6H10M7 3L10 6L7 9" stroke="#060c18" stroke-width="1.9" stroke-linecap="square"/>' +
                           '</svg></span>' +
                         '</div>') +
                   '</div>';
          }).join('') +
        '</div>' +
        '<div class="cu-corners">' +
          '<div class="cu-corners-label">Corners · every section, both homes</div>' +
          '<div class="cu-corners-row">' +
            '<div class="cu-corner-chip" id="cuCornerRound" onclick="cuPickCorners(\'round\')">' +
              '<span class="cu-corner-swatch cu-corner-swatch-round"></span>Rounded</div>' +
            '<div class="cu-corner-chip" id="cuCornerEdge" onclick="cuPickCorners(\'edge\')">' +
              '<span class="cu-corner-swatch cu-corner-swatch-edge"></span>Edges</div>' +
            '<div class="cu-corner-chip" id="cuCornerDefault" onclick="cuPickCorners(\'\')">Default</div>' +
          '</div>' +
          '<div class="cu-apply" id="cuApplyBtn" onclick="cuApplyCorners()">Apply</div>' +
        '</div>' +
        '<div class="cu-toast" id="cuToast"><span class="cu-toast-tick">' +
          '<svg viewBox="0 0 24 24" fill="none"><path d="M5 12l5 5L20 7" stroke="#060c18" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>' +
        '</span>Applied</div>' +
      '</div>' +
    '</div>';

  function mount() {
    if (document.getElementById('cuOverlay')) return;
    var d = document.createElement('div');
    d.innerHTML = MARKUP;
    document.body.appendChild(d.firstChild);
  }
  function haptic(ms) { try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) {} }

  /* ── Corners ───────────────────────────────────────────────────────
     One body class drives the radius of every top-level section on both
     homes at once. Unset is a real third state, not an absent one: the
     Normal home ships rounded and the Fashion home ships square, and
     without a way back to that mix, picking either option once would be
     a one-way door. ── */
  var CKEY = 'nwsb_home_corners';

  function readCorners() {
    var v; try { v = localStorage.getItem(CKEY); } catch (e) { v = null; }
    return (v === 'round' || v === 'edge') ? v : '';
  }
  /* What the chips are showing. Starts as whatever is committed; picking a
     chip only stages it, so nothing changes on the page until Apply. */
  var staged = null;

  function paintCorners() {
    var v = readCorners();
    document.body.classList.toggle('homecorner-round', v === 'round');
    document.body.classList.toggle('homecorner-edge', v === 'edge');
    var shown = (staged === null) ? v : staged;
    var btn = document.getElementById('cuApplyBtn');
    if (btn) {
      var dirty = shown !== v;
      btn.classList.toggle('on', dirty);
      btn.textContent = dirty ? 'Apply' : 'Applied';
    }
    [['cuCornerRound', 'round'], ['cuCornerEdge', 'edge'], ['cuCornerDefault', '']].forEach(function (pair) {
      var el = document.getElementById(pair[0]);
      if (el) el.classList.toggle('on', shown === pair[1]);
    });
  }

  window.cuPickCorners = function (v) {
    staged = (v === 'round' || v === 'edge') ? v : '';
    paintCorners();
    haptic(20);
  };

  window.cuApplyCorners = function () {
    if (staged === null) return;
    try {
      if (staged === 'round' || staged === 'edge') localStorage.setItem(CKEY, staged);
      else localStorage.removeItem(CKEY);
    } catch (e) {}
    staged = null;
    paintCorners();
    toast();
    haptic([30, 55, 30]);
  };

  /* The small "Applied" confirmation, same idea as the Fashion Background
     picker's — you need to see that the tap landed, since the change is
     behind the sheet you are still looking at. */
  var toastTimer = null;
  function toast() {
    var t = document.getElementById('cuToast');
    if (!t) return;
    t.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { t.classList.remove('show'); }, 1500);
  }

  /* Kept for anything that set corners directly before Apply existed. */
  window.cuSetCorners = function (v) { window.cuPickCorners(v); window.cuApplyCorners(); };

  /* Every mode card's switch, wherever it is rendered. */
  function paintModes() {
    var on = document.body.classList.contains('fashplus');
    document.querySelectorAll('.cu-mode-sw[data-k="fashplus"], .cust-mode-sw[data-k="fashplus"]')
      .forEach(function (el) { el.classList.toggle('on', on); });
  }
  window.cuPaintModes = paintModes;

  /* ── The Customize panel on the home ───────────────────────────────
     Same list as the hub, rendered as black banners inside the glass
     wrapper, so the panel can never list something the hub does not. ── */
  function renderPanels() {
    document.querySelectorAll('.cust-panel .cust-rows').forEach(function (host) {
      host.innerHTML = CARDS.map(function (c) {
        var arrow = c.mode
          ? '<div class="cust-mode-sw" data-k="' + c.k + '"><div class="cust-mode-knob"></div></div>'
          : '<div class="cust-row-arrow"><svg viewBox="0 0 24 24" fill="none">' +
              '<path d="M5 12h14M12 5l7 7-7 7" stroke="rgba(255,255,255,0.75)" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>' +
            '</svg></div>';
        return '<div class="cust-row" onclick="cuGo(\'' + c.k + '\')">' +
                 '<div class="cust-row-icon">' + c.icon + '</div>' +
                 '<div class="cust-row-divider"></div>' +
                 '<div class="cust-row-txt">' +
                   '<div class="cust-row-title">' + c.label + '</div>' +
                   '<div class="cust-row-sub">' + c.sub + '</div>' +
                 '</div>' + arrow +
               '</div>';
      }).join('');
    });
    paintModes();
    document.querySelectorAll('.cust-scroll').forEach(bindScroll);
  }
  window.cuRenderPanels = renderPanels;

  /* The panel is a fixed-height scroller, so it needs to say so — a track
     with a thumb whose size and position track the real scroll. */
  function bindScroll(sc) {
    var thumb = sc.querySelector('.cust-scrollthumb');
    var rows = sc.querySelector('.cust-rows');
    if (!thumb || !rows) return;
    function sync() {
      var vis = sc.clientHeight, all = sc.scrollHeight;
      if (all <= vis + 1) { sc.classList.add('no-scroll'); return; }
      sc.classList.remove('no-scroll');
      var h = Math.max(28, vis * (vis / all));
      thumb.style.height = h + 'px';
      thumb.style.transform = 'translateY(' + (sc.scrollTop / (all - vis)) * (vis - h) + 'px)';
    }
    if (!sc._cuBound) { sc._cuBound = true; sc.addEventListener('scroll', sync, { passive: true }); }
    requestAnimationFrame(sync);
  }

  window.cuOpen = function () {
    mount();
    staged = null;
    paintCorners();
    paintModes();
    var ov = document.getElementById('cuOverlay');
    requestAnimationFrame(function () { if (ov) ov.classList.add('open'); });
    haptic(28);
  };
  window.cuClose = function () {
    var ov = document.getElementById('cuOverlay');
    if (ov) ov.classList.remove('open');
  };

  window.cuGo = function (k) {
    var card = null;
    CARDS.forEach(function (c) { if (c.k === k) card = c; });
    if (!card) return;
    if (card.mode) {                 // a switch, not a door — stay open
      haptic(28);
      try { new Function(card.run)(); } catch (e) {}
      paintModes();
      return;
    }
    haptic(45);
    cuClose();
    // Wait out the close transition so a panel opening at a lower z-index
    // isn't briefly covered by this overlay on its way out.
    setTimeout(function () {
      try { new Function(card.run)(); } catch (e) {}
    }, 300);
  };

  // The corner choice has to be on <body> before first paint of the homes,
  // not only once the hub has been opened for the first time.
  function boot() { paintCorners(); renderPanels(); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
