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

  var MK = 'nwsb_reader_marks';
  var RM = 'nwsb_reader_reminders';

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

  /* ── What the reader remembers about a page ─────────────────────────
     Keyed by book then page, so a highlight on page 3 of one book cannot
     leak into page 3 of another. Everything is local — nothing here talks
     to a server. ── */
  function marks() {
    var raw; try { raw = JSON.parse(ls(MK, '{}')); } catch (e) { raw = {}; }
    return (raw && typeof raw === 'object') ? raw : {};
  }
  function pageMarks(bookKey, idx) {
    var m = marks();
    return (m[bookKey] && m[bookKey][idx]) || { hl: [], notes: [], mark: false };
  }
  function setPageMarks(bookKey, idx, v) {
    var m = marks();
    if (!m[bookKey]) m[bookKey] = {};
    m[bookKey][idx] = v;
    lsSet(MK, JSON.stringify(m));
  }
  /* Which book/page the tools are acting on right now. */
  function ctx() {
    return (curReader === 'meaning')
      ? { key: 'meanings', idx: mIdx, pages: meaningPages() }
      : { key: eBook ? eBook.key : '', idx: eIdx, pages: eBook ? bookPages(eBook) : [] };
  }
  var curReader = 'meaning';
  var swipeOn = false;      // swipe-to-highlight mode (see SWIPE HIGHLIGHT below)

  /* The last text the user selected inside a page — what the toolbar acts on. */
  var sel = '';
  function readSelection() {
    var s2 = '';
    try { s2 = String(window.getSelection ? window.getSelection().toString() : '').trim(); } catch (e) {}
    return s2;
  }
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
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4.6h3.1v14.8H4zM8.9 4.6H12v14.8H8.9z"/><path d="m14.4 5.6 2.9-.8 3 11.1-2.9.8z"/><path d="M4 19.4h16"/></svg>' +
        '</button>' +
      '</div>' +

      '<div class="rd-stage" id="rdMStage">' + pageHtml(pg, pages.length, mIdx) + '</div>' +

      '<div class="rd-rail">' +
        '<button onclick="rdToggleContents(\'meaning\')" aria-label="Contents"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4.6h3.1v14.8H4zM8.9 4.6H12v14.8H8.9z"/><path d="m14.4 5.6 2.9-.8 3 11.1-2.9.8z"/><path d="M4 19.4h16"/></svg></button>' +
        '<button onclick="rdTogglePanel(\'meaning\')" aria-label="Text settings"><span class="rd-aa">Aa</span></button>' +
        '<button onclick="rdSetPref(\'theme\',\'light\')" aria-label="Light theme"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.5 1.5M17.5 17.5 19 19M19 5l-1.5 1.5M6.5 17.5 5 19"/></svg></button>' +
        '<button onclick="rdSetPref(\'theme\',\'black\')" aria-label="Black theme"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M20.5 14.6A8.6 8.6 0 1 1 9.4 3.5a6.9 6.9 0 0 0 11.1 11.1Z"/></svg></button>' +
        '<button onclick="rdToggleTools(\'meaning\')" aria-label="Page tools"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16"/><path d="m6.5 16.5 8.4-8.4a2 2 0 0 1 2.8 0l.2.2a2 2 0 0 1 0 2.8l-8.4 8.4H6.5z"/></svg></button>' +
      '</div>' +

      /* Docked like the eBook reader's tray. As a floating popover it was
         narrower than its own controls, so the font name and the last theme
         swatch were cut off. */
      '<div class="rd-tray" id="rdMPop">' + settingsPanelHtml('meaning') + '</div>' +
      toolbarHtml() + toolsSheetHtml('meaning') + reminderHtml() +
      notepadHtml() + webHtml() +
      '<div class="rd-toast" id="rdToast"></div>' +

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
    curReader = 'meaning';
    bindSelection(host);
    bindSwipe(host);
    reapplyHighlights();
    refreshNotepad();
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
        '<button class="rd-tbtn" onclick="rdToggleTools(\'ebook\')" aria-label="Page tools">' +
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
        '<span class="rd-erow-toc" onclick="rdToggleContents(\'ebook\')">Contents</span>' +
        '<span>' + (eIdx + 1) + ' of ' + pages.length + '</span>' +
        '<span>' + pct + '%</span>' +
        '<span>' + (left === 0 ? 'last page' : left + ' page' + (left === 1 ? '' : 's') + ' left') + '</span>' +
      '</div>' +
      '<div class="rd-prog rd-prog-wide"><div class="rd-prog-fill" style="width:' + pct + '%"></div></div>' +

      '<div class="rd-tray" id="rdETray">' + settingsPanelHtml('ebook') + '</div>' +
      toolbarHtml() + toolsSheetHtml('ebook') + reminderHtml() +
      notepadHtml() + webHtml() +
      '<div class="rd-toast" id="rdToast"></div>' +

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
    curReader = 'ebook';
    bindSelection(host);
    bindSwipe(host);
    reapplyHighlights();
    refreshNotepad();
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

  function reminderHtml() {
    return '<div class="rd-remind" id="rdRemind">' +
      '<div class="rd-remind-card">' +
        '<div class="rd-remind-head" id="rdRemindHead">Remind me</div>' +
        REM.map(function (r) {
          return '<button class="rd-remind-b" onclick="rdSetReminder(' + r.k + ')">' + r.label + '</button>';
        }).join('') +
        '<button class="rd-remind-x" onclick="rdCloseReminder()">Cancel</button>' +
      '</div>' +
    '</div>';
  }

  /* ══ TOOLS ════════════════════════════════════════════════════════
     A toolbar that appears over a text selection — highlight it, keep a
     note on it, copy it, look it up, translate it — and a per-page sheet
     for the things that are about the page rather than a phrase: notes,
     highlights, a bookmark, and a reminder to come back.

     Translate and Search hand off to the web, which is the only honest way
     to do either from here — there is no dictionary or translation service
     inside the app to call. ══ */

  function toolbarHtml() {
    return '<div class="rd-seltools" id="rdSelTools">' +
      '<button onclick="rdMark(\'hl\')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16"/><path d="m6.5 16.5 8.4-8.4a2 2 0 0 1 2.8 0l.2.2a2 2 0 0 1 0 2.8l-8.4 8.4H6.5z"/></svg><span>Highlight</span></button>' +
      '<button onclick="rdMark(\'note\')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5.5A1.5 1.5 0 0 1 5.5 4H15l5 5v9.5a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 18.5z"/><path d="M14.5 4v5.5H20"/></svg><span>Note</span></button>' +
      '<button onclick="rdMark(\'copy\')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5.5A1.5 1.5 0 0 1 6.5 4H15"/></svg><span>Copy</span></button>' +
      '<button onclick="rdMark(\'translate\')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h11M8.5 4v2M11 6c0 4.5-3 8-8 10"/><path d="M6 11c1.5 2.6 4 4.6 7 5.6"/><path d="m13.5 20 4-9 4 9M15 17.4h5"/></svg><span>Translate</span></button>' +
      '<button onclick="rdMark(\'search\')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="6.5"/><path d="m16 16 4.5 4.5"/></svg><span>Search</span></button>' +
    '</div>';
  }

  /* The sheet for whole-page things. */
  function toolsSheetHtml(which) {
    var c = ctx(), pm = pageMarks(c.key, c.idx);
    return '<div class="rd-tools" id="rdTools' + (which === 'meaning' ? 'M' : 'E') + '">' +
      '<div class="rd-tools-head">Page tools' +
        '<button onclick="rdToggleTools(\'' + which + '\')" aria-label="Close">&times;</button></div>' +
      '<div class="rd-tools-grid">' +
        '<button class="rd-tool' + (pm.mark ? ' on' : '') + '" onclick="rdBookmark()">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M6.5 4h11v16l-5.5-4-5.5 4z"/></svg>' +
          '<span>' + (pm.mark ? 'Bookmarked' : 'Bookmark') + '</span></button>' +
        '<button class="rd-tool" onclick="rdAddNote()">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5.5A1.5 1.5 0 0 1 5.5 4H15l5 5v9.5a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 18.5z"/><path d="M14.5 4v5.5H20"/></svg>' +
          '<span>Notepad</span></button>' +
        '<button class="rd-tool rd-sw-btn' + (swipeOn ? ' on' : '') + '" onclick="rdSwipe()">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16"/><path d="m6.5 16.5 8.4-8.4a2 2 0 0 1 2.8 0l.2.2a2 2 0 0 1 0 2.8l-8.4 8.4H6.5z"/></svg>' +
          '<span>Swipe highlight</span></button>' +
        '<button class="rd-tool" onclick="rdOpenReminder()">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2M9 2.5h6"/></svg>' +
          '<span>Remind me</span></button>' +
        '<button class="rd-tool" onclick="rdMark(\'translate\', true)">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h11M8.5 4v2M11 6c0 4.5-3 8-8 10"/><path d="M6 11c1.5 2.6 4 4.6 7 5.6"/><path d="m13.5 20 4-9 4 9M15 17.4h5"/></svg>' +
          '<span>Translate page</span></button>' +
        '<button class="rd-tool" onclick="rdMark(\'search\', true)">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="6.5"/><path d="m16 16 4.5 4.5"/></svg>' +
          '<span>Search the web</span></button>' +
        '<button class="rd-tool" onclick="rdShare()">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v13M8 6.5 12 3l4 3.5"/><path d="M5 13v6.5h14V13"/></svg>' +
          '<span>Share</span></button>' +
      '</div>' +
      '<div class="rd-tools-lists" id="rdToolsLists">' + toolsListsHtml() + '</div>' +
    '</div>';
  }

  function toolsListsHtml() {
    var c = ctx(), pm = pageMarks(c.key, c.idx);
    var h = '';
    h += '<div class="rd-tools-lbl">Highlights on this page</div>';
    h += pm.hl.length
      ? '<div class="rd-mk-list">' + pm.hl.map(function (t, i) {
          return '<div class="rd-mk rd-mk-hl"><span>' + esc(t) + '</span>' +
                 '<button onclick="rdDrop(\'hl\',' + i + ')" aria-label="Remove">&times;</button></div>';
        }).join('') + '</div>'
      : '<div class="rd-mk-empty">Select any text on the page to highlight it.</div>';
    h += '<div class="rd-tools-lbl">Notes on this page</div>';
    h += pm.notes.length
      ? '<div class="rd-mk-list">' + pm.notes.map(function (n, i) {
          return '<div class="rd-mk rd-mk-note"><span>' + esc(n.t) +
                 (n.on ? '<em>on “' + esc(n.on) + '”</em>' : '') + '</span>' +
                 '<button onclick="rdDrop(\'notes\',' + i + ')" aria-label="Remove">&times;</button></div>';
        }).join('') + '</div>'
      : '<div class="rd-mk-empty">No notes yet.</div>';
    return h;
  }

  function refreshTools() {
    var l = document.getElementById('rdToolsLists');
    if (l) l.innerHTML = toolsListsHtml();
    reapplyHighlights();
  }

  /* Paint saved highlights back onto the page text after every render. */
  function reapplyHighlights() {
    var c = ctx(), pm = pageMarks(c.key, c.idx);
    var sc = document.getElementById('sub-reader-' + curReader);
    if (!sc) return;
    sc.querySelectorAll('.rd-page .rd-p').forEach(function (para) {
      var txt = para.getAttribute('data-raw') || para.textContent;
      para.setAttribute('data-raw', txt);
      var out = esc(txt);
      pm.hl.forEach(function (h) {
        if (!h) return;
        var i = out.indexOf(esc(h));
        if (i >= 0) out = out.slice(0, i) + '<mark class="rd-hl">' + esc(h) + '</mark>' + out.slice(i + esc(h).length);
      });
      para.innerHTML = out;
    });
  }

  window.rdToggleTools = function (which) {
    curReader = which;
    var id = 'rdTools' + (which === 'meaning' ? 'M' : 'E');
    var el = document.getElementById(id);
    if (el) { el.classList.toggle('open'); if (el.classList.contains('open')) refreshTools(); }
    haptic(15);
  };

  /* Selection toolbar — shown while there is a selection inside a page. */
  function bindSelection(sc) {
    if (!sc || sc._rdSel) return;
    sc._rdSel = true;
    var show = function () {
      var t = readSelection();
      var bar = sc.querySelector('.rd-seltools');
      if (!bar) return;
      if (t && t.length > 1) { sel = t; bar.classList.add('open'); }
      else { bar.classList.remove('open'); }
    };
    sc.addEventListener('mouseup', show);
    sc.addEventListener('touchend', function () { setTimeout(show, 40); }, { passive: true });
    sc.addEventListener('selectionchange', show);
    document.addEventListener('selectionchange', function () {
      if (sc.classList.contains('open')) show();
    });
  }

  window.rdMark = function (what, wholePage) {
    var c = ctx(), pm = pageMarks(c.key, c.idx);
    var pg = c.pages[c.idx] || {};
    var text = wholePage
      ? [pg.title, pg.root, (pg.body || []).join(' ')].filter(Boolean).join(' — ')
      : (sel || readSelection());
    if (!text) { toast('Select some text first'); return; }

    if (what === 'hl') {
      if (pm.hl.indexOf(text) < 0) pm.hl.push(text);
      setPageMarks(c.key, c.idx, pm); refreshTools(); toast('Highlighted'); haptic(28);
    } else if (what === 'note') {
      npOn = text.slice(0, 160);
      window.rdNotepad(1);
    } else if (what === 'copy') {
      try {
        if (navigator.clipboard) navigator.clipboard.writeText(text);
        toast('Copied'); haptic(20);
      } catch (e) { toast('Could not copy'); }
    } else if (what === 'translate') {
      rdWebOpen('translate', text);
    } else if (what === 'search') {
      rdWebOpen('search', text);
    }
    var bar = document.querySelector('#sub-reader-' + curReader + ' .rd-seltools');
    if (bar) bar.classList.remove('open');
  };

  window.rdDrop = function (kind, i) {
    var c = ctx(), pm = pageMarks(c.key, c.idx);
    if (!pm[kind]) return;
    pm[kind].splice(i, 1);
    setPageMarks(c.key, c.idx, pm);
    refreshTools(); haptic(20);
  };

  window.rdBookmark = function () {
    var c = ctx(), pm = pageMarks(c.key, c.idx);
    pm.mark = !pm.mark;
    setPageMarks(c.key, c.idx, pm);
    if (curReader === 'meaning') renderMeaning(); else renderEbook();
    window.rdToggleTools(curReader);
    toast(pm.mark ? 'Bookmarked' : 'Bookmark removed'); haptic(28);
  };
  window.rdAddNote = function () {
    var t = readSelection();
    npOn = t ? t.slice(0, 160) : '';
    window.rdNotepad(1);
  };
  window.rdShare = function () {
    var c = ctx(), pg = c.pages[c.idx] || {};
    var t = pg.title || 'NowssB Reader';
    if (navigator.share) { navigator.share({ title: t, text: t }).catch(function () {}); }
    else { window.rdMark('copy', true); }
  };

  /* ── Reminders ─────────────────────────────────────────────────────
     Stored with a due time and delivered through the app's own
     notification gate, so a reminder obeys the same switches as
     everything else rather than bypassing them. ── */
  var REM = [
    { k: 15,   label: 'In 15 minutes' },
    { k: 60,   label: 'In an hour' },
    { k: 180,  label: 'In 3 hours' },
    { k: 480,  label: 'This evening' },
    { k: 1440, label: 'Tomorrow' }
  ];
  window.rdOpenReminder = function () {
    var el = document.getElementById('rdRemind');
    if (!el) return;
    var c = ctx(), pg = c.pages[c.idx] || {};
    var head = document.getElementById('rdRemindHead');
    if (head) head.textContent = 'Remind me about “' + (pg.title || 'this page') + '”';
    el.classList.add('open');
    haptic(20);
  };
  window.rdCloseReminder = function () {
    var el = document.getElementById('rdRemind');
    if (el) el.classList.remove('open');
  };
  window.rdSetReminder = function (mins) {
    var c = ctx(), pg = c.pages[c.idx] || {};
    var list; try { list = JSON.parse(ls(RM, '[]')); } catch (e) { list = []; }
    if (!Array.isArray(list)) list = [];
    list.push({ at: Date.now() + mins * 60000, title: pg.title || 'Your reading',
                which: curReader, key: c.key, idx: c.idx });
    lsSet(RM, JSON.stringify(list));
    window.rdCloseReminder();
    window.rdToggleTools(curReader);
    toast('Reminder set'); haptic([30, 55, 30]);
  };
  /* Anything due is handed to nwsbNotify, which drops it if the user has
     Reading Reminders switched off. */
  function dueReminders() {
    var list; try { list = JSON.parse(ls(RM, '[]')); } catch (e) { list = []; }
    if (!Array.isArray(list) || !list.length) return;
    var now = Date.now(), keep = [];
    list.forEach(function (r) {
      if (r.at <= now) {
        if (window.nwsbNotify) {
          window.nwsbNotify({ type: 'reader', title: 'Back to “' + r.title + '”',
                              body: 'You asked to be reminded about this page.' });
        }
      } else keep.push(r);
    });
    if (keep.length !== list.length) lsSet(RM, JSON.stringify(keep));
  }

  function toast(msg) {
    var t = document.getElementById('rdToast');
    if (!t) return;
    t.textContent = msg;
    t.classList.add('show');
    clearTimeout(t._h);
    t._h = setTimeout(function () { t.classList.remove('show'); }, 1500);
  }


  /* ══ SWIPE HIGHLIGHT ══════════════════════════════════════════════
     With the mode on, dragging a finger across a line paints it and files
     the same words into the notepad — no keyboard, no dialog. The drag is
     widened to whole sentences at both ends, because a finger cannot land
     exactly on a full stop and half a sentence is not a useful note.

     touchmove is bound non-passively and preventDefault()ed while a drag
     is live, otherwise the page scrolls under the finger instead of the
     selection following it. ══ */

  function caretAt(x, y) {
    if (document.caretRangeFromPoint) return document.caretRangeFromPoint(x, y);
    if (document.caretPositionFromPoint) {
      var p = document.caretPositionFromPoint(x, y);
      if (!p) return null;
      var r = document.createRange();
      r.setStart(p.offsetNode, p.offset); r.collapse(true);
      return r;
    }
    return null;
  }

  /* Grow a partial drag out to the sentences it touches. */
  function sentenceAround(para, text) {
    if (!para || !text) return text;
    var raw = para.getAttribute('data-raw') || para.textContent || '';
    var i = raw.indexOf(text);
    if (i < 0) return text;
    var a = i, b = i + text.length;
    while (a > 0 && '.!?—'.indexOf(raw.charAt(a - 1)) < 0) a--;
    while (b < raw.length && '.!?'.indexOf(raw.charAt(b)) < 0) b++;
    if (b < raw.length) b++;
    return raw.slice(a, b).trim();
  }

  function saveSwiped(text) {
    if (!text || text.length < 2) return;
    var c = ctx(), pm = pageMarks(c.key, c.idx);
    if (pm.hl.indexOf(text) < 0) pm.hl.push(text);
    /* The swiped words are the note — that is the whole point of the mode. */
    var dup = pm.notes.some(function (n) { return n.t === text; });
    if (!dup) pm.notes.push({ t: text, on: '', at: Date.now(), auto: 1 });
    setPageMarks(c.key, c.idx, pm);
    refreshTools(); refreshNotepad();
    toast('Highlighted · saved to notepad');
    haptic([16, 26, 16]);
  }

  window.rdSwipe = function () {
    swipeOn = !swipeOn;
    ['sub-reader-meaning', 'sub-reader-ebook'].forEach(function (id) {
      var sc = document.getElementById(id);
      if (sc) sc.classList.toggle('rd-swipe', swipeOn);
    });
    document.querySelectorAll('.rd-sw-btn').forEach(function (b) { b.classList.toggle('on', swipeOn); });
    toast(swipeOn ? 'Swipe across any line to highlight it' : 'Swipe highlight off');
    haptic(swipeOn ? [20, 40, 20] : 20);
  };

  function bindSwipe(sc) {
    if (!sc || sc._rdSwipe) return;
    sc._rdSwipe = true;
    var start = null, para = null, live = false;

    function at(e) {
      var t = (e.touches && e.touches[0]) || (e.changedTouches && e.changedTouches[0]) || e;
      return { x: t.clientX, y: t.clientY };
    }
    function begin(e) {
      if (!swipeOn) return;
      var el = e.target && e.target.closest ? e.target.closest('.rd-p') : null;
      if (!el) return;
      para = el;
      var p = at(e);
      start = caretAt(p.x, p.y);
      live = !!start;
      if (live && e.cancelable) e.preventDefault();
    }
    function move(e) {
      if (!live || !start) return;
      if (e.cancelable) e.preventDefault();
      var p = at(e);
      var c = caretAt(p.x, p.y);
      if (!c) return;
      var r = document.createRange();
      try {
        r.setStart(start.startContainer, start.startOffset);
        r.setEnd(c.startContainer, c.startOffset);
      } catch (err) {
        /* dragged backwards past the anchor */
        try {
          r.setStart(c.startContainer, c.startOffset);
          r.setEnd(start.startContainer, start.startOffset);
        } catch (e2) { return; }
      }
      if (r.collapsed) return;
      var g = window.getSelection();
      g.removeAllRanges(); g.addRange(r);
    }
    function end() {
      if (!live) { start = null; return; }
      live = false;
      var t = readSelection();
      var host = para;
      start = null; para = null;
      if (!t) return;
      saveSwiped(sentenceAround(host, t));
      try { window.getSelection().removeAllRanges(); } catch (e) {}
    }

    sc.addEventListener('touchstart', begin, { passive: false });
    sc.addEventListener('touchmove', move, { passive: false });
    sc.addEventListener('touchend', end);
    sc.addEventListener('touchcancel', end);
    sc.addEventListener('mousedown', begin);
    sc.addEventListener('mousemove', move);
    sc.addEventListener('mouseup', end);
  }

  /* ══ NOTEPAD ══════════════════════════════════════════════════════
     A bubble parked over the page — one tap from anywhere in either
     reader — opening every note and highlight in the book you are in,
     grouped by page, with the page number as a jump. ══ */

  var npOn = '';    // the phrase a new note is being written about, if any

  function notepadHtml() {
    return '' +
      '<button class="rd-npbub" id="rdNpBub" onclick="rdNotepad(1)" aria-label="Notepad">' +
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">' +
          '<path d="M6 3h9l4 4v14a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z"/>' +
          '<path d="M14.5 3v4.5H19M8.5 12h7M8.5 16h4.5"/></svg>' +
        '<span class="rd-npbub-n" id="rdNpCount">0</span>' +
      '</button>' +
      '<div class="rd-np" id="rdNp" onclick="if(event.target===this)rdNotepad(0)">' +
        '<div class="rd-np-card">' +
          '<div class="rd-np-head">' +
            '<span class="rd-np-title">Notepad</span>' +
            '<span class="rd-np-sub" id="rdNpWhere"></span>' +
            '<button class="rd-np-x" onclick="rdNotepad(0)" aria-label="Close">&times;</button>' +
          '</div>' +
          '<div class="rd-np-on" id="rdNpOn"></div>' +
          '<div class="rd-np-new">' +
            '<textarea id="rdNpIn" rows="2" placeholder="Write a note…"></textarea>' +
            '<button class="rd-np-add" onclick="rdNpAdd()">Add</button>' +
          '</div>' +
          '<div class="rd-np-tools">' +
            '<button class="rd-np-b rd-sw-btn" onclick="rdSwipe()">' +
              '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">' +
              '<path d="M4 20h16"/><path d="m6.5 16.5 8.4-8.4a2 2 0 0 1 2.8 0l.2.2a2 2 0 0 1 0 2.8l-8.4 8.4H6.5z"/></svg>' +
              'Swipe Highlight</button>' +
            '<button class="rd-np-b" onclick="rdNpCopy()">' +
              '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">' +
              '<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5.5A1.5 1.5 0 0 1 6.5 4H15"/></svg>Copy all</button>' +
            '<button class="rd-np-b" onclick="rdNpShare()">' +
              '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">' +
              '<path d="M12 3v13M8 6.5 12 3l4 3.5"/><path d="M5 13v6.5h14V13"/></svg>Share</button>' +
            '<button class="rd-np-b" onclick="rdNpClear()">' +
              '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">' +
              '<path d="M5 7h14M9 7V5h6v2M7 7l1 13h8l1-13"/></svg>Clear book</button>' +
          '</div>' +
          '<div class="rd-np-list" id="rdNpList"></div>' +
        '</div>' +
      '</div>';
  }

  /* Everything kept in the book that is open, newest page first. */
  function bookEntries() {
    var c = ctx(), m = marks()[c.key] || {}, out = [];
    Object.keys(m).forEach(function (k) {
      var pm = m[k] || {};
      var hl = pm.hl || [];
      hl.forEach(function (t, i) { out.push({ page: +k, kind: 'hl', i: i, t: t }); });
      (pm.notes || []).forEach(function (n, i) {
        /* A swipe writes the same words twice — once as the highlight on the
           page, once as the note. Show that as one row, tagged, rather than
           the same sentence listed back to back. */
        if (n.auto && hl.indexOf(n.t) >= 0) {
          for (var j = 0; j < out.length; j++) {
            if (out[j].page === +k && out[j].kind === 'hl' && out[j].t === n.t) { out[j].auto = 1; break; }
          }
          return;
        }
        out.push({ page: +k, kind: 'notes', i: i, t: n.t, on: n.on, auto: n.auto, at: n.at });
      });
    });
    out.sort(function (a, b) { return a.page - b.page || (a.kind === b.kind ? a.i - b.i : (a.kind === 'hl' ? -1 : 1)); });
    return out;
  }

  function refreshNotepad() {
    var list = document.getElementById('rdNpList');
    var cnt = document.getElementById('rdNpCount');
    var where = document.getElementById('rdNpWhere');
    var on = document.getElementById('rdNpOn');
    var c = ctx();
    var rows = bookEntries();
    if (cnt) { cnt.textContent = String(rows.length); cnt.style.display = rows.length ? 'flex' : 'none'; }
    if (where) where.textContent = (curReader === 'meaning' ? 'The Book of Meanings' : (eBook ? eBook.title : 'Library'));
    if (on) {
      on.innerHTML = npOn ? 'on “' + esc(npOn) + '”' +
        '<button onclick="rdNpDropOn()" aria-label="Clear">&times;</button>' : '';
      on.style.display = npOn ? 'flex' : 'none';
    }
    document.querySelectorAll('.rd-sw-btn').forEach(function (b) { b.classList.toggle('on', swipeOn); });
    if (!list) return;
    if (!rows.length) {
      list.innerHTML = '<div class="rd-np-empty">Nothing yet. Turn on Swipe Highlight and drag across a line — ' +
        'it is painted on the page and lands here at the same time.</div>';
      return;
    }
    list.innerHTML = rows.map(function (r) {
      return '<div class="rd-np-i rd-np-' + r.kind + '">' +
        '<button class="rd-np-pg" onclick="rdJump(\'' + curReader + '\',' + r.page + ')">' + (r.page + 1) + '</button>' +
        '<div class="rd-np-txt">' + esc(r.t) +
          (r.on ? '<em>on “' + esc(r.on) + '”</em>' : '') +
          (r.auto ? '<i class="rd-np-tag">swiped</i>' : '') +
        '</div>' +
        '<button class="rd-np-go" onclick="rdWebOpen(\'search\',' + JSON.stringify(r.t).replace(/"/g, '&quot;') + ')" aria-label="Look up">' +
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="11" cy="11" r="6.5"/><path d="m16 16 4.5 4.5"/></svg></button>' +
        '<button class="rd-np-rm" onclick="rdNpDrop(' + r.page + ',\'' + r.kind + '\',' + r.i + ')" aria-label="Remove">&times;</button>' +
      '</div>';
    }).join('');
  }

  window.rdNotepad = function (open) {
    var el = document.getElementById('rdNp');
    if (!el) return;
    if (open) { refreshNotepad(); el.classList.add('open'); }
    else { el.classList.remove('open'); npOn = ''; }
    haptic(18);
  };
  window.rdNpDropOn = function () { npOn = ''; refreshNotepad(); };

  window.rdNpAdd = function () {
    var ta = document.getElementById('rdNpIn');
    var t = ta ? ta.value.trim() : '';
    if (!t) { toast('Write something first'); return; }
    var c = ctx(), pm = pageMarks(c.key, c.idx);
    pm.notes.push({ t: t, on: npOn, at: Date.now() });
    setPageMarks(c.key, c.idx, pm);
    if (ta) ta.value = '';
    npOn = '';
    refreshNotepad(); refreshTools();
    toast('Note saved'); haptic(28);
  };

  window.rdNpDrop = function (page, kind, i) {
    var c = ctx(), pm = pageMarks(c.key, page);
    if (!pm[kind]) return;
    pm[kind].splice(i, 1);
    setPageMarks(c.key, page, pm);
    refreshNotepad(); refreshTools();
    haptic(20);
  };

  function notepadText() {
    var rows = bookEntries();
    var head = (curReader === 'meaning' ? 'The Book of Meanings' : (eBook ? eBook.title : 'NowssB Reader'));
    return head + '\n\n' + rows.map(function (r) {
      return 'p' + (r.page + 1) + '  ' + r.t + (r.on ? '\n     on “' + r.on + '”' : '');
    }).join('\n\n');
  }

  window.rdNpCopy = function () {
    var rows = bookEntries();
    if (!rows.length) { toast('Nothing to copy'); return; }
    try {
      if (navigator.clipboard) navigator.clipboard.writeText(notepadText());
      toast('Notepad copied'); haptic(20);
    } catch (e) { toast('Could not copy'); }
  };
  window.rdNpShare = function () {
    var rows = bookEntries();
    if (!rows.length) { toast('Nothing to share'); return; }
    if (navigator.share) navigator.share({ title: 'NowssB Reader notes', text: notepadText() }).catch(function () {});
    else window.rdNpCopy();
  };
  window.rdNpClear = function () {
    var c = ctx(), m = marks();
    if (!m[c.key]) { toast('Nothing to clear'); return; }
    delete m[c.key];
    lsSet(MK, JSON.stringify(m));
    refreshNotepad(); refreshTools();
    if (curReader === 'meaning') renderMeaning(); else renderEbook();
    window.rdNotepad(1);
    toast('Notepad cleared'); haptic([20, 40, 20]);
  };

  /* ══ LOOK UP AND TRANSLATE, WITHOUT LEAVING THE READER ═════════════
     Translation is real and in-app: Google's translate endpoint answers
     with CORS, so the words come back into this sheet.

     Search is the honest half. Google's results page refuses to be framed
     (X-Frame-Options) and it has no endpoint a page may call, so what
     lands here is Wikipedia's summary and DuckDuckGo's instant answer —
     both of which do allow it — with Google one tap away for the full web
     results. That beats bouncing the reader out to a browser for a word.
     ══ */

  var LANGS = [
    { c: 'en', l: 'English' }, { c: 'hi', l: 'हिन्दी' },
    { c: 'mr', l: 'मराठी' }, { c: 'es', l: 'Español' },
    { c: 'fr', l: 'Français' }, { c: 'de', l: 'Deutsch' },
    { c: 'ar', l: 'العربية' }, { c: 'ja', l: '日本語' }
  ];
  var LK = 'nwsb_reader_lang';
  var webMode = 'translate', webText = '';

  function webHtml() {
    return '<div class="rd-web" id="rdWeb" onclick="if(event.target===this)rdWebClose()">' +
      '<div class="rd-web-card">' +
        '<div class="rd-np-head">' +
          '<span class="rd-np-title" id="rdWebTitle">Translate</span>' +
          '<button class="rd-np-x" onclick="rdWebClose()" aria-label="Close">&times;</button>' +
        '</div>' +
        '<div class="rd-web-src" id="rdWebSrc"></div>' +
        '<div class="rd-web-langs" id="rdWebLangs"></div>' +
        '<div class="rd-web-body" id="rdWebBody"></div>' +
        '<button class="rd-web-out" id="rdWebOut" onclick="rdWebOut()"></button>' +
      '</div>' +
    '</div>';
  }

  window.rdWebOpen = function (mode, text) {
    webMode = mode;
    webText = String(text || '').trim();
    if (!webText) { toast('Select some text first'); return; }
    var el = document.getElementById('rdWeb');
    if (!el) return;
    var bar = document.querySelector('#sub-reader-' + curReader + ' .rd-seltools');
    if (bar) bar.classList.remove('open');
    document.getElementById('rdWebTitle').textContent = mode === 'translate' ? 'Translate' : 'Look up';
    document.getElementById('rdWebSrc').textContent = webText.length > 220 ? webText.slice(0, 220) + '…' : webText;
    document.getElementById('rdWebOut').textContent =
      mode === 'translate' ? 'Open Google Translate' : 'Open full Google results';
    var langs = document.getElementById('rdWebLangs');
    if (mode === 'translate') {
      var to = ls(LK, 'hi');
      langs.innerHTML = LANGS.map(function (g) {
        return '<button class="rd-web-lang' + (g.c === to ? ' on' : '') + '" onclick="rdWebLang(\'' + g.c + '\')">' + g.l + '</button>';
      }).join('');
      langs.style.display = 'flex';
    } else {
      langs.innerHTML = ''; langs.style.display = 'none';
    }
    el.classList.add('open');
    haptic(20);
    if (mode === 'translate') runTranslate(); else runSearch();
  };
  window.rdWebClose = function () {
    var el = document.getElementById('rdWeb');
    if (el) el.classList.remove('open');
  };
  window.rdWebLang = function (c) { lsSet(LK, c); window.rdWebOpen('translate', webText); };
  window.rdWebOut = function () {
    var u = webMode === 'translate'
      ? 'https://translate.google.com/?sl=auto&tl=' + ls(LK, 'hi') + '&op=translate&text=' + encodeURIComponent(webText)
      : 'https://www.google.com/search?q=' + encodeURIComponent(webText);
    window.open(u, '_blank');
    haptic(20);
  };

  function webBody(html) {
    var b = document.getElementById('rdWebBody');
    if (b) b.innerHTML = html;
  }

  function runTranslate() {
    var to = ls(LK, 'hi');
    webBody('<div class="rd-web-wait">Translating…</div>');
    var url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=' +
      encodeURIComponent(to) + '&dt=t&q=' + encodeURIComponent(webText);
    fetch(url).then(function (r) { return r.json(); }).then(function (j) {
      var out = (j && j[0] ? j[0] : []).map(function (p) { return p && p[0] ? p[0] : ''; }).join('');
      if (!out) throw new Error('empty');
      webBody('<div class="rd-web-txt">' + esc(out) + '</div>' +
        '<div class="rd-web-note">Google Translate · detected ' + esc(j[2] || 'source') + '</div>' +
        '<button class="rd-web-save" onclick="rdWebSave()">Save to notepad</button>');
    }).catch(function () {
      webBody('<div class="rd-web-note">Could not reach Google Translate from here — ' +
        'check the connection, or open it with the button below.</div>');
    });
  }

  function runSearch() {
    var q = webText.split(/\s+/).slice(0, 10).join(' ');
    webBody('<div class="rd-web-wait">Looking it up…</div>');
    var wiki = fetch('https://en.wikipedia.org/api/rest_v1/page/summary/' +
        encodeURIComponent(q.replace(/\s+/g, '_')))
      .then(function (r) { return r.ok ? r.json() : null; }).catch(function () { return null; });
    var ddg = fetch('https://api.duckduckgo.com/?format=json&no_html=1&skip_disambig=1&q=' + encodeURIComponent(q))
      .then(function (r) { return r.ok ? r.json() : null; }).catch(function () { return null; });
    Promise.all([wiki, ddg]).then(function (res) {
      var w = res[0], d = res[1], h = '';
      if (w && w.extract) {
        h += '<div class="rd-web-res"><span class="rd-web-from">Wikipedia</span>' +
          '<div class="rd-web-txt">' + esc(w.extract) + '</div></div>';
      }
      if (d && d.AbstractText) {
        h += '<div class="rd-web-res"><span class="rd-web-from">' + esc(d.AbstractSource || 'DuckDuckGo') + '</span>' +
          '<div class="rd-web-txt">' + esc(d.AbstractText) + '</div></div>';
      } else if (d && d.RelatedTopics && d.RelatedTopics.length) {
        h += '<div class="rd-web-res"><span class="rd-web-from">DuckDuckGo</span><div class="rd-web-txt">' +
          d.RelatedTopics.slice(0, 3).map(function (t) { return esc(t.Text || ''); })
            .filter(Boolean).join('<br><br>') + '</div></div>';
      }
      if (!h) {
        h = '<div class="rd-web-note">No summary came back for this phrase. ' +
            'Google has the full web results — its own results page cannot be shown ' +
            'inside the app, so the button below opens it.</div>';
      } else {
        h += '<button class="rd-web-save" onclick="rdWebSave()">Save to notepad</button>';
      }
      webBody(h);
    }).catch(function () {
      webBody('<div class="rd-web-note">Could not reach the network from here.</div>');
    });
  }

  /* Whatever the sheet is showing can go straight into the notepad. */
  window.rdWebSave = function () {
    var b = document.getElementById('rdWebBody');
    var t = b ? (b.querySelector('.rd-web-txt') || {}).textContent : '';
    if (!t) { toast('Nothing to save'); return; }
    var c = ctx(), pm = pageMarks(c.key, c.idx);
    pm.notes.push({ t: t.trim(), on: webText.slice(0, 80), at: Date.now() });
    setPageMarks(c.key, c.idx, pm);
    refreshNotepad(); refreshTools();
    toast('Saved to notepad'); haptic(28);
  };

  /* ── Screens ───────────────────────────────────────────────────────── */
  window.rdOpen = function () {
    var sc = document.getElementById('sub-reader');
    if (sc) sc.classList.add('open');
    haptic(28);
  };
  window.rdOpenMeaning = function () {
    var sc = document.getElementById('sub-reader-meaning');
    if (!sc) return;
    curReader = 'meaning';
    renderMeaning();
    sc.classList.add('open');
    haptic(28);
  };
  window.rdOpenEbook = function () {
    var sc = document.getElementById('sub-reader-ebook');
    if (!sc) return;
    curReader = 'ebook';
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

  /* Reminders are checked on load and every minute the app stays open. */
  function bootReminders() { try { dueReminders(); } catch (e) {} }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', bootReminders);
  else bootReminders();
  setInterval(function () { try { dueReminders(); } catch (e) {} }, 60000);

})();
