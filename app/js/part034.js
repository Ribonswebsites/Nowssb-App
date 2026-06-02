
/* ═══════════════════════════════════════════════
   SOUND BATH CONTROLLER
═══════════════════════════════════════════════ */
(function(){
  var SB = {
    playing: false,
    mode: 'sleep',
    ambient: 'none',
    timerMins: 0,
    timerRemain: 0,
    timerInterval: null,
    volume: 0.70,
    utterances: [],
    wordIdx: 0,
    wordInterval: null,
    ambientCtx: null,
    ambientNodes: [],
  };

  var MODES = {
    sleep: {
      title: 'Sleep Mode',
      desc: 'Words soften the nervous system. Let your body absorb the frequency without effort.',
      accent: 'rgba(180,160,255,0.8)',
      glow:   'rgba(180,160,255,0.3)',
      discBg: 'rgba(180,160,255,0.12)',
      bgTop:  'rgba(100,80,200,0.12)',
      bgBot:  'rgba(60,40,140,0.10)',
      rate: 0.65, pitch: 1.05,
    },
    focus: {
      title: 'Focus Mode',
      desc: 'Clear, precise frequencies that sharpen attention and build mental resonance.',
      accent: 'rgba(200,232,245,0.9)',
      glow:   'rgba(200,232,245,0.3)',
      discBg: 'rgba(200,232,245,0.12)',
      bgTop:  'rgba(40,120,200,0.10)',
      bgBot:  'rgba(20,80,160,0.08)',
      rate: 0.80, pitch: 0.95,
    },
    healing: {
      title: 'Healing Mode',
      desc: 'Gold-frequency words loop continuously. Organs resonate. No action required.',
      accent: 'rgba(232,213,163,0.9)',
      glow:   'rgba(232,213,163,0.35)',
      discBg: 'rgba(232,213,163,0.15)',
      bgTop:  'rgba(180,140,40,0.10)',
      bgBot:  'rgba(140,100,20,0.08)',
      rate: 0.72, pitch: 0.88,
    },
  };

  var BATH_WORDS = [
    'AAROGYA','PRANA','SHAKTI','ANANDA','SOMA',
    'TEJAS','OJAS','SURYA','CHANDRA','VATA'
  ];

  // Pull real words from player if available
  function getBathWords(){
    if (window.PRACTICE_WORDS && window.PRACTICE_WORDS.length > 0)
      return window.PRACTICE_WORDS.map(function(w){ return w.word; });
    return BATH_WORDS;
  }

  function applyMode(m){
    SB.mode = m;
    var cfg = MODES[m];
    var player = document.getElementById('sbPlayer');
    if (player){
      player.style.setProperty('--sb-accent', cfg.accent);
      player.style.setProperty('--sb-glow',   cfg.glow);
      player.style.setProperty('--sb-disc-bg', cfg.discBg);
    }
    var bg = document.getElementById('sbPlayerBg');
    if (bg){
      bg.style.background =
        'radial-gradient(ellipse at 50% 0%, '+cfg.bgTop+' 0%, transparent 70%), '+
        'radial-gradient(ellipse at 20% 100%, '+cfg.bgBot+' 0%, transparent 60%), #060c18';
    }
    // Update labels
    var t=document.getElementById('sbModeTitle'), d=document.getElementById('sbModeDesc');
    if (t) t.textContent = cfg.title;
    if (d) d.textContent = cfg.desc;
    // Update tab active states
    ['sleep','focus','healing'].forEach(function(k){
      var el=document.getElementById('sbMode-'+k);
      if (el) el.classList.toggle('active', k===m);
    });
  }

  function updateTimerDisplay(){
    var el = document.getElementById('sbTimerDisplay');
    if (!el) return;
    if (SB.timerMins === 0){ el.textContent = '∞'; return; }
    var m = Math.floor(SB.timerRemain/60), s = SB.timerRemain%60;
    el.textContent = m+':'+(s<10?'0':'')+s;
  }

  function speakNext(){
    if (!SB.playing) return;
    if (typeof speechSynthesis === 'undefined') return;
    var words = getBathWords();
    var word = words[SB.wordIdx % words.length];
    SB.wordIdx++;
    var utt = new SpeechSynthesisUtterance(word);
    var cfg = MODES[SB.mode];
    utt.rate  = cfg.rate  * (window._pwSpeed||1);
    utt.pitch = cfg.pitch;
    utt.volume= SB.volume;
    speechSynthesis.speak(utt);
    // Schedule next word — longer pause for sleep
    var pause = SB.mode==='sleep' ? 6000 : SB.mode==='focus' ? 3500 : 5000;
    SB.wordInterval = setTimeout(speakNext, pause + (word.length*120));
  }

  function startPlayback(){
    SB.playing = true;
    SB.wordIdx = 0;
    // Animate disc + wave
    var disc=document.getElementById('sbDisc'), wave=document.getElementById('sbWave');
    if (disc) disc.classList.add('playing');
    if (wave) wave.classList.remove('paused');
    // Play icon → pause
    var icon=document.getElementById('sbPlayIcon');
    if (icon){
      icon.innerHTML='<rect x="6" y="4" width="4" height="16" rx="1"/><rect x="14" y="4" width="4" height="16" rx="1"/>';
    }
    var btn=document.getElementById('sbPlayBtn');
    if (btn) btn.classList.add('playing');
    speakNext();
    // Timer countdown
    if (SB.timerMins > 0){
      SB.timerRemain = SB.timerMins * 60;
      SB.timerInterval = setInterval(function(){
        SB.timerRemain--;
        updateTimerDisplay();
        if (SB.timerRemain <= 0){ sbStop(); }
      }, 1000);
    }
  }

  function sbStop(){
    SB.playing = false;
    clearTimeout(SB.wordInterval);
    clearInterval(SB.timerInterval);
    if (typeof speechSynthesis !== 'undefined') speechSynthesis.cancel();
    var disc=document.getElementById('sbDisc'), wave=document.getElementById('sbWave');
    if (disc) disc.classList.remove('playing');
    if (wave) wave.classList.add('paused');
    var icon=document.getElementById('sbPlayIcon');
    if (icon) icon.innerHTML='<polygon points="5 3 19 12 5 21 5 3"/>';
    var btn=document.getElementById('sbPlayBtn');
    if (btn) btn.classList.remove('playing');
    updateTimerDisplay();
  }

  /* Public functions */
  window.sbEnter = function(){
    var intro=document.getElementById('sbIntro'), player=document.getElementById('sbPlayer');
    if (intro) intro.classList.add('sb-hidden');
    if (player) setTimeout(function(){ player.classList.add('sb-active'); }, 120);
    applyMode('sleep');
  };

  window.sbClose = function(){
    sbStop();
    var intro=document.getElementById('sbIntro'), player=document.getElementById('sbPlayer');
    if (player) player.classList.remove('sb-active');
    if (intro) setTimeout(function(){ intro.classList.remove('sb-hidden'); }, 120);
    setTimeout(function(){ closeSub('sound-bath'); }, 400);
  };

  window.sbTogglePlay = function(){
    if (SB.playing) sbStop(); else startPlayback();
  };

  window.sbSetMode = function(m){ applyMode(m); if(SB.playing){ sbStop(); startPlayback(); } };

  window.sbSetTimer = function(mins, el){
    SB.timerMins = mins;
    SB.timerRemain = mins * 60;
    document.querySelectorAll('.sb-timer-btn').forEach(function(b){ b.classList.remove('active'); });
    if (el) el.classList.add('active');
    updateTimerDisplay();
  };

  window.sbSetAmbient = function(type, el){
    SB.ambient = type;
    document.querySelectorAll('.sb-ambient-btn').forEach(function(b){ b.classList.remove('active'); });
    if (el) el.classList.add('active');
    // Note: real ambient audio needs Cloudflare R2 URLs from Ribon
    // Using Web Audio API tone as placeholder
    sbPlayAmbientTone(type);
  };

  window.sbSetVolume = function(v){
    SB.volume = v/100;
  };

  function sbPlayAmbientTone(type){
    // Stop existing ambient
    SB.ambientNodes.forEach(function(n){ try{ n.stop(); }catch(e){} });
    SB.ambientNodes = [];
    if (type==='none' || !window.AudioContext && !window.webkitAudioContext) return;
    try {
      if (!SB.ambientCtx) SB.ambientCtx = new (window.AudioContext||window.webkitAudioContext)();
      var ctx = SB.ambientCtx;
      // Create subtle brown noise (low rumble) as ambient placeholder
      var bufSize = ctx.sampleRate * 2;
      var buf = ctx.createBuffer(1, bufSize, ctx.sampleRate);
      var data = buf.getChannelData(0);
      var lastOut = 0;
      for (var i=0; i<bufSize; i++){
        var white = (Math.random()*2-1);
        data[i] = (lastOut + (.02*white)) / 1.02;
        lastOut = data[i];
        data[i] *= 3.5;
      }
      var src = ctx.createBufferSource();
      src.buffer = buf; src.loop = true;
      var gain = ctx.createGain();
      gain.gain.value = SB.volume * 0.12;
      var filter = ctx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.value = type==='rain'?2400:type==='ocean'?800:type==='forest'?1600:400;
      src.connect(filter); filter.connect(gain); gain.connect(ctx.destination);
      src.start();
      SB.ambientNodes.push(src);
    } catch(e){}
  }

  // Reset when sub-screen opens
  var _sbOrig = window.openSub;
  if (typeof _sbOrig === 'function'){
    window.openSub = function(id){
      if (id === 'sound-bath' && window.GATE && !window.GATE.check('resonance')) return;
      var r = _sbOrig.apply(this, arguments);
      if (id === 'sound-bath'){
        sbStop();
        var intro=document.getElementById('sbIntro'), player=document.getElementById('sbPlayer');
        if (intro){ intro.style.opacity=''; intro.classList.remove('sb-hidden'); }
        if (player) player.classList.remove('sb-active');
      }
      return r;
    };
  }
})();
