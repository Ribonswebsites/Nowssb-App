/* ══════════════════════════════════════════════════════════════════════
   FOLLOW THE STEPS — the guide that runs through the hero's own rail

   A white disc with a black arrow sits at the bottom right of the hero.
   Tapping it does not open a page and does not push anything down the
   home: it takes over the rail the hero already has. The six video
   banners that slide in from the right are replaced by fifteen black
   cards that slide in from the right in exactly the same way, and tapping
   the disc again puts the banners back.

   That is the whole idea, and it is why this file is so small. The deck —
   the slide, the height, the swipe, the direction — belongs to
   app/js/part083.js and stays there. This file only ever says WHAT is
   passing through it, through the three hooks that file lends out
   (nwsbHeroCells, nwsbHeroAuto, nwsbHeroGo).

   Three rules the cards are built on:

     1. A step card is BLACK. No clip in it, no tablet round it, no glass.
        Everything else in that rail is footage inside a frame, so the one
        thing meant to be read is the one thing with nothing moving in it —
        and it wears the banners' own shape so it still belongs to the rail
        it is running through.

     2. It is exactly as tall as the hero card, because it IS a cell of the
        hero's deck and the deck takes the height of whatever is in it.
        Measured off cell 0 rather than guessed: the hero sizes itself from
        the space left between the fixed header and the nav.

     3. The auto-advance stops. A banner leaving on a timer is the rail
        doing its job; a step you are half-way through leaving on a timer
        is the guide fighting you. Two discs under the deck move it
        instead — previous and forward, bottom right.

   The Fashion home only, and this hero look only. The rail does not exist
   in the other two looks and the Normal home has no hero at all, so there
   is nothing for the disc to sit on or to take over.
   ══════════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  function haptic(ms) { try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) {} }

  /* ── The marks ────────────────────────────────────────────────────
     Drawn, not fetched. Fifteen cards is fifteen icons, and fifteen more
     image requests on a home that already carries a dozen clips is not a
     trade worth making for something this small. */
  var I = {
    play:   '<path d="M8 5.2 19 12 8 18.8z"/>',
    sun:    '<circle cx="12" cy="12" r="4.2"/><path d="M12 2.6v2.6M12 18.8v2.6M2.6 12h2.6M18.8 12h2.6M5.4 5.4l1.9 1.9M16.7 16.7l1.9 1.9M18.6 5.4l-1.9 1.9M7.3 16.7l-1.9 1.9"/>',
    clock:  '<circle cx="12" cy="12" r="8.6"/><path d="M12 6.8V12l3.4 2"/>',
    book:   '<path d="M4 5.4h6.4a2 2 0 0 1 2 2v11.2a2.4 2.4 0 0 0-2-1H4z"/><path d="M20 5.4h-6.4a2 2 0 0 0-2 2v11.2a2.4 2.4 0 0 1 2-1H20z"/>',
    bag:    '<path d="M4.4 7.6h15.2l-1.1 12.2a1.5 1.5 0 0 1-1.5 1.4H7a1.5 1.5 0 0 1-1.5-1.4z"/><path d="M8.7 10V6.6a3.3 3.3 0 0 1 6.6 0V10"/>',
    pages:  '<path d="M7.4 3.6h7l4 4v12.8h-11z"/><path d="M14.4 3.6v4h4"/><path d="M9.6 12.4h6M9.6 15.6h4"/>',
    sig:    '<path d="M3.6 16.6c3-.4 5-2.2 6.6-5.4 1.2-2.4 2-4.6 3.2-4.6 1 0 1.4 1 1 2.4-.5 1.8-2 3-3.4 3.6-1.4.6-2 1.4-1.6 2.2.4.8 1.8.9 3.2.4 1.6-.6 2.8-1.6 4-3"/><path d="M4 20h16"/>',
    sound:  '<path d="M11.4 4.6 6.8 8.6H3.6v6.8h3.2l4.6 4V4.6z"/><path d="M15.6 8.8a4.6 4.6 0 0 1 0 6.4M18.4 6a8.6 8.6 0 0 1 0 12"/>',
    atom:   '<circle cx="12" cy="12" r="2.4"/><ellipse cx="12" cy="12" rx="9" ry="4" /><ellipse cx="12" cy="12" rx="9" ry="4" transform="rotate(60 12 12)"/><ellipse cx="12" cy="12" rx="9" ry="4" transform="rotate(120 12 12)"/>',
    search: '<circle cx="10.6" cy="10.6" r="6.4"/><path d="M15.4 15.4 20.4 20.4"/>',
    heart:  '<path d="M12 20.4S3.8 15.2 3.8 9.6A4.4 4.4 0 0 1 12 7.2a4.4 4.4 0 0 1 8.2 2.4c0 5.6-8.2 10.8-8.2 10.8z"/>',
    chart:  '<path d="M4 20h16"/><path d="M6.8 20V13M11.4 20V7.2M16 20v-4.6"/>',
    people: '<circle cx="9.4" cy="8.4" r="3.4"/><path d="M3.4 19.4a6 6 0 0 1 12 0"/><path d="M16.4 5.4a3.4 3.4 0 0 1 0 6M17.6 19.4a6 6 0 0 0-1.6-4.1"/>',
    crown:  '<path d="M4 8.4l3.6 3.2L12 5.4l4.4 6.2L20 8.4l-1.6 9.2H5.6z"/><path d="M5.6 19.6h12.8"/>',
    spark:  '<path d="M12 3.4l1.9 5.3 5.3 1.9-5.3 1.9-1.9 5.3-1.9-5.3-5.3-1.9 5.3-1.9z"/><path d="M18.6 16.4l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8z"/>'
  };
  function ico(k) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" ' +
      'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + (I[k] || '') + '</svg>';
  }

  /* ── The steps ────────────────────────────────────────────────────
     Player first, then outward: what you practise with, what you practise
     from, where the words come from, what they do to you, and what the app
     becomes once it is yours. Every line describes something that is
     actually in the app — the copy is drawn from the pages themselves, so
     a step never promises a screen that is not there.

     `go` is optional. Where a step has a door, the card carries it; where
     it is describing something you are already looking at, it does not,
     because a button that scrolls you three inches is noise. */
  /* ── The steps ────────────────────────────────────────────────────
     Player first, then outward. Written SHORT on purpose: a card is the
     hero's own rectangle, which on this look is a landscape television
     about 230px tall, so a step is a lead of one line and three points of
     one line each. That is the constraint the length sets, and it is a
     good one — a step you can take in at a glance beats a step you have to
     scroll.

     `go` is optional. Where a step has a door the card carries it; where
     it is describing something you are already looking at, it does not. */
  var STEPS = [
    { i: 'play', t: 'The Word Player',
      lead: 'Every word opens the same way — one screen, five tabs, no scrolling.',
      pts: [
        ['Listen', 'The word plays, each syllable lighting as it sounds.'],
        ['Record', 'Speak it back and it is scored 0–100.'],
        ['Repeat', 'Count your reps — 3, 7 or 21.'],
        ['Meaning', 'The organ it targets and where the sound comes from.'],
        ['Guide', 'Mouth position, resonance, and the common mistake.']
      ] },

    { i: 'sun', t: "Today's Practice",
      lead: 'The card at the top of your home already knows the hour.',
      pts: [
        ['Five windows', 'Morning, midday, afternoon, evening, night.'],
        ['One tap starts it', 'The words queue up and the session runs itself.'],
        ['It closes itself', 'A healing sentence from everything you practised.']
      ] },

    { i: 'clock', t: 'My Routines',
      lead: 'Five slots you own — rename any of them, set any time.',
      pts: [
        ['The NOW badge', 'Marks whichever routine matches this hour.'],
        ['Words and Library', 'Build the list, tap + to add from what you own.'],
        ['History', 'Every session, its word count and how much you finished.']
      ] },

    { i: 'book', t: 'The Reader',
      lead: 'Meanings and eBooks in one place — the word science, read.',
      pts: [
        ['Any meaning', 'Origin, organ and frequency, laid out as a page.'],
        ['It keeps your place', 'So a long piece survives being put down.']
      ] },

    { i: 'bag', t: 'The NowssB Store',
      lead: 'Two libraries under one roof. You own what you buy.',
      pts: [
        ['Word Library', 'Sounds that heal, each with its organ and frequency.'],
        ['Meaning Library', 'The natural meaning under the dictionary one.'],
        ['Organ targeting', 'Shop by the part of the body, not by the word.']
      ],
      go: ['Enter the store', function () {
        var s = document.getElementById('sub-nowssb-store');
        if (s) s.classList.add('open');
        var iv = document.getElementById('nssIntroVid');
        if (iv) { iv.muted = true; try { iv.play().catch(function () {}); } catch (e) {} }
      }] },

    { i: 'pages', t: 'eBooks',
      lead: 'Where a meaning card gives the answer, an eBook gives the working.',
      pts: [
        ['Yours to keep', 'Bought once, read offline, kept in your library.'],
        ['Linked through', 'Every word in them opens in the player.']
      ],
      go: ['Open eBooks', function () { if (typeof window.ebSecOpen === 'function') window.ebSecOpen(); }] },

    { i: 'sig', t: 'The Signature',
      lead: 'Your name, in sound — the word science turned on the one word you answer to.',
      pts: [
        ['Your own frequency', 'What your name activates, and where it lands.'],
        ['Made once', 'Generated for you, and then it is yours.']
      ] },

    { i: 'sound', t: 'Sound Library',
      lead: 'Everything you own, arranged to be listened to.',
      pts: [
        ['Sentences', 'Healing sentences built from your words. Tap to play.'],
        ['Words', 'The phonetic breakdown and organ tag on every one.'],
        ['Straight through', 'Tap any word and it opens where you practise it.']
      ] },

    { i: 'atom', t: 'Word Science',
      lead: 'The system underneath all of it. Ten letters, ten organs.',
      pts: [
        ['N O W S B A N S I U', 'Every letter maps to a target in the body.'],
        ['Tap a letter', 'Its organ, the science, and the words that show it.']
      ] },

    { i: 'search', t: 'Real Meaning',
      lead: 'Any word, any language — its origin as a sound, before any dictionary.',
      pts: [
        ['Before the dictionary', 'What it meant as a sound, not as a definition.'],
        ['What it activates', 'The organ it reaches and the frequency it carries.'],
        ['How to say it', 'The correct pronunciation, in the same player.']
      ] },

    { i: 'heart', t: 'Personalised Healing',
      lead: 'Words chosen for a body, not for a vocabulary.',
      pts: [
        ['Choose your path', 'Female or male, ten health categories each.'],
        ['Every category is a set', 'Chosen for that organ system, not by topic.']
      ] },

    { i: 'chart', t: 'My Progress',
      lead: 'What the practice has added up to.',
      pts: [
        ['Streak and sessions', 'Days in a row, and everything you finished.'],
        ['Mastered words', 'Scored 90 or above three sessions running.'],
        ['Body map', 'Organs light as you practise the words that reach them.']
      ] },

    { i: 'people', t: 'NowssB Connect',
      lead: 'The social side — share the practice, find the people doing the same work.',
      pts: [
        ['Follow and react', 'Creators and practitioners further along.'],
        ['Your own space', 'A profile about the practice rather than about you.']
      ] },

    { i: 'crown', t: 'Subscription',
      lead: 'Every word and every frequency at once, instead of a piece at a time.',
      pts: [
        ['The full library', 'Both stores open, nothing held back.'],
        ['Your Edition', 'The card on your home shows the plan you are on.']
      ],
      go: ['See the plans', function () { if (window.SS && SS.open) SS.open('subscription'); }] },

    { i: 'spark', t: 'Make it yours',
      lead: 'The last step is the app itself. Almost nothing here is fixed.',
      pts: [
        ['Hero header', 'Three ways the top can look — this is one of them.'],
        ['Fashion Plus', 'Turns the app to film. The tiles and cards start moving.'],
        ['Your layout', 'Sections go on and off, and the home remembers it.']
      ],
      go: ['Change the hero header', function () { if (typeof window.stOpen === 'function') window.stOpen(); }] }
  ];

  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
                    .replace(/"/g, '&quot;');
  }

  /* ── A step, shaped like a banner ─────────────────────────────────
     Same outer element as .hs-ban and the same head — a disc with a mark,
     a light line and a heavy one — because it is running through the same
     rail and has to belong to it. What is under the head is where they
     part: a banner has a tablet with a clip in it, and this has words. */
  function cellHtml(s, i) {
    return '<div class="hs-cell fst-cell" data-i="' + (i + 1) + '">' +
             '<span class="hs-head">' +
               '<span class="hs-orb">' + ico(s.i) + '</span>' +
               '<span class="hs-head-txt">' +
                 '<span class="hs-head-h">Step ' + (i + 1) + ' of ' + STEPS.length + '</span>' +
                 '<span class="hs-head-t">' + esc(s.t) + '</span>' +
               '</span>' +
             '</span>' +
             '<div class="fst-body">' +
               '<p class="fst-lead">' + esc(s.lead) + '</p>' +
               '<div class="fst-pts">' +
                 s.pts.map(function (p) {
                   return '<div class="fst-pt">' +
                            '<span class="fst-pt-k">' + esc(p[0]) + '</span>' +
                            '<span class="fst-pt-v">' + esc(p[1]) + '</span>' +
                          '</div>';
                 }).join('') +
               '</div>' +
               (s.go ? '<button class="fst-go" onclick="window._fstGo(' + i + ')">' +
                         '<span>' + esc(s.go[0]) + '</span>' +
                         '<svg viewBox="0 0 24 24" fill="none"><path d="M5 12h14M12 5l7 7-7 7" ' +
                           'stroke="currentColor" stroke-width="1.9" stroke-linecap="round" ' +
                           'stroke-linejoin="round"/></svg>' +
                       '</button>'
                     : '') +
             '</div>' +
           '</div>';
  }
  function cellsHtml() { return STEPS.map(cellHtml).join(''); }

  window._fstGo = function (i) {
    var s = STEPS[i];
    if (!s || !s.go) return;
    haptic(18);
    try { s.go[1](); } catch (e) {}
  };

  /* ── The two discs ────────────────────────────────────────────────
     Under the deck, hard right, which is where a thumb already is. They
     exist only while the guide is on: the rail is meant to have no dots
     and no arrows, and that is still true of the banners. */
  function arrow(dir) {
    return '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
             '<path d="' + (dir < 0 ? 'M19 12H5M12 19l-7-7 7-7' : 'M5 12h14M12 5l7 7-7 7') + '" ' +
               'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
           '</svg>';
  }
  function navHtml() {
    return '<button class="fst-x" onclick="window.fstClose()" aria-label="Close the steps">' +
             '<svg viewBox="0 0 24 24" fill="none"><path d="M6 6l12 12M18 6L6 18" ' +
               'stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>' +
           '</button>' +
           '<div class="fst-count"><b id="fstNow">Start</b><span id="fstOf">' + STEPS.length + ' steps</span></div>' +
           '<div class="fst-bar"><i id="fstFill"></i></div>' +
           '<div class="fst-lbl" id="fstLbl">Follow the steps</div>' +
           '<button class="fst-arrow" id="fstPrev" onclick="window.fstStep(-1)" aria-label="Previous step">' + arrow(-1) + '</button>' +
           '<button class="fst-arrow fst-arrow-n" id="fstNext" onclick="window.fstStep(1)" aria-label="Next step">' + arrow(1) + '</button>';
  }

  function deck() { return document.getElementById('hsDeck'); }
  function heroCell() { return document.querySelector('#hsDeck .hs-hero-cell'); }
  function on() { return !!document.getElementById('fstNav'); }

  /* Cell 0 is the hero and is never one of the steps, so the deck's index
     and the step number differ by one. Everything the reader is shown is
     the step number; everything the deck is told is the index. */
  function paint() {
    if (!on()) return;
    var i = typeof window.nwsbHeroAt === 'function' ? window.nwsbHeroAt() : 0;
    var now = document.getElementById('fstNow'), lbl = document.getElementById('fstOf');
    /* Cell 0 is the title card, so it is not step one — it is what comes
       before step one, and the counter says so rather than lying. */
    if (now) now.textContent = i < 1 ? 'Start' : String(i);
    if (lbl) lbl.textContent = i < 1 ? STEPS.length + ' steps' : 'of ' + STEPS.length;
    var fill = document.getElementById('fstFill');
    if (fill) fill.style.width = ((i / STEPS.length) * 100) + '%';
    /* The name of what you are looking at, right where your thumb is about
       to press. On the title card it is what the guide is; from there on it
       is the step you are on. */
    var lbl = document.getElementById('fstLbl');
    if (lbl) lbl.textContent = i < 1 ? 'Follow the steps' : STEPS[i - 1].t;
    var p = document.getElementById('fstPrev'), n = document.getElementById('fstNext');
    if (p) p.disabled = i <= 0;
    if (n) n.disabled = i >= STEPS.length;
  }

  /* ── It runs itself ───────────────────────────────────────────────
     The rail auto-advances, so the guide does too — a card you have to
     press through is a slideshow, and this is meant to introduce the app
     while you look at it. Not part083's timer: that one is driven by a
     clip ending, and a step card has no clip. This one is its own, it
     wraps from the last step back to the title, and it gets out of the way
     for a while whenever a finger touches it — the point of pressing
     forward is to go at your own speed, and a card that then slid away
     under you would be the rail arguing. */
  var ROTATE = 7000, HOLD = 14000, spin = null, held = 0;

  function tick() {
    if (!on()) return;
    if (Date.now() < held) return;
    if (document.hidden) return;
    /* not while the home is not the screen you are on, and not while
       something is open over it */
    var home = document.getElementById('home');
    if (!home || !home.classList.contains('active')) return;
    if (document.querySelector('.sub-screen.open')) return;
    var d = deck();
    if (!d) return;
    var r = d.getBoundingClientRect();
    if (r.bottom < 40 || r.top > (window.innerHeight || 800) - 40) return;
    var i = window.nwsbHeroAt();
    window.nwsbHeroGo(i >= STEPS.length ? -STEPS.length : 1);   /* wraps to the title */
    paint();
  }
  function spinOn()  { if (!spin) spin = setInterval(tick, ROTATE); }
  function spinOff() { if (spin) { clearInterval(spin); spin = null; } }
  function hold()    { held = Date.now() + HOLD; }

  window.fstStep = function (d) {
    if (typeof window.nwsbHeroGo !== 'function') return;
    var i = window.nwsbHeroAt();
    if (i + d < 0 || i + d > STEPS.length) return;
    haptic(14);
    hold();
    window.nwsbHeroGo(d);
    paint();
    syncHeight();
  };

  /* ── The set becomes the title card ───────────────────────────────
     Tapping the disc does not jump straight to step one. The television's
     own screen changes first: the wordmark goes blonde, "Follow the steps"
     comes up under it, and the tagline, the word, the picture rail and the
     two buttons go. THAT is the guide's first card, and it is the hero
     itself — so the thing you tapped is the thing that answers.

     Injected into .hero-content, which is the screen inside the set. The
     hero's own furniture is hidden by CSS rather than removed: it is the
     app's real header, with a search that opens the explore sheet and a
     word on a timer, and taking it apart to put it back is how you lose
     one of them. */
  function title(on) {
    var hero = document.querySelector('#home .hero-section.hero-simple');
    if (!hero) return;
    var screen = hero.querySelector('.hero-content');
    if (!screen) return;
    var t = screen.querySelector(':scope > .fst-title');
    if (on && !t) {
      t = document.createElement('div');
      t.className = 'fst-title';
      t.innerHTML = '<div class="fst-title-b"><span class="b">Nowss</span><span class="t">B</span></div>' +
                    '<div class="fst-title-s">Follow the steps</div>';
      screen.appendChild(t);
    } else if (!on && t) {
      t.remove();
    }
    hero.classList.toggle('fst-title-on', !!on);
  }

  /* ── One length, and it is the hero's ─────────────────────────────
     A step card is exactly as tall as the hero card, because the hero card
     is the first card of the same guide — the two have to be one
     rectangle or the deck resizes the moment you press forward.

     offsetHeight, not the rectangle: a cell mid-slide is transformed, and
     getBoundingClientRect would hand back the scaled number. */
  function syncHeight() {
    var d = deck(), h = heroCell();
    if (!d || !h) return;
    var n = h.offsetHeight;
    if (n > 120) d.style.setProperty('--fst-h', n + 'px');

  }

  window.fstOpen = function () {
    if (typeof window.nwsbHeroCells !== 'function') return;
    var d = deck();
    if (!d) return;
    syncHeight();
    window.nwsbHeroAuto(false);
    if (!window.nwsbHeroCells(cellsHtml())) return;
    d.classList.add('fst-on');

    var nav = document.getElementById('fstNav');
    if (!nav) {
      nav = document.createElement('div');
      nav.id = 'fstNav';
      nav.className = 'fst-nav';
      nav.innerHTML = navHtml();
      d.parentNode.insertBefore(nav, d.nextSibling);
    }
    /* It stays on cell 0 — the set, now carrying the title. That IS the
       first thing the guide has to say, and forward is what starts it. */
    title(true);
    paint();
    hold();
    spinOn();
    syncHeight();
    haptic(24);
    var btn = document.getElementById('fstBtn');
    if (btn) btn.classList.add('on');
  };

  window.fstClose = function () {
    spinOff();
    var d = deck();
    if (d) d.classList.remove('fst-on');
    title(false);
    var nav = document.getElementById('fstNav');
    if (nav) nav.remove();
    if (typeof window.nwsbHeroCells === 'function') {
      window.nwsbHeroCells(null);                 /* the banners come back */
      window.nwsbHeroAuto(true);
    }
    var btn = document.getElementById('fstBtn');
    if (btn) btn.classList.remove('on');
  };

  window.fstToggle = function () { if (on()) window.fstClose(); else window.fstOpen(); };

  /* ── The disc on the hero ─────────────────────────────────────────
     Only on this look, and only on the Fashion home. The other two hero
     looks have no rail for the guide to run through, and the Normal home
     has no hero at all — a disc there would be a button with nothing
     behind it.

     Re-read on a heartbeat because the look can be switched from the Hero
     header page while this home is sitting underneath, and because
     switching to this look rebuilds the deck from scratch. */
  function mountBtn() {
    var hero = document.querySelector('#home .hero-section.hero-simple');
    var btn = document.getElementById('fstBtn');
    if (!hero) {
      if (btn) btn.remove();
      if (on()) { var nav = document.getElementById('fstNav'); if (nav) nav.remove(); }
      return false;
    }
    if (!btn) {
      btn = document.createElement('button');
      btn.id = 'fstBtn';
      btn.className = 'fst-btn';
      btn.type = 'button';
      btn.setAttribute('aria-label', 'How this app works — follow the steps');
      btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true">' +
          '<path d="M5 12h14M12 5l7 7-7 7" stroke="currentColor" stroke-width="2.3" ' +
            'stroke-linecap="round" stroke-linejoin="round"/></svg>';
      btn.addEventListener('click', function (e) {
        e.preventDefault(); e.stopPropagation();
        window.fstToggle();
      });
    }
    if (btn.parentNode !== hero) hero.appendChild(btn);
    btn.classList.toggle('on', on());
    return true;
  }

  window.addEventListener('resize', syncHeight);

  /* The rail can also be moved by a finger — part083.js's own swipe — and
     that changes which step is on without going through fstStep. The count
     and the two discs follow it rather than only following themselves. */
  setInterval(function () {
    mountBtn();
    if (on()) { paint(); syncHeight(); }
  }, 900);

  /* part083's own swipe moves the rail without coming through fstStep, and
     a finger on it means the same thing there as it does on an arrow. */
  document.addEventListener('touchend', function (e) {
    if (!on()) return;
    var d = deck();
    if (d && e.target && d.contains(e.target)) hold();
  }, { passive: true, capture: true });

  (function boot(n) {
    if (mountBtn()) return;
    if (n > 120) return;
    setTimeout(function () { boot(n + 1); }, 150);
  })(0);
})();
