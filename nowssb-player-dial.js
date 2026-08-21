/* Physical settings dial. Replaces the glass arc when Settings is opened. */
(function () {
  var KEY = 'nwsb_player_prefs_v1';
  var EQ = {
    flat: [0, 0, 0, 0, 0, 0, 0],
    focus: [-2, -1, 1, 4, 5, 1, -2],
    deep: [6, 5, 2, 0, -1, -3, -4],
    bright: [-3, -2, 0, 1, 3, 6, 7]
  };
  var HZ = ['60', '150', '400', '1k', '2.4k', '6k', '14k'];
  var defaults = {
    voice: 'female', loop: 'off', reps: 7, speed: 1, volume: 0.85,
    eq: 'flat', bands: EQ.flat.slice(), output: 'speaker',
    quality: 'high', animation: true, notify: true, shuffle: false
  };
  function load() {
    try {
      var raw = JSON.parse(localStorage.getItem(KEY) || 'null');
      if (!raw) return Object.assign({}, defaults, { bands: EQ.flat.slice() });
      return Object.assign({}, defaults, raw, { bands: raw.bands || EQ.flat.slice() });
    } catch (e) { return Object.assign({}, defaults, { bands: EQ.flat.slice() }); }
  }
  function save(p) {
    try { localStorage.setItem(KEY, JSON.stringify(p)); } catch (e) {}
    window._pwVoice = p.voice === 'male' ? 'M' : 'F';
    window._pwSpeed = p.speed;
    window._pwRepTarget = p.reps;
    window._pwLoop = p.loop !== 'off';
    if (typeof window.lgpSetVolume === 'function') window.lgpSetVolume(p.volume);
  }
  var prefs = load();
  save(prefs);

  var ICO = {
    voice: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4"><path d="M2 10v4M6 7v10M10 4v16M14 7v10M18 10v4M22 8v8"/></svg>',
    eq: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4"><path d="M4 21v-7M4 8V3M12 21v-9M12 8V3M20 21v-5M20 10V3M2 8h4M10 8h4M18 10h4"/></svg>',
    loop: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4"><path d="M17 2l4 4-4 4"/><path d="M3 11V9a4 4 0 014-4h14"/><path d="M7 22l-4-4 4-4"/><path d="M21 13v2a4 4 0 01-4 4H3"/></svg>',
    speed: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4"><path d="M12 14l4-7"/><circle cx="12" cy="14" r="8"/></svg>',
    vol: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35"><path d="M11 5L6 9H2v6h4l5 4z"/><path d="M15.5 8.5a5 5 0 010 7"/><path d="M19 5a9 9 0 010 14"/></svg>',
    shuffle: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.35"><path d="M16 3h5v5"/><path d="M4 20L21 3"/><path d="M21 16v5h-5"/><path d="M15 15l6 6"/><path d="M4 4l5 5"/></svg>',
    gear: '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 00.3 1.8l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.8-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 11-4 0v-.2a1.7 1.7 0 00-1-1.5 1.7 1.7 0 00-1.8.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.8 1.7 1.7 0 00-1.5-1H3a2 2 0 110-4h.2a1.7 1.7 0 001.5-1 1.7 1.7 0 00-.3-1.8l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.8.3H9a1.7 1.7 0 001-1.5V3a2 2 0 114 0v.2a1.7 1.7 0 001 1.5 1.7 1.7 0 001.8-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00-.3 1.8V9c.3.7 1 1.2 1.8 1.2H21a2 2 0 110 4h-.2a1.7 1.7 0 00-1.4 1z"/></svg>'
  };

  function ticks() {
    var s = '<svg class="nwsb-dial-ticks" viewBox="0 0 100 100">';
    for (var i = 0; i < 120; i++) {
      var m = i % 5 === 0;
      s += '<line x1="50" y1="2.4" x2="50" y2="' + (m ? '6.8' : '4.6') + '" stroke="white" stroke-opacity="' + (m ? '.55' : '.2') + '" stroke-width="' + (m ? '.42' : '.24') + '" transform="rotate(' + (i * 3) + ' 50 50)"/>';
    }
    return s + '</svg>';
  }

  var arm = 'volume';
  var tickCtx = null;
  function hapticTick() {
    try { if (navigator.vibrate) navigator.vibrate(10); } catch (e) {}
    try {
      var AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) return;
      tickCtx = tickCtx || new AC();
      if (tickCtx.state === 'suspended') tickCtx.resume();
      var o = tickCtx.createOscillator();
      var g = tickCtx.createGain();
      o.type = 'square';
      o.frequency.value = 1760;
      g.gain.setValueAtTime(0.032, tickCtx.currentTime);
      g.gain.exponentialRampToValueAtTime(0.0001, tickCtx.currentTime + 0.016);
      o.connect(g).connect(tickCtx.destination);
      o.start();
      o.stop(tickCtx.currentTime + 0.018);
    } catch (e) {}
  }

  function applyTick(dir) {
    if (arm === 'volume') {
      prefs.volume = Math.max(0, Math.min(1, +(prefs.volume + dir * 0.02).toFixed(2)));
      save(prefs);
      hud('Volume · ' + Math.round(prefs.volume * 100));
    } else if (arm === 'speed') {
      prefs.speed = Math.max(0.7, Math.min(1.5, +(prefs.speed + dir * 0.05).toFixed(2)));
      save(prefs);
      hud('Speed · ' + prefs.speed.toFixed(2) + '×');
    } else {
      prefs.reps = Math.max(1, Math.min(99, prefs.reps + dir));
      save(prefs);
      var b = document.querySelector('#nwsbDialRoot .nwsb-dial-badge');
      if (b) b.textContent = prefs.reps + '×';
      hud('Reps · ' + prefs.reps + '×');
    }
  }

  function bindWind(dial) {
    if (!dial || dial._wound) return;
    dial._wound = true;
    var last = null, acc = 0, wind = 0;
    function ang(e) {
      var r = dial.getBoundingClientRect();
      return Math.atan2(e.clientY - (r.top + r.height / 2), e.clientX - (r.left + r.width / 2));
    }
    dial.addEventListener('pointerdown', function (e) {
      if (e.target.closest('button')) return;
      dial.setPointerCapture(e.pointerId);
      last = ang(e); acc = 0;
    });
    dial.addEventListener('pointermove', function (e) {
      if (last == null) return;
      var next = ang(e);
      var d = next - last;
      if (d > Math.PI) d -= Math.PI * 2;
      if (d < -Math.PI) d += Math.PI * 2;
      last = next;
      var deg = d * 180 / Math.PI;
      wind += deg;
      dial.style.setProperty('--wind', wind + 'deg');
      acc += deg;
      while (acc >= 5) { acc -= 5; hapticTick(); applyTick(1); }
      while (acc <= -5) { acc += 5; hapticTick(); applyTick(-1); }
    });
    function up() { last = null; }
    dial.addEventListener('pointerup', up);
    dial.addEventListener('pointercancel', up);
  }

  function loopName() {
    return prefs.loop === 'off' ? 'Off' : prefs.loop === 'once' ? 'Once' : 'Infinite';
  }

  function ensure() {
    if (document.getElementById('nwsbDialRoot')) return;
    var root = document.createElement('div');
    root.id = 'nwsbDialRoot';
    root.innerHTML =
      '<div class="nd-back"></div>' +
      '<div class="nwsb-ghost nwsb-ghost-a"></div><div class="nwsb-ghost nwsb-ghost-b"></div>' +
      '<button class="nd-close" type="button" aria-label="Close">←</button>' +
      '<div class="nd-brand">PLAYER</div>' +
      '<div class="nwsb-dial" role="group" aria-label="Player settings dial. Drag the ring to wind.">' +
        '<div class="nwsb-dial-bezel"><div class="nwsb-dial-knurl"></div></div>' +
        '<div class="nwsb-dial-lip"></div>' +
        '<div class="nwsb-dial-face">' + ticks() + '</div>' +
        '<button class="nwsb-dial-icon" data-slot="voice" data-act="voice" aria-label="Voice">' + ICO.voice + '</button>' +
        '<button class="nwsb-dial-icon" data-slot="eq" data-act="eq" aria-label="Equalizer">' + ICO.eq + '</button>' +
        '<button class="nwsb-dial-icon" data-slot="loop" data-act="loop" aria-label="Loop">' + ICO.loop + '</button>' +
        '<button class="nwsb-dial-icon" data-slot="shuffle" data-act="shuffle" aria-label="Shuffle">' + ICO.shuffle + '</button>' +
        '<button class="nwsb-dial-icon" data-slot="speed" data-act="speed" aria-label="Speed">' + ICO.speed + '</button>' +
        '<button class="nwsb-dial-icon" data-slot="volume" data-act="volume" aria-label="Volume">' + ICO.vol + '</button>' +
        '<button class="nwsb-dial-badge" data-act="reps" aria-label="Repetitions">' + prefs.reps + '×</button>' +
        '<button class="nwsb-dial-core" data-act="settings" aria-label="Open settings">' + ICO.gear + '</button>' +
      '</div>' +
      '<div class="nd-hint">Voice · EQ · Loop · Reps · Speed · Volume</div>' +
      '<div class="nd-hud" id="ndHud" hidden></div>' +
      '<div class="nd-sheet" id="ndSheet"></div>';
    document.body.appendChild(root);
    root.querySelector('.nd-close').onclick = close;
    root.querySelector('.nd-back').onclick = close;
    root.addEventListener('click', function (e) {
      var t = e.target.closest('[data-act]');
      if (!t || t.closest('#ndSheet')) return;
      act(t.getAttribute('data-act'));
    });
    bindWind(root.querySelector('.nwsb-dial'));
  }

  function hud(msg) {
    var el = document.getElementById('ndHud');
    if (!el) return;
    el.hidden = false; el.textContent = msg;
    clearTimeout(hud._t);
    hud._t = setTimeout(function () { el.hidden = true; }, 1100);
  }

  function speak(word) {
    if (!window.speechSynthesis) return;
    window.speechSynthesis.cancel();
    var u = new SpeechSynthesisUtterance((word || 'aarogya').toLowerCase());
    u.rate = Math.max(0.6, Math.min(1.4, prefs.speed * 0.92));
    u.volume = prefs.volume;
    u.pitch = prefs.voice === 'male' ? 0.75 : prefs.voice === 'night' ? 0.9 : prefs.voice === 'resonance' ? 0.85 : 1.05;
    window.speechSynthesis.speak(u);
  }

  function currentWord() {
    try {
      var words = typeof PRACTICE_WORDS !== 'undefined' ? PRACTICE_WORDS : [];
      var idx = typeof _pwIdx !== 'undefined' ? _pwIdx : 0;
      return (words[idx] && words[idx].word) || 'AAROGYA';
    } catch (e) { return 'AAROGYA'; }
  }

  function sheet(html) {
    var s = document.getElementById('ndSheet');
    s.innerHTML = html;
    s.classList.add('open');
  }
  function hideSheet() {
    var s = document.getElementById('ndSheet');
    if (s) { s.classList.remove('open'); s.innerHTML = ''; }
  }

  function head(title) {
    return '<button class="nd-close" type="button" data-act="back">←</button><p class="nd-brand" style="position:static;margin:48px 0 0">PLAYER</p><h1>' + title + '</h1>';
  }

  function act(kind) {
    if (kind === 'volume' || kind === 'speed' || kind === 'reps') {
      arm = kind;
      var icons = document.querySelectorAll('#nwsbDialRoot .nwsb-dial-icon');
      for (var i = 0; i < icons.length; i++) {
        var a = icons[i].getAttribute('data-act');
        icons[i].setAttribute('data-armed', a === arm ? 'true' : 'false');
      }
    }
    if (kind === 'loop') {
      prefs.loop = prefs.loop === 'off' ? 'once' : prefs.loop === 'once' ? 'infinite' : 'off';
      save(prefs);
      hud('Loop · ' + loopName());
      var b = document.querySelector('#nwsbDialRoot [data-act="loop"]');
      if (b) b.setAttribute('data-on', prefs.loop !== 'off' ? 'true' : 'false');
      return;
    }
    if (kind === 'shuffle') {
      prefs.shuffle = !prefs.shuffle;
      save(prefs);
      hud('Shuffle · ' + (prefs.shuffle ? 'On' : 'Off'));
      return;
    }
    if (kind === 'output') {
      prefs.output = prefs.output === 'speaker' ? 'earpiece' : prefs.output === 'earpiece' ? 'bluetooth' : 'speaker';
      save(prefs);
      hud(prefs.output === 'speaker' ? 'Speaker' : prefs.output === 'earpiece' ? 'Earpiece' : 'Bluetooth');
      return;
    }
    if (kind === 'voice') {
      var voices = [
        ['female', 'Female', 'Clear mid, the default teaching voice'],
        ['male', 'Male', 'Lower chest resonance'],
        ['resonance', 'Resonance', 'Studio master, held longer'],
        ['night', 'Night', 'Soft, for late practice']
      ];
      sheet(head('Voice') + voices.map(function (v) {
        return '<button class="nd-row' + (prefs.voice === v[0] ? ' on' : '') + '" data-voice="' + v[0] + '"><span>' + ICO.voice + '</span><span><b>' + v[1] + '</b><br><small style="opacity:.55">' + v[2] + '</small></span></button>';
      }).join(''));
      document.getElementById('ndSheet').onclick = function (e) {
        if (e.target.closest('[data-act="back"]')) { hideSheet(); return; }
        var r = e.target.closest('[data-voice]'); if (!r) return;
        prefs.voice = r.getAttribute('data-voice'); save(prefs); speak(currentWord()); act('voice');
      };
      return;
    }
    if (kind === 'eq') {
      sheet(head('Equalizer') + '<div class="nd-eq nd-card" style="display:flex">' +
        prefs.bands.map(function (b, i) {
          return '<label>' + HZ[i] + '<input type="range" min="-12" max="12" value="' + b + '" data-band="' + i + '"></label>';
        }).join('') + '</div>' +
        ['flat', 'focus', 'deep', 'bright', 'custom'].map(function (p) {
          return '<button class="nd-pill' + (prefs.eq === p ? ' on' : '') + '" data-eq="' + p + '">' + p + '</button>';
        }).join(''));
      document.getElementById('ndSheet').onclick = function (e) {
        if (e.target.closest('[data-act="back"]')) { hideSheet(); return; }
        var p = e.target.closest('[data-eq]'); if (!p) return;
        prefs.eq = p.getAttribute('data-eq');
        if (prefs.eq !== 'custom') prefs.bands = (EQ[prefs.eq] || EQ.flat).slice();
        save(prefs); act('eq');
      };
      document.getElementById('ndSheet').oninput = function (e) {
        var i = e.target.getAttribute('data-band'); if (i == null) return;
        prefs.bands[+i] = +e.target.value; prefs.eq = 'custom'; save(prefs);
      };
      return;
    }
    if (kind === 'reps') {
      var presets = [1, 3, 5, 7, 10];
      var customOn = presets.indexOf(prefs.reps) < 0;
      sheet(head('Repetitions') +
        presets.map(function (n) {
          return '<button class="nd-card' + (prefs.reps === n ? ' on' : '') + '" data-reps="' + n + '" style="justify-content:center;font-size:22px;font-weight:800">' + n + '×</button>';
        }).join('') +
        '<button class="nd-card' + (customOn ? ' on' : '') + '" data-reps="custom" style="justify-content:center;font-weight:700">Custom</button>');
      document.getElementById('ndSheet').onclick = function (e) {
        if (e.target.closest('[data-act="back"]')) { hideSheet(); return; }
        var r = e.target.closest('[data-reps]'); if (!r) return;
        var v = r.getAttribute('data-reps');
        if (v === 'custom') {
          var n = Number(window.prompt('Custom repetitions', String(prefs.reps)));
          if (!Number.isFinite(n) || n < 1 || n > 99) return;
          prefs.reps = Math.round(n);
        } else {
          prefs.reps = +v;
        }
        save(prefs);
        var b = document.querySelector('#nwsbDialRoot .nwsb-dial-badge');
        if (b) b.textContent = prefs.reps + '×';
        act('reps');
      };
      return;
    }
    if (kind === 'speed') {
      sheet(head('Speed') + '<div class="nd-card" style="flex-direction:column"><div style="font-size:44px;font-weight:800;color:#d7f2ff" id="ndSpeedVal">' + prefs.speed.toFixed(2) + '×</div><p style="opacity:.5;font-size:12px">0.70× slow hold — 1.50× fluent</p><input id="ndSpeed" type="range" min="0.7" max="1.5" step="0.05" value="' + prefs.speed + '" style="width:100%;accent-color:#d7f2ff"></div>');
      document.getElementById('ndSheet').onclick = function (e) { if (e.target.closest('[data-act="back"]')) hideSheet(); };
      document.getElementById('ndSpeed').oninput = function () {
        prefs.speed = +this.value; save(prefs);
        document.getElementById('ndSpeedVal').textContent = prefs.speed.toFixed(2) + '×';
      };
      return;
    }
    if (kind === 'volume') {
      sheet(head('Volume') + '<div class="nd-card" style="flex-direction:column"><div style="font-size:44px;font-weight:800;color:#d7f2ff" id="ndVolVal">' + Math.round(prefs.volume * 100) + '</div><input id="ndVol" type="range" min="0" max="1" step="0.01" value="' + prefs.volume + '" style="width:100%;accent-color:#d7f2ff"></div>' +
        [['speaker', 'Speaker'], ['earpiece', 'Earpiece'], ['bluetooth', 'Bluetooth']].map(function (o) {
          return '<button class="nd-row' + (prefs.output === o[0] ? ' on' : '') + '" data-out="' + o[0] + '">' + o[1] + '</button>';
        }).join(''));
      document.getElementById('ndSheet').onclick = function (e) {
        if (e.target.closest('[data-act="back"]')) { hideSheet(); return; }
        var o = e.target.closest('[data-out]'); if (!o) return;
        prefs.output = o.getAttribute('data-out'); save(prefs); act('volume');
      };
      document.getElementById('ndVol').oninput = function () {
        prefs.volume = +this.value; save(prefs);
        document.getElementById('ndVolVal').textContent = Math.round(prefs.volume * 100);
      };
      return;
    }
    if (kind === 'settings') {
      sheet(head('Settings') +
        '<div class="nd-card" style="flex-direction:column;align-items:stretch"><div style="opacity:.45;font-size:10px;letter-spacing:.2em;font-weight:800">PLAYBACK</div>' +
        [['Voice', 'voice', prefs.voice], ['Speed', 'speed', prefs.speed + '×'], ['Reps', 'reps', prefs.reps + '×'], ['Loop', 'loop', loopName()], ['Equalizer', 'eq', prefs.eq]].map(function (r) {
          return '<button class="nd-row" data-act="' + r[1] + '" style="margin:0"><span>' + r[0] + '</span><b style="margin-left:auto;color:#d7f2ff">' + r[2] + '</b></button>';
        }).join('') + '</div>' +
        '<div class="nd-card" style="flex-direction:column;align-items:stretch"><div style="opacity:.45;font-size:10px;letter-spacing:.2em;font-weight:800">AUDIO QUALITY</div>' +
        '<button class="nd-row" data-toggle="quality" style="margin:0"><span>Render</span><b style="margin-left:auto;color:#d7f2ff">' + (prefs.quality === 'high' ? 'High' : 'Standard') + '</b></button></div>' +
        '<div class="nd-card" style="flex-direction:column;align-items:stretch"><div style="opacity:.45;font-size:10px;letter-spacing:.2em;font-weight:800">DISPLAY & ANIMATION</div>' +
        '<button class="nd-row" data-toggle="animation" style="margin:0"><span>Motion</span><b style="margin-left:auto;color:#d7f2ff">' + (prefs.animation ? 'On' : 'Off') + '</b></button></div>' +
        '<div class="nd-card" style="flex-direction:column;align-items:stretch"><div style="opacity:.45;font-size:10px;letter-spacing:.2em;font-weight:800">NOTIFICATIONS</div>' +
        '<button class="nd-row" data-toggle="notify" style="margin:0"><span>Practice reminders</span><b style="margin-left:auto;color:#d7f2ff">' + (prefs.notify ? 'On' : 'Off') + '</b></button></div>' +
        '<div class="nd-card" style="flex-direction:column;align-items:stretch"><div style="opacity:.45;font-size:10px;letter-spacing:.2em;font-weight:800">ABOUT</div><div>Version 9.6.0</div><button class="nd-btn cyan" data-act="update" style="margin-top:10px">Check for updates</button></div>');
      document.getElementById('ndSheet').onclick = function (e) {
        var tog = e.target.closest('[data-toggle]');
        if (tog) {
          var t = tog.getAttribute('data-toggle');
          if (t === 'quality') prefs.quality = prefs.quality === 'high' ? 'standard' : 'high';
          if (t === 'animation') prefs.animation = !prefs.animation;
          if (t === 'notify') prefs.notify = !prefs.notify;
          save(prefs); act('settings'); return;
        }
        var a = e.target.closest('[data-act]'); if (!a) return;
        var k = a.getAttribute('data-act');
        if (k === 'back') hideSheet();
        else if (k === 'loop') { act('loop'); act('settings'); }
        else act(k);
      };
      return;
    }
    if (kind === 'update') {
      sheet('<div class="nd-update"><span class="nd-badge">NEW</span><h1 style="margin-top:12px">Update available</h1><p style="opacity:.55">NowssB 9.6.0</p><p style="line-height:1.55;margin:14px 0 20px">Physical settings dial. Voice, equalizer, loop, reps, speed and volume now live on the player.</p><div style="display:flex;gap:10px"><button class="nd-btn ghost" style="flex:1" data-act="back">Later</button><button class="nd-btn cyan" style="flex:1" data-act="back">Update now</button></div></div>');
      document.getElementById('ndSheet').onclick = function (e) {
        if (e.target.closest('[data-act="back"]')) hideSheet();
      };
    }
  }

  function open() {
    ensure();
    hideSheet();
    document.getElementById('nwsbDialRoot').classList.add('open');
    var loopBtn = document.querySelector('#nwsbDialRoot [data-act="loop"]');
    if (loopBtn) loopBtn.setAttribute('data-on', prefs.loop !== 'off' ? 'true' : 'false');
    var reps = document.querySelector('#nwsbDialRoot .nwsb-dial-badge');
    if (reps) reps.textContent = prefs.reps + '×';
  }
  function close() {
    var r = document.getElementById('nwsbDialRoot');
    if (r) r.classList.remove('open');
    hideSheet();
  }

  var orig = window.lgpToggleArc;
  window.lgpToggleArc = function (force) {
    var root = document.getElementById('nwsbDialRoot');
    var openNow = root && root.classList.contains('open');
    if (force === true || !openNow) open();
    else close();
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
