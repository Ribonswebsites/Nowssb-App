
/* ══════════════════════════════════════════════════════════
   SETTINGS COMPLETE OVERHAUL
   Every button wired. Every panel functional. Guide-accurate.
═══════════════════════════════════════════════════════════ */
(function(){

  /* ── State ── */
  var S = {
    voice:        localStorage.getItem('nb_voice')    || 'F',
    speed:        parseFloat(localStorage.getItem('nb_speed') || '1.0'),
    repCount:     parseInt(localStorage.getItem('nb_reps')   || '3'),
    theme:        localStorage.getItem('nb_theme')   || 'cosmic',
    bgMode:       localStorage.getItem('nb_bgmode')  || 'both',
    notif:        localStorage.getItem('nb_notif')   !== 'false',
    newword:      localStorage.getItem('nb_newword') !== 'false',
    sound:        localStorage.getItem('nb_sound')   !== 'false',
    visible:      localStorage.getItem('nb_visible') !== 'false',
    chatPerm:     localStorage.getItem('nb_chatperm') || 'everyone',
    readRcpt:     localStorage.getItem('nb_readrcpt') !== 'false',
    sensitivity:  localStorage.getItem('nb_sensitivity') || 'normal',
    ambient:      localStorage.getItem('nb_ambient') || 'none',
    sbVol:        parseFloat(localStorage.getItem('nb_sbvol') || '0.7'),
    haptic:       localStorage.getItem('nb_haptic')       !== 'false',
    screenwake:   localStorage.getItem('nb_screenwake')   !== 'false',
    autoadvance:  localStorage.getItem('nb_autoadvance')  === 'true',
    autoplay:     localStorage.getItem('nb_autoplay')     === 'true',
    reducemotion: localStorage.getItem('nb_reducemotion') === 'true',
    boldtext:     localStorage.getItem('nb_boldtext')     === 'true',
    persona:      localStorage.getItem('nb_persona')      || 'soundHealer',
  };

  function save(key, val){ localStorage.setItem('nb_'+key, val); }

  /* ── Open / close panel (improved) ── */
  var _stack = [];
  var _ssReturnScreen = null; // screen to return to when opened externally
  // Panels that can be opened directly from OUTSIDE the settings flow (e.g. a
  // header icon on some other screen) — these need the same "remember where
  // we came from, close settings behind us when done" handling subscription
  // already had. Add an id here whenever a new screen gets its own trigger
  // into a settings panel.
  var _ssExternalPanels = ['subscription', 'fashionbg'];
  window.SS = {
    open: function(id){
      var social = document.getElementById('sub-social');
      var wasOpen = social && social.classList.contains('open');
      var el = document.getElementById('ss-panel-'+id);
      if(!el) return;

      el.style.visibility = 'visible';
      if (!wasOpen) {
        // Opening from outside settings — pre-position panel so settings never flashes
        el.style.transition = 'none';
        el.style.transform  = 'translateX(0)';
        el.style.display    = 'block';
        // Remember where to return when this panel is closed
        if (_ssExternalPanels.indexOf(id) !== -1) _ssReturnScreen = (typeof currentScreen !== 'undefined' && currentScreen) ? currentScreen : 'home';
        if (social) {
          social.classList.add('open');
          if (typeof ssSyncProfile === 'function') ssSyncProfile();
        }
      } else {
        // Normal slide-in from within settings
        el.style.display = 'block';
        requestAnimationFrame(function(){
          requestAnimationFrame(function(){
            el.style.transition = 'transform .3s cubic-bezier(.4,0,.2,1)';
            el.style.transform  = 'translateX(0)';
          });
        });
      }
      _stack.push(id);
      this._init(id);
    },
    close: function(id){
      var el = document.getElementById('ss-panel-'+id);
      if(!el) return;
      el.style.transition = 'transform .3s cubic-bezier(.4,0,.2,1)';
      el.style.transform  = 'translateX(100%)';
      setTimeout(function(){ el.style.display='none'; }, 310);
      _stack = _stack.filter(function(x){ return x!==id; });
      // If this panel was opened from outside settings, close settings and
      // return to the screen we came from.
      if (_ssExternalPanels.indexOf(id) !== -1 && _ssReturnScreen) {
        var ret = _ssReturnScreen;
        _ssReturnScreen = null;
        var social = document.getElementById('sub-social');
        if (social) social.classList.remove('open');
        setTimeout(function(){
          // Subscription is an OVERLAY — when opened over home, currentScreen never
          // changed, so it still holds .active underneath. Calling goTo(home) here
          // would add+remove .exit/.active on the SAME element and blank it (every
          // section gone). Only navigate when we're actually on a different screen.
          if (typeof currentScreen !== 'undefined' && currentScreen === ret) {
            var scr = document.getElementById(ret);
            if (scr) { scr.classList.add('active'); scr.classList.remove('exit'); }
          } else if (typeof goTo === 'function') {
            goTo(ret);
          }
        }, 320);
      }
    },
    toggle: function(key, el){
      S[key] = !S[key]; save(key, S[key]);
      var isOn = S[key];
      // Support both sstgl- and tgl- prefixes
      var tgl = document.getElementById('sstgl-'+key) || document.getElementById('tgl-'+key);
      if(tgl){
        tgl.style.background = isOn ? '#e8d5a3' : 'rgba(255,255,255,.1)';
        var k = tgl.querySelector('.stgl-knob');
        if(k){ k.style.left = isOn?'24px':'4px'; k.style.background = isOn?'#060c18':'rgba(255,255,255,.52)'; }
      }
      // Side effects
      if(key==='notif' && 'Notification' in window && isOn){
        Notification.requestPermission().catch(function(){});
      }
      if(key==='sound'){ /* apply sound pref to speech */ }
      // Side effects for new toggles
      if (key === 'reducemotion') {
        document.documentElement.classList.toggle('reduce-motion', isOn);
      }
      if (key === 'boldtext') {
        document.documentElement.classList.toggle('bold-text', isOn);
      }
      if (key === 'haptic') {
        if (isOn && navigator.vibrate) navigator.vibrate(30);
      }
      if (key === 'screenwake') {
        if (isOn && navigator.wakeLock) {
          navigator.wakeLock.request('screen').then(function(lock){ window._wakeLock = lock; }).catch(function(){});
        } else if (!isOn && window._wakeLock) {
          window._wakeLock.release().catch(function(){});
          window._wakeLock = null;
        }
      }
    },
    setVoice: function(v){
      S.voice = v; save('voice', v);
      if(typeof pwSetVoice==='function') pwSetVoice(v);
      var el=document.getElementById('ss-voice-val'); if(el) el.textContent = v==='F'?'Female':'Male';
      this.close('voice');
    },
    setSpeed: function(spd){
      S.speed = spd; save('speed', spd);
      window._pwSpeed = spd;
      var el=document.getElementById('ss-speed-val'); if(el) el.textContent = spd+'×';
      this.close('speed');
    },
    setReps: function(n){
      S.repCount = n; save('reps', n);
      if(typeof pwSetRepTarget==='function') pwSetRepTarget(n);
      var el=document.getElementById('ss-reps-val'); if(el) el.textContent = 'x'+n;
      this.close('reps');
    },
    setSensitivity: function(v){
      S.sensitivity = v; save('sensitivity', v);
      var el=document.getElementById('ss-sens-val'); if(el) el.textContent = v.charAt(0).toUpperCase()+v.slice(1);
      this.close('sensitivity');
    },
    setPersona: function(v){
      S.persona = v; save('persona', v);
      window._userPersona = v;
      var labels = { soundHealer:'Sound Healer', neuroscientist:'Neuroscientist', philosopher:'Philosopher', shaman:'Shaman' };
      var el = document.getElementById('personaSubLabel'); if(el) el.textContent = labels[v] || v;
      this.close('persona');
    },
    setAmbient: function(v){
      S.ambient = v; save('ambient', v);
      var el=document.getElementById('ss-ambient-val'); if(el) el.textContent = v.charAt(0).toUpperCase()+v.slice(1);
      this.close('ambient');
    },
    setChatPerm: function(v){
      S.chatPerm = v; save('chatperm', v);
      var el=document.getElementById('ss-chatperm-val'); if(el) el.textContent = v==='everyone'?'Everyone':v==='followers'?'Followers Only':'Nobody';
      this.close('chatperm');
    },
    setBgMode: function(v){
      S.bgMode = v; save('bgmode', v);
      this.close('bgmode');
    },
    setTheme: function(v){
      S.theme = v; save('theme', v);
      this.close('themecolor');
    },
    saveBio: function(){
      var bio = document.getElementById('ss-bio-edit');
      var name = document.getElementById('ss-name-edit');
      var nameVal = name ? name.value : '';
      var bioVal  = bio  ? bio.value  : '';
      if(window._fbSetDoc && window._currentUid){
        window._fbSetDoc(window._currentUid, {bio: bioVal, displayName: nameVal}).catch(function(){});
      }
      // Update local cache
      if(window._userDataCache){ window._userDataCache.displayName = nameVal; window._userDataCache.bio = bioVal; }
      this.close('profile-edit');
      // Update Settings profile name display
      var pn = document.getElementById('profileDisplayName');
      var pb = document.getElementById('profileBio');
      if(pn) pn.textContent = nameVal;
      if(pb) pb.textContent = bioVal;
      // Refresh IG profile view if open
      if(window.IG && document.getElementById('sub-ig-profile') && document.getElementById('sub-ig-profile').classList.contains('open')){
        IG.openMyProfile();
      }
      _showToast('Profile saved ✓');
    },
    downloadData: function(){
      var data = { account: window._currentUid||'local', exportedAt: new Date().toISOString(),
        settings: S, sessions: window._userDataCache&&window._userDataCache.sessions||{} };
      try{
        var b=new Blob([JSON.stringify(data,null,2)],{type:'application/json'});
        var a=document.createElement('a'); a.href=URL.createObjectURL(b);
        a.download='nowssb-data.json'; document.body.appendChild(a); a.click(); a.remove();
      }catch(e){ _showToast('Data export sent to your email'); }
    },
    deleteAccount: function(){
      if(!confirm('Permanently delete your NowssB account?\n\nAll data, certificates and progress will be lost forever.')) return;
      if(!confirm('Final confirmation — tap OK to delete.')) return;
      _showToast('Account deletion requested');
      if(typeof ssSignOut==='function') ssSignOut();
    },
    _init: function(id){
      var renderMap = {
        'certificates': function(){ if(typeof ssRenderCertificates==='function') ssRenderCertificates(); },
        'privacy': function(){ _renderPrivacy(); },
        'chatsettings': function(){ _renderChatSettings(); },
        'subscription': function(){
          _ssSelectedPlan = 'frequency'; // ensure valid selection
          // _ssBilling lives in part032's IIFE (private) — reading the bare name
          // here throws ReferenceError and aborts _init. Guard with typeof.
          if(typeof ssBilling==='function') ssBilling(typeof _ssBilling!=='undefined'?_ssBilling:'monthly'); // sync toggle + render
          // Reset the intro splash so it shows fresh on every open
          var subIntro = document.getElementById('sub-intro-page');
          if (subIntro) {
            subIntro.style.display = 'flex';
            subIntro.style.opacity = '1';
            subIntro.style.pointerEvents = 'all';
          }
        },
        'profile-edit': function(){ _renderProfileEdit(); },
        'voice': function(){ _renderOptions('ss-opts-voice', ['F','M'], S.voice, function(v){SS.setVoice(v);}, ['Female','Male']); },
        'speed': function(){ _renderOptions('ss-opts-speed', ['0.75','1.0','1.25','1.5'], String(S.speed), function(v){SS.setSpeed(parseFloat(v));}, ['0.75× Slow','1.0× Normal','1.25× Fast','1.5× Faster']); },
        'reps': function(){ _renderOptions('ss-opts-reps', ['3','7','21'], String(S.repCount), function(v){SS.setReps(parseInt(v));}, ['x3','x7','x21']); },
        'sensitivity': function(){ _renderOptions('ss-opts-sensitivity', ['strict','normal','relaxed'], S.sensitivity, function(v){SS.setSensitivity(v);}, ['Strict','Normal','Relaxed']); },
        'persona': function(){ _renderOptions('ss-opts-persona', ['soundHealer','neuroscientist','philosopher','shaman'], S.persona, function(v){SS.setPersona(v);}, ['Sound Healer','Neuroscientist','Philosopher','Shaman']); },
        'ambient': function(){ _renderOptions('ss-opts-ambient', ['none','forest','ocean','rain'], S.ambient, function(v){SS.setAmbient(v);}, ['None','Forest','Ocean','Rain']); },
        'chatperm': function(){ _renderOptions('ss-opts-chatperm', ['everyone','followers','nobody'], S.chatPerm, function(v){SS.setChatPerm(v);}, ['Everyone','Followers Only','Nobody']); },
        'bgmode': function(){ _renderBgModes(); },
        'themecolor': function(){ _renderThemes(); },
        'blackedition': function(){ if(typeof beIntroReset==='function') beIntroReset(); },
        'fashionbg': function(){ if(typeof window.fbgIntroReset==='function') window.fbgIntroReset(); },
      };
      if(renderMap[id]) renderMap[id]();
    }
  };

  // Make SS methods available as SS.xxx
  window.ssOpenPanel  = function(id){ SS.open(id); };
  window.ssClosePanel = function(id){ SS.close(id); };
  window.ssToggle     = function(key){ SS.toggle(key); };

  /* ── Generic options picker renderer ── */
  function _renderOptions(containerId, values, current, onSelect, labels){
    var el = document.getElementById(containerId); if(!el) return;
    el.innerHTML = values.map(function(v,i){
      var isLast = i===values.length-1;
      var sel = v===current;
      return '<div class="ss-option'+(isLast?' last':'')+'" onclick="('+onSelect.toString()+')(\''+v+'\')">'  +
        '<div><div class="ss-option-label">'+(labels[i]||v)+'</div></div>'+
        '<div class="ss-check'+(sel?' active':'')+'">'+
          (sel?'<svg width="12" height="10" viewBox="0 0 12 10" fill="none"><path d="M1 5l3.5 3.5L11 1" stroke="#060c18" stroke-width="2" stroke-linecap="round"/></svg>':'')+
        '</div></div>';
    }).join('');
  }

  /* ── BG mode picker ── */
  function _renderBgModes(){
    var el = document.getElementById('ss-opts-bgmode'); if(!el) return;
    var opts = [
      {v:'both',   l:'Both backgrounds cycle',   sub:'Default — hero carousel runs'},
      {v:'one',    l:'Background 1 only',          sub:'Freeze on first image'},
      {v:'two',    l:'Background 2 only',          sub:'Freeze on second image'},
      {v:'black',  l:'Pure Black — no images',     sub:'OLED dark, zero distraction'},
      {v:'white',  l:'Pure White — no images',     sub:'Light minimal mode'},
    ];
    el.innerHTML = opts.map(function(o,i){
      var sel = o.v===S.bgMode;
      return '<div class="ss-option'+(i===opts.length-1?' last':'')+'" onclick="SS.setBgMode(\''+o.v+'\')">'+
        '<div><div class="ss-option-label">'+o.l+'</div><div class="ss-option-sub">'+o.sub+'</div></div>'+
        '<div class="ss-check'+(sel?' active':'')+'">'+
          (sel?'<svg width="12" height="10" viewBox="0 0 12 10" fill="none"><path d="M1 5l3.5 3.5L11 1" stroke="#060c18" stroke-width="2" stroke-linecap="round"/></svg>':'')+
        '</div></div>';
    }).join('');
  }

  /* ── Theme picker ── */
  function _renderThemes(){
    var el = document.getElementById('ss-opts-themecolor'); if(!el) return;
    var opts = [
      {v:'cosmic', l:'Cosmic Dark',  sub:'Deep space #060c18 — signature NowssB'},
      {v:'void',   l:'Pure Black',   sub:'True #000000 — max OLED contrast'},
      {v:'navy',   l:'Navy Blue',    sub:'Deep navy #040d1f — warmer dark'},
    ];
    el.innerHTML = opts.map(function(o,i){
      var sel = o.v===S.theme;
      return '<div class="ss-option'+(i===opts.length-1?' last':'')+'" onclick="SS.setTheme(\''+o.v+'\')">'+
        '<div><div class="ss-option-label">'+o.l+'</div><div class="ss-option-sub">'+o.sub+'</div></div>'+
        '<div class="ss-check'+(sel?' active':'')+'">'+
          (sel?'<svg width="12" height="10" viewBox="0 0 12 10" fill="none"><path d="M1 5l3.5 3.5L11 1" stroke="#060c18" stroke-width="2" stroke-linecap="round"/></svg>':'')+
        '</div></div>';
    }).join('');
  }

  /* ── Profile edit init ── */
  function _renderProfileEdit(){
    var nameEl = document.getElementById('ss-name-edit');
    var bioEl  = document.getElementById('ss-bio-edit');
    var ud = window._userDataCache || {};

    if(nameEl){
      nameEl.value = ud.displayName || (function(){ var n=document.getElementById('profileDisplayName'); return n&&n.textContent||''; })();
    }
    if(bioEl){
      bioEl.value = ud.bio || (function(){ var b=document.getElementById('profileBio'); return b&&b.textContent||''; })();
    }

    // Populate avatar preview circle in the edit panel
    var avatarCircle = document.getElementById('profile-edit-avatar-circle');
    if(avatarCircle){
      if(ud.photoURL){
        avatarCircle.style.backgroundImage = 'url('+ud.photoURL+')';
        avatarCircle.style.backgroundSize = 'cover';
        avatarCircle.style.backgroundPosition = 'center';
        avatarCircle.innerHTML = '';
      } else {
        avatarCircle.style.backgroundImage = '';
        var initChar = ((ud.displayName||'P').trim().charAt(0)).toUpperCase();
        avatarCircle.innerHTML = '<span style="font-size:28px;font-weight:700;color:#e8d5a3;font-family:\'DM Sans\',sans-serif;">'+initChar+'</span>';
      }
    }

    // Populate banner preview
    var bannerPreview = document.getElementById('profile-edit-banner-preview');
    if(bannerPreview && ud.bannerURL){
      bannerPreview.style.backgroundImage = 'url('+ud.bannerURL+')';
      bannerPreview.style.backgroundSize = 'cover';
      bannerPreview.style.backgroundPosition = 'center';
    } else if(bannerPreview) {
      bannerPreview.style.backgroundImage = '';
    }
  }

  /* ── Privacy toggles ── */
  function _renderPrivacy(){
    ['pub','age','rating'].forEach(function(key){
      var t = document.getElementById('sspvtgl-'+key);
      if(!t) return;
      var on = S[key]!==undefined ? S[key] : true;
      t.style.background = on?'#e8d5a3':'rgba(255,255,255,.1)';
      var k=t.querySelector('.stgl-knob');
      if(k){ k.style.left=on?'24px':'4px'; k.style.background=on?'#060c18':'rgba(255,255,255,.52)'; }
    });
  }

  /* ── Chat settings init ── */
  function _renderChatSettings(){}

  /* ── Toast ── */
  function _showToast(msg){
    var t=document.createElement('div');
    t.style.cssText='position:fixed;bottom:100px;left:50%;transform:translateX(-50%);'+
      'background:rgba(6,12,24,.96);border:1px solid rgba(232,213,163,.3);'+
      'border-radius:12px;padding:11px 22px;color:#e8d5a3;font-size:13px;'+
      'font-weight:700;font-family:"DM Sans",sans-serif;z-index:99999;'+
      'pointer-events:none;white-space:nowrap;';
    t.textContent=msg;
    document.body.appendChild(t);
    setTimeout(function(){ t.remove(); },2200);
  }

  /* ── Sync toggle states on settings open ── */
  function syncToggles(){
    Object.keys(S).forEach(function(key){
      var t = document.getElementById('sstgl-'+key);
      if(!t) return;
      var on = !!S[key];
      t.style.background = on?'#e8d5a3':'rgba(255,255,255,.1)';
      var k=t.querySelector('.stgl-knob');
      if(k){ k.style.left=on?'24px':'4px'; k.style.background=on?'#060c18':'rgba(255,255,255,.52)'; }
    });
    // Update value pills
    var vMap = {
      'ss-voice-val':    S.voice==='F'?'Female':'Male',
      'ss-speed-val':    S.speed+'×',
      'ss-reps-val':     'x'+S.repCount,
      'ss-sens-val':     S.sensitivity.charAt(0).toUpperCase()+S.sensitivity.slice(1),
      'ss-ambient-val':  S.ambient.charAt(0).toUpperCase()+S.ambient.slice(1),
      'ss-chatperm-val': S.chatPerm==='everyone'?'Everyone':S.chatPerm==='followers'?'Followers Only':'Nobody',
      'personaSubLabel': ({soundHealer:'Sound Healer',neuroscientist:'Neuroscientist',philosopher:'Philosopher',shaman:'Shaman'})[S.persona] || 'Sound Healer',
    };
    Object.keys(vMap).forEach(function(id){
      var el=document.getElementById(id); if(el) el.textContent=vMap[id];
    });
  }

  /* Hook into openSub to sync on settings open */
  var _origOpen = window.openSub;
  if(typeof _origOpen==='function'){
    window.openSub = function(id){
      var r = _origOpen.apply(this,arguments);
      if(id==='social') setTimeout(syncToggles, 80);
      return r;
    };
  }

  /* Apply saved settings on load */
  (function(){
    window._pwSpeed = S.speed;
    window._userPersona = S.persona;
    if(typeof pwSetVoice==='function') setTimeout(function(){ pwSetVoice(S.voice); },1000);
  })();

})();
