/* ── Sound Library, laid out the way a music app lays out a home feed ─────
   Everything on this screen is real and everything on it comes from the
   Store. The artwork is the Word Atelier's fifteen collection renders and
   the Meaning Store's per-word product shots; the clips are the Store's own
   — the door, Signature, subscription, the coupon reel — with the Sound
   Library's banner clip at the head of the rail. The words come from
   MASTER_WORD_LIBRARY, the sentences and purchases from the same
   localStorage keys part018.js reads, and the session counts from
   window._mpData when My Progress has loaded it. Nothing here invents a
   number.

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

  /* ── Artwork — the Store's own ─────────────────────────────────────────
     The Word Atelier ships fifteen collections and one banner render each
     (assets/banners, 2560x1440, previously unreferenced since the store
     moved to a text banner). Those renders are this feed's artwork,
     re-cut to a clean 16:9 at 720 wide in assets/store/collections — 650KB
     for the set, against 71MB of source.

     A word gets the banner of the collection it actually belongs to; a
     word the Atelier does not carry gets a stable pick, so its tile never
     changes between renders. */
  var COL = './assets/store/collections/';
  var COLS = [
    { id: 'off50',    file: 'sale',     label: '50% OFF',               sub: 'Limited time — best words at half price' },
    { id: 'elements', file: 'elements', label: 'Elements',              sub: 'The original sounds of the natural world' },
    { id: 'sacred',   file: 'sacred',   label: 'Sacred & Divine',       sub: 'Words that carry consciousness itself' },
    { id: 'identity', file: 'identity', label: 'Identity & Mind',       sub: 'The sounds of self — who you are' },
    { id: 'cosmos',   file: 'cosmos',   label: 'Time & Cosmos',         sub: 'Words born from the infinite' },
    { id: 'nature',   file: 'nature',   label: 'Nature',                sub: 'The living world around you' },
    { id: 'family',   file: 'family',   label: 'Family & Being',        sub: 'The words we are made of' },
    { id: 'elite',    file: 'elite',    label: 'Elite Words',           sub: 'The rarest words in existence' },
    { id: 'premium',  file: 'premium',  label: 'Premium',               sub: 'Exclusive — limited release words' },
    { id: 'mythical', file: 'mythical', label: 'Mythical Edition',      sub: 'Gods, beasts & ancient forces' },
    { id: 'warriors', file: 'warriors', label: 'Warriors',              sub: 'Born in blood, forged in fire' },
    { id: 'ancient',  file: 'ancient',  label: 'Ancient Civilizations', sub: 'Words from the dawn of history' },
    { id: 'peace',    file: 'peace',    label: 'Peace Edition',         sub: 'Words of stillness and surrender' },
    { id: 'white',    file: 'white',    label: 'White Edition',         sub: 'Minimal. Pure. Eternal.' },
    { id: 'black',    file: 'black',    label: 'Black Edition',         sub: 'Dark. Rare. Unstoppable.' }
  ];
  function colImg(c) { return COL + c.file + '.webp'; }
  /* The live catalogue when part010.js has it (the studio can republish it),
     the table above otherwise — labels and subs stay in step either way. */
  function collections() {
    var live = window.NWSB_DEFAULT_WORD_CATS;
    if (!live || !live.length) return COLS;
    return live.map(function (c) {
      var seed = COLS.find(function (x) { return x.id === c.id; }) || COLS[0];
      return { id: c.id, file: seed.file, label: c.label || seed.label, sub: c.sub || seed.sub, words: c.words };
    });
  }

  /* word -> the collection that carries it */
  var _byWord = null;
  function wordToCol() {
    if (_byWord) return _byWord;
    _byWord = {};
    collections().forEach(function (c) {
      (c.words || []).forEach(function (w) {
        var k = String(w[0] || w).toLowerCase();
        if (!_byWord[k]) _byWord[k] = c;
      });
    });
    return _byWord;
  }
  function hash(s) {
    var h = 0, i;
    for (i = 0; i < String(s).length; i++) h = (h * 31 + String(s).charCodeAt(i)) | 0;
    return Math.abs(h);
  }
  function art(name) {
    var n = String(name || '').toLowerCase();
    var c = wordToCol()[n];
    if (c) return colImg(c);
    var cs = collections();
    return colImg(cs[hash(n) % cs.length]);
  }
  /* The Meaning Store has a real product shot per word — those stay theirs. */
  function meaningArt(m) { return m.img || art(m.word); }

  /* ── HTML helpers ─────────────────────────────────────────────────── */
  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
  function jsArg(s) { return String(s == null ? '' : s).replace(/\\/g, '\\\\').replace(/'/g, "\\'"); }
  function tile(src) { return '<span class="slm-art" style="background-image:url(\'' + esc(src) + '\');"></span>'; }
  /* Every picture on this screen that is a card rather than a thumbnail sits
     on a tablet. The wrapper IS the frame (see .slm-fr in nowssb-nm.css) and
     must span its card, because its bezel is percentage padding and that
     resolves against the parent's width, not its own.
       tab4 — wordmark top-left, home slot on the chin: the 16:9 rails
       tab5 — NOWSSB top-right, round home button: mosaics and covers
       tab6 — hairline bezel: the speed-dial tiles, the only one whose bezel
              still reads as one at a third of the screen's width */
  function frame(kind, inner) {
    return '<span class="slm-fr dev-' + kind + '">' + inner + '</span>';
  }

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
      frame('tab6-l', tile(art(w.word))) +
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
        /* Nine tiles from fifteen collections will otherwise repeat, and two
           identical squares side by side read as a bug rather than as art.
           A word that collides steps to the next collection — deterministic,
           because the word order on a page is. */
        var used = {};
        return '<div class="slm-sd-page">' + p.map(function (w) {
          var src = art(w.word);
          if (used[src]) {
            var cs = collections();
            for (var k = 1; k <= cs.length; k++) {
              var alt = colImg(cs[(hash(w.word) + k) % cs.length]);
              if (!used[alt]) { src = alt; break; }
            }
          }
          used[src] = 1;
          return '<div class="slm-sq" onclick="slmPlay(\'' + jsArg(w.word) + '\')">' +
            frame('tab6-l', tile(src)) + '<span class="slm-sq-t">' + esc(w.word) + '</span></div>';
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
        '<span class="slm-sd-ava">' + frame('tab5-l', tile('https://nowssb-api.ribonpatil2.workers.dev/media/media/repo/assets/store/intro-store.webp')) + '</span>' +
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
      '<div class="slm-promo-r">' +
        frame('tab6-l', tile('https://nowssb-api.ribonpatil2.workers.dev/media/media/repo/assets/store/intro-meanings.webp')) +
      '</div>' +
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
        frame('tab6-l', tile(art((s.words && s.words[0]) || s.text))) +
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
          frame('tab4-l', tile(art(w.word))) +
          '<span class="slm-big-t">' + esc(w.word) + ' — ' + esc(w.benefit || w.meaning || '') + '</span>' +
          '<span class="slm-big-s">' + esc([w.organ, w.origin].filter(Boolean).join(' · ')) + '</span>' +
          '</div>';
      }).join('') + '</div></section>';
  }

  /* ── The Store's own clips, as video cards ────────────────────────────
     Every one of these already ships with the app — the Sound Library's
     banner clip first, then the store door, Signature, subscription and
     the coupon reel. preload="none" and no poster-less card, so nothing
     downloads until app/js/part051.js gives it a decoder slot, which it
     does for whichever cards are actually on screen. */
  /* Every clip in this rail has to be 16:9, because the tablet's aperture
     is 1.6352 and anything portrait letterboxes into a stripe with black
     down both sides. Two of them were: store-trigger and signature-store
     are both 768x1168 (0.6575) — they are the store DOOR and the Signature
     door, shot upright for a full-screen trigger, not banners.
     Replaced with the Store's actual 16:9 banners. The store card takes the
     clip that heads every meaning's page in the Meaning Store, which
     .ms-meaning-vid pins to 16/9; Signature takes signature-banner.mp4,
     1280x720, which already ships here. The other three were fine:
     1.7778, 1.7734, 1.7734. */
  var STORE_VIDS = [
    { v: 'sound-library-banner', t: 'Sound Library',    s: 'Every word and sentence you own', go: 'practice' },
    { meaning: 1,                t: 'The NowssB Store', s: 'Two libraries. One destination.', go: 'store' },
    { v: 'signature-banner',     t: 'NowssB Signature', s: 'The rarest words and meanings',   go: 'store' },
    { v: 'subscription-a',       t: 'Subscription',     s: 'Unlock the full word library',    go: 'subscription' },
    { v: 'coupon-a',             t: 'Offers & bundles', s: 'Coupons on words and meanings',   go: 'store' }
  ];
  var MEANING_VID = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/4c1c17d70f5656d48438620681f91a5a03c9cbef907f4c865ceb4bc1e2b56ed2.mp4';
  function storeVideos() {
    return '<section class="slm-sec">' + head('From the Store', chevron("slmStore()")) +
      '<div class="slm-hscroll">' + STORE_VIDS.map(function (x) {
        /* The meaning clip lives on Cloudinary and part026.js owns it — read
           it from there so there is one URL, with the literal as a fallback
           for the case where that file has not run yet. It has no local
           poster; the screen behind it is already black, which is what a
           poster would be for. */
        var src = x.meaning ? (window.MS_MEANING_VID || MEANING_VID) : './assets/video/' + x.v + '.mp4';
        var poster = x.meaning ? '' : ' poster="./assets/video/' + x.v + '-poster.webp"';
        return '<div class="slm-big" onclick="slmVidGo(\'' + jsArg(x.go) + '\')">' +
          frame('tab4-l',
            '<span class="slm-vidbox">' +
              '<video class="slm-vid" muted loop playsinline preload="none" aria-hidden="true" tabindex="-1"' +
              poster + ' src="' + src + '"></video>' +
            '</span>') +
          '<span class="slm-big-t">' + esc(x.t) + '</span>' +
          '<span class="slm-big-s">' + esc(x.s) + '</span>' +
          '</div>';
      }).join('') + '</div></section>';
  }

  /* ── The Atelier's fifteen collections, on their own banners ─────────── */
  function collectionCards() {
    var cs = collections();
    if (!cs.length) return '';
    return '<section class="slm-sec">' + head('Collections', chevron("slmStore()")) +
      '<div class="slm-hscroll">' + cs.map(function (c) {
        return '<div class="slm-big" onclick="slmStore()">' +
          frame('tab4-l', tile(colImg(c))) +
          '<span class="slm-big-t">' + esc(c.label) + '</span>' +
          '<span class="slm-big-s">' + esc(c.sub) + '</span>' +
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
        /* Four DIFFERENT collections in the four quadrants — the same
           banner cropped four ways is a smear, not a mosaic. Seeded by the
           category name so each one is its own arrangement and keeps it. */
        var cs = collections();
        var four = [0, 1, 2, 3].map(function (i) {
          return '<span class="slm-mo-q" style="background-image:url(\'' +
            esc(colImg(cs[(hash(c) + i * 4) % cs.length])) + '\');"></span>';
        }).join('');
        return '<div class="slm-mo" onclick="slmChip(\'' + jsArg(c) + '\')">' +
          frame('tab5-l', '<span class="slm-mo-grid">' + four + '</span>') +
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
          frame('tab5-l', tile(art(r.words[0]))) +
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
        frame('tab6-l', tile(meaningArt(m))) +
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
      html = sentenceSec() + storeVideos() + promo() + meaningRows();
    } else if (!ws.length) {
      html = '<div class="slm-empty">Nothing in this filter yet.' +
        '<button class="slm-pill slm-empty-cta" onclick="slmChip(\'All\')">Show everything</button></div>' + promo();
    } else {
      html = speedDial(ws) +
        '<section class="slm-sec">' + head('Quick picks', playAll(ws)) + rowPages(ws.slice(0, 12), counts) + '</section>' +
        storeVideos() +
        promo() +
        sentenceSec() +
        collectionCards() +
        bigCards(ws, counts) +
        mosaics() +
        albums() +
        meaningRows();
    }
    feed.innerHTML = html;

    /* The bell is the app's notification bell, not a sentence counter — its
       badge is one of the three app/js/part064.js paints, so ask that file
       to repaint rather than writing a different number into it here. */
    if (typeof window.nwsbNotifBadge === 'function') window.nwsbNotifBadge();
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
  /* The store is opened by hand everywhere else in the app — it has no
     openSub id, it is a screen that gets .open added and its intro clip
     started. Same three lines here rather than a fourth way of doing it. */
  window.slmStore = function () {
    var s = document.getElementById('sub-nowssb-store');
    if (s) s.classList.add('open');
    var iv = document.getElementById('nssIntroVid');
    if (iv) { iv.muted = true; iv.play().catch(function () {}); }
  };
  window.slmVidGo = function (go) {
    if (go === 'store') return window.slmStore();
    if (go === 'subscription') {
      if (window.SS && window.SS.open) return window.SS.open('subscription');
      return window.slmStore();
    }
    slmGo(go);
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
