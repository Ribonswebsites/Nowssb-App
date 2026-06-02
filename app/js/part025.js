
(function(){
'use strict';

/* ── Wait for Part 1 globals ── */
function waitForPg3(cb) {
  if (window._pgShow && window._PG) { cb(); }
  else { setTimeout(function(){ waitForPg3(cb); }, 120); }
}

waitForPg3(function() {

  var PG = window._PG;

  /* ── Part 3 guide definitions ── */

  PG['word-science'] = {
    eye:   'Word Science',
    title: 'The NOWSBANSIU System',
    body:  'Five tabs. Each one goes deeper into how sound becomes healing.',
    tips: [
      ['What tab', 'The core principle — every word has a natural origin vibration that predates all dictionaries.'],
      ['How It Works', 'The science of how correct pronunciation creates specific frequencies in specific organs.'],
      ['Body Effects', 'Which sounds activate which body systems — mapped letter by letter.'],
      ['Word Origins', 'Where natural origin words come from — any language, any civilization, any era.'],
      ['La Letter', 'The NOWSBANSIU letter map — tap any letter chip to see its organ target and demonstration words.']
    ]
  };

  PG['profile'] = {
    eye:   'Profile',
    title: 'Your Practitioner Space',
    body:  'Everything about your account and practice in one place.',
    tips: [
      ['Avatar', 'Tap the circle to edit your name. Tap the pencil icon to upload a photo.'],
      ['Plan badge', 'Shows Free, Pro or Premium. Upgrade to unlock AI scoring, all routines and sentence builder.'],
      ['Your Progress', 'Live stats — streak, sessions completed, words practiced, and mastered words.'],
      ['Settings', 'Voice preference, session duration, daily reminder time — all adjustable here.'],
      ['Sign Out', 'At the bottom — your session stays saved in Firestore so nothing is lost.']
    ]
  };

  PG['real-meaning'] = {
    eye:   'Word Origins',
    title: 'Word Without Dictionary',
    body:  'Type any word from any language. Discover its natural phonetic origin before any dictionary wrote it down.',
    tips: [
      ['Search bar', 'Type any word — English, Hindi, Arabic, Latin, any language — and tap Go.'],
      ['Origin result', 'See which natural sound root the word comes from and which organ it activates.'],
      ['Sound breakdown', 'The word broken into phonetic chips — each chip is one frequency unit.'],
      ['Library cards', 'Scroll down to browse pre-loaded words by category — Elements, Body, Nature.'],
      ['Tap any card', 'Opens the full origin analysis for that word with healing frequency detail.']
    ]
  };

  PG['shabdapathy'] = {
    eye:   'Shabdapathy',
    title: 'The Foundation Science',
    body:  'Five chapters on how sound heals. Read them in order — each one builds on the last.',
    tips: [
      ['Chapter I', 'The Origin of Sound — how primordial sounds became the building blocks of all language.'],
      ['Chapter II', 'Body as Instrument — each organ has a corresponding sound signature.'],
      ['Chapter III', 'The NOWSBANSIU Key — the nine-letter framework that maps sounds to healing.'],
      ['Chapter IV', 'Practice & Application — daily protocols for activating word-body resonance.'],
      ['Download eBook', 'Free download at the bottom — all five chapters compiled for offline reading.']
    ]
  };

  /* ── Hook into the EnterFromIntro functions — fire guide AFTER cinematic dismissal ── */

  /* word-science */
  var _origWsEnter = window.wsEnterFromIntro;
  window.wsEnterFromIntro = function() {
    if (_origWsEnter) _origWsEnter.apply(this, arguments);
    window._pgSchedule('word-science', 700);
  };

  /* shabdapathy */
  var _origShabdaEnter = window.shabdaEnterFromIntro;
  window.shabdaEnterFromIntro = function() {
    if (_origShabdaEnter) _origShabdaEnter.apply(this, arguments);
    window._pgSchedule('shabdapathy', 700);
  };

  /* profile — hook profileEnterFromIntro */
  var _origProfileEnter = window.profileEnterFromIntro;
  window.profileEnterFromIntro = function() {
    if (_origProfileEnter) _origProfileEnter.apply(this, arguments);
    window._pgSchedule('profile', 700);
  };

  /* real-meaning — hook rmEnterFromIntro */
  var _origRmEnter = window.rmEnterFromIntro;
  window.rmEnterFromIntro = function() {
    if (_origRmEnter) _origRmEnter.apply(this, arguments);
    window._pgSchedule('real-meaning', 700);
  };

}); // end waitForPg3

})();
