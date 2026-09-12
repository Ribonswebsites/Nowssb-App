/* Shared subscription TV composition for the website and Capacitor WebView. */
(function () {
  'use strict';
  var tiers = [
    { name: 'Free', detail: 'NowssB Edition', tone: '#f2f2f4' },
    { name: 'Resonance', detail: '$4.99 / month', tone: '#c8e8f5' },
    { name: 'Frequency', detail: '$9.99 / month', tone: '#e8d5a3' },
    { name: 'Frequency X', detail: '$19.99 / month', tone: '#f2f2f4' }
  ];
  function arrow() {
    return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h13M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  }
  function sparkle() {
    return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3c.4 3.6 1 5.2 2.4 6.6C15.8 11 17.4 11.6 21 12c-3.6.4-5.2 1-6.6 2.4C13 15.8 12.4 17.4 12 21c-.4-3.6-1-5.2-2.4-6.6C8.2 13 6.6 12.4 3 12c3.6-.4 5.2-1-6.6-2.4C11 8.2 11.6 6.6 12 3z" fill="currentColor"/></svg>';
  }
  function row(tier, index) {
    return '<button class="nwsb-sub-tier" type="button" data-tier="' + tier.name + '" onclick="if(window.SS)SS.open(\'subscription\')">' +
      '<span class="nwsb-sub-icon-glass">' + sparkle() + '</span>' +
      '<span class="nwsb-sub-tier-pill"><span class="nwsb-sub-tier-copy"><strong style="color:' + tier.tone + '">' + tier.name + '</strong><small>' + tier.detail + '</small></span><span class="nwsb-sub-enter-glass">' + arrow() + '</span></span>' +
      (index < tiers.length - 1 ? '<span class="nwsb-sub-hairline" aria-hidden="true"></span>' : '') +
      '</button>';
  }
  function render(block) {
    if (!block || block.dataset.nwsbSubscriptionReady) return;
    block.dataset.nwsbSubscriptionReady = 'true';
    block.style.display = '';
    block.innerHTML = '<div class="nwsb-subscription-page"><div class="nwsb-sub-tv-frame"><div class="nwsb-sub-tv-screen">' +
      '<video class="nwsb-sub-tv-video" data-nwsb-auto muted loop playsinline autoplay preload="auto" poster="assets/video/subscription-promo-poster.webp" src="assets/video/subscription-promo.mp4"></video>' +
      '<div class="nwsb-sub-tv-shade" aria-hidden="true"></div><div class="nwsb-sub-tv-content">' +
      '<button class="nwsb-sub-upgrade-banner" type="button" onclick="if(window.SS)SS.open(\'subscription\')"><span class="nwsb-sub-banner-copy"><strong>Subscription</strong><strong>Join NowssB</strong><small>Try it free for 30 days · Choose your frequency</small></span><span>' + arrow() + '</span></button>' +
      '<div class="nwsb-sub-tier-list" aria-label="Subscription tiers">' + tiers.map(row).join('') + '</div>' +
      '<div class="nwsb-sub-trial-copy"><strong>Join NowssB</strong><span>Get your subscription today</span></div>' +
      '<button class="nwsb-subscribe-cta" type="button" onclick="if(window.SS)SS.open(\'subscription\')"><span>Get Subscription Today</span><span>' + arrow() + '</span></button>' +
      '</div></div></div></div>';
    var video = block.querySelector('.nwsb-sub-tv-video');
    if (video) {
      video.muted = true; video.defaultMuted = true; video.loop = true; video.playsInline = true;
      var play = function () { var promise = video.play(); if (promise && promise.catch) promise.catch(function () {}); };
      video.addEventListener('canplay', play, { once: true });
      play();
    }
  }
  function init() {
    document.querySelectorAll('.nsub-blk').forEach(render);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
  window.addEventListener('nwsb:home-ready', init);
})();
