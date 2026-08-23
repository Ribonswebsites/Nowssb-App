/*
 * NowssB time-aware home dashboard.
 *
 * The normal home and Fashion home share the same information architecture —
 * Focus, Progress, Up Next — but deliberately wear different surfaces. The
 * mode-specific CSS supplies the neumorphic or glass treatment.
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

  function srcFor(file, ext) {
    var path = 'home-banners/' + file + '.' + ext;
    return R2_BASE + '/' + path;
  }
  function localSrcFor(file, ext) { return LOCAL_VIDEO_BASE + file + '.' + ext; }

  function esc(value) {
    return String(value == null ? '' : value)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
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
    return { streak: isFinite(streak) ? streak : 0, sessions: isFinite(total) ? total : 0, words: Object.keys(words).length };
  }

  function nextPractice() {
    var routines = Array.isArray(window._routines) ? window._routines : [];
    var active = routines.find(function (r) { return r && r.enabled !== false && (r.word || r.title || r.name); });
    if (!active) return { title: 'Open today’s practice', sub: 'Choose a word and begin your next sound ritual', action: 'practice' };
    var label = active.word || active.title || active.name;
    return { title: String(label), sub: active.time || active.duration || 'Next word in your practice routine', action: 'practice' };
  }

  function icon(name) {
    var icons = {
      focus: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="12" r="8.5" stroke="currentColor" stroke-width="1.6"/><circle cx="12" cy="12" r="4.2" stroke="currentColor" stroke-width="1.6"/><circle cx="12" cy="12" r="1.4" fill="currentColor"/></svg>',
      progress: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M4 19V9M10 19V5M16 19v-7M22 19H2" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>',
      up: '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M6 4h12a2 2 0 0 1 2 2v12H4V6a2 2 0 0 1 2-2z" stroke="currentColor" stroke-width="1.7"/><path d="M8 2v4M16 2v4M4 9h16M8 13h4M8 16h7" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>'
    };
    return icons[name] || icons.focus;
  }

  function html(mode) {
    var fashion = mode === 'fashion';
    var p = progress();
    var n = nextPractice();
    var key = slotFor(new Date());
    var s = SLOT[key];
    var rootClass = 'nwsb-daydash ' + (fashion ? 'nwsb-daydash-fashion' : 'nwsb-daydash-normal');
    return '<section class="' + rootClass + '" data-daydash-mode="' + mode + '" data-slot="' + key + '">' +
      '<div class="nwsb-focus-card" data-daydash-focus>' +
        '<video class="nwsb-focus-video" data-nwsb-own="1" muted autoplay loop playsinline preload="metadata" poster="' + esc(localSrcFor(s.file, 'webp')) + '" src="' + esc(srcFor(s.file, 'mp4')) + '" data-local-src="' + esc(localSrcFor(s.file, 'mp4')) + '" aria-hidden="true"></video>' +
        '<div class="nwsb-focus-scrim"></div>' +
        '<div class="nwsb-focus-content">' +
          '<div class="nwsb-focus-eyebrow">' + esc(s.eyebrow) + '</div>' +
          '<div class="nwsb-focus-title">' + esc(s.title) + '</div>' +
          '<div class="nwsb-focus-sub">' + esc(s.sub) + '</div>' +
          '<button type="button" class="nwsb-focus-cta" data-daydash-focus-go>Start practice <span>→</span></button>' +
        '</div>' +
      '</div>' +
      '<div class="nwsb-dashboard-heading"><div><div class="nwsb-dashboard-eyebrow">Your practice</div><h2>Your Progress</h2></div><button type="button" data-daydash-progress>View all <span>›</span></button></div>' +
      '<div class="nwsb-progress-card">' +
        '<div class="nwsb-progress-stat"><span class="nwsb-stat-icon">' + icon('progress') + '</span><strong data-progress-streak>' + p.streak + '</strong><small>day streak</small></div>' +
        '<div class="nwsb-progress-stat"><span class="nwsb-stat-icon">' + icon('focus') + '</span><strong data-progress-sessions>' + p.sessions + '</strong><small>sessions</small></div>' +
        '<div class="nwsb-progress-stat"><span class="nwsb-stat-icon">' + icon('up') + '</span><strong data-progress-words>' + p.words + '</strong><small>words explored</small></div>' +
      '</div>' +
      '<div class="nwsb-dashboard-heading nwsb-up-heading"><div><div class="nwsb-dashboard-eyebrow">Keep the ritual moving</div><h2>Up next</h2></div><button type="button" data-daydash-upnext>View all <span>›</span></button></div>' +
      '<button type="button" class="nwsb-upnext-card" data-daydash-upnext>' +
        '<span class="nwsb-upnext-icon">' + icon('up') + '</span>' +
        '<span class="nwsb-upnext-copy"><strong data-upnext-title>' + esc(n.title) + '</strong><small data-upnext-sub>' + esc(n.sub) + '</small></span>' +
        '<span class="nwsb-upnext-arrow">→</span>' +
      '</button>' +
    '</section>';
  }

  function open(action) {
    if (action === 'progress' && typeof openSub === 'function') openSub('my-progress');
    else if (action === 'upnext' && typeof openSub === 'function') openSub('routines');
    else if (typeof openPracticeIntro === 'function') openPracticeIntro();
  }

  function bind(root) {
    if (!root || root.__daydashBound) return;
    root.__daydashBound = true;
    root.querySelectorAll('[data-daydash-focus-go]').forEach(function (el) { el.addEventListener('click', function (e) { e.stopPropagation(); open('focus'); }); });
    root.querySelectorAll('[data-daydash-progress]').forEach(function (el) { el.addEventListener('click', function (e) { e.stopPropagation(); open('progress'); }); });
    root.querySelectorAll('[data-daydash-upnext]').forEach(function (el) { el.addEventListener('click', function (e) { e.stopPropagation(); open('upnext'); }); });
    var video = root.querySelector('.nwsb-focus-video');
    if (video) {
      video.muted = true;
      video.playsInline = true;
      var play = function () { var p = video.play(); if (p && p.catch) p.catch(function () {}); };
      video.addEventListener('error', function () {
        var fallback = video.getAttribute('data-local-src');
        if (fallback && video.getAttribute('src') !== fallback) { video.setAttribute('src', fallback); video.load(); play(); }
      });
      if ('IntersectionObserver' in window) new IntersectionObserver(function (entries) { entries.forEach(function (entry) { if (entry.isIntersecting) play(); else video.pause(); }); }, { rootMargin: '120px' }).observe(video);
      else play();
    }
  }

  function mount(mode, selector, afterSelector) {
    var host = document.querySelector(selector);
    if (!host || host.querySelector(':scope > .nwsb-daydash')) return;
    var wrap = document.createElement('div');
    wrap.innerHTML = html(mode);
    var node = wrap.firstElementChild;
    var after = host.querySelector(afterSelector);
    if (after && after.parentNode === host) after.insertAdjacentElement('afterend', node);
    else host.insertBefore(node, host.firstChild);
    bind(node);
  }

  function refresh() {
    var key = slotFor(new Date());
    document.querySelectorAll('.nwsb-daydash').forEach(function (root) {
      if (root.getAttribute('data-slot') !== key) {
        var mode = root.getAttribute('data-daydash-mode') || 'normal';
        var fresh = document.createElement('div');
        fresh.innerHTML = html(mode);
        var node = fresh.firstElementChild;
        root.replaceWith(node);
        bind(node);
      } else {
        var p = progress();
        var n = nextPractice();
        var set = function (sel, value) { var el = root.querySelector(sel); if (el) el.textContent = value; };
        set('[data-progress-streak]', p.streak); set('[data-progress-sessions]', p.sessions); set('[data-progress-words]', p.words);
        set('[data-upnext-title]', n.title); set('[data-upnext-sub]', n.sub);
      }
    });
  }

  function boot() {
    mount('normal', '#home-nm .nmh-wrap', '.nmh-search');
    mount('fashion', '#home .home-body', '.home-tagline');
    refresh();
  }

  window.NWSBDayDash = { refresh: refresh, slotFor: slotFor };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
  setInterval(refresh, 15 * 60 * 1000);
})();
