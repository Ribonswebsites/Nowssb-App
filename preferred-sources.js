(function () {
  'use strict';

  var fallbackUrl = 'https://www.google.com/preferences/source?q=nowssb.com';

  function setFallbackLinks() {
    document.querySelectorAll('[data-nowssb-preferred-source]').forEach(function (control) {
      if (control.tagName === 'A') control.href = fallbackUrl;
    });
  }

  function bindPreferredSource(preferredSource) {
    setFallbackLinks();

    if (!preferredSource || typeof preferredSource.addPreferredSource !== 'function') return;

    try {
      preferredSource.init({
        theme: 'light',
        lang: document.documentElement.lang || 'en'
      });
    } catch (error) {
      return;
    }

    document.querySelectorAll('[data-nowssb-preferred-source]').forEach(function (control) {
      control.addEventListener('click', function (event) {
        try {
          event.preventDefault();
          preferredSource.addPreferredSource();
        } catch (error) {
          window.location.href = fallbackUrl;
        }
      });
    });
  }

  setFallbackLinks();
  window.PREFERRED_SOURCE = window.PREFERRED_SOURCE || [];
  window.PREFERRED_SOURCE.push(bindPreferredSource);
})();
