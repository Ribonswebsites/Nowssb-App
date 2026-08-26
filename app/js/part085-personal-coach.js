(function () {
  'use strict';

  var API = 'https://nowssb-api.ribonpatil2.workers.dev';
  var state = { messages: [], busy: false };

  function el(id) { return document.getElementById(id); }
  function escapeHtml(value) {
    return String(value == null ? '' : value).replace(/[&<>"']/g, function (ch) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch];
    });
  }

  function fallbackReply(text) {
    var normalized = String(text || '').toLowerCase();
    if (normalized.indexOf('stress') >= 0 || normalized.indexOf('anx') >= 0) {
      return 'Let’s make the next step small. Take one slow breath, then open a short Practice session. You can stop after one word if that is enough for today.';
    }
    if (normalized.indexOf('plan') >= 0 || normalized.indexOf('day') >= 0) {
      return 'A simple plan: choose one short practice, keep one pause between tasks, and return here for a reflection when you are done.';
    }
    if (normalized.indexOf('motivat') >= 0 || normalized.indexOf('streak') >= 0) {
      return 'Consistency is built from gentle returns, not perfect days. Choose one small action now and let that count.';
    }
    return 'I’m here to help you choose a gentle next step. You can ask for a practice, a short routine, or a pause to reset.';
  }

  function renderMessages() {
    var list = el('nwsbPersonalCoachMessages');
    var send = el('nwsbPersonalCoachSend');
    if (!list) return;
    list.innerHTML = state.messages.map(function (message) {
      return '<div class="nwsb-personal-coach-message ' + (message.role === 'user' ? 'user' : '') + '">' + escapeHtml(message.content).replace(/\n/g, '<br>') + '</div>';
    }).join('') + (state.busy ? '<div class="nwsb-personal-coach-message typing">NowssB is thinking…</div>' : '');
    list.scrollTop = list.scrollHeight;
    if (send) send.disabled = state.busy;
  }

  function resetConversation() {
    state.messages = [{
      role: 'assistant',
      content: 'I’m your NowssB Personal Coach. Tell me how you feel or what you want to practise, and I’ll help you choose a gentle next step.'
    }];
    state.busy = false;
    renderMessages();
  }

  window.openPersonalCoach = function () {
    var screen = el('nwsbPersonalCoach');
    if (!screen) return;
    resetConversation();
    screen.classList.add('open');
    screen.setAttribute('aria-hidden', 'false');
    setTimeout(function () { var input = el('nwsbPersonalCoachInput'); if (input) input.focus(); }, 240);
  };

  window.closePersonalCoach = function () {
    var screen = el('nwsbPersonalCoach');
    if (!screen) return;
    screen.classList.remove('open');
    screen.setAttribute('aria-hidden', 'true');
  };

  window.openPersonalCoachPractice = function () {
    closePersonalCoach();
    if (typeof openSub === 'function') openSub('practice');
  };

  window.sendPersonalCoachPreset = function (button) {
    var prompt = button && button.getAttribute('data-prompt');
    if (prompt) sendCoachMessage(prompt);
  };

  window.sendPersonalCoachMessage = function (event) {
    if (event) event.preventDefault();
    var input = el('nwsbPersonalCoachInput');
    if (input) sendCoachMessage(input.value);
  };

  function sendCoachMessage(text) {
    text = String(text || '').trim();
    if (!text || state.busy) return;
    var input = el('nwsbPersonalCoachInput');
    if (input) input.value = '';
    state.messages.push({ role: 'user', content: text });
    state.busy = true;
    renderMessages();

    var headerPromise = typeof window.nwsbWorkerHeaders === 'function'
      ? window.nwsbWorkerHeaders({ 'Content-Type': 'application/json', 'X-NowssB-Client': 'webview' })
      : Promise.reject(new Error('Assistant headers unavailable'));

    headerPromise.then(function (headers) {
      return fetch(API + '/api/assistant/chat', {
        method: 'POST',
        headers: headers,
        body: JSON.stringify({
          mode: 'coach',
          messages: state.messages,
          context: 'The user is using the dedicated NowssB Personal Coach. Give concise, supportive, non-medical wellbeing guidance and, when useful, suggest an existing NowssB practice or routine.'
        })
      });
    }).then(function (response) {
      return response.json().then(function (body) {
        if (!response.ok) throw new Error(body.error || 'Assistant request failed');
        return body;
      });
    }).then(function (body) {
      state.messages.push({ role: 'assistant', content: body.message || fallbackReply(text) });
    }).catch(function () {
      state.messages.push({ role: 'assistant', content: fallbackReply(text) });
    }).finally(function () {
      state.busy = false;
      renderMessages();
    });
  }

  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') closePersonalCoach();
  });
})();
