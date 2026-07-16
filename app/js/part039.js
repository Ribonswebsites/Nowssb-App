
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

  function timeStr(ts){
    if(!ts) return '';
    var d = new Date(ts);
    var h=d.getHours(), m=d.getMinutes();
    return (h<10?'0':'')+h+':'+(m<10?'0':'')+m;
  }

  function renderMessages(){
    var box = document.getElementById('chatMessages');
    if(!box) return;
    var me = window._currentUid || 'me';
    box.innerHTML = _msgs.map(function(msg){
      var isMe = msg.from === me;
      return '<div class="chat-bubble-wrap'+(isMe?' me':'')+'">'+
        '<div class="chat-bubble '+(isMe?'me':'them')+'">'+msg.text+'</div>'+
        '</div>'+
        '<div class="chat-time" style="text-align:'+(isMe?'right':'left')+';">'+timeStr(msg.ts)+'</div>';
    }).join('');
    box.scrollTop = box.scrollHeight;
  }

  function addMessage(text, fromMe){
    var me = window._currentUid || 'me';
    var msg = { from: fromMe?me:'them', text:text, ts:Date.now() };
    _msgs.push(msg);
    renderMessages();
    if(_currentUser) saveLocal(roomId(_currentUser), _msgs);

    // If Firestore is available, write to it
    if(window._db && fromMe && _currentUser){
      try{
        var rId = roomId(_currentUser);
        var colRef = window._db.collection ? window._db.collection('chats/'+rId+'/messages') : null;
        if(colRef) colRef.add(msg).catch(function(){});
      }catch(e){}
    }

    // Auto-reply simulation (remove when real Firebase connected)
    if(fromMe && (!window._db || !window._currentUid)){
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
      if(!_msgs.length){
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

      overlay.style.display = 'block';
      setTimeout(function(){ var i=document.getElementById('chatInput'); if(i) i.focus(); }, 80);

      if(window._db){
        try{
          var rId = roomId(user);
          var q = window._db.collection('chats/'+rId+'/messages').orderBy('ts');
          _unsubscribe = q.onSnapshot(function(snap){
            _msgs = snap.docs.map(function(d){ return d.data(); });
            renderMessages();
          });
        }catch(e){}
      }
    },
    send: function(){
      var inp = document.getElementById('chatInput');
      if(!inp) return;
      var text = inp.value.trim();
      if(!text) return;
      inp.value='';
      addMessage(text, true);
    },
    close: function(){
      if(_unsubscribe) try{ _unsubscribe(); }catch(e){}
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
  // Apply saved follow state
  SEED.forEach(function(p) { p.following_state = window.FOLLOW ? window.FOLLOW.isFollowing(p.id) : false; });
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
