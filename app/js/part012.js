
// ── Block the native long-press context menu (Copy/Download/Share image,
// "Open in Chrome browser") on every image/video app-wide, on the PWA and
// the plain website alike. CSS alone (-webkit-touch-callout etc., see
// app.css) doesn't reliably suppress Android Chrome's own long-press menu —
// this explicit prevention is what actually stops it. Doesn't touch normal
// taps/clicks, only the long-press/right-click menu and native drag-out. ──
document.addEventListener('contextmenu', function (e) { e.preventDefault(); }, { passive: false });
document.addEventListener('dragstart', function (e) {
  if (e.target && (e.target.tagName === 'IMG' || e.target.tagName === 'VIDEO')) e.preventDefault();
});

// ── BACKGROUND IMAGES — 1 per screen, never repeated ──
const bgImages = {
  splash:     null, // splash uses its own inline bg
  login:      null,
  signup1:    'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto,w_900/v1777584943/grok_image_1777580530017_nftrrb.jpg',
  signup1phone: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto,w_900/v1777584978/grok_image_1777580577245_s0oftf.jpg',
  signup2:    'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto,w_900/v1777591568/grok_image_1777591433417_rx2whb.jpg',
  'profile-setup': 'https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto,w_900/v1778309102/grok_image_1778309033334_fza02n.jpg',
  onboarding: 'https://res.cloudinary.com/ds6duqabl/image/upload/q_auto/f_auto,w_900/v1779804089/3cca01a0-590b-11f1-8540-43cf58c6068c_ke31me.png',
  onboarding2: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto,w_900/v1777615898/grok_image_1777615621529_xdxfj6.jpg',
  onboarding3: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto,w_900/v1777616006/grok_image_1777615631154_yddgyh.jpg',
  analysis:   'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto,w_900/v1776850607/1000033084-ezremove_ybzuzs.png',
  home:       'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto,w_900/v1776850550/1000033096-ezremove_eb2gnu.png'
};

// Per-screen background positions — new image is well-centered, characters top half, panel bottom
const bgPositions = {};

const appBg = document.getElementById('appBg');

function setBg(screenId) {
  const url = bgImages[screenId];
  if (url) {
    // Fade out briefly so image swap is invisible
    appBg.style.transition = 'opacity 0.25s ease, background-image 0s 0.25s';
    appBg.style.opacity = '0';
    setTimeout(() => {
      appBg.style.backgroundImage = `url('${url}')`;
      appBg.style.backgroundPosition = bgPositions[screenId] || 'center';
      appBg.style.transition = 'opacity 0.4s ease';
      appBg.style.opacity = '1';
    }, 250);
  } else {
    appBg.style.transition = 'opacity 0.3s ease';
    appBg.style.backgroundPosition = 'center';
    appBg.style.opacity = '0';
  }
}

// Init
setBg('splash');

// ── PARTICLES ──
(function createParticles() {
  const cont = document.getElementById('particles');
  for (let i = 0; i < 8; i++) {
    const p = document.createElement('div');
    p.className = 'particle';
    p.style.cssText = `
      left:${Math.random()*100}%;
      width:${Math.random()*2+1}px;
      height:${Math.random()*2+1}px;
      animation-duration:${9+Math.random()*13}s;
      animation-delay:${-Math.random()*22}s;
      opacity:${0.25+Math.random()*0.65};
    `;
    cont.appendChild(p);
  }
})();

// ── SCREEN NAVIGATION ──
// ── SMART VIDEO MANAGER ──
// Preloads videos in sequence so they're ready before user arrives.
// Pauses videos on screens the user leaves, plays on screens they enter.
const _videoMap = {
  'home':              ['hvb-video'],
  'sub-word-search':   ['word-search-video', 'nssWordVid'],
  'sub-meaning-search':['krm-video', 'nssMeaningVid', 'msBannerImg'],
};
// Step screens share same video src — just one preload needed
const _stepVideoSrc = 'https://res.cloudinary.com/dfc8lwj22/video/upload/q_auto/f_auto/v1777979792/grok_video_2026-05-05-16-46-09_dpauwg.mp4';
const _stepScreens = ['sub-shabdapathy','sub-pronunciation','sub-namasmaran','sub-electricity','sub-moral','sub-birthday'];

// Preload a video src silently in background
function _preloadVideoSrc(src) {
  if (!src || _preloadVideoSrc._done) return;
  if (!_preloadVideoSrc._cache) _preloadVideoSrc._cache = new Set();
  if (_preloadVideoSrc._cache.has(src)) return;
  _preloadVideoSrc._cache.add(src);
  const link = document.createElement('link');
  link.rel = 'preload';
  link.as = 'video';
  link.href = src;
  link.fetchPriority = 'low';
  document.head.appendChild(link);
}

// Play all videos on a screen
function _playScreenVideos(screenId) {
  const el = document.getElementById(screenId);
  if (!el) return;
  el.querySelectorAll('video').forEach(v => {
    if (v.paused) {
      // Set src if not yet set (lazy load)
      const src = v.dataset.lazySrc;
      if (src && !v.src && !v.querySelector('source[src]')) {
        v.src = src;
      }
      v.play().catch(() => {});
    }
  });
}

// Pause all videos on a screen
function _pauseScreenVideos(screenId) {
  const el = document.getElementById(screenId);
  if (!el) return;
  el.querySelectorAll('video').forEach(v => { if (!v.paused) v.pause(); });
}

// Sequential background preload — runs after splash, low priority
function _runSequentialPreload() {
  const queue = [
    // Home video first — most likely destination
    'https://res.cloudinary.com/dfc8lwj22/video/upload/q_auto/v1778061531/grok_video_2026-05-06-15-27-23_zhylbe.mp4',
    // Step screen video (shared)
    _stepVideoSrc,
    // Word search
    'https://res.cloudinary.com/dkzxw33ln/video/upload/q_auto/f_auto/v1776800800/InShot_20260422_000025290_xqdxey.mp4',
    // Meaning search
    'https://res.cloudinary.com/dcbs8xr1l/video/upload/q_auto/v1778677278/grok_video_2026-05-13-17-16-28_e4m4vr.mp4',
    'https://res.cloudinary.com/dcbs8xr1l/video/upload/q_auto/f_auto/v1778511160/grok_video_2026-05-11-19-06-52_e67kc6.mp4',
  ];
  let i = 0;
  function next() {
    if (i >= queue.length) return;
    _preloadVideoSrc(queue[i++]);
    // Stagger each preload 1.5s apart so they don't compete
    setTimeout(next, 1500);
  }
  // Start 3s after splash — user is on login/onboarding, not watching videos yet
  setTimeout(next, 3000);
}
_runSequentialPreload();

let currentScreen = 'splash';
function goTo(id) {
  const cur = document.getElementById(currentScreen);
  const next = document.getElementById(id);
  const homeHdr = document.getElementById('homeHeader');
  if (!cur || !next) { console.warn('goTo: missing element for', currentScreen, '→', id); return; }

  /* Self-exit guard: some callers reach goTo(id) without knowing
     currentScreen already equals id — e.g. after navigating through an
     overlay system like the Store, which never updates currentScreen —
     so cur === next. The 500ms cleanup below would then strip
     .active/.exit from the very screen it just (re)activated, leaving it
     with neither class and the screen effectively blank. Several callers
     already work around this by manually nudging currentScreen first;
     guard it here too so every caller is protected, not just the ones
     that remembered to. */
  if (cur === next) {
    if (homeHdr) homeHdr.style.display = (id === 'home') ? 'flex' : 'none';
    return;
  }

  // Force-close all SS panels so they never bleed into other screens
  document.querySelectorAll('.ss-panel').forEach(function(p) {
    p.style.transform = 'translateX(100%)';
    p.style.display = 'none';
  });
  if (window._ssOpenPanels) window._ssOpenPanels = [];

  cur.classList.add('exit');
  setBg(id);

  // ── PAUSE intervals not needed for next screen ──
  // NOTE: Hero (_heroInterval, _tagInterval) runs ALWAYS — even on other screens.
  // This keeps all 5 hero images cycling in browser cache so returning to home is instant.
  const healthIntervals = [window._maleBannerInterval, window._femaleBannerInterval];
  const playerIntervals = [window._wlBannerTimer];

  function pauseInterval(ref) { if (ref) clearInterval(ref); }

  if (id !== 'sub-health-male' && id !== 'sub-health-female') {
    healthIntervals.forEach(pauseInterval);
  }
  if (id !== 'sub-sound-library') {
    playerIntervals.forEach(pauseInterval);
  }

  // ── RESUME intervals when entering their screen ──
  if (id === 'sub-health-male' || id === 'sub-health-female') {
    // Clear any existing intervals before starting new ones to prevent stacking
    if (window._maleBannerInterval) { clearInterval(window._maleBannerInterval); window._maleBannerInterval = null; }
    if (window._femaleBannerInterval) { clearInterval(window._femaleBannerInterval); window._femaleBannerInterval = null; }
    window._maleBannerInterval = setInterval(() => {
      rotateBanner(document.getElementById('maleBannerImg'), maleBanners, maleIdx, v => maleIdx = v);
    }, 4000);
    window._femaleBannerInterval = setInterval(() => {
      rotateBanner(document.getElementById('femaleBannerImg'), femaleBanners, femaleIdx, v => femaleIdx = v);
    }, 4000);
  }

  // Immediately activate entering screen — cross-fade with exiting, no dark-body gap
  document.querySelectorAll('.screen.active').forEach(function(s) { if (s !== next) s.classList.remove('active','exit'); });
  next.classList.add('active');
  next.scrollTop = 0;
  currentScreen = id;
  if (homeHdr) homeHdr.style.display = (id === 'home') ? 'flex' : 'none';

  /* Light screens must not show the dark app background in any bottom gap.
     Toggle a plain body/html class (works where :has() doesn't) that lightens
     the whole fallback stack + kills the dark vignette → no black band. */
  var _LIGHT_SCREENS = { login:1, signup1:1, signup2:1, onboarding:1, 'ob-normal':1, 'profile-setup':1, 'home-nm':1 };
  var _isLight = !!_LIGHT_SCREENS[id];
  document.body.classList.toggle('nwsb-lightbg', _isLight);
  document.documentElement.classList.toggle('nwsb-lightbg', _isLight);

  setTimeout(() => {
    // Clean up exiting screen after CSS transition (0.5s) completes
    cur.classList.remove('active','exit');
    // Pause videos on screen we left
    _pauseScreenVideos(cur.id);
    // Play videos on screen we arrived at
    _playScreenVideos(id);
    // Show download FAB only on home screen
    const fab = document.getElementById('dlFab');
    const alreadyInstalled = isInStandaloneMode() || (!isIOS() && !deferredInstallPrompt);
    if (fab) fab.style.display = (id === 'home' && !alreadyInstalled) ? 'flex' : 'none';
    if (id === 'analysis') startAnalysis();
    if (id === 'ob-intro') { /* nothing extra needed, the screen just shows */ }
    if (id === 'onboarding') renderQuestion();
    if (id === 'ob-normal') { if(typeof obnRender==='function') obnRender(); }
    if (id === 'profile-setup') psInit();
    if (id === 'landing') {
      var hint = document.getElementById('ld-cta-hint');
      if (hint) hint.textContent = window._currentUid ? 'Enter your practice' : 'Sign in to begin';
    }
    if (id === 'home') { initHomeScrollBg(); updateTodayCard(); if(typeof rxInit==='function') setTimeout(rxInit,120); if (typeof nssUpdateHomeBadges === 'function') nssUpdateHomeBadges(); if(typeof _nwsbRotateFashBanner==='function') _nwsbRotateFashBanner('homeFashImg','home'); if(typeof _nwsbCwcCycle==='function') _nwsbCwcCycle(); (function(){ var d=window._userDataCache||{}; var s=d.currentStreak||d.streakCount||0; var e=document.getElementById('fashStreakNum'); if(e) e.textContent=s; })(); (function(){ var card = document.getElementById('sub-promo-card'); if (!card) return; var hasPlan = window.GATE ? (window.GATE.tier()==='resonance'||window.GATE.tier()==='frequency'||window.GATE.tier()==='frequencyX') : (window._userDataCache && window._userDataCache.isPro); card.style.display = hasPlan ? 'none' : 'block'; })(); }
    if (id === 'home-nm') {
      if(typeof nmhRefresh==='function') setTimeout(nmhRefresh,80);
      if(typeof updateTodayCard==='function') setTimeout(updateTodayCard,100);
      var nav=document.getElementById('ig-bottomnav');
      if(nav){ nav.classList.add('show'); }
      document.documentElement.style.setProperty('--nav-height','58px');
    }
    if (id === 'home') {
      var nav=document.getElementById('ig-bottomnav');
      if(nav){ nav.classList.add('show'); }
      document.documentElement.style.setProperty('--nav-height','58px');
    }
    if (id !== 'home') resetHomeBgLayer();
  }, 520);
}

// ── SPLASH FALLBACK TIMER ──
setTimeout(() => {
  if (currentScreen !== 'splash') return;
  window._splashDone = true;
  if (typeof _doNavigate === 'function') _doNavigate(window._splashRoute || 'home');
  else goTo(window._splashRoute || 'login');
}, 5000);

// ══════════════════════════════════════════════════════════════════
// PROFILE SETUP SCREEN — name + avatar / photo
// ══════════════════════════════════════════════════════════════════

// 12 diverse DiceBear avatars (mix of lorelei + notionists for variety)

// ── PROFILE SETUP STATE ──
let _psSelectedAvatarUrl = null;
let _psUploadedPhotoUrl  = null;
let _psGridBuilt = false;

// ── REAL AVATAR IMAGES — your 8 Cloudinary characters ──
const _AVATAR_URLS = [
  'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778418246/image-131_jyrnhx.jpg',
  'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778418246/image-135_hziacn.jpg',
  'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778418246/image-92_rfnjut.jpg',
  'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778418246/image-190_jqulqk.jpg',
  'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778418246/image-240_wxgthb.jpg',
  'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778418327/image-156_awwho5.jpg',
  'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778418357/image-162_vl3unq.jpg',
  'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778418383/image-167_qbyiji.jpg',
];
function _genAvatarURI(idx) {
  return _AVATAR_URLS[idx % _AVATAR_URLS.length];
}
const _PS_AVATAR_COUNT = 8;

function psInit() {
  // Pre-fill name
  const input = document.getElementById('psNameInput');
  if (input && !input.value) {
    const cachedName = (window._userDataCache && window._userDataCache.displayName) || '';
    if (cachedName) input.value = cachedName;
  }
  // Restore saved avatar if any
  const cachedPhoto = (window._userDataCache && window._userDataCache.photoURL) || null;
  if (cachedPhoto) {
    _psSelectedAvatarUrl = cachedPhoto;
    const ringImg = document.getElementById('psAvatarRingImg');
    if (ringImg) ringImg.src = cachedPhoto;
  }
  // Build grid once
  if (_psGridBuilt) return;
  _psGridBuilt = true;
  _psBuildGrid();
}

function _psBuildGrid() {
  const grid = document.getElementById('psAvatarGrid');
  if (!grid) return;
  for (let i = 0; i < _PS_AVATAR_COUNT; i++) {
    const url = _genAvatarURI(i);
    const cell = document.createElement('div');
    cell.className = 'ps-sheet-cell';
    cell.innerHTML = `
      <img decoding="async" src="${url}" alt="Avatar ${i+1}" loading="eager">
      <div class="ps-sheet-check">
        <svg width="18" height="14" viewBox="0 0 18 14" fill="none">
          <path d="M2 7L6 11L16 2" stroke="var(--accent)" stroke-width="2" stroke-linecap="square"/>
        </svg>
      </div>`;
    cell.onclick = () => psSelectAvatar(cell, url);
    grid.appendChild(cell);
  }
  // Set first avatar as default ring image
  const ringImg = document.getElementById('psAvatarRingImg');
  if (ringImg && (!_psSelectedAvatarUrl && !_psUploadedPhotoUrl)) {
    ringImg.src = _AVATAR_URLS[0];
    _psSelectedAvatarUrl = _AVATAR_URLS[0];
  }
}

function psOpenSheet() {
  document.getElementById('psSheetBackdrop').classList.add('open');
  document.getElementById('psSheet').classList.add('open');
}
function psCloseSheet() {
  document.getElementById('psSheetBackdrop').classList.remove('open');
  document.getElementById('psSheet').classList.remove('open');
}
window.psOpenSheet  = psOpenSheet;
window.psCloseSheet = psCloseSheet;

function psSelectAvatar(cell, url) {
  document.querySelectorAll('.ps-sheet-cell').forEach(c => c.classList.remove('selected'));
  cell.classList.add('selected');
  _psSelectedAvatarUrl = url;
  _psUploadedPhotoUrl = null;
  // Update the ring preview
  const ringImg = document.getElementById('psAvatarRingImg');
  if (ringImg) ringImg.src = url;
  // Reset upload button
  const btn = document.getElementById('psUploadBtn');
  if (btn) {
    btn.classList.remove('has-photo');
    btn.innerHTML = `<svg width="15" height="15" viewBox="0 0 15 15" fill="none">
      <circle cx="7.5" cy="7.5" r="6" stroke="currentColor" stroke-width="1.3"/>
      <path d="M7.5 5V10M5 7.5H10" stroke="currentColor" stroke-width="1.3" stroke-linecap="square"/>
    </svg> Upload a Photo`;
  }
  // Close sheet after a short delay so selection is visible
  setTimeout(psCloseSheet, 220);
}

async function psHandlePhoto(file) {
  if (!file || !file.type.startsWith('image/')) return;
  if (file.size > 8 * 1024 * 1024) { alert('Image too large — max 8 MB'); return; }

  const btn = document.getElementById('psUploadBtn');
  if (btn) { btn.innerHTML = '⏳ Uploading…'; btn.disabled = true; }

  // Show local preview on ring immediately
  const reader = new FileReader();
  reader.onload = e => {
    const ringImg = document.getElementById('psAvatarRingImg');
    if (ringImg) ringImg.src = e.target.result;
  };
  reader.readAsDataURL(file);

  try {
    const url = await _profileUploadToCloudinary(file);
    _psUploadedPhotoUrl = url;
    _psSelectedAvatarUrl = null;
    document.querySelectorAll('.ps-sheet-cell').forEach(c => c.classList.remove('selected'));
    const ringImg = document.getElementById('psAvatarRingImg');
    if (ringImg) ringImg.src = url;
    if (btn) {
      btn.disabled = false;
      btn.classList.add('has-photo');
      btn.innerHTML = `<svg width="14" height="14" viewBox="0 0 14 14" fill="none">
        <path d="M2 8L5 11L12 3" stroke="currentColor" stroke-width="1.4" stroke-linecap="square"/>
      </svg> Photo uploaded — tap to change`;
    }
    setTimeout(psCloseSheet, 300);
  } catch(e) {
    if (btn) {
      btn.disabled = false;
      btn.classList.remove('has-photo');
      btn.innerHTML = `<svg width="15" height="15" viewBox="0 0 15 15" fill="none">
        <circle cx="7.5" cy="7.5" r="6" stroke="currentColor" stroke-width="1.3"/>
        <path d="M7.5 5V10M5 7.5H10" stroke="currentColor" stroke-width="1.3" stroke-linecap="square"/>
      </svg> Upload a Photo`;
    }
    alert('Upload failed: ' + e.message);
  }
}
window.psHandlePhoto = psHandlePhoto;

async function psContinue() {
  const name     = (document.getElementById('psNameInput').value || '').trim();
  const photoURL = _psUploadedPhotoUrl || _psSelectedAvatarUrl || null;

  const btn = document.getElementById('psContinueBtn');
  if (btn) { btn.textContent = 'Saving…'; btn.disabled = true; }

  try {
    if (window._currentUid && window._fbSetDoc) {
      const update = { profileStepDone: true };
      if (name)     update.displayName = name;
      if (photoURL) update.photoURL    = photoURL;
      await window._fbSetDoc(window._currentUid, update);
      if (!window._userDataCache) window._userDataCache = {};
      if (name)     window._userDataCache.displayName = name;
      if (photoURL) window._userDataCache.photoURL    = photoURL;
    }
  } catch(e) {
    console.warn('Profile setup save error:', e.message);
  }

  if (btn) { btn.textContent = 'Continue →'; btn.disabled = false; }
  try { localStorage.setItem('nwsb_onboarding_done', '1'); } catch(e){}
  // If user skipped all onboarding, skip the fake analysis screen — go straight home
  if (window._obSkipped) {
    window._obSkipped = false;
    finishOnboarding();
  } else {
    goTo('analysis');
  }
}
window.psContinue = psContinue;

function psSkip() {
  if (window._currentUid && window._fbSetDoc) {
    window._fbSetDoc(window._currentUid, { profileStepDone: true }).catch(() => {});
  }
  try { localStorage.setItem('nwsb_onboarding_done', '1'); } catch(e){}
  // If user skipped all onboarding, skip the fake analysis screen — go straight home
  if (window._obSkipped) {
    window._obSkipped = false;
    finishOnboarding();
  } else {
    goTo('analysis');
  }
}
window.psSkip = psSkip;

// ── HOME SCROLL BG CROSSFADE ──
// When the Word Search section scrolls into view on the home screen,
// the background cross-fades to the left footer image (primal/nature figure).
// Scrolling back restores the original home background.
const HOME_BG_SCROLL = 'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850631/1000033052-ezremove_vx4rib.png';
const appBgLayer2 = document.getElementById('appBgLayer2');
(new Image()).src = HOME_BG_SCROLL;
appBgLayer2.style.backgroundImage = `url('${HOME_BG_SCROLL}')`;

let homeBgObserver = null;
function initHomeScrollBg() {
  if (homeBgObserver) return; // only set up once
  const homeScreen = document.getElementById('home');
  const trigger = homeScreen.querySelector('.word-search-section');
  if (!trigger) return;

  homeBgObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (currentScreen !== 'home') return;
      if (entry.isIntersecting) {
        appBgLayer2.style.opacity = '1';
      } else {
        appBgLayer2.style.opacity = '0';
      }
    });
  }, { root: homeScreen, threshold: 0.12 });

  homeBgObserver.observe(trigger);
}

function resetHomeBgLayer() {
  appBgLayer2.style.opacity = '0';
}

// ── PASSWORD TOGGLE ──
function togglePw() {
  const inp = document.getElementById('pwInput');
  inp.type = inp.type === 'password' ? 'text' : 'password';
}

// ── NEUMORPHIC AUTH FORM TOGGLE ──
function landingEnter() {
  if (!window._currentUid) { goTo('login'); return; }
  var overlay = document.getElementById('ld-transition');
  if (overlay) {
    overlay.classList.add('show');
    setTimeout(function() {
      goTo('home');
      setTimeout(function() { overlay.classList.remove('show'); }, 300);
    }, 950);
  } else {
    goTo('home');
  }
}

// ── Neumorphic Home helpers ──
function nmhSwitchMode() {
  var el = document.getElementById('home-nm');
  var btn = document.getElementById('nmhModeBtn');
  var sun = document.getElementById('nmhSunIcon');
  var moon = document.getElementById('nmhMoonIcon');
  var isDark = el && el.classList.contains('nm-dark');
  if (!isDark) {
    if (el) el.classList.add('nm-dark');
    if (btn) btn.classList.add('nmh-mode-dark');
    if (sun) sun.style.display = 'none';
    if (moon) moon.style.display = '';
    localStorage.setItem('nwsb_nm_dark', '1');
  } else {
    if (el) el.classList.remove('nm-dark');
    if (btn) btn.classList.remove('nmh-mode-dark');
    if (sun) sun.style.display = '';
    if (moon) moon.style.display = 'none';
    localStorage.removeItem('nwsb_nm_dark');
  }
}

/* Shared rotating Fashion/Trend banner — used on both the neumorphism home
   (#home-nm, img #nmhFashImg) and the Fashion home (#home, img #homeFashImg).
   Preloads once, seamless crossfade, rotates only while its host is visible. */
window._FASH_SEQ = window._FASH_SEQ || [
  'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_1000/v1783179785/grok_image_1783178874949_zcbb28.jpg',
  'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_1000/v1783179785/grok_image_1783179042580_kdfmbl.jpg',
  'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_1000/v1783179785/grok_image_1783179567035_qgupmu.jpg',
  'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_1000/v1783179785/grok_image_1783179620064_quvp6x.jpg',
  'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_1000/v1783082388/image-22_ns2jhx.jpg'
];
/* one animated caption per image (same order as _FASH_SEQ); last image = no text */
window._FASH_CAPS = window._FASH_CAPS || [
  'The new trend of meditation',
  'Fashion meets frequency',
  'Wear your healing',
  'Sound is the new style',
  ''
];
window._nwsbRotateFashBanner = function(imgId, hostId) {
  var img = document.getElementById(imgId); if (!img) return;
  var seq = window._FASH_SEQ, caps = window._FASH_CAPS;
  var idxKey = imgId + 'Idx', timerKey = imgId + 'Timer';
  var capEl = document.getElementById(imgId.replace('Img', 'Cap'));
  var ovEl  = document.getElementById(imgId.replace('Img', 'Ov'));
  function showCap(i){
    var c = caps[i % caps.length];
    if (capEl) capEl.textContent = c;
    if (ovEl){
      ovEl.style.display = c ? '' : 'none';            // no text on empty-caption images
      if (c){ ovEl.classList.remove('in'); void ovEl.offsetWidth; ovEl.classList.add('in'); } // re-trigger entrance
    }
  }
  if (!img.getAttribute('src')) { window[idxKey] = 0; img.src = seq[0]; showCap(0); }
  if (!window._fashPreloaded) { window._fashPreloaded = seq.map(function(u){ var im = new Image(); im.src = u; return im; }); }
  if (window[timerKey]) clearInterval(window[timerKey]);
  window[timerKey] = setInterval(function(){
    var el = document.getElementById(imgId);
    var host = document.getElementById(hostId);
    if (!el) { clearInterval(window[timerKey]); window[timerKey] = null; return; }
    if (document.hidden) return;                                // skip crossfade while backgrounded
    if (!host || !host.classList.contains('active')) return;   // rotate only while visible
    var nextIdx = ((window[idxKey] || 0) + 1) % seq.length;
    var nextSrc = seq[nextIdx];
    var pre = new Image();
    pre.onload = function(){
      if (!host.classList.contains('active')) return;
      el.style.opacity = '0';
      setTimeout(function(){ el.src = nextSrc; el.style.opacity = '1'; showCap(nextIdx); }, 340);
      window[idxKey] = nextIdx;
    };
    pre.src = nextSrc;
  }, 4000);
};

/* Store-case cycling caption — shows one phrase at a time (fade out → swap →
   fade in), only while the Fashion home is visible. Bold dark + gold accent. */
window._CWC_PHRASES = window._CWC_PHRASES || [
  ['Your fashion', 'drops'],
  ['The style', 'archive'],
  ['In your', 'fashion bag'],
  ['Saved fashion', 'looks'],
  ['Your', 'healing ritual']
];
window._nwsbCwcCycle = function() {
  var line = document.getElementById('cwcLine'); if (!line) return;
  var P = window._CWC_PHRASES;
  function render(k){ var ph = P[k % P.length]; line.innerHTML = '<span class="cwc-b">'+ph[0]+'</span> <span class="cwc-g">'+ph[1]+'</span>'; }
  var i = window._cwcIdx || 0; render(i);
  if (window._cwcTimer) clearInterval(window._cwcTimer);
  window._cwcTimer = setInterval(function(){
    var l = document.getElementById('cwcLine'); var host = document.getElementById('home');
    if (!l) { clearInterval(window._cwcTimer); window._cwcTimer = null; return; }
    if (document.hidden) return;
    if (!host || !host.classList.contains('active')) return;   // cycle only while visible
    l.classList.add('out');
    setTimeout(function(){ i = (i + 1) % P.length; window._cwcIdx = i; render(i); l.classList.remove('out'); }, 420);
  }, 3200);
};

function nmhRefresh() {
  // Restore dark mode state from storage
  var _nmDark = localStorage.getItem('nwsb_nm_dark') === '1';
  var _nmEl = document.getElementById('home-nm');
  var _nmBtn = document.getElementById('nmhModeBtn');
  var _nmSun = document.getElementById('nmhSunIcon');
  var _nmMoon = document.getElementById('nmhMoonIcon');
  if (_nmDark) {
    if (_nmEl) _nmEl.classList.add('nm-dark');
    if (_nmBtn) _nmBtn.classList.add('nmh-mode-dark');
    if (_nmSun) _nmSun.style.display = 'none';
    if (_nmMoon) _nmMoon.style.display = '';
  } else {
    if (_nmEl) _nmEl.classList.remove('nm-dark');
    if (_nmBtn) _nmBtn.classList.remove('nmh-mode-dark');
    if (_nmSun) _nmSun.style.display = '';
    if (_nmMoon) _nmMoon.style.display = 'none';
  }

  // Kick the Connect background video(s) — autoplay can be deferred, so nudge them
  document.querySelectorAll('.nmh-connect-vid').forEach(function(v){ v.muted = true; var p = v.play(); if (p && p.catch) p.catch(function(){}); });

  // Sync streak (both homes)
  var d = window._userDataCache || {};
  var streak = d.currentStreak || d.streakCount || 0;
  var el = document.getElementById('nmhStreakNum');
  if (el) el.textContent = streak;
  var elF = document.getElementById('fashStreakNum');
  if (elF) elF.textContent = streak;

  // Store COUPON banners — rotate one by one (greeting was removed by request).
  var GREET_SEQ = [
    'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_900/v1784044991/grok_image_1784044846126_pyqsll.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_900/v1784044991/grok_image_1784044843386_iarpg7.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_900/v1784044991/grok_image_1784044844917_ocvbli.jpg'
  ];
  var gimg = document.getElementById('nmhGreetImg');
  // Shop Now is VISIBLE by default; hide it ONLY while the 1st image shows.
  // Toggling a class (not display) means a stale/absent JS can never leave it
  // permanently hidden — worst case it just shows on all three.
  function _nmhCtaSync(i) {
    var cta = document.getElementById('nmhCouponCta');
    if (!cta) return;
    var show = (i !== 0);
    cta.classList.toggle('nmh-cta-hidden', !show);
    // dash the button IN together with the coupon image
    if (show) { cta.classList.remove('coupon-dash-cta'); void cta.offsetWidth; cta.classList.add('coupon-dash-cta'); }
  }
  if (gimg) {
    // Belt & braces: whenever the banner img finishes loading ANY src, sync the
    // button off the URL itself (pyqsll = the 1st, button-less image). This works
    // no matter which code path swapped the image.
    if (!gimg._nwsbCtaBound) {
      gimg._nwsbCtaBound = true;
      gimg.addEventListener('load', function () {
        _nmhCtaSync(gimg.src.indexOf('pyqsll') !== -1 ? 0 : 1);
      });
    }
    if (!gimg.getAttribute('src')) { window._nmhGreetIdx = 0; gimg.src = GREET_SEQ[0]; }
    _nmhCtaSync(window._nmhGreetIdx || 0);
    // preload all so the rotation is seamless (once)
    if (!window._nmhGreetPreloaded) {
      window._nmhGreetPreloaded = GREET_SEQ.map(function(u){ var im = new Image(); im.src = u; return im; });
    }
    if (window._nmhGreetTimer) clearInterval(window._nmhGreetTimer);
    window._nmhGreetTimer = setInterval(function(){
      var el = document.getElementById('nmhGreetImg');
      var host = document.getElementById('home-nm');
      if (!el) { clearInterval(window._nmhGreetTimer); window._nmhGreetTimer = null; return; }
      if (!host || !host.classList.contains('active')) return;   // only rotate while home is visible
      var nextIdx = ((window._nmhGreetIdx || 0) + 1) % GREET_SEQ.length;
      var nextSrc = GREET_SEQ[nextIdx];
      // Only swap once the next image is fully decoded — no broken flash / double-load
      var pre = new Image();
      pre.onload = function(){
        if (!host.classList.contains('active')) return;
        // dash in from the right with a tiny wiggle (no fade)
        el.src = nextSrc;
        el.classList.remove('coupon-dash'); void el.offsetWidth; el.classList.add('coupon-dash');
        window._nmhGreetIdx = nextIdx;
        _nmhCtaSync(nextIdx);
      };
      pre.src = nextSrc;
    }, 4000);
  }

  // ── Fashion / Trend rotating banner (normal home, above the Fashion button) ──
  if (typeof _nwsbRotateFashBanner === 'function') _nwsbRotateFashBanner('nmhFashImg', 'home-nm');

  // Sync today's word from the dark home if available
  var tw = document.getElementById('todayPracticeTitle');
  var nmw = document.getElementById('nmhTodayWord');
  if (tw && nmw) nmw.textContent = tw.textContent || 'Loading...';
  var ts = document.getElementById('todayPracticeSub');
  var nms = document.getElementById('nmhTodayMeaning');
  if (ts && nms) nms.textContent = ts.textContent || 'Your personalized word ritual for right now.';
}

// Hook into goTo so we refresh whenever home-nm is opened
(function(){
  var _origGoTo = window.goTo;
  if (typeof _origGoTo === 'function') {
    window.goTo = function(id) {
      var r = _origGoTo.apply(this, arguments);
      if (id === 'home-nm') setTimeout(nmhRefresh, 60);
      return r;
    };
  }
})();

// Also add classic→nm toggle button on dark home header area
// (We inject a small pill toggle onto home screen after DOM ready)

function nmToggleAuthForm(id) {
  var target = document.getElementById(id);
  if (!target) return;
  var isOpen = target.classList.contains('open');
  document.querySelectorAll('.nm-form-panel').forEach(function(p) { p.classList.remove('open'); });
  document.querySelectorAll('.nm-toggle-btn').forEach(function(b) { b.classList.remove('nm-active'); });
  if (!isOpen) {
    target.classList.add('open');
    var btn = document.querySelector('[data-form="' + id + '"]');
    if (btn) btn.classList.add('nm-active');
    var firstInput = target.querySelector('input');
    if (firstInput) setTimeout(function() { firstInput.focus(); }, 50);
  }
}

// ── LOGIN TAB SWITCHER ──
const TAB_ORDER = ['email', 'phone'];
function switchLoginTab(name) {
  const idx = TAB_ORDER.indexOf(name);
  // move pill: each tab is 50% of the parent
  const pill = document.getElementById('loginTabPill');
  const tabs = document.querySelector('.login-tabs');
  const tabW = tabs ? tabs.offsetWidth / 2 : 0;
  pill.style.transform = `translateX(${idx * tabW}px)`;
  // toggle tab button active states
  TAB_ORDER.forEach(t => {
    document.getElementById('tab-' + t).classList.toggle('active', t === name);
  });
  // toggle panes
  document.querySelectorAll('.login-pane').forEach(p => p.classList.remove('active'));
  document.getElementById('pane-' + name).classList.add('active');
}

// ── SIGNUP TAB SWITCHER ──
function switchSu1Tab(name) {
  const pill = document.getElementById('su1TabPill');
  const tabs = document.querySelector('#signup1 .su-tabs');
  const tabW = tabs ? tabs.offsetWidth / 2 : 0;
  if (pill) pill.style.transform = `translateX(${name === 'phone' ? tabW : 0}px)`;
  ['email','phone'].forEach(t => {
    const el = document.getElementById('su1-tab-' + t);
    if (el) el.classList.toggle('active', t === name);
  });
  document.querySelectorAll('#signup1 .su-pane').forEach(p => p.classList.remove('active'));
  const activePane = document.getElementById('su1-pane-' + name);
  if (activePane) activePane.classList.add('active');
  // swap background
  const appBg = document.getElementById('appBg');
  if (appBg) {
    appBg.style.backgroundImage = name === 'phone'
      ? `url('${bgImages.signup1phone}')`
      : `url('${bgImages.signup1}')`;
  }
  // Show notice if phone auth might not be enabled yet
  if (name === 'phone') {
    const pane = document.getElementById('su1-pane-phone');
    if (pane && !document.getElementById('_phoneAuthNotice')) {
      const notice = document.createElement('p');
      notice.id = '_phoneAuthNotice';
      notice.style.cssText = 'font-size:11px;color:rgba(255,255,255,0.45);text-align:center;margin:0 0 8px;letter-spacing:.5px;';
      notice.textContent = 'Phone sign-up requires your number to receive a one-time code.';
      pane.insertBefore(notice, pane.firstChild);
    }
  }
}

// ── SIGNUP EMAIL — simple email/password flow ──
function goToSignup2Email() {
  const name  = document.getElementById('su1EmailName') ? document.getElementById('su1EmailName').value.trim() : '';
  const email = document.getElementById('su1Email').value.trim();
  const pass  = document.getElementById('su1Password').value.trim();
  if (!email) return alert('Enter your email address');
  if (!pass || pass.length < 6) return alert('Password must be at least 6 characters');
  window._su2Method   = 'email';
  window._su2Name     = name;
  window._su2Email    = email;
  window._su2Password = pass;
  _applySignup2PhoneWrap('email');
  goTo('signup2');
}
// ── SIGNUP PHONE OTP ──
function signupSendPhoneOtp() {
  const name=document.getElementById('su1PhoneName').value.trim();
  const country=document.getElementById('su1PhoneCountry').value;
  const phone=document.getElementById('su1Phone').value.trim();
  const otpWrap=document.getElementById('su1PhoneOtpWrap');
  const btn=document.getElementById('su1PhoneBtn');
  // name optional
  if(!phone) return alert('Enter your phone number');
  const full=country+phone;
  if(!otpWrap.classList.contains('show')) {
    btn.textContent='Sending…'; btn.disabled=true;
    signInWithPhoneNumber(auth, full, _getRecaptcha('recaptcha-signup'))
      .then(res => { _signupConfirmationResult=res; window._su2Name=name; window._su2Phone=full;
        otpWrap.classList.add('show'); btn.textContent='Verify & Continue →'; btn.disabled=false;
        btn.onclick=verifySignupPhoneOtp; })
      .catch(e => { btn.textContent='Send OTP'; btn.disabled=false; alert('Failed: '+e.message); });
  } else { verifySignupPhoneOtp(); }
}
async function verifySignupPhoneOtp() {
  const code=document.getElementById('su1PhoneOtp').value.trim();
  const btn=document.getElementById('su1PhoneBtn');
  if(!code) return alert('Enter OTP');
  if(!_signupConfirmationResult) return alert('Request OTP first');
  try { btn.textContent='Verifying…'; btn.disabled=true; await _signupConfirmationResult.confirm(code); }
  catch(e) { btn.textContent='Verify & Continue →'; btn.disabled=false; alert('Invalid OTP: '+e.message); }
}
function _applySignup2PhoneWrap(method) {
  // Centralized: show phone field only for email signups (optional phone),
  // hide it for phone signups (phone already captured) and social (no phone field needed)
  const pw = document.getElementById('su2PhoneWrap');
  if (pw) pw.style.display = (method === 'email') ? 'block' : 'none';
}

function goToSignup2Phone() {
  const name    = document.getElementById('su1PhoneName').value.trim();
  const country = document.getElementById('su1PhoneCountry').value;
  const phone   = document.getElementById('su1Phone').value.trim();
  if (!name || !phone) return alert('Please complete all fields');
  window._su2Method = 'phone';
  window._su2Name   = name;
  window._su2Phone  = country + phone;
  _applySignup2PhoneWrap('phone');
  goTo('signup2');
}

// ── SIGNUP2 HELPERS ──
function signup2Back() {
  // Google/social users should go back to login, not signup1
  if (window._su2Method === 'social') {
    window._su2Method = null;
    goTo('login');
  } else {
    goTo('signup1');
  }
}
function signup2Skip() {
  // Save profileStepDone so we don't loop them back to signup2 on next login.
  // onboardingDone will be set when they complete or skip onboarding.
  if (window._currentUid && window._fbSetDoc) {
    window._fbSetDoc(window._currentUid, { profileStepDone: true }).catch(() => {});
  }
  currentQ = 0; selectedOpts = [null, null, null, null, null];
  goTo('ob-intro');
}

// ── TERMS CHECKBOX ──
function toggleTerms() {
  document.getElementById('su2TermsCb').classList.toggle('checked');
}

// ── CREATE ACCOUNT FINAL ──
async function createAccountFinal() {
  const termsChecked = document.getElementById('su2TermsCb').classList.contains('checked');
  if (!termsChecked) {
    const cb = document.getElementById('su2TermsCb');
    cb.style.border = '2px solid #ff6b6b';
    cb.style.boxShadow = '0 0 0 3px rgba(255,107,107,0.25)';
    cb.scrollIntoView({ behavior: 'smooth', block: 'center' });
    alert('Please agree to the Terms of Service to continue.');
    setTimeout(() => { cb.style.border = ''; cb.style.boxShadow = ''; }, 2500);
    return;
  }

  const name  = window._su2Name || '';
  const dob   = document.getElementById('su2Dob').value || null;
  const phone = (document.getElementById('su2Phone') || {}).value?.trim() || window._su2Phone || null;

  const btn = document.querySelector('#signup2 .nm-btn-gold');
  if (btn) { btn.textContent = 'Setting up…'; btn.disabled = true; }

  function _reset() { if(btn){ btn.textContent='Create Account →'; btn.disabled=false; } }

  // ── Already authenticated (Google, phone OTP, or email already created) ──
  // Just save the extra profile fields — never try to re-create the account.
  const user = auth.currentUser;
  if (user) {
    try {
      await window._fbSetDoc(user.uid, {
        uid: user.uid,
        displayName: name || user.displayName || '',
        email: user.email || null,
        phone: phone,
        dob: dob,
        signupMethod: window._su2Method || (user.providerData[0] && user.providerData[0].providerId) || 'unknown',
        isPro: false,
        profileStepDone: true,
        lastLogin: window._fbServerTimestamp()
      });
      _reset();
      currentQ = 0; selectedOpts = [null, null, null, null, null];
      goTo('ob-intro');
    } catch(e) {
      _reset();
      alert('Could not save your profile: ' + e.message);
    }
    return;
  }

  // ── No current user — session expired, send back to login ──
  _reset();
  alert('Your session expired. Please sign in again.');
  goTo('login');
}

// ── OTP SEND — Login via Phone ──
async function sendOtp() {
  const country = document.getElementById('phoneCountry').value;
  const phone   = document.getElementById('phoneInput').value.trim();
  if (!phone) return alert('Enter your phone number');
  const full = country + phone;
  const btn  = document.getElementById('btnSendOtp');
  const otpInput = document.getElementById('otpInput');
  if (_confirmationResult) {
    const code = otpInput.value.trim();
    if (!code) return alert('Enter the OTP you received');
    try {
      btn.textContent = 'Verifying…'; btn.disabled = true;
      await _confirmationResult.confirm(code);
      // OTP verified — onAuthStateChanged will navigate. Reset button as fallback.
      btn.textContent = 'Verified'; btn.disabled = true;
    } catch(e) {
      btn.textContent = 'Verify OTP'; btn.disabled = false;
      alert('Invalid OTP. Please check the code and try again.');
    }
    return;
  }
  try {
    btn.textContent = 'Sending…'; btn.disabled = true;
    _confirmationResult = await signInWithPhoneNumber(auth, full, _getRecaptcha('recaptcha-login'));
    if (otpInput) otpInput.closest('.glass-input-wrap') && (otpInput.closest('.glass-input-wrap').style.display='block');
    btn.textContent = 'Verify OTP'; btn.disabled = false;
    alert('OTP sent to ' + full);
  } catch(e) { btn.textContent = 'Send OTP'; btn.disabled = false; alert('Failed: ' + e.message); }
}

// ── ONBOARDING DATA ──
// ── FASHION (DARK CINEMATIC) QUESTIONS ──
const questions = [
  {
    label:'What Calls You',
    q:'What calls you to heal?',
    opts:['Voice & Vocal power','Inner calm & peace','Ancient wisdom & knowledge','Physical strength & vitality'],
    bg: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782622024/grok_image_1782621969038_uvugj1.jpg'
  },
  {
    label:'What Feels Broken',
    q:'What feels most out of balance?',
    opts:['My confidence & self-expression','My sleep & recovery','My focus & clarity','My relationships & connection'],
    bg: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777615898/grok_image_1777615621529_xdxfj6.jpg'
  },
  {
    label:'Your Signature Moment',
    q:'When do you meet yourself?',
    opts:['In the quiet of the morning','In the heat of midday','In the stillness of the night','Whenever the feeling comes'],
    bg: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777616006/grok_image_1777615631154_yddgyh.jpg'
  },
  {
    label:'Your Depth',
    q:'Where are you in your journey?',
    opts:['A seeker — just beginning','I have touched this before','I practice regularly','I want to go much deeper'],
    bg: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777748690/grok_image_1777748446479_lotpls.jpg'
  },
  {
    label:'Personalise Further',
    q:'What is your gender?',
    opts:['Male','Female'],
    bg: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777748597/grok_image_1777747756281_j10yta.jpg'
  }
];

// ── SIMPLE (NEUMORPHIC) QUESTIONS ──
const normalQuestions = [
  {
    label:'Your Healing Focus',
    q:'What do you most want to work on?',
    opts:['Body & Physical health','Mind & Mental clarity','Emotions & Relationships','Sleep & Deep rest']
  },
  {
    label:'Your Daily Challenge',
    q:"What's your biggest struggle right now?",
    opts:['Stress & Anxiety','Low energy & fatigue','Poor focus & distraction','Feeling disconnected']
  },
  {
    label:'Your Practice Time',
    q:'How much time can you give each day?',
    opts:['5 minutes — just a quick ritual','10-15 minutes — a proper session','30+ minutes — I go deep','Flexible — it varies']
  },
  {
    label:'Your Style',
    q:'How do you prefer to learn?',
    opts:['Listening — I absorb through sound','Reading — I understand through text','Doing — I learn by practising','Feeling — I go by intuition']
  },
  {
    label:'About You',
    q:'What is your gender?',
    opts:['Male','Female']
  }
];

let currentQ = 0;
let selectedOpts = [null, null, null, null, null];

// ── Normal onboarding state ──
let obnQ = 0;
let obnSelected = [null, null, null, null, null];

// ── OB-INTRO SCREEN HANDLERS ──
function goIntroYes() {
  renderQuestion();
  goTo('onboarding');
}
function goIntroNormal() {
  obnQ = 0;
  obnSelected = [null, null, null, null, null];
  obnRender();
  goTo('ob-normal');
}
function goIntroSkip() {
  window._obSkipped = true;
  localStorage.setItem('nwsb_ob_skipped', 'true');
  if (window.saveOnboardingAnswers) window.saveOnboardingAnswers([], true);
  goTo('profile-setup');
}

function renderQuestion() {
  const q = questions[currentQ];
  // Visual step: each of the 5 questions = its own step number
  const visualStep = currentQ + 1;
  const totalSteps = 5;
  document.getElementById('stepText').textContent = `Step ${visualStep} of ${totalSteps}`;
  document.getElementById('obQText').textContent = q.q;
  document.querySelector('.ob-q-label').textContent = q.label;
  document.getElementById('obProgress').style.width = `${((currentQ+1)/questions.length)*100}%`;

  // Per-question background — fade out, swap, fade in
  if (q.bg) {
    appBg.style.transition = 'opacity 0.25s ease';
    appBg.style.opacity = '0';
    setTimeout(() => {
      appBg.style.backgroundImage = `url('${q.bg}')`;
      appBg.style.backgroundPosition = 'center top';
      appBg.style.opacity = '1';
    }, 260);
  }

  // Tick marks — 5 ticks, one per question
  const tickIdx = currentQ;
  for (let i=0; i<5; i++) {
    const el = document.getElementById(`tick${i}`);
    if (el) el.className = 'ob-tick' + (i <= tickIdx ? ' done' : '');
  }

  // Gender question — horizontal rows like regular options, symbol on left
  const cont = document.getElementById('obOptions');
  cont.innerHTML = '';
  if (currentQ === 4) {
    cont.style.display = 'flex';
    cont.style.flexDirection = 'column';
    cont.style.gap = '12px';
    q.opts.forEach((opt, i) => {
      const div = document.createElement('div');
      const sel = selectedOpts[currentQ] === i;
      div.className = 'ob-option' + (sel ? ' selected' : '');
      div.innerHTML = `
        <div style="display:flex;align-items:center;gap:14px;">
          <span style="font-size:24px;line-height:1;color:${sel?'rgba(200,232,245,0.97)':'rgba(255,255,255,0.75)'};">${opt==='Male'?'♂':'♀'}</span>
          <span class="ob-option-text" style="font-size:13px;font-weight:500;letter-spacing:2px;text-transform:uppercase;">${opt}</span>
        </div>
        <div class="ob-option-check">
          ${sel ? `<svg width="10" height="8" viewBox="0 0 10 8" fill="none"><path d="M1 4L3.5 6.5L9 1" stroke="#07101f" stroke-width="1.8" stroke-linecap="square" fill="none"/></svg>` : ''}
        </div>`;
      div.onclick = () => selectOption(i);
      cont.appendChild(div);
    });
    // "Almost Complete" filler below gender buttons
    const filler = document.createElement('div');
    filler.style.cssText = 'margin-top:6px;padding:12px 4px 2px;text-align:center;';
    filler.innerHTML = `
      <div style="font-family:'Quattrocento Sans','DM Sans',sans-serif;font-size:16px;font-weight:500;color:rgba(255,255,255,0.75);letter-spacing:0.3px;line-height:1.4;">Your personalised Shabdapathy path is ready to be revealed.</div>`;
    cont.appendChild(filler);
  } else {
    cont.style.display = 'flex';
    cont.style.flexDirection = 'column';
    cont.style.gap = '12px';
    q.opts.forEach((opt, i) => {
      const div = document.createElement('div');
      div.className = 'ob-option' + (selectedOpts[currentQ] === i ? ' selected' : '');
      div.innerHTML = `
        <span class="ob-option-text">${opt}</span>
        <div class="ob-option-check">
          ${selectedOpts[currentQ] === i ? `<svg width="10" height="8" viewBox="0 0 10 8" fill="none"><path d="M1 4L3.5 6.5L9 1" stroke="#07101f" stroke-width="1.8" stroke-linecap="square" fill="none"/></svg>` : ''}
        </div>`;
      div.onclick = () => selectOption(i);
      cont.appendChild(div);
    });
  }
}

function selectOption(i) {
  selectedOpts[currentQ] = i;
  renderQuestion();
}

function prevQuestion() {
  if (currentQ > 0) {
    currentQ--;
    renderQuestion();
  } else {
    // Go back to signup2 if user came through signup flow (they have a method set)
    // Go back to login only if they somehow reached onboarding without signup
    if (window._su2Method) {
      goTo('signup2');
    } else {
      goTo('login');
    }
  }
}

function nextQuestion() {
  if (currentQ < questions.length - 1) {
    currentQ++;
    renderQuestion();
  } else {
    // Merge goal-A (q0) + goal-B (q1) answers, then routine (q2), level (q3), gender (q4)
    const goalA   = selectedOpts[0] !== null ? questions[0].opts[selectedOpts[0]] : 'Skipped';
    const goalB   = selectedOpts[1] !== null ? questions[1].opts[selectedOpts[1]] : null;
    const routine = selectedOpts[2] !== null ? questions[2].opts[selectedOpts[2]] : 'Skipped';
    const level   = selectedOpts[3] !== null ? questions[3].opts[selectedOpts[3]] : 'Skipped';
    const gender  = selectedOpts[4] !== null ? questions[4].opts[selectedOpts[4]] : 'Skipped';
    const goal    = goalB ? `${goalA}, ${goalB}` : goalA;
    // Store on window so finishOnboarding won't re-save with empty data
    window._onboardingAnswers = [goal, routine, level, gender];
    if (window.saveOnboardingAnswers) {
      window.saveOnboardingAnswers([goal, routine, level, gender], false);
    }
    localStorage.removeItem('nwsb_ob_skipped');
    goTo('profile-setup'); // → name + avatar step before analysis
  }
}

function skipOnboarding() {
  // Skip advances to the next question; on the last question it saves & goes to profile-setup
  if (currentQ < questions.length - 1) {
    currentQ++;
    renderQuestion();
  } else {
    window._obSkipped = true; // flag: user skipped all onboarding — bypass analysis
    localStorage.setItem('nwsb_ob_skipped', 'true');
    if (window.saveOnboardingAnswers) {
      window.saveOnboardingAnswers([], true);
    }
    goTo('profile-setup'); // → name + avatar step before analysis
  }
}

// ── NEUMORPHIC ONBOARDING (ob-normal) ──
function obnRender() {
  var q = normalQuestions[obnQ];
  var total = normalQuestions.length;
  document.getElementById('obnStepText').textContent = 'Step ' + (obnQ+1) + ' of ' + total;
  document.getElementById('obnLabel').textContent = q.label;
  document.getElementById('obnQText').textContent = q.q;
  document.getElementById('obnProgressFill').style.width = (((obnQ+1)/total)*100) + '%';

  var cont = document.getElementById('obnOptions');
  cont.innerHTML = '';
  q.opts.forEach(function(opt, i) {
    var sel = obnSelected[obnQ] === i;
    var div = document.createElement('div');
    div.className = 'obn-option' + (sel ? ' selected' : '');
    div.innerHTML =
      '<span>' + opt + '</span>' +
      '<div class="obn-check">' +
        (sel ? '<svg width="10" height="8" viewBox="0 0 10 8" fill="none"><path d="M1 4L3.5 6.5L9 1" stroke="#1a1a2e" stroke-width="2" stroke-linecap="round"/></svg>' : '') +
      '</div>';
    div.onclick = function() {
      obnSelected[obnQ] = i;
      obnRender();
    };
    cont.appendChild(div);
  });
  // Gender question sub-text
  if (obnQ === total - 1) {
    var note = document.createElement('div');
    note.style.cssText = 'text-align:center;margin-top:8px;font-family:\'DM Sans\',sans-serif;font-size:11px;color:rgba(0,0,0,0.35);';
    note.textContent = 'Helps personalise your word prescription.';
    cont.appendChild(note);
  }
}
function obnNext() {
  if (obnQ < normalQuestions.length - 1) {
    obnQ++;
    obnRender();
  } else {
    // Save answers and proceed
    var focus  = obnSelected[0] !== null ? normalQuestions[0].opts[obnSelected[0]] : 'Skipped';
    var challenge = obnSelected[1] !== null ? normalQuestions[1].opts[obnSelected[1]] : null;
    var time   = obnSelected[2] !== null ? normalQuestions[2].opts[obnSelected[2]] : 'Flexible';
    var style  = obnSelected[3] !== null ? normalQuestions[3].opts[obnSelected[3]] : 'Skipped';
    var gender = obnSelected[4] !== null ? normalQuestions[4].opts[obnSelected[4]] : 'Skipped';
    var goal   = challenge ? focus + ', ' + challenge : focus;
    window._onboardingAnswers = [goal, time, style, gender];
    if (window.saveOnboardingAnswers) window.saveOnboardingAnswers([goal, time, style, gender], false);
    localStorage.removeItem('nwsb_ob_skipped');
    goTo('profile-setup');
  }
}
function obnBack() {
  if (obnQ > 0) {
    obnQ--;
    obnRender();
  } else {
    goTo('ob-intro');
  }
}
function obnSkip() {
  if (obnQ < normalQuestions.length - 1) {
    obnQ++;
    obnRender();
  } else {
    window._obSkipped = true;
    localStorage.setItem('nwsb_ob_skipped', 'true');
    if (window.saveOnboardingAnswers) window.saveOnboardingAnswers([], true);
    goTo('profile-setup');
  }
}

// ── HERO HEADER ──
const HERO_IMGS = [
  'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto,w_900/v1776800798/grok_image_1776753853585_luk2yh.jpg',
  'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto,w_900/v1776800798/grok_image_1776754047350_m02pef.jpg',
  'https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto,w_900/v1778662189/image-84_bqpkid.jpg',
  'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto,w_900/v1776800798/grok_image_1776754188034_snzcgu.jpg',
  'https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto,w_900/v1778662207/image-202_yktk8y.jpg'
];
const HERO_WORDS = ['VIBRATION','FREQUENCIES','MIND','NEURONS','RESONANCE'];

const heroBgs   = [0,1,2,3,4].map(i => document.getElementById('hb'+i));
const heroCards = [0,1,2,3,4].map(i => document.getElementById('hc'+i));
const heroWEl   = document.getElementById('hwd');

heroBgs.forEach((el,i) => {
  el.style.backgroundImage = `url('${HERO_IMGS[i]}')`;
});
heroCards.forEach((c,i) => {
  c.style.backgroundImage = `url('${HERO_IMGS[i]}')`;
});

let heroCur = 0;
function heroActive(n) { heroCards.forEach((c,i) => c.classList.toggle('active', i===n)); }
heroActive(0);

function heroGo(n) {
  if (n === heroCur) return;
  heroBgs[heroCur].classList.remove('on');
  heroCur = n;
  heroBgs[heroCur].classList.add('on');
  heroActive(heroCur);

  const homeIsVisible = document.getElementById('home').classList.contains('active');

  if (homeIsVisible) {
    // Home is on screen — full animation as normal
    heroWEl.classList.add('hw-out');
    setTimeout(() => {
      heroWEl.textContent = HERO_WORDS[heroCur];
      heroWEl.classList.remove('hw-out');
      heroWEl.classList.add('hw-in');
      setTimeout(() => heroWEl.classList.remove('hw-in'), 360);
    }, 270);
  } else {
    // Home is hidden — swap silently, clean any stuck animation classes
    heroWEl.classList.remove('hw-out', 'hw-in');
    heroWEl.textContent = HERO_WORDS[heroCur];
  }
}
window._heroInterval = setInterval(() => {
  if (document.hidden) return; // don't composite full-screen crossfades while backgrounded
  if (window._heroLock !== null && window._heroLock !== undefined) return; // bg-mode one/two/none locks the carousel
  if (document.getElementById('home').classList.contains('active')) {
    heroGo((heroCur + 1) % 5);
  }
}, 4000);

// ── TAGLINE WORD CYCLER ──
const TAG_WORDS = ['VIBRATION','FREQUENCY','RESONANCE','AWAKENING','SOUND BIRTH'];
const tagEl = document.getElementById('tagWord');
let tagIdx = 0;
window._tagInterval = setInterval(() => {
  if (document.hidden) return;
  if (!document.getElementById('home').classList.contains('active')) return;
  tagIdx = (tagIdx + 1) % TAG_WORDS.length;
  tagEl.style.opacity = '0';
  tagEl.style.transform = 'translateY(8px)';
  tagEl.style.transition = 'opacity 0.25s ease, transform 0.25s ease';
  setTimeout(() => {
    tagEl.textContent = TAG_WORDS[tagIdx];
    tagEl.style.opacity = '1';
    tagEl.style.transform = 'translateY(0)';
  }, 260);
}, 2500);

// ── ANALYSIS ANIMATION ──
function startAnalysis() {
  const delays =     [300, 700, 1100, 1500, 1900];
  const doneDelays = [950, 1350, 1750, 2150, 2500];

  delays.forEach((d, i) => {
    setTimeout(() => {
      const el = document.getElementById(`ci${i}`);
      if (el) el.classList.add('visible');
    }, d);
  });
  doneDelays.forEach((d, i) => {
    setTimeout(() => {
      const el = document.getElementById(`cd${i}`);
      if (el) el.classList.add('show');
    }, d);
  });

  const numEl = document.getElementById('ringNum');
  if (!numEl) return;
  // Clear any previous interval to prevent stacking on re-entry
  if (window._analysisInterval) { clearInterval(window._analysisInterval); window._analysisInterval = null; }
  numEl.textContent = '0%';
  let count = 0;
  window._analysisInterval = setInterval(() => {
    count += 2;
    if (count >= 100) {
      count = 100; clearInterval(window._analysisInterval); window._analysisInterval = null;
      setTimeout(() => {
        const btn = document.getElementById('startJourneyBtn');
        if (btn) btn.style.display = 'block';
        const hint = document.getElementById('scrollHint');
        if (hint) hint.style.display = 'none';
      }, 500);
    }
    numEl.textContent = count + '%';
  }, 56);
}

// ── PWA SERVICE WORKER (enables offline + installability) ──
if ('serviceWorker' in navigator) {
  // updateViaCache:'none' → the SW script is ALWAYS re-fetched from the network,
  // never the 24h HTTP cache. This breaks the "stale service worker" trap where
  // an old cache-first SW keeps serving outdated CSS/JS no matter how many times
  // we ship a fix.
  navigator.serviceWorker.register('./sw.js', { updateViaCache: 'none' }).then(reg => {
    try { reg.update(); } catch (e) {}
    // When a freshly-installed SW takes control, reload once so the page is
    // running the new HTML/CSS/JS instead of whatever the old SW had cached.
    var refreshing = false;
    navigator.serviceWorker.addEventListener('controllerchange', function () {
      if (refreshing) return;
      refreshing = true;
      location.reload();
    });
  }).catch(err => {
    console.info('PWA service worker not registered:', err.message);
  });
}

// ── PWA INSTALL PROMPT capture ──
// No auto popup — the native browser prompt is captured (also pre-captured by
// the early <head> listener into window._bipEvent) and only fired when the
// user taps "Download App".
let deferredInstallPrompt = window._bipEvent || null;
window.addEventListener('beforeinstallprompt', e => {
  e.preventDefault();
  deferredInstallPrompt = e;
  window._bipEvent = e;
});
// helper: the freshest available prompt (head listener may have caught it first)
function _getInstallPrompt() { return deferredInstallPrompt || window._bipEvent || null; }

// ── DETECT iOS SAFARI ──
function isIOS() {
  return /iphone|ipad|ipod/i.test(navigator.userAgent) && !window.MSStream;
}
function isInStandaloneMode() {
  return (('standalone' in window.navigator) && window.navigator.standalone) ||
         window.matchMedia('(display-mode: standalone)').matches ||
         window.matchMedia('(display-mode: fullscreen)').matches;
}

// ── DOWNLOAD POPUP ──
function openDlPopup() {
  const overlay  = document.getElementById('dlOverlay');
  const viewInstall = document.getElementById('dlViewInstall');
  const viewIOS  = document.getElementById('dlViewIOS');

  if (isIOS() && !isInStandaloneMode()) {
    viewInstall.style.display = 'none';
    viewIOS.style.display     = 'block';
  } else {
    viewInstall.style.display = 'block';
    viewIOS.style.display     = 'none';
    // Keep the label as "Download App" regardless of native-prompt availability
    if (!_getInstallPrompt()) {
      const btn = document.getElementById('dlInstallBtn');
      btn.innerHTML = `<svg width="16" height="16" viewBox="0 0 16 16" fill="none"><path d="M8 2V11M8 11L5 8M8 11L11 8" stroke="#07101f" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/><path d="M2 14H14" stroke="#07101f" stroke-width="1.6" stroke-linecap="round"/></svg> Download App`;
    }
  }

  overlay.style.display = 'flex';
  requestAnimationFrame(() => requestAnimationFrame(() => overlay.classList.add('open')));
}

function showManualInstallInstructions() {
  // No native prompt (or it failed) — show platform-specific manual instructions
  // instead of leaving the button doing nothing.
  const viewInstall = document.getElementById('dlViewInstall');
  const viewIOS = document.getElementById('dlViewIOS');
  if (viewInstall) viewInstall.style.display = 'none';
  if (viewIOS) {
    if (!isIOS()) {
      // Android Chrome: update step text to match Chrome menu
      const steps = viewIOS.querySelectorAll('.dl-step-text');
      if (steps[0]) steps[0].innerHTML = 'Tap the <strong style="color:#c8a96e">⋮ menu</strong> in the top-right of Chrome';
      if (steps[1]) steps[1].innerHTML = 'Tap <strong style="color:#c8a96e">"Add to Home screen"</strong> then tap <strong style="color:#c8a96e">"Add"</strong>';
      const title = viewIOS.querySelector('.dl-title');
      if (title) title.textContent = 'Add to Home Screen';
    }
    viewIOS.style.display = 'block';
  }
}

// Wait up to `ms` for the native install prompt to arrive (it often fires a
// beat AFTER page load, so a tap right away would otherwise see nothing).
function _waitForInstallPrompt(ms) {
  return new Promise(resolve => {
    const now = _getInstallPrompt();
    if (now) return resolve(now);
    let done = false;
    const onBip = e => { if (done) return; done = true; window._bipEvent = e; deferredInstallPrompt = e; cleanup(); resolve(e); };
    const cleanup = () => window.removeEventListener('beforeinstallprompt', onBip);
    window.addEventListener('beforeinstallprompt', onBip);
    setTimeout(() => { if (done) return; done = true; cleanup(); resolve(_getInstallPrompt()); }, ms);
  });
}

async function triggerInstall() {
  // Already installed → nothing to download.
  if (isInStandaloneMode()) { showManualInstallInstructions(); return; }
  let prompt = _getInstallPrompt();
  if (!prompt && !isIOS()) {
    // give the browser a moment to hand us the prompt before falling back
    const btn = document.getElementById('dlInstallBtn');
    const prev = btn ? btn.innerHTML : '';
    if (btn) { btn.innerHTML = 'Preparing…'; btn.disabled = true; }
    prompt = await _waitForInstallPrompt(2500);
    if (btn) { btn.innerHTML = prev; btn.disabled = false; }
  }
  if (prompt) {
    try {
      prompt.prompt();                                   // ← fires the native install dialog directly
      const { outcome } = await prompt.userChoice;
      deferredInstallPrompt = null; window._bipEvent = null;
      if (outcome === 'accepted') closeDlSheet();
      // outcome === 'dismissed' — the native dialog worked; user said no. Fine.
    } catch (e) {
      deferredInstallPrompt = null; window._bipEvent = null;
      showManualInstallInstructions();
    }
  } else {
    // Browser genuinely isn't offering the one-tap install (already dismissed,
    // engagement heuristics, or an in-app browser) — manual is the only path.
    showManualInstallInstructions();
  }
}

function closeDlSheet() {
  const overlay = document.getElementById('dlOverlay');
  overlay.style.opacity = '0';
  overlay.style.transition = 'opacity 0.22s ease';
  setTimeout(() => {
    overlay.style.display = 'none';
    overlay.style.opacity = '';
    overlay.style.transition = '';
    overlay.classList.remove('open');
  }, 230);
}

function closeDlPopup(e) {
  if (e && e.target !== document.getElementById('dlOverlay')) return;
  closeDlSheet();
}
// ── PWA installed event ──
window.addEventListener('appinstalled', () => {
  closeDlSheet();
  localStorage.setItem('pwaPopupDismissed', '1');
  deferredInstallPrompt = null;
});

// ── HAMBURGER MENU ──
function openMenu() {
  document.getElementById('menuOverlay').classList.add('open');
  var drawer = document.getElementById('menuDrawer');
  drawer.classList.add('open');
  // Explicit kick tied directly to the actual open action — same pattern as
  // meaning-store's banner video. preload="metadata" + autoplay isn't
  // reliably enough on its own to start playback for a video that's been
  // sitting off-screen (translateX) since page load; this guarantees it.
  var vid = drawer.querySelector('video');
  if (vid) { vid.muted = true; vid.play().catch(function () {}); }
}
function closeMenu() {
  document.getElementById('menuOverlay').classList.remove('open');
  document.getElementById('menuDrawer').classList.remove('open');
}
// NowssB Connect intro — pops ONCE per session, and only via the Fashion-home
// Connect section (which is the only caller). Any later tap goes straight in.
function openConnectIntro() {
  var ov = document.getElementById('connectIntro');
  if (!ov || window._connectIntroSeen) { if (window.IG) IG.nav('profile'); return; }
  window._connectIntroSeen = true;
  ov.style.display = 'flex';
  ov.style.pointerEvents = 'all';
  requestAnimationFrame(function() { requestAnimationFrame(function() { ov.style.opacity = '1'; }); });
}
function connectIntroEnter() {
  var ov = document.getElementById('connectIntro');
  if (ov) {
    ov.style.opacity = '0';
    setTimeout(function() { ov.style.display = 'none'; ov.style.pointerEvents = 'none'; }, 440);
  }
  if (window.IG) IG.nav('profile');
}

// ── SUB-SCREENS ──
function applyHealthGenderHighlight(gender) {
  const mCard = document.getElementById('gsel-card-male');
  const fCard = document.getElementById('gsel-card-female');
  if (!mCard || !fCard) return;
  mCard.classList.remove('for-you','other-gender');
  fCard.classList.remove('for-you','other-gender');
  if (!gender) return;
  const g = gender.toLowerCase();
  if (g === 'male') { mCard.classList.add('for-you'); fCard.classList.add('other-gender'); }
  else if (g === 'female') { fCard.classList.add('for-you'); mCard.classList.add('other-gender'); }
}

function openSub(id) {
  document.getElementById('sub-' + id).classList.add('open');
  if (id === 'health-journey') {
    if (window._userGender !== undefined) {
      applyHealthGenderHighlight(window._userGender);
    } else if (window._currentUid) {
      window._userGender = null;
      applyHealthGenderHighlight(null);
      import("https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js").then(({ getFirestore, doc, getDoc }) => {
        import("https://www.gstatic.com/firebasejs/11.8.1/firebase-app.js").then(({ getApp }) => {
          try {
            const db2 = getFirestore(getApp());
            getDoc(doc(db2, "users", window._currentUid)).then(snap => {
              if (snap.exists()) { window._userGender = snap.data().gender || null; applyHealthGenderHighlight(window._userGender); }
            }).catch(()=>{});
          } catch(e) {}
        }).catch(()=>{});
      }).catch(()=>{});
    }
  }
  if (id === 'word-science') initLetterChips();
  if (id === 'real-meaning') {
    if (typeof shouldShowIntro === 'function' && !shouldShowIntro('word-store')) {
      setTimeout(function() {
        var intro = document.getElementById('rmIntroPage');
        if (intro) intro.classList.add('rm-intro-hidden');
        if (typeof window.rmEnterFromIntro === 'function') window.rmEnterFromIntro();
      }, 100);
    }
  }
  if (id === 'meaning-store') {
    if (typeof shouldShowIntro === 'function' && !shouldShowIntro('meaning-store')) {
      setTimeout(function() {
        if (typeof window.msEnterFromIntro === 'function') window.msEnterFromIntro();
      }, 100);
    }
    setTimeout(msRenderStore, 80);
    setTimeout(msInitParallax, 200);
    // Kick video playback on mobile (autoplay blocked until user gesture)
    var msVid = document.getElementById('msBannerImg');
    if (msVid) { msVid.muted = true; msVid.play().catch(function(){}); }
  }
  if (id === 'practice') {
    // Load active routine words if not manually set
    if (!window._rtManualLaunch) {
      const ar = getActiveRoutine();
      if (ar && typeof loadRoutineWords === 'function') loadRoutineWords(ar);
    }
    window._rtManualLaunch = false;
    // Reset state on each open
    _pwIdx = 0; _pwRepCount = 0; _pwRepTarget = 7;
    _pwSteps = new Set(); _pwPlaying = false; _pwDone = false; _pwMode = 'listen';
    if ('speechSynthesis' in window) window.speechSynthesis.cancel();
    if (window._pwShowIntro && (typeof shouldShowIntro !== 'function' || shouldShowIntro('practice'))) {
      window._pwShowIntro = false;
      setTimeout(renderPracticeIntro, 80);
    } else {
      window._pwShowIntro = false;
      setTimeout(renderPractice, 80);
    }
  }
}
function closeSub(id) {
  // Cancel any pending coach so it doesn't fire on the screen you just left
  if (window._pgTimer) { clearTimeout(window._pgTimer); window._pgTimer = null; }
  if (typeof window._pgTimerToken !== 'undefined') window._pgTimerToken++;
  if (typeof pgClose === 'function') pgClose(false);
  document.getElementById('sub-' + id).classList.remove('open');
  // Reset real-meaning intro so it shows again next time
  if (id === 'real-meaning') {
    setTimeout(() => {
      const intro = document.getElementById('rmIntroPage');
      const main  = document.getElementById('rmMainContent');
      const dv    = document.getElementById('rmDetailView');
      const lc    = document.getElementById('rmLibraryContent');
      const fc    = document.getElementById('rmFeatureCard');
      const mp    = document.getElementById('rmMeaningPanel');
      const sp    = document.getElementById('rmSoundPanel');
      const bg    = document.getElementById('rmBg');
      // Restore intro / hide main
      if (intro) { intro.classList.remove('rm-intro-hidden'); intro.style.opacity = ''; intro.style.pointerEvents = ''; }
      if (main)  main.style.display = 'none';
      // Fix: reset detail/library views so next open starts from library
      if (dv) dv.style.display = 'none';
      if (lc) lc.style.display = 'block';
      // Fix: restore panels (not strictly needed now, but keeps state clean)
      if (fc) fc.style.display = '';
      if (mp) mp.style.display = '';
      if (sp) sp.style.display = '';
      // Clear background
      if (bg) bg.style.backgroundImage = '';
      // Reset new detail elements
      var rmdBanner = document.getElementById('rmdBannerImg');
      var rmdChar   = document.getElementById('rmdCharImg');
      if (rmdBanner) rmdBanner.src = '';
      if (rmdChar)   { rmdChar.src = ''; rmdChar.style.opacity = '0'; }
      window._rmdCurrentKey  = null;
      window._rmdCurrentWord = null;
    }, 500);
  }
  if (id === 'meaning-store') {
    setTimeout(function() {
      var intro = document.getElementById('msIntroPage');
      var mc    = document.getElementById('msMcontent');
      var dp    = document.getElementById('msDetailPanel');
      if (intro) { intro.classList.remove('ms-intro-hidden'); }
      if (mc)    { mc.style.display = 'none'; }
      if (dp)    { dp.classList.remove('open'); }
    }, 500);
  }
}

// ── WORD SCIENCE LETTER CHIPS ──
const LETTERS = [
  { l:'N', m:'Nature',   d:'N represents the natural breath — the first sound expelled at birth. It activates the nasal resonance chamber and connects to the nervous system and neurological clarity.' },
  { l:'O', m:'Origin',   d:'O is the circular, open vowel of creation. Found in every language as a sound of recognition and wholeness. Resonates with the heart and thoracic cavity.' },
  { l:'W', m:'Water',    d:'W mirrors the waveform of water in motion. Its labial formation activates salivary glands, digestive initiation, and cellular hydration at a vibrational level.' },
  { l:'S', m:'Sound',    d:'S is the sibilant of the sun and wind — universal across civilizations. It stimulates the solar plexus, activates adrenal clarity and metabolic function.' },
  { l:'B', m:'Body',     d:'B is the plosive of birth — the closing of lips and sudden release mirrors the moment of first breath. Activates the lungs and bronchial pathways.' },
  { l:'A', m:'Air',      d:'A is the open throat — the most universally shared vowel. It activates the vocal cords, thyroid gland, and upper respiratory resonance.' },
  { l:'N', m:'Neural',   d:'Second N deepens the neural activation pattern, creating a looping resonance between the initial sound and the brain\'s language centers.' },
  { l:'S', m:'Silence',  d:'Second S completes the vibrational arc — the settling of sound into silence, where healing integration takes place at the cellular level.' },
  { l:'I', m:'Intention', d:'I is the forward, pointed vowel of intention and will. It activates the prefrontal cortex and pineal gland — the seat of conscious direction.' },
  { l:'U', m:'Universe', d:'U is the deep, resonant vowel of the universe itself — found in sacred syllables across Sanskrit, Sumerian and indigenous traditions worldwide.' }
];
let initedLetters = false;
function initLetterChips() {
  if (initedLetters) return;
  initedLetters = true;
  const row = document.getElementById('letterRow');
  LETTERS.forEach((item, i) => {
    const chip = document.createElement('div');
    chip.className = 'letter-chip';
    chip.innerHTML = `<span class="letter-chip-letter">${item.l}</span><span class="letter-chip-meaning">${item.m}</span>`;
    chip.onclick = () => {
      document.querySelectorAll('.letter-chip').forEach(c => c.classList.remove('active-chip'));
      chip.classList.add('active-chip');
      document.getElementById('letterDetail').innerHTML = `<div class="letter-detail-title">${item.l} — ${item.m}</div><div class="letter-detail-text">${item.d}</div>`;
    };
    row.appendChild(chip);
  });
}

// ── KNOW THE REAL MEANING — cycling questions ──
const KRM_QUESTIONS = [
  'Why is <em>Earth</em> called Earth?',
  'Why is <em>Water</em> called Water?',
  'Why is <em>God</em> called God?',
  'Why is <em>Fire</em> called Fire?',
  'What does your <em>Name</em> really mean?',
  'Why is <em>Mother</em> called Mother?',
  'Why is <em>Sun</em> called Sun?',
  'What is <em>Love</em> at its root?',
  'Why is your <em>Country</em> named that?',
  'What does <em>Soul</em> really mean?',
];
let krmQIdx = 0;
const krmQEl = document.getElementById('krmQuestion');
if (krmQEl) {
  setInterval(() => {
    krmQIdx = (krmQIdx + 1) % KRM_QUESTIONS.length;
    krmQEl.classList.add('krm-q-out');
    setTimeout(() => {
      krmQEl.innerHTML = KRM_QUESTIONS[krmQIdx];
      krmQEl.classList.remove('krm-q-out');
      krmQEl.classList.add('krm-q-in');
      setTimeout(() => krmQEl.classList.remove('krm-q-in'), 360);
    }, 250);
  }, 3200);
}

// ── FOOTER 3D CAROUSEL — factory so both the Fashion and normal home footers
// (each with their own ids) can run an independent instance. ──
function _nwsbSetupFooterCarousel(carouselId, bgImgId) {
  var active = 0, autoT = null, items, dots, N;
  var bgEl = null; // footer bg image element

  // Image URLs in same order as .fci cards
  var IMGS = [
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934919/grok_image_1776931241446_2_oqn7z0.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934919/grok_image_1776931251298_2_nuhjin.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934919/grok_image_1776931991083_2_eyvogv.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934919/grok_image_1776932343988_3_bofj1s.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934919/grok_image_1776931659181_2_l3dxyi.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934919/grok_image_1776931253654_2_hrtsra.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934920/grok_image_1776932830246_2_x0yyb6.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934921/grok_image_1776933033268_2_m3fmo9.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934921/grok_image_1776932933365_2_jb1lch.jpg',
    'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776934921/grok_image_1776932486772_2_spplq4.jpg'
  ];

  function updateBg(idx) {
    if (!bgEl) return;
    bgEl.style.backgroundImage = 'url("' + IMGS[idx] + '")';
  }

  function cfg(s) {
    var a = Math.abs(s), d = s < 0 ? -1 : 1;
    if (a===0) return {tx:0,      tz:200,  ry:0,     sc:1.00, op:1.00, zi:20};
    if (a===1) return {tx:d*172,  tz:-10,  ry:d*-28, sc:0.78, op:0.68, zi:15};
    if (a===2) return {tx:d*292,  tz:-155, ry:d*-50, sc:0.55, op:0.36, zi:10};
    if (a===3) return {tx:d*362,  tz:-285, ry:d*-65, sc:0.34, op:0.12, zi:5};
    return           {tx:0,      tz:-600, ry:0,     sc:0.10, op:0.00, zi:0};
  }

  function paint() {
    items.forEach(function(el, i) {
      var off = ((i - active) % N + N) % N;
      var s = off > Math.floor(N/2) ? off - N : off;
      var c = cfg(s);
      el.style.transform     = 'translateX('+c.tx+'px) translateZ('+c.tz+'px) rotateY('+c.ry+'deg) scale('+c.sc+')';
      el.style.opacity       = c.op;
      el.style.zIndex        = c.zi;
      el.style.pointerEvents = c.op > 0.05 ? 'auto' : 'none';
    });
    dots.forEach(function(d,i){ d.classList.toggle('active', i===active); });
    updateBg(active);
  }

  function go(n) { active=((n%N)+N)%N; paint(); }
  function startAuto() { clearInterval(autoT); autoT=setInterval(function(){go(active+1);},2800); }

  function init() {
    var carousel = document.getElementById(carouselId);
    if (!carousel) return;
    bgEl = document.getElementById(bgImgId);
    items = Array.from(carousel.querySelectorAll('.fci'));
    dots  = Array.from(carousel.querySelectorAll('.fcd'));
    N = items.length;
    if (!N) return;

    // Set initial bg
    updateBg(0);

    items.forEach(function(el) {
      el.style.transition = 'none';
      el.style.transform  = 'translateX(0px) translateZ(-600px) rotateY(0deg) scale(0.1)';
      el.style.opacity    = '0';
    });

    void carousel.offsetHeight;

    requestAnimationFrame(function() {
      requestAnimationFrame(function() {
        var T = 'transform 0.78s cubic-bezier(0.34,1.08,0.64,1),opacity 0.78s ease,box-shadow 0.78s ease';
        items.forEach(function(el){ el.style.transition = T; });
        paint();
        startAuto();
      });
    });

    items.forEach(function(el,i){
      el.addEventListener('click', function(e){
        if (i!==active){ e.stopPropagation(); go(i); startAuto(); }
      });
    });

    var tx0=0;
    carousel.addEventListener('touchstart',function(e){tx0=e.touches[0].clientX;},{passive:true});
    carousel.addEventListener('touchend',function(e){
      var dx=e.changedTouches[0].clientX-tx0;
      if(Math.abs(dx)>44){go(active+(dx<0?1:-1));startAuto();}
    },{passive:true});
  }

  setTimeout(init, 5200);
}
_nwsbSetupFooterCarousel('footerCarousel', 'footerBgImg');
_nwsbSetupFooterCarousel('footerCarouselNm', 'footerBgImgNm');

function krmSearch() {
  const val = document.getElementById('krmInput').value.trim().toLowerCase();
  if (!val) return;
  openSub('real-meaning');
  setTimeout(() => {
    rmSkipIntro();
    document.getElementById('rmSearchInput').value = val;
    loadWordOrigin(val);
  }, 120);
}


// ── INTRO → MAIN transition ──
function rmEnterFromIntro() {
  var intro = document.getElementById('rmIntroPage');
  var main  = document.getElementById('rmMainContent');
  if (intro) { intro.style.opacity = '0'; intro.style.pointerEvents = 'none'; setTimeout(function(){ intro.classList.add('rm-intro-hidden'); }, 350); }
  if (main)  { main.style.display = 'flex'; }
  nssVidBannerCycle();
  rmStoreBgSync();
}
function rmSkipIntro() {
  var intro = document.getElementById('rmIntroPage');
  var main  = document.getElementById('rmMainContent');
  if (intro) intro.classList.add('rm-intro-hidden');
  if (main)  main.style.display = 'flex';
  nssVidBannerCycle();
  rmStoreBgSync();
}

// Word Atelier's own backdrop — same custom Fashion background the user
// picked (via the header's customize icon, which just opens the existing
// Fashion Background picker), or left as the plain default if none is set
// yet. #rmBg already carries the app-wide .sub-screen-bg dark gradient
// overlay, so only the image itself needs setting here.
function rmStoreBgSync() {
  var bg = document.getElementById('rmBg');
  if (!bg) return;
  var custom = null;
  try { custom = localStorage.getItem('nwsb_fashion_bg_custom'); } catch (e) {}
  if (custom === '__black__') {
    bg.style.backgroundImage = 'none';
    bg.style.backgroundColor = '#000';
  } else if (custom) {
    bg.style.backgroundImage = "url('" + custom + "')";
    bg.style.backgroundColor = '';
  } else {
    bg.style.backgroundImage = '';
    bg.style.backgroundColor = '';
  }
}

// Video banner text — icon stays fixed, only the tagline cycles (same
// dash-in-from-right treatment as the home Shop Now banner's word).
var NSS_VID_BANNER_TAGLINES = ['Buy Words', 'Request Words', 'Build Your Library', 'Heal with Sound'];
var _nssVidBannerTimer = null;
function nssVidBannerCycle() {
  var el = document.getElementById('nssVidBannerText');
  if (!el || _nssVidBannerTimer) return;
  var idx = 0;
  function paint() {
    el.textContent = NSS_VID_BANNER_TAGLINES[idx % NSS_VID_BANNER_TAGLINES.length];
    el.classList.remove('dash-in');
    void el.offsetWidth;
    el.classList.add('dash-in');
    idx++;
  }
  paint();
  _nssVidBannerTimer = setInterval(paint, 3000);
}

// ── WORD ORIGINS: TIER DEFINITIONS ──
const RM_TIERS = {
  basic_a: {
    price: '$0.80', priceVal: 80, origPrice: null, discount: null,
    banners: [
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778971604/ffec7380-516c-11f1-9b86-d16f5852128e_1_xdqlio.png',
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778971603/ffc4a030-516c-11f1-9b86-d16f5852128e_oahwvn.png'
    ]
  },
  basic_b: {
    price: '$0.80', priceVal: 80, origPrice: null, discount: null,
    banners: [
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778971513/7bb6c750-516c-11f1-9b86-d16f5852128e_appn0v.png',
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778971513/7bb519a0-516c-11f1-9b86-d16f5852128e_1_lnqxkr.png'
    ]
  },
  discount_40: {
    price: '$0.40', priceVal: 40, origPrice: '$0.80', discount: '50% off',
    banners: [
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778971512/ffbb0340-516c-11f1-9b86-d16f5852128e_ekdtma.png'
    ]
  },
  standard_50: {
    price: '$0.50', priceVal: 50, origPrice: '$1.00', discount: '50% off',
    banners: [
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778971513/7bb17020-516c-11f1-9b86-d16f5852128e_1_bbzls6.png'
    ]
  },
  premium_140: {
    price: '$1.40', priceVal: 140, origPrice: '$2.00', discount: '30% off',
    banners: [
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778972614/a3447b70-516f-11f1-9b86-d16f5852128e_q0eye7.png',
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778972781/a345db00-516f-11f1-9b86-d16f5852128e_s3mxiu.png',
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778973115/5c8e9a00-517c-11f1-a3dd-d923e87f1895_qggn8o.png',
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778972614/fd7c24e0-516e-11f1-9b86-d16f5852128e_bticry.png',
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778972614/c36f0950-517a-11f1-9d12-25df0fdf84f2_jwiys1.png',
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/f_auto,q_auto/v1778972614/a7215cf0-516e-11f1-9b86-d16f5852128e_edvhiv.png'
    ]
  },
  // ── ELITE TIERS — $1.00 each, unique banner per word ──
  elite_spirit:   { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/46d6afc0-517e-11f1-9c9e-43067f971164_l7lezo.png'] },
  elite_life:     { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/411c2a10-517e-11f1-9c9e-43067f971164_cdezmw.png'] },
  elite_death:    { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/411c7830-517e-11f1-9c9e-43067f971164_qzbtnk.png'] },
  elite_power:    { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/480348e0-517e-11f1-9c9e-43067f971164_1_uiieto.png'] },
  elite_star:     { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/49427fa0-517e-11f1-9c9e-43067f971164_1_qlepve.png'] },
  elite_dream:    { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/411c5120-517e-11f1-9c9e-43067f971164_igwnf1.png'] },
  elite_voice:    { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974062/ae3d15c0-516d-11f1-9b86-d16f5852128e_1_v9xplj.png'] },
  elite_heart:    { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974062/4d2f7140-517e-11f1-9c9e-43067f971164_kcheth.png'] },
  elite_peace:    { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974062/4b208e70-517e-11f1-9c9e-43067f971164_tcsrzl.png'] },
  elite_wisdom:   { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974063/b2064b60-5170-11f1-9b86-d16f5852128e_bo7cug.png'] },
  elite_strength: { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974063/b2067270-5170-11f1-9b86-d16f5852128e_ajcacg.png'] },
  elite_grace:    { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974064/f1849ab0-517c-11f1-9c9e-43067f971164_gyqpko.png'] },
  elite_freedom:  { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974065/f185ac20-517c-11f1-9c9e-43067f971164_vfyfa0.png'] },
  elite_karma:    { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974067/ffbb0340-516c-11f1-9b86-d16f5852128e_aavqzy.png'] },
  elite_energy:   { price: '$1.00', priceVal: 100, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/411c2a10-517e-11f1-9c9e-43067f971164_cdezmw.png'] },
  // ── SIGNATURE TIERS — $2.99, the most expensive word in each category.
  // One per category section (see part010.js's SIGNATURE map) — every
  // signature word shares the same gold NowssB product shot as its image. ──
  sig_off50:    { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_elements: { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_sacred:   { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_identity: { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_cosmos:   { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_nature:   { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_family:   { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_elite:    { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_premium:  { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_mythical: { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_warriors: { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_ancient:  { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_peace:    { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_white:    { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] },
  sig_black:    { price: '$2.99', priceVal: 299, origPrice: null, discount: null, banners: ['https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto/v1784438406/file_00000000d39081faa073bf17312d89fc_q9ehat.png'] }
};

// ── SIGNATURE WORDS — display-name overrides (loadWordOrigin only
// auto-capitalizes the first letter, which breaks for these multi-word
// names) and their tier mapping. Keys/names/images mirror part010.js's
// SIGNATURE map — keep both in sync if a category is added or removed. ──
const RM_DISPLAY_NAME = {
  sale: 'Sale', elements: 'Elements', sacreddivine: 'Sacred Divine', identitymind: 'Identity Mind',
  cosmostime: 'Cosmos Time', natureforest: 'Nature Forest', familylove: 'Family Love',
  elitesovereign: 'Elite Sovereign', premiumexclusive: 'Premium Exclusive', mythicaledition: 'Mythical Edition',
  warriorsedition: 'Warriors Edition', ancientcivilizations: 'Ancient Civilizations', peaceedition: 'Peace Edition',
  whiteedition: 'White Edition', blackedition: 'Black Edition'
};
const RM_SIGNATURE_TIER = {
  sale: 'sig_off50', elements: 'sig_elements', sacreddivine: 'sig_sacred', identitymind: 'sig_identity',
  cosmostime: 'sig_cosmos', natureforest: 'sig_nature', familylove: 'sig_family', elitesovereign: 'sig_elite',
  premiumexclusive: 'sig_premium', mythicaledition: 'sig_mythical', warriorsedition: 'sig_warriors',
  ancientcivilizations: 'sig_ancient', peaceedition: 'sig_peace', whiteedition: 'sig_white', blackedition: 'sig_black'
};

// ── ELITE WORDS — each has its own single banner ──
const RM_ELITE = [
  { key:'elite1',  banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/46d6afc0-517e-11f1-9c9e-43067f971164_l7lezo.png' },
  { key:'elite2',  banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/411c2a10-517e-11f1-9c9e-43067f971164_cdezmw.png' },
  { key:'elite3',  banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/411c7830-517e-11f1-9c9e-43067f971164_qzbtnk.png' },
  { key:'elite4',  banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/480348e0-517e-11f1-9c9e-43067f971164_1_uiieto.png' },
  { key:'elite5',  banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/49427fa0-517e-11f1-9c9e-43067f971164_1_qlepve.png' },
  { key:'elite6',  banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/411c7830-517e-11f1-9c9e-43067f971164_qzbtnk.png' },
  { key:'elite7',  banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974061/411c5120-517e-11f1-9c9e-43067f971164_igwnf1.png' },
  { key:'elite8',  banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974062/ae3d15c0-516d-11f1-9b86-d16f5852128e_1_v9xplj.png' },
  { key:'elite9',  banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974062/4d2f7140-517e-11f1-9c9e-43067f971164_kcheth.png' },
  { key:'elite10', banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974062/4b208e70-517e-11f1-9c9e-43067f971164_tcsrzl.png' },
  { key:'elite11', banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974063/b2064b60-5170-11f1-9b86-d16f5852128e_bo7cug.png' },
  { key:'elite12', banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974063/b2067270-5170-11f1-9b86-d16f5852128e_ajcacg.png' },
  { key:'elite13', banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974064/f1849ab0-517c-11f1-9c9e-43067f971164_gyqpko.png' },
  { key:'elite14', banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974065/f185ac20-517c-11f1-9c9e-43067f971164_vfyfa0.png' },
  { key:'elite15', banner:'https://res.cloudinary.com/ds15pgoy2/image/upload/q_auto/f_auto/v1778974067/ffbb0340-516c-11f1-9b86-d16f5852128e_aavqzy.png' }
];

// ── WORD → TIER MAPPING ──
const RM_WORD_TIER = {
  // Basic $0.80 — Set A
  earth:    'basic_a',
  water:    'basic_a',
  time:     'basic_a',
  sky:      'basic_a',
  tree:     'basic_a',
  river:    'basic_a',
  // Basic $0.80 — Set B
  fire:     'basic_b',
  sun:      'basic_b',
  moon:     'basic_b',
  space:    'basic_b',
  wind:     'basic_b',
  sea:      'basic_b',
  // Discount $0.80 → $0.40 (50% off)
  god:      'discount_40',
  soul:     'discount_40',
  dark:     'discount_40',
  stone:    'discount_40',
  rain:     'discount_40',
  // Standard $1.00 → $0.50 (50% off)
  love:     'standard_50',
  truth:    'standard_50',
  light:    'standard_50',
  mother:   'standard_50',
  father:   'standard_50',
  child:    'standard_50',
  king:     'standard_50',
  // Premium $2.00 → $1.40 (30% off)
  name:     'premium_140',
  mind:     'premium_140',
  india:    'premium_140',
  breath:   'premium_140',
  blood:    'premium_140',
  woman:    'premium_140',
  man:      'premium_140',
  // Elite $1.00 — unique banners
  spirit:   'elite_spirit',
  life:     'elite_life',
  death:    'elite_death',
  power:    'elite_power',
  star:     'elite_star',
  dream:    'elite_dream',
  voice:    'elite_voice',
  heart:    'elite_heart',
  peace:    'elite_peace',
  wisdom:   'elite_wisdom',
  strength: 'elite_strength',
  grace:    'elite_grace',
  freedom:  'elite_freedom',
  karma:    'elite_karma',
  energy:   'elite_energy'
};
// Fold the signature words (see RM_SIGNATURE_TIER above) into the same
// lookup table loadWordOrigin() reads, so they behave exactly like every
// other purchasable word.
Object.keys(RM_SIGNATURE_TIER).forEach(function(k) { RM_WORD_TIER[k] = RM_SIGNATURE_TIER[k]; });

// ── WORD ROOT/ORIGIN LABELS ──
const RM_ROOTS = {
  earth:'Proto-Germanic · erpō',   water:'Proto-Indo-European · wódr',
  fire:'Proto-Indo-European · péh₂wr̥', sun:'Proto-Indo-European · sóh₂wl̥',
  moon:'Proto-Indo-European · mḗh₁n̥s', god:'Proto-Germanic · guthan',
  soul:'Proto-Germanic · saiwalō', love:'Proto-Indo-European · lubh',
  truth:'Proto-Germanic · trewwith', light:'Proto-Indo-European · leuk',
  name:'Proto-Indo-European · h₁nómn̥', mind:'Proto-Indo-European · men',
  india:'Sanskrit · Sindhu',       breath:'Proto-Germanic · brǣþ',
  blood:'Proto-Germanic · blōþą',  time:'Proto-Indo-European · dʰeh₁',
  space:'Latin · spatium',         dark:'Proto-Germanic · derkaz',
  mother:'Proto-Indo-European · méh₂tēr', father:'Proto-Indo-European · ph₂tḗr',
  sky:'Old Norse · ský',           tree:'Proto-Germanic · trewą',
  wind:'Proto-Indo-European · h₂wéh₁nts', sea:'Proto-Germanic · saiwaz',
  river:'Latin · rīpa',            stone:'Proto-Germanic · stainaz',
  rain:'Proto-Germanic · regnaz',  child:'Proto-Indo-European · ǵʰel',
  king:'Proto-Germanic · kuningaz', woman:'Proto-Indo-European · gʷén',
  man:'Proto-Indo-European · manus', spirit:'Latin · spiritus',
  life:'Proto-Germanic · liban',   death:'Proto-Indo-European · dhwih₂',
  power:'Latin · potere',          star:'Proto-Indo-European · h₂stḗr',
  dream:'Proto-Germanic · draumaz', voice:'Latin · vox',
  heart:'Proto-Indo-European · kḗr', peace:'Latin · pax',
  wisdom:'Proto-Germanic · wīsdōmaz', strength:'Proto-Germanic · strengaz',
  grace:'Latin · gratia',          freedom:'Proto-Germanic · frīdōmaz',
  karma:'Sanskrit · karman',       energy:'Greek · energeia'
};

// ── HEALING FOCUS — organ/system each word's frequency is associated with ──
const RM_ORGAN = {
  earth:'Grounding · Nervous System', water:'Hydration · Kidneys',
  fire:'Circulation · Vitality',      sun:'Energy · Metabolism',
  moon:'Sleep · Hormonal Balance',    god:'Mental Clarity',
  soul:'Heart · Emotional Balance',   love:'Heart Health',
  truth:'Throat · Communication',     light:'Eyes · Pineal Gland',
  name:'Identity · Confidence',       mind:'Mental Clarity',
  india:'Cultural Roots',             breath:'Lungs · Respiratory',
  blood:'Circulation · Heart',        time:'Nervous System · Focus',
  space:'Mental Clarity',             dark:'Sleep · Melatonin',
  mother:'Heart · Emotional Balance', father:'Grounding · Strength',
  sky:'Lungs · Breath',               tree:'Grounding · Nervous System',
  wind:'Lungs · Breath',              sea:'Hydration · Kidneys',
  river:'Circulation · Flow',         stone:'Bone & Joint Strength',
  rain:'Skin & Glow',                 child:'Immunity · Vitality',
  king:'Confidence · Posture',        woman:'Hormonal Balance',
  man:'Strength · Vitality',          spirit:'Lungs · Breath',
  life:'Immunity · Vitality',         death:'Nervous System · Release',
  power:'Strength · Vitality',        star:'Mental Clarity',
  dream:'Sleep · Hormonal Balance',   voice:'Throat · Communication',
  heart:'Heart Health',               peace:'Nervous System · Calm',
  wisdom:'Mental Clarity',            strength:'Strength · Vitality',
  grace:'Nervous System · Calm',      freedom:'Lungs · Breath',
  karma:'Mental Clarity',             energy:'Energy · Metabolism',
  thunder:'Adrenal · Focus',          storm:'Lungs · Breath',
  prayer:'Mental Clarity',            divine:'Mental Clarity'
};
var RM_ORGAN_FALLBACK = ['Heart Health','Mental Clarity','Lungs · Breath','Immunity · Vitality','Gut Health','Skin & Glow'];
function rmdOrganFor(key) {
  if (RM_ORGAN[key]) return RM_ORGAN[key];
  var h = 0;
  for (var i = 0; i < key.length; i++) h = (h * 31 + key.charCodeAt(i)) >>> 0;
  return RM_ORGAN_FALLBACK[h % RM_ORGAN_FALLBACK.length];
}
function rmdDescriptionFor(word, root) {
  return 'Every word carries a vibrational signature shaped by centuries of natural speech. "' + word + '" traces back to ' + root + ' — a root whose original pronunciation is believed to resonate with the body\'s own frequency. Practicing it aloud, slowly and deliberately, reconnects your voice to language as it was first spoken, before dictionaries flattened its sound into spelling.';
}

// ── SLIDER STATE ──
var _rmdSlideIdx = 0;
var _rmdSlideTimer = null;
var _rmdBanners = [];
var _rmdCurrentKey = null;

function rmdBuildSlider(banners) {
  _rmdBanners = banners;
  _rmdSlideIdx = 0;
  clearInterval(_rmdSlideTimer);
  var track = document.getElementById('rmdSlidesTrack');
  var dots  = document.getElementById('rmdDots');
  if (!track || !dots) return;
  track.innerHTML = banners.map(function(url) {
    return '<div class="rmd-slide"><img decoding="async" src="' + url + '" loading="lazy"></div>';
  }).join('');
  dots.innerHTML = banners.length > 1 ? banners.map(function(_, i) {
    return '<div class="rmd-dot' + (i === 0 ? ' active' : '') + '" onclick="rmdGoSlide(' + i + ')"></div>';
  }).join('') : '';
  track.style.transform = 'translateX(0)';
  if (banners.length > 1) {
    _rmdSlideTimer = setInterval(function() {
      rmdGoSlide((_rmdSlideIdx + 1) % banners.length);
    }, 3500);
  }
}

function rmdGoSlide(idx) {
  _rmdSlideIdx = idx;
  var track = document.getElementById('rmdSlidesTrack');
  var dots  = document.querySelectorAll('.rmd-dot');
  if (track) track.style.transform = 'translateX(-' + (idx * 100) + '%)';
  dots.forEach(function(d, i) { d.classList.toggle('active', i === idx); });
}

// Multi-word signature names (e.g. "cosmostime" -> "Cosmos Time") need an
// explicit lookup — every other word is a single token, so a plain
// first-letter capitalize is enough for those.
function rmDisplayName(key) { return RM_DISPLAY_NAME[key] || (key.charAt(0).toUpperCase() + key.slice(1)); }

// ── LOAD WORD ORIGIN ──
function loadWordOrigin(key) {
  key = key.toLowerCase();
  _rmdCurrentKey = key;
  var word = rmDisplayName(key);
  var tierKey = RM_WORD_TIER[key] || 'basic_a';
  var tier = RM_TIERS[tierKey];
  var root = RM_ROOTS[key] || 'Natural Origin · ' + word;

  // Show detail, hide library
  var lib = document.getElementById('rmLibraryContent');
  var det = document.getElementById('rmDetailView');
  var sub = document.getElementById('rmSubBody');
  var hero = document.getElementById('rmHeroBanner');
  var srch = document.querySelector('.rm-search-wrap');
  if (lib)  lib.style.display  = 'none';
  if (det)  det.style.display  = 'block';
  if (hero) hero.style.display = 'none';
  if (srch) srch.style.display = 'none';
  if (sub)  sub.scrollTop = 0;

  // Build slider
  rmdBuildSlider(tier.banners);

  // Word info
  var wEl = document.getElementById('rmdWord');
  var rEl = document.getElementById('rmdRoot');
  if (wEl) wEl.textContent = word;
  if (rEl) rEl.textContent = root;

  // Healing focus + description
  var organEl = document.getElementById('rmdOrganText');
  var descEl  = document.getElementById('rmdDescText');
  if (organEl) organEl.textContent = rmdOrganFor(key);
  if (descEl)  descEl.textContent  = rmdDescriptionFor(word, root);

  // Price
  var pNow  = document.getElementById('rmdPriceNow');
  var pOrig = document.getElementById('rmdPriceOrig');
  var pBadge= document.getElementById('rmdPriceBadge');
  if (pNow)   pNow.textContent  = tier.price;
  if (pOrig)  { pOrig.textContent = tier.origPrice || ''; pOrig.style.display = tier.origPrice ? '' : 'none'; }
  if (pBadge) { pBadge.textContent = tier.discount || ''; pBadge.style.display = tier.discount ? '' : 'none'; }

  // Buy button
  var buyBtn = document.getElementById('rmdBuyBtn');
  var purchased = [];
  try { purchased = JSON.parse(localStorage.getItem('nwsb_purchased') || '[]'); } catch(e){}
  var owned = purchased.some(function(p){ return p.word && p.word.toLowerCase() === key; });
  if (buyBtn) {
    buyBtn.textContent = owned ? '✓ Owned' : 'Buy Now — ' + tier.price;
    buyBtn.disabled = owned;
  }

  // Wish/cart state
  _rmdRefreshActions();

  // Similar words (same healing focus, excluding this one)
  rmdPopulateSimilar(key);

  // Collapse "View More Details" back down each time a new word loads
  var detBody = document.getElementById('rmdDetailsBody');
  var detChev = document.getElementById('rmdDetailsChev');
  if (detBody) detBody.style.display = 'none';
  if (detChev) detChev.style.transform = '';
}

function rmdToggleDetails() {
  var body = document.getElementById('rmdDetailsBody');
  var chev = document.getElementById('rmdDetailsChev');
  if (!body) return;
  var open = body.style.display !== 'none';
  body.style.display = open ? 'none' : 'block';
  if (chev) chev.style.transform = open ? '' : 'rotate(180deg)';
}

function rmdPopulateSimilar(key) {
  var row = document.getElementById('rmdSimilarRow');
  if (!row) return;
  var organ = rmdOrganFor(key);
  var allWords = Object.keys(RM_WORD_TIER);
  var matches = allWords.filter(function(k) { return k !== key && rmdOrganFor(k) === organ; });
  if (matches.length < 4) {
    allWords.filter(function(k) { return k !== key && matches.indexOf(k) === -1; }).forEach(function(k) {
      if (matches.length < 4) matches.push(k);
    });
  }
  matches = matches.slice(0, 4);
  /* Same generic word-card image used for every word in the actual store
     grid (part010.js's IMG constant) — tier.banners[0] is shared across
     many unrelated words (same tier = same banner), which made several
     "similar words" show the exact same picture. This is the one image
     that's actually meant to represent "a word" consistently. */
  var img = 'https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto/v1778571475/grok_image_1778520937416_jazknf.jpg';
  row.innerHTML = matches.map(function(k) {
    var w = rmDisplayName(k);
    var t = RM_TIERS[RM_WORD_TIER[k] || 'basic_a'];
    return '<div onclick="loadWordOrigin(\'' + k + '\')" style="flex-shrink:0;width:96px;cursor:pointer;">' +
      '<div style="width:96px;height:96px;border-radius:10px;background:#111 url(\'' + img + '\') center/cover;border:1px solid rgba(255,255,255,0.1);"></div>' +
      '<div style="font-size:11.5px;font-weight:600;color:#fff;font-family:\'DM Sans\',sans-serif;margin-top:6px;">' + w + '</div>' +
      '<div style="font-size:10.5px;color:rgba(255,255,255,0.4);font-family:\'DM Sans\',sans-serif;">' + t.price + '</div>' +
    '</div>';
  }).join('');
}

function _rmdRefreshActions() {
  var key = _rmdCurrentKey; if (!key) return;
  var tierKey = RM_WORD_TIER[key] || 'basic_a';
  var tier = RM_TIERS[tierKey];
  var word = rmDisplayName(key);
  var tier_img = tier.banners[0] || '';
  var inWish = (window.nssWishlist||[]).some(function(w){ return w.id === 'rm-'+key; });
  var inCart  = (window.nssCart||[]).some(function(c){ return c.id === 'rm-'+key; });
  var wBtn = document.getElementById('rmdWishBtn');
  var cBtn = document.getElementById('rmdCartBtn');
  var heart= document.getElementById('rmdWishHeart');
  if (wBtn)  wBtn.classList.toggle('wishlisted', inWish);
  if (cBtn)  cBtn.classList.toggle('carted', inCart);
  if (heart) heart.setAttribute('fill', inWish ? 'rgba(220,60,60,0.85)' : 'none');
}

function rmdToggleWish() {
  var key = _rmdCurrentKey; if (!key) return;
  var tierKey = RM_WORD_TIER[key] || 'basic_a';
  var tier = RM_TIERS[tierKey];
  var word = rmDisplayName(key);
  if (typeof nssToggleWishlist === 'function')
    nssToggleWishlist({ id:'rm-'+key, name:word, type:'Word', price:tier.priceVal, img:tier.banners[0]||'' });
  _rmdRefreshActions();
}

function rmdAddCart() {
  var key = _rmdCurrentKey; if (!key) return;
  var tierKey = RM_WORD_TIER[key] || 'basic_a';
  var tier = RM_TIERS[tierKey];
  var word = rmDisplayName(key);
  if (typeof nssAddToCart === 'function')
    nssAddToCart({ id:'rm-'+key, name:word, type:'Word', price:tier.priceVal, img:tier.banners[0]||'' });
  _rmdRefreshActions();
}

function rmdBuyNow() {
  rmdAddCart();
  if (typeof openSub === 'function') openSub('checkout');
}

// Header back is context-aware: from a word detail it returns to the word list;
// from the list it closes the store. (Replaces the old duplicate back button.)
function rmHeaderBack() {
  var det = document.getElementById('rmDetailView');
  if (det && getComputedStyle(det).display !== 'none') {
    rmdBackToLibrary();          // in a word detail → return to the word list
  } else {
    closeSub('real-meaning');    // already in the list → close the store
  }
}

function rmdBackToLibrary() {
  clearInterval(_rmdSlideTimer);
  _rmdCurrentKey = null;
  var lib  = document.getElementById('rmLibraryContent');
  var det  = document.getElementById('rmDetailView');
  var sub  = document.getElementById('rmSubBody');
  var hero = document.getElementById('rmHeroBanner');
  var srch = document.querySelector('.rm-search-wrap');
  if (lib)  lib.style.display  = '';
  if (det)  det.style.display  = 'none';
  if (hero) hero.style.display = '';
  if (srch) srch.style.display = '';
  if (sub)  sub.scrollTop = 0;
}

// ── Request-a-word flow (replaces the old fixed "All Words" pill grid) —
// mirrors the per-word $2.99 request sheet already used in Word Science
// (part030.js's wsRequestThisWord/_wsShowRequestSheet), but generalized
// with a text field since there's no word already in view here.
function rmOpenWordRequest() {
  var existing = document.getElementById('rmReqSheet');
  if (existing) existing.remove();
  var sheet = document.createElement('div');
  sheet.id = 'rmReqSheet';
  sheet.style.cssText = 'position:fixed;inset:0;z-index:9999;display:flex;align-items:flex-end;background:rgba(0,0,0,0.72);';
  sheet.innerHTML = '<div style="width:100%;background:#0e1828;border-top:1px solid rgba(232,213,163,0.2);padding:32px 24px max(env(safe-area-inset-bottom,28px),28px);font-family:\'DM Sans\',sans-serif;box-sizing:border-box;">' +
    '<div style="font-size:10px;font-weight:500;letter-spacing:3px;text-transform:uppercase;color:rgba(232,213,163,0.6);margin-bottom:12px;">Request a Word</div>' +
    '<div style="font-size:22px;font-weight:800;color:#fff;margin-bottom:8px;">Any word. Yours alone.</div>' +
    '<div style="font-size:13px;font-weight:300;color:rgba(255,255,255,0.5);line-height:1.6;margin-bottom:20px;">Type any word, name or phrase — our team personally crafts its phonetic breakdown, natural origin and healing intention, delivered to your library within 48 hours.</div>' +
    '<input id="rmReqInput" type="text" placeholder="Type a word…" style="width:100%;box-sizing:border-box;background:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.14);color:#fff;font-family:\'DM Sans\',sans-serif;font-size:15px;padding:14px 16px;margin-bottom:16px;outline:none;">' +
    '<button onclick="rmConfirmWordRequest()" style="width:100%;background:#e8d5a3;border:none;cursor:pointer;font-family:\'DM Sans\',sans-serif;font-size:14px;font-weight:700;color:#060c18;padding:16px 20px;letter-spacing:0.5px;margin-bottom:12px;display:flex;align-items:center;justify-content:space-between;">Request · $2.99 <span style="opacity:0.5;font-weight:400;">48 hrs delivery</span></button>' +
    '<button onclick="document.getElementById(\'rmReqSheet\').remove()" style="width:100%;background:none;border:1px solid rgba(255,255,255,0.12);cursor:pointer;font-family:\'DM Sans\',sans-serif;font-size:13px;font-weight:400;color:rgba(255,255,255,0.45);padding:14px 20px;">Cancel</button>' +
    '</div>';
  sheet.onclick = function(e){ if (e.target === sheet) sheet.remove(); };
  document.body.appendChild(sheet);
  setTimeout(function() { var inp = document.getElementById('rmReqInput'); if (inp) inp.focus(); }, 50);
}

function rmConfirmWordRequest() {
  var inp = document.getElementById('rmReqInput');
  var word = inp ? inp.value.trim() : '';
  if (!word) { if (inp) inp.style.borderColor = 'rgba(255,100,100,0.6)'; return; }
  word = word.charAt(0).toUpperCase() + word.slice(1);
  var sheet = document.getElementById('rmReqSheet');
  if (sheet) sheet.remove();
  // TODO: integrate payment $2.99 here — same placeholder pattern as
  // wsConfirmRequest() in part030.js until Razorpay is wired up.
  var waiting = document.createElement('div');
  waiting.id = 'rmReqWaiting';
  waiting.style.cssText = 'position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;background:rgba(6,12,24,0.95);font-family:\'DM Sans\',sans-serif;flex-direction:column;gap:16px;';
  waiting.innerHTML = '<div style="width:48px;height:48px;border-radius:50%;border:2px solid rgba(232,213,163,0.2);border-top-color:#e8d5a3;animation:wsSpinAnim 0.8s linear infinite;"></div>' +
    '<div style="font-size:13px;font-weight:300;color:rgba(255,255,255,0.6);letter-spacing:1px;">Processing request…</div>';
  document.body.appendChild(waiting);
  setTimeout(function() {
    var w = document.getElementById('rmReqWaiting');
    if (w) w.remove();
    if (typeof _wsShowSuccessSheet === 'function') _wsShowSuccessSheet(word);
  }, 1800);
}

function rmSearch() {
  var val = (document.getElementById('rmSearchInput')||{}).value;
  if (!val) return;
  val = val.trim().toLowerCase();
  rmSkipIntro();
  if (RM_WORD_TIER[val]) { loadWordOrigin(val); return; }
  // Unknown word — show basic_a tier with AI fallback banner
  RM_WORD_TIER[val] = 'basic_a';
  loadWordOrigin(val);
}

function rmSearchFallback(val) { rmSearch(); }

// ── WORD SEARCH ──
const WORD_DB = {
  'water':   { origin:'Proto-Indo-European · wed-', meaning:'From PIE *wódr — the primordial liquid. In Shabdapathy, W activates cellular hydration resonance and O opens the thoracic cavity. Water words in all languages begin with labial-vowel combinations mimicking drinking motion.' },
  'nature':  { origin:'Latin · natura', meaning:'From Latin nasci — to be born. The N root (nasal breath of birth) combined with the T of touch and R of rhythm. In NOWSBANSIU, this word activates the birth-breath resonance of the nervous system.' },
  'heal':    { origin:'Proto-Germanic · hailaz', meaning:'From PIE *kailo — whole, uninjured. H is the breath of life across cultures. In Shabdapathy, the H-EAL combination opens the throat chakra and activates thyroid-assisted immune function.' },
  'sound':   { origin:'Latin · sonus', meaning:'From PIE *swon-o — to make noise. S activates solar plexus, OU is the circular resonance of the chest, N returns to nasal grounding. The complete phonetic journey from stimulus to vibration to stillness.' },
  'mind':    { origin:'Proto-Indo-European · men-', meaning:'From PIE *men — to think. M is the labial hum of internal vibration. In Shabdapathy, M resonates with the brain\'s default mode network and activates contemplative neural pathways.' },
  'word':    { origin:'Proto-Indo-European · werdh-', meaning:'From PIE *werdh — word, speech. In NOWSBANSIU, W-O-R-D encodes the complete cycle: W (water/creation), O (openness), R (rhythm), D (direction). The word \'word\' contains its own instruction.' },
  'body':    { origin:'Old English · bodig', meaning:'From Proto-Germanic *budagaz. B is the plosive of birth, O opens resonance, D is direction of flow, Y is the connector to higher self. In Shabdapathy, chanting \'BODY\' activates awareness of the physical instrument.' },
};
function searchWord() {
  const input = document.getElementById('wordSearchInput');
  const val = input ? input.value.trim() : '';
  if (!val) return;
  const data = WORD_DB[val.toLowerCase()];
  if (data) {
    document.getElementById('wsrWord').textContent = val.charAt(0).toUpperCase() + val.slice(1);
    document.getElementById('wsrOrigin').textContent = data.origin;
    document.getElementById('wsrMeaning').textContent = data.meaning;
    document.getElementById('wordSearchResult').classList.add('show');
  } else {
    groqHomeSearch(val); // AI for any unknown word
  }
}
