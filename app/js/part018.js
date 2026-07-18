
// ══ ROUTINE DATA ══
const RT_COLORS = ['#c8e8f5','#e8d5a3','#b8d4ff','#ffd4b8','#d4ffb8'];
let _routines;
try {
  _routines = JSON.parse(localStorage.getItem('nwsb_routines') || 'null') || [
    { id:1, name:'Morning', time:'Morning', color:RT_COLORS[0], words:['AAROGYA','PRANA'], reps:7, lastPracticed:null },
    { id:2, name:'Midday',  time:'Midday',  color:RT_COLORS[1], words:['SHAKTI'],          reps:7, lastPracticed:null },
    { id:3, name:'Afternoon',time:'Afternoon',color:RT_COLORS[2],words:[],                 reps:7, lastPracticed:null },
    { id:4, name:'Evening', time:'Evening', color:RT_COLORS[3], words:[],                  reps:7, lastPracticed:null },
    { id:5, name:'Night',   time:'Night',   color:RT_COLORS[4], words:[],                  reps:7, lastPracticed:null }
  ];
} catch(e) {
  _routines = [
    { id:1, name:'Morning', time:'Morning', color:RT_COLORS[0], words:['AAROGYA','PRANA'], reps:7, lastPracticed:null },
    { id:2, name:'Midday',  time:'Midday',  color:RT_COLORS[1], words:['SHAKTI'],          reps:7, lastPracticed:null },
    { id:3, name:'Afternoon',time:'Afternoon',color:RT_COLORS[2],words:[],                 reps:7, lastPracticed:null },
    { id:4, name:'Evening', time:'Evening', color:RT_COLORS[3], words:[],                  reps:7, lastPracticed:null },
    { id:5, name:'Night',   time:'Night',   color:RT_COLORS[4], words:[],                  reps:7, lastPracticed:null }
  ];
}
let _rtActiveId   = null;
let _rtDetailTab  = 'words';
let _rtLibFilter  = 'All';
let _rtEditId     = null;
let _rtEditName   = '';
let _rtEditTime   = '';
let _rtIntroFromHome = false;

// ── WORD LIBRARY — scalable architecture ──
// MASTER_WORD_LIBRARY is the local seed cache (defined earlier in the page).
// _wordLibCache holds the working set — starts from MASTER_WORD_LIBRARY,
// grows as more words are fetched from Firestore over time.
// Nothing here limits the total word count — it scales to millions.

// Unified lookup: works on any word string → returns meta object
function getWordMeta(wordName) {
  const lib = typeof MASTER_WORD_LIBRARY !== 'undefined' ? MASTER_WORD_LIBRARY : [];
  const found = lib.find(w => w.word === wordName);
  if (found) return { syl: found.phonetic, organ: found.organ, origin: found.origin };
  return { syl: wordName.toLowerCase(), organ: '', origin: '' };
}
// Proxy so old code doing WORD_META['AAROGYA'] keeps working
const WORD_META = new Proxy({}, { get: (_, name) => getWordMeta(name) });

// getAllWordNames() — always reflects current library (post-fetch too)
function getAllWordNames() {
  return (typeof MASTER_WORD_LIBRARY !== 'undefined' ? MASTER_WORD_LIBRARY : []).map(w => w.word);
}

// Get all unique categories from master library
function getAllCategories() {
  const cats = new Set();
  const lib = typeof MASTER_WORD_LIBRARY !== 'undefined' ? MASTER_WORD_LIBRARY : [];
  lib.forEach(w => { (w.categories || []).forEach(c => cats.add(c)); });
  return ['All', ...Array.from(cats)];
}

// saveRoutines defined after openSub hook

// ── HOME CARD → INTRO THEN ROUTINES ──
function openDailyPracticeIntro() {
  var now = new Date();
  var hr = now.getHours();
  var activeName = hr < 10 ? 'Morning' : hr < 13 ? 'Midday' : hr < 17 ? 'Afternoon' : hr < 20 ? 'Evening' : 'Night';
  var activeRoutine = _routines.find(function(r){ return r.name === activeName; }) || _routines[0];
  _rtActiveId = activeRoutine.id;
  _rtDetailTab = 'words';
  _rtLibFilter = 'All';
  _rtIntroFromHome = true;
  // Open the routines sub-screen, then render the intro into it
  _origOpenSub('routines');
  if (typeof shouldShowIntro === 'function' && !shouldShowIntro('routine')) {
    setTimeout(renderRoutineDetail_inline, 60);
  } else {
    setTimeout(renderRoutineIntro, 60);
  }
}

// ── RENDER ROUTINES LIST ──
function renderRoutines() {
  const body = document.getElementById('routinesBody');
  if (!body) return;
  const now = new Date();
  const hr = now.getHours();
  const activeName = hr < 10 ? 'Morning' : hr < 13 ? 'Midday' : hr < 17 ? 'Afternoon' : hr < 20 ? 'Evening' : 'Night';

  body.innerHTML = `
    <div class="rt-screen" style="position:relative;overflow:hidden;">
      <div class="rt-bg" style="background-image:url('https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777989351/grok_image_1777989145016_rkszz4.jpg');background-size:cover;background-position:center top;top:240px;left:0;right:0;bottom:0;position:absolute;"></div>
      <div class="rt-bg-overlay"></div>
      <div class="rt-banner">
        <div class="rt-banner-img" style="background-image:url('https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777982340/grok_image_1777982257091_q5lkbb.jpg');"></div>
        <div class="rt-banner-fade"></div>
        <div class="rt-banner-header">
          <button onclick="closeSub('routines')" style="background:rgba(0,0,0,0.35);border:1px solid rgba(255,255,255,0.18);cursor:pointer;padding:8px;display:flex;align-items:center;backdrop-filter:none;-webkit-backdrop-filter:none;">
            <svg width="14" height="12" viewBox="0 0 16 14" fill="none"><path d="M7 1L1 7L7 13" stroke="rgba(255,255,255,0.8)" stroke-width="1.5" stroke-linecap="square"/><line x1="1" y1="7" x2="15" y2="7" stroke="rgba(255,255,255,0.8)" stroke-width="1.5"/></svg>
          </button>
          <div class="rt-banner-title">My Routines</div>
          <div style="width:38px;"></div>
        </div>
      </div>
      <div class="rt-scroll">
        <span class="rt-section-label">Daily Schedule</span>
        ${_routines.map(r => {
          const isActive = r.name === activeName;
          const wordCount = r.words.length;
          const last = r.lastPracticed ? new Date(r.lastPracticed).toLocaleDateString('en-GB',{day:'numeric',month:'short'}) : 'Never';
          return `
          <div class="rt-card${isActive?' ':''}">
            ${isActive ? '<div style="position:absolute;top:0;right:0;padding:5px 12px;background:rgba(200,232,245,0.1);border-left:1px solid rgba(200,232,245,0.15);border-bottom:1px solid rgba(200,232,245,0.15);font-size:7px;letter-spacing:1.5px;text-transform:uppercase;color:var(--accent);">Now</div>' : ''}
            <div class="rt-card-top">
              <div class="rt-card-name-row">
                <div class="rt-card-dot" style="background:${r.color};box-shadow:0 0 8px ${r.color}60;"></div>
                <div class="rt-card-name">${r.name}</div>
              </div>
              <div class="rt-card-time">${r.time}</div>
            </div>
            <div class="rt-card-meta">
              <div class="rt-card-stat">
                <div class="rt-card-stat-val">${wordCount}</div>
                <div class="rt-card-stat-label">Words</div>
              </div>
              <div class="rt-card-stat">
                <div class="rt-card-stat-val">${r.reps}</div>
                <div class="rt-card-stat-label">Reps</div>
              </div>
              <div class="rt-card-stat">
                <div class="rt-card-stat-val">${last}</div>
                <div class="rt-card-stat-label">Last</div>
              </div>
            </div>
            <div class="rt-card-footer">
              <span class="rt-card-last">${wordCount === 0 ? 'Add words to start' : wordCount + ' word' + (wordCount!==1?'s':'') + ' ready'}</span>
              <div style="display:flex;gap:8px;">
                <button class="rt-start-btn rt-intro-btn" data-rid="${r.id}" style="padding:7px 10px;background:rgba(255,255,255,0.06);border-color:rgba(255,255,255,0.15);color:rgba(255,255,255,0.4);">
                  <svg width="10" height="10" viewBox="0 0 12 12" fill="none"><path d="M2 6H10M7 3L10 6L7 9" stroke="currentColor" stroke-width="1.4" stroke-linecap="square"/></svg>
                </button>
                <button class="rt-start-btn" onclick="rtStartSession(${r.id},event)" ${wordCount===0?'style="opacity:0.3;pointer-events:none;"':''}>Start</button>
              </div>
            </div>
          </div>`;
        }).join('')}
      </div>
    </div>`;

  // Wire arrow buttons via addEventListener — reliable on Android content:// protocol
  body.querySelectorAll('.rt-intro-btn').forEach(function(btn) {
    btn.addEventListener('click', function(e) {
      e.stopPropagation();
      _rtActiveId = parseInt(btn.getAttribute('data-rid'), 10);
      _rtDetailTab = 'words';
      _rtLibFilter = 'All';
      _rtIntroFromHome = false;
      renderRoutineIntro();
    });
  });
}

// ── ROUTINE INTRO — renders inline into routinesBody ──
function rtOpenDetail(id, e) {
  if (e) e.stopPropagation();
  _rtActiveId = parseInt(id, 10);
  _rtDetailTab = 'words';
  _rtLibFilter = 'All';
  renderRoutineIntro();
}

function renderRoutineIntro() {
  var body = document.getElementById('routinesBody');
  if (!body) return;
  var r = _routines.find(function(x){ return Number(x.id) === Number(_rtActiveId); });
  if (!r) return;

  var wordCount = r.words.length;
  var descriptors = {
    'Morning':   'Begin the day with natural origin sound. Each word activates a living frequency within your body.',
    'Midday':    'Restore balance at the centre of the day. These words realign your natural healing flow.',
    'Afternoon': 'Deepen your practice. These natural sounds carry grounding, focusing resonance.',
    'Evening':   'Wind down with intention. These words calm the nervous system and restore inner balance.',
    'Night':     'Deep healing begins at night. These root sounds work while your body rests and repairs.',
    'Custom':    'Your personal word prescription. Each sound is a phonetic key to your body healing intelligence.'
  };
  var desc = descriptors[r.name] || 'Each word is a living vibration. Phonetic keys that unlock your body healing intelligence.';
  var countText = wordCount > 0 ? wordCount : String.fromCharCode(8734);

  body.innerHTML =
    '<div class="rt-screen" style="position:relative;overflow:hidden;background:#060c18;">' +
    '<div style="position:absolute;top:0;left:0;right:0;bottom:0;' +
      'background-image:url(https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777965419/grok_image_1777891898700_zzskwn.jpg);' +
      'background-size:cover;background-position:center center;"></div>' +

    '<div style="position:absolute;top:0;left:0;right:0;bottom:0;' +
      'background:linear-gradient(to bottom,rgba(4,10,24,0.15) 0%,rgba(4,10,24,0.03) 25%,rgba(4,10,24,0.6) 60%,rgba(4,10,24,0.98) 100%);"></div>' +

    '<div style="position:relative;z-index:2;height:100%;display:flex;flex-direction:column;' +
      'padding:max(env(safe-area-inset-top,18px),18px) 28px calc(var(--nav-height,0px) + max(env(safe-area-inset-bottom,20px),20px));">' +

      // TOP ROW
      '<div style="display:flex;align-items:center;justify-content:space-between;flex-shrink:0;margin-bottom:4px;">' +
        '<div id="rtIntroBackBtn" style="width:42px;height:42px;cursor:pointer;border-radius:50%;' +
          'background:url(\'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782728734/file_00000000ae6071fa982c6eec401328c6_uvgfjs.png\') center/28px no-repeat,rgba(255,255,255,0.14);border:1px solid rgba(255,255,255,0.28);box-shadow:0 6px 18px rgba(0,0,0,.3),inset 0 1px 0 rgba(255,255,255,.4);backdrop-filter:none;-webkit-backdrop-filter:none;' +
          'display:flex;align-items:center;justify-content:center;flex-shrink:0;">' +
        '</div>' +
        '<span style="font-size:9px;font-weight:400;letter-spacing:6px;text-transform:uppercase;color:rgba(255,255,255,0.35);">NOWSBANSIU</span>' +
        '<button onclick="openIntroSetting()" style="width:40px;height:40px;background:rgba(6,12,24,0.42);border:1px solid rgba(255,255,255,0.18);backdrop-filter:none;-webkit-backdrop-filter:none;display:flex;align-items:center;justify-content:center;cursor:pointer;overflow:hidden;">' +
          '<svg width="4" height="16" viewBox="0 0 4 18" fill="none"><circle cx="2" cy="2" r="1.8" fill="rgba(255,255,255,0.7)"/><circle cx="2" cy="9" r="1.8" fill="rgba(255,255,255,0.7)"/><circle cx="2" cy="16" r="1.8" fill="rgba(255,255,255,0.7)"/></svg>' +
        '</button>' +
      '</div>' +

      // SPACER
      '<div style="flex:1;min-height:20px;"></div>' +

      // BOTTOM BLOCK
      '<div style="flex-shrink:0;">' +

        // COUNT + SACRED
        '<div style="font-size:56px;font-weight:800;color:#fff;line-height:1.05;' +
          'letter-spacing:-1px;">' +
          countText + ' Sacred' +
        '</div>' +

        // ROUTINE NAME in gold gradient
        '<div style="font-size:56px;font-weight:800;display:inline-block;line-height:1.05;' +
          'letter-spacing:-1px;margin-bottom:18px;color:#f5c842;' +
          'background:linear-gradient(90deg,#f5c842,#e8913a);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;">' +
          r.name +
        '</div>' +

        // DESCRIPTOR
        '<div style="font-size:14px;font-weight:300;color:rgba(255,255,255,0.72);' +
          'line-height:1.7;margin-bottom:24px;max-width:300px;">' +
          desc +
        '</div>' +

        // ACTIVATE SOUND TOGGLE
        '<div style="display:flex;align-items:center;justify-content:space-between;' +
          'background:rgba(10,18,38,0.75);border-radius:14px !important;' +
          'padding:14px 20px;margin-bottom:22px;">' +
          '<span style="font-size:14px;font-weight:700;color:#fff;">Activate Sound</span>' +
          '<div id="rtIntroToggle" class="rt-intro-toggle nwsb-pill-toggle" style="width:46px;height:26px;border-radius:999px !important;' +
            'background:#e8b100;position:relative;cursor:pointer;transition:background 0.25s;' +
            'flex-shrink:0;box-shadow:0 2px 12px rgba(232,177,0,0.45);">' +
            '<div class="nwsb-pill-knob" style="width:20px;height:20px;border-radius:50% !important;background:#fff;position:absolute;' +
              'top:3px;right:3px;transition:right 0.25s;box-shadow:0 1px 4px rgba(0,0,0,.25);' +
              'display:flex;align-items:center;justify-content:center;">' +
              '<svg width="11" height="9" viewBox="0 0 10 8" fill="none">' +
                '<path d="M1 4L3.5 6.5L9 1" stroke="#e8b100" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
              '</svg>' +
            '</div>' +
          '</div>' +
        '</div>' +

        // ENTER / SKIP
        '<div style="display:flex;align-items:center;justify-content:space-between;">' +
          '<div class="rt-intro-enter" style="display:flex;align-items:center;gap:10px;cursor:pointer;' +
            'background:rgba(20,28,48,0.85);border:1px solid rgba(255,255,255,0.18);' +
            'padding:15px 34px;font-size:13px;font-weight:600;letter-spacing:1.5px;' +
            'color:#fff;text-transform:uppercase;">' +
            '<svg width="15" height="13" viewBox="0 0 16 14" fill="none">' +
              '<path d="M3 7H13M8 2L13 7L8 12" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>' +
            '</svg>' +
            'Enter' +
          '</div>' +
          '<span class="rt-intro-skip" style="font-size:13px;font-weight:400;' +
            'letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,0.45);cursor:pointer;padding:15px 8px;">Skip</span>' +
        '</div>' +

      '</div>' + // end bottom block
    '</div>' + // end content layer
    '</div>'; // end rt-screen wrapper

  // Wire buttons via addEventListener
  var backBtn = body.querySelector('#rtIntroBackBtn');
  var enterBtn = body.querySelector('.rt-intro-enter');
  var skipBtn = body.querySelector('.rt-intro-skip');
  var rid = r.id;
  if (backBtn) backBtn.addEventListener('click', function() {
    if (_rtIntroFromHome) {
      _rtIntroFromHome = false;
      closeSub('routines');
    } else {
      renderRoutines();
    }
  });
  if (enterBtn) enterBtn.addEventListener('click', function() {
    // ENTER always opens the routine detail screen (Words / Library / History tabs)
    _rtActiveId = rid;
    var rCheck = _routines.find(function(x){ return Number(x.id) === Number(rid); });
    _rtDetailTab = (!rCheck || !rCheck.words || rCheck.words.length === 0) ? 'library' : 'words';
    _rtLibFilter = 'All';
    _rtIntroFromHome = false;
    renderRoutineDetail_inline();
  });
  if (skipBtn) skipBtn.addEventListener('click', function() {
    // SKIP goes back to the routines list
    _rtIntroFromHome = false;
    renderRoutines();
  });
  var toggleEl = body.querySelector('.rt-intro-toggle');
  if (toggleEl) toggleEl.addEventListener('click', function() { rtToggleActivate(toggleEl); });
}

function rtIntroClose() { renderRoutines(); }

// Renders the routine detail (with Library tab open) directly into routinesBody
// Used when ENTER is pressed on a 0-word routine — keeps user inside the routines sub-screen
function renderRoutineDetail_inline() {
  var body = document.getElementById('routinesBody');
  if (!body) return;
  var r = _routines.find(function(x){ return Number(x.id) === Number(_rtActiveId); });
  if (!r) return;

  var filters = typeof getAllCategories === 'function' ? getAllCategories() : ['All','Immunity Boost','Heart Health','Mental Clarity','Skin & Glow','Gut Health','Fitness & Muscle'];
  var libFiltered = getAllWordNames().filter(function(w) {
    if (_rtLibFilter === 'All') return true;
    var wordData = typeof MASTER_WORD_LIBRARY !== 'undefined' ? MASTER_WORD_LIBRARY.find(function(m){ return m.word === w; }) : null;
    if (!wordData) return false;
    return (wordData.categories || []).includes(_rtLibFilter) || (wordData.organ || '').toLowerCase().includes(_rtLibFilter.toLowerCase());
  });

  var wordsPanel = r.words.length === 0
    ? '<div style="text-align:center;padding:40px 20px;color:rgba(255,255,255,0.25);font-size:13px;">No words yet — add from Library below</div>'
    : r.words.map(function(w, i) {
        var meta = WORD_META[w] || {syl:'',organ:'',origin:''};
        return '<div class="rtd-word-row"><div class="rtd-word-num">' + (i+1) + '</div><div class="rtd-word-info"><div class="rtd-word-name">' + w + '</div><div class="rtd-word-syl">' + meta.syl + '</div></div><div class="rtd-word-tag">' + meta.organ + '</div></div>';
      }).join('');

  var libraryPanel = '<div class="rtd-filter-bar">' +
    filters.map(function(f){ return '<div class="rtd-filter-chip' + (_rtLibFilter===f?' active':'') + '" data-filter="' + f + '">' + f + '</div>'; }).join('') +
    '</div>' +
    libFiltered.map(function(w) {
      var meta = WORD_META[w] || {syl:'',organ:'',origin:''};
      var added = r.words.includes(w);
      return '<div class="rtd-lib-row"><div class="rtd-lib-info"><div class="rtd-lib-name">' + w + '</div><div class="rtd-lib-detail">' + meta.syl + ' · ' + meta.organ + '</div></div>' +
        '<div class="rtd-add-btn' + (added?' added':'') + '" data-word="' + w + '">' +
        (added ? '<svg width="12" height="10" viewBox="0 0 12 10" fill="none"><path d="M1 5L4 8.5L11 1" stroke="rgba(232,213,163,0.9)" stroke-width="1.5" stroke-linecap="square"/></svg>'
               : '<svg width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M6 1V11M1 6H11" stroke="rgba(200,232,245,0.8)" stroke-width="1.5" stroke-linecap="square"/></svg>') +
        '</div></div>';
    }).join('');

  var inlineBanners = {
    'Morning':   'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777989351/grok_image_1777988498025_yn2kwz.jpg',
    'Midday':    'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777989352/grok_image_1777988498991_vr7cc3.jpg',
    'Afternoon': 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777989352/grok_image_1777988560596_ihjsc6.jpg',
    'Evening':   'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777989352/grok_image_1777988562428_tddkze.jpg',
    'Night':     'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777989351/grok_image_1777988401110_loe5xq.jpg'
  };
  var inlineBannerUrl = inlineBanners[r.time] || inlineBanners['Evening'];

  body.innerHTML =
    '<div class="rtd-screen" style="position:relative;overflow:hidden;">' +
      '<div class="rt-bg" style="background-image:url(https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777965473/grok_image_1777891938824_cxuhwm.jpg);background-size:cover;background-position:center top;top:240px;left:0;right:0;bottom:0;position:absolute;"></div>' +
      '<div class="rt-bg-overlay"></div>' +
      '<div class="rt-banner" style="flex-shrink:0;position:relative;">' +
        '<div class="rt-banner-img" style="background-image:url(\'' + inlineBannerUrl + '\');"></div>' +
        '<div class="rt-banner-fade"></div>' +
        '<div class="rtd-header" style="position:absolute;top:0;left:0;right:0;">' +
          '<button class="rtd-inline-back" style="width:42px;height:42px;cursor:pointer;padding:0;border-radius:50%;background:url(\'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782728734/file_00000000ae6071fa982c6eec401328c6_uvgfjs.png\') center/28px no-repeat,rgba(255,255,255,0.14);border:1px solid rgba(255,255,255,0.28);box-shadow:0 6px 18px rgba(0,0,0,.3),inset 0 1px 0 rgba(255,255,255,.4);display:flex;align-items:center;justify-content:center;flex-shrink:0;">' +
          '</button>' +
          '<button class="rtd-myroutines-btn" style="background:rgba(255,255,255,0.08);border:1px solid rgba(255,255,255,0.18);border-radius:100px;cursor:pointer;padding:6px 14px;display:flex;align-items:center;gap:6px;font-size:10px;font-weight:500;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,0.65);">' +
            '<svg width="12" height="10" viewBox="0 0 14 12" fill="none"><path d="M1 1H13M1 6H10M1 11H7" stroke="rgba(255,255,255,0.65)" stroke-width="1.4" stroke-linecap="square"/></svg>' +
            'My Routines' +
          '</button>' +
        '</div>' +
        '<div style="position:absolute;bottom:0;left:0;right:0;padding:0 18px 16px;z-index:10;">' +
          '<div class="rtd-name" style="display:flex;align-items:center;gap:8px;padding:0;position:static;">' +
            '<div style="width:9px;height:9px;border-radius:50%;background:' + r.color + ';box-shadow:0 0 10px ' + r.color + '80;"></div>' +
            r.name +
          '</div>' +
          '<div class="rtd-meta" style="padding:2px 0 0;position:static;">' + r.time + ' · ' + r.words.length + ' words · ' + r.reps + ' reps</div>' +
        '</div>' +
      '</div>' +
      '<div class="rtd-tabs">' +
        '<button class="rtd-tab' + (_rtDetailTab==='words'?' active':'') + '" data-tab="words">Words</button>' +
        '<button class="rtd-tab' + (_rtDetailTab==='library'?' active':'') + '" data-tab="library">Library</button>' +
        '<button class="rtd-tab' + (_rtDetailTab==='history'?' active':'') + '" data-tab="history">History</button>' +
      '</div>' +
      '<div class="rtd-panel">' +
        (_rtDetailTab==='words' ? wordsPanel : '') +
        (_rtDetailTab==='library' ? libraryPanel : '') +
      '</div>' +
      '<div class="rtd-bottom">' +
        '<button class="rtd-edit-btn" data-editid="' + r.id + '">' +
          '<svg width="14" height="14" viewBox="0 0 16 16" fill="none"><path d="M11 2L14 5L5 14H2V11L11 2Z" stroke="rgba(255,255,255,0.6)" stroke-width="1.4" stroke-linecap="square" fill="none"/></svg>' +
        '</button>' +
        '<button class="rtd-session-btn' + (r.words.length===0?' rtd-disabled':'') + '" data-startid="' + r.id + '" ' + (r.words.length===0?'style="opacity:0.4;pointer-events:none;"':'') + '>' +
          'Start Session · ' + r.words.length + ' Words' +
        '</button>' +
      '</div>' +
    '</div>';

  // Wire back button
  body.querySelector('.rtd-inline-back').addEventListener('click', function() { renderRoutineIntro(); });
  // Wire My Routines button
  var myRoutinesBtn = body.querySelector('.rtd-myroutines-btn');
  if (myRoutinesBtn) myRoutinesBtn.addEventListener('click', function() { renderRoutines(); });
  // Wire tab buttons
  body.querySelectorAll('.rtd-tab[data-tab]').forEach(function(btn) {
    btn.addEventListener('click', function() { _rtDetailTab = btn.getAttribute('data-tab'); renderRoutineDetail_inline(); });
  });
  // Wire filter chips
  body.querySelectorAll('.rtd-filter-chip[data-filter]').forEach(function(chip) {
    chip.addEventListener('click', function() { _rtLibFilter = chip.getAttribute('data-filter'); renderRoutineDetail_inline(); });
  });
  // Wire add buttons
  body.querySelectorAll('.rtd-add-btn[data-word]').forEach(function(btn) {
    btn.addEventListener('click', function() { rtToggleWord(r.id, btn.getAttribute('data-word')); renderRoutineDetail_inline(); });
  });
  // Wire edit
  var editBtn = body.querySelector('.rtd-edit-btn[data-editid]');
  if (editBtn) editBtn.addEventListener('click', function() { rtOpenEdit(r.id); });
  // Wire start session
  var startBtn = body.querySelector('.rtd-session-btn[data-startid]');
  if (startBtn && r.words.length > 0) startBtn.addEventListener('click', function() { rtStartSession(r.id); });
}

function rtIntroEnter(id) { rtStartSession(id); }

function rtIntroSkip() {
  // Close 'routines' too (same pattern as rtStartSession) — it still has the
  // "1 Sacred <name>" intro rendered inside #routinesBody, so leaving it open
  // meant pressing back from routine-detail revealed that stale intro
  // instead of the actual routines list.
  closeSub('routines');
  openSub('routine-detail');
  setTimeout(renderRoutineDetail, 60);
}

function rtToggleActivate(el) {
  var thumb = el.querySelector('div');
  var isOn = el.style.background === 'rgb(232, 177, 0)' || el.getAttribute('data-on') !== 'false';
  if (isOn) {
    // Turn OFF — session will open silently
    _pwAutoPlay = false;
    el.style.background = 'rgba(255,255,255,0.12)';
    el.style.boxShadow = 'none';
    el.setAttribute('data-on','false');
    if (thumb) { thumb.style.right = 'calc(100% - 23px)'; thumb.innerHTML = ''; }
  } else {
    // Turn ON — word pronounces itself automatically when session starts
    _pwAutoPlay = true;
    el.style.background = '#e8b100';
    el.style.boxShadow = '0 2px 12px rgba(232,177,0,0.45)';
    el.setAttribute('data-on','true');
    if (thumb) { thumb.style.right = '3px'; thumb.innerHTML = '<svg width="11" height="9" viewBox="0 0 10 8" fill="none"><path d="M1 4L3.5 6.5L9 1" stroke="#e8b100" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>'; }
  }
}

// ── RENDER ROUTINE DETAIL ──
function renderRoutineDetail() {
  const body = document.getElementById('routineDetailBody');
  if (!body) return;
  const r = _routines.find(x => x.id === _rtActiveId);
  if (!r) return;

  const wordsPanel = `
    ${r.words.length === 0
      ? '<div style="text-align:center;padding:40px 20px;color:rgba(255,255,255,0.25);font-size:13px;">No words yet — go to Library to add words</div>'
      : r.words.map((w,i) => {
          const meta = WORD_META[w] || {syl:'',organ:'',origin:''};
          return `<div class="rtd-word-row">
            <div class="rtd-word-num">${i+1}</div>
            <div class="rtd-word-info">
              <div class="rtd-word-name">${w}</div>
              <div class="rtd-word-syl">${meta.syl}</div>
            </div>
            <div class="rtd-word-tag">${meta.organ}</div>
            <div class="rtd-word-drag">
              <svg width="14" height="12" viewBox="0 0 14 12" fill="none"><path d="M2 9H12M2 6H12M2 3H12" stroke="rgba(255,255,255,0.4)" stroke-width="1.3" stroke-linecap="square"/></svg>
            </div>
          </div>`;
        }).join('')
    }`;

  const filters = typeof getAllCategories === 'function' ? getAllCategories() : ['All','Immunity Boost','Heart Health','Mental Clarity','Skin & Glow','Gut Health','Fitness & Muscle'];
  const libFiltered = getAllWordNames().filter(w => {
    if (_rtLibFilter === 'All') return true;
    const wordData = typeof MASTER_WORD_LIBRARY !== 'undefined' ? MASTER_WORD_LIBRARY.find(m => m.word === w) : null;
    if (!wordData) return false;
    return (wordData.categories || []).includes(_rtLibFilter) || (wordData.organ || '').toLowerCase().includes(_rtLibFilter.toLowerCase());
  });

  const libraryPanel = `
    <div class="rtd-filter-bar">
      ${filters.map(f => `<div class="rtd-filter-chip${_rtLibFilter===f?' active':''}" onclick="rtSetFilter('${f}')">${f}</div>`).join('')}
    </div>
    ${libFiltered.map(w => {
      const meta = WORD_META[w] || {syl:'',organ:'',origin:''};
      const added = r.words.includes(w);
      return `<div class="rtd-lib-row">
        <div class="rtd-lib-info">
          <div class="rtd-lib-name">${w}</div>
          <div class="rtd-lib-detail">${meta.syl} · ${meta.organ}</div>
        </div>
        <div class="rtd-add-btn${added?' added':''}" onclick="rtToggleWord(${_rtActiveId},'${w}')">
          ${added
            ? '<svg width="12" height="10" viewBox="0 0 12 10" fill="none"><path d="M1 5L4 8.5L11 1" stroke="rgba(232,213,163,0.9)" stroke-width="1.5" stroke-linecap="square"/></svg>'
            : '<svg width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M6 1V11M1 6H11" stroke="rgba(200,232,245,0.8)" stroke-width="1.5" stroke-linecap="square"/></svg>'}
        </div>
      </div>`;
    }).join('')}`;

  const historyPanel = `
    ${r.lastPracticed
      ? `<div class="rtd-hist-row"><div><div class="rtd-hist-date">Today</div><div class="rtd-hist-words">${r.words.join(', ')}</div></div><div class="rtd-hist-stat">${r.words.length} words</div></div>`
      : '<div style="text-align:center;padding:40px 20px;color:rgba(255,255,255,0.25);font-size:13px;">No sessions yet</div>'}`;

  const ROUTINE_BANNERS = {
    'Morning':   'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777989351/grok_image_1777988498025_yn2kwz.jpg',
    'Midday':    'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777989352/grok_image_1777988498991_vr7cc3.jpg',
    'Afternoon': 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777989352/grok_image_1777988560596_ihjsc6.jpg',
    'Evening':   'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777989352/grok_image_1777988562428_tddkze.jpg',
    'Night':     'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777989351/grok_image_1777988401110_loe5xq.jpg'
  };
  const bannerUrl = ROUTINE_BANNERS[r.time] || ROUTINE_BANNERS['Evening'];

  body.innerHTML = `
    <div class="rtd-screen" style="position:relative;overflow:hidden;">
      <div class="rt-bg" style="background-image:url(https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777965473/grok_image_1777891938824_cxuhwm.jpg);background-size:cover;background-position:center top;top:240px;left:0;right:0;bottom:0;position:absolute;"></div>
      <div class="rt-bg-overlay"></div>
      <div class="rt-banner" style="flex-shrink:0;position:relative;">
        <div class="rt-banner-img" style="background-image:url('${bannerUrl}');"></div>
        <div class="rt-banner-fade"></div>
        <div class="rtd-header" style="position:absolute;top:0;left:0;right:0;">
          <button onclick="closeSub('routine-detail');openSub('routines');" style="width:34px;height:34px;min-width:34px !important;min-height:34px !important;border-radius:50% !important;background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.18);cursor:pointer;padding:0;display:flex;align-items:center;justify-content:center;flex-shrink:0;">
            <svg width="14" height="12" viewBox="0 0 16 14" fill="none"><path d="M7 1L1 7L7 13" stroke="rgba(255,255,255,0.65)" stroke-width="1.5" stroke-linecap="square"/><line x1="1" y1="7" x2="15" y2="7" stroke="rgba(255,255,255,0.65)" stroke-width="1.5"/></svg>
          </button>
          <button onclick="closeSub('routine-detail');openSub('routines');" style="background:rgba(255,255,255,0.08);border:1px solid rgba(255,255,255,0.18);border-radius:100px;cursor:pointer;padding:6px 14px;display:flex;align-items:center;gap:6px;font-size:10px;font-weight:500;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,0.65);">
            <svg width="12" height="10" viewBox="0 0 14 12" fill="none"><path d="M1 1H13M1 6H10M1 11H7" stroke="rgba(255,255,255,0.65)" stroke-width="1.4" stroke-linecap="square"/></svg>
            My Routines
          </button>
        </div>
        <div style="position:absolute;bottom:0;left:0;right:0;padding:0 18px 16px;z-index:10;">
          <div class="rtd-name" style="display:flex;align-items:center;gap:8px;padding:0;position:static;">
            <div style="width:9px;height:9px;border-radius:50%;background:${r.color};box-shadow:0 0 10px ${r.color}80;"></div>
            ${r.name}
          </div>
          <div class="rtd-meta" style="padding:2px 0 0;position:static;">${r.time} · ${r.words.length} words · ${r.reps} reps</div>
        </div>
      </div>
      <div class="rtd-tabs">
        <button class="rtd-tab${_rtDetailTab==='words'?' active':''}" onclick="rtSetTab('words')">Words</button>
        <button class="rtd-tab${_rtDetailTab==='library'?' active':''}" onclick="rtSetTab('library')">Library</button>
        <button class="rtd-tab${_rtDetailTab==='history'?' active':''}" onclick="rtSetTab('history')">History</button>
      </div>
      <div class="rtd-panel">
        ${_rtDetailTab==='words' ? wordsPanel : ''}
        ${_rtDetailTab==='library' ? libraryPanel : ''}
        ${_rtDetailTab==='history' ? historyPanel : ''}
      </div>
      <div class="rtd-bottom">
        <button class="rtd-edit-btn" onclick="rtOpenEdit(${r.id})">
          <svg width="14" height="14" viewBox="0 0 16 16" fill="none"><path d="M11 2L14 5L5 14H2V11L11 2Z" stroke="rgba(255,255,255,0.6)" stroke-width="1.4" stroke-linecap="square" fill="none"/></svg>
        </button>
        <button class="rtd-session-btn" onclick="rtStartSession(${r.id})" ${r.words.length===0?'style="opacity:0.4;pointer-events:none;"':''}>
          Start Session · ${r.words.length} Words
        </button>
      </div>
    </div>`;
}

function rtSetTab(tab) { _rtDetailTab = tab; renderRoutineDetail(); }
function rtSetFilter(f) { _rtLibFilter = f; renderRoutineDetail(); }

function rtToggleWord(id, word) {
  const r = _routines.find(x => x.id === id);
  if (!r) return;
  const idx = r.words.indexOf(word);
  if (idx >= 0) r.words.splice(idx, 1);
  else r.words.push(word);
  saveRoutines();
  renderRoutineDetail();
}

function rtStartSession(id, e) {
  if (e) e.stopPropagation();
  const r = _routines.find(x => x.id === id);
  if (!r || !r.words || r.words.length === 0) return;
  // Load routine words into active PRACTICE_WORDS
  loadRoutineWords(r);
  window._rtManualLaunch = true;
  // Reset player state
  _pwIdx = 0; _pwRepCount = 0; _pwDone = false; _pwMode = 'listen';
  // Update lastPracticed
  r.lastPracticed = Date.now();
  saveRoutines();
  // Arm auto-play if Activate Sound toggle is ON, then open player
  _pwAutoPlayOnce = _pwAutoPlay;
  closeSub('routine-detail');
  closeSub('routines');
  setTimeout(() => openSub('practice'), 80);
}

function rtOpenPlayer(routineId, wordIdx) {
  rtStartSession(routineId);
}

// ── EDIT ROUTINE ──
function rtOpenEdit(id) {
  const r = _routines.find(x => x.id === id);
  if (!r) return;
  _rtEditId = id;
  _rtEditName = r.name;
  _rtEditTime = r.time;
  renderRtEdit();
}

function renderRtEdit() {
  let overlay = document.getElementById('rtEditOverlay');
  if (!overlay) {
    overlay = document.createElement('div');
    overlay.id = 'rtEditOverlay';
    overlay.className = 'rt-edit-overlay';
    overlay.onclick = e => { if (e.target === overlay) closeRtEdit(); };
    document.body.appendChild(overlay);
  }
  const times = ['Morning','Midday','Afternoon','Evening','Night','Custom'];
  overlay.style.display = 'flex';
  overlay.innerHTML = `
    <div class="rt-edit-sheet">
      <div class="rt-edit-banner">
        <div class="rt-edit-banner-img"></div>
        <div class="rt-edit-banner-fade"></div>
        <div style="position:absolute;bottom:14px;left:20px;z-index:2;">
          <div class="rt-edit-title" style="margin-bottom:0;">Customize Routine</div>
        </div>
      </div>
      <div class="rt-edit-content">
      <div class="rt-edit-field">
        <span class="rt-edit-label">Routine Name</span>
        <input class="rt-edit-input" id="rtEditNameInput" value="${_rtEditName}" placeholder="e.g. Pre-Workout" oninput="_rtEditName=this.value">
      </div>
      <div class="rt-edit-field">
        <span class="rt-edit-label">Time of Day</span>
        <div class="rt-edit-time-row" style="flex-wrap:wrap;gap:6px;">
          ${times.map(t => `<div class="rt-edit-time-chip${_rtEditTime===t?' active':''}" onclick="rtSelectTime('${t}')" style="flex:0 0 calc(33% - 4px);">${t}</div>`).join('')}
        </div>
      </div>
      <button class="rt-edit-save" onclick="rtSaveEdit()">Save Changes</button>
      </div>
    </div>`;
}

function rtSelectTime(t) { _rtEditTime = t; renderRtEdit(); }

function rtSaveEdit() {
  const r = _routines.find(x => x.id === _rtEditId);
  if (!r) return;
  r.name = _rtEditName || r.name;
  r.time = _rtEditTime || r.time;
  saveRoutines();
  closeRtEdit();
  renderRoutineDetail();
  renderRoutines();
}

function closeRtEdit() {
  const overlay = document.getElementById('rtEditOverlay');
  if (overlay) overlay.style.display = 'none';
}

// Hook into openSub for routines
const _origOpenSub = window.openSub;
window.openSub = function(id) {
  if (id === 'routines') {
    _origOpenSub(id);
    setTimeout(renderRoutines, 60);
  } else if (id === 'routine-detail') {
    _origOpenSub(id);
    setTimeout(renderRoutineDetail, 60);
  } else if (id === 'health-category') {
    _origOpenSub(id);
    setTimeout(hcpRenderTab, 60);
  } else if (id === 'hcp-intro') {
    _origOpenSub(id);
  } else if (id === 'sound-library') {
    _origOpenSub(id);
    var introPage = document.getElementById('slIntroPage');
    if (introPage) {
      if (typeof shouldShowIntro === 'function' && !shouldShowIntro('sound-library')) {
        introPage.classList.add('sl-intro-hidden');
        setTimeout(function() {
          if (typeof window.slEnterLibrary === 'function') window.slEnterLibrary();
          else if (typeof slRender === 'function') slRender();
        }, 80);
      } else {
        introPage.classList.remove('sl-intro-hidden');
        try {
          var _s = JSON.parse(localStorage.getItem('nwsb_sentences') || '[]');
          var _p = JSON.parse(localStorage.getItem('nwsb_purchased') || '[]');
          var _all = typeof PRACTICE_WORDS !== 'undefined' ? PRACTICE_WORDS : [];
          var isStat = document.getElementById('slIntroStatSentences');
          var iwStat = document.getElementById('slIntroStatWords');
          var ipStat = document.getElementById('slIntroStatPurchased');
          if (isStat) isStat.textContent = _s.length;
          if (iwStat) iwStat.textContent = _all.length;
          if (ipStat) ipStat.textContent = _p.length;
        } catch(e) {}
      }
    }
  } else {
    _origOpenSub(id);
  }
};

// Also update routines list after save
function saveRoutines() {
  try { localStorage.setItem('nwsb_routines', JSON.stringify(_routines)); } catch(e) {}
  setTimeout(updateTodayCard, 100);
}

// ──────────────────────────────────────────────
// SOUND LIBRARY — Full logic
// ──────────────────────────────────────────────
var _slTab = 'sentences';
var _slWordsFilter = 'All';
var _slSort = 'recent'; // 'recent' | 'az'

// ── DATA HELPERS ──
function slGetSentences() {
  try { return JSON.parse(localStorage.getItem('nwsb_sentences') || '[]'); } catch(e) { return []; }
}
function slSaveSentences(arr) {
  try { localStorage.setItem('nwsb_sentences', JSON.stringify(arr)); } catch(e) {}
}
function slGetPurchased() {
  try { return JSON.parse(localStorage.getItem('nwsb_purchased') || '[]'); } catch(e) { return []; }
}
function slGetSubscriptionWords() {
  // Subscription words = all words in master library not individually purchased
  var purchased = slGetPurchased().map(function(p){ return p.word; });
  var all = typeof PRACTICE_WORDS !== 'undefined' ? PRACTICE_WORDS : [];
  return all.filter(function(w){ return !purchased.includes(w.word); });
}

// Public: call this after a sentence is generated to save it
window.slAddSentence = function(text, words, routineName) {
  var arr = slGetSentences();
  arr.unshift({
    id: Date.now(),
    text: text,
    words: words || [],
    routineName: routineName || 'Practice',
    date: Date.now(),
    playCount: 0
  });
  // Keep last 50 sentences
  if (arr.length > 50) arr = arr.slice(0, 50);
  slSaveSentences(arr);
};

// ── INTRO → MAIN LIBRARY TRANSITION ──
window.slEnterLibrary = function slEnterLibrary() {
  var introPage = document.getElementById('slIntroPage');
  if (introPage) {
    introPage.classList.add('sl-intro-hidden');
  }
  setTimeout(slRender, 60);
};

// ── MAIN RENDER ──
function slRender() {
  var sentences = slGetSentences();
  var subWords = slGetSubscriptionWords();
  var purchased = slGetPurchased();

  // Update stats
  var els = ['slStatSentences','slStatWords','slStatPurchased','slBadgeSentences','slBadgeWords','slBadgePurchased'];
  var vals = [sentences.length, subWords.length, purchased.length, sentences.length, subWords.length, purchased.length];
  els.forEach(function(id, i) {
    var el = document.getElementById(id);
    if (el) el.textContent = vals[i];
  });

  var content = document.getElementById('slContent');
  if (!content) return;

  if (_slTab === 'sentences') {
    content.innerHTML = slRenderSentences(sentences);
  } else if (_slTab === 'words') {
    content.innerHTML = slRenderWords(subWords);
  } else if (_slTab === 'purchased') {
    content.innerHTML = slRenderPurchased(purchased, subWords);
  }
}

// ── TAB SWITCH ──
function slSetTab(tab) {
  _slTab = tab;
  ['sentences','words','purchased'].forEach(function(t) {
    var btn = document.getElementById('slTab-' + t);
    if (btn) btn.classList.toggle('active', t === tab);
  });
  slRender();
}

// ── SORT ──
function slSetSort(s) {
  _slSort = s;
  document.querySelectorAll('.sl-sort-btn').forEach(function(b){ b.classList.toggle('active', b.getAttribute('data-sort') === s); });
  slRender();
}

// ── FILTER (words tab) ──
function slSetFilter(f) {
  _slWordsFilter = f;
  document.querySelectorAll('.sl-filter-chip').forEach(function(c){ c.classList.toggle('active', c.getAttribute('data-filter') === f); });
  slRender();
}

// ── RENDER: SENTENCES TAB ──
function slRenderSentences(sentences) {
  if (sentences.length === 0) {
    return '<div class="sl-empty">' +
      '<svg class="sl-empty-icon" width="52" height="44" viewBox="0 0 52 44" fill="none">' +
        '<path d="M4 4H48M4 14H38M4 24H48M4 34H32" stroke="rgba(200,232,245,0.6)" stroke-width="1.5" stroke-linecap="square"/>' +
      '</svg>' +
      '<div class="sl-empty-title">No sentences yet</div>' +
      '<div class="sl-empty-text">Complete a practice session to save your first sentence — or subscribe to unlock words and buy individual tracks for deeper healing.</div>' +
      '<button class="sl-empty-cta" onclick="navFromSub(\'sound-library\',openPracticeIntro)">Start a Session</button>' +
    '</div>';
  }

  // Sort
  var sorted = sentences.slice();
  if (_slSort === 'az') {
    sorted.sort(function(a,b){ return a.text.localeCompare(b.text); });
  } // default: recent (already newest first from unshift)

  var html = '<div class="sl-sort-row">' +
    '<span class="sl-sort-label">' + sorted.length + ' sentence' + (sorted.length !== 1 ? 's' : '') + '</span>' +
    '<div class="sl-sort-btns">' +
      '<button class="sl-sort-btn' + (_slSort==='recent'?' active':'') + '" data-sort="recent" onclick="slSetSort(\'recent\')">Recent</button>' +
      '<button class="sl-sort-btn' + (_slSort==='az'?' active':'') + '" data-sort="az" onclick="slSetSort(\'az\')">A–Z</button>' +
    '</div>' +
  '</div>';

  sorted.forEach(function(s) {
    var dateStr = slFormatDate(s.date);
    // Build sentence text with highlighted words
    var highlightedText = s.text;
    (s.words || []).forEach(function(w) {
      var re = new RegExp('\\b(' + w + ')\\b', 'gi');
      highlightedText = highlightedText.replace(re, '<span class="sl-word-hl">$1</span>');
    });
    // Word chips
    var chips = (s.words || []).map(function(w){ return '<span class="sl-sentence-chip">' + w + '</span>'; }).join('');

    html += '<div class="sl-sentence-card">' +
      '<div class="sl-sentence-eyebrow">' +
        '<span>Built Sentence</span>' +
        '<span class="sl-sentence-date">' + dateStr + '</span>' +
      '</div>' +
      '<div class="sl-sentence-text">' + highlightedText + '</div>' +
      (chips ? '<div class="sl-sentence-chips">' + chips + '</div>' : '') +
      '<div class="sl-sentence-footer">' +
        '<div class="sl-sentence-meta">' +
          '<svg width="11" height="10" viewBox="0 0 12 11" fill="none"><circle cx="6" cy="5.5" r="4.5" stroke="rgba(255,255,255,0.4)" stroke-width="1.2"/><path d="M6 3V6L8 7.5" stroke="rgba(255,255,255,0.4)" stroke-width="1.2" stroke-linecap="square"/></svg>' +
          (s.routineName || 'Practice') +
          (s.playCount ? ' · ' + s.playCount + ' plays' : '') +
        '</div>' +
        '<div class="sl-sentence-actions">' +
          '<button class="sl-sentence-play-btn" onclick="slPlaySentence(\'' + s.id + '\')" title="Play">' +
            '<svg width="10" height="12" viewBox="0 0 10 12" fill="none"><path d="M1 1L9 6L1 11V1Z" fill="rgba(200,232,245,0.8)"/></svg>' +
          '</button>' +
          '<button class="sl-sentence-delete-btn" onclick="slDeleteSentence(\'' + s.id + '\')" title="Delete">' +
            '<svg width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M2 2L10 10M10 2L2 10" stroke="rgba(255,100,100,0.65)" stroke-width="1.4" stroke-linecap="square"/></svg>' +
          '</button>' +
        '</div>' +
      '</div>' +
    '</div>';
  });

  return html;
}

// ── RENDER: MY WORDS TAB ──
function slRenderWords(words) {
  if (words.length === 0) {
    return '<div class="sl-empty">' +
      '<svg class="sl-empty-icon" width="44" height="44" viewBox="0 0 44 44" fill="none">' +
        '<circle cx="22" cy="22" r="18" stroke="rgba(200,232,245,0.45)" stroke-width="1.4"/>' +
        '<path d="M14 22H22M22 22V14" stroke="rgba(200,232,245,0.45)" stroke-width="1.4" stroke-linecap="square"/>' +
        '<path d="M22 22L30 22" stroke="rgba(200,232,245,0.22)" stroke-width="1.4" stroke-linecap="square"/>' +
      '</svg>' +
      '<div class="sl-empty-title">No words yet</div>' +
      '<div class="sl-empty-text">Subscribe to unlock your full word library and start building healing sentences.</div>' +
      '<button class="sl-empty-cta" onclick="closeSub(\'sound-library\');setTimeout(function(){ alert(\'Subscription coming soon\') },80)">Subscribe to Unlock</button>' +
      '<div style="margin-top:8px;font-size:9px;color:rgba(255,255,255,0.18);letter-spacing:1px;">or purchase individual words below</div>' +
      '<button style="margin-top:10px;padding:8px 18px;background:transparent;border:1px solid rgba(232,213,163,0.22);font-size:8px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(232,213,163,0.6);cursor:pointer;font-family:\'DM Sans\',sans-serif;" onclick="slSetTab(\'purchased\')">Browse The Word Atelier</button>' +
    '</div>';
  }

  // Get all categories for filter
  var cats = ['All'];
  words.forEach(function(w) {
    (w.categories || []).forEach(function(c){ if (!cats.includes(c)) cats.push(c); });
  });

  // Filter
  var filtered = _slWordsFilter === 'All'
    ? words
    : words.filter(function(w){ return (w.categories || []).includes(_slWordsFilter); });

  // Sort
  var sorted = filtered.slice();
  if (_slSort === 'az') sorted.sort(function(a,b){ return a.word.localeCompare(b.word); });

  var html = '';

  // Filter chips (only show if multiple categories)
  if (cats.length > 1) {
    html += '<div class="sl-filter-row">';
    cats.forEach(function(c) {
      html += '<div class="sl-filter-chip' + (_slWordsFilter===c?' active':'') + '" data-filter="' + c + '" onclick="slSetFilter(\'' + c + '\')">' + c + '</div>';
    });
    html += '</div>';
  }

  html += '<div class="sl-sort-row">' +
    '<span class="sl-word-count-label"><span>' + sorted.length + '</span> word' + (sorted.length !== 1 ? 's' : '') + ' · Subscription</span>' +
    '<div class="sl-sort-btns">' +
      '<button class="sl-sort-btn' + (_slSort==='recent'?' active':'') + '" data-sort="recent" onclick="slSetSort(\'recent\')">Default</button>' +
      '<button class="sl-sort-btn' + (_slSort==='az'?' active':'') + '" data-sort="az" onclick="slSetSort(\'az\')">A–Z</button>' +
    '</div>' +
  '</div>';

  if (sorted.length === 0) {
    html += '<div style="text-align:center;padding:32px 0;font-size:12px;color:rgba(255,255,255,0.22);">No words in this category.</div>';
    return html;
  }

  sorted.forEach(function(w) {
    html += '<div class="sl-word-card" onclick="slOpenWord(\'' + w.word + '\')">' +
      '<div class="sl-word-disc"><div class="sl-word-disc-letter">' + w.word.charAt(0) + '</div></div>' +
      '<div class="sl-word-info">' +
        '<div class="sl-word-name">' + w.word + '</div>' +
        '<div class="sl-word-phonetic">' + (w.phonetic || '') + '</div>' +
      '</div>' +
      '<div class="sl-word-right">' +
        '<span class="sl-word-badge sl-badge-sub">Subscription</span>' +
        '<span class="sl-word-organ">' + (w.organ || '') + '</span>' +
      '</div>' +
    '</div>';
  });

  return html;
}

// ── RENDER: PURCHASED TAB ──
function slRenderPurchased(purchased, allSubWords) {
  // Upgrade banner always at top
  var html = '<div class="sl-upgrade-banner">' +
    '<span class="sl-upgrade-label">The Word Atelier</span>' +
    '<div class="sl-upgrade-title">Acquire more words.<br>Build deeper sentences.</div>' +
    '<div class="sl-upgrade-text">Each word you acquire unlocks new sentence combinations. The more words you own, the richer and more powerful your healing sentences become.</div>' +
    '<button class="sl-upgrade-btn" onclick="navFromSub(\'sound-library\',function(){ openSub(\'word-store\') || alert(\'Word Atelier coming soon\') })">' +
      '<svg width="12" height="12" viewBox="0 0 14 14" fill="none"><path d="M2 2H4L5.5 9.5H10L11.5 5H4.5" stroke="currentColor" stroke-width="1.3" stroke-linecap="square"/><circle cx="6" cy="12" r="1" fill="currentColor"/><circle cx="9.5" cy="12" r="1" fill="currentColor"/></svg>' +
      'Browse The Word Atelier' +
    '</button>' +
  '</div>';

  if (purchased.length === 0) {
    html += '<div class="sl-empty" style="padding-top:28px;">' +
      '<svg class="sl-empty-icon" width="44" height="44" viewBox="0 0 44 44" fill="none">' +
        '<path d="M8 8H14L18 28H34L38 16H14" stroke="rgba(232,213,163,0.55)" stroke-width="1.5" stroke-linecap="square"/>' +
        '<circle cx="20" cy="38" r="2.5" fill="rgba(232,213,163,0.4)"/>' +
        '<circle cx="32" cy="38" r="2.5" fill="rgba(232,213,163,0.4)"/>' +
      '</svg>' +
      '<div class="sl-empty-title">No purchased words yet</div>' +
      '<div class="sl-empty-text">Acquire individual words from The Word Atelier — each acquisition unlocks new sentence combinations and deeper healing frequencies.</div>' +
    '</div>';
    return html;
  }

  html += '<span class="sl-word-count-label"><span>' + purchased.length + '</span> purchased word' + (purchased.length !== 1 ? 's' : '') + '</span>';

  purchased.forEach(function(p) {
    var dateStr = p.purchasedAt ? slFormatDate(p.purchasedAt) : 'Purchased';
    html += '<div class="sl-word-card" onclick="slOpenWord(\'' + (p.word || '') + '\')">' +
      '<div class="sl-word-disc" style="border-color:rgba(232,213,163,0.2);background:rgba(232,213,163,0.05);">' +
        '<div class="sl-word-disc-letter" style="color:rgba(232,213,163,0.55);">' + (p.word || '?').charAt(0) + '</div>' +
      '</div>' +
      '<div class="sl-word-info">' +
        '<div class="sl-word-name">' + (p.word || '—') + '</div>' +
        '<div class="sl-word-phonetic">' + (p.phonetic || '') + '</div>' +
        '<div class="sl-purchased-date">' + dateStr + '</div>' +
      '</div>' +
      '<div class="sl-word-right">' +
        '<span class="sl-word-badge sl-badge-buy">Purchased</span>' +
        '<span class="sl-word-organ">' + (p.organ || '') + '</span>' +
      '</div>' +
    '</div>';
  });

  return html;
}

// ── ACTIONS ──
function slPlaySentence(id) {
  var sentences = slGetSentences();
  var s = sentences.find(function(x){ return String(x.id) === String(id); });
  if (!s) return;
  // Increment play count
  s.playCount = (s.playCount || 0) + 1;
  slSaveSentences(sentences);
  // Load sentence into practice player as a "sentence playback"
  // Set a special sentence playback state and open player
  window._slSentencePlayback = s;
  closeSub('sound-library');
  setTimeout(function() {
    if (typeof openSub === 'function') openSub('practice');
  }, 80);
  slRender();
}

function slDeleteSentence(id) {
  var sentences = slGetSentences();
  var idx = sentences.findIndex(function(x){ return String(x.id) === String(id); });
  if (idx === -1) return;
  sentences.splice(idx, 1);
  slSaveSentences(sentences);
  slRender();
}

function slOpenWord(wordName) {
  // Find the word in PRACTICE_WORDS and jump to it in the player
  var words = typeof PRACTICE_WORDS !== 'undefined' ? PRACTICE_WORDS : [];
  var idx = words.findIndex(function(w){ return w.word === wordName; });
  if (idx >= 0) {
    _pwIdx = idx;
    closeSub('sound-library');
    setTimeout(function(){ openSub('practice'); }, 80);
  }
}

// ── DATE FORMATTER ──
function slFormatDate(ts) {
  if (!ts) return '';
  var d = new Date(ts);
  var now = new Date();
  var diff = now - d;
  if (diff < 60000) return 'Just now';
  if (diff < 3600000) return Math.floor(diff/60000) + 'm ago';
  if (diff < 86400000) return Math.floor(diff/3600000) + 'h ago';
  if (diff < 604800000) return Math.floor(diff/86400000) + 'd ago';
  return d.toLocaleDateString('en', {month:'short', day:'numeric'});
}

// ── EXPOSE ALL SL FUNCTIONS ON WINDOW so inline onclick handlers can reach them ──
window.slSetTab        = slSetTab;
window.slSetSort       = slSetSort;
window.slSetFilter     = slSetFilter;
window.slRender        = slRender;
window.slPlaySentence  = slPlaySentence;
window.slDeleteSentence = slDeleteSentence;
window.slOpenWord      = slOpenWord;

// ══ SHABDAPATHY CHAPTER READER ══
var _scChapters = [
  {
    title: 'I. The Origin of Sound',
    body: `
      <div class="sc-section">
        <span class="sc-section-label">Chapter I</span>
        <div class="sc-section-title">The Origin of Sound</div>
        <p class="sc-body-text">Before any language existed, before any script was carved into stone or pressed into clay, there was sound. Not arbitrary sound — but precise, biologically determined vibrations that the human body produced in response to the natural world.</p>
        <p class="sc-body-text">Every primordial sound came from a physical action: the mouth opening in surprise (<em>A</em>), the nasal hum of the nursing infant (<em>M</em>), the roar of wind through the throat (<em>R</em>), the tongue striking the palate like rain on earth (<em>T</em>). These were not invented. They were discovered — by the body, in response to existence.</p>
        <div class="sc-quote">"Every word in every language — across all civilizations — has a root vibration that was first formed naturally, in the human body, before any dictionary ever existed."</div>
        <div class="sc-divider"></div>
        <p class="sc-body-text">Across all human civilizations — from Sumerian and proto-Dravidian to Indigenous American languages — the same root sounds appear mapped to the same natural phenomena. Water words carry lip-sounds. Fire words carry breath-sounds. Earth words carry dental and nasal sounds.</p>
        <p class="sc-body-text">This is not coincidence. This is phonetic science — the natural origin of word science, Naisargik Mul Shabd Vidnyan.</p>
        <div class="sc-highlight-box">
          <span class="sc-highlight-label">Key Insight</span>
          <p class="sc-highlight-text">The word 'WORD' itself encodes the complete creation cycle: <strong>W</strong> (water / creation) · <strong>O</strong> (openness / awareness) · <strong>R</strong> (rhythm / flow) · <strong>D</strong> (direction / intention). The word "word" contains its own instruction.</p>
        </div>
        <div class="sc-divider"></div>
        <p class="sc-body-text">Understanding the natural origin of sound is the foundation of Shabdapathy. Once you hear a word not as a label but as a vibrational event — your relationship to language, to your body, and to healing is permanently transformed.</p>
      </div>`
  },
  {
    title: 'II. Body as Instrument',
    body: `
      <div class="sc-section">
        <span class="sc-section-label">Chapter II</span>
        <div class="sc-section-title">Body as Instrument</div>
        <p class="sc-body-text">The human body is not merely a receiver of sound — it is a precision instrument that produces, amplifies, and transmits vibrational frequencies. Every organ, gland, and tissue has a natural resonant frequency. When the correct sound is produced, that organ is activated.</p>
        <p class="sc-body-text">The verbal pronunciation of Shabdapathy words touches: the skull, three brains, tongue, teeth, palate, salivary glands, ears, nose, eyes, cheeks, throat, heart, lungs, small intestine, large intestine, kidneys, navel, and reproductive organs — all internal organ nerves, veins, and ultra-fine subtle tissues.</p>
        <div class="sc-quote">"Uchcharaa Dvaarech Upchaar — healing through pronunciation alone. Specific root-word vibrations activate specific organs, glands, and neural pathways without any external medicine."</div>
        <div class="sc-divider"></div>
        <span class="sc-section-label">Organ Resonance Map</span>
        <div class="sc-key-grid">
          <div class="sc-key-cell"><div class="sc-key-letter">N</div><div class="sc-key-word">Nasal / Breath</div><div class="sc-key-desc">Activates nasal passages, pineal gland, upper nervous system</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">O</div><div class="sc-key-word">Open / Heart</div><div class="sc-key-desc">Expands chest cavity, cardiac coherence, vagal activation</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">W</div><div class="sc-key-word">Water / Lips</div><div class="sc-key-desc">Cellular hydration pathways, lymphatic activation</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">S</div><div class="sc-key-word">Sibilant / Wind</div><div class="sc-key-desc">Respiratory system, nervous system regulation</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">B</div><div class="sc-key-word">Birth / Pressure</div><div class="sc-key-desc">Cardiovascular system, birth-breath resonance</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">M</div><div class="sc-key-word">Internal Hum</div><div class="sc-key-desc">Default mode network, consciousness centre of the brain</div></div>
        </div>
        <div class="sc-divider"></div>
        <div class="sc-highlight-box">
          <span class="sc-highlight-label">Hormonal Activation</span>
          <p class="sc-highlight-text">Hormones regulate digestion, metabolism, breathing, sleep, growth, reproduction, and emotion. Shabdapathy word practice directly corrects hormonal imbalances through targeted gland activation. When hormones fall out of balance — from lack of correct word exercise — symptoms include muscle pain, sleep irregularities, weight changes, irregular menstruation, dry nails and skin, and sensory organ problems.</p>
        </div>
        <p class="sc-body-text">The body is not a machine to be repaired — it is an instrument to be played. Shabdapathy teaches you the notes.</p>
      </div>`
  },
  {
    title: 'III. The NOWSBANSIU Key',
    body: `
      <div class="sc-section">
        <span class="sc-section-label">Chapter III</span>
        <div class="sc-section-title">The NOWSBANSIU Key</div>
        <p class="sc-body-text">NOWSBANSIU is not an acronym invented by a committee. It is a discovered framework — nine letters that represent the nine primary natural sound origins that account for the root vibration of every word across every human language and every era.</p>
        <p class="sc-body-text">Each letter in NOWSBANSIU maps to a natural origin principle connecting sound, body, and universe. Together they form the complete framework of Natural Origin Word Science — the key to decoding every word.</p>
        <div class="sc-divider"></div>
        <span class="sc-section-label">The Nine Letters</span>
        <div class="sc-key-grid">
          <div class="sc-key-cell"><div class="sc-key-letter">N</div><div class="sc-key-word">Natural</div><div class="sc-key-desc">The breath of birth — nasal origin of consciousness</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">O</div><div class="sc-key-word">Origin</div><div class="sc-key-desc">The open mouth — primordial vowel of existence</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">W</div><div class="sc-key-word">Word</div><div class="sc-key-desc">Water — creation sound, the lip-release of flow</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">S</div><div class="sc-key-word">Science</div><div class="sc-key-desc">Sibilant wind — respiratory, spatial resonance</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">B</div><div class="sc-key-word">Being</div><div class="sc-key-desc">Birth-breath pressure — cardiovascular root</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">A</div><div class="sc-key-word">Awareness</div><div class="sc-key-desc">Open throat — the universal sound of awakening</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">N</div><div class="sc-key-word">Nourish</div><div class="sc-key-desc">Nasal resonance — internal nourishment frequency</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">S</div><div class="sc-key-word">Soma</div><div class="sc-key-desc">Body-sound — somatic activation pathways</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">I</div><div class="sc-key-word">Inner</div><div class="sc-key-desc">High-frequency inward sound — pineal activation</div></div>
          <div class="sc-key-cell"><div class="sc-key-letter">U</div><div class="sc-key-word">Universe</div><div class="sc-key-desc">The deep hum — universal resonance, root grounding</div></div>
        </div>
        <div class="sc-divider"></div>
        <div class="sc-quote">"Each letter in NOWSBANSIU maps to a natural origin principle connecting sound, body, and universe. Together they form the complete framework — the key to decoding every word across every language and era."</div>
        <p class="sc-body-text">When you learn to hear any word through the NOWSBANSIU framework, you can immediately perceive its natural origin, its organ resonance, and its healing application — regardless of which language it belongs to.</p>
      </div>`
  },
  {
    title: 'IV. Practice & Application',
    body: `
      <div class="sc-section">
        <span class="sc-section-label">Chapter IV</span>
        <div class="sc-section-title">Practice &amp; Application</div>
        <p class="sc-body-text">Knowing the theory of Shabdapathy is the beginning. Practising it is the transformation. Daily word practice — performed with awareness of the body's resonance — is the mechanism by which healing occurs.</p>
        <div class="sc-highlight-box">
          <span class="sc-highlight-label">Morning Practice</span>
          <p class="sc-highlight-text">The moment of waking — emerging from what Shabdapathy calls "Mother Earth's lap" — is the most potent window for word practice. The nervous system is in a highly receptive state. Pronouncing root words in this state activates the day's cellular programming.</p>
        </div>
        <div class="sc-divider"></div>
        <span class="sc-section-label">The Three Stages of Life</span>
        <p class="sc-body-text"><strong style="color:rgba(200,232,245,0.8);">Stage I — Foundation (Birth to 33):</strong> The establishment of correct sound patterns in the body. Every word spoken in childhood either builds or disrupts the body's natural resonance. Conscious word practice in this stage prevents most modern diseases.</p>
        <p class="sc-body-text"><strong style="color:rgba(200,232,245,0.8);">Stage II — Activation (33 to 66):</strong> The deepening of practice. The body's instrument is now mature; correct word practice in this stage produces profound healing of existing conditions and expansion of consciousness.</p>
        <p class="sc-body-text"><strong style="color:rgba(200,232,245,0.8);">Stage III — Harvest (66 to Century):</strong> The natural result of correct word practice throughout life. Century living — reaching 100 in full vitality — is not exceptional when all three stages are navigated with Shabdapathy awareness.</p>
        <div class="sc-divider"></div>
        <div class="sc-quote">"Naturopathy, Ayurveda, Unani, Acupuncture, Homeopathy, Allopathy — even surgery — have never fully achieved the desired proportion of longevity. All these systems are made more effective when combined with Shabdakoshvinashabd Shabdapathy."</div>
        <p class="sc-body-text">Shabdapathy is complementary — not competitive — filling the gap left by every existing healing practice. It is the missing dimension in all medicine: the vibrational activation of the body's own intelligence through the science of natural word origin.</p>
      </div>`
  },
  {
    title: 'V. Scientific Evidence',
    body: `
      <div class="sc-section">
        <span class="sc-section-label">Chapter V</span>
        <div class="sc-section-title">Scientific Evidence</div>
        <p class="sc-body-text">Shabdapathy is not mysticism. It is a science that predates the modern scientific method — but one that is now being confirmed, piece by piece, by neuroscience, cymatics, linguistics, and bioacoustics research.</p>
        <div class="sc-highlight-box">
          <span class="sc-highlight-label">Cymatics</span>
          <p class="sc-highlight-text">Cymatics — the study of visible sound — demonstrates that specific frequencies create specific geometric patterns in matter. Dr. Hans Jenny's research showed that sound physically organises matter. Shabdapathy applies this principle to the most complex matter system known: the human body.</p>
        </div>
        <div class="sc-divider"></div>
        <div class="sc-highlight-box">
          <span class="sc-highlight-label">Neuroscience</span>
          <p class="sc-highlight-text">Modern neuroscience confirms that vocalisation activates the vagus nerve, regulates the autonomic nervous system, and triggers the release of healing neurotransmitters. Specific phonetic patterns activate specific neural pathways — exactly as Shabdapathy has mapped for thousands of years.</p>
        </div>
        <div class="sc-divider"></div>
        <div class="sc-highlight-box">
          <span class="sc-highlight-label">Linguistics</span>
          <p class="sc-highlight-text">Proto-Indo-European reconstruction, comparative linguistics, and phonosemantic research all confirm cross-language sound-meaning correspondences. Words for water, fire, mother, and earth share root phonemes across unconnected civilizations — exactly the pattern the NOWSBANSIU framework predicted.</p>
        </div>
        <div class="sc-divider"></div>
        <div class="sc-quote">"The true scientific original meaning of every word — through Naisargik Mul Shabd Vidnyan's Shabdapathy — reveals that language is not arbitrary. It is a precise record of the body's encounter with the natural world."</div>
        <p class="sc-body-text">Even Pranayama and Yoga, while beneficial, do not activate the full range of subtle organs that word vibration reaches. The scientific evidence points toward one conclusion: the body listens to every word you speak — and responds accordingly.</p>
        <p class="sc-body-text">Shabdapathy gives you the knowledge to speak deliberately, heal intentionally, and live fully.</p>
      </div>`
  }
];

window.scOpenChapter = function(idx) {
  var ch = _scChapters[idx];
  if (!ch) return;
  var overlay = document.getElementById('scReaderOverlay');
  var titleEl = document.getElementById('scReaderTitle');
  var bodyEl  = document.getElementById('scReaderBody');
  if (!overlay || !titleEl || !bodyEl) return;
  titleEl.textContent = ch.title;
  bodyEl.innerHTML    = ch.body;
  overlay.style.display = 'block';
  overlay.scrollTop = 0;
  document.body.style.overflow = 'hidden';
};

window.scCloseChapter = function() {
  var overlay = document.getElementById('scReaderOverlay');
  if (overlay) overlay.style.display = 'none';
  document.body.style.overflow = '';
};

