// Subscription page hero banner — auto-rotating crossfade, no dot
// indicators. Same reset-on-open pattern as Word Atelier's rmBannerReset
// (app/js/part009.js): stop any running interval, snap back to slide 0,
// then cycle. Iterates however many ssHeroSlideN elements exist, so
// adding another slide later needs no JS change.
(function () {
  function collectSlides() {
    var slides = [];
    var i = 0;
    var el;
    while ((el = document.getElementById('ssHeroSlide' + i))) { slides.push(el); i++; }
    return slides;
  }

  function ssHeroBannerReset() {
    var slides = collectSlides();
    if (!slides.length) return;
    if (window._ssHeroBannerInterval) { clearInterval(window._ssHeroBannerInterval); window._ssHeroBannerInterval = null; }
    slides.forEach(function (s) { s.style.transition = 'none'; s.style.opacity = '0'; });
    slides[0].style.opacity = '1';
    var cur = 0;
    setTimeout(function () {
      slides.forEach(function (s) { s.style.transition = 'opacity 0.9s ease'; });
      if (slides.length > 1) {
        window._ssHeroBannerInterval = setInterval(function () {
          slides[cur].style.opacity = '0';
          cur = (cur + 1) % slides.length;
          slides[cur].style.opacity = '1';
        }, 4000);
      }
    }, 50);
  }

  window.ssHeroBannerReset = ssHeroBannerReset;
  ssHeroBannerReset();
})();
