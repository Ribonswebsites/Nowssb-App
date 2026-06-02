
(function() {
  // ── Carousel state ──
  var ispActive = 0, ispItems = null, ispDotEls = null, ISP_N = 10, _ispTimer = null;

  function ispCfg(s) {
    var a = Math.abs(s), d = s < 0 ? -1 : 1;
    if (a === 0) return {tx:0,     tz:200,  ry:0,      sc:1.00, op:1.00, zi:20};
    if (a === 1) return {tx:d*172, tz:-10,  ry:d*-28,  sc:0.78, op:0.68, zi:15};
    if (a === 2) return {tx:d*290, tz:-155, ry:d*-50,  sc:0.52, op:0.22, zi:10};
    return             {tx:0,     tz:-600, ry:0,      sc:0.10, op:0.00, zi:0};
  }

  function ispPaint() {
    if (!ispItems) return;
    ispItems.forEach(function(el, i) {
      var off = ((i - ispActive) % ISP_N + ISP_N) % ISP_N;
      var s = off > Math.floor(ISP_N / 2) ? off - ISP_N : off;
      var c = ispCfg(s);
      el.style.transform     = 'translateX('+c.tx+'px) translateZ('+c.tz+'px) rotateY('+c.ry+'deg) scale('+c.sc+')';
      el.style.opacity       = String(c.op);
      el.style.zIndex        = String(c.zi);
      el.style.pointerEvents = c.op > 0.05 ? 'auto' : 'none';
      el.style.borderColor   = (i === ispActive) ? '#e8d5a3' : 'rgba(255,255,255,0.08)';
    });
    if (ispDotEls) ispDotEls.forEach(function(d, i){ d.classList.toggle('active', i === ispActive); });
  }

  function ispGo(n) { ispActive = ((n % ISP_N) + ISP_N) % ISP_N; ispPaint(); }

  window.ispCarouselInit = function() {
    var carousel = document.getElementById('ispCarousel');
    var dotsEl   = document.getElementById('ispDots');
    if (!carousel || !dotsEl) return;
    ispItems  = Array.from(carousel.querySelectorAll('.ispci'));
    ispDotEls = Array.from(dotsEl.querySelectorAll('.ispcd'));
    ISP_N = ispItems.length;
    ispActive = 0;

    ispItems.forEach(function(el) {
      el.style.transition = 'none';
      el.style.transform  = 'translateX(0px) translateZ(-600px) rotateY(0deg) scale(0.1)';
      el.style.opacity    = '0';
    });
    void carousel.offsetHeight;
    requestAnimationFrame(function(){ requestAnimationFrame(function(){
      var T = 'transform 0.78s cubic-bezier(0.34,1.08,0.64,1),opacity 0.78s ease,border-color 0.3s ease';
      ispItems.forEach(function(el){ el.style.transition = T; });
      ispPaint();
    }); });

    var tx0 = 0;
    carousel.addEventListener('touchstart', function(e){ tx0 = e.touches[0].clientX; }, {passive:true});
    carousel.addEventListener('touchend',   function(e){
      var dx = e.changedTouches[0].clientX - tx0;
      if (Math.abs(dx) > 40) ispGo(ispActive + (dx < 0 ? 1 : -1));
    }, {passive:true});
    ispItems.forEach(function(el, i){
      el.addEventListener('click', function(e){ e.stopPropagation(); ispGo(i); });
    });

    // Auto-rotate — fast (1.1 s per card)
    clearInterval(_ispTimer);
    _ispTimer = setInterval(function(){ ispGo(ispActive + 1); }, 1100);
  };

  // ── Intro page enter / reset ──
  window.ispEnterFromIntro = function() {
    var intro = document.getElementById('ispIntroPage');
    var main  = document.getElementById('ispMainContent');
    if (intro) { intro.style.opacity = '0'; intro.style.pointerEvents = 'none'; setTimeout(function(){ intro.style.display = 'none'; }, 480); }
    if (main) {
      main.style.display = 'flex';
      requestAnimationFrame(function(){ ispCarouselInit(); });
      // Sync toggle state
      var tgl = document.getElementById('isp-toggle');
      if (tgl) {
        var knob = tgl.querySelector('.stgl-knob');
        var on = localStorage.getItem('nwsb_intros') !== 'off';
        tgl.style.background = on ? '#e8d5a3' : 'rgba(255,255,255,.12)';
        if (knob) { knob.style.left = on ? '24px' : '4px'; knob.style.background = on ? '#060c18' : 'rgba(255,255,255,.52)'; }
      }
    }
  };

  window.ispIntroReset = function() {
    clearInterval(_ispTimer); _ispTimer = null;
    var intro = document.getElementById('ispIntroPage');
    var main  = document.getElementById('ispMainContent');
    if (intro) { intro.style.display = 'flex'; intro.style.opacity = '1'; intro.style.pointerEvents = ''; }
    if (main)  { main.style.display = 'none'; }
    ispActive = 0; ispItems = null; ispDotEls = null;
    var sub = document.getElementById('isp-status-sub');
    if (sub) sub.textContent = localStorage.getItem('nwsb_intros') === 'off' ? 'Currently off' : 'Showing before each section';
  };

  // Called from settings row onclick — shows intro page fresh each time
  window.ispStart = function() { ispIntroReset(); };
  window.ispStop  = function() { clearInterval(_ispTimer); _ispTimer = null; };

  window.ispToggleIntros = function() {
    var on = localStorage.getItem('nwsb_intros') !== 'off';
    if (on) {
      document.getElementById('intro-warn-modal').style.display = 'flex';
    } else {
      localStorage.setItem('nwsb_intros', 'always');
      window._introSeen = {};
      var tgl = document.getElementById('isp-toggle');
      if (tgl) { var knob = tgl.querySelector('.stgl-knob'); tgl.style.background = '#e8d5a3'; if (knob) { knob.style.left = '24px'; knob.style.background = '#060c18'; } }
      var sub = document.getElementById('isp-status-sub');
      if (sub) sub.textContent = 'Showing before each section';
    }
  };
})();
