/* ═══════════════════════════════════════════════════════════════
   NowssB Social — Phase 1+2: Visual Redesign + Reels Engine
   Patches the IG controller (app/js/part033.js) at runtime.
   HTML stays in index.html; all CSS overrides in nowssb-social.css.
═══════════════════════════════════════════════════════════════ */
(function () {

  /* ── NowssB Verified IMAGE badge (the headphone check-mark seal images),
     shown as a neumorphic circle — replaces the old teal headphone SVG ── */
  var VB_IMG = {
    blue:    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782635218/fdb78570-72c6-11f1-bcbf-fb86e1a7c55f_ns1hnq.png',
    silver:  'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782635218/417b2090-72c8-11f1-bcbf-fb86e1a7c55f_cf2eyw.png',
    gold:    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782635218/311b1480-72c8-11f1-bcbf-fb86e1a7c55f_blupbs.png',
    diamond: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782635219/1aeee4a0-72ca-11f1-bcbf-fb86e1a7c55f_xc3v9h.png'
  };
  function imgBadge(tier, size) {
    size = size || 18;
    var img = VB_IMG[tier] || VB_IMG.blue;
    return '<span class="ig-vbadge" style="display:inline-flex;align-items:center;justify-content:center;width:' + size + 'px;height:' + size + 'px;border-radius:50% !important;margin-left:5px;vertical-align:-' + Math.round(size * 0.22) + 'px;overflow:hidden;background:none;box-shadow:none;"><img src="' + img + '" alt="Verified" style="width:100%;height:100%;object-fit:cover;border-radius:50% !important;display:block;"></span>';
  }
  var HP_SVG_TIER = imgBadge('blue', 18);
  var HP_SVG_ULT  = imgBadge('gold', 18);
  var HP_SVG_MASS = imgBadge('diamond', 18);
  var HP_ICON_SVG = imgBadge('blue', 16);

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

    var verifyBadge = window.VERIFY ? window.VERIFY.badge(ud) : '';
    var verifyLevel = window.VERIFY ? window.VERIFY.level(ud) : 'none';
    var levelLabel  = { massive:'Massive', ultimate:'Ultimate', tier:'Verified', none:'Unverified' }[verifyLevel] || '';

    box.innerHTML =
      '<div class="nwsb-hero">' +
        '<div class="nwsb-hero-img">' +
          '<div class="nwsb-hero-tag">Healing is Fashion</div>' +
        '</div>' +
        '<div class="nwsb-hero-body">' +
          '<div class="nwsb-hero-title">Your Stats,<br>Your Frequency.</div>' +
          '<div class="nwsb-hero-sub">NowssB · Word Science' +
            (verifyBadge ? '  <span style="display:inline-flex;align-items:center;gap:4px;color:#e8d5a3;">' + verifyBadge + levelLabel + '</span>' : '') +
          '</div>' +
          '<div class="nwsb-hero-stats">' +
            '<div class="nwsb-hero-stat"><span class="nwsb-hero-stat-num">' + words    + '</span><span class="nwsb-hero-stat-lbl">Words</span></div>' +
            '<div class="nwsb-hero-stat"><span class="nwsb-hero-stat-num">' + sessions + '</span><span class="nwsb-hero-stat-lbl">Sessions</span></div>' +
            '<div class="nwsb-hero-stat"><span class="nwsb-hero-stat-num">' + (score ? score + '%' : '—') + '</span><span class="nwsb-hero-stat-lbl">Score</span></div>' +
            '<div class="nwsb-hero-stat"><span class="nwsb-hero-stat-num">' + streak   + '</span><span class="nwsb-hero-stat-lbl">Streak</span></div>' +
          '</div>' +
        '</div>' +
      '</div>' +

      '<div class="nwsb-section-hd">Reels · Pronunciation</div>' +
      '<div id="nwsb-home-reels-strip" class="nwsb-reels-strip">' +
        '<div style="padding:20px 0;color:rgba(255,255,255,.25);font-family:\'DM Sans\',sans-serif;font-size:12px;">Loading…</div>' +
      '</div>' +

      /* Image-explainer slots — placeholders for the user's own evolution/origin imagery */
      '<div class="nwsb-section-hd">The New Fashion Trend</div>' +
      '<div class="nwsb-explainer-grid">' +
        '<div class="nwsb-explainer-slot has-img" style="background-image:url(https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782620614/grok_image_1782620063491_op58of.jpg)"><span>Origin</span></div>' +
        '<div class="nwsb-explainer-slot has-img" style="background-image:url(https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782620614/image_qg7ro5.jpg)"><span>Evolution</span></div>' +
        '<div class="nwsb-explainer-slot has-img" style="background-image:url(https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782620614/image_dtmprf.jpg)"><span>Frequency</span></div>' +
        '<div class="nwsb-explainer-slot has-img" style="background-image:url(https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782620614/grok_image_1782620475749_fgncxl.jpg)"><span>Healing</span></div>' +
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
    /* close the profile / other social screens so Stats shows directly */
    ['sub-ig-profile', 'sub-people', 'sub-reels-feed'].forEach(function (id) {
      var e = document.getElementById(id); if (e) e.classList.remove('open');
    });
    el.classList.add('open');
    var sn = document.getElementById('ig-social-nav');
    if (sn) sn.style.display = 'flex';
    renderSocialHome();
    var sc = document.getElementById('ig-social-home-scroll');
    if (sc) sc.scrollTop = 0;
  };

  window.nwsbCloseStats = function () {
    var el = document.getElementById('sub-social-home');
    if (el) el.classList.remove('open');
    /* back from Stats → the social profile */
    var igp = document.getElementById('sub-ig-profile');
    if (igp) igp.classList.add('open');
    if (window.IG && typeof IG.openMyProfile === 'function') { try { IG.openMyProfile(); } catch (e) {} }
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
    ['sub-social-home', 'sub-reels-feed', 'sub-people', 'sub-ig-profile', 'sub-ig-feed'].forEach(function (id) {
      var el = document.getElementById(id);
      if (el) el.classList.remove('open');
    });
  }

  /* Helper — set social nav active button */
  function setSocialActive(which) {
    ['home', 'feed', 'profile', 'me'].forEach(function (k) {
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
        /* Avoid goTo()'s self-exit bug when we're "already" on home (social is
           an overlay so currentScreen never changed) — nudge it first. */
        try { if (typeof currentScreen !== 'undefined' && currentScreen === 'home') currentScreen = 'home-nm'; } catch (e) {}
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
          /* renderExplore is a private fn inside IG's closure, not global — this bare
             call always silently no-op'd (typeof renderExplore === 'undefined' here),
             leaving the grid blank. Call it through window.IG.renderExplore instead. */
          if (window.IG && typeof window.IG.renderExplore === 'function') window.IG.renderExplore();
          window.IG.clearSearch && window.IG.clearSearch();
        }

      } else if (which === 'feedhome') {
        hideSocialScreens();
        setSocialActive('home');
        if (window.IG && typeof window.IG.openFeed === 'function') window.IG.openFeed();

      } else if (which === 'me') {
        hideSocialScreens();
        setSocialActive('me');
        if (window.IG && typeof window.IG.openMyProfile === 'function') window.IG.openMyProfile();

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

  /* ══════════════════════════════════════════════════════════
     PHASE 4 — VERIFICATION BADGES + COUNTS MIGRATION
  ══════════════════════════════════════════════════════════ */

  /* ── Firestore count sync ── */
  function syncCountsToFirestore() {
    if (!window._currentUid || !window._fbSetDoc) return;
    var sentences = 0;
    try { sentences = JSON.parse(localStorage.getItem('nwsb_sentences') || '[]').length; } catch (e) {}
    var purchased = 0;
    try { purchased = JSON.parse(localStorage.getItem('nwsb_purchased') || '[]').length; } catch (e) {}
    var practiced = 0;
    try {
      var ks = Object.keys(localStorage).filter(function (k) { return /^\d{4}-\d{2}-\d{2}_/.test(k); });
      practiced = new Set(ks.map(function (k) { return k.split('_').slice(1).join('_'); })).size;
    } catch (e) {}
    var claimed = 0;
    try { claimed = JSON.parse(localStorage.getItem('nwsb_claimed') || '[]').length; } catch (e) {}
    var wordsOwnedCount = Math.max(purchased + claimed, practiced);
    var ud = window._userDataCache || {};
    var verifyLevel = window.VERIFY
      ? window.VERIFY.level({ wordsOwnedCount: wordsOwnedCount, sentencesCount: sentences, isPro: ud.isPro, tier: ud.tier })
      : 'none';
    window._fbSetDoc(window._currentUid, {
      wordsOwnedCount: wordsOwnedCount,
      sentencesCount:  sentences,
      verifyLevel:     verifyLevel
    }).catch(function () {});
    /* Update local cache so badges refresh without reload */
    ud.wordsOwnedCount = wordsOwnedCount;
    ud.sentencesCount  = sentences;
    ud.verifyLevel     = verifyLevel;
  }

  /* ── Remove the 50-sentence cap in slAddSentence ── */
  function patchSentenceCap() {
    if (typeof window.slAddSentence !== 'function') { return setTimeout(patchSentenceCap, 200); }
    window.slAddSentence = function (text, words, routineName) {
      var arr;
      try { arr = JSON.parse(localStorage.getItem('nwsb_sentences') || '[]'); } catch (e) { arr = []; }
      arr.unshift({
        id: Date.now(),
        text: text,
        words: words || [],
        routineName: routineName || 'Practice',
        date: Date.now(),
        playCount: 0
      });
      /* unlimited — no 50-item cap */
      try { localStorage.setItem('nwsb_sentences', JSON.stringify(arr)); } catch (e) {}
      syncCountsToFirestore();
    };
  }
  patchSentenceCap();

  /* ── Sync counts after each completed practice session ── */
  function patchCompleteSession() {
    if (typeof window.pwCompleteSession !== 'function') { return setTimeout(patchCompleteSession, 200); }
    var _origComplete = window.pwCompleteSession;
    window.pwCompleteSession = async function () {
      var result = await _origComplete.apply(this, arguments);
      setTimeout(syncCountsToFirestore, 500);
      return result;
    };
  }
  patchCompleteSession();

  /* ── Sync on load (so counts are always current at startup) ── */
  function initialSync() {
    if (window._currentUid) {
      syncCountsToFirestore();
    } else {
      /* Wait for auth to complete */
      var attempts = 0;
      var iv = setInterval(function () {
        if (window._currentUid || ++attempts > 20) {
          clearInterval(iv);
          if (window._currentUid) syncCountsToFirestore();
        }
      }, 500);
    }
  }
  initialSync();

  /* ── Headphone SVG badge for a given userData object ── */
  function badgeForUser(userData) {
    if (!userData) return '';
    return window.VERIFY ? window.VERIFY.badge(userData) : '';
  }

  /* ── Patch IG.search to swap Instagram blue check → headphone badge ── */
  function patchSearch() {
    if (!window.IG || typeof window.IG.search !== 'function') { return setTimeout(patchSearch, 120); }
    var _origSearch = window.IG.search;
    window.IG.search = function (v) {
      _origSearch.call(this, v);
      /* After DOM update, replace any .ig-verified (Instagram blue check) with headphone badges */
      requestAnimationFrame(function () {
        var box = document.getElementById('ig-search-results');
        if (box) box.querySelectorAll('.ig-verified').forEach(function (el) {
          el.outerHTML = HP_SVG_TIER;
        });
      });
    };
  }
  patchSearch();

  /* ── Patch renderExplore grid to use headphone badges ── */
  /* renderExplore is private — observe the explore grid for newly inserted user rows */
  (function observeExplore() {
    var grid = document.getElementById('ig-search-results');
    if (!grid) { return setTimeout(observeExplore, 300); }
    var mo = new MutationObserver(function () {
      grid.querySelectorAll('.ig-verified').forEach(function (el) { el.outerHTML = HP_SVG_TIER; });
    });
    mo.observe(grid, { childList: true, subtree: true });
  })();

  /* ── Add headphone badge to the self profile top verified area ── */
  function patchProfileVerifiedBadge() {
    if (!window.IG || typeof window.IG.openMyProfile !== 'function') {
      return setTimeout(patchProfileVerifiedBadge, 120);
    }
    var _origMy = window.IG.openMyProfile;
    /* Already patched in Stats section — wrap the already-patched version */
    window.IG.openMyProfile = function () {
      var r = _origMy.apply(this, arguments);
      requestAnimationFrame(function () {
        /* Replace top-bar verified badge with headphone badge based on real level */
        var topBadge = document.getElementById('ig-prof-verified-top');
        if (topBadge) {
          var ud = window._userDataCache || {};
          topBadge.innerHTML = badgeForUser(ud);
        }
        /* Also fix the ring to NowssB gold→blue gradient for self */
        var ring = document.getElementById('ig-prof-avatar-ring');
        if (ring) ring.style.background = 'linear-gradient(135deg,#e8d5a3,#c8e8f5)';
        /* Stats button injection already handled in patchProfileButtons */
      });
      return r;
    };
  }
  patchProfileVerifiedBadge();

  /* ── Patch openProfile (other users) to swap badge ── */
  function patchOtherProfileBadge() {
    if (!window.IG || typeof window.IG.openProfile !== 'function') {
      return setTimeout(patchOtherProfileBadge, 120);
    }
    var _origProf = window.IG.openProfile;
    window.IG.openProfile = function (id) {
      var r = _origProf.apply(this, arguments);
      requestAnimationFrame(function () {
        var topBadge = document.getElementById('ig-prof-verified-top');
        if (topBadge) {
          /* For other users use tier badge (stub — real data would come from Firestore) */
          var current = window.IG && window.IG._currentProfile;
          if (current && current.verified) topBadge.innerHTML = HP_SVG_TIER;
        }
      });
      return r;
    };
  }
  patchOtherProfileBadge();

  /* ══════════════════════════════════════════════════════════
     PHASE 5 — SELF-CONTAINED SOCIAL SETTINGS
  ══════════════════════════════════════════════════════════ */

  var SOCIAL_SETTINGS = [
    { key: 'reels_autoplay', label: 'Reels autoplay',     sub: 'Play reels as you scroll',          def: true },
    { key: 'allow_claims',   label: 'Allow free claims',   sub: 'Let others claim words from your reels', def: true },
    { key: 'show_stats',     label: 'Show stats publicly', sub: 'Display your stat cube on your profile', def: true },
    { key: 'reel_notifs',    label: 'Reel notifications',  sub: 'Notify me when my reels get likes',  def: true },
    { key: 'verified_only',  label: 'Verified DMs only',   sub: 'Only verified members can message you', def: false }
  ];

  function getSocialSetting(key, def) {
    var v = null;
    try { v = localStorage.getItem('nwsb_social_' + key); } catch (e) {}
    if (v === null) return def;
    return v === '1';
  }

  function setSocialSetting(key, on) {
    try { localStorage.setItem('nwsb_social_' + key, on ? '1' : '0'); } catch (e) {}
  }

  window.nwsbToggleSocialSetting = function (key, el) {
    var on = !el.classList.contains('on');
    setSocialSetting(key, on);
    renderSocialSettings(); // keeps every mounted copy of the rows in sync
  };

  function socialSettingsRowsHtml() {
    return SOCIAL_SETTINGS.map(function (s) {
      var on = getSocialSetting(s.key, s.def);
      return '<div class="nwsb-ss-row">' +
        '<div class="nwsb-ss-row-body">' +
          '<div class="nwsb-ss-row-label">' + s.label + '</div>' +
          '<div class="nwsb-ss-row-sub">' + s.sub + '</div>' +
        '</div>' +
        '<div class="nwsb-ss-toggle' + (on ? ' on' : '') + '" onclick="nwsbToggleSocialSetting(\'' + s.key + '\', this)">' +
          '<div class="nwsb-ss-toggle-knob"></div>' +
        '</div>' +
      '</div>';
    }).join('');
  }

  // Re-render EVERY place these rows are mounted (the legacy sheet + the
  // NowssB Connect Hub page) so a toggle flipped in one place is reflected
  // in the other without a reload.
  function renderSocialSettings() {
    var html = socialSettingsRowsHtml();
    ['nwsb-social-settings-rows', 'nch-settings-rows'].forEach(function (id) {
      var box = document.getElementById(id);
      if (box) box.innerHTML = html;
    });
  }
  window.nwsbRenderSocialSettingsRows = renderSocialSettings;

  window.nwsbOpenSocialSettings = function () {
    renderSocialSettings();
    var el = document.getElementById('nwsb-social-settings');
    if (el) el.classList.add('open');
  };

  window.nwsbCloseSocialSettings = function () {
    var el = document.getElementById('nwsb-social-settings');
    if (el) el.classList.remove('open');
  };

  /* Route the IG menu "Settings" entry to the self-contained social settings */
  function patchMenuSettings() {
    if (!window.IG || typeof window.IG.menu !== 'function') {
      return setTimeout(patchMenuSettings, 150);
    }
    var _origMenu = window.IG.menu;
    window.IG.menu = function () {
      _origMenu.apply(this, arguments);
      /* After the sheet renders, redirect its Settings button to social settings */
      var settingsBtn = document.getElementById('ig-ms-settings');
      if (settingsBtn) {
        settingsBtn.onclick = function () {
          var sheet = document.getElementById('ig-menu-sheet');
          if (sheet) sheet.remove();
          window.nwsbOpenSocialSettings();
        };
      }
    };
  }
  patchMenuSettings();

  /* ═══════════════════════════════════════════════════════════════
     NOWSSB CONNECT — one-time account setup wizard
     Gated from app/js/part033.js's IG.nav('profile') — the first time a
     user ever taps into Connect, this runs instead; once it finishes it
     calls IG.nav('profile') again to actually land in the real feed.
  ═══════════════════════════════════════════════════════════════ */
  var CS_FOCUS_OPTIONS = ['Sound Healer', 'Daily Practitioner', 'Wellness', 'Beginner', 'Practitioner', 'Frequency Sage'];
  var _csSelectedFocus = '';
  var _csSelectedTheme = 'neu';
  var _csOnComplete = null;
  var _csAvatarObserver = null;
  var _csBannerObserver = null;

  window.nwsbSocialOnboardingDone = function () {
    try { if (localStorage.getItem('nwsb_social_onboarding_done') === '1') return true; } catch (e) {}
    var ud = window._userDataCache;
    if (ud && ud.socialOnboardingDone) return true;
    return false;
  };

  // Avatar/banner pickers are the app's existing shared sheets (profileEditPhoto()
  // → prebuilt avatar grid or upload; nwsbBannerChooser() → prebuilt banner grid
  // or upload). Both persist straight to Firestore/localStorage on selection and
  // update their own known DOM targets (#profile-edit-avatar-circle /
  // #profile-edit-banner-preview) — mirror those onto this wizard's own preview
  // elements via MutationObserver instead of duplicating the picker UI.
  function watchSharedPickers() {
    var avSrc = document.getElementById('profile-edit-avatar-circle');
    var avMine = document.getElementById('nwsbcsAvatar');
    if (_csAvatarObserver) { _csAvatarObserver.disconnect(); _csAvatarObserver = null; }
    if (avSrc && avMine) {
      _csAvatarObserver = new MutationObserver(function () {
        if (avSrc.style.backgroundImage && avSrc.style.backgroundImage !== 'none') {
          avMine.style.backgroundImage = avSrc.style.backgroundImage;
          avMine.innerHTML = '';
        }
      });
      _csAvatarObserver.observe(avSrc, { attributes: true, attributeFilter: ['style'] });
    }
    var bnSrc = document.getElementById('profile-edit-banner-preview');
    var bnMine = document.getElementById('nwsbcsBannerPreview');
    if (_csBannerObserver) { _csBannerObserver.disconnect(); _csBannerObserver = null; }
    if (bnSrc && bnMine) {
      _csBannerObserver = new MutationObserver(function () {
        if (bnSrc.style.backgroundImage && bnSrc.style.backgroundImage !== 'none') {
          bnMine.style.backgroundImage = bnSrc.style.backgroundImage;
          bnMine.innerHTML = '';
        }
      });
      _csBannerObserver.observe(bnSrc, { attributes: true, attributeFilter: ['style'] });
    }
  }
  function unwatchSharedPickers() {
    if (_csAvatarObserver) { _csAvatarObserver.disconnect(); _csAvatarObserver = null; }
    if (_csBannerObserver) { _csBannerObserver.disconnect(); _csBannerObserver = null; }
  }

  window.nwsbOpenConnectSetup = function (onComplete) {
    _csOnComplete = onComplete || null;
    var overlay = document.getElementById('nwsbConnectSetup');
    if (!overlay) { if (onComplete) onComplete(); return; }

    var ud = window._userDataCache || {};
    var nameInput = document.getElementById('nwsbcsName');
    if (nameInput) nameInput.value = ud.displayName || (window._currentUser && window._currentUser.displayName) || '';
    var bioInput = document.getElementById('nwsbcsBio');
    if (bioInput) bioInput.value = ud.bio || '';

    var av = document.getElementById('nwsbcsAvatar');
    var existingPhoto = ud.photoURL || (window._currentUser && window._currentUser.photoURL) || '';
    if (av) { av.style.backgroundImage = existingPhoto ? "url('" + existingPhoto + "')" : 'none'; if (existingPhoto) av.innerHTML = ''; }

    var bn = document.getElementById('nwsbcsBannerPreview');
    if (bn) {
      if (ud.bannerURL) { bn.style.backgroundImage = "url('" + ud.bannerURL + "')"; bn.innerHTML = ''; }
      else { bn.style.backgroundImage = 'none'; }
    }

    _csSelectedFocus = ud.healthFocus || '';
    _csSelectedTheme = (function () { try { return localStorage.getItem('nwsb_social_theme') || 'neu'; } catch (e) { return 'neu'; } })();

    renderCsFocusChips();
    syncCsTheme();
    watchSharedPickers();

    document.getElementById('nwsbcs-stage-intro').style.display = 'flex';
    document.getElementById('nwsbcs-stage-profile').style.display = 'none';
    document.getElementById('nwsbcs-stage-welcome').style.display = 'none';
    overlay.style.display = 'block';
  };

  window.nwsbConnectSetupBack = function () {
    document.getElementById('nwsbcs-stage-profile').style.display = 'none';
    document.getElementById('nwsbcs-stage-intro').style.display = 'flex';
  };

  window.nwsbConnectSetupNext = function (stage) {
    if (stage === 'profile') {
      document.getElementById('nwsbcs-stage-intro').style.display = 'none';
      document.getElementById('nwsbcs-stage-profile').style.display = 'flex';
      return;
    }
    if (stage === 'welcome') {
      var name = (document.getElementById('nwsbcsName').value || '').trim();
      if (!name) {
        if (window.nwsbToast) nwsbToast('Enter your name to continue');
        else alert('Enter your name to continue');
        return;
      }
      saveCsProfile(name);
      document.getElementById('nwsbcs-stage-profile').style.display = 'none';
      document.getElementById('nwsbcs-stage-welcome').style.display = 'flex';
      document.getElementById('nwsbcsWelcomeSub').textContent = 'Welcome to NowssB Connect, ' + name.split(' ')[0] + '.';
      setTimeout(function () {
        var w = document.getElementById('nwsbcs-stage-welcome');
        if (w && w.style.display !== 'none') window.nwsbConnectSetupFinish();
      }, 2200);
    }
  };

  window.nwsbConnectSetupTheme = function (theme) {
    _csSelectedTheme = theme;
    syncCsTheme();
  };
  function syncCsTheme() {
    var neu = document.getElementById('nwsbcsThemeNeu');
    var gl = document.getElementById('nwsbcsThemeGlass');
    if (neu) neu.classList.toggle('active', _csSelectedTheme === 'neu');
    if (gl) gl.classList.toggle('active', _csSelectedTheme === 'glass');
  }

  function renderCsFocusChips() {
    var row = document.getElementById('nwsbcsFocusRow');
    if (!row) return;
    row.innerHTML = CS_FOCUS_OPTIONS.map(function (f) {
      return '<div class="nwsbcs-chip' + (f === _csSelectedFocus ? ' selected' : '') + '" onclick="nwsbConnectSetupFocus(this,\'' + f + '\')">' + f + '</div>';
    }).join('');
  }
  window.nwsbConnectSetupFocus = function (el, focus) {
    _csSelectedFocus = focus;
    var row = document.getElementById('nwsbcsFocusRow');
    if (row) Array.prototype.forEach.call(row.children, function (c) { c.classList.remove('selected'); });
    el.classList.add('selected');
  };

  function saveCsProfile(name) {
    var bio = (document.getElementById('nwsbcsBio').value || '').trim();

    // Apply the chosen theme via the already-wired setter (localStorage + body class).
    if (typeof nwsbSetSocTheme === 'function') nwsbSetSocTheme(_csSelectedTheme);

    // Avatar/banner were already persisted the moment they were picked (the
    // shared pickers do that themselves) — only name/focus/bio/completion
    // are this wizard's own responsibility to save.
    if (window._userDataCache) {
      window._userDataCache.displayName = name;
      if (_csSelectedFocus) window._userDataCache.healthFocus = _csSelectedFocus;
      window._userDataCache.bio = bio;
      window._userDataCache.socialOnboardingDone = true;
    }

    try { localStorage.setItem('nwsb_social_onboarding_done', '1'); } catch (e) {}

    if (window._currentUid && window._fbSetDoc) {
      var payload = { displayName: name, socialOnboardingDone: true };
      if (_csSelectedFocus) payload.healthFocus = _csSelectedFocus;
      if (bio) payload.bio = bio;
      window._fbSetDoc(window._currentUid, payload).catch(function () {});
    }
  }

  window.nwsbConnectSetupFinish = function () {
    var overlay = document.getElementById('nwsbConnectSetup');
    if (overlay) overlay.style.display = 'none';
    unwatchSharedPickers();
    var cb = _csOnComplete;
    _csOnComplete = null;
    if (cb) cb();
  };

  /* ═══════════════════════════════════════════════════════════════
     THEME PREVIEW IMAGES — real background removal
     The two theme screenshots are studio-style renders on a flat white
     backdrop, not transparent PNGs — mix-blend-mode alone isn't reliable
     enough (depends on the exact page colour behind it). This actually
     strips the pixels: flood-fill from the four image edges through
     near-white pixels only, erasing just the connected background region
     and leaving any white *inside* the phone mockup (bounded by its dark
     bezel) untouched. Result is cached per URL and reused everywhere the
     same image appears (setup wizard, Connect Hub, Edit Profile). ── */
  var _bgStripCache = {};
  function nwsbStripCornerBg(url) {
    if (_bgStripCache[url]) return _bgStripCache[url];
    var p = new Promise(function (resolve) {
      var img = new Image();
      // Load through our own same-origin proxy (functions/_middleware.js)
      // instead of crossOrigin='anonymous' straight to Cloudinary — canvas
      // pixel access throws a SecurityError unless the image was served
      // with CORS headers, which Cloudinary doesn't reliably send. A
      // same-origin image never has that problem.
      img.src = '/img-proxy?u=' + encodeURIComponent(url);
      img.onload = function () {
        try {
          var w = img.naturalWidth, h = img.naturalHeight;
          var canvas = document.createElement('canvas');
          canvas.width = w; canvas.height = h;
          var ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0);
          var imgData = ctx.getImageData(0, 0, w, h);
          var px = imgData.data;
          var THRESH = 236;
          function isWhite(p2) {
            var i = p2 * 4;
            return px[i] >= THRESH && px[i + 1] >= THRESH && px[i + 2] >= THRESH;
          }
          var visited = new Uint8Array(w * h);
          var stack = [];
          function seed(p2) { if (!visited[p2] && isWhite(p2)) { visited[p2] = 1; stack.push(p2); } }
          for (var x = 0; x < w; x++) { seed(x); seed((h - 1) * w + x); }
          for (var y = 0; y < h; y++) { seed(y * w); seed(y * w + (w - 1)); }
          while (stack.length) {
            var p2 = stack.pop();
            var x2 = p2 % w, y2 = (p2 / w) | 0;
            px[p2 * 4 + 3] = 0;
            if (x2 > 0) seed(p2 - 1);
            if (x2 < w - 1) seed(p2 + 1);
            if (y2 > 0) seed(p2 - w);
            if (y2 < h - 1) seed(p2 + w);
          }
          ctx.putImageData(imgData, 0, 0);
          resolve(canvas.toDataURL('image/png'));
        } catch (e) {
          console.warn('nwsbStripCornerBg: canvas processing failed, using original image:', e);
          resolve(url);
        }
      };
      img.onerror = function () { resolve(url); };
    });
    _bgStripCache[url] = p;
    return p;
  }
  function nwsbApplyStrippedBg(url, selector) {
    nwsbStripCornerBg(url).then(function (finalUrl) {
      document.querySelectorAll(selector).forEach(function (el) {
        el.style.backgroundImage = "url('" + finalUrl + "')";
      });
    });
  }
  window.nwsbApplyStrippedBg = nwsbApplyStrippedBg;

  var NWSB_THEME_IMG_NEU   = 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_400/v1784257659/file_00000000a718720aaba9aef2f7b1e757_sdk2a8.png';
  var NWSB_THEME_IMG_GLASS = 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_400/v1784257659/file_00000000cf8c720a89a1fb6f44fe8c55_xwdwnz.png';
  nwsbApplyStrippedBg(NWSB_THEME_IMG_NEU,   '#nwsbcsThemeNeu .nwsb-theme-opt-img, #nch-theme-neu .nwsb-theme-opt-img, #nwsb-theme-neu .nwsb-theme-opt-img');
  nwsbApplyStrippedBg(NWSB_THEME_IMG_GLASS, '#nwsbcsThemeGlass .nwsb-theme-opt-img, #nch-theme-glass .nwsb-theme-opt-img, #nwsb-theme-glass .nwsb-theme-opt-img');

  /* ═══════════════════════════════════════════════════════════════
     NOWSSB CONNECT HOME — custom background photo picker
     Only ever visible where it matters: applies exclusively under the
     Connect Fashion (glass) theme, never neumorphism — the neu theme has
     no photo background at all. Only touches #sub-social-home (the
     Connect "Stats"/home screen) — feed/reels/discover/profile keep
     their own fixed photos. Same 3D-carousel interaction as the Fashion
     Home background picker (reuses its .fbgci card styling), pooling the
     4 existing Connect glass photos (feed/reels/discover/home) with the
     9 Fashion Home photos for 13 choices total. ── */
  var NWSB_CONNECT_BGS = [
    'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_900/v1784177300/grok_image_1784177099346_a7zq1m.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_900/v1784177300/grok_image_1784177245304_ihjubs.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_900/v1784177300/grok_image_1784177237514_bbhcec.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_900/v1784177300/grok_image_1784177200001_clr7h6.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/v1784263977/grok_image_1784261485118_fnnndw.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/v1784263977/grok_image_1784263702345_zlt99m.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/v1784263977/grok_image_1784263836740_qclr5g.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/v1784263977/grok_image_1784261493254_szhsuw.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/v1784263977/grok_image_1784263881946_zespcn.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/v1784263977/grok_image_1784263699783_tyf4l8.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/v1784263996/grok_image_1784263979789_doxtcp.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/v1784264037/grok_image_1784263836740_atjk35.jpg',
    'https://res.cloudinary.com/eenvubod/image/upload/v1784264037/grok_image_1784263778179_okskwb.jpg'
  ];

  window.nwsbSetConnectBg = function (url) {
    document.body.style.setProperty('--nwsb-connect-bg-url', "url('" + url + "')");
    document.body.classList.add('nwsb-custom-connect-bg');
    try { localStorage.setItem('nwsb_connect_bg_custom', url); } catch (e) {}
    if (window._currentUid && window._fbSetDoc) {
      window._fbSetDoc(window._currentUid, { connectBgCustom: url }).catch(function () {});
    }
    if (window.nwsbToast) nwsbToast('Connect background updated ✓');
  };

  (function initConnectBg() {
    var saved = null;
    try { saved = localStorage.getItem('nwsb_connect_bg_custom'); } catch (e) {}
    if (saved) {
      document.body.style.setProperty('--nwsb-connect-bg-url', "url('" + saved + "')");
      document.body.classList.add('nwsb-custom-connect-bg');
    }
  })();

  window.nwsbOpenConnectBgPanel = function () {
    var panel = document.getElementById('nwsbConnectBgPanel');
    if (!panel) return;
    panel.style.display = 'block';
    ncbgCarouselInit();
  };
  window.nwsbCloseConnectBgPanel = function () {
    var panel = document.getElementById('nwsbConnectBgPanel');
    if (panel) panel.style.display = 'none';
  };

  var ncbgActive = 0, ncbgItems = null, ncbgDotEls = null;
  var NCBG_N = NWSB_CONNECT_BGS.length;

  function ncbgCfg(s) {
    var a = Math.abs(s), d = s < 0 ? -1 : 1;
    if (a === 0) return {tx: 0,     tz: 200,  ry: 0,     sc: 1.00, op: 1.00, zi: 20};
    if (a === 1) return {tx: d*172, tz: -10,  ry: d*-28, sc: 0.78, op: 0.68, zi: 15};
    if (a === 2) return {tx: d*290, tz: -155, ry: d*-50, sc: 0.52, op: 0.22, zi: 10};
    return             {tx: 0,     tz: -600, ry: 0,     sc: 0.10, op: 0.00, zi: 0};
  }

  function ncbgPaint() {
    if (!ncbgItems) return;
    ncbgItems.forEach(function (el, i) {
      var off = ((i - ncbgActive) % NCBG_N + NCBG_N) % NCBG_N;
      var s = off > Math.floor(NCBG_N / 2) ? off - NCBG_N : off;
      var c = ncbgCfg(s);
      el.style.transform     = 'translateX('+c.tx+'px) translateZ('+c.tz+'px) rotateY('+c.ry+'deg) scale('+c.sc+')';
      el.style.opacity       = String(c.op);
      el.style.zIndex        = String(c.zi);
      el.style.pointerEvents = c.op > 0.05 ? 'auto' : 'none';
      el.style.borderColor   = (i === ncbgActive) ? '#e8d5a3' : 'rgba(255,255,255,0.08)';
    });
    if (ncbgDotEls) ncbgDotEls.forEach(function (d, i) { d.classList.toggle('active', i === ncbgActive); });
    var label = document.getElementById('ncbgSelectedLabel');
    if (label) label.textContent = 'Photo ' + (ncbgActive + 1) + ' of ' + NCBG_N;
  }

  function ncbgGo(n) { ncbgActive = ((n % NCBG_N) + NCBG_N) % NCBG_N; ncbgPaint(); }

  window.ncbgCarouselInit = function () {
    var carousel = document.getElementById('ncbgCarousel');
    var inner    = document.getElementById('ncbgCarouselInner');
    var dotsEl   = document.getElementById('ncbgDots');
    if (!carousel || !inner || !dotsEl) return;

    if (!inner.dataset.built) {
      inner.dataset.built = '1';
      inner.innerHTML = NWSB_CONNECT_BGS.map(function (url) {
        return '<div class="fbgci" style="background-image:url(\'' + url + '\')"></div>';
      }).join('');
      dotsEl.innerHTML = NWSB_CONNECT_BGS.map(function () { return '<div class="becd"></div>'; }).join('');
    }

    ncbgItems  = Array.from(inner.querySelectorAll('.fbgci'));
    ncbgDotEls = Array.from(dotsEl.querySelectorAll('.becd'));
    NCBG_N = ncbgItems.length;

    var cur = null;
    try { cur = localStorage.getItem('nwsb_connect_bg_custom'); } catch (e) {}
    var idx = NWSB_CONNECT_BGS.indexOf(cur);
    ncbgActive = idx >= 0 ? idx : 0;

    ncbgItems.forEach(function (el) {
      el.style.transition = 'none';
      el.style.transform  = 'translateX(0px) translateZ(-600px) rotateY(0deg) scale(0.1)';
      el.style.opacity    = '0';
    });
    void carousel.offsetHeight;
    requestAnimationFrame(function () {
      requestAnimationFrame(function () {
        var T = 'transform 0.78s cubic-bezier(0.34,1.08,0.64,1),opacity 0.78s ease,border-color 0.3s ease,box-shadow 0.3s ease';
        ncbgItems.forEach(function (el) { el.style.transition = T; });
        ncbgPaint();
      });
    });

    var tx0 = 0;
    carousel.addEventListener('touchstart', function (e) { tx0 = e.touches[0].clientX; }, {passive: true});
    carousel.addEventListener('touchend', function (e) {
      var dx = e.changedTouches[0].clientX - tx0;
      if (Math.abs(dx) > 40) ncbgGo(ncbgActive + (dx < 0 ? 1 : -1));
    }, {passive: true});

    ncbgItems.forEach(function (el, i) {
      el.onclick = function (e) {
        e.stopPropagation();
        if (i !== ncbgActive) ncbgGo(i);
        else ncbgApply();
      };
    });
  };

  window.ncbgApply = function () {
    var url = NWSB_CONNECT_BGS[ncbgActive];
    nwsbSetConnectBg(url);
    var btn = document.getElementById('ncbgApplyBtn');
    if (btn) {
      btn.textContent = 'APPLIED!';
      btn.style.background = '#fff';
      setTimeout(function () {
        btn.textContent = 'APPLY THIS BACKGROUND';
        btn.style.background = '#e8d5a3';
      }, 1400);
    }
  };

})();
