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

  /* ── Style pairs (image background + waveform video). One per word, rotating.
     Add each pair as you send it; the player cycles through them by word index. ── */
  var LGP_THEMES = [
    { img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782656918/grok_image_1782656676834_rzp2cz.jpg',
      video:'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782656947/grok_video_2026-06-28-19-54-38_wrxkgr.mp4',
      accent:'#7fe9da' },
    { img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782656917/grok_image_1782656710977_nj5r6x.jpg',
      video:'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782656870/grok_video_2026-06-28-19-55-09_otgbxd.mp4',
      accent:'#9bb8ff' },
    { img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782656917/grok_image_1782656704854_cfsah3.jpg',
      video:'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782656923/grok_video_2026-06-28-19-55-02_of5fwh.mp4',
      accent:'#bd7bff' }
  ];

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
    var voice = (typeof _pwVoice !== 'undefined') ? _pwVoice : 'F';
    var loop = (typeof _pwLoop !== 'undefined') ? !!_pwLoop : false;
    var th = LGP_THEMES[Math.abs(idx) % LGP_THEMES.length];
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

    /* the practice player's own image icons */
    var ICO_PLAY  = 'https://res.cloudinary.com/ds6duqabl/image/upload/v1780340484/04610c10-5dec-11f1-9e1a-9303081e5fda_cbsa8c.png';
    var ICO_PREV  = 'https://res.cloudinary.com/ds6duqabl/image/upload/v1780340484/00f0e8d0-5dec-11f1-9e1a-9303081e5fda_xnc4lk.png';
    var ICO_NEXT  = 'https://res.cloudinary.com/ds6duqabl/image/upload/v1780340484/02b2b8b0-5dec-11f1-9e1a-9303081e5fda_qkq4dq.png';
    var ICO_SET   = 'https://res.cloudinary.com/ds6duqabl/image/upload/v1780340484/018b2fc0-5dec-11f1-9e1a-9303081e5fda_ccsoef.png';
    var playIco = playing
      ? '<svg width="22" height="24" viewBox="0 0 16 18" fill="none"><rect x="2" y="1" width="4" height="16" rx="1.5" fill="#fff"/><rect x="10" y="1" width="4" height="16" rx="1.5" fill="#fff"/></svg>'
      : '<img class="lgp-ico" src="' + ICO_PLAY + '" alt="">';

    var prevSvg = '<img class="lgp-ico" src="' + ICO_PREV + '" alt="" style="transform:scaleX(-1)">';
    var nextSvg = '<img class="lgp-ico" src="' + ICO_NEXT + '" alt="">';

    /* Library (left) + Replay (right) flank the transport */
    var libSvg = '<svg width="23" height="22" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5v14M9 5v14M14 6l5 13M14 19l-5-14"/></svg>';
    var replaySvg = '<svg width="23" height="23" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 3-6.7M3 4v4h4"/></svg>';
    var libBtn = '<button class="lgp-side" onclick="lgpToggleArc&&document.getElementById(\'lgpArc\')&&document.getElementById(\'lgpArc\').classList.remove(\'open\');openWalkmanLib&&openWalkmanLib()" aria-label="Library">' + libSvg + '<span>Library</span></button>';
    var replayBtn = '<button class="lgp-side" onclick="if(typeof _pwPhase!==\'undefined\'){_pwPhase=\'idle\';}pwPlay&&pwPlay()" aria-label="Replay">' + replaySvg + '<span>Replay</span></button>';

    /* central waveform = the pair's looping video */
    var visual = th.video
      ? '<video class="lgp-video" autoplay loop muted playsinline preload="auto" src="' + th.video + '"></video>'
      : '<div class="lgp-video-fallback"></div>';

    /* phase-aware center block — preserves the original IDs so play/record/score work */
    var center =
      '<div class="lgp-phase">' +
        '<div id="spPhaseIdlePlay" style="display:' + ((phase === 'idle' || phase === 'playing') ? 'flex' : 'none') + ';flex-direction:column;align-items:center;gap:10px;width:100%;">' +
          '<div class="lgp-status" id="spAutoStatus">' + (phase === 'playing' ? 'Listening…' : 'Tap ▸ to listen') + '</div>' +
          '<div class="lgp-controls">' +
            libBtn +
            '<div class="lgp-transport">' +
              '<button class="lgp-ctrl" id="lgpPrev" onclick="pwPrevWord&&pwPrevWord()" ' + (idx === 0 ? 'disabled' : '') + '>' + prevSvg + '</button>' +
              '<button class="lgp-play' + (playing ? ' playing' : '') + '" id="spPlayBtn" onclick="pwTogglePlay&&pwTogglePlay()">' + playIco + '</button>' +
              '<button class="lgp-ctrl" id="lgpNext" onclick="pwNextWord&&pwNextWord()" ' + (idx >= total - 1 ? 'disabled' : '') + '>' + nextSvg + '</button>' +
            '</div>' +
            replayBtn +
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

    /* curved liquid-glass ARC — slides up when you tap Settings (camera-dial style).
       Library + Replay now live in the transport row, so the arc is settings only. */
    var arc =
      '<div class="lgp-arc" id="lgpArc">' +
        '<div class="lgp-arc-back" onclick="lgpToggleArc()"></div>' +
        '<div class="lgp-arc-sheet">' +
          '<div class="lgp-arc-handle"></div>' +
          '<div class="lgp-arc-title">Settings</div>' +
          '<div class="lgp-arc-row"><span>Voice</span><div class="lgp-arc-seg">' +
            '<button class="' + (voice === 'F' ? 'on' : '') + '" onclick="pwSetVoice&&pwSetVoice(\'F\');renderPractice&&renderPractice()">Female</button>' +
            '<button class="' + (voice === 'M' ? 'on' : '') + '" onclick="pwSetVoice&&pwSetVoice(\'M\');renderPractice&&renderPractice()">Male</button>' +
          '</div></div>' +
          '<div class="lgp-arc-row" onclick="pwToggleLoop&&pwToggleLoop();renderPractice&&renderPractice()"><span>Loop</span><b>' + (loop ? 'On' : 'Off') + '</b></div>' +
          '<div class="lgp-arc-row" onclick="pwCycleRepTarget&&pwCycleRepTarget();renderPractice&&renderPractice()"><span>Reps</span><b>' + repTarget + '×</b></div>' +
          '<div class="lgp-arc-actions">' +
            '<button onclick="lgpToggleArc();openWalkmanLib&&openWalkmanLib()">' + libSvg + '<span>Library</span></button>' +
            '<button onclick="lgpToggleArc();if(typeof _pwPhase!==\'undefined\'){_pwPhase=\'idle\';}pwPlay&&pwPlay()">' + replaySvg + '<span>Replay</span></button>' +
          '</div>' +
        '</div>' +
      '</div>';

    body.innerHTML =
      '<div class="lgp' + (playing ? ' playing' : '') + '" style="--lg-bg:url(\'' + th.img + '\');--lg-accent:' + th.accent + ';">' +
        '<div class="lgp-bg"></div><div class="lgp-scrim"></div><div class="lgp-orbs"></div>' +
        '<div class="lgp-top">' +
          '<button class="lgp-back" onclick="closeSub&&closeSub(\'practice\')" aria-label="Back">' +
            '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M15 18l-6-6 6-6"/></svg>' +
          '</button>' +
          '<button class="lgp-settings" onclick="lgpToggleArc()" aria-label="Settings">' +
            '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.7"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 00.3 1.9l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.9-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.7 1.7 0 00-1.1-1.5 1.7 1.7 0 00-1.9.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.9 1.7 1.7 0 00-1.5-1H3a2 2 0 110-4h.1a1.7 1.7 0 001.5-1.1 1.7 1.7 0 00-.3-1.9l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.9.3H9a1.7 1.7 0 001-1.5V3a2 2 0 114 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.9-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00-.3 1.9V9a1.7 1.7 0 001.5 1H21a2 2 0 110 4h-.1a1.7 1.7 0 00-1.5 1z"/></svg>' +
          '</button>' +
        '</div>' +
        '<div class="lgp-brand">NowssB</div>' +
        '<div class="lgp-ritual">' + ritual + ' Ritual · ' + (idx + 1) + ' of ' + total + '</div>' +
        '<div class="lgp-visual">' + visual + '</div>' +
        '<div class="lgp-title">' + (w.word || '') + '</div>' +
        '<div class="lgp-syls">' + syl + '</div>' +
        '<div class="lgp-organ">' + (w.organ || '') + '</div>' +
        '<div class="lgp-progress"><div class="lgp-progress-fill" style="width:' + repPct + '%"></div></div>' +
        center +
        arc +
      '</div>';
  }
  window.renderLiquidPlayer = renderLiquidPlayer;
  window.lgpToggleArc = function () {
    var a = document.getElementById('lgpArc');
    if (a) a.classList.toggle('open');
  };

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
