/* Physical settings dial. Replaces the glass arc when Settings is opened. */
(function () {
  var KEY = 'nwsb-player-prefs';
  var prefs = load();

  function load() {
    try {
      var raw = localStorage.getItem(KEY);
      if (raw) return Object.assign(defaults(), JSON.parse(raw));
    } catch (e) {}
    return defaults();
  }
  function defaults() {
    return { voice: 'female', speed: 1, reps: 3, loop: 'off', volume: 0.85, eq: 'flat', output: 'speaker' };
  }
  function save(p) {
    prefs = p;
    try { localStorage.setItem(KEY, JSON.stringify(p)); } catch (e) {}
    window._pwVoice = p.voice === 'male' ? 'M' : 'F';
    window._pwSpeed = p.speed;
    window._pwRepTarget = p.reps;
    window._pwLoop = p.loop !== 'off';
    if (typeof window.lgpSetVolume === 'function') window.lgpSetVolume(p.volume);
  }

  function loopName() {
    if (prefs.loop === 'infinite') return 'Infinite';
    if (prefs.loop === 'once') return 'Once';
    return 'Off';
  }

  function ensure() {
    if (document.getElementById('nwsbDialRoot')) return;
    var root = document.createElement('div');
    root.id = 'nwsbDialRoot';
    root.innerHTML = '';
    document.body.appendChild(root);
  }

  function hideSheet() {
    var s = document.getElementById('ndSheet');
    if (s) s.remove();
  }

  function sheet(html) {
    hideSheet();
    var el = document.createElement('div');
    el.id = 'ndSheet';
    el.className = 'nd-sheet';
    el.innerHTML = html;
    document.getElementById('nwsbDialRoot').appendChild(el);
  }

  function head(title) {
    return '<div class="nd-sheet-head"><button type="button" data-act="back" aria-label="Back">←</button><span>' + title + '</span></div>';
  }

  /* Open the exact AURA player-settings page (not the dial clone). */
  function open() {
    try {
      sessionStorage.setItem('nwsb_return_to_player', JSON.stringify({ ts: Date.now() }));
    } catch (e) {}
    var url = 'player-settings.html#clock';
    try {
      var pages = (window.NOWSSB_PAGES || (typeof PAGES !== 'undefined' ? PAGES : '') || '').toString();
      if (pages && /github\.io/i.test(pages)) {
        url = pages.replace(/\/?$/, '/') + 'player-settings.html#clock';
      }
    } catch (e) {}
    location.assign(url);
  }
  function close() {
    var r = document.getElementById('nwsbDialRoot');
    if (r) r.classList.remove('open');
    hideSheet();
  }

  var orig = window.lgpToggleArc;
  window.lgpToggleArc = function (force) {
    if (force === false) {
      close();
      return;
    }
    open();
    var a = document.getElementById('lgpArc');
    if (a) a.classList.remove('open');
  };

  if (!window._nwsbDialBound) {
    window._nwsbDialBound = true;
    document.addEventListener('click', function (e) {
      var hit = e.target && e.target.closest && e.target.closest('.lgp-settings');
      if (hit) { e.preventDefault(); e.stopPropagation(); window.lgpToggleArc(true); }
    }, true);
  }
})();
