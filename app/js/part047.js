
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
  window.NWSB_FASHION_BGS = NWSB_FASHION_BGS;

  // Sentinel stored in localStorage when "Black" is picked instead of a
  // real photo — lets every consumer (this file's own CSS var, rmStoreBgSync,
  // msStoreBgSync) tell "plain black" apart from "no customization at all".
  var NWSB_BG_BLACK = '__black__';

  // Dedicated success toast for the Fashion Background picker — black pill,
  // the same customize-background icon on the left, a proper checkmark
  // badge instead of a bare "✓" character. Kept separate from the generic
  // nwsbToast() (used app-wide for unrelated messages) so this redesign
  // only touches this one flow.
  function fbgApplyToast(msg) {
    var t = document.createElement('div');
    t.className = 'fbg-toast';
    t.innerHTML =
      '<div class="fbg-toast-icon"><img loading="lazy" decoding="async" src="https://res.cloudinary.com/eenvubod/image/upload/v1784318203/file_00000000b11472098a225d3703b04a60_phr6ph.png" alt=""></div>' +
      '<div class="fbg-toast-text"></div>' +
      '<div class="fbg-toast-check"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#060c18" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg></div>';
    t.querySelector('.fbg-toast-text').textContent = msg;
    document.body.appendChild(t);
    requestAnimationFrame(function () { requestAnimationFrame(function () { t.classList.add('show'); }); });
    setTimeout(function () {
      t.classList.remove('show');
      setTimeout(function () { if (t.parentNode) t.parentNode.removeChild(t); }, 260);
    }, 2200);
  }

  window.nwsbSetFashionBg = function (url) {
    document.body.style.setProperty('--nwsb-custom-bg-url', "url('" + url + "')");
    document.body.style.setProperty('--nwsb-custom-bg-color', 'transparent');
    document.body.classList.add('nwsb-custom-fashion-bg');
    try { localStorage.setItem('nwsb_fashion_bg_custom', url); } catch (e) {}
    if (window._currentUid && window._fbSetDoc) {
      window._fbSetDoc(window._currentUid, { fashionBgCustom: url }).catch(function () {});
    }
    fbgApplyToast('Background updated');
    _nwsbSyncBgConsumers();
  };

  // "Black" toggle — plain solid black, no photo.
  window.nwsbSetFashionBgBlack = function () {
    document.body.style.setProperty('--nwsb-custom-bg-url', 'none');
    document.body.style.setProperty('--nwsb-custom-bg-color', '#000');
    document.body.classList.add('nwsb-custom-fashion-bg');
    try { localStorage.setItem('nwsb_fashion_bg_custom', NWSB_BG_BLACK); } catch (e) {}
    if (window._currentUid && window._fbSetDoc) {
      window._fbSetDoc(window._currentUid, { fashionBgCustom: NWSB_BG_BLACK }).catch(function () {});
    }
    fbgApplyToast('Background set to black');
    _nwsbSyncBgConsumers();
  };

  // "Default" toggle — clears all customization, back to the built-in look.
  window.nwsbClearFashionBg = function () {
    document.body.classList.remove('nwsb-custom-fashion-bg');
    document.body.style.removeProperty('--nwsb-custom-bg-url');
    document.body.style.removeProperty('--nwsb-custom-bg-color');
    try { localStorage.removeItem('nwsb_fashion_bg_custom'); } catch (e) {}
    if (window._currentUid && window._fbSetDoc) {
      window._fbSetDoc(window._currentUid, { fashionBgCustom: null }).catch(function () {});
    }
    fbgApplyToast('Background reset to default');
    _nwsbSyncBgConsumers();
  };

  // Other screens with their own "customize background" icon (Word
  // Atelier, Meaning Store, ...) reuse this exact picker — re-sync them
  // immediately so the change shows the moment you close the picker,
  // whether or not that screen happens to be the one visible right now.
  function _nwsbSyncBgConsumers() {
    if (typeof window.rmStoreBgSync === 'function') window.rmStoreBgSync();
    if (typeof window.msStoreBgSync === 'function') window.msStoreBgSync();
    if (typeof window.nwsbConnectSetupBgSync === 'function') window.nwsbConnectSetupBgSync();
    if (typeof window.nwsbVerifyBgSync === 'function') window.nwsbVerifyBgSync();
    if (typeof window.nwsbVkycBgSync === 'function') window.nwsbVkycBgSync();
  }

  // The Fashion Background picker lives inside #sub-social, a plain
  // .sub-screen (z-index:600). Screens that call SS.open('fashionbg') from
  // their OWN much-higher-z-index overlay (NowssB Verified at 100001, the
  // Connect setup wizard at 9400, ...) need #sub-social bumped above that
  // overlay first — otherwise the picker opens but paints invisibly behind
  // it, which reads as "the button doesn't do anything". Reset happens the
  // moment #sub-social loses its .open class again (SS.close removes it).
  window.nwsbOpenFashionBgOverlay = function () {
    var sc = document.getElementById('sub-social');
    if (sc) {
      sc.style.zIndex = '200000';
      var mo = new MutationObserver(function () {
        if (!sc.classList.contains('open')) {
          sc.style.zIndex = '';
          mo.disconnect();
        }
      });
      mo.observe(sc, { attributes: true, attributeFilter: ['class'] });
    }
    if (window.SS) window.SS.open('fashionbg');
  };

  // Explicitly picking a Black-Edition theme card clears any custom photo —
  // otherwise the !important custom override would keep winning over the
  // theme's own background, which reads as broken ("I picked Black but my
  // old photo is still showing").
  var _origSetNwsbTheme = window.setNwsbTheme;
  window.setNwsbTheme = function (theme, explicit) {
    document.body.classList.remove('nwsb-custom-fashion-bg');
    document.body.style.removeProperty('--nwsb-custom-bg-url');
    document.body.style.removeProperty('--nwsb-custom-bg-color');
    try { localStorage.removeItem('nwsb_fashion_bg_custom'); } catch (e) {}
    return _origSetNwsbTheme(theme, explicit);
  };

  (function initFashionBg() {
    var saved2 = null;
    try { saved2 = localStorage.getItem('nwsb_fashion_bg_custom'); } catch (e) {}
    if (saved2 === NWSB_BG_BLACK) {
      document.body.style.setProperty('--nwsb-custom-bg-url', 'none');
      document.body.style.setProperty('--nwsb-custom-bg-color', '#000');
      document.body.classList.add('nwsb-custom-fashion-bg');
    } else if (saved2) {
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
  // Staged (not-yet-applied) Default/Black card selection. null = defer to
  // the carousel's centered photo instead — nothing actually changes on
  // the live background until fbgApply() runs (APPLY THIS BACKGROUND).
  var fbgStagedMode = null;

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
      el.style.borderColor   = (!fbgStagedMode && i === fbgActive) ? '#e8d5a3' : 'rgba(255,255,255,0.08)';
    });
    if (fbgDotEls) fbgDotEls.forEach(function (d, i) { d.classList.toggle('active', i === fbgActive); });
    var label = document.getElementById('fbgSelectedLabel');
    if (label) label.textContent = 'Background ' + (fbgActive + 1) + ' of ' + FBG_N;
    var previewBg = document.getElementById('fbgPreviewBg');
    if (previewBg) previewBg.style.backgroundImage = "url('" + NWSB_FASHION_BGS[fbgActive] + "')";
  }

  function fbgGo(n) { fbgActive = ((n % FBG_N) + FBG_N) % FBG_N; fbgPaint(); }

  /* ── Intro: enter picker from intro page (same pattern as Black Edition's
     beEnterFromIntro/beIntroReset in part048.js) — shown once ever, then
     every later open skips straight to the picker itself. ── */
  window.fbgEnterFromIntro = function () {
    try { localStorage.setItem('nwsb_fbg_intro_seen', '1'); } catch (e) {}
    var intro = document.getElementById('fbgIntroPage');
    var main  = document.getElementById('fbgMainContent');
    if (intro) intro.classList.add('sl-intro-hidden');
    setTimeout(function () {
      if (intro) intro.style.display = 'none';
      if (main)  main.style.display = 'block';
      fbgCarouselInit();
    }, 420);
  };
  window.fbgIntroReset = function () {
    var intro = document.getElementById('fbgIntroPage');
    var main  = document.getElementById('fbgMainContent');
    var seen = false;
    try { seen = localStorage.getItem('nwsb_fbg_intro_seen') === '1'; } catch (e) {}
    if (seen) {
      if (intro) { intro.style.display = 'none'; intro.classList.add('sl-intro-hidden'); }
      if (main)  main.style.display = 'block';
      fbgCarouselInit();
      return;
    }
    if (intro) { intro.style.display = 'flex'; intro.classList.remove('sl-intro-hidden'); }
    if (main)  main.style.display = 'none';
  };

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

    // Start from whichever photo is currently applied, if any — and seed
    // the staged mode from the currently COMMITTED state (not just left
    // over from a previous open) so reopening the picker shows the truth.
    var cur = null;
    try { cur = localStorage.getItem('nwsb_fashion_bg_custom'); } catch (e) {}
    if (cur === NWSB_BG_BLACK) fbgStagedMode = 'black';
    else if (!cur) fbgStagedMode = 'default';
    else fbgStagedMode = null;
    var idx = NWSB_FASHION_BGS.indexOf(cur);
    fbgActive = idx >= 0 ? idx : 0;
    var previewBg0 = document.getElementById('fbgPreviewBg');
    if (previewBg0) previewBg0.style.backgroundImage = "url('" + NWSB_FASHION_BGS[fbgActive] + "')";

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

    // touch-action:pan-y (inline on #fbgCarousel) already tells the browser
    // this element handles its own horizontal gestures, but Android
    // WebViews can still kick off their native edge-swipe-back page slide
    // on a horizontal drag unless touchmove is actively prevented too —
    // belt-and-braces so swiping through the carousel never drags the
    // whole page sideways with it.
    var tx0 = 0, ty0 = 0;
    carousel.addEventListener('touchstart', function (e) { tx0 = e.touches[0].clientX; ty0 = e.touches[0].clientY; }, {passive: true});
    carousel.addEventListener('touchmove', function (e) {
      var dx = e.touches[0].clientX - tx0;
      var dy = e.touches[0].clientY - ty0;
      if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 8 && e.cancelable) e.preventDefault();
    }, {passive: false});
    carousel.addEventListener('touchend', function (e) {
      var dx = e.changedTouches[0].clientX - tx0;
      if (Math.abs(dx) > 40) {
        fbgStagedMode = null;
        fbgSyncModeButtons();
        fbgGo(fbgActive + (dx < 0 ? 1 : -1));
      }
    }, {passive: true});

    fbgItems.forEach(function (el, i) {
      el.onclick = function (e) {
        e.stopPropagation();
        fbgStagedMode = null;
        fbgSyncModeButtons();
        if (i !== fbgActive) fbgGo(i);
        else fbgApply();
      };
    });

    fbgSyncModeButtons();
  };

  window.fbgApply = function () {
    if (fbgStagedMode === 'black') {
      window.nwsbSetFashionBgBlack();
    } else if (fbgStagedMode === 'default') {
      window.nwsbClearFashionBg();
    } else {
      var url = NWSB_FASHION_BGS[fbgActive];
      nwsbSetFashionBg(url);
    }
    fbgSyncModeButtons();
    fbgPaint();
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

  // "Default" / "Black" cards — an alternative to picking one of the 9
  // photos. Tapping only STAGES the choice (highlights the card, dims the
  // carousel's gold border) — nothing on the live background actually
  // changes until APPLY THIS BACKGROUND is pressed, same as picking a photo.
  window.fbgSelectMode = function (mode) {
    fbgStagedMode = (mode === 'black') ? 'black' : 'default';
    fbgSyncModeButtons();
    fbgPaint();
  };
  function fbgSyncModeButtons() {
    var cardDefault = document.getElementById('fbgModeCardDefault');
    var cardBlack   = document.getElementById('fbgModeCardBlack');
    if (cardDefault) cardDefault.classList.toggle('on', fbgStagedMode === 'default');
    if (cardBlack)   cardBlack.classList.toggle('on', fbgStagedMode === 'black');
  }
})();
