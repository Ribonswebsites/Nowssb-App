/* ═══════════════════════════════════════════════════════════════
   NowssB Normal-Home (Neumorphism) controller
   - body.nm-mode  : active when the normal home is the chosen home
                     (localStorage nwsb_home_mode !== 'home')
   - body.nm-night : active when nm-mode AND the day/night toggle is dark
   - Suppresses the cinematic intros while in normal-home mode
   - Renders Today Trending + Today Offers on the normal home
   Inner-page neumorphism lives in nowssb-nm.css under body.nm-mode.
═══════════════════════════════════════════════════════════════ */
(function () {

  /* ── Body-class sync ── */
  function syncNmBody() {
    var mode = localStorage.getItem('nwsb_home_mode') || 'nm';
    var dark = localStorage.getItem('nwsb_nm_dark') === '1';
    var nm   = mode !== 'home';
    document.body.classList.toggle('nm-mode', nm);
    document.body.classList.toggle('nm-night', nm && dark);
  }
  window.nwsbSyncNmBody = syncNmBody;
  syncNmBody();

  /* ── Wrap a global fn so `after` runs once it finishes (retries until defined) ── */
  function wrapAfter(name, after) {
    var orig = window[name];
    if (typeof orig !== 'function') { return setTimeout(function () { wrapAfter(name, after); }, 150); }
    window[name] = function () {
      var r = orig.apply(this, arguments);
      try { after(); } catch (e) {}
      return r;
    };
  }
  wrapAfter('goTo',         syncNmBody);
  wrapAfter('nmhSwitchMode', syncNmBody);
  wrapAfter('openSub',      syncNmBody);

  /* ── Suppress cinematic intros while in normal-home mode ── */
  function patchIntros() {
    if (typeof window.shouldShowIntro !== 'function') { return setTimeout(patchIntros, 150); }
    var orig = window.shouldShowIntro;
    window.shouldShowIntro = function (key) {
      if (document.body.classList.contains('nm-mode')) return false; /* skip straight to content */
      return orig.apply(this, arguments);
    };
  }
  patchIntros();

  /* ══════════════════════════════════════════════════════════
     TODAY TRENDING + TODAY OFFERS  (auto-rotate daily by date)
  ══════════════════════════════════════════════════════════ */

  function dayIndex() {
    var now   = new Date();
    var start = new Date(now.getFullYear(), 0, 0);
    return Math.floor((now - start) / 86400000);
  }

  /* Deterministic daily slice of an array */
  function rotate(arr, count, offset) {
    if (!arr || !arr.length) return [];
    var out = [], n = arr.length, base = (dayIndex() + (offset || 0)) % n;
    if (base < 0) base += n;
    for (var i = 0; i < Math.min(count, n); i++) out.push(arr[(base + i) % n]);
    return out;
  }

  function getLib()      { try { return (typeof MASTER_WORD_LIBRARY !== 'undefined') ? MASTER_WORD_LIBRARY : []; } catch (e) { return []; } }
  function getTiers()    { try { return (typeof RM_TIERS         !== 'undefined') ? RM_TIERS         : {}; } catch (e) { return {}; } }
  function getWordTier() { try { return (typeof RM_WORD_TIER     !== 'undefined') ? RM_WORD_TIER     : {}; } catch (e) { return {}; } }

  function renderTrending() {
    var box = document.getElementById('nmh-trending-row');
    if (!box) return;
    var picks = rotate(getLib(), 6, 0);
    if (!picks.length) { var s = document.getElementById('nmh-trending-section'); if (s) s.style.display = 'none'; return; }
    box.innerHTML = picks.map(function (w) {
      return '<div class="nmh-trend-card" onclick="nwsbOpenStoreWord(\'' + String(w.word).replace(/'/g, '') + '\')">' +
        '<div class="nmh-trend-badge">Trending</div>' +
        '<div class="nmh-trend-word">' + (w.word || '') + '</div>' +
        '<div class="nmh-trend-organ">' + (w.organ || '') + '</div>' +
        '<div class="nmh-trend-benefit">' + (w.benefit || '') + '</div>' +
        '<div class="nmh-trend-cta">View in Store →</div>' +
      '</div>';
    }).join('');
  }

  function renderOffers() {
    var box = document.getElementById('nmh-offers-row');
    if (!box) return;
    var tiers = getTiers(), wordTier = getWordTier();
    var discounted = Object.keys(wordTier).filter(function (word) {
      var t = tiers[wordTier[word]];
      return t && t.discount;
    });
    var picks = rotate(discounted, 5, 3);
    var section = document.getElementById('nmh-offers-section');
    if (!picks.length) { if (section) section.style.display = 'none'; return; }
    if (section) section.style.display = '';
    box.innerHTML = picks.map(function (word) {
      var t = tiers[wordTier[word]] || {};
      return '<div class="nmh-offer-card" onclick="nwsbOpenStoreWord(\'' + String(word).replace(/'/g, '') + '\')">' +
        (t.discount ? '<div class="nmh-offer-badge">' + t.discount + '</div>' : '') +
        '<div class="nmh-offer-word">' + word + '</div>' +
        '<div class="nmh-offer-price">' +
          '<span class="nmh-offer-now">' + (t.price || '') + '</span>' +
          (t.origPrice ? '<span class="nmh-offer-was">' + t.origPrice + '</span>' : '') +
        '</div>' +
        '<div class="nmh-offer-cta">Grab Deal →</div>' +
      '</div>';
    }).join('');
  }

  /* Tap a trending/offer card → open the store */
  window.nwsbOpenStoreWord = function (word) {
    window._nwsbStoreTargetWord = word || null;
    if (typeof openSub === 'function') openSub('nowssb-store');
  };

  function renderHomeExtras() { renderTrending(); renderOffers(); }
  window.nwsbRenderHomeExtras = renderHomeExtras;

  /* Re-render the storefront whenever the normal home refreshes */
  wrapAfter('nmhRefresh', function () { syncNmBody(); renderHomeExtras(); });

  if (document.readyState !== 'loading') setTimeout(renderHomeExtras, 350);
  else document.addEventListener('DOMContentLoaded', function () { setTimeout(renderHomeExtras, 350); });

})();
