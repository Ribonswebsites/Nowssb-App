
function openAppGuide() {
  var guide = document.getElementById('nwAppGuide');
  var intro = document.getElementById('nwag-intro');
  var panel = document.getElementById('nwag-panel');
  // Hard-reset every time — prevents hang on re-tap
  intro.style.display = 'flex';
  intro.style.opacity = '1';
  panel.style.display = 'none';
  panel.style.opacity = '0';
  guide.classList.add('open');
  document.getElementById('nwag-body').scrollTop = 0;
  // Show scroll hint on panel open
  setTimeout(function() { nwagShowScrollHint(); }, 800);
}
function nwagShowGuide() {
  var intro = document.getElementById('nwag-intro');
  var panel = document.getElementById('nwag-panel');
  intro.style.opacity = '0';
  setTimeout(function() {
    intro.style.display = 'none';
    panel.style.display = 'flex';
    void panel.offsetHeight; // force reflow so transition fires
    panel.style.opacity = '1';
    setTimeout(function() { nwagShowScrollHint(); }, 600);
  }, 280);
}
function nwagShowScrollHint() {
  var hint = document.getElementById('nwag-scroll-hint');
  if (!hint) return;
  hint.classList.add('visible');
  setTimeout(function() { hint.classList.remove('visible'); }, 2200);
}
function closeAppGuide() {
  document.getElementById('nwAppGuide').classList.remove('open');
}
// Close on overlay tap
document.getElementById('nwag-overlay').addEventListener('click', closeAppGuide);

/* ── Open a section from the guide + force its page guide to show ── */
function nwagOpenSection(id) {
  closeAppGuide();

  // These screens need their EnterFromIntro to fire the guide —
  // we reset seen + open the sub, then auto-trigger enter after transition
  var introScreens = {
    'word-science':  function() { setTimeout(function() { if (window.wsEnterFromIntro) wsEnterFromIntro(); }, 500); },
    'profile':       function() { setTimeout(function() { if (window.profileEnterFromIntro) profileEnterFromIntro(); }, 500); },
    'real-meaning':  function() { setTimeout(function() { if (window.rmEnterFromIntro) rmEnterFromIntro(); }, 500); },
    'shabdapathy':   function() { setTimeout(function() { if (window.shabdaEnterFromIntro) shabdaEnterFromIntro(); }, 500); }
  };

  // Reset the seen flag so the guide always shows when coming from the guide panel
  if (window._pgMarkSeen && window._pgSeen) {
    delete window._pgSeen[id];
    try { localStorage.setItem('nwsb_pg', JSON.stringify(window._pgSeen)); } catch(e) {}
  }

  // ensure home screen is visible before opening any sub-panel
  if (typeof goTo === 'function') {
    var _pm2 = localStorage.getItem('nwsb_home_mode') || 'nm';
    goTo(_pm2 === 'nm' ? 'home-nm' : 'home');
  }

  setTimeout(function() {
    if (typeof openSub === 'function') openSub(id);
    if (introScreens[id]) introScreens[id]();
  }, 400); // slightly longer to let goTo transition settle
}

// ── GUIDE BANNER: 3D SCROLL PARALLAX + TOUCH TILT ──
(function() {
  var bannerImg = document.getElementById('nwag-banner-img');
  var bannerEl  = document.getElementById('nwag-banner');
  var bodyEl    = document.getElementById('nwag-body');

  // ── Scroll parallax — banner image rises as you scroll (same rate as hero) ──
  bodyEl.addEventListener('scroll', function() {
    var sy = bodyEl.scrollTop;
    if (bannerImg) {
      bannerImg.style.transform = 'scale(1.08) translateY(' + (sy * 0.38) + 'px)';
    }
    // Hide scroll hint the moment user scrolls
    if (sy > 8) {
      var hint = document.getElementById('nwag-scroll-hint');
      if (hint) hint.classList.remove('visible');
    }
  }, { passive: true });

  // ── Touch tilt — 3D perspective tilt on drag, reset on release ──
  function applyGuideTilt(clientX, clientY) {
    var rect = bannerEl.getBoundingClientRect();
    var cx = rect.width / 2, cy = rect.height / 2;
    var dx = (clientX - cx) / cx;
    var dy = (clientY - cy) / cy;
    var rotY =  dx * 5;
    var rotX = -dy * 3.5;
    bannerImg.style.transform = 'perspective(900px) rotateX(' + rotX + 'deg) rotateY(' + rotY + 'deg) scale(1.06)';
    bannerImg.style.transition = 'transform 0.12s ease-out';
  }

  function resetGuideTilt() {
    bannerImg.style.transform = 'perspective(900px) rotateX(0deg) rotateY(0deg) scale(1.08)';
    bannerImg.style.transition = 'transform 0.55s cubic-bezier(0.25,0.46,0.45,0.94)';
  }

  bannerEl.addEventListener('touchmove', function(e) {
    // Only tilt when near top of scroll (banner visible)
    if (bodyEl.scrollTop < bannerEl.offsetHeight) {
      applyGuideTilt(e.touches[0].clientX, e.touches[0].clientY);
    }
  }, { passive: true });
  bannerEl.addEventListener('touchend', resetGuideTilt);
  bannerEl.addEventListener('mousemove', function(e) { applyGuideTilt(e.clientX, e.clientY); });
  bannerEl.addEventListener('mouseleave', resetGuideTilt);
})();
