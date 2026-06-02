
      (function(){
        var slides = [0,1,2,3].map(function(i){ return document.getElementById('rmSlide'+i); });
        var cur = 0;

        function rmBannerReset() {
          // Stop existing interval
          if (window._rmBannerInterval) { clearInterval(window._rmBannerInterval); window._rmBannerInterval = null; }
          // Reset all to hidden, show first
          slides.forEach(function(s){ s.style.transition = 'none'; s.style.opacity = '0'; });
          slides[0].style.opacity = '1';
          cur = 0;
          // Re-enable transitions after a tick then start cycling
          setTimeout(function(){
            slides.forEach(function(s){ s.style.transition = 'opacity 0.9s ease'; });
            window._rmBannerInterval = setInterval(function(){
              slides[cur].style.opacity = '0';
              cur = (cur + 1) % 4;
              slides[cur].style.opacity = '1';
            }, 4000);
          }, 50);
        }

        // Expose reset so openSub can call it
        window.rmBannerReset = rmBannerReset;

        // Run once on first parse
        rmBannerReset();
      })();
      