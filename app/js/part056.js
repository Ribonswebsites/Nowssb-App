// "Unlock your full healing potential" subscription banners — Normal Home
// (.nmh-fsec, prefix nmhFsec) and Fashion Home (#sub-promo-card, prefix
// fashFsec) — auto-rotating crossfade background, no dot indicators. Same
// pattern as Word Atelier's rmBannerReset (app/js/part009.js), generalized
// to iterate however many <prefix>SlideN elements exist per banner. Both
// screens are always in the DOM once the app boots, so each just
// self-starts once on load.
(function () {
  function collectSlides(prefix) {
    var slides = [];
    var i = 0;
    var el;
    while ((el = document.getElementById(prefix + 'Slide' + i))) { slides.push(el); i++; }
    return slides;
  }

  function startRotator(prefix) {
    var slides = collectSlides(prefix);
    if (!slides.length) return;
    var intervalKey = '_' + prefix + 'BannerInterval';
    if (window[intervalKey]) { clearInterval(window[intervalKey]); window[intervalKey] = null; }
    slides.forEach(function (s) { s.style.transition = 'none'; s.style.opacity = '0'; });
    slides[0].style.opacity = '1';
    var cur = 0;
    setTimeout(function () {
      slides.forEach(function (s) { s.style.transition = 'opacity 0.9s ease'; });
      if (slides.length > 1) {
        window[intervalKey] = setInterval(function () {
          slides[cur].style.opacity = '0';
          cur = (cur + 1) % slides.length;
          slides[cur].style.opacity = '1';
        }, 4000);
      }
    }, 50);
  }

  window.nmhFsecBannerReset = function () { startRotator('nmhFsec'); };
  window.fashFsecBannerReset = function () { startRotator('fashFsec'); };
  window.nmhFsecBannerReset();
  window.fashFsecBannerReset();
})();
