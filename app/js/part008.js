
// ══════════════════════════════════════════════════════════════════
// PROFILE — Part 1: Live Firestore data, editable name, preferences
// ══════════════════════════════════════════════════════════════════

// ── In-memory prefs state (mirrors Firestore) ──
window._profilePrefs = {
  soundFeedback:  true,
  practiceMins:   18,
  reminderTime:   '06:00',
  voice:          'female'
};

// ── Firestore helpers (lazy-import, same pattern as rest of app) ──
async function _profileDb() {
  const { getFirestore, doc, getDoc, setDoc } =
    await import("https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js");
  return { db: getFirestore(), doc, getDoc, setDoc };
}

// ── Patch openSub to show intro first, then load data ──
(function patchOpenSubForProfile() {
  const _origOpen = window.openSub;
  if (!_origOpen) { setTimeout(patchOpenSubForProfile, 200); return; }
  window.openSub = function(id) {
    _origOpen(id);
    if (id === 'profile') {
      const introPage   = document.getElementById('profileIntroPage');
      const mainContent = document.getElementById('profileMainContent');
      if (typeof shouldShowIntro === 'function' && !shouldShowIntro('profile')) {
        if (introPage)   { introPage.classList.add('sl-intro-hidden'); }
        if (mainContent) mainContent.style.display = '';
        profileLoadAll();
        if (typeof nssUpdateProfileCounts === 'function') nssUpdateProfileCounts();
        setTimeout(function() { if (typeof window.profileEnterFromIntro === 'function') window.profileEnterFromIntro(); }, 100);
      } else {
        if (introPage)   { introPage.classList.remove('sl-intro-hidden'); introPage.style.display = ''; }
        if (mainContent) mainContent.style.display = 'none';
        profileLoadAll();
        if (typeof nssUpdateProfileCounts === 'function') nssUpdateProfileCounts();
      }
    }
  };
})();

// ── Load ALL user data from Firestore, populate every field ──
async function profileLoadAll() {
  try {
    let data = window._userDataCache;
    if (!data && window._currentUid) {
      const { db, doc, getDoc } = await _profileDb();
      const snap = await getDoc(doc(db, 'users', window._currentUid));
      data = snap.exists() ? snap.data() : null;
      window._userDataCache = data;
      if (window._spRefreshPromo) window._spRefreshPromo();
    }
    if (!data) return;

    // ── Sync prefs state ──
    const p = window._profilePrefs;
    if (data.prefs) {
      if (data.prefs.soundFeedback  !== undefined) p.soundFeedback  = data.prefs.soundFeedback;
      if (data.prefs.practiceMins   !== undefined) p.practiceMins   = data.prefs.practiceMins;
      if (data.prefs.reminderTime   !== undefined) p.reminderTime   = data.prefs.reminderTime;
      if (data.prefs.voice          !== undefined) p.voice          = data.prefs.voice;
    }

    // ── Intro stat row ──
    const firstName = data.displayName ? data.displayName.split(' ')[0] : 'Practitioner';
    const tier      = data.isPro ? 'Pro' : 'Free';
    const since     = data.createdAt
      ? new Date(data.createdAt.seconds * 1000).getFullYear()
      : new Date().getFullYear();
    const sinceFormatted = data.createdAt
      ? new Date(data.createdAt.seconds * 1000).toLocaleDateString('en', {month:'short', year:'numeric'})
      : 'Recently';

    _pfEl('profileIntroName',  firstName);
    _pfEl('profileIntroTier',  tier);
    _pfEl('profileIntroSince', since);

    // ── Main content ──
    const name = data.displayName || 'Practitioner';
    _pfEl('profileMainName',    name);
    _pfEl('profileMainEmail',   data.email || '');
    _pfEl('profileMemberSince', sinceFormatted);
    _pfEl('profilePlanText',    tier);

    // Avatar — show photo if exists, otherwise show initial
    profileUpdateAvatarDisplay(data.photoURL || null, name);

    // Plan badge
    const badge = document.getElementById('profilePlanBadge');
    if (badge) {
      badge.textContent = tier === 'Pro' ? 'Pro Member' : 'Free Plan';
      badge.style.borderColor = tier === 'Pro' ? 'rgba(232,213,163,0.55)' : 'rgba(255,255,255,0.18)';
      badge.style.color       = tier === 'Pro' ? 'var(--accent-gold)' : 'rgba(255,255,255,0.45)';
    }

    // Apply prefs UI
    profileApplyPrefsUI();

    // ── Live stats ──
    profileRenderStats(data);

  } catch(e) {
    console.warn('Profile load:', e);
  }
}

// ── Compute + render live stats from sessions map ──
function profileRenderStats(data) {
  try {
    const sessions    = (data && data.sessions) ? data.sessions : {};
    const sessionKeys = Object.keys(sessions); // "YYYY-MM-DD_WORD"

    // Build date set
    const practicedDays = new Set();
    sessionKeys.forEach(k => {
      const d = k.split('_')[0];
      if (d && /^\d{4}-\d{2}-\d{2}$/.test(d)) practicedDays.add(d);
    });

    // Streak
    const today = new Date();
    function dateStr(d) { return d.toISOString().split('T')[0]; }
    let streak = 0;
    let checkDate = new Date(today);
    if (!practicedDays.has(dateStr(today))) checkDate.setDate(checkDate.getDate() - 1);
    while (practicedDays.has(dateStr(checkDate))) {
      streak++;
      checkDate.setDate(checkDate.getDate() - 1);
      if (streak > 365) break;
    }

    // Total sessions & unique words
    const totalSessions = sessionKeys.length;
    const uniqueWords   = new Set(sessionKeys.map(k => k.split('_').slice(1).join('_')));
    const totalWords    = uniqueWords.size;

    // Unique organs reached
    let uniqueOrgans = new Set();
    try {
      const lib = typeof MASTER_WORD_LIBRARY !== 'undefined' ? MASTER_WORD_LIBRARY : [];
      uniqueWords.forEach(w => {
        const match = lib.find(x => x.word === w);
        if (match && match.organ) uniqueOrgans.add(match.organ.toLowerCase().trim());
      });
    } catch(e2) {}
    const totalOrgans = uniqueOrgans.size;

    // Last practiced
    let lastLabel = '';
    if (practicedDays.size > 0) {
      const latestDay = Array.from(practicedDays).sort().reverse()[0];
      const todayStr  = dateStr(today);
      const yest      = new Date(today); yest.setDate(today.getDate() - 1);
      if (latestDay === todayStr) {
        lastLabel = 'Practiced today';
      } else if (latestDay === dateStr(yest)) {
        lastLabel = 'Last practiced yesterday';
      } else {
        const d = new Date(latestDay);
        lastLabel = 'Last practiced ' + d.toLocaleDateString('en', {month:'short', day:'numeric'});
      }
    }

    // Update stat cells
    _pfEl('pstat-streak',   streak);
    _pfEl('pstat-sessions', totalSessions);
    _pfEl('pstat-words',    totalWords);
    _pfEl('pstat-organs',   totalOrgans || '—');
    _pfEl('pstat-last',     lastLabel);

    // Week grid
    const weekEl = document.getElementById('profileWeekGrid');
    if (weekEl) {
      const monday = new Date(today);
      const daysFromMon = (today.getDay() + 6) % 7;
      monday.setDate(today.getDate() - daysFromMon);
      const dayLetters = ['M','T','W','T','F','S','S'];
      let html = '';
      for (let i = 0; i < 7; i++) {
        const d = new Date(monday);
        d.setDate(monday.getDate() + i);
        const ds       = dateStr(d);
        const isToday  = ds === dateStr(today);
        const isFuture = d > today;
        const isDone   = practicedDays.has(ds);

        let dotBg, dotBorder, dotColor;
        if (isDone && isToday) {
          dotBg = 'var(--accent-gold)'; dotBorder = 'var(--accent-gold)'; dotColor = '#060c18';
        } else if (isDone) {
          dotBg = 'rgba(200,232,245,0.25)'; dotBorder = 'rgba(200,232,245,0.45)'; dotColor = 'var(--accent)';
        } else if (isToday) {
          dotBg = 'transparent'; dotBorder = 'rgba(200,232,245,0.55)'; dotColor = 'var(--accent)';
        } else {
          dotBg = 'transparent'; dotBorder = 'rgba(255,255,255,0.12)'; dotColor = 'rgba(255,255,255,0.22)';
        }
        const opacity = isFuture && !isDone ? '0.35' : '1';
        html += `<div style="display:flex;flex-direction:column;align-items:center;gap:5px;opacity:${opacity};">
          <div style="width:28px;height:28px;background:${dotBg};border:1px solid ${dotBorder};display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:500;color:${dotColor};letter-spacing:0;">${dayLetters[i]}</div>
        </div>`;
      }
      weekEl.innerHTML = html;
    }

    // Render body map in profile
    setTimeout(function(){
      if (window.HBM){
        var mini = document.getElementById('hbm-profile-mini');
        if (mini) mini.innerHTML = window.HBM.renderMini(data);
      }
    }, 60);

    // Update intro eyebrow with live rank
    if (window.RANK) {
      var rankTitle = window.RANK.compute(totalSessions, totalWords).rank.title;
      var eyebrow = document.getElementById('profileIntroEyebrow');
      if (eyebrow) eyebrow.textContent = 'Shabdapathy · ' + rankTitle;
    }

  } catch(e) {
    console.warn('Profile stats render:', e);
  }
}

// ── Apply current prefs state to all UI controls ──
function profileApplyPrefsUI() {
  const p = window._profilePrefs;

  // Sound toggle
  const toggle = document.getElementById('pref-sound-toggle');
  const knob   = document.getElementById('pref-sound-knob');
  const label  = document.getElementById('pref-sound-label');
  if (toggle && knob && label) {
    if (p.soundFeedback) {
      toggle.style.background = 'rgba(200,232,245,0.22)';
      toggle.style.borderColor = 'rgba(200,232,245,0.38)';
      knob.style.transform = 'translateX(24px)';
      knob.style.background = 'var(--accent)';
      label.textContent = 'On';
    } else {
      toggle.style.background = 'rgba(255,255,255,0.07)';
      toggle.style.borderColor = 'rgba(255,255,255,0.18)';
      knob.style.transform = 'translateX(0)';
      knob.style.background = 'rgba(255,255,255,0.4)';
      label.textContent = 'Off';
    }
  }

  // Duration
  const durEl = document.getElementById('pref-duration-val');
  if (durEl) durEl.textContent = p.practiceMins + ' min';

  // Reminder
  const remEl = document.getElementById('pref-reminder-input');
  if (remEl) remEl.value = p.reminderTime || '06:00';

  // Voice
  const btnF = document.getElementById('voice-btn-female');
  const btnM = document.getElementById('voice-btn-male');
  if (btnF && btnM) {
    const activeStyle = {background:'rgba(200,232,245,0.15)', border:'1px solid rgba(200,232,245,0.38)', color:'var(--accent)'};
    const inactiveStyle = {background:'rgba(255,255,255,0.06)', border:'1px solid rgba(255,255,255,0.18)', color:'rgba(255,255,255,0.45)'};
    const applyStyle = (el, s) => { el.style.background = s.background; el.style.border = s.border; el.style.color = s.color; };
    applyStyle(btnF, p.voice === 'female' ? activeStyle : inactiveStyle);
    applyStyle(btnM, p.voice === 'male'   ? activeStyle : inactiveStyle);
  }
}

// ── Save prefs object to Firestore ──
async function _profileSavePrefs() {
  if (!window._currentUid) return;
  try {
    const { db, doc, setDoc } = await _profileDb();
    await setDoc(doc(db, 'users', window._currentUid), { prefs: window._profilePrefs }, { merge: true });
    // Keep cache in sync
    if (window._userDataCache) window._userDataCache.prefs = { ...window._profilePrefs };
    _profileShowToast('Saved');
  } catch(e) {
    console.warn('Profile prefs save:', e);
    _profileShowToast('Error saving');
  }
}

// ── Name editing ──
function profileStartEditName() {
  const displayWrap = document.getElementById('profileNameDisplay');
  const editWrap    = document.getElementById('profileNameEditWrap');
  const input       = document.getElementById('profileNameInput');
  const current     = document.getElementById('profileMainName');
  if (!displayWrap || !editWrap || !input) return;
  input.value = current ? current.textContent : '';
  displayWrap.style.display = 'none';
  editWrap.style.display = 'flex';
  setTimeout(() => input.focus(), 60);
}

function profileCancelEditName() {
  document.getElementById('profileNameDisplay').style.display = 'flex';
  document.getElementById('profileNameEditWrap').style.display = 'none';
}

async function profileSaveName() {
  const input = document.getElementById('profileNameInput');
  const name  = input ? input.value.trim() : '';
  if (!name || !window._currentUid) return;

  const btn = document.getElementById('profileSaveNameBtn');
  if (btn) { btn.textContent = '…'; btn.disabled = true; }

  try {
    const { db, doc, setDoc } = await _profileDb();
    await setDoc(doc(db, 'users', window._currentUid), { displayName: name }, { merge: true });

    // Update cache
    if (window._userDataCache) window._userDataCache.displayName = name;

    // Update all name fields
    _pfEl('profileMainName', name);
    _pfEl('profileIntroName', name.split(' ')[0]);
    const currentPhoto = (window._userDataCache && window._userDataCache.photoURL) || null;
    profileUpdateAvatarDisplay(currentPhoto, name);

    profileCancelEditName();
    _profileShowToast('Name saved');
  } catch(e) {
    console.warn('Profile name save:', e);
    _profileShowToast('Error saving');
  } finally {
    if (btn) { btn.textContent = 'Save'; btn.disabled = false; }
  }
}

// ── Preference actions ──
function profileToggleSound() {
  window._profilePrefs.soundFeedback = !window._profilePrefs.soundFeedback;
  profileApplyPrefsUI();
  _profileSavePrefs();
}

function profileChangeDuration(delta) {
  const p = window._profilePrefs;
  p.practiceMins = Math.min(60, Math.max(6, p.practiceMins + delta));
  const durEl = document.getElementById('pref-duration-val');
  if (durEl) durEl.textContent = p.practiceMins + ' min';
  _profileSavePrefs();
}

function profileSaveReminder(val) {
  window._profilePrefs.reminderTime = val;
  _profileSavePrefs();
}

function profileSetVoice(v) {
  window._profilePrefs.voice = v;
  profileApplyPrefsUI();
  _profileSavePrefs();
}

// ── Helpers ──
function _pfEl(id, text) {
  const el = document.getElementById(id);
  if (el) el.textContent = text;
}

function _profileShowToast(msg) {
  const toast = document.getElementById('profileSaveToast');
  if (!toast) return;
  toast.textContent = msg;
  toast.style.opacity = '1';
  clearTimeout(toast._t);
  toast._t = setTimeout(() => { toast.style.opacity = '0'; }, 1800);
}

// ── "Open Profile" button — dismiss intro, reveal content ──
function profileEnterFromIntro() {
  const intro = document.getElementById('profileIntroPage');
  const main  = document.getElementById('profileMainContent');
  if (intro) intro.classList.add('sl-intro-hidden');
  setTimeout(() => {
    if (intro) intro.style.display = 'none';
    if (main)  main.style.display = 'flex';
  }, 420);
}

// ── PROFILE BANNER: clean, static (no 3D tilt) to match Settings guide page ──
// (Tilt/parallax removed — the banner now fades cleanly into the solid background.)

// ══════════════════════════════════════════════════════════════════
// PROFILE PHOTO — select, upload to Cloudinary, save to Firestore
// ══════════════════════════════════════════════════════════════════

// Cloudinary config — uses the same cloud as the rest of the app
const _CLOUDINARY_CLOUD  = 'dfc8lwj22';  // active account
const _CLOUDINARY_PRESET = 'nowssb_profiles'; // unsigned upload preset (create this in your Cloudinary dashboard)

// ── Update avatar display: show photo img or fallback to initial ──
function profileUpdateAvatarDisplay(photoURL, name) {
  const imgEl = document.getElementById('profileAvatarImg');
  if (!imgEl) return;

  const url = photoURL || _AVATAR_URLS[0];
  imgEl.src = url;
  imgEl.className = 'profile-avatar-ring-img';  // ensure class is always set
}

// ── Open the photo source selection sheet ──
function profileEditPhoto() {
  const sheet = document.getElementById('profilePhotoSheet');
  if (sheet) sheet.classList.add('pps-open');
}
function profileClosePhotoSheet() {
  const sheet = document.getElementById('profilePhotoSheet');
  if (sheet) sheet.classList.remove('pps-open');
}
// Option 1: pick from phone library
function profilePickFromLibrary() {
  profileClosePhotoSheet();
  const input = document.getElementById('profilePhotoInput');
  if (input) { input.value = ''; input.click(); }
}
// Option 2: open avatar picker
function profileOpenAvatarPicker() {
  profileClosePhotoSheet();
  const picker = document.getElementById('profileAvatarPicker');
  if (picker) {
    picker.classList.add('pap-open');
    _papInit();
  }
}
function profileCloseAvatarPicker() {
  const picker = document.getElementById('profileAvatarPicker');
  if (picker) picker.classList.remove('pap-open');
  window._papSelectedUrl = null;
  const btn = document.getElementById('papConfirmBtn');
  if (btn) btn.style.display = 'none';
}
function profileAvatarBackToSheet() {
  profileCloseAvatarPicker();
  const sheet = document.getElementById('profilePhotoSheet');
  if (sheet) sheet.classList.add('pps-open');
}

// ── Avatar picker internals ──
const _PAP_AVATAR_COUNT = 8;
let _papCurrentStyle = 'offline';
window._papSelectedUrl = null;

function _papInit() {
  // Hide style tabs — we use offline SVGs now, no DiceBear styles
  const tabsEl = document.getElementById('papStyleTabs');
  if (tabsEl) tabsEl.style.display = 'none';
  _papRenderGrid();
}

function _papSwitchStyle() { /* no-op — offline mode has no styles */ }

function _papRenderGrid() {
  const grid = document.getElementById('papAvatarGrid');
  if (!grid) return;
  if (grid.dataset.built) return; // already built
  grid.dataset.built = '1';
  for (let i = 0; i < _PAP_AVATAR_COUNT; i++) {
    const url = _genAvatarURI(i);
    const cell = document.createElement('div');
    cell.className = 'pap-avatar-cell';
    cell.dataset.url = url;
    cell.innerHTML = `<img decoding="async" src="${url}" alt="Avatar ${i+1}" loading="eager">`;
    cell.onclick = () => _papSelectCell(cell, url);
    grid.appendChild(cell);
  }
}

function _papSelectCell(cell, url) {
  document.querySelectorAll('.pap-avatar-cell').forEach(c => c.classList.remove('selected'));
  cell.classList.add('selected');
  window._papSelectedUrl = url;
  // Update ring preview immediately (same as onboarding)
  const imgEl = document.getElementById('profileAvatarImg');
  if (imgEl) { imgEl.src = url; imgEl.className = 'profile-avatar-ring-img'; }
  const btn = document.getElementById('papConfirmBtn');
  if (btn) btn.style.display = 'block';
}

async function profileConfirmAvatar() {
  const url = window._papSelectedUrl;
  if (!url) return;
  profileCloseAvatarPicker();
  // Show preview immediately
  profileUpdateAvatarDisplay(url, null);
  _profileShowToast('Saving…');
  try {
    await _profileSavePhotoURL(url);
    _profileShowToast('Avatar saved ✓');
  } catch(err) {
    console.warn('Avatar save error:', err);
    const cached = (window._userDataCache && window._userDataCache.photoURL) || null;
    const cachedName = (window._userDataCache && window._userDataCache.displayName) || 'Practitioner';
    profileUpdateAvatarDisplay(cached, cachedName);
    _profileShowToast(err.message || 'Save failed');
  }
}

// ── Called when user picks a file ──
async function profileHandlePhotoFile(file) {
  // Validate type — only allow safe image MIME types
  const ALLOWED_TYPES = ['image/jpeg','image/png','image/webp','image/gif'];
  if (!file || !ALLOWED_TYPES.includes(file.type)) {
    _profileShowToast('Please choose a JPG, PNG, WebP or GIF image');
    return;
  }
  // 5 MB hard limit (Cloudinary free tier is generous but no need to allow large files)
  if (file.size > 5 * 1024 * 1024) { _profileShowToast('Image too large — please choose one under 5 MB'); return; }

  // Show local preview immediately so it feels instant
  const reader = new FileReader();
  reader.onload = e => profileUpdateAvatarDisplay(e.target.result, null);
  reader.readAsDataURL(file);

  _profileShowToast('Uploading…');

  try {
    const url = await _profileUploadToCloudinary(file);
    await _profileSavePhotoURL(url);
    // Show the final Cloudinary URL
    profileUpdateAvatarDisplay(url, null);
    _profileShowToast('Photo saved ✓');
  } catch(err) {
    console.warn('Photo upload error:', err);
    // Revert preview on failure
    const cached = (window._userDataCache && window._userDataCache.photoURL) || null;
    const cachedName = (window._userDataCache && window._userDataCache.displayName) || 'Practitioner';
    profileUpdateAvatarDisplay(cached, cachedName);
    _profileShowToast(err.message || 'Upload failed');
  }
}

// ── Upload file to Cloudinary via unsigned upload ──
async function _profileUploadToCloudinary(file) {
  const fd = new FormData();
  fd.append('file',           file);
  fd.append('upload_preset',  _CLOUDINARY_PRESET);
  fd.append('folder',         'nowssb_user_profiles');
  fd.append('public_id',      'user_' + (window._currentUid || Date.now()));

  const res = await fetch(
    `https://api.cloudinary.com/v1_1/${_CLOUDINARY_CLOUD}/image/upload`,
    { method: 'POST', body: fd }
  );

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error && err.error.message ? err.error.message : 'Cloudinary upload failed');
  }

  const data = await res.json();
  if (!data.secure_url) throw new Error('No URL returned from Cloudinary');

  // Use auto-optimized delivery URL
  return data.secure_url.replace('/upload/', '/upload/q_auto/f_auto/');
}

// ── Save photoURL to Firestore + update local cache ──
async function _profileSavePhotoURL(url) {
  if (!window._currentUid) throw new Error('Not logged in');
  const { db, doc, setDoc } = await _profileDb();
  await setDoc(doc(db, 'users', window._currentUid), { photoURL: url }, { merge: true });
  if (window._userDataCache) window._userDataCache.photoURL = url;
  // Refresh edit panel avatar circle and IG nav avatar
  var circle = document.getElementById('profile-edit-avatar-circle');
  if (circle) { circle.style.backgroundImage = 'url('+url+')'; circle.style.backgroundSize = 'cover'; circle.style.backgroundPosition = 'center'; circle.innerHTML = ''; }
  if (window.IG && typeof IG.refreshNavAvatar === 'function') IG.refreshNavAvatar();
  // Refresh IG profile banner/avatar if open
  if (window.IG && document.getElementById('sub-ig-profile') && document.getElementById('sub-ig-profile').classList.contains('open')) IG.openMyProfile();
}

// ── Save bannerURL to Firestore + update local cache ──
async function _profileSaveBannerURL(url) {
  if (!window._currentUid) throw new Error('Not logged in');
  const { db, doc, setDoc } = await _profileDb();
  await setDoc(doc(db, 'users', window._currentUid), { bannerURL: url }, { merge: true });
  if (window._userDataCache) window._userDataCache.bannerURL = url;
}

// ── Called when user picks a banner image file ──
async function profileHandleBannerFile(file) {
  const ALLOWED = ['image/jpeg','image/png','image/webp','image/gif'];
  if (!file || !ALLOWED.includes(file.type)) { _profileShowToast('Please choose a JPG, PNG, or WebP image'); return; }
  if (file.size > 10 * 1024 * 1024) { _profileShowToast('Image too large — max 10 MB'); return; }

  const reader = new FileReader();
  reader.onload = function(e) {
    var src = e.target.result;
    var preview = document.getElementById('profile-edit-banner-preview');
    if (preview) { preview.style.backgroundImage = 'url('+src+')'; preview.style.backgroundSize = 'cover'; preview.style.backgroundPosition = 'center'; }
    var mainBanner = document.getElementById('ig-prof-banner');
    if (mainBanner) { mainBanner.style.backgroundImage = 'url('+src+')'; mainBanner.style.backgroundSize = 'cover'; mainBanner.style.backgroundPosition = 'center top'; }
  };
  reader.readAsDataURL(file);

  _profileShowToast('Uploading banner…');

  try {
    var fd = new FormData();
    fd.append('file', file);
    fd.append('upload_preset', _CLOUDINARY_PRESET);
    fd.append('folder', 'nowssb_user_banners');
    fd.append('public_id', 'banner_' + (window._currentUid || Date.now()));
    var res = await fetch('https://api.cloudinary.com/v1_1/' + _CLOUDINARY_CLOUD + '/image/upload', { method: 'POST', body: fd });
    if (!res.ok) { var err = await res.json().catch(function(){ return {}; }); throw new Error(err.error && err.error.message ? err.error.message : 'Upload failed'); }
    var data = await res.json();
    if (!data.secure_url) throw new Error('No URL returned');
    var url = data.secure_url.replace('/upload/', '/upload/q_auto/f_auto/');
    await _profileSaveBannerURL(url);
    _profileShowToast('Banner saved ✓');
  } catch(err) {
    console.warn('Banner upload error:', err);
    _profileShowToast(err.message || 'Upload failed');
  }
}

// ── Trigger banner file picker ──
function profilePickBanner() {
  var input = document.getElementById('profileBannerInput');
  if (input) { input.value = ''; input.click(); }
}
