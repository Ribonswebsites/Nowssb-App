/*
 * NowssB Your essentials — supplied timeline structure.
 * The markup is shared; the final stylesheet supplies the neumorphic Normal
 * surface and glassmorphic Fashion surface.
 */
(function () {
  'use strict';

  var ITEMS = [
    { id: 'sound-library', icon: 'sound', title: 'Sound Library', sub: 'Root frequencies for focused listening', meta: 'Explore', action: 'sound-library' },
    { id: 'health-journey', icon: 'lock', title: 'Healing Journey', sub: 'Choose a body, organ or mind path', meta: 'Explore', action: 'health-journey' },
    { id: 'word-science', icon: 'science', title: 'Word Science', sub: 'Discover the origin behind any word', meta: 'Explore', action: 'word-science' },
    { id: 'my-progress', icon: 'science', title: 'My Progress', sub: 'See your practice and sound score', meta: 'Open', action: 'my-progress' },
    { id: 'routines', icon: 'sound', title: 'Build your routine', sub: 'Set a daily practice system', meta: 'Open', action: 'routines' },
    { id: 'social', icon: 'lock', title: 'Connect', sub: 'People, chat and the NowssB feed', meta: 'Open', action: 'social' },
    { id: 'fashion-plus', icon: 'science', title: 'Fashion Plus', sub: 'Explore the moving visual practice', meta: 'Open', action: 'fashion-plus' }
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
  function isExpanded(root) { return root.getAttribute('data-essential-expanded') === 'true'; }
  function action(actionName) {
    if (actionName === 'practice' && typeof openPracticeIntro === 'function') return openPracticeIntro();
    if (typeof openSub === 'function') return openSub(actionName);
  }
  function itemPill(item) {
    return '<div class="nwsb-essential-row-wrap"><div class="nwsb-essential-track"><span class="nwsb-essential-dot" aria-hidden="true"></span><span class="nwsb-essential-connector" aria-hidden="true"></span></div>' +
      '<button type="button" class="nwsb-essential-pill" data-essential-action="' + esc(item.action) + '">' +
        '<span class="nwsb-essential-icon-circle">' + icon(item.icon) + '</span>' +
        '<span class="nwsb-essential-pill-text"><strong>' + esc(item.title) + '</strong><small>' + esc(item.sub) + '</small></span>' +
        '<span class="nwsb-essential-meta">' + esc(item.meta) + '</span><span class="nwsb-essential-arrow" aria-hidden="true">→</span>' +
      '</button></div>';
  }
  function render(root) {
    var list = root.querySelector('[data-essential-list]');
    if (!list) return;
    list.innerHTML = (isExpanded(root) ? ITEMS : ITEMS.slice(0, 3)).map(itemPill).join('');
    var expand = root.querySelector('[data-essential-expand]');
    if (expand) {
      expand.hidden = ITEMS.length <= 3;
      expand.setAttribute('aria-expanded', isExpanded(root) ? 'true' : 'false');
      expand.querySelector('span').textContent = isExpanded(root) ? 'Show less' : 'See more';
      expand.querySelector('b').textContent = isExpanded(root) ? '⌃' : '⌄';
    }
    root.querySelectorAll('[data-essential-action]').forEach(function (el) {
      el.addEventListener('click', function () { action(el.getAttribute('data-essential-action')); });
    });
  }
  function html(mode) {
    var fashion = mode === 'fashion';
    return '<section class="nwsb-essentials nwsb-essentials-supplied nwsb-essentials-' + (fashion ? 'fashion' : 'normal') + '" data-essentials-mode="' + mode + '" data-essential-expanded="false">' +
      '<div class="nwsb-essentials-body">' +
        '<div class="nwsb-essentials-heading"><span class="nwsb-essentials-heading-icon">' + icon('sliders') + '</span><div><div class="nwsb-essentials-eyebrow">Your daily practice</div><h2>Your essentials</h2></div></div>' +
        '<div class="nwsb-essentials-timeline">' +
          '<div class="nwsb-essential-row-wrap nwsb-essential-featured-wrap"><div class="nwsb-essential-track"><span class="nwsb-essential-dot active" aria-hidden="true"></span><span class="nwsb-essential-connector" aria-hidden="true"></span></div>' +
            '<button type="button" class="nwsb-essential-featured" data-essential-action="practice"><span class="nwsb-essential-badge">NOWSSB · 543</span><span class="nwsb-essential-featured-icon">' + icon('sound') + '</span><strong>Today’s word ritual</strong><small>Today’s pronunciation</small><em>3–20 min</em><svg class="nwsb-essential-face" viewBox="0 0 100 100" aria-hidden="true"><path d="M25 55 Q35 65 45 55M55 55 Q65 65 75 55" stroke="currentColor" stroke-width="5" fill="none" stroke-linecap="round"/></svg></button>' +
          '</div>' +
          '<div data-essential-list></div>' +
        '</div>' +
        '<button type="button" class="nwsb-essential-expand" data-essential-expand aria-expanded="false"><span>See more</span><b>⌄</b></button>' +
      '</div>' +
    '</section>';
  }
  function bind(root) {
    if (!root || root.__essentialsSuppliedBound) return;
    root.__essentialsSuppliedBound = true;
    root.querySelector('[data-essential-expand]').addEventListener('click', function () {
      root.setAttribute('data-essential-expanded', isExpanded(root) ? 'false' : 'true');
      render(root);
    });
    root.querySelector('[data-essential-action="practice"]').addEventListener('click', function () { action('practice'); });
    render(root);
  }
  function mount(mode, selector, afterSelector) {
    var host = document.querySelector(selector);
    if (!host || host.querySelector(':scope > .nwsb-essentials')) return;
    var wrap = document.createElement('div');
    wrap.innerHTML = html(mode);
    var node = wrap.firstElementChild;
    var after = host.querySelector(afterSelector);
    if (after && after.parentNode === host) after.insertAdjacentElement('afterend', node); else host.appendChild(node);
    bind(node);
  }
  function boot() {
    mount('normal', '#home-nm .nmh-wrap', '.nwsb-daydash');
    mount('fashion', '#home .home-body', '.nwsb-daydash');
  }
  window.NWSBEssentials = { boot: boot };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
})();
