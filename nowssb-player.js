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

  /* ═══════════════════════════════════════════════════════════════
     ORGAN VISUALIZATION VIDEOS (1:1) — shown in the INFO panel (NOT the
     player). Mapped by ORGAN/CATEGORY, so every word in that category
     automatically shows its organ video. Drop each Cloudinary URL in as
     you send it (lungs first). Leave '' to keep the "coming soon"
     placeholder for organs not wired yet. ═══════════════════════════ */
  var ORGAN_VIDEOS = {
    lungs:  'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782991520/grok_video_2026-07-02-16-52-38_pehfcr.mp4',   // ← lungs / breath / respiratory
    heart:  'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782991522/grok_video_2026-07-02-16-51-54_zpffyf.mp4',   // ← heart / cardiac / circulation
    kidney: 'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782991521/grok_video_2026-07-02-16-52-19_mlfgei.mp4',   // ← kidney / renal / bladder
    liver:  'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782991522/grok_video_2026-07-02-16-51-43_gilelq.mp4'    // ← liver / hepatic / detox
  };
  /* Cloudinary on-the-fly compression — the raw grok mp4s are huge and lag /
     take forever. Inject q_auto,f_auto (+ a width cap) so Cloudinary serves a
     small, fast, hardware-friendly clip instead of the multi-MB source. */
  function cldVid(url, w) {
    if (!url || url.indexOf('/video/upload/') < 0) return url;
    if (/\/video\/upload\/(q_auto|f_auto|w_|vc_|ac_)/.test(url)) return url; // already transformed
    /* H.264 = hardware-decoded on every phone (VP9/AV1 stutter on many).
       q_auto (normal, NOT eco — eco looked garbage and didn't help the lag,
       which proved size wasn't the bottleneck). Strip audio (muted anyway).
       No fps cap — capping fps made motion judder, which read as "lag". */
    var t = 'vc_h264,q_auto,ac_none' + (w ? ',w_' + w : '');
    return url.replace('/video/upload/', '/video/upload/' + t + '/');
  }

  /* Match a word's organ/category/benefit text to one of the ORGAN_VIDEOS keys.
     Robust to wording like "Lungs · Joints", "Lung & Breath", "Immune", etc. */
  function organVideoFor(w) {
    if (!w) return '';
    if (w.organVideo) return w.organVideo;               // explicit per-word override still wins
    var hay = ((w.organ || '') + ' ' + ((w.categories || []).join(' ')) + ' ' + (w.benefit || '')).toLowerCase();
    if (/\blung|breath|respirat|pulmon/.test(hay))         return ORGAN_VIDEOS.lungs  || '';
    if (/\bheart|cardiac|cardio|circulat/.test(hay))       return ORGAN_VIDEOS.heart  || '';
    if (/\bkidney|renal|bladder|urinary/.test(hay))        return ORGAN_VIDEOS.kidney || '';
    if (/\bliver|hepat|detox|gall/.test(hay))              return ORGAN_VIDEOS.liver  || '';
    return '';
  }

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
      accent:'#bd7bff' },
    { img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782657140/grok_image_1782656684101_o9vc93.jpg',
      video:'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782656932/grok_video_2026-06-28-19-54-43_it2bur.mp4',
      accent:'#a6dcff' },
    { img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782795978/grok_image_1782795582310_llvpix.jpg',
      video:'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782795956/grok_video_2026-06-30-10-29-43_hzxyun.mp4',
      accent:'#b9a6ff' },
    { img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782796726/grok_image_1782796537731_vzyhwn.jpg',
      video:'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782796761/grok_video_2026-06-30-10-45-45_dg2ohg.mp4',
      accent:'#a6c8ff' },
    { img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782796725/grok_image_1782796641824_izkh09.jpg',
      video:'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782796770/grok_video_2026-06-30-10-47-20_rljghs.mp4',
      accent:'#b9a6ff' },
    { img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782796726/grok_image_1782796519587_thrrws.jpg',
      video:'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782796770/grok_video_2026-06-30-10-45-34_pg2y2j.mp4',
      accent:'#e8d5a3' },
    { img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782796983/grok_image_1782796924745_nmksmi.jpg',
      video:'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782797027/grok_video_2026-06-30-10-52-07_gvffol.mp4',
      accent:'#f0d9a8' },
    { img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782796983/grok_image_1782796933792_qwzfgx.jpg',
      video:'https://res.cloudinary.com/dc4nsi3xs/video/upload/v1782796996/grok_video_2026-06-30-10-52-20_zk87yh.mp4',
      accent:'#8fe6ff' }
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
    /* ONE theme (= one video) for the whole session, chosen when the player
       opened — so navigating words never reloads the video (that reload was
       the transition stutter). Falls back to per-word if not set. */
    var _thIdx = (typeof window._lgpSessionThemeIdx === 'number') ? window._lgpSessionThemeIdx : Math.abs(idx);
    var th = LGP_THEMES[_thIdx % LGP_THEMES.length];
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
      settings: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718779/f90f56e0-7386-11f1-ac66-23a66b2b6053_n5ahnk.png',
      info:     'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782986898/file_000000002038722fac63c79466d73f0f_jnhjvg.png'
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

    /* central waveform = the pair's looping video (compressed via Cloudinary).
       We REUSE the existing <video> element across re-renders (detach before
       innerHTML, re-insert after) so it never reloads/seeks — recreating it on
       every phase/rep change was the real cause of the constant stutter. */
    var _newVidSrc = th.video ? cldVid(th.video, 720) : '';
    var _keepVid = null;
    (function () {
      var ex = document.getElementById('practiceBody');
      var cur = ex ? ex.querySelector('.lgp-video') : null;
      if (cur && cur.getAttribute('src') === _newVidSrc) {
        _keepVid = cur;
        if (cur.parentNode) cur.parentNode.removeChild(cur); // survive the innerHTML wipe
      }
    })();
    var visual = th.video
      ? (_keepVid ? '<span class="lgp-video-slot"></span>'
                  : '<video class="lgp-video" autoplay loop muted playsinline preload="auto" src="' + _newVidSrc + '"></video>')
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
            '<button class="lgp-store" onclick="lgpOpenStore&&lgpOpenStore()" aria-label="Store">' +
              '<span class="lgp-store-orb"><span class="lgp-store-ico" style="background-image:url(\'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782729222/file_00000000b86c7207988c04376fd0529c_dunq9l.png\')"></span></span>' +
              '<span class="lgp-store-lbl">Store</span>' +
            '</button>' +
          '</div>' +
        '</div>' +
        '<div id="spPhasePost" style="display:' + (phase === 'post-play' ? 'flex' : 'none') + ';flex-direction:column;align-items:center;gap:12px;width:100%;">' +
          '<div class="lgp-status">Word played · your turn</div>' +
          '<div class="lgp-cta-row">' +
            '<button class="lgp-replay-orb" onclick="_pwPhase=\'idle\';pwPlay&&pwPlay()" aria-label="Replay"><span class="lgp-bgico" style="background-image:url(\'' + IC.replay + '\')"></span></button>' +
            '<button class="lgp-cta" onclick="pwPracticeNow&&pwPracticeNow()"><span class="lgp-mic-ico" style="background-image:url(\'' + IC.mic + '\')"></span><span class="lgp-cta-lbl">Practice Now</span></button>' +
          '</div>' +
          '<div class="lgp-tube" style="margin-top:4px;">' +
            '<div class="lgp-controls">' +
              '<div class="lgp-transport">' +
                '<button class="lgp-ctrl" onclick="pwPrevWord&&pwPrevWord()" ' + (idx === 0 ? 'disabled' : '') + '>' + prevSvg + '</button>' +
                '<button class="lgp-play" onclick="_pwPhase=\'idle\';pwPlay&&pwPlay()"><span class="lgp-img" style="background-image:url(\'' + IC.play + '\')"></span></button>' +
                '<button class="lgp-ctrl" onclick="pwNextWord&&pwNextWord()" ' + (idx >= total - 1 ? 'disabled' : '') + '>' + nextSvg + '</button>' +
              '</div>' +
            '</div>' +
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

    /* RADIAL liquid-glass settings menu — opens centred, blurs everything behind,
       settings icon in the middle with the options in a glass circle around it. */
    var wInfo =
      '<div class="lgp-arc-info">' +
        '<div class="lgp-arc-info-word">' + (w.word || '') + (w.phonetic ? ' <span>' + w.phonetic + '</span>' : '') + '</div>' +
        (w.meaning ? '<div class="lgp-arc-info-row"><span class="k">Meaning</span><span class="v">' + w.meaning + '</span></div>' : '') +
        (w.benefit ? '<div class="lgp-arc-info-row"><span class="k">Heals</span><span class="v">' + w.benefit + '</span></div>' : '') +
        ((w.categories && w.categories.length) ? '<div class="lgp-arc-info-row"><span class="k">Category</span><span class="v">' + w.categories.join(' · ') + '</span></div>' : (w.organ ? '<div class="lgp-arc-info-row"><span class="k">Category</span><span class="v">' + w.organ + '</span></div>' : '')) +
      '</div>';
    var arc =
      '<div class="lgp-arc" id="lgpArc" style="--lg-accent:' + th.accent + '">' +
        '<div class="lgp-arc-back" onclick="lgpToggleArc()"></div>' +
        '<button class="lgp-arc-close" onclick="lgpToggleArc()" aria-label="Back"><span class="lgp-arc-close-ico" style="background-image:url(\'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782728734/file_00000000ae6071fa982c6eec401328c6_uvgfjs.png\')"></span></button>' +
        '<div class="lgp-arc-radial">' +
          '<div class="lgp-arc-ring"></div>' +
          '<button class="lgp-arc-opt o1" onclick="pwSetVoice&&pwSetVoice(\'' + (voice === 'F' ? 'M' : 'F') + '\');renderPractice&&renderPractice()"><span class="lbl">Voice</span><span class="val">' + (voice === 'F' ? 'Female' : 'Male') + '</span></button>' +
          '<button class="lgp-arc-opt o2" onclick="pwToggleLoop&&pwToggleLoop();renderPractice&&renderPractice()"><span class="lbl">Loop</span><span class="val">' + (loop ? 'On' : 'Off') + '</span></button>' +
          '<button class="lgp-arc-opt o3" onclick="pwCycleRepTarget&&pwCycleRepTarget();renderPractice&&renderPractice()"><span class="lbl">Reps</span><span class="val">' + repTarget + '×</span></button>' +
          '<button class="lgp-arc-opt o4" onclick="lgpToggleArc();openWalkmanLib&&openWalkmanLib()"><span class="ico" style="background-image:url(\'' + IC.library + '\')"></span><span class="lbl">Library</span></button>' +
          '<button class="lgp-arc-opt o5" onclick="lgpToggleArc();if(typeof _pwPhase!==\'undefined\'){_pwPhase=\'idle\';}pwPlay&&pwPlay()"><span class="ico" style="background-image:url(\'' + IC.replay + '\')"></span><span class="lbl">Replay</span></button>' +
          '<div class="lgp-arc-center"><span class="lgp-arc-center-ico" style="background-image:url(\'' + IC.settings + '\')"></span><span class="lgp-arc-center-lbl">Settings</span></div>' +
        '</div>' +
        wInfo +
      '</div>';

    /* ── INFO PANEL — full-screen liquid-glass overlay opened from the ⓘ icon
       on the video. Shows an organ-specific video (wired later per word via
       w.organVideo — falls back to a placeholder for now), then what's
       happening in the body, the word's meaning, and the practitioner's
       results for this word. Icons are plain inline SVG for now — real
       image icons come later, same as the rest of the player. ── */
    /* NOTE: no autoplay + preload="none" — the info video must NOT load or play
       while the panel is closed (it was loading hidden on every render and
       fighting the main player video for bandwidth). It's started on open by
       lgpToggleInfo, paused/reset on close. Also compressed via Cloudinary. */
    var _organVid = organVideoFor(w);
    var infoVideo = _organVid
      ? '<video class="lgp-info-video" loop muted playsinline preload="none" src="' + cldVid(_organVid, 640) + '"></video>'
      : '<div class="lgp-info-video-placeholder">' +
          '<span class="lgp-info-video-ico"><svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M10 8.5v7l6-3.5-6-3.5z" fill="#fff" stroke="none"/></svg></span>' +
          '<span class="lgp-info-video-lbl">Organ visualization coming soon</span>' +
        '</div>';

    var bodyRows = '' +
      (w.organ    ? '<div class="lgp-info-row"><span class="k">Target Organ</span><span class="v">' + w.organ + '</span></div>' : '') +
      (w.benefit  ? '<div class="lgp-info-row"><span class="k">Effect</span><span class="v">' + w.benefit + '</span></div>' : '') +
      (w.resonance? '<div class="lgp-info-row"><span class="k">Resonance Point</span><span class="v">' + w.resonance + '</span></div>' : '') +
      (w.mouthPos ? '<div class="lgp-info-row"><span class="k">Mouth Position</span><span class="v">' + w.mouthPos + '</span></div>' : '');

    var meaningRows = '' +
      (w.meaning ? '<div class="lgp-info-row"><span class="k">Meaning</span><span class="v">' + w.meaning + '</span></div>' : '') +
      (w.origin  ? '<div class="lgp-info-row"><span class="k">Origin</span><span class="v">' + w.origin + '</span></div>' : '');

    /* best-effort real numbers where the data already exists in this session;
       everything else shows a clean placeholder until scoring/history is wired */
    var infoRepPct = repPct;

    var infoPanel =
      '<div class="lgp-info-panel" id="lgpInfoPanel">' +
        '<div class="lgp-info-back" onclick="lgpToggleInfo()"></div>' +
        '<div class="lgp-info-sheet">' +
          '<div class="lgp-info-sheet-top">' +
            '<button class="lgp-info-close lgp-imgbtn" onclick="lgpToggleInfo()" aria-label="Back">' +
              '<span class="lgp-bgico" style="background-image:url(\'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782728734/file_00000000ae6071fa982c6eec401328c6_uvgfjs.png\')"></span>' +
            '</button>' +
            '<div class="lgp-info-sheet-title">' + (w.word || '') + '</div>' +
          '</div>' +
          '<div class="lgp-info-video-wrap">' + infoVideo + '</div>' +
          (bodyRows ? '<div class="lgp-info-sec"><div class="lgp-info-sec-h">What\'s Happening</div><div class="lgp-info-card">' + bodyRows + '</div></div>' : '') +
          (meaningRows ? '<div class="lgp-info-sec"><div class="lgp-info-sec-h">Meaning</div><div class="lgp-info-card">' + meaningRows + '</div></div>' : '') +
          '<div class="lgp-info-sec">' +
            '<div class="lgp-info-sec-h">Your Results</div>' +
            '<div class="lgp-info-results">' +
              '<div class="lgp-info-result-tile"><div class="lgp-info-result-num">' + repCount + '<span>/' + repTarget + '</span></div><div class="lgp-info-result-lbl">Reps This Session</div></div>' +
              '<div class="lgp-info-result-tile"><div class="lgp-info-result-num">' + infoRepPct + '<span>%</span></div><div class="lgp-info-result-lbl">Session Progress</div></div>' +
              '<div class="lgp-info-result-tile"><div class="lgp-info-result-num">—</div><div class="lgp-info-result-lbl">Pronunciation Score</div></div>' +
            '</div>' +
            '<div class="lgp-info-improve">Practice this word in Record mode to build your score history and track improvement over time.</div>' +
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
          '<div class="lgp-info-cluster" id="lgpInfoCluster">' +
            '<div class="lgp-info-pill"><span class="lgp-info-pill-txt" id="lgpInfoPillTxt">Learn more</span></div>' +
            '<button class="lgp-info-btn" onclick="window.lgpToggleInfo&&window.lgpToggleInfo()" aria-label="Word info">' +
              '<span class="lgp-bgico" style="background-image:url(\'' + IC.info + '\')"></span>' +
            '</button>' +
          '</div>' +
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

    /* Re-insert the preserved video element (kept playing, no reload/seek). */
    if (_keepVid) {
      var _slot = body.querySelector('.lgp-video-slot');
      if (_slot && _slot.parentNode) _slot.parentNode.replaceChild(_keepVid, _slot);
      else { var _vw = body.querySelector('.lgp-visual'); if (_vw) _vw.insertBefore(_keepVid, _vw.firstChild); }
    }

    /* Keep the background video playing. Bind the resume listeners ONCE per
       element (not every render — that leaked handlers and caused jank). */
    (function () {
      var v = body.querySelector('.lgp-video');
      if (!v) return;
      v.muted = true; v.setAttribute('muted', ''); v.playsInline = true;
      function tryPlay() { try { var p = v.play(); if (p && p.catch) p.catch(function () {}); } catch (e) {} }
      if (!v._lgpBound) {
        v._lgpBound = true;
        function stillOpen() { var s = document.getElementById('sub-practice'); return s && s.classList.contains('open'); }
        v.addEventListener('loadeddata', tryPlay);
        v.addEventListener('canplay', tryPlay);
        v.addEventListener('pause', function () { if (stillOpen()) setTimeout(tryPlay, 30); });
        v.addEventListener('stalled', tryPlay);
        v.addEventListener('ended', function () { try { v.currentTime = 0; } catch (e) {} tryPlay(); });
      }
      if (v.paused) tryPlay();
    })();

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

    /* Same reasoning as the arc — the info panel must live outside .sub-screen's
       stacking context, and must not be yanked shut mid-view by a re-render. */
    var existingInfo = document.getElementById('lgpInfoPanel');
    if (!(existingInfo && existingInfo.classList.contains('open'))) {
      if (existingInfo) existingInfo.remove();
      var tmp2 = document.createElement('div');
      tmp2.innerHTML = infoPanel;
      document.body.appendChild(tmp2.firstChild);
    }

    /* ── ONE-SHOT info-icon hint: ~0.9s after the player opens, the icon
       pulses and a pill grows out to its left — "Learn more" then
       "Learn your score" with a light tracing round it — then it retracts.
       Plays once per player open (not on every re-render, not looping). ── */
    if (window._lgpHintPending && !window._lgpHintScheduled) {
      window._lgpHintScheduled = true;
      setTimeout(function () {
        window._lgpHintPending = false;
        window._lgpHintScheduled = false;
        var cluster = document.getElementById('lgpInfoCluster');
        var txt = document.getElementById('lgpInfoPillTxt');
        if (!cluster) return;
        if (txt) txt.textContent = 'Learn more';
        cluster.classList.remove('hint-run');
        void cluster.offsetWidth;              // restart the animation cleanly
        cluster.classList.add('hint-run');
        setTimeout(function () { var t = document.getElementById('lgpInfoPillTxt'); if (t) t.textContent = 'Learn your score'; }, 2100);
        setTimeout(function () {
          var c = document.getElementById('lgpInfoCluster'); if (c) c.classList.remove('hint-run');
          /* once the pill has retracted, the icon itself gets a light tracing round it */
          var b = c && c.querySelector('.lgp-info-btn');
          if (b) {
            b.classList.remove('trace-run'); void b.offsetWidth; b.classList.add('trace-run');
            setTimeout(function () { if (b) b.classList.remove('trace-run'); }, 2700);
          }
        }, 4600);
      }, 900);
    }
  }
  window.renderLiquidPlayer = renderLiquidPlayer;

  /* Open the Store DIRECTLY from the player — no home flash, no intro flash.
     Open the store ON TOP of the player (higher z-index), skip its intro, then
     quietly close the player behind it. */
  window.lgpOpenStore = function () {
    try {
      if (typeof openSub === 'function') openSub('nowssb-store');   /* nssOpen — slides the store in */
      var s = document.getElementById('sub-nowssb-store');
      if (s) s.style.zIndex = '900';                               /* sit ON TOP of the player (no need to close it → no home flash) */
      if (typeof nssEnterStore === 'function') nssEnterStore();     /* render the store body + media */
      /* kill the intro page INSTANTLY (no fade) so we land straight on the store */
      var intro = document.getElementById('nssIntroPage');
      if (intro) { intro.style.display = 'none'; intro.style.opacity = '0'; intro.style.pointerEvents = 'none'; }
    } catch (e) {}
  };

  window.lgpToggleArc = function (forceOpen) {
    var a = document.getElementById('lgpArc');
    if (!a) return;
    var willOpen = (forceOpen === true) ? true : !a.classList.contains('open');
    a.classList.toggle('open', willOpen);
    /* Inline styles so the arc opens even if a stale cached player CSS is still
       in effect (immune to the old narrow-column bug). */
    a.style.position = 'fixed';
    a.style.left = a.style.top = a.style.right = a.style.bottom = '0';
    a.style.zIndex = '2147483000';
    a.style.pointerEvents = willOpen ? 'auto' : 'none';
    var back = a.querySelector('.lgp-arc-back');
    if (back) {
      back.style.position = 'absolute';
      back.style.left = back.style.top = back.style.right = back.style.bottom = '0';
      back.style.background = 'rgba(6,10,25,.32)';
      back.style.transition = 'opacity .3s';
      back.style.opacity = willOpen ? '1' : '0';
      /* blur EVERYTHING behind the menu (only while open) */
      var blur = willOpen ? 'blur(16px) saturate(1.2)' : 'none';
      back.style.webkitBackdropFilter = blur;
      back.style.backdropFilter = blur;
    }
    var rad = a.querySelector('.lgp-arc-radial');
    if (rad) {
      rad.style.transition = 'transform .36s cubic-bezier(.2,1.1,.3,1), opacity .28s';
      rad.style.opacity = willOpen ? '1' : '0';
      rad.style.transform = 'translate(-50%,-50%) scale(' + (willOpen ? '1' : '.55') + ')';
    }
  };

  window.lgpToggleInfo = function (forceOpen) {
    var p = document.getElementById('lgpInfoPanel');
    if (!p) return;
    var willOpen = (forceOpen === true) ? true : !p.classList.contains('open');
    p.classList.toggle('open', willOpen);
    /* Inline styles so it opens even if a stale cached player CSS is still in
       effect — same bulletproofing as the settings arc. */
    p.style.position = 'fixed';
    p.style.left = p.style.top = p.style.right = p.style.bottom = '0';
    p.style.zIndex = '2147483000';
    p.style.pointerEvents = willOpen ? 'auto' : 'none';
    var back = p.querySelector('.lgp-info-back');
    if (back) {
      back.style.position = 'absolute';
      back.style.left = back.style.top = back.style.right = back.style.bottom = '0';
      back.style.background = 'rgba(6,10,25,.4)';
      back.style.transition = 'opacity .3s';
      back.style.opacity = willOpen ? '1' : '0';
      /* completely blur the player behind it, liquid-glass style */
      var blur = willOpen ? 'blur(22px) saturate(1.3)' : 'none';
      back.style.webkitBackdropFilter = blur;
      back.style.backdropFilter = blur;
    }
    var sheet = p.querySelector('.lgp-info-sheet');
    if (sheet) {
      /* full-page now (inset:0), so it centers by filling the screen — no
         translateX needed. Slide up + fade on open. */
      sheet.style.left = '0';
      sheet.style.transition = 'transform .4s cubic-bezier(.2,1,.3,1), opacity .3s';
      sheet.style.opacity = willOpen ? '1' : '0';
      sheet.style.transform = willOpen ? 'translateY(0)' : 'translateY(100%)';
      if (willOpen) sheet.scrollTop = 0;
    }
    // load+play the organ video ONLY while the panel is open; stop it on close
    var vid = p.querySelector('.lgp-info-video');
    if (vid) {
      try {
        if (willOpen) { var pp = vid.play(); if (pp && pp.catch) pp.catch(function(){}); }
        else { vid.pause(); try { vid.currentTime = 0; } catch (e) {} }
      } catch (e) {}
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
      /* not using the liquid player → make sure no stray body-level arc/info panel lingers */
      var stray = document.getElementById('lgpArc');
      if (stray) stray.remove();
      var strayInfo = document.getElementById('lgpInfoPanel');
      if (strayInfo) strayInfo.remove();
      return orig.apply(this, arguments);
    };
  })();

  /* Close (and detach) the arc + info panel whenever the practice screen is closed */
  (function patchCloseSub() {
    if (typeof window.closeSub !== 'function') { return setTimeout(patchCloseSub, 200); }
    var orig = window.closeSub;
    window.closeSub = function (id) {
      if (id === 'practice') {
        var a = document.getElementById('lgpArc'); if (a) a.remove();
        var p = document.getElementById('lgpInfoPanel'); if (p) p.remove();
      }
      return orig.apply(this, arguments);
    };
  })();

  /* Arm the one-shot info hint each time the practice screen is opened */
  (function patchOpenSubHint() {
    if (typeof window.openSub !== 'function') { return setTimeout(patchOpenSubHint, 200); }
    var orig = window.openSub;
    window.openSub = function (id) {
      if (id === 'practice') {
        window._lgpHintPending = true; window._lgpHintScheduled = false;
        /* pick ONE theme for this whole session (rotate through all 10 across
           sessions for variety, but keep it fixed within a session so the
           video never reloads on word navigation). */
        try {
          var n = (parseInt(localStorage.getItem('nwsb_lgp_theme') || '-1', 10) + 1);
          if (isNaN(n) || n < 0) n = 0;
          n = n % LGP_THEMES.length;
          localStorage.setItem('nwsb_lgp_theme', String(n));
          window._lgpSessionThemeIdx = n;
          /* warm the chosen video into cache right away */
          if (LGP_THEMES[n] && LGP_THEMES[n].video) { var pv = new Image(); /* hint */ }
        } catch (e) { window._lgpSessionThemeIdx = 0; }
      }
      return orig.apply(this, arguments);
    };
  })();

  /* ── Warm the cache: preload all player theme IMAGES in the background once
     the app is idle, so the player opens instantly. Images only — preloading
     every video would be 100+MB and still wouldn't stop decode-time stutter,
     so that's deliberately NOT done here. Runs once. ── */
  (function preloadPlayerImages() {
    if (window._lgpImgsPreloaded) return;
    window._lgpImgsPreloaded = true;
    function run() {
      for (var i = 0; i < LGP_THEMES.length; i++) {
        if (LGP_THEMES[i].img) { var im = new Image(); im.src = LGP_THEMES[i].img; }
      }
    }
    if (window.requestIdleCallback) requestIdleCallback(run, { timeout: 4000 });
    else setTimeout(run, 2500);
  })();
})();
