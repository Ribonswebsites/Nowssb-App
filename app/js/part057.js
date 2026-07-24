/* ══════════════════════════════════════════════════════════
   QUICK ACCESS — BOTTOM NAV-BAR CUSTOMIZER
   Turns the Quick Access page (#sub-quick-access) into a live
   customizer for the app's bottom navigation bar (#ig-bottomnav):
   - Shape:  default (full-width) / floating pill / floating rectangle
   - Colour: default glass / black
   - Icons:  pick up to 5 features (real NowssB pages) to fill the bar,
             each with its real image icon and tap-to-open action.
   Everything applies live and persists in localStorage; a Reset
   restores the original nav (Connect avatar / Practice / Library /
   Store / Profile). Wired from openSub()'s id==='quick-access' branch.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  // Real NowssB feature icons (reused from the hamburger menu / nav / pages)
  // + their real open actions, so tapping a customized nav slot behaves
  // exactly like opening that feature anywhere else in the app.
  var FEATURES = [
    { id: 'connect',      label: 'Connect',    img: 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_120/v1784218818/file_00000000b84c7209ab496862cacd6a7f_kagsie.png', run: function () { if (window.IG) IG.nav('home'); } },
    { id: 'practice',     label: 'Practice',   img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563281/38538b80-56d8-11f1-8fad-095787cce754_xam2bb.png', run: function () { if (typeof openPracticeIntro === 'function') openPracticeIntro(); } },
    { id: 'library',      label: 'Library',    img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563282/c500a990-56cf-11f1-8fad-095787cce754_1_zqzbal.png', run: function () { openSub('sound-library'); } },
    { id: 'store',        label: 'Store',      img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563284/ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png', run: function () { openSub('nowssb-store'); } },
    { id: 'profile',      label: 'Profile',    img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563282/62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png', run: function () { openSub('profile'); } },
    { id: 'progress',     label: 'Progress',   img: 'https://res.cloudinary.com/ds6duqabl/image/upload/q_auto/f_auto/v1779639181/a7b04840-5789-11f1-9331-1302872077be_bqobig.png', run: function () { openSub('my-progress'); } },
    { id: 'wordscience',  label: 'Word Sci',   img: 'https://res.cloudinary.com/ds6duqabl/image/upload/q_auto/f_auto/v1779639180/f89da3a0-578a-11f1-9331-1302872077be_xfgkbq.png', run: function () { openSub('word-science'); } },
    { id: 'meaningstore', label: 'Meaning',    img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779558988/cb456de0-56cf-11f1-8fad-095787cce754_zplzrc.png', run: function () { openSub('meaning-store'); } },
    { id: 'routines',     label: 'Routines',   img: 'https://res.cloudinary.com/eenvubod/image/upload/v1784361579/file_00000000f740820ba6aaa761133e8889_fitm0p.png', run: function () { openSub('routines'); } },
    { id: 'chat',         label: 'Chat',       img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1780123160/1ae1b990-5bf2-11f1-8248-b91d5cd919c2_z3xi3j.png', run: function () { if (typeof chatInboxOpen === 'function') chatInboxOpen(); } },
    { id: 'ai',           label: 'AI Rx',      img: 'https://res.cloudinary.com/eenvubod/image/upload/v1784895543/file_0000000062a882089abd27eb90ea3945_ngqyu6.png', run: function () { openSub('ai-prescription'); } },
    { id: 'streak',       label: 'Streak',     img: 'https://res.cloudinary.com/eenvubod/image/upload/v1784895543/file_0000000010fc820891f9e15a38316d2b_ffffhq.png', run: function () { openSub('streak'); } }
  ];
  var DEFAULT_SLOTS = ['connect', 'practice', 'library', 'store', 'profile'];
  var SHAPES = [{ id: 'default', label: 'Default' }, { id: 'pill', label: 'Floating Pill' }, { id: 'rect', label: 'Floating Rectangle' }];
  var COLORS = [{ id: 'glass', label: 'Default Glass' }, { id: 'black', label: 'Black' }];

  var _navDefaultHTML = null;   // pristine #ig-bottomnav markup (incl. live avatar) for Reset

  function feat(id) { for (var i = 0; i < FEATURES.length; i++) if (FEATURES[i].id === id) return FEATURES[i]; return null; }
  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  function getShape() { var s = ls('nwsb_nav_shape', 'default'); return (s === 'pill' || s === 'rect') ? s : 'default'; }
  function getColor() { var c = ls('nwsb_nav_color', 'glass'); return c === 'black' ? 'black' : 'glass'; }
  function getSlots() {
    var raw = ls('nwsb_nav_slots', null);
    if (!raw) return DEFAULT_SLOTS.slice();
    try {
      var arr = JSON.parse(raw);
      if (Object.prototype.toString.call(arr) === '[object Array]') {
        arr = arr.filter(function (id) { return !!feat(id); }).slice(0, 5);
        if (arr.length) return arr;
      }
    } catch (e) {}
    return DEFAULT_SLOTS.slice();
  }
  function setSlots(a) { lsSet('nwsb_nav_slots', JSON.stringify(a)); }

  function isDefaultConfig() {
    if (getShape() !== 'default' || getColor() !== 'glass') return false;
    var s = getSlots();
    if (s.length !== DEFAULT_SLOTS.length) return false;
    for (var i = 0; i < s.length; i++) if (s[i] !== DEFAULT_SLOTS[i]) return false;
    return true;
  }

  // ── Apply to the LIVE bottom nav ──────────────────────────────
  function applyShapeColor() {
    var b = document.body; if (!b) return;
    b.classList.remove('navshape-default', 'navshape-pill', 'navshape-rect');
    b.classList.add('navshape-' + getShape());
    b.classList.remove('navcolor-glass', 'navcolor-black');
    b.classList.add('navcolor-' + getColor());
  }
  function applyIcons() {
    var nav = document.getElementById('ig-bottomnav'); if (!nav) return;
    var btns = nav.querySelectorAll('.ig-nav-btn'); if (btns.length < 5) return;
    var slots = getSlots();
    for (var i = 0; i < 5; i++) {
      var f = feat(slots[i]) || feat(DEFAULT_SLOTS[i]);
      var btn = btns[i];
      btn.innerHTML =
        '<span class="ig-nav-puck"><img class="ig-nav-img" decoding="async" loading="lazy" src="' + f.img + '" alt=""></span>' +
        '<span class="ig-nav-label">' + f.label + '</span>';
      (function (run) { btn.onclick = function () { if (run) run(); }; })(f.run);
    }
  }
  function applyAll() {
    applyShapeColor();
    if (!isDefaultConfig()) applyIcons();
  }

  // ── Render the customizer UI ──────────────────────────────────
  function renderPreview() {
    var el = document.getElementById('qaNavPreview'); if (!el) return;
    var slots = getSlots();
    el.className = 'qa-nav-preview qa-prev-' + getShape() + ' qa-prevcol-' + getColor();
    var html = '<div class="qa-prev-bar">';
    for (var i = 0; i < 5; i++) {
      var f = feat(slots[i]) || feat(DEFAULT_SLOTS[i]);
      html += '<div class="qa-prev-item"><span class="qa-prev-puck"><img src="' + f.img + '" alt=""></span><span class="qa-prev-lbl">' + f.label + '</span></div>';
    }
    el.innerHTML = html + '</div>';
  }
  function renderChips() {
    var sh = document.getElementById('qaShapeRow');
    var cur = getShape();
    if (sh) sh.innerHTML = SHAPES.map(function (s) {
      return '<div class="qa-opt' + (s.id === cur ? ' active' : '') + '" onclick="qaSetShape(\'' + s.id + '\')">' + s.label + '</div>';
    }).join('');
    var co = document.getElementById('qaColorRow');
    var curC = getColor();
    if (co) co.innerHTML = COLORS.map(function (c) {
      return '<div class="qa-opt' + (c.id === curC ? ' active' : '') + '" onclick="qaSetColor(\'' + c.id + '\')">' + c.label + '</div>';
    }).join('');
  }
  function renderFeatures() {
    var el = document.getElementById('qaFeatGrid'); if (!el) return;
    var slots = getSlots();
    el.innerHTML = FEATURES.map(function (f) {
      var idx = slots.indexOf(f.id);
      var sel = idx >= 0;
      return '<div class="qa-feat' + (sel ? ' sel' : '') + '" onclick="qaToggleFeature(\'' + f.id + '\')">' +
        (sel ? '<span class="qa-feat-num">' + (idx + 1) + '</span>' : '') +
        '<span class="qa-feat-ic"><img src="' + f.img + '" alt=""></span>' +
        '<span class="qa-feat-lbl">' + f.label + '</span></div>';
    }).join('');
    var cnt = document.getElementById('qaSlotCount'); if (cnt) cnt.textContent = slots.length + ' / 5';
  }
  function render() { renderPreview(); renderChips(); renderFeatures(); }
  window.qaNavRender = render;

  // ── Public actions ────────────────────────────────────────────
  window.qaSetShape = function (s) { lsSet('nwsb_nav_shape', s); applyShapeColor(); render(); };
  window.qaSetColor = function (c) { lsSet('nwsb_nav_color', c); applyShapeColor(); render(); };
  window.qaToggleFeature = function (id) {
    var slots = getSlots().slice();
    var idx = slots.indexOf(id);
    if (idx >= 0) {
      if (slots.length <= 1) return;          // never allow an empty bar
      slots.splice(idx, 1);
    } else {
      if (slots.length >= 5) slots.shift();   // tapping a 6th replaces the oldest
      slots.push(id);
    }
    setSlots(slots);
    applyIcons();
    render();
  };
  window.qaResetNav = function () {
    lsSet('nwsb_nav_shape', 'default');
    lsSet('nwsb_nav_color', 'glass');
    setSlots(DEFAULT_SLOTS.slice());
    applyShapeColor();
    var nav = document.getElementById('ig-bottomnav');
    if (nav && _navDefaultHTML != null) nav.innerHTML = _navDefaultHTML;
    render();
  };

  // ── Init ──────────────────────────────────────────────────────
  function init() {
    var nav = document.getElementById('ig-bottomnav');
    if (nav && _navDefaultHTML == null) _navDefaultHTML = nav.innerHTML;
    applyAll();
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
