
(function(){
'use strict';

/* ── Wait for Part 1 globals ── */
function waitForPg(cb) {
  if (window._pgShow && window._PG) { cb(); }
  else { setTimeout(function(){ waitForPg(cb); }, 100); }
}

waitForPg(function() {

  /* ── Add Part 2 guide definitions to the shared PG object ── */
  var PG = window._PG;

  PG['health-male'] = {
    eye:   'Male · Health Journey',
    title: 'Your 10 Healing Categories',
    body:  'Each card targets a specific organ system. Tap one to open it.',
    tips: [
      ['Tap any card', 'Opens the category intro — see the organ it targets and what the words activate.'],
      ['Words tab', 'The words assigned to this category. Tap any to open in the player.'],
      ['About tab', 'The organ science — why these phonetic frequencies affect this body system.'],
      ['Start Session', 'Loads all category words into the Walkman player immediately.'],
      ['Stack categories', 'Practice a different category each day for full-body frequency coverage.']
    ]
  };

  PG['health-female'] = {
    eye:   'Female · Health Journey',
    title: 'Your 10 Healing Categories',
    body:  'Each card targets a specific organ or hormonal system. Tap one to enter.',
    tips: [
      ['Tap any card', 'Opens the category intro — organ tag, description, and a one-tap entry.'],
      ['Words tab', 'Words for this category. Each targets the organ shown on the card.'],
      ['About tab', 'The phonetic science behind why these words affect this body system.'],
      ['Start Session', 'Loads all category words straight into the player.'],
      ['Rotate categories', 'Heart one day, Hormonal Balance the next — build a full healing cycle.']
    ]
  };

  PG['health-category'] = {
    eye:   'Category Page',
    title: 'Inside a Healing Category',
    body:  'Three tabs. One bottom button. Everything you need for this body target.',
    tips: [
      ['Words tab', 'Words assigned to this category. Tap any word to open it in the player.'],
      ['About tab', 'The organ this category targets and why these phonetics affect it.'],
      ['Sessions tab', 'Your past sessions in this category — word count, date, completion.'],
      ['Start Session', 'Bottom button — loads all category words straight into the Walkman player.']
    ]
  };

  PG['sound-library'] = {
    eye:   'Sound Library',
    title: 'Your Personal Collection',
    body:  'Every word and sentence you own lives here. Three tabs, one archive.',
    tips: [
      ['Sentences tab', 'Healing sentences built from the words you own. Tap any to play.'],
      ['My Words tab', 'Your full word library with phonetic breakdown and organ tag. Tap any to open in the player.'],
      ['Purchased tab', 'Words you have bought from the Word Store — permanently yours, playable anytime.'],
      ['More words = more sentences', 'The more words you own, the more sentence combinations unlock automatically.']
    ]
  };

  PG['my-progress'] = {
    eye:   'My Progress',
    title: 'Your Healing Record',
    body:  'Every session you complete is tracked here in real time.',
    tips: [
      ['Streak', 'Consecutive days with at least one completed session. Keep it alive.'],
      ['Sessions count', 'Every session you finish — a permanent record of your practice.'],
      ['Mastered Words', 'Words you scored 90+ on in Record mode three sessions in a row.'],
      ['Body Map', 'Organs light up as you practice words that target them — your frequency map.'],
      ['Weekly grid', 'Your activity heatmap for the past 7 days — see your consistency at a glance.']
    ]
  };

  /* ── Part 2 screens are already registered in the Part 1 single openSub hook ── */
  /* health-male, health-female, health-category are handled via pgSchedule — no re-wrapping needed */

  /* ── sound-library: fire guide only after user taps Open Library ── */
  var _origSlEnter = window.slEnterLibrary;
  window.slEnterLibrary = function() {
    if (_origSlEnter) _origSlEnter.apply(this, arguments);
    window._pgSchedule('sound-library', 700);
  };

  /* ── my-progress: fire guide only after user taps Enter ── */
  var _origMpEnter = window.mpEnterFromIntro;
  window.mpEnterFromIntro = function() {
    if (_origMpEnter) _origMpEnter.apply(this, arguments);
    window._pgSchedule('my-progress', 700);
  };
  window.mpEnterFromIntro = window.mpEnterFromIntro; // re-expose

}); // end waitForPg

})();
