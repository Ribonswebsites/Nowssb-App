/* Direct rendering of the two supplied neomorphic documents.
   The documents are fetched as source, but their CSS and body markup are
   mounted inside the page itself—not in an iframe—so Android WebView never
   exposes an external-document frame or cuts their height. */
(function () {
  'use strict';

  function sourceParts(source, transparentHost) {
    var documentNode = new DOMParser().parseFromString(source, 'text/html');
    var style = documentNode.querySelector('style');
    Array.prototype.slice.call(documentNode.querySelectorAll('script')).forEach(function (node) { node.remove(); });
    var css = style ? style.textContent : '';
    css = css.replace(/:root\s*\{/g, ':host{').replace(/\bbody\s*\{/g, ':host{');
    if (transparentHost) css += '\n:host{background:transparent !important;}';
    return { css: css, markup: documentNode.body.innerHTML };
  }

  function mount(host, source, transparentHost) {
    var parts = sourceParts(source, transparentHost);
    var root = host.attachShadow({ mode: 'open' });
    root.innerHTML = '<style>:host{display:block;width:100%;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;}\n' + parts.css + '</style>' + parts.markup;
    return root;
  }

  function dashboardText(root, id, value) {
    var element = root.getElementById(id);
    if (element) element.textContent = value;
  }

  function dashboardRoutine(root, prefix, routine) {
    dashboardText(root, prefix + 'Title', routine.title);
    dashboardText(root, prefix + 'Sub', routine.subtitle);
    var status = root.getElementById(prefix + 'Status');
    if (status) status.textContent = routine.status;
    var title = root.getElementById(prefix + 'Title');
    var row = title && title.closest('.upnext-row');
    if (row) {
      row.dataset.dashboardRoutineId = routine.id || '';
      row.setAttribute('aria-label', 'Play ' + routine.title);
    }
  }

  function runDashboardAction(action, routineId) {
    if (action === 'practice' && typeof window.startDashboardPractice === 'function') {
      window.startDashboardPractice(routineId);
    } else if (action === 'progress' && typeof window.openSub === 'function') {
      window.openSub('my-progress');
    } else if (action === 'routines' && typeof window.openSub === 'function') {
      window.openSub('routines');
    }
  }

  function wireDashboard(root) {
    root.querySelectorAll('[data-dashboard-action]').forEach(function (control) {
      function activate() { runDashboardAction(control.dataset.dashboardAction, control.dataset.dashboardRoutineId); }
      control.addEventListener('click', activate);
      control.addEventListener('keydown', function (event) {
        if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); activate(); }
      });
    });
  }

  function renderDashboard(root, data) {
    if (!data) return;
    dashboardText(root, 'dashboardFocusLabel', data.focus.label);
    dashboardText(root, 'dashboardFocusTitle', data.focus.title);
    dashboardText(root, 'dashboardFocusMeta', data.focus.meta);
    dashboardText(root, 'dashboardFocusDetail', data.focus.detail);
    dashboardText(root, 'dashboardMetricToday', data.metrics.today.value);
    dashboardText(root, 'dashboardMetricTodayLabel', data.metrics.today.label);
    dashboardText(root, 'dashboardMetricTodayDetail', data.metrics.today.detail);
    dashboardText(root, 'dashboardMetricTotal', data.metrics.total.value);
    dashboardText(root, 'dashboardMetricTotalLabel', data.metrics.total.label);
    dashboardText(root, 'dashboardMetricTotalDetail', data.metrics.total.detail);
    dashboardText(root, 'dashboardMetricStreak', data.metrics.streak.value);
    dashboardText(root, 'dashboardMetricStreakDetail', data.metrics.streak.detail);
    dashboardText(root, 'dashboardMetricGoal', data.metrics.goal.value);
    dashboardText(root, 'dashboardMetricGoalDetail', data.metrics.goal.detail);
    dashboardRoutine(root, 'dashboardRoutineOne', data.routines[0]);
    dashboardRoutine(root, 'dashboardRoutineTwo', data.routines[1]);
  }

  function wireEssentials(root) {
    root.querySelectorAll('[onclick]').forEach(function (node) { node.removeAttribute('onclick'); });
    var button = root.getElementById('see-more-btn');
    var extra = root.getElementById('extra-track');
    var label = root.getElementById('see-more-label');
    var tail = root.getElementById('tail-connector');
    if (!button || !extra || !label || !tail) return;
    button.addEventListener('click', function () {
      var open = extra.classList.toggle('show');
      tail.style.display = open ? 'block' : 'none';
      button.classList.toggle('open', open);
      label.textContent = open ? 'See less' : 'See more';
    });
  }

  function wireActionBar(root) {
    root.querySelectorAll('[data-actionbar-action]').forEach(function (control) {
      control.addEventListener('click', function () {
        var action = control.dataset.actionbarAction;
        if (action === 'support') {
          if (typeof window.ssOpenPanel === 'function') window.ssOpenPanel('support');
          else if (typeof window.openSub === 'function') window.openSub('settings');
        } else if (action === 'coach' && typeof window.openPersonalCoach === 'function') {
          window.openPersonalCoach();
        }
      });
    });
  }

  function closePersonalCoach() {
    var overlay = document.getElementById('nwsbPersonalCoachOverlay');
    if (overlay) overlay.classList.remove('open');
    document.body.classList.remove('nwsb-personal-coach-open');
  }

  function wireFashionMode(root) {
    root.querySelectorAll('[data-fashion-mode-action], .mini-box').forEach(function (control) {
      if (control.tagName !== 'BUTTON') {
        control.setAttribute('role', 'button');
        control.setAttribute('tabindex', '0');
      }
      function openFashion() {
        try { localStorage.setItem('nwsb_home_mode', 'home'); } catch (_) {}
        if (typeof window.goTo === 'function') window.goTo('home');
      }
      control.addEventListener('click', openFashion);
      control.addEventListener('keydown', function (event) {
        if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); openFashion(); }
      });
    });
  }

  function wirePersonalCoach(root) {
    var placeholder = root.querySelector('.chat-placeholder');
    var send = root.querySelector('.send-btn');
    var chatBox = root.querySelector('.chat-box');
    if (!placeholder || !send || !chatBox) return;
    var input = document.createElement('input');
    input.type = 'text';
    input.placeholder = 'How can I help you today?';
    input.setAttribute('aria-label', 'Message your Personal Coach');
    input.style.cssText = 'width:100%;border:0;outline:0;background:transparent;color:#fff;font:inherit;';
    placeholder.replaceWith(input);
    var thread = document.createElement('div');
    thread.className = 'coach-thread';
    thread.style.cssText = 'display:flex;flex-direction:column;gap:10px;margin:0 0 14px;max-height:340px;overflow:auto;scrollbar-width:none;';
    chatBox.insertBefore(thread, chatBox.firstChild);
    var status = document.createElement('div');
    status.className = 'coach-status';
    status.style.cssText = 'display:none;margin:8px 0;color:rgba(255,255,255,.55);font-size:12px;line-height:1.4;';
    chatBox.insertBefore(status, chatBox.firstChild);
    var state = { messages: [], conversationId: null, busy: false };

    function renderDashboardCards() {
      var data = window.nowssbDashboardState;
      if (!data) return;
      var goal = data.metrics && data.metrics.goal ? data.metrics.goal.value : '—';
      var focus = data.focus || {};
      var total = data.metrics && data.metrics.total ? data.metrics.total.value : '0';
      var numericGoal = Number.parseInt(goal, 10);
      if (!Number.isFinite(numericGoal)) numericGoal = 0;
      var pct = root.querySelector('.ring-pct');
      var focusTitle = root.querySelector('.focus-title');
      var barCaption = root.querySelector('.bar-caption');
      var cardFooter = root.querySelector('.card-footer');
      if (pct) pct.textContent = goal;
      if (focusTitle) focusTitle.textContent = focus.title || 'Choose a focus';
      if (barCaption) barCaption.textContent = total + ' completed sessions';
      var ring = root.querySelector('circle[stroke="#f0f0f0"]');
      if (ring) ring.style.strokeDashoffset = String(364.4 - (364.4 * numericGoal / 100));
      var fill = root.querySelector('.bar-fill');
      var dot = root.querySelector('.bar-dot');
      if (fill) fill.style.width = numericGoal + '%';
      if (dot) dot.style.left = numericGoal + '%';
      if (cardFooter) cardFooter.textContent = (data.metrics && data.metrics.goal ? data.metrics.goal.detail : 'Build a routine to personalise it');
    }
    function safeJson(key, fallback) {
      try { return JSON.parse(localStorage.getItem(key) || fallback); } catch (_) { return JSON.parse(fallback); }
    }
    function coachContext() {
      var sessions = safeJson('nwsb_local_sessions', '{}');
      var routines = Array.isArray(window._routines) ? window._routines : safeJson('nwsb_routines', '[]');
      var entries = Object.keys(sessions).map(function (key) { return sessions[key] || {}; });
      var today = new Date().toISOString().slice(0, 10);
      var todaySessions = entries.filter(function (entry) { return String(entry.date || '').slice(0, 10) === today; });
      var days = {};
      entries.forEach(function (entry) { var date = String(entry.date || '').slice(0, 10); if (/^\\d{4}-\\d{2}-\\d{2}$/.test(date)) days[date] = true; });
      var cursor = new Date();
      if (!days[cursor.toISOString().slice(0, 10)]) cursor.setDate(cursor.getDate() - 1);
      var streak = 0;
      while (days[cursor.toISOString().slice(0, 10)] && streak < 365) { streak += 1; cursor.setDate(cursor.getDate() - 1); }
      var routine = routines[0] || {};
      var words = Array.isArray(routine.words) ? routine.words : [];
      var completed = {};
      todaySessions.forEach(function (entry) { if (entry.word) completed[entry.word] = true; });
      return { client: 'webview', timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC', progress: { todaySessions: todaySessions.length, totalSessions: entries.length, streak: streak, goalPercent: words.length ? Math.round(Object.keys(completed).length / words.length * 100) : null }, routine: { name: routine.name || null, wordCount: words.length } };
    }
    function showStatus(text, visible) { status.textContent = text || ''; status.style.display = visible ? 'block' : 'none'; }
    function bubble(message) {
      var item = document.createElement('div');
      item.style.cssText = 'align-self:' + (message.role === 'user' ? 'flex-end' : 'flex-start') + ';max-width:88%;padding:11px 13px;border-radius:15px;background:' + (message.role === 'user' ? 'rgba(255,255,255,.16)' : 'rgba(255,255,255,.07)') + ';color:#f5f5f5;font-size:13px;line-height:1.5;white-space:pre-wrap;';
      item.textContent = message.content;
      return item;
    }
    function render() {
      renderDashboardCards();
      thread.replaceChildren();
      if (!state.messages.length) {
        var empty = document.createElement('div');
        empty.style.cssText = 'padding:2px 0 12px;color:rgba(255,255,255,.48);font-size:12px;line-height:1.45;';
        empty.textContent = 'Ask a real question about your focus, routine, progress, or what to do next.';
        thread.appendChild(empty);
      } else {
        state.messages.forEach(function (message) {
          thread.appendChild(bubble(message));
          (message.actions || []).forEach(function (action) {
            if (action.type !== 'start_practice') return;
            var actionButton = document.createElement('button');
            actionButton.type = 'button';
            actionButton.textContent = action.label || 'Start focused practice';
            actionButton.style.cssText = 'align-self:flex-start;border:1px solid rgba(255,255,255,.24);border-radius:999px;padding:8px 12px;background:transparent;color:#fff;font:inherit;font-size:12px;cursor:pointer;';
            actionButton.addEventListener('click', function () {
              if (typeof window.startDashboardPractice === 'function') window.startDashboardPractice();
              else if (typeof window.openSub === 'function') window.openSub('practice');
            });
            thread.appendChild(actionButton);
          });
        });
      }
      thread.scrollTop = thread.scrollHeight;
    }
    async function token() {
      var app = await import('https://www.gstatic.com/firebasejs/11.8.1/firebase-app.js');
      var authModule = await import('https://www.gstatic.com/firebasejs/11.8.1/firebase-auth.js');
      var user = authModule.getAuth(app.getApp()).currentUser;
      if (!user) throw new Error('Sign in first to chat with your coach.');
      return user.getIdToken();
    }
    async function loadHistory() {
      try {
        showStatus('Loading your coach history…', true);
        var idToken = await token();
        var response = await fetch('/api/coach', { headers: { Authorization: 'Bearer ' + idToken } });
        var data = await response.json().catch(function () { return {}; });
        if (!response.ok) throw new Error(data.error || 'Could not load coach history.');
        state.conversationId = data.conversationId || null;
        state.messages = (data.messages || []).filter(function (message) { return message.role === 'user' || message.role === 'assistant'; }).map(function (message) { return { role: message.role, content: message.content, actions: [] }; });
        render();
      } catch (error) {
        showStatus(error.message || 'Could not load coach history.', true);
      } finally {
        if (status.textContent === 'Loading your coach history…') showStatus('', false);
      }
    }
    async function respond(text) {
      var message = (text || '').trim();
      if (!message || state.busy) return;
      state.busy = true;
      input.value = '';
      var history = state.messages.slice(-20).map(function (item) { return { role: item.role, content: item.content }; });
      state.messages.push({ role: 'user', content: message, actions: [] });
      render();
      showStatus('Thinking…', true);
      send.style.opacity = '.45';
      try {
        var idToken = await token();
        var response = await fetch('/api/coach', { method: 'POST', headers: { Authorization: 'Bearer ' + idToken, 'Content-Type': 'application/json' }, body: JSON.stringify({ message: message, conversationId: state.conversationId, history: history, context: coachContext() }) });
        var data = await response.json().catch(function () { return {}; });
        if (!response.ok) throw new Error(data.error || 'The coach is unavailable.');
        state.conversationId = data.conversationId || state.conversationId;
        state.messages.push({ role: 'assistant', content: data.message.content, actions: data.message.actions || [] });
        render();
        showStatus('', false);
      } catch (error) {
        state.messages.pop();
        render();
        showStatus(error.message || 'The coach is unavailable. Check your connection and retry.', true);
      } finally {
        state.busy = false;
        send.style.opacity = '';
      }
    }
    send.setAttribute('role', 'button');
    send.setAttribute('tabindex', '0');
    send.setAttribute('aria-label', 'Send message to Personal Coach');
    send.addEventListener('click', function () { respond(input.value); });
    send.addEventListener('keydown', function (event) { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); respond(input.value); } });
    input.addEventListener('keydown', function (event) { if (event.key === 'Enter') respond(input.value); });
    root.querySelectorAll('.chip').forEach(function (chip) {
      chip.setAttribute('role', 'button');
      chip.setAttribute('tabindex', '0');
      chip.addEventListener('click', function () { respond(chip.textContent.trim()); });
      chip.addEventListener('keydown', function (event) { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); respond(chip.textContent.trim()); } });
    });
    render();
    loadHistory();
  }

  function personalCoachOverlay() {
    var overlay = document.getElementById('nwsbPersonalCoachOverlay');
    if (overlay) return overlay;
    overlay = document.createElement('div');
    overlay.id = 'nwsbPersonalCoachOverlay';
    overlay.className = 'nwsb-personal-coach-overlay';
    overlay.innerHTML = '<div id="nwsbPersonalCoachMount"></div>';
    document.body.appendChild(overlay);
    return overlay;
  }

  window.openPersonalCoach = function () {
    var overlay = personalCoachOverlay();
    overlay.classList.add('open');
    document.body.classList.add('nwsb-personal-coach-open');
    var mountPoint = document.getElementById('nwsbPersonalCoachMount');
    if (mountPoint && mountPoint.shadowRoot) return;
    fetch('app/widgets/personal-coach.html')
      .then(function (response) { return response.text(); })
      .then(function (source) {
        if (!mountPoint) return;
        var root = mount(mountPoint, source);
        wirePersonalCoach(root);
        var back = root.querySelector('.back-btn');
        if (back) {
          back.setAttribute('role', 'button');
          back.setAttribute('tabindex', '0');
          back.setAttribute('aria-label', 'Close Personal Coach');
          back.addEventListener('click', closePersonalCoach);
          back.addEventListener('keydown', function (event) {
            if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); closePersonalCoach(); }
          });
        }
      })
      .catch(function (error) { console.warn('Personal Coach:', error.message); });
  };

  function placeActionBar(host) {
    var mainOps = document.querySelector('#home-nm .mainops-blk.nmh-sec-wrap');
    if (!mainOps || !mainOps.parentNode) return;
    host.hidden = false;
    host.classList.remove('hl-off');
    host.style.setProperty('display', 'block', 'important');
    host.style.setProperty('visibility', 'visible', 'important');
    if (mainOps.nextElementSibling === host) return;
    host.classList.remove('hl-off');
    mainOps.parentNode.insertBefore(host, mainOps.nextSibling);
  }

  async function start() {
    var dashboardHost = document.querySelector('[data-direct-neomorphic="dashboard"]');
    var essentialsHost = document.querySelector('[data-direct-neomorphic="essentials"]');
    var actionBarHost = document.querySelector('[data-direct-neomorphic="actionbar"]');
    var fashionHost = document.querySelector('[data-direct-neomorphic="fashion"]');
    if (!dashboardHost || !essentialsHost || !actionBarHost || !fashionHost) return;
    try {
      var sources = await Promise.all([
        fetch('app/widgets/neomorphic_dashboard.html').then(function (response) { return response.text(); }),
        fetch('app/widgets/neumorphic-essentials.html').then(function (response) { return response.text(); }),
        fetch('app/widgets/neomorphic-action-bar-1.html').then(function (response) { return response.text(); }),
        fetch('app/widgets/fashion-mode-neumorphic-white.html').then(function (response) { return response.text(); })
      ]);
      var dashboardRoot = mount(dashboardHost, sources[0]);
      var essentialsRoot = mount(essentialsHost, sources[1], true);
      var actionBarRoot = mount(actionBarHost, sources[2]);
      var fashionRoot = mount(fashionHost, sources[3], true);
      wireDashboard(dashboardRoot);
      wireEssentials(essentialsRoot);
      wireActionBar(actionBarRoot);
      wireFashionMode(fashionRoot);
      placeActionBar(actionBarHost);
      window.addEventListener('load', function () { placeActionBar(actionBarHost); }, { once: true });
      var mainOps = document.querySelector('#home-nm .mainops-blk.nmh-sec-wrap');
      if (mainOps && mainOps.parentNode) {
        new MutationObserver(function () { placeActionBar(actionBarHost); })
          .observe(mainOps.parentNode, { childList: true });
      }
      window.nowssbDirectDashboardRender = function (data) { renderDashboard(dashboardRoot, data); };
      if (typeof window.nowssbDashboardRefresh === 'function') window.nowssbDashboardRefresh();
    } catch (error) {
      console.warn('Direct neomorphic sections:', error.message);
    }
  }

  start();
})();
