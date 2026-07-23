// Player Guide — one-time-ever walkthrough shown the first time a user ever
// enters the practice player, before anything else loads. Explains every
// button in the Liquid Glass Player. Uses the "pwg" prefix (Practice-Walkthrough-Guide)
// to avoid collision with the unrelated coach-mark system in part022.js (which
// already owns the "pg" prefix — pgShow/pgClose/pgMarkSeen/pgSchedule).
(function () {

  var PWG_ICONS = {
    welcome: '<svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M4 14v-2a8 8 0 0116 0v2"/><rect x="2" y="14" width="5" height="7" rx="2"/><rect x="17" y="14" width="5" height="7" rx="2"/></svg>',
    listen: '<svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.6"><circle cx="12" cy="12" r="9.5"/><path d="M10 8.2l5.2 3.8-5.2 3.8z" fill="#e8d5a3" stroke="none"/></svg>',
    practice: '<svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="2" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0014 0M12 18v4M8 22h8"/></svg>',
    library: '<svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4.5A2.5 2.5 0 016.5 2H12v18H6.5A2.5 2.5 0 004 17.5v-13z"/><path d="M20 4.5A2.5 2.5 0 0017.5 2H12v18h5.5a2.5 2.5 0 012.5 2.5v-18z"/></svg>',
    settings: '<svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 13a7.97 7.97 0 000-2l2-1.5-2-3.5-2.4 1a8 8 0 00-1.7-1L15 3h-4l-.3 2.5a8 8 0 00-1.7 1l-2.4-1-2 3.5L6.6 11a7.97 7.97 0 000 2l-2 1.5 2 3.5 2.4-1a8 8 0 001.7 1L11 21h4l.3-2.5a8 8 0 001.7-1l2.4 1 2-3.5-2-1.5z"/></svg>',
    store: '<svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8h12l-1 12H7L6 8z"/><path d="M9 8V6a3 3 0 016 0v2"/></svg>',
    flame: '<svg width="40" height="40" viewBox="0 0 18 18" fill="none"><path d="M9 2C9 2 5 6.5 5 10a4 4 0 008 0c0-2-1.5-4-4-8z" fill="#e8d5a3" opacity="0.9"/><path d="M9 10c0 0-1.5 1-1.5 2.5a1.5 1.5 0 003 0C10.5 11 9 10 9 10z" fill="#fff" opacity="0.85"/></svg>'
  };

  var PWG_SLIDES = [
    {
      icon: PWG_ICONS.welcome,
      heading: 'Welcome to Your Practice Player',
      desc: 'This is where you listen to, pronounce and master every word in your daily routine. Let’s walk through exactly how it works — button by button.'
    },
    {
      icon: PWG_ICONS.listen,
      heading: 'Listen & Navigate',
      desc: 'Tap the centre Play button to hear the word pronounced aloud. Use the arrows on either side to move to the Previous or Next word, and tap Replay anytime to hear it again.'
    },
    {
      icon: PWG_ICONS.practice,
      heading: 'Practice & Get Scored',
      desc: 'Tap Practice to record your own voice saying the word. Each syllable lights up as you speak it, and you get an instant pronunciation score — the more you repeat, the more it builds your streak.'
    },
    {
      icon: PWG_ICONS.library,
      heading: 'Build Your Library & Sentences',
      desc: 'Tap the Library icon to open every word you’ve unlocked. Every word you purchase is added here automatically — combine them to build your own healing sentences, saved for practice anytime.'
    },
    {
      icon: PWG_ICONS.settings,
      heading: 'Word Info & Player Settings',
      desc: 'Tap the info icon to see the word’s meaning, the organ it benefits, and healing detail. Tap the settings gear to switch the voice (male or female), turn Loop on, or change your rep target.'
    },
    {
      icon: PWG_ICONS.store,
      heading: 'Grow Your Collection',
      desc: 'Tap the Store icon anytime to buy new words and meanings — every purchase instantly joins your Library, so you can keep expanding your personal word ritual.'
    },
    {
      icon: PWG_ICONS.flame,
      heading: 'You’re All Set',
      desc: 'That’s everything you need to know. Tap Begin to start your first practice session.',
      final: true
    }
  ];

  var _pwgIdx = 0;
  var _pwgOnDone = null;

  function pwgSlideHtml(s, i) {
    return (
      '<div class="pwg-slide' + (i === 0 ? ' active' : '') + '" data-i="' + i + '">' +
        '<div class="pwg-illus"><div class="pwg-illus-icon">' + s.icon + '</div></div>' +
        '<div class="pwg-text">' +
          '<div class="pwg-heading">' + s.heading + '</div>' +
          '<div class="pwg-desc">' + s.desc + '</div>' +
        '</div>' +
      '</div>'
    );
  }

  window.renderPwGuide = function (onDone) {
    var body = document.getElementById('practiceBody');
    if (!body) { if (typeof onDone === 'function') onDone(); return; }
    _pwgIdx = 0;
    _pwgOnDone = onDone;

    var dots = PWG_SLIDES.map(function (s, i) {
      return '<div class="pwg-dot' + (i === 0 ? ' active' : '') + '" data-i="' + i + '"></div>';
    }).join('');

    body.innerHTML =
      '<div class="pwg-screen">' +
        '<div class="pwg-header">' +
          '<div class="pwg-close" onclick="pwgSkip()"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg></div>' +
          '<div class="pwg-title">Player Guide</div>' +
        '</div>' +
        PWG_SLIDES.map(pwgSlideHtml).join('') +
        '<div class="pwg-footer">' +
          '<div class="pwg-dots" id="pwgDots">' + dots + '</div>' +
          '<div class="pwg-nav" id="pwgNav"></div>' +
        '</div>' +
      '</div>';

    pwgRenderNav();
  };

  function pwgRenderNav() {
    var nav = document.getElementById('pwgNav');
    if (!nav) return;
    var isLast = _pwgIdx === PWG_SLIDES.length - 1;
    var backBtn = _pwgIdx > 0
      ? '<div class="pwg-nav-btn pwg-nav-back" onclick="pwgBack()"><svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M19 12H5M12 19l-7-7 7-7" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg></div>'
      : '';
    if (isLast) {
      nav.innerHTML = backBtn +
        '<div class="pwg-final-btn" onclick="pwgFinish()" style="flex:1;">Begin' +
          '<svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M3 7H11M7 3L11 7L7 11" stroke="#060c18" stroke-width="1.8" stroke-linecap="square"/></svg>' +
        '</div>';
      nav.style.width = '100%';
    } else {
      nav.style.width = '';
      nav.innerHTML = backBtn +
        '<div class="pwg-nav-btn pwg-nav-fwd" onclick="pwgNext()"><svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M5 12h14M12 5l7 7-7 7" stroke="#0a0f1e" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg></div>';
    }
  }

  function pwgShow(i) {
    _pwgIdx = i;
    document.querySelectorAll('.pwg-slide').forEach(function (el) {
      el.classList.toggle('active', parseInt(el.getAttribute('data-i'), 10) === i);
    });
    document.querySelectorAll('.pwg-dot').forEach(function (el) {
      el.classList.toggle('active', parseInt(el.getAttribute('data-i'), 10) === i);
    });
    pwgRenderNav();
  }

  window.pwgNext = function () { if (_pwgIdx < PWG_SLIDES.length - 1) pwgShow(_pwgIdx + 1); };
  window.pwgBack = function () { if (_pwgIdx > 0) pwgShow(_pwgIdx - 1); };

  function pwgMarkSeen() {
    try { localStorage.setItem('nwsb_player_guide_seen', '1'); } catch (e) {}
    if (window._userDataCache) window._userDataCache.playerGuideSeen = true;
    if (window._currentUid && window._fbSetDoc) {
      window._fbSetDoc(window._currentUid, { playerGuideSeen: true }).catch(function () {});
    }
  }

  window.pwgFinish = function () {
    pwgMarkSeen();
    var cb = _pwgOnDone;
    _pwgOnDone = null;
    if (typeof cb === 'function') cb();
  };
  window.pwgSkip = window.pwgFinish;

  window.pwgShouldShow = function () {
    // TEMP-DEBUG: always show, ignoring the seen-flag below — for now, so
    // it can be reviewed every session. Remove this early return to
    // restore normal once-ever behavior.
    if (true) return true;
    try { if (localStorage.getItem('nwsb_player_guide_seen') === '1') return false; } catch (e) {}
    if (window._userDataCache && window._userDataCache.playerGuideSeen) return false;
    return true;
  };

  // Manual replay — reachable anytime from Settings > Intro Pages > Player Guide.
  // Does not touch the seen-flag on open (only pwgFinish marks it, same as first run).
  window.pwgReplay = function () {
    if (typeof openSub === 'function') openSub('practice');
    setTimeout(function () {
      window.renderPwGuide(function () {
        if (typeof renderPracticeIntro === 'function') renderPracticeIntro();
        else if (typeof renderPractice === 'function') renderPractice();
      });
    }, 80);
  };

})();
