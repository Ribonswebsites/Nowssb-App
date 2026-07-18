
// ══════════════════════════════════════════════════════════════
//  Settings + Discover — vanilla JS controller
// ══════════════════════════════════════════════════════════════

(function() {

// ── State ──────────────────────────────────────────────────
var _ssToggles = { sound:true, notif:true, newword:true, visible:true, pub:true, age:false, rating:true };
var _ssBilling = 'monthly';
var _ssSelectedPlan = 'frequency';
var _ssDiscoverFilter = 'all';
var _ssViewUser = null;
var _ssMyRating = 0;
var _ssChatMsgs = [{ from:'them', text:'Which word helped you the most so far?' }];
var _ssOpenPanels = [];

// ── Mock data ──────────────────────────────────────────────
var SS_USERS = [
  { id:1, name:'Kavya Singh',  bio:'Word without dictionary. Frequency is truth.',         tier:'elite', words:211, sentences:67,  clarity:97, dedication:99, resonance:4.9,  rank:1,  age:29 },
  { id:2, name:'Aryan Mehta',  bio:'Sound practice every morning, 47-day streak.',         tier:'elite', words:124, sentences:38,  clarity:94, dedication:89, resonance:4.8,  rank:3,  age:27 },
  { id:3, name:'Priya Nair',   bio:'Healing my body one word at a time.',                  tier:'pro',   words:82,  sentences:21,  clarity:88, dedication:76, resonance:4.6,  rank:11, age:24 },
  { id:4, name:'Rohan Desai',  bio:'Morning practice since Jan 2026. Building the habit.', tier:'pro',   words:63,  sentences:15,  clarity:79, dedication:92, resonance:4.4,  rank:18, age:31 },
  { id:5, name:'Aisha Patel',  bio:'Natural origin sounds healed my anxiety.',             tier:'elite', words:188, sentences:54,  clarity:96, dedication:95, resonance:4.85, rank:2,  age:26 },
];

var SS_PLANS = [
  {
    id:'resonance', name:'Resonance',
    tagline:'The full frequency. The complete practice.',
    color:'#c8e8f5', badge:'',
    price:{ monthly:4.99, yearly:49.99 },
    features:[
      [true, 'Unlimited words per day'],
      [true, 'All 5 player modes (Listen, Repeat, Speak, Library, AI)'],
      [true, 'AI pronunciation scoring'],
      [true, 'All 20 health categories'],
      [true, 'AI daily word prescription'],
      [true, 'The Word Atelier — acquire up to 10 words/month'],
      [true, 'Enhanced profile (bio, banner)'],
    ]
  },
  {
    id:'frequency', name:'Frequency',
    tagline:'Healing is your identity. This is the full edition.',
    color:'#e8d5a3', badge:'Most Popular',
    price:{ monthly:9.99, yearly:99.99 },
    features:[
      [true, 'Everything in Resonance'],
      [true, 'Voice Resonance Score'],
      [true, 'Sentence Alchemy — personalised AI sentences'],
      [true, 'Full AI Conversation with session memory'],
      [true, 'Premium certificate designs + export'],
      [true, 'Priority chat + exclusive community access'],
      [true, 'Healing Body Map — full organ tracking'],
    ]
  },
  {
    id:'frequencyX', name:'Frequency X',
    tagline:'Beyond practice. This is mastery.',
    color:'#f0f0f0', badge:'Mastery',
    price:{ monthly:19.99, yearly:199.99 },
    features:[
      [true, 'Everything in Frequency'],
      [true, 'Custom words — 5 requests/month (team-crafted)'],
      [true, 'Word Drop — 48h early access before anyone'],
      [true, 'Premium studio-quality voice'],
      [true, '1:1 monthly Shabdapathy session (video call)'],
      [true, 'Profile badge: Frequency X (gold + verified)'],
      [true, 'Premium support (24h response)'],
    ]
  },
];


// ── Helpers ────────────────────────────────────────────────
function badgeClass(tier) {
  if (tier==='frequencyX'||tier==='elite_x') return 'badge-elite';
  if (tier==='frequency'||tier==='elite')    return 'badge-pro';
  if (tier==='resonance'||tier==='pro')      return 'badge-pro';
  return 'badge-free';
}
function badgeLabel(tier) {
  if (tier==='frequencyX'||tier==='elite_x') return 'FREQUENCY X';
  if (tier==='frequency'||tier==='elite')    return 'FREQUENCY';
  if (tier==='resonance'||tier==='pro')      return 'RESONANCE';
  return 'TRIAL';
}
function chevSvg() { return '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,.22)" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>'; }
function checkSvg(color) { return '<svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="'+color+'" stroke-width="2.5"><path d="M20 6L9 17l-5-5"/></svg>'; }

// ── Tab switch ─────────────────────────────────────────────
window.ssSwitchTab = function(tab) {
  ['settings','discover'].forEach(function(t) {
    document.getElementById('ss-tab-'+t).classList.toggle('active', t===tab);
    document.getElementById('ss-content-'+t).classList.toggle('active', t===tab);
  });
  if (tab==='discover') ssRenderDiscover();
};

// ── Toggle ─────────────────────────────────────────────────
window.ssToggle = function(key) {
  _ssToggles[key] = !_ssToggles[key];
  var el = document.getElementById('tgl-'+key);
  if (!el) return;
  var knob = el.querySelector('.stgl-knob');
  el.style.background = _ssToggles[key] ? '#e8d5a3' : 'rgba(255,255,255,0.1)';
  knob.style.left = _ssToggles[key] ? '24px' : '4px';
  knob.style.background = _ssToggles[key] ? '#060c18' : 'rgba(255,255,255,.52)';
};

// ── Panel navigation ───────────────────────────────────────
window.ssOpenPanel = function(id) {
  var el = document.getElementById('ss-panel-'+id);
  if (!el) return;
  el.style.display = (id === 'chat' || id === 'support') ? 'flex' : 'block';
  // Force reflow then animate
  el.style.transform = 'translateX(100%)';
  requestAnimationFrame(function() {
    requestAnimationFrame(function() {
      el.style.transition = 'transform .28s cubic-bezier(.4,0,.2,1)';
      el.style.transform = 'translateX(0)';
    });
  });
  _ssOpenPanels.push(id);
  // Init panel data
  if (id==='subscription') {
    ssRenderPlans();
    // Reset intro page so it shows fresh each time
    var subIntro = document.getElementById('sub-intro-page');
    if (subIntro) {
      subIntro.style.display = 'flex';
      subIntro.style.opacity = '1';
      subIntro.style.pointerEvents = 'all';
    }
  }
  if (id==='user-profile' && _ssViewUser) ssRenderUserProfile(_ssViewUser);
  if (id==='intro-settings' && typeof ispIntroReset === 'function') ispIntroReset();
};

window.ssClosePanel = function(id) {
  var el = document.getElementById('ss-panel-'+id);
  if (!el) return;
  el.style.transition = 'transform .28s cubic-bezier(.4,0,.2,1)';
  el.style.transform = 'translateX(100%)';
  setTimeout(function() { el.style.display = 'none'; }, 300);
  _ssOpenPanels = _ssOpenPanels.filter(function(p) { return p!==id; });
};

// ── Support Chat ───────────────────────────────────────────
var _supHistory = []; // conversation history for context

var SUP_SYSTEM = `You are the NowssB support assistant — friendly, concise, and knowledgeable about the app.

NowssB is a healing word-science app based on Shabdapathy — the study of natural-origin phonetic vibrations and their effect on organs and wellbeing. Users practice Sanskrit and natural-origin words by listening and repeating them. The app's AI scores their pronunciation.

Key facts to know:
- Plans: Free Trial (7 days full access) → Resonance ($4.99/mo · $49.99/yr) → Frequency ($9.99/mo · $99.99/yr) → Frequency X ($19.99/mo · $199.99/yr)
- Payments via Razorpay. Cancel anytime from Settings → Your Plan.
- Pronunciation is scored 0-100 based on phonetic match. 90%+ three times = Word Mastery.
- Word Atelier: browse and acquire words. Resonance: 10/month, Frequency+: unlimited.
- Sentence Alchemy: AI builds a healing sentence from your practiced words after each session.
- AI conversation, Voice Resonance Score — Frequency tier and above.
- Custom word requests: Frequency (2/mo), Frequency X (5/mo personally crafted by the NowssB team).
- Support email: nowssbonline@gmail.com

Answer support questions clearly in 1-3 sentences. If unsure, say so honestly. Never make up features. Do not use emojis.`;

window.supSend = async function() {
  var input = document.getElementById('sup-input');
  var msgs  = document.getElementById('sup-msgs');
  if (!input || !msgs) return;
  var text = (input.value || '').trim();
  if (!text) return;

  // Render user message
  input.value = ''; input.style.height = 'auto';
  msgs.innerHTML += '<div class="sup-msg sup-me"><div class="sup-bubble">' + _sanitizeHtml(text) + '</div></div>';

  // Hide quick questions after first send
  var quick = document.getElementById('sup-quick');
  if (quick) quick.style.display = 'none';

  // Typing indicator
  var typingId = 'sup-typing-' + Date.now();
  msgs.innerHTML += '<div class="sup-msg sup-them sup-typing" id="' + typingId + '"><div class="sup-bubble">Thinking…</div></div>';
  msgs.scrollTop = msgs.scrollHeight;

  // Build conversation history
  _supHistory.push({ role: 'user', content: text });

  try {
    var reply = await callAI(
      _supHistory.slice(), // pass full history for context
      { model: 'claude-haiku-4-5', max_tokens: 300, system: SUP_SYSTEM }
    );
    reply = (reply || 'I don\'t have an answer for that right now. Email us at nowssbonline@gmail.com.').trim();
    _supHistory.push({ role: 'assistant', content: reply });

    var typing = document.getElementById(typingId);
    if (typing) typing.outerHTML = '<div class="sup-msg sup-them"><div class="sup-bubble">' + _sanitizeHtml(reply) + '</div></div>';
  } catch(e) {
    var typing = document.getElementById(typingId);
    if (typing) typing.outerHTML = '<div class="sup-msg sup-them"><div class="sup-bubble">Something went wrong. Please email nowssbonline@gmail.com.</div></div>';
  }
  msgs.scrollTop = msgs.scrollHeight;
};

window.supSendQuick = function(btn) {
  var input = document.getElementById('sup-input');
  if (!input) return;
  input.value = btn.textContent;
  supSend();
};

// ── Sign out ───────────────────────────────────────────────
window.ssSignOut = function() {
  // Close every open overlay/sub-screen first so nothing covers the login page.
  try { document.querySelectorAll('.sub-screen.open').forEach(function(el){ el.classList.remove('open'); }); } catch(e) {}
  ['nwsb-social-settings','ig-social-nav'].forEach(function(id){ var e=document.getElementById(id); if(e){ e.classList.remove('open'); if(id==='ig-social-nav') e.style.display='none'; } });
  try { if (typeof closeSub === 'function') closeSub('social'); } catch(e) {}
  // Real sign-out: clears the session, signs out of Firebase and redirects to
  // the LOGIN screen (fbSignOut does goTo('login')). ssSignOut previously called
  // an undefined handleSignOut / a module-scoped signOut, so it never signed out
  // and just fell back to the home page.
  if (typeof window.fbSignOut === 'function') { window.fbSignOut(); return; }
  try { if (typeof goTo === 'function') goTo('login'); } catch(e) {}
};

  // ── Words per Session ──────────────────────────────────────────
  var WPS_OPTS = [3, 5, 7, 10];
  var WPS_LABELS = {3:'3 words per practice', 5:'5 words per practice', 7:'7 words per practice', 10:'10 words per practice'};
  window.ssCycleWordsPerSession = function(row) {
    var cur = parseInt(localStorage.getItem('nb_wps') || '5');
    var i = WPS_OPTS.indexOf(cur); if (i < 0) i = 1;
    var next = WPS_OPTS[(i + 1) % WPS_OPTS.length];
    localStorage.setItem('nb_wps', next);
    window._pwWordsPerSession = next;
    var pill = document.getElementById('ss-wps-pill');
    var sub  = document.getElementById('ss-wps-sub');
    if (pill) pill.textContent = next;
    if (sub)  sub.textContent  = WPS_LABELS[next];
  };

  // ── Repetitions per Word ───────────────────────────────────────
  var REPS_OPTS = [3, 7, 11, 21];
  var REPS_LABELS = {3:'3× per word', 7:'7× per word', 11:'11× per word', 21:'21× per word'};
  window.ssCycleReps = function(row) {
    var cur = parseInt(localStorage.getItem('nb_reps') || '7');
    var i = REPS_OPTS.indexOf(cur); if (i < 0) i = 1;
    var next = REPS_OPTS[(i + 1) % REPS_OPTS.length];
    localStorage.setItem('nb_reps', next);
    window._pwRepCount = next;
    var pill = document.getElementById('ss-reps-pill');
    var sub  = document.getElementById('ss-reps-sub');
    if (pill) pill.textContent = next + '×';
    if (sub)  sub.textContent  = REPS_LABELS[next];
  };

  // ── Scoring Sensitivity ────────────────────────────────────────
  var SENS_OPTS = ['strict','normal','relaxed'];
  var SENS_LABELS = {strict:'Strict — high accuracy required', normal:'Normal — standard match threshold', relaxed:'Relaxed — forgiving match'};
  var SENS_PILLS  = {strict:'Strict', normal:'Normal', relaxed:'Relaxed'};
  window.ssCycleSensitivity = function(row) {
    var cur = localStorage.getItem('nb_sensitivity') || 'normal';
    var i = SENS_OPTS.indexOf(cur); if (i < 0) i = 1;
    var next = SENS_OPTS[(i + 1) % SENS_OPTS.length];
    localStorage.setItem('nb_sensitivity', next);
    window._pwSensitivity = next;
    var pill = document.getElementById('ss-sens-pill');
    var sub  = document.getElementById('ss-sens-sub');
    if (pill) pill.textContent = SENS_PILLS[next];
    if (sub)  sub.textContent  = SENS_LABELS[next];
  };

  // ── Ambient Sound ──────────────────────────────────────────────
  var AMBIENT_OPTS = ['off','forest','ocean','rain'];
  var AMBIENT_LABELS = {'off':'Off — silence during practice','forest':'Forest — birds & wind','ocean':'Ocean — waves & tide','rain':'Rain — gentle rainfall'};
  var AMBIENT_PILLS  = {'off':'Off','forest':'Forest','ocean':'Ocean','rain':'Rain'};
  var _ambientAudio  = null;
  var AMBIENT_URLS   = {
    forest: 'https://assets.mixkit.co/sfx/preview/mixkit-forest-birds-ambience-1210.mp3',
    ocean:  'https://assets.mixkit.co/sfx/preview/mixkit-sea-waves-loop-1196.mp3',
    rain:   'https://assets.mixkit.co/sfx/preview/mixkit-light-rain-loop-2393.mp3'
  };
  window.ssCycleAmbient = function(row) {
    var cur = localStorage.getItem('nb_ambient') || 'off';
    var i = AMBIENT_OPTS.indexOf(cur); if (i < 0) i = 0;
    var next = AMBIENT_OPTS[(i + 1) % AMBIENT_OPTS.length];
    localStorage.setItem('nb_ambient', next);
    window._practiceAmbient = next;
    var pill = document.getElementById('ss-ambient-pill');
    var sub  = document.getElementById('ss-ambient-sub');
    if (pill) pill.textContent = AMBIENT_PILLS[next];
    if (sub)  sub.textContent  = AMBIENT_LABELS[next];
    // Preview: play a 2-second clip of the selected ambient sound
    if (_ambientAudio) { _ambientAudio.pause(); _ambientAudio = null; }
    if (next !== 'off' && AMBIENT_URLS[next]) {
      _ambientAudio = new Audio(AMBIENT_URLS[next]);
      _ambientAudio.volume = 0.25;
      _ambientAudio.play().catch(function(){});
      setTimeout(function(){ if (_ambientAudio){ _ambientAudio.pause(); _ambientAudio=null; } }, 2500);
    }
  };

  // ── Text Size ──────────────────────────────────────────────────
  var TSIZE_OPTS   = ['s','m','l'];
  var TSIZE_LABELS = {s:'Small — compact layout', m:'Medium — default', l:'Large — easier reading'};
  var TSIZE_PILLS  = {s:'S', m:'M', l:'L'};
  var TSIZE_SCALES = {s:'0.9', m:'1', l:'1.12'};
  window.ssCycleTextSize = function(row) {
    var cur = localStorage.getItem('nb_textsize') || 'm';
    var i = TSIZE_OPTS.indexOf(cur); if (i < 0) i = 1;
    var next = TSIZE_OPTS[(i + 1) % TSIZE_OPTS.length];
    localStorage.setItem('nb_textsize', next);
    document.documentElement.style.setProperty('--app-text-scale', TSIZE_SCALES[next]);
    document.documentElement.setAttribute('data-textsize', next);
    var pill = document.getElementById('ss-textsize-pill');
    var sub  = document.getElementById('ss-textsize-sub');
    if (pill) pill.textContent = TSIZE_PILLS[next];
    if (sub)  sub.textContent  = TSIZE_LABELS[next];
  };

  // ── Nav Bar Style ────────────────────────────────────────────
  var NAV_OPTS   = ['glass','neo','solid'];
  window.NAV_PILLS  = {glass:'Glass', neo:'Neo', solid:'Solid'};
  window.NAV_LABELS = {glass:'Glassmorphism — frosted translucent', neo:'Neumorphism — deep shadow raised', solid:'Default — solid dark'};
  window._applyNavStyle = function(style) {
    document.body.classList.remove('nav-glass','nav-neo','nav-solid');
    document.body.classList.add('nav-' + (style || 'glass'));
  };
  window.ssCycleNavStyle = function() {
    var cur = localStorage.getItem('nwsb_nav_style') || 'glass';
    var i = NAV_OPTS.indexOf(cur); if (i < 0) i = 0;
    var next = NAV_OPTS[(i + 1) % NAV_OPTS.length];
    localStorage.setItem('nwsb_nav_style', next);
    window._applyNavStyle(next);
    var pill = document.getElementById('ss-navstyle-pill');
    var sub  = document.getElementById('ss-navstyle-sub');
    if (pill) pill.textContent = window.NAV_PILLS[next];
    if (sub)  sub.textContent  = window.NAV_LABELS[next];
  };

  // ── Download My Data ──────────────────────────────────────────
  window.ssDownloadData = function() {
    var data = {};
    for (var i = 0; i < localStorage.length; i++) {
      var k = localStorage.key(i);
      if (k && k.indexOf('nwsb') === 0 || (k && k.indexOf('nb_') === 0)) {
        try { data[k] = JSON.parse(localStorage.getItem(k)); } catch(e) { data[k] = localStorage.getItem(k); }
      }
    }
    data['_exported'] = new Date().toISOString();
    data['_user'] = (window._userDataCache && window._userDataCache.displayName) || 'Unknown';
    var blob = new Blob([JSON.stringify(data, null, 2)], {type:'application/json'});
    var url  = URL.createObjectURL(blob);
    var a    = document.createElement('a');
    a.href   = url; a.download = 'nowssb-data-' + Date.now() + '.json';
    document.body.appendChild(a); a.click();
    document.body.removeChild(a); URL.revokeObjectURL(url);
  };

  // ── Cache size display ────────────────────────────────────────
  function ssCalcCacheSize() {
    var total = 0;
    for (var i = 0; i < localStorage.length; i++) {
      var k = localStorage.key(i);
      total += (k ? k.length : 0) + (localStorage.getItem(k) || '').length;
    }
    var kb = (total * 2 / 1024).toFixed(1);
    var el = document.getElementById('ss-cache-size');
    if (el) el.textContent = kb + ' KB used — tap to clear non-essential data';
  }
  setTimeout(ssCalcCacheSize, 800);

  // ── Clear cache ───────────────────────────────────────────────
  window.ssClearCache = function() {
    var keep = ['nb_voice','nb_speed','nb_reps','nb_theme','nb_bgmode','nb_notif','nb_newword',
      'nb_sound','nb_visible','nb_chatperm','nb_readrcpt','nb_sensitivity','nb_ambient',
      'nb_wps','nb_textsize','nb_haptic','nb_autoplay','nb_autoadvance','nb_screenwake',
      'nb_reducemotion','nb_boldtext','nwsb_intros','nwsb_purchased','firebase:authUser'];
    var removed = 0;
    for (var i = localStorage.length - 1; i >= 0; i--) {
      var k = localStorage.key(i);
      if (k && keep.indexOf(k) < 0 && k.indexOf('firebase') < 0) {
        localStorage.removeItem(k); removed++;
      }
    }
    ssCalcCacheSize();
    var el = document.getElementById('ss-cache-size');
    if (el) el.textContent = removed + ' items cleared';
  };

  // ── Clear practice history ─────────────────────────────────────
  window.ssConfirmClearHistory = function() {
    if (!confirm('Clear all practice history? This removes session logs but keeps your words and settings.')) return;
    var histKeys = ['nwsb_sessions','nwsb_history','nwsb_streak','nwsb_lastpractice','nwsb_weekgrid'];
    histKeys.forEach(function(k){ localStorage.removeItem(k); });
    ssCalcCacheSize();
  };

  // ── Retake onboarding ──────────────────────────────────────
  window.ssRetakeOnboarding = function() {
    window._obSkipped = false;
    currentQ = 0;
    selectedOpts = [null,null,null,null,null];
    if (typeof closeSub === 'function') closeSub('settings');
    setTimeout(function() { goTo('onboarding'); }, 320);
  };

// ── Settings search filter ─────────────────────────────────
window.ssFilterSettings = function(q) {
  q = (q || '').toLowerCase().trim();
  var container = document.getElementById('ss-content-settings');
  if (!container) return;
  var sections = container.querySelectorAll('[data-ss-section]');
  var groups   = container.querySelectorAll('[data-ss-group]');
  if (!q) {
    // reset all
    sections.forEach(function(el){ el.style.display = ''; });
    groups.forEach(function(el){
      el.style.display = '';
      el.querySelectorAll('.sr').forEach(function(r){ r.style.display = ''; });
    });
    return;
  }
  groups.forEach(function(group, i) {
    var rows = group.querySelectorAll('.sr');
    if (!rows.length) { group.style.display=''; if(sections[i]) sections[i].style.display=''; return; }
    var anyMatch = false;
    rows.forEach(function(row) {
      var label   = row.querySelector('.sr-label');
      var sub     = row.querySelector('.sr-sub');
      var match   = (label && label.textContent.toLowerCase().indexOf(q) >= 0) ||
                    (sub   && sub.textContent.toLowerCase().indexOf(q) >= 0);
      row.style.display = match ? '' : 'none';
      if (match) anyMatch = true;
    });
    group.style.display = anyMatch ? '' : 'none';
    if (sections[i]) sections[i].style.display = anyMatch ? '' : 'none';
  });
};

// ── Sync profile from existing app data ───────────────────
function ssSyncProfile() {
  var nameEl  = document.getElementById('ss-prof-name');
  var emailEl = document.getElementById('ss-prof-email');
  var badgeEl = document.getElementById('ss-prof-badge');
  if (!nameEl) return;
  // Try reading from existing profile DOM
  var profileName  = document.getElementById('profileDisplayName');
  var profileEmail = document.getElementById('profileEmail');
  var isPro = (window._userDataCache && window._userDataCache.isPro);
  var tier = window.GATE ? window.GATE.tier() : ((window._userDataCache && window._userDataCache.tier) || (isPro ? 'pro' : 'free'));
  if (profileName  && profileName.textContent)  nameEl.textContent  = profileName.textContent;
  if (profileEmail && profileEmail.textContent) emailEl.textContent = profileEmail.textContent;
  badgeEl.className = 'sub-badge ' + badgeClass(tier);
  badgeEl.textContent = badgeLabel(tier);
  // Appearance row
  var appearBadge = document.getElementById('ss-appear-badge');
  var appearSub   = document.getElementById('ss-appear-sub');
  if (tier === 'elite') {
    if (appearBadge) appearBadge.style.display = 'none';
    if (appearSub)   appearSub.textContent = 'Themes, backgrounds, gallery upload';
    var row = document.getElementById('ss-appear-row');
    if (row) row.style.cursor = 'pointer';
  }
}

// ── Sub-screen open hook ───────────────────────────────────
var _origOpenSub = window.openSub;
window.openSub = function(id) {
  if (id === 'social') {
    document.getElementById('sub-social').classList.add('open');
    ssSyncProfile();
    return;
  }
  if (_origOpenSub) _origOpenSub(id);
};

// ══ SUBSCRIPTION ══════════════════════════════════════════

window.ssBilling = function(b) {
  _ssBilling = b;
  ['monthly','yearly'].forEach(function(x) {
    var btn = document.getElementById('ss-bill-'+x);
    btn.style.background = x===b ? 'rgba(255,255,255,.07)' : 'transparent';
    btn.style.color = x===b ? '#fff' : 'rgba(255,255,255,.52)';
    btn.style.fontWeight = x===b ? '600' : '400';
  });
  ssRenderPlans();
};

window.ssSelectPlan = function(id) {
  _ssSelectedPlan = id;
  ssRenderPlans();
};

function ssRenderPlans() {
  var container = document.getElementById('ss-plan-cards');
  var ctaEl     = document.getElementById('ss-plan-cta');
  if (!container) return;
  var tier = window.GATE ? window.GATE.tier() : ((window._userDataCache && window._userDataCache.tier) || 'free');
  var html = '';
  // Simple black cards — name, badge, tagline, price. No feature checklist.
  SS_PLANS.forEach(function(p) {
    var isSel = _ssSelectedPlan === p.id;
    var isCur = tier === p.id;
    var monthlyEquiv = (_ssBilling==='yearly' && p.price.monthly>0) ? (p.price.yearly/12).toFixed(2) : p.price.monthly;
    var borderColor = isSel ? p.color : 'rgba(255,255,255,.22)';
    html += '<div class="plan-card" onclick="ssSelectPlan(\''+p.id+'\')" style="border:1px solid '+borderColor+';background:rgba(255,255,255,0.09);backdrop-filter:none;-webkit-backdrop-filter:none;box-shadow:var(--glass-shadow);">';
    html += '<div style="display:flex;align-items:center;gap:8px;margin-bottom:10px;flex-wrap:wrap;">';
    html += '<span style="font-size:22px;font-weight:800;color:'+(isSel?p.color:'#fff')+';font-family:\'DM Sans\',sans-serif;">'+p.name+'</span>';
    if (p.badge) html += '<span style="font-size:9px;font-weight:700;letter-spacing:.7px;color:'+p.color+';background:'+p.color+'18;padding:3px 8px;border-radius:5px;">'+p.badge.toUpperCase()+'</span>';
    if (isCur) html += '<span style="font-size:9px;color:#6ee7b7;background:rgba(110,231,183,.12);padding:3px 8px;border-radius:5px;font-weight:700;">CURRENT</span>';
    html += '</div>';
    html += '<div style="font-size:13px;color:rgba(255,255,255,.55);line-height:1.5;margin-bottom:18px;font-family:\'DM Sans\',sans-serif;">'+p.tagline+'</div>';
    if (p.price.monthly===0) {
      html += '<div style="font-size:26px;font-weight:800;color:#fff;font-family:\'DM Sans\',sans-serif;">Free</div>';
    } else {
      html += '<div style="font-size:26px;font-weight:800;color:'+(isSel?p.color:'#fff')+';font-family:\'DM Sans\',sans-serif;">$'+monthlyEquiv+'<span style="font-size:13px;font-weight:400;color:rgba(255,255,255,.52);">/mo</span></div>';
      if (_ssBilling==='yearly') html += '<div style="font-size:11px;color:rgba(255,255,255,.52);font-family:\'DM Sans\',sans-serif;margin-top:2px;">$'+p.price.yearly+'/year</div>';
    }
    // Features — up to 7, same list on every card regardless of selection
    html += '<div style="margin-top:16px;display:flex;flex-direction:column;gap:8px;">';
    p.features.forEach(function(f) {
      var text = f[1];
      html += '<div style="display:flex;align-items:flex-start;gap:9px;">';
      html += '<div style="width:16px;height:16px;border-radius:50%;flex-shrink:0;margin-top:1px;background:'+p.color+'18;border:1.5px solid '+p.color+';display:flex;align-items:center;justify-content:center;">';
      html += checkSvg(p.color);
      html += '</div>';
      html += '<span style="font-size:12px;color:#fff;font-family:\'DM Sans\',sans-serif;line-height:1.4;">'+text+'</span>';
      html += '</div>';
    });
    html += '</div>';
    html += '</div>';
  });
  container.innerHTML = html;
  // CTA
  var plan = SS_PLANS.find(function(p){return p.id===_ssSelectedPlan;});
  if (!plan) plan = SS_PLANS[1]; // default to Frequency
  var ctaHtml = '';
  var curTier = window.GATE ? window.GATE.tier() : (tier || 'expired');
  var isCurrentPlan = curTier === plan.id;
  var bgMap = { resonance:'linear-gradient(135deg,#a8d4e8,#7ab8d4)', frequency:'linear-gradient(135deg,#e8d5a3,#c8a96e)', frequencyX:'linear-gradient(135deg,#f0f0f0,#c8c8c8)' };
  var planBg = bgMap[plan.id] || 'linear-gradient(135deg,#e8d5a3,#c8a96e)';
  var trialLabel = (curTier === 'trial' || curTier === 'expired')
    ? 'Start 7-Day Free Trial — then $' + ((_ssBilling==='yearly') ? plan.price.yearly + '/year' : plan.price.monthly + '/mo')
    : ((_ssBilling==='yearly') ? 'Subscribe — $' + plan.price.yearly + '/year' : 'Subscribe — $' + plan.price.monthly + '/mo');
  if (!isCurrentPlan || curTier === 'trial' || curTier === 'expired') {
    ctaHtml = '<button onclick="ssStartSubscription(\''+plan.id+'\',\''+(_ssBilling||'monthly')+'\')" style="width:100%;padding:17px 0;border-radius:16px;border:none;background:'+planBg+';color:#060c18;font-size:15px;font-weight:700;font-family:\'DM Sans\',sans-serif;cursor:pointer;margin-bottom:12px;letter-spacing:.2px;">'+trialLabel+'</button>';
    if (curTier === 'trial') {
      ctaHtml += '<div style="text-align:center;font-size:11px;color:rgba(255,255,255,.38);font-family:\'DM Sans\',sans-serif;margin-bottom:8px;">Card saved now · charged after 7-day trial · cancel anytime before</div>';
    }
  } else {
    ctaHtml = '<div style="text-align:center;padding:14px 0;font-size:13px;color:rgba(255,255,255,.38);font-family:\'DM Sans\',sans-serif;">This is your current plan</div>';
  }
  if (ctaEl) ctaEl.innerHTML = ctaHtml;
  ssPlanBannerSync();
}

// Plan banner (video, text right-middle) mirrors whichever plan is selected.
function ssPlanBannerSync() {
  var bannerText = document.getElementById('ssPlanBannerText');
  if (!bannerText) return;
  var activePlan = SS_PLANS.find(function (p) { return p.id === _ssSelectedPlan; }) || SS_PLANS[0];
  var priceStr = (_ssBilling === 'yearly') ? '$' + activePlan.price.yearly + '/year' : '$' + activePlan.price.monthly + '/mo';
  bannerText.innerHTML = '<div class="ss-plan-banner-name">' + activePlan.name + '</div><div class="ss-plan-banner-price">' + priceStr + '</div>';
}


// ══ DISCOVER ══════════════════════════════════════════════

var SS_FILTERS = [
  { id:'all',   label:'All' },
  { id:'elite', label:'Frequency' },
  { id:'pro',   label:'Resonance' },
  { id:'top5',  label:'Top 5' },
];

function ssRenderFilterChips() {
  var row = document.getElementById('ss-filter-row');
  if (!row) return;
  row.innerHTML = SS_FILTERS.map(function(f) {
    var sel = _ssDiscoverFilter === f.id;
    return '<button onclick="ssSetFilter(\''+f.id+'\')" style="padding:7px 16px;border-radius:20px;flex-shrink:0;border:1px solid '+(sel?'#e8d5a3':'rgba(255,255,255,.08)')+';background:'+(sel?'rgba(232,213,163,.08)':'transparent')+';color:'+(sel?'#e8d5a3':'rgba(255,255,255,.52)')+';font-size:12px;font-weight:'+(sel?600:400)+';font-family:\'DM Sans\',sans-serif;cursor:pointer;">'+f.label+'</button>';
  }).join('');
}

window.ssSetFilter = function(id) { _ssDiscoverFilter = id; ssRenderDiscover(); };

window.ssRenderDiscover = function() {
  ssRenderFilterChips();
  var query = (document.getElementById('ss-discover-search')||{value:''}).value.toLowerCase();
  var shown = SS_USERS.filter(function(u) {
    if (query && u.name.toLowerCase().indexOf(query)<0) return false;
    if (_ssDiscoverFilter==='elite') return u.tier==='elite';
    if (_ssDiscoverFilter==='pro')   return u.tier==='pro';
    if (_ssDiscoverFilter==='top5')  return u.rank<=5;
    return true;
  }).sort(function(a,b){return a.rank-b.rank;});

  var list = document.getElementById('ss-discover-list');
  if (!list) return;
  if (!shown.length) { list.innerHTML = '<div style="text-align:center;color:rgba(255,255,255,.22);font-family:\'DM Sans\',sans-serif;padding:40px 0;">No practitioners found</div>'; return; }

  list.innerHTML = shown.map(function(u) {
    var rankColor = u.rank===1?'#f5c842':u.rank<=3?'#e8d5a3':'rgba(255,255,255,.22)';
    var borderColor = u.tier==='elite'?'rgba(245,200,66,.25)':'rgba(255,255,255,.08)';
    var avatarStroke = u.tier==='elite'?'#f5c842':'rgba(255,255,255,.52)';
    return '<div class="du-card" onclick="ssViewUser('+u.id+')" style="border-color:'+borderColor+';">'+
      (u.tier==='elite'?'<div style="position:absolute;top:-15px;right:-15px;width:60px;height:60px;border-radius:50%;background:#f5c842;opacity:.05;filter:blur(15px);"></div>':'')+
      '<div style="position:absolute;top:14px;right:16px;font-size:12px;font-weight:800;color:'+rankColor+';font-family:\'DM Sans\',sans-serif;">#'+u.rank+'</div>'+
      '<div style="display:flex;align-items:flex-start;gap:12px;">'+
      '<div style="width:48px;height:48px;border-radius:50%;flex-shrink:0;background:linear-gradient(135deg,rgba(232,213,163,.11),rgba(200,232,245,.08));border:2px solid '+(u.tier==='elite'?'#f5c842':u.tier==='pro'?'#c8e8f5':'rgba(255,255,255,.08)')+';display:flex;align-items:center;justify-content:center;">'+
      '<img loading="lazy" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779563282/62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png" style="width:20px;height:20px;object-fit:contain;display:block;" alt=""></div>'+
      '<div style="flex:1;min-width:0;padding-right:30px;">'+
      '<div style="display:flex;align-items:center;gap:8px;margin-bottom:3px;flex-wrap:wrap;">'+
      '<span style="font-size:15px;font-weight:700;color:#fff;font-family:\'DM Sans\',sans-serif;">'+u.name+'</span>'+
      '<span class="sub-badge '+badgeClass(u.tier)+'">'+badgeLabel(u.tier)+'</span></div>'+
      '<div style="font-size:12px;color:rgba(255,255,255,.52);font-family:\'DM Sans\',sans-serif;margin-bottom:12px;overflow:hidden;white-space:nowrap;text-overflow:ellipsis;">'+u.bio+'</div>'+
      '<div style="display:flex;gap:18px;align-items:center;">'+
      '<div><div style="font-size:15px;font-weight:700;color:#e8d5a3;font-family:\'DM Sans\',sans-serif;">'+u.words+'</div><div style="font-size:10px;color:rgba(255,255,255,.22);font-family:\'DM Sans\',sans-serif;">Words</div></div>'+
      '<div><div style="font-size:15px;font-weight:700;color:#c8e8f5;font-family:\'DM Sans\',sans-serif;">'+u.sentences+'</div><div style="font-size:10px;color:rgba(255,255,255,.22);font-family:\'DM Sans\',sans-serif;">Sentences</div></div>'+
      '<div><div style="font-size:15px;font-weight:700;color:#fff;font-family:\'DM Sans\',sans-serif;">'+u.clarity+'%</div><div style="font-size:10px;color:rgba(255,255,255,.22);font-family:\'DM Sans\',sans-serif;">Clarity</div></div>'+
      '<div style="margin-left:auto;display:flex;align-items:center;gap:4px;">'+
      '<svg width="12" height="12" viewBox="0 0 24 24" fill="#e8d5a3" stroke="#e8d5a3" stroke-width="1.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>'+
      '<span style="font-size:13px;font-weight:700;color:#fff;font-family:\'DM Sans\',sans-serif;">'+u.resonance+'</span></div>'+
      '</div></div></div></div>';
  }).join('');
};

// ══ USER PROFILE ══════════════════════════════════════════

window.ssViewUser = function(id) {
  var u = SS_USERS.find(function(x){return x.id===id;});
  if (!u) return;
  _ssViewUser = u;
  _ssMyRating = 0;
  _ssChatMsgs = [{ from:'them', text:'Which word helped you the most so far?' }];
  ssRenderUserProfile(u);
  ssOpenPanel('user-profile');
};

function ssRenderUserProfile(u) {
  var el = function(id) { return document.getElementById(id); };
  if (el('ss-up-name'))  el('ss-up-name').textContent  = u.name;
  if (el('ss-up-age'))   el('ss-up-age').textContent   = u.age ? 'Age '+u.age : '';
  if (el('ss-up-bio'))   el('ss-up-bio').textContent   = u.bio;
  if (el('ss-up-rank'))  el('ss-up-rank').textContent  = '#'+u.rank+' Rank';
  el('ss-up-rank').style.color = u.rank<=3 ? '#f5c842' : 'rgba(255,255,255,.22)';
  if (el('ss-up-badge')) { el('ss-up-badge').className='sub-badge '+badgeClass(u.tier); el('ss-up-badge').textContent=badgeLabel(u.tier); }
  if (el('ss-up-avatar-icon')) el('ss-up-avatar-icon').setAttribute('stroke', u.tier==='elite'?'#f5c842':'rgba(255,255,255,.52)');
  if (el('ss-up-rate-name')) el('ss-up-rate-name').textContent = 'How would you rate '+u.name.split(' ')[0]+'\'s healing journey?';
  // Score cards
  var scores = [
    {label:'Clarity',val:u.clarity+'%',color:'#c8e8f5',sub:'Pronunciation'},
    {label:'Dedication',val:u.dedication+'%',color:'#6ee7b7',sub:'Consistency'},
    {label:'Resonance',val:u.resonance,color:'#e8d5a3',sub:'Community rating'},
  ];
  if (el('ss-up-scores')) el('ss-up-scores').innerHTML = scores.map(function(s){
    return '<div class="score-card"><div style="font-size:20px;font-weight:800;color:'+s.color+';font-family:\'DM Sans\',sans-serif;">'+s.val+'</div>'+
      '<div style="font-size:11px;font-weight:600;color:#fff;font-family:\'DM Sans\',sans-serif;margin-top:2px;">'+s.label+'</div>'+
      '<div style="font-size:9px;color:rgba(255,255,255,.22);font-family:\'DM Sans\',sans-serif;margin-top:2px;">'+s.sub+'</div></div>';
  }).join('');
  // Stat cards
  var stats = [{label:'Words',val:u.words},{label:'Sentences',val:u.sentences},{label:'Streak',val:u.dedication+'d'}];
  if (el('ss-up-stats')) el('ss-up-stats').innerHTML = stats.map(function(s){
    return '<div class="score-card"><div style="font-size:18px;font-weight:700;color:#fff;font-family:\'DM Sans\',sans-serif;">'+s.val+'</div>'+
      '<div style="font-size:10px;color:rgba(255,255,255,.22);font-family:\'DM Sans\',sans-serif;margin-top:2px;">'+s.label+'</div></div>';
  }).join('');
  // Stars
  ssRenderStars();
}

function ssRenderStars() {
  var row = document.getElementById('ss-star-row');
  if (!row) return;
  row.innerHTML = [1,2,3,4,5].map(function(n){
    var filled = n <= _ssMyRating;
    return '<button class="star-btn" onclick="ssSetRating('+n+')">'+
      '<svg width="32" height="32" viewBox="0 0 24 24" fill="'+(filled?'#e8d5a3':'transparent')+'" stroke="'+(filled?'#e8d5a3':'rgba(255,255,255,.22)')+'" stroke-width="1.5">'+
      '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg></button>';
  }).join('');
  var submitBtn = document.getElementById('ss-submit-rating');
  if (submitBtn) submitBtn.style.display = _ssMyRating > 0 ? 'block' : 'none';
}

window.ssSetRating = function(n) { _ssMyRating = n; ssRenderStars(); };
window.ssSubmitRating = function() { alert('Rating submitted!'); };

// ══ CHAT ══════════════════════════════════════════════════

window.ssOpenChat = function() {
  if (!_ssViewUser) return;
  var nameEl = document.getElementById('ss-chat-name');
  var badgeEl = document.getElementById('ss-chat-badge');
  if (nameEl) nameEl.textContent = _ssViewUser.name;
  if (badgeEl) { badgeEl.className='sub-badge '+badgeClass(_ssViewUser.tier); badgeEl.textContent=badgeLabel(_ssViewUser.tier); }
  ssRenderChatMsgs();
  ssOpenPanel('chat');
};

window.ssCloseChat = function() { ssClosePanel('chat'); };

function ssRenderChatMsgs() {
  var container = document.getElementById('ss-chat-messages');
  if (!container) return;
  container.innerHTML = _ssChatMsgs.map(function(m){
    return '<div style="display:flex;justify-content:'+(m.from==='me'?'flex-end':'flex-start')+';">'+
      '<div style="max-width:74%;padding:10px 14px;font-size:14px;font-family:\'DM Sans\',sans-serif;line-height:1.5;" class="'+(m.from==='me'?'chat-me':'chat-them')+'">'+m.text+'</div></div>';
  }).join('');
  container.scrollTop = container.scrollHeight;
}

window.ssSendMsg = function() {
  var input = document.getElementById('ss-chat-input');
  if (!input || !input.value.trim()) return;
  _ssChatMsgs.push({from:'me', text:input.value.trim()});
  input.value = '';
  ssRenderChatMsgs();
};

// ── init discover on first open
document.getElementById('sub-social').addEventListener('transitionend', function(e){
  if (e.target === this && this.classList.contains('open')) ssRenderDiscover();
}, {once:false});

})(); // end IIFE
