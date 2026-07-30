/* ══════════════════════════════════════════════════════════
   VIDEO BANNERS — one place that says which clip goes above what.

   Placing these by hand would have meant editing a dozen spots across a
   9k-line document and then finding them all again next time one moves.
   The table below is the whole feature: a selector, a clip, and whether
   the banner goes before that element or at the top of it.

   Everything is injected once and guarded by a marker class, so a section
   that gets re-rendered by its own file does not end up with two banners.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var V = 'https://res.cloudinary.com/eenvubod/video/upload/';

  /* before: the banner is inserted as the element's previous sibling.
     top:    the banner is inserted as the element's first child. */
  var PLACE = [
    // Above the NowssB Store section, on both homes
    { before: '#home-nm .nss-store-trigger',      vid: V + 'v1785402930/grok_video_2026-07-30-14-43-38_olejrw.mp4' },
    { before: '#home .nss-store-trigger',          vid: V + 'v1785402930/grok_video_2026-07-30-14-43-38_olejrw.mp4' },

    // Above Personalised Healing — the clip's subject sits left, so the
    // copy and the arrow go right, the same way the Reader section reads.
    { before: '#home-nm .health-journey-card',     vid: V + 'v1785402957/grok_video_2026-07-30-14-42-14_ihmhi7.mp4', gender: 1 },
    { before: '#home .health-journey-card',        vid: V + 'v1785402957/grok_video_2026-07-30-14-42-14_ihmhi7.mp4', gender: 1 },

    // Above NowssB Connect
    { before: '#home-nm .nmh-connect-sec',         vid: V + 'v1785402935/grok_video_2026-07-30-14-43-48_lfrvok.mp4' },
    { before: '#home .fash-connect-wrap',          vid: V + 'v1785402935/grok_video_2026-07-30-14-43-48_lfrvok.mp4' },

    // Trending
    { before: '#home-nm #nmh-trending-section',    vid: V + 'v1785402931/grok_video_2026-07-30-14-43-11_gjhfww.mp4' },
    { before: '#home .fash-trend-wrap',            vid: V + 'v1785402931/grok_video_2026-07-30-14-43-11_gjhfww.mp4' },

    // Meaning — a different clip in each place it appears
    { before: '#home-nm .krm-section',             vid: V + 'v1785402917/grok_video_2026-07-30-14-44-14_cqj4qc.mp4' },
    { before: '#home #fashMeaningSearchWrap',      vid: V + 'v1785406062/grok_video_2026-07-30-15-36-37_mrnmll.mp4' },
    { top:    '#msMeaningBody',                    vid: V + 'v1785406069/grok_video_2026-07-30-15-36-38_uq9l5d.mp4' },

    // Today's Offer page, Quick Access page, eBooks store
    { top:    '#offersMainContent',                vid: V + 'v1785402975/grok_video_2026-07-30-14-43-34_lqppzd.mp4' },
    { top:    '#qaMainContent',                    vid: V + 'v1785402945/grok_video_2026-07-30-14-43-00_ft8o8u.mp4' },
    { top:    '#ebBody',                           vid: V + 'v1785406073/grok_video_2026-07-30-15-35-40_xwm1ei.mp4' }
  ];

  /* The subscription clip was the same one in several places. The two home
     banners keep a clip of their own; the plan banner on the subscription
     page and the Edition cards each get their own. */
  var SWAP = [
    { sel: '#home-nm .nmh-vb-tall video, #home .fash-vb-tall video',
      vid: V + 'v1785403503/grok_video_2026-07-30-14-44-37_jufhyx.mp4' },
    { sel: '.ss-plan-banner-vid',
      vid: V + 'v1785406071/grok_video_2026-07-30-15-36-45_ihftsp.mp4' },
    { sel: '.fsec-video',
      vid: V + 'v1785407198/grok_video_2026-07-30-15-55-42_onadht.mp4' }
  ];

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
    });
  }

  function makeBanner(spec) {
    var d = document.createElement('div');
    d.className = 'vb-banner';
    var html = '<video data-nwsb-auto muted loop playsinline preload="none" src="' + spec.vid + '"></video>';
    if (spec.gender) {
      /* Two words over their own halves of the clip and a bare Enter — no
         panel behind any of it, so the video is not covered. Each label
         opens Personalised Healing with that side already highlighted,
         using the page's own applyHealthGenderHighlight. */
      html +=
        '<button class="vb-g vb-g-f" onclick="event.stopPropagation();vbGender(\'female\')">Female</button>' +
        '<button class="vb-g vb-g-m" onclick="event.stopPropagation();vbGender(\'male\')">Male</button>' +
        '<span class="vb-cta vb-cta-mid" onclick="event.stopPropagation();vbGender()">' +
          '<span class="vb-cta-lbl">Enter</span>' +
          '<span class="vb-go"><svg viewBox="0 0 12 12" fill="none">' +
            '<path d="M2 6H10M7 3L10 6L7 9" stroke="#060c18" stroke-width="1.9" stroke-linecap="square"/>' +
          '</svg></span>' +
        '</span>';
    } else if (spec.cta) {
      html += '<span class="vb-rule"></span>' +
        '<div class="vb-txt">' +
          '<span class="vb-hello">' + esc(spec.cta.hello) + '</span>' +
          '<span class="vb-name">' + esc(spec.cta.name) + '</span>' +
          (spec.cta.sub ? '<span class="vb-sub">' + esc(spec.cta.sub) + '</span>' : '') +
          '<span class="vb-cta"><span class="vb-cta-lbl">Enter</span>' +
            '<span class="vb-go"><svg viewBox="0 0 12 12" fill="none">' +
              '<path d="M2 6H10M7 3L10 6L7 9" stroke="#060c18" stroke-width="1.9" stroke-linecap="square"/>' +
            '</svg></span>' +
          '</span>' +
        '</div>';
    }
    d.innerHTML = html;
    return d;
  }

  window.vbGender = function (g) {
    try { if (g) window._userGender = g; } catch (e) {}
    if (window.openSub) window.openSub('health-journey');
    if (g && window.applyHealthGenderHighlight) {
      setTimeout(function () { window.applyHealthGenderHighlight(g); }, 220);
    }
    try { if (navigator.vibrate) navigator.vibrate(28); } catch (e) {}
  };

  function place() {
    var added = false;
    PLACE.forEach(function (spec, i) {
      var key = 'vb' + i;
      var sel = spec.before || spec.top;
      var host = document.querySelector(sel);
      if (!host) return;
      /* One banner per target, however many times this runs. */
      var scope = spec.before ? host.parentNode : host;
      if (!scope || scope.querySelector(':scope > .vb-banner[data-vb="' + key + '"]')) return;
      var el = makeBanner(spec);
      el.setAttribute('data-vb', key);
      if (spec.before) host.parentNode.insertBefore(el, host);
      else host.insertBefore(el, host.firstChild);
      added = true;
    });
    /* The layout editor reorders the registered children of each home, and
       every banner is registered alongside the section it introduces — so a
       newly injected one has to be run through that pass or it stays where
       it landed while its section moves away. */
    if (added && window.hlApplyLayout) { try { window.hlApplyLayout(); } catch (e) {} }

    SWAP.forEach(function (s) {
      document.querySelectorAll(s.sel).forEach(function (v) {
        if (v.tagName !== 'VIDEO') return;
        if (v.getAttribute('src') === s.vid) return;
        v.setAttribute('src', s.vid);
        try { v.load(); } catch (e) {}
      });
    });
  }
  window.vbPlace = place;

  function boot() {
    place();
    /* Several of these sections are rendered by their own files after first
       paint; a couple of late passes catch the ones that were not there yet. */
    setTimeout(place, 1500);
    setTimeout(place, 3500);
    setTimeout(place, 6000);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
