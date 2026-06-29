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

    /* ── Custom glass-sphere icons (background-removed PNGs). Each sphere IS the
       button — the round glass button background is dropped in CSS. ── */
    var IC = {
      play:     'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718777/e06d2880-7389-11f1-8c74-0593c060acc9_jy24tl.png',
      pause:    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718776/e0723190-7389-11f1-8c74-0593c060acc9_e0lcl6.png',
      prev:     'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718778/ad77f630-7389-11f1-8c74-0593c060acc9_pe0zco.png',
      next:     'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718778/c5576970-7389-11f1-8c74-0593c060acc9_c4epec.png',
      replay:   'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718779/file_00000000a484720aa71b5f34f8539f05_amesbb.png',
      mic:      'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718779/27cbc180-7387-11f1-ac66-23a66b2b6053_mf6jdr.png',
      library:  'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718780/3259c840-7387-11f1-ac66-23a66b2b6053_ikqafa.png',
      settings: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718779/f90f56e0-7386-11f1-ac66-23a66b2b6053_n5ahnk.png'
    };
    /* render every icon as a background-image SPAN (never an <img>) so the
       browser can't open/zoom it on tap and taps always hit the button */
    function bgi(cls, url) { return '<span class="' + cls + '" style="background-image:url(\'' + url + '\')"></span>'; }
    var playIco = bgi('lgp-img', playing ? IC.pause : IC.play);
    var prevSvg = bgi('lgp-img', IC.prev);
    var nextSvg = bgi('lgp-img', IC.next);

    /* Library (left, image icon) + Replay (right) flank the transport */
    var replaySvg = bgi('lgp-side-ico', IC.replay);
    var libSvg = bgi('lgp-side-ico', IC.library);
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
          '<div class="lgp-tube">' +
            '<div class="lgp-controls">' +
              libBtn +
              '<div class="lgp-transport">' +
                '<button class="lgp-ctrl" id="lgpPrev" onclick="pwPrevWord&&pwPrevWord()" ' + (idx === 0 ? 'disabled' : '') + '>' + prevSvg + '</button>' +
                '<button class="lgp-play' + (playing ? ' playing' : '') + '" id="spPlayBtn" onclick="pwTogglePlay&&pwTogglePlay()">' + playIco + '</button>' +
                '<button class="lgp-ctrl" id="lgpNext" onclick="pwNextWord&&pwNextWord()" ' + (idx >= total - 1 ? 'disabled' : '') + '>' + nextSvg + '</button>' +
              '</div>' +
              replayBtn +
            '</div>' +
          '</div>' +
          '<div class="lgp-practice-row">' +
            '<button class="lgp-sentence" onclick="openWalkmanLib&&openWalkmanLib();if(typeof wlSwitchTab===\'function\')setTimeout(function(){wlSwitchTab(\'build\')},90)" aria-label="Build your sentence">' +
              '<span class="lgp-sentence-orb"><span class="lgp-sentence-ico" style="background-image:url(\'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782722895/file_00000000a23c71f49581cfa65c26e6d2_bnwstr.png\')"></span></span>' +
              '<span class="lgp-sentence-lbl">Sentence</span>' +
            '</button>' +
            '<button class="lgp-practice" onclick="pwPracticeNow&&pwPracticeNow()" aria-label="Practice this word">' +
              '<span class="lgp-practice-orb"><span class="lgp-practice-ring"></span><span class="lgp-practice-ring"></span><span class="lgp-practice-ico" style="background-image:url(\'' + IC.mic + '\')"></span></span>' +
              '<span class="lgp-practice-lbl">Practice</span>' +
            '</button>' +
            '<button class="lgp-store" onclick="openSub&&openSub(\'nowssb-store\')" aria-label="Store">' +
              '<span class="lgp-store-orb"><span class="lgp-store-ico" style="background-image:url(\'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782729222/file_00000000b86c7207988c04376fd0529c_dunq9l.png\')"></span></span>' +
              '<span class="lgp-store-lbl">Store</span>' +
            '</button>' +
          '</div>' +
        '</div>' +
        '<div id="spPhasePost" style="display:' + (phase === 'post-play' ? 'flex' : 'none') + ';flex-direction:column;align-items:center;gap:12px;width:100%;">' +
          '<div class="lgp-status">Word played · your turn</div>' +
          '<button class="lgp-cta" onclick="pwPracticeNow&&pwPracticeNow()"><span class="lgp-mic-ico" style="background-image:url(\'' + IC.mic + '\')"></span>Practice Now</button>' +
          '<div class="lgp-controls" style="margin-top:4px;">' +
            '<button class="lgp-ctrl" onclick="pwPrevWord&&pwPrevWord()" ' + (idx === 0 ? 'disabled' : '') + '>' + prevSvg + '</button>' +
            '<button class="lgp-play" onclick="_pwPhase=\'idle\';pwPlay&&pwPlay()"><span class="lgp-img" style="background-image:url(\'' + IC.play + '\')"></span></button>' +
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
            '<button class="lgp-play" onclick="_pwPhase=\'idle\';pwPlay&&pwPlay()"><span class="lgp-img" style="background-image:url(\'' + IC.play + '\')"></span></button>' +
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
          '<button class="lgp-back lgp-imgbtn" onclick="closeSub&&closeSub(\'practice\')" aria-label="Back">' +
            '<span class="lgp-bgico" style="background-image:url(\'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782728734/file_00000000ae6071fa982c6eec401328c6_uvgfjs.png\')"></span>' +
          '</button>' +
          '<div class="lgp-brand">NowssB</div>' +
          '<button class="lgp-settings lgp-imgbtn" type="button" aria-label="Settings">' +
            '<span class="lgp-bgico" style="background-image:url(\'' + IC.settings + '\')"></span>' +
          '</button>' +
        '</div>' +
        '<div class="lgp-tagline">' + ['The','new','fashion','trend','of','meditation'].map(function (wd, i) { return '<span style="animation-delay:' + (0.25 + i * 0.18).toFixed(2) + 's">' + wd + '</span>'; }).join(' ') + '</div>' +
        '<div class="lgp-ritual">' + ritual + ' Ritual · ' + (idx + 1) + ' of ' + total + '</div>' +
        '<div class="lgp-visual">' + visual +
          '<div class="lgp-visual-overlay">' +
            '<div class="lgp-title">' + (w.word || '') + '</div>' +
            '<div class="lgp-syls">' + syl + '</div>' +
            '<div class="lgp-organ">' + (w.organ || '') + '</div>' +
          '</div>' +
        '</div>' +
        '<div class="lgp-ticker"><span>Listen</span><span>Learn</span><span>Practice</span><span>Heal</span></div>' +
        '<div class="lgp-progress"><div class="lgp-progress-fill" style="width:' + repPct + '%"></div></div>' +
        center +
      '</div>';

    /* The settings arc must NOT live inside .sub-screen — that screen creates its
       own stacking context (z-index:600 + transform/contain), which traps and
       clips the arc no matter how high its z-index. Render it as a direct child
       of <body> so it's a real top-level overlay above everything. */
    var existingArc = document.getElementById('lgpArc');
    /* If the arc is already OPEN, leave it alone — re-renders during playback
       would otherwise yank it shut / flicker. Only (re)build when it's closed. */
    if (!(existingArc && existingArc.classList.contains('open'))) {
      if (existingArc) existingArc.remove();
      var tmp = document.createElement('div');
      tmp.innerHTML = arc;
      document.body.appendChild(tmp.firstChild);
    }
  }
  window.renderLiquidPlayer = renderLiquidPlayer;
  window.lgpToggleArc = function (forceOpen) {
    var a = document.getElementById('lgpArc');
    if (!a) return;
    var willOpen = (forceOpen === true) ? true : !a.classList.contains('open');
    a.classList.toggle('open', willOpen);
    /* Inline styles so the arc opens even if a stale cached player CSS is still
       in effect (immune to the old narrow-column bug). */
    a.style.position = 'fixed';
    a.style.left = a.style.top = a.style.right = a.style.bottom = '0';
    a.style.zIndex = '99999';
    a.style.pointerEvents = willOpen ? 'auto' : 'none';
    var back = a.querySelector('.lgp-arc-back');
    if (back) {
      back.style.position = 'absolute';
      back.style.left = back.style.top = back.style.right = back.style.bottom = '0';
      back.style.background = 'rgba(6,10,25,.5)';
      back.style.transition = 'opacity .3s';
      back.style.opacity = willOpen ? '1' : '0';
    }
    var sheet = a.querySelector('.lgp-arc-sheet');
    if (sheet) {
      sheet.style.position = 'absolute';
      sheet.style.left = sheet.style.right = sheet.style.bottom = '0';
      sheet.style.transition = 'transform .38s cubic-bezier(.16,1,.3,1)';
      sheet.style.transform = willOpen ? 'translateY(0)' : 'translateY(105%)';
    }
  };

  /* Bulletproof, capture-phase delegated handler for the gear — fires even if the
     inline onclick is ever stripped/blocked. Bound once on document. */
  if (!window._lgpSettingsBound) {
    window._lgpSettingsBound = true;
    document.addEventListener('click', function (e) {
      var t = e.target;
      var hit = t && (t.closest ? t.closest('.lgp-settings') : null);
      if (hit) { e.preventDefault(); e.stopPropagation(); window.lgpToggleArc(); }
    }, true);
  }

  /* override renderPractice when liquid mode is on */
  (function wrap() {
    if (typeof window.renderPractice !== 'function') { return setTimeout(wrap, 200); }
    var orig = window.renderPractice;
    window.renderPractice = function () {
      document.body.classList.toggle('nwsb-lg', active());
      if (active() && !window._sspActive) {
        try { renderLiquidPlayer(); return; } catch (e) { /* fall back to original */ }
      }
      /* not using the liquid player → make sure no stray body-level arc lingers */
      var stray = document.getElementById('lgpArc');
      if (stray) stray.remove();
      return orig.apply(this, arguments);
    };
  })();

  /* Close (and detach) the arc whenever the practice screen is closed */
  (function patchCloseSub() {
    if (typeof window.closeSub !== 'function') { return setTimeout(patchCloseSub, 200); }
    var orig = window.closeSub;
    window.closeSub = function (id) {
      if (id === 'practice') { var a = document.getElementById('lgpArc'); if (a) a.remove(); }
      return orig.apply(this, arguments);
    };
  })();
})();
