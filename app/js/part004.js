
// ── HTML SANITIZER — prevents XSS from AI-generated content ──
function _sanitizeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');
}
// ══ PRACTICE WORD DATA ══
// ── MASTER WORD LIBRARY ──
// Each word has: categories (health areas), gender ('M','F','both'), time ('morning','evening','night','any')
const MASTER_WORD_LIBRARY = [
  { word:'AAROGYA', phonetic:'aa · ro · gyaa', syllables:['aa','ro','gyaa'], organ:'Immune System', origin:'Natural Origin', benefit:'Activates cellular immunity and vital life force', meaning:'Perfect health — freedom from all disease', mouthPos:'Open jaw, tongue flat, breath from belly', resonance:'Feel vibration in chest and upper throat', mistake:"Don't rush the final syllable — hold it 1 second", tip:'Say 3 times on exhale, eyes closed, hand on chest', categories:['Immunity Boost','Heart Health'], gender:'both', time:'morning' },
  { word:'PRANA', phonetic:'praa · naa', syllables:['praa','naa'], organ:'Lungs · Heart', origin:'Natural Origin', benefit:'Expands breath capacity and vital life energy', meaning:'Life force, breath — the pulse of all living', mouthPos:"Lips parted, tongue on upper palate for 'pr'", resonance:"Feel the chest open and expand on the 'aa' vowel", mistake:"Don't separate P from R — one continuous breath flow", tip:'Inhale fully before, then exhale the word completely', categories:['Heart Health','Lung & Breath','Fitness & Muscle'], gender:'both', time:'morning' },
  { word:'SHAKTI', phonetic:'shak · ti', syllables:['shak','ti'], organ:'Solar Plexus', origin:'Natural Origin', benefit:'Builds core vitality, willpower and primal energy', meaning:'Power, primal energy — the divine creative force', mouthPos:'Lips firm, push the sound from the diaphragm', resonance:'Feel vibration in the mid-abdomen region', mistake:"The 'sh' is soft, not harsh — breathe gently into it", tip:"Stand tall — upright posture amplifies this word's effect", categories:['Fitness & Muscle','Testosterone & Hormones','Fitness & Tone'], gender:'both', time:'morning' },
  { word:'ANANDA', phonetic:'aa · nan · da', syllables:['aa','nan','da'], organ:'Nervous System', origin:'Natural Origin', benefit:'Calms the nervous system and unlocks deep joy', meaning:'Pure bliss, inner happiness', mouthPos:'Soft open mouth, tongue relaxed', resonance:'Feel warmth spreading through the chest', mistake:"Don't clip the final 'da' — let it trail softly", tip:'Close your eyes and let the sound dissolve into silence', categories:['Mental Clarity','Hormonal Balance'], gender:'both', time:'evening' },
  { word:'SOMA', phonetic:'so · ma', syllables:['so','ma'], organ:'Brain', origin:'Natural Origin', benefit:'Stimulates mental clarity and fluid intelligence', meaning:'Nectar of consciousness', mouthPos:"Round lips for 'so', open wide for 'ma'", resonance:'Feel vibration behind the eyes and forehead', mistake:"The 'o' is long — don't rush it", tip:'Say it slowly like a moon rising', categories:['Mental Clarity','Skin & Glow'], gender:'both', time:'any' },
  { word:'TEJAS', phonetic:'te · jas', syllables:['te','jas'], organ:'Eyes · Skin', origin:'Natural Origin', benefit:'Enhances radiance, clarity and inner fire', meaning:'Luminous fire, brilliance', mouthPos:"Tongue touches upper teeth for 'te'", resonance:'Feel heat in the center of the chest', mistake:"The 'j' is a soft 'dj' not hard", tip:'Visualize a flame at your heart as you speak', categories:['Skin & Glow','Hair Health'], gender:'F', time:'morning' },
  { word:'OJAS', phonetic:'o · jas', syllables:['o','jas'], organ:'Immune · Vitality', origin:'Natural Origin', benefit:'Builds deep immunity and radiant vitality', meaning:'Essential vigor, life essence', mouthPos:'Open throat, let the O resonate fully', resonance:'Feel deep warmth in the core of the body', mistake:'Do not shorten the O — full resonance is the key', tip:'Practice at dawn for maximum absorption', categories:['Immunity Boost','Fitness & Muscle'], gender:'both', time:'morning' },
  { word:'VATA', phonetic:'vaa · ta', syllables:['vaa','ta'], organ:'Nervous System', origin:'Natural Origin', benefit:'Balances nervous energy and reduces anxiety', meaning:'Wind, movement — the force of motion', mouthPos:'Long open A, let breath carry the word', resonance:'Feel movement in the chest and throat', mistake:'Do not clip the A — it must be long', tip:'Say it with a slow exhale, like releasing wind', categories:['Mental Clarity','Lung & Breath'], gender:'both', time:'evening' },
  { word:'PITTA', phonetic:'pit · ta', syllables:['pit','ta'], organ:'Liver · Digestion', origin:'Natural Origin', benefit:'Activates digestive fire and metabolic strength', meaning:'Fire, transformation — the force of digestion', mouthPos:'Short sharp P, then open for TA', resonance:'Feel heat in the upper abdomen', mistake:'Both T sounds are soft, not explosive', tip:'Say after meals to activate digestive energy', categories:['Gut Health','Liver Detox'], gender:'both', time:'any' },
  { word:'KAPHA', phonetic:'kaa · pha', syllables:['kaa','pha'], organ:'Lungs · Joints', origin:'Natural Origin', benefit:'Strengthens joints, lungs and ground energy', meaning:'Water, earth — the force of stability', mouthPos:'Long K, then PH as in phone not p+h', resonance:'Feel heaviness and groundedness in the lower body', mistake:'PH is aspirated — breathe through it', tip:'Say slowly to build stillness and stability', categories:['Lung & Breath','Fitness & Muscle'], gender:'both', time:'night' },
  { word:'SURYA', phonetic:'sur · ya', syllables:['sur','ya'], organ:'Heart · Energy', origin:'Natural Origin', benefit:'Energizes the heart and ignites solar vitality', meaning:'The sun — source of all light and life', mouthPos:'R is rolled gently, YA is open', resonance:'Feel warmth and expansion in the chest', mistake:'Do not harden the R — it is gentle', tip:'Face sunlight when you say this word if possible', categories:['Heart Health','Fitness & Tone'], gender:'both', time:'morning' },
  { word:'CHANDRA', phonetic:'chan · dra', syllables:['chan','dra'], organ:'Mind · Emotions', origin:'Natural Origin', benefit:'Soothes the emotional mind and enhances intuition', meaning:'The moon — ruler of mind and emotions', mouthPos:'CH is soft like church, DRA flows together', resonance:'Feel coolness in the forehead and crown', mistake:'Do not separate D from R in DRA', tip:'Say this at night or under moonlight', categories:['Mental Clarity','Hormonal Balance','Reproductive Wellness'], gender:'F', time:'night' }
];

// Active session words — set by routine launch or direct open
let PRACTICE_WORDS = [...MASTER_WORD_LIBRARY];

// Get words for a specific health category
function getWordsForCategory(category) {
  return MASTER_WORD_LIBRARY.filter(w => w.categories && w.categories.includes(category));
}

// Get words for gender
function getWordsForGender(gender) {
  return MASTER_WORD_LIBRARY.filter(w => !w.gender || w.gender === 'both' || w.gender === gender);
}

// Get words for time of day
function getWordsForTime(time) {
  const hr = new Date().getHours();
  const t = time || (hr < 10 ? 'morning' : hr < 17 ? 'any' : hr < 20 ? 'evening' : 'night');
  return MASTER_WORD_LIBRARY.filter(w => !w.time || w.time === 'any' || w.time === t);
}

// Launch player from a health category
function launchCategorySession(category, gender) {
  let words = getWordsForCategory(category);
  // Filter by gender if specified
  if (gender && gender !== 'both') {
    words = words.filter(w => !w.gender || w.gender === 'both' || w.gender === gender);
  }
  // Fallback: show all words if none match
  if (words.length === 0) words = [...MASTER_WORD_LIBRARY];
  PRACTICE_WORDS = words;
  window._rtManualLaunch = true;
  window._rtSessionCategory = category;
  window._rtSessionGender = gender;
  _pwIdx = 0; _pwRepCount = 0; _pwDone = false; _pwMode = 'listen';
  openSub('practice');
}

// Get active routine based on time of day
function getActiveRoutine() {
  try {
    const stored = localStorage.getItem('nwsb_routines');
    if (!stored) return null;
    const routines = JSON.parse(stored);
    const hr = new Date().getHours();
    const timeName = hr < 10 ? 'Morning' : hr < 13 ? 'Midday' : hr < 17 ? 'Afternoon' : hr < 20 ? 'Evening' : 'Night';
    return routines.find(r => r.time === timeName || r.name === timeName) || routines[0];
  } catch(e) { return null; }
}

// Load words from routine into PRACTICE_WORDS
function loadRoutineWords(routine) {
  if (!routine || !routine.words || routine.words.length === 0) {
    PRACTICE_WORDS = [...MASTER_WORD_LIBRARY];
    return;
  }
  PRACTICE_WORDS = routine.words.map(w => {
    return MASTER_WORD_LIBRARY.find(m => m.word === w) || { word:w, phonetic:w.toLowerCase(), syllables:[w.toLowerCase()], organ:'', origin:'', benefit:'', meaning:'', mouthPos:'', resonance:'', mistake:'', tip:'' };
  }).filter(Boolean);
  if (PRACTICE_WORDS.length === 0) PRACTICE_WORDS = [...MASTER_WORD_LIBRARY];
}

// Launch active routine from home card
function openPracticeIntro() {
  const routine = getActiveRoutine();
  loadRoutineWords(routine);
  window._rtManualLaunch = true;
  window._pwShowIntro = true;
  openSub('practice');
}

function renderPracticeIntro() {
  const body = document.getElementById('practiceBody');
  if (!body) return;

  const routine = getActiveRoutine();
  const hr = new Date().getHours();
  const timeName = hr < 10 ? 'Morning' : hr < 13 ? 'Midday' : hr < 17 ? 'Afternoon' : hr < 20 ? 'Evening' : 'Night';
  const wordCount = routine && routine.words ? routine.words.length : PRACTICE_WORDS.length;
  const countText = wordCount > 0 ? wordCount : String.fromCharCode(8734);
  const routineName = routine ? routine.name : timeName;

  const timeDescs = {
    'Morning':   'Begin the day with natural origin sound. Each word activates a living frequency within your body.',
    'Midday':    'Restore balance at the centre of the day. Natural sounds realign your healing flow.',
    'Afternoon': 'Deepen your practice. Root sounds carry grounding, focusing resonance through the body.',
    'Evening':   'Wind down with intention. These words calm the nervous system and restore inner balance.',
    'Night':     'Deep healing begins at night. Root sounds work while your body rests and repairs.'
  };
  const desc = timeDescs[routineName] || 'Every word has a natural origin vibration. Sound before definition. Vibration before meaning.';

  body.innerHTML =
    '<div style="position:relative;width:100%;height:100%;overflow:hidden;background:#060c18;">' +
      '<div style="position:absolute;inset:0;background-image:url(https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777973723/grok_image_1777967661568_pbau2f.jpg);background-size:cover;background-position:center center;"></div>' +
      '<div style="position:absolute;inset:0;background:linear-gradient(to bottom,rgba(4,10,24,0.1) 0%,rgba(4,10,24,0.02) 20%,rgba(4,10,24,0.55) 58%,rgba(4,10,24,0.97) 100%);pointer-events:none;"></div>' +
      '<div style="position:relative;z-index:2;height:100%;display:flex;flex-direction:column;padding:max(env(safe-area-inset-top,18px),18px) 28px calc(var(--nav-height,0px) + max(env(safe-area-inset-bottom,20px),20px));">' +

        '<div style="display:flex;align-items:center;justify-content:space-between;flex-shrink:0;margin-bottom:4px;">' +
          '<div onclick="closeSub(\'practice\')" style="width:40px;height:40px;cursor:pointer;background:rgba(6,12,24,0.42);border:1px solid rgba(255,255,255,0.18);backdrop-filter:blur(8px);-webkit-backdrop-filter:blur(8px);display:flex;align-items:center;justify-content:center;flex-shrink:0;">' +
            '<svg width="14" height="12" viewBox="0 0 16 14" fill="none"><path d="M7 1L1 7L7 13" stroke="rgba(255,255,255,0.75)" stroke-width="1.5" stroke-linecap="square"/><line x1="1" y1="7" x2="15" y2="7" stroke="rgba(255,255,255,0.75)" stroke-width="1.5"/></svg>' +
          '</div>' +
          '<span style="font-size:9px;font-weight:400;letter-spacing:6px;text-transform:uppercase;color:rgba(255,255,255,0.35);">NOWSBANSIU</span>' +
          '<button onclick="openIntroSetting()" style="width:40px;height:40px;background:rgba(6,12,24,0.42);border:1px solid rgba(255,255,255,0.18);backdrop-filter:blur(8px);-webkit-backdrop-filter:blur(8px);display:flex;align-items:center;justify-content:center;cursor:pointer;">' +
            '<svg width="4" height="16" viewBox="0 0 4 18" fill="none"><circle cx="2" cy="2" r="1.8" fill="rgba(255,255,255,0.7)"/><circle cx="2" cy="9" r="1.8" fill="rgba(255,255,255,0.7)"/><circle cx="2" cy="16" r="1.8" fill="rgba(255,255,255,0.7)"/></svg>' +
          '</button>' +
        '</div>' +

        '<div style="flex:1;min-height:20px;"></div>' +

        '<div style="flex-shrink:0;">' +
          '<div style="font-size:56px;font-weight:800;color:#fff;line-height:1.05;letter-spacing:-1px;">' + countText + ' Natural</div>' +
          '<div style="font-size:56px;font-weight:800;display:inline-block;line-height:1.05;letter-spacing:-1px;margin-bottom:18px;color:#f5c842;background:linear-gradient(90deg,#f5c842,#e8913a);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;">' + routineName + ' Sounds</div>' +
          '<div style="font-size:14px;font-weight:300;color:rgba(255,255,255,0.72);line-height:1.7;margin-bottom:24px;max-width:300px;">' + desc + '</div>' +

          '<div style="display:flex;align-items:center;justify-content:space-between;background:rgba(10,18,38,0.75);border-radius:14px !important;padding:14px 20px;margin-bottom:22px;">' +
            '<span style="font-size:14px;font-weight:700;color:#fff;">Voice Guidance</span>' +
            '<div id="piToggle" onclick="pwIntroToggle(this)" data-on="true" style="width:56px;height:32px;border-radius:11px !important;background:#e8b100;position:relative;flex-shrink:0;cursor:pointer;box-shadow:0 2px 14px rgba(232,177,0,0.5);transition:background 0.25s,box-shadow 0.25s;">' +
              '<div style="width:26px;height:26px;border-radius:7px !important;background:#fff;position:absolute;top:3px;right:3px;display:flex;align-items:center;justify-content:center;transition:right 0.25s;">' +
                '<svg width="11" height="9" viewBox="0 0 10 8" fill="none"><path d="M1 4L3.5 6.5L9 1" stroke="#e8b100" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>' +
              '</div>' +
            '</div>' +
          '</div>' +

          '<div style="display:flex;align-items:center;justify-content:space-between;">' +
            '<div onclick="pwIntroBegin()" style="display:flex;align-items:center;gap:10px;cursor:pointer;background:rgba(20,28,48,0.85);border:1px solid rgba(255,255,255,0.18);padding:15px 34px;font-size:13px;font-weight:600;letter-spacing:1.5px;color:#fff;text-transform:uppercase;">' +
              '<svg width="15" height="13" viewBox="0 0 16 14" fill="none"><path d="M3 7H13M8 2L13 7L8 12" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>&nbsp;Begin' +
            '</div>' +
            '<span onclick="renderPractice()" style="font-size:13px;font-weight:400;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,0.45);cursor:pointer;padding:15px 8px;">Skip</span>' +
          '</div>' +
        '</div>' +
      '</div>' +
    '</div>';

  // All interaction is wired via inline onclick above - no addEventListener needed
}

function pwIntroToggle(el) {
  var thumb = el.querySelector('div');
  var isOn = el.getAttribute('data-on') !== 'false';
  if (isOn) {
    // Turn OFF — voice guidance disabled, player opens silently
    _pwAutoPlay = false;
    el.style.background = 'rgba(255,255,255,0.12)';
    el.style.boxShadow = 'none';
    el.setAttribute('data-on', 'false');
    if (thumb) { thumb.style.right = 'calc(100% - 29px)'; thumb.innerHTML = ''; }
  } else {
    // Turn ON — word pronounces itself automatically when player opens
    _pwAutoPlay = true;
    el.style.background = '#e8b100';
    el.style.boxShadow = '0 2px 14px rgba(232,177,0,0.5)';
    el.setAttribute('data-on', 'true');
    if (thumb) { thumb.style.right = '3px'; thumb.innerHTML = '<svg width="11" height="9" viewBox="0 0 10 8" fill="none"><path d="M1 4L3.5 6.5L9 1" stroke="#e8b100" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>'; }
  }
}

// Called by the Begin button — arms auto-play flag then opens the player
function pwIntroBegin() {
  _pwAutoPlayOnce = _pwAutoPlay;
  renderPractice();
}

function launchActiveRoutine() {
  const routine = getActiveRoutine();
  loadRoutineWords(routine);
  window._rtManualLaunch = true;
  _pwIdx = 0; _pwRepCount = 0; _pwDone = false; _pwMode = 'listen';
  openSub('practice');
}

// Update home card dynamically
function updateTodayCard() {
  const routine = getActiveRoutine();
  const hr = new Date().getHours();
  const timeLabel = hr < 10 ? 'Morning' : hr < 13 ? 'Midday' : hr < 17 ? 'Afternoon' : hr < 20 ? 'Evening' : 'Night';
  const titleEl = document.getElementById('todayPracticeTitle');
  const subEl = document.getElementById('todayPracticeSub');
  const labelEl = document.getElementById('todayPracticeLabel');
  if (!titleEl) return;
  // Swap banner image per time of day
  const TODAY_BANNERS = {
    'Morning':   'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1778052547/grok_image_1778052232385_qpdmgh.jpg',
    'Midday':    'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1778052565/grok_image_1778052259502_s8fbkb.jpg',
    'Afternoon': 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1778052585/grok_image_1778052247702_xxo6jv.jpg',
    'Evening':   'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1778052598/grok_image_1778052255147_welycg.jpg',
    'Night':     'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1778052611/grok_image_1778052238350_bxdyvx.jpg'
  };
  const bgEl = document.getElementById('todayPracticeBg');
  if (bgEl) bgEl.style.backgroundImage = "url('" + (TODAY_BANNERS[timeLabel] || TODAY_BANNERS['Morning']) + "')";
  if (routine) {
    titleEl.textContent = routine.name + ' Word Ritual';
    const wc = routine.words ? routine.words.length : 0;
    subEl.textContent = wc > 0 ? wc + ' words ready for your ' + timeLabel.toLowerCase() + ' practice.' : 'Go to My Routines to add words to this session.';
    labelEl.textContent = timeLabel + ' Practice';
  } else {
    titleEl.textContent = timeLabel + ' Word Ritual';
    subEl.textContent = 'Start with foundational root syllables to activate clarity and vitality.';
    labelEl.textContent = "Today's Practice";
  }
}

// Run on DOMContentLoaded AND on every goTo('home') — see goTo() call at line ~11043
// Also run immediately at parse time if home is already the active screen
document.addEventListener('DOMContentLoaded', () => {
  updateTodayCard(); // run immediately, no delay — avoids "Loading..." flash
  // Nudge autoplay for videos on home page (mobile browsers block without gesture)
  setTimeout(function() {
    var vids = ['wsStoreVideo', 'msHomeCardVid'];
    vids.forEach(function(id) {
      var v = document.getElementById(id);
      if (v && typeof v.play === 'function') { v.muted = true; v.play().catch(function(){}); }
    });
  }, 800);
});

// ── State ──
let _pwIdx       = 0;
let _pwRepTarget = 7;
let _pwRepCount  = 0;
let _pwVoice     = 'F';
let _pwPlaying   = false;
let _pwLoop      = false;
let _pwPhase    = 'idle'; // 'idle'|'playing'|'post-play'|'recording'|'scoring'|'scored'
let _pwDone      = false;
let _pwMode      = 'listen';
let _pwUtt       = null;

// Auto-play: controlled by the Voice Guidance / Activate Sound toggles on both intros.
// _pwAutoPlay = persistent preference. _pwAutoPlayOnce = one-shot flag consumed by renderPractice.
let _pwAutoPlay     = true;   // default ON — matches toggle default state
let _pwAutoPlayOnce = false;  // set just before opening the player

// ── Sentence Player State ──
let _sspActive    = false;   // true = sentence player mode
let _sspData      = null;    // { sentence, highlights, mood }
let _sspPlaying   = false;
let _sspUtt       = null;
let _sspProgress  = 0;       // 0–100
let _sspWordIdx   = -1;      // currently lit word index
let _sspWords     = [];      // parsed word tokens

function launchSentencePlayer(data, mood) {
  _sspData    = { ...data, mood: mood || 'Healing' };
  _sspActive  = true;
  _sspPlaying = false;
  _sspProgress= 0;
  _sspWordIdx = -1;
  // Parse sentence into tokens: spaces + words
  _sspWords = _sspData.sentence.trim().split(/\s+/).filter(Boolean);
  renderSentencePlayer();
}

function exitSentencePlayer() {
  if (_sspPlaying) sspStop();
  _sspActive  = false;
  _sspData    = null;
  _sspWords   = [];
  _sspWordIdx = -1;
  _sspProgress= 0;
  renderPractice();
}

function renderSentencePlayer() {
  const body = document.getElementById('practiceBody');
  if (!body || !_sspData) return;

  // Figure out which words are Shabdapathy words (in highlights)
  const shabdaWords = new Set(
    (_sspData.highlights || []).map(h => h.word.toUpperCase())
  );

  const wvBars = Array.from({length:15},(_,i)=>`<div class="sp-wv" style="animation-delay:${(i*0.07).toFixed(2)}s"></div>`).join('');

  // Build word chip HTML
  const chipHTML = _sspWords.map((token, i) => {
    // Strip punctuation for lookup
    const clean = token.replace(/[^\w]/g, '').toUpperCase();
    const isShabda = shabdaWords.has(clean);
    const hlData = (_sspData.highlights || []).find(h => h.word.toUpperCase() === clean);
    const meaning = hlData ? hlData.meaning : '';
    const genre   = hlData ? (hlData.genre || '') : '';
    return `<span class="ssp-word-chip${isShabda ? ' shabda' : ''}${_sspWordIdx === i ? ' lit' : ''}"
      data-widx="${i}"
      ${isShabda ? `onclick="sspShowMeaning('${clean}','${meaning.replace(/'/g,"\\'")}','${genre.replace(/'/g,"\\'")}')"` : ''}
    >${token}</span>`;
  }).join('');

  body.innerHTML = `
    <div class="sp-sentence-player">
      <!-- Bg -->
      <div class="sp-bg-img" id="spBgImg"></div>
      <video id="spBgVideo"
        class="sp-bg-video${_sspPlaying?' playing':''}"
        src="https://res.cloudinary.com/dfc8lwj22/video/upload/q_auto/f_auto/v1777979792/grok_video_2026-05-05-16-46-09_dpauwg.mp4"
        loop muted playsinline preload="none">
      </video>
      <div class="sp-bg-overlay"></div>
      <div class="sp-bg-glow${_sspPlaying?' playing':''}"></div>

      <!-- TOP BAR -->
      <div class="ssp-mood-badge">
        <button class="ssp-back-btn" onclick="exitSentencePlayer()">
          <svg width="13" height="11" viewBox="0 0 16 14" fill="none"><path d="M7 1L1 7L7 13" stroke="rgba(255,255,255,0.6)" stroke-width="1.5" stroke-linecap="square"/><line x1="1" y1="7" x2="15" y2="7" stroke="rgba(255,255,255,0.6)" stroke-width="1.5"/></svg>
          Back
        </button>
        <div class="ssp-mood-pill">${_sspData.mood}</div>
        <div class="ssp-voice-toggle">
          <button class="sp-voice-btn${_pwVoice==='F'?' active':''}" onclick="pwSetVoice('F');renderSentencePlayer()">F</button>
          <button class="sp-voice-btn${_pwVoice==='M'?' active':''}" onclick="pwSetVoice('M');renderSentencePlayer()">M</button>
        </div>
      </div>

      <!-- SPACER -->
      <div style="flex:1;min-height:0;max-height:60px;"></div>

      <!-- DISC -->
      <div class="sp-disc-wrap" style="position:relative;z-index:10;">
        <div class="sp-glass-ring${_sspPlaying?' playing':''}">
          <div class="sp-wm-ripple"></div>
          <div class="sp-wm-ripple"></div>
          <div class="sp-wm-ripple"></div>
          <div class="sp-wm-grooves">
            <div class="sp-wm-groove"></div><div class="sp-wm-groove"></div>
            <div class="sp-wm-groove"></div><div class="sp-wm-groove"></div>
            <div class="sp-wm-groove"></div>
          </div>
          <div class="sp-wm-dial"></div>
          <div class="sp-wm-arc"></div>
          <div class="sp-disc-outer${_sspPlaying?' playing':''}">
            <div class="sp-disc${_sspPlaying?' playing':''}">
              <img decoding="async" src="https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1777803046/grok_image_1777802759590_giabgl.jpg" alt="NowssB" loading="eager">
            </div>
          </div>
        </div>
      </div>

      <!-- WAVEFORM -->
      <div class="sp-waveform-strip${_sspPlaying?' active':''}" style="position:relative;z-index:10;">
        ${wvBars}
      </div>

      <!-- TRANSPORT -->
      <div class="ssp-transport">
        <div class="ssp-transport-row">
          <div class="sp-transport-side" onclick="sspRestart()">
            <div class="sp-transport-icon-circle">
              <svg width="16" height="16" viewBox="0 0 18 18" fill="none">
                <path d="M15 9A6 6 0 1 1 9 3" stroke="rgba(255,255,255,0.55)" stroke-width="1.7" stroke-linecap="round"/>
                <path d="M9 1v4h4" stroke="rgba(255,255,255,0.55)" stroke-width="1.7" stroke-linecap="square"/>
              </svg>
            </div>
            <div class="sp-transport-side-label">Restart</div>
          </div>

          <button class="sp-play-orb${_sspPlaying?' playing':''}" onclick="sspTogglePlay()">
            ${_sspPlaying
              ? `<svg width="14" height="16" viewBox="0 0 16 18" fill="none"><rect x="1" y="1" width="5" height="16" rx="1" fill="rgba(200,232,245,0.9)"/><rect x="10" y="1" width="5" height="16" rx="1" fill="rgba(200,232,245,0.9)"/></svg>`
              : `<svg width="16" height="18" viewBox="0 0 18 20" fill="none"><path d="M3 2L17 10L3 18V2Z" fill="rgba(200,232,245,0.9)"/></svg>`}
          </button>

          <div class="sp-transport-side" onclick="sspRebuild()">
            <div class="sp-transport-icon-circle">
              <svg width="16" height="16" viewBox="0 0 18 18" fill="none">
                <path d="M3 3h5v5" stroke="rgba(255,255,255,0.55)" stroke-width="1.7" stroke-linecap="square" stroke-linejoin="round"/>
                <path d="M15 15h-5v-5" stroke="rgba(255,255,255,0.55)" stroke-width="1.7" stroke-linecap="square" stroke-linejoin="round"/>
                <path d="M3 3l4 4 5-5 4 4" stroke="rgba(255,255,255,0.55)" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                <path d="M15 15l-4-4-5 5-4-4" stroke="rgba(255,255,255,0.55)" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </div>
            <div class="sp-transport-side-label">New</div>
          </div>
        </div>

        <!-- PROGRESS BAR -->
        <div class="ssp-progress-wrap" style="width:100%;">
          <div class="ssp-progress-track">
            <div class="ssp-progress-fill" id="sspProgressFill" style="width:${_sspProgress}%"></div>
          </div>
        </div>
      </div>

      <!-- SENTENCE AREA — above transport -->
      <div style="padding: 0 0 16px; flex-shrink:0; position:relative; z-index:10;">
        <div class="ssp-label">Shabdapathy Sentence · Tap a word</div>
        <div class="ssp-sentence-wrap" id="sspSentenceWrap">
          ${chipHTML}
        </div>
      </div>

      <!-- MEANING TOAST -->
      <div class="ssp-meaning-toast" id="sspMeaningToast">
        <button class="ssp-toast-close" onclick="sspCloseMeaning()">✕</button>
        <div class="ssp-toast-word" id="sspToastWord"></div>
        <div class="ssp-toast-meaning" id="sspToastMeaning"></div>
      </div>

    </div>`;

  // If was playing before re-render, restart video
  if (_sspPlaying) {
    const vid = document.getElementById('spBgVideo');
    if (vid) vid.play().catch(()=>{});
  }
}

// ── Sentence player controls ──
function sspTogglePlay() { _sspPlaying ? sspStop() : sspPlay(); }

function sspPlay() {
  if (!_sspData) return;
  _sspPlaying = true;
  _sspProgress = 0;
  _sspWordIdx = -1;
  renderSentencePlayer();

  const vid = document.getElementById('spBgVideo');
  if (vid) { vid.currentTime = 0; vid.play().catch(()=>{}); }

  if (!('speechSynthesis' in window)) { setTimeout(sspStop, 3000); return; }
  window.speechSynthesis.cancel();

  _sspUtt = new SpeechSynthesisUtterance(_sspData.sentence);
  _sspUtt.rate  = 0.72;
  _sspUtt.pitch = _pwVoice === 'F' ? 1.15 : 0.78;
  _sspUtt.volume = 1;

  // Word-by-word boundary events
  _sspUtt.onboundary = (e) => {
    if (e.name !== 'word') return;
    // Find which word index we're at based on charIndex
    let charCount = 0;
    const sentence = _sspData.sentence;
    const words = sentence.trim().split(/\s+/);
    let wIdx = 0;
    for (let i = 0; i < words.length; i++) {
      const pos = sentence.indexOf(words[i], charCount);
      if (pos <= e.charIndex && e.charIndex <= pos + words[i].length) {
        wIdx = i; break;
      }
      charCount = pos + words[i].length;
    }
    _sspWordIdx = wIdx;
    _sspProgress = Math.round((wIdx / Math.max(1, _sspWords.length - 1)) * 100);
    _sspUpdateHighlight();
  };

  _sspUtt.onend = () => {
    _sspPlaying = false;
    _sspProgress = 100;
    _sspWordIdx = -1;
    const fill = document.getElementById('sspProgressFill');
    if (fill) fill.style.width = '100%';
    // Update play button
    const orb = document.querySelector('.sp-play-orb');
    if (orb) {
      orb.classList.remove('playing');
      orb.innerHTML = `<svg width="16" height="18" viewBox="0 0 18 20" fill="none"><path d="M3 2L17 10L3 18V2Z" fill="rgba(200,232,245,0.9)"/></svg>`;
    }
    const wvStrip = document.querySelector('.sp-waveform-strip');
    if (wvStrip) wvStrip.classList.remove('active');
    const vid = document.getElementById('spBgVideo');
    if (vid) vid.pause();
    // Clear all highlights
    document.querySelectorAll('.ssp-word-chip').forEach(c => c.classList.remove('lit'));
  };

  window.speechSynthesis.speak(_sspUtt);
}

function sspStop() {
  _sspPlaying = false;
  window.speechSynthesis.cancel();
  const vid = document.getElementById('spBgVideo');
  if (vid) vid.pause();
  document.querySelectorAll('.ssp-word-chip').forEach(c => c.classList.remove('lit'));
  const orb = document.querySelector('.sp-play-orb');
  if (orb) {
    orb.classList.remove('playing');
    orb.innerHTML = `<svg width="16" height="18" viewBox="0 0 18 20" fill="none"><path d="M3 2L17 10L3 18V2Z" fill="rgba(200,232,245,0.9)"/></svg>`;
  }
  const wvStrip = document.querySelector('.sp-waveform-strip');
  if (wvStrip) wvStrip.classList.remove('active');
}

function sspRestart() {
  sspStop();
  _sspProgress = 0;
  const fill = document.getElementById('sspProgressFill');
  if (fill) fill.style.width = '0%';
  setTimeout(sspPlay, 120);
}

function sspRebuild() {
  // Go back to LIB overlay Build tab
  sspStop();
  openWalkmanLib();
  setTimeout(() => wlSwitchTab('build'), 80);
}

function _sspUpdateHighlight() {
  // Light up current word chip, dim others
  document.querySelectorAll('.ssp-word-chip').forEach(el => {
    const idx = parseInt(el.dataset.widx);
    el.classList.toggle('lit', idx === _sspWordIdx);
  });
  // Update progress bar
  const fill = document.getElementById('sspProgressFill');
  if (fill) fill.style.width = _sspProgress + '%';
}

function sspShowMeaning(word, meaning, genre) {
  const toast  = document.getElementById('sspMeaningToast');
  const wEl    = document.getElementById('sspToastWord');
  const mEl    = document.getElementById('sspToastMeaning');
  if (!toast || !wEl || !mEl) return;
  const genreClass = genre ? `wl-genre-${genre.toLowerCase()}` : '';
  wEl.innerHTML = `${word}${genre ? `<span class="wl-track-genre ${genreClass}" style="margin-left:8px;font-size:7px;vertical-align:middle;">${genre}</span>` : ''}`;
  mEl.textContent = meaning;
  toast.classList.add('show');
}

function sspCloseMeaning() {
  const toast = document.getElementById('sspMeaningToast');
  if (toast) toast.classList.remove('show');
}

// ── Render ──
function renderPractice() {
  if (_sspActive) { renderSentencePlayer(); return; }
  const body = document.getElementById('practiceBody');
  if (!body) return;
  const w = PRACTICE_WORDS[_pwIdx];
  if (!w) return;
  const pct = Math.min(100, Math.round((_pwRepCount / _pwRepTarget) * 100));
  const repDone = _pwRepCount >= _pwRepTarget;
  const isFirst = _pwIdx === 0;
  const isLast  = _pwIdx === PRACTICE_WORDS.length - 1;
  const hr = new Date().getHours();
  const timeLabel = hr < 10 ? 'Morning' : hr < 13 ? 'Midday' : hr < 17 ? 'Afternoon' : hr < 20 ? 'Evening' : 'Night';

  const sylChips = w.syllables.map((s,i) =>
    `<div class="sp-syl-chip" id="spSyl${i}">${s}</div>${i < w.syllables.length-1 ? '<div class="sp-syl-dot">·</div>' : ''}`
  ).join('');

  const wvBars = Array.from({length:15},(_,i)=>`<div class="sp-wv" style="animation-delay:${(i*0.07).toFixed(2)}s"></div>`).join('');

  const recBars = Array.from({length:24},()=>`<div class="sp-rec-bar" style="height:4px"></div>`).join('');

  const autoStatusTxt = _pwRecording ? 'Speak now…'
    : _pwRecordingBlob ? 'Recorded · tap ▶ to replay'
    : 'Tap ▶ to listen · practice follows';


  body.innerHTML = `
    <div class="sp-player">
      <div class="sp-bg-img${_pwPlaying?' hidden':''}" id="pwBgImg"></div>
      <video id="pwBgVideo"
        class="sp-bg-video${_pwPlaying?' playing':''}"
        src="https://res.cloudinary.com/dfc8lwj22/video/upload/q_auto/f_auto/v1777979792/grok_video_2026-05-05-16-46-09_dpauwg.mp4"
        loop muted playsinline preload="none">
      </video>
      <div class="sp-bg-overlay"></div>
      <div class="sp-bg-glow${_pwPlaying?' playing':''}"></div>

      <!-- TOP BAR -->
      <div class="sp-topbar">
        <button onclick="closeSub('practice')" style="background:none;border:none;cursor:pointer;padding:4px;display:flex;align-items:center;width:36px;flex-shrink:0;">
          <svg width="13" height="11" viewBox="0 0 16 14" fill="none"><path d="M7 1L1 7L7 13" stroke="rgba(255,255,255,0.6)" stroke-width="1.5" stroke-linecap="square"/><line x1="1" y1="7" x2="15" y2="7" stroke="rgba(255,255,255,0.6)" stroke-width="1.5"/></svg>
        </button>
        <div class="sp-topbar-label">${(()=>{const ar=getActiveRoutine();return ar?ar.name:timeLabel})()} Ritual &nbsp;·&nbsp; ${_pwIdx+1} of ${PRACTICE_WORDS.length}</div>
        <div style="width:36px;flex-shrink:0;"></div>
      </div>

      <!-- WORD HERO — compact, centered -->
      <div class="sp-word-hero" style="position:relative;z-index:10;">
        <div class="sp-origin-pill">${w.origin}</div>
        <div class="sp-word-title">${w.word}</div>
        <div class="sp-syl-row">${sylChips}</div>
        <div class="sp-tags"><span class="sp-tag">${w.organ}</span></div>
      </div>

      <!-- DISC — Glassmorphism Walkman -->
      <div class="sp-disc-wrap" style="position:relative;z-index:10;">
        <div class="sp-glass-ring${_pwPlaying?' playing':''}">

          <!-- Ripple rings (beat pulse, playing only) -->
          <div class="sp-wm-ripple"></div>
          <div class="sp-wm-ripple"></div>
          <div class="sp-wm-ripple"></div>

          <!-- Groove rings (vinyl record lines) -->
          <div class="sp-wm-grooves">
            <div class="sp-wm-groove"></div>
            <div class="sp-wm-groove"></div>
            <div class="sp-wm-groove"></div>
            <div class="sp-wm-groove"></div>
            <div class="sp-wm-groove"></div>
          </div>

          <!-- Dial tick-mark ring (slow outer rotation) -->
          <div class="sp-wm-dial"></div>

          <!-- Orbiting glowing arc -->
          <div class="sp-wm-arc"></div>

          <!-- Main spinning disc -->
          <div class="sp-disc-outer${_pwPlaying?' playing':''}">
            <div class="sp-disc${_pwPlaying?' playing':''}">
              <img decoding="async" src="https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1777803046/grok_image_1777802759590_giabgl.jpg" alt="NowssB" loading="eager">
            </div>
          </div>

        </div>
      </div>

      <!-- WAVEFORM STRIP -->
      <div class="sp-waveform-strip${_pwPlaying?' active':''}" id="spWaveform" style="position:relative;z-index:10;">
        ${wvBars}
      </div>

      <!-- CENTER: phase-aware -->
      <div class="sp-center-section">

        <!-- Phase: idle / playing -->
        <div id="spPhaseIdlePlay" style="display:${(_pwPhase==='idle'||_pwPhase==='playing')?'flex':'none'};flex-direction:column;align-items:center;gap:8px;width:100%;">
          <div class="sp-auto-status" id="spAutoStatus">${_pwPhase==='playing'?'Listening…':'Tap ▶ to listen'}</div>
          <div class="sp-play-row">
            <button class="sp-play-orb${_pwPlaying?' playing':''}" id="spPlayBtn" onclick="pwTogglePlay()">
              ${_pwPlaying
                ? `<svg width="14" height="16" viewBox="0 0 16 18" fill="none"><rect x="1" y="1" width="5" height="16" rx="1" fill="rgba(200,232,245,0.9)"/><rect x="10" y="1" width="5" height="16" rx="1" fill="rgba(200,232,245,0.9)"/></svg>`
                : `<img src="https://res.cloudinary.com/ds6duqabl/image/upload/v1780340484/04610c10-5dec-11f1-9e1a-9303081e5fda_cbsa8c.png" style="width:32px;height:32px;object-fit:contain;display:block;" alt="">`}
            </button>
          </div>
        </div>

        <!-- Phase: post-play — practice CTA -->
        <div id="spPhasePost" style="display:${_pwPhase==='post-play'?'flex':'none'};flex-direction:column;align-items:center;gap:10px;width:100%;padding:0 20px;">
          <div style="font-size:10px;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,0.38);font-family:'DM Sans',sans-serif;font-weight:600;">Word played · your turn</div>
          <button class="sp-practice-cta" onclick="pwPracticeNow()">
            <svg width="8" height="8" viewBox="0 0 10 10" fill="none"><circle cx="5" cy="5" r="4" fill="#e8d5a3"/></svg>
            PRACTICE NOW
          </button>
        </div>

        <!-- Phase: recording — waveform -->
        <div id="spPhaseRec" style="display:${_pwPhase==='recording'?'flex':'none'};flex-direction:column;align-items:center;gap:8px;width:100%;">
          <div class="sp-auto-status recording">● Recording</div>
          <div class="sp-rec-waveform" id="spRecWaveform">${recBars}</div>
          <div class="sp-rec-compare-hint" id="spRecHint">Speak the word clearly</div>
        </div>

        <!-- Phase: scoring / scored — score display -->
        <div id="spScoreWrap" style="display:${(_pwPhase==='scoring'||_pwPhase==='scored')?'flex':'none'};flex-direction:column;align-items:center;gap:4px;padding:0 20px;width:100%;">
          <div style="font-size:9px;letter-spacing:2px;text-transform:uppercase;color:rgba(200,232,245,0.38);font-family:'DM Sans',sans-serif;" id="spScoreLabel">${_pwPhase==='scoring'?'Analyzing…':'Your score'}</div>
          <div id="spScoreNum" style="font-family:'DM Sans',sans-serif;font-size:52px;font-weight:800;letter-spacing:-2px;color:#e8d5a3;line-height:1;"></div>
          <div id="spPersonaWrap" style="display:none;margin-top:6px;padding:10px 14px;background:rgba(255,255,255,0.04);text-align:left;width:100%;">
            <div id="spPersonaName" style="font-size:9px;letter-spacing:2px;color:rgba(232,213,163,0.55);text-transform:uppercase;margin-bottom:5px;"></div>
            <div id="spPersonaText" style="font-size:12px;color:rgba(255,255,255,0.75);line-height:1.6;font-weight:300;"></div>
          </div>
        </div>

        <!-- hidden compat for existing JS refs -->
        <div style="display:none;">
          <button id="spRecBtn"></button>
          <div id="spRecLabel"></div>
          <div id="spRecStatus"></div>
          <button id="spRecPlayBtn"></button>
          <button id="spRecTrashBtn"></button>
          <div id="spRecControls"></div>
        </div>
      </div>

      <!-- 3-BUTTON BAR -->
      <div class="sp-3btn-bar">
        <button class="sp-3btn" onclick="pwOpenSettings()">
          <div class="sp-3btn-ico"><img src="https://res.cloudinary.com/ds6duqabl/image/upload/v1780340484/018b2fc0-5dec-11f1-9e1a-9303081e5fda_ccsoef.png" style="width:26px;height:26px;object-fit:contain;display:block;opacity:0.9;" alt=""></div>
          SETTINGS
        </button>
        <button class="sp-3btn sp-3btn-main sp-btn-play" id="sp3BtnMain" onclick="pwMainBtnAction()">
          <div class="sp-3btn-ico" id="sp3BtnIco"><img src="https://res.cloudinary.com/ds6duqabl/image/upload/v1780340484/04610c10-5dec-11f1-9e1a-9303081e5fda_cbsa8c.png" style="width:26px;height:26px;object-fit:contain;display:block;" alt=""></div>
          <span id="sp3BtnLbl">PLAY</span>
        </button>
        <button class="sp-3btn" onclick="openWalkmanLib()">
          <div class="sp-3btn-ico"><svg width="16" height="14" viewBox="0 0 16 14" fill="none"><rect x="0" y="0" width="6" height="6" stroke="currentColor" stroke-width="1.3"/><rect x="10" y="0" width="6" height="6" stroke="currentColor" stroke-width="1.3"/><rect x="0" y="9" width="6" height="5" stroke="currentColor" stroke-width="1.3"/><rect x="10" y="9" width="6" height="5" stroke="currentColor" stroke-width="1.3"/></svg></div>
          LIBRARY
        </button>
      </div>

      <!-- SETTINGS SHEET (slides up) -->
      <div id="spSettingsSheet" class="sp-settings-sheet">
        <div class="sp-ss-handle"></div>
        <div class="sp-ss-row" style="cursor:default;">
          <span class="sp-ss-lbl">Voice</span>
          <div class="sp-ss-voice">
            <button class="sp-ss-vbtn${_pwVoice==='F'?' active':''}" onclick="pwSetVoice('F');pwUpdateSettingsSheet()">Female</button>
            <button class="sp-ss-vbtn${_pwVoice==='M'?' active':''}" onclick="pwSetVoice('M');pwUpdateSettingsSheet()">Male</button>
          </div>
        </div>
        <div class="sp-ss-row" onclick="pwToggleLoop();pwUpdateSettingsSheet()">
          <span class="sp-ss-lbl">Loop</span>
          <span class="sp-ss-val" id="ssLoopVal">${_pwLoop?'On':'Off'}</span>
        </div>
        <div class="sp-ss-row" onclick="pwCycleRepTarget();pwUpdateSettingsSheet()">
          <span class="sp-ss-lbl">Reps</span>
          <span class="sp-ss-val" id="ssRepsVal">${_pwRepTarget}×</span>
        </div>
        <div class="sp-ss-row" onclick="pwExpandMeaning();pwCloseSettings()">
          <span class="sp-ss-lbl">Meaning</span>
          <span class="sp-ss-val">→</span>
        </div>
        <div class="sp-ss-navrow">
          <button class="sp-ss-navbtn" onclick="pwPrevWord();pwCloseSettings()" ${isFirst?'disabled':''}>
            <svg width="10" height="9" viewBox="0 0 12 11" fill="none"><path d="M5 1L1 5.5L5 10" stroke="currentColor" stroke-width="1.5" stroke-linecap="square"/><line x1="1" y1="5.5" x2="11" y2="5.5" stroke="currentColor" stroke-width="1.5"/></svg>
            PREV
          </button>
          <button class="sp-ss-navbtn" onclick="pwNextWord();pwCloseSettings()" ${isLast?'disabled':''}>
            NEXT
            <svg width="10" height="9" viewBox="0 0 12 11" fill="none"><path d="M7 1L11 5.5L7 10" stroke="currentColor" stroke-width="1.5" stroke-linecap="square"/><line x1="11" y1="5.5" x2="1" y2="5.5" stroke="currentColor" stroke-width="1.5"/></svg>
          </button>
        </div>
        <button class="sp-ss-done${_pwDone?' completed':''}" onclick="pwCompleteSession();pwCloseSettings()">${_pwDone?'COMPLETED ✓':'COMPLETE SESSION'}</button>
        <div style="height:calc(var(--nav-height,58px) + max(env(safe-area-inset-bottom,20px),20px) + 8px);"></div>
      </div>

      <!-- Meaning expand sheet (fixed bottom overlay) -->
      <div id="spMeaningSheet" style="position:fixed;bottom:0;left:0;right:0;z-index:9000;background:#060c18;border-top:1px solid rgba(255,255,255,0.12);padding:20px 20px calc(var(--nav-height,58px) + 24px);transform:translateY(100%);transition:transform 0.32s cubic-bezier(0.4,0,0.2,1);"></div>

      <!-- Hidden compat divs for repeat tab JS -->
      <div style="display:none;">
        <div id="spRepNum">${_pwRepCount}</div>
        <div id="spRepBar" style="width:${pct}%"></div>
      </div>

    </div>`;

  // Restore recorder state visually after re-render
  _pwRestoreRecorderState();

  // Auto-play: consume the one-shot flag set by pwIntroBegin / rtStartSession
  if (_pwAutoPlayOnce) {
    _pwAutoPlayOnce = false;
    setTimeout(pwPlay, 380);
  }
}

function pwSetMode(m) { _pwMode = m; renderPractice(); }

// ── LIBRARY — word selection + sentence builder ──
let _libSelected = new Set();
let _libSentenceData = null;
let _libSpeaking = false;

function pwLibToggleWord(idx) {
  if (_libSelected.has(idx)) {
    _libSelected.delete(idx);
  } else {
    _libSelected.add(idx);
  }
  window._libSelected = _libSelected; // keep window ref in sync for Groq override
  // Update chip visual
  document.querySelectorAll('.sp-lib-word-chip').forEach(el => {
    const i = parseInt(el.dataset.idx);
    el.classList.toggle('selected', _libSelected.has(i));
  });
  // Enable/disable build button
  const btn = document.getElementById('spLibBuildBtn');
  if (btn) btn.disabled = _libSelected.size < 2;
}

async function pwLibBuildSentence() {
  const btn = document.getElementById('spLibBuildBtn');
  const resultEl = document.getElementById('spLibResult');
  const sentenceEl = document.getElementById('spLibSentenceText');
  const meaningPop = document.getElementById('spLibMeaningPop');

  if (_libSelected.size < 2) return;

  // Get selected words data
  const selectedWords = [..._libSelected].map(i => PRACTICE_WORDS[i]);
  const wordNames = selectedWords.map(w => w.word).join(', ');
  const wordInfo = selectedWords.map(w =>
    `${w.word} (${w.meaning}, heals: ${w.organ})`
  ).join('; ');

  // Loading state
  if (btn) { btn.disabled = true; btn.innerHTML = '<span class="sp-lib-spinner"></span> Building…'; }
  if (resultEl) resultEl.style.display = 'none';
  if (meaningPop) { meaningPop.classList.remove('show'); meaningPop.textContent = ''; }

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 500,
        system: 'You are a Shabdapathy sentence builder for the NowssB healing app. Given natural-origin healing words, create one beautiful, meaningful healing sentence in English that weaves the given words naturally. The sentence should feel poetic, personal, and intentional. Respond ONLY with a JSON object — no preamble, no markdown — in this exact format: {"sentence":"...","highlights":[{"word":"WORD","meaning":"short 8-word meaning"}]}. The words array must include every given word that appears in the sentence, exact case match.',
        messages: [{
          role: 'user',
          content: `Create a healing sentence using these Shabdapathy words: ${wordNames}. Word details: ${wordInfo}.`
        }]
      })
    });

    const data = await response.json();
    const raw = data.content?.find(b => b.type === 'text')?.text || '';
    const clean = raw.replace(/```json|```/g, '').trim();
    _libSentenceData = JSON.parse(clean);

    // Render sentence with highlighted words
    let rendered = _libSentenceData.sentence;
    (_libSentenceData.highlights || []).forEach(h => {
      const safe = h.word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      rendered = rendered.replace(
        new RegExp(`\\b${safe}\\b`, 'gi'),
        `<span class="sp-lib-word-hl" onclick="pwLibShowMeaning('${h.word.replace(/'/g,"\\'")}','${h.meaning.replace(/'/g,"\\'")}')">${h.word}</span>`
      );
    });

    if (sentenceEl) sentenceEl.innerHTML = rendered;
    if (resultEl) resultEl.style.display = 'block';

  } catch(e) {
    console.error('Library sentence error:', e);
    if (sentenceEl) sentenceEl.textContent = 'Could not generate sentence. Check your connection.';
    if (resultEl) resultEl.style.display = 'block';
  }

  // Restore button
  if (btn) {
    btn.disabled = false;
    btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 16 16" fill="none"><path d="M2 8h12M9 3l5 5-5 5" stroke="currentColor" stroke-width="1.5" stroke-linecap="square"/></svg> Build Sentence';
  }
}

function pwLibShowMeaning(word, meaning) {
  const pop = document.getElementById('spLibMeaningPop');
  if (!pop) return;
  pop.innerHTML = `<strong style="color:var(--accent-gold);letter-spacing:1px">${_sanitizeHtml(word)}</strong> — ${_sanitizeHtml(meaning)}`;
  pop.classList.add('show');
}

function pwLibPlaySentence() {
  if (!_libSentenceData || !_libSentenceData.sentence) return;
  if (_libSpeaking) { window.speechSynthesis.cancel(); _libSpeaking = false; return; }
  const utt = new SpeechSynthesisUtterance(_libSentenceData.sentence);
  utt.rate = 0.85*(window._pwSpeed||1); utt.pitch = _pwVoice === 'F' ? 1.1 : 0.85;
  utt.onend = () => { _libSpeaking = false; };
  _libSpeaking = true;
  window.speechSynthesis.speak(utt);
}
function pwToggleLoop() { _pwLoop = !_pwLoop; renderPractice(); }

function pwTogglePlay() { _pwPlaying ? pwStop() : pwPlay(); }

function pwPlay() {
  const w = PRACTICE_WORDS[_pwIdx];
  if (!w) return;
  _pwPlaying = true;
  _pwPhase = 'playing';
  renderPractice();
  const vid = document.getElementById('pwBgVideo');
  if (vid) { vid.currentTime = 0; vid.play().catch(()=>{}); }
  if ('speechSynthesis' in window) {
    window.speechSynthesis.cancel();
    _pwUtt = new SpeechSynthesisUtterance(w.word.toLowerCase());
    _pwUtt.rate  = 0.48;
    _pwUtt.pitch = _pwVoice === 'F' ? 1.35 : 0.72;
    _pwUtt.volume = 1;
    const dur = 750;
    const animSyls = () => {
      w.syllables.forEach((s, i) => {
        setTimeout(() => {
          document.querySelectorAll('.sp-syl-chip').forEach(el => el.classList.remove('lit'));
          const el = document.getElementById('spSyl' + i);
          if (el) el.classList.add('lit');
        }, i * dur);
      });
    };
    animSyls();
    let loops = 0;
    const loopPlay = () => {
      _pwUtt.onend = () => {
        loops++;
        const shouldLoop = _pwLoop ? true : loops < 3;
        if (shouldLoop && _pwPlaying) {
          setTimeout(() => { animSyls(); loopPlay(); }, 480);
        } else { pwStop(true); }
      };
      window.speechSynthesis.speak(_pwUtt);
    };
    loopPlay();
  } else { setTimeout(() => { if (_pwPlaying) pwStop(true); }, 3000); }
}

function pwStop(autoEnd) {
  _pwPlaying = false;
  _pwPhase = autoEnd ? 'post-play' : 'idle';
  if ('speechSynthesis' in window) window.speechSynthesis.cancel();
  document.querySelectorAll('.sp-syl-chip').forEach(el => el.classList.remove('lit'));
  const vid = document.getElementById('pwBgVideo');
  if (vid) { vid.pause(); }
  renderPractice();
}

function pwSetVoice(v) {
  _pwVoice = v;
  if (_pwPlaying) { pwStop(); setTimeout(pwPlay, 80); }
  else renderPractice();
}

function pwSetRepTarget(n) { _pwRepTarget = n; _pwRepCount = 0; renderPractice(); }

function pwAddRep() {
  if (_pwRepCount >= _pwRepTarget) return;
  _pwRepCount++;
  const numEl = document.getElementById('spRepNum');
  const barEl = document.getElementById('spRepBar');
  if (numEl) {
    numEl.textContent = _pwRepCount;
    numEl.classList.add('bump');
    setTimeout(() => { if (numEl) numEl.classList.remove('bump'); }, 120);
  }
  if (barEl) barEl.style.width = Math.min(100, (_pwRepCount / _pwRepTarget * 100)) + '%';
  if (_pwRepCount >= _pwRepTarget) setTimeout(renderPractice, 150);
}


function pwResetReps() { _pwRepCount = 0; renderPractice(); }

// ══ RECORDER LOGIC ══
let _pwMediaRecorder = null;
let _pwAudioChunks   = [];
let _pwRecording     = false;
let _pwRecordingBlob = null;
let _pwRecAudio      = null;
let _pwRecAnimFrame  = null;
let _pwAnalyser      = null;
let _pwAudioCtx      = null;

function pwToggleRecording() {
  if (_pwRecording) { pwStopRecording(); }
  else { pwStartRecording(); }
}

async function pwStartRecording() {
  if (window.GATE && !window.GATE.check('resonance')) return;
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    _pwAudioCtx  = new (window.AudioContext || window.webkitAudioContext)();
    _pwAnalyser  = _pwAudioCtx.createAnalyser();
    _pwAnalyser.fftSize = 64;
    const src = _pwAudioCtx.createMediaStreamSource(stream);
    src.connect(_pwAnalyser);

    _pwMediaRecorder = new MediaRecorder(stream);
    _pwAudioChunks   = [];
    _pwMediaRecorder.ondataavailable = e => { if (e.data.size > 0) _pwAudioChunks.push(e.data); };
    _pwMediaRecorder.onstop = () => {
      _pwRecordingBlob = new Blob(_pwAudioChunks, { type: 'audio/webm' });
      const objUrl = URL.createObjectURL(_pwRecordingBlob);
      if (_pwRecAudio) { try { URL.revokeObjectURL(_pwRecAudio.src); } catch(e) {} }
      _pwRecAudio = new Audio(objUrl);
      _pwRecording = false;
      cancelAnimationFrame(_pwRecAnimFrame);
      if (_pwAudioCtx) { _pwAudioCtx.close(); _pwAudioCtx = null; }
      stream.getTracks().forEach(t => t.stop());
      _pwPhase = 'scoring';
      renderPractice();
      pwScoreRecording();
    };
    _pwMediaRecorder.start();
    _pwRecording = true;
    _pwRestoreRecorderState();
    _pwAnimRecWaveform();
  } catch(e) {
    // Clean up any partial state
    if (_pwAudioCtx) { try { _pwAudioCtx.close(); } catch(e2) {} _pwAudioCtx = null; }
    _pwRecording = false;
    const st = document.getElementById('spRecStatus');
    if (st) { st.textContent = 'Mic access denied — check browser permissions'; st.classList.remove('recording'); }
  }
}

function pwStopRecording() {
  if (_pwMediaRecorder && _pwMediaRecorder.state !== 'inactive') {
    _pwMediaRecorder.stop();
  }
}

function _pwAnimRecWaveform() {
  if (!_pwAnalyser || !_pwRecording) return;
  const data = new Uint8Array(_pwAnalyser.frequencyBinCount);
  _pwAnalyser.getByteFrequencyData(data);
  const bars = document.querySelectorAll('.sp-rec-bar');
  bars.forEach((bar, i) => {
    const val = data[i % data.length] || 0;
    const h = Math.max(3, (val / 255) * 36);
    bar.style.height = h + 'px';
    bar.style.background = `rgba(255,107,107,${0.3 + (val/255)*0.7})`;
  });
  _pwRecAnimFrame = requestAnimationFrame(_pwAnimRecWaveform);
}

function pwPlayRecording() {
  if (!_pwRecAudio) return;
  _pwRecAudio.currentTime = 0;
  _pwRecAudio.play();
  const st = document.getElementById('spRecStatus');
  if (st) { st.textContent = '▶ Playing back…'; st.classList.remove('recording'); }
  _pwRecAudio.onended = () => {
    if (st) st.textContent = 'Recording ready';
  };
}

function pwClearRecording() {
  if (_pwRecording) pwStopRecording();
  _pwRecordingBlob = null;
  if (_pwRecAudio) {
    try { URL.revokeObjectURL(_pwRecAudio.src); } catch(e) {}
    _pwRecAudio = null;
  }
  _pwRestoreRecorderState();
}

// ── 3-button bar: main action + settings ──
function pwMainBtnAction() {
  if (_pwPhase === 'idle') pwPlay();
  else if (_pwPhase === 'playing') pwStop(false);
  else if (_pwPhase === 'post-play') { _pwPhase = 'idle'; pwPlay(); }
  else if (_pwPhase === 'recording') pwStopRecording();
  else if (_pwPhase === 'scored') { _pwPhase = 'idle'; _pwRecordingBlob = null; renderPractice(); }
}

function pwPracticeNow() {
  _pwPhase = 'recording';
  renderPractice();
  setTimeout(pwStartRecording, 150);
}

function pwOpenSettings() {
  var s = document.getElementById('spSettingsSheet');
  if (s) s.classList.add('open');
}

function pwCloseSettings() {
  var s = document.getElementById('spSettingsSheet');
  if (s) s.classList.remove('open');
}

function pwUpdateSettingsSheet() {
  var lv = document.getElementById('ssLoopVal');
  var rv = document.getElementById('ssRepsVal');
  if (lv) lv.textContent = _pwLoop ? 'On' : 'Off';
  if (rv) rv.textContent = _pwRepTarget + '×';
  var vbtns = document.querySelectorAll('.sp-ss-vbtn');
  vbtns.forEach(function(b) {
    b.classList.toggle('active', (b.textContent.trim()==='Female'&&_pwVoice==='F')||(b.textContent.trim()==='Male'&&_pwVoice==='M'));
  });
}

function _pwUpdateMainBtn() {
  var btn = document.getElementById('sp3BtnMain');
  var ico = document.getElementById('sp3BtnIco');
  var lbl = document.getElementById('sp3BtnLbl');
  if (!btn) return;
  var SVG = {
    play: '<img src="https://res.cloudinary.com/ds6duqabl/image/upload/v1780340484/04610c10-5dec-11f1-9e1a-9303081e5fda_cbsa8c.png" style="width:26px;height:26px;object-fit:contain;display:block;" alt="">',
    stop: '<svg width="13" height="14" viewBox="0 0 14 16" fill="none"><rect x="1" y="1" width="4" height="14" fill="currentColor"/><rect x="9" y="1" width="4" height="14" fill="currentColor"/></svg>',
    replay: '<img src="https://res.cloudinary.com/ds6duqabl/image/upload/v1780340485/fd31c0b0-5deb-11f1-9e1a-9303081e5fda_finid1.png" style="width:26px;height:26px;object-fit:contain;display:block;" alt="">',
    stoprec: '<svg width="12" height="12" viewBox="0 0 12 12" fill="none"><rect x="1" y="1" width="10" height="10" fill="currentColor"/></svg>',
    spin: '<svg width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="7" cy="7" r="5.5" stroke="currentColor" stroke-width="1.5" opacity="0.3"/><path d="M7 1.5a5.5 5.5 0 015.5 5.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="square"/></svg>'
  };
  btn.disabled = false;
  btn.className = 'sp-3btn sp-3btn-main';
  if (_pwPhase === 'idle')       { ico.innerHTML = SVG.play;    lbl.textContent = 'PLAY';    btn.className += ' sp-btn-play'; }
  else if (_pwPhase === 'playing')  { ico.innerHTML = SVG.stop;    lbl.textContent = 'PLAYING'; btn.className += ' sp-btn-playing'; }
  else if (_pwPhase === 'post-play'){ ico.innerHTML = SVG.replay;  lbl.textContent = 'REPLAY';  btn.className += ' sp-btn-post'; }
  else if (_pwPhase === 'recording'){ ico.innerHTML = SVG.stoprec; lbl.textContent = 'STOP';    btn.className += ' sp-btn-rec'; }
  else if (_pwPhase === 'scoring')  { ico.innerHTML = SVG.spin;    lbl.textContent = 'SCORING'; btn.disabled = true; }
  else if (_pwPhase === 'scored')   { ico.innerHTML = SVG.replay;  lbl.textContent = 'AGAIN';   btn.className += ' sp-btn-post'; }
}

function pwSkipPlay() {
  pwStop();
  if (_pwIdx < PRACTICE_WORDS.length - 1) { _pwIdx++; _pwRepCount = 0; _pwDone = false; renderPractice(); }
}

function _pwRestoreRecorderState() {
  const btn  = document.getElementById('spRecBtn');
  const lbl  = document.getElementById('spRecLabel');
  const st   = document.getElementById('spRecStatus');
  const pb   = document.getElementById('spRecPlayBtn');
  const tb   = document.getElementById('spRecTrashBtn');
  if (!btn) return;

  if (_pwRecording) {
    btn.classList.add('active');
    if (lbl) lbl.textContent = 'Stop';
    if (st)  { st.textContent = '● Recording…'; st.classList.add('recording'); }
    if (pb)  { pb.classList.remove('ready'); }
    if (tb)  { tb.classList.remove('ready'); }
  } else if (_pwRecordingBlob) {
    btn.classList.remove('active');
    if (lbl) lbl.textContent = 'Re-Record';
    if (st)  { st.textContent = 'Recording ready — play it back'; st.classList.remove('recording'); }
    if (pb)  { pb.classList.add('ready'); }
    if (tb)  { tb.classList.add('ready'); }
    // Reset bars to flat
    document.querySelectorAll('.sp-rec-bar').forEach(b => { b.style.height = '4px'; b.style.background = 'rgba(255,107,107,0.3)'; });
  } else {
    btn.classList.remove('active');
    if (lbl) lbl.textContent = 'Record';
    if (st)  { st.textContent = 'Tap mic to record your pronunciation'; st.classList.remove('recording'); }
    if (pb)  { pb.classList.remove('ready'); }
    if (tb)  { tb.classList.remove('ready'); }
    document.querySelectorAll('.sp-rec-bar').forEach(b => { b.style.height = '4px'; b.style.background = 'rgba(255,107,107,0.3)'; });
  }
}

function pwNextWord() {
  if (_pwIdx >= PRACTICE_WORDS.length - 1) return;
  pwStop(); _pwIdx++; _pwRepCount = 0; _pwDone = false; _pwMode = 'listen';
  _pwPhase = 'idle'; _pwRecordingBlob = null;
  renderPractice();
}
function pwPrevWord() {
  if (_pwIdx <= 0) return;
  pwStop(); _pwIdx--; _pwRepCount = 0; _pwDone = false; _pwMode = 'listen';
  _pwPhase = 'idle'; _pwRecordingBlob = null;
  renderPractice();
}

async function pwCompleteSession() {
  const btn = document.getElementById('pwCompleteBtn');
  if (btn) { btn.disabled = true; btn.textContent = 'Saving…'; }
  const today = new Date().toISOString().split('T')[0];
  const w = PRACTICE_WORDS[_pwIdx];
  if (w && w.word) {
    try {
      if (window._fbSetDoc && window._currentUid) {
        await window._fbSetDoc(window._currentUid, {
          [`sessions.${today}_${w.word}`]: { date:today, word:w.word, repsCompleted:_pwRepCount, repTarget:_pwRepTarget, completedAt:new Date().toISOString() },
          lastPractice: today
        });
      }
    } catch(e) { console.warn('Practice save:', e.message); }
    if (window._hbmRecordWord) window._hbmRecordWord(w.word);
  }
  _pwDone = true;
  renderPractice();
  pwAutoSentence(); // ← Groq generates session-end sentence
} // end pwCompleteSession

if (typeof window._currentUid === 'undefined') window._currentUid = null;

