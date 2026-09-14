/* Start Today — 3-card horizontal carousel under Today's Practice
   (Fashion + Normal). Gold caps header twin of TODAY'S PRACTICE.
   Three equal swipe cards; no coach title / customise banner / overlays. */
(function () {
  'use strict';

  var PRACTICE_ART = './assets/coach/aarogya-personal-coach.png';
  var PRACTICE_VID = './assets/videos/09a50041065bdeab_grok_video_2026-07-30-14-54-07_ddjmrr.mp4';
  var PRACTICE_STILL = 'https://media.nowssb.com/migrated-images/4daad1a85b624fed_grok_image_1778052232385_qpdmgh.jpg';

  function openPractice() {
    if (typeof openPracticeIntro === 'function') {
      try { openPracticeIntro(); return; } catch (e) {}
    }
    if (typeof openSub === 'function') {
      try { openSub('practice'); return; } catch (e) {}
    }
  }

  function cardShell(innerHtml) {
    return (
      '<span class="st-today-tab">' +
        '<span class="st-today-screen">' + innerHtml + '</span>' +
        '<span class="st-today-chin" aria-hidden="true"></span>' +
      '</span>'
    );
  }

  function build(fashion) {
    var root = document.createElement('div');
    root.className = 'st-today-sec' + (fashion ? ' st-today-sec--fash' : ' st-today-sec--nm');
    root.setAttribute('data-st-today', '1');

    var head = document.createElement('div');
    head.className = 'st-today-head';
    head.innerHTML = '<div class="st-today-label">START TODAY</div>';
    root.appendChild(head);

    var rail = document.createElement('div');
    rail.className = 'st-today-rail';
    rail.setAttribute('aria-label', 'Start Today cards');

    // Card 1 — full practice artwork, contain (no crop), no overlays.
    var c1 = document.createElement('button');
    c1.type = 'button';
    c1.className = 'st-today-card';
    c1.innerHTML = cardShell(
      '<img class="st-today-art" src="' + PRACTICE_ART + '" alt="" decoding="async" loading="eager">'
    );
    c1.addEventListener('click', openPractice);
    rail.appendChild(c1);

    // Card 2 — twin of Today's Practice / NowssB Player (swirl + glass Enter).
    var c2 = document.createElement('button');
    c2.type = 'button';
    c2.className = 'st-today-card';
    var useVid = fashion && document.body.classList.contains('fashplus');
    var media = useVid
      ? '<video class="st-today-player-media" data-nwsb-auto muted loop playsinline preload="metadata" src="' + PRACTICE_VID + '"></video>'
      : '<img class="st-today-player-media" src="' + PRACTICE_STILL + '" alt="" decoding="async" loading="lazy">';
    c2.innerHTML = cardShell(
      media +
      '<span class="st-today-player-scrim" aria-hidden="true"></span>' +
      '<span class="st-today-enter tp-enter">' +
        '<span class="tp-enter-lbl">Enter</span>' +
        '<span class="tp-enter-go"><svg viewBox="0 0 12 12" fill="none"><path d="M2 6H10M7 3L10 6L7 9" stroke="#060c18" stroke-width="1.9" stroke-linecap="square"/></svg></span>' +
      '</span>'
    );
    c2.addEventListener('click', openPractice);
    rail.appendChild(c2);

    // Card 3 — healing kickoff copy.
    var c3 = document.createElement('button');
    c3.type = 'button';
    c3.className = 'st-today-card';
    c3.innerHTML = cardShell(
      '<span class="st-today-kick">' +
        '<span class="st-today-kick-title">Let\'s start your healing today</span>' +
        '<span class="st-today-kick-line">Start your streak today</span>' +
        '<span class="st-today-kick-line">Get your score</span>' +
        '<span class="st-today-kick-line">Share your score</span>' +
      '</span>'
    );
    c3.addEventListener('click', openPractice);
    rail.appendChild(c3);

    root.appendChild(rail);

    var dots = document.createElement('div');
    dots.className = 'st-today-dots';
    for (var i = 0; i < 3; i++) {
      var d = document.createElement('span');
      d.className = 'st-today-dot' + (i === 0 ? ' on' : '');
      dots.appendChild(d);
    }
    root.appendChild(dots);

    var idx = 0;
    var timer = setInterval(function () {
      if (!root.isConnected) { clearInterval(timer); return; }
      idx = (idx + 1) % 3;
      var card = rail.children[idx];
      if (card && card.scrollIntoView) {
        try {
          card.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
        } catch (e) {
          rail.scrollLeft = card.offsetLeft - 24;
        }
      }
      Array.prototype.forEach.call(dots.children, function (el, j) {
        el.classList.toggle('on', j === idx);
      });
    }, 4200);

    rail.addEventListener('scroll', function () {
      var mid = rail.scrollLeft + rail.clientWidth * 0.5;
      var best = 0, bestDist = 1e9;
      Array.prototype.forEach.call(rail.children, function (el, j) {
        var c = el.offsetLeft + el.offsetWidth * 0.5;
        var dist = Math.abs(c - mid);
        if (dist < bestDist) { bestDist = dist; best = j; }
      });
      idx = best;
      Array.prototype.forEach.call(dots.children, function (el, j) {
        el.classList.toggle('on', j === best);
      });
    }, { passive: true });

    return root;
  }

  function mount() {
    var targets = [
      { after: '#home .fash-plyr-wrap', fashion: true },
      { after: '#home-nm .nmh-plyr-wrap', fashion: false }
    ];
    targets.forEach(function (t) {
      var anchor = document.querySelector(t.after);
      if (!anchor || !anchor.parentNode) return;
      // Strip legacy coach carousel class if still present.
      Array.prototype.forEach.call(
        anchor.parentNode.querySelectorAll(':scope > .pc-coach-sec'),
        function (n) { if (n.parentNode) n.parentNode.removeChild(n); }
      );
      if (anchor.parentNode.querySelector(':scope > .st-today-sec')) return;
      var node = build(t.fashion);
      if (anchor.nextSibling) anchor.parentNode.insertBefore(node, anchor.nextSibling);
      else anchor.parentNode.appendChild(node);
    });
  }

  function cleanPracticeHero() {
    var title = document.getElementById('todayPracticeTitle');
    if (title) title.style.display = 'none';
    var sub = document.getElementById('todayPracticeSub');
    if (sub) sub.textContent = 'Your personalized word ritual for right now.';
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { mount(); cleanPracticeHero(); });
  } else {
    mount();
    cleanPracticeHero();
  }
  setTimeout(mount, 1200);
  setTimeout(mount, 3200);
})();
