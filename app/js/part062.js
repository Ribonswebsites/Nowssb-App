/* ══════════════════════════════════════════════════════════
   SET AS YOU LIKE — home layout editor.

   Both homes are one long scrolling column of sections and banners. This
   file lets the user decide the order of that column and which pieces are
   in it at all, for the Normal home and the Fashion home independently.

   Two things never move, because the page stops making sense without them:
   the hero header at the top, and Today's Practice. Everything else — every
   section, every banner — is free.

   How the reorder works
   ---------------------
   REG below lists the wrap's children in their shipped order, one entry per
   movable unit. A unit can be more than one DOM node (the tip rail and the
   four tiles are one thing to a user, so they travel together), which is
   why `sel` is an array.

   Applying a layout walks the shipped order and refills it: a locked entry
   keeps its exact slot, every other slot takes the next entry off the
   user's list. That way a fixed entry stays where it has always been even
   though everything around it moved — a plain "locked items first, the
   rest after" model would have shoved the Normal home's streak and store
   disc below Today's Practice on a fresh install, quietly changing the
   default page for someone who never opened this editor.

   Anything in the wrap that ISN'T in REG (the offscreen <svg> filter defs,
   say) is left exactly where it sits and never enters the list.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var B = 'banner', S = 'section';

  var REG = {
    nm: {
      key:   'nm',
      name:  'Normal Home',
      wrap:  '#home-nm .nmh-wrap',
      items: [
        { k:'greet',    sel:['.nmh-greet-block'],                                          t:S, label:'Greeting',              sub:'Good morning · hero header', locked:1 },
        /* Registered so the layout editor places it. Unregistered sections
           are left where they are while every registered one is re-appended
           around them, which strands them at the TOP of the home — this bar
           was landing above the greeting for exactly that reason. It sits
           after the greeting and before the hero clip and the streak. */
        { k:'search',   sel:['.nmh-search'],                                               t:S, label:'Search',                sub:'One bar for words and meanings' },
        { k:'herovid',  sel:['.nsvb-blk'],                                                   t:S, label:'Streak Video',          sub:'The clip above the streak, on the tablet', vb:1 },
        { k:'streak',   sel:['.nmh-streak-section'],                                       t:S, label:'Streak',                sub:'Your daily practice streak', always:1 },
        { k:'storedisc',sel:['.npc-card.npc-purple'],                                      t:B, label:'Store Disc',            sub:'Rotating store promo disc', vb:1 },
        { k:'practice', sel:['.nmh-plyr-wrap'],                                             t:S, label:"Today's Practice",      sub:'Your personalised word ritual', locked:1, after:'streak' },
        { k:'tiles',    sel:['.nmh-tiles-wrap'],                                    t:S, label:'Home Tiles',            sub:'The four buttons and their tip rail', always:1 },
        { k:'reader',   sel:['.nmh-rdsec-wrap'],                                         t:S, label:'Reader',                sub:'Meanings and eBooks' },
        { k:'trendwd',  sel:['.nmh-trend-wrap'],                                          t:S, label:"Today's Trending",      sub:'The clip and its black banner', vb:1 },
        { k:'custom',   sel:['.nmh-cust-panel'],                                           t:S, label:'Customize',             sub:'Quick Access · Quick Links · Set As You Like' },
        /* 'offer' and 'shopvid' are gone — the two Shop Now banners they
           pointed at were removed from the homes, and a registry row with
           nothing behind it shows up in Customize as a switch that does
           nothing. */
        { k:'rx',       sel:['.nmh-rx-heading', '.nmh-rx-section'],                        t:S, label:'AI Prescription',       sub:'Your daily recommended words' },
        { k:'routines', sel:['.home-card.home-card-static.w100'],                          t:S, label:'My Routines',           sub:'Daily practice system', defOff:1 },
        { k:'condisc',  sel:['.npc-card.npc-blue'],                                        t:B, label:'Connect Disc',          sub:'Rotating Connect promo disc', vb:1 },
        { k:'connect',  sel:['.nmh-connect-sec'],                                        t:S, label:'NowssB Connect',        sub:'What the social space is' },
        { k:'feed',     sel:['#ncbCarouselNm'],                                            t:S, label:'Community Carousel',    sub:'Swipeable feed cards' },
        /* The BLOCK, not the frame or the row inside it: this registry
           matches ':scope > sel', a DIRECT child of the wrap. Pointing it
           at anything nested finds nothing and strands the section at the
           top of the page — which is what happened the first time the
           television went on. */
        { k:'quickrow', sel:['.qa-tv-block'],                                              t:S, label:'Quick Access',          sub:'Cart · Wishlist · Order' },
        { k:'trendshop',sel:['.nmh-trend-shop-wrap'],                                     t:S, label:'Trending Shop',         sub:'The clip and the Shop Now banner', vb:1 },
        { k:'subvid',   sel:['.nsub-blk'],                                                  t:S, label:'Subscription',          sub:'The clip, the heading and its banner', vb:1 },
        { k:'edition',  sel:['.nedi-blk'],                                                 t:S, label:'Your Edition',          sub:'Current plan and upgrade', always:1 },
        { k:'ebooks',   sel:['.nmh-ebsec-wrap'],                                         t:S, label:'eBooks',                sub:'Deep-dive guides, yours to keep' },
        { k:'connectban', sel:['.nc-blk'],                                              t:S, label:'Connect Banner',        sub:'The clip and what Connect offers', vb:1 },
        /* Off on the shipped Normal home, and opt-in from this editor —
           `always` is gone precisely so it CAN be switched off, and defOff
           keeps it off until someone turns it on. The Fashion home's own
           healing entry is untouched. */
        { k:'healing',  sel:['.nmh-healing-wrap'],                                        t:S, label:'Personalised Healing',  sub:'Choose your health journey', defOff:1 },
        /* Choose Your Path is its own section now — it used to live inside
           the wrapper above. A direct child of the home wrap that this
           registry does not know about gets stranded at the top of the page
           while every registered one is re-appended around it. */
        { k:'genderpath', sel:['[data-vbwrap="vb2"]'],                                     t:S, label:'Choose Your Path',      sub:'Female and Male, on the laptop', vb:1 },
        { k:'wsearch',  sel:['.word-search-section'],                                      t:S, label:'Word Search',           sub:'Discover the origin of any word', defOff:1 },
        { k:'msearch',  sel:['[data-vbwrap="vb8"]', '.krm-section'],                                              t:S, label:'Meaning Search',        sub:'Earth · Water · God · your name', defOff:1 },
        { k:'store',    sel:['.nmh-store-wrap'],                                          t:S, label:'NowssB Store',          sub:'Enter the store', always:1 },
        { k:'fashsw',   sel:['#nmhFashSwitch'],                                            t:S, label:'Fashion Mode',          sub:'Switch to the Fashion home' },
        { k:'footer',   sel:['#homeFooterNm'],                                             t:S, label:'Footer',                sub:'Across Every Language', locked:1 }
      ]
    },
    fash: {
      key:   'fash',
      name:  'Fashion Home',
      wrap:  '#home .home-body',
      items: [
        { k:'greet',    sel:['.home-greeting', '.home-tagline'],                           t:S, label:'Greeting',              sub:'Begin Your Healing Path · hero header', locked:1 },
        { k:'herorow',  sel:['.hhr-blk'],                                              t:S, label:'Customize · Features · Earn', sub:'The row under the greeting' , kind:'tab' },
        { k:'practice', sel:['.fash-plyr-wrap'],                                        t:S, label:"Today's Practice",      sub:'Morning word ritual', locked:1 },
        { k:'reader',   sel:['.fash-rdsec-wrap'],                                        t:S, label:'Reader',                sub:'Meanings and eBooks' },
        { k:'herovid',  sel:['.nsvb-blk'],                                                  t:S, label:'Streak Video',          sub:'The clip above the streak, on the tablet', vb:1 , kind:'blk' },
        { k:'streak',   sel:['.nmh-streak-glass-section'],                                 t:S, label:'Streak',                sub:'Your daily practice streak', always:1 },
        { k:'tiles',    sel:['.fash-tiles-wrap'],                                   t:S, label:'Home Tiles',            sub:'The four buttons and their tip rail', always:1 },
        { k:'trendwd',  sel:['.fash-trend-wrap'],                                          t:S, label:"Today's Trending",      sub:'The clip and its black banner', vb:1 },
        { k:'custom',   sel:['.fash-cust-panel'],                                          t:S, label:'Customize',             sub:'Quick Access · Quick Links · Set As You Like' },
        /* Registered so it lands where it is meant to. Anything NOT in this
           table keeps its markup position while every registered section is
           re-appended around it — which puts the stray one at the TOP of the
           home no matter where it was written. That is exactly what happened
           to this card. */
        { k:'fashplus', sel:['.fps-mini'],                                                 t:S, label:'Fashion Plus',          sub:'The door to the motion mode' , kind:'tab' },
        { k:'rx',       sel:['#rxCardWrap'],                                               t:S, label:'AI Prescription',       sub:'Your daily recommended words' },
        { k:'connect',  sel:['.fash-connect-wrap'],                                      t:S, label:'NowssB Connect',        sub:'What the social space is' , kind:'blk' },
        { k:'trendvid', sel:['.fash-storevid-wrap'],                                      t:S, label:'Trending Shop',        sub:'The clip and the Shop Now banner', vb:1 },
        { k:'subvid',   sel:['.nsub-blk'],                                                t:S, label:'Subscription',          sub:'The clip, the heading and its banner', vb:1 , kind:'blk' },
        { k:'edition',  sel:['.nedi-blk'],                                                 t:S, label:'Your Edition',          sub:'Current plan and upgrade', always:1 , kind:'blk' },
        { k:'routines', sel:['.fash-routines-wrap'],                                       t:S, label:'My Routines',          sub:'Daily practice system', defOff:1 },
        { k:'offer',    sel:['.fash-offer-wrap'],                                          t:S, label:"Today's Offer",         sub:'Coupon art and the offer banner', vb:1 },
        { k:'cube',     sel:['#fashCubeSec'],                                              t:S, label:'Quick Access',          sub:'Cart · Wishlist · Order' , kind:'blk' },
        { k:'shabda',   sel:['.fash-shabda-wrap'],                                         t:S, label:'Shabdapathy Foundations', sub:'Featured ancient word science', vb:1, defOff:1 },
        { k:'ebooks',   sel:['.fash-ebsec-wrap'],                                        t:S, label:'eBooks',                sub:'Deep-dive guides, yours to keep' },
        { k:'connectban', sel:['.nc-blk'],                                              t:S, label:'Connect Banner',        sub:'The clip and what Connect offers', vb:1 , kind:'blk' },
        { k:'healing',  sel:['.fash-healing-wrap'],                                       t:S, label:'Personalised Healing',  sub:'Choose your health journey', always:1 },
        { k:'genderpath', sel:['[data-vbwrap="vb3"]'],                                     t:S, label:'Choose Your Path',      sub:'Female and Male, on the laptop', vb:1 , kind:'blk' },
        { k:'promovid', sel:['#fashPromoVid'],                                             t:B, label:'Promo Video',           sub:'16:9 video above Word Search', vb:1 , kind:'blk' },
        { k:'wsearch',  sel:['#fashWordSearchWrap'],                                       t:S, label:'Word Search',           sub:'Banner and search section', defOff:1 },
        { k:'msearch',  sel:['[data-vbwrap="vb9"]', '#fashMeaningSearchWrap'],                                    t:S, label:'Meaning Search',        sub:'Banner and search section' , kind:'blk', defOff:1 },
        { k:'store',    sel:['.vb-banner[data-vb="vb1"]', '.nss-store-trigger'],                                        t:S, label:'NowssB Store',          sub:'Enter the store', always:1 },
        { k:'shabvid',  sel:['.hvb-glass-wrap'],                                           t:B, label:'Shabdapathy Video',     sub:'Video banner near the footer', vb:1 , kind:'blk' },
        { k:'footer',   sel:['#homeFooter'],                                               t:S, label:'Footer',                sub:'Across Every Language', locked:1 }
      ]
    }
  };

  function LSKEY(which) { return 'nwsb_home_layout_' + which; }

  /* Bump when a section becomes defOff after it has already shipped switched
     on, so saved layouts get the change once. See the migration in load().
       1 — Personalised Healing leaves the Normal home.
       2 — Word Search, Meaning Search, My Routines and (on the Fashion
           home) Shabdapathy Foundations leave both homes. They are not
           gone: they are off by default and go back on from the Widgets
           page, whole — the section, its banner and its clip together,
           because each registry row covers the block and not a piece of
           it. Word Search also stops being `always`, or it could not be
           switched off at all. */
  var LAYOUT_V = 2;

  function load(which) {
    var reg = REG[which], all = reg.items.filter(function (i) { return !i.locked; }).map(function (i) { return i.k; });
    var raw;
    try { raw = JSON.parse(localStorage.getItem(LSKEY(which)) || 'null'); } catch (e) { raw = null; }
    var order = (raw && Array.isArray(raw.order)) ? raw.order.filter(function (k) { return all.indexOf(k) >= 0; }) : [];
    /* Anything the saved order doesn't mention is new since it was written.
       It goes in NEXT TO ITS SHIPPED NEIGHBOUR, not at its shipped index —
       an index means nothing in somebody else's arrangement, so inserting
       at one dropped the new section wherever that slot happened to be.
       Finding the section it ships after and going in behind it puts it
       where it was designed to sit, whatever order the rest are in. */
    all.forEach(function (k) {
      if (order.indexOf(k) >= 0) return;
      var i = all.indexOf(k), at = -1;
      for (var j = i - 1; j >= 0 && at < 0; j--) at = order.indexOf(all[j]);
      order.splice(at < 0 ? 0 : at + 1, 0, k);
    });
    // With nothing saved yet, entries flagged defOff start switched off —
    // they are opt-in additions rather than part of the shipped page.
    var off = (raw && Array.isArray(raw.off))
      ? raw.off.filter(function (k) { return all.indexOf(k) >= 0; })
      : reg.items.filter(function (i) { return i.defOff; }).map(function (i) { return i.k; });
    /* defOff only decides a FRESH install. A section that becomes defOff
       after someone already has a saved layout would sit on their page
       forever, because their saved `off` list simply doesn't mention it —
       so the change would land for new readers and nobody else. This runs
       the difference in once, marks the layout with the version it has
       been brought up to, and never touches it again. Turning the section
       back on therefore sticks: save() writes the version too, so there is
       nothing left for a later load to migrate. */
    if (raw && (raw.v || 0) < LAYOUT_V) {
      reg.items.forEach(function (i) {
        if (i.defOff && off.indexOf(i.k) < 0) off.push(i.k);
      });
      try {
        localStorage.setItem(LSKEY(which), JSON.stringify({ order: order, off: off, v: LAYOUT_V }));
      } catch (e) {}
    }
    // Entries flagged `always` can be reordered but never switched off, so the
    // user can't hide the only on-page way back into this editor.
    off = off.filter(function (k) { return !itemOf(which, k).always; });
    return { order: order, off: off };
  }
  function save(which, st) {
    try { localStorage.setItem(LSKEY(which), JSON.stringify({ order: st.order, off: st.off, v: LAYOUT_V })); } catch (e) {}
  }
  function itemOf(which, k) {
    var a = REG[which].items;
    for (var i = 0; i < a.length; i++) if (a[i].k === k) return a[i];
    return {};
  }
  function nodesOf(wrap, item) {
    var out = [];
    item.sel.forEach(function (s) {
      var n = wrap.querySelector(':scope > ' + s);
      if (n) out.push(n);
    });
    return out;
  }

  /* ── applying a saved layout to the live DOM ───────────────────── */
  function apply(which) {
    var reg = REG[which];
    var wrap = document.querySelector(reg.wrap);
    if (!wrap) return;

    var st = load(which);
    var visible = st.order.filter(function (k) { return st.off.indexOf(k) < 0; });
    var queue = visible.slice();

    var seq = [];   // the DOM nodes, in the order they should end up
    reg.items.forEach(function (it) {
      if (it.locked) { seq.push({ item: it }); return; }
      var next = queue.shift();
      if (next) seq.push({ item: itemOf(which, next) });
    });
    // Hidden entries still need their nodes parked somewhere; keep them in the
    // wrap (display:none) so re-enabling one is a class flip, not a re-render.
    st.off.forEach(function (k) { seq.push({ item: itemOf(which, k), hide: 1 }); });

    seq.forEach(function (s) {
      nodesOf(wrap, s.item).forEach(function (n) {
        n.classList.toggle('hl-off', !!s.hide);
        wrap.appendChild(n);
      });
    });

    /* ── pinned pairs ──────────────────────────────────────────────
       An item carrying `after` sits directly below that item's section
       WHEREVER it ends up, rather than at a fixed slot in the registry.

       The slot model above cannot express that. `locked` anchors an item
       to an INDEX among the slots — so Today's Practice held position six
       and whatever the reader's saved order happened to drop into slot
       five landed between it and the streak. That is how the Reader ended
       up sitting between them: not a bug in the order, a bug in what the
       order can say.

       This runs last, after everything is placed, so it only has to move
       the pinned node — and it re-reads the anchor from the DOM rather
       than from the sequence, which means it is correct even if something
       else moved the anchor after the fact. */
    reg.items.forEach(function (it) {
      if (!it.after) return;
      var anchors = nodesOf(wrap, itemOf(which, it.after));
      if (!anchors.length) return;
      var ref = anchors[anchors.length - 1];   // below the anchor's LAST node
      nodesOf(wrap, it).forEach(function (n) {
        if (n === ref || !ref.parentNode) return;
        ref.parentNode.insertBefore(n, ref.nextSibling);
        ref = n;   // keep a multi-node section in its own order
      });
    });
  }

  function applyAll() { apply('nm'); apply('fash'); }
  window.hlApplyLayout = applyAll;

  /* ── the sheet ─────────────────────────────────────────────────── */
  var MARKUP =
    '<div class="hl-overlay" id="hlOverlay" onclick="if(event.target===this)hlClose()">' +
      '<div class="hl-box">' +
        '<div class="hl-head">' +
          '<div class="hl-head-icon"><svg viewBox="0 0 22 22" fill="none">' +
            '<rect x="3" y="2.5" width="16" height="4.2" rx="1" stroke="#fff" stroke-width="1.5"/>' +
            '<rect x="3" y="8.9" width="16" height="4.2" rx="1" stroke="rgba(255,255,255,0.5)" stroke-width="1.5"/>' +
            '<rect x="3" y="15.3" width="16" height="4.2" rx="1" stroke="rgba(255,255,255,0.5)" stroke-width="1.5"/>' +
          '</svg></div>' +
          '<div class="hl-head-txt"><div class="hl-head-title">Set As You Like</div>' +
            '<div class="hl-head-sub" id="hlHeadSub">Order every section and banner</div></div>' +
          '<div class="hl-close" onclick="hlClose()"><svg viewBox="0 0 24 24" fill="none">' +
            '<path d="M6 6l12 12M18 6L6 18" stroke="rgba(255,255,255,0.75)" stroke-width="1.7" stroke-linecap="round"/></svg></div>' +
        '</div>' +
        '<div class="hl-tabs">' +
          '<div class="hl-tab" id="hlTabNm" onclick="hlTab(\'nm\')">Normal Home</div>' +
          '<div class="hl-tab" id="hlTabFash" onclick="hlTab(\'fash\')">Fashion Home</div>' +
        '</div>' +
        '<div class="hl-list" id="hlList"></div>' +
        '<div class="hl-foot">' +
          '<div class="hl-reset" onclick="hlReset()">Reset</div>' +
          '<div class="hl-done" onclick="hlClose()">Done</div>' +
        '</div>' +
        '<div class="hl-picker" id="hlPicker">' +
          '<div class="hl-picker-head" id="hlPickerHead">Move to position</div>' +
          '<div class="hl-picker-grid" id="hlPickerGrid"></div>' +
          '<div class="hl-picker-cancel" onclick="hlPickerClose()">Cancel</div>' +
        '</div>' +
      '</div>' +
    '</div>';

  var cur = 'nm';

  function mount() {
    if (document.getElementById('hlOverlay')) return;
    var d = document.createElement('div');
    d.innerHTML = MARKUP;
    document.body.appendChild(d.firstChild);
  }

  function haptic(ms) { try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) {} }

  function render() {
    var list = document.getElementById('hlList');
    if (!list) return;
    var reg = REG[cur], st = load(cur);
    var sub = document.getElementById('hlHeadSub');
    if (sub) sub.textContent = reg.name + ' · ' + st.order.length + ' movable pieces';
    document.getElementById('hlTabNm').classList.toggle('on', cur === 'nm');
    document.getElementById('hlTabFash').classList.toggle('on', cur === 'fash');

    var html = '';

    reg.items.filter(function (i) { return i.locked; }).forEach(function (it) {
      html +=
        '<div class="hl-row hl-row-locked">' +
          '<div class="hl-num hl-num-lock"><svg viewBox="0 0 24 24" fill="none">' +
            '<rect x="5" y="10" width="14" height="10" rx="2" stroke="rgba(255,255,255,0.45)" stroke-width="1.6"/>' +
            '<path d="M8 10V7a4 4 0 0 1 8 0v3" stroke="rgba(255,255,255,0.45)" stroke-width="1.6"/></svg></div>' +
          '<div class="hl-body"><div class="hl-label">' + it.label + '<span class="hl-chip hl-chip-lock">Fixed</span></div>' +
            '<div class="hl-sub">' + it.sub + '</div></div>' +
        '</div>';
    });

    st.order.forEach(function (k, i) {
      var it = itemOf(cur, k);
      var hidden = st.off.indexOf(k) >= 0;
      html +=
        '<div class="hl-row' + (hidden ? ' hl-row-off' : '') + '">' +
          '<div class="hl-num" onclick="hlPick(\'' + k + '\')">' + (i + 1) + '</div>' +
          '<div class="hl-body">' +
            '<div class="hl-label">' + it.label +
              (it.t === B ? '<span class="hl-chip hl-chip-ban">Banner</span>' : '') +
              (it.always ? '<span class="hl-chip hl-chip-lock">Always on</span>' : '') +
            '</div>' +
            '<div class="hl-sub">' + it.sub + '</div>' +
          '</div>' +
          '<div class="hl-arrows">' +
            '<div class="hl-arw' + (i === 0 ? ' hl-arw-off' : '') + '" onclick="hlMove(\'' + k + '\',-1)">' +
              '<svg viewBox="0 0 24 24" fill="none"><path d="M12 19V5M5 12l7-7 7 7" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/></svg></div>' +
            '<div class="hl-arw' + (i === st.order.length - 1 ? ' hl-arw-off' : '') + '" onclick="hlMove(\'' + k + '\',1)">' +
              '<svg viewBox="0 0 24 24" fill="none"><path d="M12 5v14M5 12l7 7 7-7" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/></svg></div>' +
          '</div>' +
          (it.always ? '<div class="hl-eye hl-eye-fixed"></div>'
                     : '<div class="hl-eye' + (hidden ? '' : ' on') + '" onclick="hlToggle(\'' + k + '\')">' +
                         '<div class="hl-eye-knob"></div></div>') +
        '</div>';
    });

    list.innerHTML = html;
  }

  window.hlOpen = function (which) {
    mount();
    cur = (which === 'fash') ? 'fash'
        : (which === 'nm')   ? 'nm'
        : (localStorage.getItem('nwsb_home_mode') === 'home' ? 'fash' : 'nm');
    render();
    var ov = document.getElementById('hlOverlay');
    requestAnimationFrame(function () { if (ov) ov.classList.add('open'); });
    haptic(28);
  };
  /* ── A public read/write for the section list ──────────────────────
     The Widgets page (app/js/part082.js) shows the same sections as this
     editor and has to agree with it exactly — same storage, same rules
     about `always` and `locked`. It asks here rather than keeping a copy:
     one place decides what a home is made of.
     `which` is 'nm' or 'fash'; omitted, it follows the home in use. ── */
  function whichNow(which) {
    return (which === 'fash' || which === 'nm') ? which
      : (localStorage.getItem('nwsb_home_mode') === 'home' ? 'fash' : 'nm');
  }
  window.hlWhich = whichNow;
  window.hlList = function (which) {
    var w = whichNow(which), st = load(w), reg = REG[w];
    return st.order.map(function (k) {
      var it = itemOf(w, k);
      /* `vb` says this unit is a banner block — a clip, a disc, artwork
         with a black bar under it — rather than a section you use. The
         Widgets page shows the two on separate rails, because choosing
         between banners and choosing between sections are different
         decisions and one long rail of both was neither. */
      /* `kind` is what SHAPE the unit is, which decides how the Widgets
         page shows it: 'sec' a section, 'ban' a bare clip, 'blk' a block
         that already carries its own device frame — a tablet, a laptop, a
         television — and 'tab' a row of buttons rather than a section at
         all. Unmarked units fall back to the vb flag, so a registry row
         that says nothing still lands somewhere sensible. */
      return it ? { k: k, label: it.label, sub: it.sub, on: st.off.indexOf(k) < 0,
                    always: !!it.always, locked: !!it.locked, vb: !!it.vb,
                    kind: it.kind || (it.vb ? 'ban' : 'sec') } : null;
    }).filter(Boolean);
  };
  /* The live nodes of a section, so the Widgets page can clone the real
     thing rather than describe it. Returns them whether the section is
     showing or hidden — a hidden one still has to be previewable, which
     is the whole point of a page for turning them back on. */
  window.hlNodes = function (which, k) {
    var w = whichNow(which), reg = REG[w];
    var wrap = document.querySelector(reg.wrap);
    var it = itemOf(w, k);
    if (!wrap || !it) return [];
    return nodesOf(wrap, it);
  };

  window.hlSet = function (which, k, on) {
    var w = whichNow(which), it = itemOf(w, k);
    if (!it || it.always || it.locked) return false;
    var st = load(w), i = st.off.indexOf(k);
    if (on && i >= 0) st.off.splice(i, 1);
    else if (!on && i < 0) st.off.push(k);
    else return true;                       /* already where it was asked to be */
    save(w, st); apply(w);
    return true;
  };

  window.hlClose = function () {
    hlPickerClose();
    var ov = document.getElementById('hlOverlay');
    if (ov) ov.classList.remove('open');
  };
  window.hlTab = function (which) { cur = which; hlPickerClose(); render(); haptic(20); };

  window.hlMove = function (k, dir) {
    var st = load(cur), i = st.order.indexOf(k), j = i + dir;
    if (i < 0 || j < 0 || j >= st.order.length) return;
    st.order.splice(i, 1);
    st.order.splice(j, 0, k);
    save(cur, st); apply(cur); render(); haptic(20);
  };

  window.hlToggle = function (k) {
    // An `always` entry renders no switch, but the function is still on
    // window — refuse here too so the guard lives with the rule.
    if (itemOf(cur, k).always) return;
    var st = load(cur), i = st.off.indexOf(k);
    if (i >= 0) st.off.splice(i, 1); else st.off.push(k);
    save(cur, st); apply(cur); render(); haptic(28);
  };

  window.hlReset = function () {
    try { localStorage.removeItem(LSKEY(cur)); } catch (e) {}
    apply(cur); render(); haptic([30, 55, 30]);
  };

  /* ── "move to position N" ──────────────────────────────────────── */
  var pickKey = null;
  window.hlPick = function (k) {
    pickKey = k;
    var st = load(cur), grid = document.getElementById('hlPickerGrid');
    var head = document.getElementById('hlPickerHead');
    if (head) head.textContent = 'Move “' + itemOf(cur, k).label + '” to position';
    var at = st.order.indexOf(k), html = '';
    for (var n = 1; n <= st.order.length; n++) {
      html += '<div class="hl-pn' + (n === at + 1 ? ' on' : '') + '" onclick="hlPickTo(' + n + ')">' + n + '</div>';
    }
    if (grid) grid.innerHTML = html;
    var p = document.getElementById('hlPicker');
    if (p) p.classList.add('open');
    haptic(20);
  };
  window.hlPickTo = function (n) {
    if (!pickKey) return;
    var st = load(cur), i = st.order.indexOf(pickKey);
    if (i < 0) return;
    st.order.splice(i, 1);
    st.order.splice(Math.max(0, Math.min(st.order.length, n - 1)), 0, pickKey);
    save(cur, st); apply(cur); render(); hlPickerClose(); haptic(45);
  };
  window.hlPickerClose = function () {
    pickKey = null;
    var p = document.getElementById('hlPicker');
    if (p) p.classList.remove('open');
  };

  /* ── boot ──────────────────────────────────────────────────────── */
  function boot() {
    applyAll();
    // Other files (the Rx card, the promo card) fill their wrappers after
    // first paint; the wrappers themselves are in the markup from the start,
    // so a single late pass is enough to catch anything that arrived since.
    setTimeout(applyAll, 1200);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
