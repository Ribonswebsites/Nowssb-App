/* ══════════════════════════════════════════════════════════
   CONTENT — the catalogue, as data rather than as code.

   Every word and every meaning in this app was written into a JavaScript
   file: fifteen categories in part010.js, twenty-four meanings in
   part026.js. That is why nothing the studio does could ever change them —
   an edit meant a deploy. This file is the layer that makes them content.

   Three sources, in the order they arrive
   ---------------------------------------
   1. The shipped lists. Already in the page, so the shelf is never empty
      and a first-ever visit with no connection looks exactly as it does
      today. Nothing here can make the app worse than it was.
   2. The last copy seen, kept in localStorage. Applied immediately on the
      next launch, so a published edit survives being offline and does not
      wait on a round trip.
   3. Firestore, live. content/words and content/meanings, watched rather
      than fetched, so an edit in the studio lands on every open app
      without anybody reloading.

   Each one overwrites the one before it, and only if it actually parses.
   A malformed document leaves the previous state alone rather than
   emptying the store — the failure mode of a bad publish is "no change",
   never "no catalogue".

   Cost: two documents, watched. Not two hundred — the whole catalogue is
   an array inside one document per kind, which is one read to open and one
   more per edit, rather than a read per word.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var K_WORDS = 'nwsb_content_words';
  var K_MEANINGS = 'nwsb_content_meanings';

  window.NWSB_CONTENT = { words: null, meanings: null, source: 'default' };

  function ls(k) { try { return localStorage.getItem(k); } catch (e) { return null; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  /* ── What a valid catalogue looks like ─────────────────────────────
     Checked before anything is applied. This is the whole safety net: a
     half-written or wrongly-shaped document is refused here, and the app
     keeps whatever it already had. ── */
  function validWords(cats) {
    if (!Array.isArray(cats) || !cats.length) return false;
    return cats.every(function (c) {
      return c && typeof c.label === 'string' && Array.isArray(c.words) &&
        c.words.every(function (w) { return Array.isArray(w) && typeof w[0] === 'string'; });
    });
  }
  function validMeanings(list) {
    if (!Array.isArray(list) || !list.length) return false;
    return list.every(function (m) {
      return m && typeof m.key === 'string' && typeof m.word === 'string';
    });
  }

  /* ── Applying ──────────────────────────────────────────────────────
     The meanings array is mutated rather than replaced: msRenderStore and
     part053.js both close over the array part026.js created, so handing
     them a new one would leave them drawing the old catalogue forever. */
  function applyWords(cats) {
    if (!validWords(cats)) return false;
    window.NWSB_CONTENT.words = cats;
    if (window.rmRenderWordSections) {
      try { window.rmRenderWordSections(cats); } catch (e) { return false; }
    }
    return true;
  }

  function applyMeanings(list) {
    if (!validMeanings(list)) return false;
    var live = window.MS_BASE_MEANINGS;
    if (!Array.isArray(live)) return false;
    live.length = 0;
    for (var i = 0; i < list.length; i++) live.push(list[i]);
    window.NWSB_CONTENT.meanings = live;
    if (window.msRenderStore) { try { window.msRenderStore(); } catch (e) {} }
    return true;
  }

  function announce(source) {
    window.NWSB_CONTENT.source = source;
    try { window.dispatchEvent(new CustomEvent('nwsb-content', { detail: { source: source } })); } catch (e) {}
  }

  /* ── 2. The last copy seen ─────────────────────────────────────────
     Before the network is asked anything, so a published catalogue is on
     screen at first paint rather than a beat later. */
  function applyCache() {
    var any = false;
    var w = ls(K_WORDS), m = ls(K_MEANINGS);
    if (w) { try { if (applyWords(JSON.parse(w))) any = true; } catch (e) {} }
    if (m) { try { if (applyMeanings(JSON.parse(m))) any = true; } catch (e) {} }
    if (any) announce('cache');
  }

  /* ── 3. Firestore, watched ─────────────────────────────────────────
     onSnapshot rather than getDoc: the studio publishes and every open app
     redraws. The rules make this readable without signing in — the
     catalogue is public, that is what a shop is. */
  function watch() {
    if (!window._db) return false;
    import('https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js').then(function (fs) {
      var db = window._db;

      fs.onSnapshot(fs.doc(db, 'content', 'words'), function (snap) {
        if (!snap.exists()) return;
        var cats = (snap.data() || {}).categories;
        if (applyWords(cats)) { lsSet(K_WORDS, JSON.stringify(cats)); announce('live'); }
      }, function () { /* offline or refused — the cache stands */ });

      fs.onSnapshot(fs.doc(db, 'content', 'meanings'), function (snap) {
        if (!snap.exists()) return;
        var list = (snap.data() || {}).items;
        if (applyMeanings(list)) { lsSet(K_MEANINGS, JSON.stringify(list)); announce('live'); }
      }, function () {});
    }).catch(function () {});
    return true;
  }

  /* ── What the studio publishes ─────────────────────────────────────
     Exposed so the first publish can be built from exactly what ships
     today, rather than being typed out again and drifting. */
  window.nwsbContentDefaults = function () {
    return {
      words: window.NWSB_DEFAULT_WORD_CATS || null,
      meanings: window.MS_BASE_MEANINGS || null
    };
  };

  function boot() {
    applyCache();
    /* firebase.module.js sets window._db when it has finished; it may not
       have yet, so try until it is there rather than racing it. */
    if (!watch()) {
      var n = 0;
      var t = setInterval(function () { if (watch() || ++n > 60) clearInterval(t); }, 250);
    }
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
