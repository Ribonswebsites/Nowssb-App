/*
 * NowssB essentials — four real paths in one compact home wrapper.
 * The rows deliberately use existing app destinations; they are not demos.
 */
(function () {
  'use strict';

  var ITEMS = [
    { id: 'practice', icon: 'mic', title: 'Today’s word ritual', sub: 'Listen, speak and score your next word', meta: '3–20 min', action: 'practice', featured: true },
    { id: 'sound-library', icon: 'sound', title: 'Sound Library', sub: 'Root frequencies for focused listening', meta: 'Explore', action: 'sound-library' },
    { id: 'word-science', icon: 'science', title: 'Word Science', sub: 'Discover what a word truly means', meta: 'Explore', action: 'word-science' },
    { id: 'health-journey', icon: 'path', title: 'Healing Journey', sub: 'Choose a body, organ or mind path', meta: 'Explore', action: 'health-journey' }
  ];

  function esc(value) {
    return String(value == null ? '' : value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
  function icon(name) {
    var icons = {
      mic: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><rect x="8" y="3" width="8" height="12" rx="4" stroke="currentColor" stroke-width="1.7"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3M8.5 21h7" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>',
      sound: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M4 14h3l4 4V6L7 10H4v4ZM15 9.5a4 4 0 0 1 0 5M18 7a7.5 7.5 0 0 1 0 10" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>',
      science: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="12" r="8.2" stroke="currentColor" stroke-width="1.7"/><path d="M9 9h6M10 12h4M9 15h6" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>',
      path: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="6" cy="18" r="2" stroke="currentColor" stroke-width="1.6"/><circle cx="18" cy="6" r="2" stroke="currentColor" stroke-width="1.6"/><path d="M8 18c7 0 1-12 8-12" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>'
    };
    return icons[name] || icons.path;
  }
  function html(mode) {
    var fashion = mode === 'fashion';
    var itemHtml = ITEMS.map(function (item) {
      return '<button type="button" class="nwsb-essential-row' + (item.featured ? ' nwsb-essential-featured' : '') + '" data-essential-action="' + esc(item.action) + '" data-essential-id="' + esc(item.id) + '">' +
        '<span class="nwsb-essential-rail" aria-hidden="true"><span class="nwsb-essential-dot"></span></span>' +
        '<span class="nwsb-essential-icon" aria-hidden="true">' + icon(item.icon) + '</span>' +
        '<span class="nwsb-essential-copy"><strong>' + esc(item.title) + '</strong><small>' + esc(item.sub) + '</small></span>' +
        '<span class="nwsb-essential-meta">' + esc(item.meta) + '</span><span class="nwsb-essential-arrow" aria-hidden="true">→</span>' +
      '</button>';
    }).join('');
    return '<section class="nwsb-essentials nwsb-essentials-' + (fashion ? 'fashion' : 'normal') + '" data-essentials-mode="' + mode + '">' +
      '<div class="nwsb-essentials-heading"><div><div class="nwsb-dashboard-eyebrow">Your daily paths</div><h2>Your essentials</h2></div><span class="nwsb-essentials-mark">NOWSSB</span></div>' +
      '<div class="nwsb-essentials-shell"><div class="nwsb-essential-list" data-essential-list>' + itemHtml + '</div></div>' +
    '</section>';
  }
  function run(action) {
    if (action === 'practice' && typeof openPracticeIntro === 'function') return openPracticeIntro();
    if (typeof openSub === 'function') return openSub(action);
  }
  function bind(root) {
    if (!root || root.__essentialsBound) return;
    root.__essentialsBound = true;
    root.querySelectorAll('[data-essential-action]').forEach(function (el) { el.addEventListener('click', function () { run(el.getAttribute('data-essential-action')); }); });
  }
  function mount(mode, selector, afterSelector) {
    var host = document.querySelector(selector);
    if (!host || host.querySelector(':scope > .nwsb-essentials')) return;
    var wrap = document.createElement('div'); wrap.innerHTML = html(mode);
    var node = wrap.firstElementChild; var after = host.querySelector(afterSelector);
    if (after && after.parentNode === host) after.insertAdjacentElement('afterend', node); else host.appendChild(node);
    bind(node);
  }
  function boot() { mount('normal', '#home-nm .nmh-wrap', '.nwsb-daydash'); mount('fashion', '#home .home-body', '.nwsb-daydash'); }
  window.NWSBEssentials = { boot: boot };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
})();
