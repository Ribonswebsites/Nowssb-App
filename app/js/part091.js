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
    { id: 'health-journey', icon: 'lock', title: 'Healing Journey', sub: 'Choose a body, organ or mind path', meta: 'Explore', action: 'health-journey', favorite: true },
    { id: 'word-science', icon: 'science', title: 'Word Science', sub: 'Discover the origin behind any word', meta: 'Explore', action: 'word-science', favorite: false },
    { id: 'my-progress', icon: 'science', title: 'My Progress', sub: 'See your practice and sound score', meta: 'Open', action: 'my-progress', favorite: true },
    { id: 'routines', icon: 'sound', title: 'Build your routine', sub: 'Set a daily practice system', meta: 'Open', action: 'routines', favorite: false },
    { id: 'social', icon: 'lock', title: 'Connect', sub: 'People, chat and the NowssB feed', meta: 'Open', action: 'social', favorite: false },
    { id: 'fashion-plus', icon: 'science', title: 'Fashion Plus', sub: 'Explore the moving visual practice', meta: 'Open', action: 'fashion-plus', favorite: false }
  ];
  var HELP = [
    { icon: 'sound', title: 'Voice scoring', sub: 'Practice and see your sound score', action: 'practice', art: 'violet' },
    { icon: 'science', title: 'Word Science', sub: 'Meanings, origins and sound', action: 'word-science', art: 'pink' },
    { icon: 'sound', title: 'Sleep Music', sub: 'Settle into a quieter frequency', action: 'sound-library', art: 'blue' },
    { icon: 'science', title: 'Healing Journey', sub: 'Choose a body, organ or mind path', action: 'health-journey', art: 'mint' },
    { icon: 'sound', title: 'Daily Routines', sub: 'Five slots to keep your practice moving', action: 'routines', art: 'amber' },
    { icon: 'lock', title: 'Connect', sub: 'People, chat and the NowssB feed', action: 'social', art: 'coral' },
    { icon: 'science', title: 'The Store', sub: 'Words, meanings and sound tools', action: 'nowssb-store', art: 'cyan' },
    { icon: 'science', title: 'Fashion Plus', sub: 'A moving practice for the senses', action: 'fashion-plus', art: 'violet' }
  ];

  function esc(value) { return String(value == null ? '' : value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;'); }
  function icon(name) {
    var icons = {
      lock: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><rect x="5" y="10" width="14" height="10" rx="2" fill="currentColor"/><path d="M8 10V7a4 4 0 0 1 8 0v3" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><circle cx="12" cy="15" r="1.1" fill="#fff"/></svg>',
      sound: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M4 14h3l4 4V6L7 10H4v4ZM15 9.5a4 4 0 0 1 0 5M18 7a7.5 7.5 0 0 1 0 10" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>',
      science: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="12" r="8.2" stroke="currentColor" stroke-width="1.7"/><path d="M9 9h6M10 12h4M9 15h6" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>',
      sliders: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M4 7h8M16 7h4M4 17h4M12 17h8" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><circle cx="14" cy="7" r="2" stroke="currentColor" stroke-width="1.7"/><circle cx="10" cy="17" r="2" stroke="currentColor" stroke-width="1.7"/></svg>'
    };
    return icons[name] || icons.sound;
  }
  function filterValue(root) { return root.getAttribute('data-essential-filter') || 'recent'; }
  function isExpanded(root) { return root.getAttribute('data-essential-expanded') === 'true'; }
  function filteredItems(filter) { return filter === 'favorite' ? ITEMS.filter(function (item) { return item.favorite; }) : ITEMS; }
  function visibleRows(root, items) { return isExpanded(root) ? items : items.slice(0, 3); }
  function row(item) {
    if (item.featured) return '<button type="button" class="nwsb-essential-featured-card" data-essential-action="' + esc(item.action) + '"><span class="nwsb-essential-badge">NOWSSB · 543</span><span class="nwsb-essential-featured-icon">' + icon('sound') + '</span><strong>' + esc(item.title) + '</strong><small>' + esc(item.sub) + '</small><em>' + esc(item.meta) + '</em><span class="nwsb-essential-featured-art" aria-hidden="true"></span></button>';
    return '<button type="button" class="nwsb-essential-row" data-essential-action="' + esc(item.action) + '"><span class="nwsb-essential-row-icon">' + icon(item.icon) + '</span><span class="nwsb-essential-row-copy"><strong>' + esc(item.title) + '</strong><small>' + esc(item.sub) + '</small></span><span class="nwsb-essential-meta">' + esc(item.meta) + '</span><span class="nwsb-essential-arrow" aria-hidden="true">›</span></button>';
  }
  function helpCard(item) { return '<button type="button" class="nwsb-help-card nwsb-help-' + item.art + '" data-essential-action="' + esc(item.action) + '"><span class="nwsb-help-art">' + icon(item.icon) + '</span><span class="nwsb-help-copy"><strong>' + esc(item.title) + '</strong><small>' + esc(item.sub) + '</small></span></button>'; }
  function render(root, filter) {
    var list = root.querySelector('[data-essential-list]'); if (!list) return;
    root.setAttribute('data-essential-filter', filter);
    root.querySelectorAll('[data-essential-filter-button]').forEach(function (button) { button.classList.toggle('is-active', button.getAttribute('data-essential-filter-button') === filter); });
    var items = filteredItems(filter);
    list.innerHTML = visibleRows(root, items).map(row).join('');
    var expand = root.querySelector('[data-essential-expand]');
    if (expand) {
      var needsExpand = items.length > 3;
      expand.hidden = !needsExpand;
      expand.setAttribute('aria-expanded', isExpanded(root) ? 'true' : 'false');
      expand.querySelector('span').textContent = isExpanded(root) ? 'Show fewer' : 'See all essentials';
      expand.querySelector('b').textContent = isExpanded(root) ? '⌃' : '⌄';
    }
    bindActions(root);
  }
  function html(mode) {
    var fashion = mode === 'fashion';
    return '<section class="nwsb-essentials nwsb-essentials-reference nwsb-essentials-' + (fashion ? 'fashion' : 'normal') + '" data-essentials-mode="' + mode + '" data-essential-filter="recent">' +
      '<div class="nwsb-essentials-body">' +
        '<div class="nwsb-essentials-heading"><span class="nwsb-essentials-heading-icon" aria-hidden="true">' + icon('sliders') + '</span><div><div class="nwsb-essentials-eyebrow">Your daily practice</div><h2>Your essentials</h2></div></div>' +
        '<div class="nwsb-essentials-shell"><div class="nwsb-essential-list" data-essential-list></div><button type="button" class="nwsb-essential-expand" data-essential-expand aria-expanded="false"><span>See all essentials</span><b>⌄</b></button></div>' +
        '<button type="button" class="nwsb-essentials-guide" data-essential-guide><span class="nwsb-essentials-guide-icon">' + icon('sliders') + '</span><span class="nwsb-essentials-guide-copy"><strong>Find Your Way Around</strong><small>Every screen in the app, and what each one is for</small></span><span class="nwsb-essentials-guide-arrow">›</span></button>' +
        '<div class="nwsb-help-heading"><h3>What’s helping others</h3><button type="button" data-essential-help-view aria-label="Open helpful NowssB features">›</button></div>' +
        '<div class="nwsb-help-rail">' + HELP.map(helpCard).join('') + '</div>' +
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
    root.querySelectorAll('[data-essential-filter-button]').forEach(function (button) { button.addEventListener('click', function () { root.setAttribute('data-essential-expanded', 'false'); render(root, button.getAttribute('data-essential-filter-button')); }); });
    root.querySelectorAll('[data-essential-expand]').forEach(function (button) { button.addEventListener('click', function () { root.setAttribute('data-essential-expanded', isExpanded(root) ? 'false' : 'true'); render(root, filterValue(root)); }); });
    root.querySelectorAll('[data-essential-help-view]').forEach(function (button) { button.addEventListener('click', function () { run('word-science'); }); });
    root.querySelectorAll('[data-essential-guide]').forEach(function (button) { button.addEventListener('click', function () { run('my-progress'); }); });
    root.setAttribute('data-essential-expanded', 'false');
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
