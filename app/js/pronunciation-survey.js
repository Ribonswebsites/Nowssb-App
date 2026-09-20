/* NowssB pronunciation feedback survey — plain HTML/CSS/JS, no dependencies. */
(function () {
  'use strict';

  var STORAGE_KEY = 'hasSeenPronunciationSurvey';
  var active = null;

  var icons = {
    check: '<svg viewBox="0 0 24 24" aria-hidden="true"><path class="nps-icon-path" d="M5 12.5l4.2 4.2L19 7"/></svg>',
    star: '<svg viewBox="0 0 24 24" aria-hidden="true"><path class="nps-icon-path" d="M12 3.8l2.45 4.97 5.49.8-3.97 3.87.94 5.47L12 16.32l-4.91 2.59.94-5.47-3.97-3.87 5.49-.8L12 3.8z"/></svg>',
    thumb: '<svg viewBox="0 0 24 24" aria-hidden="true"><path class="nps-icon-path" d="M7.2 10.3v9.1H4.5a1 1 0 0 1-1-1v-7.1a1 1 0 0 1 1-1h2.7zM7.2 19.4h8.9a2 2 0 0 0 1.94-1.52l1.8-7.2a2 2 0 0 0-1.94-2.48h-4.1l.62-3.1A1.8 1.8 0 0 0 12.66 3l-5.46 7.3v9.1z"/></svg>',
    pencil: '<svg viewBox="0 0 24 24" aria-hidden="true"><path class="nps-icon-path" d="M4 17.8V20h2.2L18.9 7.3l-2.2-2.2L4 17.8zM15.5 5.3l2.2 2.2 1.2-1.2a1.55 1.55 0 0 0 0-2.2l-.1-.1a1.55 1.55 0 0 0-2.2 0l-1.1 1.3z"/></svg>'
  };

  function esc(value) {
    return String(value || '').replace(/[&<>"']/g, function (c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c];
    });
  }

  function template() {
    return '<div class="nps-backdrop" data-nps-close="1">' +
      '<section class="nps-sheet" role="dialog" aria-modal="true" aria-labelledby="npsTitle" tabindex="-1" onclick="event.stopPropagation()">' +
        '<div class="nps-handle" aria-hidden="true"></div>' +
        '<div class="nps-brand" aria-label="NowssB logo">NowssB<span>.</span></div>' +
        '<button class="nps-close" type="button" aria-label="Close feedback">&times;</button>' +
        '<h2 id="npsTitle">Help us improve <span class="nps-purple">pronunciation</span> on NowssB</h2>' +
        '<p class="nps-sub">Tell us what\'s working and what\'s not. The more <span class="nps-purple">specific</span>, the better.</p>' +
        '<div class="nps-options" role="group" aria-label="Pronunciation feedback options">' +
          '<button class="nps-option" type="button" data-value="helpful"><span class="nps-icon-badge">' + icons.check + '</span><span>This pronunciation is <span class="nps-purple">helpful</span></span></button>' +
          '<button class="nps-option" type="button" data-value="experience"><span class="nps-icon-badge">' + icons.star + '</span><span>How was your overall <span class="nps-purple">experience</span>?</span></button>' +
          '<button class="nps-option" type="button" data-value="dislike"><span class="nps-icon-badge">' + icons.thumb + '</span><span>What didn\'t you <span class="nps-purple">like</span> about it?</span></button>' +
          '<button class="nps-option" type="button" data-value="changes"><span class="nps-icon-badge">' + icons.pencil + '</span><span>What changes should we make? / Write a <span class="nps-purple">review</span></span></button>' +
        '</div>' +
        '<textarea class="nps-textarea" maxlength="1200" placeholder="What would you like us to know?" aria-label="Additional feedback"></textarea>' +
        '<button class="nps-submit" type="button">Send <span class="nps-purple">feedback</span><span class="nps-submit-check" aria-hidden="true">✓</span></button>' +
        '<div class="nps-success" role="status" aria-live="polite"><span>✓</span> Thank you for helping us <b>improve</b>.</div>' +
      '</section>' +
    '</div>';
  }

  function closeSurvey() {
    if (!active) return;
    var root = active.root;
    if (active.closed) return;
    active.closed = true;
    root.classList.remove('nps-open');
    setTimeout(function () {
      if (root.parentNode) root.parentNode.removeChild(root);
      var done = active && active.done;
      active = null;
      if (done) done();
    }, 320);
  }

  function openSurvey(done) {
    if (active) return true;
    try {
      if (localStorage.getItem(STORAGE_KEY) === 'true') return false;
      localStorage.setItem(STORAGE_KEY, 'true');
    } catch (_) { /* Private browsing: the in-memory active guard still applies. */ }

    var root = document.createElement('div');
    root.innerHTML = template();
    root = root.firstElementChild;
    document.body.appendChild(root);
    active = { root: root, done: typeof done === 'function' ? done : null, closed: false };

    var sheet = root.querySelector('.nps-sheet');
    var submit = root.querySelector('.nps-submit');
    root.querySelector('[data-nps-close="1"]').addEventListener('click', closeSurvey);
    root.querySelector('.nps-close').addEventListener('click', closeSurvey);
    root.querySelectorAll('.nps-option').forEach(function (option) {
      option.addEventListener('click', function () {
        root.querySelectorAll('.nps-option').forEach(function (item) { item.classList.remove('is-selected'); });
        option.classList.add('is-selected');
      });
    });
    submit.addEventListener('click', function () {
      if (submit.classList.contains('is-sent')) return;
      var selected = root.querySelector('.nps-option.is-selected');
      var payload = {
        selected: selected ? selected.getAttribute('data-value') : null,
        note: root.querySelector('.nps-textarea').value.trim(),
        createdAt: new Date().toISOString()
      };
      window.nwsbLastPronunciationFeedback = payload;
      document.dispatchEvent(new CustomEvent('nwsb:pronunciation-feedback', { detail: payload }));
      submit.classList.add('is-sent');
      root.querySelector('.nps-success').classList.add('is-visible');
      setTimeout(closeSurvey, 760);
    });
    sheet.addEventListener('keydown', function (event) {
      if (event.key === 'Escape') closeSurvey();
    });
    requestAnimationFrame(function () {
      root.classList.add('nps-open');
      setTimeout(function () { sheet.focus(); }, 80);
    });
    return true;
  }

  window.nwsbTriggerPronunciationSurvey = openSurvey;
  window.nwsbMaybePronunciationSurvey = function (done) {
    return openSurvey(done);
  };
}());
