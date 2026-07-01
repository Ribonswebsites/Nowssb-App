
// ══════════════════════════════════════════════════
// MY PROGRESS — Part 1: Real data, real streak,
// real sessions, feedback capture
// ══════════════════════════════════════════════════

// State
window._mpData = null;

// Called when openSub('my-progress') fires
// Hook into openSub by patching it after definition
(function patchOpenSubForProgress() {
  const _origOpen = window.openSub;
  if (!_origOpen) { setTimeout(patchOpenSubForProgress, 200); return; }
  window.openSub = function(id) {
    _origOpen(id);
    if (id === 'my-progress') {
      // Always show intro first — reset state
      const introPage   = document.getElementById('mpIntroPage');
      const mainContent = document.getElementById('mpMainContent');
      if (introPage)   { introPage.classList.remove('sl-intro-hidden'); introPage.style.display = ''; }
      if (mainContent) mainContent.style.display = 'none';
      // Load data in background to populate intro stats
      mpLoadForIntro();
    }
  };
})();

// ── LOAD FOR INTRO — fetch data, populate stat preview ──
async function mpLoadForIntro() {
  let userData = null;
  if (window._currentUid) {
    try {
      const { getFirestore, doc, getDoc } = await import("https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js");
      const { getApp } = await import("https://www.gstatic.com/firebasejs/11.8.1/firebase-app.js");
      const db2 = getFirestore(getApp());
      const snap = await getDoc(doc(db2, 'users', window._currentUid));
      if (snap.exists()) userData = snap.data();
    } catch(e) { console.warn('mpLoadForIntro:', e.message); }
  }
  window._mpData = userData;

  // Populate intro stats
  const sessions    = (userData && userData.sessions) ? userData.sessions : {};
  const sessionKeys = Object.keys(sessions);
  const practicedDays = new Set();
  sessionKeys.forEach(k => {
    const d = k.split('_')[0];
    if (d && /^\d{4}-\d{2}-\d{2}$/.test(d)) practicedDays.add(d);
  });
  const today = new Date();
  function ds(d) { return d.toISOString().split('T')[0]; }
  let streak = 0;
  let checkDate = new Date(today);
  if (!practicedDays.has(ds(today))) checkDate.setDate(checkDate.getDate() - 1);
  while (practicedDays.has(ds(checkDate))) {
    streak++;
    checkDate.setDate(checkDate.getDate() - 1);
    if (streak > 365) break;
  }
  const uniqueWords = new Set(sessionKeys.map(k => k.split('_').slice(1).join('_')));

  const elStreak   = document.getElementById('mpIntroStreak');
  const elSessions = document.getElementById('mpIntroSessions');
  const elWords    = document.getElementById('mpIntroWords');
  if (elStreak)   elStreak.textContent   = streak;
  if (elSessions) elSessions.textContent = sessionKeys.length;
  if (elWords)    elWords.textContent    = uniqueWords.size;
}

// ── ENTER — dismiss intro, show main content ──
function mpEnterFromIntro() {
  const introPage   = document.getElementById('mpIntroPage');
  const mainContent = document.getElementById('mpMainContent');
  if (introPage) {
    introPage.style.transition = 'opacity 0.38s ease';
    introPage.style.opacity = '0';
    introPage.style.pointerEvents = 'none';
    setTimeout(() => { introPage.style.display = 'none'; introPage.style.opacity = ''; }, 380);
  }
  if (mainContent) mainContent.style.display = 'flex';
  // Now render the full progress content
  if (window._mpData !== null) {
    mpRender(window._mpData);
  } else {
    mpLoad();
  }
  mpInitHero3D();
}
window.mpEnterFromIntro = mpEnterFromIntro;

// ── 3D SCROLL HERO — the banner tilts back, sinks and fades as you scroll ──
function mpInitHero3D() {
  var body = document.getElementById('mpBody');
  var hdr  = document.querySelector('#sub-my-progress #mpMainContent > .sub-header');
  if (!body || !hdr) return;
  if (body._hero3d) return;      // wire once
  body._hero3d = true;
  var H = 300;
  body.addEventListener('scroll', function() {
    var sy = body.scrollTop;
    var p  = Math.min(sy / H, 1);
    var ty = -sy * 0.5;           // parallax — rises slower than the content
    var tz = -p * 170;            // sinks into the screen
    var rx = p * 16;              // tilts back
    var sc = 1 - p * 0.05;
    hdr.style.transform = 'translateY(' + ty + 'px) translateZ(' + tz + 'px) rotateX(' + rx + 'deg) scale(' + sc + ')';
    hdr.style.opacity   = String(Math.max(1 - p * 1.05, 0));
  }, { passive: true });
}
window.mpInitHero3D = mpInitHero3D;

// ── LOAD (full) ──
async function mpLoad() {
  const body = document.getElementById('mpBody');
  if (!body) return;

  body.innerHTML = '<div class="mp-loading"><div class="mp-loading-ring"></div><div class="mp-loading-text">Loading your journey…</div></div>';

  let userData = window._mpData;
  if (!userData && window._currentUid) {
    try {
      const { getFirestore, doc, getDoc } = await import("https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js");
      const { getApp } = await import("https://www.gstatic.com/firebasejs/11.8.1/firebase-app.js");
      const db2 = getFirestore(getApp());
      const snap = await getDoc(doc(db2, 'users', window._currentUid));
      if (snap.exists()) userData = snap.data();
      window._mpData = userData;
    } catch(e) { console.warn('mpLoad:', e.message); }
  }

  mpRender(userData);
}

// ── RENDER ──
function mpRender(data) {
  const body = document.getElementById('mpBody');
  if (!body) return;

  const sessions = (data && data.sessions) ? data.sessions : {};
  const sessionKeys = Object.keys(sessions); // "YYYY-MM-DD_WORD"

  // --- Build date set of practiced days ---
  const practicedDays = new Set();
  sessionKeys.forEach(k => {
    const d = k.split('_')[0]; // first part is date
    if (d && /^\d{4}-\d{2}-\d{2}$/.test(d)) practicedDays.add(d);
  });

  // --- Streak calculation ---
  const today = new Date();
  function dateStr(d) {
    return d.toISOString().split('T')[0];
  }
  let streak = 0;
  let checkDate = new Date(today);
  // If not practiced today yet, start from yesterday for streak count
  if (!practicedDays.has(dateStr(today))) {
    checkDate.setDate(checkDate.getDate() - 1);
  }
  while (practicedDays.has(dateStr(checkDate))) {
    streak++;
    checkDate.setDate(checkDate.getDate() - 1);
    if (streak > 365) break; // safety
  }

  // --- Total sessions count ---
  const totalSessions = sessionKeys.length;

  // --- Total unique words practiced ---
  const uniqueWords = new Set(sessionKeys.map(k => k.split('_').slice(1).join('_')));
  const totalWords = uniqueWords.size;

  // --- Last practiced ---
  let lastPracticed = null;
  if (practicedDays.size > 0) {
    const sorted = Array.from(practicedDays).sort().reverse();
    lastPracticed = sorted[0];
  }

  // --- This week grid ---
  const dayNames = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
  const dayLetters = ['S','M','T','W','T','F','S'];
  const todayDow = today.getDay(); // 0=Sun
  // Build week: Mon → Sun of current week
  // Find Monday of this week
  const monday = new Date(today);
  const daysFromMon = (todayDow + 6) % 7;
  monday.setDate(today.getDate() - daysFromMon);

  let weekGridHtml = '';
  for (let i = 0; i < 7; i++) {
    const d = new Date(monday);
    d.setDate(monday.getDate() + i);
    const ds = dateStr(d);
    const isToday = ds === dateStr(today);
    const isFuture = d > today;
    const isDone = practicedDays.has(ds);
    const shortDay = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i];
    const letter = ['M','T','W','T','F','S','S'][i];
    let cls = 'mp-week-dot';
    if (isDone && isToday) cls += ' done today';
    else if (isDone) cls += ' done';
    else if (isToday) cls += ' today';
    const opacity = isFuture && !isDone ? 'opacity:0.4;' : '';
    weekGridHtml += `<div class="mp-week-cell">
      <div class="${cls}" style="${opacity}">${letter}</div>
      <div class="mp-week-name">${shortDay}</div>
    </div>`;
  }

  // --- Recent sessions (last 8) ---
  const recentSessions = sessionKeys
    .map(k => ({ key:k, ...sessions[k] }))
    .filter(s => s.date)
    .sort((a,b) => (b.completedAt || b.date) > (a.completedAt || a.date) ? 1 : -1)
    .slice(0, 8);

  let sessionsHtml = '';
  if (recentSessions.length === 0) {
    sessionsHtml = `<div class="mp-empty-state">
      <svg class="mp-empty-icon" width="40" height="40" viewBox="0 0 40 40" fill="none">
        <circle cx="20" cy="20" r="15" stroke="rgba(200,232,245,0.25)" stroke-width="1"/>
        <path d="M14 20 L18 24 L26 16" stroke="rgba(200,232,245,0.4)" stroke-width="1.4" stroke-linecap="square"/>
      </svg>
      <div class="mp-empty-title">No sessions recorded yet</div>
      <div class="mp-empty-text">Complete your first word practice session and your real progress will appear here — every rep, every word, every day.</div>
    </div>`;
  } else {
    sessionsHtml = '<div class="mp-session-list">';
    recentSessions.forEach(s => {
      const word = s.word || '—';
      const letter = word.charAt(0);
      const reps = s.repsCompleted || 0;
      const target = s.repTarget || 7;
      const dateLabel = mpFormatDate(s.completedAt || s.date);
      const organ = mpGetOrgan(word);
      sessionsHtml += `<div class="mp-session-row">
        <div class="mp-session-disc">${letter}</div>
        <div class="mp-session-info">
          <div class="mp-session-word">${word}</div>
          <div class="mp-session-detail">${organ ? organ + ' · ' : ''}${dateLabel}</div>
        </div>
        <div class="mp-session-right">
          <div class="mp-session-reps">${reps}</div>
          <div class="mp-session-reps-label">of ${target} reps</div>
        </div>
      </div>`;
    });
    sessionsHtml += '</div>';
  }

  // --- Greeting message ---
  const name = (data && data.displayName) ? data.displayName.split(' ')[0] : null;
  const hour = today.getHours();
  const timeGreet = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
  let greetMsg = '';
  let greetSub = '';
  if (streak === 0 && totalSessions === 0) {
    greetMsg = 'Your journey starts today.';
    greetSub = 'Every master word practitioner began with zero sessions. Practice one word — your data begins building now.';
  } else if (streak === 0) {
    greetMsg = `${totalSessions} session${totalSessions !== 1 ? 's' : ''} in your history.`;
    greetSub = `You've practiced ${totalWords} unique word${totalWords !== 1 ? 's' : ''}. Practice today to restart your streak.`;
  } else if (streak >= 21) {
    greetMsg = `${streak}-day streak. Deep resonance.`;
    greetSub = `${totalWords} words activated. ${totalSessions} sessions complete. You are building something real.`;
  } else if (streak >= 7) {
    greetMsg = `${streak} days in a row. Momentum building.`;
    greetSub = `${totalWords} unique word${totalWords !== 1 ? 's' : ''} practiced. ${totalSessions} sessions logged.`;
  } else {
    greetMsg = `${streak > 0 ? streak + '-day' : 'Starting your'} streak.`;
    greetSub = `${totalSessions} session${totalSessions !== 1 ? 's' : ''} completed · ${totalWords} word${totalWords !== 1 ? 's' : ''} practiced.`;
  }

  // --- Last practiced line ---
  let lastPracticedHtml = '';
  if (lastPracticed) {
    const lp = mpFormatDate(lastPracticed + 'T12:00:00');
    lastPracticedHtml = `<div class="mp-last-practiced"><div class="mp-lp-dot"></div>Last practiced ${lp}</div>`;
  }

  // --- Feedback check: did we already save? ---
  const savedFeedback = data && data.progressFeedback;

  // --- Build full HTML ---
  body.innerHTML = `
    <!-- Greeting -->
    <div class="mp-greeting">
      ${name ? `<div class="mp-greeting-name">${timeGreet}, ${name}</div>` : `<div class="mp-greeting-name">${timeGreet}</div>`}
      <div class="mp-greeting-msg">${greetMsg}</div>
      <div class="mp-greeting-sub">${greetSub}</div>
    </div>

    <!-- Stats row -->
    <span class="sub-section-label">Your Numbers</span>
    <div class="mp-stats-row">
      <div class="mp-stat-box">
        <div class="mp-stat-num">${streak}</div>
        <div class="mp-stat-label">Day Streak</div>
        <div class="mp-stat-sub">${streak === 0 ? 'Start today' : streak === 1 ? 'Started' : 'consecutive'}</div>
      </div>
      <div class="mp-stat-box">
        <div class="mp-stat-num">${totalSessions}</div>
        <div class="mp-stat-label">Sessions</div>
        <div class="mp-stat-sub">${totalSessions === 0 ? 'None yet' : 'total logged'}</div>
      </div>
      <div class="mp-stat-box">
        <div class="mp-stat-num">${totalWords}</div>
        <div class="mp-stat-label">Words</div>
        <div class="mp-stat-sub">${totalWords === 0 ? 'None yet' : 'practiced'}</div>
      </div>
    </div>

    <!-- Week grid -->
    <span class="sub-section-label">This Week</span>
    <div class="mp-week-grid">${weekGridHtml}</div>
    ${lastPracticedHtml}

    <!-- Recent sessions -->
    <span class="sub-section-label">Recent Sessions</span>
    ${sessionsHtml}

    <!-- Feedback section -->
    <span class="sub-section-label">Your Feedback</span>
    <div class="mp-feedback-wrap" id="mpFeedbackWrap">
      ${savedFeedback ? mpRenderSavedFeedback(savedFeedback) : mpRenderFeedbackForm()}
    </div>

    <!-- Part 3: Milestones -->
    <span class="sub-section-label">Milestones</span>
    <div class="mp-milestones-grid" id="mpMilestonesGrid">
      ${mpRenderMilestones(streak, totalSessions, totalWords)}
    </div>

    <!-- Part: Healing Body Map -->
    <span class="sub-section-label">Healing Body Map</span>
    <div id="hbm-full" style="margin-bottom:8px;">
      ${window.HBM ? window.HBM.renderHTML(data) : ''}
    </div>

    <!-- Part 3: AI Weekly Insight -->
    <span class="sub-section-label">Weekly Insight</span>
    <div class="mp-insight-wrap" id="mpInsightWrap">
      <div class="mp-insight-eyebrow">
        <div class="mp-insight-dot"></div>
        Shabdapathy · AI Analysis
      </div>
      <div class="mp-insight-text" id="mpInsightText">
        <div class="mp-insight-loading">
          <div class="mp-insight-shimmer"></div>
          <div class="mp-insight-shimmer"></div>
          <div class="mp-insight-shimmer"></div>
        </div>
      </div>
    </div>
  `;

  // Trigger AI insight load after DOM is set
  setTimeout(() => mpLoadInsight(data, streak, totalSessions, totalWords), 0);
  // Refresh body map after render
  setTimeout(function(){ if(window.HBM) window.HBM.refresh(data); }, 50);
}

function mpRenderSavedFeedback(fb) {
  const working = (fb.working || []).join(', ') || '—';
  const notWorking = (fb.notWorking || []).join(', ') || '—';
  const wants = (fb.wants || []).join(', ') || '—';
  const note = fb.note || '';
  const saved = mpFormatDate(fb.savedAt);
  return `<div class="mp-feedback-saved" style="display:block;">
    <svg class="mp-feedback-saved-icon" width="28" height="28" viewBox="0 0 28 28" fill="none">
      <circle cx="14" cy="14" r="12" stroke="rgba(200,232,245,0.3)" stroke-width="1"/>
      <path d="M9 14 L12.5 17.5 L19 11" stroke="var(--accent)" stroke-width="1.4" stroke-linecap="square"/>
    </svg>
    <div class="mp-feedback-saved-title">Feedback received</div>
    <div class="mp-feedback-saved-sub">Working for you: ${working}<br>Not working: ${notWorking}${note ? '<br>Your note: "' + note + '"' : ''}</div>
    <div style="margin-top:12px;">
      <button class="mp-chip" style="border-color:rgba(255,255,255,0.18);color:rgba(255,255,255,0.45);font-size:10px;padding:6px 12px;" onclick="mpResetFeedback()">Update feedback</button>
    </div>
  </div>`;
}

function mpRenderFeedbackForm() {
  return `
    <div class="mp-feedback-question">What's working for you?</div>
    <div class="mp-feedback-chips" id="mpChipsWorking">
      ${['Morning routine','Evening session','Repeat mode','Listening mode','Word meaning','Phonetic guide'].map(t => `<div class="mp-chip" onclick="mpToggleChip(this,'working','${t}')">${t}</div>`).join('')}
    </div>

    <div class="mp-feedback-question">What's not working or feels off?</div>
    <div class="mp-feedback-chips" id="mpChipsNotWorking">
      ${['Too many words','Audio missing','Pronunciation unclear','App too slow','Reps feel long','No guidance'].map(t => `<div class="mp-chip" onclick="mpToggleChip(this,'not-working','${t}')">${t}</div>`).join('')}
    </div>

    <div class="mp-feedback-question">What do you want more of?</div>
    <div class="mp-feedback-chips" id="mpChipsWants">
      ${['More words','Body map','Sound Bath mode','AI feedback','Progress charts','Sentence builder','Weekly report','More voices'].map(t => `<div class="mp-chip" onclick="mpToggleChip(this,'wants','${t}')">${t}</div>`).join('')}
    </div>

    <div class="mp-feedback-question" style="margin-top:4px;">Anything else you want to tell us?</div>
    <textarea class="mp-feedback-textarea" id="mpFeedbackNote" rows="3" placeholder="Your thoughts, requests, or what healing means to you…"></textarea>

    <button class="mp-submit-btn" id="mpSubmitBtn" onclick="mpSubmitFeedback()">Save My Feedback</button>
  `;
}

// ── CHIP TOGGLE ──
window._mpWorking    = new Set();
window._mpNotWorking = new Set();
window._mpWants      = new Set();

function mpToggleChip(el, type, val) {
  const map = { 'working': window._mpWorking, 'not-working': window._mpNotWorking, 'wants': window._mpWants };
  const colorMap = { 'working': 'selected', 'not-working': 'selected-red', 'wants': 'selected-gold' };
  const set = map[type];
  const cls = colorMap[type];
  if (set.has(val)) { set.delete(val); el.classList.remove('selected','selected-red','selected-gold'); }
  else { set.add(val); el.classList.add(cls); }
}

// ── SUBMIT ──
async function mpSubmitFeedback() {
  const note = (document.getElementById('mpFeedbackNote') || {}).value || '';
  const btn = document.getElementById('mpSubmitBtn');
  if (btn) { btn.disabled = true; btn.textContent = 'Saving…'; }

  const feedbackPayload = {
    working:    Array.from(window._mpWorking),
    notWorking: Array.from(window._mpNotWorking),
    wants:      Array.from(window._mpWants),
    note:       note.trim(),
    savedAt:    new Date().toISOString()
  };

  try {
    if (window._fbSetDoc && window._currentUid) {
      await window._fbSetDoc(window._currentUid, { progressFeedback: feedbackPayload });
    }
    // Update local cache
    if (window._mpData) window._mpData.progressFeedback = feedbackPayload;
    // Re-render feedback section only
    const wrap = document.getElementById('mpFeedbackWrap');
    if (wrap) wrap.innerHTML = mpRenderSavedFeedback(feedbackPayload);
    // Reset sets
    window._mpWorking    = new Set();
    window._mpNotWorking = new Set();
    window._mpWants      = new Set();
  } catch(e) {
    console.warn('Feedback save:', e.message);
    if (btn) { btn.disabled = false; btn.textContent = 'Save My Feedback'; }
  }
}

function mpResetFeedback() {
  window._mpWorking    = new Set();
  window._mpNotWorking = new Set();
  window._mpWants      = new Set();
  const wrap = document.getElementById('mpFeedbackWrap');
  if (wrap) wrap.innerHTML = mpRenderFeedbackForm();
}

// ── HELPERS ──
function mpFormatDate(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  const now = new Date();
  const diff = now - d;
  if (diff < 60000) return 'Just now';
  if (diff < 3600000) return Math.floor(diff/60000) + 'm ago';
  if (diff < 86400000) return Math.floor(diff/3600000) + 'h ago';
  if (diff < 172800000) return 'Yesterday';
  if (diff < 604800000) return Math.floor(diff/86400000) + ' days ago';
  return d.toLocaleDateString('en', { month:'short', day:'numeric' });
}

// ── PART 3: MILESTONES ──
function mpRenderMilestones(streak, sessions, words) {
  const milestones = [
    {
      icon: '◎',
      name: 'First Session',
      cond: 'Complete 1 session',
      unlocked: sessions >= 1
    },
    {
      icon: '◈',
      name: '3-Day Streak',
      cond: 'Practice 3 days in a row',
      unlocked: streak >= 3
    },
    {
      icon: '◉',
      name: 'Weekly Rhythm',
      cond: '7 consecutive days',
      unlocked: streak >= 7
    },
    {
      icon: '◆',
      name: '21-Day Resonance',
      cond: '21 days unbroken',
      unlocked: streak >= 21
    },
    {
      icon: '◇',
      name: '5 Words Activated',
      cond: 'Practice 5 unique words',
      unlocked: words >= 5
    },
    {
      icon: '⬡',
      name: '10 Words Activated',
      cond: 'Practice 10 unique words',
      unlocked: words >= 10
    },
    {
      icon: '▲',
      name: 'Deep Practitioner',
      cond: '21 sessions completed',
      unlocked: sessions >= 21
    },
    {
      icon: '★',
      name: 'Century Mark',
      cond: '100 sessions logged',
      unlocked: sessions >= 100
    }
  ];
  return milestones.map(m => `
    <div class="mp-milestone ${m.unlocked ? 'unlocked' : ''}">
      <div class="mp-milestone-icon">${m.icon}</div>
      <div class="mp-milestone-name">${m.name}</div>
      <div class="mp-milestone-cond">${m.cond}</div>
      <svg class="mp-milestone-lock" width="12" height="14" viewBox="0 0 12 14" fill="none">
        <rect x="2" y="6" width="8" height="7" rx="1" stroke="rgba(255,255,255,0.5)" stroke-width="1.1" fill="none"/>
        <path d="M4 6V4.5a2 2 0 014 0V6" stroke="rgba(255,255,255,0.5)" stroke-width="1.1" fill="none"/>
      </svg>
    </div>
  `).join('');
}

// ── PART 3: AI WEEKLY INSIGHT ──
async function mpLoadInsight(data, streak, sessions, words) {
  const el = document.getElementById('mpInsightText');
  if (!el) return;

  // No activity — skip AI call, show human copy
  if (sessions === 0) {
    el.textContent = 'Complete your first practice session and a personal insight will appear here — built from your actual data, not a template.';
    return;
  }

  const name = (data && data.displayName) ? data.displayName.split(' ')[0] : 'Practitioner';
  const prompt = `You are a Shabdapathy practice guide. The user's name is ${name}.
Their practice data: ${streak} day streak, ${sessions} total sessions, ${words} unique words practiced.
Write 2-3 sentences of personal insight about their healing journey.
Be specific to their data. Reference their streak and word count.
Do NOT use phrases like "great job" or "keep it up".
Do NOT mention Sanskrit, sacred texts, or spirituality.
Speak about natural phonetic resonance, frequency, and the body's response to consistent practice.
Be poetic but grounded. 80 words max.`;

  try {
    const res = await fetch(GROQ_CHAT_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        max_tokens: 150,
        messages: [{ role: 'user', content: prompt }]
      })
    });
    const json = await res.json();
    const text = json.choices && json.choices[0] && json.choices[0].message && json.choices[0].message.content;
    if (text && el) el.textContent = text.trim();
  } catch(e) {
    if (el) el.textContent = `${name}, ${sessions} session${sessions !== 1 ? 's' : ''} of practice has begun activating ${words} phonetic frequency${words !== 1 ? 'patterns' : ' pattern'} in your body. A ${streak > 0 ? streak + '-day' : ''} streak of consistent practice creates cumulative resonance — each session builds on the last.`;
  }
}

function mpGetOrgan(word) {
  // Look up in PRACTICE_WORDS / MASTER_WORD_LIBRARY
  try {
    const lib = typeof MASTER_WORD_LIBRARY !== 'undefined' ? MASTER_WORD_LIBRARY : [];
    const match = lib.find(w => w.word === word);
    return match ? (match.organ || '') : '';
  } catch(e) { return ''; }
}
