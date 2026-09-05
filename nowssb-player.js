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
     automatically shows its organ video. Drop each R2 URL in as
     you send it (lungs first). Leave '' to keep the "coming soon"
     placeholder for organs not wired yet. ═══════════════════════════ */
  var ORGAN_VIDEOS = {
    lungs:  'assets/videos/aa7be224940a8451_grok_video_2026-07-02-16-52-38_pehfcr.mp4',   // ← lungs / breath / respiratory
    heart:  'assets/videos/9020d24aadc3adc3_grok_video_2026-07-02-16-51-54_zpffyf.mp4',   // ← heart / cardiac / circulation
    kidney: 'assets/videos/6355694c6db62e0d_grok_video_2026-07-02-16-52-19_mlfgei.mp4',   // ← kidney / renal / bladder
    liver:  'assets/videos/421bc4d59cb1bfcf_grok_video_2026-07-02-16-51-43_gilelq.mp4'    // ← liver / hepatic / detox
  };
  /* R2 on-the-fly compression — the raw grok mp4s are huge and lag /
     take forever. Inject q_auto,f_auto (+ a width cap) so R2 serves a
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
    /* The former third visual is now the first/default look for a session. */
    { img:'https://media.nowssb.com/migrated-images/d694cb3157c4e58f_grok_image_1782656710977_nj5r6x.jpg',
      video:'assets/videos/79d7c93a6734ed8d_grok_video_2026-06-28-19-55-09_otgbxd.mp4',
      accent:'#9bb8ff' },
    { img:'https://media.nowssb.com/migrated-images/3670d1e477f48c31_grok_image_1782656676834_rzp2cz.jpg',
      video:'assets/videos/a1b0a1b513ec57f6_grok_video_2026-06-28-19-54-38_wrxkgr.mp4',
      accent:'#7fe9da' },
    { img:'https://media.nowssb.com/migrated-images/fd380f5670852d0c_grok_image_1782656704854_cfsah3.jpg',
      video:'assets/videos/dc68caaf51e87003_grok_video_2026-06-28-19-55-02_of5fwh.mp4',
      accent:'#bd7bff' },
    { img:'https://media.nowssb.com/migrated-images/e8bb832f2815c15a_grok_image_1782656684101_o9vc93.jpg',
      video:'assets/videos/d8ac259577c403f3_grok_video_2026-06-28-19-54-43_it2bur.mp4',
      accent:'#a6dcff' },
    { img:'https://media.nowssb.com/migrated-images/48ad23ade254b2d7_grok_image_1782795582310_llvpix.jpg',
      video:'assets/videos/3b63edc1485a45e2_grok_video_2026-06-30-10-29-43_hzxyun.mp4',
      accent:'#b9a6ff' },
    { img:'https://media.nowssb.com/migrated-images/20314fda05d34b49_grok_image_1782796537731_vzyhwn.jpg',
      video:'assets/videos/a779a65872bf917c_grok_video_2026-06-30-10-45-45_dg2ohg.mp4',
      accent:'#a6c8ff' },
    { img:'https://media.nowssb.com/migrated-images/f734c819e92db433_grok_image_1782796641824_izkh09.jpg',
      video:'assets/videos/da4159578099ee48_grok_video_2026-06-30-10-47-20_rljghs.mp4',
      accent:'#b9a6ff' },
    { img:'https://media.nowssb.com/migrated-images/e103480a2c87d55b_grok_image_1782796519587_thrrws.jpg',
      video:'assets/videos/e55e1f1f879d8074_grok_video_2026-06-30-10-45-34_pg2y2j.mp4',
      accent:'#e8d5a3' },
    { img:'https://media.nowssb.com/migrated-images/122962572090895c_grok_image_1782796924745_nmksmi.jpg',
      video:'assets/videos/7a0e0cf6903f3b16_grok_video_2026-06-30-10-52-07_gvffol.mp4',
      accent:'#f0d9a8' },
    { img:'https://media.nowssb.com/migrated-images/28b7b32c97232472_grok_image_1782796933792_qwzfgx.jpg',
      video:'assets/videos/39905d27bd778cff_grok_video_2026-06-30-10-52-20_zk87yh.mp4',
      accent:'#8fe6ff' },
  ];

  /* Prayer/session clips alternate by active word index. Replaying a word
     keeps its clip; Next/Previous selects the next indexed clip. */
  var PRAYER_WORD_VIDEOS = [
    'grok_video_2026-09-05-15-32-08.mp4',
    'grok_video_2026-09-05-15-32-13.mp4'
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
  window.NWSB_PLAYER_VIDEO_URLS = PRAYER_WORD_VIDEOS
    .concat(LGP_THEMES.map(function (t) { return cldVid(t.video, 720); }))
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

  /* ── Real stats / profile / next-up (from actual session logs, never fake) ── */
  function lgpEsc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '\x26amp;').replace(/</g, '\x26lt;').replace(/>/g, '\x26gt;')
      .replace(/"/g, '\x26quot;').replace(/'/g, '\x26#39;');
  }
  function lgpFmtMinutes(totalMinutes) {
    var m = Math.max(0, Math.round(totalMinutes || 0));
    if (m < 60) return m + 'm';
    var h = Math.floor(m / 60);
    var r = m % 60;
    return r ? (h + 'h ' + r + 'm') : (h + 'h');
  }
  function lgpFmtClock(sec) {
    sec = Math.max(0, Math.round(Number(sec) || 0));
    var m = Math.floor(sec / 60);
    var s = sec % 60;
    return (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s;
  }
  function lgpWordSecs(word) {
    if (!word) return 321;
    var parts = (word.parts && word.parts.length) ? word.parts : [];
    var sec = 0;
    for (var i = 0; i < parts.length; i++) {
      var h = parseFloat(parts[i].hold);
      if (h > 0) sec += h;
    }
    if (sec < 8 && word.syllables && word.syllables.length) sec = word.syllables.length * 4;
    return sec < 8 ? 12 : Math.round(sec);
  }
  function lgpReadSessions() {
    var map = {};
    function ingest(obj) {
      if (!obj || typeof obj !== 'object' || Array.isArray(obj)) return;
      Object.keys(obj).forEach(function (k) {
        var e = obj[k];
        if (e && typeof e === 'object') map[k] = e;
      });
    }
    function parse(key) {
      try { ingest(JSON.parse(localStorage.getItem(key) || '{}')); } catch (e) {}
    }
    parse('nwsb_local_sessions');
    parse('nwsb_native_sessions');
    parse('nwsb_sessions_v1');
    var ud = window._userDataCache || {};
    ingest(ud.sessions);
    if (window._mpData) ingest(window._mpData.sessions);
    return map;
  }
  function lgpSessionStats() {
    var map = lgpReadSessions();
    var keys = Object.keys(map);
    var minutes = 0;
    keys.forEach(function (k) {
      var e = map[k] || {};
      if (typeof e.durationSec === 'number' && e.durationSec > 0) minutes += e.durationSec / 60;
      else if (typeof e.durationMin === 'number' && e.durationMin > 0) minutes += e.durationMin;
      else if (typeof e.repsCompleted === 'number' && e.repsCompleted > 0) minutes += (e.repsCompleted * 8) / 60;
    });
    var days = {};
    keys.forEach(function (k) {
      var e = map[k] || {};
      var d = String(e.date || k.split('_')[0] || '').slice(0, 10);
      if (/^\d{4}-\d{2}-\d{2}$/.test(d)) days[d] = true;
    });
    var iso = function (dt) {
      var y = dt.getFullYear();
      var m = String(dt.getMonth() + 1).padStart(2, '0');
      var d = String(dt.getDate()).padStart(2, '0');
      return y + '-' + m + '-' + d;
    };
    var cursor = new Date();
    if (!days[iso(cursor)]) cursor.setDate(cursor.getDate() - 1);
    var streak = 0;
    while (days[iso(cursor)] && streak < 365) {
      streak += 1;
      cursor.setDate(cursor.getDate() - 1);
    }
    return {
      streak: streak,
      sessions: keys.length,
      minutes: minutes,
      timeLabel: keys.length ? lgpFmtMinutes(minutes) : '0m',
      level: (function () {
        var earned = Math.max(1, Math.min(10, Math.floor(minutes / 30) + 1));
        try {
          var o = parseInt(localStorage.getItem('nwsb_player_level') || '', 10);
          if (o >= 1 && o <= 10) return o;
        } catch (e) {}
        return earned;
      })()
    };
  }
  function lgpUserProfile() {
    var ud = window._userDataCache || {};
    var cu = window._currentUser || {};
    var name = String(ud.displayName || cu.displayName || window._userName || '').trim();
    if (!name) name = 'Guest';
    var photo = ud.photoURL || cu.photoURL || '';
    var parts = name.split(/\s+/).filter(Boolean);
    var initials = parts.map(function (p) { return p.charAt(0); }).join('').slice(0, 2).toUpperCase() || 'G';
    return { name: name, photo: photo, initials: initials };
  }
  var _lgpLevelsOpen = false;
  function lgpSetLevel(n) {
    n = Math.max(1, Math.min(10, parseInt(n, 10) || 1));
    try { localStorage.setItem('nwsb_player_level', String(n)); } catch (e) {}
    return n;
  }
  window.lgpPlayNext = function () {
    if (typeof pwNextWord === 'function') pwNextWord();
  };
  window.lgpShuffle = function () {
    try { return localStorage.getItem('nwsb_player_shuffle') === '1'; } catch (e) { return false; }
  };
  window.lgpToggleShuffle = function () {
    var on = !window.lgpShuffle();
    try { localStorage.setItem('nwsb_player_shuffle', on ? '1' : '0'); } catch (e) {}
    var btn = document.querySelector('.lgp-mode-shuffle');
    if (btn) {
      if (on) btn.classList.add('is-on'); else btn.classList.remove('is-on');
      btn.setAttribute('aria-pressed', on ? 'true' : 'false');
    }
  };
  window.lgpGoNext = function () {
    if (window.lgpShuffle()) {
      var list = (typeof PRACTICE_WORDS !== 'undefined') ? PRACTICE_WORDS : [];
      var cur = (typeof _pwIdx !== 'undefined') ? _pwIdx : 0;
      if (list.length > 1) {
        var n = cur, guard = 0;
        while (n === cur && guard++ < 24) n = Math.floor(Math.random() * list.length);
        try { _pwIdx = n; } catch (e) {}
        if (typeof renderPractice === 'function') renderPractice();
        return;
      }
    }
    if (typeof pwNextWord === 'function') pwNextWord();
  };
  window.lgpRewind = function () {
    try {
      if (window._lgpSound) {
        window._lgpSound.t0 = (window.performance && performance.now) ? performance.now() : Date.now();
        window._lgpSound.loop = 0;
        window._lgpSound.done = false;
      }
      var fill = document.querySelector('.lgp-progress-fill');
      if (fill) fill.style.width = '0%';
      var knob = document.querySelector('.lgp-progress-knob');
      if (knob) knob.style.left = '0%';
      var t0 = document.querySelector('.lgp-time-now');
      if (t0) t0.textContent = '00:00';
      if (typeof _pwPlaying !== 'undefined' && _pwPlaying) {
        if (typeof _pwPhase !== 'undefined') _pwPhase = 'idle';
        if (typeof pwPlay === 'function') pwPlay();
      } else if (typeof pwStop === 'function') {
        try { pwStop(); } catch (e) {}
      }
    } catch (e) {}
  };
  window.lgpOpenQueue = function () {
    if (typeof openWalkmanLib === 'function') openWalkmanLib();
    else if (typeof openSub === 'function') openSub('practice');
  };
  window.lgpOpenLevel = function (force) {
    if (force === false) return;
    try { sessionStorage.setItem('nwsb_return_to_player', JSON.stringify({ts:Date.now()})); } catch (_) {}
    window.lgpOpenIntegratedPage&&window.lgpOpenIntegratedPage('select-level.html','Select Level');
    return;
    if (force === true) _lgpLevelsOpen = true;
    else if (force === false) _lgpLevelsOpen = false;
    else _lgpLevelsOpen = !_lgpLevelsOpen;
    var el = document.getElementById('lgpLevels');
    var pill = document.querySelector('.lgp-stage-level');
    if (el) {
      if (_lgpLevelsOpen) el.removeAttribute('hidden');
      else el.setAttribute('hidden', '');
    }
    if (pill) pill.setAttribute('aria-expanded', _lgpLevelsOpen ? 'true' : 'false');
  };
  window.lgpPickLevel = function (n) {
    n = lgpSetLevel(n);
    _lgpLevelsOpen = false;
    var list = document.getElementById('lgpLevels');
    if (list) list.setAttribute('hidden', '');
    var pill = document.querySelector('.lgp-stage-level');
    if (pill) pill.setAttribute('aria-expanded', 'false');
    var pillN = document.querySelector('.lgp-stage-level-n');
    if (pillN) pillN.textContent = 'Level ' + n;
    var items = list ? list.querySelectorAll('.lgp-stage-lv') : [];
    for (var i = 0; i < items.length; i++) {
      if (parseInt(items[i].getAttribute('data-level'), 10) === n) items[i].classList.add('is-on');
      else items[i].classList.remove('is-on');
    }
  };


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
    var _baseTheme = LGP_THEMES[_thIdx % LGP_THEMES.length];
    var th = {
      img: _baseTheme.img,
      video: PRAYER_WORD_VIDEOS[_thIdx % PRAYER_WORD_VIDEOS.length],
      accent: _baseTheme.accent
    };
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
        .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
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
      play:     'https://media.nowssb.com/migrated-images/74d38b3c7b69b30b_e06d2880-7389-11f1-8c74-0593c060acc9_jy24tl.png',
      pause:    'https://media.nowssb.com/migrated-images/f073aa60452e1cb9_e0723190-7389-11f1-8c74-0593c060acc9_e0lcl6.png',
      prev:     'https://media.nowssb.com/migrated-images/2f091c1083cd0b65_ad77f630-7389-11f1-8c74-0593c060acc9_pe0zco.png',
      next:     'https://media.nowssb.com/migrated-images/71a2d8954b5e6209_c5576970-7389-11f1-8c74-0593c060acc9_c4epec.png',
      replay:   'https://media.nowssb.com/migrated-images/982488a58a8e453e_file_00000000a484720aa71b5f34f8539f05_amesbb.png',
      mic:      'https://media.nowssb.com/migrated-images/a8a2eb1bb04d59d1_27cbc180-7387-11f1-ac66-23a66b2b6053_mf6jdr.png',
      library:  'https://media.nowssb.com/migrated-images/643dd804e986b5f6_3259c840-7387-11f1-ac66-23a66b2b6053_ikqafa.png',
      settings: 'https://media.nowssb.com/migrated-images/909b614a4f984b77_f90f56e0-7386-11f1-ac66-23a66b2b6053_n5ahnk.png',
      info:     'https://media.nowssb.com/migrated-images/924446cd8446dc7b_file_000000002038722fac63c79466d73f0f_jnhjvg.png',
      brand:    'https://media.nowssb.com/migrated-images/93cdeb591c49c96f_file_000000003254720aab81c7118e7cc24a_ohsba3.png',
      /* Only the two black banners use this. The top bar, the corner mark
         and the info sheet keep IC.brand — same icon there as before. */
      banner:   'https://media.nowssb.com/migrated-images/aece3225c7dc8d27_1000002027_o74vwe.png'
    };
    /* render every icon as a background-image SPAN (never an <img>) so the
       browser can't open/zoom it on tap and taps always hit the button */
    function bgi(cls, url) { return '<span class="' + cls + '" style="background-image:url(\'' + url + '\')"></span>'; }
    var playIco = bgi('lgp-img', playing ? IC.pause : IC.play);
    var prevIco = bgi('lgp-img', IC.prev);
    var nextIco = bgi('lgp-img', IC.next);
    var prevSvg = prevIco;
    var nextSvg = nextIco;
    var rewindSvg = '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="m11 12 9-5.4v10.8L11 12z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/><path d="M2 12 11 6.6v10.8L2 12z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/></svg>';
    var replayTubeSvg = '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M3.5 12a8.5 8.5 0 1 0 2.6-6.1" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><path d="M3 3v5h5" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>';
    var shuffleSvg = '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="m18 14 4 4-4 4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/><path d="m18 2 4 4-4 4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/><path d="M2 18h1.88a6 6 0 0 0 4.5-2.13l6.24-7.74A6 6 0 0 1 16.12 6H22" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/><path d="M2 6h1.88a6 6 0 0 1 4.5 2.13l6.24 7.74A6 6 0 0 0 16.12 18H22" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>';
    var repeatSvg = '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="m17 2 4 4-4 4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/><path d="M3 11V9a4 4 0 0 1 4-4h14" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/><path d="m7 22-4-4 4-4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/><path d="M21 13v2a4 4 0 0 1-4 4H3" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>';
    var queueSvg = '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M16 5H3" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><path d="M16 12H3" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><path d="M10 19H3" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><path d="M21 15V6" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><circle cx="18.5" cy="18" r="2.5" stroke="currentColor" stroke-width="1.7"/></svg>';

    /* Library (left, image icon) + Replay (right) flank the transport */
    var replaySvg = bgi('lgp-side-ico', IC.replay);
    var libSvg = bgi('lgp-side-ico', IC.library);
    var libBtn = '<button class="lgp-side" onclick="window.lgpOpenIntegratedPage&&window.lgpOpenIntegratedPage(\'sound_library_ui_world_class-3.html\',\'Sound Library\')" aria-label="Library">' + libSvg + '<span>Library</span></button>';
    var replayBtn = '<button class="lgp-side" onclick="if(typeof _pwPhase!==\'undefined\'){_pwPhase=\'idle\';}pwPlay&&pwPlay()" aria-label="Replay">' + replaySvg + '<span>Replay</span></button>';

    /* central waveform = the pair's looping video (compressed via R2).
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
    /* Same trick for the clip inside the tab under the picture. It now
       plays the current word's theme video — the same clip as the box
       above — so we only keep the element when the source still matches. */
    var _keepWaVid = null;
    (function () {
      var ex = document.getElementById('practiceBody');
      var cur = ex ? ex.querySelector('.lgp-wa-vid') : null;
      if (cur && _newVidSrc && cur.getAttribute('src') === _newVidSrc) {
        _keepWaVid = cur;
        if (cur.parentNode) cur.parentNode.removeChild(cur);
      }
    })();
    var visual = th.video
      ? (_keepVid ? '<span class="lgp-video-slot"></span>'
                  : '<video class="lgp-video" autoplay loop muted playsinline webkit-playsinline preload="auto" src="' + _newVidSrc + '"></video>')
      : '<div class="lgp-video-fallback"></div>';

    var _prof = lgpUserProfile();
    var _dur = lgpFmtClock(lgpWordSecs(w));
    var _av = _prof.photo
      ? '<img class="lgp-avatar-img" src="' + lgpEsc(_prof.photo) + '" alt="">'
      : '<span class="lgp-avatar-init">' + lgpEsc(_prof.initials) + '</span>';

    /* phase-aware center block — preserves the original IDs so play/record/score work */
    var center =
      '<div class="lgp-phase">' +
        '<div id="spPhaseIdlePlay" style="display:' + ((phase === 'idle' || phase === 'playing') ? 'flex' : 'none') + ';flex-direction:column;align-items:center;gap:10px;width:100%;">' +
          /* "Tap ▸ to listen" used to sit here. The play button says that
             already, and the bars beside the bar say when it is playing.
             The id stays on a hidden node — other code writes to it. */
          '<div class="lgp-status" id="spAutoStatus" hidden></div>' +
          '<div class="lgp-np-transport">' +
            '<div class="lgp-tube">' +
              '<button class="lgp-tube-svg lgp-mode lgp-mode-shuffle' + (window.lgpShuffle() ? ' is-on' : '') + '" type="button" onclick="window.lgpToggleShuffle&&window.lgpToggleShuffle()" aria-label="Shuffle" aria-pressed="' + (window.lgpShuffle() ? 'true' : 'false') + '">' + shuffleSvg + '</button>' +
              '<button class="lgp-ctrl" id="lgpPrev" type="button" onclick="pwPrevWord&&pwPrevWord()" ' + (idx === 0 ? 'disabled' : '') + ' aria-label="Previous">' + prevIco + '</button>' +
              '<button class="lgp-play' + (playing ? ' playing' : '') + '" id="spPlayBtn" type="button" onclick="pwTogglePlay&&pwTogglePlay()" aria-label="' + (playing ? 'Pause' : 'Play') + '">' + playIco + '</button>' +
              '<button class="lgp-ctrl" id="lgpNext" type="button" onclick="window.lgpGoNext&&window.lgpGoNext()" ' + (idx >= total - 1 && !window.lgpShuffle() ? 'disabled' : '') + ' aria-label="Next">' + nextIco + '</button>' +
              '<button class="lgp-tube-svg lgp-mode lgp-mode-repeat' + (loop ? ' is-on' : '') + '" type="button" onclick="pwToggleLoop&&pwToggleLoop();renderPractice&&renderPractice()" aria-label="Repeat" aria-pressed="' + (loop ? 'true' : 'false') + '">' + repeatSvg + '</button>' +
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
    var arc = '';

    /* ── INFO PANEL — full-screen liquid-glass overlay opened from the ⓘ icon
       on the video. Shows an organ-specific video (wired later per word via
       w.organVideo — falls back to a placeholder for now), then what's
       happening in the body, the word's meaning, and the practitioner's
       results for this word. Icons are plain inline SVG for now — real
       image icons come later, same as the rest of the player. ── */
    /* NOTE: no autoplay + preload="none" — the info video must NOT load or play
       while the panel is closed (it was loading hidden on every render and
       fighting the main player video for bandwidth). It's started on open by
       lgpToggleInfo, paused/reset on close. Also compressed via R2. */
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
              '<span class="lgp-bgico" style="background-image:url(\'https://media.nowssb.com/migrated-images/7ee8439eec0e17a8_file_00000000ae6071fa982c6eec401328c6_uvgfjs.png\')"></span>' +
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
            : (_newVidSrc
                ? '<video class="lgp-wa-vid" muted playsinline autoplay loop preload="auto" aria-hidden="true"' +
                  ' src="' + _newVidSrc + '"></video>'
                : '')) +
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
          '<button class="lgp-back lgp-now-btn" onclick="closeSub&&closeSub(\'practice\')" aria-label="Back">' +
            '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
              '<path d="M6 9l6 6 6-6" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>' +
            '</svg>' +
          '</button>' +
          '<div class="lgp-now" aria-hidden="true"><span>Now Playing</span><i></i></div>' +
          '<div class="lgp-top-right">' +
            '<button class="lgp-settings lgp-now-btn" type="button" aria-label="More">' +
              '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><circle cx="5" cy="12" r="1.7"/><circle cx="12" cy="12" r="1.7"/><circle cx="19" cy="12" r="1.7"/></svg>' +
            '</button>' +
          '</div>' +
        '</div>' +
        (function () {
          var st = lgpSessionStats();
          return '<div class="lgp-stats-tab"><div class="lgp-stats" id="lgpStats">' +
            '<div class="lgp-stat"><div class="lgp-stat-num" id="lgpStatStreak">' + st.streak + '</div><div class="lgp-stat-lbl">Days Streak</div></div>' +
            '<div class="lgp-stat"><div class="lgp-stat-num" id="lgpStatSessions">' + st.sessions + '</div><div class="lgp-stat-lbl">Sessions</div></div>' +
            '<div class="lgp-stat"><div class="lgp-stat-num" id="lgpStatTime">' + st.timeLabel + '</div><div class="lgp-stat-lbl">Time Meditated</div></div>' +
          '</div></div>';
        })() +
        '<div class="lgp-visual">' +
          visual +
          '<div class="lgp-art-photo" style="background-image:url(\'' + th.img + '\')"></div>' +
          '<div class="lgp-art-shade" aria-hidden="true"></div>' +
          (function () {
            var st = lgpSessionStats();
            var cur = st.level;
            var star = '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 2.4l2.2 6.6H21l-5.4 4 2.1 6.6L12 15.8 6.3 19.6l2.1-6.6L3 9h6.8z"/></svg>';
            var items = '';
            for (var i = 1; i <= 10; i++) {
              items += (i > 1 ? '<span class="lgp-stage-sep" aria-hidden="true"></span>' : '') +
                '<button class="lgp-stage-lv' + (i === cur ? ' is-on' : '') + '" type="button" data-level="' + i + '"' +
                ' onclick="window.lgpPickLevel&&window.lgpPickLevel(' + i + ')">' + star + '<span>Level ' + i + '</span></button>';
            }
            return '' +
              '<button class="lgp-stage-level" type="button" onclick="window.lgpOpenLevel&&window.lgpOpenLevel()" aria-label="Level ' + cur + '" aria-expanded="' + (_lgpLevelsOpen ? 'true' : 'false') + '">' +
                star + '<span class="lgp-stage-level-n">Level ' + cur + '</span>' +
              '</button>' +
              '<div class="lgp-stage-glass">' +
                '<button type="button" onclick="window.lgpOpenIntegratedPage&&window.lgpOpenIntegratedPage(\'player-settings.html\',\'Music Player Settings\')" aria-label="Settings">' +
                  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>' +
                '</button>' +
                '<button type="button" onclick="window.lgpToggleInfo&&window.lgpToggleInfo()" aria-label="Word info">' +
                  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><path d="M12 17h.01"/></svg>' +
                '</button>' +
              '</div>' +
              '<div class="lgp-stage-sheet" id="lgpLevels"' + (_lgpLevelsOpen ? '' : ' hidden') + '>' +
                '<div class="lgp-stage-sheet-top">' +
                  '<p>LEVEL</p>' +
                  '<button type="button" class="lgp-stage-close" onclick="window.lgpOpenLevel&&window.lgpOpenLevel(false)" aria-label="Close">' +
                    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="M18 6 6 18M6 6l12 12"/></svg>' +
                  '</button>' +
                '</div>' +
                '<div class="lgp-stage-list">' + items + '</div>' +
              '</div>';
          })() +
          '<div class="lgp-visual-overlay">' +
            '<p class="lgp-art-kicker">' + _e(String(w.word || '').toUpperCase()) + '</p>' +
            '<div class="lgp-wordblock">' +
              (w.deva ? '<div class="lgp-deva nwsb-deva">' + _e(w.deva) + '</div>' : '') +
              '<div class="lgp-syls">' + syl + '</div>' +
              '<div class="lgp-organ">' + (w.organ || '') + '</div>' +
            '</div>' +
            '<div class="lgp-acts">' +
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
            '</div>' +
          '</div>' +
          '<div class="lgp-info-cluster" id="lgpInfoCluster">' +
            '<div class="lgp-info-pill"><span class="lgp-info-pill-txt" id="lgpInfoPillTxt">Learn more</span></div>' +
            '<button class="lgp-info-btn" onclick="window.lgpToggleInfo&&window.lgpToggleInfo()" aria-label="Word info">' +
              '<span class="lgp-bgico" style="background-image:url(\'' + IC.info + '\')"></span>' +
            '</button>' +
          '</div>' +
        '</div>' +
        '<div class="lgp-np-meta">' +
          '<div class="lgp-title-row">' +
            '<h1 class="lgp-np-name">' + _e(w.word || '') + '</h1>' +
            '<button class="lgp-heart lgp-like' + (lgpIsLiked(w.word) ? ' liked' : '') + '" id="lgpLikeBtn" type="button"' +
              ' onclick="window.lgpToggleLike&&window.lgpToggleLike()"' +
              ' aria-pressed="' + (lgpIsLiked(w.word) ? 'true' : 'false') + '" aria-label="Like this word">' +
              '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 20.2 4.6 13a4.6 4.6 0 0 1 6.5-6.5l.9.9.9-.9A4.6 4.6 0 0 1 19.4 13z"/></svg>' +
            '</button>' +
          '</div>' +
          '<p class="lgp-np-sub">NowssB<span aria-hidden="true"> · </span>Words Without Dictionary</p>' +
        '</div>' +
        '<div class="lgp-progress" role="slider" tabindex="0" aria-label="Playback position" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0">' +
          '<div class="lgp-bar"><i class="lgp-progress-fill"></i><span class="lgp-progress-knob" style="left:0%"></span></div>' +
          '<div class="lgp-times"><span class="lgp-time-now">00:00</span><span class="lgp-time-end">' + _dur + '</span></div>' +
        '</div>' +
        center +
        (function () {
          var next = words[idx + 1];
          if (!next) {
            return '<div class="lgp-nextup" id="lgpNextUp">' +
              '<div class="lgp-nextup-grab" aria-hidden="true"></div>' +
              '<div class="lgp-nextup-head"><span>Up Next</span>' +
                '<button class="lgp-queue-btn" type="button" onclick="window.lgpOpenIntegratedPage&&window.lgpOpenIntegratedPage(\'sound-library-4-3.html\',\'Sound Library\')" aria-label="Queue">' + queueSvg + '</button>' +
              '</div>' +
              '<div class="lgp-nextup-line" aria-hidden="true"></div>' +
              '<p class="lgp-nextup-empty">End of queue</p>' +
            '</div>';
          }
          var art = next.img || th.img || '';
          var nextDur = lgpFmtClock(lgpWordSecs(next));
          return '<div class="lgp-nextup" id="lgpNextUp">' +
            '<div class="lgp-nextup-grab" aria-hidden="true"></div>' +
            '<div class="lgp-nextup-head"><span>Up Next</span>' +
              '<button class="lgp-queue-btn" type="button" onclick="event.stopPropagation();window.lgpOpenIntegratedPage&&window.lgpOpenIntegratedPage(\'sound-library-4-3.html\',\'Sound Library\')" aria-label="Queue">' + queueSvg + '</button>' +
            '</div>' +
            '<div class="lgp-nextup-line" aria-hidden="true"></div>' +
            '<button class="lgp-nextup-item" type="button" onclick="window.lgpPlayNext&&window.lgpPlayNext()">' +
              '<span class="lgp-nextup-art"' + (art ? ' style="background-image:url(\'' + lgpEsc(art) + '\')"' : '') + '></span>' +
              '<span class="lgp-nextup-mid">' +
                '<b>' + lgpEsc(next.word || '') + '</b>' +
                '<em>NowssB<span aria-hidden="true"> · </span>' + nextDur + '</em>' +
              '</span>' +
              '<span class="lgp-nextup-play" aria-hidden="true">' +
                '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8.2 5.4v13.2L19 12z"/></svg>' +
              '</span>' +
            '</button>' +
          '</div>';
        })() +
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
      v.muted = true; v.defaultMuted = true; v.loop = true; v.playsInline = true;
      v.setAttribute('muted', ''); v.setAttribute('playsinline', 'true');
      v.setAttribute('webkit-playsinline', 'true'); v.setAttribute('autoplay', '');
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
        var knob = document.querySelector('.lgp-progress-knob');
        if (knob) knob.style.left = p + '%';
        var bar = el.parentNode && el.parentNode.parentNode;
        if (bar && bar.setAttribute) bar.setAttribute('aria-valuenow', Math.round(p));
        var S = window._lgpSound;
        var durMs = S ? (S.dur || S.est || 2000) : (lgpWordSecs(w) * 1000);
        if (S && S.total) durMs = (S.dur || S.est || 2000) * S.total;
        var t0 = document.querySelector('.lgp-time-now');
        var t1 = document.querySelector('.lgp-time-end');
        if (t0) t0.textContent = lgpFmtClock((durMs * p) / 100000);
        if (t1) t1.textContent = lgpFmtClock(durMs / 1000);
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
      var gear = t && (t.closest ? t.closest('.lgp-stage-glass button[aria-label="Settings"]') : null);
      if (gear) {
        e.preventDefault(); e.stopPropagation();
        try { sessionStorage.setItem('nwsb_return_to_player', JSON.stringify({ts:Date.now()})); } catch (_) {}
        window.lgpOpenIntegratedPage&&window.lgpOpenIntegratedPage('player-settings.html','Music Player Settings');
        return;
      }
      var hit = t && (t.closest ? t.closest('.lgp-settings') : null);
      if (hit) { e.preventDefault(); e.stopPropagation(); window.lgpOpenIntegratedPage&&window.lgpOpenIntegratedPage('aura-player.html','AURA Player'); }
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

/* UP NEXT grab handle: an upward swipe opens the future tab surface. */
(function () {
  if (window._lgpNextUpSwipeBound) return;
  window._lgpNextUpSwipeBound = true;
  var y0 = null;
  document.addEventListener('touchstart', function (e) {
    var card = e.target && e.target.closest ? e.target.closest('.lgp-nextup') : null;
    if (card) y0 = e.touches && e.touches[0] ? e.touches[0].clientY : null;
  }, {passive: true});
  document.addEventListener('touchend', function (e) {
    if (y0 == null) return;
    var y1 = e.changedTouches && e.changedTouches[0] ? e.changedTouches[0].clientY : y0;
    if (y0 - y1 > 48) {
      var card = e.target && e.target.closest ? e.target.closest('.lgp-nextup') : document.getElementById('lgpNextUp');
      if (card) window.lgpOpenIntegratedPage&&window.lgpOpenIntegratedPage('sound-library-4-3.html','Sound Library');
    }
    y0 = null;
  }, {passive: true});
})();


/* Unified Sound Library 4-3 expansion panel for UP NEXT and its grab handle. */
(function () {
  if (window.lgpOpenSoundLibrary43) return;
  window.lgpOpenSoundLibrary43 = function (origin) {
    if (document.getElementById('lgpSoundLibrary43Sheet')) return;
    var sheet = document.createElement('div');
    sheet.id = 'lgpSoundLibrary43Sheet';
    sheet.className = 'lgp-sound-library-43-sheet';
    sheet.innerHTML = '<div class="lgp-sound-library-43-backdrop"></div>' +
      '<div class="lgp-sound-library-43-panel" role="dialog" aria-label="Sound Library">' +
      '<div class="lgp-sound-library-43-grab"></div>' +
      '<button class="lgp-sound-library-43-close" aria-label="Close">×</button>' +
      '<iframe title="Sound Library 4-3" src="sound-library-4-3.html?from=expanded" loading="eager"></iframe>' +
      '</div>';
    document.body.appendChild(sheet);
    requestAnimationFrame(function () { sheet.classList.add('is-open'); });
    sheet.querySelector('.lgp-sound-library-43-close').onclick = function () { sheet.classList.remove('is-open'); setTimeout(function(){sheet.remove();}, 340); };
    sheet.querySelector('.lgp-sound-library-43-backdrop').onclick = function () { sheet.querySelector('.lgp-sound-library-43-close').click(); };
  };
})();

(function(){
  window.lgpCloseIntegratedPage=function(){var x=document.getElementById('lgpIntegratedPageSheet');if(!x)return;x.classList.remove('is-open');setTimeout(function(){x.remove();},360);};
  window.lgpOpenIntegratedPage=function(file,title){window.lgpCloseIntegratedPage();var x=document.createElement('div');x.id='lgpIntegratedPageSheet';x.className='lgp-integrated-sheet';x.innerHTML='<div class="lgp-integrated-backdrop"></div><div class="lgp-integrated-panel" role="dialog" aria-label="'+title+'"><div class="lgp-integrated-grab"></div><button class="lgp-integrated-close" aria-label="Back to Player">‹</button><iframe title="'+title+'" src="'+file+'?from=player-sheet" loading="eager"></iframe></div>';document.body.appendChild(x);requestAnimationFrame(function(){x.classList.add('is-open');});x.querySelector('.lgp-integrated-close').onclick=window.lgpCloseIntegratedPage;x.querySelector('.lgp-integrated-backdrop').onclick=window.lgpCloseIntegratedPage;};
  window.addEventListener('message',function(e){if(e.data&&e.data.type==='close-player-sheet')window.lgpCloseIntegratedPage();});
})();
