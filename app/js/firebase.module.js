
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.8.1/firebase-app.js";
import { getAuth, onAuthStateChanged, signInWithPopup, signInWithRedirect,
  getRedirectResult, GoogleAuthProvider,
  signInWithEmailAndPassword, createUserWithEmailAndPassword,
  sendSignInLinkToEmail, sendPasswordResetEmail, signOut,
  RecaptchaVerifier, signInWithPhoneNumber }
  from "https://www.gstatic.com/firebasejs/11.8.1/firebase-auth.js";
import { getFirestore, doc, setDoc, getDoc, serverTimestamp,
  collection, addDoc, getDocs, query, orderBy, limit, where }
  from "https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js";

const app = initializeApp({
  apiKey: "AIzaSyBly5XnqNnpVom11thjlvT5q_BfxNJBfgQ",
  authDomain: "nowssb-34f1b.firebaseapp.com",
  projectId: "nowssb-34f1b",
  storageBucket: "nowssb-34f1b.firebasestorage.app",
  messagingSenderId: "1024709686012",
  appId: "1:1024709686012:web:20d425060043141a0b5d79",
  measurementId: "G-KNGQK10PHJ"
});

const auth = getAuth(app);
const db   = getFirestore(app);
window._splashStartTime = Date.now();
    // Optimization: Defer non-critical font loading
    if ('fonts' in document) {
      document.fonts.ready.then(() => {
        document.body.classList.add('fonts-loaded');
      });
    }

async function saveUser(user) {
  const ref  = doc(db, "users", user.uid);
  const snap = await getDoc(ref);
  if (!snap.exists()) {
    var _tStart = new Date();
    var _tEnd   = new Date(_tStart.getTime() + 7 * 24 * 60 * 60 * 1000);
    await setDoc(ref, {
      uid: user.uid, email: user.email,
      displayName: user.displayName || '',
      photoURL: user.photoURL || '',
      isPro: false,
      tier: null,
      trialStartDate: _tStart.toISOString(),
      trialEndDate:   _tEnd.toISOString(),
      createdAt: serverTimestamp(),
      lastLogin: serverTimestamp()
    });
  } else {
    await setDoc(ref, { lastLogin: serverTimestamp() }, { merge: true });
  }
}

// ── USER DATA CACHE — prevents repeat Firestore reads ──
window._userDataCache = null;
// _splashRoute: where to go when splash finishes (set by auth during splash)
window._splashRoute   = null;
// _splashDone: true once the 2.5s splash timer has fired
window._splashDone    = false;
// _authNavigating: lock to prevent double-navigation (e.g. Google popup + onAuthStateChanged)
window._authNavigating = false;

async function _resolveUserRoute(user) {
  // Returns 'home', 'signup2' based on Firestore profile
  // Device-level fast path: once this device has finished onboarding (questions +
  // profile picker), never show those screens again — go straight home, even if
  // the Firestore read is slow or offline.
  try { if (localStorage.getItem('nwsb_onboarding_done') === '1') return 'home'; } catch(e){}
  let data = window._userDataCache;
  if (!data) {
    const ref  = doc(db, "users", user.uid);
    let snap;
    try {
      snap = await Promise.race([
        getDoc(ref),
        new Promise((_, rej) => setTimeout(() => rej(new Error('firestore-timeout')), 6000))
      ]);
    } catch (e) {
      // Firestore timed out — use Firebase auth metadata to distinguish new vs returning.
      // For a brand-new account, creationTime and lastSignInTime are the same moment.
      return _isNewUser(user) ? 'ob-intro' : 'home';
    }
    data = snap.data() || {};
    window._userDataCache = data;
    setTimeout(function(){ if (window._spRefreshPromo) window._spRefreshPromo(); }, 100);
  }
  if (data.gender) window._userGender = data.gender;
  if (data.blocked) {
    if (typeof signOut === 'function') try { signOut(auth); } catch(e) {}
    alert('Your account has been suspended. Please contact support.');
    return 'login';
  }
  if (data.onboardingDone) {
    try { localStorage.setItem('nwsb_onboarding_done', '1'); } catch(e){}
    return 'home';
  }
  if (data.profileStepDone) {
    if (window._fbSetDoc && window._currentUid) {
      window._fbSetDoc(window._currentUid, { onboardingDone: true }, { merge: true }).catch(() => {});
    }
    if (window._userDataCache) window._userDataCache.onboardingDone = true;
    try { localStorage.setItem('nwsb_onboarding_done', '1'); } catch(e){}
    return 'home';
  }
  // New user — start the onboarding choose page
  return 'ob-intro';
}

// Detect first-ever login using Firebase auth metadata (works offline, no Firestore needed).
// For a brand-new account, creationTime and lastSignInTime are the same moment.
function _isNewUser(user) {
  try {
    var c = new Date(user.metadata.creationTime).getTime();
    var l = new Date(user.metadata.lastSignInTime).getTime();
    return Math.abs(c - l) < 90000; // within 90 seconds = first login
  } catch(e) { return false; }
}

onAuthStateChanged(auth, async user => {
  if (user) {
    window._currentUid = user.uid;
    window._currentUser = user;                          // fix: was never set
    window._userName = user.displayName || '';           // fix: was never set
    // Fire-and-forget lastLogin update — don't block routing on it
    saveUser(user).catch(() => {});

    // ── DURING SPLASH: logged-in users go to home or onboarding ──
    if (currentScreen === 'splash') {
      // Set placeholder immediately so the fallback timer never defaults to 'login'
      window._splashRoute = 'home';
      try {
        window._splashRoute = await _resolveUserRoute(user);
      } catch(e) {
        window._splashRoute = 'home';
      }
      if (window._splashDone) {
        _doNavigate(window._splashRoute);
      } else {
        // Navigate as soon as the minimum splash time has elapsed. On a fresh
        // session-resume (user switched apps and came back), skip the branded
        // splash delay so it feels like returning to a native app, not a reload.
        var _elapsed = Date.now() - (window._splashStartTime || Date.now());
        var _resumeFresh = false;
        try { _resumeFresh = (typeof window._nwsbHasFreshResume === 'function') && window._nwsbHasFreshResume(); } catch (e) {}
        var _minWait = Math.max(0, (_resumeFresh ? 150 : 1500) - _elapsed);
        setTimeout(function() {
          if (currentScreen !== 'splash') return;
          window._splashDone = true;
          _doNavigate(window._splashRoute);
        }, _minWait);
      }
      return;
    }

    // ── ALREADY ON A SAFE SCREEN — don't interrupt ──
    const noRedirect = ['home','home-nm','onboarding','ob-normal','ob-intro','analysis','signup1','signup2','profile-setup','landing'];
    if (noRedirect.includes(currentScreen)) return;

    // ── ON LOGIN SCREEN — navigate to correct destination ──
    if (window._authNavigating) return;
    window._authNavigating = true;
    // Safety net: if routing stalls beyond 8s, force-navigate based on user type
    var _authStuckTimer = setTimeout(function() {
      if (currentScreen === 'login' || currentScreen === 'splash') {
        _doNavigate(_isNewUser(user) ? 'signup2' : 'home');
      }
      window._authNavigating = false;
    }, 8000);
    try {
      const dest = await _resolveUserRoute(user);
      clearTimeout(_authStuckTimer);
      _doNavigate(dest);
    } catch(e) {
      console.warn('Auth routing error:', e.message);
      clearTimeout(_authStuckTimer);
      _doNavigate(_isNewUser(user) ? 'signup2' : 'home');
    } finally {
      window._authNavigating = false;
    }

  } else {
    window._currentUid = null;
    window._userDataCache = null;

    // Unauthenticated → go straight to login
    if (currentScreen === 'splash') {
      window._splashRoute = 'login';
      if (window._splashDone) _doNavigate('login');
      return;
    }

    // Not logged in on a protected screen — send to login
    // home and home-nm both allow guest browsing (skip login sets _guestMode)
    const protectedScreens = ['onboarding','analysis'];
    if (protectedScreens.includes(currentScreen)) {
      goTo('login');
    }
    if ((currentScreen === 'home' || currentScreen === 'home-nm') && !window._guestMode) {
      goTo('login');
    }
  }
});

window._doNavigate = _doNavigate;
function _doNavigate(dest) {
  // Reset one-shot flags
  _googleSignInInProgress = false;
  // Hide auth loader if visible
  const loader = document.getElementById('authLoader');
  if (loader) loader.classList.remove('visible');
  // Route 'home' to the user's preferred home screen (default: home-nm)
  if (dest === 'home') {
    var homeMode = localStorage.getItem('nwsb_home_mode') || 'nm';
    if (homeMode !== 'home') dest = 'home-nm';
  }
  if (currentScreen !== dest) goTo(dest);
}

// Finish onboarding — go home (answers already saved by nextQuestion)
window.finishOnboarding = async () => {
  // Answers were already saved when user completed the last onboarding question.
  // Just navigate to home. Only save here if somehow _onboardingAnswers is set
  // (legacy path) or mark as done if not already marked.
  if (window._onboardingAnswers && window._onboardingAnswers.length > 0) {
    window.saveOnboardingAnswers(window._onboardingAnswers, false).catch(() => {});
  } else if (window._currentUid && window._fbSetDoc) {
    // Ensure onboardingDone is set without overwriting existing answers
    window._fbSetDoc(window._currentUid, { onboardingDone: true }, { merge: true }).catch(() => {});
  }
  try { localStorage.setItem('nwsb_onboarding_done', '1'); } catch(e){}
  goTo('home');
};

// Save onboarding answers to Firestore
// answers = [goal (merged q0+q1), routine (q2 time-of-day), level (q3), gender (q4)]
window.saveOnboardingAnswers = async (answers, skipped) => {
  const user = auth.currentUser;
  if (!user) return;
  const ref = doc(db, "users", user.uid);
  await setDoc(ref, {
    onboardingDone: true,
    onboardingSkipped: skipped || false,
    onboardingAnswers: skipped ? null : {
      goal:    answers[0],
      routine: answers[1],   // time-of-day preference (Morning / Evening / etc)
      level:   answers[2],
      gender:  answers[3]
    },
    // Save gender at top level too — used by health section + word sets
    gender: skipped ? null : (answers[3] || null)
  }, { merge: true });
  try { localStorage.setItem('nwsb_onboarding_done', '1'); } catch(e){}
  if (!skipped && answers[3]) window._userGender = answers[3];
};

const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
    // Optimization: Passive event listeners for better scroll performance
    const passiveEvents = { passive: true };
    window.addEventListener('touchstart', () => {}, passiveEvents);
    window.addEventListener('touchmove', () => {}, passiveEvents);
getRedirectResult(auth).then(async result => {
  if (result && result.user) {
    // Coming back from a redirect fallback (incognito / PWA mode).
    // Route new users to signup2, returning users to home.
    var _rDest = _isNewUser(result.user) ? 'ob-intro' : 'home';
    window._splashRoute = _rDest;
    window._splashDone  = true;
    saveUser(result.user).catch(() => {});
    // Let onAuthStateChanged fire first (it will also route correctly);
    // this setTimeout is only a fallback if it hasn't fired within 300ms.
    setTimeout(function() {
      if (currentScreen === 'splash' || currentScreen === 'login') {
        _doNavigate(_rDest);
      }
    }, 300);
  }
}).catch(e => {
  const code = e.code || '';
  if (code === 'auth/unauthorized-domain') {
    console.warn('Firebase: domain not authorised for Google sign-in.');
  } else if (code && code !== 'auth/user-cancelled') {
    console.error('Redirect error:', e.message);
  }
  _googleSignInInProgress = false;
});

let _googleSignInInProgress = false;
window.fbGoogleLogin = async () => {
  if (_googleSignInInProgress) return;
  _googleSignInInProgress = true;
  const provider = new GoogleAuthProvider();
  const loader = document.getElementById('authLoader');

  // Always try popup first — on mobile Chrome this shows the native account picker
  // overlay without leaving the page (same as Manus / Claude). Only fall back to
  // redirect if the browser explicitly blocks popups (PWA standalone, some WebViews).
  if (loader) loader.classList.add('visible');
  try {
    await signInWithPopup(auth, provider);
    // onAuthStateChanged fires and handles navigation — nothing to do here
  } catch(e) {
    _googleSignInInProgress = false;
    if (loader) loader.classList.remove('visible');
    if (e.code === 'auth/popup-blocked' || e.code === 'auth/operation-not-supported-in-this-environment') {
      // Browser blocked the popup (PWA mode, WKWebView) — fall back to redirect
      if (loader) loader.classList.add('visible');
      try {
        await signInWithRedirect(auth, provider);
        // Page navigates away — code below never runs
      } catch(re) {
        _googleSignInInProgress = false;
        if (loader) loader.classList.remove('visible');
        alert(re.code === 'auth/unauthorized-domain'
          ? 'Google sign-in is not available here. Please use Email or Phone instead.'
          : 'Sign-in failed: ' + re.message);
      }
    } else if (e.code === 'auth/unauthorized-domain') {
      alert('Google sign-in is not available here. Please use Email or Phone instead.');
    } else if (e.code !== 'auth/popup-closed-by-user' && e.code !== 'auth/cancelled-popup-request') {
      alert('Sign-in failed: ' + e.message);
    }
  }
};

let _recaptchaVerifier = null;
let _confirmationResult = null;
let _signupConfirmationResult = null;
function _getRecaptcha(containerId) {
  if (_recaptchaVerifier) { try { _recaptchaVerifier.clear(); } catch(e) {} _recaptchaVerifier = null; }
  _recaptchaVerifier = new RecaptchaVerifier(auth, containerId, { size: 'invisible' });
  return _recaptchaVerifier;
}

window.fbEmailLogin = async () => {
  const email = document.getElementById('loginEmail').value.trim();
  const pass  = document.getElementById('pwInput').value.trim();
  if (!email || !pass) { alert('Enter your email and password.'); return; }
  if (pass.length < 6) { alert('Password must be at least 6 characters.'); return; }
  const btn = document.querySelector('#nm-login-email .nm-btn-gold');
  const loader = document.getElementById('authLoader');
  if (btn) { btn.textContent = 'Please wait…'; btn.disabled = true; }
  try {
    await signInWithEmailAndPassword(auth, email, pass);
    if (loader) loader.classList.add('visible');
  } catch(signInErr) {
    // These codes all mean "user doesn't exist with that email" — create new account
    const notFound = ['auth/user-not-found','auth/invalid-credential','auth/invalid-email'];
    if (notFound.some(c => signInErr.code === c || signInErr.message?.includes('no user'))) {
      try {
        if (btn) btn.textContent = 'Creating account…';
        window._su2Method   = 'email';
        window._su2Email    = email;
        window._su2Password = pass;
        await createUserWithEmailAndPassword(auth, email, pass);
        if (loader) loader.classList.add('visible');
      } catch(createErr) {
        if (btn) { btn.textContent = 'Continue →'; btn.disabled = false; }
        if (createErr.code === 'auth/email-already-in-use') {
          alert('This email is already registered. Check your password and try again.');
        } else if (createErr.code === 'auth/weak-password') {
          alert('Password must be at least 6 characters.');
        } else {
          alert('Could not create account: ' + createErr.message);
        }
      }
    } else if (signInErr.code === 'auth/wrong-password') {
      if (btn) { btn.textContent = 'Continue →'; btn.disabled = false; }
      alert('Wrong password. Try again or tap "Forgot password" below.');
    } else {
      if (btn) { btn.textContent = 'Continue →'; btn.disabled = false; }
      alert('Sign-in failed: ' + signInErr.message);
    }
  }
};

window.fbSignUp = async () => {
  // Reads from signup screen fields (su1Email / su1Password), not login screen
  const email = (document.getElementById('su1Email') || document.getElementById('loginEmail') || {}).value?.trim();
  const pass  = (document.getElementById('su1Password') || document.getElementById('pwInput') || {}).value?.trim();
  if (!email || !pass) return alert('Enter email and password');
  try { await createUserWithEmailAndPassword(auth, email, pass); }
  catch(e) { alert('Sign up failed: ' + e.message); }
};

window.fbMagicLink = async () => {
  const email = document.getElementById('loginEmail').value.trim();
  if (!email) return alert('Enter your email first');
  try {
    await sendSignInLinkToEmail(auth, email, { url: window.location.href, handleCodeInApp: true });
    localStorage.setItem('emailForSignIn', email);
    alert('Magic link sent. Check your inbox.');
  } catch(e) { alert(e.message); }
};

window.fbSignOut = async () => {
  // Clear all session state
  window._userDataCache = null;
  window._splashRoute   = null;
  window._splashDone    = false;
  window._authNavigating = false;
  window._su2Method = null;
  window._userGender = null;
  window._currentUid = null;
  window._currentUser = null;
  window._userName = null;
  _googleSignInInProgress = false;
  try { await signOut(auth); } catch(e) { console.warn('Sign out error:', e.message); }
  goTo('login');
};

// ── EXPOSE FOR SIGNUP SCREENS ──
window._fbCreateUser = (email, pass) => createUserWithEmailAndPassword(auth, email, pass);
window._fbSendEmailLink = (email) => sendSignInLinkToEmail(auth, email, { url: window.location.href, handleCodeInApp: true });
window._fbSetDoc = (uid, data) => setDoc(doc(db, 'users', uid), data, { merge: true });
window._fbServerTimestamp = () => serverTimestamp();

/* ── Reels collection helpers ── */
window._fbAddReelDoc = (reelData) =>
  addDoc(collection(db, 'reels'), { ...reelData, createdAt: serverTimestamp(), likes: 0 });

window._fbGetReels = async (opts) => {
  opts = opts || {};
  var constraints = [orderBy('createdAt', 'desc'), limit(opts.limit || 30)];
  if (opts.uid) constraints.splice(1, 0, where('uid', '==', opts.uid));
  var snap = await getDocs(query(collection(db, 'reels'), ...constraints));
  return snap.docs.map(function(d){ return Object.assign({ id: d.id }, d.data()); });
};
