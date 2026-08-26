/* Live Normal Home dashboard.
   The iframe owns only the supplied visual design; this file owns account
   data, routine selection, and the real practice-player launch. */
(function () {
  'use strict';

  function readJson(key, fallback) {
    try { return JSON.parse(localStorage.getItem(key) || fallback); }
    catch (e) { return JSON.parse(fallback); }
  }

  function currentSlot() {
    var hour = new Date().getHours();
    if (hour < 10) return 'Morning';
    if (hour < 13) return 'Midday';
    if (hour < 17) return 'Afternoon';
    if (hour < 20) return 'Evening';
    return 'Night';
  }

  function routineList() {
    var live = Array.isArray(window._routines) ? window._routines : null;
    return live && live.length ? live : readJson('nwsb_routines', '[]');
  }

  function activeRoutine(list) {
    var slot = currentSlot();
    return list.find(function (routine) {
      return routine && (routine.time === slot || routine.name === slot);
    }) || list[0] || null;
  }

  function localSessions() {
    return readJson('nwsb_local_sessions', '{}');
  }

  function mergedSessions(data) {
    return Object.assign({}, localSessions(), (data && data.sessions) || {});
  }

  function dateKey(value) {
    return String(value || '').slice(0, 10);
  }

  function streakFrom(sessions) {
    var days = {};
    Object.keys(sessions).forEach(function (key) {
      var entry = sessions[key] || {};
      var date = dateKey(entry.date) || key.split('_')[0];
      if (/^\d{4}-\d{2}-\d{2}$/.test(date)) days[date] = true;
    });
    var cursor = new Date();
    var today = cursor.toISOString().slice(0, 10);
    if (!days[today]) cursor.setDate(cursor.getDate() - 1);
    var streak = 0;
    while (days[cursor.toISOString().slice(0, 10)] && streak < 365) {
      streak += 1;
      cursor.setDate(cursor.getDate() - 1);
    }
    return streak;
  }

  function routineCard(routine, isActive) {
    var words = Array.isArray(routine && routine.words) ? routine.words : [];
    var reps = Number(routine && routine.reps) || 7;
    var title = routine && routine.name ? routine.name + ' Word Ritual' : 'Your practice';
    return {
      id: String((routine && routine.id) || ''),
      title: title,
      subtitle: words.length ? words.length + ' word' + (words.length === 1 ? '' : 's') + ' · ' + reps + ' reps each' : 'No words selected yet',
      status: isActive ? 'Now' : 'Next'
    };
  }

  function dashboardState(data) {
    var routines = routineList();
    var active = activeRoutine(routines);
    var sessionMap = mergedSessions(data);
    var entries = Object.keys(sessionMap).map(function (key) { return sessionMap[key] || {}; });
    var today = new Date().toISOString().slice(0, 10);
    var todaySessions = entries.filter(function (entry) { return dateKey(entry.date) === today; });
    var activeWords = Array.isArray(active && active.words) ? active.words : [];
    var target = activeWords.length;
    var completedWords = {};
    todaySessions.forEach(function (entry) { if (entry.word) completedWords[entry.word] = true; });
    var completedToday = Object.keys(completedWords).length;
    var goal = target ? Math.min(100, Math.round((completedToday / target) * 100)) : 0;
    var streak = streakFrom(sessionMap);
    var activeCard = routineCard(active, true);
    var following = routines.filter(function (routine) { return routine !== active; })[0] || active;
    var nextCard = routineCard(following, following === active);

    return {
      focus: {
        label: 'Your ' + currentSlot().toLowerCase() + ' practice',
        title: activeCard.title,
        meta: target ? target + ' word' + (target === 1 ? '' : 's') : 'Choose words',
        detail: target ? ((Number(active && active.reps) || 7) + ' reps each') : 'Build a routine to personalise it'
      },
      metrics: {
        today: { value: String(todaySessions.length), label: 'Sessions today', detail: todaySessions.length ? 'Completed' : 'Start today' },
        total: { value: String(entries.length), label: 'Total sessions', detail: entries.length ? 'All time' : 'None completed yet' },
        streak: { value: String(streak), detail: streak ? 'Days in a row' : 'Start your streak' },
        goal: { value: target ? goal + '%' : '—', detail: target ? (completedToday + ' of ' + target + ' words') : 'No routine yet' }
      },
      routines: [activeCard, nextCard]
    };
  }

  var cachedData = {};

  async function loadUserData() {
    var base = Object.assign({}, window._userDataCache || {}, window._mpData || {});
    if (!window._currentUid) return base;
    try {
      var firestore = await import('https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js');
      var app = await import('https://www.gstatic.com/firebasejs/11.8.1/firebase-app.js');
      var snapshot = await firestore.getDoc(firestore.doc(firestore.getFirestore(app.getApp()), 'users', window._currentUid));
      if (snapshot.exists()) base = Object.assign(base, snapshot.data());
    } catch (e) {
      console.warn('Dashboard data:', e.message);
    }
    return base;
  }

  function postDashboard() {
    var frame = document.querySelector('.nmh-supplied-dashboard iframe');
    if (!frame || !frame.contentWindow) return;
    frame.contentWindow.postMessage({ type: 'nowssb-dashboard-data', dashboard: dashboardState(cachedData) }, window.location.origin);
  }

  window.nowssbDashboardRefresh = async function () {
    cachedData = await loadUserData();
    postDashboard();
  };

  window.startDashboardPractice = function (routineId) {
    var routines = routineList();
    var routine = routines.find(function (item) { return String(item && item.id) === String(routineId || ''); }) || activeRoutine(routines);
    if (routine && typeof loadRoutineWords === 'function') loadRoutineWords(routine);
    window._rtManualLaunch = true;
    window._pwShowIntro = false;
    window._pwAutoPlayOnce = true;
    if (typeof openSub === 'function') openSub('practice');
  };

  window.addEventListener('nwsb-practice-complete', function (event) {
    var session = event.detail;
    if (session && session.key) {
      cachedData.sessions = Object.assign({}, cachedData.sessions || {}, (function () {
        var item = {}; item[session.key] = session; return item;
      })());
    }
    postDashboard();
  });
  window.addEventListener('storage', function (event) {
    if (event.key === 'nwsb_routines' || event.key === 'nwsb_local_sessions') postDashboard();
  });
  window.addEventListener('load', function () { window.nowssbDashboardRefresh(); });
})();
