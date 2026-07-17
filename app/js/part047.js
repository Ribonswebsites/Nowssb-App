
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
    var map = {'':'default','fashion':'black','neo':'neo','glass':'glass-black'};
    window.setNwsbTheme(map[style || ''] || 'default');
  };

  // Init from localStorage
  var saved = localStorage.getItem('nwsb_theme') || 'default';
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

  function renderFashionBgRow() {
    var row = document.getElementById('nwsbFbgRow');
    if (!row) return;
    var current = null;
    try { current = localStorage.getItem('nwsb_fashion_bg_custom'); } catch (e) {}
    row.innerHTML = NWSB_FASHION_BGS.map(function (url) {
      return '<div class="nwsb-fbg-card' + (url === current ? ' active' : '') + '" onclick="nwsbSetFashionBg(\'' + url + '\')">' +
        '<div class="nwsb-fbg-img" style="background-image:url(\'' + url + '\')"></div>' +
      '</div>';
    }).join('');
  }

  window.nwsbSetFashionBg = function (url) {
    document.body.style.setProperty('--nwsb-custom-bg-url', "url('" + url + "')");
    document.body.classList.add('nwsb-custom-fashion-bg');
    try { localStorage.setItem('nwsb_fashion_bg_custom', url); } catch (e) {}
    if (window._currentUid && window._fbSetDoc) {
      window._fbSetDoc(window._currentUid, { fashionBgCustom: url }).catch(function () {});
    }
    renderFashionBgRow();
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
    renderFashionBgRow();
    return _origSetNwsbTheme(theme, explicit);
  };

  (function initFashionBg() {
    var saved2 = null;
    try { saved2 = localStorage.getItem('nwsb_fashion_bg_custom'); } catch (e) {}
    if (saved2) {
      document.body.style.setProperty('--nwsb-custom-bg-url', "url('" + saved2 + "')");
      document.body.classList.add('nwsb-custom-fashion-bg');
    }
    renderFashionBgRow();
  })();
})();
