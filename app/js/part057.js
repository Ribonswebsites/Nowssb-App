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
    /* The five default slots must go through IG.nav() with the SAME route the
       stock nav bar uses — it also handles closing other screens, swapping to
       the social nav and setting the active highlight. Connect in particular
       is IG.nav('profile'), NOT 'home': routing it to 'home' just bounced the
       user to the home screen, which is why Connect stopped working once a
       nav customization had been applied. */
    { id: 'connect',      label: 'Connect',    img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/ea559460014dd8d9447072cdece7eb07f670832effdae7f062973b76151f3bde.webp', run: function () { if (window.IG) IG.nav('profile'); } },
    { id: 'practice',     label: 'Practice',   img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/44ed38a222535b9c30291d2e0b1c0217c7e5703cbc9fef0cad292a30a99414f5.webp', run: function () { if (window.IG) IG.nav('practice'); else if (typeof openPracticeIntro === 'function') openPracticeIntro(); } },
    { id: 'library',      label: 'Library',    img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/62e5d0908e54a2a619e9a80ef81fcb8f99de917b2ada10114250cf63f44978f4.webp', run: function () { if (window.IG) IG.nav('library'); else openSub('sound-library'); } },
    { id: 'store',        label: 'Store',      img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/86a128368819649971c48094f340d790cd2e7020f0ad78fd80e7f268edc6fe6d.webp', run: function () { if (window.IG) IG.nav('store'); else openSub('nowssb-store'); } },
    { id: 'profile',      label: 'Profile',    img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/3979b9fa35b579e61e60226665c68128ad03987930169b94504c89b3fe74ccc8.webp', run: function () { if (window.IG) IG.nav('myprofile'); else openSub('profile'); } },
    { id: 'progress',     label: 'Progress',   img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/0480c10b8a8d79dd38f0f5ffaf71f982cb92d7e49b8cbb3a9bd93bc6820c8a99.webp', run: function () { openSub('my-progress'); } },
    { id: 'wordscience',  label: 'Word Sci',   img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/dd44cf9fc35b783c2e30a7d85cff2f88eeca40d929d9fe19db47b941586210f7.webp', run: function () { openSub('word-science'); } },
    { id: 'meaningstore', label: 'Meaning',    img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/1a5f669e63dbae9d85d9c9de036d868f67d74e40a0bd42c178110839f9572cfa.png', run: function () { openSub('meaning-store'); } },
    { id: 'search',       label: 'Search',     img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/8d85320f63c3e1760c436ecb735a892202453e58b9a36178183dc6c2d7f72be4.webp', run: function () { openSub('search-choice'); } },
    { id: 'cart',         label: 'Cart',       img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/311c26afee2bc52c712ebb6fcce54014ce10264bcb6805954a9f3b45a9c99c5d.webp', run: function () { openSub('cart'); } },
    { id: 'wishlist',     label: 'Wishlist',   img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/a74a9935fb237eb82b17a92169d2b57e5a8733d5a3fd699754717fcd8869dfed.webp', run: function () { openSub('wishlist'); } },
    { id: 'routines',     label: 'Routines',   img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/307233cd22669455f19d52470a876209c8289b54081839108ba1b076bbf63926.png', run: function () { openSub('routines'); } },
    { id: 'chat',         label: 'Chat',       img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/db15f3026ea179dc265b5e8805e9e2288b69852af9cf4d7e4eac111b034d565e.webp', run: function () { if (typeof chatInboxOpen === 'function') chatInboxOpen(); } },
    { id: 'ai',           label: 'AI Rx',      img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/41c9ed21b2822c901ad8a28461e97ed8e682ad06730f6d245fd8bb3a718b71f7.png', run: function () { openSub('ai-prescription'); } },
    { id: 'streak',       label: 'Streak',     img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/f82047a0e727766b375647daaff93ba2784f6ac0ecf6c3f9b207639c3444529f.png', run: function () { openSub('streak'); } },
    { id: 'settings',     label: 'Settings',   img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/523b5889d13cb14a6fec694bea6199550bbf4ea9df232769f01e6cfa5ccbfd82.webp', run: function () { openSub('social'); } },
    { id: 'everything',   label: 'Everything', img: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/47f9e2c9fad5a78faa2e75819832c6648532079b7499b33175725fc3eaae80db.webp', run: function () { openSub('features'); } }
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

  // Intro page → main content, same transition Streak/AI Prescription use.
  window.qaEnterFromIntro = function () {
    var intro = document.getElementById('qaIntroPage');
    var main = document.getElementById('qaMainContent');
    if (intro) intro.classList.add('rm-intro-hidden');
    if (main) main.style.display = 'block';
  };

  // ── Toast ─────────────────────────────────────────────────────
  var _toastT = null;
  var QA_TOAST_ICON = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/272b820a002190feecdbb45d06acb8a2b6737bb411d9a4bf6459fa3171900b2b.png';
  function toast(msg) {
    var scr = document.getElementById('sub-quick-access'); if (!scr) return;
    var t = document.getElementById('qaToast');
    if (!t) {
      t = document.createElement('div'); t.id = 'qaToast'; t.className = 'qa-toast';
      t.innerHTML =
        '<div class="qa-toast-icon"><img decoding="async" src="' + QA_TOAST_ICON + '" alt=""></div>' +
        '<div class="qa-toast-text"></div>' +
        '<div class="qa-toast-check"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#060c18" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg></div>';
      scr.appendChild(t);
    }
    t.querySelector('.qa-toast-text').textContent = msg;
    t.classList.add('show');
    if (_toastT) clearTimeout(_toastT);
    _toastT = setTimeout(function () { t.classList.remove('show'); }, 1800);
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
