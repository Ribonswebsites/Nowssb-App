/* ══════════════════════════════════════════════════════════
   HOME TILES — style picker for the four home buttons
   (Sound Library / My Progress / Word Science / My Profile).

   This used to sit inside Quick Access, which is the BOTTOM NAV BAR
   customizer — a different thing entirely — so it now owns #sub-home-tiles,
   built on the same shell/UI as that page.

   The two homes are styled independently:
     Fashion Home (.home-tile)          → body.fashtile-* + body.fashcorner-*
     Normal Home  (.nmh-tile.nmh-tile-art) → body.nmtile-*  + body.nmcorner-*
   Every tile carries all the looks' pieces in its markup, so applying a style
   is a body-class swap — no re-render, no DOM surgery.

   Selections are STAGED: the previews update instantly, but nothing reaches
   the real tiles until "Apply Changes". Reset restores both defaults.

   Also drives the tip rail above each grid: a black pill that opens one tile
   at a time (icon · rule · what that button does), then the settings circle
   itself expands into a pill pointing at the tap target.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var HOME_TILES = [
    { name: 'Sound Library', sub: 'Root frequencies', tip: 'Root frequencies to practice with',
      icon: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157829/file_0000000039c8720893ebc07bba4d3afd_iq64ts.png',
      cover: 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_400/v1784899463/file_000000008bf881faa9949f7b7d9824bf_niqhps.png',
      photo: 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_400/v1784130175/grok_image_1784119058739_g0ihh7.jpg', photoPos: 'center',
      art: 'https://res.cloudinary.com/eenvubod/image/upload/e_trim,f_auto,q_auto,w_180/v1784123006/file_00000000048471f4ab69afc37df973c0_iab33r.png' },
    { name: 'My Progress', sub: 'Healing journey', tip: 'Your healing journey and body map',
      icon: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157829/file_00000000ae607208aa51504989648920_ml2czc.png',
      cover: 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_400/v1784899471/file_00000000345481faafd2bea97c8320ab_oknybe.png',
      photo: 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_400/v1784130175/grok_image_1784120246538_thvpik.jpg', photoPos: 'center top',
      art: 'https://res.cloudinary.com/eenvubod/image/upload/e_trim,f_auto,q_auto,w_180/v1784123007/file_000000009f8871f48dbd29b870dbdc9e_z9idoj.png' },
    { name: 'Word Science', sub: 'NOWSBANSIU texts', tip: 'The NOWSBANSIU word science texts',
      icon: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783158082/file_0000000086d872089ce376674620d5f3_mtfftb.png',
      cover: 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_400/v1784899472/file_00000000a24081fa83eeab9164647db8_w2fzuq.png',
      photo: 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_400/v1784130175/grok_image_1784120203500_t6zwrf.jpg', photoPos: 'center',
      art: 'https://res.cloudinary.com/eenvubod/image/upload/e_trim,f_auto,q_auto,w_180/v1784123007/file_0000000015b071f48397d34be0129b36_bx9cur.png' },
    { name: 'My Profile', sub: 'Your settings', tip: 'Your profile and app settings',
      icon: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563282/62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png',
      cover: 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_400/v1784896734/file_0000000080688207a9599e17a28e7710_oefkxy.png',
      photo: 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_400/v1784130232/grok_image_1784119291881_s6pws0.jpg', photoPos: 'center',
      art: 'https://res.cloudinary.com/eenvubod/image/upload/e_trim,f_auto,q_auto,w_180/v1784123007/file_00000000536071f4bf5172014811968f_jkt450.png' }
  ];

  /* The Normal Home's identity is the soft raised card the rest of that page is
     built from, so that stays its default; the Fashion Home defaults to black. */
  var FASH_STYLES = [{ id: 'black', label: 'Black Banner' }, { id: 'image', label: 'Cover Image' },
                     { id: 'artwork', label: 'Artwork' }, { id: 'classic', label: 'Classic Glass' }];
  var NM_STYLES   = [{ id: 'neuro', label: 'Standard' }, { id: 'artwork', label: 'Artwork' },
                     { id: 'black', label: 'Black' }, { id: 'image', label: 'Cover Image' }];
  var NM_SURFACES = [{ id: 'convex', label: 'Convex' }, { id: 'concave', label: 'Concave (Dimple)' }];
  function isSoft(style) { return style === 'neuro' || style === 'artwork'; }
  var CORNERS     = [{ id: 'rounded', label: 'Rounded' }, { id: 'edge', label: 'Edge' },
                     { id: 'pill', label: 'Pill Shape' }];

  var _stage = null;   // staged (unsaved) config

  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  // ── APPLIED (persisted) config ────────────────────────────────
  function savedFashStyle()  { var s = ls('nwsb_tile_style', 'black'); return (s === 'image' || s === 'classic' || s === 'artwork') ? s : 'black'; }
  function savedFashCorner() { var c = ls('nwsb_tile_corner', 'rounded'); return (c === 'edge' || c === 'pill') ? c : 'rounded'; }
  function savedNmStyle()    { var s = ls('nwsb_nm_tile_style', 'neuro'); return (s === 'black' || s === 'image' || s === 'artwork') ? s : 'neuro'; }
  function savedNmSurface()  { return ls('nwsb_nm_tile_surface', 'convex') === 'concave' ? 'concave' : 'convex'; }
  function savedNmCorner()   { var c = ls('nwsb_nm_tile_corner', 'rounded'); return (c === 'edge' || c === 'pill') ? c : 'rounded'; }

  function applyLive() {
    var b = document.body; if (!b) return;
    b.classList.remove('fashtile-black', 'fashtile-image', 'fashtile-artwork', 'fashtile-classic');
    b.classList.add('fashtile-' + savedFashStyle());
    b.classList.remove('fashcorner-rounded', 'fashcorner-edge', 'fashcorner-pill');
    b.classList.add('fashcorner-' + savedFashCorner());
    b.classList.remove('nmtile-neuro', 'nmtile-artwork', 'nmtile-black', 'nmtile-image');
    b.classList.add('nmtile-' + savedNmStyle());
    b.classList.remove('nmsurface-convex', 'nmsurface-concave');
    b.classList.add('nmsurface-' + savedNmSurface());
    b.classList.remove('nmcorner-rounded', 'nmcorner-edge', 'nmcorner-pill');
    b.classList.add('nmcorner-' + savedNmCorner());
  }

  // ── Render the picker (uses STAGED values) ────────────────────
  function loadStage() {
    _stage = { fashStyle: savedFashStyle(), fashCorner: savedFashCorner(),
               nmStyle: savedNmStyle(), nmCorner: savedNmCorner(), nmSurface: savedNmSurface() };
  }
  var ARROW = '<span class="qat-enter-go"><svg viewBox="0 0 12 12" fill="none"><path d="M2 6H10M7 3L10 6L7 9" stroke="#060c18" stroke-width="1.9" stroke-linecap="square"/></svg></span>';
  function previewHtml() {
    return HOME_TILES.map(function (t) {
      return '<div class="qat-tile">' +
        '<div class="qat-cover" style="background-image:url(\'' + t.cover + '\');"></div>' +
        '<div class="qat-scrim"></div>' +
        '<div class="qat-photo" style="background-image:url(\'' + t.photo + '\');background-position:' + t.photoPos + ';"></div>' +
        '<div class="qat-photo-scrim"></div>' +
        '<img class="qat-art" decoding="async" loading="lazy" src="' + t.art + '" alt="">' +
        '<span class="qat-ic"><img decoding="async" loading="lazy" src="' + t.icon + '" alt=""></span>' +
        '<span class="qat-rule"></span>' +
        '<span class="qat-txt"><span class="qat-name">' + t.name + '</span><span class="qat-sub">' + t.sub + '</span></span>' +
        '<span class="qat-enter"><span class="qat-enter-lbl">Enter</span>' + ARROW + '</span>' +
      '</div>';
    }).join('');
  }
  function chip(cur, o, fn) { return '<div class="qa-opt' + (o.id === cur ? ' active' : '') + '" onclick="' + fn + '(\'' + o.id + '\')">' + o.label + '</div>'; }
  function fill(id, html) { var el = document.getElementById(id); if (el) el.innerHTML = html; }
  function render() {
    if (!_stage) return;
    var f = document.getElementById('htFashGrid');
    if (f) { f.className = 'qat-grid qat-' + _stage.fashStyle + ' qat-corner-' + _stage.fashCorner; f.innerHTML = previewHtml(); }
    var n = document.getElementById('htNmGrid');
    if (n) {
      // Own class prefix: the Normal Home's looks are soft-surface cards, not
      // the Fashion Home's dark ones, so they can't share qat-<style>.
      n.className = 'qat-grid qat-nm-' + _stage.nmStyle + ' qat-corner-' + _stage.nmCorner +
                    ' qat-surf-' + _stage.nmSurface;
      n.innerHTML = previewHtml();
    }
    fill('htFashStyleRow',  FASH_STYLES.map(function (o) { return chip(_stage.fashStyle, o, 'htSetFashStyle'); }).join(''));
    fill('htFashCornerRow', CORNERS.map(function (o) { return chip(_stage.fashCorner, o, 'htSetFashCorner'); }).join(''));
    fill('htNmStyleRow',    NM_STYLES.map(function (o) { return chip(_stage.nmStyle, o, 'htSetNmStyle'); }).join(''));
    fill('htNmCornerRow',   CORNERS.map(function (o) { return chip(_stage.nmCorner, o, 'htSetNmCorner'); }).join(''));
    var sr = document.getElementById('htNmSurfaceRow');
    if (sr) {
      if (isSoft(_stage.nmStyle)) { sr.style.display = ''; sr.innerHTML = NM_SURFACES.map(function (o) { return chip(_stage.nmSurface, o, 'htSetNmSurface'); }).join(''); }
      else { sr.style.display = 'none'; sr.innerHTML = ''; }
    }
  }
  window.htRender = function () { loadStage(); render(); };

  /* Opening is self-contained on purpose. window.openSub is wrapped by ~17
     files, so relying on part012's branch to call htRender() means a single
     stale file in that chain leaves this page rendered but empty. Opening the
     screen and rendering it here keeps the two inseparable. */
  window.htOpen = function () {
    if (typeof window.openSub === 'function') window.openSub('home-tiles');
    else { var s = document.getElementById('sub-home-tiles'); if (s) s.classList.add('open'); }
    window.htRender();
  };

  // ── Toast ─────────────────────────────────────────────────────
  var HT_ICON = 'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718779/f90f56e0-7386-11f1-ac66-23a66b2b6053_n5ahnk.png';
  var _toastT = null;
  function toast(msg) {
    var scr = document.getElementById('sub-home-tiles'); if (!scr) return;
    var t = document.getElementById('htToast');
    if (!t) {
      t = document.createElement('div'); t.id = 'htToast'; t.className = 'qa-toast';
      t.innerHTML =
        '<div class="qa-toast-icon"><img decoding="async" src="' + HT_ICON + '" alt=""></div>' +
        '<div class="qa-toast-text"></div>' +
        '<div class="qa-toast-check"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#060c18" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg></div>';
      scr.appendChild(t);
    }
    t.querySelector('.qa-toast-text').textContent = msg;
    t.classList.add('show');
    if (_toastT) clearTimeout(_toastT);
    _toastT = setTimeout(function () { t.classList.remove('show'); }, 1800);
  }

  // ── Staged actions (preview only) ─────────────────────────────
  window.htSetFashStyle  = function (s) { if (!_stage) loadStage(); _stage.fashStyle = s; render(); };
  window.htSetFashCorner = function (c) { if (!_stage) loadStage(); _stage.fashCorner = c; render(); };
  window.htSetNmStyle    = function (s) { if (!_stage) loadStage(); _stage.nmStyle = s; render(); };
  window.htSetNmCorner   = function (c) { if (!_stage) loadStage(); _stage.nmCorner = c; render(); };
  window.htSetNmSurface  = function (v) { if (!_stage) loadStage(); _stage.nmSurface = v; render(); };

  // ── Apply / Reset (these DO write to the live tiles) ──────────
  function applyFash() {
    lsSet('nwsb_tile_style', _stage.fashStyle);
    lsSet('nwsb_tile_corner', _stage.fashCorner);
  }
  function applyNm() {
    lsSet('nwsb_nm_tile_style', _stage.nmStyle);
    lsSet('nwsb_nm_tile_corner', _stage.nmCorner);
    lsSet('nwsb_nm_tile_surface', _stage.nmSurface);
  }
  /* Each home applies on its own so the two sections never surprise each other,
     and Default is scoped the same way — the header Reset still does both. */
  window.htApplyFash = function () { if (!_stage) loadStage(); applyFash(); applyLive(); toast('Fashion home updated ✓'); };
  window.htApplyNm   = function () { if (!_stage) loadStage(); applyNm();   applyLive(); toast('Normal home updated ✓'); };
  window.htApply     = function () { if (!_stage) loadStage(); applyFash(); applyNm(); applyLive(); toast('Applied to your home ✓'); };
  window.htDefaultFash = function () {
    if (!_stage) loadStage();
    _stage.fashStyle = 'black'; _stage.fashCorner = 'rounded';
    applyFash(); applyLive(); render(); toast('Fashion home back to default');
  };
  window.htDefaultNm = function () {
    if (!_stage) loadStage();
    _stage.nmStyle = 'neuro'; _stage.nmCorner = 'rounded'; _stage.nmSurface = 'convex';
    applyNm(); applyLive(); render(); toast('Normal home back to default');
  };
  window.htReset = function () {
    lsSet('nwsb_tile_style', 'black');
    lsSet('nwsb_tile_corner', 'rounded');
    lsSet('nwsb_nm_tile_style', 'neuro');
    lsSet('nwsb_nm_tile_corner', 'rounded');
    lsSet('nwsb_nm_tile_surface', 'convex');
    applyLive();
    loadStage(); render();
    toast('Reset to default');
  };

  /* ══ TIP RAIL ══════════════════════════════════════════════════
     Above each tile grid: a black pill that opens one tile at a time
     (icon · vertical rule · what that button does), holds, then closes
     before the next one opens — deliberately unhurried. After the last
     one has fully closed, the settings circle itself grows leftward into
     a pill pointing back at the tap target. */
  var OPEN_MS = 900, HOLD_MS = 2100, CLOSE_MS = 900, GAP_MS = 450;
  var RAILS = [{ tip: 'nmhTileTip', set: 'nmhTileSet', end: 'nmhTileEnd' },
               { tip: 'fashTileTip', set: 'fashTileSet', end: 'fashTileEnd' }];
  var _timers = [];
  function later(fn, ms) { _timers.push(setTimeout(fn, ms)); }
  function eachTip(fn) { RAILS.forEach(function (r) { var el = document.getElementById(r.tip); if (el) fn(el); }); }
  function eachSet(fn) { RAILS.forEach(function (r) { var el = document.getElementById(r.set); if (el) fn(el); }); }
  function eachEnd(fn) { RAILS.forEach(function (r) { var el = document.getElementById(r.end); if (el) fn(el); }); }

  /* Measure an element's OPEN width without animating it there: kill the
     transition, toggle the class, read, restore — all inside one frame, so
     nothing paints. Reading it live instead would sample mid-transition and
     always come back too small. */
  function measureOpen(el) {
    var wasOpen = el.classList.contains('open');
    if (wasOpen) return el.getBoundingClientRect().width;
    var prev = el.style.transition;
    el.style.transition = 'none';
    el.classList.add('open');
    var w = el.getBoundingClientRect().width;
    el.classList.remove('open');
    void el.offsetWidth;              // flush, so removing the class can't animate
    el.style.transition = prev;
    return w;
  }
  /* Narrow phones can't hold both expanded pills at once. Checked just before
     the closing pill opens, so the settings pill collapses as the other grows
     — a handoff, not a visible open-then-close flip. */
  function fitRail() {
    RAILS.forEach(function (r) {
      var set = document.getElementById(r.set), end = document.getElementById(r.end);
      if (!set || !end) return;
      var rail = set.parentElement;
      if (!rail || !rail.clientWidth) return;
      var style = window.getComputedStyle(rail);
      var gap = parseFloat(style.columnGap || style.gap) || 0;
      var avail = rail.clientWidth - (parseFloat(style.paddingLeft) || 0) - (parseFloat(style.paddingRight) || 0);
      if (measureOpen(set) + measureOpen(end) + gap * 2 > avail) set.classList.remove('open');
    });
  }

  function showTip(i) {
    if (i >= HOME_TILES.length) {
      // Every tip is closed by now, so the circle can grow without overlapping it.
      later(function () {
        eachSet(function (el) { el.classList.add('open'); });
        // ...and once that pill has settled, the closing one opens on the far right.
        later(function () {
          fitRail();
          eachEnd(function (el) { el.classList.add('open'); });
        }, OPEN_MS + 500);
      }, GAP_MS);
      return;
    }
    var t = HOME_TILES[i];
    eachTip(function (el) {
      var img = el.querySelector('.htg-tip-ic img');
      if (img) img.src = t.icon;
      var txt = el.querySelector('.htg-tip-txt');
      if (txt) txt.textContent = t.tip;
      el.classList.add('open');
    });
    later(function () {
      eachTip(function (el) { el.classList.remove('open'); });
      later(function () { showTip(i + 1); }, CLOSE_MS + GAP_MS);
    }, OPEN_MS + HOLD_MS);
  }

  window.htRunTipRail = function () {
    _timers.forEach(clearTimeout); _timers = [];
    eachTip(function (el) { el.classList.remove('open'); });
    eachSet(function (el) { el.classList.remove('open'); });
    eachEnd(function (el) { el.classList.remove('open'); });
    later(function () { showTip(0); }, 600);
  };

  // ── Init — apply the saved look, then run the rail once ───────
  function init() {
    applyLive();
    loadStage();
    render();   // so the page is never blank, whichever way it gets opened
    if (!document.getElementById('nmhTileTip') && !document.getElementById('fashTileTip')) return;
    later(function () { if (!document.hidden) window.htRunTipRail(); }, 1800);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();

})();
