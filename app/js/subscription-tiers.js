/* Shared subscription composition for the website and Capacitor WebView. */
(function () {
  'use strict';

  var tiers = [
    { name: 'Free', detail: 'NowssB Edition', tone: '#e8eaf0', mark: '♔' },
    { name: 'Resonance', detail: '$4.99 / month', tone: '#c8e8f5', mark: '◉' },
    { name: 'Frequency', detail: '$9.99 / month', tone: '#e8d5a3', mark: '◌' },
    { name: 'Frequency X', detail: '$19.99 / month', tone: '#f0f0f0', mark: '✦' }
  ];

  function arrow() {
    return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h13M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  }

  function row(tier, index) {
    return '<button class="nwsb-sub-tier" type="button" data-tier="' + tier.name + '" onclick="if(window.SS)SS.open(\'subscription\')">' +
      '<span class="nwsb-sub-icon-glass"><span class="nwsb-sub-icon" style="color:' + tier.tone + '">' + tier.mark + '</span></span>' +
      '<span class="nwsb-sub-tier-divider" aria-hidden="true"></span>' +
      '<span class="nwsb-sub-tier-pill"><span class="nwsb-sub-tier-copy"><strong style="color:' + tier.tone + '">' + tier.name + '</strong><small>' + tier.detail + '</small></span><span class="nwsb-sub-enter-glass">' + arrow() + '</span></span>' +
      (index < tiers.length - 1 ? '<span class="nwsb-sub-hairline" aria-hidden="true"></span>' : '') +
      '</button>';
  }

  function render(block) {
    if (!block || block.dataset.nwsbSubscriptionReady) return;
    block.dataset.nwsbSubscriptionReady = 'true';
    block.style.display = '';
    block.innerHTML = '<div class="nwsb-subscription-page">' +
      '<button class="nwsb-sub-upgrade-banner" type="button" onclick="if(window.SS)SS.open(\'subscription\')"><span>SUBSCRIPTION TIER UPGRADE</span><span>' + arrow() + '</span></button>' +
      '<div class="nwsb-sub-title-wrap"><div class="nwsb-sub-eyebrow">The full library · choose your frequency</div><h3>Find your resonance</h3><p>Unlock a deeper practice, one tier at a time.</p></div>' +
      '<div class="nwsb-sub-tier-list" aria-label="Subscription tiers">' + tiers.map(row).join('') + '</div>' +
      '<button class="nwsb-subscribe-cta" type="button" onclick="if(window.SS)SS.open(\'subscription\')"><span>Subscribe Today</span><span>' + arrow() + '</span></button>' +
      '</div>';
  }

  function init() {
    document.querySelectorAll('.nsub-blk').forEach(render);
    var edition = document.getElementById('sub-promo-card');
    if (edition) render(edition);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
  window.addEventListener('nwsb:home-ready', init);
})();
