/*
 * NowssB time-aware home dashboard.
 * Normal and Fashion use the same content model; CSS supplies their distinct
 * white neumorphic and dark glassmorphism surfaces.
 */
(function () {
  'use strict';

  var LOCAL_VIDEO_BASE = './assets/video/';
  var R2_BASE = (window.NWSB_R2_BASE || 'https://nowssb-api.ribonpatil2.workers.dev/media').replace(/\/$/, '');
  var SLOT = {
    morning:   { start: 5,  end: 12, title: 'Morning Resonance', sub: 'Begin with a clear tone', file: 'time-morning', eyebrow: 'Today’s focus' },
    afternoon: { start: 12, end: 17, title: 'Afternoon Reset', sub: 'Return to the sound in the middle of the day', file: 'time-afternoon', eyebrow: 'Today’s focus' },
    evening:   { start: 17, end: 21, title: 'Evening Release', sub: 'Let the day settle through sound', file: 'time-evening', eyebrow: 'Today’s focus' },
    night:     { start: 21, end: 29, title: 'Night Restoration', sub: 'Close the day with a quieter frequency', file: 'time-night', eyebrow: 'Today’s focus' }
  };

  function slotFor(date) {
    var hour = (date || new Date()).getHours();
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
  function srcFor(file, ext) { return R2_BASE + '/home-banners/' + file + '.' + ext; }
  function localSrcFor(file, ext) { return LOCAL_VIDEO_BASE + file + '.' + ext; }
  function esc(value) {
    return String(value == null ? '' : value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
  function userData() { return window._userDataCache || {}; }
  function progress() {
    var d = userData();
    var sessions = d.sessions && typeof d.sessions === 'object' ? Object.keys(d.sessions) : [];
    var words = {};
    sessions.forEach(function (key) {
      var word = String(key).split('_').slice(1).join('_');
      if (word) words[word.toUpperCase()] = true;
    });
    var streak = Number(d.currentStreak || d.streakCount || d.streak || 0);
    var total = Number(d.totalSessions || d.sessionCount || sessions.length || 0);
    var goal = Number(d.goalProgress || d.weeklyGoalProgress || Math.min(100, total * 10));
    return { streak: isFinite(streak) ? streak : 0, sessions: isFinite(total) ? total : 0, words: Object.keys(words).length, goal: isFinite(goal) ? Math.max(0, Math.min(100, goal)) : 0 };
  }
  function nextPractice() {
    var routines = Array.isArray(window._routines) ? window._routines : [];
    var active = routines.find(function (r) { return r && r.enabled !== false && (r.word || r.title || r.name); });
    if (!active) return { title: 'Open today’s practice', sub: 'Choose a word and begin your next sound ritual', action: 'practice' };
    var label = active.word || active.title || active.name;
    return { title: String(label), sub: active.time || active.duration || 'Next word in your practice routine', action: 'practice' };
  }
  function upNextItems() {
    var first = nextPractice();
    return [first, { title: first.action === 'practice' ? 'Build your routine' : 'Start your first word', sub: first.action === 'practice' ? 'Set a daily practice system' : 'Open the pronunciation player', action: first.action === 'practice' ? 'routines' : 'practice' }];
  }
  function icon(name) {
    var icons = {
      check: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M5 12.5l4.2 4.2L19 7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>',
      timer: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="13" r="7.7" stroke="currentColor" stroke-width="1.7"/><path d="M12 9v4l2.5 1.5M9 3h6M12 3v2" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>',
      fire: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M12.1 21c4.2 0 7-2.7 7-6.6 0-2.8-1.6-5.5-4.6-8.3.2 2-1 3.3-2.1 4-1-2.4-2.7-4-4.4-5.1.2 3.1-2.9 5.2-2.9 9.1 0 4.1 2.8 6.9 7 6.9Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>',
      target: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="12" r="8.5" stroke="currentColor" stroke-width="1.6"/><circle cx="12" cy="12" r="4.2" stroke="currentColor" stroke-width="1.6"/><circle cx="12" cy="12" r="1.4" fill="currentColor"/></svg>',
      calendar: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><rect x="4" y="5" width="16" height="15" rx="2" stroke="currentColor" stroke-width="1.7"/><path d="M8 3v4M16 3v4M4 9h16M8 13h4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>'
    };
    return icons[name] || icons.target;
  }

  function html(mode) {
    var fashion = mode === 'fashion';
    var p = progress();
    var s = SLOT[slotFor(new Date())];
    var items = upNextItems();
    var rootClass = 'nwsb-daydash ' + (fashion ? 'nwsb-daydash-fashion' : 'nwsb-daydash-normal');
    return '<section class="' + rootClass + '" data-daydash-mode="' + mode + '" data-slot="' + slotFor(new Date()) + '">' +
      '<div class="nwsb-focus-card" data-daydash-focus>' +
        '<video class="nwsb-focus-video" data-nwsb-own="1" muted autoplay loop playsinline preload="auto" poster="' + esc(srcFor(s.file, 'webp')) + '" src="' + esc(srcFor(s.file, 'mp4')) + '" data-local-poster="' + esc(localSrcFor(s.file, 'webp')) + '" data-local-src="' + esc(localSrcFor(s.file, 'mp4')) + '" aria-hidden="true"></video>' +
        '<div class="nwsb-focus-scrim"></div>' +
        '<div class="nwsb-focus-content">' +
          '<div class="nwsb-focus-eyebrow">' + esc(s.eyebrow) + '</div><div class="nwsb-focus-title">' + esc(s.title) + '</div><div class="nwsb-focus-sub">' + esc(s.sub) + '</div>' +
          '<button type="button" class="nwsb-focus-cta" data-daydash-focus-go>Start practice <span>→</span></button>' +
        '</div>' +
      '</div>' +
      '<div class="nwsb-dashboard-heading"><div><div class="nwsb-dashboard-eyebrow">Your practice</div><h2>Your Progress</h2></div><button type="button" data-daydash-progress>View all <span>›</span></button></div>' +
      '<div class="nwsb-progress-card">' +
        '<div class="nwsb-progress-stat"><span class="nwsb-stat-icon">' + icon('check') + '</span><strong data-progress-sessions>' + p.sessions + '</strong><small>sessions</small></div>' +
        '<div class="nwsb-progress-stat"><span class="nwsb-stat-icon">' + icon('timer') + '</span><strong data-progress-words>' + p.words + '</strong><small>words explored</small></div>' +
        '<div class="nwsb-progress-stat"><span class="nwsb-stat-icon">' + icon('fire') + '</span><strong data-progress-streak>' + p.streak + '</strong><small>day streak</small></div>' +
        '<div class="nwsb-progress-stat"><span class="nwsb-stat-icon">' + icon('target') + '</span><strong data-progress-goal>' + p.goal + '%</strong><small>goal progress</small></div>' +
      '</div>' +
      '<div class="nwsb-dashboard-heading nwsb-up-heading"><div><div class="nwsb-dashboard-eyebrow">Keep the ritual moving</div><h2>Up next</h2></div><button type="button" data-daydash-upnext-view>View all <span>›</span></button></div>' +
      '<div class="nwsb-upnext-list">' + items.map(function (item) { return '<button type="button" class="nwsb-upnext-card" data-daydash-upnext-action="' + esc(item.action) + '"><span class="nwsb-upnext-icon">' + icon('calendar') + '</span><span class="nwsb-upnext-copy"><strong>' + esc(item.title) + '</strong><small>' + esc(item.sub) + '</small></span><span class="nwsb-upnext-arrow">→</span></button>'; }).join('') + '</div>' +
    '</section>';
  }

  function open(action) {
    if (action === 'progress' && typeof openSub === 'function') openSub('my-progress');
    else if (action === 'routines' && typeof openSub === 'function') openSub('routines');
    else if (typeof openPracticeIntro === 'function') openPracticeIntro();
  }
  function bind(root) {
    if (!root || root.__daydashBound) return;
    root.__daydashBound = true;
    root.querySelectorAll('[data-daydash-focus-go]').forEach(function (el) { el.addEventListener('click', function (e) { e.stopPropagation(); open('practice'); }); });
    root.querySelectorAll('[data-daydash-progress]').forEach(function (el) { el.addEventListener('click', function (e) { e.stopPropagation(); open('progress'); }); });
    root.querySelectorAll('[data-daydash-upnext-view]').forEach(function (el) { el.addEventListener('click', function (e) { e.stopPropagation(); open('routines'); }); });
    root.querySelectorAll('[data-daydash-upnext-action]').forEach(function (el) { el.addEventListener('click', function (e) { e.stopPropagation(); open(el.getAttribute('data-daydash-upnext-action')); }); });
    var video = root.querySelector('.nwsb-focus-video');
    if (video) {
      video.muted = true; video.playsInline = true;
      var play = function () { var promise = video.play(); if (promise && promise.catch) promise.catch(function () {}); };
      video.addEventListener('error', function () {
        var fallback = video.getAttribute('data-local-src');
        var poster = video.getAttribute('data-local-poster');
        if (poster && video.poster !== poster) video.poster = poster;
        if (fallback && video.getAttribute('src') !== fallback) { video.setAttribute('src', fallback); video.load(); play(); }
      });
      if ('IntersectionObserver' in window) new IntersectionObserver(function (entries) { entries.forEach(function (entry) { if (entry.isIntersecting) play(); else video.pause(); }); }, { rootMargin: '120px' }).observe(video);
      else play();
    }
  }
  function mount(mode, selector, afterSelector) {
    var host = document.querySelector(selector);
    if (!host || host.querySelector(':scope > .nwsb-daydash')) return;
    var wrap = document.createElement('div'); wrap.innerHTML = html(mode);
    var node = wrap.firstElementChild; var after = host.querySelector(afterSelector);
    if (after && after.parentNode === host) after.insertAdjacentElement('afterend', node); else host.insertBefore(node, host.firstChild);
    bind(node);
  }
  function refresh() {
    var key = slotFor(new Date());
    document.querySelectorAll('.nwsb-daydash').forEach(function (root) {
      if (root.getAttribute('data-slot') !== key) { var fresh = document.createElement('div'); fresh.innerHTML = html(root.getAttribute('data-daydash-mode') || 'normal'); var node = fresh.firstElementChild; root.replaceWith(node); bind(node); }
      else { var p = progress(); var set = function (sel, value) { var el = root.querySelector(sel); if (el) el.textContent = value; }; set('[data-progress-sessions]', p.sessions); set('[data-progress-words]', p.words); set('[data-progress-streak]', p.streak); set('[data-progress-goal]', p.goal + '%'); }
    });
  }
  function boot() { mount('normal', '#home-nm .nmh-wrap', '.nmh-search'); mount('fashion', '#home .home-body', '.home-tagline'); refresh(); }
  window.NWSBDayDash = { refresh: refresh, slotFor: slotFor };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
  setInterval(refresh, 15 * 60 * 1000);
})();
