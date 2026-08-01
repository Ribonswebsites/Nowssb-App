/* ══════════════════════════════════════════════════════════
   SECTION FURNITURE — the three pieces every section on a home has.

   The Reader, the eBooks shelf and Today's Practice were built with a
   complete set of parts and the rest of the page was not. A finished
   section carries:

     1. the spill   — a round icon and a black pill above it, saying in one
                      line what the section is
     2. the glass   — the section reads as a card rather than as loose
                      content floating on the page background
     3. the banner  — a black bar at the foot of it: icon, hairline, title,
                      subtitle, arrow

   This adds whichever of the three a section is missing and touches
   nothing else. A section that already has a spill keeps the spill it has;
   the check is for the element, not for this file's version of it. So the
   sections that were already right are not restyled, re-worded or
   re-ordered — which is the whole reason this is a pass over the page
   rather than fifty edits to the markup.

   What it deliberately does NOT do
   --------------------------------
   Wrap anything. app/js/part062.js reorders the *direct children* of each
   home's wrap — `wrap.querySelector(':scope > ' + sel)` — so putting a
   section inside a new element would take it out of the layout editor's
   reach and it would stop moving with the others. The glass is a class on
   the section itself instead, which looks the same and keeps it a child.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var I = 'https://res.cloudinary.com/';
  var IC = {
    meaning: I + 'eenvubod/image/upload/v1784460474/file_00000000854881fa9a548a68fae59c15_w1utya.png',
    words:   I + 'ds6duqabl/image/upload/f_auto,q_auto/v1779563284/ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png',
    ebooks:  I + 'eenvubod/image/upload/v1784974211/file_00000000ae5882089bc97a56b7368777_l4cq7e.png',
    connect: I + 'eenvubod/image/upload/f_auto,q_auto,w_120/v1784218818/file_00000000b84c7209ab496862cacd6a7f_kagsie.png',
    profile: I + 'ds6duqabl/image/upload/f_auto,q_auto/v1779563282/62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png',
    offer:   I + 'eenvubod/image/upload/v1784915420/file_000000006b20820b84961321dcdcaaa8_be9meu.png',
    streak:  I + 'eenvubod/image/upload/f_auto,q_auto/v1784130176/file_000000003254720aab81c7118e7cc24a_ohsba3.png',
    health:  I + 'ds6duqabl/image/upload/q_auto/f_auto/v1779639181/a7b04840-5789-11f1-9331-1302872077be_bqobig.png',
    science: I + 'ds6duqabl/image/upload/q_auto/f_auto/v1779639180/f89da3a0-578a-11f1-9331-1302872077be_xfgkbq.png'
  };

  /* One row per section that is missing something. `sel` is matched against
     the home wraps' own children, so the same row serves both homes where
     the class is shared.

       ic    which icon
       pill  the one line above the section
       t/s   the black banner's title and subtitle
       go    what tapping either of them does — omitted where the section
             already handles its own taps and a second handler would fight it
     ── */
  var SECTIONS = [
    { sel: '.hero-vid-banner',    ic: 'streak',  pill: 'Today, in one look',
      t: 'Your Day', s: 'Where the practice starts' },
    { sel: '.nmh-streak-section, .nmh-streak-glass-section', ic: 'streak',
      pill: 'Keep the run alive', t: 'Daily Streak', s: 'Practice daily to keep it going',
      go: "openSub('streak')" },
    { sel: '.npc-card.npc-purple', ic: 'words', pill: 'The shop, in a disc',
      t: 'NowssB Store', s: 'Words, meanings and the signature' },
    { sel: '.nmh-tiles-wrap, .glass-wrap.tiles-wrap', ic: 'science',
      pill: 'Four ways in', t: 'Home Tiles', s: 'Library, progress, science, profile',
      go: 'htOpen()' },
    { sel: '.cust-panel', ic: 'profile', pill: 'Make this home yours',
      t: 'Customize', s: 'Themes, background, quick access', go: 'cuOpen()' },
    { sel: '.nmh-offer-section:not(.nmh-rx-section), .glass-wrap.fash-offer-wrap',
      ic: 'offer', pill: 'Today only', t: "Today's Offer", s: 'Rotating store coupons' },
    { sel: '.nmh-rx-heading', ic: 'health', pill: 'Chosen for you',
      t: 'AI Prescription', s: 'Your daily recommended words' },
    { sel: '.home-card.home-card-static', ic: 'streak', pill: 'Your daily system',
      t: 'My Routines', s: 'Five routine slots', go: "openSub('routines')" },
    { sel: '.npc-card.npc-blue', ic: 'connect', pill: 'The social side',
      t: 'NowssB Connect', s: 'Share your practice' },
    { sel: '.nmh-connect-sec, .glass-wrap.connect-wrap', ic: 'connect',
      pill: 'Practice, together', t: 'NowssB Connect', s: 'What the social space is' },
    { sel: '.nmh-quick-row', ic: 'words', pill: 'Straight there',
      t: 'Quick Row', s: 'Store · Health · Community' },
    { sel: '.nmh-video-banner.nmh-vb-tall, .fash-video-banner.fash-vb-tall',
      ic: 'offer', pill: 'More words, more features', t: 'Subscribe Today',
      s: 'See every tier', go: "SS.open('subscription')" },
    { sel: '.nmh-fsec, #sub-promo-card', ic: 'profile', pill: 'Where you are now',
      t: 'Your Edition', s: 'Current plan and upgrade' },
    { sel: '.healing-wrap', ic: 'health', pill: 'Choose your journey',
      t: 'Personalised Healing', s: 'Healing by body goal' },
    { sel: '.word-search-section, #fashWordSearchWrap', ic: 'words',
      pill: 'Any word, any language', t: 'Word Search', s: 'Discover the origin of any word' },
    { sel: '.krm-section, #fashMeaningSearchWrap', ic: 'meaning',
      pill: 'The truth behind it', t: 'Meaning Search', s: 'Earth · Water · God · your name' },
    { sel: '.nmh-sec-wrap.nmh-store-wrap, .nss-store-trigger', ic: 'words',
      pill: 'Everything, in one place', t: 'NowssB Store', s: 'Enter the store' },
    { sel: '#fashCubeSec', ic: 'offer', pill: 'This week',
      t: 'Your Fashion Drops', s: 'The rotating cube' },
    { sel: '#fashPromoVid, .fash-video-banner:not(.fash-vb-tall)', ic: 'words',
      pill: 'Shop the sounds', t: 'NowssB Store', s: 'Shop now' },
    { sel: '#nmhFashSwitch', ic: 'profile', pill: 'The other home',
      t: 'Fashion Mode', s: 'Switch to the Fashion home' }
  ];

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function spillHtml(row) {
    var img = '<img loading="lazy" decoding="async" src="' + esc(IC[row.ic] || IC.words) +
              '" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:50%;display:block;">';
    return '<div class="spill nwsb-spill-auto"' + (row.go ? ' onclick="' + esc(row.go) + '"' : '') + '>' +
             '<span class="spill-circle">' + img + '</span>' +
             '<span class="spill-pill">' +
               '<span class="spill-pill-ic">' + img + '</span>' +
               '<span class="spill-pill-rule"></span>' +
               '<span class="spill-pill-txt">' + esc(row.pill) + '</span>' +
             '</span>' +
           '</div>';
  }

  function bannerHtml(row) {
    return '<div class="nmh-sec-banner nwsb-banner-auto"' + (row.go ? ' onclick="' + esc(row.go) + '"' : '') + '>' +
             '<div class="nmh-sec-banner-icon"><img loading="lazy" decoding="async" src="' +
               esc(IC[row.ic] || IC.words) + '" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:50%;"></div>' +
             '<div class="nmh-sec-banner-divider"></div>' +
             '<div class="nmh-sec-banner-txt">' +
               '<div class="nmh-sec-banner-title">' + esc(row.t) + '</div>' +
               '<div class="nmh-sec-banner-sub">' + esc(row.s) + '</div>' +
             '</div>' +
             '<div class="nmh-sec-banner-arrow"><svg viewBox="0 0 24 24" fill="none">' +
               '<path d="M5 12h14M12 5l7 7-7 7" stroke="rgba(255,255,255,0.9)" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>' +
             '</svg></div>' +
           '</div>';
  }

  /* Anything that already looks like a card — its own background, its own
     border, its own blur — is left alone. The point is to finish the
     sections that were never given one, not to restyle the ones that were. */
  function looksLikeCard(el) {
    var cs = getComputedStyle(el);
    if (cs.backdropFilter && cs.backdropFilter !== 'none') return true;
    if (cs.borderTopWidth !== '0px' && cs.borderTopStyle !== 'none') return true;
    var bg = cs.backgroundColor || '';
    var m = bg.match(/rgba?\(([^)]+)\)/);
    if (m) {
      var parts = m[1].split(',').map(parseFloat);
      if (parts.length < 4 || parts[3] > 0.02) return true;   // any real fill
    }
    if (cs.backgroundImage && cs.backgroundImage !== 'none') return true;
    return false;
  }

  function furnish(wrap) {
    if (!wrap) return 0;
    var done = 0;
    SECTIONS.forEach(function (row) {
      row.sel.split(',').forEach(function (one) {
        var el;
        try { el = wrap.querySelector(':scope > ' + one.trim()); } catch (e) { return; }
        if (!el || el.getAttribute('data-nwsb-furnished')) return;

        /* Each piece is independent: a section may already have the banner
           and want only the spill. */
        if (!el.querySelector('.spill')) el.insertAdjacentHTML('afterbegin', spillHtml(row));
        if (!el.querySelector('.nmh-sec-banner, .rm-cat-banner, .nmh-trend-shop-banner')) {
          el.insertAdjacentHTML('beforeend', bannerHtml(row));
        }
        if (!looksLikeCard(el)) el.classList.add('nwsb-sec-glass');

        el.setAttribute('data-nwsb-furnished', '1');
        done++;
      });
    });
    return done;
  }

  function run() {
    furnish(document.querySelector('#home-nm .nmh-wrap'));
    furnish(document.querySelector('#home .home-body'));
  }
  window.nwsbFurnishSections = run;

  /* Several of these sections are rendered by their own files after first
     paint, and part067.js injects more of them later still — so run again a
     few times rather than once, and again after the layout editor moves
     things. Each element is marked, so a second pass costs one attribute
     read and adds nothing twice. */
  function boot() {
    run();
    [400, 1200, 2600, 5000].forEach(function (t) { setTimeout(run, t); });
    var prev = window.hlApplyLayout;
    if (typeof prev === 'function') {
      window.hlApplyLayout = function () {
        var r = prev.apply(this, arguments);
        run();
        return r;
      };
    }
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
