
/* ══════════════════════════════════════════════════════════
   IG — Instagram-style People / Explore / Profile controller
═══════════════════════════════════════════════════════════ */
(function(){
  var img = function(seed,w,h){ return 'https://picsum.photos/seed/'+seed+'/'+(w||500)+'/'+(h||500); };
  var av  = function(seed){ return 'https://i.pravatar.cc/150?img='+seed; };

  // ── current user (self) ──
  var ME = {
    username:'', fullName:'', verified:false,
    avatar:'', words:0, sessions:0, score:0,
    category:'Sound Practitioner', bio:'',
    link:'nowssb.com', self:true,
    highlights:[], grid:[]
  };

  // ── people (extends the community concept) ──
  var PEOPLE = [
    { id:1, username:'kavya.frequency', fullName:'Kavya Singh', verified:true, avatar:av(5), posts:211, followers:'48.2k', following:312, category:'Sound Healer', bio:'Word without dictionary.\nFrequency is truth.', link:'nowssb.com/kavya' },
    { id:2, username:'aryan.sound', fullName:'Aryan Mehta', verified:true, avatar:av(13), posts:124, followers:'12.4k', following:198, category:'Daily Practitioner', bio:'Sound practice every morning.\n47-day streak 🔥', link:'' },
    { id:3, username:'priya.heals', fullName:'Priya Nair', verified:false, avatar:av(20), posts:82, followers:'3,204', following:421, category:'Wellness', bio:'Healing my body one word at a time.', link:'' },
    { id:4, username:'rohan.resonance', fullName:'Rohan Desai', verified:false, avatar:av(33), posts:63, followers:'1,887', following:560, category:'Health & Frequency', bio:'Morning practice since Jan 2026.\nBuilding the habit.', link:'' },
    { id:5, username:'aisha.vibration', fullName:'Aisha Patel', verified:true, avatar:av(45), posts:188, followers:'31.7k', following:240, category:'Sound Healer', bio:'Natural origin sounds healed my anxiety.', link:'nowssb.com/aisha' },
    { id:6, username:'dev.tones', fullName:'Dev Sharma', verified:false, avatar:av(51), posts:47, followers:'902', following:333, category:'Beginner', bio:'New to Shabdapathy. Learning every day.', link:'' },
    { id:7, username:'meera.om', fullName:'Meera Iyer', verified:false, avatar:av(47), posts:96, followers:'5,612', following:188, category:'Practitioner', bio:'Frequency is medicine.', link:'' },
    { id:8, username:'kabir.naad', fullName:'Kabir Khan', verified:true, avatar:av(60), posts:301, followers:'72.1k', following:142, category:'Frequency Sage', bio:'Top 1% · 1000+ sessions.\nYour voice is the instrument.', link:'nowssb.com/kabir' },
  ];
  // Banner pool — every placeholder person gets a profile banner
  var PEOPLE_BANNERS = [
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592067/grok_image_1782591933705_qq3l9g.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592067/grok_image_1782591857840_tbznap.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592067/grok_image_1782592051446_womamz.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592067/grok_image_1782591669371_kqnaf9.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592066/grok_image_1782591627828_lmde11.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592066/grok_image_1782591559591_yxgud5.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592066/grok_image_1782591561380_ytpn3b.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782592260/grok_image_1782591732123_epmpiu.jpg'
  ];
  PEOPLE.forEach(function(p,i){
    p.highlights = [{label:'Practice',img:img('p'+i+'a',150)},{label:'Words',img:img('p'+i+'b',150)},{label:'Journey',img:img('p'+i+'c',150)}];
    p.grid = Array.from({length:12},function(_,j){return img('u'+p.id+'g'+j,500);});
    p.following_state = false;
    p.bannerURL = PEOPLE_BANNERS[i % PEOPLE_BANNERS.length];
  });

  var verifiedSvg = '<svg class="ig-verified" viewBox="0 0 24 24" fill="#0095f6"><path d="M12 2l2.3 1.7 2.8-.3 1 2.6 2.5 1.3-.6 2.8 1.4 2.5-1.9 2.1.2 2.8-2.7.9-1.4 2.5-2.8-.5L12 22l-2.6-1.3-2.8.5-1.4-2.5-2.7-.9.2-2.8L.8 12.9l1.4-2.5-.6-2.8 2.5-1.3 1-2.6 2.8.3z"/><path d="M10.5 14.6l-2.3-2.3-1.2 1.2 3.5 3.5 6-6-1.2-1.2z" fill="#fff"/></svg>';
  var multiSvg = '<svg class="ig-multi" width="18" height="18" viewBox="0 0 24 24" fill="#fff"><path d="M16 2H8a2 2 0 00-2 2v0h10a2 2 0 012 2v10a2 2 0 002-2V4a2 2 0 00-2-2z"/><rect x="2" y="6" width="14" height="14" rx="2" fill="none" stroke="#fff" stroke-width="2"/></svg>';

  // ── NowssB Verified — tiers (the headphone check-mark badges) ──
  var VERIFY_TIERS = [
    {key:'blue',   name:'Verified', tag:'Confirmed Practitioner', img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782635218/fdb78570-72c6-11f1-bcbf-fb86e1a7c55f_ns1hnq.png', promo:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782792269/grok_image_1782792072386_d8fifm.jpg', req:['Complete your profile','Reach a 7-day practice streak','Practice 25 words'], price:'$1.99', priceN:199, per:'/mo'},
    {key:'silver', name:'Silver',   tag:'Sound Healer',           img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782635218/417b2090-72c8-11f1-bcbf-fb86e1a7c55f_cf2eyw.png', promo:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782792269/grok_image_1782792074543_iasker.jpg', req:['30-day practice streak','100 words practiced','20 sessions completed'], price:'$4.99', priceN:499, per:'/mo'},
    {key:'gold',   name:'Gold',     tag:'Frequency Master',       img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782635218/311b1480-72c8-11f1-bcbf-fb86e1a7c55f_blupbs.png', promo:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782792269/grok_image_1782792076655_amox3t.jpg', req:['365-day streak','1000 words practiced','50 sessions completed'], price:'$9.99', priceN:999, per:'/mo'},
    {key:'diamond',name:'Diamond',  tag:'Iced Out · Top 1%',      img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782635219/1aeee4a0-72ca-11f1-bcbf-fb86e1a7c55f_xc3v9h.png', promo:'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782792269/grok_image_1782792148248_tpzn1r.jpg', req:['Everything in Gold','Top 1% of all practitioners','Invite-only — or buy the Lifetime Pass'], price:'$49.99', priceN:4999, per:' lifetime'}
  ];
  var VERIFY_ORDER = ['', 'blue', 'silver', 'gold', 'diamond'];
  function verifyTierOf(p){
    if(p && p.self){
      try { return localStorage.getItem('nwsb_verify_tier') || (window._userDataCache && window._userDataCache.verifyTier) || ''; } catch(e){ return (window._userDataCache && window._userDataCache.verifyTier) || ''; }
    }
    return (p && p.verifyTier) || (p && p.verified ? 'blue' : '');
  }
  function verifyBadgeImg(tier, size){
    for(var i=0;i<VERIFY_TIERS.length;i++){
      if(VERIFY_TIERS[i].key===tier){
        size = size || 20;
        return '<span class="ig-vbadge" style="display:inline-flex;align-items:center;justify-content:center;width:'+size+'px;height:'+size+'px;border-radius:50% !important;margin-left:6px;vertical-align:-'+Math.round(size*0.24)+'px;overflow:hidden;background:#eef1f6;box-shadow:2.5px 2.5px 6px rgba(0,0,0,.2), -2px -2px 5px rgba(255,255,255,.96);"><img src="'+VERIFY_TIERS[i].img+'" alt="'+VERIFY_TIERS[i].name+'" style="width:100%;height:100%;object-fit:cover;border-radius:50% !important;display:block;"></span>';
      }
    }
    return '';
  }

  // ── EXPLORE GRID ──
  function renderExplore(){
    var grid = document.getElementById('ig-explore-grid');
    if(!grid) return;
    // No real explore posts yet (this used an external placeholder image
    // service that failed to load, leaving a blank page) — show a clean
    // centered empty state instead of 30 broken tiles.
    grid.innerHTML =
      '<div class="ig-explore-empty">' +
        '<div class="ig-explore-empty-circle">' +
          '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>' +
        '</div>' +
        '<div class="ig-explore-empty-title">No posts to explore yet</div>' +
        '<div class="ig-explore-empty-sub">New posts from the NowssB community will appear here.</div>' +
      '</div>';
  }

  // ── SEARCH ──
  function renderSearchResults(q){
    var box = document.getElementById('ig-search-results');
    var grid = document.getElementById('ig-explore-grid');
    if(!q){ box.style.display='none'; grid.style.display='grid'; return; }
    grid.style.display='none'; box.style.display='block';
    var ql = q.toLowerCase();
    var matches = PEOPLE.filter(function(p){ return p.username.toLowerCase().indexOf(ql)>=0 || p.fullName.toLowerCase().indexOf(ql)>=0; });
    if(!matches.length){ box.innerHTML='<div style="text-align:center;color:#737373;padding:40px 0;font-size:14px;">No results found</div>'; return; }
    box.innerHTML = matches.map(function(p){
      return '<div class="ig-userrow" onclick="IG.openProfile('+p.id+')">'+
        '<img loading="lazy" decoding="async" class="ig-av" src="'+p.avatar+'">'+
        '<div class="ig-meta"><div class="ig-u">'+p.username+(p.verified?verifiedSvg:'')+'</div>'+
        '<div class="ig-n">'+p.fullName+' · '+p.followers+' followers</div></div>'+
        '<button class="ig-mini-follow'+(p.following_state?' following':'')+'" onclick="event.stopPropagation();IG.toggleFollowMini('+p.id+',this)">'+(p.following_state?'Following':'Follow')+'</button>'+
        '</div>';
    }).join('');
  }

  // ── PROFILE RENDER ──
  function renderProfile(p){
    var $ = function(id){ return document.getElementById(id); };
    $('ig-prof-username').textContent = p.username || '';
    var vtTop = verifyTierOf(p);
    $('ig-prof-verified-top').innerHTML = vtTop ? verifyBadgeImg(vtTop, 22) : '';

    // Banner
    var bannerEl = $('ig-prof-banner');
    if (bannerEl) {
      var bannerURL = p.self
        ? ((window._userDataCache && window._userDataCache.bannerURL) || (function(){ try { return localStorage.getItem('nwsb_local_banner') || ''; } catch(e){ return ''; } })())
        : (p.bannerURL || '');
      if (bannerURL) {
        bannerEl.style.backgroundImage = 'url(' + bannerURL + ')';
        bannerEl.style.backgroundSize = 'cover';
        bannerEl.style.backgroundPosition = 'center';
      } else {
        bannerEl.style.backgroundImage = '';
      }
    }

    // Avatar — real photoURL for self, p.avatar for others; no placeholders
    var ring = $('ig-prof-avatar-ring');
    var avatarImg = $('ig-prof-avatar');
    var photoURL = p.self
      ? ((window._userDataCache && window._userDataCache.photoURL) || '')
      : (p.avatar || '');
    // Remove any existing initials element
    var existing = ring ? ring.querySelector('.ig-prof-initials') : null;
    if (existing) existing.parentNode.removeChild(existing);
    if (photoURL) {
      if (avatarImg) { avatarImg.style.display = 'block'; avatarImg.src = photoURL; }
    } else {
      if (avatarImg) avatarImg.style.display = 'none';
      var initChar = ((p.fullName || p.username || '?').trim().charAt(0)).toUpperCase();
      var initEl = document.createElement('div');
      initEl.className = 'ig-prof-initials';
      initEl.textContent = initChar;
      if (ring) ring.appendChild(initEl);
    }

    // Stats — real data for self, p.* for others
    if (p.self) {
      var sessionKeys = Object.keys(localStorage).filter(function(k){ return /^\d{4}-\d{2}-\d{2}_/.test(k); });
      var uniqueWords = new Set(sessionKeys.map(function(k){ return k.split('_').slice(1).join('_'); }));
      var purchased = []; try { purchased = JSON.parse(localStorage.getItem('nwsb_purchased') || '[]'); } catch(e){}
      var totalSessions = sessionKeys.length;
      var totalWords = uniqueWords.size;
      var wordsOwned = purchased.length > 0 ? purchased.length : totalWords;
      var score = Math.min(9999, totalSessions * 10 + totalWords * 5);
      if ($('ig-prof-words'))    $('ig-prof-words').textContent    = wordsOwned;
      if ($('ig-prof-sessions')) $('ig-prof-sessions').textContent = totalSessions;
      if ($('ig-prof-score'))    $('ig-prof-score').textContent    = score;
      // Plan badge + rank
      var planEl = $('ig-prof-plan');
      if (planEl) {
        var ud = window._userDataCache;
        var isPro = ud && ud.isPro;
        var tier = (ud && ud.tier) || (isPro ? 'Pro' : 'Starter');
        var rankLabel = window.RANK ? window.RANK.compute(totalSessions, 0).rank.title : (totalSessions >= 100 ? 'Sound Master' : totalSessions >= 50 ? 'Healer' : totalSessions >= 10 ? 'Resonant' : totalSessions > 0 ? 'Practitioner' : 'Seeker');
        planEl.innerHTML = '<span class="ig-prof-plan-badge">'+tier+'</span><span class="ig-prof-rank">'+rankLabel+'</span>';
      }
    } else {
      if ($('ig-prof-words'))    $('ig-prof-words').textContent    = p.posts || 0;
      if ($('ig-prof-sessions')) $('ig-prof-sessions').textContent = p.followers || 0;
      if ($('ig-prof-score'))    $('ig-prof-score').textContent    = p.following || 0;
      var planEl2 = $('ig-prof-plan'); if (planEl2) planEl2.innerHTML = '';
    }

    var fnEl = $('ig-prof-fullname');
    if(fnEl){
      var vtier = verifyTierOf(p);
      fnEl.innerHTML = (p.fullName || '') + (vtier ? '<span style="cursor:pointer" onclick="IG.openVerify()">'+verifyBadgeImg(vtier, 22)+'</span>' : (p.self ? ' <span onclick="IG.openVerify()" style="cursor:pointer;font-size:12px;font-weight:700;color:#a8854a;margin-left:6px;vertical-align:1px;">Get Verified ✓</span>' : ''));
    }
    $('ig-prof-category').textContent = p.category||'';
    $('ig-prof-biotext').textContent = p.bio||'';
    $('ig-prof-linktext').innerHTML = p.link ? ('<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="vertical-align:-1px;margin-right:3px;"><path d="M10 13a5 5 0 007 0l3-3a5 5 0 00-7-7l-1 1"/><path d="M14 11a5 5 0 00-7 0l-3 3a5 5 0 007 7l1-1"/></svg>'+p.link) : '';
    // ring gradient
    ring.style.background = p.self ? '#222' : 'linear-gradient(45deg,#f09433,#e6683c,#dc2743,#cc2366,#bc1888)';

    $('ig-prof-back').style.display = p.self ? 'none' : 'flex';
    $('ig-prof-add').style.display = 'none';

    // buttons
    var btns = $('ig-prof-btns');
    if(p.self){
      btns.innerHTML =
        '<button class="ig-btn gray" onclick="IG.editProfile()">Edit profile</button>'+
        '<button class="ig-btn gray" onclick="IG.shareProfile()">Share profile</button>';
    } else {
      btns.innerHTML =
        '<button class="ig-btn primary'+(p.following_state?' following':'')+'" id="ig-bigfollow" onclick="IG.toggleFollow('+p.id+')">'+(p.following_state?'Following':'Follow')+'</button>'+
        '<button class="ig-btn gray" onclick="IG.message('+p.id+')">Message</button>'+
        '<button class="ig-btn gray icon" onclick="IG.message('+p.id+')"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 9l6 6 6-6"/></svg></button>';
    }

    // highlights — only "New" for self (no picsum); real highlight circles for others
    var hl = $('ig-prof-highlights');
    var hls = '';
    if (!p.self) {
      hls = (p.highlights||[]).map(function(h){
        return '<div class="ig-hl"><div class="ig-hl-circle"><img loading="lazy" decoding="async" src="'+h.img+'"></div><div class="ig-hl-label">'+h.label+'</div></div>';
      }).join('');
    }
    if(p.self){
      hls += '<div class="ig-hl"><div class="ig-hl-circle new"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg></div><div class="ig-hl-label">New</div></div>';
    }
    hl.innerHTML = hls;

    // grid — empty state for self (no fake posts)
    var g = $('ig-prof-grid');
    if(p.self || !p.posts || !(p.grid&&p.grid.length)){
      g.innerHTML = '<div class="nwsb-empty-grid" style="grid-column:1/4;text-align:center;padding:50px 0;"><div class="nwsb-empty-ico"><svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="9" cy="9" r="2"/><path d="M21 15l-5-5L5 21"/></svg></div><div class="nwsb-empty-title">Share Photos</div></div>';
    } else {
      g.innerHTML = p.grid.map(function(src,i){
        return '<div class="ig-tile" onclick="IG.openExplorePost(this)"><img decoding="async" loading="lazy" src="'+src+'">'+(i%4===0?multiSvg:'')+'</div>';
      }).join('');
    }
    profTab('grid');
  }

  function profTab(t){
    ['grid','reels','tagged'].forEach(function(x){
      var el=document.getElementById('ig-tab-'+x); if(el) el.classList.toggle('active',x===t);
    });
    var g=document.getElementById('ig-prof-grid');
    if(t==='grid'){ var pp = IG._currentProfile; renderGridOnly(pp); }
    else if(t==='reels'){ g.innerHTML='<div style="grid-column:1/4;text-align:center;padding:50px 0;color:#737373;font-size:14px;">No reels yet</div>'; }
    else { g.innerHTML='<div style="grid-column:1/4;text-align:center;padding:50px 0;color:#737373;font-size:14px;">No tagged posts</div>'; }
  }
  function renderGridOnly(p){
    var g=document.getElementById('ig-prof-grid'); if(!g||!p) return;
    if(!p.posts||!(p.grid&&p.grid.length)) return; // empty state already there
    g.innerHTML = p.grid.map(function(src,i){
      return '<div class="ig-tile" onclick="IG.openExplorePost(this)"><img decoding="async" loading="lazy" src="'+src+'">'+(i%4===0?multiSvg:'')+'</div>';
    }).join('');
  }

  // ── NAV management ──
  var NAV_MAP = {
    'sub-nowssb-store':'store', 'sub-meaning-store':'store',
    'sub-cart':'store', 'sub-wishlist':'store', 'sub-orders':'store', 'sub-order-history':'store',
    'sub-routines':'home', 'sub-routine-detail':'home',
    'sub-sound-library':'library', 'sub-sound-bath':'library',
    'sub-people':'profile', 'sub-ig-profile':'profile',
    'sub-social':'profile', 'sub-profile':'profile'
  };
  function setActiveNav(which){
    ['home','practice','library','store','profile'].forEach(function(k){
      var el=document.getElementById('ignav-'+k);
      if(el) el.classList.toggle('active', k===which);
    });
    document.documentElement.style.setProperty('--nav-height', '58px');
  }
  function closeNavScreens(){
    Object.keys(NAV_MAP).forEach(function(id){
      var el=document.getElementById(id); if(el) el.classList.remove('open');
    });
  }
  function showNav(show){
    var n=document.getElementById('ig-bottomnav');
    if(n) n.classList.toggle('show', !!show);
    document.documentElement.style.setProperty('--nav-height', show ? '58px' : '0px');
  }
  window.showNav = showNav;
  window.setActiveNav = setActiveNav;

  // ── public API ──
  window.IG = {
    _currentProfile:null,
    nav:function(which){
      if(which==='home'){
        // Close all sub-screens instantly (no slide animation) — prevents cycling flash
        document.querySelectorAll('.sub-screen.open').forEach(function(el){
          el.style.transition='none'; el.classList.remove('open');
          requestAnimationFrame(function(){ el.style.transition=''; });
        });
        // Restore main nav, hide social nav
        var _mainNav = document.getElementById('ig-bottomnav');
        var _socialNav = document.getElementById('ig-social-nav');
        if (_socialNav) _socialNav.style.display = 'none';
        if (_mainNav) _mainNav.style.display = '';
        if(typeof goTo==='function'&&(typeof currentScreen==='undefined'||(currentScreen!=='home'&&currentScreen!=='home-nm'))){
          goTo('home');
        }
        setActiveNav('home'); showNav(true);
      } else if(which==='practice'){
        closeNavScreens();
        if(typeof openPracticeIntro==='function') openPracticeIntro();
        else if(typeof openSub==='function') openSub('practice');
        setActiveNav('practice');
      } else if(which==='library'){
        closeNavScreens();
        if(typeof openSub==='function') openSub('sound-library');
        setActiveNav('library'); showNav(true);
      } else if(which==='store'){
        closeNavScreens();
        if(typeof openSub==='function') openSub('nowssb-store');
        setActiveNav('store'); showNav(true);
      } else if(which==='profile'){
        closeNavScreens();
        // Swap to Instagram-style social nav
        var mainNav = document.getElementById('ig-bottomnav');
        var socialNav = document.getElementById('ig-social-nav');
        if (mainNav) mainNav.style.display = 'none';
        if (socialNav) { socialNav.style.display = 'flex'; }
        // Land on the Instagram-style Home feed
        this.openFeed();
        setSocialNavActive('home');
      } else if(which==='myprofile'){
        closeNavScreens();
        if(typeof openSub==='function') openSub('profile');
        setActiveNav('profile'); showNav(true);
      }
      setTimeout(syncNav,60);
    },
    openExplore:function(){
      document.getElementById('sub-ig-profile').classList.remove('open');
      document.getElementById('sub-people').classList.add('open');
      renderExplore(); this.clearSearch();
      setActiveNav('profile'); showNav(true);
      var sc=document.getElementById('ig-people-scroll'); if(sc) sc.scrollTop=0;
    },
    openFeed:function(){
      var screen=document.getElementById('sub-ig-feed');
      if(!screen) return;
      var ud=window._userDataCache||{};
      var myAv=ud.photoURL||'';
      var myStory = myAv
        ? '<div class="nwsbf-story-av" style="background-image:url('+myAv+')"></div>'
        : '<div class="nwsbf-story-av nwsbf-story-init">+</div>';
      var stories='<div class="nwsbf-story" onclick="IG.socialNav(\'me\')"><div class="nwsbf-story-ring nwsbf-you">'+myStory+'</div><span>Your Story</span></div>'+
        PEOPLE.map(function(p){
          return '<div class="nwsbf-story" onclick="IG.openProfile('+p.id+')"><div class="nwsbf-story-ring"><div class="nwsbf-story-av" style="background-image:url('+p.avatar+')"></div></div><span>'+(p.username||p.fullName)+'</span></div>';
        }).join('');

      var heart='<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#1a1a2e" stroke-width="1.7"><path d="M20.8 4.6a5.5 5.5 0 00-7.8 0L12 5.6l-1-1a5.5 5.5 0 00-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 000-7.8z"/></svg>';
      var comment='<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1a1a2e" stroke-width="1.7"><path d="M21 11.5a8.4 8.4 0 01-11.9 7.6L3 21l1.9-6.1A8.4 8.4 0 1121 11.5z"/></svg>';
      var send='<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1a1a2e" stroke-width="1.7"><path d="M22 2L11 13"/><path d="M22 2l-7 20-4-9-9-4 20-7z"/></svg>';
      var save='<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1a1a2e" stroke-width="1.7"><path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/></svg>';
      var chat='<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#1a1a2e" stroke-width="1.7"><path d="M21 11.5a8.4 8.4 0 01-11.9 7.6L3 21l1.9-6.1A8.4 8.4 0 1121 11.5z"/></svg>';
      var exitc='<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1a1a2e" stroke-width="1.7"><path d="M3 12l9-9 9 9"/><path d="M5 10v10h14V10"/></svg>';
      var CAPS=['Every sound is a step closer. 🙏','Frequency is truth.','Morning ritual done. ✨','Sound is medicine.','Tuned in, tuned up.','Found my frequency today.','Breath. Sound. Stillness.','Practice over perfection. 🎧'];
      var LOCS=['Rishikesh, India','Bali','Himalayas','','Varanasi','','Sound Lab',''];
      function lc(i){ return 137+(i*53)%900; }
      function cf(n){ return String(n).replace(/\B(?=(\d{3})+(?!\d))/g,','); }

      var posts=PEOPLE.map(function(p,i){
        var loc=LOCS[i%LOCS.length], cap=CAPS[i%CAPS.length];
        var src=(p.grid&&p.grid[0])||p.avatar;
        return '<div class="nwsbf-post">'+
            '<div class="nwsbf-post-head" onclick="IG.openProfile('+p.id+')">'+
              '<div class="nwsbf-post-av" style="background-image:url('+p.avatar+')"></div>'+
              '<div class="nwsbf-post-meta"><div class="nwsbf-post-name">'+(p.username||p.fullName)+(verifyTierOf(p)?verifyBadgeImg(verifyTierOf(p),16):'')+'</div>'+(loc?'<div class="nwsbf-post-loc">'+loc+'</div>':'')+'</div>'+
            '</div>'+
            '<div class="nwsbf-post-imgwrap" onclick="IG.feedOpenPost('+p.id+')"><img class="nwsbf-post-img" src="'+src+'" alt="" loading="lazy"></div>'+
            '<div class="nwsbf-post-actions"><button class="nwsbf-act">'+heart+'</button><button class="nwsbf-act">'+comment+'</button><button class="nwsbf-act">'+send+'</button><span class="nwsbf-sp"></span><button class="nwsbf-act">'+save+'</button></div>'+
            '<div class="nwsbf-post-likes">'+cf(lc(i))+' likes</div>'+
            '<div class="nwsbf-post-cap"><b>'+(p.username||p.fullName)+'</b> '+cap+'</div>'+
          '</div>';
      }).join('');

      var css='#sub-ig-feed{background:#eef0f5 !important;}'+
        '#sub-ig-feed *{box-sizing:border-box;font-family:DM Sans,sans-serif;}'+
        '#sub-ig-feed .nwsbf-scroll{position:absolute;inset:0;overflow-y:auto;-webkit-overflow-scrolling:touch;padding-bottom:calc(58px + env(safe-area-inset-bottom,0px) + 22px);}'+
        '#sub-ig-feed .nwsbf-top{position:sticky;top:0;z-index:5;display:flex;align-items:center;gap:10px;padding:max(env(safe-area-inset-top,12px),12px) 16px 12px;background:#eef0f5;box-shadow:0 4px 14px rgba(0,0,0,.06);}'+
        '#sub-ig-feed .nwsbf-brand{display:flex;align-items:center;gap:10px;flex:1;cursor:pointer;}'+
        '#sub-ig-feed .nwsbf-brandlogo{width:34px;height:34px;border-radius:50% !important;object-fit:cover;background:#eef0f5;box-shadow:4px 4px 9px rgba(0,0,0,.14),-3px -3px 7px rgba(255,255,255,.96);flex-shrink:0;}'+
        '#sub-ig-feed .nwsbf-logo{font-size:20px;font-weight:800;color:#1a1a2e;letter-spacing:-.3px;}'+
        '#sub-ig-feed .nwsbf-icon{width:42px;height:42px;border:none;border-radius:50% !important;background:#eef0f5;cursor:pointer;box-shadow:4px 4px 10px rgba(0,0,0,.12),-3px -3px 8px rgba(255,255,255,.95);display:flex;align-items:center;justify-content:center;}'+
        '#sub-ig-feed .nwsbf-icon:active{box-shadow:inset 3px 3px 7px rgba(0,0,0,.13),inset -2px -2px 5px rgba(255,255,255,.92);}'+
        '#sub-ig-feed .nwsbf-iconimg{width:23px;height:23px;object-fit:contain;filter:brightness(0) opacity(0.5);}'+
        '#sub-ig-feed .nwsbf-stories{display:flex;gap:15px;overflow-x:auto;padding:14px 16px 16px;scrollbar-width:none;}'+
        '#sub-ig-feed .nwsbf-stories::-webkit-scrollbar{display:none;}'+
        '#sub-ig-feed .nwsbf-story{display:flex;flex-direction:column;align-items:center;gap:6px;flex-shrink:0;cursor:pointer;width:66px;}'+
        '#sub-ig-feed .nwsbf-story-ring{width:64px;height:64px;border-radius:50% !important;padding:4px;background:#eef0f5;box-shadow:5px 5px 12px rgba(0,0,0,.13),-4px -4px 10px rgba(255,255,255,.95);}'+
        '#sub-ig-feed .nwsbf-story-av{width:100%;height:100%;border-radius:50% !important;background-size:cover;background-position:center;background-repeat:no-repeat;background-color:#e6e9f1;}'+
        '#sub-ig-feed .nwsbf-story-init{display:flex;align-items:center;justify-content:center;color:#c8a96e;font-size:24px;font-weight:700;}'+
        '#sub-ig-feed .nwsbf-story span{font-size:11px;color:rgba(0,0,0,.6);max-width:64px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}'+
        '#sub-ig-feed .nwsbf-post{background:#eef0f5;border-radius:22px !important;margin:0 14px 18px;padding:14px;box-shadow:7px 7px 18px rgba(0,0,0,.12),-5px -5px 14px rgba(255,255,255,.97);}'+
        '#sub-ig-feed .nwsbf-post-head{display:flex;align-items:center;gap:11px;margin-bottom:12px;cursor:pointer;}'+
        '#sub-ig-feed .nwsbf-post-av{width:42px;height:42px;border-radius:50% !important;background-size:cover;background-position:center;flex-shrink:0;box-shadow:3px 3px 8px rgba(0,0,0,.14),-2px -2px 6px rgba(255,255,255,.95);}'+
        '#sub-ig-feed .nwsbf-post-name{font-size:14px;font-weight:700;color:#1a1a2e;}'+
        '#sub-ig-feed .nwsbf-post-loc{font-size:11px;color:rgba(0,0,0,.5);}'+
        '#sub-ig-feed .nwsbf-post-imgwrap{border-radius:16px !important;overflow:hidden;cursor:pointer;}'+
        '#sub-ig-feed .nwsbf-post-img{width:100%;display:block;border-radius:16px !important;}'+
        '#sub-ig-feed .nwsbf-post-actions{display:flex;align-items:center;gap:12px;margin-top:13px;}'+
        '#sub-ig-feed .nwsbf-sp{flex:1;}'+
        '#sub-ig-feed .nwsbf-act{width:44px;height:44px;border:none;border-radius:50% !important;background:#eef0f5;cursor:pointer;box-shadow:4px 4px 10px rgba(0,0,0,.12),-3px -3px 8px rgba(255,255,255,.95);display:flex;align-items:center;justify-content:center;}'+
        '#sub-ig-feed .nwsbf-act:active{box-shadow:inset 3px 3px 7px rgba(0,0,0,.13),inset -2px -2px 5px rgba(255,255,255,.92);}'+
        '#sub-ig-feed .nwsbf-post-likes{font-size:13px;font-weight:700;color:#1a1a2e;margin-top:12px;}'+
        '#sub-ig-feed .nwsbf-post-cap{font-size:13px;color:#1a1a2e;margin-top:4px;line-height:1.45;}';

      screen.innerHTML='<style>'+css+'</style>'+
        '<div class="nwsbf-scroll">'+
          '<div class="nwsbf-top"><div class="nwsbf-brand"><img class="nwsbf-brandlogo" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779717856/30ebb160-5840-11f1-bb0c-71720609fd8f_g5nmcn.png" alt=""><span class="nwsbf-logo">NowssB <span style="color:#c8a96e;">Connect</span></span></div>'+
            '<button class="nwsbf-icon nwsbf-verifybtn" aria-label="Shop Verified" onclick="IG.openVerify()"><img class="nwsbf-iconimg" decoding="async" src="https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782635218/fdb78570-72c6-11f1-bcbf-fb86e1a7c55f_ns1hnq.png" alt="Verified"></button>'+
            '<button class="nwsbf-icon" aria-label="Messages" onclick="if(typeof chatInboxOpen===\'function\')chatInboxOpen()"><img class="nwsbf-iconimg" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1780123160/1ae1b990-5bf2-11f1-8248-b91d5cd919c2_z3xi3j.png" alt="Chat"></button>'+
            '<button class="nwsbf-icon" aria-label="Home" onclick="IG.socialNav(\'home\')"><img class="nwsbf-iconimg" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/q_auto/f_auto/v1779639661/569b91f0-578c-11f1-b67f-cfd32a085e10_pm6xc7.png" alt="Home"></button>'+
          '</div>'+
          '<div class="nwsbf-stories">'+stories+'</div>'+
          posts+
        '</div>';

      ['sub-social-home','sub-reels-feed','sub-people','sub-ig-profile'].forEach(function(id){ var e=document.getElementById(id); if(e) e.classList.remove('open'); });
      screen.classList.add('open');
      if(typeof showNav==='function') showNav(true);
    },
    feedOpenPost:function(id){
      var p=PEOPLE.find(function(x){return String(x.id)===String(id);}); if(!p) return;
      this._currentProfile=p;
      this.openExplorePost((p.grid&&p.grid[0])||p.avatar);
    },
    openVerify:function(){
      var cur='';
      try{ cur = localStorage.getItem('nwsb_verify_tier') || (window._userDataCache&&window._userDataCache.verifyTier) || ''; }catch(e){}
      var curName = cur ? (function(){ for(var i=0;i<VERIFY_TIERS.length;i++){ if(VERIFY_TIERS[i].key===cur) return VERIFY_TIERS[i].name; } return ''; })() : '';
      var cards = VERIFY_TIERS.map(function(t){
        var owned = cur && VERIFY_ORDER.indexOf(cur) >= VERIFY_ORDER.indexOf(t.key);
        var reqs = t.req.map(function(r){ return '<div class="nwsb-vr-req"><span class="nwsb-vr-tick">✓</span><span>'+r+'</span></div>'; }).join('');
        return '<div class="nwsb-vr-card'+(t.key==='diamond'?' diamond':'')+'">'+
            '<div class="nwsb-vr-banner"><img class="nwsb-vr-banner-img" src="'+(t.promo||t.img)+'" alt="">'+
              (owned ? '<span class="nwsb-vr-owned-flag">Owned ✓</span>' : '')+
            '</div>'+
            '<div class="nwsb-vr-top"><img class="nwsb-vr-img" src="'+t.img+'" alt=""><div class="nwsb-vr-meta"><div class="nwsb-vr-name">'+t.name+'</div><div class="nwsb-vr-tag">'+t.tag+'</div></div></div>'+
            '<div class="nwsb-vr-reqs-h">Earn it the organic way</div>'+reqs+
            '<div class="nwsb-vr-or"><span>or skip the grind — buy it</span></div>'+
            '<div class="nwsb-vr-buy"><div class="nwsb-vr-price">'+t.price+'<span>'+t.per+'</span></div>'+
              (owned ? '<button class="nwsb-vr-btn owned" disabled>Owned ✓</button>' : '<button class="nwsb-vr-btn" onclick="IG.buyVerify(\''+t.key+'\')">Buy '+t.name+'</button>')+
            '</div>'+
          '</div>';
      }).join('');
      var css='#nwsb-verify{position:fixed;inset:0;z-index:100001;background:#eef0f5;display:flex;flex-direction:column;}'+
        '#nwsb-verify *{box-sizing:border-box;font-family:DM Sans,sans-serif;}'+
        '#nwsb-verify .nwsb-vr-bar{position:sticky;top:0;display:flex;align-items:center;gap:12px;padding:max(env(safe-area-inset-top,14px),14px) 16px 14px;background:#eef0f5;box-shadow:0 4px 14px rgba(0,0,0,.07);}'+
        '#nwsb-verify .nwsb-vr-h{flex:1;font-size:18px;font-weight:800;color:#1a1a2e;}'+
        '#nwsb-verify .nwsb-vr-x{width:42px;height:42px;border:none;border-radius:50% !important;background:#eef0f5;color:#1a1a2e;font-size:22px;cursor:pointer;box-shadow:4px 4px 10px rgba(0,0,0,.13),-3px -3px 8px rgba(255,255,255,.95);display:flex;align-items:center;justify-content:center;}'+
        '#nwsb-verify .nwsb-vr-scroll{flex:1;overflow-y:auto;-webkit-overflow-scrolling:touch;padding:16px 16px calc(env(safe-area-inset-bottom,20px) + 26px);}'+
        '#nwsb-verify .nwsb-vr-intro{font-size:13px;color:rgba(0,0,0,.55);line-height:1.5;margin-bottom:6px;}'+
        '#nwsb-verify .nwsb-vr-cur{font-size:12px;font-weight:700;color:#a8854a;margin-bottom:18px;}'+
        '#nwsb-verify .nwsb-vr-card{background:#eef0f5;border-radius:22px !important;padding:18px;margin-bottom:16px;box-shadow:7px 7px 18px rgba(0,0,0,.12),-5px -5px 14px rgba(255,255,255,.97);overflow:hidden;}'+
        '#nwsb-verify .nwsb-vr-card.diamond{box-shadow:7px 7px 18px rgba(0,0,0,.13),-5px -5px 14px rgba(255,255,255,.97),inset 0 0 0 2px rgba(120,200,232,.45);}'+
        '#nwsb-verify .nwsb-vr-banner{position:relative;width:calc(100% + 36px);margin:-18px -18px 16px;height:230px;background:#0a0a12;overflow:hidden;}'+
        '#nwsb-verify .nwsb-vr-banner-img{width:100%;height:100%;object-fit:cover;object-position:center 46%;display:block;}'+
        '#nwsb-verify .nwsb-vr-owned-flag{position:absolute;top:12px;right:12px;background:rgba(26,167,106,.95);color:#fff;font-size:11px;font-weight:800;letter-spacing:.5px;padding:5px 11px;border-radius:20px !important;box-shadow:0 4px 12px rgba(0,0,0,.3);}'+
        '#nwsb-verify .nwsb-vr-top{display:flex;align-items:center;gap:14px;margin-bottom:14px;}'+
        '#nwsb-verify .nwsb-vr-img{width:66px;height:66px;border-radius:16px !important;object-fit:cover;flex-shrink:0;box-shadow:4px 4px 11px rgba(0,0,0,.16),-3px -3px 8px rgba(255,255,255,.9);}'+
        '#nwsb-verify .nwsb-vr-name{font-size:18px;font-weight:800;color:#1a1a2e;}'+
        '#nwsb-verify .nwsb-vr-tag{font-size:12px;font-weight:700;color:#a8854a;margin-top:2px;}'+
        '#nwsb-verify .nwsb-vr-reqs-h{font-size:10px;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:rgba(0,0,0,.38);margin-bottom:9px;}'+
        '#nwsb-verify .nwsb-vr-req{display:flex;align-items:flex-start;gap:8px;font-size:13px;color:#1a1a2e;margin-bottom:6px;line-height:1.4;}'+
        '#nwsb-verify .nwsb-vr-tick{color:#1aa76a;font-weight:800;flex-shrink:0;}'+
        '#nwsb-verify .nwsb-vr-or{display:flex;align-items:center;gap:10px;margin:15px 0 4px;font-size:10px;font-weight:800;letter-spacing:1.5px;text-transform:uppercase;color:rgba(0,0,0,.34);}'+
        '#nwsb-verify .nwsb-vr-or:before,#nwsb-verify .nwsb-vr-or:after{content:"";flex:1;height:1px;background:rgba(0,0,0,.1);}'+
        '#nwsb-verify .nwsb-vr-buy{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-top:12px;}'+
        '#nwsb-verify .nwsb-vr-price{font-size:19px;font-weight:800;color:#1a1a2e;white-space:nowrap;}'+
        '#nwsb-verify .nwsb-vr-price span{font-size:12px;font-weight:500;color:rgba(0,0,0,.45);}'+
        '#nwsb-verify .nwsb-vr-btn{border:none;border-radius:14px !important;background:#eef0f5;padding:12px 20px;font-size:14px;font-weight:700;color:#a8854a;cursor:pointer;white-space:nowrap;box-shadow:5px 5px 12px rgba(0,0,0,.13),-3px -3px 9px rgba(255,255,255,.95);}'+
        '#nwsb-verify .nwsb-vr-btn:active{box-shadow:inset 3px 3px 7px rgba(0,0,0,.13),inset -2px -2px 5px rgba(255,255,255,.92);}'+
        '#nwsb-verify .nwsb-vr-btn.owned{color:#1aa76a;}';
      var old=document.getElementById('nwsb-verify'); if(old) old.remove();
      var ov=document.createElement('div');
      ov.id='nwsb-verify';
      ov.innerHTML='<style>'+css+'</style>'+
        '<div class="nwsb-vr-bar"><span class="nwsb-vr-h">NowssB Verified</span><button class="nwsb-vr-x" aria-label="Close" onclick="var p=document.getElementById(\'nwsb-verify\');if(p)p.remove();">&times;</button></div>'+
        '<div class="nwsb-vr-scroll">'+
          '<div class="nwsb-vr-intro">Wear the headphone check-mark. Show the world you\'re a real NowssB practitioner — and climb from Blue all the way to Diamond.</div>'+
          (curName ? '<div class="nwsb-vr-cur">Your badge: '+curName+'</div>' : '<div class="nwsb-vr-cur">You\'re not verified yet</div>')+
          cards+
        '</div>';
      document.body.appendChild(ov);
    },
    buyVerify:function(tier){
      // Put the badge in the shopping bag and send the user through the real
      // checkout — the badge is granted by chkHandleSuccess after payment.
      var t=null; for(var i=0;i<VERIFY_TIERS.length;i++){ if(VERIFY_TIERS[i].key===tier){ t=VERIFY_TIERS[i]; break; } }
      if(!t) return;
      window.nssCart = window.nssCart || [];
      var id='badge-'+tier;
      if(!window.nssCart.some(function(c){ return c.id===id; })){
        // a badge replaces any lower badge already in the bag
        window.nssCart = window.nssCart.filter(function(c){ return String(c.id).indexOf('badge-')!==0; });
        window.nssCart.push({ id:id, name:t.name+' Verified Badge', type:'Badge', tier:tier, price:t.priceN, img:t.img });
        if(typeof nssSaveCart==='function') nssSaveCart();
        if(typeof nssUpdateBadges==='function') nssUpdateBadges();
      }
      var ov=document.getElementById('nwsb-verify'); if(ov) ov.remove();
      if(window.nwsbToast) nwsbToast('Badge added to bag — checkout to verify ✓');
      if(typeof openSub==='function') openSub('cart');
      // land straight on the bag contents, not the cart intro
      setTimeout(function(){ if(typeof window.cartEnterFromIntro==='function') window.cartEnterFromIntro(); }, 120);
    },
    openMyProfile:function(){
      // sync real user data
      var ud = window._userDataCache;
      var pn = document.getElementById('ss-prof-name');
      ME.fullName = (ud && ud.displayName) || (pn && pn.textContent && pn.textContent!=='—' ? pn.textContent : '') || 'Practitioner';
      ME.avatar   = (ud && ud.photoURL) || '';
      ME.username = ME.fullName.toLowerCase().replace(/\s+/g, '.') || 'practitioner';
      this._currentProfile = ME;
      renderProfile(ME);
      // sync explore avatar
      this._syncExploreAvatar();
      document.getElementById('sub-people').classList.remove('open');
      document.getElementById('sub-ig-profile').classList.add('open');
      setActiveNav('profile'); showNav(true);
      var sc=document.getElementById('ig-prof-scroll'); if(sc) sc.scrollTop=0;
    },
    openProfile:function(id){
      // Accept a numeric/string id OR a full user object (e.g. from chat).
      var p;
      if(id && typeof id==='object'){
        p = PEOPLE.find(function(x){return String(x.id)===String(id.id);}) || id;
      } else {
        p = PEOPLE.find(function(x){return String(x.id)===String(id);});
      }
      if(!p) return;
      this._currentProfile=p;
      renderProfile(p);
      document.getElementById('sub-ig-profile').classList.add('open');
      showNav(true); setActiveNav('profile');
      var sc=document.getElementById('ig-prof-scroll'); if(sc) sc.scrollTop=0;
    },
    closeProfile:function(){
      document.getElementById('sub-ig-profile').classList.remove('open');
      // if people screen underneath is open keep nav on search else default
      if(document.getElementById('sub-people').classList.contains('open')) setActiveNav('profile');
    },
    search:function(v){
      document.getElementById('ig-search-clear').style.display = v?'block':'none';
      renderSearchResults(v);
    },
    searchFocus:function(){},
    clearSearch:function(){
      var inp=document.getElementById('ig-search-input'); if(inp) inp.value='';
      document.getElementById('ig-search-clear').style.display='none';
      renderSearchResults('');
    },
    toggleFollow:function(id){
      var p=PEOPLE.find(function(x){return x.id===id;}); if(!p) return;
      p.following_state=!p.following_state;
      var b=document.getElementById('ig-bigfollow');
      if(b){ b.classList.toggle('following',p.following_state); b.textContent=p.following_state?'Following':'Follow'; }
    },
    toggleFollowMini:function(id,btn){
      var p=PEOPLE.find(function(x){return x.id===id;}); if(!p) return;
      p.following_state=!p.following_state;
      btn.classList.toggle('following',p.following_state);
      btn.textContent=p.following_state?'Following':'Follow';
    },
    profTab:profTab,
    message:function(id){
      // bridge to existing chat if available
      if(typeof ssOpenChat==='function'){ /* could integrate */ }
      (window.nwsbToast||window.alert)('Messaging — coming soon');
    },
    openExplorePost:function(el){
      // Neumorphic, Instagram-style post viewer — author header above each
      // image, scrollable feed, opens at the tapped post.
      var prof = this._currentProfile || (typeof ME!=='undefined'?ME:{}) || {};
      var imgs = (prof.grid && prof.grid.length) ? prof.grid.slice() : [];
      var tapped = (el && el.querySelector) ? ((el.querySelector('img')||{}).src || '') : (typeof el==='string'?el:'');
      var idx = 0;
      if(el && el.parentNode){ var k = Array.prototype.indexOf.call(el.parentNode.children, el); if(k>=0) idx=k; }
      if(!imgs.length){ if(tapped) imgs=[tapped]; else return; }
      if(idx>=imgs.length) idx=0;

      var name = prof.fullName || prof.username || 'Practitioner';
      var uname = prof.username ? ('@'+prof.username) : '';
      var av = prof.avatar || '';
      var avHtml = av
        ? '<div class="nwsb-pv-av" style="background-image:url('+av+')"></div>'
        : '<div class="nwsb-pv-av nwsb-pv-av-init">'+(name.charAt(0)||'N').toUpperCase()+'</div>';

      var heart='<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#1a1a2e" stroke-width="1.7"><path d="M20.8 4.6a5.5 5.5 0 00-7.8 0L12 5.6l-1-1a5.5 5.5 0 00-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 000-7.8z"/></svg>';
      var comment='<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1a1a2e" stroke-width="1.7"><path d="M21 11.5a8.4 8.4 0 01-11.9 7.6L3 21l1.9-6.1A8.4 8.4 0 1121 11.5z"/></svg>';
      var send='<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1a1a2e" stroke-width="1.7"><path d="M22 2L11 13"/><path d="M22 2l-7 20-4-9-9-4 20-7z"/></svg>';
      var save='<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1a1a2e" stroke-width="1.7"><path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/></svg>';
      var pin='<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="rgba(0,0,0,.5)" stroke-width="1.9" style="margin-right:4px;vertical-align:-2px;"><path d="M21 10c0 7-9 12-9 12s-9-5-9-12a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>';

      var CAPTIONS=['Every sound is a step closer. 🙏','Word without dictionary. Frequency is truth.','Morning ritual complete. ✨','Healing through natural origin sound.','The vibration before the meaning.','Practice over perfection. 🎧','Tuned in, tuned up.','Sound is medicine.','Found my frequency today.','Breath. Sound. Stillness.'];
      var LOCS=['Rishikesh, India','Studio · NowssB','Himalayas','','Bali, Indonesia','','Sound Lab','Varanasi, India','',''];
      function likeCount(i){ return 137 + (i*53)%900 + ((i*7)%9)*11; }
      function commafy(n){ return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ','); }

      var cards = imgs.map(function(src,i){
        var multi = (i % 4 === 0) && imgs.length > 2;
        var postImgs = multi ? [src, imgs[(i+1)%imgs.length], imgs[(i+2)%imgs.length]] : [src];
        var slides = postImgs.map(function(s){ return '<div class="nwsb-pv-slide"><img class="nwsb-pv-img" src="'+s+'" alt="" loading="lazy"></div>'; }).join('');
        var dots = multi ? '<div class="nwsb-pv-dots">'+postImgs.map(function(_,d){return '<span class="nwsb-pv-dot'+(d===0?' on':'')+'"></span>';}).join('')+'</div>' : '';
        var loc = LOCS[i % LOCS.length];
        var cap = CAPTIONS[i % CAPTIONS.length];
        return '<div class="nwsb-pv-card" id="nwsb-pv-card-'+i+'">'+
            (loc ? '<div class="nwsb-pv-loc">'+pin+loc+'</div>' : '')+
            '<div class="nwsb-pv-carousel'+(multi?' multi':'')+'">'+slides+'</div>'+
            dots+
            '<div class="nwsb-pv-actions"><button class="nwsb-pv-act">'+heart+'</button><button class="nwsb-pv-act">'+comment+'</button><button class="nwsb-pv-act">'+send+'</button><span class="nwsb-pv-spacer"></span><button class="nwsb-pv-act">'+save+'</button></div>'+
            '<div class="nwsb-pv-likes">'+commafy(likeCount(i))+' likes</div>'+
            '<div class="nwsb-pv-caption"><b>'+name+'</b> '+cap+'</div>'+
          '</div>';
      }).join('');

      var css = '#nwsb-postviewer{position:fixed;inset:0;z-index:100000;background:#eef0f5;display:flex;flex-direction:column;}'+
        '#nwsb-postviewer *{box-sizing:border-box;font-family:DM Sans,sans-serif;}'+
        '.nwsb-pv-top{position:sticky;top:0;display:flex;align-items:center;gap:12px;padding:max(env(safe-area-inset-top,14px),14px) 16px 14px;background:#eef0f5;box-shadow:0 4px 16px rgba(0,0,0,.07);flex-shrink:0;}'+
        '.nwsb-pv-topmeta{flex:1;min-width:0;}'+
        '.nwsb-pv-close{width:42px;height:42px;border:none;border-radius:50%!important;background:#eef0f5;color:#1a1a2e;font-size:22px;line-height:1;cursor:pointer;box-shadow:4px 4px 10px rgba(0,0,0,.13),-3px -3px 8px rgba(255,255,255,.95);display:flex;align-items:center;justify-content:center;flex-shrink:0;}'+
        '.nwsb-pv-close:active{box-shadow:inset 3px 3px 7px rgba(0,0,0,.13),inset -2px -2px 5px rgba(255,255,255,.92);}'+
        '.nwsb-pv-scroll{flex:1;overflow-y:auto;-webkit-overflow-scrolling:touch;padding:14px 14px calc(env(safe-area-inset-bottom,20px) + 26px);}'+
        '.nwsb-pv-card{background:#eef0f5;border-radius:22px!important;margin-bottom:18px;padding:14px;box-shadow:7px 7px 18px rgba(0,0,0,.12),-5px -5px 14px rgba(255,255,255,.97);}'+
        '.nwsb-pv-av{width:46px;height:46px;border-radius:50%!important;background-size:cover;background-position:center;background-repeat:no-repeat;flex-shrink:0;box-shadow:4px 4px 10px rgba(0,0,0,.14),-3px -3px 8px rgba(255,255,255,.95);}'+
        '.nwsb-pv-av-init{display:flex;align-items:center;justify-content:center;background:#e6e9f1;color:#c8a96e;font-weight:800;font-size:18px;}'+
        '.nwsb-pv-name{font-size:15px;font-weight:700;color:#1a1a2e;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}'+
        '.nwsb-pv-uname{font-size:12px;color:rgba(0,0,0,.45);margin-top:1px;}'+
        '.nwsb-pv-loc{font-size:12px;color:rgba(0,0,0,.55);font-weight:600;margin-bottom:10px;}'+
        '.nwsb-pv-carousel{display:flex;overflow-x:auto;scroll-snap-type:x mandatory;-webkit-overflow-scrolling:touch;border-radius:16px!important;scrollbar-width:none;}'+
        '.nwsb-pv-carousel::-webkit-scrollbar{display:none;}'+
        '.nwsb-pv-slide{flex:0 0 100%;scroll-snap-align:center;}'+
        '.nwsb-pv-img{width:100%;display:block;border-radius:16px!important;}'+
        '.nwsb-pv-dots{display:flex;align-items:center;justify-content:center;gap:5px;margin:10px 0 2px;}'+
        '.nwsb-pv-dot{width:6px;height:6px;border-radius:50%!important;background:rgba(0,0,0,.18);transition:background .2s,transform .2s;}'+
        '.nwsb-pv-dot.on{background:#c8a96e;transform:scale(1.25);}'+
        '.nwsb-pv-actions{display:flex;align-items:center;gap:12px;margin-top:14px;}'+
        '.nwsb-pv-spacer{flex:1;}'+
        '.nwsb-pv-act{width:44px;height:44px;border:none;border-radius:50%!important;background:#eef0f5;cursor:pointer;box-shadow:4px 4px 10px rgba(0,0,0,.12),-3px -3px 8px rgba(255,255,255,.95);display:flex;align-items:center;justify-content:center;}'+
        '.nwsb-pv-act:active{box-shadow:inset 3px 3px 7px rgba(0,0,0,.13),inset -2px -2px 5px rgba(255,255,255,.92);}'+
        '.nwsb-pv-likes{font-size:13px;font-weight:700;color:#1a1a2e;margin-top:13px;}'+
        '.nwsb-pv-caption{font-size:13px;color:#1a1a2e;line-height:1.45;margin-top:4px;}'+
        '.nwsb-pv-caption b{font-weight:700;}';

      var old=document.getElementById('nwsb-postviewer'); if(old) old.remove();
      var ov=document.createElement('div');
      ov.id='nwsb-postviewer';
      ov.innerHTML='<style>'+css+'</style>'+
        '<div class="nwsb-pv-top">'+avHtml+
          '<div class="nwsb-pv-topmeta"><div class="nwsb-pv-name">'+name+(verifyTierOf(prof)?verifyBadgeImg(verifyTierOf(prof),15):'')+'</div>'+(uname?'<div class="nwsb-pv-uname">'+uname+'</div>':'')+'</div>'+
          '<button class="nwsb-pv-close" aria-label="Close" onclick="var p=document.getElementById(\'nwsb-postviewer\');if(p)p.remove();">&times;</button>'+
        '</div>'+
        '<div class="nwsb-pv-scroll" id="nwsb-pv-scroll">'+cards+'</div>';
      document.body.appendChild(ov);
      // carousel dots follow horizontal scroll
      Array.prototype.forEach.call(ov.querySelectorAll('.nwsb-pv-carousel.multi'), function(car){
        car.addEventListener('scroll', function(){
          var w = car.clientWidth || 1;
          var cur = Math.round(car.scrollLeft / w);
          var dotbox = car.nextElementSibling;
          if(dotbox && dotbox.classList.contains('nwsb-pv-dots')){
            Array.prototype.forEach.call(dotbox.children, function(d,di){ d.classList.toggle('on', di===cur); });
          }
        }, {passive:true});
      });
      setTimeout(function(){
        var t=document.getElementById('nwsb-pv-card-'+idx), sc=document.getElementById('nwsb-pv-scroll');
        if(t&&sc) sc.scrollTop = t.offsetTop - 6;
      },40);
    },
    showFollowers:function(){ (window.nwsbToast||window.alert)('Followers list — coming soon'); },
    editProfile:function(){
      if(typeof openSub==='function'){ openSub('social'); if(typeof ssOpenPanel==='function') setTimeout(function(){ssOpenPanel('profile-edit');},120); }
    },
    shareProfile:function(){ (window.nwsbToast||window.alert)('Share profile — coming soon'); },
    menu:function(){ this.openVerify(); },
    refreshNavAvatar:function(){
      var ud = window._userDataCache;
      var DEFAULT_AVATAR = 'https://res.cloudinary.com/ds6duqabl/image/upload/v1780065459/a84616f0-5b6b-11f1-b4b5-35b4f5e67a31_mureko.png';
      var photoURL = (ud && ud.photoURL) || ME.avatar || '';
      var imgEl  = document.getElementById('ignav-avatar');
      var initEl = document.getElementById('ignav-avatar-init');
      if (imgEl) { imgEl.src = photoURL || DEFAULT_AVATAR; imgEl.style.display = 'block'; }
      if (initEl) initEl.style.display = 'none';
      this._syncExploreAvatar();
    },
    _syncExploreAvatar:function(){
      var ud = window._userDataCache;
      var photoURL = (ud && ud.photoURL) || '';
      var fullName = (ud && ud.displayName) || ME.fullName || '?';
      var imgEl  = document.getElementById('ig-explore-myavatar-img');
      var initEl = document.getElementById('ig-explore-myavatar-init');
      if (photoURL) {
        if (imgEl)  { imgEl.src = photoURL; imgEl.style.display = 'block'; }
        if (initEl) initEl.style.display = 'none';
      } else {
        if (imgEl)  imgEl.style.display = 'none';
        if (initEl) { initEl.textContent = fullName.trim().charAt(0).toUpperCase(); initEl.style.display = 'block'; }
      }
    },
    openMyProfileTab:function(){ this.openMyProfile(); }
  };

  // ── Profile sub-nav controller ──
  window.PSN = {
    go: function(tab) {
      ['profile','nowssb','settings','explore'].forEach(function(t){
        var btn = document.getElementById('psn-'+t);
        if(btn) btn.classList.toggle('active', t===tab);
      });
      if(tab==='profile'){
        if(typeof closeSub==='function') { closeSub('social'); closeSub('profile'); }
        document.getElementById('sub-people').classList.remove('open');
        IG.openMyProfile();
      } else if(tab==='nowssb'){
        document.getElementById('sub-ig-profile').classList.remove('open');
        document.getElementById('sub-people').classList.remove('open');
        if(typeof closeSub==='function') closeSub('social');
        if(typeof openSub==='function') openSub('profile');
      } else if(tab==='settings'){
        document.getElementById('sub-ig-profile').classList.remove('open');
        document.getElementById('sub-people').classList.remove('open');
        if(typeof closeSub==='function') closeSub('profile');
        if(typeof openSub==='function') openSub('social');
      } else if(tab==='explore'){
        if(typeof closeSub==='function') { closeSub('social'); closeSub('profile'); }
        document.getElementById('sub-ig-profile').classList.remove('open');
        IG.openExplore();
      }
    }
  };

  IG.socialNav = function(which) {
      setSocialNavActive(which);
      if (which === 'home') {
        closeNavScreens();
        var mainNav = document.getElementById('ig-bottomnav');
        var socialNav = document.getElementById('ig-social-nav');
        if (socialNav) socialNav.style.display = 'none';
        if (mainNav) mainNav.style.display = '';
        setActiveNav('home');
        if (typeof goTo === 'function') goTo('home');
      } else if (which === 'feed') {
        document.getElementById('sub-ig-profile').classList.remove('open');
        document.getElementById('sub-people').classList.add('open');
        renderExplore(); this.clearSearch();
        var _sc = document.getElementById('ig-people-scroll'); if (_sc) _sc.scrollTop = 0;
      } else if (which === 'profile') {
        this.openMyProfile();
      } else if (which === 'chat') {
        setSocialNavActive('chat');
        if (typeof chatInboxOpen === 'function') chatInboxOpen();
      }
  };

  function setSocialNavActive(which) {
    ['home','feed','profile','me'].forEach(function(k){
      var el = document.getElementById('igsn-'+k);
      if (el) el.classList.toggle('active', k === which);
    });
    // keep the Profile-tab avatar in sync
    var meav = document.getElementById('igsn-me-av');
    var ud = window._userDataCache;
    if (meav && ud && ud.photoURL) {
      meav.style.backgroundImage = 'url(' + ud.photoURL + ')';
      var svg = meav.querySelector('svg'); if (svg) svg.style.display = 'none';
    }
  }

  function closeAllIG(){
    document.getElementById('sub-people').classList.remove('open');
    document.getElementById('sub-ig-profile').classList.remove('open');
  }

  // ── keep nav visible on the four sections; hide on focused screens ──
  function syncNav(){
    var drawer = document.getElementById('menuDrawer');
    if(drawer && drawer.classList.contains('open')){ showNav(false); return; }
    var navScreen=null, focused=false;
    Array.prototype.forEach.call(document.querySelectorAll('.sub-screen'), function(s){
      if(!s.classList.contains('open')) return;
      if(NAV_MAP[s.id]) navScreen=s.id; else focused=true;
    });
    if(focused){ showNav(false); return; }       // player / health / etc. = full focus
    if(navScreen){ showNav(true); setActiveNav(NAV_MAP[navScreen]); return; }
    var onHome = (typeof currentScreen!=='undefined' && (currentScreen==='home'||currentScreen==='home-nm'));
    showNav(onHome);
    if(onHome) setActiveNav('home');
  }

  // wrap navigation functions to keep nav in sync
  function wrap(name){
    var orig = window[name];
    if(typeof orig!=='function') return;
    window[name] = function(){ var r=orig.apply(this,arguments); setTimeout(syncNav,30); return r; };
  }
  ['goTo','showScreen','openSub','closeSub','openMenu','closeMenu'].forEach(wrap);

  // init avatar + first sync once DOM ready
  function boot(){
    IG.refreshNavAvatar();
    syncNav();
  }
  if(document.readyState!=='loading') boot(); else document.addEventListener('DOMContentLoaded',boot);
  // Sync on visibility change (tab switch, lock screen) — not on an interval which causes flicker
  document.addEventListener('visibilitychange', function(){ if(!document.hidden) syncNav(); });
  // Sync after any openSub/closeSub via MutationObserver on sub-screens instead of polling
  (function(){
    var mo = new MutationObserver(function(){ setTimeout(syncNav, 40); });
    var home = document.getElementById('home');
    if(home) mo.observe(home.parentNode || document.body, { childList:false, subtree:true, attributes:true, attributeFilter:['class'] });
  })();
})();

;

/* ══════════════════════════════════════════════════════════
   SETTINGS — functional controllers (sequence build)
═══════════════════════════════════════════════════════════ */
(function(){
  // ── Voice Preference (cycles Female/Male, drives the player) ──
  window.ssCycleVoice = function(){
    var cur = window._pwVoice || 'F';
    var next = cur === 'F' ? 'M' : 'F';
    if (typeof pwSetVoice === 'function') pwSetVoice(next); else window._pwVoice = next;
    var pill = document.getElementById('ss-voice-pill');
    var sub  = document.getElementById('ss-voice-sub');
    if (pill) pill.textContent = next === 'F' ? 'Female' : 'Male';
    if (sub)  sub.textContent  = (next === 'F' ? 'Female' : 'Male') + ' voice';
  };

  // ── Playback Speed (cycles 0.75 / 1.0 / 1.25 / 1.5) ──
  var SPEEDS = [0.75, 1.0, 1.25, 1.5];
  var SPEED_LABELS = {0.75:'Slow', 1:'Normal', 1.25:'Fast', 1.5:'Faster'};
  window.ssCycleSpeed = function(){
    var cur = window._pwSpeed || 1.0;
    var i = SPEEDS.indexOf(cur); if (i < 0) i = 1;
    var next = SPEEDS[(i + 1) % SPEEDS.length];
    window._pwSpeed = next;
    var pill = document.getElementById('ss-speed-pill');
    var sub  = document.getElementById('ss-speed-sub');
    var txt  = (next % 1 === 0 ? next.toFixed(1) : next) + '×';
    if (pill) pill.textContent = txt;
    if (sub)  sub.textContent  = txt + ' ' + (SPEED_LABELS[next] || '');
  };

  // ── Self-contained toggle (defaults ON) for new chat toggles ──
  var _localToggleState = { readreceipts:true, chatsound:true };
  window.ssLocalToggle = function(key, el){
    _localToggleState[key] = !_localToggleState[key];
    var t = document.getElementById('tgl-'+key);
    if (!t) return;
    var knob = t.querySelector('.stgl-knob');
    var on = _localToggleState[key];
    t.style.background = on ? '#e8d5a3' : 'rgba(255,255,255,0.1)';
    if (knob){ knob.style.left = on ? '24px' : '4px'; knob.style.background = on ? '#060c18' : 'rgba(255,255,255,.52)'; }
  };

  // ── Certificates data + render ──
  var CERTS = [
    { word:'AAROGYA',  organ:'Immune System', date:'May 12, 2026', score:96, earned:true  },
    { word:'PRANA',    organ:'Lungs & Breath', date:'May 4, 2026',  score:94, earned:true  },
    { word:'OJAS',     organ:'Vitality',       date:'Apr 28, 2026', score:91, earned:true  },
    { word:'TEJAS',    organ:'Metabolism',     date:null,           score:0,  earned:false },
    { word:'SHAKTI',   organ:'Core Strength',  date:null,           score:0,  earned:false },
  ];
  window.ssRenderCertificates = function(){
    var box = document.getElementById('ss-cert-list'); if (!box) return;
    box.innerHTML = CERTS.map(function(c){
      if (c.earned){
        return '<div style="border:1.5px solid rgba(232,213,163,.3);border-radius:18px;padding:18px;margin-bottom:14px;background:linear-gradient(135deg,rgba(232,213,163,.07),rgba(200,232,245,.04));position:relative;overflow:hidden;">'+
          '<div style="position:absolute;top:-20px;right:-20px;width:80px;height:80px;border-radius:50%;background:#e8d5a3;opacity:.06;filter:blur(18px);"></div>'+
          '<div style="display:flex;align-items:center;gap:12px;">'+
          '<div style="width:46px;height:46px;border-radius:12px;background:rgba(232,213,163,.12);display:flex;align-items:center;justify-content:center;flex-shrink:0;">'+
          '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.5"><circle cx="12" cy="8" r="6"/><polyline points="8.5 13.5 7 22 12 19 17 22 15.5 13.5"/></svg></div>'+
          '<div style="flex:1;"><div style="font-size:17px;font-weight:800;color:#fff;font-family:\'DM Sans\',sans-serif;letter-spacing:.5px;">'+c.word+'</div>'+
          '<div style="font-size:12px;color:rgba(255,255,255,.52);font-family:\'DM Sans\',sans-serif;">'+c.organ+' · mastered '+c.date+'</div></div>'+
          '<div style="text-align:right;"><div style="font-size:18px;font-weight:800;color:#e8d5a3;font-family:\'DM Sans\',sans-serif;">'+c.score+'%</div></div></div></div>';
      }
      return '<div style="border:1px dashed rgba(255,255,255,.1);border-radius:18px;padding:18px;margin-bottom:14px;opacity:.6;">'+
        '<div style="display:flex;align-items:center;gap:12px;">'+
        '<div style="width:46px;height:46px;border-radius:12px;background:rgba(255,255,255,.04);display:flex;align-items:center;justify-content:center;flex-shrink:0;">'+
        '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,.3)" stroke-width="1.5"><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 018 0v4"/></svg></div>'+
        '<div style="flex:1;"><div style="font-size:16px;font-weight:700;color:rgba(255,255,255,.6);font-family:\'DM Sans\',sans-serif;letter-spacing:.5px;">'+c.word+'</div>'+
        '<div style="font-size:12px;color:rgba(255,255,255,.3);font-family:\'DM Sans\',sans-serif;">'+c.organ+' · locked</div></div></div></div>';
    }).join('');
  };

  // ── Privacy selects ──
  var _privacy = { visibility:'Public', age:'Hidden', tier:'Visible', activity:'Hidden' };
  var PRIVACY_DEFS = [
    { key:'visibility', label:'Profile Visibility', sub:'Who can find your profile',  opts:['Public','Followers','Private'] },
    { key:'age',        label:'Show Age',           sub:'Display age range on profile', opts:['Hidden','Visible'] },
    { key:'tier',       label:'Show Plan Badge',    sub:'Display your subscription tier', opts:['Visible','Hidden'] },
    { key:'activity',   label:'Activity Status',    sub:'Show when you were last active', opts:['Hidden','Visible'] },
  ];
  window.ssRenderPrivacySelects = function(){
    var box = document.getElementById('ss-privacy-selects'); if (!box) return;
    box.innerHTML = '<div class="sg" style="padding:0 18px;">'+ PRIVACY_DEFS.map(function(d,i){
      var last = i === PRIVACY_DEFS.length-1;
      return '<div class="sr'+(last?' last':'')+'" onclick="ssCyclePrivacy(\''+d.key+'\',this)">'+
        '<div class="sr-body"><div class="sr-label">'+d.label+'</div><div class="sr-sub">'+d.sub+'</div></div>'+
        '<span id="ss-pv-'+d.key+'" style="font-size:12px;font-weight:700;color:#c8e8f5;background:rgba(200,232,245,.1);padding:4px 12px;border-radius:8px;font-family:\'DM Sans\',sans-serif;">'+_privacy[d.key]+'</span></div>';
    }).join('') + '</div>';
  };
  window.ssCyclePrivacy = function(key){
    var d = PRIVACY_DEFS.find(function(x){return x.key===key;}); if(!d) return;
    var i = d.opts.indexOf(_privacy[key]); _privacy[key] = d.opts[(i+1)%d.opts.length];
    var el = document.getElementById('ss-pv-'+key); if(el) el.textContent = _privacy[key];
  };

  // ── Chat permission options ──
  var _chatPerm = 'Everyone';
  var CHAT_OPTS = ['Everyone','Followers Only','Nobody'];
  window.ssRenderChatPerms = function(){
    var box = document.getElementById('ss-chatperm-options'); if(!box) return;
    box.innerHTML = '<div class="sg" style="padding:0 18px;">' + CHAT_OPTS.map(function(o,i){
      var last = i === CHAT_OPTS.length-1; var sel = o === _chatPerm;
      return '<div class="sr'+(last?' last':'')+'" onclick="ssSetChatPerm(\''+o+'\')">'+
        '<div class="sr-body"><div class="sr-label">'+o+'</div></div>'+
        (sel ? '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="2.2"><path d="M20 6L9 17l-5-5"/></svg>' : '')+
        '</div>';
    }).join('') + '</div>';
  };
  window.ssSetChatPerm = function(o){ _chatPerm = o; ssRenderChatPerms(); };

  // ── Data actions ──
  window.ssDownloadData = function(){
    var data = { account:'nowsbansiu', exportedAt:new Date().toISOString(), routines:5, note:'Full export is generated server-side on the live app.' };
    try {
      var blob = new Blob([JSON.stringify(data,null,2)], {type:'application/json'});
      var a = document.createElement('a'); a.href = URL.createObjectURL(blob);
      a.download = 'nowssb-data.json'; document.body.appendChild(a); a.click(); a.remove();
    } catch(e){ alert('Your data export will be emailed to you.'); }
  };
  window.ssDeleteAccount = function(){
    if (confirm('Permanently delete your account? This cannot be undone. All routines, certificates and progress will be lost.')) {
      if (confirm('Are you absolutely sure? Tap OK to confirm deletion.')) {
        alert('Account deletion requested. You will be signed out.');
        if (typeof ssSignOut === 'function') ssSignOut();
      }
    }
  };

  // ── Wrap ssOpenPanel to render data when the new panels open ──
  function wrapPanel(){
    if (typeof window.ssOpenPanel !== 'function'){ return setTimeout(wrapPanel, 200); }
    var orig = window.ssOpenPanel;
    window.ssOpenPanel = function(id){
      var r = orig.apply(this, arguments);
      if (id === 'certificates') ssRenderCertificates();
      if (id === 'privacy')      ssRenderPrivacySelects();
      if (id === 'chatsettings') ssRenderChatPerms();
      return r;
    };
  }
  wrapPanel();
})();
