/* NowssB editorial banners — three editorial spreads placed at distinct
   mid-page positions on both home surfaces. The uploaded square campaign art
   remains intact; the banner supplies the magazine-like framing and copy. */
(function () {
  'use strict';

  var banners = [
    {
      key: 'connect',
      eyebrow: 'NOWSSB / CONNECT',
      title: 'SOUND\nTHAT\nFINDS YOU',
      body: 'A daily language for the way you listen, move and meet the world.',
      note: 'CONNECT · WORDS · PRESENCE',
      tint: 'paper',
      images: [
        'file_00000000156082109bcff739c6d80a7a.png',
        'file_00000000b56c820aade81ceee1d06ccf.png',
        'file_00000000813081f594f7597ac46978d6.png'
      ]
    },
    {
      key: 'science',
      eyebrow: 'NOWSSB / WORD SCIENCE',
      title: 'WORDS\nTHAT\nMOVE YOU',
      body: 'Discover the sound beneath every word and let meaning become practice.',
      note: 'SPEAK · FEEL · TRANSFORM',
      tint: 'blue',
      images: [
        'file_00000000b77c82119c4127cc603420a8.png',
        'file_000000005f1081f497a9edaf32d38a24.png',
        'file_00000000098c82468fa2a0dbcee6b344.png'
      ]
    },
    {
      key: 'healing',
      eyebrow: 'NOWSSB / THE DAILY RITUAL',
      title: 'HEALING\nIN A\nNEW FORM',
      body: 'Pronunciation, sound and stillness — carried with you wherever you are.',
      note: 'LISTEN · PRACTICE · HEAL',
      tint: 'rose',
      images: [
        'file_000000005f8881f48b6867d03c79a021.png',
        'file_0000000019a0820ca12b3d08e77712e0.png',
        'file_00000000fdd48246890602f65eafaab8.png'
      ]
    }
,
    {
      key: 'stories',
      eyebrow: 'NOWSSB / EDITORIAL DISCOVERY',
      title: 'STORIES\nTHAT\nFIND YOU',
      body: 'A living collection of words, images and rituals that meet you at exactly the right moment.',
      note: 'READ · LISTEN · DISCOVER',
      tint: 'paper',
      images: [
        'file_00000000156082109bcff739c6d80a7a.png',
        'file_00000000b77c82119c4127cc603420a8.png',
        'file_000000005f8881f48b6867d03c79a021.png'
      ]
    }
  ];

  function esc(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'})[c];
    });
  }

  function render(data, index) {
    var art = data.images.map(function (src, i) {
      return '<div class="nwsb-editorial-art nwsb-editorial-art-' + (i + 1) + '">' +
        '<img src="' + esc(src) + '" alt="NowssB ' + esc(data.key) + ' campaign image ' + (i + 1) + '" loading="lazy" decoding="async"></div>';
    }).join('');
    var title = esc(data.title).replace(/\\n/g, '<br>');
    var el = document.createElement('section');
    el.className = 'nwsb-editorial-banner nwsb-editorial-' + esc(data.tint);
    el.setAttribute('data-editorial-banner', data.key);
    el.setAttribute('aria-label', data.title.replace(/\\n/g, ' '));
    el.innerHTML =
      '<div class="nwsb-editorial-topline"><span>' + esc(data.eyebrow) + '</span><span>0' + (index + 1) + ' / 04</span></div>' +
      '<div class="nwsb-editorial-layout">' +
        '<div class="nwsb-editorial-copy"><div class="nwsb-editorial-title">' + title + '</div>' +
          '<div class="nwsb-editorial-body">' + esc(data.body) + '</div>' +
          '<div class="nwsb-editorial-rule"></div><div class="nwsb-editorial-note">' + esc(data.note) + '</div></div>' +
        '<div class="nwsb-editorial-mosaic">' + art + '</div>' +
      '</div>' +
      '<div class="nwsb-editorial-footer"><span>NOWSSB.</span><span>THE NEW FASHION TREND OF MEDITATION</span><span>ENTER →</span></div>';
    return el;
  }

  function place(hostSelector, anchorSelector, data, index) {
    var host = document.querySelector(hostSelector);
    var anchor = host && host.querySelector(anchorSelector);
    if (!anchor || anchor.parentNode.querySelector('[data-editorial-banner="' + data.key + '"]')) return;
    anchor.insertAdjacentElement('afterend', render(data, index));
  }

  function mount() {
    /* Each surface gets the same three campaigns in a different vertical
       rhythm, so they feel discovered rather than stacked as one gallery. */
    place('#home-nm .nmh-wrap', '.nmh-supplied-essentials', banners[1], 1);
    place('#home-nm .nmh-wrap', '.nmh-supplied-essentials', banners[3], 3);
    place('#home-nm .nmh-wrap', '.nmh-trend-wrap', banners[2], 2);
    place('#home-nm .nmh-wrap', '.nmh-store-wrap', banners[0], 0);
    place('#home .home-body', '.fash-plyr-wrap', banners[2], 2);
    place('#home .home-body', '.fash-plyr-wrap', banners[3], 3);
    place('#home .home-body', '.fash-trend-wrap', banners[0], 0);
    place('#home .home-body', '.nwsb-enter-pager', banners[1], 1);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount);
  else mount();
  window.nwsbMountEditorialBanners = mount;
})();
