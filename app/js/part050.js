/* ══════════════════════════════════════════════════════════════════════════
   NOWSSB CONNECT — CREATE (Instagram-style content creation, neumorphism)
   Post · Story · Reel · Highlight. Images are read as data URLs (the same
   pattern the app already uses for KYC uploads) and stored in localStorage so
   created content persists on the device and renders in the profile / stories.
   ────────────────────────────────────────────────────────────────────────── */
(function () {
  var KEYS = { post: 'nwsb_my_posts', story: 'nwsb_my_stories', reel: 'nwsb_my_reels', highlight: 'nwsb_my_highlights' };

  function load(k) { try { return JSON.parse(localStorage.getItem(k) || '[]'); } catch (e) { return []; } }
  function save(k, arr) { try { localStorage.setItem(k, JSON.stringify(arr)); } catch (e) {} }
  window.nwsbMyPosts = function () { return load(KEYS.post); };

  // ── toast ──
  function toast(msg) {
    var t = document.createElement('div');
    t.className = 'nwsb-toast';
    t.textContent = msg;
    document.body.appendChild(t);
    requestAnimationFrame(function () { t.classList.add('show'); });
    setTimeout(function () { t.classList.remove('show'); setTimeout(function () { t.remove(); }, 300); }, 2200);
  }

  // ── build the create sheet + hidden file input once ──
  function build() {
    if (document.getElementById('nwsbCreateSheet')) return;

    var file = document.createElement('input');
    file.type = 'file'; file.id = 'nwsbCreateFile'; file.style.display = 'none';
    file.accept = 'image/*';
    file.addEventListener('change', onFile);
    document.body.appendChild(file);

    var opt = function (mode, title, sub, svg) {
      return '<button class="nwsb-cr-opt" onclick="_nwsbPick(\'' + mode + '\')">' +
        '<span class="nwsb-cr-ic">' + svg + '</span>' +
        '<span class="nwsb-cr-tx"><b>' + title + '</b><i>' + sub + '</i></span>' +
        '<svg class="nwsb-cr-chev" width="8" height="14" viewBox="0 0 8 14" fill="none"><path d="M1 1l6 6-6 6" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>' +
        '</button>';
    };
    var sheet = document.createElement('div');
    sheet.id = 'nwsbCreateSheet';
    sheet.className = 'nwsb-cr-wrap';
    sheet.innerHTML =
      '<div class="nwsb-cr-scrim" onclick="nwsbCloseCreate()"></div>' +
      '<div class="nwsb-cr-sheet">' +
        '<div class="nwsb-cr-grip"></div>' +
        '<div class="nwsb-cr-title">Create</div>' +
        opt('post', 'Post', 'Share a photo to your grid',
          '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><rect x="3" y="3" width="18" height="18" rx="4"/><circle cx="8.5" cy="8.5" r="1.8"/><path d="M21 16l-5-5L5 21"/></svg>') +
        opt('story', 'Story', 'Add to your story · 24h',
          '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="12" cy="12" r="9" stroke-dasharray="3 3"/><path d="M12 8v8M8 12h8"/></svg>') +
        opt('reel', 'Reel', 'Share a short video / clip',
          '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><rect x="3" y="3" width="18" height="18" rx="4"/><path d="M3 8h18M8 3l2.5 5M14 3l2.5 5M10 12l5 3-5 3z"/></svg>') +
        opt('highlight', 'Highlight', 'Save a memory to your profile',
          '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="12" cy="12" r="9"/><path d="M12 7l1.6 3.2 3.4.5-2.5 2.4.6 3.4L12 15.4 8.9 17l.6-3.4L7 11.2l3.4-.5z"/></svg>') +
        '<button class="nwsb-cr-cancel" onclick="nwsbCloseCreate()">Cancel</button>' +
      '</div>';
    document.body.appendChild(sheet);

    // prominent Create FAB on the profile screen
    var prof = document.getElementById('sub-ig-profile');
    if (prof && !document.getElementById('nwsbCreateFab')) {
      var fab = document.createElement('button');
      fab.id = 'nwsbCreateFab'; fab.className = 'nwsb-cr-fab'; fab.setAttribute('aria-label', 'Create');
      fab.onclick = window.nwsbOpenCreate;
      fab.innerHTML = '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>';
      prof.appendChild(fab);
    }
  }

  window.nwsbOpenCreate = function () { build(); var s = document.getElementById('nwsbCreateSheet'); if (s) { s.classList.add('open'); } };
  window.nwsbCloseCreate = function () { var s = document.getElementById('nwsbCreateSheet'); if (s) s.classList.remove('open'); };

  var _mode = 'post';
  window._nwsbPick = function (mode) {
    _mode = mode;
    var f = document.getElementById('nwsbCreateFile');
    if (!f) return;
    f.value = '';
    f.setAttribute('accept', mode === 'reel' ? 'image/*,video/*' : 'image/*');
    // posts support multiple images (a carousel)
    if (mode === 'post') f.setAttribute('multiple', 'multiple'); else f.removeAttribute('multiple');
    f._append = false;
    f.click();
  };

  function readAll(files, cb) {
    var items = new Array(files.length), left = files.length;
    [].forEach.call(files, function (f, i) {
      var rd = new FileReader();
      rd.onload = function () { items[i] = { img: rd.result, video: /^data:video/.test(String(rd.result)) }; if (--left === 0) cb(items.filter(Boolean)); };
      rd.readAsDataURL(f);
    });
  }

  function onFile(e) {
    var files = e.target.files;
    if (!files || !files.length) return;
    var append = e.target._append;
    readAll(files, function (items) {
      if (append && _composeItems) { _composeItems = _composeItems.concat(items); renderPreview(); }
      else { nwsbCloseCreate(); openCompose(_mode, items); }
    });
  }

  // ── Instagram-style compose editor ─────────────────────────────────────────
  var _composeItems = null, _ratio = 'sq'; // sq = 1:1, pt = 4:5 (full length)
  var _composeOv = null;

  function renderPreview() {
    if (!_composeOv) return;
    var prev = _composeOv.querySelector('.nwsb-cp-preview');
    prev.className = 'nwsb-cp-preview ' + _ratio;
    var slides = _composeItems.map(function (it) {
      return it.video
        ? '<div class="nwsb-cp-slide"><video src="' + it.img + '" muted autoplay loop playsinline></video></div>'
        : '<div class="nwsb-cp-slide" style="background-image:url(' + it.img + ')"></div>';
    }).join('');
    var dots = _composeItems.length > 1
      ? '<div class="nwsb-cp-dots">' + _composeItems.map(function (_, i) { return '<span class="' + (i === 0 ? 'on' : '') + '"></span>'; }).join('') + '</div>' : '';
    var multi = _composeItems.length > 1 ? '<div class="nwsb-cp-count">1/' + _composeItems.length + '</div>' : '';
    prev.innerHTML =
      '<div class="nwsb-cp-track">' + slides + '</div>' +
      '<button class="nwsb-cp-ratio" aria-label="Aspect ratio"><svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.8"><path d="M15 3H5a2 2 0 0 0-2 2v10M9 21h10a2 2 0 0 0 2-2V9"/></svg></button>' +
      (_mode === 'post' ? '<button class="nwsb-cp-addmore" aria-label="Add more">+</button>' : '') +
      multi + dots;
    // wire ratio + add-more + carousel dots
    prev.querySelector('.nwsb-cp-ratio').onclick = function () { _ratio = _ratio === 'sq' ? 'pt' : 'sq'; renderPreview(); };
    var addm = prev.querySelector('.nwsb-cp-addmore');
    if (addm) addm.onclick = function () { var f = document.getElementById('nwsbCreateFile'); f.value = ''; f.setAttribute('multiple', 'multiple'); f._append = true; f.click(); };
    var track = prev.querySelector('.nwsb-cp-track'), cnt = prev.querySelector('.nwsb-cp-count'), dwrap = prev.querySelector('.nwsb-cp-dots');
    if (_composeItems.length > 1) track.addEventListener('scroll', function () {
      var i = Math.round(track.scrollLeft / track.clientWidth);
      if (cnt) cnt.textContent = (i + 1) + '/' + _composeItems.length;
      if (dwrap) [].forEach.call(dwrap.children, function (d, j) { d.className = j === i ? 'on' : ''; });
    }, { passive: true });
  }

  function openCompose(mode, items) {
    var old = document.getElementById('nwsbCompose'); if (old) old.remove();
    _composeItems = items; _ratio = 'sq';
    var label = mode.charAt(0).toUpperCase() + mode.slice(1);
    var row = function (svg, tx) {
      return '<div class="nwsb-cp-field nwsb-cp-opt"><span class="nwsb-cp-ic">' + svg + '</span><span class="nwsb-cp-toggle-tx">' + tx + '</span>' +
        '<svg class="nwsb-cp-chev2" width="8" height="14" viewBox="0 0 8 14" fill="none" stroke="rgba(0,0,0,0.3)" stroke-width="1.6"><path d="M1 1l6 6-6 6"/></svg></div>';
    };
    var ov = document.createElement('div');
    ov.id = 'nwsbCompose'; ov.className = 'nwsb-cp-wrap'; _composeOv = ov;
    ov.innerHTML =
      '<div class="nwsb-cp-head">' +
        '<button class="nwsb-cp-x" aria-label="Back">&#10005;</button>' +
        '<div class="nwsb-cp-title">New ' + label + '</div>' +
        '<button class="nwsb-cp-share">Share</button>' +
      '</div>' +
      '<div class="nwsb-cp-body">' +
        '<div class="nwsb-cp-preview sq"></div>' +
        '<textarea class="nwsb-cp-caption" maxlength="2200" placeholder="Write a caption…"></textarea>' +
        '<div class="nwsb-cp-field"><span class="nwsb-cp-ic">' +
          '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M12 21s-7-5.5-7-11a7 7 0 0114 0c0 5.5-7 11-7 11z"/><circle cx="12" cy="10" r="2.5"/></svg>' +
          '</span><input class="nwsb-cp-loc" type="text" placeholder="Add location"></div>' +
        row('<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="9" cy="8" r="3.2"/><path d="M3.5 19c.4-3 2.8-5 5.5-5s5.1 2 5.5 5"/><path d="M17 8h4M19 6v4"/></svg>', 'Tag people') +
        row('<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M9 18V6l10-2v12"/><circle cx="6" cy="18" r="3"/><circle cx="16" cy="16" r="3"/></svg>', 'Add music') +
        '<div class="nwsb-cp-field nwsb-cp-toggle"><span class="nwsb-cp-ic">' +
          '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M4 4h16v13H5.2L4 18z"/></svg>' +
          '</span><span class="nwsb-cp-toggle-tx">Also share to your Story</span><span class="nwsb-cp-sw" data-on="0"></span></div>' +
        row('<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1l2-1.6-2-3.4-2.3 1a7 7 0 0 0-1.7-1l-.3-2.5H9.4l-.3 2.5a7 7 0 0 0-1.7 1l-2.3-1-2 3.4 2 1.6a7 7 0 0 0 0 2l-2 1.6 2 3.4 2.3-1a7 7 0 0 0 1.7 1l.3 2.5h5.2l.3-2.5a7 7 0 0 0 1.7-1l2.3 1 2-3.4-2-1.6c.1-.3.1-.7.1-1z"/></svg>', 'Advanced settings') +
        '<div class="nwsb-cp-footer">NowssB <span>Connect</span></div>' +
      '</div>';
    document.body.appendChild(ov);
    renderPreview();
    requestAnimationFrame(function () { ov.classList.add('open'); });

    ov.querySelector('.nwsb-cp-x').onclick = function () { closeCompose(); };
    var sw = ov.querySelector('.nwsb-cp-sw');
    sw.onclick = function () { sw.setAttribute('data-on', sw.getAttribute('data-on') === '1' ? '0' : '1'); };
    ov.querySelector('.nwsb-cp-share').onclick = function () {
      var cap = ov.querySelector('.nwsb-cp-caption').value.trim();
      var loc = ov.querySelector('.nwsb-cp-loc').value.trim();
      var imgs = _composeItems.map(function (i) { return i.img; });
      var isVid = !!(_composeItems[0] && _composeItems[0].video);
      var item = { img: imgs[0], imgs: imgs, ratio: _ratio, caption: cap, location: loc, ts: Date.now(), video: isVid };
      var key = KEYS[mode] || KEYS.post;
      var arr = load(key); arr.unshift(item);
      var cap2 = (mode === 'post' ? 60 : 30); if (arr.length > cap2) arr = arr.slice(0, cap2);
      save(key, arr);
      if (sw.getAttribute('data-on') === '1' && mode !== 'story') {
        var st = load(KEYS.story); st.unshift({ img: imgs[0], caption: cap, ts: Date.now(), video: isVid });
        save(KEYS.story, st.slice(0, 30));
      }
      closeCompose();
      toast(label + ' shared ✓');
      refreshProfile();
    };
  }
  function closeCompose() { if (_composeOv) { _composeOv.classList.remove('open'); var o = _composeOv; setTimeout(function () { o.remove(); }, 300); _composeOv = null; _composeItems = null; } }

  // ── render created posts into the profile grid + wire create triggers ──
  function injectGrid() {
    var IG = window.IG;
    if (!IG || !IG._currentProfile || !IG._currentProfile.self) return;
    var g = document.getElementById('ig-prof-grid');
    if (!g) return;
    var posts = load(KEYS.post);
    var createTile = '<div class="ig-tile nwsb-cr-tile" onclick="nwsbOpenCreate()">' +
      '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg></div>';
    if (posts.length) {
      g.innerHTML = createTile + posts.map(function (p, i) {
        var badge = p.video
          ? '<svg class="nwsb-tile-badge" width="16" height="16" viewBox="0 0 24 24" fill="#fff"><path d="M8 5v14l11-7z"/></svg>'
          : ((p.imgs && p.imgs.length > 1) ? '<svg class="nwsb-tile-badge" width="15" height="15" viewBox="0 0 24 24" fill="#fff"><path d="M7 3h11a3 3 0 0 1 3 3v11h-2V6a1 1 0 0 0-1-1H7z"/><rect x="3" y="7" width="13" height="13" rx="2"/></svg>' : '');
        return '<div class="ig-tile" onclick="nwsbViewMyPost(' + i + ')"><img decoding="async" loading="lazy" src="' + p.img + '">' + badge + '</div>';
      }).join('');
    } else {
      // keep the "Share Photos" empty state but make it open Create
      var empty = g.querySelector('.nwsb-empty-grid');
      if (empty) { empty.style.cursor = 'pointer'; empty.onclick = window.nwsbOpenCreate; }
    }
  }

  function refreshProfile() {
    var IG = window.IG;
    if (IG && typeof IG.profTab === 'function' && IG._currentProfile && IG._currentProfile.self) {
      IG.profTab('grid');       // our wrapper re-injects
    }
    syncStoryRing();
  }

  // latest story shows on the "Your Story" ring in the feed
  function syncStoryRing() {
    var stories = load(KEYS.story);
    if (!stories.length) return;
    var ring = document.querySelector('.nwsbf-you .nwsbf-story-av');
    if (ring) { ring.classList.remove('nwsbf-story-init'); ring.textContent = ''; ring.style.backgroundImage = 'url(' + stories[0].img + ')'; }
    var you = document.querySelector('.nwsbf-you'); if (you) you.classList.add('nwsb-has-story');
  }

  // ── simple viewer for a created post (image + delete) ──
  window.nwsbViewMyPost = function (i) {
    var posts = load(KEYS.post); var p = posts[i]; if (!p) return;
    var ov = document.createElement('div'); ov.className = 'nwsb-pv-wrap';
    var meta = '';
    if (p.location) meta += '<div class="nwsb-pv-loc">📍 ' + p.location + '</div>';
    if (p.caption) meta += '<div class="nwsb-pv-cap">' + p.caption + '</div>';
    var imgs = (p.imgs && p.imgs.length) ? p.imgs : [p.img];
    var media = p.video
      ? '<video src="' + p.img + '" controls autoplay loop playsinline class="nwsb-pv-media"></video>'
      : (imgs.length > 1
          ? '<div class="nwsb-pv-carousel">' + imgs.map(function (s) { return '<img src="' + s + '" class="nwsb-pv-media">'; }).join('') + '</div>'
          : '<img src="' + p.img + '" class="nwsb-pv-media">');
    ov.innerHTML =
      '<div class="nwsb-pv-scrim" onclick="this.parentNode.remove()"></div>' +
      '<div class="nwsb-pv-card">' +
        media +
        (meta ? '<div class="nwsb-pv-meta">' + meta + '</div>' : '') +
        '<div class="nwsb-pv-row">' +
          '<button class="nwsb-pv-del" data-i="' + i + '">Delete</button>' +
          '<button class="nwsb-pv-close" onclick="this.closest(\'.nwsb-pv-wrap\').remove()">Close</button>' +
        '</div>' +
      '</div>';
    document.body.appendChild(ov);
    ov.querySelector('.nwsb-pv-del').addEventListener('click', function () {
      var arr = load(KEYS.post); arr.splice(i, 1); save(KEYS.post, arr);
      ov.remove(); refreshProfile();
    });
  };

  // ── hook the IG profile tab render so our posts appear ──
  function hookIG() {
    var IG = window.IG;
    if (!IG || IG._nwsbCrHooked) return false;
    if (typeof IG.profTab !== 'function') return false;
    IG._nwsbCrHooked = true;
    var orig = IG.profTab;
    IG.profTab = function (t) {
      var r = orig.apply(this, arguments);
      if (t === 'grid') { try { injectGrid(); } catch (e) {} }
      return r;
    };
    return true;
  }
  // IG loads before this file, but hook defensively
  if (!hookIG()) {
    var tries = 0, iv = setInterval(function () { if (hookIG() || ++tries > 40) clearInterval(iv); }, 150);
  }

  // delegate clicks on the "New" highlight (rendered dynamically) to Create
  document.addEventListener('click', function (e) {
    var t = e.target;
    var newHl = t.closest && t.closest('.ig-hl-circle.new');
    if (newHl) { e.preventDefault(); e.stopPropagation(); nwsbOpenCreate(); }
  }, true);

  if (document.readyState !== 'loading') build();
  else document.addEventListener('DOMContentLoaded', build);
})();
