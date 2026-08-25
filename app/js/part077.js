/* ══════════════════════════════════════════════════════════
   THE FULL-SCREEN SHEET — one component, three uses.

   The shape is the interstitial you sent: a dark blurred field, a close
   cross alone in the top right, the artwork, a heavy all-caps line under
   it, one grey line under that, and full-width white pills stacked at the
   bottom. Nothing else. It is used for

     1. the Fashion Plus caution, before the mode can be turned on
     2. the Word Atelier's disclaimer
     3. the Meaning Store's disclaimer

   Two and three carry the same text, because they are the same claim: the
   words and the meanings in this app are described by their SOUNDS, under
   a hypothesis that is openly presented as a hypothesis. That page is a
   research proposal, not a marketing line, and nobody should be able to
   buy a meaning without having been shown it. Agreement is recorded per
   store and asked for once.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  var host = null;

  function close() {
    if (!host) return;
    host.classList.remove('on');
    setTimeout(function () { if (host) { host.remove(); host = null; } }, 260);
  }
  window.nwsbSheetClose = close;

  /* opts: art, head, sub, body (html), actions [{label, primary, go}] */
  function open(opts) {
    if (host) { host.remove(); host = null; }
    var o = opts || {};
    host = document.createElement('div');
    host.className = 'nwsb-fs';

    var acts = (o.actions || []).map(function (a, i) {
      return '<button class="nwsb-fs-btn' + (a.ghost ? ' ghost' : '') + '" data-i="' + i + '">' +
             String(a.label || 'OK') + '</button>';
    }).join('');

    host.innerHTML =
      '<div class="nwsb-fs-back"></div>' +
      '<button class="nwsb-fs-x" aria-label="Close">' +
        '<svg viewBox="0 0 24 24" fill="none"><path d="M6 6l12 12M18 6L6 18" stroke="#0b0b0b" stroke-width="2.2" stroke-linecap="round"/></svg>' +
      '</button>' +
      '<div class="nwsb-fs-scroll">' +
        (o.art ? '<div class="nwsb-fs-art"><img src="' + o.art + '" alt="" decoding="async"></div>' : '') +
        (o.head ? '<div class="nwsb-fs-head">' + o.head + '</div>' : '') +
        (o.sub ? '<div class="nwsb-fs-sub">' + o.sub + '</div>' : '') +
        (o.body ? '<div class="nwsb-fs-body">' + o.body + '</div>' : '') +
        '<div class="nwsb-fs-acts">' + acts + '</div>' +
      '</div>';

    document.body.appendChild(host);
    /* One frame between "in the document" and "visible", so the fade has
       something to fade from. */
    requestAnimationFrame(function () { host.classList.add('on'); });

    host.querySelector('.nwsb-fs-x').onclick = function () {
      close();
      if (typeof o.onDismiss === 'function') o.onDismiss();
    };
    host.querySelectorAll('.nwsb-fs-btn').forEach(function (b) {
      b.onclick = function () {
        var a = (o.actions || [])[+b.getAttribute('data-i')];
        if (a && a.keepOpen) { if (a.go) a.go(); return; }
        close();
        if (a && a.go) setTimeout(a.go, 120);
      };
    });
    return host;
  }
  window.nwsbSheet = open;

  /* ── The research proposal ────────────────────────────────────────
     Reproduced as written. It is the reason both stores exist, so it is
     the same text in both and it is not paraphrased anywhere. */
  var NOWS =
    '<div class="nwsb-fs-kicker">Research Proposal</div>' +
    '<p class="nwsb-fs-lead">Natural-Origin Word Science (NOWS): A New Framework for Exploring the Origin of Human Language</p>' +

    '<div class="nwsb-fs-h">Abstract</div>' +
    '<p>This research proposes a new hypothesis called Natural-Origin Word Science (NOWS). It investigates whether words across the world’s languages may share deeper natural sound patterns and structural relationships that are not fully explained by existing linguistic models.</p>' +
    '<p>The research introduces a methodology called <b>Shabdpathy</b> and a structured lexical framework named <b>Shabdakoshvinashabda</b> for analysing root sounds, word formation, semantic evolution, and possible universal linguistic relationships.</p>' +
    '<p>Rather than rejecting established historical linguistics, this study invites independent scientific testing of its hypotheses through comparative linguistics, phonetics, statistics, archaeology, anthropology, and computational language analysis.</p>' +
    '<p>The author requests independent academic evaluation by experts.</p>' +

    '<div class="nwsb-fs-h">Keywords</div>' +
    '<div class="nwsb-fs-keys">' +
      ['Natural-Origin Word Science', 'Shabdpathy', 'Universal Language',
       'Comparative Linguistics', 'Root Words', 'Human Language Origin',
       'Phonetics', 'Computational Linguistics']
        .map(function (k) { return '<span class="nwsb-fs-key">' + k + '</span>'; }).join('') +
    '</div>' +

    '<div class="nwsb-fs-h">Request</div>' +
    '<p>The author respectfully requests an independent scientific evaluation of this hypothesis by qualified experts. The purpose is not immediate acceptance, but objective testing using established academic methods.</p>' +

    '<div class="nwsb-fs-rule"></div>' +
    '<p class="nwsb-fs-note">Every word and every meaning in this store is described by its <b>sounds</b> — its phonetic origin under the framework above. It is a hypothesis offered for testing, not an established finding of historical linguistics, and it is not medical advice. Purchases unlock written work produced under that framework.</p>';

  /* ── The two stores ───────────────────────────────────────────────
     Same sheet, different art and different key, so agreeing in one does
     not silently agree for the other. */
  function storeSheet(which) {
    var isWord = which === 'word';
    var key = 'nwsb_terms_' + which;
    if (ls(key, '') === '1') return false;
    window.nwsbSheet({
      art: isWord ? 'assets/media/image/intro-words-9adb7eb3.webp' : 'assets/media/image/intro-meanings-0a159fa2.webp',
      head: isWord ? 'Words described by sound' : 'Meanings described by sound',
      sub: 'Read this before you buy. Agreeing records that you have.',
      body: NOWS,
      actions: [
        { label: 'I Agree · Continue', go: function () { lsSet(key, '1'); } },
        { label: 'Not Now', ghost: true, go: function () {
            if (isWord && typeof window.rmClose === 'function') window.rmClose();
            else if (!isWord && typeof window.msClose === 'function') window.msClose();
            else if (typeof window.closeSub === 'function') window.closeSub();
          } }
      ],
      onDismiss: function () {}
    });
    return true;
  }
  window.nwsbTermsFor = storeSheet;
  window.nwsbTermsAccepted = function (which) { return ls('nwsb_terms_' + which, '') === '1'; };

  /* Shown when the store is entered, not when the intro is looked at —
     the intro is a poster, entering is the intent. */
  function guard(name, fn) {
    var prev = window[fn];
    if (typeof prev !== 'function') return;
    window[fn] = function () {
      var r = prev.apply(this, arguments);
      setTimeout(function () { storeSheet(name); }, 420);
      return r;
    };
  }

  function boot() {
    guard('word', 'rmEnterFromIntro');
    guard('meaning', 'msEnterFromIntro');
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
