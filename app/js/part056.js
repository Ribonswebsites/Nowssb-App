// Home page "Unlock your full healing potential" (.nmh-fsec) subscription
// banner — auto-rotating crossfade background, no dot indicators. Same
// pattern as Word Atelier's rmBannerReset (app/js/part009.js), generalized
// to iterate however many nmhFsecSlideN elements exist. Home is always in
// the DOM once the app boots, so this just self-starts once on load.
(function () {
  function collectSlides() {
    var slides = [];
    var i = 0;
    var el;
    while ((el = document.getElementById('nmhFsecSlide' + i))) { slides.push(el); i++; }
    return slides;
  }

  function nmhFsecBannerReset() {
    var slides = collectSlides();
    if (!slides.length) return;
    if (window._nmhFsecBannerInterval) { clearInterval(window._nmhFsecBannerInterval); window._nmhFsecBannerInterval = null; }
    slides.forEach(function (s) { s.style.transition = 'none'; s.style.opacity = '0'; });
    slides[0].style.opacity = '1';
    var cur = 0;
    setTimeout(function () {
      slides.forEach(function (s) { s.style.transition = 'opacity 0.9s ease'; });
      if (slides.length > 1) {
        window._nmhFsecBannerInterval = setInterval(function () {
          slides[cur].style.opacity = '0';
          cur = (cur + 1) % slides.length;
          slides[cur].style.opacity = '1';
        }, 4000);
      }
    }, 50);
  }

  window.nmhFsecBannerReset = nmhFsecBannerReset;
  nmhFsecBannerReset();
})();
