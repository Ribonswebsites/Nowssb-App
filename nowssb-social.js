/* ═══════════════════════════════════════════════════════════════
   NowssB Social — Phase 1+2: Visual Redesign + Reels Engine
   Patches the IG controller (app/js/part033.js) at runtime.
   HTML stays in index.html; all CSS overrides in nowssb-social.css.
═══════════════════════════════════════════════════════════════ */
(function () {

  /* ── Headphone SVG (replaces Instagram blue verified check) ── */
  var HP_SVG_TIER = '<svg class="nwsb-badge-hp nwsb-badge-tier" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18v-6a9 9 0 0118 0v6"/><path d="M21 19a2 2 0 01-2 2h-1a2 2 0 01-2-2v-3a2 2 0 012-2h3z"/><path d="M3 19a2 2 0 002 2h1a2 2 0 002-2v-3a2 2 0 00-2-2H3z"/></svg>';
  var HP_SVG_ULT  = '<svg class="nwsb-badge-hp nwsb-badge-ult" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18v-6a9 9 0 0118 0v6"/><path d="M21 19a2 2 0 01-2 2h-1a2 2 0 01-2-2v-3a2 2 0 012-2h3z"/><path d="M3 19a2 2 0 002 2h1a2 2 0 002-2v-3a2 2 0 00-2-2H3z"/></svg>';
  var HP_SVG_MASS = '<svg class="nwsb-badge-hp nwsb-badge-massive" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18v-6a9 9 0 0118 0v6"/><path d="M21 19a2 2 0 01-2 2h-1a2 2 0 01-2-2v-3a2 2 0 012-2h3z"/><path d="M3 19a2 2 0 002 2h1a2 2 0 002-2v-3a2 2 0 00-2-2H3z"/></svg>';
  var HP_ICON_SVG = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18v-6a9 9 0 0118 0v6"/><path d="M21 19a2 2 0 01-2 2h-1a2 2 0 01-2-2v-3a2 2 0 012-2h3z"/><path d="M3 19a2 2 0 002 2h1a2 2 0 002-2v-3a2 2 0 00-2-2H3z"/></svg>';

  /* ══════════════════════════════════════════════════════════
     VERIFY — badge level system
  ══════════════════════════════════════════════════════════ */
  window.VERIFY = {
    level: function (userData) {
      if (!userData) return 'none';
      var words = userData.wordsOwnedCount || 0;
      var sents = userData.sentencesCount  || 0;
      if (userData.verifyPurchased)           return 'massive';
      if (words >= 1000 && sents >= 1000)     return 'massive';
      if (words >= 50   && sents >= 50)       return 'ultimate';
      var t = userData.tier || '';
      if (t === 'frequencyX' || t === 'frequency' || t === 'resonance' || userData.isPro)
        return 'tier';
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

  /* ── Expose headphone SVG to IG controller ── */
  function patchVerified() {
    if (!window.IG) { return setTimeout(patchVerified, 120); }
    window.IG._nwsbVerifiedSvg = HP_SVG_ULT;
  }
  patchVerified();

  /* ══════════════════════════════════════════════════════════
     REELS ENGINE
  ══════════════════════════════════════════════════════════ */

  /* ── Candidate stored here after scoring ── */
  window._nwsbReelCandidate = null;

  /* ── Hook into pwScoreRecording to capture score + inject button ── */
  function patchScoring() {
    if (typeof window.pwScoreRecording !== 'function') {
      return setTimeout(patchScoring, 200);
    }
    var _origScore = window.pwScoreRecording;
    window.pwScoreRecording = async function () {
      await _origScore.apply(this, arguments);

      /* Score is now in DOM; grab word from PRACTICE_WORDS[_pwIdx] if available */
      var scoreNum = document.getElementById('spScoreNum');
      var score = scoreNum ? parseInt(scoreNum.textContent, 10) : 0;
      if (!score || isNaN(score)) return;

      /* Get current word object safely */
      var wordObj = null;
      try {
        if (typeof PRACTICE_WORDS !== 'undefined' && typeof _pwIdx !== 'undefined') {
          wordObj = PRACTICE_WORDS[_pwIdx];
        }
      } catch (e) { /* not accessible */ }

      if (!wordObj) return;

      /* Block if this is a purchased word */
      var purchased = [];
      try { purchased = JSON.parse(localStorage.getItem('nwsb_purchased') || '[]'); } catch (e) {}
      if (purchased.indexOf(wordObj.word) !== -1) return; /* purchased = no reel posting */

      /* Store candidate */
      window._nwsbReelCandidate = {
        word:      wordObj.word,
        syllables: (wordObj.syllables || []).join(' · '),
        score:     score,
        organ:     wordObj.organ || '',
      };

      /* Inject "Post as Reel" button if not already there */
      var wrap = document.getElementById('spScoreWrap');
      if (!wrap || document.getElementById('nwsb-post-reel-btn')) return;

      var btn = document.createElement('button');
      btn.id        = 'nwsb-post-reel-btn';
      btn.className = 'nwsb-post-reel-btn';
      btn.innerHTML = HP_ICON_SVG + ' Post as Reel';
      btn.onclick   = function () { nwsbPostReel(btn); };
      wrap.appendChild(btn);
    };
  }
  patchScoring();

  /* ── Post reel to Firestore ── */
  window.nwsbPostReel = function (btn) {
    var cand = window._nwsbReelCandidate;
    if (!cand) return;
    if (!window._currentUid || !window._fbAddReelDoc) {
      alert('Sign in to post reels.');
      return;
    }

    btn.disabled   = true;
    btn.textContent = 'Posting…';

    var ud = window._userDataCache || {};
    window._fbAddReelDoc({
      uid:       window._currentUid,
      name:      ud.displayName || 'Practitioner',
      photoURL:  ud.photoURL    || '',
      word:      cand.word,
      syllables: cand.syllables,
      score:     cand.score,
      organ:     cand.organ,
      wordTier:  (ud.tier || 'resonance'),
    }).then(function () {
      btn.textContent = '✓ Posted';
      /* Refresh home reels strip */
      if (document.getElementById('sub-social-home').classList.contains('open')) {
        renderSocialHome();
      }
    }).catch(function (e) {
      btn.disabled   = false;
      btn.innerHTML  = HP_ICON_SVG + ' Post as Reel';
      console.warn('Post reel error:', e);
    });
  };

  /* ── Build one reel card HTML ── */
  function reelCardHtml(r) {
    var initials = (r.name || '?').charAt(0).toUpperCase();
    var avHtml = r.photoURL
      ? '<img src="' + r.photoURL + '" class="nwsb-reel-av" alt="" loading="lazy" decoding="async">'
      : '<div class="nwsb-reel-av-init">' + initials + '</div>';

    var bgHtml = r.photoURL
      ? '<img src="' + r.photoURL + '" class="nwsb-reel-card-bg" alt="" loading="lazy" decoding="async">'
      : '';

    var scoreColor = r.score >= 80 ? '#e8d5a3' : r.score >= 55 ? '#c8e8f5' : 'rgba(255,255,255,.5)';

    return '<div class="nwsb-reel-card">' +
      bgHtml +
      '<div class="nwsb-reel-card-body">' +
        '<div class="nwsb-reel-word">' + (r.word || '') + '</div>' +
        (r.syllables ? '<div class="nwsb-reel-syllables">' + r.syllables + '</div>' : '') +
        '<div class="nwsb-reel-score-row">' +
          '<div class="nwsb-reel-score-pill">' +
            '<span class="nwsb-reel-score-num" style="color:' + scoreColor + ';">' + (r.score || 0) + '</span>' +
            '<span class="nwsb-reel-score-suffix">/100</span>' +
          '</div>' +
        '</div>' +
        '<div class="nwsb-reel-user-row">' +
          avHtml +
          '<span class="nwsb-reel-username">' + (r.name || 'Practitioner') + '</span>' +
        '</div>' +
      '</div>' +
    '</div>';
  }

  /* ── Render reels feed into a container element ── */
  window.nwsbRenderReelsFeed = async function (containerId, opts) {
    var box = document.getElementById(containerId);
    if (!box) return;
    box.innerHTML = '<div style="padding:30px;text-align:center;color:rgba(255,255,255,.3);font-family:\'DM Sans\',sans-serif;font-size:13px;">Loading reels…</div>';

    try {
      if (!window._fbGetReels) throw new Error('Firestore not ready');
      var reels = await window._fbGetReels(opts || {});

      if (!reels.length) {
        box.innerHTML =
          '<div class="nwsb-reels-empty">' +
            '<div class="nwsb-reels-empty-title">No reels yet</div>' +
            '<div class="nwsb-reels-empty-sub">Practice a word and tap "Post as Reel" after scoring to share your pronunciation.</div>' +
          '</div>';
        return;
      }
      box.innerHTML = reels.map(reelCardHtml).join('');
    } catch (e) {
      box.innerHTML =
        '<div class="nwsb-reels-empty">' +
          '<div class="nwsb-reels-empty-title">Could not load reels</div>' +
          '<div class="nwsb-reels-empty-sub">Check your connection and try again.</div>' +
        '</div>';
    }
  };

  /* ══════════════════════════════════════════════════════════
     SOCIAL HOME rendering
  ══════════════════════════════════════════════════════════ */
  function renderSocialHome() {
    var box = document.getElementById('nwsb-social-home-content');
    if (!box) return;

    var ud       = window._userDataCache || {};
    var words    = ud.wordsOwnedCount || ud.words    || 0;
    var sessions = ud.sessionsCount   || ud.sessions || 0;
    var score    = ud.avgScore        || ud.score    || 0;
    var streak   = ud.streak          || 0;

    var people     = (window.IG && window.IG._allPeople) ? window.IG._allPeople.slice(0, 5) : [];
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

    box.innerHTML =
      '<div class="nwsb-hero">' +
        '<div class="nwsb-hero-tag">Healing is Fashion</div>' +
        '<div class="nwsb-hero-title">Your Practice,<br>Your Frequency.</div>' +
        '<div class="nwsb-hero-sub">NowssB · Word Science</div>' +
        '<div class="nwsb-hero-stats">' +
          '<div class="nwsb-hero-stat"><span class="nwsb-hero-stat-num">' + words    + '</span><span class="nwsb-hero-stat-lbl">Words</span></div>' +
          '<div class="nwsb-hero-stat"><span class="nwsb-hero-stat-num">' + sessions + '</span><span class="nwsb-hero-stat-lbl">Sessions</span></div>' +
          '<div class="nwsb-hero-stat"><span class="nwsb-hero-stat-num">' + (score ? score + '%' : '—') + '</span><span class="nwsb-hero-stat-lbl">Score</span></div>' +
          '<div class="nwsb-hero-stat"><span class="nwsb-hero-stat-num">' + streak   + '</span><span class="nwsb-hero-stat-lbl">Streak</span></div>' +
        '</div>' +
      '</div>' +

      '<div class="nwsb-section-hd">Reels · Pronunciation</div>' +
      '<div id="nwsb-home-reels-strip" class="nwsb-reels-strip">' +
        '<div style="padding:20px 0;color:rgba(255,255,255,.25);font-family:\'DM Sans\',sans-serif;font-size:12px;">Loading…</div>' +
      '</div>' +

      (people.length
        ? '<div class="nwsb-section-hd">Suggested · Community</div>' +
          '<div class="nwsb-home-people">' + peopleHtml + '</div>'
        : '');

    /* Async-load real reels into the strip */
    if (window._fbGetReels) {
      window._fbGetReels({ limit: 6 }).then(function (reels) {
        var strip = document.getElementById('nwsb-home-reels-strip');
        if (!strip) return;
        if (!reels.length) {
          strip.innerHTML = '<div style="padding:16px 0;color:rgba(255,255,255,.25);font-family:\'DM Sans\',sans-serif;font-size:12px;">Be the first — practice a word and post a reel.</div>';
          return;
        }
        strip.innerHTML = reels.map(function (r) {
          return '<div class="nwsb-reel-thumb" onclick="IG.socialNav(\'feed\')" style="cursor:pointer;">' +
            (r.photoURL ? '<img src="' + r.photoURL + '" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover;" loading="lazy" decoding="async">' : '') +
            '<span class="nwsb-reel-thumb-word">' + (r.word || '') + '</span>' +
          '</div>';
        }).join('');
      }).catch(function () {});
    }
  }

  window._nwsbRenderSocialHome = renderSocialHome;

  /* ══════════════════════════════════════════════════════════
     SOCIAL NAV PATCHES
  ══════════════════════════════════════════════════════════ */

  /* Helper — hide all social sub-screens */
  function hideSocialScreens() {
    ['sub-social-home', 'sub-reels-feed', 'sub-people', 'sub-ig-profile'].forEach(function (id) {
      var el = document.getElementById(id);
      if (el) el.classList.remove('open');
    });
  }

  /* Helper — set social nav active button */
  function setSocialActive(which) {
    ['home', 'feed', 'profile', 'chat'].forEach(function (k) {
      var el = document.getElementById('igsn-' + k);
      if (el) el.classList.toggle('active', k === which);
    });
  }

  /* Patch IG.socialNav */
  function patchSocialNav() {
    if (!window.IG || typeof window.IG.socialNav !== 'function') {
      return setTimeout(patchSocialNav, 120);
    }
    var _orig = window.IG.socialNav.bind(window.IG);

    window.IG.socialNav = function (which) {
      var sn = document.getElementById('ig-social-nav');
      if (sn) sn.style.display = 'flex';

      if (which === 'home') {
        hideSocialScreens();
        var homeEl = document.getElementById('sub-social-home');
        if (homeEl) homeEl.classList.add('open');
        setSocialActive('home');
        renderSocialHome();

      } else if (which === 'feed') {
        hideSocialScreens();
        var feedEl = document.getElementById('sub-reels-feed');
        if (feedEl) feedEl.classList.add('open');
        setSocialActive('feed');
        window.nwsbRenderReelsFeed('reels-feed-content');

      } else if (which === 'profile') {
        hideSocialScreens();
        setSocialActive('profile');
        /* Open discover (explore grid) */
        var subPeople = document.getElementById('sub-people');
        if (subPeople) subPeople.classList.add('open');
        if (window.IG && typeof window.IG.openExplore === 'function') {
          /* call underlying explore without triggering our patched nav */
          var grid = document.getElementById('sub-ig-profile');
          if (grid) grid.classList.remove('open');
          var sc = document.getElementById('ig-people-scroll');
          if (sc) sc.scrollTop = 0;
          /* renderExplore is a private fn inside IG closure — trigger via openExplore */
          if (typeof renderExplore === 'function') renderExplore();
          window.IG.clearSearch && window.IG.clearSearch();
        }

      } else if (which === 'chat') {
        setSocialActive('chat');
        if (typeof chatInboxOpen === 'function') chatInboxOpen();

      } else {
        _orig(which);
      }
    };
  }
  patchSocialNav();

  /* Patch IG.nav('profile') to open social home first */
  function patchNavProfile() {
    if (!window.IG || typeof window.IG.nav !== 'function') {
      return setTimeout(patchNavProfile, 120);
    }
    var _origNav = window.IG.nav.bind(window.IG);
    window.IG.nav = function (which) {
      if (which === 'profile') {
        var mainNav   = document.getElementById('ig-bottomnav');
        var socialNav = document.getElementById('ig-social-nav');
        if (mainNav)   mainNav.style.display   = 'none';
        if (socialNav) socialNav.style.display = 'flex';

        hideSocialScreens();
        var homeEl = document.getElementById('sub-social-home');
        if (homeEl) homeEl.classList.add('open');
        setSocialActive('home');
        renderSocialHome();

        if (typeof setActiveNav === 'function') setActiveNav('profile');
        if (typeof showNav      === 'function') showNav(true);
      } else {
        var homeEl2 = document.getElementById('sub-social-home');
        if (homeEl2) homeEl2.classList.remove('open');
        var feedEl2 = document.getElementById('sub-reels-feed');
        if (feedEl2) feedEl2.classList.remove('open');
        _origNav(which);
      }
    };
  }
  patchNavProfile();

  /* ══════════════════════════════════════════════════════════
     Profile reels tab — render user's own reels
  ══════════════════════════════════════════════════════════ */
  function patchProfTab() {
    if (!window.IG) { return setTimeout(patchProfTab, 120); }

    /* Wrap the existing profTab function (it lives in the IG closure as IG.profTab) */
    var _origTab = window.IG.profTab;
    if (typeof _origTab !== 'function') return;

    window.IG.profTab = function (tab) {
      _origTab.call(this, tab);
      if (tab === 'reels') {
        var uid = (window.IG._currentProfile && !window.IG._currentProfile.self)
          ? window.IG._currentProfile.uid
          : window._currentUid;

        var grid = document.getElementById('ig-prof-grid');
        if (!grid) return;

        /* Replace grid content with reel cards */
        grid.innerHTML = '<div style="padding:20px;text-align:center;color:rgba(255,255,255,.3);font-family:\'DM Sans\',sans-serif;font-size:13px;">Loading reels…</div>';
        grid.style.display    = 'block';
        grid.style.gridTemplate = '';

        if (!window._fbGetReels) return;
        window._fbGetReels({ uid: uid || undefined, limit: 20 }).then(function (reels) {
          if (!reels.length) {
            grid.innerHTML = '<div class="nwsb-reels-empty"><div class="nwsb-reels-empty-title">No reels yet</div><div class="nwsb-reels-empty-sub">Practice and score a word, then post it as a reel.</div></div>';
            return;
          }
          grid.innerHTML = reels.map(reelCardHtml).join('');
        }).catch(function () {
          grid.innerHTML = '<div class="nwsb-reels-empty"><div class="nwsb-reels-empty-title">Could not load</div></div>';
        });
      }
    };
  }
  patchProfTab();

})();
