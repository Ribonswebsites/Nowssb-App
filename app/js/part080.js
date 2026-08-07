/* ── Sound Library, laid out the way a music app lays out a home feed ─────
   Everything on this screen is real: the words come from
   MASTER_WORD_LIBRARY, the artwork from MS_BASE_MEANINGS (the Meaning
   Store already ships one image per word — no new art was added for this),
   the sentences and purchases from the same localStorage keys part018.js
   reads, and the session counts from window._mpData when My Progress has
   loaded it. Nothing here invents a number.

   This file loads AFTER part018.js and takes over window.slRender, which is
   what part005.js and part018.js's own openSub hook both call. The old tab
   renderers stay where they are and are simply no longer reached. ── */
(function () {
  'use strict';

  /* ── Data ─────────────────────────────────────────────────────────── */
  function J(k, d) { try { return JSON.parse(localStorage.getItem(k) || d); } catch (e) { return JSON.parse(d); } }
  function allWords()   { return window.MASTER_WORD_LIBRARY || window.PRACTICE_WORDS || []; }
  function meanings()   { return window.MS_BASE_MEANINGS || []; }
  function sentences()  { return J('nwsb_sentences', '[]'); }
  function purchased()  { return J('nwsb_purchased', '[]'); }
  function mPurchased() { return J('nwsb_meaning_purchased', '[]'); }
  /* part018.js seeds five routines in memory and only writes them to
     localStorage once one is edited, so the live array is the truthful
     source and the key is the fallback. */
  function routines()   { return window._routines || J('nwsb_routines', '[]'); }

  /* Real per-word session counts, when My Progress has already fetched the
     user document. Keys look like "YYYY-MM-DD_WORD". No document, no
     number — the row falls back to the word's own facts rather than to a
     made-up one. */
  function sessionCounts() {
    var out = {}, d = window._mpData;
    var s = d && d.sessions;
    if (!s) return out;
    Object.keys(s).forEach(function (k) {
      var w = k.split('_').slice(1).join('_');
      if (w) out[w] = (out[w] || 0) + 1;
    });
    return out;
  }

  /* ── Artwork ──────────────────────────────────────────────────────────
     Exact match on the word first; otherwise a stable pick out of the
     store's own images, so a word keeps the same tile every render. */
  var _pool = null;
  function pool() {
    if (_pool) return _pool;
    var seen = {}, out = [];
    meanings().forEach(function (m) { if (m.img && !seen[m.img]) { seen[m.img] = 1; out.push(m.img); } });
    if (window.MS_CAT_LOGO && !seen[window.MS_CAT_LOGO]) out.push(window.MS_CAT_LOGO);
    _pool = out;
    return out;
  }
  function hash(s) {
    var h = 0, i;
    for (i = 0; i < String(s).length; i++) h = (h * 31 + String(s).charCodeAt(i)) | 0;
    return Math.abs(h);
  }
  function art(name) {
    var n = String(name || '').toLowerCase();
    var hit = meanings().find(function (m) { return (m.word || '').toLowerCase() === n; });
    if (hit && hit.img) return hit.img;
    var p = pool();
    return p.length ? p[hash(n) % p.length] : '';
  }

  /* ── HTML helpers ─────────────────────────────────────────────────── */
  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
  function jsArg(s) { return String(s == null ? '' : s).replace(/\\/g, '\\\\').replace(/'/g, "\\'"); }
  function tile(src) { return '<span class="slm-art" style="background-image:url(\'' + esc(src) + '\');"></span>'; }

  var MORE_SVG = '<svg viewBox="0 0 4 16" fill="none" aria-hidden="true">' +
    '<circle cx="2" cy="2" r="1.7" fill="currentColor"/><circle cx="2" cy="8" r="1.7" fill="currentColor"/>' +
    '<circle cx="2" cy="14" r="1.7" fill="currentColor"/></svg>';
  var CHEV_SVG = '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
    '<path d="M9 5l7 7-7 7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  var ARROW_SVG = '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
    '<path d="M4 12h15M13 6l6 6-6 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  /* ── Chips ────────────────────────────────────────────────────────────
     The old three tabs are the first three; the rest are the categories
     the word library actually carries. */
  var _chip = 'All';
  function chipList() {
    var cats = [];
    allWords().forEach(function (w) {
      (w.categories || []).forEach(function (c) { if (cats.indexOf(c) === -1) cats.push(c); });
    });
    return ['All', 'Sentences', 'My Words', 'Purchased'].concat(cats);
  }
  function paintChips() {
    var box = document.getElementById('slmChips');
    if (!box) return;
    box.innerHTML = chipList().map(function (c) {
      return '<button class="slm-chip' + (c === _chip ? ' on' : '') + '" onclick="slmChip(\'' + jsArg(c) + '\')">' + esc(c) + '</button>';
    }).join('');
  }
  window.slmChip = function (c) {
    _chip = c;
    paintChips();
    paintFeed();
    var f = document.getElementById('slContent');
    if (f) f.scrollTop = 0;
  };

  /* Which words this chip is asking for. */
  function chosenWords() {
    var ws = allWords();
    if (_chip === 'All' || _chip === 'Sentences') return ws;
    if (_chip === 'Purchased') {
      var owned = purchased().map(function (p) { return (p.word || '').toUpperCase(); });
      return ws.filter(function (w) { return owned.indexOf(w.word.toUpperCase()) !== -1; });
    }
    if (_chip === 'My Words') {
      var bought = purchased().map(function (p) { return (p.word || '').toUpperCase(); });
      return ws.filter(function (w) { return bought.indexOf(w.word.toUpperCase()) === -1; });
    }
    return ws.filter(function (w) { return (w.categories || []).indexOf(_chip) !== -1; });
  }

  /* ── Section head ─────────────────────────────────────────────────── */
  function head(title, right) {
    return '<div class="slm-sec-head"><h3 class="slm-sec-title">' + esc(title) + '</h3>' + (right || '') + '</div>';
  }
  function playAll(words) {
    if (!words.length) return '';
    return '<button class="slm-pill" onclick="slmPlay(\'' + jsArg(words[0].word) + '\')">Play all</button>';
  }
  function chevron(onclick) {
    return '<button class="slm-chev" onclick="' + onclick + '" aria-label="See all">' + CHEV_SVG + '</button>';
  }

  /* ── Rows ─────────────────────────────────────────────────────────── */
  function wordSub(w, counts) {
    var n = counts[w.word];
    var bits = [w.phonetic, w.organ].filter(Boolean);
    if (n) bits.push(n + ' session' + (n === 1 ? '' : 's'));
    return bits.join(' · ');
  }
  function row(w, counts) {
    return '<div class="slm-row" onclick="slmPlay(\'' + jsArg(w.word) + '\')">' +
      tile(art(w.word)) +
      '<span class="slm-row-txt"><span class="slm-row-t">' + esc(w.word) + '</span>' +
      '<span class="slm-row-s">' + esc(wordSub(w, counts)) + '</span></span>' +
      '<button class="slm-more" aria-label="Open ' + esc(w.word) + '"' +
      ' onclick="event.stopPropagation();slmPlay(\'' + jsArg(w.word) + '\')">' + MORE_SVG + '</button>' +
      '</div>';
  }
  /* Four rows a page, the next page showing at the edge — the shape a
     music app uses for a list it wants to be swiped, not scrolled. */
  function rowPages(words, counts, per) {
    per = per || 4;
    if (!words.length) return '';
    var out = '<div class="slm-hpages">';
    for (var i = 0; i < words.length; i += per) {
      out += '<div class="slm-hpage">' + words.slice(i, i + per).map(function (w) { return row(w, counts); }).join('') + '</div>';
    }
    return out + '</div>';
  }

  /* ── Speed dial — a 3x3 grid of square tiles, paged, with dots ────── */
  function speedDial(words) {
    if (!words.length) return '';
    var pages = [];
    for (var i = 0; i < Math.min(words.length, 27); i += 9) pages.push(words.slice(i, i + 9));
    var id = 'slmSd';
    var grid = '<div class="slm-sd-pages" id="' + id + '" onscroll="slmDots(\'' + id + '\')">' +
      pages.map(function (p) {
        return '<div class="slm-sd-page">' + p.map(function (w) {
          return '<div class="slm-sq" onclick="slmPlay(\'' + jsArg(w.word) + '\')">' +
            tile(art(w.word)) + '<span class="slm-sq-t">' + esc(w.word) + '</span></div>';
        }).join('') + '</div>';
      }).join('') + '</div>';
    var dots = pages.length > 1
      ? '<div class="slm-dots" id="' + id + 'Dots">' + pages.map(function (_, i) {
          return '<span class="slm-dot' + (i === 0 ? ' on' : '') + '"></span>';
        }).join('') + '</div>'
      : '';
    var name = (localStorage.getItem('nwsb_name') || 'Your practice');
    return '<section class="slm-sec">' +
      '<div class="slm-sd-head">' +
        '<span class="slm-sd-ava">' + tile(pool()[0] || '') + '</span>' +
        '<span class="slm-sd-txt"><span class="slm-sd-eye">' + esc(String(name).toUpperCase()) + '</span>' +
        '<span class="slm-sd-t">Speed dial</span></span>' +
      '</div>' + grid + dots + '</section>';
  }

  window.slmDots = function (id) {
    var box = document.getElementById(id), dots = document.getElementById(id + 'Dots');
    if (!box || !dots) return;
    var i = Math.round(box.scrollLeft / Math.max(1, box.clientWidth));
    var ds = dots.querySelectorAll('.slm-dot');
    for (var k = 0; k < ds.length; k++) ds[k].classList.toggle('on', k === i);
  };

  /* ── The wide promo card ──────────────────────────────────────────── */
  function promo() {
    var owned = mPurchased().length;
    return '<section class="slm-sec"><div class="slm-promo" onclick="slmGo(\'real-meaning\')">' +
      '<div class="slm-promo-l">' +
        '<div class="slm-promo-t">Every word has an origin.<br>Find out what yours means.</div>' +
        '<div class="slm-promo-s">' + (owned ? owned + ' meaning' + (owned === 1 ? '' : 's') + ' unlocked' : 'The Meaning Store') + '</div>' +
        '<span class="slm-promo-go">' + ARROW_SVG + '</span>' +
      '</div>' +
      '<div class="slm-promo-r" style="background-image:url(\'' + esc(window.MS_SIGNATURE_IMG || pool()[1] || '') + '\');"></div>' +
      '</div></section>';
  }

  /* ── Saved sentences ──────────────────────────────────────────────── */
  function sentenceSec() {
    var arr = sentences();
    if (!arr.length) {
      return '<section class="slm-sec" id="slmSentences">' + head('Your sentences') +
        '<div class="slm-empty">Finish a practice session and the sentence you built is saved here.' +
        '<button class="slm-pill slm-empty-cta" onclick="slmGo(\'practice\')">Start a session</button></div></section>';
    }
    var rows = arr.slice(0, 12).map(function (s) {
      var meta = [s.routineName || 'Practice', s.playCount ? s.playCount + ' play' + (s.playCount === 1 ? '' : 's') : '']
        .filter(Boolean).join(' · ');
      return '<div class="slm-row" onclick="slPlaySentence(\'' + jsArg(s.id) + '\')">' +
        tile(art((s.words && s.words[0]) || s.text)) +
        '<span class="slm-row-txt"><span class="slm-row-t">' + esc(s.text) + '</span>' +
        '<span class="slm-row-s">' + esc(meta) + '</span></span>' +
        '<button class="slm-more" aria-label="Remove sentence"' +
        ' onclick="event.stopPropagation();slDeleteSentence(\'' + jsArg(s.id) + '\')">' + MORE_SVG + '</button>' +
        '</div>';
    });
    var pages = '<div class="slm-hpages">';
    for (var i = 0; i < rows.length; i += 4) pages += '<div class="slm-hpage">' + rows.slice(i, i + 4).join('') + '</div>';
    pages += '</div>';
    return '<section class="slm-sec" id="slmSentences">' +
      head('Your sentences', '<button class="slm-pill" onclick="slPlaySentence(\'' + jsArg(arr[0].id) + '\')">Play all</button>') +
      pages + '</section>';
  }

  /* ── The big 16:9 card ────────────────────────────────────────────── */
  function bigCards(words, counts) {
    var cold = words.filter(function (w) { return !counts[w.word]; });
    var use = (cold.length ? cold : words).slice(0, 6);
    if (!use.length) return '';
    return '<section class="slm-sec">' + head('Not practised yet') +
      '<div class="slm-hscroll">' + use.map(function (w) {
        return '<div class="slm-big" onclick="slmPlay(\'' + jsArg(w.word) + '\')">' +
          '<span class="slm-big-art" style="background-image:url(\'' + esc(art(w.word)) + '\');"></span>' +
          '<span class="slm-big-t">' + esc(w.word) + ' — ' + esc(w.benefit || w.meaning || '') + '</span>' +
          '<span class="slm-big-s">' + esc([w.organ, w.origin].filter(Boolean).join(' · ')) + '</span>' +
          '</div>';
      }).join('') + '</div></section>';
  }

  /* ── 2x2 mosaics, one per category ────────────────────────────────── */
  function mosaics() {
    var cats = [];
    allWords().forEach(function (w) {
      (w.categories || []).forEach(function (c) { if (cats.indexOf(c) === -1) cats.push(c); });
    });
    if (!cats.length) return '';
    return '<section class="slm-sec">' + head('Browse by category') +
      '<div class="slm-hscroll">' + cats.slice(0, 10).map(function (c) {
        var ws = allWords().filter(function (w) { return (w.categories || []).indexOf(c) !== -1; });
        var four = [0, 1, 2, 3].map(function (i) {
          var w = ws[i % Math.max(1, ws.length)];
          return '<span class="slm-mo-q" style="background-image:url(\'' + esc(art(w ? w.word : c)) + '\');"></span>';
        }).join('');
        return '<div class="slm-mo" onclick="slmChip(\'' + jsArg(c) + '\')">' +
          '<span class="slm-mo-grid">' + four + '</span>' +
          '<span class="slm-mo-t">' + esc(c) + '</span>' +
          '<span class="slm-mo-s">' + ws.length + ' word' + (ws.length === 1 ? '' : 's') + '</span>' +
          '</div>';
      }).join('') + '</div></section>';
  }

  /* ── Routines, as square covers ───────────────────────────────────── */
  function albums() {
    var rs = routines().filter(function (r) { return (r.words || []).length; });
    if (!rs.length) return '';
    return '<section class="slm-sec">' + head('Your routines', chevron("slmGo('routines')")) +
      '<div class="slm-hscroll">' + rs.map(function (r) {
        return '<div class="slm-alb" onclick="slmGo(\'routines\')">' +
          '<span class="slm-alb-art" style="background-image:url(\'' + esc(art(r.words[0])) + '\');"></span>' +
          '<span class="slm-alb-t">' + esc(r.name) + '</span>' +
          '<span class="slm-alb-s">Routine · ' + r.words.length + ' word' + (r.words.length === 1 ? '' : 's') + '</span>' +
          '</div>';
      }).join('') + '</div></section>';
  }

  /* ── Meanings, as rows ────────────────────────────────────────────── */
  function meaningRows() {
    var ms = meanings();
    if (!ms.length) return '';
    var owned = mPurchased().map(function (p) { return (p.word || '').toLowerCase(); });
    var rows = ms.slice(0, 12).map(function (m) {
      var has = owned.indexOf((m.word || '').toLowerCase()) !== -1;
      return '<div class="slm-row" onclick="slmMeaning(\'' + jsArg(m.key) + '\',\'' + jsArg(m.word) + '\')">' +
        tile(m.img) +
        '<span class="slm-row-txt"><span class="slm-row-t">' + esc(m.word) + '</span>' +
        '<span class="slm-row-s">' + esc(m.root) + (has ? ' · Owned' : '') + '</span></span>' +
        '<button class="slm-more" aria-label="Open ' + esc(m.word) + '"' +
        ' onclick="event.stopPropagation();slmMeaning(\'' + jsArg(m.key) + '\',\'' + jsArg(m.word) + '\')">' + MORE_SVG + '</button>' +
        '</div>';
    });
    var pages = '<div class="slm-hpages">';
    for (var i = 0; i < rows.length; i += 4) pages += '<div class="slm-hpage">' + rows.slice(i, i + 4).join('') + '</div>';
    pages += '</div>';
    return '<section class="slm-sec">' + head('Meanings & origins', chevron("slmGo('real-meaning')")) + pages + '</section>';
  }

  /* ── The feed ─────────────────────────────────────────────────────── */
  function paintFeed() {
    var feed = document.getElementById('slContent');
    if (!feed) return;
    var counts = sessionCounts();
    var ws = chosenWords();
    var html = '';

    if (_chip === 'Sentences') {
      html = sentenceSec() + promo() + meaningRows();
    } else if (!ws.length) {
      html = '<div class="slm-empty">Nothing in this filter yet.' +
        '<button class="slm-pill slm-empty-cta" onclick="slmChip(\'All\')">Show everything</button></div>' + promo();
    } else {
      html = speedDial(ws) +
        '<section class="slm-sec">' + head('Quick picks', playAll(ws)) + rowPages(ws.slice(0, 12), counts) + '</section>' +
        promo() +
        sentenceSec() +
        bigCards(ws, counts) +
        mosaics() +
        albums() +
        meaningRows();
    }
    feed.innerHTML = html;

    var b = document.getElementById('slmBellCount');
    if (b) { var n = sentences().length; b.textContent = n; b.style.display = n ? '' : 'none'; }
    var av = document.getElementById('slmAvatarLetter');
    if (av) av.textContent = (localStorage.getItem('nwsb_name') || 'N').trim().charAt(0).toUpperCase() || 'N';
  }

  /* ── Actions ──────────────────────────────────────────────────────── */
  window.slmPlay = function (word) {
    if (typeof window.slOpenWord === 'function') return window.slOpenWord(word);
    slmGo('practice');
  };
  window.slmGo = function (id) {
    if (typeof window.navFromSub === 'function') return window.navFromSub('sound-library', function () { window.openSub(id); });
    if (typeof window.closeSub === 'function') window.closeSub('sound-library');
    setTimeout(function () { if (window.openSub) window.openSub(id); }, 80);
  };
  window.slmMeaning = function (key, word) {
    if (typeof window.msOpenDetailFromPlayer === 'function') return window.msOpenDetailFromPlayer(key, word);
    if (typeof window.msShowDetail === 'function') return window.msShowDetail(key, word);
    slmGo('real-meaning');
  };
  window.slmOpenSaved = function () {
    window.slmChip('Sentences');
  };
  window.slmOpenProfile = function () { slmGo('profile'); };

  /* ── Takeover ─────────────────────────────────────────────────────────
     part005.js and part018.js's openSub hook both call window.slRender, and
     part018.js's slSetTab is still referenced by its own empty states. Both
     are pointed here so there is one renderer for this screen. */
  window.slRender = function () { paintChips(); paintFeed(); };
  window.slSetTab = function (t) {
    var map = { sentences: 'Sentences', words: 'My Words', purchased: 'Purchased' };
    window.slmChip(map[t] || 'All');
  };
})();
