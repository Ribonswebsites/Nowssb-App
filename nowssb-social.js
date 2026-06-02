/* ═══════════════════════════════════════════════════════════════
   NowssB Social — Phase 1: Visual Redesign + Social Home
   Patches the IG controller (app/js/part033.js) at runtime.
   HTML stays in index.html; all CSS overrides in nowssb-social.css.
═══════════════════════════════════════════════════════════════ */
(function () {

  /* ── Headphone SVG (replaces Instagram blue verified check) ── */
  var HP_SVG_TIER = '<svg class="nwsb-badge-hp nwsb-badge-tier" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18v-6a9 9 0 0118 0v6"/><path d="M21 19a2 2 0 01-2 2h-1a2 2 0 01-2-2v-3a2 2 0 012-2h3z"/><path d="M3 19a2 2 0 002 2h1a2 2 0 002-2v-3a2 2 0 00-2-2H3z"/></svg>';
  var HP_SVG_ULT  = '<svg class="nwsb-badge-hp nwsb-badge-ult" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18v-6a9 9 0 0118 0v6"/><path d="M21 19a2 2 0 01-2 2h-1a2 2 0 01-2-2v-3a2 2 0 012-2h3z"/><path d="M3 19a2 2 0 002 2h1a2 2 0 002-2v-3a2 2 0 00-2-2H3z"/></svg>';
  var HP_SVG_MASS = '<svg class="nwsb-badge-hp nwsb-badge-massive" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18v-6a9 9 0 0118 0v6"/><path d="M21 19a2 2 0 01-2 2h-1a2 2 0 01-2-2v-3a2 2 0 012-2h3z"/><path d="M3 19a2 2 0 002 2h1a2 2 0 002-2v-3a2 2 0 00-2-2H3z"/></svg>';

  /* ── VERIFY — determine badge level ── */
  window.VERIFY = {
    level: function (userData) {
      if (!userData) return 'none';
      var words = userData.wordsOwnedCount || 0;
      var sents = userData.sentencesCount  || 0;
      if (userData.verifyPurchased)    return 'massive';
      if (words >= 1000 && sents >= 1000) return 'massive';
      if (words >= 50   && sents >= 50)   return 'ultimate';
      var t = userData.tier || '';
      if (t === 'frequencyX' || t === 'frequency' || t === 'resonance' || userData.isPro) return 'tier';
      return 'none';
    },
    badge: function (userData) {
      var lv = this.level(userData);
      if (lv === 'massive')  return HP_SVG_MASS;
      if (lv === 'ultimate') return HP_SVG_ULT;
      if (lv === 'tier')     return HP_SVG_TIER;
      return '';
    }
  };

  /* ── Patch IG verified SVG once IG is loaded ── */
  function patchVerified() {
    if (!window.IG) { return setTimeout(patchVerified, 120); }
    /* Store the headphone SVG so renderProfile / renderUserRow pick it up */
    window.IG._nwsbVerifiedSvg = HP_SVG_ULT;
  }
  patchVerified();

  /* ── Social Home rendering ── */
  function renderSocialHome() {
    var box = document.getElementById('nwsb-social-home-content');
    if (!box) return;

    var ud = window._userDataCache || {};
    var words    = ud.wordsOwnedCount || ud.words    || 0;
    var sessions = ud.sessionsCount   || ud.sessions || 0;
    var score    = ud.avgScore        || ud.score    || 0;
    var streak   = ud.streak          || 0;

    /* Suggested people — reuse IG._allPeople if loaded */
    var people = (window.IG && window.IG._allPeople) ? window.IG._allPeople.slice(0, 5) : [];
    var peopleHtml = people.map(function (p) {
      var initials = (p.fullName || p.username || '?').charAt(0).toUpperCase();
      var av = p.avatar
        ? '<img src="' + p.avatar + '" class="ig-av" style="width:44px;height:44px;border-radius:50%!important;object-fit:cover;flex-shrink:0;" loading="lazy" decoding="async">'
        : '<div style="width:44px;height:44px;border-radius:50%!important;background:#1a1a2e;display:flex;align-items:center;justify-content:center;flex-shrink:0;"><span style="color:#e8d5a3;font-size:16px;font-weight:700;font-family:\'DM Sans\',sans-serif;">' + initials + '</span></div>';
      var badge = VERIFY.badge(p);
      return '<div class="ig-userrow" onclick="IG.openProfile(' + p.id + ')" style="cursor:pointer;">' +
        av +
        '<div class="ig-meta" style="flex:1;min-width:0;">' +
          '<div class="ig-u" style="display:flex;align-items:center;gap:5px;">' + (p.username || '') + badge + '</div>' +
          '<div class="ig-n">' + (p.category || '') + '</div>' +
        '</div>' +
        '<button class="ig-mini-follow' + (p.following_state ? ' following' : '') + '" ' +
          'onclick="event.stopPropagation();IG.toggleFollowMini(' + p.id + ',this)">' +
          (p.following_state ? 'Following' : 'Follow') +
        '</button>' +
      '</div>';
    }).join('');

    /* Placeholder reel thumbnails */
    var demoWords = ['PRANA', 'SHAKTI', 'OJAS', 'TEJAS', 'SOMA'];
    var reelThumbsHtml = demoWords.map(function (w) {
      return '<div class="nwsb-reel-thumb">' +
        '<span class="nwsb-reel-thumb-word">' + w + '</span>' +
      '</div>';
    }).join('');

    box.innerHTML =
      '<div class="nwsb-hero">' +
        '<div class="nwsb-hero-tag">Healing is Fashion</div>' +
        '<div class="nwsb-hero-title">Your Practice,<br>Your Frequency.</div>' +
        '<div class="nwsb-hero-sub">NowssB · Word Science</div>' +
        '<div class="nwsb-hero-stats">' +
          '<div class="nwsb-hero-stat"><span class="nwsb-hero-stat-num">' + words + '</span><span class="nwsb-hero-stat-lbl">Words</span></div>' +
          '<div class="nwsb-hero-stat"><span class="nwsb-hero-stat-num">' + sessions + '</span><span class="nwsb-hero-stat-lbl">Sessions</span></div>' +
          '<div class="nwsb-hero-stat"><span class="nwsb-hero-stat-num">' + (score ? score + '%' : '—') + '</span><span class="nwsb-hero-stat-lbl">Score</span></div>' +
          '<div class="nwsb-hero-stat"><span class="nwsb-hero-stat-num">' + streak + '</span><span class="nwsb-hero-stat-lbl">Streak</span></div>' +
        '</div>' +
      '</div>' +

      '<div class="nwsb-section-hd">Reels · Pronunciation</div>' +
      '<div class="nwsb-reels-strip">' + reelThumbsHtml + '</div>' +

      (people.length ?
        '<div class="nwsb-section-hd">Suggested · Community</div>' +
        '<div class="nwsb-home-people">' + peopleHtml + '</div>'
        : '');
  }

  window._nwsbRenderSocialHome = renderSocialHome;

  /* ── Patch IG.socialNav — 'home' shows social home, not main app home ── */
  function patchSocialNav() {
    if (!window.IG || typeof window.IG.socialNav !== 'function') {
      return setTimeout(patchSocialNav, 120);
    }

    var _orig = window.IG.socialNav.bind(window.IG);

    window.IG.socialNav = function (which) {
      var homeEl = document.getElementById('sub-social-home');

      if (which === 'home') {
        /* Show social home, hide discover + profile */
        if (homeEl) homeEl.classList.add('open');
        var subPeople = document.getElementById('sub-people');
        var subProf   = document.getElementById('sub-ig-profile');
        if (subPeople) subPeople.classList.remove('open');
        if (subProf)   subProf.classList.remove('open');
        /* Activate the Home nav button */
        ['home','feed','profile','chat'].forEach(function (k) {
          var el = document.getElementById('igsn-' + k);
          if (el) el.classList.toggle('active', k === 'home');
        });
        /* Render content */
        renderSocialHome();
        /* Make sure social nav stays visible */
        var sn = document.getElementById('ig-social-nav');
        if (sn) sn.style.display = 'flex';
      } else {
        /* Close social home before handing off to the original handler */
        if (homeEl) homeEl.classList.remove('open');
        _orig(which);
      }
    };
  }
  patchSocialNav();

  /* ── Also patch IG.nav('profile') to start on social home ── */
  function patchNavProfile() {
    if (!window.IG || typeof window.IG.nav !== 'function') {
      return setTimeout(patchNavProfile, 120);
    }
    var _origNav = window.IG.nav.bind(window.IG);
    window.IG.nav = function (which) {
      if (which === 'profile') {
        /* Open social section: swap navs, show social home first */
        var mainNav   = document.getElementById('ig-bottomnav');
        var socialNav = document.getElementById('ig-social-nav');
        if (mainNav)   mainNav.style.display   = 'none';
        if (socialNav) socialNav.style.display = 'flex';

        /* Show social home */
        var homeEl = document.getElementById('sub-social-home');
        if (homeEl) homeEl.classList.add('open');
        var subPeople = document.getElementById('sub-people');
        var subProf   = document.getElementById('sub-ig-profile');
        if (subPeople) subPeople.classList.remove('open');
        if (subProf)   subProf.classList.remove('open');

        /* Mark Home as active */
        ['home','feed','profile','chat'].forEach(function (k) {
          var el = document.getElementById('igsn-' + k);
          if (el) el.classList.toggle('active', k === 'home');
        });

        renderSocialHome();

        /* Sync the main bottom-nav highlight */
        if (typeof setActiveNav === 'function') setActiveNav('profile');
        if (typeof showNav === 'function') showNav(true);
      } else {
        /* Close social home for non-profile navigation */
        var homeEl2 = document.getElementById('sub-social-home');
        if (homeEl2) homeEl2.classList.remove('open');
        _origNav(which);
      }
    };
  }
  patchNavProfile();

})();
