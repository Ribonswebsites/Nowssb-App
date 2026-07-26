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
            '</svg>' }
  ];

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
            return '<div class="cu-card" onclick="cuGo(\'' + c.k + '\')">' +
                     '<div class="cu-card-icon">' + c.icon + '</div>' +
                     '<div class="cu-card-label">' + c.label + '</div>' +
                     '<div class="cu-card-sub">' + c.sub + '</div>' +
                   '</div>';
          }).join('') +
        '</div>' +
        '<div class="cu-corners">' +
          '<div class="cu-corners-label">Corners · every section, both homes</div>' +
          '<div class="cu-corners-row">' +
            '<div class="cu-corner-chip" id="cuCornerRound" onclick="cuSetCorners(\'round\')">' +
              '<span class="cu-corner-swatch cu-corner-swatch-round"></span>Rounded</div>' +
            '<div class="cu-corner-chip" id="cuCornerEdge" onclick="cuSetCorners(\'edge\')">' +
              '<span class="cu-corner-swatch cu-corner-swatch-edge"></span>Edges</div>' +
            '<div class="cu-corner-chip" id="cuCornerDefault" onclick="cuSetCorners(\'\')">Default</div>' +
          '</div>' +
        '</div>' +
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
  function paintCorners() {
    var v = readCorners();
    document.body.classList.toggle('homecorner-round', v === 'round');
    document.body.classList.toggle('homecorner-edge', v === 'edge');
    [['cuCornerRound', 'round'], ['cuCornerEdge', 'edge'], ['cuCornerDefault', '']].forEach(function (pair) {
      var el = document.getElementById(pair[0]);
      if (el) el.classList.toggle('on', v === pair[1]);
    });
  }
  window.cuSetCorners = function (v) {
    try {
      if (v === 'round' || v === 'edge') localStorage.setItem(CKEY, v);
      else localStorage.removeItem(CKEY);
    } catch (e) {}
    paintCorners();
    haptic(28);
  };

  window.cuOpen = function () {
    mount();
    paintCorners();
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
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', paintCorners);
  else paintCorners();

})();
