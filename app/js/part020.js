
(function() {
  // ── State ──
  var _explOpen = false;

  // ── Open / Close overlay ──
  function openExploreOverlay() {
    var el = document.getElementById('exploreOverlay');
    el.classList.add('expl-open');
    requestAnimationFrame(function() {
      requestAnimationFrame(function() {
        el.classList.add('expl-slide-in');
      });
    });
    // always start at intro page
    showIntroPage();
    document.body.style.overflow = 'hidden';
    _explOpen = true;
  }

  function closeExploreOverlay() {
    var el = document.getElementById('exploreOverlay');
    el.classList.remove('expl-slide-in');
    el.addEventListener('transitionend', function handler() {
      el.classList.remove('expl-open');
      el.removeEventListener('transitionend', handler);
      document.body.style.overflow = '';
      _explOpen = false;
    }, { once: true });
  }

  // ── Intro / Cards toggle ──
  function showIntroPage() {
    document.getElementById('explIntroPage').classList.remove('expl-intro-hidden');
    document.getElementById('explCardsList').classList.remove('expl-cards-visible');
    document.getElementById('explCardsList').style.display = 'none';
  }

  function showCards() {
    var intro = document.getElementById('explIntroPage');
    intro.classList.add('expl-intro-hidden');
    var cards = document.getElementById('explCardsList');
    cards.style.display = 'flex';
    cards.classList.add('expl-cards-visible');
    cards.scrollTop = 0;
  }

  function explShowIntro() {
    showIntroPage();
  }

  // ── Open a section then close overlay ──
  function exploreOpen(section) {
    closeExploreOverlay();
    setTimeout(function() {
      if (typeof openSub === 'function') openSub(section);
    }, 340);
  }

  // ── 3D Tilt parallax on intro bg (same as hero section) ──
  var introBg   = document.getElementById('explIntroBg');
  var introPage = document.getElementById('explIntroPage');

  function applyExplTilt(clientX, clientY) {
    var rect = introPage.getBoundingClientRect();
    var cx = rect.width / 2, cy = rect.height / 2;
    var dx = (clientX - cx) / cx;
    var dy = (clientY - cy) / cy;
    var rotY =  dx * 5;
    var rotX = -dy * 3.5;
    introBg.style.transform = 'perspective(900px) rotateX(' + rotX + 'deg) rotateY(' + rotY + 'deg) scale(1.04)';
    introBg.style.transition = 'transform 0.12s ease-out';
  }

  function resetExplTilt() {
    introBg.style.transform = 'perspective(900px) rotateX(0deg) rotateY(0deg) scale(1)';
    introBg.style.transition = 'transform 0.55s cubic-bezier(0.25,0.46,0.45,0.94)';
  }

  introPage.addEventListener('touchmove', function(e) {
    applyExplTilt(e.touches[0].clientX, e.touches[0].clientY);
  }, { passive: true });
  introPage.addEventListener('touchend', resetExplTilt);
  introPage.addEventListener('mousemove', function(e) { applyExplTilt(e.clientX, e.clientY); });
  introPage.addEventListener('mouseleave', resetExplTilt);

  // ── Scroll parallax on cards banner bg ──
  var cardsList  = document.getElementById('explCardsList');
  var bannerBg   = document.getElementById('explCardsBannerBg');

  cardsList.addEventListener('scroll', function() {
    var sy = cardsList.scrollTop;
    if (bannerBg) {
      bannerBg.style.transform = 'scale(1.08) translateY(' + (sy * 0.32) + 'px)';
    }
  }, { passive: true });

  // ── Wire Enter button ──
  var enterBtn = document.getElementById('explEnterBtn');
  if (enterBtn) {
    function doEnter(e) {
      if (e && e.preventDefault) e.preventDefault();
      showCards();
    }
    enterBtn.addEventListener('click', doEnter);
    enterBtn.addEventListener('touchend', doEnter);
  }

  // ── Expose globals ──
  window.openExploreOverlay  = openExploreOverlay;
  window.closeExploreOverlay = closeExploreOverlay;
  window.explShowIntro       = explShowIntro;
  window.exploreOpen         = exploreOpen;
})();
