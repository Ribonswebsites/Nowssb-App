/* ══════════════════════════════════════════════════════════
   QUICK ACCESS — BOTTOM NAV-BAR CUSTOMIZER
   Live customizer for the app's bottom navigation bar (#ig-bottomnav):
   - Shape:  default (full-width) / floating pill / floating rectangle
             (rectangle offers Rounded vs Edge/sharp corners)
   - Colour: default glass / black
   - Icons:  pick up to 5 features (real NowssB pages), grouped into
             "In Your Nav" vs "Available", each with its real image icon.
   Selections are STAGED and only pushed to the live nav when the user
   taps "Apply Changes"; the preview updates instantly. Everything
   persists in localStorage and re-applies on load. Reset restores the
   original bar (Connect avatar / Practice / Library / Store / Profile).
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var FEATURES = [
    { id: 'connect',      label: 'Connect',    img: 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_120/v1784218818/file_00000000b84c7209ab496862cacd6a7f_kagsie.png', run: function () { if (window.IG) IG.nav('home'); } },
    { id: 'practice',     label: 'Practice',   img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563281/38538b80-56d8-11f1-8fad-095787cce754_xam2bb.png', run: function () { if (typeof openPracticeIntro === 'function') openPracticeIntro(); } },
    { id: 'library',      label: 'Library',    img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563282/c500a990-56cf-11f1-8fad-095787cce754_1_zqzbal.png', run: function () { openSub('sound-library'); } },
    { id: 'store',        label: 'Store',      img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563284/ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png', run: function () { openSub('nowssb-store'); } },
    { id: 'profile',      label: 'Profile',    img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563282/62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png', run: function () { openSub('profile'); } },
    { id: 'progress',     label: 'Progress',   img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157829/file_00000000ae607208aa51504989648920_ml2czc.png', run: function () { openSub('my-progress'); } },
    { id: 'wordscience',  label: 'Word Sci',   img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783158082/file_0000000086d872089ce376674620d5f3_mtfftb.png', run: function () { openSub('word-science'); } },
    { id: 'meaningstore', label: 'Meaning',    img: 'https://res.cloudinary.com/eenvubod/image/upload/v1784460474/file_00000000854881fa9a548a68fae59c15_w1utya.png', run: function () { openSub('meaning-store'); } },
    { id: 'search',       label: 'Search',     img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157830/file_00000000029c7208b5e915d9af2c480c_tuccwo.png', run: function () { openSub('search-choice'); } },
    { id: 'cart',         label: 'Cart',       img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157830/file_00000000f02c72088cd128f3f4b08af5_vskoom.png', run: function () { openSub('cart'); } },
    { id: 'wishlist',     label: 'Wishlist',   img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157830/file_0000000055d8720895f7ba98c4a7bf4a_s2lzab.png', run: function () { openSub('wishlist'); } },
    { id: 'routines',     label: 'Routines',   img: 'https://res.cloudinary.com/eenvubod/image/upload/v1784361579/file_00000000f740820ba6aaa761133e8889_fitm0p.png', run: function () { openSub('routines'); } },
    { id: 'chat',         label: 'Chat',       img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1780123160/1ae1b990-5bf2-11f1-8248-b91d5cd919c2_z3xi3j.png', run: function () { if (typeof chatInboxOpen === 'function') chatInboxOpen(); } },
    { id: 'ai',           label: 'AI Rx',      img: 'https://res.cloudinary.com/eenvubod/image/upload/v1784895543/file_0000000062a882089abd27eb90ea3945_ngqyu6.png', run: function () { openSub('ai-prescription'); } },
    { id: 'streak',       label: 'Streak',     img: 'https://res.cloudinary.com/eenvubod/image/upload/v1784895543/file_0000000010fc820891f9e15a38316d2b_ffffhq.png', run: function () { openSub('streak'); } },
    { id: 'settings',     label: 'Settings',   img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563283/260480b0-56d8-11f1-8fad-095787cce754_rz6zbi.png', run: function () { openSub('social'); } }
  ];
  var DEFAULT_SLOTS = ['connect', 'practice', 'library', 'store', 'profile'];
  var SHAPES  = [{ id: 'default', label: 'Default' }, { id: 'pill', label: 'Floating Pill' }, { id: 'rect', label: 'Floating Rectangle' }];
  var CORNERS = [{ id: 'rounded', label: 'Rounded Corners' }, { id: 'edge', label: 'Edge Corners' }];
  var COLORS  = [{ id: 'glass', label: 'Default Glass' }, { id: 'black', label: 'Black' }];
  var PENCIL  = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/></svg>';

  var _navDefaultHTML = null;   // pristine #ig-bottomnav markup (incl. live avatar) for Reset
  var _stage = null;            // staged (unsaved) config: {shape,color,corner,slots}

  function feat(id) { for (var i = 0; i < FEATURES.length; i++) if (FEATURES[i].id === id) return FEATURES[i]; return null; }
  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  // ── APPLIED (persisted) config ────────────────────────────────
  function savedShape()  { var s = ls('nwsb_nav_shape', 'default'); return (s === 'pill' || s === 'rect') ? s : 'default'; }
  function savedColor()  { return ls('nwsb_nav_color', 'glass') === 'black' ? 'black' : 'glass'; }
  function savedCorner() { return ls('nwsb_nav_rect_corner', 'rounded') === 'edge' ? 'edge' : 'rounded'; }
  function savedSlots() {
    var raw = ls('nwsb_nav_slots', null);
    if (raw) { try { var a = JSON.parse(raw); if (a && a.length) { a = a.filter(function (id) { return !!feat(id); }).slice(0, 5); if (a.length) return a; } } catch (e) {} }
    return DEFAULT_SLOTS.slice();
  }
  function isDefaultApplied() {
    if (savedShape() !== 'default' || savedColor() !== 'glass') return false;
    var s = savedSlots(); if (s.length !== DEFAULT_SLOTS.length) return false;
    for (var i = 0; i < s.length; i++) if (s[i] !== DEFAULT_SLOTS[i]) return false;
    return true;
  }

  // ── Apply to the LIVE bottom nav (uses persisted values) ──────
  function applyShapeColor() {
    var b = document.body; if (!b) return;
    b.classList.remove('navshape-default', 'navshape-pill', 'navshape-rect');
    b.classList.add('navshape-' + savedShape());
    b.classList.remove('navcorner-rounded', 'navcorner-edge');
    b.classList.add('navcorner-' + savedCorner());
    b.classList.remove('navcolor-glass', 'navcolor-black');
    b.classList.add('navcolor-' + savedColor());
  }
  function applyIcons() {
    var nav = document.getElementById('ig-bottomnav'); if (!nav) return;
    var btns = nav.querySelectorAll('.ig-nav-btn'); if (btns.length < 5) return;
    var slots = savedSlots();
    for (var i = 0; i < 5; i++) {
      var f = feat(slots[i]) || feat(DEFAULT_SLOTS[i]);
      var btn = btns[i];
      btn.innerHTML =
        '<span class="ig-nav-puck"><img class="ig-nav-img' + (f.id === 'connect' ? ' ig-nav-img-connect' : '') + '" decoding="async" loading="lazy" src="' + f.img + '" alt=""></span>' +
        '<span class="ig-nav-label">' + f.label + '</span>';
      (function (run) { btn.onclick = function () { if (run) run(); }; })(f.run);
    }
  }
  function applyLive() {
    applyShapeColor();
    if (isDefaultApplied()) { restoreDefaultNav(); }
    else { applyIcons(); }
  }
  function restoreDefaultNav() {
    var nav = document.getElementById('ig-bottomnav');
    if (nav && _navDefaultHTML != null) nav.innerHTML = _navDefaultHTML;
  }

  // ── Render the customizer (uses STAGED values) ────────────────
  function loadStage() {
    _stage = { shape: savedShape(), color: savedColor(), corner: savedCorner(), slots: savedSlots() };
  }
  function renderPreview() {
    var el = document.getElementById('qaNavPreview'); if (!el || !_stage) return;
    el.className = 'qa-nav-preview qa-prev-' + _stage.shape + ' qa-prevcorner-' + _stage.corner + ' qa-prevcol-' + _stage.color;
    var html = '<div class="qa-prev-bar">';
    for (var i = 0; i < 5; i++) {
      var f = feat(_stage.slots[i]) || feat(DEFAULT_SLOTS[i]);
      html += '<div class="qa-prev-item"><span class="qa-prev-puck' + (f.id === 'connect' ? ' qa-prev-connect' : '') + '"><img src="' + f.img + '" alt=""></span><span class="qa-prev-lbl">' + f.label + '</span></div>';
    }
    el.innerHTML = html + '</div>';
  }
  function chip(cur, o, fn) { return '<div class="qa-opt' + (o.id === cur ? ' active' : '') + '" onclick="' + fn + '(\'' + o.id + '\')">' + o.label + '</div>'; }
  function renderChips() {
    if (!_stage) return;
    var sh = document.getElementById('qaShapeRow');
    if (sh) sh.innerHTML = SHAPES.map(function (o) { return chip(_stage.shape, o, 'qaSetShape'); }).join('');
    var cr = document.getElementById('qaCornerRow');
    if (cr) {
      if (_stage.shape === 'rect') { cr.style.display = ''; cr.innerHTML = CORNERS.map(function (o) { return chip(_stage.corner, o, 'qaSetCorner'); }).join(''); }
      else { cr.style.display = 'none'; cr.innerHTML = ''; }
    }
    var co = document.getElementById('qaColorRow');
    if (co) co.innerHTML = COLORS.map(function (o) { return chip(_stage.color, o, 'qaSetColor'); }).join('');
  }
  function tileHtml(f, selIdx) {
    var sel = selIdx >= 0;
    return '<div class="qa-feat' + (sel ? ' sel' : '') + (f.id === 'connect' ? ' qa-feat-connect' : '') + '" onclick="qaToggleFeature(\'' + f.id + '\')">' +
      '<span class="qa-feat-edit">' + PENCIL + '</span>' +
      (sel ? '<span class="qa-feat-num">' + (selIdx + 1) + '</span>' : '') +
      '<span class="qa-feat-ic"><img src="' + f.img + '" alt=""></span>' +
      '<span class="qa-feat-lbl">' + f.label + '</span></div>';
  }
  function renderFeatures() {
    var wrap = document.getElementById('qaFeatWrap'); if (!wrap || !_stage) return;
    var slots = _stage.slots;
    var selFeats = slots.map(function (id) { return feat(id); }).filter(Boolean);
    var nonSel = FEATURES.filter(function (f) { return slots.indexOf(f.id) < 0; });
    var html = '';
    html += '<div class="qa-group-banner">In Your Nav · ' + slots.length + ' / 5</div>';
    html += '<div class="qa-feat-grid">' + selFeats.map(function (f) { return tileHtml(f, slots.indexOf(f.id)); }).join('') + '</div>';
    html += '<div class="qa-group-divider"></div>';
    html += '<div class="qa-group-banner">Available Features</div>';
    html += '<div class="qa-feat-grid">' + (nonSel.length ? nonSel.map(function (f) { return tileHtml(f, -1); }).join('') : '<div class="qa-feat-empty">All features are in your nav.</div>') + '</div>';
    wrap.innerHTML = html;
    var cnt = document.getElementById('qaSlotCount'); if (cnt) cnt.textContent = slots.length + ' / 5';
  }
  function render() { renderPreview(); renderChips(); renderFeatures(); }
  window.qaNavRender = function () { loadStage(); render(); };

  // ── Toast ─────────────────────────────────────────────────────
  var _toastT = null;
  function toast(msg) {
    var scr = document.getElementById('sub-quick-access'); if (!scr) return;
    var t = document.getElementById('qaToast');
    if (!t) { t = document.createElement('div'); t.id = 'qaToast'; t.className = 'qa-toast'; scr.appendChild(t); }
    t.textContent = msg; t.classList.add('show');
    if (_toastT) clearTimeout(_toastT);
    _toastT = setTimeout(function () { t.classList.remove('show'); }, 1600);
  }

  // ── Staged actions (preview only — nothing hits the live nav) ─
  window.qaSetShape = function (s) { if (!_stage) loadStage(); _stage.shape = s; render(); };
  window.qaSetCorner = function (c) { if (!_stage) loadStage(); _stage.corner = c; render(); };
  window.qaSetColor = function (c) { if (!_stage) loadStage(); _stage.color = c; render(); };
  window.qaToggleFeature = function (id) {
    if (!_stage) loadStage();
    var slots = _stage.slots.slice();
    var idx = slots.indexOf(id);
    if (idx >= 0) { if (slots.length <= 1) return; slots.splice(idx, 1); }
    else { if (slots.length >= 5) slots.shift(); slots.push(id); }
    _stage.slots = slots; render();
  };

  // ── Apply / Reset (these DO write to the live nav) ────────────
  window.qaApplyNav = function () {
    if (!_stage) loadStage();
    lsSet('nwsb_nav_shape', _stage.shape);
    lsSet('nwsb_nav_color', _stage.color);
    lsSet('nwsb_nav_rect_corner', _stage.corner);
    lsSet('nwsb_nav_slots', JSON.stringify(_stage.slots));
    applyLive();
    toast('Applied to your nav ✓');
  };
  window.qaResetNav = function () {
    lsSet('nwsb_nav_shape', 'default');
    lsSet('nwsb_nav_color', 'glass');
    lsSet('nwsb_nav_rect_corner', 'rounded');
    lsSet('nwsb_nav_slots', JSON.stringify(DEFAULT_SLOTS.slice()));
    applyShapeColor();
    restoreDefaultNav();
    loadStage(); render();
    toast('Reset to default');
  };

  // ── Init — apply saved config to the live nav on load ─────────
  function init() {
    var nav = document.getElementById('ig-bottomnav');
    if (nav && _navDefaultHTML == null) _navDefaultHTML = nav.innerHTML;
    applyLive();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();

})();
