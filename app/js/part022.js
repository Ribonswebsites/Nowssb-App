
(function(){
'use strict';

/* ── Seen tracker ── */
var _pgSeen = {};
try { _pgSeen = JSON.parse(localStorage.getItem('nwsb_pg')||'{}'); } catch(e){}
function pgMarkSeen(key) {
  _pgSeen[key] = 1;
  try { localStorage.setItem('nwsb_pg', JSON.stringify(_pgSeen)); } catch(e){}
}
function pgHasSeen(key) { return !!_pgSeen[key]; }

/* ── Page guide definitions ── */
var PG = {

  'practice': {
    eye:   'Word Player',
    title: 'How the Player Works',
    body:  'Everything happens on this one screen. No scrolling needed.',
    tips: [
      ['Listen tab', 'Plays the word. Phonetic chips light up syllable by syllable.'],
      ['Record tab', 'Tap the red button, speak the word, get an AI pronunciation score 0–100.'],
      ['Repeat tab', 'Count your reps — tap 3, 7, or 21 times. Progress bar fills.'],
      ['Meaning tab', 'See which organ this word targets and its healing benefit.'],
      ['Guide tab', 'Correct mouth position, resonance point, common mistake, tip.'],
      ['Session end', 'When all words finish, a healing sentence plays automatically — let it complete.']
    ]
  },

  'routines': {
    eye:   'My Routines',
    title: 'Your Daily Schedule',
    body:  'Five time slots. Each one becomes a ritual at its time of day.',
    tips: [
      ['NOW badge', 'The gold badge shows which routine matches your current time.'],
      ['Arrow button', 'Opens the routine detail — add words, view history.'],
      ['Start button', 'Launches the player immediately with all words in that routine.'],
      ['Pencil icon', 'Rename the routine or change its time slot.']
    ]
  },

  'routine-detail': {
    eye:   'Routine Detail',
    title: 'Build Your Practice List',
    body:  'Three tabs control everything about this routine.',
    tips: [
      ['Words tab', 'Your current word list. Tap any word to open it in the player.'],
      ['Library tab', 'All words you own. Tap + to add to this routine, tap the tick to remove.'],
      ['History tab', 'Past sessions with word count and completion date.'],
      ['Start Session', 'Launches the player with every word in this routine.']
    ]
  },

  'health-journey': {
    eye:   'Health Journey',
    title: 'Healing by Body Goal',
    body:  'Words organized by the organ or system they target. Choose your path.',
    tips: [
      ['Male / Female', 'Each has 10 targeted health categories built for that body.'],
      ['Tap a card', 'Opens that category — words, science, and a session ready to go.'],
      ['Start Session', 'Loads all category words straight into the player.'],
      ['Stacking', 'Practice multiple categories in a week for full-body frequency coverage.']
    ]
  }

};

/* ── Show a guide ── */
var _pgActive = null;
var _pggBanners = {
  'practice':       'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401851/image-109_flaoqi.jpg',
  'routines':       'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401874/image-96_wklfon.jpg',
  'routine-detail': 'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401905/image-206_mhgp5c.jpg',
  'health-journey': 'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401851/image-109_flaoqi.jpg',
  'health-male':    'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401874/image-96_wklfon.jpg',
  'health-female':  'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401905/image-206_mhgp5c.jpg',
  'health-category':'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401851/image-109_flaoqi.jpg',
  'sound-library':  'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401874/image-96_wklfon.jpg',
  'my-progress':    'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401905/image-206_mhgp5c.jpg',
  'word-science':   'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401851/image-109_flaoqi.jpg',
  'shabdapathy':    'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401874/image-96_wklfon.jpg',
  'profile':        'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401905/image-206_mhgp5c.jpg',
  'real-meaning':   'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778401851/image-109_flaoqi.jpg'
};
function pgShow(key) {
  if (pgHasSeen(key)) return;
  var d = PG[key];
  if (!d) return;
  _pgActive = key;

  /* set banner image */
  var bannerEl = document.getElementById('pggBannerImg');
  if (bannerEl) bannerEl.src = _pggBanners[key] || _pggBanners['practice'];

  document.getElementById('pggEye').textContent   = d.eye;
  document.getElementById('pggTitle').textContent = d.title;
  document.getElementById('pggBody').textContent  = d.body;

  var html = '';
  d.tips.forEach(function(t, i) {
    html += '<div class="pgg-row">'
          + '<div class="pgg-num">'+(i+1)+'</div>'
          + '<div class="pgg-txt"><strong>'+t[0]+'</strong> — '+t[1]+'</div>'
          + '</div>';
  });
  document.getElementById('pggRows').innerHTML = html;

  document.getElementById('pgGuide').classList.add('open');
}

function pgClose(permanent) {
  document.getElementById('pgGuide').classList.remove('open');
  if (permanent && _pgActive) pgMarkSeen(_pgActive);
  _pgActive = null;
}

document.getElementById('pggOk').addEventListener('click', function() {
  pgClose(true);  // permanently dismiss — never show again
});
document.getElementById('pggDismiss').addEventListener('click', function() {
  pgClose(true);  // mark as seen permanently
});

/* ── Single cancellable coach timer — shared across all parts ── */
window._pgTimer = null;
window._pgTimerToken = 0; // increments on every navigation; pending callbacks check their token

function pgSchedule(key, delay) {
  // Cancel any pending coach from a previous navigation
  if (window._pgTimer) { clearTimeout(window._pgTimer); window._pgTimer = null; }
  pgClose(false); // hide any currently-open coach instantly
  var token = ++window._pgTimerToken;
  window._pgTimer = setTimeout(function() {
    if (token !== window._pgTimerToken) return; // stale — another nav happened, abort
    pgShow(key);
    window._pgTimer = null;
  }, delay);
}

/* ── Single openSub hook — all screens registered here, no Part 2 re-wrapping ── */
var _prevOpenSub = window.openSub;
window.openSub = function(id) {
  if (_prevOpenSub) _prevOpenSub.apply(this, arguments);

  var pgScreens = ['practice','routines','routine-detail','health-journey','health-male','health-female','health-category','sound-library','my-progress'];
  window._pgActiveScreens = pgScreens;

  var d = 700;
  if      (id === 'practice')        pgSchedule('practice',        d);
  else if (id === 'routines')        pgSchedule('routines',        d);
  else if (id === 'routine-detail')  pgSchedule('routine-detail',  d + 200);
  else if (id === 'health-journey')  pgSchedule('health-journey',  d);
  else if (id === 'health-male')     pgSchedule('health-male',     d);
  else if (id === 'health-female')   pgSchedule('health-female',   d);
  else if (id === 'health-category') pgSchedule('health-category', d + 150);
  else {
    // No coach for this screen — cancel any pending one and close any open one
    if (window._pgTimer) { clearTimeout(window._pgTimer); window._pgTimer = null; }
    ++window._pgTimerToken;
    pgClose(false);
  }
};

window._pgSchedule = pgSchedule;

/* expose for later parts */
window._pgShow    = pgShow;
window._pgSeen    = _pgSeen;
window._pgMarkSeen= pgMarkSeen;
window._pgHasSeen = pgHasSeen;
window._PG        = PG;

})();
