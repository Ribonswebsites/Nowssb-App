
/* ═══════════════════════════════════════════════════════════
   5. HEALING RANK SYSTEM
═══════════════════════════════════════════════════════════ */
window.RANK = (function(){
  var RANKS = [
    { level:0, title:'Seeker',         minSessions:0,   minWords:0  },
    { level:1, title:'Resonant',       minSessions:10,  minWords:0  },
    { level:2, title:'Practitioner',   minSessions:50,  minWords:5  },
    { level:3, title:'Healer',         minSessions:150, minWords:15 },
    { level:4, title:'Sound Master',   minSessions:500, minWords:50 },
    { level:5, title:'Frequency Sage', minSessions:1000,minWords:100},
  ];

  function compute(sessions, words){
    var s = sessions||0, w = words||0;
    var rank = RANKS[0];
    for(var i=RANKS.length-1;i>=0;i--){
      if(s>=RANKS[i].minSessions && w>=RANKS[i].minWords){ rank=RANKS[i]; break; }
    }
    var next = RANKS[rank.level+1];
    var pct = 0;
    if(next){
      var sRange = next.minSessions - RANKS[rank.level].minSessions;
      var sPos   = s - RANKS[rank.level].minSessions;
      pct = Math.min(100, Math.round((sPos/sRange)*100));
    } else { pct=100; }
    return { rank:rank, next:next, pct:pct };
  }

  return {
    compute: compute,
    badge: function(sessions,words){
      var r = compute(sessions,words);
      return '<span class="rank-badge">'+r.rank.title+'</span>';
    },
    progressHTML: function(sessions,words){
      var r = compute(sessions,words);
      var nextLabel = r.next
        ? r.next.minSessions+' sessions · '+r.next.minWords+' words → '+r.next.title
        : 'Maximum rank reached';
      return '<div class="rank-progress-wrap">'+
        '<div class="rank-progress-title">Healing Rank</div>'+
        '<div style="display:flex;align-items:center;justify-content:space-between;">'+
          '<span class="rank-badge">'+r.rank.title+'</span>'+
          (r.next?'<span style="font-size:11px;color:rgba(255,255,255,.35);font-family:\'DM Sans\',sans-serif;">'+r.pct+'%</span>':'')+
        '</div>'+
        '<div class="rank-bar-wrap"><div class="rank-bar-fill" style="width:'+r.pct+'%"></div></div>'+
        '<div class="rank-next-label">'+nextLabel+'</div>'+
      '</div>';
    }
  };
})();

// Inject rank into profile stats after they render
(function(){
  var orig = window.profileRenderStats;
  if(typeof orig!=='function') return;
  window.profileRenderStats = function(data){
    orig.apply(this,arguments);
    setTimeout(function(){
      var sessions = data && data.sessions ? Object.keys(data.sessions).length : 0;
      var words    = data && data.sessions ? new Set(Object.keys(data.sessions).map(function(k){return k.split('_').slice(1).join('_');})).size : 0;
      var rankWrap = document.getElementById('profileRankWrap');
      if(rankWrap) rankWrap.innerHTML = window.RANK.progressHTML(sessions,words);
    },80);
  };
})();

/* ═══════════════════════════════════════════════════════════
   6. AI PERSONA PICKER
═══════════════════════════════════════════════════════════ */
window.PERSONAS_UI = (function(){
  var PERSONAS = [
    { key:'soundHealer',  emoji:'🎵', name:'Sound Healer',   desc:'Compassionate frequency guide' },
    { key:'meditator',    emoji:'🧘', name:'Meditator',      desc:'Stillness and inner clarity' },
    { key:'neuroscientist',emoji:'🧠',name:'Neuroscientist', desc:'Science of brain & sound' },
    { key:'shaman',       emoji:'🌿', name:'Shaman',         desc:'Ancient earth wisdom' },
    { key:'philosopher',  emoji:'💡', name:'Philosopher',    desc:'Deep meaning & purpose' },
    { key:'ceo',          emoji:'⚡', name:'CEO',            desc:'Performance & excellence' },
    { key:'prophet',      emoji:'✦',  name:'Prophet',        desc:'Vision and transformation' },
    { key:'warrior',      emoji:'🔥', name:'Warrior',        desc:'Power and discipline' },
  ];

  function getSelected(){ return window._userPersona || 'soundHealer'; }

  function panelHTML(){
    var sel = getSelected();
    return '<div style="padding:20px 0 4px;"><button class="ss-back" onclick="ssClosePanel(\'persona\')"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M19 12H5M12 5l-7 7 7 7"/></svg> Back</button></div>'+
      '<div style="padding:8px 0 24px;"><div style="font-size:26px;font-weight:800;color:#fff;font-family:\'DM Sans\',sans-serif;">AI Persona</div>'+
      '<div style="font-size:13px;color:rgba(255,255,255,.48);font-family:\'DM Sans\',sans-serif;margin-top:4px;">Your AI guide speaks in the voice you choose.</div></div>'+
      '<div class="persona-grid">'+
      PERSONAS.map(function(p){
        return '<div class="persona-card'+(p.key===sel?' selected':'')+'" onclick="PERSONAS_UI.select(\''+p.key+'\')">'+
          '<span class="persona-emoji">'+p.emoji+'</span>'+
          '<span class="persona-name">'+p.name+'</span>'+
          '<span class="persona-desc">'+p.desc+'</span>'+
        '</div>';
      }).join('')+
      '</div>'+
      '<button onclick="ssClosePanel(\'persona\')" style="width:100%;padding:16px;border-radius:14px;border:none;background:linear-gradient(135deg,#e8d5a3,#c4a35a);color:#060c18;font-size:15px;font-weight:700;font-family:\'DM Sans\',sans-serif;cursor:pointer;">Save</button>';
  }

  return {
    select: function(key){
      window._userPersona = key;
      try{ localStorage.setItem('nowssb_persona', key); }catch(e){}
      // Re-render panel
      var panel = document.getElementById('ss-panel-persona');
      if(panel) panel.innerHTML = panelHTML();
    },
    openPanel: function(){
      // Create panel if not exists
      var wrap = document.querySelector('#sub-social .ss-wrap');
      if(!wrap) return;
      var panel = document.getElementById('ss-panel-persona');
      if(!panel){
        panel = document.createElement('div');
        panel.className = 'ss-panel'; panel.id = 'ss-panel-persona';
        panel.style.cssText = 'padding:0 20px 80px;';
        wrap.appendChild(panel);
      }
      panel.innerHTML = panelHTML();
      if(typeof ssOpenPanel==='function') ssOpenPanel('persona');
    },
    init: function(){
      try{ var k=localStorage.getItem('nowssb_persona'); if(k) window._userPersona=k; }catch(e){}
    }
  };
})();
PERSONAS_UI.init();

/* Wire AI Persona row in settings → Practice section */
(function(){
  function wirePersonaRow(){
    // Find no-tap rows in settings that could be persona
    var rows = document.querySelectorAll('#sub-social .sr.no-tap');
    // Check if any mention persona
    var already = document.querySelector('[data-persona-wired]');
    if(already) return;
    // Add AI Persona row to Audio section
    // We'll hook it via ssOpenPanel wrap
    var origOpen = window.ssOpenPanel;
    if(typeof origOpen!=='function') return;
    var wrapped = window.ssOpenPanel;
    window.ssOpenPanel = function(id){
      if(id==='persona'){ PERSONAS_UI.openPanel(); return; }
      return wrapped.apply(this,arguments);
    };
    document.body.setAttribute('data-persona-wired','1');
  }
  setTimeout(wirePersonaRow, 500);
})();

/* ═══════════════════════════════════════════════════════════
   7. VOICE RESONANCE WAVEFORM
═══════════════════════════════════════════════════════════ */
window.RESONANCE = (function(){
  var _userFreqs = [];
  var _refFreqs  = [];
  var _canvas    = null;
  var _ctx       = null;
  var _raf       = null;

  function buildReferenceFreqs(wordPhonetic){
    // Build a static reference pattern from phonetic length (proxy for real ElevenLabs freq)
    var len = (wordPhonetic||'').length;
    _refFreqs = [];
    for(var i=0;i<32;i++){
      // Sine-shaped reference based on phonetic
      _refFreqs.push(Math.abs(Math.sin((i/32)*Math.PI*2 + len*0.3)) * 180 + 40);
    }
  }

  function draw(){
    if(!_canvas || !_ctx) return;
    var W = _canvas.width, H = _canvas.height;
    _ctx.clearRect(0,0,W,H);

    var barW = W/32 - 1;

    for(var i=0;i<32;i++){
      var ref  = (_refFreqs[i]||60)/255 * H;
      var user = (_userFreqs[i]||0)/255 * H;

      // Reference bar (gold, faint)
      _ctx.fillStyle = 'rgba(232,213,163,0.22)';
      _ctx.fillRect(i*(barW+1), H-ref, barW, ref);

      // User bar (blue, solid)
      _ctx.fillStyle = 'rgba(200,232,245,0.75)';
      _ctx.fillRect(i*(barW+1), H-user, barW, user);
    }
  }

  function matchScore(){
    if(!_userFreqs.length || !_refFreqs.length) return 0;
    var diff = 0;
    for(var i=0;i<32;i++) diff += Math.abs((_userFreqs[i]||0)-(_refFreqs[i]||0));
    return Math.max(0, Math.round(100 - (diff/(32*255))*100));
  }

  return {
    // Called when recording starts — inject canvas into record tab
    init: function(canvasId, wordPhonetic){
      _canvas = document.getElementById(canvasId);
      if(!_canvas) return;
      _ctx = _canvas.getContext('2d');
      _canvas.width  = _canvas.offsetWidth  || 280;
      _canvas.height = _canvas.offsetHeight || 56;
      buildReferenceFreqs(wordPhonetic);
      this.startDraw();
    },
    // Feed frequency data from the existing analyser
    feed: function(freqData){
      // Downsample to 32 bins
      var step = Math.floor(freqData.length/32);
      _userFreqs = [];
      for(var i=0;i<32;i++) _userFreqs.push(freqData[i*step]||0);
    },
    startDraw: function(){
      var self=this;
      function loop(){ draw(); _raf=requestAnimationFrame(loop); }
      loop();
    },
    stop: function(){
      if(_raf) cancelAnimationFrame(_raf);
      var sc = document.getElementById('resMatchScore');
      if(sc) sc.textContent = 'Resonance match: '+matchScore()+'%';
    }
  };
})();

// Hook resonance into the existing recording waveform animation
(function(){
  var origAnim = window._pwAnimRecWaveform;
  if(typeof origAnim !== 'function') return;
  window._pwAnimRecWaveform = function(){
    origAnim.apply(this,arguments);
    if(window._pwAnalyser && window._pwRecording){
      var data = new Uint8Array(window._pwAnalyser.frequencyBinCount);
      window._pwAnalyser.getByteFrequencyData(data);
      window.RESONANCE.feed(data);
    }
  };
})();

/* ═══════════════════════════════════════════════════════════
   8. COMMUNITY RATINGS
═══════════════════════════════════════════════════════════ */
window.RATINGS = (function(){
  var _currentRating = 0;
  var _targetUser    = null;
  var STORE_KEY      = 'nowssb_ratings_v1';

  function load(){ try{ return JSON.parse(localStorage.getItem(STORE_KEY)||'{}'); }catch(e){ return {}; } }
  function save(d){ try{ localStorage.setItem(STORE_KEY,JSON.stringify(d)); }catch(e){} }

  function renderStars(selected){
    var wrap = document.getElementById('ratingStars');
    if(!wrap) return;
    wrap.innerHTML = [1,2,3,4,5].map(function(n){
      return '<button class="star-btn" onclick="RATINGS.setStar('+n+')" style="color:'+(n<=selected?'#e8d5a3':'rgba(255,255,255,.2)')+'">★</button>';
    }).join('');
    var cap = document.getElementById('ratingCaption');
    var labels = ['','Needs work','Getting there','Good practice','Great healer','Frequency Sage'];
    if(cap) cap.textContent = selected ? labels[selected] : 'Tap to rate';
  }

  return {
    open: function(user){
      _targetUser    = user || window._chatCurrentUser || null;
      _currentRating = 0;
      var modal = document.getElementById('ratingModal');
      if(!modal) return;
      var title = document.getElementById('ratingModalTitle');
      if(title) title.textContent = 'Rate '+((_targetUser&&_targetUser.fullName)||'Practitioner');
      renderStars(0);
      modal.style.display = 'flex';
    },
    setStar: function(n){
      _currentRating = n;
      renderStars(n);
    },
    submit: function(){
      if(!_currentRating){ alert('Please select a rating'); return; }
      var data = load();
      var key  = (_targetUser&&_targetUser.id) || 'unknown';
      data[key] = { rating:_currentRating, date:new Date().toISOString() };
      save(data);
      this.close();
      // Show brief confirmation
      var t=document.createElement('div');
      t.style.cssText='position:fixed;bottom:100px;left:50%;transform:translateX(-50%);background:rgba(6,12,24,.95);border:1px solid rgba(232,213,163,.3);border-radius:12px;padding:10px 20px;color:#e8d5a3;font-size:13px;font-weight:700;font-family:"DM Sans",sans-serif;z-index:9999;pointer-events:none;';
      t.textContent = '★'.repeat(_currentRating)+' Rating submitted';
      document.body.appendChild(t);
      setTimeout(function(){ t.remove(); },2200);
    },
    close: function(){
      var m=document.getElementById('ratingModal'); if(m) m.style.display='none';
    },
    getAvg: function(userId){
      var data=load();
      var entries=Object.values(data).filter(function(d){ return d; });
      if(!entries.length) return null;
      var sum=entries.reduce(function(a,b){ return a+(b.rating||0); },0);
      return (sum/entries.length).toFixed(1);
    }
  };
})();

/* ═══════════════════════════════════════════════════════════
   9. REAL-TIME CHAT (Firestore-ready, localStorage fallback)
═══════════════════════════════════════════════════════════ */
window.CHAT = (function(){
  var _msgs      = [];
  var _currentUser = null;
  var STORE_KEY  = 'nowssb_chat_v1';
  var _unsubscribe = null;
  var _callConnectTimer = null;
  var _callTickTimer = null;
  var _fsMod = null; // cached dynamic import of the v9 modular Firestore SDK
  var _stMod = null; // cached dynamic import of the v9 modular Storage SDK
  var _recording = false;
  var _recorder  = null;
  var _activeAudio = null; // currently-playing voice-note <audio>, if any

  function loadLocal(roomId){
    try{ return JSON.parse(localStorage.getItem(STORE_KEY+'_'+roomId)||'[]'); }catch(e){ return []; }
  }
  function saveLocal(roomId, msgs){
    try{ localStorage.setItem(STORE_KEY+'_'+roomId, JSON.stringify(msgs.slice(-100))); }catch(e){} }

  function roomId(user){
    var me = window._currentUid || 'me';
    var them = user.id || user.username || 'them';
    return [me,them].sort().join('_');
  }

  // true when the current conversation should stay on the local-only
  // simulated flow: no logged-in user, no Firestore, or the other side is
  // one of the demo/seed profiles (nobody real is there to actually reply).
  function isMockChat(){
    return !window._db || !window._currentUid || !!(_currentUser && _currentUser.mock);
  }

  // Lazily import the v9 modular Firestore SDK once and cache it — matches
  // the pattern already used elsewhere in this file (_igFetchRealUsers, etc).
  function getFS(){
    if (_fsMod) return Promise.resolve(_fsMod);
    return import("https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js").then(function(m){
      _fsMod = m;
      return m;
    });
  }

  function getStorageMod(){
    if (_stMod) return Promise.resolve(_stMod);
    return import("https://www.gstatic.com/firebasejs/11.8.1/firebase-storage.js").then(function(m){
      _stMod = m;
      return m;
    });
  }

  // Upload a real photo/voice-note file to Firebase Storage (default app,
  // same project as window._db) and resolve with its public download URL —
  // small enough to store directly in a Firestore chat message afterward.
  function uploadToStorage(fileOrBlob, contentType, kind){
    return getStorageMod().then(function(st){
      var storage = st.getStorage();
      var rId = roomId(_currentUser);
      var subtype = ((contentType||'').split('/')[1] || 'bin').split(';')[0];
      var path = 'chat_uploads/' + rId + '/' + kind + '_' + Date.now() + '_' + Math.random().toString(36).slice(2) + '.' + subtype;
      var fileRef = st.ref(storage, path);
      return st.uploadBytes(fileRef, fileOrBlob, contentType ? { contentType: contentType } : undefined)
        .then(function(){ return st.getDownloadURL(fileRef); });
    });
  }

  function timeStr(ts){
    if(!ts) return '';
    var d = new Date(ts);
    var h=d.getHours(), m=d.getMinutes();
    return (h<10?'0':'')+h+':'+(m<10?'0':'')+m;
  }

  function escapeHtml(s){
    return String(s==null?'':s).replace(/[&<>"']/g, function(c){
      return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c];
    });
  }

  function waveformHtml(){
    var bars = [];
    for(var i=0;i<14;i++) bars.push('<span style="height:'+(6+Math.round(Math.abs(Math.sin(i*1.3))*14))+'px"></span>');
    return bars.join('');
  }

  function bubbleHtml(msg){
    if(msg.type === 'image'){
      return '<img class="chat-bubble-img" src="'+msg.img+'" alt="">';
    }
    if(msg.type === 'voice'){
      return '<div class="chat-voice-msg" onclick="CHAT.toggleVoicePlay(this)" data-audio-url="'+escapeHtml(msg.audioUrl||'')+'">' +
        '<span class="chat-voice-play">' +
          '<svg class="ico-play" width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><polygon points="5 3 19 12 5 21 5 3"/></svg>' +
          '<svg class="ico-pause" width="15" height="15" viewBox="0 0 24 24" fill="currentColor" style="display:none;"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>' +
        '</span>' +
        '<span class="chat-voice-wave">'+waveformHtml()+'</span>' +
        '<span class="chat-voice-dur">'+msg.duration+'</span>' +
      '</div>';
    }
    return escapeHtml(msg.text);
  }

  function setPlayIcons(el, playing){
    var play = el.querySelector('.ico-play');
    var pause = el.querySelector('.ico-pause');
    if(play)  play.style.display  = playing ? 'none' : '';
    if(pause) pause.style.display = playing ? '' : 'none';
  }

  function renderMessages(){
    var box = document.getElementById('chatMessages');
    if(!box) return;
    var me = window._currentUid || 'me';
    box.innerHTML = _msgs.map(function(msg){
      var isMe = msg.from === me;
      return '<div class="chat-bubble-wrap'+(isMe?' me':'')+'">'+
        '<div class="chat-bubble '+(isMe?'me':'them')+(msg.type==='image'?' has-img':'')+'">'+bubbleHtml(msg)+'</div>'+
        '</div>'+
        '<div class="chat-time" style="text-align:'+(isMe?'right':'left')+';">'+timeStr(msg.ts)+'</div>';
    }).join('');
    box.scrollTop = box.scrollHeight;
  }

  function pushMessage(fields, fromMe){
    var me = window._currentUid || 'me';
    var msg = fields;
    msg.from = fromMe ? me : 'them';
    msg.ts = Date.now();
    _msgs.push(msg);
    renderMessages();
    if(_currentUser) saveLocal(roomId(_currentUser), _msgs);

    // Real Firestore sync. Only for real accounts, never demo seed profiles —
    // there's nobody real on the other end of those rooms. Image/voice
    // messages always carry a short Storage download URL by the time they
    // reach here (uploaded first — see onImageChosen/finishVoiceNote), never
    // a raw data: URL, so they're safe to store as a Firestore document.
    if(fromMe && !isMockChat()){
      var rId = roomId(_currentUser);
      getFS().then(function(fs){
        var colRef = fs.collection(window._db, 'chats', rId, 'messages');
        return fs.addDoc(colRef, msg);
      }).catch(function(e){ console.warn('CHAT: Firestore send failed:', e); });
    }
    return msg;
  }

  function addMessage(text, fromMe){
    pushMessage({ text:text }, fromMe);

    // Auto-reply simulation — only for demo profiles / guests, never for a
    // real conversation (a real listener will render the real reply instead).
    if(fromMe && isMockChat()){
      setTimeout(function(){
        var replies = [
          'Frequency received 🙏',
          'Which word are you practicing today?',
          'The resonance is building...',
          'Every sound is a step closer.',
          'Keep your streak going!'
        ];
        addMessage(replies[Math.floor(Math.random()*replies.length)], false);
      }, 1200+Math.random()*800);
    }
  }

  function addImageMessage(dataUrl, fromMe){
    pushMessage({ type:'image', img:dataUrl }, fromMe);
    if(fromMe && isMockChat()){
      setTimeout(function(){ addMessage('Beautiful 🙏', false); }, 1300+Math.random()*700);
    }
  }

  function addVoiceMessage(duration, fromMe, audioUrl){
    pushMessage({ type:'voice', duration:duration, audioUrl:audioUrl||'' }, fromMe);
    if(fromMe && isMockChat()){
      setTimeout(function(){ addMessage('Got your voice note 🎧', false); }, 1300+Math.random()*700);
    }
  }

  // ── Real microphone recording (MediaRecorder). Mock chats keep a purely
  //    local blob URL (fine — nobody else needs to hear it); real chats
  //    upload the recording to Storage first so it survives for the other
  //    person and across reloads. ──
  function startRecording(btn){
    if (!navigator.mediaDevices || !window.MediaRecorder) {
      alert('Voice messages need microphone access, which this browser doesn\'t support here.');
      return;
    }
    navigator.mediaDevices.getUserMedia({ audio: true }).then(function(stream){
      var mimeType = (window.MediaRecorder.isTypeSupported && MediaRecorder.isTypeSupported('audio/webm')) ? 'audio/webm' : '';
      var rec = mimeType ? new MediaRecorder(stream, { mimeType: mimeType }) : new MediaRecorder(stream);
      var chunks = [];
      var startedAt = Date.now();
      rec.ondataavailable = function(e){ if (e.data && e.data.size) chunks.push(e.data); };
      rec.onstop = function(){
        stream.getTracks().forEach(function(t){ t.stop(); });
        var blob = new Blob(chunks, { type: rec.mimeType || 'audio/webm' });
        var durationSec = Math.max(1, Math.round((Date.now() - startedAt) / 1000));
        finishVoiceNote(blob, durationSec);
      };
      rec.start();
      _recorder = rec;
      _recording = true;
      if (btn) btn.classList.add('recording');
    }).catch(function(e){
      console.warn('CHAT: mic access failed:', e);
      alert('Could not access the microphone. Check your browser/site permissions and try again.');
    });
  }

  function stopRecording(){
    if (_recorder && _recorder.state !== 'inactive') _recorder.stop();
    _recording = false;
    var btn = document.getElementById('chatMicBtn');
    if (btn) btn.classList.remove('recording');
  }

  function finishVoiceNote(blob, durationSec){
    var mm = Math.floor(durationSec/60), ss = durationSec%60;
    var durStr = (mm<10?'0':'')+mm+':'+(ss<10?'0':'')+ss;
    if (isMockChat()) {
      addVoiceMessage(durStr, true, URL.createObjectURL(blob));
      return;
    }
    uploadToStorage(blob, blob.type || 'audio/webm', 'voice').then(function(url){
      addVoiceMessage(durStr, true, url);
    }).catch(function(e){
      console.warn('CHAT: voice upload failed:', e);
      alert('Could not send the voice note — check your connection and try again.');
    });
  }

  return {
    openPeerProfile: function(){
      var u = _currentUser; if(!u) return;
      this.close();
      setTimeout(function(){
        if(window.IG && typeof IG.openProfile==='function') IG.openProfile(u);
      }, 140);
    },
    open: function(user){
      _currentUser = user;
      window._chatCurrentUser = user;
      var overlay = document.getElementById('chatScreenOverlay');
      if(!overlay) return;

      var av   = document.getElementById('chatTopAv');
      var name = document.getElementById('chatTopName');
      var rank = document.getElementById('chatTopRank');
      if(av)   av.src  = user.avatar||'';
      if(name) name.textContent = user.fullName||user.username||'—';
      if(rank) rank.textContent = user.category||'Practitioner';

      _msgs = loadLocal(roomId(user));
      if(!_msgs.length && isMockChat()){
        _msgs.push({ from:'them', text:'Hey! Great to connect on NowssB 🙏', ts:Date.now()-60000 });
      }
      renderMessages();

      // Hide both navs so they don't block the chat input bar
      var bn = document.getElementById('ig-bottomnav');
      var sn = document.getElementById('ig-social-nav');
      overlay._prevBnDisplay = bn ? bn.style.display : null;
      overlay._prevSnDisplay = sn ? sn.style.display : null;
      if(bn) bn.style.display = 'none';
      if(sn) sn.style.display = 'none';

      var inp = document.getElementById('chatInput'); if(inp) inp.value = '';
      var tools = document.getElementById('chatInputTools'); if(tools) tools.style.display = 'flex';
      var sendBtn = document.getElementById('chatSendBtn'); if(sendBtn) sendBtn.style.display = 'none';
      var tray = document.getElementById('chatStickerTray'); if(tray) tray.style.display = 'none';

      overlay.style.display = 'block';
      setTimeout(function(){ var i=document.getElementById('chatInput'); if(i) i.focus(); }, 80);

      if(_unsubscribe){ try{ _unsubscribe(); }catch(e){} _unsubscribe = null; }
      if(!isMockChat()){
        var rId = roomId(user);
        getFS().then(function(fs){
          if(_currentUser !== user) return; // user switched chats before this resolved
          var colRef = fs.collection(window._db, 'chats', rId, 'messages');
          var q = fs.query(colRef, fs.orderBy('ts'));
          _unsubscribe = fs.onSnapshot(q, function(snap){
            var fsMsgs = [];
            snap.forEach(function(d){ fsMsgs.push(d.data()); });
            _msgs = fsMsgs;
            renderMessages();
            saveLocal(rId, _msgs);
          }, function(err){ console.warn('CHAT: Firestore listen failed:', err); });
        }).catch(function(e){ console.warn('CHAT: Firestore listen setup failed:', e); });
      }
    },
    send: function(){
      var inp = document.getElementById('chatInput');
      if(!inp) return;
      var text = inp.value.trim();
      if(!text) return;
      inp.value='';
      this.onInputChange(inp);
      addMessage(text, true);
    },
    onInputChange: function(el){
      var hasText = !!(el && el.value.trim().length);
      var tools = document.getElementById('chatInputTools');
      var sendBtn = document.getElementById('chatSendBtn');
      if(tools)   tools.style.display = hasText ? 'none' : 'flex';
      if(sendBtn) sendBtn.style.display = hasText ? 'flex' : 'none';
    },
    // Photo attach — camera or gallery source, sent as an image bubble.
    pickImage: function(source){
      var inp = document.getElementById('chatImageInput');
      if(!inp) return;
      if(source === 'camera') inp.setAttribute('capture', 'environment');
      else inp.removeAttribute('capture');
      inp.click();
    },
    onImageChosen: function(el){
      var file = el.files && el.files[0];
      el.value = '';
      if(!file) return;
      if (isMockChat()) {
        var reader = new FileReader();
        reader.onload = function(e){ addImageMessage(e.target.result, true); };
        reader.readAsDataURL(file);
        return;
      }
      uploadToStorage(file, file.type || 'image/jpeg', 'photo').then(function(url){
        addImageMessage(url, true);
      }).catch(function(e){
        console.warn('CHAT: image upload failed:', e);
        alert('Could not send the photo — check your connection and try again.');
      });
    },
    // Tap to start recording, tap again to stop and send. Real microphone
    // audio (MediaRecorder) — see startRecording/finishVoiceNote above.
    sendVoiceNote: function(btn){
      if (_recording) stopRecording();
      else startRecording(btn);
    },
    toggleVoicePlay: function(el){
      var url = el.getAttribute('data-audio-url');
      if(!url) return;
      if(_activeAudio && _activeAudio._bubbleEl === el){
        if(_activeAudio.paused) _activeAudio.play().catch(function(){});
        else _activeAudio.pause();
        return;
      }
      if(_activeAudio){ _activeAudio.pause(); }
      var audio = new Audio(url);
      audio._bubbleEl = el;
      audio.play().catch(function(e){ console.warn('CHAT: audio play failed:', e); });
      setPlayIcons(el, true);
      audio.onpause = function(){ setPlayIcons(el, false); };
      audio.onplay  = function(){ setPlayIcons(el, true); };
      audio.onended = function(){ setPlayIcons(el, false); if(_activeAudio===audio) _activeAudio=null; };
      _activeAudio = audio;
    },
    toggleStickers: function(){
      var tray = document.getElementById('chatStickerTray');
      if(!tray) return;
      if(tray.style.display !== 'none'){ tray.style.display = 'none'; return; }
      var emojis = ['🙏','😍','🔥','✨','💛','😂','👏','🎶','🧘','🌿','💫','🙌'];
      tray.innerHTML = emojis.map(function(e){
        return '<button class="chat-sticker-item" onclick="CHAT.sendSticker(\''+e+'\')">'+e+'</button>';
      }).join('');
      tray.style.display = 'flex';
    },
    sendSticker: function(emoji){
      addMessage(emoji, true);
      var tray = document.getElementById('chatStickerTray');
      if(tray) tray.style.display = 'none';
    },
    // Demo profiles get the simulated call UI (nobody real to ring). Real
    // accounts get an actual WebRTC call via window.RTC — see below.
    startCall: function(kind){
      var u = _currentUser; if(!u) return;
      if (!isMockChat()) { if(window.RTC) window.RTC.startCall(u, kind); return; }

      var overlay = document.getElementById('chatCallOverlay');
      if(!overlay) return;
      var kindEl   = document.getElementById('chatCallKind');
      var avEl     = document.getElementById('chatCallAv');
      var bgEl     = document.getElementById('chatCallBg');
      var nameEl   = document.getElementById('chatCallName');
      var statusEl = document.getElementById('chatCallStatus');
      if(kindEl)   kindEl.textContent = kind==='video' ? 'Video Call' : 'Voice Call';
      if(avEl)     avEl.src = u.avatar || '';
      if(bgEl)     bgEl.style.backgroundImage = u.avatar ? "url('"+u.avatar+"')" : 'none';
      if(nameEl)   nameEl.textContent = u.fullName || u.username || '—';
      if(statusEl) statusEl.textContent = 'Calling…';
      overlay.style.display = 'block';

      clearTimeout(_callConnectTimer);
      clearInterval(_callTickTimer);
      _callConnectTimer = setTimeout(function(){
        if(overlay.style.display === 'none') return;
        var start = Date.now();
        _callTickTimer = setInterval(function(){
          var sec = Math.floor((Date.now()-start)/1000);
          var mm = Math.floor(sec/60), ss = sec%60;
          if(statusEl) statusEl.textContent = (mm<10?'0':'')+mm+':'+(ss<10?'0':'')+ss;
        }, 1000);
      }, 1800 + Math.random()*900);
    },
    endCall: function(){
      if (window.RTC && window.RTC.isActive()) { window.RTC.hangup(); return; }
      var overlay = document.getElementById('chatCallOverlay');
      if(overlay) overlay.style.display = 'none';
      clearTimeout(_callConnectTimer);
      clearInterval(_callTickTimer);
    },
    close: function(){
      if(_unsubscribe) try{ _unsubscribe(); }catch(e){}
      if(_recording) stopRecording();
      if(_activeAudio){ _activeAudio.pause(); _activeAudio = null; }
      var overlay = document.getElementById('chatScreenOverlay');
      if(!overlay) return;
      // Restore whichever nav was showing before chat opened
      var bn = document.getElementById('ig-bottomnav');
      var sn = document.getElementById('ig-social-nav');
      if(bn && overlay._prevBnDisplay !== null) bn.style.display = overlay._prevBnDisplay || '';
      if(sn && overlay._prevSnDisplay !== null) sn.style.display = overlay._prevSnDisplay || '';
      overlay.style.display = 'none';
    }
  };
})();

/* ═══════════════════════════════════════════════════════════
   REAL 1:1 VOICE/VIDEO CALLING (WebRTC + Firestore signaling)
   Free: WebRTC itself, Google's public STUN servers, and Firestore
   (existing free project) carrying the offer/answer/ICE handshake — no
   extra server needed. Known limitation: no TURN relay, so a minority of
   users behind strict corporate/hotel NATs won't connect. Also: this is a
   PWA, not a native app, so a call can only reach the other person while
   their app is open (foreground or background tab) — there's no OS-level
   wake/ring when the app is fully closed.
═══════════════════════════════════════════════════════════ */
window.RTC = (function(){
  var _pc = null;
  var _localStream = null;
  var _callDocRef = null;
  var _callId = null;
  var _role = null; // 'caller' | 'callee'
  var _kind = null; // 'audio' | 'video'
  var _peerInfo = null; // {uid, name, avatar} of the other side
  var _candUnsub = null;
  var _callDocUnsub = null;
  var _incomingUnsub = null;
  var _ringingCall = null; // {id, data} of a currently-incoming call, pre-accept
  var _fsMod = null;
  var _connectTickTimer = null;

  var ICE_SERVERS = { iceServers: [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' }
  ]};

  function getFS(){
    if (_fsMod) return Promise.resolve(_fsMod);
    return import("https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js").then(function(m){ _fsMod = m; return m; });
  }

  function overlayEls(){
    return {
      overlay: document.getElementById('chatCallOverlay'),
      kindEl: document.getElementById('chatCallKind'),
      avEl: document.getElementById('chatCallAv'),
      bgEl: document.getElementById('chatCallBg'),
      nameEl: document.getElementById('chatCallName'),
      statusEl: document.getElementById('chatCallStatus'),
      outActions: document.getElementById('chatCallOutActions'),
      inActions: document.getElementById('chatCallInActions'),
      avWrap: document.getElementById('chatCallAvWrap'),
      remoteVideo: document.getElementById('chatCallRemoteVideo'),
      localVideo: document.getElementById('chatCallLocalVideo'),
      remoteAudio: document.getElementById('chatCallRemoteAudio')
    };
  }

  function showOverlay(peer, kind, statusText, mode){
    var el = overlayEls();
    if(!el.overlay) return;
    if(el.kindEl)   el.kindEl.textContent = kind==='video' ? 'Video Call' : 'Voice Call';
    if(el.avEl)     el.avEl.src = peer.avatar || '';
    if(el.bgEl)      el.bgEl.style.backgroundImage = peer.avatar ? "url('"+peer.avatar+"')" : 'none';
    if(el.nameEl)   el.nameEl.textContent = peer.fullName || peer.username || '—';
    if(el.statusEl) el.statusEl.textContent = statusText;
    if(el.outActions) el.outActions.style.display = mode === 'incoming' ? 'none' : 'flex';
    if(el.inActions)   el.inActions.style.display = mode === 'incoming' ? 'flex' : 'none';
    el.overlay.style.display = 'block';
  }

  function hideOverlay(){
    var el = overlayEls();
    if(el.overlay) el.overlay.style.display = 'none';
    if(el.remoteVideo){ el.remoteVideo.style.display = 'none'; el.remoteVideo.srcObject = null; }
    if(el.localVideo){ el.localVideo.style.display = 'none'; el.localVideo.srcObject = null; }
    if(el.remoteAudio) el.remoteAudio.srcObject = null;
    if(el.avWrap) el.avWrap.style.display = '';
    clearInterval(_connectTickTimer);
  }

  function setStatus(text){
    var el = document.getElementById('chatCallStatus');
    if(el) el.textContent = text;
  }

  function startConnectedTimer(){
    clearInterval(_connectTickTimer);
    var start = Date.now();
    _connectTickTimer = setInterval(function(){
      var sec = Math.floor((Date.now()-start)/1000);
      var mm = Math.floor(sec/60), ss = sec%60;
      setStatus((mm<10?'0':'')+mm+':'+(ss<10?'0':'')+ss);
    }, 1000);
  }

  function attachLocalPreview(stream){
    var el = overlayEls();
    if (_kind === 'video' && el.localVideo){
      el.localVideo.srcObject = stream;
      el.localVideo.style.display = 'block';
    }
  }

  function attachRemoteStream(stream){
    var el = overlayEls();
    if (_kind === 'video' && el.remoteVideo){
      el.remoteVideo.srcObject = stream;
      el.remoteVideo.style.display = 'block';
      if (el.avWrap) el.avWrap.style.display = 'none';
    } else if (el.remoteAudio){
      el.remoteAudio.srcObject = stream;
      el.remoteAudio.play().catch(function(e){ console.warn('RTC: remote audio play blocked:', e); });
    }
  }

  function makePeerConnection(fs, candidatesSubcollection){
    var pc = new RTCPeerConnection(ICE_SERVERS);
    var remoteStream = new MediaStream();
    pc.ontrack = function(e){
      e.streams[0].getTracks().forEach(function(t){ remoteStream.addTrack(t); });
      attachRemoteStream(remoteStream);
    };
    pc.onicecandidate = function(e){
      if (!e.candidate || !_callDocRef) return;
      fs.addDoc(fs.collection(_callDocRef, candidatesSubcollection), e.candidate.toJSON()).catch(function(err){
        console.warn('RTC: failed to write ICE candidate:', err);
      });
    };
    pc.onconnectionstatechange = function(){
      if (!pc) return;
      if (pc.connectionState === 'connected') startConnectedTimer();
      else if (pc.connectionState === 'failed' || pc.connectionState === 'disconnected'){
        setStatus(pc.connectionState === 'failed' ? 'Connection failed' : 'Reconnecting…');
      }
    };
    return pc;
  }

  function cleanupPeer(){
    if (_pc) { try { _pc.close(); } catch(e){} _pc = null; }
    if (_localStream) { _localStream.getTracks().forEach(function(t){ t.stop(); }); _localStream = null; }
    if (_candUnsub) { try { _candUnsub(); } catch(e){} _candUnsub = null; }
    if (_callDocUnsub) { try { _callDocUnsub(); } catch(e){} _callDocUnsub = null; }
    _callDocRef = null;
    _callId = null;
    _role = null;
    _kind = null;
    _peerInfo = null;
  }

  return {
    isActive: function(){ return !!(_pc || _role); },

    // Subscribe once (after login) to calls where I'm the callee and it's
    // still ringing — this is the "does my phone ring" piece. Only works
    // while this tab is open; see the module-level note above.
    init: function(){
      if (!window._db || !window._currentUid) return;
      if (_incomingUnsub) return; // already listening
      var self = this;
      getFS().then(function(fs){
        var q = fs.query(
          fs.collection(window._db, 'calls'),
          fs.where('calleeUid', '==', window._currentUid),
          fs.where('status', '==', 'ringing')
        );
        _incomingUnsub = fs.onSnapshot(q, function(snap){
          snap.docChanges().forEach(function(change){
            if (change.type === 'added' && !self.isActive()){
              var data = change.doc.data();
              _ringingCall = { id: change.doc.id, data: data };
              showOverlay(
                { fullName: data.callerName, avatar: data.callerAvatar },
                data.kind,
                (data.kind === 'video' ? 'Incoming video call…' : 'Incoming call…'),
                'incoming'
              );
            }
            if (change.type === 'removed' || (change.type === 'modified' && change.doc.data().status !== 'ringing')){
              if (_ringingCall && _ringingCall.id === change.doc.id && _role !== 'callee'){
                _ringingCall = null;
                hideOverlay();
              }
            }
          });
        }, function(err){ console.warn('RTC: incoming-call listener failed:', err); });
      }).catch(function(e){ console.warn('RTC: init failed:', e); });
    },

    // Caller side.
    startCall: function(peer, kind){
      if (this.isActive()) return;
      if (!window._db || !window._currentUid) { alert('Sign in to make a real call.'); return; }
      _role = 'caller';
      _kind = kind;
      _peerInfo = peer;
      showOverlay(peer, kind, 'Calling…', 'outgoing');

      var calleeUid = peer.uid || String(peer.id);
      var me = { uid: window._currentUid, name: window._userName || 'NowssB user', avatar: (window._currentUser && window._currentUser.photoURL) || '' };

      navigator.mediaDevices.getUserMedia({ audio: true, video: kind === 'video' }).then(function(stream){
        _localStream = stream;
        attachLocalPreview(stream);
        getFS().then(function(fs){
          var pc = makePeerConnection(fs, 'callerCandidates');
          _pc = pc;
          stream.getTracks().forEach(function(t){ pc.addTrack(t, stream); });

          fs.addDoc(fs.collection(window._db, 'calls'), {
            callerUid: me.uid, callerName: me.name, callerAvatar: me.avatar,
            calleeUid: calleeUid, kind: kind, status: 'ringing',
            createdAt: Date.now()
          }).then(function(docRef){
            _callDocRef = docRef;
            _callId = docRef.id;

            pc.createOffer().then(function(offerDesc){
              return pc.setLocalDescription(offerDesc).then(function(){ return offerDesc; });
            }).then(function(offerDesc){
              return fs.updateDoc(docRef, { offer: { type: offerDesc.type, sdp: offerDesc.sdp } });
            }).catch(function(e){ console.warn('RTC: offer creation failed:', e); });

            _callDocUnsub = fs.onSnapshot(docRef, function(snap){
              var data = snap.data();
              if (!data) return;
              if (data.answer && pc.currentRemoteDescription === null){
                setStatus('Connecting…');
                pc.setRemoteDescription(new RTCSessionDescription(data.answer)).catch(function(e){
                  console.warn('RTC: setRemoteDescription (answer) failed:', e);
                });
              }
              if (data.status === 'declined'){ setStatus('Declined'); setTimeout(function(){ window.RTC.hangup(); }, 1200); }
              if (data.status === 'ended'){ setStatus('Call ended'); setTimeout(function(){ window.RTC.hangup(true); }, 900); }
            });

            _candUnsub = fs.onSnapshot(fs.collection(docRef, 'calleeCandidates'), function(snap){
              snap.docChanges().forEach(function(change){
                if (change.type === 'added') pc.addIceCandidate(new RTCIceCandidate(change.doc.data())).catch(function(e){
                  console.warn('RTC: addIceCandidate (callee->caller) failed:', e);
                });
              });
            });
          }).catch(function(e){
            console.warn('RTC: could not create call doc:', e);
            setStatus('Could not start the call');
            setTimeout(function(){ window.RTC.hangup(true); }, 1200);
          });
        });
      }).catch(function(e){
        console.warn('RTC: getUserMedia failed:', e);
        setStatus('Camera/mic access needed');
        setTimeout(function(){ window.RTC.hangup(true); }, 1500);
      });
    },

    // Callee side — accept the currently-ringing call.
    accept: function(){
      if (!_ringingCall) return;
      var call = _ringingCall;
      _ringingCall = null;
      _role = 'callee';
      _kind = call.data.kind;
      _peerInfo = { fullName: call.data.callerName, avatar: call.data.callerAvatar };
      showOverlay(_peerInfo, _kind, 'Connecting…', 'outgoing');

      navigator.mediaDevices.getUserMedia({ audio: true, video: _kind === 'video' }).then(function(stream){
        _localStream = stream;
        attachLocalPreview(stream);
        getFS().then(function(fs){
          var docRef = fs.doc(window._db, 'calls', call.id);
          _callDocRef = docRef;
          _callId = call.id;
          var pc = makePeerConnection(fs, 'calleeCandidates');
          _pc = pc;
          stream.getTracks().forEach(function(t){ pc.addTrack(t, stream); });

          pc.setRemoteDescription(new RTCSessionDescription(call.data.offer)).then(function(){
            return pc.createAnswer();
          }).then(function(answerDesc){
            return pc.setLocalDescription(answerDesc).then(function(){ return answerDesc; });
          }).then(function(answerDesc){
            return fs.updateDoc(docRef, { answer: { type: answerDesc.type, sdp: answerDesc.sdp }, status: 'accepted' });
          }).catch(function(e){
            console.warn('RTC: answer creation failed:', e);
            setStatus('Could not connect');
            setTimeout(function(){ window.RTC.hangup(true); }, 1500);
          });

          _callDocUnsub = fs.onSnapshot(docRef, function(snap){
            var data = snap.data();
            if (data && data.status === 'ended'){ setStatus('Call ended'); setTimeout(function(){ window.RTC.hangup(true); }, 900); }
          });

          _candUnsub = fs.onSnapshot(fs.collection(docRef, 'callerCandidates'), function(snap){
            snap.docChanges().forEach(function(change){
              if (change.type === 'added') pc.addIceCandidate(new RTCIceCandidate(change.doc.data())).catch(function(e){
                console.warn('RTC: addIceCandidate (caller->callee) failed:', e);
              });
            });
          });
        });
      }).catch(function(e){
        console.warn('RTC: getUserMedia failed:', e);
        alert('Could not access camera/microphone to answer the call.');
        window.RTC.decline();
      });
    },

    // Callee side — decline without ever opening a peer connection.
    decline: function(){
      if (!_ringingCall) { hideOverlay(); return; }
      var call = _ringingCall;
      _ringingCall = null;
      hideOverlay();
      getFS().then(function(fs){
        return fs.updateDoc(fs.doc(window._db, 'calls', call.id), { status: 'declined' });
      }).catch(function(e){ console.warn('RTC: decline write failed:', e); });
    },

    // Either side — end an active or outgoing call.
    hangup: function(skipRemoteUpdate){
      var docRef = _callDocRef;
      hideOverlay();
      if (docRef && !skipRemoteUpdate){
        getFS().then(function(fs){
          return fs.updateDoc(docRef, { status: 'ended' });
        }).catch(function(e){ console.warn('RTC: hangup write failed:', e); });
      }
      cleanupPeer();
    }
  };
})();

// Start listening for incoming real calls once auth has settled — mirrors
// the timing already used for _igInitFollowing elsewhere in this file.
setTimeout(function(){ if (window.RTC) window.RTC.init(); }, 2000);

// Wire IG message button to real chat
window.IG._origMessage = window.IG.message;
window.IG.message = function(id){
  var people = this._allPeople || [];
  var user = people.find ? people.find(function(p){ return p.id===id; }) : null;
  if(user) CHAT.open(user);
  else if(typeof id==='object') CHAT.open(id);
};

/* ═══════════════════════════════════════════════════════════
   10. FOLLOW SYSTEM
═══════════════════════════════════════════════════════════ */
window.FOLLOW = (function(){
  var KEY = 'nowssb_following_v1';
  function load(){ try{ return JSON.parse(localStorage.getItem(KEY)||'[]'); }catch(e){ return []; } }
  function save(d){ try{ localStorage.setItem(KEY,JSON.stringify(d)); }catch(e){} }

  return {
    toggle: function(userId){
      var list = load();
      var idx  = list.indexOf(userId);
      if(idx>=0) list.splice(idx,1); else list.push(userId);
      save(list);
      // Firestore hook
      if(window._fbSetDoc && window._currentUid){
        var update = {};
        update['following.'+userId] = idx<0 ? true : null;
        window._fbSetDoc(window._currentUid, update).catch(function(){});
      }
      return idx < 0; // true = now following
    },
    isFollowing: function(userId){ return load().indexOf(userId)>=0; },
    count: function(){ return load().length; }
  };
})();

/* ═══════════════════════════════════════════════════════════
   PARTS 2 & 3: Real Firestore users · Firestore follow/ratings ·
                Firestore v9 real-time chat
═══════════════════════════════════════════════════════════ */

// ── Seed IG._allPeople with fallback so chat inbox is never empty ──
(function() {
  var SEED = [
    {id:'1',uid:'1',username:'kavya.frequency',fullName:'Kavya Singh',verified:true,avatar:'https://i.pravatar.cc/150?img=5',bio:'Word without dictionary.\nFrequency is truth.',category:'Sound Healer',link:'nowssb.com/kavya',following_state:false,highlights:[],grid:[]},
    {id:'2',uid:'2',username:'aryan.sound',fullName:'Aryan Mehta',verified:true,avatar:'https://i.pravatar.cc/150?img=13',bio:'Sound practice every morning.\n47-day streak.',category:'Daily Practitioner',link:'',following_state:false,highlights:[],grid:[]},
    {id:'3',uid:'3',username:'priya.heals',fullName:'Priya Nair',verified:false,avatar:'https://i.pravatar.cc/150?img=20',bio:'Healing my body one word at a time.',category:'Wellness',link:'',following_state:false,highlights:[],grid:[]},
    {id:'4',uid:'4',username:'rohan.resonance',fullName:'Rohan Desai',verified:false,avatar:'https://i.pravatar.cc/150?img=33',bio:'Morning practice since Jan 2026. Building the habit.',category:'Health & Frequency',link:'',following_state:false,highlights:[],grid:[]},
    {id:'5',uid:'5',username:'aisha.vibration',fullName:'Aisha Patel',verified:true,avatar:'https://i.pravatar.cc/150?img=45',bio:'Natural origin sounds healed my anxiety.',category:'Sound Healer',link:'nowssb.com/aisha',following_state:false,highlights:[],grid:[]},
    {id:'6',uid:'6',username:'dev.tones',fullName:'Dev Sharma',verified:false,avatar:'https://i.pravatar.cc/150?img=51',bio:'New to Shabdapathy. Learning every day.',category:'Beginner',link:'',following_state:false,highlights:[],grid:[]},
    {id:'7',uid:'7',username:'meera.om',fullName:'Meera Iyer',verified:false,avatar:'https://i.pravatar.cc/150?img=47',bio:'Frequency is medicine.',category:'Practitioner',link:'',following_state:false,highlights:[],grid:[]},
    {id:'8',uid:'8',username:'kabir.naad',fullName:'Kabir Khan',verified:true,avatar:'https://i.pravatar.cc/150?img=60',bio:'Top 1% · 1000+ sessions.\nYour voice is the instrument.',category:'Frequency Sage',link:'nowssb.com/kabir',following_state:false,highlights:[],grid:[]}
  ];
  // Apply saved follow state. mock:true marks these as demo profiles, not real
  // accounts — CHAT keeps them on the simulated local-only reply flow even
  // once real Firestore messaging is live, since nobody real is behind them.
  SEED.forEach(function(p) {
    p.following_state = window.FOLLOW ? window.FOLLOW.isFollowing(p.id) : false;
    p.mock = true;
  });
  if (window.IG) window.IG._allPeople = SEED;
})();

// ── Fetch real Firestore users → update IG._allPeople ──
window._igFetchRealUsers = async function() {
  if (!window._currentUid) return;
  try {
    var fs = await import("https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js");
    var db2 = fs.getFirestore();
    var snap = await fs.getDocs(fs.query(fs.collection(db2,'users'), fs.limit(40)));
    var real = [];
    snap.forEach(function(d) {
      if (d.id === window._currentUid) return;
      var u = d.data();
      if (!u.displayName) return;
      real.push({
        id: d.id, uid: d.id,
        username: u.displayName.toLowerCase().replace(/\s+/g,'.').replace(/[^a-z0-9.]/g,''),
        fullName: u.displayName,
        verified: !!(u.isPro || u.tier),
        avatar: u.photoURL || '',
        bannerURL: u.bannerURL || '',
        bio: u.bio || '',
        category: u.healthFocus || 'Practitioner',
        link: '', posts: 0, followers: '0', following: 0,
        following_state: window.FOLLOW ? window.FOLLOW.isFollowing(d.id) : false,
        highlights: [], grid: [], self: false
      });
    });
    if (real.length && window.IG) {
      window.IG._allPeople = real;
      // Refresh chat inbox if open
      var inbox = document.getElementById('chatInboxOverlay');
      if (inbox && inbox.style.display !== 'none' && typeof chatInboxRender === 'function') chatInboxRender();
    }
  } catch(e) { console.warn('_igFetchRealUsers:', e); }
};

// ── Sync follow state from _userDataCache when auth settles ──
window._igInitFollowing = function() {
  var ud = window._userDataCache;
  if (!ud || !ud.following) return;
  var KEY = 'nowssb_following_v1';
  var existing = []; try { existing = JSON.parse(localStorage.getItem(KEY)||'[]'); } catch(e){}
  Object.keys(ud.following).forEach(function(uid) {
    if (ud.following[uid] && existing.indexOf(uid)<0) existing.push(uid);
    else if (!ud.following[uid]) { var i=existing.indexOf(uid); if(i>=0) existing.splice(i,1); }
  });
  try { localStorage.setItem(KEY, JSON.stringify(existing)); } catch(e){}
  if (window.IG && window.IG._allPeople) {
    window.IG._allPeople.forEach(function(p) {
      p.following_state = window.FOLLOW ? window.FOLLOW.isFollowing(String(p.id)) : false;
    });
  }
};

// ── Patch IG.toggleFollow / toggleFollowMini → FOLLOW system + _allPeople sync ──
(function() {
  window.IG.toggleFollow = function(id) {
    var now = window.FOLLOW.toggle(String(id));
    var b = document.getElementById('ig-bigfollow');
    if (b) { b.classList.toggle('following', now); b.textContent = now ? 'Following' : 'Follow'; }
    if (this._allPeople) {
      var p = this._allPeople.find(function(x){ return String(x.id)===String(id)||x.uid===String(id); });
      if (p) p.following_state = now;
    }
  };
  window.IG.toggleFollowMini = function(id, btn) {
    var now = window.FOLLOW.toggle(String(id));
    if (btn) { btn.classList.toggle('following', now); btn.textContent = now ? 'Following' : 'Follow'; }
    if (this._allPeople) {
      var p = this._allPeople.find(function(x){ return String(x.id)===String(id)||x.uid===String(id); });
      if (p) p.following_state = now;
    }
  };
})();

// ── Patch RATINGS → write to Firestore on submit ──
(function() {
  var origSetStar = window.RATINGS.setStar;
  var origSubmit  = window.RATINGS.submit;
  window._lastRatingValue = 0;
  window.RATINGS.setStar = function(n) { window._lastRatingValue = n; origSetStar.call(this, n); };
  window.RATINGS.submit = async function() {
    var rating = window._lastRatingValue || 0;
    origSubmit.call(this);
    if (!rating || !window._currentUid) return;
    var tu = window._chatCurrentUser;
    var targetUid = tu ? (tu.uid || String(tu.id)) : null;
    if (!targetUid || targetUid === window._currentUid) return;
    try {
      var fs = await import("https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js");
      var db2 = fs.getFirestore();
      await fs.setDoc(fs.doc(db2,'ratings',targetUid,'entries',window._currentUid), {
        rating: rating, ratedAt: new Date().toISOString(), raterUid: window._currentUid
      });
    } catch(e) { console.warn('RATINGS Firestore write:', e); }
  };
})();

// ── Hook People screen open → fetch real users once ──
(function() {
  var orig = window.IG.openExplore;
  window.IG.openExplore = function() {
    orig.call(this);
    if (!window._igPeopleFetched && window._currentUid) {
      window._igPeopleFetched = true;
      window._igFetchRealUsers();
    }
  };
})();

// Sync following state 2s after page load (auth resolves by then)
setTimeout(window._igInitFollowing, 2000);

// ── Override editProfile to close IG screens before opening Settings ──
// sub-ig-profile is later in DOM than sub-social (same z-index 600), so it renders
// on top — we must remove 'open' from IG screens before showing Settings.
window.IG.editProfile = function() {
  document.getElementById('sub-ig-profile').classList.remove('open');
  document.getElementById('sub-people').classList.remove('open');
  if (typeof openSub === 'function') {
    openSub('social');
    if (typeof ssOpenPanel === 'function') setTimeout(function(){ ssOpenPanel('profile-edit'); }, 150);
  }
};

// ── IG profile menu (three-dots button) ──
window.IG.menu = function() {
  var old = document.getElementById('ig-menu-sheet'); if (old) old.remove();
  var sheet = document.createElement('div');
  sheet.id = 'ig-menu-sheet';
  sheet.style.cssText = 'position:fixed;inset:0;z-index:9500;background:rgba(0,0,0,.65);backdrop-filter:none;-webkit-backdrop-filter:none;display:flex;align-items:flex-end;';
  sheet.onclick = function(e){ if (e.target === sheet) sheet.remove(); };
  sheet.innerHTML =
    '<div style="width:100%;background:#0a1628;border-radius:20px 20px 0 0;border-top:1.5px solid rgba(232,213,163,.25);padding-bottom:calc(20px + env(safe-area-inset-bottom,0px));font-family:\'DM Sans\',sans-serif;">'+
      '<div style="width:40px;height:4px;background:rgba(255,255,255,.14);border-radius:2px;margin:16px auto 20px;"></div>'+
      '<div id="ig-ms-edit" style="padding:16px 24px;display:flex;align-items:center;gap:16px;cursor:pointer;border-bottom:1px solid rgba(255,255,255,.06);">'+
        '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,.8)" stroke-width="1.8"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4z"/></svg>'+
        '<span style="font-size:16px;font-weight:600;color:#fff;">Edit profile</span>'+
      '</div>'+
      '<div id="ig-ms-share" style="padding:16px 24px;display:flex;align-items:center;gap:16px;cursor:pointer;border-bottom:1px solid rgba(255,255,255,.06);">'+
        '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,.8)" stroke-width="1.8"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>'+
        '<span style="font-size:16px;font-weight:600;color:#fff;">Share profile</span>'+
      '</div>'+
      '<div id="ig-ms-saved" style="padding:16px 24px;display:flex;align-items:center;gap:16px;cursor:pointer;border-bottom:1px solid rgba(255,255,255,.06);">'+
        '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,.8)" stroke-width="1.8"><path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/></svg>'+
        '<span style="font-size:16px;font-weight:600;color:#fff;">Saved</span>'+
      '</div>'+
      '<div id="ig-ms-settings" style="padding:16px 24px;display:flex;align-items:center;gap:16px;cursor:pointer;border-bottom:1px solid rgba(255,255,255,.06);">'+
        '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,.8)" stroke-width="1.8"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z"/></svg>'+
        '<span style="font-size:16px;font-weight:600;color:#fff;">Settings</span>'+
      '</div>'+
      '<div id="ig-ms-cancel" style="padding:16px 24px;text-align:center;cursor:pointer;">'+
        '<span style="font-size:15px;font-weight:700;color:rgba(255,100,100,.85);">Cancel</span>'+
      '</div>'+
    '</div>';
  document.body.appendChild(sheet);
  document.getElementById('ig-ms-edit').onclick    = function(){ sheet.remove(); IG.editProfile(); };
  document.getElementById('ig-ms-share').onclick   = function(){ sheet.remove(); IG.shareProfile(); };
  document.getElementById('ig-ms-saved').onclick   = function(){ sheet.remove(); IG.openSaved(); };
  document.getElementById('ig-ms-settings').onclick= function(){ sheet.remove(); if(typeof openSub==='function') openSub('social'); };
  document.getElementById('ig-ms-cancel').onclick  = function(){ sheet.remove(); };
};

// ── Share profile via Web Share API (fallback: copy link) ──
window.IG.shareProfile = function() {
  var ud = window._userDataCache || {};
  var name = ud.displayName || 'a NowssB Practitioner';
  var shareData = { title: name + ' on NowssB', text: 'Healing through word science — join me on NowssB', url: 'https://nowssb.com' };
  if (navigator.share) {
    navigator.share(shareData).catch(function(){});
  } else if (navigator.clipboard) {
    navigator.clipboard.writeText('https://nowssb.com').then(function(){
      var t = document.createElement('div');
      t.style.cssText = 'position:fixed;bottom:100px;left:50%;transform:translateX(-50%);background:rgba(6,12,24,.96);border:1px solid rgba(232,213,163,.3);border-radius:12px;padding:10px 20px;color:#e8d5a3;font-size:13px;font-weight:700;font-family:"DM Sans",sans-serif;z-index:9999;pointer-events:none;';
      t.textContent = 'Link copied';
      document.body.appendChild(t);
      setTimeout(function(){ t.remove(); }, 2000);
    });
  }
};

/* ═══════════════════════════════════════════════════════════
   11. WORD OF THE DAY
═══════════════════════════════════════════════════════════ */
window.WOTD = (function(){
  var KEY = 'nowssb_wotd_v1';

  function pick(){
    var lib = window.MASTER_WORD_LIBRARY || [];
    if(!lib.length) return null;
    var doy = Math.floor((Date.now()-new Date(new Date().getFullYear(),0,0))/86400000);
    return lib[doy % lib.length];
  }

  function render(){
    var wrap = document.getElementById('wotdCardWrap');
    if(!wrap) return;
    var w = pick(); if(!w) return;

    wrap.innerHTML =
      '<div class="wotd-card" onclick="rxStartWord(\''+w.word+'\')">'+
        '<div class="wotd-inner">'+
          '<div class="wotd-eyebrow">Word of the Day</div>'+
          '<div class="wotd-word">'+w.word+'</div>'+
          '<div class="wotd-phonetic">'+w.phonetic.toUpperCase()+'</div>'+
          '<div class="wotd-benefit">'+w.benefit+'</div>'+
          '<div class="wotd-organ-tag">'+
            '<svg width="8" height="8" viewBox="0 0 8 8" fill="rgba(200,232,245,.65)"><circle cx="4" cy="4" r="3"/></svg>'+
            w.organ.toUpperCase()+
          '</div>'+
        '</div>'+
      '</div>';
  }

  return { render:render, pick:pick };
})();

/* ═══════════════════════════════════════════════════════════
   12. AI CONVERSATION MODE PER WORD
═══════════════════════════════════════════════════════════ */
window.AICONVO = (function(){
  var _history = [];
  var _word    = null;
  var _persona = null;

  function addMsg(text, role){
    _history.push({role:role, content:text});
    var box = document.getElementById('aiConvoMessages');
    if(!box) return;
    var div = document.createElement('div');
    div.className = 'ai-msg '+(role==='user'?'user':'system');
    div.textContent = text;
    box.appendChild(div);
    box.scrollTop = box.scrollHeight;
  }

  function addTyping(){
    var box = document.getElementById('aiConvoMessages');
    if(!box) return;
    var d = document.createElement('div');
    d.className='ai-msg system'; d.id='aiConvoTyping';
    d.innerHTML='<span style="opacity:.5;letter-spacing:2px;">•••</span>';
    box.appendChild(d); box.scrollTop=box.scrollHeight;
  }
  function removeTyping(){ var d=document.getElementById('aiConvoTyping'); if(d)d.remove(); }

  return {
    open: function(wordObj){
      _word    = wordObj;
      _history = [];
      _persona = window.GROQ_PERSONAS ? (window.GROQ_PERSONAS[window._userPersona||'soundHealer']) : { name:'Sound Healer', prompt:'You are a compassionate sound healer.' };
      var overlay = document.getElementById('aiConvoOverlay');
      if(!overlay) return;
      var title = document.getElementById('aiConvoWordTitle');
      if(title) title.textContent = wordObj.word + (wordObj.phonetic?' · '+wordObj.phonetic.toUpperCase():'');
      document.getElementById('aiConvoMessages').innerHTML='';
      overlay.style.display='flex';
      // Opening message
      var open = 'I\'m '+(_persona?_persona.name:'your guide')+'. Ask me anything about "'+wordObj.word+'" — its sound, healing target ('+wordObj.organ+'), or how to deepen your practice.';
      addMsg(open,'assistant');
    },
    send: async function(){
      var inp = document.getElementById('aiConvoInput');
      if(!inp) return;
      var text = inp.value.trim(); if(!text) return;
      inp.value=''; inp.disabled=true;
      addMsg(text,'user');
      addTyping();

      var GROQ_KEY = window._groqKey || (typeof GROQ_KEY!=='undefined'?GROQ_KEY:'');
      if(!GROQ_KEY || GROQ_KEY==='PASTE_YOUR_GROQ_KEY_HERE'){
        removeTyping();
        var fallbacks = [
          'The word "'+_word.word+'" resonates with the '+_word.organ+'. Every syllable targets this system specifically.',
          'Mouth position is everything. '+_word.mouthPos,
          'Common mistake: '+_word.mistake+'. Correct this and feel the difference immediately.',
          'Practice tip: '+_word.tip,
          'The natural origin meaning: '+_word.meaning,
        ];
        addMsg(fallbacks[_history.length%fallbacks.length],'assistant');
        inp.disabled=false; return;
      }

      try{
        var sysPrompt = (_persona?_persona.prompt:'You are a sound healing guide.')+
          ' The user is asking about the NowssB word "'+_word.word+'" (phonetic: '+_word.phonetic+
          ', organ: '+_word.organ+', benefit: '+_word.benefit+
          ', meaning: '+_word.meaning+'). Answer in 2-3 sentences max. Stay in character.';

        var resp = await fetch(GROQ_CHAT_URL,{
          method:'POST',
          headers:{'Content-Type':'application/json'},
          body:JSON.stringify({
            model:'llama3-8b-8192',
            messages:[{role:'system',content:sysPrompt}].concat(_history),
            max_tokens:150, temperature:0.75
          })
        });
        var data = await resp.json();
        var reply = data.choices[0].message.content.trim();
        removeTyping(); addMsg(reply,'assistant');
      }catch(e){
        removeTyping(); addMsg('The frequency is strong. Keep practicing.','assistant');
      }
      inp.disabled=false;
    },
    close: function(){
      var o=document.getElementById('aiConvoOverlay'); if(o) o.style.display='none';
    }
  };
})();

// Expose AICONVO.open to the player — wire into Meaning tab
(function(){
  var origRender = window.renderPractice;
  if(typeof origRender!=='function') return;
  window.renderPractice = function(){
    var r = origRender.apply(this,arguments);
    // Add "Chat with AI" button to meaning panel
    setTimeout(function(){
      var mp = document.querySelector('.sp-info-full');
      if(!mp || mp.querySelector('.ai-convo-trigger')) return;
      var w = window.PRACTICE_WORDS && window.PRACTICE_WORDS[window._pwIdx];
      if(!w) return;
      var btn = document.createElement('button');
      btn.className='ai-convo-trigger';
      btn.style.cssText='width:100%;margin-top:14px;padding:11px;border-radius:12px;border:1px solid rgba(232,213,163,.25);background:rgba(232,213,163,.07);color:#e8d5a3;font-size:13px;font-weight:700;font-family:"DM Sans",sans-serif;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:7px;';
      btn.innerHTML='<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg> Ask AI about this word';
      btn.onclick=function(){ AICONVO.open(w); };
      mp.appendChild(btn);
    },60);
    return r;
  };
})();

/* ═══════════════════════════════════════════════════════════
   13. CINEMATIC ONBOARDING UPGRADE
   Replaces static 4-question form with Groq AI conversation
═══════════════════════════════════════════════════════════ */
window.ONBOARD = (function(){
  var _answers = [];
  var _step    = 0;
  var QUESTIONS = [
    { q:'What brings you to NowssB? Tell me in your own words — what do you want to heal or improve?', key:'goal' },
    { q:'How do you feel about your voice right now — confident, uncertain, or somewhere in between?', key:'voice' },
    { q:'Morning person or night owl? When do you usually have 10 quiet minutes?', key:'time' },
    { q:'On a scale of 1–10, how seriously are you ready to commit to a daily sound practice?', key:'commitment' },
  ];

  function addBubble(text, role){
    var box = document.getElementById('obConvoBox');
    if(!box) return;
    var wrap = document.createElement('div');
    wrap.style.cssText='display:flex;justify-content:'+(role==='user'?'flex-end':'flex-start')+';margin-bottom:12px;animation:fadeInUp .3s ease;';
    var bubble = document.createElement('div');
    bubble.style.cssText='max-width:82%;padding:13px 16px;border-radius:'+
      (role==='user'?'18px 4px 18px 18px':'4px 18px 18px 18px')+';'+
      'font-size:14px;font-family:"DM Sans",sans-serif;line-height:1.55;'+
      (role==='user'?'background:rgba(232,213,163,.15);color:#fff;border:1px solid rgba(232,213,163,.2);':
                     'background:rgba(255,255,255,.07);color:rgba(255,255,255,.85);');
    bubble.textContent=text;
    wrap.appendChild(bubble);
    box.appendChild(wrap);
    box.scrollTop=box.scrollHeight;
  }

  function askNext(){
    if(_step >= QUESTIONS.length){
      buildPrescription();
      return;
    }
    setTimeout(function(){
      addBubble(QUESTIONS[_step].q, 'system');
      var inp=document.getElementById('obConvoInput'); if(inp){ inp.disabled=false; inp.focus(); }
    }, 400);
  }

  async function buildPrescription(){
    addBubble('One moment while I build your personal word prescription…','system');
    var inp=document.getElementById('obConvoInput'); if(inp) inp.disabled=true;
    var btn=document.getElementById('obConvoSend'); if(btn) btn.disabled=true;

    var GROQ_KEY = window._groqKey || (typeof GROQ_KEY!=='undefined'?GROQ_KEY:'');
    var prescription;

    if(GROQ_KEY && GROQ_KEY!=='PASTE_YOUR_GROQ_KEY_HERE'){
      try{
        var prompt='User onboarding answers: '+JSON.stringify(_answers)+
          '. Based on this, write a warm 2-sentence personal word prescription intro for a NowssB user. Then say their practice is ready. Be encouraging and specific to their answers. Max 3 sentences total.';
        var resp=await fetch(GROQ_CHAT_URL,{
          method:'POST', headers:{'Content-Type':'application/json'},
          body:JSON.stringify({ model:'llama3-8b-8192', messages:[{role:'user',content:prompt}], max_tokens:120 })
        });
        var data=await resp.json();
        prescription=data.choices[0].message.content.trim();
      }catch(e){}
    }
    if(!prescription){
      prescription='Based on what you\'ve shared, I\'ve built your personal word prescription. Your daily ritual starts now — your body is ready to receive these frequencies.';
    }

    setTimeout(function(){
      addBubble(prescription,'system');
      setTimeout(function(){
        // Save answers and complete onboarding
        window._onboardingAnswers = _answers;
        if(window.saveOnboardingAnswers) window.saveOnboardingAnswers(_answers,false);
        // Show finish button
        var finishWrap=document.getElementById('obConvoFinish');
        if(finishWrap) finishWrap.style.display='flex';
      }, 1200);
    }, 800);
  }

  return {
    init: function(){
      _answers=[]; _step=0;
      var box=document.getElementById('obConvoBox'); if(box) box.innerHTML='';
      var fw=document.getElementById('obConvoFinish'); if(fw) fw.style.display='none';
      // Opening message
      setTimeout(function(){
        addBubble('Welcome to NowssB. I\'m going to ask you a few questions to build your personal word prescription. Ready?','system');
        setTimeout(function(){ askNext(); },600);
      },300);
    },
    answer: function(){
      var inp=document.getElementById('obConvoInput'); if(!inp) return;
      var text=inp.value.trim(); if(!text) return;
      inp.value='';
      addBubble(text,'user');
      _answers.push({ key:QUESTIONS[_step]?QUESTIONS[_step].key:'q'+_step, value:text });
      _step++;
      inp.disabled=true;
      askNext();
    }
  };
})();

/* ═══════════════════════════════════════════════════════════
   INIT — wire everything up on load
═══════════════════════════════════════════════════════════ */
(function(){
  // Rank badge in profile — add wrap div to existing stats block
  function addRankWrap(){
    var statsBlock=document.getElementById('profileStatsBlock'); if(!statsBlock) return;
    if(document.getElementById('profileRankWrap')) return;
    var div=document.createElement('div'); div.id='profileRankWrap';
    statsBlock.parentNode.insertBefore(div, statsBlock.nextSibling);
  }

  // Word of the Day wrap in home
  function addWotdWrap(){
    var rxWrap=document.getElementById('rxCardWrap'); if(!rxWrap) return;
    if(document.getElementById('wotdCardWrap')) return;
    var div=document.createElement('div'); div.id='wotdCardWrap'; div.style.cssText='width:100%;';
    rxWrap.parentNode.insertBefore(div, rxWrap.nextSibling);
    WOTD.render();
  }

  // Hook into profile open
  var origProfileEnter = window.profileEnterFromIntro;
  if(typeof origProfileEnter==='function'){
    window.profileEnterFromIntro = function(){
      var r = origProfileEnter.apply(this,arguments);
      setTimeout(addRankWrap,100);
      return r;
    };
  }

  // Hook into home init
  var origShowScreen = window.showScreen;
  if(typeof origShowScreen==='function'){
    window.showScreen = function(id){
      var r = origShowScreen.apply(this,arguments);
      if(id==='home') setTimeout(function(){ addWotdWrap(); }, 200);
      return r;
    };
  }

  // Add AI Persona row to settings Audio section
  setTimeout(function(){
    var audSection = document.querySelector('#sub-social .slbl');
    // Find the AUDIO & PLAYBACK section and add persona row
    var sgs = document.querySelectorAll('#sub-social .sg');
    sgs.forEach(function(sg){
      var rows = sg.querySelectorAll('.sr');
      rows.forEach(function(row){
        var label = row.querySelector('.sr-label');
        if(label && label.textContent==='Playback Speed' && !sg.querySelector('[data-persona-row]')){
          var personaRow=document.createElement('div');
          personaRow.className='sr'; personaRow.setAttribute('data-persona-row','1');
          personaRow.onclick=function(){ PERSONAS_UI.openPanel(); };
          personaRow.innerHTML='<div class="sr-icon"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="12" cy="8" r="4"/><path d="M4 20v-1a8 8 0 0116 0v1"/></svg></div>'+
            '<div class="sr-body"><div class="sr-label">AI Persona</div><div class="sr-sub" id="personaSubLabel">Sound Healer</div></div>'+
            '<svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>';
          // Insert before playback speed row
          sg.insertBefore(personaRow, row);
          // Update label when persona changes
          setInterval(function(){
            var sub=document.getElementById('personaSubLabel');
            if(sub){
              var key=window._userPersona||'soundHealer';
              var PMAP={'soundHealer':'Sound Healer','meditator':'Meditator','neuroscientist':'Neuroscientist','shaman':'Shaman','philosopher':'Philosopher','ceo':'CEO','prophet':'Prophet','warrior':'Warrior'};
              sub.textContent=PMAP[key]||key;
            }
          },1000);
        }
      });
    });

    // Wire IG people array to CHAT
    if(window.IG && window.IG._allPeople===undefined){
      // Expose PEOPLE from IG module
      var igScript = document.querySelector('script');
      // We'll set it via a global flag in the IG init
      window.IG._allPeople = window._igPeople || [];
    }
  }, 800);

  // Add resonance waveform to record tab after render
  setTimeout(function(){
    var origRender = window.renderPractice;
    if(typeof origRender!=='function') return;
    // Already patched above for AI convo; hook resonance here
    var _resInited = false;
    var _origToggle = window.pwToggleRecording;
    if(typeof _origToggle==='function'){
      window.pwToggleRecording = function(){
        var r = _origToggle.apply(this,arguments);
        // Inject resonance canvas if not present
        setTimeout(function(){
          var scoreWrap=document.getElementById('spScoreWrap');
          if(!scoreWrap) return;
          if(document.getElementById('resCanvas')) return;
          var w = window.PRACTICE_WORDS && window.PRACTICE_WORDS[window._pwIdx];
          var resHTML='<div class="resonance-wrap" id="resWrap" style="display:none;">'+
            '<div class="resonance-label">'+
              '<svg width="10" height="10" viewBox="0 0 10 10" fill="#c8e8f5"><circle cx="5" cy="5" r="4"/></svg>'+
              'Voice Resonance Overlay'+
            '</div>'+
            '<div class="resonance-canvas-wrap">'+
              '<canvas class="res-canvas" id="resCanvas" height="56"></canvas>'+
            '</div>'+
            '<div class="res-match-score" id="resMatchScore"></div>'+
          '</div>';
          scoreWrap.insertAdjacentHTML('beforeend', resHTML);
          RESONANCE.init('resCanvas', w?w.phonetic:'');
        },50);
        // Show/hide resonance wrap
        if(window._pwRecording){
          setTimeout(function(){ var rw=document.getElementById('resWrap'); if(rw) rw.style.display='block'; },100);
        } else {
          RESONANCE.stop();
        }
        return r;
      };
    }
  }, 1000);

  // Expose PEOPLE array from IG module for CHAT
  setTimeout(function(){
    // The PEOPLE array is inside the IG IIFE — expose via IG methods
    var origOpenProfile = window.IG && window.IG.openProfile;
    if(typeof origOpenProfile==='function'){
      window.IG.openProfile = function(id){
        // Intercept to grab user for chat
        window._lastOpenedProfile = id;
        return origOpenProfile.apply(this,arguments);
      };
    }
    // Patch IG message to use ID lookup
    window.IG.message = function(id){
      // Build a minimal user object from what we know
      var user = { id:id, fullName:'NowssB Practitioner', username:'practitioner', avatar:'https://i.pravatar.cc/150?img='+id, category:'Practitioner' };
      CHAT.open(user);
    };
  }, 1200);

})();

// ── NowssB Connect Hub — theme pill sync (separate ids from the Edit Profile
// switcher, same nwsb_social_theme storage) ──
window.nchSyncTheme = function () {
  var theme = 'neu';
  try { theme = localStorage.getItem('nwsb_social_theme') || 'neu'; } catch (e) {}
  var neu = document.getElementById('nch-theme-neu');
  var gl  = document.getElementById('nch-theme-glass');
  if (neu) neu.classList.toggle('active', theme === 'neu');
  if (gl)  gl.classList.toggle('active', theme === 'glass');
};
// Runs every time the Hub page opens: syncs the theme pills AND renders the
// settings toggle rows inline (so nothing requires a second popup/sheet).
window.nchOnOpen = function () {
  nchSyncTheme();
  if (typeof window.nwsbRenderSocialSettingsRows === 'function') window.nwsbRenderSocialSettingsRows();
};
