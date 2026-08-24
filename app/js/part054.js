// Player Guide — one-time-ever walkthrough shown the first time a user ever
// enters the practice player, before anything else loads. Explains every
// button in the Liquid Glass Player. Uses the "pwg" prefix (Practice-Walkthrough-Guide)
// to avoid collision with the unrelated coach-mark system in part022.js (which
// already owns the "pg" prefix — pgShow/pgClose/pgMarkSeen/pgSchedule).
(function () {

  // Header badge (top-right, small) per slide: Listen/Record/Library/
  // Settings/Store reuse the exact same chrome-orb button images the real
  // Liquid Glass Player uses (nowssb-player.js's IC map + its inline
  // store-icon URL) — so the guide's badge shows the literal button the
  // user will tap. "playerBrand" is the same icon used for the "NowssB
  // Player" row on the Quick Access menu — the guide's own identity.
  var PWG_ICONS = {
    playerBrand: '<img src="https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/2ab8b4bbd1a045b068da1fb6b6781158ca16fa948a8a67f1038b8449f5499996.webp" style="width:70px;height:70px;object-fit:contain;" alt="">',
    listen: '<img src="https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/74d38b3c7b69b30b2c50cf8b4c45c700fd3de0720dc8f4308c6ebf266a3e0a87.png" style="width:70px;height:70px;object-fit:contain;" alt="">',
    practice: '<img src="https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/a8a2eb1bb04d59d13da0555e497160e43f19fc651e90426a8901650a10ca838b.png" style="width:70px;height:70px;object-fit:contain;" alt="">',
    library: '<img src="https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/643dd804e986b5f6bfa1c5cc431958f35659b7bcdb86cb07ae7dafb275e77346.png" style="width:70px;height:70px;object-fit:contain;" alt="">',
    settings: '<img src="https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/909b614a4f984b774551ffc7076a62c79a7ff2c49cde35ccbb88f2195ad74ae2.png" style="width:70px;height:70px;object-fit:contain;" alt="">',
    store: '<img src="https://nowssb-api.ribonpatil2.workers.dev/media/media/repo/assets/icons/logo-disc.webp" style="width:70px;height:70px;object-fit:contain;" alt="">',
    flame: '<svg width="40" height="40" viewBox="0 0 18 18" fill="none"><path d="M9 2C9 2 5 6.5 5 10a4 4 0 008 0c0-2-1.5-4-4-8z" fill="#e8d5a3" opacity="0.9"/><path d="M9 10c0 0-1.5 1-1.5 2.5a1.5 1.5 0 003 0C10.5 11 9 10 9 10z" fill="#fff" opacity="0.85"/></svg>',
    playerReady: '<img src="https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/dc638b945c082954c3ace9d76ee56338fa35bba7fdeaadd8594dfdf0b71fdbfc.png" style="width:70px;height:70px;object-fit:contain;" alt="">'
  };

  // Illustration card background — placeholder for now (reusing an
  // existing app asset, the Today's Practice "Morning" banner) until real
  // per-slide photography is supplied; swap PWG_SLIDES[i].img then.
  var PWG_PLACEHOLDER_IMG = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/4daad1a85b624fed6e165ae7b21c0214bccb203b2bcdcaa2966bf961021431f7.webp';
  // Same "NowssB Player" art as the header badge — used as the final
  // slide's card image too (raw URL, since the card sets it via CSS
  // background-image rather than an <img> tag).
  var PWG_PLAYER_BRAND_IMG = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/2ab8b4bbd1a045b068da1fb6b6781158ca16fa948a8a67f1038b8449f5499996.webp';
  // Per-slide illustration photography, supplied for the welcome,
  // Signature Word, Player Store and Player Ready slides.
  var PWG_WELCOME_IMG = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/2ec9ad4747c6b76db9b104cf19ba003ae459edcc586e87ed9989ed425785f7ed.png';
  var PWG_SIGNATURE_IMG = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/f3c17b36e07098ec54f5d3702e18b4f6bbc36e96774d89b61c0b532ef97113cc.png';
  var PWG_READY_IMG = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/9f4113b898ea8bfe5e0017ce6b980a0d87d4fa97e623a437e7f01697c95c22a2.png';
  var PWG_STORE_IMG = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/5808c91d1975b9fae1858c79d81a907ef367fc4ead68b305624c87a287139cff.png';
  var PWG_PRACTICE_IMG = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/2c3aae23bdda443d2e95d3fe8d7bf52f5cc9e7f6a1d16808058955ee129b0dc2.png';
  var PWG_LISTEN_IMG = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/8f6e22d3e27e8f8297df5cef9dfa17e9a8d7e7d00b76e1fe4fe14469be3478a4.png';
  var PWG_SETTINGS_IMG = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/db763251a11604b46901914f7c5fc0bf26ee038a425ce692b9097b446cfb18de.png';
  var PWG_LIBRARY_IMG = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/d21b96de1967b542883b772ac5414a68deeeef28c311dcdd30c46dfb89211aae.png';

  var PWG_SLIDES = [
    {
      title: 'NowssB Player Guide',
      icon: PWG_ICONS.playerBrand,
      img: PWG_WELCOME_IMG,
      heading: 'Welcome to Your Practice Player',
      desc: 'This is where you listen to, pronounce and master every word in your daily routine. Let’s walk through exactly how it works — button by button.'
    },
    {
      title: 'Player Listen',
      icon: PWG_ICONS.listen,
      img: PWG_LISTEN_IMG,
      heading: 'Listen & Navigate',
      desc: 'Tap the centre Play button to hear the word pronounced aloud. Use the arrows on either side to move to the Previous or Next word, and tap Replay anytime to hear it again.'
    },
    {
      title: 'Player Record',
      icon: PWG_ICONS.practice,
      img: PWG_PRACTICE_IMG,
      heading: 'Practice & Get Scored',
      desc: 'Tap Practice to record your own voice saying the word. Each syllable lights up as you speak it, and you get an instant pronunciation score — the more you repeat, the more it builds your streak.'
    },
    {
      title: 'Player Library',
      icon: PWG_ICONS.library,
      img: PWG_LIBRARY_IMG,
      heading: 'Build Your Library & Sentences',
      desc: 'Tap the Library icon to open every word you’ve unlocked. Every word you purchase is added here automatically — combine them to build your own healing sentences, saved for practice anytime.'
    },
    {
      title: 'Player Settings',
      icon: PWG_ICONS.settings,
      img: PWG_SETTINGS_IMG,
      heading: 'Word Info & Player Settings',
      desc: 'Tap the info icon to see the word’s meaning, the organ it benefits, and healing detail. Tap the settings gear to switch the voice (male or female), turn Loop on, or change your rep target.'
    },
    {
      title: 'Player Store',
      icon: PWG_ICONS.store,
      img: PWG_STORE_IMG,
      heading: 'Grow Your Collection',
      desc: 'Tap the Store icon anytime to buy new words and meanings — every purchase instantly joins your Library, so you can keep expanding your personal word ritual.'
    },
    {
      title: 'Signature Word',
      icon: PWG_ICONS.store,
      img: PWG_SIGNATURE_IMG,
      heading: 'Unlock a Signature Word',
      desc: 'Signature words are the rarest word in each category — one per set, own only in a special gold edition. Look for the Signature tag in the Store to add one to your collection.'
    },
    {
      title: 'Player Ready',
      icon: PWG_ICONS.playerReady,
      img: PWG_READY_IMG,
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
        '<div class="pwg-illus-bg" style="background-image:url(\'' + s.img + '\')"></div>' +
        '<div class="pwg-illus-fade"></div>' +
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
        '<div class="pwg-slides-wrap">' +
          PWG_SLIDES.map(pwgSlideHtml).join('') +
        '</div>' +
        '<div class="pwg-header">' +
          '<div class="pwg-close" onclick="pwgSkip()"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg></div>' +
          '<div class="pwg-title" id="pwgTitle">' + PWG_SLIDES[0].title + '</div>' +
          '<div style="flex:1;"></div>' +
          '<div class="pwg-header-icon" id="pwgHeaderIcon">' + PWG_SLIDES[0].icon + '</div>' +
        '</div>' +
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
