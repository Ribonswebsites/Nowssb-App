/* Personal Coach rotating horizontal section — Normal + Fashion homes.
   Black Routine-style banner OUTSIDE the glass/tablet wrappers.
   1st card = AAROGYA Personal Coach artwork (no recompress). */
(function () {
  'use strict';

  var SLIDES = [
    {
      src: './assets/coach/aarogya-personal-coach.png',
      title: 'AAROGYA',
      sub: 'Immune System · Personal Coach'
    },
    {
      src: './assets/coach/personal_coach_hero.jpg',
      title: 'Personal Coach',
      sub: 'Guided word practice, for you'
    },
    {
      src: './assets/coach/coach-orb.png',
      title: 'Daily Ritual',
      sub: 'Continue your healing path'
    }
  ];

  function openCoach() {
    if (typeof openSub === 'function') {
      try { openSub('personal-coach'); return; } catch (e) {}
    }
    if (typeof window.nwsbOpenPersonalCoach === 'function') {
      try { window.nwsbOpenPersonalCoach(); return; } catch (e) {}
    }
  }

  function build(fashion) {
    var root = document.createElement('div');
    root.className = 'pc-coach-sec' + (fashion ? ' pc-coach-sec--fash' : ' pc-coach-sec--nm');
    root.setAttribute('data-pc-coach', '1');

    var head = document.createElement('div');
    head.className = 'pc-coach-head';
    head.innerHTML =
      '<div class="pc-coach-head-title">Personal Coach</div>' +
      '<div class="pc-coach-head-meta">' + SLIDES.length + ' cards</div>';
    root.appendChild(head);

    var ban = document.createElement('button');
    ban.type = 'button';
    ban.className = 'pc-coach-black-ban';
    ban.innerHTML =
      '<span class="pc-coach-black-ban-txt">Personal Coach<br>Customise your practice</span>' +
      '<span class="pc-coach-black-ban-go" aria-hidden="true">' +
        '<svg viewBox="0 0 24 24" width="22" height="22"><path d="M5 12h12M13 6l6 6-6 6" fill="none" stroke="#060c18" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>' +
      '</span>';
    ban.addEventListener('click', openCoach);
    root.appendChild(ban);

    var rail = document.createElement('div');
    rail.className = 'pc-coach-rail';
    rail.setAttribute('aria-label', 'Personal Coach cards');

    SLIDES.forEach(function (s, i) {
      var card = document.createElement('button');
      card.type = 'button';
      card.className = 'pc-coach-card';
      card.innerHTML =
        '<span class="pc-coach-tab">' +
          '<span class="pc-coach-screen">' +
            '<img src="' + s.src + '" alt="" decoding="async" loading="' + (i ? 'lazy' : 'eager') + '">' +
            '<span class="pc-coach-caption">' +
              '<span class="pc-coach-card-title">' + s.title + '</span>' +
              '<span class="pc-coach-card-sub">' + s.sub + '</span>' +
            '</span>' +
          '</span>' +
          '<span class="pc-coach-chin" aria-hidden="true"></span>' +
        '</span>';
      card.addEventListener('click', openCoach);
      rail.appendChild(card);
    });
    root.appendChild(rail);

    var dots = document.createElement('div');
    dots.className = 'pc-coach-dots';
    SLIDES.forEach(function (_, i) {
      var d = document.createElement('span');
      d.className = 'pc-coach-dot' + (i === 0 ? ' on' : '');
      dots.appendChild(d);
    });
    root.appendChild(dots);

    var idx = 0;
    var timer = setInterval(function () {
      if (!root.isConnected) { clearInterval(timer); return; }
      idx = (idx + 1) % SLIDES.length;
      var card = rail.children[idx];
      if (card && card.scrollIntoView) {
        try {
          card.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
        } catch (e) {
          rail.scrollLeft = card.offsetLeft - 24;
        }
      }
      Array.prototype.forEach.call(dots.children, function (el, i) {
        el.classList.toggle('on', i === idx);
      });
    }, 4200);

    rail.addEventListener('scroll', function () {
      var mid = rail.scrollLeft + rail.clientWidth * 0.5;
      var best = 0, bestDist = 1e9;
      Array.prototype.forEach.call(rail.children, function (el, i) {
        var c = el.offsetLeft + el.offsetWidth * 0.5;
        var d = Math.abs(c - mid);
        if (d < bestDist) { bestDist = d; best = i; }
      });
      idx = best;
      Array.prototype.forEach.call(dots.children, function (el, i) {
        el.classList.toggle('on', i === best);
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
      if (anchor.parentNode.querySelector(':scope > .pc-coach-sec')) return;
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
  // Registry re-order can run later — remount if stripped.
  setTimeout(mount, 1200);
  setTimeout(mount, 3200);
})();
