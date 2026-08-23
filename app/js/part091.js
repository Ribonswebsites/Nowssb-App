/*
 * NowssB essentials — the compact daily paths shown below the home dashboard.
 * Every row opens an existing app destination; there are no simulated actions.
 */
(function () {
  'use strict';

  var ITEMS = [
    { id: 'practice', icon: '◉', title: 'Today’s word ritual', sub: 'Listen, speak and score your next word', meta: '3–20 min', action: 'practice', featured: true },
    { id: 'sound-library', icon: '◌', title: 'Sound Library', sub: 'Root frequencies for focused listening', meta: 'Explore', action: 'sound-library' },
    { id: 'word-science', icon: '◈', title: 'Word Science', sub: 'Discover what a word truly means', meta: 'Explore', action: 'word-science' },
    { id: 'health-journey', icon: '✦', title: 'Healing Journey', sub: 'Choose a body, organ or mind path', meta: 'Explore', action: 'health-journey' }
  ];

  function esc(value) {
    return String(value == null ? '' : value)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  function filteredItems(filter) {
    if (filter !== 'favorites') return ITEMS;
    var data = window._userDataCache || {};
    var favorites = data.favourites || data.favorites || [];
    var names = Array.isArray(favorites) ? favorites.map(String) : Object.keys(favorites || {});
    var found = ITEMS.filter(function (item) { return names.some(function (name) { return name.toLowerCase().indexOf(item.title.toLowerCase()) >= 0; }); });
    return found.length ? found : ITEMS;
  }

  function html(mode) {
    var fashion = mode === 'fashion';
    var now = new Date();
    var hour = now.getHours();
    var slot = hour >= 5 && hour < 12 ? 'Morning' : hour < 17 ? 'Afternoon' : hour < 21 ? 'Evening' : 'Night';
    var itemHtml = ITEMS.map(function (item, index) {
      return '<button type="button" class="nwsb-essential-row' + (item.featured ? ' nwsb-essential-featured' : '') + '" data-essential-action="' + esc(item.action) + '" data-essential-id="' + esc(item.id) + '">' +
        '<span class="nwsb-essential-rail" aria-hidden="true"><span class="nwsb-essential-dot"></span></span>' +
        '<span class="nwsb-essential-icon" aria-hidden="true">' + esc(item.icon) + '</span>' +
        '<span class="nwsb-essential-copy"><strong>' + esc(item.title) + '</strong><small>' + esc(item.sub) + '</small></span>' +
        '<span class="nwsb-essential-meta">' + esc(item.featured ? slot + ' · ' + item.meta : item.meta) + '</span>' +
        '<span class="nwsb-essential-arrow" aria-hidden="true">›</span>' +
      '</button>';
    }).join('');
    return '<section class="nwsb-essentials nwsb-essentials-' + (fashion ? 'fashion' : 'normal') + '" data-essentials-mode="' + mode + '">' +
      '<div class="nwsb-essential-tabs" role="tablist" aria-label="Essential filters">' +
        '<button type="button" class="nwsb-essential-tab is-active" data-essential-filter="recent" role="tab" aria-selected="true">◷&nbsp; Recents</button>' +
        '<button type="button" class="nwsb-essential-tab" data-essential-filter="favorites" role="tab" aria-selected="false">♥&nbsp; Favorites</button>' +
      '</div>' +
      '<div class="nwsb-essentials-heading"><div><div class="nwsb-dashboard-eyebrow">Your daily paths</div><h2>Your essentials</h2></div><span class="nwsb-essentials-mark">NOWSSB</span></div>' +
      '<div class="nwsb-essential-list" data-essential-list>' + itemHtml + '</div>' +
      '<div class="nwsb-essential-help" data-essential-help hidden>Your saved paths will appear here as you practice.</div>' +
    '</section>';
  }

  function run(action) {
    if (action === 'practice' && typeof openPracticeIntro === 'function') return openPracticeIntro();
    if (typeof openSub === 'function') return openSub(action);
  }

  function bind(root) {
    if (!root || root.__essentialsBound) return;
    root.__essentialsBound = true;
    root.querySelectorAll('[data-essential-action]').forEach(function (el) {
      el.addEventListener('click', function () { run(el.getAttribute('data-essential-action')); });
    });
    root.querySelectorAll('[data-essential-filter]').forEach(function (tab) {
      tab.addEventListener('click', function () {
        var filter = tab.getAttribute('data-essential-filter');
        root.querySelectorAll('[data-essential-filter]').forEach(function (other) {
          var active = other === tab;
          other.classList.toggle('is-active', active);
          other.setAttribute('aria-selected', active ? 'true' : 'false');
        });
        var list = root.querySelector('[data-essential-list]');
        var help = root.querySelector('[data-essential-help]');
        if (!list) return;
        var rows = filteredItems(filter);
        list.querySelectorAll('[data-essential-id]').forEach(function (row) {
          row.hidden = !rows.some(function (item) { return item.id === row.getAttribute('data-essential-id'); });
        });
        if (help) help.hidden = filter !== 'favorites' || rows.length > 0;
      });
    });
  }

  function mount(mode, selector, afterSelector) {
    var host = document.querySelector(selector);
    if (!host || host.querySelector(':scope > .nwsb-essentials')) return;
    var wrap = document.createElement('div');
    wrap.innerHTML = html(mode);
    var node = wrap.firstElementChild;
    var after = host.querySelector(afterSelector);
    if (after && after.parentNode === host) after.insertAdjacentElement('afterend', node);
    else host.appendChild(node);
    bind(node);
  }

  function boot() {
    mount('normal', '#home-nm .nmh-wrap', '.nwsb-daydash');
    mount('fashion', '#home .home-body', '.nwsb-daydash');
  }

  window.NWSBEssentials = { boot: boot };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
