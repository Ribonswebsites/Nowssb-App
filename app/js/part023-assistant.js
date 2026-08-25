(function () {
  'use strict';

  var API = 'https://nowssb-api.ribonpatil2.workers.dev';
  var state = {
    mode: 'support',
    messages: [],
    busy: false
  };
  var COPY = {
    support: {
      title: 'Chat Support',
      desc: 'Get clear help with the player, practice, library, routines, account, and every part of NowssB.',
      hero: 'assets/media/image/support-hero-291ea476.png',
      secondary: 'assets/media/image/support-topics-2830aa1b.png',
      featureEyebrow: 'App-aware help',
      featureTitle: 'Ask about any NowssB screen',
      featureCopy: 'Player controls, videos, audio, routines, the library, settings, subscriptions, and account guidance.',
      placeholder: 'Ask for help…',
      welcome: 'I’m NowssB Chat Support. Ask me about any app feature, or tell me what is not working and I’ll guide you step by step.',
      prompts: ['How do I use the Word Player?', 'My video or audio is not playing', 'Where are my routines and library?']
    },
    coach: {
      title: 'Personal Coach',
      desc: 'A calm NowssB companion for choosing a practice, building a routine, and reflecting on your day.',
      hero: 'assets/media/image/coach-hero-4e870666.png',
      secondary: 'assets/media/image/coach-practice-d7bfc5b8.png',
      featureEyebrow: 'Practice guidance',
      featureTitle: 'Make today’s next step simple',
      featureCopy: 'Talk about your mood, choose a time-aware practice, build a routine, and reflect without pressure.',
      placeholder: 'Tell your coach what you need…',
      welcome: 'I’m your NowssB Personal Coach. Tell me how you feel or what you want to practise, and I’ll help you choose a gentle next step.',
      prompts: ['Choose a practice for me today', 'Help me build a simple routine', 'I feel stressed right now']
    }
  };

  function el(id) { return document.getElementById(id); }
  function escapeHtml(value) {
    return String(value == null ? '' : value).replace(/[&<>"']/g, function (ch) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch];
    });
  }

  function appContext() {
    return 'The user is in the ' + state.mode + ' area of the NowssB WebView. Available destinations include Normal Home, Fashion Home, Today\'s Practice, Word Player, My Routines, Healing Path, Word Science, Real Meaning, Sound Library, eBooks, Store, Fashion Plus, Connect, Profile, Settings, progress, and streaks.';
  }

  function renderMessages() {
    var chat = el('nwsbAssistantChat');
    if (!chat) return;
    chat.innerHTML = state.messages.map(function (message) {
      var user = message.role === 'user';
      return '<div class="nwsb-assistant-message ' + (user ? 'user' : 'assistant') + '">' + escapeHtml(message.content).replace(/\n/g, '<br>') + '</div>';
    }).join('') + (state.busy ? '<div class="nwsb-assistant-typing">NowssB is thinking…</div>' : '');
    chat.scrollTop = chat.scrollHeight;
  }

  function renderQuick() {
    var quick = el('nwsbAssistantQuick');
    if (!quick) return;
    quick.innerHTML = COPY[state.mode].prompts.map(function (prompt) {
      return '<button type="button" onclick="sendAssistantPreset(this)" data-prompt="' + escapeHtml(prompt) + '"' + (state.busy ? ' disabled' : '') + '>' + escapeHtml(prompt) + '</button>';
    }).join('');
  }

  function renderMode() {
    var c = COPY[state.mode];
    var title = el('nwsbAssistantModeTitle');
    var desc = el('nwsbAssistantModeDesc');
    var hero = el('nwsbAssistantHero');
    var secondary = el('nwsbAssistantSecondary');
    var eyebrow = el('nwsbAssistantFeatureEyebrow');
    var featureTitle = el('nwsbAssistantFeatureTitle');
    var featureCopy = el('nwsbAssistantFeatureCopy');
    var input = el('nwsbAssistantInput');
    if (title) title.textContent = c.title;
    if (desc) desc.textContent = c.desc;
    if (hero) { hero.src = c.hero; hero.alt = c.title; }
    if (secondary) { secondary.src = c.secondary; secondary.alt = c.title + ' illustration'; }
    if (eyebrow) eyebrow.textContent = c.featureEyebrow;
    if (featureTitle) featureTitle.textContent = c.featureTitle;
    if (featureCopy) featureCopy.textContent = c.featureCopy;
    if (input) input.placeholder = c.placeholder;
    var supportTab = el('nwsbAssistantSupportTab');
    var coachTab = el('nwsbAssistantCoachTab');
    if (supportTab) supportTab.classList.toggle('active', state.mode === 'support');
    if (coachTab) coachTab.classList.toggle('active', state.mode === 'coach');
    renderQuick();
  }

  window.openAssistant = function (mode) {
    state.mode = mode === 'coach' ? 'coach' : 'support';
    state.messages = [{ role: 'assistant', content: COPY[state.mode].welcome }];
    state.busy = false;
    var screen = el('nwAssistant');
    if (!screen) return;
    renderMode();
    renderMessages();
    screen.classList.add('open');
    screen.setAttribute('aria-hidden', 'false');
    setTimeout(function () { var input = el('nwsbAssistantInput'); if (input) input.focus(); }, 240);
  };

  window.openAssistantMode = function (mode) {
    var next = mode === 'coach' ? 'coach' : 'support';
    if (state.mode === next && state.messages.length) {
      renderMode();
      return;
    }
    window.openAssistant(next);
  };

  window.closeAssistant = function () {
    var screen = el('nwAssistant');
    if (!screen) return;
    screen.classList.remove('open');
    screen.setAttribute('aria-hidden', 'true');
  };

  window.sendAssistantPreset = function (button) {
    var prompt = button && button.getAttribute('data-prompt');
    if (prompt) sendAssistant(prompt);
  };

  window.sendAssistantMessage = function (event) {
    if (event) event.preventDefault();
    var input = el('nwsbAssistantInput');
    if (input) sendAssistant(input.value);
  };

  function sendAssistant(text) {
    text = String(text || '').trim();
    if (!text || state.busy) return;
    var input = el('nwsbAssistantInput');
    if (input) input.value = '';
    state.messages.push({ role: 'user', content: text });
    state.busy = true;
    renderMessages();
    renderQuick();
    fetch(API + '/api/assistant/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-NowssB-Client': 'webview' },
      body: JSON.stringify({ mode: state.mode, messages: state.messages, context: appContext() })
    }).then(function (response) {
      return response.json().then(function (body) {
        if (!response.ok) throw new Error(body.error || 'Assistant request failed');
        return body;
      });
    }).then(function (body) {
      state.messages.push({ role: 'assistant', content: body.message || 'I could not find an answer right now.' });
    }).catch(function () {
      state.messages.push({ role: 'assistant', content: 'I could not reach the free NowssB assistant right now. Please try again in a moment. For account or billing matters, use human support.' });
    }).finally(function () {
      state.busy = false;
      renderMessages();
      renderQuick();
    });
  }

  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') closeAssistant();
  });
})();
