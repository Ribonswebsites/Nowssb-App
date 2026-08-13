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
  var STEPS = [
    { i: 'play', t: 'The Word Player',
      lead: 'Every word in NowssB opens the same way: one screen, a spinning disc, and five tabs across the bottom. No scrolling — everything is one tap.',
      pts: [
        ['Listen', 'The word plays. Each phonetic syllable lights up as its sound arrives. Male or female voice, top right.'],
        ['Record', 'Speak it back. Your pronunciation is scored 0–100, and you can play your own recording against the original.'],
        ['Repeat', 'Count your reps — 3, 7 or 21. Every tap registers one, and the bar fills to the end.'],
        ['Meaning', 'The organ this word targets, the healing benefit, the full meaning and where the sound comes from.'],
        ['Guide', 'Mouth position, where it should resonate in the body, the mistake most people make, and your tip.']
      ] },

    { i: 'sun', t: "Today's Practice",
      lead: 'The card at the top of your home already knows what time it is. It loads the routine that matches the hour and waits for one tap.',
      pts: [
        ['Morning · Midday · Afternoon · Evening · Night', 'Five windows through the day, and the card is always showing the one you are in.'],
        ['One tap starts it', 'The words for that routine queue up in the player, in order, and the session runs itself.'],
        ['It closes itself', 'When the last word finishes, a healing sentence built from everything you just practised plays automatically.']
      ] },

    { i: 'clock', t: 'My Routines',
      lead: 'Five slots you own. Rename any of them, set any time, and fill each with the words you want to practise in it.',
      pts: [
        ['The NOW badge', 'Marks whichever routine matches the current hour, so you never have to remember which one you are on.'],
        ['Words', 'The practice list for that routine — reorder it, cut it, grow it.'],
        ['Library', 'Everything you own. Tap + on any word to drop it into this routine.'],
        ['History', 'Every past session with its word count and how much of it you finished.']
      ] },

    { i: 'book', t: 'The Reader',
      lead: 'Meanings and eBooks in one place. Where the player is for your mouth, the Reader is for your eye — the same word science, read rather than spoken.',
      pts: [
        ['Open any meaning', 'Full origin, organ target and frequency, laid out as a page rather than a card.'],
        ['Read anywhere', 'It keeps your place, so a long piece survives being put down.']
      ] },

    { i: 'bag', t: 'The NowssB Store',
      lead: 'Two libraries under one roof. This is where words and meanings actually come from — you own what you buy, and owned words work everywhere else in the app.',
      pts: [
        ['Word Library', 'Sounds that heal, each with its organ target and its frequency.'],
        ['Meaning Library', 'Origins that were hidden — the natural meaning underneath the dictionary one.'],
        ['Organ targeting', 'Shop by the part of the body you are working on rather than by the word.']
      ],
      go: ['Enter the store', function () {
        var s = document.getElementById('sub-nowssb-store');
        if (s) s.classList.add('open');
        var iv = document.getElementById('nssIntroVid');
        if (iv) { iv.muted = true; try { iv.play().catch(function () {}); } catch (e) {} }
      }] },

    { i: 'pages', t: 'eBooks',
      lead: 'The long form. Where a meaning card gives you the answer, an eBook gives you the working — word science and sound healing at the length they actually need.',
      pts: [
        ['Yours to keep', 'Bought once, readable offline, and they stay in your library.'],
        ['Built on what you own', 'The words in them link straight through to the player.']
      ],
      go: ['Open eBooks', function () { if (typeof window.ebSecOpen === 'function') window.ebSecOpen(); }] },

    { i: 'sig', t: 'The Signature',
      lead: 'Your name, in sound. The Signature takes the word science and turns it on the one word you answer to.',
      pts: [
        ['Your own frequency', 'What your name activates, and where it lands in the body.'],
        ['Made once', 'It is generated for you and then it is yours — it does not change under you.']
      ] },

    { i: 'sound', t: 'Sound Library',
      lead: 'Everything you own, arranged to be listened to rather than studied.',
      pts: [
        ['Sentences', 'Healing sentences assembled from the words in your library. Tap to play.'],
        ['Words', 'Your full library with the phonetic breakdown and the organ tag on every one.'],
        ['Straight to the player', 'Tap any word here and it opens where you practise it.']
      ] },

    { i: 'atom', t: 'Word Science',
      lead: 'The system underneath all of it. N O W S B A N S I U — ten letters, and each one is an organ.',
      pts: [
        ['Tap a letter', 'Its organ target, the phonetic science behind it, and the words that demonstrate it.'],
        ['Why a word works', 'This is the part that explains the rest of the app rather than adding to it.']
      ] },

    { i: 'search', t: 'Real Meaning',
      lead: 'Type any word, from any language, and get its natural phonetic origin — what it meant as a sound, before a dictionary was written down.',
      pts: [
        ['Before the dictionary', 'The origin the word had as a sound rather than as a definition.'],
        ['What it activates', 'The organ it reaches and the healing frequency it carries.'],
        ['How to say it', 'The correct pronunciation, in the same player everything else uses.']
      ] },

    { i: 'heart', t: 'Personalised Healing',
      lead: 'Words chosen for a body rather than for a vocabulary. Pick your path and the app works backwards from the organ.',
      pts: [
        ['Choose your path', 'Female or male, each with ten targeted health categories.'],
        ['Every category is a set', 'The words in it were chosen for that organ system, not gathered by topic.']
      ] },

    { i: 'chart', t: 'My Progress',
      lead: 'What the practice has actually added up to. Five numbers and a body.',
      pts: [
        ['Streak', 'Consecutive days with at least one finished session.'],
        ['Sessions', 'Everything you have completed, not everything you have opened.'],
        ['Mastered words', 'Scored 90 or above three sessions running.'],
        ['Body map', 'Organs light up as you practise the words that reach them.'],
        ['Weekly grid', 'The last seven days, at a glance.']
      ] },

    { i: 'people', t: 'NowssB Connect',
      lead: 'The social side. Share the practice, post the journey, and find the people doing the same work.',
      pts: [
        ['Follow and react', 'Creators, practitioners, and anyone further along the same path.'],
        ['Your own space', 'A profile that is about the practice rather than about you.']
      ] },

    { i: 'crown', t: 'Subscription',
      lead: 'Every word and every frequency, unlocked at once — the alternative to buying the library a piece at a time.',
      pts: [
        ['The full library', 'Both stores open, with nothing held back behind a price.'],
        ['Your Edition', 'The card on your home always shows the plan you are actually on.']
      ],
      go: ['See the plans', function () { if (window.SS && SS.open) SS.open('subscription'); }] },

    { i: 'spark', t: 'Make it yours',
      lead: 'The last step is the app itself. Almost nothing on this home is fixed — the order, the look and the top of the page are all yours.',
      pts: [
        ['Hero header', 'Three ways the top can look: inside the television, full screen, or plain.'],
        ['Fashion Plus', 'Turns the app to film — the tiles, the practice card and every photographic background start moving.'],
        ['Your layout', 'Sections go on and off and change order, and the home remembers it.']
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
           '<div class="fst-count"><b id="fstNow">1</b><span>of ' + STEPS.length + '</span></div>' +
           '<div class="fst-bar"><i id="fstFill"></i></div>' +
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
    var step = i < 1 ? 0 : i - 1;
    var now = document.getElementById('fstNow');
    if (now) now.textContent = String(step + 1);
    var fill = document.getElementById('fstFill');
    if (fill) fill.style.width = (((step + 1) / STEPS.length) * 100) + '%';
    var p = document.getElementById('fstPrev'), n = document.getElementById('fstNext');
    /* Previous is disabled on the first step rather than walking back onto
       the hero card — the hero is not step zero, it is the thing the guide
       is about. */
    if (p) p.disabled = i <= 1;
    if (n) n.disabled = i >= STEPS.length;
  }

  window.fstStep = function (d) {
    if (typeof window.nwsbHeroGo !== 'function') return;
    var i = window.nwsbHeroAt();
    if (i + d < 1 || i + d > STEPS.length) return;
    haptic(14);
    window.nwsbHeroGo(d);
    paint();
    syncHeight();
  };

  /* ── One length for all fifteen ────────────────────────────────────
     Not measured off the hero. On this look the hero is a landscape
     television 229px tall and a step card of that height would be four
     lines and a scrollbar. It takes the rail's own length instead — the
     banner cells it is standing in for — and where that is shorter than
     the words need, the words win. A single number for all fifteen, so
     the deck does not resize under you as you step through it, which is
     what "the cards should be the same length" is actually asking for.

     The floor and the ceiling are in the stylesheet as a clamp; this only
     raises it when the banners themselves are taller, which is a thing
     only the live page knows. */
  function syncHeight() {
    var d = deck();
    if (!d) return;
    var ban = d.querySelector('.hs-ban');
    if (ban && ban.offsetHeight > 120) BAN_H = ban.offsetHeight;
    if (BAN_H) d.style.setProperty('--fst-ban', BAN_H + 'px');
  }
  var BAN_H = 0;

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
    /* Straight to the first step. Leaving it on cell 0 would mean tapping
       the disc appeared to do nothing — the hero is what was already there. */
    window.nwsbHeroGo(1);
    paint();
    syncHeight();
    haptic(24);
    var btn = document.getElementById('fstBtn');
    if (btn) btn.classList.add('on');
  };

  window.fstClose = function () {
    var d = deck();
    if (d) d.classList.remove('fst-on');
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

  (function boot(n) {
    if (mountBtn()) return;
    if (n > 120) return;
    setTimeout(function () { boot(n + 1); }, 150);
  })(0);
})();
