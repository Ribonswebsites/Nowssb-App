
  // Performance optimizations
  (function() {
    // 1. Pre-resolve critical domains
    const domains = ['res.cloudinary.com', 'fonts.googleapis.com', 'www.gstatic.com', 'firestore.googleapis.com'];
    domains.forEach(d => {
      const link = document.createElement('link');
      link.rel = 'preconnect';
      link.href = 'https://' + d;
      link.crossOrigin = 'anonymous';
      document.head.appendChild(link);
    });

    // 2. Performance monitoring
    window.addEventListener('load', () => {
      if ('performance' in window && 'getEntriesByType' in performance) {
        const paint = performance.getEntriesByType('paint');
        paint.forEach(entry => {
          console.log(`[Perf] ${entry.name}: ${entry.startTime.toFixed(2)}ms`);
        });
      }
    });
  })();
