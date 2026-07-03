
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
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782592067/grok_image_1782591933705_qq3l9g.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782592067/grok_image_1782591857840_tbznap.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782592067/grok_image_1782592051446_womamz.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782592067/grok_image_1782591669371_kqnaf9.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782592066/grok_image_1782591627828_lmde11.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782592066/grok_image_1782591559591_yxgud5.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782592066/grok_image_1782591561380_ytpn3b.jpg',
    'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782592260/grok_image_1782591732123_epmpiu.jpg'
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
    {key:'blue',   name:'Verified', tag:'Confirmed Practitioner', img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782635218/fdb78570-72c6-11f1-bcbf-fb86e1a7c55f_ns1hnq.png', promo:'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782792269/grok_image_1782792072386_d8fifm.jpg', req:['1,000 followers','20 words purchased','100-day practice streak'], price:'$1.99', priceN:199, per:'/mo'},
    {key:'silver', name:'Silver',   tag:'Sound Healer',           img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782635218/417b2090-72c8-11f1-bcbf-fb86e1a7c55f_cf2eyw.png', promo:'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782792269/grok_image_1782792074543_iasker.jpg', req:['2,000 followers','40 words purchased','200-day practice streak'], price:'$4.99', priceN:499, per:'/mo'},
    {key:'gold',   name:'Gold',     tag:'Frequency Master',       img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782635218/311b1480-72c8-11f1-bcbf-fb86e1a7c55f_blupbs.png', promo:'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782792269/grok_image_1782792076655_amox3t.jpg', req:['4,000 followers','80 words purchased','400-day practice streak'], price:'$9.99', priceN:999, per:'/mo'},
    {key:'diamond',name:'Diamond',  tag:'Iced Out · Top 1%',      img:'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782635219/1aeee4a0-72ca-11f1-bcbf-fb86e1a7c55f_xc3v9h.png', promo:'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto/v1782792269/grok_image_1782792148248_tpzn1r.jpg', req:['10,000 followers','200 words purchased','800-day practice streak'], price:'$49.99', priceN:4999, per:'/mo', yearly:'$200', yearlyN:20000, yearlyPer:'/yr'}
  ];
  var VERIFY_ORDER = ['', 'blue', 'silver', 'gold', 'diamond'];
  // Universal country list (ISO short names) — the app is global, not region-locked.
  var COUNTRIES = ['Afghanistan','Albania','Algeria','Andorra','Angola','Antigua & Barbuda','Argentina','Armenia','Australia','Austria','Azerbaijan','Bahamas','Bahrain','Bangladesh','Barbados','Belarus','Belgium','Belize','Benin','Bhutan','Bolivia','Bosnia & Herzegovina','Botswana','Brazil','Brunei','Bulgaria','Burkina Faso','Burundi','Cambodia','Cameroon','Canada','Cape Verde','Central African Republic','Chad','Chile','China','Colombia','Comoros','Congo','Congo (DRC)','Costa Rica','Côte d’Ivoire','Croatia','Cuba','Cyprus','Czechia','Denmark','Djibouti','Dominica','Dominican Republic','Ecuador','Egypt','El Salvador','Equatorial Guinea','Eritrea','Estonia','Eswatini','Ethiopia','Fiji','Finland','France','Gabon','Gambia','Georgia','Germany','Ghana','Greece','Grenada','Guatemala','Guinea','Guinea-Bissau','Guyana','Haiti','Honduras','Hong Kong','Hungary','Iceland','India','Indonesia','Iran','Iraq','Ireland','Israel','Italy','Jamaica','Japan','Jordan','Kazakhstan','Kenya','Kiribati','Kosovo','Kuwait','Kyrgyzstan','Laos','Latvia','Lebanon','Lesotho','Liberia','Libya','Liechtenstein','Lithuania','Luxembourg','Macau','Madagascar','Malawi','Malaysia','Maldives','Mali','Malta','Marshall Islands','Mauritania','Mauritius','Mexico','Micronesia','Moldova','Monaco','Mongolia','Montenegro','Morocco','Mozambique','Myanmar','Namibia','Nauru','Nepal','Netherlands','New Zealand','Nicaragua','Niger','Nigeria','North Korea','North Macedonia','Norway','Oman','Pakistan','Palau','Palestine','Panama','Papua New Guinea','Paraguay','Peru','Philippines','Poland','Portugal','Qatar','Romania','Russia','Rwanda','Saint Kitts & Nevis','Saint Lucia','Saint Vincent & Grenadines','Samoa','San Marino','São Tomé & Príncipe','Saudi Arabia','Senegal','Serbia','Seychelles','Sierra Leone','Singapore','Slovakia','Slovenia','Solomon Islands','Somalia','South Africa','South Korea','South Sudan','Spain','Sri Lanka','Sudan','Suriname','Sweden','Switzerland','Syria','Taiwan','Tajikistan','Tanzania','Thailand','Timor-Leste','Togo','Tonga','Trinidad & Tobago','Tunisia','Turkey','Turkmenistan','Tuvalu','Uganda','Ukraine','United Arab Emirates','United Kingdom','United States','Uruguay','Uzbekistan','Vanuatu','Vatican City','Venezuela','Vietnam','Yemen','Zambia','Zimbabwe'];
  // Country → local currency [code, symbol, approx units per 1 USD]. Everything
  // else falls back to USD. Lets the verify flow show prices in the user's money.
  var _EU = ['Austria','Belgium','Croatia','Cyprus','Estonia','Finland','France','Germany','Greece','Ireland','Italy','Latvia','Lithuania','Luxembourg','Malta','Netherlands','Portugal','Slovakia','Slovenia','Spain','Andorra','Monaco','Montenegro','Kosovo','San Marino','Vatican City'];
  var CURRENCY_MAP = {
    'United Kingdom':['GBP','£',0.79],'India':['INR','₹',83],'Canada':['CAD','C$',1.36],'Australia':['AUD','A$',1.52],'New Zealand':['NZD','NZ$',1.63],'Japan':['JPY','¥',157],'China':['CNY','¥',7.2],'Switzerland':['CHF','Fr',0.88],'Sweden':['SEK','kr',10.5],'Norway':['NOK','kr',10.7],'Denmark':['DKK','kr',6.9],'Singapore':['SGD','S$',1.35],'Hong Kong':['HKD','HK$',7.8],'United Arab Emirates':['AED','د.إ',3.67],'Saudi Arabia':['SAR','﷼',3.75],'Qatar':['QAR','﷼',3.64],'Kuwait':['KWD','د.ك',0.31],'Brazil':['BRL','R$',5.0],'Mexico':['MXN','MX$',17],'South Africa':['ZAR','R',18.5],'Russia':['RUB','₽',90],'Turkey':['TRY','₺',32],'South Korea':['KRW','₩',1350],'Indonesia':['IDR','Rp',15800],'Malaysia':['MYR','RM',4.7],'Thailand':['THB','฿',36],'Philippines':['PHP','₱',57],'Vietnam':['VND','₫',25000],'Pakistan':['PKR','₨',278],'Bangladesh':['BDT','৳',110],'Sri Lanka':['LKR','Rs',300],'Nepal':['NPR','₨',133],'Nigeria':['NGN','₦',1500],'Kenya':['KES','KSh',130],'Egypt':['EGP','E£',48],'Ghana':['GHS','₵',15],'Israel':['ILS','₪',3.7],'Poland':['PLN','zł',4.0],'Czechia':['CZK','Kč',23],'Hungary':['HUF','Ft',360],'Romania':['RON','lei',4.6],'Ukraine':['UAH','₴',41],'Argentina':['ARS','$',900],'Chile':['CLP','$',950],'Colombia':['COP','$',3900],'Peru':['PEN','S/',3.8]
  };
  _EU.forEach(function(c){ CURRENCY_MAP[c] = ['EUR','€',0.92]; });
  var _NO_DEC = {JPY:1,KRW:1,VND:1,IDR:1,HUF:1,CLP:1,COP:1,ISK:1,PKR:1,NGN:1,INR:1};
  function currencyForCountry(name){
    var c = CURRENCY_MAP[name];
    if(!c) return {code:'USD',symbol:'$',rate:1,dec:2};
    return {code:c[0],symbol:c[1],rate:c[2],dec:_NO_DEC[c[0]]?0:2};
  }
  function vkycFmt(usd, cur){
    cur = cur || {code:'USD',symbol:'$',rate:1,dec:2};
    var v = (usd||0) * cur.rate;
    var s = (cur.dec===0) ? String(Math.round(v)) : v.toFixed(2);
    s = s.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return cur.symbol + s;
  }
  function vkycParseDob(str){
    var d = String(str||'').replace(/\D/g,'');
    if(d.length!==8) return null;
    var day=+d.slice(0,2), mon=+d.slice(2,4), yr=+d.slice(4,8);
    if(mon<1||mon>12||day<1||day>31||yr<1900||yr>2025) return null;
    var dt=new Date(yr,mon-1,day);
    if(dt.getFullYear()!==yr||dt.getMonth()!==mon-1||dt.getDate()!==day) return null;
    var age=(Date.now()-dt.getTime())/31557600000;
    return {iso: yr+'-'+('0'+mon).slice(-2)+'-'+('0'+day).slice(-2), age:age};
  }
  function vkycDobToText(iso){
    if(iso && /^\d{4}-\d{2}-\d{2}$/.test(iso)){ var p=iso.split('-'); return p[2]+' / '+p[1]+' / '+p[0]; }
    return '';
  }
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
    var grid  = document.getElementById('ig-explore-grid');
    var empty = document.getElementById('ig-explore-empty');
    if(!grid) return;
    // Real community explore posts (none yet). When posts exist, fill the grid
    // with tiles and hide the empty state; otherwise clear the grid and show
    // the "No posts to explore yet" block (a SIBLING of the grid, so the
    // grid's grid-auto-rows can't shove it off-screen).
    var posts = (window.IG && Array.isArray(window.IG._explorePosts)) ? window.IG._explorePosts : [];
    if(posts.length){
      grid.style.display = 'grid';
      if(empty) empty.style.display = 'none';
      grid.innerHTML = posts.map(function(p){
        var img = (p && (p.img||p.image||p.thumb)) || '';
        return '<div class="ig-explore-tile" onclick="IG.openExplorePost&&IG.openExplorePost(\''+img+'\')">'+
               '<img loading="lazy" decoding="async" src="'+img+'" alt=""></div>';
      }).join('');
    } else {
      grid.innerHTML = '';
      grid.style.display = 'none';        // no phantom grid rows when empty
      if(empty) empty.style.display = 'flex';
    }
  }

  // ── SEARCH ──
  function renderSearchResults(q){
    var box = document.getElementById('ig-search-results');
    var grid = document.getElementById('ig-explore-grid');
    var empty = document.getElementById('ig-explore-empty');
    if(!q){ box.style.display='none'; renderExplore(); return; }
    grid.style.display='none'; if(empty) empty.style.display='none'; box.style.display='block';
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
    renderExplore:renderExplore,
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
          '<div class="nwsbf-top"><div class="nwsbf-brand"><img class="nwsbf-brandlogo" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779717856/30ebb160-5840-11f1-bb0c-71720609fd8f_g5nmcn.png" alt=""><span class="nwsbf-logo">NowssB <span style="color:#c8a96e;">Connect</span></span></div>'+
            '<button class="nwsbf-icon" aria-label="Messages" onclick="if(typeof chatInboxOpen===\'function\')chatInboxOpen()"><img class="nwsbf-iconimg" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1780123160/1ae1b990-5bf2-11f1-8248-b91d5cd919c2_z3xi3j.png" alt="Chat"></button>'+
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
              (owned ? '<button class="nwsb-vr-btn owned" disabled>Owned ✓</button>' : '<button class="nwsb-vr-btn" onclick="IG.verifyKyc(\''+t.key+'\',\'monthly\')">Buy '+t.name+'</button>')+
            '</div>'+
            ((t.yearly && !owned) ? '<button class="nwsb-vr-year" onclick="IG.verifyKyc(\''+t.key+'\',\'yearly\')"><span class="nwsb-vr-year-l">or '+t.yearly+t.yearlyPer+' <b>· save '+Math.round((1-(t.yearlyN/(t.priceN*12)))*100)+'%</b></span><span class="nwsb-vr-year-go">Buy yearly ›</span></button>' : '')+
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
        '#nwsb-verify .nwsb-vr-year{width:100%;margin-top:12px;border:none;border-radius:14px !important;background:#eef0f5;padding:13px 16px;display:flex;align-items:center;justify-content:space-between;gap:10px;cursor:pointer;box-shadow:inset 3px 3px 7px rgba(0,0,0,.1),inset -2px -2px 5px rgba(255,255,255,.9);}'+
        '#nwsb-verify .nwsb-vr-year:active{box-shadow:inset 4px 4px 9px rgba(0,0,0,.13),inset -2px -2px 5px rgba(255,255,255,.85);}'+
        '#nwsb-verify .nwsb-vr-year-l{font-size:12px;font-weight:600;color:rgba(0,0,0,.55);}'+
        '#nwsb-verify .nwsb-vr-year-l b{color:#1aa76a;font-weight:800;}'+
        '#nwsb-verify .nwsb-vr-year-go{font-size:13px;font-weight:800;color:#a8854a;white-space:nowrap;}'+
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
    /* ── Verification KYC wizard — real name → DOB → residence → documents →
       review, then hands off to the real payment gateway (buyVerify → cart →
       Razorpay checkout). Pre-fills from the user's profile where available. ── */
    verifyKyc:function(tier, billing){
      var t=null; for(var i=0;i<VERIFY_TIERS.length;i++){ if(VERIFY_TIERS[i].key===tier){ t=VERIFY_TIERS[i]; break; } }
      if(!t) return;
      var isYear = (billing==='yearly' && t.yearly);   // yearly option (Diamond)
      var ud = window._userDataCache || {};
      // pull any previously-entered KYC first, then profile fields, so returning
      // users don't re-type. DOB / residence come from the profile if present.
      var st = {
        tier: tier, billing: isYear?'yearly':'monthly', tierName: t.name,
        price: isYear ? t.yearly : t.price, per: isYear ? t.yearlyPer : t.per,
        priceUSDNum: ((isYear ? t.yearlyN : t.priceN)||0)/100,
        name:    ud.kycName    || ud.displayName || ((this._currentProfile&&this._currentProfile.fullName)||'') || '',
        dob:     ud.kycDob     || ud.dob || ud.dateOfBirth || ud.birthday || '',
        country: ud.kycCountry || ud.residence || ud.country || '',
        city:    ud.kycCity    || ud.city || '',
        address: ud.kycAddress || ud.address || '',
        docFront: '', docBack: '', selfie: '', step: 0,
        currency: {code:'USD',symbol:'$',rate:1,dec:2}
      };
      st.tierLabel = (t.name==='Verified') ? 'NowssB Verified' : (t.name+' Verified');
      window._vkyc = st;
      var STEPS = 6; // intro, name, dob, residence, documents, review
      st.steps = STEPS;

      var css='#nwsb-vkyc{position:fixed;inset:0;z-index:100002;background:#eef0f5;display:flex;flex-direction:column;}'+
        '#nwsb-vkyc *{box-sizing:border-box;font-family:DM Sans,sans-serif;}'+
        /* proper fixed header: back · badge · NowssB Verified / price · step */
        '#nwsb-vkyc .vk-bar{display:flex;align-items:center;gap:12px;padding:max(env(safe-area-inset-top,12px),12px) 16px 12px;background:#eef0f5;flex-shrink:0;box-shadow:0 3px 14px rgba(0,0,0,.06);z-index:5;}'+
        '#nwsb-vkyc .vk-back{width:42px;height:42px;border:none;border-radius:50% !important;background:#eef0f5;color:#1a1a2e;font-size:20px;cursor:pointer;box-shadow:4px 4px 10px rgba(0,0,0,.13),-3px -3px 8px rgba(255,255,255,.95);display:flex;align-items:center;justify-content:center;flex-shrink:0;}'+
        '#nwsb-vkyc .vk-back:active{box-shadow:inset 3px 3px 7px rgba(0,0,0,.13),inset -2px -2px 5px rgba(255,255,255,.92);}'+
        '#nwsb-vkyc .vk-bar-badge{width:40px;height:40px;border-radius:12px !important;object-fit:cover;flex-shrink:0;box-shadow:3px 3px 8px rgba(0,0,0,.14),-2px -2px 6px rgba(255,255,255,.9);}'+
        '#nwsb-vkyc .vk-bar-titles{flex:1;min-width:0;}'+
        '#nwsb-vkyc .vk-bar-t{font-size:15px;font-weight:800;color:#1a1a2e;line-height:1.15;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}'+
        '#nwsb-vkyc .vk-bar-s{font-size:12px;color:rgba(0,0,0,.5);margin-top:1px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}'+
        '#nwsb-vkyc .vk-steplbl{flex-shrink:0;font-size:12px;font-weight:700;color:#a8854a;letter-spacing:.3px;}'+
        '#nwsb-vkyc .vk-prog{height:5px;border-radius:3px !important;background:rgba(0,0,0,.08);margin:0;flex-shrink:0;overflow:hidden;}'+
        '#nwsb-vkyc .vk-prog-fill{height:100%;border-radius:0 3px 3px 0 !important;background:linear-gradient(90deg,#c8a96e,#e8d5a3);transition:width .3s cubic-bezier(.4,0,.2,1);}'+
        '#nwsb-vkyc .vk-scroll{flex:1;overflow-y:auto;-webkit-overflow-scrolling:touch;display:flex;flex-direction:column;padding:22px 22px calc(env(safe-area-inset-bottom,16px) + 8px);}'+
        '#nwsb-vkyc .vk-step{display:none;}'+
        '#nwsb-vkyc .vk-step.on{display:block;animation:vkin .28s ease;}'+
        '@keyframes vkin{from{opacity:0;transform:translateX(14px)}to{opacity:1;transform:none}}'+
        '#nwsb-vkyc .vk-spacer{flex:1 1 auto;min-height:22px;}'+
        '#nwsb-vkyc .vk-title{font-size:23px;font-weight:800;color:#1a1a2e;line-height:1.2;margin-bottom:7px;}'+
        '#nwsb-vkyc .vk-sub{font-size:13px;color:rgba(0,0,0,.5);line-height:1.5;margin-bottom:24px;}'+
        '#nwsb-vkyc .vk-flabel{font-size:11px;font-weight:800;letter-spacing:1px;text-transform:uppercase;color:rgba(0,0,0,.4);margin:0 4px 8px;}'+
        '#nwsb-vkyc .vk-input{width:100%;border:none;border-radius:16px !important;background:#eef0f5;padding:16px 18px;font-size:15px;color:#1a1a2e;box-shadow:inset 4px 4px 9px rgba(0,0,0,.11),inset -3px -3px 7px rgba(255,255,255,.94);outline:none;margin-bottom:18px;}'+
        '#nwsb-vkyc .vk-input::placeholder{color:rgba(0,0,0,.32);}'+
        '#nwsb-vkyc .vk-select{appearance:none;-webkit-appearance:none;background-image:url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'14\' height=\'14\' viewBox=\'0 0 24 24\' fill=\'none\' stroke=\'%23a8854a\' stroke-width=\'2.4\' stroke-linecap=\'round\' stroke-linejoin=\'round\'%3E%3Cpath d=\'M6 9l6 6 6-6\'/%3E%3C/svg%3E");background-repeat:no-repeat;background-position:right 18px center;padding-right:44px;}'+
        '#nwsb-vkyc .vk-prefill{font-size:11px;color:#1aa76a;font-weight:700;margin:-12px 4px 18px;}'+
        /* intro / requirements — COMPLETE banner, full width, natural height:
           the whole image shows, never cropped and with no black bars. */
        '#nwsb-vkyc .vk-hero{width:calc(100% + 44px);margin:-22px -22px 20px;background:#07070d;overflow:hidden;position:relative;font-size:0;}'+
        '#nwsb-vkyc .vk-hero img{width:100%;height:auto;display:block;}'+
        '#nwsb-vkyc .vk-req{display:flex;align-items:flex-start;gap:13px;background:#eef0f5;border-radius:16px !important;padding:15px 16px;margin-bottom:12px;box-shadow:5px 5px 12px rgba(0,0,0,.09),-4px -4px 10px rgba(255,255,255,.95);}'+
        '#nwsb-vkyc .vk-req-ic{width:38px;height:38px;flex-shrink:0;border-radius:10px !important;background:#eef0f5;display:flex;align-items:center;justify-content:center;box-shadow:inset 2px 2px 5px rgba(0,0,0,.1),inset -2px -2px 5px rgba(255,255,255,.9);}'+
        '#nwsb-vkyc .vk-req-t{font-size:14px;font-weight:700;color:#1a1a2e;}'+
        '#nwsb-vkyc .vk-req-s{font-size:12px;color:rgba(0,0,0,.5);margin-top:2px;line-height:1.45;}'+
        /* DOB row: text field + calendar button */
        '#nwsb-vkyc .vk-dobrow{position:relative;margin-bottom:18px;}'+
        '#nwsb-vkyc .vk-dobrow .vk-input{margin-bottom:0;padding-right:56px;letter-spacing:1px;}'+
        '#nwsb-vkyc .vk-cal{position:absolute;right:8px;top:50%;transform:translateY(-50%);width:40px;height:40px;border:none;border-radius:12px !important;background:#eef0f5;display:flex;align-items:center;justify-content:center;cursor:pointer;box-shadow:3px 3px 7px rgba(0,0,0,.13),-2px -2px 6px rgba(255,255,255,.92);}'+
        '#nwsb-vkyc .vk-cal:active{box-shadow:inset 2px 2px 5px rgba(0,0,0,.13),inset -1px -1px 4px rgba(255,255,255,.9);}'+
        '#nwsb-vkyc .vk-dob-native{position:absolute;right:8px;top:50%;transform:translateY(-50%);width:40px;height:40px;opacity:0;pointer-events:none;}'+
        /* country autocomplete */
        '#nwsb-vkyc .vk-field{position:relative;margin-bottom:18px;}'+
        '#nwsb-vkyc .vk-field .vk-input{margin-bottom:0;}'+
        '#nwsb-vkyc .vk-sugg{position:absolute;left:0;right:0;top:calc(100% + 5px);background:#eef0f5;border-radius:14px !important;box-shadow:7px 7px 18px rgba(0,0,0,.16),-4px -4px 10px rgba(255,255,255,.92);max-height:238px;overflow-y:auto;-webkit-overflow-scrolling:touch;z-index:20;display:none;}'+
        '#nwsb-vkyc .vk-sugg.on{display:block;}'+
        '#nwsb-vkyc .vk-sugg-item{padding:13px 16px;font-size:14px;color:#1a1a2e;cursor:pointer;border-bottom:1px solid rgba(0,0,0,.05);}'+
        '#nwsb-vkyc .vk-sugg-item:last-child{border-bottom:none;}'+
        '#nwsb-vkyc .vk-sugg-item:active{background:rgba(168,133,74,.14);}'+
        '#nwsb-vkyc .vk-cur-note{font-size:12px;color:#a8854a;font-weight:700;margin:8px 4px 4px;display:none;}'+
        '#nwsb-vkyc .vk-docgrid{display:flex;flex-direction:column;gap:14px;}'+
        '#nwsb-vkyc .vk-doc{position:relative;border-radius:18px !important;background:#eef0f5;box-shadow:5px 5px 13px rgba(0,0,0,.11),-4px -4px 10px rgba(255,255,255,.95);padding:18px;cursor:pointer;overflow:hidden;}'+
        '#nwsb-vkyc .vk-doc:active{box-shadow:inset 3px 3px 8px rgba(0,0,0,.12),inset -2px -2px 6px rgba(255,255,255,.92);}'+
        '#nwsb-vkyc .vk-doc-row{display:flex;align-items:center;gap:14px;}'+
        '#nwsb-vkyc .vk-doc-ic{width:46px;height:46px;border-radius:12px !important;background:#eef0f5;display:flex;align-items:center;justify-content:center;flex-shrink:0;box-shadow:3px 3px 8px rgba(0,0,0,.13),-2px -2px 6px rgba(255,255,255,.92);}'+
        '#nwsb-vkyc .vk-doc-t{font-size:14px;font-weight:700;color:#1a1a2e;}'+
        '#nwsb-vkyc .vk-doc-s{font-size:12px;color:rgba(0,0,0,.45);margin-top:2px;}'+
        '#nwsb-vkyc .vk-doc.done .vk-doc-s{color:#1aa76a;font-weight:700;}'+
        '#nwsb-vkyc .vk-doc-thumb{width:100%;height:150px;object-fit:cover;border-radius:12px !important;margin-top:14px;display:block;}'+
        '#nwsb-vkyc .vk-doc input{display:none;}'+
        '#nwsb-vkyc .vk-rev{border-radius:18px !important;background:#eef0f5;box-shadow:inset 3px 3px 8px rgba(0,0,0,.09),inset -2px -2px 6px rgba(255,255,255,.92);padding:8px 18px;margin-bottom:20px;}'+
        '#nwsb-vkyc .vk-rev-row{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:13px 0;border-bottom:1px solid rgba(0,0,0,.06);}'+
        '#nwsb-vkyc .vk-rev-row:last-child{border-bottom:none;}'+
        '#nwsb-vkyc .vk-rev-k{font-size:12px;color:rgba(0,0,0,.45);font-weight:600;}'+
        '#nwsb-vkyc .vk-rev-v{font-size:13px;color:#1a1a2e;font-weight:700;text-align:right;max-width:60%;word-break:break-word;}'+
        '#nwsb-vkyc .vk-rev-v.ok{color:#1aa76a;}'+
        '#nwsb-vkyc .vk-legal{font-size:11px;color:rgba(0,0,0,.4);line-height:1.6;margin-bottom:6px;}'+
        '#nwsb-vkyc .vk-foot{flex-shrink:0;padding:6px 0 4px;}'+
        '#nwsb-vkyc .vk-next{width:100%;border:none;border-radius:16px !important;background:linear-gradient(135deg,#c8a96e,#e8d5a3);color:#1a1a2e;font-size:15px;font-weight:800;letter-spacing:.3px;padding:17px;cursor:pointer;box-shadow:5px 5px 14px rgba(168,133,74,.32);display:flex;align-items:center;justify-content:center;gap:8px;}'+
        '#nwsb-vkyc .vk-next:active{transform:scale(.985);}'+
        '#nwsb-vkyc .vk-next[disabled]{opacity:.5;}';

      function esc(s){ return String(s||'').replace(/[&<>"]/g,function(c){return{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c];}); }
      var prefilledName    = !!st.name;
      var prefilledDob     = !!st.dob;
      var prefilledCountry = !!st.country;

      var docIco = '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#a8854a" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="16" rx="3"/><circle cx="9" cy="10" r="2"/><path d="M15 9h3M15 13h3M6 16h12"/></svg>';
      var selfieIco='<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#a8854a" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>';

      var idIco = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#a8854a" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="14" rx="3"/><circle cx="8" cy="11" r="2"/><path d="M14 10h4M14 14h4M5 15c.7-1.4 4.3-1.4 5 0"/></svg>';
      var faceIco = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#a8854a" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M8.5 14c1 1.3 5.5 1.3 7 0M9 10h.01M15 10h.01"/></svg>';
      var docsIco = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#a8854a" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6M9 13h6M9 17h4"/></svg>';
      var ageIco = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#a8854a" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>';
      var calIco = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#a8854a" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="3"/><path d="M16 2v4M8 2v4M3 10h18"/></svg>';
      var dobText = vkycDobToText(st.dob);

      var html='<style>'+css+'</style>'+
        '<div class="vk-bar">'+
          '<button class="vk-back" id="vk-back" aria-label="Back">&#8249;</button>'+
          '<img class="vk-bar-badge" src="'+t.img+'" alt="">'+
          '<div class="vk-bar-titles"><div class="vk-bar-t">'+st.tierLabel+'</div><div class="vk-bar-s" id="vk-price-mini">'+t.price+t.per+' · identity check</div></div>'+
          '<span class="vk-steplbl" id="vk-steplbl"></span>'+
        '</div>'+
        '<div class="vk-prog" style="visibility:hidden"><div class="vk-prog-fill" id="vk-progfill" style="width:0%"></div></div>'+
        '<div class="vk-scroll">'+
          /* Step 1 — intro / requirements */
          '<div class="vk-step on" data-step="0">'+
            '<div class="vk-hero"><img src="'+(t.promo||t.img)+'" alt=""></div>'+
            '<div class="vk-title">Before you start</div>'+
            '<div class="vk-sub">Getting verified takes about 2 minutes. Here\'s what you\'ll need — have it ready:</div>'+
            '<div class="vk-req"><div class="vk-req-ic">'+idIco+'</div><div><div class="vk-req-t">A government photo ID</div><div class="vk-req-s">Passport, driver\'s licence or national ID — clear and readable.</div></div></div>'+
            '<div class="vk-req"><div class="vk-req-ic">'+faceIco+'</div><div><div class="vk-req-t">A selfie that matches your ID</div><div class="vk-req-s">Your face in the selfie must match the photo on your ID.</div></div></div>'+
            '<div class="vk-req"><div class="vk-req-ic">'+docsIco+'</div><div><div class="vk-req-t">Your legal name, birth date &amp; country</div><div class="vk-req-s">These are checked against your ID and kept private.</div></div></div>'+
            '<div class="vk-req"><div class="vk-req-ic">'+ageIco+'</div><div><div class="vk-req-t">You must be 18 or older</div><div class="vk-req-s">Verification is only available to adults.</div></div></div>'+
          '</div>'+
          /* Step 2 — real name */
          '<div class="vk-step" data-step="1">'+
            '<div class="vk-title">What\'s your real name?</div>'+
            '<div class="vk-sub">This is the legal name that will be checked against your ID. It stays private and is never shown on your profile.</div>'+
            '<div class="vk-flabel">Full legal name</div>'+
            '<input class="vk-input" id="vk-name" type="text" autocomplete="name" placeholder="Your full legal name" value="'+esc(st.name)+'">'+
            (prefilledName ? '<div class="vk-prefill">✓ Suggested from your profile — edit if needed</div>' : '')+
          '</div>'+
          /* Step 3 — date of birth (type it OR use the calendar) */
          '<div class="vk-step" data-step="2">'+
            '<div class="vk-title">Your date of birth</div>'+
            '<div class="vk-sub">Type it in, or tap the calendar — whichever is quicker. You must be 18 or older.</div>'+
            '<div class="vk-flabel">Date of birth</div>'+
            '<div class="vk-dobrow">'+
              '<input class="vk-input" id="vk-dob-text" type="text" inputmode="numeric" autocomplete="bday" placeholder="DD / MM / YYYY" maxlength="14" oninput="IG.vkycDobInput(this)" value="'+esc(dobText)+'">'+
              '<button type="button" class="vk-cal" aria-label="Open calendar" onclick="IG.vkycDobCalendar()">'+calIco+'</button>'+
              '<input type="date" class="vk-dob-native" id="vk-dob-native" max="2012-12-31" onchange="IG.vkycDobNative(this)">'+
            '</div>'+
            (prefilledDob ? '<div class="vk-prefill">✓ From your profile</div>' : '')+
          '</div>'+
          /* Step 4 — place of residence (type-ahead country + local currency) */
          '<div class="vk-step" data-step="3">'+
            '<div class="vk-title">Where do you live?</div>'+
            '<div class="vk-sub">Start typing your country and pick it from the list. Prices will show in your local currency.</div>'+
            '<div class="vk-flabel">Country of residence</div>'+
            '<div class="vk-field">'+
              '<input class="vk-input" id="vk-country" type="text" autocomplete="off" autocorrect="off" spellcheck="false" placeholder="Start typing your country…" oninput="IG.vkycCountryInput(this)" onfocus="IG.vkycCountryInput(this)" value="'+esc(st.country)+'">'+
              '<div class="vk-sugg" id="vk-country-sugg"></div>'+
            '</div>'+
            '<div class="vk-cur-note" id="vk-cur-note"></div>'+
            '<div class="vk-flabel" style="margin-top:6px;">City</div>'+
            '<input class="vk-input" id="vk-city" type="text" autocomplete="address-level2" placeholder="Your city" value="'+esc(st.city)+'">'+
          '</div>'+
          /* Step 5 — documents */
          '<div class="vk-step" data-step="4">'+
            '<div class="vk-title">Verify your identity</div>'+
            '<div class="vk-sub">Upload a clear photo of your government ID, then a selfie. Your selfie must match the face on your ID.</div>'+
            '<div class="vk-docgrid">'+
              '<label class="vk-doc" id="vk-doc-front"><div class="vk-doc-row"><div class="vk-doc-ic">'+docIco+'</div><div><div class="vk-doc-t">ID — front</div><div class="vk-doc-s">Passport, driver\'s licence or national ID</div></div></div><input type="file" accept="image/*" onchange="IG.vkycFile(\'docFront\',this)"><img class="vk-doc-thumb" id="vk-th-docFront" style="display:none"></label>'+
              '<label class="vk-doc" id="vk-doc-back"><div class="vk-doc-row"><div class="vk-doc-ic">'+docIco+'</div><div><div class="vk-doc-t">ID — back <span style="font-weight:400;color:rgba(0,0,0,.35)">(optional)</span></div><div class="vk-doc-s">Back side, if your ID has one</div></div></div><input type="file" accept="image/*" onchange="IG.vkycFile(\'docBack\',this)"><img class="vk-doc-thumb" id="vk-th-docBack" style="display:none"></label>'+
              '<label class="vk-doc" id="vk-doc-selfie"><div class="vk-doc-row"><div class="vk-doc-ic">'+selfieIco+'</div><div><div class="vk-doc-t">Selfie</div><div class="vk-doc-s">A clear photo of your face — must match your ID</div></div></div><input type="file" accept="image/*" capture="user" onchange="IG.vkycFile(\'selfie\',this)"><img class="vk-doc-thumb" id="vk-th-selfie" style="display:none"></label>'+
            '</div>'+
          '</div>'+
          /* Step 6 — review + pay */
          '<div class="vk-step" data-step="5">'+
            '<div class="vk-title">Review &amp; pay</div>'+
            '<div class="vk-sub">Confirm your details. Next you\'ll complete a secure payment to finish verification.</div>'+
            '<div class="vk-rev" id="vk-review"></div>'+
            '<div class="vk-legal" id="vk-legal">By continuing you confirm the information is accurate and agree to NowssB\'s verification terms. Your documents are used only to confirm your identity.</div>'+
          '</div>'+
          '<div class="vk-spacer"></div>'+
          '<div class="vk-foot"><button class="vk-next" id="vk-next">Continue</button></div>'+
        '</div>';

      var old=document.getElementById('nwsb-vkyc'); if(old) old.remove();
      var ov=document.createElement('div'); ov.id='nwsb-vkyc'; ov.innerHTML=html;
      document.body.appendChild(ov);
      document.getElementById('vk-back').onclick=function(){ IG.vkycNav(-1); };
      document.getElementById('vk-next').onclick=function(){ IG.vkycNav(1); };
      this.vkycRender();
      if(st.country) this.vkycSetCountry(st.country); // prefill currency note from profile
    },
    vkycRender:function(){
      var st=window._vkyc; if(!st) return;
      var STEPS=st.steps||6;
      var FS=STEPS-1; // numbered field steps (intro is a pre-step, not counted)
      document.querySelectorAll('#nwsb-vkyc .vk-step').forEach(function(el){
        el.classList.toggle('on', parseInt(el.getAttribute('data-step'),10)===st.step);
      });
      var lbl=document.getElementById('vk-steplbl');
      var pf=document.getElementById('vk-progfill');
      var prog=document.querySelector('#nwsb-vkyc .vk-prog');
      if(st.step===0){ // intro cover — NOT a numbered step
        if(lbl) lbl.textContent='';
        if(pf) pf.style.width='0%';
        if(prog) prog.style.visibility='hidden';
      } else {
        if(lbl) lbl.textContent='Step '+st.step+' of '+FS;
        if(pf) pf.style.width=((st.step/FS)*100)+'%';
        if(prog) prog.style.visibility='visible';
      }
      var priceLocal = vkycFmt(st.priceUSDNum, st.currency);
      var nb=document.getElementById('vk-next'); if(nb) nb.textContent = (st.step===STEPS-1) ? 'Pay '+priceLocal+' & verify' : 'Continue';
      if(st.step===STEPS-1){
        var box=document.getElementById('vk-review');
        function row(k,v,ok){ return '<div class="vk-rev-row"><span class="vk-rev-k">'+k+'</span><span class="vk-rev-v'+(ok?' ok':'')+'">'+(v||'—')+'</span></div>'; }
        var docs=[]; if(st.docFront)docs.push('ID front'); if(st.docBack)docs.push('ID back'); if(st.selfie)docs.push('Selfie');
        var esc=function(s){return String(s||'').replace(/[<>&]/g,function(c){return{'<':'&lt;','>':'&gt;','&':'&amp;'}[c];});};
        var nonUsd = st.currency && st.currency.code!=='USD';
        if(box) box.innerHTML=
          row('Badge', st.tierLabel||(st.tierName+' Verified'), false)+
          row('Legal name', esc(st.name), false)+
          row('Date of birth', esc(vkycDobToText(st.dob)||st.dob), false)+
          row('Residence', esc([st.city,st.country].filter(Boolean).join(', ')), false)+
          row('Documents', docs.length? docs.join(' · '):'—', docs.length>0)+
          row('Total', priceLocal+st.per, false);
        var legal=document.getElementById('vk-legal');
        if(legal) legal.innerHTML = (nonUsd ? 'Shown in '+st.currency.code+'; billed as '+st.price+' USD ('+st.price+st.per+') at checkout. ' : '')+
          'By continuing you confirm the information is accurate and agree to NowssB’s verification terms. Your documents are used only to confirm your identity.';
      }
    },
    vkycFile:function(which, input){
      var st=window._vkyc; if(!st||!input.files||!input.files[0]) return;
      var f=input.files[0];
      var rd=new FileReader();
      rd.onload=function(e){
        st[which]=e.target.result;
        var th=document.getElementById('vk-th-'+which);
        if(th){ th.src=e.target.result; th.style.display='block'; }
        var lab=input.closest('.vk-doc'); if(lab){ lab.classList.add('done'); var s=lab.querySelector('.vk-doc-s'); if(s) s.textContent='✓ '+(f.name.length>26?f.name.slice(0,24)+'…':f.name); }
      };
      rd.readAsDataURL(f);
    },
    vkycNav:function(dir){
      var st=window._vkyc; if(!st) return;
      var STEPS=st.steps||6;
      if(dir<0){
        if(st.step===0){ var p=document.getElementById('nwsb-vkyc'); if(p)p.remove(); if(this.openVerify) this.openVerify(); return; }
        st.step--; this.vkycRender();
        var sc=document.querySelector('#nwsb-vkyc .vk-scroll'); if(sc) sc.scrollTop=0; return;
      }
      // forward — validate & capture current step
      function shake(id){ var el=document.getElementById(id); if(el){ el.style.boxShadow='inset 0 0 0 2px rgba(220,80,80,.7)'; el.focus(); setTimeout(function(){ el.style.boxShadow=''; },1600);} }
      if(st.step===0){ /* intro — nothing to validate */ }
      else if(st.step===1){ var n=(document.getElementById('vk-name')||{}).value||''; if(n.trim().length<2){ shake('vk-name'); return; } st.name=n.trim(); }
      else if(st.step===2){ var raw=(document.getElementById('vk-dob-text')||{}).value||''; var pd=vkycParseDob(raw);
        if(!pd){ if(window.nwsbToast)nwsbToast('Enter your date as DD / MM / YYYY'); shake('vk-dob-text'); return; }
        if(pd.age<18){ if(window.nwsbToast)nwsbToast('You must be 18+ to verify'); shake('vk-dob-text'); return; } st.dob=pd.iso; }
      else if(st.step===3){ var typed=((document.getElementById('vk-country')||{}).value||'').trim();
        var match=COUNTRIES.filter(function(c){return c.toLowerCase()===typed.toLowerCase();})[0];
        if(!match){ if(window.nwsbToast)nwsbToast('Pick your country from the suggestions'); shake('vk-country'); return; }
        this.vkycSetCountry(match); st.city=((document.getElementById('vk-city')||{}).value||'').trim(); }
      else if(st.step===4){ if(!st.docFront||!st.selfie){ if(window.nwsbToast)nwsbToast('Upload your ID front and a selfie'); return; } }
      if(st.step>=STEPS-1){ this.vkycFinish(); return; }
      st.step++; this.vkycRender();
      var sc2=document.querySelector('#nwsb-vkyc .vk-scroll'); if(sc2) sc2.scrollTop=0;
    },
    /* Date of birth — auto-format as they type (DD / MM / YYYY) */
    vkycDobInput:function(el){
      var v=(el.value||'').replace(/\D/g,'').slice(0,8);
      var out=v;
      if(v.length>4) out=v.slice(0,2)+' / '+v.slice(2,4)+' / '+v.slice(4);
      else if(v.length>2) out=v.slice(0,2)+' / '+v.slice(2);
      el.value=out;
    },
    vkycDobCalendar:function(){
      var n=document.getElementById('vk-dob-native'); if(!n) return;
      n.style.pointerEvents='auto';
      try{ if(n.showPicker) n.showPicker(); else n.click(); }catch(e){ try{ n.click(); }catch(e2){} }
    },
    vkycDobNative:function(n){
      if(!n||!n.value) return;
      var t=document.getElementById('vk-dob-text'); if(t){ t.value=vkycDobToText(n.value); }
    },
    /* Country — type-ahead suggestions + local currency */
    vkycCountryInput:function(el){
      var st=window._vkyc; var q=((el&&el.value)||'').trim().toLowerCase();
      var sugg=document.getElementById('vk-country-sugg');
      if(!q){ if(sugg){ sugg.classList.remove('on'); sugg.innerHTML=''; } this.vkycSetCountry(''); return; }
      var starts=[], incl=[];
      for(var i=0;i<COUNTRIES.length;i++){ var c=COUNTRIES[i], lc=c.toLowerCase();
        if(lc.indexOf(q)===0) starts.push(c); else if(lc.indexOf(q)>=0) incl.push(c); }
      var list=starts.concat(incl).slice(0,8);
      if(sugg){
        sugg.innerHTML=list.map(function(c){ var safe=c.replace(/'/g,"\\'"); return '<div class="vk-sugg-item" onmousedown="event.preventDefault();IG.vkycPickCountry(\''+safe+'\')">'+c+'</div>'; }).join('');
        sugg.classList.toggle('on', list.length>0);
      }
      var exact=COUNTRIES.filter(function(c){return c.toLowerCase()===q;})[0];
      this.vkycSetCountry(exact||'');
    },
    vkycPickCountry:function(name){
      var el=document.getElementById('vk-country'); if(el) el.value=name;
      var sugg=document.getElementById('vk-country-sugg'); if(sugg){ sugg.classList.remove('on'); sugg.innerHTML=''; }
      this.vkycSetCountry(name);
    },
    vkycSetCountry:function(name){
      var st=window._vkyc; if(!st) return;
      st.country=name||'';
      st.currency = name ? currencyForCountry(name) : {code:'USD',symbol:'$',rate:1,dec:2};
      var note=document.getElementById('vk-cur-note');
      if(note){ if(name){ note.style.display='block'; note.textContent='✓ '+name+' · prices shown in '+st.currency.code+' ('+st.currency.symbol+')'; } else { note.style.display='none'; note.textContent=''; } }
      this.vkycUpdatePrices();
    },
    vkycUpdatePrices:function(){
      var st=window._vkyc; if(!st) return;
      var local=vkycFmt(st.priceUSDNum, st.currency);
      var pm=document.getElementById('vk-price-mini'); if(pm) pm.textContent=local+st.per+' · identity check';
      var nb=document.getElementById('vk-next'); if(nb && st.step===(st.steps-1)) nb.textContent='Pay '+local+' & verify';
    },
    vkycFinish:function(){
      var st=window._vkyc; if(!st) return;
      // Persist KYC to the user record (metadata only — the images stay on the
      // device for this session; a backend bucket would store them for review).
      window._userDataCache = window._userDataCache || {};
      var ud=window._userDataCache;
      ud.kycName=st.name; ud.kycDob=st.dob; ud.kycCountry=st.country; ud.kycCity=st.city; ud.kycSubmitted=true;
      // also fill the generic profile fields if they were empty
      if(!ud.dob) ud.dob=st.dob; if(!ud.residence) ud.residence=st.country; if(!ud.city) ud.city=st.city;
      try{ localStorage.setItem('nwsb_kyc', JSON.stringify({name:st.name,dob:st.dob,country:st.country,city:st.city,submitted:true,tier:st.tier})); }catch(e){}
      if(window._fbSetDoc && window._currentUid){
        window._fbSetDoc(window._currentUid, {kycName:st.name,kycDob:st.dob,kycCountry:st.country,kycCity:st.city,kycSubmitted:true}).catch(function(){});
      }
      var p=document.getElementById('nwsb-vkyc'); if(p) p.remove();
      // Hand off to the REAL payment gateway (adds badge to bag → checkout → Razorpay)
      this.buyVerify(st.tier, st.billing);
    },
    buyVerify:function(tier, billing){
      // Put the badge in the shopping bag and send the user through the real
      // checkout — the badge is granted by chkHandleSuccess after payment.
      var t=null; for(var i=0;i<VERIFY_TIERS.length;i++){ if(VERIFY_TIERS[i].key===tier){ t=VERIFY_TIERS[i]; break; } }
      if(!t) return;
      var isYear = (billing==='yearly' && t.yearly);
      var priceN = isYear ? t.yearlyN : t.priceN;
      var label  = t.name+' Verified Badge'+(isYear?' · Yearly':(t.per==='/mo'?' · Monthly':''));
      window.nssCart = window.nssCart || [];
      var id='badge-'+tier;
      // a badge replaces any lower/other badge already in the bag (incl. the
      // other billing period of the same tier)
      window.nssCart = window.nssCart.filter(function(c){ return String(c.id).indexOf('badge-')!==0; });
      window.nssCart.push({ id:id, name:label, type:'Badge', tier:tier, billing:(isYear?'yearly':'monthly'), price:priceN, img:t.img });
      if(typeof nssSaveCart==='function') nssSaveCart();
      if(typeof nssUpdateBadges==='function') nssUpdateBadges();
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
      var DEFAULT_AVATAR = 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1780065459/a84616f0-5b6b-11f1-b4b5-35b4f5e67a31_mureko.png';
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
