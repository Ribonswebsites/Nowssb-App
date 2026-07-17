
/* ── Intro: enter carousel from intro page ── */
window.beEnterFromIntro = function() {
  var intro = document.getElementById('beIntroPage');
  var main  = document.getElementById('beMainContent');
  if (intro) { intro.style.opacity = '0'; intro.style.pointerEvents = 'none'; setTimeout(function(){ intro.style.display = 'none'; }, 480); }
  if (main)  {
    main.style.display = 'flex';
    requestAnimationFrame(function(){
      if(typeof beCarouselInit==='function') beCarouselInit();
      beBannerRotate();
    });
  }
};

/* ── Reset intro each time the panel opens (called from SS._init renderMap) ── */
window.beIntroReset = function(){
  var intro = document.getElementById('beIntroPage');
  var main  = document.getElementById('beMainContent');
  if (intro) { intro.style.display='flex'; intro.style.opacity='1'; intro.style.pointerEvents=''; }
  if (main)  { main.style.display='none'; }
  beBgRotate();
};

/* ── Background cross-fade rotation (intro page — the two intro images) ── */
var _beBgTimer = null;
var _beBgFace  = 0;
function beBgRotate(){
  clearInterval(_beBgTimer);
  _beBgFace = 0;
  var b1 = document.getElementById('beBg1');
  var b2 = document.getElementById('beBg2');
  if (b1) b1.style.opacity='1';
  if (b2) b2.style.opacity='0';
  _beBgTimer = setInterval(function(){
    _beBgFace = 1 - _beBgFace;
    if (b1) b1.style.opacity = _beBgFace===0 ? '1' : '0';
    if (b2) b2.style.opacity = _beBgFace===1 ? '1' : '0';
  }, 3200);
}

/* ── Banner strip cross-fade (main content — the two banner images) ── */
var _beBannerTimer = null;
var _beBannerFace  = 0;
function beBannerRotate(){
  clearInterval(_beBannerTimer);
  _beBannerFace = 0;
  var b1 = document.getElementById('beBanner1');
  var b2 = document.getElementById('beBanner2');
  if (b1) b1.style.opacity='1';
  if (b2) b2.style.opacity='0';
  _beBannerTimer = setInterval(function(){
    _beBannerFace = 1 - _beBannerFace;
    if (b1) b1.style.opacity = _beBannerFace===0 ? '1' : '0';
    if (b2) b2.style.opacity = _beBannerFace===1 ? '1' : '0';
  }, 3200);
}

/* unused stubs kept so no ReferenceErrors from any lingering calls */
window.beFlipNow = function(){};
function beFlipStart(){
  var d1=document.getElementById('beFlipDot1'), d2=document.getElementById('beFlipDot2');
  if(d1){d1.style.width='20px';d1.style.background='#e8d5a3';}
  if(d2){d2.style.width='4px';d2.style.background='rgba(255,255,255,0.25)';}
  _beFlipTimer = setInterval(beFlipNow, 3800);
}

(function(){
  var beActive = 0, beItems = null, beDotEls = null;
  var BE_N = 3;
  var BE_STYLES = ['', 'fashion', 'neo'];
  var BE_LABELS = ['Fashion', 'Black Edition', 'Black Neo'];

  function beCfg(s) {
    var a = Math.abs(s), d = s < 0 ? -1 : 1;
    if (a === 0) return {tx: 0,       tz: 200,  ry: 0,      sc: 1.00, op: 1.00, zi: 20};
    if (a === 1) return {tx: d*172,   tz: -10,  ry: d*-28,  sc: 0.78, op: 0.68, zi: 15};
    if (a === 2) return {tx: d*290,   tz: -155, ry: d*-50,  sc: 0.52, op: 0.22, zi: 10};
    return             {tx: 0,       tz: -600, ry: 0,      sc: 0.10, op: 0.00, zi: 0};
  }

  function bePaint() {
    if (!beItems) return;
    beItems.forEach(function(el, i) {
      var off = ((i - beActive) % BE_N + BE_N) % BE_N;
      var s = off > Math.floor(BE_N / 2) ? off - BE_N : off;
      var c = beCfg(s);
      el.style.transform     = 'translateX('+c.tx+'px) translateZ('+c.tz+'px) rotateY('+c.ry+'deg) scale('+c.sc+')';
      el.style.opacity       = String(c.op);
      el.style.zIndex        = String(c.zi);
      el.style.pointerEvents = c.op > 0.05 ? 'auto' : 'none';
      el.style.borderColor   = (i === beActive) ? '#e8d5a3' : 'rgba(255,255,255,0.08)';
    });
    if (beDotEls) beDotEls.forEach(function(d, i){ d.classList.toggle('active', i === beActive); });
    var label = document.getElementById('beSelectedLabel');
    if (label) label.textContent = BE_LABELS[beActive];
    var btn = document.getElementById('beApplyBtn');
    if (btn) btn.textContent = 'APPLY — ' + BE_LABELS[beActive].toUpperCase();
  }

  function beGo(n) { beActive = ((n % BE_N) + BE_N) % BE_N; bePaint(); }

  window.beCarouselInit = function() {
    var carousel = document.getElementById('beCarousel');
    var dotsEl   = document.getElementById('beDots');
    if (!carousel || !dotsEl) return;
    beItems  = Array.from(carousel.querySelectorAll('.beci'));
    beDotEls = Array.from(dotsEl.querySelectorAll('.becd'));
    BE_N = beItems.length;

    // Start from current applied style
    var cur = localStorage.getItem('nwsb_be') || '';
    beActive = BE_STYLES.indexOf(cur);
    if (beActive < 0) beActive = 0;

    beItems.forEach(function(el) {
      el.style.transition = 'none';
      el.style.transform  = 'translateX(0px) translateZ(-600px) rotateY(0deg) scale(0.1)';
      el.style.opacity    = '0';
    });
    void carousel.offsetHeight;
    requestAnimationFrame(function(){
      requestAnimationFrame(function(){
        var T = 'transform 0.78s cubic-bezier(0.34,1.08,0.64,1),opacity 0.78s ease,border-color 0.3s ease,box-shadow 0.3s ease';
        beItems.forEach(function(el){ el.style.transition = T; });
        bePaint();
      });
    });

    // Touch swipe
    var tx0 = 0;
    carousel.addEventListener('touchstart', function(e){ tx0 = e.touches[0].clientX; }, {passive:true});
    carousel.addEventListener('touchend', function(e){
      var dx = e.changedTouches[0].clientX - tx0;
      if (Math.abs(dx) > 40) beGo(beActive + (dx < 0 ? 1 : -1));
    }, {passive:true});

    // Card click: first tap selects, second tap applies (or tap selected card applies)
    beItems.forEach(function(el, i){
      el.addEventListener('click', function(e){
        e.stopPropagation();
        if (i !== beActive) { beGo(i); }
        else { beApply(); }
      });
    });
  };

  window.beApply = function() {
    var style = BE_STYLES[beActive];
    if (typeof setBE === 'function') setBE(style);
    var btn = document.getElementById('beApplyBtn');
    if (btn) { btn.textContent = 'APPLIED!'; btn.style.background = '#fff'; setTimeout(function(){ btn.textContent = 'APPLY — '+BE_LABELS[beActive].toUpperCase(); btn.style.background = '#e8d5a3'; }, 1400); }
  };
})();
