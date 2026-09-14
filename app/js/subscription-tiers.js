/* Subscription offer inside home TV/frame — black banners + pricing only.
   No decorative videos/images inside the framed aperture. */
(function () {
  'use strict';
  var tiers = [
    { name: 'Free', detail: 'NowssB Edition · 30 days free', tone: '#f2f2f4' },
    { name: 'Resonance', detail: '$4.99 / month · $41.90 / year', tone: '#c8e8f5' },
    { name: 'Frequency', detail: '$9.99 / month · $83.90 / year', tone: '#e8d5a3' },
    { name: 'Frequency X', detail: '$19.99 / month · $167.90 / year', tone: '#f2f2f4' }
  ];
  function arrow() {
    return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h13M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  }
  function blackBanner(title, detail, tone) {
    return '<button class="nwsb-sub-plan-banner" type="button" data-tier="' + title +
      '" onclick="if(window.SS)SS.open(\'subscription\')">' +
      '<span class="nwsb-sub-plan-copy"><strong style="color:' + (tone || '#fff') + '">' + title +
      '</strong><small>' + detail + '</small></span>' +
      '<span class="nwsb-sub-plan-go">' + arrow() + '</span></button>';
  }
  function render(block) {
    if (!block || block.dataset.nwsbSubscriptionReady) return;
    var screen = block.querySelector('.vbs-screen');
    if (!screen) return;
    block.dataset.nwsbSubscriptionReady = 'true';
    var oldBanner = block.querySelector('.nsub-ban');
    if (oldBanner) oldBanner.classList.add('nwsb-sub-legacy-hidden');
    var oldCta = screen.querySelector('.nmh-banner-cta,.fash-banner-cta');
    if (oldCta) oldCta.classList.add('nwsb-sub-legacy-hidden');
    // Remove decorative video/image from framed content
    screen.querySelectorAll('video, img.nwsb-sub-deco').forEach(function (el) {
      el.removeAttribute('src');
      el.removeAttribute('poster');
      el.classList.add('nwsb-sub-legacy-hidden');
      try { el.pause && el.pause(); } catch (e) {}
    });
    screen.classList.add('nwsb-sub-screen-banners');
    var overlay = document.createElement('div');
    overlay.className = 'nwsb-sub-overlay nwsb-sub-overlay-banners';
    overlay.innerHTML =
      '<button class="nwsb-sub-upgrade-banner" type="button" onclick="if(window.SS)SS.open(\'subscription\')">' +
        '<span class="nwsb-sub-banner-copy"><strong>Subscription</strong><strong>Join NowssB</strong>' +
        '<small>Try it free for 30 days · Choose your frequency</small></span><span>' + arrow() + '</span></button>' +
      '<div class="nwsb-sub-plan-banner-list" aria-label="Subscription tiers">' +
        tiers.map(function (t) { return blackBanner(t.name, t.detail, t.tone); }).join('') +
      '</div>';
    screen.appendChild(overlay);
  }
  function init() { document.querySelectorAll('.nsub-blk').forEach(render); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
  window.addEventListener('nwsb:home-ready', init);

  // Full subscription page: strip decorative video banner, inject tier black banners
  function polishSubscriptionPage() {
    var panel = document.getElementById('ss-panel-subscription');
    if (!panel || panel.dataset.nwsbSubPolished) return;
    panel.dataset.nwsbSubPolished = 'true';
    var bg = panel.querySelector('.nwsb-sub-page-bg');
    if (bg) {
      try { bg.pause && bg.pause(); } catch (e) {}
      bg.removeAttribute('src');
      bg.classList.add('nwsb-sub-legacy-hidden');
    }
    var planBanner = panel.querySelector('.ss-plan-banner');
    if (planBanner) {
      planBanner.querySelectorAll('video').forEach(function (v) {
        try { v.pause && v.pause(); } catch (e) {}
        v.removeAttribute('src');
        v.classList.add('nwsb-sub-legacy-hidden');
      });
      planBanner.classList.add('ss-plan-banner-static');
      var list = planBanner.querySelector('.nwsb-sub-plan-banner-list');
      if (!list) {
        list = document.createElement('div');
        list.className = 'nwsb-sub-plan-banner-list nwsb-sub-plan-banner-list-page';
        list.setAttribute('aria-label', 'Subscription tiers');
        planBanner.appendChild(list);
      }
      if (!list.children.length) {
        list.innerHTML = tiers.map(function (t) {
          return blackBanner(t.name, t.detail, t.tone);
        }).join('');
      }
    }
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', polishSubscriptionPage);
  } else {
    polishSubscriptionPage();
  }
  window.addEventListener('nwsb:home-ready', polishSubscriptionPage);

  var slides = [
    ['SUBSCRIPTION · JOIN NOWSSB', 'Try it free for 30 days · Choose your frequency'],
    ['EVERY WORD · EVERY FREQUENCY', 'Unlock the full NowssB practice'],
    ['JOIN NOWSSB', 'Get your subscription today']
  ];
  var slideIndex = 0;
  function rotateSubscriptionBanners() {
    var bars = document.querySelectorAll('.nwsb-web-sub-black-banner');
    if (!bars.length) return;
    slideIndex = (slideIndex + 1) % slides.length;
    bars.forEach(function (bar) {
      var strong = bar.querySelector('strong');
      var span = bar.querySelector('span');
      if (strong) strong.textContent = slides[slideIndex][0];
      if (span) span.textContent = slides[slideIndex][1];
      bar.classList.remove('nwsb-banner-swap');
      void bar.offsetWidth;
      bar.classList.add('nwsb-banner-swap');
    });
  }
  setInterval(rotateSubscriptionBanners, 3000);
  document.addEventListener('scroll', function () {
    var rail = document.getElementById('ss-plan-cards');
    var bottom = document.querySelector('.nwsb-web-sub-bottom');
    if (!rail || !bottom) return;
    var cards = rail.querySelectorAll('.plan-card');
    var best = null, bestDistance = Infinity;
    cards.forEach(function (card) {
      var d = Math.abs(card.getBoundingClientRect().left - rail.getBoundingClientRect().left);
      if (d < bestDistance) { best = card; bestDistance = d; }
    });
    if (best) {
      var name = best.querySelector('.plan-card-name');
      var label = best.querySelector('strong');
      if (name && label) label.textContent = 'JOIN NOWSSB · ' + name.textContent;
    }
  }, {passive:true});
})();
