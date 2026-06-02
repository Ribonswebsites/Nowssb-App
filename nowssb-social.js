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

  /* ══════════════════════════════════════════════════════════
     PHASE 3 — GATING + FREE-CLAIM
  ══════════════════════════════════════════════════════════ */

  /* Numeric tier rank — higher sees more. trial = full access. */
  function tierRank(t) {
    switch (t) {
      case 'trial':      return 99;
      case 'frequencyX': return 3;
      case 'frequency':  return 2;
      case 'resonance':  return 1;
      default:           return 0; /* expired / free / none */
    }
  }

  /* Words the viewer already owns (purchased + claimed + practiced) */
  function ownedWordSet() {
    var set = {};
    try { JSON.parse(localStorage.getItem('nwsb_purchased') || '[]').forEach(function (w) { set[w] = 1; }); } catch (e) {}
    try { JSON.parse(localStorage.getItem('nwsb_claimed')   || '[]').forEach(function (w) { set[w] = 1; }); } catch (e) {}
    /* words practiced (session keys: YYYY-MM-DD_WORD) */
    try {
      Object.keys(localStorage).forEach(function (k) {
        var m = /^\d{4}-\d{2}-\d{2}_(.+)$/.exec(k);
        if (m) set[m[1]] = 1;
      });
    } catch (e) {}
    return set;
  }

  /* Claim a free word (within the viewer's tier) into the owned set */
  window.nwsbClaimWord = function (word, btn) {
    if (!word) return;
    var claimed = [];
    try { claimed = JSON.parse(localStorage.getItem('nwsb_claimed') || '[]'); } catch (e) {}
    if (claimed.indexOf(word) === -1) {
      claimed.push(word);
      try { localStorage.setItem('nwsb_claimed', JSON.stringify(claimed)); } catch (e) {}
    }
    if (btn) {
      btn.textContent = '✓ Claimed';
      btn.disabled = true;
      btn.classList.add('claimed');
    }
  };

  /* ── Build one reel card HTML ── */
  function reelCardHtml(r, ctx) {
    ctx = ctx || {};
    var initials = (r.name || '?').charAt(0).toUpperCase();
    var avHtml = r.photoURL
      ? '<img src="' + r.photoURL + '" class="nwsb-reel-av" alt="" loading="lazy" decoding="async">'
      : '<div class="nwsb-reel-av-init">' + initials + '</div>';

    var bgHtml = r.photoURL
      ? '<img src="' + r.photoURL + '" class="nwsb-reel-card-bg" alt="" loading="lazy" decoding="async">'
      : '';

    var scoreColor = r.score >= 80 ? '#e8d5a3' : r.score >= 55 ? '#c8e8f5' : 'rgba(255,255,255,.5)';

    /* Free-claim button: viewer can access this word's tier, doesn't own it,
       and it's not their own reel */
    var claimHtml = '';
    var isOwn = ctx.uid && r.uid === ctx.uid;
    if (!isOwn && r.word && ctx.owned && !ctx.owned[r.word] &&
        tierRank(ctx.viewerTier) >= tierRank(r.wordTier || 'resonance')) {
      claimHtml = '<button class="nwsb-reel-claim-btn" onclick="nwsbClaimWord(\'' +
        String(r.word).replace(/'/g, '') + '\', this)">Claim free</button>';
    }

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
          claimHtml +
        '</div>' +
        '<div class="nwsb-reel-user-row">' +
          avHtml +
          '<span class="nwsb-reel-username">' + (r.name || 'Practitioner') + '</span>' +
        '</div>' +
      '</div>' +
    '</div>';
  }

  /* ── Gate prompt shown when viewer has no active plan ── */
  function reelsGateHtml() {
    return '<div class="nwsb-reels-empty">' +
      '<div class="nwsb-reels-empty-title">Reels are a member feature</div>' +
      '<div class="nwsb-reels-empty-sub">Start a plan to watch the community\'s pronunciation reels and claim free words.</div>' +
      '<button class="nwsb-post-reel-btn" style="max-width:220px;margin:18px auto 0;" ' +
        'onclick="window.SS&&window.SS.open(\'subscription\')">See Plans</button>' +
    '</div>';
  }

  /* ── Render reels feed into a container element ── */
  window.nwsbRenderReelsFeed = async function (containerId, opts) {
    var box = document.getElementById(containerId);
    if (!box) return;

    /* Gate: only members (or trial) can view the feed */
    if (window.GATE && !window.GATE.canAccess()) {
      box.innerHTML = reelsGateHtml();
      return;
    }

    box.innerHTML = '<div style="padding:30px;text-align:center;color:rgba(255,255,255,.3);font-family:\'DM Sans\',sans-serif;font-size:13px;">Loading reels…</div>';

    var viewerTier = window.GATE ? window.GATE.tier() : 'free';
    var ctx = {
      viewerTier: viewerTier,
      uid:        window._currentUid,
      owned:      ownedWordSet()
    };

    try {
      if (!window._fbGetReels) throw new Error('Firestore not ready');
      var reels = await window._fbGetReels(opts || {});

      /* Tier visibility — viewer sees reels at or below their tier */
      if (!(opts && opts.uid)) {
        reels = reels.filter(function (r) {
          return tierRank(viewerTier) >= tierRank(r.wordTier || 'resonance');
        });
      }

      if (!reels.length) {
        box.innerHTML =
          '<div class="nwsb-reels-empty">' +
            '<div class="nwsb-reels-empty-title">No reels yet</div>' +
            '<div class="nwsb-reels-empty-sub">Practice a word and tap "Post as Reel" after scoring to share your pronunciation.</div>' +
          '</div>';
        return;
      }
      box.innerHTML = reels.map(function (r) { return reelCardHtml(r, ctx); }).join('');
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
        '<div class="nwsb-hero-title">Your Stats,<br>Your Frequency.</div>' +
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
     STATS SCREEN — opened from Profile (the old social-home content)
  ══════════════════════════════════════════════════════════ */
  window.nwsbOpenStats = function () {
    var el = document.getElementById('sub-social-home');
    if (!el) return;
    el.classList.add('open');
    renderSocialHome();
    var sc = document.getElementById('ig-social-home-scroll');
    if (sc) sc.scrollTop = 0;
  };

  window.nwsbCloseStats = function () {
    var el = document.getElementById('sub-social-home');
    if (el) el.classList.remove('open');
    /* Profile sits underneath — keep it open */
  };

  /* ── Inject a "Stats" button into the self profile button row ── */
  function injectStatsBtn() {
    var btns = document.getElementById('ig-prof-btns');
    if (!btns) return;
    var isSelf = window.IG && window.IG._currentProfile && window.IG._currentProfile.self;
    if (!isSelf) return;
    if (btns.querySelector('.nwsb-stats-btn')) return;
    var b = document.createElement('button');
    b.className = 'ig-btn gray nwsb-stats-btn';
    b.textContent = 'Stats';
    b.onclick = function () { window.nwsbOpenStats(); };
    btns.appendChild(b);
  }

  /* Wrap openMyProfile / openProfile to add the Stats button after render */
  function patchProfileButtons() {
    if (!window.IG || typeof window.IG.openMyProfile !== 'function') {
      return setTimeout(patchProfileButtons, 120);
    }
    var _origMy = window.IG.openMyProfile.bind(window.IG);
    window.IG.openMyProfile = function () {
      var r = _origMy();
      setTimeout(injectStatsBtn, 30);
      return r;
    };
  }
  patchProfileButtons();

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

    window.IG.socialNav = function (which) {
      var sn      = document.getElementById('ig-social-nav');
      var mainNav = document.getElementById('ig-bottomnav');

      if (which === 'home') {
        /* Go back to Fashion/app home — hide social nav, restore main nav */
        hideSocialScreens();
        if (sn)      sn.style.display      = 'none';
        if (mainNav) mainNav.style.display = '';
        if (typeof setActiveNav === 'function') setActiveNav('home');
        if (typeof goTo         === 'function') goTo('home');

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
        if (sn) sn.style.display = 'flex';
        if (typeof chatInboxOpen === 'function') chatInboxOpen();
      }
    };
  }
  patchSocialNav();

  /* Patch IG.nav('profile') — close social screens when leaving social section */
  function patchNavProfile() {
    if (!window.IG || typeof window.IG.nav !== 'function') {
      return setTimeout(patchNavProfile, 120);
    }
    var _origNav = window.IG.nav.bind(window.IG);
    window.IG.nav = function (which) {
      if (which !== 'profile') {
        /* Leaving social section — close social-only screens */
        var homeEl = document.getElementById('sub-social-home');
        var feedEl = document.getElementById('sub-reels-feed');
        if (homeEl) homeEl.classList.remove('open');
        if (feedEl) feedEl.classList.remove('open');
      }
      _origNav(which);
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
          var pctx = { viewerTier: window.GATE ? window.GATE.tier() : 'free', uid: window._currentUid, owned: {} };
          grid.innerHTML = reels.map(function (r) { return reelCardHtml(r, pctx); }).join('');
        }).catch(function () {
          grid.innerHTML = '<div class="nwsb-reels-empty"><div class="nwsb-reels-empty-title">Could not load</div></div>';
        });
      }
    };
  }
  patchProfTab();

})();
