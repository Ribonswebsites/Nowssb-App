
  (function(){
    var TOTAL = 4, INTERVAL = 4000, cur = 0;
    var track = document.getElementById('storeBannerTrack');
    function goTo(i) {
      cur = (i + TOTAL) % TOTAL;
      track.style.transform = 'translateX(-' + (cur * 100) + '%)';
    }
    var timer = setInterval(function(){ goTo(cur + 1); }, INTERVAL);
    var wrap = document.getElementById('storeBannerWrap');
    var startX = 0;
    wrap.addEventListener('touchstart', function(e){ startX = e.touches[0].clientX; clearInterval(timer); }, {passive:true});
    wrap.addEventListener('touchend', function(e){
      var dx = e.changedTouches[0].clientX - startX;
      if (Math.abs(dx) > 36) goTo(cur + (dx < 0 ? 1 : -1));
      timer = setInterval(function(){ goTo(cur + 1); }, INTERVAL);
    }, {passive:true});
  })();
  