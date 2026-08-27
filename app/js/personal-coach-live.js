/* Personal Coach data + AI wiring.
   The supplied page owns the visual design; this module only fills it with
   the signed-in person's real practice progress and persists conversation
   history in that person's existing Firebase user document. */
(function () {
  'use strict';

  var API_URL = 'https://nowssb-api.ribonpatil2.workers.dev/api/assistant/chat';
  var MAX_HISTORY = 24;

  function json(key, fallback) {
    try { return JSON.parse(localStorage.getItem(key) || fallback); }
    catch (_) { return JSON.parse(fallback); }
  }

  function day(value) { return String(value || '').slice(0, 10); }

  function mergedSessions(profile) {
    return Object.assign({}, json('nwsb_local_sessions', '{}'), (profile && profile.sessions) || {});
  }

  function streak(sessions) {
    var recorded = {};
    Object.keys(sessions || {}).forEach(function (key) {
      var entry = sessions[key] || {};
      var recordedDay = day(entry.date) || key.split('_')[0];
      if (/^\d{4}-\d{2}-\d{2}$/.test(recordedDay)) recorded[recordedDay] = true;
    });
    var cursor = new Date();
    if (!recorded[cursor.toISOString().slice(0, 10)]) cursor.setDate(cursor.getDate() - 1);
    var count = 0;
    while (recorded[cursor.toISOString().slice(0, 10)] && count < 365) {
      count += 1;
      cursor.setDate(cursor.getDate() - 1);
    }
    return count;
  }

  function activeRoutine() {
    var routines = Array.isArray(window._routines) ? window._routines : json('nwsb_routines', '[]');
    var hour = new Date().getHours();
    var slot = hour < 10 ? 'Morning' : hour < 13 ? 'Midday' : hour < 17 ? 'Afternoon' : hour < 20 ? 'Evening' : 'Night';
    return routines.find(function (routine) { return routine && (routine.time === slot || routine.name === slot); }) || routines[0] || null;
  }

  function safeMessages(value) {
    if (!Array.isArray(value)) return [];
    return value.filter(function (item) {
      return item && (item.role === 'user' || item.role === 'assistant') && typeof item.text === 'string';
    }).map(function (item) {
      return { role: item.role, text: item.text.slice(0, 4000), at: String(item.at || '') };
    }).slice(-MAX_HISTORY);
  }

  function profileState(profile) {
    profile = profile || {};
    var coach = profile.coach || {};
    var routine = activeRoutine();
    var words = Array.isArray(routine && routine.words) ? routine.words : [];
    var sessions = mergedSessions(profile);
    var today = new Date().toISOString().slice(0, 10);
    var completedWords = {};
    Object.keys(sessions).forEach(function (key) {
      var entry = sessions[key] || {};
      if (day(entry.date) === today && entry.word) completedWords[entry.word] = true;
    });
    var completed = Object.keys(completedWords).length;
    var storedTasks = Array.isArray(coach.tasks) ? coach.tasks : [];
    var openTasks = storedTasks.filter(function (task) { return task && task.status !== 'completed'; });
    var doneTasks = storedTasks.filter(function (task) { return task && task.status === 'completed'; });
    var target = storedTasks.length || words.length;
    var done = storedTasks.length ? doneTasks.length : completed;
    var percent = target ? Math.min(100, Math.round((done / target) * 100)) : 0;
    var savedGoal = coach.goal && (coach.goal.title || coach.goal.focus) ? coach.goal : null;
    var onboardingGoal = profile.onboardingAnswers && profile.onboardingAnswers.goal;
    var focus = (savedGoal && (savedGoal.title || savedGoal.focus)) || onboardingGoal || (routine && routine.name) || 'Your practice';
    return {
      uid: window._currentUid || '',
      name: profile.displayName || window._userName || '',
      goal: String(focus),
      routine: routine && routine.name ? routine.name : '',
      taskTotal: target,
      taskDone: done,
      taskOpen: openTasks.length,
      percent: percent,
      streak: streak(sessions),
      totalSessions: Object.keys(sessions).length,
      messages: safeMessages(coach.messages)
    };
  }

  function text(root, selector, value) {
    var node = root.querySelector(selector);
    if (node) node.textContent = value;
  }

  function draw(root, state) {
    text(root, '[data-coach-progress-value]', state.percent + '%');
    text(root, '[data-coach-progress-label]', state.taskTotal ? (state.percent >= 100 ? 'Complete' : 'On Track') : 'Start here');
    text(root, '[data-coach-progress-caption]', state.taskTotal ? (state.taskDone + ' of ' + state.taskTotal + ' today') : 'Choose a practice to begin.');
    text(root, '[data-coach-focus]', state.goal);
    text(root, '[data-coach-task-count]', state.taskTotal ? (state.taskDone + ' / ' + state.taskTotal + ' tasks completed') : 'No tasks planned yet');
    text(root, '[data-coach-mindset]', state.streak ? (state.streak + '-day\nstreak.') : 'Growth\nin progress.');
    text(root, '[data-coach-mindset-caption]', state.streak ? 'Keep your rhythm going.' : 'Stay patient. Results compound.');
    var progress = root.querySelector('[data-coach-progress-ring]');
    if (progress) progress.setAttribute('stroke-dashoffset', String(364.4 * (1 - state.percent / 100)));
  }

  function showMessages(root, messages) {
    var chatBox = root.querySelector('.chat-box');
    if (!chatBox) return;
    chatBox.querySelectorAll('.coach-live-message').forEach(function (node) { node.remove(); });
    messages.slice(-4).forEach(function (message) {
      var bubble = document.createElement('div');
      bubble.className = 'coach-live-message coach-live-message-' + message.role;
      bubble.style.cssText = 'margin-top:10px;padding:12px 14px;border-radius:14px;background:' + (message.role === 'assistant' ? 'rgba(255,255,255,.08)' : 'rgba(255,255,255,.14)') + ';color:#f5f5f5;font-size:13px;line-height:1.45;white-space:pre-wrap;';
      bubble.textContent = (message.role === 'assistant' ? 'Coach: ' : 'You: ') + message.text;
      chatBox.appendChild(bubble);
    });
  }

  async function firebase() {
    if (!window._db || !window._currentUid) return null;
    var firestore = await import('https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js');
    return { api: firestore, ref: firestore.doc(window._db, 'users', window._currentUid) };
  }

  async function fetchProfile() {
    var connection = await firebase();
    if (!connection) return {};
    var snapshot = await connection.api.getDoc(connection.ref);
    return snapshot.exists() ? (snapshot.data() || {}) : {};
  }

  async function saveMessages(messages) {
    var connection = await firebase();
    if (!connection) throw new Error('Sign in to save your Personal Coach conversation.');
    await connection.api.setDoc(connection.ref, { coach: { messages: messages.slice(-MAX_HISTORY), updatedAt: new Date().toISOString() } }, { merge: true });
  }

  async function callCoach(messages, state) {
    var headers = { 'Content-Type': 'application/json', 'X-NowssB-Client': 'webview' };
    try {
      if (window._currentUser && typeof window._currentUser.getIdToken === 'function') {
        var token = await window._currentUser.getIdToken();
        if (token) headers.Authorization = 'Bearer ' + token;
      }
    } catch (_) {}
    var context = {
      user: state.name || 'NowssB member',
      activeGoal: state.goal,
      selectedRoutine: state.routine || 'none selected',
      todayCompleted: state.taskDone,
      todayTarget: state.taskTotal,
      openTasks: state.taskOpen,
      streakDays: state.streak,
      completedSessions: state.totalSessions
    };
    var response = await fetch(API_URL, {
      method: 'POST', headers: headers,
      body: JSON.stringify({
        mode: 'coach',
        messages: messages.slice(-12).map(function (message) { return { role: message.role, content: message.text }; }),
        context: JSON.stringify(context)
      })
    });
    if (!response.ok) throw new Error('Your coach is unavailable right now. Please try again.');
    var payload = await response.json();
    if (!payload || typeof payload.message !== 'string' || !payload.message.trim()) throw new Error('Your coach did not return a response. Please try again.');
    return payload.message.trim();
  }

  async function planDay(root, current, submit) {
    if (!window._currentUid) {
      showMessages(root, [{ role: 'assistant', text: 'Sign in to create a plan and keep it with your Personal Coach.' }]);
      return;
    }
    var routine = activeRoutine();
    var words = Array.isArray(routine && routine.words) ? routine.words.slice(0, 3) : [];
    if (words.length && !current.taskTotal) {
      var today = new Date().toISOString().slice(0, 10);
      var connection = await firebase();
      if (connection) {
        await connection.api.setDoc(connection.ref, {
          coach: {
            tasks: words.map(function (word) {
              return { id: today + '_' + word, title: 'Practice ' + word, date: today, status: 'open' };
            }),
            updatedAt: new Date().toISOString()
          }
        }, { merge: true });
      }
    }
    await submit('Plan my day');
  }

  function inputFor(root) {
    var existing = root.querySelector('.coach-live-input');
    if (existing) return existing;
    var placeholder = root.querySelector('.chat-placeholder');
    if (!placeholder) return null;
    var input = document.createElement('input');
    input.className = 'coach-live-input';
    input.type = 'text';
    input.placeholder = 'How can I help you today?';
    input.setAttribute('aria-label', 'Message your Personal Coach');
    input.style.cssText = 'width:100%;border:0;outline:0;background:transparent;color:#fff;font:inherit;';
    placeholder.replaceWith(input);
    return input;
  }

  function mount(root) {
    var input = inputFor(root);
    var send = root.querySelector('.send-btn');
    if (!input || !send || root.__nowssbCoachMounted) return;
    root.__nowssbCoachMounted = true;
    var current = profileState({});
    var submitting = false;

    function setSending(value) {
      submitting = value;
      send.style.opacity = value ? '.55' : '1';
      send.setAttribute('aria-busy', value ? 'true' : 'false');
    }

    async function refresh() {
      try {
        current = profileState(await fetchProfile());
        draw(root, current);
        showMessages(root, current.messages);
      } catch (error) {
        current = profileState({});
        draw(root, current);
      }
    }

    async function submit(value) {
      var message = String(value || '').trim();
      if (!message || submitting) return;
      if (!window._currentUid) {
        showMessages(root, [{ role: 'assistant', text: 'Sign in to use Personal Coach and keep your guidance connected to your progress.' }]);
        return;
      }
      setSending(true);
      try {
        var history = current.messages.concat([{ role: 'user', text: message, at: new Date().toISOString() }]).slice(-MAX_HISTORY);
        showMessages(root, history);
        input.value = '';
        var reply = await callCoach(history, current);
        history.push({ role: 'assistant', text: reply, at: new Date().toISOString() });
        await saveMessages(history);
        current.messages = history;
        showMessages(root, history);
      } catch (error) {
        showMessages(root, current.messages.concat([{ role: 'assistant', text: error && error.message ? error.message : 'Your coach is unavailable right now. Please try again.' }]));
      } finally {
        setSending(false);
      }
    }

    send.setAttribute('role', 'button');
    send.setAttribute('tabindex', '0');
    send.setAttribute('aria-label', 'Send message to Personal Coach');
    send.addEventListener('click', function () { submit(input.value); });
    send.addEventListener('keydown', function (event) { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); submit(input.value); } });
    input.addEventListener('keydown', function (event) { if (event.key === 'Enter') submit(input.value); });
    root.querySelectorAll('.chip').forEach(function (chip) {
      chip.setAttribute('role', 'button');
      chip.setAttribute('tabindex', '0');
      function act() {
        var prompt = chip.textContent.trim();
        if (/plan my day/i.test(prompt)) planDay(root, current, submit).then(refresh).catch(function (error) {
          showMessages(root, current.messages.concat([{ role: 'assistant', text: error && error.message ? error.message : 'Your day plan could not be saved. Please try again.' }]));
        });
        else submit(prompt);
      }
      chip.addEventListener('click', act);
      chip.addEventListener('keydown', function (event) { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); act(); } });
    });
    refresh();
  }

  window.NowssbPersonalCoach = { mount: mount };
})();
