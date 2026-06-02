
(function() {
  function shouldShowIntro(key) {
    var mode = localStorage.getItem('nwsb_intros') || 'always';
    if (mode === 'off') return false;
    if (mode === 'always') return true;
    if (!window._introSeen) window._introSeen = {};
    if (window._introSeen[key]) return false;
    window._introSeen[key] = true;
    return true;
  }
  window.shouldShowIntro = shouldShowIntro;

  window.openIntroSetting = function() {
    if (typeof openSub === 'function') openSub('social');
    setTimeout(function() {
      var row = document.getElementById('intro-setting-row');
      if (row) {
        row.scrollIntoView({ behavior: 'smooth', block: 'center' });
        row.style.transition = 'background 0.3s';
        row.style.background = 'rgba(232,213,163,0.12)';
        setTimeout(function() { row.style.background = ''; }, 1400);
      }
    }, 420);
  };

  window.ssToggleIntros = function(el) {
    var knob = el ? el.querySelector('.stgl-knob') : null;
    if (!knob) return;
    var isOn = parseInt(knob.style.left) > 10;
    if (isOn) {
      document.getElementById('intro-warn-modal').style.display = 'flex';
    } else {
      localStorage.setItem('nwsb_intros', 'always');
      window._introSeen = {};
      knob.style.left = '24px';
      el.style.background = '#e8d5a3';
    }
  };

  window._introWarnConfirm = function() {
    localStorage.setItem('nwsb_intros', 'off');
    var el = document.getElementById('tgl-intros');
    if (el) { var knob = el.querySelector('.stgl-knob'); if (knob) knob.style.left = '4px'; el.style.background = 'rgba(255,255,255,0.1)'; }
    var isp = document.getElementById('isp-toggle');
    if (isp) { var k2 = isp.querySelector('.stgl-knob'); if (k2) { k2.style.left='4px'; k2.style.background='rgba(255,255,255,.52)'; } isp.style.background='rgba(255,255,255,.12)'; }
    document.getElementById('intro-warn-modal').style.display = 'none';
  };

  window._introWarnCancel = function() {
    document.getElementById('intro-warn-modal').style.display = 'none';
  };

  // Sync toggle visual state from localStorage when settings opens
  function _syncIntroToggle() {
    var el = document.getElementById('tgl-intros');
    if (!el) return;
    var mode = localStorage.getItem('nwsb_intros') || 'always';
    var knob = el.querySelector('.stgl-knob');
    if (!knob) return;
    if (mode === 'always') {
      knob.style.left = '24px';
      el.style.background = '#e8d5a3';
    } else {
      knob.style.left = '4px';
      el.style.background = 'rgba(255,255,255,0.1)';
    }
  }
  // Sync on any openSub('social') call — patch after DOM ready
  document.addEventListener('DOMContentLoaded', function() {
    var _prevOpenSub = window.openSub;
    if (typeof _prevOpenSub === 'function') {
      window.openSub = function(id) {
        var result = _prevOpenSub.apply(this, arguments);
        if (id === 'social') {
          // Show settings intro page every time settings opens
          var intro = document.getElementById('ss-intro-page');
          if (intro) intro.classList.remove('sl-intro-hidden');
          setTimeout(_syncIntroToggle, 50);
        }
        return result;
      };
    }
    _syncIntroToggle();

  // Initialize new settings
  (function initNewSettings() {
    // Words per session
    var wps = parseInt(localStorage.getItem('nb_wps') || '5');
    window._pwWordsPerSession = wps;
    var wpsPill = document.getElementById('ss-wps-pill');
    var wpsSub  = document.getElementById('ss-wps-sub');
    if (wpsPill) wpsPill.textContent = wps;
    if (wpsSub)  wpsSub.textContent  = wps + ' words per practice';

    // Repetitions
    var reps = parseInt(localStorage.getItem('nb_reps') || '7');
    window._pwRepCount = reps;
    var repsPill = document.getElementById('ss-reps-pill');
    var repsSub  = document.getElementById('ss-reps-sub');
    if (repsPill) repsPill.textContent = reps + '×';
    if (repsSub)  repsSub.textContent  = reps + '× per word';

    // Sensitivity
    var sens = localStorage.getItem('nb_sensitivity') || 'normal';
    window._pwSensitivity = sens;
    var sensPill = document.getElementById('ss-sens-pill');
    var sensSub  = document.getElementById('ss-sens-sub');
    if (sensPill) sensPill.textContent = sens.charAt(0).toUpperCase() + sens.slice(1);
    if (sensSub)  sensSub.textContent  = ({strict:'Strict — high accuracy required',normal:'Normal — standard match threshold',relaxed:'Relaxed — forgiving match'})[sens];

    // Ambient
    var amb = localStorage.getItem('nb_ambient') || 'off';
    var ambPill = document.getElementById('ss-ambient-pill');
    var ambSub  = document.getElementById('ss-ambient-sub');
    if (ambPill) ambPill.textContent = amb.charAt(0).toUpperCase() + amb.slice(1);
    if (ambSub)  ambSub.textContent  = ({off:'Off — silence during practice',forest:'Forest — birds & wind',ocean:'Ocean — waves & tide',rain:'Rain — gentle rainfall'})[amb];

    // Text size
    var tsz = localStorage.getItem('nb_textsize') || 'm';
    document.documentElement.style.setProperty('--app-text-scale', {s:'0.9',m:'1',l:'1.12'}[tsz]);
    document.documentElement.setAttribute('data-textsize', tsz);
    var tszPill = document.getElementById('ss-textsize-pill');
    var tszSub  = document.getElementById('ss-textsize-sub');
    if (tszPill) tszPill.textContent = tsz.toUpperCase();
    if (tszSub)  tszSub.textContent  = ({s:'Small — compact layout',m:'Medium — default',l:'Large — easier reading'})[tsz];

    // Nav style
    var ns = localStorage.getItem('nwsb_nav_style') || 'glass';
    if (typeof window._applyNavStyle === 'function') window._applyNavStyle(ns);
    var nsPill = document.getElementById('ss-navstyle-pill');
    var nsSub  = document.getElementById('ss-navstyle-sub');
    if (nsPill && window.NAV_PILLS)  nsPill.textContent = window.NAV_PILLS[ns]  || 'Glass';
    if (nsSub  && window.NAV_LABELS) nsSub.textContent  = window.NAV_LABELS[ns] || 'Glassmorphism — frosted translucent';

    // Reduce motion
    var rm = localStorage.getItem('nb_reducemotion') === 'true';
    if (rm) document.documentElement.classList.add('reduce-motion');
    var tglRm = document.getElementById('tgl-reducemotion');
    if (tglRm) {
      var knob = tglRm.querySelector('.stgl-knob');
      if (rm) { tglRm.style.background='#e8d5a3'; if(knob){knob.style.left='24px';knob.style.background='#060c18';} }
    }

    // Bold text
    var bt = localStorage.getItem('nb_boldtext') === 'true';
    if (bt) document.documentElement.classList.add('bold-text');
    var tglBt = document.getElementById('tgl-boldtext');
    if (tglBt) {
      var knobBt = tglBt.querySelector('.stgl-knob');
      if (bt) { tglBt.style.background='#e8d5a3'; if(knobBt){knobBt.style.left='24px';knobBt.style.background='#060c18';} }
    }

    // Auto-advance (default OFF)
    var aa = localStorage.getItem('nb_autoadvance') === 'true';
    var tglAa = document.getElementById('tgl-autoadvance');
    if (tglAa) {
      var knobAa = tglAa.querySelector('.stgl-knob');
      if (aa) { tglAa.style.background='#e8d5a3'; if(knobAa){knobAa.style.left='24px';knobAa.style.background='#060c18';} }
      else { tglAa.style.background='rgba(255,255,255,.1)'; if(knobAa){knobAa.style.left='4px';knobAa.style.background='rgba(255,255,255,.52)';} }
    }

    // Auto-play (default OFF)
    var ap = localStorage.getItem('nb_autoplay') === 'true';
    var tglAp = document.getElementById('tgl-autoplay');
    if (tglAp) {
      var knobAp = tglAp.querySelector('.stgl-knob');
      if (ap) { tglAp.style.background='#e8d5a3'; if(knobAp){knobAp.style.left='24px';knobAp.style.background='#060c18';} }
      else { tglAp.style.background='rgba(255,255,255,.1)'; if(knobAp){knobAp.style.left='4px';knobAp.style.background='rgba(255,255,255,.52)';} }
    }

    // Haptic (default ON)
    var hap = localStorage.getItem('nb_haptic') !== 'false';
    var tglHap = document.getElementById('tgl-haptic');
    if (tglHap) {
      var knobHap = tglHap.querySelector('.stgl-knob');
      if (hap) { tglHap.style.background='#e8d5a3'; if(knobHap){knobHap.style.left='24px';knobHap.style.background='#060c18';} }
      else { tglHap.style.background='rgba(255,255,255,.1)'; if(knobHap){knobHap.style.left='4px';knobHap.style.background='rgba(255,255,255,.52)';} }
    }

    // Screen wake (default ON)
    var sw = localStorage.getItem('nb_screenwake') !== 'false';
    var tglSw = document.getElementById('tgl-screenwake');
    if (tglSw) {
      var knobSw = tglSw.querySelector('.stgl-knob');
      if (sw) { tglSw.style.background='#e8d5a3'; if(knobSw){knobSw.style.left='24px';knobSw.style.background='#060c18';} }
      else { tglSw.style.background='rgba(255,255,255,.1)'; if(knobSw){knobSw.style.left='4px';knobSw.style.background='rgba(255,255,255,.52)';} }
    }

    // Cache size
    setTimeout(function(){
      var total = 0;
      for (var i = 0; i < localStorage.length; i++) {
        var k = localStorage.key(i);
        total += (k ? k.length : 0) + (localStorage.getItem(k) || '').length;
      }
      var kb = (total * 2 / 1024).toFixed(1);
      var el = document.getElementById('ss-cache-size');
      if (el) el.textContent = kb + ' KB used — tap to clear non-essential data';
    }, 1200);

    // Show retake row if user skipped onboarding
    var skipped = localStorage.getItem('nwsb_ob_skipped') === 'true' ||
      (window._userDataCache && window._userDataCache.onboardingSkipped);
    var retakeRow = document.getElementById('ss-retake-row');
    if (retakeRow) retakeRow.style.display = skipped ? 'flex' : 'none';
  })();

  });
})();
