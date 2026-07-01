
(function(){
'use strict';

/* ══════════════════════════════════════════
   STEPS — each targets ONE specific element
   The arrow draws from the card edge TO the element center
══════════════════════════════════════════ */
var STEPS = [
  {
    sel: '#todayPracticeCard',
    step: '1 / 6',
    title: "Today's Practice",
    body: "Detects your current time and loads your matching routine automatically. Tap this to start your session right now.",
    side: 'top'   // tooltip goes above element, arrow points down to it
  },
  {
    sel: '.hero-btn.hero-btn-p',   // Explore button specifically
    step: '2 / 6',
    title: "Explore",
    body: "Opens all sections of NowssB — your main navigation hub.",
    side: 'bottom'
  },
  {
    sel: '.hero-btn.hero-btn-s',   // Learn More button specifically
    step: '3 / 6',
    title: "Learn More",
    body: "Opens Shabdapathy — the science behind how correct word pronunciation creates healing frequency in the body.",
    side: 'bottom'
  },
  {
    sel: '.home-grid',
    step: '4 / 6',
    title: "Quick Access",
    body: "Sound Library · My Progress · Word Science · Profile. Tap any tile to jump directly into that section.",
    side: 'top'
  },
  {
    sel: '.health-journey-card',
    step: '5 / 6',
    title: "Health Journey",
    body: "Choose words by your health goal. Multiple male & female categories — Heart, Skin, Mental Clarity, Hormones, Bone, Sleep and more.",
    side: 'top',
    noRing: true   // large card — skip box, arrow-only pointer
  },
  {
    sel: '.word-search-section',
    step: '6 / 6',
    title: "Word Search",
    body: "Type any word from any language. Discover its natural phonetic origin — which organ it targets and its healing frequency.",
    side: 'top',
    noRing: true   // large section — skip box, arrow-only pointer
  }
];

/* ══ Sub-screen tips ══ */
var SUB = {
  'practice':{eye:'Word Player',h:'How to use the player',b:'Your Walkman session:',steps:['Tap Play — disc spins while audio plays. Tap again to pause.','M / F toggle (top right) — switches Male or Female voice anytime.','Listen tab: hears the word. Record tab: scores your pronunciation 0–100.','Repeat tab: counts your practice reps (3, 7, or 21).','Meaning tab: shows which organ this word targets and its healing benefit.','Guide tab: correct mouth position, resonance point, common mistake, tip.','When all words finish, a healing sentence plays automatically — session closing.']},
  'sound-library':{eye:'Sound Library',h:'Your word collection',b:'Three tabs:',steps:['Sentences — healing sentences built from the words you own.','Words — your full library with phonetic breakdown and organ tag.','Purchased — words acquired from The Word Atelier.']},
  'routines':{eye:'My Routines',h:'Build your daily ritual',b:'How it works:',steps:['5 slots — Morning, Midday, Afternoon, Evening, Night.','NOW badge — gold tag on the routine matching your current time.','Pencil icon — rename or change the time of any routine.','Words tab — your word list. Tap any word to open in the player.','Library tab — all words you own. Tap + to add to this routine.','Start Session — launches the player immediately with all routine words.']},
  'health-journey':{eye:'Health Journey',h:'Healing by body goal',b:'How to navigate:',steps:['Tap Male or Female — each has multiple targeted health categories for every body system.','Tap a category card to open it (e.g. Heart Health, Mental Clarity).','Words tab: words for that category. About tab: the organ science.','Start Session loads all category words straight into the player.']},
  'health-male':{eye:'Male Health Path',h:'Your Healing Categories',b:'Tap any card:',steps:['Fitness & Muscle · Heart Health · Skin & Glow · Gut Health','Liver Detox · Mental Clarity · Testosterone & Hormones','Immunity Boost · Lung & Breath · Kidney & Bladder','Bone & Joint · Sleep & Recovery · Hair Health · Eye Sight Health','Explorer & Courage · Power & Conquest · Glass Skin','Each opens a targeted word session for that body system.']},
  'health-female':{eye:'Female Health Path',h:'Your Healing Categories',b:'Tap any card:',steps:['Fitness & Tone · Heart Health · Skin & Glow · Gut Health','Liver Detox · Hormonal Balance · Mental Clarity · Hair Health','Immunity Boost · Anti-Aging · Dark Spot & Pigmentation','Bone & Joint · Glass Skin · Eye Sight Health','Explorer & Courage','Each opens a targeted word session for that body system.']},
  'my-progress':{eye:'My Progress',h:'Your healing tracker',b:'What you see:',steps:['Streak — consecutive days with at least one completed session.','Sessions — total practice sessions finished.','Mastered Words — scored 90+ in Record mode, three sessions in a row.','Body Map — organs light up as you practice words that target them.','Weekly grid — your activity over the past 7 days.']},
  'word-science':{eye:'Word Science',h:'The NOWSBANSIU letters',b:'How to explore:',steps:['Tap any letter chip — N O W S B A N S I U — to see the organ it targets.','Each panel holds articles on the phonetic science behind that letter.','Read to understand why mouth position and resonance create healing frequency.']},
  'real-meaning':{eye:'Real Meaning',h:'Word origin search',b:'How to use:',steps:['Type any word from any language into the search bar.','See its natural phonetic origin — before any dictionary.','Result shows which organ it activates and its healing frequency.','Tap Play to hear the correct pronunciation.']},
  'shabdapathy':{eye:'Shabdapathy',h:'The foundation science',b:'Inside this section:',steps:['Letter map — every letter of NOWSBANSIU mapped to its organ target.','Foundation articles — science connecting pronunciation to body effects.','Play buttons — hear demonstration words. Feel where the resonance sits.']},
  'profile':{eye:'Profile',h:'Your account settings',b:'What you can do:',steps:['Tap your avatar to upload a photo or choose an avatar.','Tap the pencil next to your name to change your display name.','Sound toggle, session duration, daily reminder time, voice preference.','Plan badge shows Free, Pro or Premium. Member since date shown below.']}
};

/* ══ DOM ══ */
var W   = document.getElementById('nwWelcome');
var wEy = document.getElementById('nwwEye');
var wH  = document.getElementById('nwwH');
var wS  = document.getElementById('nwwS');
var wBt = document.getElementById('nwwBtn');
var wSk = document.getElementById('nwwSkip');

var D   = [0,1,2,3].map(function(i){ return document.getElementById('nwD'+i); });
var ring= document.getElementById('nwRing');
var dot = document.getElementById('nwDot');
var cvs = document.getElementById('nwArrow');
var ctx;

var card  = document.getElementById('nwCard');
var cStep = document.getElementById('nwcStep');
var cTit  = document.getElementById('nwcTitle');
var cBod  = document.getElementById('nwcBody');
var cDots = document.getElementById('nwcDots');
var cNext = document.getElementById('nwcNext');

var sub     = document.getElementById('nwSub');
var subEye  = document.getElementById('nwsEye');
var subH    = document.getElementById('nwsH');
var subB    = document.getElementById('nwsB');
var subRows = document.getElementById('nwsRows');

var _step   = 0;
var _active = false;
var _subTimer = null;
var _subSeen  = {};
try { _subSeen = JSON.parse(localStorage.getItem('nwsb_sub')||'{}'); } catch(e){}

/* ══ Setup canvas — DPR-scaled so lines are crisp on retina ══ */
function initCanvas() {
  var dpr = Math.ceil(window.devicePixelRatio || 1);
  var W = window.innerWidth;
  var H = window.innerHeight;
  cvs.width  = W * dpr;
  cvs.height = H * dpr;
  cvs.style.width  = W + 'px';
  cvs.style.height = H + 'px';
  ctx = cvs.getContext('2d');
  ctx.scale(dpr, dpr);
}

/* ══ Dim 4 strips around element rect + ring ══ */
function spotOn(el) {
  var PAD = 8;
  var r   = el.getBoundingClientRect();
  var vw  = window.innerWidth;
  var vh  = window.innerHeight;
  var x   = Math.floor(r.left   - PAD);
  var y   = Math.floor(r.top    - PAD);
  var x2  = Math.ceil (r.right  + PAD);
  var y2  = Math.ceil (r.bottom + PAD);
  x  = Math.max(0,  x);
  y  = Math.max(0,  y);
  x2 = Math.min(vw, x2);
  y2 = Math.min(vh, y2);

  /* Auto-detect shape: circle for small square-ish elements (<=60px), rect otherwise */
  var elW = r.right - r.left;
  var elH = r.bottom - r.top;
  var ar  = elW > 0 ? elH / elW : 0;
  var isCircle = (ar > 0.72 && ar < 1.38) && elW <= 60;
  var br = isCircle ? '50%' : '14px';

  var s = 'position:fixed;background:rgba(2,5,12,.86);z-index:99981;pointer-events:all;';
  D[0].style.cssText = s+'top:0;left:0;right:0;height:'+y+'px;';
  D[1].style.cssText = s+'top:'+y2+'px;left:0;right:0;bottom:0;';
  D[2].style.cssText = s+'top:'+y+'px;left:0;width:'+x+'px;height:'+(y2-y)+'px;';
  D[3].style.cssText = s+'top:'+y+'px;left:'+x2+'px;right:0;height:'+(y2-y)+'px;';

  ring.style.cssText = 'position:fixed;z-index:99982;pointer-events:none;display:block;'+
    'left:'+x+'px;top:'+y+'px;width:'+(x2-x)+'px;height:'+(y2-y)+'px;'+
    'border-radius:'+br+';'+
    'border:2px solid rgba(232,213,163,0.62);'+
    'background:rgba(232,213,163,0.05);'+
    'backdrop-filter:blur(2px) saturate(1.3);'+
    '-webkit-backdrop-filter:blur(2px) saturate(1.3);'+
    'box-shadow:0 0 0 1px rgba(232,213,163,.1),0 0 30px 8px rgba(232,213,163,.24),'+
    'inset 0 1px 0 rgba(255,255,255,.14);';

  return { x:x, y:y, x2:x2, y2:y2,
           cx:(x+x2)/2, cy:(y+y2)/2, isCircle:isCircle };
}

function spotOff() {
  D.forEach(function(d){ d.style.cssText='display:none;'; });
  ring.style.display = 'none';
  if (ctx) ctx.clearRect(0, 0, window.innerWidth, window.innerHeight);
  cvs.classList.remove('on');
  var pulse = document.getElementById('nwPulse');
  if (pulse) pulse.classList.remove('on');
}

/* ══ Draw arrow line from card anchor to element ══ */
function drawArrow(from, to) {
  initCanvas();
  cvs.classList.add('on');
  ctx.clearRect(0, 0, window.innerWidth, window.innerHeight);

  var dx = to.x - from.x;
  var dy = to.y - from.y;
  var len = Math.sqrt(dx*dx + dy*dy);
  if (len < 12) return;

  var SRC_M = 8, DST_M = 15;
  var ux = dx/len, uy = dy/len;
  var sx = from.x + ux*SRC_M;
  var sy = from.y + uy*SRC_M;
  var ex = to.x   - ux*DST_M;
  var ey = to.y   - uy*DST_M;

  /* Dashed shaft */
  ctx.save();
  ctx.beginPath();
  ctx.setLineDash([4, 4]);
  ctx.lineCap    = 'round';
  ctx.strokeStyle = 'rgba(232,213,163,0.72)';
  ctx.lineWidth  = 1.6;
  ctx.moveTo(sx, sy);
  ctx.lineTo(ex, ey);
  ctx.stroke();
  ctx.restore();

  /* Solid arrowhead */
  ctx.save();
  ctx.beginPath();
  var AH    = 8;
  var angle = Math.atan2(dy, dx);
  ctx.moveTo(ex + ux*DST_M*0.1, ey + uy*DST_M*0.1);
  ctx.lineTo(ex - AH*Math.cos(angle - 0.48), ey - AH*Math.sin(angle - 0.48));
  ctx.lineTo(ex - AH*Math.cos(angle + 0.48), ey - AH*Math.sin(angle + 0.48));
  ctx.closePath();
  ctx.fillStyle = 'rgba(232,213,163,0.92)';
  ctx.fill();
  ctx.restore();
}

/* ══ Position card + draw arrow ══ */
function placeCard(spot, side) {
  var vw = window.innerWidth;
  var vh = window.innerHeight;

  card.style.display = 'block';
  card.classList.remove('on');

  /* Measure card after display:block forces reflow */
  var CW = card.offsetWidth  || 220;
  var CH = card.offsetHeight || 150;
  var GAP = 18;

  /* Decide card position: above or below the element */
  var cx, cy;
  if (side === 'bottom') {
    cx = Math.max(12, Math.min(vw-CW-12, spot.cx - CW/2));
    cy = spot.y2 + GAP;
    if (cy + CH > vh - 16) cy = spot.y - CH - GAP;
  } else {
    cx = Math.max(12, Math.min(vw-CW-12, spot.cx - CW/2));
    cy = spot.y - CH - GAP;
    if (cy < 12) cy = spot.y2 + GAP;
  }
  cy = Math.max(12, Math.min(vh-CH-16, cy));

  card.style.left = Math.round(cx) + 'px';
  card.style.top  = Math.round(cy) + 'px';

  /* Arrow: from card edge to nearest element edge */
  var fromX = Math.round(cx + CW/2);
  var fromY, toY;
  var cardAbove = (cy + CH) < spot.cy;
  var elH2 = spot.y2 - spot.y;
  if (cardAbove) {
    fromY = Math.round(cy + CH);
    toY   = Math.round(elH2 > 80 ? spot.y + 18 : spot.cy);
  } else {
    fromY = Math.round(cy);
    toY   = Math.round(elH2 > 80 ? spot.y2 - 18 : spot.cy);
  }
  /* Clamp toX within element bounds */
  var toX = Math.round(Math.max(spot.x + 10, Math.min(spot.x2 - 10, fromX)));

  drawArrow({ x:fromX, y:fromY }, { x:toX, y:toY });

  /* For noRing steps: show animated pulse at arrow tip */
  var pulse = document.getElementById('nwPulse');
  if (pulse) {
    if (spot.noRing) {
      pulse.style.left = toX + 'px';
      pulse.style.top  = toY + 'px';
      pulse.classList.add('on');
    } else {
      pulse.classList.remove('on');
    }
  }

  /* Fade card in */
  requestAnimationFrame(function(){
    card.classList.add('on');
  });
}

/* ══ Dots ══ */
function dots(cur) {
  var h = '';
  for (var i=0;i<STEPS.length;i++) h += '<div class="nwc-dot'+(i===cur?' on':'')+'"></div>';
  cDots.innerHTML = h;
}

/* ══ Scroll element into view, then show step ══ */
function scrollToEl(el, cb) {
  /* Find the scrollable ancestor */
  var scroller = null;
  var node = el.parentElement;
  while (node && node !== document.body) {
    var os = window.getComputedStyle(node).overflowY;
    if (os === 'auto' || os === 'scroll') { scroller = node; break; }
    node = node.parentElement;
  }

  var r   = el.getBoundingClientRect();
  var vh  = window.innerHeight;
  var TOP_MARGIN    = 90;  /* below nav bar */
  var BOTTOM_MARGIN = 120; /* above tooltip card area */
  var inView = r.top >= TOP_MARGIN && r.bottom <= vh - BOTTOM_MARGIN;
  if (inView) { requestAnimationFrame(cb); return; }

  /* Scroll so element sits in the upper-middle zone (leaves room for card below) */
  var ideal = r.top - vh * 0.3 + r.height / 2;
  if (scroller) {
    scroller.scrollTo({ top: Math.max(0, scroller.scrollTop + ideal), behavior: 'smooth' });
  } else {
    window.scrollTo({ top: Math.max(0, window.scrollY + ideal), behavior: 'smooth' });
  }
  /* 750ms: enough for smooth scroll on all devices, then RAF to let layout settle */
  setTimeout(function() { requestAnimationFrame(cb); }, 750);
}

/* ══ Show step ══ */
function show(idx) {
  _step = idx;
  var s = STEPS[idx];

  var el = document.querySelector(s.sel);
  if (!el) {
    if (idx+1 < STEPS.length) { show(idx+1); return; }
    done(); return;
  }
  var r = el.getBoundingClientRect();
  if (!r.width && !r.height) {
    if (idx+1 < STEPS.length) { show(idx+1); return; }
    done(); return;
  }

  /* First scroll element into view, THEN spotlight + card */
  scrollToEl(el, function() {
    var el2 = document.querySelector(s.sel); // re-query after scroll
    if (!el2) { if (idx+1 < STEPS.length) show(idx+1); else done(); return; }

    var spot;
    if (s.noRing) {
      /* Arrow-only: no dim strips, no box — just compute position from rect */
      var r2 = el2.getBoundingClientRect();
      var PAD = 8;
      var x  = Math.max(0, Math.floor(r2.left - PAD));
      var y  = Math.max(0, Math.floor(r2.top  - PAD));
      var x2 = Math.min(window.innerWidth,  Math.ceil(r2.right  + PAD));
      var y2 = Math.min(window.innerHeight, Math.ceil(r2.bottom + PAD));
      spot = { x:x, y:y, x2:x2, y2:y2, cx:(x+x2)/2, cy:(y+y2)/2, noRing:true };
      /* hide any leftover dim strips/ring from a previous step */
      D.forEach(function(d){ d.style.cssText='display:none;'; });
      ring.style.display = 'none';
    } else {
      spot = spotOn(el2);
    }

    cStep.textContent = s.step;
    cTit.textContent  = s.title;
    cBod.textContent  = s.body;
    cNext.textContent = (idx === STEPS.length-1) ? 'Done ✓' : 'Next →';
    dots(idx);

    placeCard(spot, s.side);
  });
}

/* ══ Welcome ══ */
function welcome(eyeText, hText, sText, btnText, btnFn, showSkip) {
  spotOff();
  card.classList.remove('on');
  card.style.display = 'none';

  wEy.textContent = eyeText;
  wH.textContent  = hText;
  wS.textContent  = sText;
  wBt.textContent = btnText;
  wBt.onclick     = btnFn;
  wSk.style.display = showSkip ? '' : 'none';
  wSk.onclick     = done;

  W.style.display = 'flex';
  requestAnimationFrame(function(){
    requestAnimationFrame(function(){ W.classList.add('vis'); });
  });
}

function hideWelcome(cb) {
  W.classList.remove('vis');
  setTimeout(function(){ W.style.display='none'; if(cb) cb(); }, 300);
}

/* ══ Public ══ */
function start() {
  if (_active) return;
  _active = true;
  welcome(
    'Welcome to NowssB',
    'Healing Through\nWord Vibration',
    'A quick tour shows you exactly how everything works — tap by tap.',
    'Show Me How →',
    function(){ hideWelcome(function(){ show(0); }); },
    true
  );
}

window.nwNext = function() {
  card.classList.remove('on');
  card.style.display = 'none';
  spotOff(); // clear immediately so old ring doesn't flicker during scroll
  setTimeout(function(){
    if (_step+1 < STEPS.length) {
      show(_step+1);
    } else {
      done();
    }
  }, 80);
};

window.nwSkip = function() { done(); };

function done() {
  _active = false;
  spotOff();
  card.classList.remove('on');
  card.style.display = 'none';

  /* Done card */
  welcome(
    'Ready',
    "You're All Set",
    "Tap Today's Practice to start your first session. Your words are waiting.",
    "Let's Go →",
    function(){
      hideWelcome();
    },
    false
  );

  try { localStorage.setItem('nwsb_done','1'); } catch(e){}
}

/* ══ Sub-screen tips ══ */
function subShow(key) {
  var d = SUB[key];
  if (!d || _subSeen[key]) return;
  // Don't show nwSub bottom sheet if this screen already has a pgGuide (in any part).
  // A pgGuide exists for a screen when window._PG[key] is defined (part022 + part025),
  // or the screen is in the pg-active list — either way, never double-up.
  var pgScreens = window._pgActiveScreens || ['practice','routines','routine-detail','health-journey','health-male','health-female','health-category','sound-library','my-progress'];
  if (pgScreens.indexOf(key) !== -1) return;
  if (window._PG && window._PG[key]) return;
  subEye.textContent = d.eye;
  subH.textContent   = d.h;
  subB.textContent   = d.b;
  var html = '';
  d.steps.forEach(function(t,i){
    html += '<div class="nws-row"><div class="nws-num">'+(i+1)+'</div><div class="nws-txt">'+t+'</div></div>';
  });
  subRows.innerHTML = html;
  if (_subTimer) clearTimeout(_subTimer);
  _subTimer = setTimeout(function(){ sub.classList.add('on'); }, 700);
}

window.nwSubClose = function() {
  sub.classList.remove('on');
  /* Mark seen */
  var eyeText = subEye.textContent;
  Object.keys(SUB).forEach(function(k){ if(SUB[k].eye===eyeText) _subSeen[k]=1; });
  try { localStorage.setItem('nwsb_sub',JSON.stringify(_subSeen)); } catch(e){}
};

/* ══ Hook openSub ══ */
(function patchOpenSubForTutorial() {
  var _origOpen = window.openSub;
  if (!_origOpen) { setTimeout(patchOpenSubForTutorial, 200); return; }
  window.openSub = function(id) {
    _origOpen.apply(this, arguments);
    setTimeout(function(){ subShow(id); }, 800);
  };
})();

/* ══ Hook goTo → manage fashion-home-active + fire tour on home ══ */
var _origGoTo = window.goTo;
window.goTo = function(dest) {
  var fromSplash = (currentScreen === 'splash');
  if (dest !== 'home') {
    document.body.classList.remove('fashion-home-active');
  } else {
    // Add fashion-home-active BEFORE the original goTo runs setBg(), so the
    // black-edition #appBg image is already in place from the first paint.
    document.body.classList.add('fashion-home-active');
  }

  // ── SPLASH → FASHION HOME: opaque-cover transition (kills the black flash) ──
  // The flash happens because the splash cross-fades out while the black-edition
  // #appBg image fades in behind it — for ~0.5s the user sees the black image
  // bleeding through the dissolving white splash. Fix: keep the splash fully
  // OPAQUE and on TOP while the home + black appBg build behind it, then hard-cut
  // the splash away once everything is settled. No cross-fade = nothing can bleed.
  if (fromSplash && dest === 'home') {
    var _splashEl = document.getElementById('splash');
    var _homeEl   = document.getElementById('home');
    // Pin splash above everything, solid, no fade
    if (_splashEl) {
      _splashEl.style.zIndex = '10000';
      _splashEl.style.transition = 'none';
      _splashEl.style.opacity = '1';
    }
    // Build home fully (opacity 1, no transition) hidden behind the splash cover
    if (_homeEl) {
      _homeEl.style.transition = 'none';
      _homeEl.style.opacity = '1';
    }
    if (_origGoTo) _origGoTo.apply(this, [dest]);
    // _origGoTo adds .exit (fade) to the splash — undo it, keep splash solid on top
    if (_splashEl) {
      _splashEl.classList.remove('exit');
      _splashEl.style.opacity = '1';
    }
    // Once home + black appBg have painted (700ms), fade the splash cover away to
    // reveal the already-settled home. Nothing flashes because it's already there.
    setTimeout(function() {
      if (_splashEl) {
        _splashEl.style.transition = 'opacity 0.45s ease';
        _splashEl.style.opacity = '0';
        setTimeout(function() {
          _splashEl.classList.remove('active', 'exit');
          _splashEl.style.zIndex = '';
          _splashEl.style.transition = '';
          _splashEl.style.opacity = '';
        }, 480);
      }
      if (_homeEl) {
        _homeEl.style.transition = '';
        _homeEl.style.opacity = '';
      }
    }, 700);
  } else {
    if (_origGoTo) _origGoTo.apply(this, [dest]);
  }

  if (dest === 'home') {
    setTimeout(function(){
      try { if (!localStorage.getItem('nwsb_done')) start(); }
      catch(e){ start(); }
    }, 1000);
  }
};

/* ══ On load fallback ══ */
setTimeout(function(){
  try {
    if (localStorage.getItem('nwsb_done')) return;
    var h = document.getElementById('home');
    if (h && h.classList.contains('active')) start();
  } catch(e){}
}, 1600);

/* back-compat */
window.nwCMstart = start;
window.tutStart  = start;
window.cmStart   = start;

})();
