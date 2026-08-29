/* NowssB pronunciation layer — shared by Cloudflare Pages and the Capacitor WebView. */
(function () {
  'use strict';

  var LEVEL_META = [
    ['Whisper', 0.55], ['Slow', 0.65], ['Gentle', 0.75], ['Steady', 0.85], ['Clear', 0.95],
    ['Natural', 1], ['Confident', 1.05], ['Fluent', 1.1], ['Sharp', 1.15], ['Mastery', 1.2]
  ];
  var audio = new Audio();
  audio.preload = 'auto';
  var recorder = null;
  var chunks = [];
  var recordStartedAt = 0;
  var timer = null;

  function safeGet(key, fallback) {
    try { var v = localStorage.getItem(key); return v == null ? fallback : v; } catch (_) { return fallback; }
  }
  function safeSet(key, value) { try { localStorage.setItem(key, value); } catch (_) {} }
  function word() {
    var list = (typeof PRACTICE_WORDS !== 'undefined') ? PRACTICE_WORDS : [];
    var idx = (typeof _pwIdx !== 'undefined') ? _pwIdx : 0;
    return list[idx] || {};
  }
  function wordId() { return String(word().id || word().word || '').toLowerCase().replace(/[^a-z0-9_-]/g, '-'); }
  function level() { var n = parseInt(safeGet('nowssb_level_' + wordId(), '1'), 10); return n >= 1 && n <= 10 ? n : 1; }
  function stats() {
    return { streak: parseInt(safeGet('nowssb_streak', '0'), 10) || 0, sessions: parseInt(safeGet('nowssb_sessions', '0'), 10) || 0, seconds: parseInt(safeGet('nowssb_seconds', '0'), 10) || 0, lastDate: safeGet('nowssb_last_date', '') };
  }
  function formatTime(seconds) { var h = Math.floor(seconds / 3600), m = Math.floor((seconds % 3600) / 60); return h ? h + 'h ' + m + 'm' : m + 'm'; }
  function incrementStats(seconds) {
    var s = stats(), today = new Date().toDateString(), yesterday = new Date(Date.now() - 86400000).toDateString();
    s.sessions += 1; s.seconds += Math.max(1, Math.round(seconds || 0));
    if (s.lastDate !== today) { s.streak = s.lastDate === yesterday ? s.streak + 1 : 1; s.lastDate = today; }
    safeSet('nowssb_streak', s.streak); safeSet('nowssb_sessions', s.sessions); safeSet('nowssb_seconds', s.seconds); safeSet('nowssb_last_date', s.lastDate);
    renderStats();
  }
  function renderStats() {
    var s = stats();
    [['nwsbStatStreak', s.streak], ['nwsbStatSessions', s.sessions], ['nwsbStatTime', formatTime(s.seconds)]].forEach(function (pair) { var el = document.getElementById(pair[0]); if (el) el.textContent = pair[1]; });
  }
  function bestKey() { return 'nowssb_best_score_' + wordId() + '_' + level(); }
  function bestScore() { return parseFloat(safeGet(bestKey(), '0')) || 0; }
  function saveBest(score) { if (score > bestScore()) { safeSet(bestKey(), String(score)); return true; } return false; }
  function referenceUrl() { return '/api/audio?word=' + encodeURIComponent(wordId()) + '&level=' + level(); }

  function statsMarkup() {
    return '<div class="nwsb-stats-card" id="nwsbStatsCard" aria-label="Practice statistics">' +
      '<div class="nwsb-stat"><span class="nwsb-stat-icon">' + flameSvg() + '</span><strong id="nwsbStatStreak">0</strong><small>STREAK DAYS</small></div>' +
      '<span class="nwsb-stat-divider"></span>' +
      '<div class="nwsb-stat"><span class="nwsb-stat-icon">' + barsSvg() + '</span><strong id="nwsbStatSessions">0</strong><small>SESSIONS</small></div>' +
      '<span class="nwsb-stat-divider"></span>' +
      '<div class="nwsb-stat"><span class="nwsb-stat-icon">' + clockSvg() + '</span><strong id="nwsbStatTime">0m</strong><small>TIME PRACTICED</small></div>' +
    '</div>';
  }
  function flameSvg() { return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 21c4 0 7-2.7 7-6.5 0-3.2-2.1-5.3-4.5-7.2.2 2-1 3.2-2.1 3.7.3-3.8-1.8-6.9-4.4-8.7.1 4.3-4 6.5-4 11.2C4 18.2 7.2 21 12 21Z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>'; }
  function barsSvg() { return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 19V12M10 19V7M15 19V10M20 19V4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>'; }
  function clockSvg() { return '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="8.5" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M12 7v5l3 2" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>'; }

  function inject() {
    var root = document.querySelector('#practiceBody .lgp');
    if (!root || root.getAttribute('data-nwsb-enhanced') === '1') return;
    root.setAttribute('data-nwsb-enhanced', '1');
    var visual = root.querySelector('.lgp-visual');
    if (visual) visual.insertAdjacentHTML('beforebegin', statsMarkup());
    var top = root.querySelector('.lgp-visual-top');
    if (top) {
      var pill = document.createElement('button');
      pill.className = 'nwsb-level-pill'; pill.type = 'button'; pill.id = 'nwsbLevelPill'; pill.textContent = 'LVL ' + level() + ' ›';
      pill.addEventListener('click', openLevels); top.appendChild(pill);
    }
    var phase = root.querySelector('.lgp-phase');
    if (phase) {
      var mic = document.createElement('button'); mic.className = 'nwsb-record-cta'; mic.type = 'button'; mic.id = 'nwsbRecordBtn'; mic.innerHTML = '<span class="nwsb-mic-icon">' + micSvg() + '</span><span>Record your pronunciation</span>';
      mic.addEventListener('click', toggleRecording); phase.appendChild(mic);
    }
    bindReferencePlay(root);
    renderStats();
  }
  function micSvg() { return '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="9" y="3" width="6" height="11" rx="3" fill="none" stroke="currentColor" stroke-width="1.7"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21M8.5 21h7" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>'; }
  function bindReferencePlay(root) {
    var btn = root.querySelector('#spPlayBtn');
    if (!btn || btn.getAttribute('data-nwsb-audio') === '1') return;
    btn.setAttribute('data-nwsb-audio', '1');
    btn.addEventListener('click', function (event) {
      event.stopImmediatePropagation(); event.preventDefault();
      var expected = referenceUrl();
      if (!audio.src || audio.src.indexOf('/api/audio?word=' + encodeURIComponent(wordId()) + '&level=' + level()) < 0) audio.src = expected;
      audio.playbackRate = LEVEL_META[level() - 1][1];
      if (audio.paused) audio.play().catch(function () { toast('Reference audio is not available for this level yet.'); }); else audio.pause();
    }, true);
  }
  function openLevels() {
    var old = document.getElementById('nwsbLevelSheet'); if (old) old.remove();
    var sheet = document.createElement('div'); sheet.id = 'nwsbLevelSheet'; sheet.className = 'nwsb-overlay';
    var html = '<div class="nwsb-sheet"><button class="nwsb-sheet-close" aria-label="Close">×</button><div class="nwsb-sheet-kicker">REFERENCE PACE</div><h2>Choose your level</h2><div class="nwsb-level-grid">';
    LEVEL_META.forEach(function (meta, i) { var n = i + 1, done = bestForAny(n) >= 80; html += '<button class="nwsb-level-option' + (n === level() ? ' active' : '') + '" data-level="' + n + '"><b>' + n + '</b><span>' + meta[0] + '</span>' + (done ? '<em>✓</em>' : '') + '</button>'; });
    sheet.innerHTML = html + '</div></div>'; document.body.appendChild(sheet);
    sheet.querySelector('.nwsb-sheet-close').addEventListener('click', function () { sheet.remove(); });
    sheet.addEventListener('click', function (e) { var b = e.target.closest('[data-level]'); if (!b) return; var n = Number(b.getAttribute('data-level')); safeSet('nowssb_level_' + wordId(), String(n)); var p = document.getElementById('nwsbLevelPill'); if (p) p.textContent = 'LVL ' + n + ' ›'; audio.pause(); audio.src = referenceUrl(); sheet.remove(); toast('Level ' + n + ' — ' + LEVEL_META[n - 1][0] + '. This word will now play at this pace.'); });
  }
  function bestForAny(n) { return parseFloat(safeGet('nowssb_best_score_' + wordId() + '_' + n, '0')) || 0; }
  function toggleRecording() { if (recorder && recorder.state === 'recording') stopRecording(); else startRecording(); }
  function startRecording() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia || !window.MediaRecorder) { toast('Microphone recording is not supported in this browser.'); return; }
    navigator.mediaDevices.getUserMedia({ audio: true }).then(function (stream) {
      chunks = []; recordStartedAt = Date.now(); recorder = new MediaRecorder(stream); recorder.ondataavailable = function (e) { if (e.data.size) chunks.push(e.data); }; recorder.onstop = function () { stream.getTracks().forEach(function (track) { track.stop(); }); submitRecording(); }; recorder.start();
      var b = document.getElementById('nwsbRecordBtn'); if (b) { b.classList.add('recording'); b.querySelector('span:last-child').textContent = 'Stop recording'; }
    }).catch(function () { toast('Microphone access is needed to practice your pronunciation.'); });
  }
  function stopRecording() { if (recorder && recorder.state === 'recording') recorder.stop(); var b = document.getElementById('nwsbRecordBtn'); if (b) { b.classList.remove('recording'); b.querySelector('span:last-child').textContent = 'Analyzing…'; } }
  function submitRecording() {
    var blob = new Blob(chunks, { type: 'audio/webm' }), form = new FormData(); form.append('word', word().title || word().word || ''); form.append('audio', blob, 'attempt.webm'); form.append('dialect', safeGet('nowssb_dialect', 'en-us'));
    fetch('/api/score', { method: 'POST', body: form }).then(function (r) { return r.json(); }).then(function (result) { if (result.error || result.overallScore == null) throw new Error(result.error || 'No score'); incrementStats((Date.now() - recordStartedAt) / 1000); var fresh = saveBest(Number(result.overallScore)); showScore(result, fresh); }).catch(function () { toast('Could not score that recording. Please try again.'); resetRecordButton(); });
  }
  function showScore(result, fresh) {
    var old = document.getElementById('nwsbScoreOverlay'); if (old) old.remove(); var score = Math.round(Number(result.overallScore)); var weak = (result.phonemes || []).filter(function (p) { return p.weak; }).map(function (p) { return p.sound; }); var feedback = score >= 85 ? 'Excellent — ' + score + '% accuracy. That is a clean pronunciation.' : score >= 60 ? (weak.length ? 'Good attempt — ' + score + '%. Focus on the "' + weak.join('", "') + '" sound.' : 'Good attempt — ' + score + '%. Almost there.') : (weak.length ? 'That needs work — ' + score + '%. Focus on the "' + weak.join('", "') + '" sound and match the reference rhythm.' : 'That needs work — ' + score + '%. Listen again and try once more.');
    var o = document.createElement('div'); o.id = 'nwsbScoreOverlay'; o.className = 'nwsb-overlay'; o.innerHTML = '<div class="nwsb-score-modal"><button class="nwsb-sheet-close" aria-label="Close">×</button><div class="nwsb-score-ring"><strong>' + score + '</strong><span>/100</span></div>' + (fresh ? '<div class="nwsb-best-badge">NEW BEST</div>' : '') + '<p>' + feedback + '</p><div class="nwsb-score-actions"><button data-again>Try Again</button><button data-reference>Play Reference</button></div></div>'; document.body.appendChild(o);
    o.querySelector('.nwsb-sheet-close').addEventListener('click', function () { o.remove(); resetRecordButton(); }); o.querySelector('[data-again]').addEventListener('click', function () { o.remove(); resetRecordButton(); }); o.querySelector('[data-reference]').addEventListener('click', function () { o.remove(); audio.src = referenceUrl(); audio.playbackRate = LEVEL_META[level() - 1][1]; audio.play().catch(function () {}); resetRecordButton(); });
  }
  function resetRecordButton() { var b = document.getElementById('nwsbRecordBtn'); if (b) { b.classList.remove('recording'); b.querySelector('span:last-child').textContent = 'Record your pronunciation'; } }
  function toast(text) { var t = document.getElementById('nwsbToast'); if (!t) { t = document.createElement('div'); t.id = 'nwsbToast'; t.className = 'nwsb-toast'; document.body.appendChild(t); } t.textContent = text; t.classList.add('show'); clearTimeout(timer); timer = setTimeout(function () { t.classList.remove('show'); }, 3200); }

  window.nwsbPronunciation = { loadReference: function () { audio.src = referenceUrl(); return audio; }, stats: stats, incrementStats: incrementStats };
  var observer = new MutationObserver(inject);
  function boot() { var body = document.getElementById('practiceBody'); if (body) { observer.observe(body, { childList: true, subtree: true }); inject(); } else setTimeout(boot, 250); }
  boot();
})();
