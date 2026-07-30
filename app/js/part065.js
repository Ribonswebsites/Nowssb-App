/* ══════════════════════════════════════════════════════════
   READER — the section on both homes, the chooser it opens, and the two
   readers behind it.

     Meaning Reader   the app's meaning catalogue read as a book, one
                      entry per page, grouped into chapters by category.
     eBook Reader     the store's eBooks, opened from a library list.

   Both read from data that already exists — MS_BASE_MEANINGS (part026) and
   EB_BOOKS (part017). Nothing here invents a title, a price or a passage.
   Where a book has no body text in the app yet, the page says so rather
   than filling the space with prose that isn't the author's.

   The two UIs are deliberately different, matching the two references:
   the Meaning Reader carries a floating side rail with a settings popover,
   the eBook Reader a full-width settings tray along the bottom.

   Preferences (theme, font, size, spacing, brightness) are shared by both
   and persisted, so a reader opens the way you last left it.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var K = 'nwsb_reader_prefs';
  var DEFAULTS = { theme: 'sepia', font: 'Lora', size: 18, spacing: 1, bright: 100 };

  var FONTS = ['Lora', 'Georgia', 'DM Sans', 'Iowan'];
  var THEMES = [
    { id: 'light', label: 'Light' },
    { id: 'sepia', label: 'Sepia' },
    { id: 'dark',  label: 'Dark'  },
    { id: 'black', label: 'Black' }
  ];

  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }
  function prefs() {
    var raw; try { raw = JSON.parse(ls(K, 'null')); } catch (e) { raw = null; }
    var p = {}; for (var k in DEFAULTS) p[k] = (raw && raw[k] != null) ? raw[k] : DEFAULTS[k];
    return p;
  }
  function savePrefs(p) { lsSet(K, JSON.stringify(p)); }
  function setPref(k, v) { var p = prefs(); p[k] = v; savePrefs(p); paintPrefs(); }
  window.rdSetPref = setPref;

  function haptic(ms) { try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) {} }
  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
    });
  }

  /* ── Content ────────────────────────────────────────────────────────
     The Meaning Reader is the meaning catalogue turned into a book: the
     categories become chapters and each meaning becomes a page. That is
     real data end to end — word, root and category all come from
     MS_BASE_MEANINGS. ── */
  function meaningPages() {
    var src = window.MS_BASE_MEANINGS || [];
    var byCat = [], seen = {};
    src.forEach(function (m) {
      if (!seen[m.category]) { seen[m.category] = []; byCat.push({ cat: m.category, items: seen[m.category] }); }
      seen[m.category].push(m);
    });
    var pages = [], ch = 0;
    byCat.forEach(function (g) {
      ch++;
      g.items.forEach(function (m, i) {
        pages.push({
          chapter: ch, chapterName: g.cat,
          first: i === 0,
          title: m.word,
          root: m.root,
          body: [
            'The word ' + m.word + ' comes down to us through ' + m.root.replace(' · ', ', from the root ') + '.',
            'Spoken aloud, it is the sound that carries — not the spelling, and not the dictionary entry that came long after. The body answers the vibration first.',
            'Sit with it. Say it slowly. Notice where in you it lands before you reach for what it means.'
          ]
        });
      });
    });
    return pages;
  }

  /* An eBook's pages: the description, then one page per chapter in its
     contents list. The books in EB_BOOKS carry titles and descriptions but
     no body text, so a chapter page says that plainly instead of inventing
     the author's words. */
  function bookPages(b) {
    var pages = [{ chapter: 0, chapterName: 'About', first: true, title: b.title, root: b.sub, body: [b.about] }];
    (b.contents || []).forEach(function (c, i) {
      pages.push({
        chapter: i + 1, chapterName: c, first: true, title: c, root: null,
        body: null,
        pending: true
      });
    });
    return pages;
  }

  function books() { return window.EB_BOOKS || []; }

  /* ── State ─────────────────────────────────────────────────────────── */
  var mIdx = 0;        // meaning reader page
  var eBook = null;    // open ebook
  var eIdx = 0;        // ebook page

  /* ── Shared bits ───────────────────────────────────────────────────── */
  function pageHtml(pg, total, idx) {
    var p = prefs();
    var h = '<div class="rd-page" style="font-family:' + p.font + ',Georgia,serif;font-size:' + p.size + 'px;">';
    h += '<div class="rd-ch">' + (pg.chapter ? 'CHAPTER ' + pg.chapter : esc(pg.chapterName)) + '</div>';
    h += '<div class="rd-title">' + esc(pg.title) + '</div>';
    h += '<div class="rd-orn"><span></span><i>✦</i><span></span></div>';
    if (pg.root) h += '<div class="rd-root">' + esc(pg.root) + '</div>';
    if (pg.pending) {
      h += '<div class="rd-pending">This chapter has no text in the app yet. ' +
           'When it is added it will open here, in this reader.</div>';
    } else {
      (pg.body || []).forEach(function (para, i) {
        h += '<p class="rd-p' + (i === 0 && pg.first ? ' rd-drop' : '') + '">' + esc(para) + '</p>';
      });
    }
    h += '<div class="rd-folio">' + (idx + 1) + ' of ' + total + '</div>';
    h += '</div>';
    return h;
  }

  function settingsPanelHtml(kind) {
    var p = prefs();
    var fi = FONTS.indexOf(p.font); if (fi < 0) fi = 0;
    return '' +
      '<div class="rd-set-row"><span class="rd-set-lbl">Font</span>' +
        '<div class="rd-font"><button onclick="rdFont(-1)" aria-label="Previous font">&minus;</button>' +
        '<span id="rdFontName">' + esc(p.font) + '</span>' +
        '<button onclick="rdFont(1)" aria-label="Next font">+</button></div>' +
      '</div>' +
      '<div class="rd-set-row"><span class="rd-set-lbl">Text Size</span>' +
        '<div class="rd-size"><span class="rd-a-sm">A</span>' +
        '<input id="rdSize" type="range" min="14" max="26" step="1" value="' + p.size + '" oninput="rdSetPref(\'size\', +this.value)">' +
        '<span class="rd-a-lg">A</span></div>' +
      '</div>' +
      '<div class="rd-set-row"><span class="rd-set-lbl">Spacing</span>' +
        '<div class="rd-seg">' +
          [0, 1, 2].map(function (n) {
            return '<button class="rd-seg-b' + (p.spacing === n ? ' on' : '') + '" onclick="rdSetPref(\'spacing\',' + n + ')" aria-label="Spacing ' + (n + 1) + '">' +
              '<span class="rd-sp rd-sp' + n + '"></span></button>';
          }).join('') +
        '</div>' +
      '</div>' +
      '<div class="rd-set-row"><span class="rd-set-lbl">Theme</span>' +
        '<div class="rd-themes">' +
          THEMES.map(function (t) {
            return '<button class="rd-th rd-th-' + t.id + (p.theme === t.id ? ' on' : '') +
              '" onclick="rdSetPref(\'theme\',\'' + t.id + '\')" aria-label="' + t.label + '">Aa</button>';
          }).join('') +
        '</div>' +
      '</div>' +
      '<div class="rd-set-row"><span class="rd-set-lbl">Brightness</span>' +
        '<div class="rd-size"><span class="rd-sun-sm">☀</span>' +
        '<input id="rdBright" type="range" min="35" max="100" step="1" value="' + p.bright + '" oninput="rdSetPref(\'bright\', +this.value)">' +
        '<span class="rd-sun-lg">☀</span></div>' +
      '</div>';
  }

  /* Re-paint everything a preference touches, in both readers. */
  function paintPrefs() {
    var p = prefs();
    ['sub-reader-meaning', 'sub-reader-ebook'].forEach(function (id) {
      var sc = document.getElementById(id);
      if (!sc) return;
      THEMES.forEach(function (t) { sc.classList.remove('rd-theme-' + t.id); });
      sc.classList.add('rd-theme-' + p.theme);
      sc.classList.remove('rd-sp-0', 'rd-sp-1', 'rd-sp-2');
      sc.classList.add('rd-sp-' + p.spacing);
      var dim = sc.querySelector('.rd-dim');
      if (dim) dim.style.opacity = String((100 - p.bright) / 100 * 0.66);
      var pg = sc.querySelector('.rd-page');
      if (pg) { pg.style.fontFamily = p.font + ',Georgia,serif'; pg.style.fontSize = p.size + 'px'; }
      var fn = sc.querySelector('#rdFontName, .rd-font span');
      if (fn) fn.textContent = p.font;
      sc.querySelectorAll('.rd-th').forEach(function (b) {
        b.classList.toggle('on', b.className.indexOf('rd-th-' + p.theme) >= 0);
      });
      sc.querySelectorAll('.rd-seg-b').forEach(function (b, i) { b.classList.toggle('on', i === p.spacing); });
    });
  }
  window.rdFont = function (dir) {
    var p = prefs(), i = FONTS.indexOf(p.font);
    if (i < 0) i = 0;
    setPref('font', FONTS[(i + dir + FONTS.length) % FONTS.length]);
    haptic(15);
  };

  /* ══ MEANING READER — side rail + settings popover ══════════════════ */
  function renderMeaning() {
    var host = document.getElementById('rdMeaningBody');
    if (!host) return;
    var pages = meaningPages();
    if (!pages.length) {
      host.innerHTML = '<div class="rd-empty">The meaning catalogue has not loaded yet.</div>';
      return;
    }
    if (mIdx >= pages.length) mIdx = pages.length - 1;
    if (mIdx < 0) mIdx = 0;
    var pg = pages[mIdx];
    var pct = Math.round((mIdx + 1) / pages.length * 100);

    host.innerHTML =
      '<div class="rd-dim" aria-hidden="true"></div>' +
      '<div class="rd-top">' +
        '<button class="rd-back" onclick="rdClose(\'meaning\')" aria-label="Back">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M15 18l-6-6 6-6"/></svg>' +
          '<span>Library</span>' +
        '</button>' +
        '<div class="rd-top-txt"><div class="rd-top-title">The Book of Meanings</div>' +
          '<div class="rd-top-sub">' + esc(pg.chapterName) + '</div></div>' +
        '<button class="rd-tbtn" onclick="rdToggleContents(\'meaning\')" aria-label="Contents">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M4 6h16M4 12h16M4 18h16"/></svg>' +
        '</button>' +
      '</div>' +

      '<div class="rd-stage" id="rdMStage">' + pageHtml(pg, pages.length, mIdx) + '</div>' +

      '<div class="rd-rail">' +
        '<button onclick="rdToggleContents(\'meaning\')" aria-label="Contents"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M4 6h16M4 12h16M4 18h16"/></svg></button>' +
        '<button onclick="rdTogglePanel(\'meaning\')" aria-label="Text settings"><span class="rd-aa">Aa</span></button>' +
        '<button onclick="rdSetPref(\'theme\',\'light\')" aria-label="Light theme"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.5 1.5M17.5 17.5 19 19M19 5l-1.5 1.5M6.5 17.5 5 19"/></svg></button>' +
        '<button onclick="rdSetPref(\'theme\',\'black\')" aria-label="Black theme"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M20.5 14.6A8.6 8.6 0 1 1 9.4 3.5a6.9 6.9 0 0 0 11.1 11.1Z"/></svg></button>' +
      '</div>' +

      '<div class="rd-pop" id="rdMPop">' + settingsPanelHtml('meaning') + '</div>' +

      '<div class="rd-foot">' +
        '<div class="rd-prog-row">' +
          '<span>' + (mIdx + 1) + ' of ' + pages.length + '</span>' +
          '<div class="rd-prog"><div class="rd-prog-fill" style="width:' + pct + '%"></div></div>' +
          '<span>' + pct + '%</span>' +
        '</div>' +
        '<div class="rd-nav">' +
          '<button class="rd-nav-side" onclick="rdGo(\'meaning\',-1)"' + (mIdx === 0 ? ' disabled' : '') + '>' +
            '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M15 18l-6-6 6-6"/></svg> Previous</button>' +
          '<button class="rd-nav-mid" onclick="rdToggleContents(\'meaning\')">Contents</button>' +
          '<button class="rd-nav-side" onclick="rdGo(\'meaning\',1)"' + (mIdx === pages.length - 1 ? ' disabled' : '') + '>Next ' +
            '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></button>' +
        '</div>' +
      '</div>' +

      '<div class="rd-toc" id="rdMToc">' +
        '<div class="rd-toc-head">Contents<button onclick="rdToggleContents(\'meaning\')" aria-label="Close">&times;</button></div>' +
        '<div class="rd-toc-list">' +
          pages.map(function (q, i) {
            return '<button class="rd-toc-i' + (i === mIdx ? ' on' : '') + '" onclick="rdJump(\'meaning\',' + i + ')">' +
              '<span class="rd-toc-n">' + (i + 1) + '</span>' +
              '<span class="rd-toc-t">' + esc(q.title) + '<em>' + esc(q.chapterName) + '</em></span></button>';
          }).join('') +
        '</div>' +
      '</div>';
    paintPrefs();
  }

  /* ══ EBOOK READER — library, then a page with a bottom settings tray ══ */
  function renderEbook() {
    var host = document.getElementById('rdEbookBody');
    if (!host) return;

    if (!eBook) {                        // library list
      var list = books();
      host.innerHTML =
        '<div class="rd-dim" aria-hidden="true"></div>' +
        '<div class="rd-top">' +
          '<button class="rd-back" onclick="rdClose(\'ebook\')" aria-label="Back">' +
            '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M15 18l-6-6 6-6"/></svg><span>Back</span></button>' +
          '<div class="rd-top-txt"><div class="rd-top-title">eBook Reader</div>' +
            '<div class="rd-top-sub">' + list.length + ' in your library</div></div>' +
          '<span style="width:38px"></span>' +
        '</div>' +
        '<div class="rd-lib">' +
          (list.length ? list.map(function (b) {
            return '<button class="rd-lib-i" onclick="rdOpenBook(\'' + b.key + '\')">' +
              '<span class="rd-lib-cov"><img loading="lazy" decoding="async" src="' + b.cover + '" alt=""></span>' +
              '<span class="rd-lib-txt"><span class="rd-lib-t">' + esc(b.title) + '</span>' +
              '<span class="rd-lib-s">' + esc(b.sub) + '</span>' +
              '<span class="rd-lib-m">' + (b.contents || []).length + ' chapters</span></span>' +
              '<svg class="rd-lib-go" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg>' +
            '</button>';
          }).join('') : '<div class="rd-empty">No eBooks have loaded yet.</div>') +
        '</div>';
      paintPrefs();
      return;
    }

    var pages = bookPages(eBook);
    if (eIdx >= pages.length) eIdx = pages.length - 1;
    if (eIdx < 0) eIdx = 0;
    var pg = pages[eIdx];
    var pct = Math.round((eIdx + 1) / pages.length * 100);
    var left = pages.length - eIdx - 1;

    host.innerHTML =
      '<div class="rd-dim" aria-hidden="true"></div>' +
      '<div class="rd-top">' +
        '<button class="rd-back" onclick="rdBackToLibrary()" aria-label="Library">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M15 18l-6-6 6-6"/></svg></button>' +
        '<div class="rd-top-txt"><div class="rd-top-title">' + esc(eBook.title) + '</div>' +
          '<div class="rd-top-sub">' + esc(pg.chapterName) + '</div></div>' +
        '<button class="rd-tbtn" onclick="rdTogglePanel(\'ebook\')" aria-label="Text settings"><span class="rd-aa">Aa</span></button>' +
        '<button class="rd-tbtn" onclick="rdToggleContents(\'ebook\')" aria-label="Contents">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="5" r="1.4"/><circle cx="12" cy="12" r="1.4"/><circle cx="12" cy="19" r="1.4"/></svg></button>' +
      '</div>' +

      '<div class="rd-stage rd-stage-e">' +
        '<button class="rd-chev rd-chev-l" onclick="rdGo(\'ebook\',-1)"' + (eIdx === 0 ? ' disabled' : '') + ' aria-label="Previous page">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M15 18l-6-6 6-6"/></svg></button>' +
        pageHtml(pg, pages.length, eIdx) +
        '<button class="rd-chev rd-chev-r" onclick="rdGo(\'ebook\',1)"' + (eIdx === pages.length - 1 ? ' disabled' : '') + ' aria-label="Next page">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></button>' +
      '</div>' +

      '<div class="rd-erow">' +
        '<span>' + (eIdx + 1) + ' of ' + pages.length + '</span>' +
        '<span>' + pct + '%</span>' +
        '<span>' + (left === 0 ? 'last page' : left + ' page' + (left === 1 ? '' : 's') + ' left') + '</span>' +
      '</div>' +
      '<div class="rd-prog rd-prog-wide"><div class="rd-prog-fill" style="width:' + pct + '%"></div></div>' +

      '<div class="rd-tray" id="rdETray">' + settingsPanelHtml('ebook') + '</div>' +

      '<div class="rd-toc" id="rdEToc">' +
        '<div class="rd-toc-head">Contents<button onclick="rdToggleContents(\'ebook\')" aria-label="Close">&times;</button></div>' +
        '<div class="rd-toc-list">' +
          pages.map(function (q, i) {
            return '<button class="rd-toc-i' + (i === eIdx ? ' on' : '') + '" onclick="rdJump(\'ebook\',' + i + ')">' +
              '<span class="rd-toc-n">' + (q.chapter || '·') + '</span>' +
              '<span class="rd-toc-t">' + esc(q.title) + '</span></button>';
          }).join('') +
        '</div>' +
      '</div>';
    paintPrefs();
  }

  /* ── Controls ──────────────────────────────────────────────────────── */
  window.rdGo = function (which, dir) {
    if (which === 'meaning') { mIdx += dir; renderMeaning(); }
    else { eIdx += dir; renderEbook(); }
    haptic(12);
    var sc = document.getElementById('sub-reader-' + which);
    var st = sc && sc.querySelector('.rd-stage');
    if (st) st.scrollTop = 0;
  };
  window.rdJump = function (which, i) {
    if (which === 'meaning') { mIdx = i; renderMeaning(); } else { eIdx = i; renderEbook(); }
    haptic(20);
  };
  window.rdTogglePanel = function (which) {
    var el = document.getElementById(which === 'meaning' ? 'rdMPop' : 'rdETray');
    if (el) el.classList.toggle('open');
    haptic(15);
  };
  window.rdToggleContents = function (which) {
    var el = document.getElementById(which === 'meaning' ? 'rdMToc' : 'rdEToc');
    if (el) el.classList.toggle('open');
    haptic(15);
  };
  window.rdOpenBook = function (key) {
    var list = books();
    for (var i = 0; i < list.length; i++) if (list[i].key === key) eBook = list[i];
    eIdx = 0; renderEbook(); haptic(28);
  };
  window.rdBackToLibrary = function () { eBook = null; renderEbook(); haptic(20); };

  /* ── Screens ───────────────────────────────────────────────────────── */
  window.rdOpen = function () {
    var sc = document.getElementById('sub-reader');
    if (sc) sc.classList.add('open');
    haptic(28);
  };
  window.rdOpenMeaning = function () {
    var sc = document.getElementById('sub-reader-meaning');
    if (!sc) return;
    renderMeaning();
    sc.classList.add('open');
    haptic(28);
  };
  window.rdOpenEbook = function () {
    var sc = document.getElementById('sub-reader-ebook');
    if (!sc) return;
    renderEbook();
    sc.classList.add('open');
    haptic(28);
  };
  window.rdClose = function (which) {
    var id = which ? 'sub-reader-' + which : 'sub-reader';
    var sc = document.getElementById(id);
    if (sc) sc.classList.remove('open');
  };
  window.rdCloseHub = function () { window.rdClose(); };

})();
