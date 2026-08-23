/*
 * NowssB Your essentials — faithful reference layout.
 * The visual hierarchy follows the supplied screen; labels and destinations are
 * NowssB features, not generic placeholder content.
 */
(function () {
  'use strict';

  var ITEMS = [
    { id: 'practice', icon: 'lock', title: 'Today’s word ritual', sub: 'Today’s pronunciation', meta: '3–20 min', action: 'practice', featured: true, favorite: true },
    { id: 'sound-library', icon: 'sound', title: 'Sound Library', sub: 'Root frequencies for focused listening', meta: 'Explore', action: 'sound-library', favorite: true },
    { id: 'word-science', icon: 'lock', title: 'Word Science', sub: 'Discover the origin behind any word', meta: 'Explore', action: 'word-science', favorite: false },
    { id: 'health-journey', icon: 'lock', title: 'Healing Journey', sub: 'Choose a body, organ or mind path', meta: 'Explore', action: 'health-journey', favorite: true }
  ];
  var HELP = [
    { icon: 'sound', title: 'Voice scoring', sub: 'Practice and see your sound score', action: 'practice', art: 'violet' },
    { icon: 'science', title: 'Word Science', sub: 'Meanings, origins and sound', action: 'word-science', art: 'pink' }
  ];

  function esc(value) { return String(value == null ? '' : value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;'); }
  function icon(name) {
    var icons = {
      lock: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><rect x="5" y="10" width="14" height="10" rx="2" fill="currentColor"/><path d="M8 10V7a4 4 0 0 1 8 0v3" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><circle cx="12" cy="15" r="1.1" fill="#fff"/></svg>',
      sound: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M4 14h3l4 4V6L7 10H4v4ZM15 9.5a4 4 0 0 1 0 5M18 7a7.5 7.5 0 0 1 0 10" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>',
      science: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="12" r="8.2" stroke="currentColor" stroke-width="1.7"/><path d="M9 9h6M10 12h4M9 15h6" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>'
    };
    return icons[name] || icons.sound;
  }
  function filterValue(root) { return root.getAttribute('data-essential-filter') || 'recent'; }
  function filteredItems(filter) { return filter === 'favorite' ? ITEMS.filter(function (item) { return item.favorite; }) : ITEMS; }
  function row(item) {
    if (item.featured) return '<button type="button" class="nwsb-essential-featured-card" data-essential-action="' + esc(item.action) + '"><span class="nwsb-essential-badge">NOWSSB · 543</span><span class="nwsb-essential-featured-icon">' + icon('sound') + '</span><strong>' + esc(item.title) + '</strong><small>' + esc(item.sub) + '</small><em>' + esc(item.meta) + '</em><span class="nwsb-essential-featured-art" aria-hidden="true"></span></button>';
    return '<button type="button" class="nwsb-essential-row" data-essential-action="' + esc(item.action) + '"><span class="nwsb-essential-row-icon">' + icon(item.icon) + '</span><span class="nwsb-essential-row-copy"><strong>' + esc(item.title) + '</strong><small>' + esc(item.sub) + '</small></span><span class="nwsb-essential-meta">' + esc(item.meta) + '</span><span class="nwsb-essential-arrow" aria-hidden="true">›</span></button>';
  }
  function helpCard(item) { return '<button type="button" class="nwsb-help-card nwsb-help-' + item.art + '" data-essential-action="' + esc(item.action) + '"><span class="nwsb-help-art">' + icon(item.icon) + '</span><span class="nwsb-help-copy"><strong>' + esc(item.title) + '</strong><small>' + esc(item.sub) + '</small></span></button>'; }
  function render(root, filter) {
    var list = root.querySelector('[data-essential-list]'); if (!list) return;
    root.setAttribute('data-essential-filter', filter);
    root.querySelectorAll('[data-essential-filter-button]').forEach(function (button) { button.classList.toggle('is-active', button.getAttribute('data-essential-filter-button') === filter); });
    list.innerHTML = filteredItems(filter).map(row).join('');
    bindActions(root);
  }
  function html(mode) {
    var fashion = mode === 'fashion';
    return '<section class="nwsb-essentials nwsb-essentials-reference nwsb-essentials-' + (fashion ? 'fashion' : 'normal') + '" data-essentials-mode="' + mode + '" data-essential-filter="recent">' +
      '<div class="nwsb-essentials-wave" aria-hidden="true"></div>' +
      '<div class="nwsb-essentials-body">' +
        '<div class="nwsb-essential-tabs"><button type="button" class="nwsb-essential-tab is-active" data-essential-filter-button="recent">' + icon('sound') + '<span>Recents</span></button><button type="button" class="nwsb-essential-tab" data-essential-filter-button="favorite">' + icon('lock') + '<span>Favorites</span></button></div>' +
        '<div class="nwsb-essentials-heading"><div><h2>Your essentials</h2></div></div>' +
        '<div class="nwsb-essentials-shell"><div class="nwsb-essential-list" data-essential-list></div></div>' +
        '<div class="nwsb-help-heading"><h3>What’s helping others</h3><button type="button" data-essential-help-view aria-label="Open helpful NowssB features">›</button></div>' +
        '<div class="nwsb-help-grid">' + HELP.map(helpCard).join('') + '</div>' +
      '</div>' +
    '</section>';
  }
  function run(action) { if (action === 'practice' && typeof openPracticeIntro === 'function') return openPracticeIntro(); if (typeof openSub === 'function') return openSub(action); }
  function bindActions(root) {
    root.querySelectorAll('[data-essential-action]').forEach(function (el) { if (el.__bound) return; el.__bound = true; el.addEventListener('click', function () { run(el.getAttribute('data-essential-action')); }); });
  }
  function bind(root) {
    if (!root || root.__essentialsBound) return;
    root.__essentialsBound = true;
    root.querySelectorAll('[data-essential-filter-button]').forEach(function (button) { button.addEventListener('click', function () { render(root, button.getAttribute('data-essential-filter-button')); }); });
    root.querySelectorAll('[data-essential-help-view]').forEach(function (button) { button.addEventListener('click', function () { run('word-science'); }); });
    render(root, 'recent');
  }
  function mount(mode, selector, afterSelector) {
    var host = document.querySelector(selector); if (!host || host.querySelector(':scope > .nwsb-essentials')) return;
    var wrap = document.createElement('div'); wrap.innerHTML = html(mode); var node = wrap.firstElementChild; var after = host.querySelector(afterSelector);
    if (after && after.parentNode === host) after.insertAdjacentElement('afterend', node); else host.appendChild(node);
    bind(node);
  }
  function boot() { mount('normal', '#home-nm .nmh-wrap', '.nwsb-daydash'); mount('fashion', '#home .home-body', '.nwsb-daydash'); }
  window.NWSBEssentials = { boot: boot };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
})();
