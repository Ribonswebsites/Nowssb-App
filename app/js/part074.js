/* ══════════════════════════════════════════════════════════
   NOWSSB SIGNATURE — the third library in the store.

   The Word Atelier sells words. The Meaning Store sells meanings. One item
   in each collection is the signature: the rarest thing that collection
   has, priced above everything else, with its own gold product shot rather
   than the shared card art. Those already existed — fifteen signature
   words in RM_SIGNATURE_WORDS (part010.js) and five signature meanings in
   MS_SIGNATURE (part026.js) — but the only place either could be seen was
   the Signature coupon page, which you had to already know about.

   This puts them in the store, as a library of their own, and takes
   nothing on faith: both maps are read live, so a signature added to
   either collection appears here without this file changing, and the same
   card markup and the same open-handlers the coupon page uses are reused
   rather than re-written. If the two ever disagree it is because the data
   changed, not because one of them was updated and the other was not.

   The hero card is deliberately both sections at once — the Word Atelier's
   clip and the Meaning Store's clip, crossfading behind one gold overlay,
   because the collection is both.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
  /* For a value going into an onclick="…'here'…" — the attribute is already
     double-quoted, so the single quotes are what need escaping. */
  function jsq(s) { return String(s == null ? '' : s).replace(/\\/g, '\\\\').replace(/'/g, "\\'"); }

  function money(n) {
    return (typeof window.nwsbFormatINR === 'function') ? window.nwsbFormatINR(n) : ('₹' + n);
  }

  /* ── The cards ─────────────────────────────────────────────────────
     Same classes the coupon page uses, so the gold-glass treatment,
     the Signature tag and the unlocked state all come for free. ── */
  function wordCard(sig) {
    return '<div class="rm-word-card rm-word-card-signature sig-card" ' +
             'onclick="couponOpenWordDetail(\'' + jsq(sig.key) + '\')">' +
             '<span class="rm-word-card-signature-tag">Signature</span>' +
             '<img decoding="async" class="rm-word-card-img" src="' + esc(sig.img || window.RM_SIGNATURE_IMG || '') + '" alt="" loading="lazy">' +
             '<div class="rm-word-card-overlay"></div>' +
             '<div class="rm-word-card-body">' +
               '<div class="rm-word-card-name">' + esc(sig.name) + '</div>' +
               '<div class="rm-word-card-root">Most Exclusive</div>' +
             '</div>' +
           '</div>';
  }

  function meaningCard(m) {
    var price = window.MS_SIGNATURE_PRICE || 299;
    var img = window.MS_SIGNATURE_IMG || '';
    var owned = !!(window.msIsPurchased && window.msIsPurchased(m.key));
    return '<div class="ms-card ms-card-signature sig-card sig-card-meaning' + (owned ? ' unlocked' : '') + '" ' +
             'onclick="couponOpenMeaningDetail(\'' + jsq(m.key) + '\',\'' + jsq(m.word) + '\',' + price + ',\'' + jsq(img) + '\')">' +
             '<span class="ms-card-signature-tag">Signature</span>' +
             '<div class="ms-card-img" style="background-image:url(\'' + esc(img) + '\')"></div>' +
             '<div class="ms-card-overlay"></div>' +
             '<div class="ms-card-body">' +
               '<div class="ms-card-word">' + esc(m.word) + '</div>' +
               '<div class="ms-card-root">' + esc(m.root || 'Most Exclusive') + '</div>' +
               (owned ? '<div class="ms-card-unlocked-badge">Unlocked</div>'
                      : '<div class="ms-card-price">' + money(price) + '</div>') +
             '</div>' +
           '</div>';
  }

  /* ── Filling the rails ─────────────────────────────────────────────
     Called on every open rather than once, because "Unlocked" changes
     when somebody buys one and the rail should say so next time it is
     looked at. ── */
  function render() {
    var wRail = document.getElementById('sigWordsRail');
    var mRail = document.getElementById('sigMeaningsRail');
    if (!wRail && !mRail) return;

    var words = window.RM_SIGNATURE_WORDS || {};
    var means = window.MS_SIGNATURE || {};

    if (wRail) {
      var wKeys = Object.keys(words);
      wRail.innerHTML = wKeys.length
        ? wKeys.map(function (k) { return wordCard(words[k]); }).join('')
        : '<div class="sig-empty">No signature words yet.</div>';
    }
    if (mRail) {
      var mKeys = Object.keys(means);
      mRail.innerHTML = mKeys.length
        ? mKeys.map(function (k) { return meaningCard(means[k]); }).join('')
        : '<div class="sig-empty">No signature meanings yet.</div>';
    }
  }
  window.sigRenderStore = render;

  window.sigTab = function (which) {
    var w = document.getElementById('sigWordsRail');
    var m = document.getElementById('sigMeaningsRail');
    var wb = document.getElementById('sigToggleWords');
    var mb = document.getElementById('sigToggleMeanings');
    var onWords = which !== 'meanings';
    if (w) w.style.display = onWords ? '' : 'none';
    if (m) m.style.display = onWords ? 'none' : '';
    if (wb) wb.classList.toggle('active', onWords);
    if (mb) mb.classList.toggle('active', !onWords);
    try { if (navigator.vibrate) navigator.vibrate(16); } catch (e) {}
  };

  /* The hero's button goes to whichever side is showing — tapping
     "Browse The Signature" while looking at meanings should not land you
     in the word atelier. */
  window.sigBrowseAll = function () {
    var m = document.getElementById('sigMeaningsRail');
    var onMeanings = m && m.style.display !== 'none';
    if (onMeanings) {
      var means = window.MS_SIGNATURE || {};
      var first = means[Object.keys(means)[0]];
      if (first && window.couponOpenMeaningDetail) {
        window.couponOpenMeaningDetail(first.key, first.word,
          window.MS_SIGNATURE_PRICE || 299, window.MS_SIGNATURE_IMG || '');
        return;
      }
    }
    if (typeof window.nssOpenSub === 'function') window.nssOpenSub('real-meaning');
    if (typeof window.rmSkipIntro === 'function') window.rmSkipIntro();
  };

  /* ── Both clips, one card ──────────────────────────────────────────
     The two videos are stacked; this fades between them. Only while the
     store is actually open — a timer running behind a closed screen is a
     wakelock nobody asked for. ── */
  var flip = null, showB = false;
  function crossfade(on) {
    var a = document.getElementById('sigVidWord');
    var b = document.getElementById('sigVidMeaning');
    if (!a || !b) return;
    if (!on) { if (flip) { clearInterval(flip); flip = null; } return; }
    if (flip) return;
    flip = setInterval(function () {
      showB = !showB;
      b.classList.toggle('on', showB);
      /* Play only the one being seen; the other is paused, so a card that
         is off screen costs nothing to decode. */
      var vis = showB ? b : a, hid = showB ? a : b;
      try { vis.muted = true; vis.play().catch(function () {}); } catch (e) {}
      try { hid.pause(); } catch (e) {}
    }, 6000);
  }

  /* ── Wiring it to the store screen ─────────────────────────────────
     part017.js owns the store and part055.js already wraps openSub; wrap
     it once more rather than reaching into either. Also watched directly,
     because the store is opened in several places by adding .open to the
     element rather than by calling openSub. */
  function opened() { render(); crossfade(true); }
  function closed() { crossfade(false); }

  var scr = null;
  function watch() {
    scr = document.getElementById('sub-nowssb-store');
    if (!scr) return false;
    var was = scr.classList.contains('open');
    if (was) opened();
    try {
      new MutationObserver(function () {
        var now = scr.classList.contains('open');
        if (now === was) return;
        was = now;
        if (now) opened(); else closed();
      }).observe(scr, { attributes: true, attributeFilter: ['class'] });
    } catch (e) {}
    return true;
  }

  function boot() {
    if (watch()) return;
    var n = 0;
    var t = setInterval(function () { if (watch() || ++n > 60) clearInterval(t); }, 250);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
