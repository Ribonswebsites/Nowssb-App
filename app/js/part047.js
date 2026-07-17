
(function(){
  var THEME_CLASSES = ['nwsb-theme-default','nwsb-theme-black','nwsb-theme-neo','nwsb-theme-glass-black'];
  var OLD_BE_CLASSES = ['be-fashion','be-neo','be-glass'];

  window.setNwsbTheme = function(theme, explicit) {
    theme = theme || 'default';
    THEME_CLASSES.forEach(function(c){ document.body.classList.remove(c); });
    OLD_BE_CLASSES.forEach(function(c){ document.body.classList.remove(c); });
    document.body.classList.add('nwsb-theme-' + theme);
    localStorage.setItem('nwsb_theme', theme);

    // Preload the black-edition background image so it's cached and ready —
    // prevents a blank/flash frame when fashion-home-active first applies it.
    if (theme === 'black' && !window._beBgPreloaded) {
      window._beBgPreloaded = true;
      var _pre = new Image();
      _pre.src = 'https://res.cloudinary.com/ds6duqabl/image/upload/v1780209363/grok_image_1780209143800_i8lcry.jpg';
    }

    // Fashion intro only when user explicitly selects Black — never on page-load restore
    if (theme === 'black' && explicit && !window._fashionHomeIntroSeen) {
      window._fashionHomeIntroSeen = true;
      if (window.showFashionHomeIntro) window.showFashionHomeIntro();
    }

    // Update card borders
    ['default','black','neo','glass-black'].forEach(function(s){
      var el = document.getElementById('theme-card-'+s);
      if (!el) return;
      el.style.borderColor = (s === theme) ? '#e8d5a3' : 'rgba(255,255,255,0.08)';
    });
  };

  // Backward compat alias
  window.setBE = function(style, explicit) {
    var map = {'':'default','fashion':'black','neo':'neo'};
    window.setNwsbTheme(map[style || ''] || 'default');
  };

  // Init from localStorage
  var saved = localStorage.getItem('nwsb_theme') || 'default';
  // Glass Black is removed entirely — anyone who had it saved falls back to
  // Fashion (the renamed "default") instead of silently staying stuck on a
  // theme that no longer has a card in the carousel.
  if (saved === 'glass-black') { saved = 'default'; }
  // If user already chose Black in a prior session, mark intro as seen so it
  // never fires on page reload — only shows the first time they tap the card.
  if (saved === 'black') { window._fashionHomeIntroSeen = true; }
  setNwsbTheme(saved);
  localStorage.removeItem('nwsb_be');

  /* ── Fashion home — custom background photo picker ──
     Independent of the Black-Edition themes above: picking a photo here
     layers a higher-priority #appBg override on top of whichever theme is
     active (see nowssb-nm.css). Picking a theme card clears it again, so
     the two controls never fight silently. */
  var NWSB_FASHION_BGS = [
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

  window.nwsbSetFashionBg = function (url) {
    document.body.style.setProperty('--nwsb-custom-bg-url', "url('" + url + "')");
    document.body.classList.add('nwsb-custom-fashion-bg');
    try { localStorage.setItem('nwsb_fashion_bg_custom', url); } catch (e) {}
    if (window._currentUid && window._fbSetDoc) {
      window._fbSetDoc(window._currentUid, { fashionBgCustom: url }).catch(function () {});
    }
    if (window.nwsbToast) nwsbToast('Background updated ✓');
  };

  // Explicitly picking a Black-Edition theme card clears any custom photo —
  // otherwise the !important custom override would keep winning over the
  // theme's own background, which reads as broken ("I picked Black but my
  // old photo is still showing").
  var _origSetNwsbTheme = window.setNwsbTheme;
  window.setNwsbTheme = function (theme, explicit) {
    document.body.classList.remove('nwsb-custom-fashion-bg');
    document.body.style.removeProperty('--nwsb-custom-bg-url');
    try { localStorage.removeItem('nwsb_fashion_bg_custom'); } catch (e) {}
    return _origSetNwsbTheme(theme, explicit);
  };

  (function initFashionBg() {
    var saved2 = null;
    try { saved2 = localStorage.getItem('nwsb_fashion_bg_custom'); } catch (e) {}
    if (saved2) {
      document.body.style.setProperty('--nwsb-custom-bg-url', "url('" + saved2 + "')");
      document.body.classList.add('nwsb-custom-fashion-bg');
    }
  })();

  /* ── Fashion Background — 3D carousel, same interaction language as the
     Black Edition carousel above (tap to preview/centre, tap again to
     apply, swipe to browse, dots + Apply button). Square corners on
     purpose — no border-radius anywhere in here. ── */
  var fbgActive = 0, fbgItems = null, fbgDotEls = null;
  var FBG_N = NWSB_FASHION_BGS.length;

  function fbgCfg(s) {
    var a = Math.abs(s), d = s < 0 ? -1 : 1;
    if (a === 0) return {tx: 0,     tz: 200,  ry: 0,     sc: 1.00, op: 1.00, zi: 20};
    if (a === 1) return {tx: d*172, tz: -10,  ry: d*-28, sc: 0.78, op: 0.68, zi: 15};
    if (a === 2) return {tx: d*290, tz: -155, ry: d*-50, sc: 0.52, op: 0.22, zi: 10};
    return             {tx: 0,     tz: -600, ry: 0,     sc: 0.10, op: 0.00, zi: 0};
  }

  function fbgPaint() {
    if (!fbgItems) return;
    fbgItems.forEach(function (el, i) {
      var off = ((i - fbgActive) % FBG_N + FBG_N) % FBG_N;
      var s = off > Math.floor(FBG_N / 2) ? off - FBG_N : off;
      var c = fbgCfg(s);
      el.style.transform     = 'translateX('+c.tx+'px) translateZ('+c.tz+'px) rotateY('+c.ry+'deg) scale('+c.sc+')';
      el.style.opacity       = String(c.op);
      el.style.zIndex        = String(c.zi);
      el.style.pointerEvents = c.op > 0.05 ? 'auto' : 'none';
      el.style.borderColor   = (i === fbgActive) ? '#e8d5a3' : 'rgba(255,255,255,0.08)';
    });
    if (fbgDotEls) fbgDotEls.forEach(function (d, i) { d.classList.toggle('active', i === fbgActive); });
    var label = document.getElementById('fbgSelectedLabel');
    if (label) label.textContent = 'Photo ' + (fbgActive + 1) + ' of ' + FBG_N;
  }

  function fbgGo(n) { fbgActive = ((n % FBG_N) + FBG_N) % FBG_N; fbgPaint(); }

  window.fbgCarouselInit = function () {
    var carousel = document.getElementById('fbgCarousel');
    var inner    = document.getElementById('fbgCarouselInner');
    var dotsEl   = document.getElementById('fbgDots');
    if (!carousel || !inner || !dotsEl) return;

    if (!inner.dataset.built) {
      inner.dataset.built = '1';
      inner.innerHTML = NWSB_FASHION_BGS.map(function (url) {
        return '<div class="fbgci" style="background-image:url(\'' + url + '\')"></div>';
      }).join('');
      dotsEl.innerHTML = NWSB_FASHION_BGS.map(function () { return '<div class="becd"></div>'; }).join('');
    }

    fbgItems  = Array.from(inner.querySelectorAll('.fbgci'));
    fbgDotEls = Array.from(dotsEl.querySelectorAll('.becd'));
    FBG_N = fbgItems.length;

    // Start from whichever photo is currently applied, if any
    var cur = null;
    try { cur = localStorage.getItem('nwsb_fashion_bg_custom'); } catch (e) {}
    var idx = NWSB_FASHION_BGS.indexOf(cur);
    fbgActive = idx >= 0 ? idx : 0;

    fbgItems.forEach(function (el) {
      el.style.transition = 'none';
      el.style.transform  = 'translateX(0px) translateZ(-600px) rotateY(0deg) scale(0.1)';
      el.style.opacity    = '0';
    });
    void carousel.offsetHeight;
    requestAnimationFrame(function () {
      requestAnimationFrame(function () {
        var T = 'transform 0.78s cubic-bezier(0.34,1.08,0.64,1),opacity 0.78s ease,border-color 0.3s ease,box-shadow 0.3s ease';
        fbgItems.forEach(function (el) { el.style.transition = T; });
        fbgPaint();
      });
    });

    var tx0 = 0;
    carousel.addEventListener('touchstart', function (e) { tx0 = e.touches[0].clientX; }, {passive: true});
    carousel.addEventListener('touchend', function (e) {
      var dx = e.changedTouches[0].clientX - tx0;
      if (Math.abs(dx) > 40) fbgGo(fbgActive + (dx < 0 ? 1 : -1));
    }, {passive: true});

    fbgItems.forEach(function (el, i) {
      el.onclick = function (e) {
        e.stopPropagation();
        if (i !== fbgActive) fbgGo(i);
        else fbgApply();
      };
    });
  };

  window.fbgApply = function () {
    var url = NWSB_FASHION_BGS[fbgActive];
    nwsbSetFashionBg(url);
    var btn = document.getElementById('fbgApplyBtn');
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
