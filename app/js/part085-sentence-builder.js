/* ══ Sentence Builder — glass full page (#sub-sentence-builder)
   Opens from the player Sentence tab. Black glass banners, white-circle
   SVG icons on the right, combine owned words by subconscious tier (2–6).
   No emoji. */
(function () {
  'use strict';

  function sbTier() {
    try {
      if (window.GATE && typeof window.GATE.tier === 'function') return window.GATE.tier();
    } catch (e) {}
    var d = window._userDataCache;
    if (d && d.tier) return d.tier;
    return 'free';
  }

  function sbMaxWords() {
    var t = String(sbTier() || 'free').toLowerCase();
    if (t === 'frequencyx' || t === 'elite_x') return 6;
    if (t === 'frequency' || t === 'elite') return 5;
    if (t === 'resonance' || t === 'pro') return 4;
    if (t === 'trial') return 3;
    return 2;
  }

  function sbOwnedWords() {
    if (typeof PRACTICE_WORDS !== 'undefined' && Array.isArray(PRACTICE_WORDS) && PRACTICE_WORDS.length) {
      return PRACTICE_WORDS.map(function (w) {
        return { word: w.word, meaning: w.meaning || '', organ: w.organ || '' };
      });
    }
    return [
      { word: 'Peace', meaning: 'Stillness that heals', organ: 'Mind' },
      { word: 'Breath', meaning: 'Life moving through you', organ: 'Lungs' },
      { word: 'Light', meaning: 'Clarity rising', organ: 'Eyes' },
      { word: 'Heart', meaning: 'Centre of feeling', organ: 'Heart' },
      { word: 'Flow', meaning: 'Gentle forward motion', organ: 'Blood' },
      { word: 'Calm', meaning: 'Quiet strength', organ: 'Nervous system' },
      { word: 'Truth', meaning: 'What remains', organ: 'Mind' },
      { word: 'Heal', meaning: 'Restore from within', organ: 'Body' },
      { word: 'Dawn', meaning: 'Beginning light', organ: 'Eyes' },
      { word: 'Grace', meaning: 'Soft strength', organ: 'Heart' },
      { word: 'Pulse', meaning: 'Living rhythm', organ: 'Heart' },
      { word: 'Still', meaning: 'Quiet centre', organ: 'Mind' }
    ];
  }

  var _sel = new Set();
  var _building = false;

  function sbComposeLocal(words) {
    if (words.length === 2) {
      return 'With ' + words[0] + ' and ' + words[1] + ', the body remembers how to soften.';
    }
    if (words.length === 3) {
      return words[0] + ' meets ' + words[1] + ', and ' + words[2] + ' closes the circle.';
    }
    var head = words.slice(0, -1).join(', ');
    return 'From ' + head + ' to ' + words[words.length - 1] + ' — one healing sentence, spoken as one breath.';
  }

  function sbIco(paths) {
    return '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true">' + paths + '</svg>';
  }

  var IC = {
    sentence: sbIco('<path d="M4 5.5h16v10.5H9.5L5.5 19.5V16H4z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/><path d="M7.5 9.5h9M7.5 12.6h6" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>'),
    book: sbIco('<path d="M5 4.5h6.2a2 2 0 0 1 2 2V19a1.4 1.4 0 0 0-1.4-1.4H5zM19 4.5h-6.2a2 2 0 0 0-2 2V19a1.4 1.4 0 0 1 1.4-1.4H19z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/>'),
    play: sbIco('<path d="M5 3.5 18 11 5 18.5z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/>'),
    features: sbIco('<rect x="4" y="4" width="7" height="7" rx="1.6" stroke="currentColor" stroke-width="1.7"/><rect x="13" y="4" width="7" height="7" rx="1.6" stroke="currentColor" stroke-width="1.7"/><rect x="4" y="13" width="7" height="7" rx="1.6" stroke="currentColor" stroke-width="1.7"/><rect x="13" y="13" width="7" height="7" rx="1.6" stroke="currentColor" stroke-width="1.7"/>'),
    bag: sbIco('<path d="M4.4 7.6h15.2l-1.1 12.2a1.6 1.6 0 0 1-1.6 1.4H7.1a1.6 1.6 0 0 1-1.6-1.4z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/><path d="M8.8 10V6.4a3.2 3.2 0 0 1 6.4 0V10" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>'),
    go: sbIco('<path d="M2 6H10M7 3L10 6L7 9" stroke="currentColor" stroke-width="1.9" stroke-linecap="square"/>')
  };

  function sbBanner(title, sub, ico, onclick) {
    return '<button type="button" class="sb-banner" ' + (onclick ? 'onclick="' + onclick + '"' : '') + '>' +
      '<div class="sb-banner-txt"><div class="sb-banner-title">' + title + '</div>' +
      (sub ? '<div class="sb-banner-sub">' + sub + '</div>' : '') + '</div>' +
      '<div class="sb-banner-div" aria-hidden="true"></div>' +
      '<div class="sb-banner-ico">' + ico + '</div>' +
      '</button>';
  }

  function sbRender() {
    var root = document.getElementById('sbBody');
    if (!root) return;
    var max = sbMaxWords();
    var owned = sbOwnedWords();
    var chips = owned.map(function (w) {
      var on = _sel.has(w.word);
      return '<button type="button" class="sb-chip' + (on ? ' on' : '') + '" data-word="' +
        String(w.word).replace(/"/g, '&quot;') + '" onclick="sbToggleWord(this)">' + w.word + '</button>';
    }).join('');

    root.innerHTML =
      sbBanner('Build your sentence', 'Combine owned words into one healing line', IC.sentence) +
      sbBanner('All words owned', owned.length + ' words ready to weave', IC.book, 'sbScrollCombine()') +
      sbBanner('Listen', 'Hear the words before you combine', IC.play, 'sbListen()') +
      sbBanner('Request customized words', 'Ask for words tuned to your practice', IC.features, 'sbRequestCustom()') +
      sbBanner('Buy / Shop words', 'Grow your library in the Store', IC.bag, 'sbOpenShop()') +
      '<section class="sb-glass sb-combine" id="sbCombine">' +
        '<div class="sb-combine-head"><span>Combine words</span><span class="sb-count" id="sbCount">' + _sel.size + ' / ' + max + '</span></div>' +
        '<p class="sb-hint">Select at least 2 owned words. Your subconscious tier allows up to ' + max + '.</p>' +
        '<div class="sb-chips" id="sbChips">' + chips + '</div>' +
        '<button type="button" class="sb-combine-btn" id="sbCombineBtn" onclick="sbCombine()" ' +
          (_sel.size < 2 || _building ? 'disabled' : '') + '>' +
          IC.go + '<span>Combine into sentence</span></button>' +
        '<div class="sb-result" id="sbResult" hidden>' +
          '<div class="sb-result-label">YOUR SENTENCE</div>' +
          '<div class="sb-result-text" id="sbResultText"></div>' +
        '</div>' +
      '</section>';
  }

  window.sbToggleWord = function (el) {
    if (!el) return;
    var w = el.getAttribute('data-word');
    var max = sbMaxWords();
    if (_sel.has(w)) _sel.delete(w);
    else {
      if (_sel.size >= max) {
        el.classList.add('sb-shake');
        setTimeout(function () { el.classList.remove('sb-shake'); }, 420);
        return;
      }
      _sel.add(w);
    }
    var result = document.getElementById('sbResult');
    if (result) { result.hidden = true; result.classList.remove('show'); }
    sbRender();
  };

  window.sbScrollCombine = function () {
    var el = document.getElementById('sbCombine');
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  window.sbListen = function () {
    var words = Array.from(_sel);
    if (!words.length) {
      var owned = sbOwnedWords();
      if (owned[0]) words = [owned[0].word];
    }
    try {
      if (window.speechSynthesis) {
        window.speechSynthesis.cancel();
        var u = new SpeechSynthesisUtterance(words.join(', '));
        u.rate = 0.92;
        window.speechSynthesis.speak(u);
      }
    } catch (e) {}
  };

  window.sbRequestCustom = function () {
    try {
      if (window.SS && typeof window.SS.open === 'function') return window.SS.open('subscription');
    } catch (e) {}
  };

  window.sbOpenShop = function () {
    try {
      if (typeof openSub === 'function') openSub('nowssb-store');
      if (typeof nssEnterStore === 'function') nssEnterStore();
      var intro = document.getElementById('nssIntroPage');
      if (intro) { intro.style.display = 'none'; }
    } catch (e) {}
  };

  window.sbCombine = async function () {
    if (_sel.size < 2 || _building) return;
    _building = true;
    sbRender();
    var words = Array.from(_sel);
    var text = sbComposeLocal(words);

    // Prefer existing AI builder when available.
    try {
      if (typeof window.callAI === 'function') {
        var raw = await window.callAI(
          [{ role: 'user', content: 'Create a healing sentence using these words: ' + words.join(', ') + '.' }],
          {
            model: 'claude-haiku-4-5',
            max_tokens: 400,
            system: 'You are a Shabdapathy sentence builder for NowssB. Create one beautiful healing sentence using ALL given words. Respond ONLY as JSON: {"sentence":"..."}'
          }
        );
        var clean = String(raw || '').replace(/```json|```/g, '').trim();
        var data = JSON.parse(clean);
        if (data && data.sentence) text = data.sentence;
      }
    } catch (e) { /* keep local */ }

    _building = false;
    sbRender();
    var box = document.getElementById('sbResult');
    var tx = document.getElementById('sbResultText');
    if (tx) tx.textContent = text;
    if (box) {
      box.hidden = false;
      requestAnimationFrame(function () { box.classList.add('show'); });
    }
  };

  function sbUpdateTierPill() {
    var pill = document.getElementById('sbTierPill');
    if (pill) pill.textContent = 'TIER · ' + sbMaxWords();
  }

  window.openSentenceBuilder = function () {
    if (typeof openSub === 'function') openSub('sentence-builder');
    else {
      var s = document.getElementById('sub-sentence-builder');
      if (s) s.classList.add('open');
    }
    _sel = new Set();
    _building = false;
    sbUpdateTierPill();
    sbRender();
  };

  window.sbClose = function () {
    if (typeof closeSub === 'function') closeSub('sentence-builder');
    else {
      var s = document.getElementById('sub-sentence-builder');
      if (s) s.classList.remove('open');
    }
  };

  // Re-render when the sub opens via openSub('sentence-builder')
  function patchOpen() {
    if (typeof window.openSub !== 'function') return setTimeout(patchOpen, 120);
    if (window.openSub._sbPatched) return;
    var orig = window.openSub;
    window.openSub = function (id) {
      var r = orig.apply(this, arguments);
      if (id === 'sentence-builder') {
        _sel = new Set();
        _building = false;
        setTimeout(function () { sbUpdateTierPill(); sbRender(); }, 30);
      }
      return r;
    };
    window.openSub._sbPatched = true;
  }
  patchOpen();

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { /* shell waits for open */ });
  }
})();
