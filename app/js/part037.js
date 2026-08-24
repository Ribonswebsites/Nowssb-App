
/* ═══════════════════════════════════════════════
   AI DAILY WORD PRESCRIPTION
═══════════════════════════════════════════════ */
(function(){
  var STORE_KEY = 'nowssb_rx_v1';
  var HOUR_LABELS = { morning:'Morning Ritual', midday:'Midday Boost',
    afternoon:'Afternoon Session', evening:'Evening Practice', night:'Night Restoration' };

  function getTimeSlot(){
    var h = new Date().getHours();
    if (h < 10) return 'morning';
    if (h < 13) return 'midday';
    if (h < 17) return 'afternoon';
    if (h < 20) return 'evening';
    return 'night';
  }

  function todayKey(){ return new Date().toISOString().split('T')[0]; }

  function loadCached(){
    try {
      var d = JSON.parse(localStorage.getItem(STORE_KEY)||'{}');
      if (d.date === todayKey() && d.words && d.words.length) return d;
    } catch(e){}
    return null;
  }

  function saveCache(data){
    try { localStorage.setItem(STORE_KEY, JSON.stringify(Object.assign({ date: todayKey() }, data))); } catch(e){}
  }

  // Smart static fallback when Groq key not set
  function staticPrescription(){
    var slot = getTimeSlot();
    // MASTER_WORD_LIBRARY is a script-level const (NOT on window) — reach it via
    // typeof so this never sees an empty library and crashes the rx card.
    var lib = (typeof MASTER_WORD_LIBRARY !== 'undefined' && MASTER_WORD_LIBRARY) || window.MASTER_WORD_LIBRARY || [];
    var timeWords = lib.filter(function(w){ return w.time === slot || w.time === 'any'; });
    if (timeWords.length < 3) timeWords = lib;
    if (!timeWords.length) timeWords = [
      { word:'AAROGYA', organ:'Immune System', phonetic:'aa · ro · gyaa' },
      { word:'PRANA',   organ:'Lungs · Heart', phonetic:'praa · naa' },
      { word:'SHAKTI',  organ:'Solar Plexus',  phonetic:'shak · ti' }
    ];
    // Pick 3 deterministically by day-of-year
    var doy = Math.floor((Date.now() - new Date(new Date().getFullYear(),0,0)) / 86400000);
    var picks = [];
    for (var i=0; i<3; i++){
      picks.push(timeWords[(doy + i * 3) % timeWords.length]);
    }
    return {
      words: picks.map(function(w){ return {
        word: w.word, organ: w.organ, phonetic: w.phonetic,
        why: 'Targeted for ' + slot + ' healing.'
      };}),
      reason: 'Your ' + slot + ' prescription — aligned to your current time and healing goals.',
      slot: slot
    };
  }

  async function fetchGroqPrescription(){
    // The key stays in Cloudflare. The browser only calls the shared Worker.
    if (typeof GROQ_CHAT_URL === 'undefined') return null;

    var slot = getTimeSlot();
    var lib  = (typeof MASTER_WORD_LIBRARY !== "undefined" && MASTER_WORD_LIBRARY) || window.MASTER_WORD_LIBRARY || [];
    var wordList = lib.map(function(w){ return w.word + '(' + w.organ + ')'; }).join(', ');

    // Build user context
    var sessions = {};
    try {
      var ud = window._userDataCache;
      if (ud && ud.sessions) sessions = ud.sessions;
    } catch(e){}
    var practiced = Object.keys(sessions).map(function(k){ return k.split('_').slice(1).join('_'); });
    var recentSet = practiced.slice(-20);

    var prompt = 'You are a Shabdapathy word prescription system. Given available words and user context, prescribe exactly 3 words for today\'s ' + slot + ' practice. Respond ONLY in JSON: {"words":[{"word":"WORDNAME","why":"one short reason"},{"word":"WORDNAME","why":"one short reason"},{"word":"WORDNAME","why":"one short reason"}],"reason":"one sentence why these 3 today"}. Available words: ' + wordList + '. Recently practiced: ' + (recentSet.join(', ')||'none') + '. Time: ' + slot + '. Prioritize words they haven\'t practiced recently. Keep why under 8 words each.';

    try {
      var resp = await fetch(GROQ_CHAT_URL, {
        method: 'POST',
        headers: { 'Content-Type':'application/json' },
        body: JSON.stringify({
          model: 'openai/gpt-oss-20b',
          messages: [{ role:'user', content: prompt }],
          max_tokens: 300, temperature: 0.7
        })
      });
      if (!resp.ok) return null;
      var json = await resp.json();
      var raw = json.choices?.[0]?.message?.content;
      if (!raw) return null;
      raw = raw.replace(/```json|```/g,'').trim();
      var parsed = JSON.parse(raw);
      // Enrich with organ from library
      parsed.words = parsed.words.map(function(pw){
        var match = lib.find(function(lw){ return lw.word === pw.word; });
        return Object.assign({ organ: match ? match.organ : '', phonetic: match ? match.phonetic : '' }, pw);
      });
      parsed.slot = slot;
      return parsed;
    } catch(e){ return null; }
  }

  /* The banner at the top of the card is a clip, not a still. .rx-banner
     in app/app.css is width/height/object-fit:cover, which a <video>
     answers exactly as an <img> does, so the box did not change — only
     what is in it.

     data-nwsb-auto hands it to the play controller in app/js/part051.js:
     preload="none" until it is scrolled to, played only while it is on
     screen, and counted against the cap on how many clips run at once. */
  // Render the card into #rxCardWrap
  function render(data){
    var wrap = document.getElementById('rxCardWrap');
    if (!wrap) return;
    var slot = data.slot || getTimeSlot();
    var timeLabel = HOUR_LABELS[slot] || 'Today\'s Prescription';

    wrap.innerHTML =
      '<div class="rx-card">'+
        '<video class="rx-banner" data-nwsb-auto muted loop playsinline preload="none" '+
          'aria-hidden="true" tabindex="-1" onclick="openSub(\'ai-prescription\')" '+
          'src="https://nowssb-api.ribonpatil2.workers.dev/media/media/repo/assets/video/rx-banner.mp4?v=1"></video>'+
        '<div class="rx-header" onclick="openSub(\'ai-prescription\')" style="cursor:pointer;">'+
          '<div class="rx-header-left">'+
            '<div class="rx-ai-dot"></div>'+
            '<span class="rx-label">AI Prescription</span>'+
          '</div>'+
          '<span class="rx-time-badge">'+timeLabel+'</span>'+
        '</div>'+
        '<div class="rx-reason">"'+data.reason+'"</div>'+
        '<div class="rx-words">'+
          data.words.map(function(w){
            return '<div class="rx-word-pill" onclick="rxStartWord(\''+w.word+'\')">'+
              '<div class="rx-word-name">'+w.word+'</div>'+
              '<div class="rx-word-organ">'+(w.organ||'')+'</div>'+
              '<div class="rx-word-why">'+w.why+'</div>'+
            '</div>';
          }).join('')+
        '</div>'+
        '<div class="rx-footer">'+
          '<span class="rx-cta-text">Tap word to practice</span>'+
          '<div class="rx-start-btn" onclick="openSub(\'ai-prescription\')">'+
            '<span class="rx-start-label">Enter</span>'+
            '<svg width="12" height="12" viewBox="0 0 14 14" fill="none"><path d="M3 7H11M7 3L11 7L7 11" stroke="#e8d5a3" stroke-width="1.5" stroke-linecap="square"/></svg>'+
          '</div>'+
        '</div>'+
      '</div>';
  }

  function renderLoading(){
    var wrap = document.getElementById('rxCardWrap');
    if (!wrap) return;
    wrap.innerHTML =
      '<div class="rx-card">'+
        '<video class="rx-banner" data-nwsb-auto muted loop playsinline preload="none" '+
          'aria-hidden="true" tabindex="-1" onclick="openSub(\'ai-prescription\')" '+
          'src="https://nowssb-api.ribonpatil2.workers.dev/media/media/repo/assets/video/rx-banner.mp4?v=1"></video>'+
        '<div class="rx-header">'+
          '<div class="rx-header-left"><div class="rx-ai-dot"></div><span class="rx-label">AI Prescription</span></div>'+
          '<span class="rx-time-badge">Building your ritual…</span>'+
        '</div>'+
        '<div class="rx-shimmer-row">'+
          '<div class="rx-shimmer-block"></div>'+
          '<div class="rx-shimmer-block"></div>'+
          '<div class="rx-shimmer-block"></div>'+
        '</div>'+
      '</div>';
  }

  // Start a single word — load it into player and enter practice directly
  // (no intro screen, no detour through the active routine's own words).
  //
  // This used to call a `setPracticeWords` function that doesn't exist
  // anywhere in the app (always silently false), so it fell through to
  // openPracticeIntro() instead — which loads the ACTIVE ROUTINE's words
  // (not the one word tapped here) and forces the intro screen. Assigning
  // PRACTICE_WORDS directly + _rtManualLaunch=true is the same mechanism
  // openPracticeIntro() itself uses, minus the parts that were wrong here.
  window.rxStartWord = function(wordName){
    var lib = (typeof MASTER_WORD_LIBRARY !== "undefined" && MASTER_WORD_LIBRARY) || window.MASTER_WORD_LIBRARY || [];
    var w = lib.find(function(x){ return x.word === wordName; });
    if (!w) return;
    /* The session is the word's own family, opened AT the tapped word —
       not the tapped word alone. A one-word session is "1 of 1", which
       leaves Next permanently greyed out: the player looked broken when it
       was only being honest about having nowhere to go. Next now walks the
       words that share this one's first category, which is the same set
       the category page would have started. */
    var cat = (w.categories && w.categories[0]) || '';
    var fam = cat ? lib.filter(function(x){ return x.categories && x.categories.indexOf(cat) !== -1; }) : [];
    if (fam.length < 2) fam = lib.slice();
    var at = fam.indexOf(w);
    if (at < 0) { fam = [w].concat(fam); at = 0; }
    PRACTICE_WORDS = fam;
    _pwIdx = at; _pwRepCount = 0; _pwDone = false;
    window._rtStartIdx = at;      /* openSub('practice') resets _pwIdx — this survives it */
    window._rtManualLaunch = true;
    if (typeof openSub === 'function') openSub('practice');
  };

  // Start all 3 as a mini-routine — same fix as rxStartWord above.
  window.rxStartAll = function(words){
    var lib = (typeof MASTER_WORD_LIBRARY !== "undefined" && MASTER_WORD_LIBRARY) || window.MASTER_WORD_LIBRARY || [];
    var wordObjs = words.map(function(pw){
      return lib.find(function(lw){ return lw.word === pw.word; }) || { word:pw.word, phonetic:pw.word.toLowerCase(), syllables:[pw.word.toLowerCase()], organ:pw.organ||'', origin:'', benefit:'', meaning:'', mouthPos:'', resonance:'', mistake:'', tip:'' };
    }).filter(Boolean);
    if (wordObjs.length) {
      PRACTICE_WORDS = wordObjs;
      window._rtManualLaunch = true;
    }
    if (typeof openSub === 'function') openSub('practice');
  };

  // Shared data pipeline — cache check, Groq fetch with static fallback, save.
  // Exposed so the full AI Prescription page (app/js/part053.js) reuses the
  // exact same real recommendations instead of duplicating/faking this logic.
  window.rxGetData = async function(forceRefresh){
    if (!forceRefresh){
      var cached = loadCached();
      if (cached) return cached;
    }
    var data = await fetchGroqPrescription();
    if (!data) data = staticPrescription();
    saveCache(data);
    return data;
  };

  // Main init — called on home load
  window.rxInit = async function(){
    var cached = loadCached();
    if (cached){ render(cached); return; }

    renderLoading();
    var data = await window.rxGetData();
    render(data);
  };

  // Auto-refresh when switching to home screen
  var _origShowScreen = window.showScreen;
  if (typeof _origShowScreen === 'function'){
    window.showScreen = function(id){
      var r = _origShowScreen.apply(this, arguments);
      if (id === 'home') setTimeout(window.rxInit, 80);
      return r;
    };
  }
})();
