// Player Guide — one-time-ever walkthrough shown the first time a user ever
// enters the practice player, before anything else loads. Explains every
// button in the Liquid Glass Player. Uses the "pwg" prefix (Practice-Walkthrough-Guide)
// to avoid collision with the unrelated coach-mark system in part022.js (which
// already owns the "pg" prefix — pgShow/pgClose/pgMarkSeen/pgSchedule).
(function () {

  // Listen/Record/Library/Settings/Store reuse the exact same chrome-orb
  // button images the real Liquid Glass Player uses (nowssb-player.js's IC
  // map + its inline store-icon URL) — so the guide shows the literal
  // button the user will tap, not a generic lookalike icon.
  var PWG_ICONS = {
    welcome: '<svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M4 14v-2a8 8 0 0116 0v2"/><rect x="2" y="14" width="5" height="7" rx="2"/><rect x="17" y="14" width="5" height="7" rx="2"/></svg>',
    listen: '<img src="https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718777/e06d2880-7389-11f1-8c74-0593c060acc9_jy24tl.png" style="width:70px;height:70px;object-fit:contain;" alt="">',
    practice: '<img src="https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718779/27cbc180-7387-11f1-ac66-23a66b2b6053_mf6jdr.png" style="width:70px;height:70px;object-fit:contain;" alt="">',
    library: '<img src="https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718780/3259c840-7387-11f1-ac66-23a66b2b6053_ikqafa.png" style="width:70px;height:70px;object-fit:contain;" alt="">',
    settings: '<img src="https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718779/f90f56e0-7386-11f1-ac66-23a66b2b6053_n5ahnk.png" style="width:70px;height:70px;object-fit:contain;" alt="">',
    store: '<img src="https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782729222/file_00000000b86c7207988c04376fd0529c_dunq9l.png" style="width:70px;height:70px;object-fit:contain;" alt="">',
    flame: '<svg width="40" height="40" viewBox="0 0 18 18" fill="none"><path d="M9 2C9 2 5 6.5 5 10a4 4 0 008 0c0-2-1.5-4-4-8z" fill="#e8d5a3" opacity="0.9"/><path d="M9 10c0 0-1.5 1-1.5 2.5a1.5 1.5 0 003 0C10.5 11 9 10 9 10z" fill="#fff" opacity="0.85"/></svg>'
  };

  var PWG_SLIDES = [
    {
      title: 'NowssB Player Guide',
      icon: PWG_ICONS.welcome,
      heading: 'Welcome to Your Practice Player',
      desc: 'This is where you listen to, pronounce and master every word in your daily routine. Let’s walk through exactly how it works — button by button.'
    },
    {
      title: 'Player Listen',
      icon: PWG_ICONS.listen,
      heading: 'Listen & Navigate',
      desc: 'Tap the centre Play button to hear the word pronounced aloud. Use the arrows on either side to move to the Previous or Next word, and tap Replay anytime to hear it again.'
    },
    {
      title: 'Player Record',
      icon: PWG_ICONS.practice,
      heading: 'Practice & Get Scored',
      desc: 'Tap Practice to record your own voice saying the word. Each syllable lights up as you speak it, and you get an instant pronunciation score — the more you repeat, the more it builds your streak.'
    },
    {
      title: 'Player Library',
      icon: PWG_ICONS.library,
      heading: 'Build Your Library & Sentences',
      desc: 'Tap the Library icon to open every word you’ve unlocked. Every word you purchase is added here automatically — combine them to build your own healing sentences, saved for practice anytime.'
    },
    {
      title: 'Player Settings',
      icon: PWG_ICONS.settings,
      heading: 'Word Info & Player Settings',
      desc: 'Tap the info icon to see the word’s meaning, the organ it benefits, and healing detail. Tap the settings gear to switch the voice (male or female), turn Loop on, or change your rep target.'
    },
    {
      title: 'Player Store',
      icon: PWG_ICONS.store,
      heading: 'Grow Your Collection',
      desc: 'Tap the Store icon anytime to buy new words and meanings — every purchase instantly joins your Library, so you can keep expanding your personal word ritual.'
    },
    {
      title: 'Player Ready',
      icon: PWG_ICONS.flame,
      heading: 'You’re All Set',
      desc: 'That’s everything you need to know. Tap Begin to start your first practice session.',
      final: true
    }
  ];

  var _pwgIdx = 0;
  var _pwgOnDone = null;

  function pwgSlideHtml(s, i) {
    var tryAction = (i === PWG_SLIDES.length - 1) ? 'pwgFinish()' : 'pwgNext()';
    return (
      '<div class="pwg-slide' + (i === 0 ? ' active' : '') + '" data-i="' + i + '">' +
        '<div class="pwg-illus"><div class="pwg-illus-icon">' + s.icon + '</div></div>' +
        '<div class="pwg-text">' +
          '<div class="pwg-heading">' + s.heading + '</div>' +
          '<div class="pwg-desc">' + s.desc + '</div>' +
          '<div class="pwg-try-link" onclick="' + tryAction + '">' +
            '<svg width="15" height="15" viewBox="0 0 24 24" fill="none"><path d="M5 12h14M12 5l7 7-7 7" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>' +
            'Try it now' +
          '</div>' +
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
          '<div class="pwg-title" id="pwgTitle">' + PWG_SLIDES[0].title + '</div>' +
          '<div style="flex:1;"></div>' +
          '<div class="pwg-header-icon" id="pwgHeaderIcon">' + PWG_SLIDES[0].icon + '</div>' +
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
        '<div class="pwg-final-btn" onclick="pwgFinish()">Begin' +
          '<svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M3 7H11M7 3L11 7L7 11" stroke="#060c18" stroke-width="1.8" stroke-linecap="square"/></svg>' +
        '</div>';
    } else {
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
    var titleEl = document.getElementById('pwgTitle');
    if (titleEl) titleEl.textContent = PWG_SLIDES[i].title;
    var headerIconEl = document.getElementById('pwgHeaderIcon');
    if (headerIconEl) headerIconEl.innerHTML = PWG_SLIDES[i].icon;
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
