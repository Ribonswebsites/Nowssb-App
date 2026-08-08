/* ── Pronunciation Notes ──────────────────────────────────────────────────
   Opened from the band under the player's header. It answers one question:
   what did I get wrong, and how do I say it properly.

   Everything on it is real. The score and the transcript are the attempt
   app/js/part019.js just made. The syllable marks are worked out here, by
   a stricter rule than the one the score uses — see compare() for why the
   score's own test cannot answer this question. The coaching underneath is
   the word's own entry in MASTER_WORD_LIBRARY, which already carries
   mouthPos, resonance, the common mistake and a tip. Nothing here is
   generated.

   With no attempt recorded yet the page says so and shows the coaching on
   its own, rather than inventing a fault to report. ── */
(function () {
  'use strict';

  var KEY = 'nwsb_pron_attempts';

  function all() {
    try { return JSON.parse(localStorage.getItem(KEY) || '{}'); } catch (e) { return {}; }
  }
  function save(map) {
    try { localStorage.setItem(KEY, JSON.stringify(map)); } catch (e) {}
  }

  /* Called by part019.js the moment a recording is scored. */
  window.lgpSaveAttempt = function (word, score, transcript, phonetic) {
    if (!word) return;
    var m = all();
    var prev = m[word] || {};
    m[word] = {
      score: score,
      transcript: String(transcript || ''),
      phonetic: String(phonetic || ''),
      at: Date.now(),
      /* Best is worth keeping separately — the last try being worse than
         your best is exactly the thing a notes page should be able to say. */
      best: Math.max(score, prev.best || 0),
      tries: (prev.tries || 0) + 1
    };
    save(m);
  };
  window.lgpLastAttempt = function (word) { return all()[word] || null; };

  /* ── Which syllables actually landed ──
     NOT part019.js's test. That one counts a syllable as landed if the
     syllable merely CONTAINS a heard fragment, which is far too loose to
     diagnose anything: "aa row jup" against "aa · ro · gyaa" passes all
     three, because "gyaa" contains the heard "aa". A page whose whole job
     is to say what went wrong cannot use a rule that can hardly ever say
     it.
     So the marks use nearest-match by edit distance, normalised by
     syllable length — landed if a third or less of the syllable is wrong.
     On that same attempt: aa lands, ro lands against "row" (1 of 3), gyaa
     misses against "aa" (2 of 4). The headline number is still part019's,
     and it is labelled as the overall match rather than as a count of
     these marks, because they are answering different questions. */
  function lev(a, b) {
    var m = a.length, n = b.length, i, j;
    if (!m) return n; if (!n) return m;
    var dp = [];
    for (i = 0; i <= m; i++) { dp[i] = [i]; }
    for (j = 0; j <= n; j++) { dp[0][j] = j; }
    for (i = 1; i <= m; i++)
      for (j = 1; j <= n; j++)
        dp[i][j] = a[i - 1] === b[j - 1] ? dp[i - 1][j - 1]
                 : 1 + Math.min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
    return dp[m][n];
  }
  var TOL = 0.34;   // a third of the syllable may be wrong
  function compare(heard, phonetic) {
    var a = String(heard || '').toLowerCase().replace(/[^a-z\s]/g, '').trim();
    var b = String(phonetic || '').toLowerCase().replace(/[·\-]/g, ' ').replace(/[^a-z\s]/g, '').trim();
    var parts = b.split(/\s+/).filter(Boolean);
    var heardParts = a ? a.split(/\s+/) : [];
    return parts.map(function (syl) {
      var best = 1;
      heardParts.forEach(function (p) {
        var d = lev(p, syl) / Math.max(p.length, syl.length, 1);
        if (d < best) best = d;
      });
      return { syl: syl, ok: heardParts.length > 0 && best <= TOL };
    });
  }

  function esc(x) {
    return String(x == null ? '' : x)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
  function word() {
    var lib = window.PRACTICE_WORDS || window.MASTER_WORD_LIBRARY || [];
    var i = typeof window._pwIdx === 'number' ? window._pwIdx : 0;
    return lib[i] || lib[0] || null;
  }
  function band(s) { return s >= 80 ? 'good' : s >= 55 ? 'mid' : 'low'; }

  function render(w) {
    var a = window.lgpLastAttempt(w.word);
    var sylsFromWord = (w.syllables && w.syllables.length)
      ? w.syllables
      : String(w.phonetic || '').split('·').map(function (x) { return x.trim(); }).filter(Boolean);

    var html = '';

    /* ── What you said, and what missed ── */
    if (a) {
      var cmp = compare(a.transcript, a.phonetic || w.phonetic);
      var missed = cmp.filter(function (c) { return !c.ok; });
      html +=
        '<div class="pn-card pn-' + band(a.score) + '">' +
          '<div class="pn-score-row">' +
            '<div class="pn-score"><b>' + a.score + '</b><span>/100</span></div>' +
            '<div class="pn-score-txt">' +
              '<div class="pn-score-head">Overall match</div>' +
              '<div class="pn-score-sub">Best ' + a.best + ' · ' + a.tries + ' attempt' + (a.tries === 1 ? '' : 's') + '</div>' +
            '</div>' +
          '</div>' +
          '<div class="pn-heard"><span class="pn-lbl">We heard</span>' +
            '<span class="pn-heard-txt">' + (a.transcript ? '“' + esc(a.transcript) + '”' : 'nothing clear enough to read') + '</span>' +
          '</div>' +
          '<div class="pn-syl-head">' +
            (missed.length === 0 ? 'Every syllable landed'
              : missed.length === 1 ? 'One syllable missed'
              : missed.length + ' syllables missed') +
          '</div>' +
          '<div class="pn-syls">' + cmp.map(function (c) {
            return '<span class="pn-syl' + (c.ok ? ' ok' : ' bad') + '">' + esc(c.syl) + '</span>';
          }).join('') + '</div>' +
          (missed.length
            ? '<div class="pn-fix"><span class="pn-fix-lbl">Say it like this</span>' +
              '<span class="pn-fix-line">' + sylsFromWord.map(function (sy, i) {
                var isBad = cmp[i] && !cmp[i].ok;
                return '<span class="pn-fix-syl' + (isBad ? ' bad' : '') + '">' + esc(sy) + '</span>';
              }).join('<span class="pn-fix-dot">·</span>') + '</span>' +
              '<span class="pn-fix-note">Slow down on the marked part and hold it a beat longer than feels natural.</span>' +
              '</div>'
            : '<div class="pn-fix"><span class="pn-fix-note">Nothing to correct on that attempt — keep the same pace and breath.</span></div>') +
        '</div>';
    } else {
      html +=
        '<div class="pn-card pn-empty">' +
          '<div class="pn-empty-head">No attempt recorded yet</div>' +
          '<div class="pn-empty-sub">Practice this word in Record mode and this page will show you which syllables landed, which did not, and what to change.</div>' +
          '<button class="pn-cta" onclick="window.lgpCloseNotes&&window.lgpCloseNotes();setTimeout(function(){window.pwPracticeNow&&window.pwPracticeNow()},220)">Practice ' + esc(w.word) + '</button>' +
        '</div>';
    }

    /* ── How to say it. The word's own notes, not advice invented here. ── */
    var rows = [
      ['Mouth', w.mouthPos],
      ['Where you feel it', w.resonance],
      ['The usual mistake', w.mistake],
      ['Tip', w.tip]
    ].filter(function (r) { return r[1]; });

    if (rows.length) {
      html += '<div class="pn-sec-title">How to speak it</div>' +
        '<div class="pn-card pn-how">' +
          '<div class="pn-how-word">' + esc(w.word) +
            '<span class="pn-how-ph">' + esc(w.phonetic || '') + '</span></div>' +
          rows.map(function (r) {
            return '<div class="pn-row"><span class="pn-row-lbl">' + esc(r[0]) + '</span>' +
                   '<span class="pn-row-txt">' + esc(r[1]) + '</span></div>';
          }).join('') +
        '</div>';
    }

    return html;
  }

  function mount() {
    var el = document.getElementById('lgpNotesOverlay');
    if (el) return el;
    el = document.createElement('div');
    el.id = 'lgpNotesOverlay';
    el.className = 'pn-overlay';
    el.setAttribute('role', 'dialog');
    el.setAttribute('aria-label', 'Pronunciation notes');
    el.onclick = function (e) { if (e.target === el) window.lgpCloseNotes(); };
    el.innerHTML =
      '<div class="pn-sheet">' +
        '<div class="pn-handle"></div>' +
        '<div class="pn-head">' +
          '<div class="pn-title">Pronunciation Notes</div>' +
          '<button class="pn-close" type="button" onclick="window.lgpCloseNotes&&window.lgpCloseNotes()" aria-label="Close">' +
            '<svg viewBox="0 0 24 24" fill="none"><path d="M6 6l12 12M18 6L6 18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>' +
          '</button>' +
        '</div>' +
        '<div class="pn-body" id="lgpNotesBody"></div>' +
      '</div>';
    document.body.appendChild(el);
    return el;
  }

  window.lgpOpenNotes = function () {
    var w = word();
    if (!w) return;
    var el = mount();
    var body = document.getElementById('lgpNotesBody');
    if (body) body.innerHTML = render(w);
    requestAnimationFrame(function () { el.classList.add('open'); });
    try { if (navigator.vibrate) navigator.vibrate(18); } catch (e) {}
  };
  window.lgpCloseNotes = function () {
    var el = document.getElementById('lgpNotesOverlay');
    if (el) el.classList.remove('open');
  };
})();
