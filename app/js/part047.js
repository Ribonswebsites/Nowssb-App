
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
})();
