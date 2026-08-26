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
        } else if (action === 'coach' && typeof window.openSub === 'function') {
          window.openSub('practice');
        }
      });
    });
  }

  function placeActionBar(host) {
    var mainOps = document.querySelector('#home-nm .mainops-blk.nmh-sec-wrap');
    if (!mainOps || !mainOps.parentNode) return;
    host.classList.remove('hl-off');
    mainOps.parentNode.insertBefore(host, mainOps.nextSibling);
  }

  async function start() {
    var dashboardHost = document.querySelector('[data-direct-neomorphic="dashboard"]');
    var essentialsHost = document.querySelector('[data-direct-neomorphic="essentials"]');
    var actionBarHost = document.querySelector('[data-direct-neomorphic="actionbar"]');
    if (!dashboardHost || !essentialsHost || !actionBarHost) return;
    try {
      var sources = await Promise.all([
        fetch('app/widgets/neomorphic_dashboard.html').then(function (response) { return response.text(); }),
        fetch('app/widgets/neumorphic-essentials.html').then(function (response) { return response.text(); }),
        fetch('app/widgets/neomorphic-action-bar-1.html').then(function (response) { return response.text(); })
      ]);
      var dashboardRoot = mount(dashboardHost, sources[0]);
      var essentialsRoot = mount(essentialsHost, sources[1], true);
      var actionBarRoot = mount(actionBarHost, sources[2]);
      wireDashboard(dashboardRoot);
      wireEssentials(essentialsRoot);
      wireActionBar(actionBarRoot);
      placeActionBar(actionBarHost);
      window.addEventListener('load', function () { placeActionBar(actionBarHost); }, { once: true });
      window.nowssbDirectDashboardRender = function (data) { renderDashboard(dashboardRoot, data); };
      if (typeof window.nowssbDashboardRefresh === 'function') window.nowssbDashboardRefresh();
    } catch (error) {
      console.warn('Direct neomorphic sections:', error.message);
    }
  }

  start();
})();
