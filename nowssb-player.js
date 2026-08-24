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
    /* Liquid splash goes FIRST — it is what the first word of a session
       opens on. The only look that ships WITH the app rather than coming
       from Cloudinary, which is also why it is the one worth having
       before anything else: cldVid() leaves a path with no
       /video/upload/ in it alone, so it reaches the <video> untouched. */
    { img:'./assets/player/liquid-splash.webp',
      video:'./assets/video/player-liquid-splash.mp4',
      accent:'#ffcf4d' },
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
      accent:'#8fe6ff' },
  ];

  /* Exposed so app/js/part051.js's background video pre-warmer (Cache
     Storage, same mechanism as every other decorative video in the app)
     can also warm these — the practice screen builds its <video> elements
     dynamically per word, so none of them exist in the DOM yet at the point
     the pre-warmer scans for videos to cache. Pre-transformed through
     cldVid() at the exact same widths the player actually requests
     (720 for theme videos, 640 for organ videos), so the cached entry's
     URL is byte-for-byte what the <video src> will ask for. */
  /* Every theme video, local ones included. The first look ships inside
     the app and is the one every session opens on, so it goes at the head
     of the queue — the pre-warmer (app/js/part051.js) walks this list in
     order into Cache Storage, and a cached entry means the panel is not
     waiting on the network when the player opens. */
  window.NWSB_PLAYER_VIDEO_URLS = LGP_THEMES
    .map(function (t) { return cldVid(t.video, 720); })
    .concat(Object.keys(ORGAN_VIDEOS).map(function (k) { return ORGAN_VIDEOS[k]; }).filter(Boolean).map(function (v) { return cldVid(v, 640); }));
  /* The pictures behind the player go into the same cache. They are what
     shows while a clip is still opening, so an uncached one is a visible
     blank on the first word. */
  window.NWSB_PLAYER_IMAGE_URLS = LGP_THEMES.map(function (t) { return t.img; }).filter(Boolean);

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

  /* ── Liked words ───────────────────────────────────────────────────────
     localStorage is the source of truth so the heart is right the instant
     the player opens, with no round trip and nothing to wait for. When
     someone is signed in the same list is mirrored to their user document,
     so it follows them to another phone. A failed write must never lose the
     tap — the local list is already saved by then. */
  var LIKES_KEY = 'nwsb_liked_words';
  function lgpLikes() {
    try {
      var raw = JSON.parse(localStorage.getItem(LIKES_KEY) || '[]');
      return Array.isArray(raw) ? raw : [];
    } catch (e) { return []; }
  }
  function lgpIsLiked(word) {
    if (!word) return false;
    return lgpLikes().indexOf(word) !== -1;
  }
  window.lgpIsLiked = lgpIsLiked;
  window.lgpLikedWords = lgpLikes;

  window.lgpToggleLike = function () {
    var words = (typeof PRACTICE_WORDS !== 'undefined') ? PRACTICE_WORDS : [];
    var idx = (typeof _pwIdx !== 'undefined') ? _pwIdx : 0;
    var w = words[idx];
    if (!w || !w.word) return;

    var list = lgpLikes();
    var at = list.indexOf(w.word);
    var nowLiked = at === -1;
    if (nowLiked) list.push(w.word); else list.splice(at, 1);
    try { localStorage.setItem(LIKES_KEY, JSON.stringify(list)); } catch (e) {}

    /* Repaint the one button rather than re-rendering the player: a full
       render rebuilds the video element and restarts the animation
       sequence, which is a lot of churn for a heart. */
    var btn = document.getElementById('lgpLikeBtn');
    if (btn) {
      btn.classList.toggle('liked', nowLiked);
      btn.setAttribute('aria-pressed', nowLiked ? 'true' : 'false');
      if (nowLiked) {
        btn.classList.remove('pop');
        void btn.offsetWidth;              // restart the pop cleanly
        btn.classList.add('pop');
        setTimeout(function () { if (btn) btn.classList.remove('pop'); }, 420);
      }
    }

    if (window._userDataCache) window._userDataCache.likedWords = list;
    if (window._currentUid && window._fbSetDoc) {
      window._fbSetDoc(window._currentUid, { likedWords: list }).catch(function () {});
    }
  };

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
    /* The thin bar under the panel used to be rep progress, which is 0 for
       most of the time anyone is looking at it — a line that sat there doing
       nothing. It is the SESSION now: how far through the ritual you are,
       with the current word's reps filling that word's own slice. */
    var _repFrac = repTarget ? Math.min(1, repCount / repTarget) : 0;
    var sessionPct = total ? Math.min(100, ((idx + _repFrac) / total) * 100) : 0;
    var voice = (typeof _pwVoice !== 'undefined') ? _pwVoice : 'F';
    var loop = (typeof _pwLoop !== 'undefined') ? !!_pwLoop : false;
    /* Per-word theme (= per-word video) — each word gets its own video,
       changing every time Next/Previous is pressed. An earlier version
       locked this to one theme for the whole session to avoid a reload
       stutter, but that meant the video never changed on word navigation
       at all, only between sessions — not what was wanted. */
    var _thIdx = Math.abs(idx);
    var th = LGP_THEMES[_thIdx % LGP_THEMES.length];
    var hr = new Date().getHours();
    var timeLabel = hr < 10 ? 'Morning' : hr < 13 ? 'Midday' : hr < 17 ? 'Afternoon' : hr < 20 ? 'Evening' : 'Night';
    var ar = (typeof getActiveRoutine === 'function') ? getActiveRoutine() : null;
    var ritual = ar ? ar.name : timeLabel;

    /* ── The pronunciation boxes ──────────────────────────────────────
       A NowssB word is written in Devanagari, which has sounds English has
       no letter for — so a roman spelling alone cannot teach it. Each box
       carries the roman spelling to read, the Devanagari above it to
       recognise, how long to hold it, and, when one has been recorded, the
       sound itself: tapping the box plays that syllable. The whole record
       comes from the studio (see app/js/part073.js).

       Words that predate this have only `syllables`, and still draw
       exactly as they did — every extra line is conditional. */
    var _e = function (s) {
      return String(s == null ? '' : s)
        .replace(/&/g, '&').replace(/</g, '<').replace(/>/g, '>')
        .replace(/"/g, '"').replace(/'/g, '&#39;');
    };
    var boxes = (w.parts && w.parts.length)
      ? w.parts
      : (w.syllables || []).map(function (s) { return { roman: s }; });

    window._lgpParts = boxes;
    var syl = boxes.map(function (p, i) {
      var hint = [p.say, p.hold ? 'hold ' + p.hold + 's' : ''].filter(Boolean).join(' · ');
      return '<span class="lgp-syl' + (p.audio ? ' lgp-syl-say' : '') + '" id="spSyl' + i + '"' +
               (hint ? ' title="' + _e(hint) + '"' : '') +
               (p.audio ? ' onclick="window.lgpSayPart&&window.lgpSayPart(' + i + ')"' : '') + '>' +
               (p.deva ? '<b class="lgp-syl-deva">' + _e(p.deva) + '</b>' : '') +
               '<b class="lgp-syl-rom">' + _e(p.roman || p.deva || '') + '</b>' +
               (p.hold ? '<b class="lgp-syl-hold">' + p.hold + 's</b>' : '') +
             '</span>' +
        (i < boxes.length - 1 ? '<span class="lgp-syl-dot">·</span>' : '');
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
      info:     'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782986898/file_000000002038722fac63c79466d73f0f_jnhjvg.png',
      brand:    'https://res.cloudinary.com/eenvubod/image/upload/e_trim,f_auto,q_auto,w_180/v1784130176/file_000000003254720aab81c7118e7cc24a_ohsba3.png',
      /* Only the two black banners use this. The top bar, the corner mark
         and the info sheet keep IC.brand — same icon there as before. */
      banner:   'https://res.cloudinary.com/eenvubod/image/upload/v1785070108/1000002027_o74vwe.png'
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
    /* Same trick for the clip inside the tab under the picture. Its source
       never changes, so after the first render it is always carried across
       — otherwise every phase change reloaded it and it stuttered back to
       frame one while you were looking at it. */
    var _keepWaVid = null;
    (function () {
      var ex = document.getElementById('practiceBody');
      var cur = ex ? ex.querySelector('.lgp-wa-vid') : null;
      if (cur) { _keepWaVid = cur; if (cur.parentNode) cur.parentNode.removeChild(cur); }
    })();
    var visual = th.video
      ? (_keepVid ? '<span class="lgp-video-slot"></span>'
                  : '<video class="lgp-video" autoplay loop muted playsinline preload="auto" src="' + _newVidSrc + '"></video>')
      : '<div class="lgp-video-fallback"></div>';

    /* phase-aware center block — preserves the original IDs so play/record/score work */
    var center =
      '<div class="lgp-phase">' +
        '<div id="spPhaseIdlePlay" style="display:' + ((phase === 'idle' || phase === 'playing') ? 'flex' : 'none') + ';flex-direction:column;align-items:center;gap:10px;width:100%;">' +
          /* "Tap ▸ to listen" used to sit here. The play button says that
             already, and the bars beside the bar say when it is playing.
             The id stays on a hidden node — other code writes to it. */
          '<div class="lgp-status" id="spAutoStatus" hidden></div>' +
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
        '</div>' +
        /* The "Word played · your turn" page used to sit here — a whole
           screen that replaced the transport the moment playback ended,
           with its own Replay, its own Practice Now and its own second set
           of prev/play/next. Everything on it is on the main screen
           already. pwStop() lands on 'idle' now, so the player simply goes
           back to being the player when the word finishes. */
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
      '<div class="lgp-arc-bottom">' +
        '<div class="lgp-arc-banner"><div class="lgp-arc-banner-icon" style="background-image:url(\'' + IC.banner + '\')"></div><div class="lgp-arc-banner-divider"></div><div class="lgp-arc-banner-text" id="lgpArcBannerText"></div></div>' +
        '<div class="lgp-arc-info">' +
          '<div class="lgp-arc-info-word">' + (w.word || '') + (w.phonetic ? ' <span>' + w.phonetic + '</span>' : '') + '</div>' +
          (w.meaning ? '<div class="lgp-arc-info-row"><span class="k">Meaning</span><span class="v">' + w.meaning + '</span></div>' : '') +
          (w.benefit ? '<div class="lgp-arc-info-row"><span class="k">Heals</span><span class="v">' + w.benefit + '</span></div>' : '') +
          ((w.categories && w.categories.length) ? '<div class="lgp-arc-info-row"><span class="k">Category</span><span class="v">' + w.categories.join(' · ') + '</span></div>' : (w.organ ? '<div class="lgp-arc-info-row"><span class="k">Category</span><span class="v">' + w.organ + '</span></div>' : '')) +
        '</div>' +
      '</div>';
    var arc =
      '<div class="lgp-arc" id="lgpArc" style="--lg-accent:' + th.accent + '">' +
        '<div class="lgp-arc-back" onclick="lgpToggleArc()"></div>' +
        '<button class="lgp-arc-close" onclick="lgpToggleArc()" aria-label="Back"><span class="lgp-arc-close-ico" style="background-image:url(\'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782728734/file_00000000ae6071fa982c6eec401328c6_uvgfjs.png\')"></span></button>' +
        '<div class="lgp-arc-brand"><span class="lgp-arc-brand-txt">NowssB Player</span></div>' +
        '<span class="lgp-arc-brand-ico-corner" style="background-image:url(\'' + IC.brand + '\')"></span>' +
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
            '<div class="lgp-info-sheet-brand" style="background-image:url(\'' + IC.brand + '\')"></div>' +
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

    /* ── Sentence · Practice · Store, at the TOP ──
       It was the last thing on the screen, under the transport. It is
       the first thing now, in the slot the ticker banner used to hold —
       and it is built out of the same lit tab as the row under the
       picture, with the black screen and the ring clip inside it. */
    var prow =
      '<div class="lgp-practice-row">' +
        /* The three rings, in glass. Each button sits in the hole of
           its own ring — see .lgp-pr-glass in nowssb-player.css for
           where the 19/50/81% come from. */
        '<div class="lgp-pr-glass">' +
          (_keepWaVid
            ? '<span class="lgp-wa-vid-slot"></span>'
            : '<video class="lgp-wa-vid" muted playsinline autoplay loop preload="auto" aria-hidden="true"' +
              ' src="./assets/video/word-acts.mp4"></video>') +
        '</div>' +
        '<button class="lgp-sentence" onclick="openWalkmanLib&&openWalkmanLib();if(typeof wlSwitchTab===\'function\')setTimeout(function(){wlSwitchTab(\'build\')},90)" aria-label="Build your sentence">' +
          '<span class="lgp-pr-ico"><svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M4 5.5h16v10.5H9.5L5.5 19.5V16H4z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/><path d="M7.5 9.5h9M7.5 12.6h6" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg></span>' +
          '<span class="lgp-pr-lbl">Sentence</span>' +
        '</button>' +
        '<span class="lgp-practice-sep" aria-hidden="true"></span>' +
        '<button class="lgp-practice" onclick="pwPracticeNow&&pwPracticeNow()" aria-label="Practice this word">' +
          '<span class="lgp-pr-ico"><svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><rect x="9" y="2.6" width="6" height="11.2" rx="3" stroke="currentColor" stroke-width="1.7"/><path d="M5.5 11.4a6.5 6.5 0 0 0 13 0" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><path d="M12 17.9v3.5M8.6 21.4h6.8" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg></span>' +
          '<span class="lgp-pr-lbl">Practice</span>' +
        '</button>' +
        '<span class="lgp-practice-sep" aria-hidden="true"></span>' +
        '<button class="lgp-store" onclick="lgpOpenStore&&lgpOpenStore()" aria-label="Store">' +
          '<span class="lgp-pr-ico"><svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M4.4 7.6h15.2l-1.1 12.2a1.6 1.6 0 0 1-1.6 1.4H7.1a1.6 1.6 0 0 1-1.6-1.4z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/><path d="M8.8 10V6.4a3.2 3.2 0 0 1 6.4 0V10" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg></span>' +
          '<span class="lgp-pr-lbl">Store</span>' +
        '</button>' +
      '</div>';

    body.innerHTML =
      '<div class="lgp' + (playing ? ' playing' : '') + '" style="--lg-bg:url(\'' + th.img + '\');--lg-accent:' + th.accent + ';">' +
        '<div class="lgp-bg"></div><div class="lgp-scrim"></div><div class="lgp-orbs"></div>' +
        '<div class="lgp-top">' +
          /* A white disc with a plain arrow, not the glass sphere. */
          '<button class="lgp-back lgp-white-btn" onclick="closeSub&&closeSub(\'practice\')" aria-label="Back">' +
            '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
              '<path d="M15 5l-7 7 7 7" stroke="#0a0a12" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>' +
            '</svg>' +
          '</button>' +
          '<div class="lgp-brand"><span class="lgp-brand-ico" style="background-image:url(\'' + IC.brand + '\')"></span><span class="lgp-brand-txt">NowssB</span></div>' +
          '<div class="lgp-top-right">' +
            /* The heart used to live here. It sits in the band below now,
               beside Notes, because that band was carrying nothing and
               this row was already full. */
            '<button class="lgp-settings lgp-imgbtn" type="button" aria-label="Settings">' +
              '<span class="lgp-bgico" style="background-image:url(\'' + IC.settings + '\')"></span>' +
            '</button>' +
          '</div>' +
        '</div>' +
        /* The ticker banner, back above the picture — and the black bar
           IS the tab's aperture now, so it reads as the same object as
           the two rows below it. */
        '<div class="lgp-banner-tab">' +
          '<div class="lgp-info-banner">' +
            '<div class="lgp-info-banner-icon" style="background-image:url(\'' + IC.banner + '\')"></div>' +
            '<div class="lgp-info-banner-divider"></div>' +
            '<div class="lgp-info-banner-text" id="lgpBannerText"></div>' +
          '</div>' +
        '</div>' +
        '<div class="lgp-visual">' + visual +
          /* ONE row across the top of the panel, not two islands pinned to
             the corners. Pinned, they overlapped the moment either side got
             long — "Afternoon" plus "Learn your score" was enough. In a row
             the ritual is the only thing that can shrink, and it ellipsises
             instead of running under the bars. */
          '<div class="lgp-visual-top">' +
            '<div class="lgp-visual-tag"><span class="lgp-visual-tag-dot"></span><span class="lgp-visual-tag-txt">' + _e(ritual) + '</span></div>' +
            '<div class="lgp-info-cluster" id="lgpInfoCluster">' +
            /* the sound, shown rather than described — the bars idle slowly
               and run at full tilt while the word is playing (.lgp.playing) */
            '<span class="lgp-eq" aria-hidden="true"><i></i><i></i><i></i><i></i></span>' +
            '<div class="lgp-info-pill"><span class="lgp-info-pill-txt" id="lgpInfoPillTxt">Learn more</span></div>' +
            '<button class="lgp-info-btn" onclick="window.lgpToggleInfo&&window.lgpToggleInfo()" aria-label="Word info">' +
              '<span class="lgp-bgico" style="background-image:url(\'' + IC.info + '\')"></span>' +
            '</button>' +
            '</div>' +
          '</div>' +
          /* ── The two rails, inside the picture ──
             Replay · Notes · Like stand in a vertical pill down the left;
             the volume runs down the right. Both fold away behind the
             toggle under the volume, and that choice is remembered. */
          '<div class="lgp-rail lgp-rail-l">' +
            '<button class="lgp-wa lgp-wa-replay" type="button"' +
              ' onclick="_pwPhase=\'idle\';pwPlay&&pwPlay()" aria-label="Replay">' +
              '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
                '<path d="M3.5 12a8.5 8.5 0 1 0 2.6-6.1" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>' +
                '<path d="M3 3v5h5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
              '</svg>' +
            '</button>' +
            '<span class="lgp-wa-sep" aria-hidden="true"></span>' +
            '<button class="lgp-wa lgp-wa-notes" id="lgpNotesBtn" type="button"' +
              ' onclick="window.lgpOpenNotes&&window.lgpOpenNotes()" aria-label="Pronunciation notes">' +
              '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
                '<path d="M6 3.5h8.5L19 8v12.5H6z" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>' +
                '<path d="M14 3.5V8h4.6" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>' +
                '<path d="M9 12h6M9 15.5h4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>' +
              '</svg>' +
            '</button>' +
            '<span class="lgp-wa-sep" aria-hidden="true"></span>' +
            '<button class="lgp-wa lgp-like' + (lgpIsLiked(w.word) ? ' liked' : '') + '" id="lgpLikeBtn" type="button"' +
              ' onclick="window.lgpToggleLike&&window.lgpToggleLike()"' +
              ' aria-pressed="' + (lgpIsLiked(w.word) ? 'true' : 'false') + '" aria-label="Like this word">' +
              '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 20.2 4.6 13a4.6 4.6 0 0 1 6.5-6.5l.9.9.9-.9A4.6 4.6 0 0 1 19.4 13z"/></svg>' +
            '</button>' +
          '</div>' +
          /* The volume is a speaker until you press it. The slider is what
             it opens into, and it stays open until you press it again. */
          '<div class="lgp-rail lgp-rail-r' + (lgpVolOpen() ? ' vol-open' : '') + '" id="lgpVolRail">' +
            '<div class="lgp-vol-wrap">' +
              '<span class="lgp-vol-val" id="lgpVolVal">' + Math.round(lgpVolume() * 100) + '</span>' +
              '<div class="lgp-vol" id="lgpVol" role="slider" tabindex="0"' +
                ' aria-label="Volume" aria-valuemin="0" aria-valuemax="100"' +
                ' aria-valuenow="' + Math.round(lgpVolume() * 100) + '">' +
                '<span class="lgp-vol-fill" id="lgpVolFill" style="height:' + (lgpVolume() * 100) + '%"></span>' +
              '</div>' +
            '</div>' +
            '<button class="lgp-vol-btn" id="lgpVolBtn" type="button"' +
              ' onclick="window.lgpToggleVol&&window.lgpToggleVol()"' +
              ' aria-expanded="' + (lgpVolOpen() ? 'true' : 'false') + '" aria-label="Volume">' +
              '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
                '<path d="M4 9.2h3.4L12 5.2v13.6L7.4 14.8H4z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/>' +
                '<path class="lgp-vol-w1" d="M15.6 9.4a3.6 3.6 0 0 1 0 5.2" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>' +
                '<path class="lgp-vol-w2" d="M18.2 7a7.2 7.2 0 0 1 0 10" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>' +
                '<path class="lgp-vol-mute" d="M16 9.5l5 5M21 9.5l-5 5" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>' +
              '</svg>' +
            '</button>' +
          '</div>' +
          /* Fold both away. The picture is the thing; some of the time you
             want to see it with nothing on top of it. */
          '<button class="lgp-rail-toggle" id="lgpRailToggle" type="button"' +
            ' onclick="window.lgpToggleRails&&window.lgpToggleRails()"' +
            ' aria-label="Hide the controls">' +
            '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
              '<path d="M4 8h10M18 8h2M4 16h4M12 16h8" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"/>' +
              '<circle cx="16" cy="8" r="2.1" stroke="currentColor" stroke-width="1.9"/>' +
              '<circle cx="10" cy="16" r="2.1" stroke="currentColor" stroke-width="1.9"/>' +
            '</svg>' +
          '</button>' +
        /* The bottom of the picture: the word. */
        '<div class="lgp-visual-overlay">' +
        '<div class="lgp-wordblock">' +
          '<div class="lgp-title">' + (w.word || '') + '</div>' +
            /* The word as it is actually written. The roman title above is
               the reading aid, not the word. */
          (w.deva ? '<div class="lgp-deva nwsb-deva">' + _e(w.deva) + '</div>' : '') +
          '<div class="lgp-syls">' + syl + '</div>' +
          '<div class="lgp-organ">' + (w.organ || '') + '</div>' +
        '</div>' +
        '</div>' +   /* end .lgp-visual-overlay */
        '</div>' +   /* end .lgp-visual */
        /* The Replay/Notes/Like tab used to sit here. Its clip moved
           into the Sentence · Practice · Store tab at the bottom, and the
           three buttons went into the picture. */
        /* The Listen · Learn · Practice · Heal ticker used to sit here. */
        /* The bar, in a wrapper with room around it, and the four bars on
           its left that move while the word is being spoken. */
        '<div class="lgp-barwrap">' +
          /* A waveform, not four bouncing sticks: nine bars whose resting
             heights already draw a wave, and a travelling phase while the
             word is being spoken. */
          '<span class="lgp-bar-wave" aria-hidden="true">' +
            '<i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i>' +
          '</span>' +
          '<span class="lgp-bar-sep" aria-hidden="true"></span>' +
          '<div class="lgp-progress' + (playing ? ' running' : '') + '" role="progressbar"' +
            ' aria-valuemin="0" aria-valuemax="100" aria-valuenow="0"' +
            ' aria-label="Playback">' +
            '<div class="lgp-progress-fill" style="width:0%"></div>' +
          '</div>' +
        '</div>' +
        center +
        /* Sentence · Practice · Store — back at the bottom. */
        prow +
      '</div>';

    /* Banner under the top bar — icon + divider + looping text (was two
       separate static lines: the "fashion trend" tagline and the "Ritual ·
       N of total" counter). Cycles between them on a shared timer, reset on
       every re-render since the whole body (including this text node) gets
       rebuilt on every word/phase change. */
    (function () {
      var el = document.getElementById('lgpBannerText');
      /* The banner is gone from the layout. This stays because the element
         may come back, and because a timer left running would keep
         painting into a detached node. */
      if (!el) { if (window._lgpBannerTimer) { clearInterval(window._lgpBannerTimer); window._lgpBannerTimer = 0; } return; }
      var lines = ['The new fashion trend of meditation', ritual + ' Ritual · ' + (idx + 1) + ' of ' + total];
      var i = 0;
      /* animate=false forces the line to full opacity via inline style —
         the dash-in keyframe starts at opacity:0 (both fill-mode) and only
         reaches opacity:1 partway through, so a re-render (word change,
         play/pause, phase change — this whole panel is rebuilt on all of
         them) landing mid-animation, or interrupting one cycle's animation
         with the next, can leave the class-based animation stuck at its
         0%-opacity starting style. Setting opacity/transform directly
         sidesteps that entirely for the "must be visible right now" case;
         animate=true clears the inline override first so the class-based
         dash-in keyframe is free to run for the timer-driven cycling. */
      function paint(animate) {
        el.textContent = lines[i % lines.length];
        el.classList.remove('dash-in');
        if (animate) {
          el.style.opacity = ''; el.style.transform = ''; el.style.animation = '';
          void el.offsetWidth;
          el.classList.add('dash-in');
        } else {
          el.style.animation = 'none';
          el.style.opacity = '1';
          el.style.transform = 'none';
        }
        i++;
      }
      paint(false);
      if (window._lgpBannerTimer) clearInterval(window._lgpBannerTimer);
      window._lgpBannerTimer = setInterval(function () { paint(true); }, 2800);
    })();

    /* Re-insert the preserved video element (kept playing, no reload/seek). */
    if (_keepVid) {
      var _slot = body.querySelector('.lgp-video-slot');
      if (_slot && _slot.parentNode) _slot.parentNode.replaceChild(_keepVid, _slot);
      else { var _vw = body.querySelector('.lgp-visual'); if (_vw) _vw.insertBefore(_keepVid, _vw.firstChild); }
    }

    if (window._lgpBindRails) window._lgpBindRails();

    /* Re-insert the preserved tab clip the same way. */
    if (_keepWaVid) {
      var _wslot = body.querySelector('.lgp-wa-vid-slot');
      if (_wslot && _wslot.parentNode) _wslot.parentNode.replaceChild(_keepWaVid, _wslot);
      else { var _ws = body.querySelector('.lgp-pr-glass'); if (_ws) _ws.insertBefore(_keepWaVid, _ws.firstChild); }
    }

    /* Keep the small clips playing. Bind the resume listeners ONCE per
       element (not every render — that leaked handlers and caused jank). */
    ['.lgp-wa-vid'].forEach(function (sel) {
      var v = body.querySelector(sel);
      if (!v) return;
      v.muted = true; v.setAttribute('muted', ''); v.playsInline = true; v.loop = true;
      function go() { try { var p = v.play(); if (p && p.catch) p.catch(function () {}); } catch (e) {} }
      if (!v._lgpBound) {
        v._lgpBound = true;
        v.addEventListener('loadeddata', go);
        v.addEventListener('canplay', go);
        v.addEventListener('stalled', go);
      }
      if (v.paused) go();
    });
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

    /* ── The bar follows the SOUND ──────────────────────────────────
       It was the session: word index over word count. Reps are gone and a
       one-word ritual is 0 of 1, so it sat at 0% and never moved.

       It is the spoken word now — 0% when it starts, full when it ends.
       speechSynthesis reports no position, but pwPlay() records the end of
       each repetition into window._lgpSound, so the run is known a
       repetition at a time and this interpolates inside the current one
       using the measured length of the last. The first repetition uses
       pwPlay's estimate (~750ms a syllable, the same clock that lights the
       syllable boxes); every one after it is measured, so a word whose
       real speed differs from the estimate self-corrects after one pass
       and still lands exactly on full. ── */
    (function () {
      if (window._lgpProgRaf) { cancelAnimationFrame(window._lgpProgRaf); window._lgpProgRaf = 0; }
      var fill = body.querySelector('.lgp-progress-fill');
      if (!fill) return;
      var now = function () { return (window.performance && performance.now) ? performance.now() : Date.now(); };
      function pct() {
        var S = window._lgpSound;
        if (!S) return 0;
        if (S.done) return 100;
        var dur = S.dur || S.est || 2000;
        var within = Math.min(1, (now() - S.t0) / dur);
        if (!S.total) return ((S.loop + within) % 1) * 100;   /* looping forever */
        return Math.min(100, ((S.loop + within) / S.total) * 100);
      }
      if (!playing) {
        fill.style.transition = '';
        fill.style.width = pct() + '%';
        return;
      }
      fill.style.transition = 'none';
      function step() {
        var el = document.querySelector('.lgp-progress-fill');
        var stillPlaying = (typeof _pwPlaying !== 'undefined') && !!_pwPlaying;
        if (!el) { window._lgpProgRaf = 0; return; }
        var p = pct();
        el.style.width = p + '%';
        var bar = el.parentNode;
        if (bar && bar.setAttribute) bar.setAttribute('aria-valuenow', Math.round(p));
        if (!stillPlaying) { window._lgpProgRaf = 0; return; }
        window._lgpProgRaf = requestAnimationFrame(step);
      }
      window._lgpProgRaf = requestAnimationFrame(step);
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

      /* Banner cycles through the actual practice procedure, one step at a
         time — same immediate-then-animated paint pattern as the main
         banner, so it's never caught mid-animation looking blank. */
      (function () {
        var el = document.getElementById('lgpArcBannerText');
        if (!el) return;
        var steps = [
          'Listen — hear the word\'s true pronunciation',
          'Speak — repeat it out loud, syllable by syllable',
          'Learn — understand its meaning and origin',
          'Heal — feel the vibration resonate in your body',
          'Check your Score — track your pronunciation progress'
        ];
        var i = 0;
        function paint(animate) {
          el.textContent = steps[i % steps.length];
          el.classList.remove('dash-in');
          if (animate) {
            el.style.opacity = ''; el.style.transform = ''; el.style.animation = '';
            void el.offsetWidth;
            el.classList.add('dash-in');
          } else {
            el.style.animation = 'none';
            el.style.opacity = '1';
            el.style.transform = 'none';
          }
          i++;
        }
        paint(false);
        if (window._lgpArcBannerTimer) clearInterval(window._lgpArcBannerTimer);
        window._lgpArcBannerTimer = setInterval(function () { paint(true); }, 2200);
      })();
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
        /* the ritual opposite steps aside while the pill is out — on a 360px
           column the two together are wider than the panel */
        var topRow = cluster.parentNode;
        if (topRow && topRow.classList) topRow.classList.add('lgp-hinting');
        setTimeout(function () { var t = document.getElementById('lgpInfoPillTxt'); if (t) t.textContent = 'Learn your score'; }, 5200);
        setTimeout(function () {
          var c = document.getElementById('lgpInfoCluster'); if (c) c.classList.remove('hint-run');
          if (c && c.parentNode && c.parentNode.classList) c.parentNode.classList.remove('lgp-hinting');
          /* once the pill has retracted, the icon itself gets a light tracing round it */
          var b = c && c.querySelector('.lgp-info-btn');
          if (b) {
            b.classList.remove('trace-run'); void b.offsetWidth; b.classList.add('trace-run');
            setTimeout(function () { if (b) b.classList.remove('trace-run'); }, 5400);
          }
        }, 10400);
      }, 900);
    }

    /* (re)start the one-at-a-time animation sequence after every render */
    lgpKickAnimSeq();
  }
  window.renderLiquidPlayer = renderLiquidPlayer;

  /* ── One-at-a-time animation sequencer ───────────────────────────────────
     Previously every traveling-light border (tube, Practice Now, Replay, info
     icon) looped `infinite` at the same time — 3-4 conic-gradient repaints per
     frame competing with the video decode → GPU bottleneck / video stutter.
     Now a single light animates at a time: it plays ONE sweep, then the next
     element does, cycling round. While the word is PLAYING the whole sequence
     stops (CSS also freezes every other animation) so the video gets the GPU. */
  /* .lgp-practice is in here now. Its two rings were pulsing `infinite`,
     outside the rotation entirely — so however well the lights took their
     turns, the Practice orb was always going underneath them and the whole
     thing read as everything at once. The rings are gated on .lgp-anim in
     CSS, so being in this list is what makes them run at all. */
  var _LGP_SEQ_ORDER = ['.lgp-tube', '.lgp-practice', '.lgp-replay-orb', '.lgp-cta', '.lgp-info-btn'];
  /* One sweep, then a full 1s pause where NOTHING animates — the video gets the
     GPU to itself between lights, so playback stays smooth and glitch-free. */
  var _LGP_SEQ_DUR = 2000, _LGP_SEQ_GAP = 1000;
  function lgpSeqClear() {
    var root = document.querySelector('.lgp'); if (!root) return;
    var on = root.querySelectorAll('.lgp-anim');
    for (var i = 0; i < on.length; i++) on[i].classList.remove('lgp-anim');
  }
  function lgpSeqTargets() {
    var root = document.querySelector('.lgp'); if (!root) return [];
    var out = [];
    for (var i = 0; i < _LGP_SEQ_ORDER.length; i++) {
      var els = root.querySelectorAll(_LGP_SEQ_ORDER[i]);
      for (var j = 0; j < els.length; j++) {
        var e = els[j];
        if (e.offsetWidth > 0 && e.offsetHeight > 0) out.push(e); // visible only
      }
    }
    return out;
  }
  function lgpSeqLoop() {
    if (!window._lgpSeqRun) return;              // single-owner guard (no double loops)
    var root = document.querySelector('.lgp');
    if (!root) { window._lgpSeqRun = false; return; }   // player closed — stop; render re-kicks
    if (root.classList.contains('playing')) {    // word playing → no animations, video only
      lgpSeqClear();
      window._lgpSeqTimer = setTimeout(lgpSeqLoop, 500);
      return;
    }
    var els = lgpSeqTargets();
    if (!els.length) { window._lgpSeqTimer = setTimeout(lgpSeqLoop, 600); return; }
    lgpSeqClear();
    var idx = (window._lgpSeqIdx || 0) % els.length;
    var el = els[idx];
    window._lgpSeqIdx = (idx + 1) % els.length;
    el.classList.add('lgp-anim');
    window._lgpSeqTimer = setTimeout(function () {
      el.classList.remove('lgp-anim');
      window._lgpSeqTimer = setTimeout(lgpSeqLoop, _LGP_SEQ_GAP); // one at a time, small gap
    }, _LGP_SEQ_DUR + 60);
  }
  function lgpKickAnimSeq() {
    if (window._lgpSeqRun) return;               // exactly one loop, ever
    window._lgpSeqRun = true;
    window._lgpSeqIdx = 0;
    window._lgpSeqTimer = setTimeout(lgpSeqLoop, 400);
  }
  window.lgpKickAnimSeq = lgpKickAnimSeq;

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

  /* Settings opens the AURA clock first; the clock’s Music Player Settings
     control and upward swipe then reveal the flat settings list. The radial
     arc remains available only for its own player controls, never as settings. */
  window.lgpOpenAURASettings = function () {
    try {
      sessionStorage.setItem('nwsb_return_to_player', JSON.stringify({
        ts: Date.now(),
        wordIndex: (typeof _pwIdx !== 'undefined' ? _pwIdx : 0),
        word: (typeof PRACTICE_WORDS !== 'undefined' && PRACTICE_WORDS[_pwIdx]) ? PRACTICE_WORDS[_pwIdx].word : ''
      }));
    } catch (e) {}
    var url = 'player-settings.html#clock';
    try {
      var pages = (window.NOWSSB_PAGES || (typeof PAGES !== 'undefined' ? PAGES : '') || '').toString();
      if (pages && /github\.io/i.test(pages)) url = pages.replace(/\/?$/, '/') + 'player-settings.html#clock';
    } catch (e) {}
    location.assign(url);
  };

  window.lgpToggleArc = function (forceOpen) {
    if (forceOpen === true) {
      window.lgpOpenAURASettings();
      return;
    }
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
    if (!willOpen && window._lgpArcBannerTimer) { clearInterval(window._lgpArcBannerTimer); window._lgpArcBannerTimer = null; }
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
      if (hit) { e.preventDefault(); e.stopPropagation(); window.lgpOpenAURASettings(); }
    }, true);
  }

  /* renderPractice (part004.js) now calls renderLiquidPlayer() directly and
     unconditionally — the old player UI has been deleted, so there is nothing
     left to monkey-patch/select between here. */

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

/* ── The two rails inside the picture ─────────────────────────────────
   Replay · Notes · Like down the left, the volume down the right, and a
   toggle that folds both away so the artwork is on its own.

   The volume is a real setting, not a decoration: it is what the spoken
   word and the syllable recordings play at, and it survives the app being
   closed. speechSynthesis takes it per-utterance, so it is read at the
   moment pwPlay() speaks rather than pushed anywhere.

   The slider is hand-built rather than an <input type="range">. A vertical
   range needs either the deprecated -webkit-appearance:slider-vertical or
   a writing-mode that browsers disagree about, and both fight the styling.
   A track, a fill and three pointer handlers behave the same everywhere. ── */
(function () {
  var VKEY = 'nwsb_pw_volume', RKEY = 'nwsb_lgp_rails';

  window.lgpVolume = function () {
    var v = parseFloat(localStorage.getItem(VKEY));
    return (isFinite(v) && v >= 0 && v <= 1) ? v : 1;
  };
  window.lgpSetVolume = function (v) {
    v = Math.max(0, Math.min(1, v));
    try { localStorage.setItem(VKEY, String(v)); } catch (e) {}
    var fill = document.getElementById('lgpVolFill');
    var val  = document.getElementById('lgpVolVal');
    var rail = document.getElementById('lgpVol');
    if (fill) fill.style.height = (v * 100) + '%';
    if (val) val.textContent = Math.round(v * 100);
    if (rail) rail.setAttribute('aria-valuenow', Math.round(v * 100));
    /* The speaker itself reads the level, so the folded rail still says
       what the volume is: two waves, one wave, or crossed out. */
    var vr = document.getElementById('lgpVolRail');
    if (vr) {
      vr.classList.toggle('vol-0', v <= 0.001);
      vr.classList.toggle('vol-1', v > 0.001 && v < 0.55);
    }
    /* A word already being spoken keeps the volume it started with —
       speechSynthesis has no live volume — so the change is heard from
       the next word or the next replay. */
    return v;
  };

  /* The slider is folded behind the speaker by default — the picture is
     the thing, and most of the time the volume is already right. */
  var OKEY = 'nwsb_lgp_vol_open';
  window.lgpVolOpen = function () { return localStorage.getItem(OKEY) === 'on'; };
  window.lgpToggleVol = function () {
    var open = !window.lgpVolOpen();
    try { localStorage.setItem(OKEY, open ? 'on' : 'off'); } catch (e) {}
    var rail = document.getElementById('lgpVolRail');
    var btn  = document.getElementById('lgpVolBtn');
    if (rail) rail.classList.toggle('vol-open', open);
    if (btn) btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    if (navigator.vibrate) navigator.vibrate(10);
  };

  function railsHidden() { return localStorage.getItem(RKEY) === 'off'; }
  function applyRails() {
    var v = document.querySelector('.lgp-visual');
    if (v) v.classList.toggle('rails-off', railsHidden());
    var b = document.getElementById('lgpRailToggle');
    if (b) b.setAttribute('aria-label', railsHidden() ? 'Show the controls' : 'Hide the controls');
  }
  window.lgpToggleRails = function () {
    try { localStorage.setItem(RKEY, railsHidden() ? 'on' : 'off'); } catch (e) {}
    applyRails();
    if (navigator.vibrate) navigator.vibrate(12);
  };

  /* Bind after every render — the panel is rebuilt on each word and phase
     change, so the element the handlers were on is gone by then. */
  window._lgpBindRails = function () {
    applyRails();
    window.lgpSetVolume(window.lgpVolume());   /* paint the level classes */
    var rail = document.getElementById('lgpVol');
    if (!rail || rail._lgpBound) return;
    rail._lgpBound = true;
    var dragging = false;
    function fromY(clientY) {
      var r = rail.getBoundingClientRect();
      if (!r.height) return;
      /* the track fills from the BOTTOM, so 0 is at r.bottom */
      window.lgpSetVolume((r.bottom - clientY) / r.height);
    }
    rail.addEventListener('pointerdown', function (e) {
      dragging = true;
      try { rail.setPointerCapture(e.pointerId); } catch (err) {}
      fromY(e.clientY); e.preventDefault();
    });
    rail.addEventListener('pointermove', function (e) { if (dragging) { fromY(e.clientY); e.preventDefault(); } });
    function end() { dragging = false; }
    rail.addEventListener('pointerup', end);
    rail.addEventListener('pointercancel', end);
    rail.addEventListener('keydown', function (e) {
      var step = (e.key === 'ArrowUp' || e.key === 'ArrowRight') ? 0.05
               : (e.key === 'ArrowDown' || e.key === 'ArrowLeft') ? -0.05 : 0;
      if (!step) return;
      window.lgpSetVolume(window.lgpVolume() + step);
      e.preventDefault();
    });
  };
})();

/* ── Hearing one syllable ──────────────────────────────────────────────
   The boxes under the word are the pronunciation guide, and a box that has
   a recording behind it plays it when tapped. That recording is the only
   part of the guide that cannot be argued with: Devanagari shows what the
   sound is written as, the roman spelling gives something to read, and this
   is what it actually sounds like.

   One element, reused. Tapping a second box while the first is playing
   should switch to it rather than layering two voices over each other. ── */
(function () {
  var el = null;
  window.lgpSayPart = function (i) {
    var parts = window._lgpParts || [];
    var p = parts[i];
    if (!p || !p.audio) return;
    if (!el) { el = new Audio(); el.preload = 'none'; }
    try {
      el.pause();
      if (el.src !== p.audio) el.src = p.audio;
      el.currentTime = 0;
      el.volume = (typeof window.lgpVolume === 'function') ? window.lgpVolume() : 1;
      el.play().catch(function () {});
      if (navigator.vibrate) navigator.vibrate(18);
    } catch (e) {}
  };
})();
