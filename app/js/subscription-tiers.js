/* Add the subscription offer inside the existing home TV/frame/video. */
(function () {
  'use strict';
  var tiers = [
    { name: 'Free', detail: 'NowssB Edition', tone: '#f2f2f4' },
    { name: 'Resonance', detail: '$4.99 / month', tone: '#c8e8f5' },
    { name: 'Frequency', detail: '$9.99 / month', tone: '#e8d5a3' },
    { name: 'Frequency X', detail: '$19.99 / month', tone: '#f2f2f4' }
  ];
  function arrow() { return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h13M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>'; }
  function sparkle() { return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3c.4 3.6 1 5.2 2.4 6.6C15.8 11 17.4 11.6 21 12c-3.6.4-5.2 1-6.6 2.4C13 15.8 12.4 17.4 12 21c-.4-3.6-1-5.2-2.4-6.6C8.2 13 6.6 12.4 3 12c3.6-.4 5.2-1-6.6-2.4C11 8.2 11.6 6.6 12 3z" fill="currentColor"/></svg>'; }
  function row(tier, index) {
    return '<button class="nwsb-sub-tier" type="button" data-tier="' + tier.name + '" onclick="if(window.SS)SS.open(\'subscription\')">' +
      '<span class="nwsb-sub-icon-glass">' + sparkle() + '</span>' +
      '<span class="nwsb-sub-tier-pill"><span class="nwsb-sub-tier-copy"><strong style="color:' + tier.tone + '">' + tier.name + '</strong><small>' + tier.detail + '</small></span><span class="nwsb-sub-enter-glass">' + arrow() + '</span></span>' +
      (index < tiers.length - 1 ? '<span class="nwsb-sub-hairline" aria-hidden="true"></span>' : '') + '</button>';
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
    var overlay = document.createElement('div');
    overlay.className = 'nwsb-sub-overlay';
    overlay.innerHTML = '<button class="nwsb-sub-upgrade-banner" type="button" onclick="if(window.SS)SS.open(\'subscription\')"><span class="nwsb-sub-banner-copy"><strong>Subscription</strong><strong>Join NowssB</strong><small>Try it free for 30 days · Choose your frequency</small></span><span>' + arrow() + '</span></button>' +
      '<div class="nwsb-sub-tier-list" aria-label="Subscription tiers">' + tiers.map(row).join('') + '</div>' +
      '<div class="nwsb-sub-trial-copy"><strong>Join NowssB</strong><span>Get your subscription today</span></div>' +
      '<button class="nwsb-subscribe-cta" type="button" onclick="if(window.SS)SS.open(\'subscription\')"><span>Get Subscription Today</span><span>' + arrow() + '</span></button>';
    screen.appendChild(overlay);
    var video = screen.querySelector('video');
    if (video) {
      video.muted = true; video.defaultMuted = true; video.loop = true; video.playsInline = true; video.setAttribute('preload', 'auto');
      var play = function () { var p = video.play(); if (p && p.catch) p.catch(function () {}); };
      video.addEventListener('canplay', play, { once: true }); play();
    }
  }
  function init() { document.querySelectorAll('.nsub-blk').forEach(render); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
  window.addEventListener('nwsb:home-ready', init);
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
