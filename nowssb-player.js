/* ═══════════════════════════════════════════════════════════════
   NowssB — LIQUID GLASS PLAYER
   Rebuilds the practice screen into the mockup layout (NowssB header →
   central glass waveform panel → word title → progress → ‹‹ ⏸ ››), with
   6 cosmic themes rotating per word. Reuses the practice phase containers
   + IDs so listen / record / scoring all keep working.
   Subscriber-gated (free users keep the normal player).
═══════════════════════════════════════════════════════════════ */
(function () {
  var ONLY_SUBSCRIBERS = false; // flip true to gate behind a paid/trial plan

  function isSubscribed() {
    try {
      if (window.GATE && typeof window.GATE.tier === 'function') {
        var t = window.GATE.tier();
        if (t && t !== 'free' && t !== 'starter') return true;
      }
    } catch (e) {}
    var ud = window._userDataCache;
    if (ud && (ud.isPro || ud.trial || (ud.tier && /pro|trial|resonance|frequency/i.test(ud.tier)))) return true;
    return false;
  }
  function active() { return ONLY_SUBSCRIBERS ? isSubscribed() : true; }

  function renderLiquidPlayer() {
    var body = document.getElementById('practiceBody');
    if (!body) return;
    /* practice state lives as let/const globals (not on window) — read bare */
    var words = (typeof PRACTICE_WORDS !== 'undefined') ? PRACTICE_WORDS : [];
    var idx = (typeof _pwIdx !== 'undefined') ? _pwIdx : 0;
    var w = words[idx];
    if (!w) return;
    var total = words.length;
    var phase = (typeof _pwPhase !== 'undefined') ? _pwPhase : 'idle';
    var playing = (typeof _pwPlaying !== 'undefined') ? !!_pwPlaying : false;
    var repTarget = ((typeof _pwRepTarget !== 'undefined') ? _pwRepTarget : 7) || 7;
    var repCount = (typeof _pwRepCount !== 'undefined') ? _pwRepCount : 0;
    var repPct = Math.min(100, Math.round((repCount / repTarget) * 100));
    var theme = (Math.abs(idx) % 6) + 1;
    var hr = new Date().getHours();
    var timeLabel = hr < 10 ? 'Morning' : hr < 13 ? 'Midday' : hr < 17 ? 'Afternoon' : hr < 20 ? 'Evening' : 'Night';
    var ar = (typeof getActiveRoutine === 'function') ? getActiveRoutine() : null;
    var ritual = ar ? ar.name : timeLabel;

    var syl = (w.syllables || []).map(function (s, i) {
      return '<span class="lgp-syl" id="spSyl' + i + '">' + s + '</span>' +
        (i < w.syllables.length - 1 ? '<span class="lgp-syl-dot">·</span>' : '');
    }).join('');

    var recBars = '';
    for (var r = 0; r < 26; r++) recBars += '<div class="sp-rec-bar" style="height:4px"></div>';

    var playIco = playing
      ? '<svg width="20" height="22" viewBox="0 0 16 18" fill="none"><rect x="2" y="1" width="4" height="16" rx="1.5" fill="#fff"/><rect x="10" y="1" width="4" height="16" rx="1.5" fill="#fff"/></svg>'
      : '<svg width="22" height="24" viewBox="0 0 24 24" fill="#fff"><path d="M8 5v14l11-7z"/></svg>';

    var prevSvg = '<svg width="26" height="26" viewBox="0 0 24 24" fill="#fff"><path d="M6 6h2v12H6zM20 6v12L9 12z"/></svg>';
    var nextSvg = '<svg width="26" height="26" viewBox="0 0 24 24" fill="#fff"><path d="M16 6h2v12h-2zM4 6l11 6L4 18z"/></svg>';

    /* central animated liquid waveform (SVG) — the "live" half of the hybrid */
    var wave =
      '<svg class="lgp-wave-svg" viewBox="0 0 240 120" preserveAspectRatio="none">' +
        '<defs><linearGradient id="lgpGrad" x1="0" y1="0" x2="0" y2="1">' +
          '<stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="var(--lg-accent,#7fe9da)"/>' +
        '</linearGradient></defs>' +
        '<path class="lgp-wp lgp-wp1" d="M0,60 Q30,20 60,60 T120,60 T180,60 T240,60 V120 H0 Z"/>' +
        '<path class="lgp-wp lgp-wp2" d="M0,60 Q30,95 60,60 T120,60 T180,60 T240,60 V120 H0 Z"/>' +
        '<path class="lgp-wp lgp-wp3" d="M0,62 Q40,30 80,62 T160,62 T240,62"/>' +
      '</svg>';

    /* phase-aware center block — preserves the original IDs so play/record/score work */
    var center =
      '<div class="lgp-phase">' +
        '<div id="spPhaseIdlePlay" style="display:' + ((phase === 'idle' || phase === 'playing') ? 'flex' : 'none') + ';flex-direction:column;align-items:center;gap:10px;width:100%;">' +
          '<div class="lgp-status" id="spAutoStatus">' + (phase === 'playing' ? 'Listening…' : 'Tap ▸ to listen') + '</div>' +
          '<div class="lgp-controls">' +
            '<button class="lgp-ctrl" id="lgpPrev" onclick="pwPrevWord&&pwPrevWord()" ' + (idx === 0 ? 'disabled' : '') + '>' + prevSvg + '</button>' +
            '<button class="lgp-play' + (playing ? ' playing' : '') + '" id="spPlayBtn" onclick="pwTogglePlay&&pwTogglePlay()">' + playIco + '</button>' +
            '<button class="lgp-ctrl" id="lgpNext" onclick="pwNextWord&&pwNextWord()" ' + (idx >= total - 1 ? 'disabled' : '') + '>' + nextSvg + '</button>' +
          '</div>' +
          '<button class="lgp-mic" onclick="pwPracticeNow&&pwPracticeNow()">🎙 Practice this word</button>' +
        '</div>' +
        '<div id="spPhasePost" style="display:' + (phase === 'post-play' ? 'flex' : 'none') + ';flex-direction:column;align-items:center;gap:12px;width:100%;">' +
          '<div class="lgp-status">Word played · your turn</div>' +
          '<button class="lgp-cta" onclick="pwPracticeNow&&pwPracticeNow()">🎙 Practice Now</button>' +
          '<div class="lgp-controls" style="margin-top:4px;">' +
            '<button class="lgp-ctrl" onclick="pwPrevWord&&pwPrevWord()" ' + (idx === 0 ? 'disabled' : '') + '>' + prevSvg + '</button>' +
            '<button class="lgp-play" onclick="_pwPhase=\'idle\';pwPlay&&pwPlay()">' + '<svg width="22" height="24" viewBox="0 0 24 24" fill="#fff"><path d="M8 5v14l11-7z"/></svg>' + '</button>' +
            '<button class="lgp-ctrl" onclick="pwNextWord&&pwNextWord()" ' + (idx >= total - 1 ? 'disabled' : '') + '>' + nextSvg + '</button>' +
          '</div>' +
        '</div>' +
        '<div id="spPhaseRec" style="display:' + (phase === 'recording' ? 'flex' : 'none') + ';flex-direction:column;align-items:center;gap:10px;width:100%;">' +
          '<div class="lgp-status recording">● Recording</div>' +
          '<div class="sp-rec-waveform" id="spRecWaveform">' + recBars + '</div>' +
          '<div class="lgp-status" id="spRecHint" style="opacity:.8">Speak the word clearly</div>' +
        '</div>' +
        '<div id="spScoreWrap" style="display:' + ((phase === 'scoring' || phase === 'scored') ? 'flex' : 'none') + ';flex-direction:column;align-items:center;gap:4px;width:100%;">' +
          '<div class="lgp-status" id="spScoreLabel">' + (phase === 'scoring' ? 'Analyzing…' : 'Your score') + '</div>' +
          '<div id="spScoreNum" style="font-family:DM Sans,sans-serif;font-size:54px;font-weight:800;letter-spacing:-2px;color:#fff;line-height:1;text-shadow:0 0 30px var(--lg-accent);"></div>' +
          '<div id="spPersonaWrap" style="display:none;margin-top:8px;padding:12px 14px;background:rgba(255,255,255,.1);border-radius:16px;text-align:left;width:100%;-webkit-backdrop-filter:blur(12px);backdrop-filter:blur(12px);">' +
            '<div id="spPersonaName" style="font-size:9px;letter-spacing:2px;color:rgba(255,255,255,.7);text-transform:uppercase;margin-bottom:5px;"></div>' +
            '<div id="spPersonaText" style="font-size:12px;color:rgba(255,255,255,.9);line-height:1.6;"></div>' +
          '</div>' +
          '<div class="lgp-controls" style="margin-top:10px;">' +
            '<button class="lgp-ctrl" onclick="pwPrevWord&&pwPrevWord()" ' + (idx === 0 ? 'disabled' : '') + '>' + prevSvg + '</button>' +
            '<button class="lgp-play" onclick="_pwPhase=\'idle\';pwPlay&&pwPlay()"><svg width="22" height="24" viewBox="0 0 24 24" fill="#fff"><path d="M8 5v14l11-7z"/></svg></button>' +
            '<button class="lgp-ctrl" onclick="pwNextWord&&pwNextWord()" ' + (idx >= total - 1 ? 'disabled' : '') + '>' + nextSvg + '</button>' +
          '</div>' +
        '</div>' +
        '<div style="display:none;"><button id="spRecBtn"></button><div id="spRecLabel"></div><div id="spRecStatus"></div><button id="spRecPlayBtn"></button><button id="spRecTrashBtn"></button><div id="spRecControls"></div><div id="spWaveform"></div><div id="sp3BtnMain"></div><span id="sp3BtnLbl"></span><div id="sp3BtnIco"></div></div>' +
      '</div>';

    body.innerHTML =
      '<div class="lgp lg-t' + theme + (playing ? ' playing' : '') + '">' +
        '<div class="lgp-bg"></div><div class="lgp-scrim"></div><div class="lgp-orbs"></div>' +
        '<div class="lgp-top">' +
          '<button class="lgp-back" onclick="closeSub&&closeSub(\'practice\')" aria-label="Back">' +
            '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M15 18l-6-6 6-6"/></svg>' +
          '</button>' +
          '<button class="lgp-settings" onclick="pwOpenSettings&&pwOpenSettings()" aria-label="Settings">' +
            '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.7"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 00.3 1.9l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.9-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.7 1.7 0 00-1.1-1.5 1.7 1.7 0 00-1.9.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.9 1.7 1.7 0 00-1.5-1H3a2 2 0 110-4h.1a1.7 1.7 0 001.5-1.1 1.7 1.7 0 00-.3-1.9l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.9.3H9a1.7 1.7 0 001-1.5V3a2 2 0 114 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.9-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00-.3 1.9V9a1.7 1.7 0 001.5 1H21a2 2 0 110 4h-.1a1.7 1.7 0 00-1.5 1z"/></svg>' +
          '</button>' +
        '</div>' +
        '<div class="lgp-brand">NowssB</div>' +
        '<div class="lgp-ritual">' + ritual + ' Ritual · ' + (idx + 1) + ' of ' + total + '</div>' +
        '<div class="lgp-visual">' + wave + '</div>' +
        '<div class="lgp-title">' + (w.word || '') + '</div>' +
        '<div class="lgp-syls">' + syl + '</div>' +
        '<div class="lgp-organ">' + (w.organ || '') + '</div>' +
        '<div class="lgp-progress"><div class="lgp-progress-fill" style="width:' + repPct + '%"></div></div>' +
        center +
      '</div>';
  }
  window.renderLiquidPlayer = renderLiquidPlayer;

  /* override renderPractice when liquid mode is on */
  (function wrap() {
    if (typeof window.renderPractice !== 'function') { return setTimeout(wrap, 200); }
    var orig = window.renderPractice;
    window.renderPractice = function () {
      document.body.classList.toggle('nwsb-lg', active());
      if (active() && !window._sspActive) {
        try { renderLiquidPlayer(); return; } catch (e) { /* fall back to original */ }
      }
      return orig.apply(this, arguments);
    };
  })();
})();
