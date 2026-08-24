
// ── HEALTH CATEGORY PAGE ──
var _hcpCategory = '';
var _hcpGender   = '';
var _hcpTab      = 'words';

// Category meta: organ tag + description
var HCP_BANNER = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/a52040c43f10ffe81c652a4b77f92e6ffb9ea8ea37e8eff87574461877d576a4.webp';

var HCP_META = {
  'Fitness & Muscle':        { organ:'Muscular System',      desc:'Words that activate muscular frequency, physical strength, and endurance through correct phonetic resonance.', bg:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/bd9b98a787e4c6d83a83f9ced9bf0215c4aa8616b2505a50f4fd5e168d4077a2.jpg', bannerImg:HCP_BANNER },
  'Fitness & Tone':          { organ:'Muscular System',      desc:'Words that activate toning frequency and body composition through targeted phonetic vibration.', bg:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/8b4991c73d213d0bda3b933cb9bbece67243b9c04dedaa557d7ad722e78968e2.jpg', bannerImg:HCP_BANNER },
  'Heart Health':            { organ:'Cardiovascular System',desc:'Words that resonate with cardiac frequency, supporting circulation, rhythm, and heart vitality.', bgM:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/d7e75968ace7a4e67e82a5c9fcf460bf1959ef57a6629ae3dfe75835cae67dd9.jpg', bgF:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/8a7449638e86e1aa055eeefe65a361a4b1d63272855d046a6393fa9eae9fced7.jpg', bannerImg:HCP_BANNER },
  'Skin & Glow':             { organ:'Integumentary System', desc:'Words that stimulate cellular renewal, collagen vibration, and radiant skin through sound science.', bgM:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/ec9ef1fd9f2c43da586d75f58bd0b25ad57f60d49e54b1f9caccd31ab74b042e.jpg', bgF:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/e3cbfb2aca9a7d83a775501baf6986eedef29d908ca8cf9a472a899ac9df6e01.jpg', bannerImg:HCP_BANNER },
  'Gut Health':              { organ:'Digestive System',     desc:'Words that harmonize the gut microbiome and digestive organs through specific phonetic patterns.', bgM:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/6808a654a3c7dfcad02c8f1b21d6b3173e28175660e04dfcf4d27a5ecd3d9b76.jpg', bgF:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/03dde1c40e1f4814d90065cbe4728ebdb08bd8ba1616263a8aa29cee392396b2.jpg', bannerImg:HCP_BANNER },
  'Liver Detox':             { organ:'Hepatic System',       desc:'Words that activate detoxification frequency, supporting liver purification and metabolic clarity.', bgM:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/ec085c8220f8db56e1117183e11e66cd8626c709c4a51e85cacdb8445f5843b8.jpg', bgF:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/dc302eb10c7df6b4b6b42e710cc7f9ca8028a11083a82dc6fb1c8391c95c4788.jpg', bannerImg:HCP_BANNER },
  'Mental Clarity':          { organ:'Nervous System',       desc:'Words that enhance cognitive resonance, focus, and neural clarity through phonetic activation.', bgM:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/561a09a2761920a67a0335367a5b0324837ae72cf1ce3201e19d88f3d2a07796.jpg', bgF:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/8a69740277114f237fce7f327c29693874380a1aa92944c4a661b17088b93d75.jpg', bannerImg:HCP_BANNER },
  'Testosterone & Hormones': { organ:'Endocrine System',     desc:'Words that support endocrine balance, testosterone production, and hormonal harmony through syllabic frequency.', bg:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/8f24c24937a4499500da8a08f9ab87781a15ecca02ac3c9069ece74fc44eba30.jpg', bannerImg:HCP_BANNER },
  'Hormonal Balance':        { organ:'Endocrine System',     desc:'Words that support cycle harmony, hormonal regulation, and endocrine balance through sound vibration.', bg:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/8b8815efcc01dd9e43eb0a5089b1df34aa20a8b68b5eba8aa3f051bee7d83996.jpg', bannerImg:HCP_BANNER },
  'Immunity Boost':          { organ:'Immune System',        desc:'Words that activate immune resonance, strengthening the body\'s defense through phonetic frequency.', bgM:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/0598afda8ea6defa55db5d8fd5f06bfcca8e6a55a6dc961c362d8c818fe8f7f6.jpg', bgF:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/f74abac052480172f5ab2d93170a4f4666dd98d282b5fb4b831c4b419cd9425a.jpg', bannerImg:HCP_BANNER },
  'Lung & Breath':           { organ:'Respiratory System',   desc:'Words that expand breath capacity and activate bronchial pathways through resonant phonetics.', bg:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/54666109937c228b7896405f2dda9ed68b02461dedf6a95b2c7baa4cccf5de82.jpg', bannerImg:HCP_BANNER },
  'Kidney & Bladder':        { organ:'Urinary System',       desc:'Words that resonate with water-element organs, supporting kidney filtration and fluid balance.', bg:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/9db6f6fec7955be314c64b860631ba354e4f16385679a1e4ecca3759dd4ad489.jpg', bannerImg:HCP_BANNER },
  'Hair Health':             { organ:'Follicular System',    desc:'Words that stimulate scalp circulation and follicle activation through vibrational sound patterns.', bgM:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/b028d145a11c35332ed9a0f05ba717a5b4716b030c290b637bd3c9586bed6623.jpg', bgF:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/1c00e00a2721b6727e2c2e8a83b1e374350ab5d4022a880c2039d7929d09ed5b.jpg', bannerImg:HCP_BANNER },
  'Glass Skin':              { organ:'Integumentary System', desc:'Words that activate poreless skin clarity, deep hydration and mirror-like luminosity through phonetic sound resonance.', bgM:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/f28e4187b788bfec34ffff248f91a0cbf3cf82df28a4b075952f85a824381ed5.jpg', bgF:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/82c4044a0debe445a642d39799222dd25f642b2993682a92214f5a0b2116771b.jpg', bannerImg:HCP_BANNER },
  'Anti-Aging':              { organ:'Integumentary System', desc:'Words that activate cellular regeneration, collagen renewal and youth-frequency restoration through phonetic vibration.', bg:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/8f749de37346ef700a6d817c4ca0643b5963ebf4a76b8d4f60e6db0924b1ae2e.jpg', bannerImg:HCP_BANNER },
  'Dark Spot & Pigmentation':{ organ:'Integumentary System', desc:'Words that balance melanin production and support even skin tone through targeted sound resonance.', bg:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/4ec3816eaaebce78242c1edff9abad62a0691c81ec1695c0d111f4255eda359c.jpg', bannerImg:HCP_BANNER },
  'Eye Sight Health':        { organ:'Visual System',        desc:'Words that activate ocular frequency, strengthen vision clarity and support eye health through targeted phonetic resonance.', bgM:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/1ef7a885b8fa6039d6ff7ab6056f9cdb9e50263ea3e51e71056e004145167ba1.png', bgF:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/3a1e78c61b3770a041e9072299ce45d31985bd401ba57b39e6c3da3d017f1dad.png', bannerImg:HCP_BANNER },
  'Feminine Radiance':       { organ:'Endocrine · Skin System', desc:'Words that unlock inner glow, divine confidence and feminine luminosity through deep vibrational sound activation.', bg:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/444687f82c4c8c84ebe35ee3c7579507a612a0ef6e8da43684e19d298f042857.png', bannerImg:HCP_BANNER },
  'Bone & Joint':            { organ:'Skeletal System',      desc:'Words that strengthen bone density and joint resilience through deep phonetic vibration.', bg:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/e6d9277961f1ff15e6b644011030fa98a11e45cb3d5c73df5d291dae61d1b9e3.jpg', bgF:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/0cba8cc868f511085573c47cc84d7391c2ec6f9986ad5f4bd5a49c8f7449ed29.jpg', bannerImg:HCP_BANNER },
  'Sleep & Recovery':        { organ:'Nervous System',       desc:'Words that induce deep rest states, cellular recovery, and parasympathetic activation through sound.', bgM:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/04884250a8b9f5e5b2e933a00d19ea9bfd7ad407c9315f0115b6e7d4f67de57d.jpg', bgF:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/622fc1a4ec2e6408d19ab4b6b59a00b52bc035e5f42bed5f6b4935dacefd0ef5.jpg', bannerImg:HCP_BANNER },
  'Explorer & Courage':      { organ:'Adrenal · Nervous System', desc:'Words that activate boldness, fearless direction, and the primal drive to move into the unknown. Used by those who seek expansion and breakthrough.', bg:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/88a7b77448026f04aae4894fb285d083f2f8c6cf455840f40232caf8f769f359.jpg', bannerImg:HCP_BANNER },
  'Power & Conquest':        { organ:'Muscular · Adrenal System', desc:'Words that activate raw dominance, primal authority, and unbreakable will. The frequency of those who bend the world to their vision.', bg:'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/7620e8c3204844c77b8085df61e66fe8a433e6d5b80d4c4ef44fd3113c4425fc.jpg', bannerImg:HCP_BANNER }
};

function openCategoryPage(category, gender) {
  _hcpCategory = category;
  _hcpGender   = gender;
  _hcpTab      = 'words';

  var meta = HCP_META[category] || { organ: 'Body System', desc: 'Natural origin words targeting this system through phonetic resonance.' };
  var introImg = (gender === 'M' ? meta.bgM : meta.bgF) || meta.bg || HCP_BANNER;

  // Set back button target for when intro's back is pressed
  var backTarget = gender === 'M' ? 'health-male' : 'health-female';

  // ── Populate intro page ──
  var bgEl = document.getElementById('hcpiBg');
  if (bgEl) bgEl.style.backgroundImage = 'url(' + introImg + ')';

  var organEl = document.getElementById('hcpiOrganTag');
  if (organEl) organEl.textContent = meta.organ;

  var titleEl = document.getElementById('hcpiTitle');
  if (titleEl) titleEl.textContent = category;

  var descEl = document.getElementById('hcpiDesc');
  if (descEl) descEl.textContent = meta.desc;

  var enterLabelEl = document.getElementById('hcpiEnterLabel');
  if (enterLabelEl) enterLabelEl.textContent = 'Enter ' + category;


  // Back button → goes to gender grid
  var backBtn = document.getElementById('hcpiBackBtn');
  if (backBtn) backBtn.onclick = function() { closeSub('hcp-intro'); openSub(backTarget); };

  // The whole card (including the OPEN pill) opens the category page
  var enterCard = document.getElementById('hcpiEnterCard');
  if (enterCard) enterCard.onclick = function() { _openActualCategoryPage(); };

  // Open the intro sub-screen (or skip directly to category if intros disabled).
  // Use a PER-CATEGORY key so the intro shows the first time each category is
  // opened (not just the very first category) in "once" mode.
  if (typeof shouldShowIntro === 'function' && !shouldShowIntro('health-category:' + category)) {
    _openActualCategoryPage();
  } else {
    openSub('hcp-intro');
  }
}

function _openActualCategoryPage() {
  // Retrieve current category state
  var category = _hcpCategory;
  var gender   = _hcpGender;

  // Set back button — goes straight back to the gender grid (NOT the intro)
  document.getElementById('hcp-back-btn').onclick = function() {
    closeSub('health-category');
    openSub(gender === 'M' ? 'health-male' : 'health-female');
  };

  // Title
  document.getElementById('hcp-title').textContent = category;

  // Meta
  var meta = HCP_META[category] || { organ: 'Body System', desc: 'Natural origin words targeting this system through phonetic resonance.' };
  document.getElementById('hcp-organ-tag').textContent = meta.organ;
  document.getElementById('hcp-desc').textContent = meta.desc;

  // Banner image
  var bannerEl = document.getElementById('hcp-banner-img');
  if (bannerEl) {
    var bImg = meta.bannerImg || meta.bg || '';
    bannerEl.style.backgroundImage = bImg ? 'url(' + bImg + ')' : 'none';
    bannerEl.style.backgroundPosition = 'center 15%';
  }
  // Full-screen background
  var bgEl = document.getElementById('hcp-bg');
  if (bgEl) {
    var resolvedBg = (gender === 'M' ? meta.bgM : meta.bgF) || meta.bg || '';
    if (resolvedBg) {
      bgEl.style.backgroundImage = 'url(' + resolvedBg + ')';
      bgEl.style.backgroundPosition = 'center top';
      bgEl.style.backgroundSize = 'cover';
      bgEl.style.top = '280px';
      bgEl.style.opacity = '0.25';
    } else {
      bgEl.style.backgroundImage = 'none';
      bgEl.style.opacity = '0';
    }
  }
  // Render tab
  hcpRenderTab();
  // Close intro FIRST — health-category is z-index 600, intro is 620,
  // so we must dismiss intro before opening or category renders behind it.
  closeSub('hcp-intro');
  openSub('health-category');
}

function hcpSetTab(tab) {
  _hcpTab = tab;
  ['words','about','sessions'].forEach(function(t) {
    var btn = document.getElementById('hcp-tab-' + t);
    if (btn) btn.classList.toggle('active', t === tab);
  });
  hcpRenderTab();
}

function hcpRenderTab() {
  var panel = document.getElementById('hcp-panel');
  var btn   = document.getElementById('hcp-session-btn');
  if (!panel) return;

  if (_hcpTab === 'words') {
    var words = typeof getWordsForCategory === 'function' ? getWordsForCategory(_hcpCategory) : [];
    if (_hcpGender && _hcpGender !== 'both') {
      words = words.filter(function(w) { return !w.gender || w.gender === 'both' || w.gender === _hcpGender; });
    }
    if (words.length === 0) {
      panel.innerHTML =
        '<div style="display:flex;flex-direction:column;align-items:flex-start;gap:10px;padding:8px 0;">' +
          '<div style="display:flex;align-items:center;gap:10px;margin-bottom:4px;">' +
            '<img decoding="async" src="https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/994c44e587b68fce07c4c539cdc0cfce75d4a04cc1cc0855f0ebfb9feb67dc3d.png" style="width:44px;height:44px;object-fit:contain;border-radius:50%;background:transparent;" loading="lazy">' +
            '<div style="font-family:\'DM Sans\',sans-serif;font-size:16px;line-height:1;"><span style="font-weight:800;color:#fff;">Nowsb</span><span style="font-weight:200;color:rgba(255,255,255,0.88);">ansiu</span></div>' +
          '</div>' +
          '<div style="font-size:15px;font-weight:600;color:#e8d5a3;letter-spacing:0.3px;">Words being crafted</div>' +
          '<div style="font-size:13px;font-weight:300;color:rgba(255,255,255,0.5);line-height:1.6;max-width:280px;">The client is personally crafting words for this category. They will appear here once ready.</div>' +
        '</div>';
      if (btn) { btn.textContent = 'Words Coming Soon'; btn.style.opacity = '0.4'; btn.style.pointerEvents = 'none'; }
    } else {
      var html = '<div style="display:flex;flex-direction:column;gap:10px;">';
      words.forEach(function(w) {
        html +=
          '<div onclick="hcpOpenWord(\'' + w.word + '\')" style="background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.09);border-radius:14px;padding:14px 16px;cursor:pointer;display:flex;align-items:center;justify-content:space-between;gap:10px;">' +
            '<div>' +
              '<div style="font-size:18px;font-weight:700;color:#e8d5a3;letter-spacing:1px;margin-bottom:3px;">' + w.word + '</div>' +
              '<div style="font-size:11px;font-weight:300;color:rgba(255,255,255,0.45);letter-spacing:1.2px;">' + (w.phonetic || '') + '</div>' +
              (w.organ ? '<div style="font-size:10px;font-weight:500;color:rgba(200,232,245,0.6);margin-top:4px;letter-spacing:0.8px;">' + w.organ + '</div>' : '') +
            '</div>' +
            '<svg width="14" height="14" viewBox="0 0 16 16" fill="none"><path d="M6 3l5 5-5 5" stroke="rgba(255,255,255,0.3)" stroke-width="1.4" stroke-linecap="square"/></svg>' +
          '</div>';
      });
      html += '</div>';
      panel.innerHTML = html;
      if (btn) { btn.textContent = 'Start Session · ' + words.length + ' Words'; btn.style.opacity = '1'; btn.style.pointerEvents = 'auto'; }
    }

  } else if (_hcpTab === 'about') {
    var meta2 = HCP_META[_hcpCategory] || { organ: 'Body System', desc: '' };
    panel.innerHTML =
      '<div style="display:flex;flex-direction:column;gap:18px;padding:4px 0;">' +
        '<div style="background:rgba(232,213,163,0.05);border:1px solid rgba(232,213,163,0.12);border-radius:14px;padding:16px;">' +
          '<div style="font-size:10px;font-weight:500;letter-spacing:1.8px;text-transform:uppercase;color:#e8d5a3;opacity:0.7;margin-bottom:8px;">What This Targets</div>' +
          '<div style="font-size:14px;font-weight:300;color:rgba(255,255,255,0.75);line-height:1.65;">' + meta2.desc + '</div>' +
        '</div>' +
        '<div style="background:rgba(200,232,245,0.04);border:1px solid rgba(200,232,245,0.1);border-radius:14px;padding:16px;">' +
          '<div style="font-size:10px;font-weight:500;letter-spacing:1.8px;text-transform:uppercase;color:#c8e8f5;opacity:0.7;margin-bottom:8px;">Organ System</div>' +
          '<div style="font-size:14px;font-weight:400;color:rgba(255,255,255,0.8);">' + meta2.organ + '</div>' +
        '</div>' +
        '<div style="background:rgba(255,255,255,0.03);border:1px solid rgba(255,255,255,0.07);border-radius:14px;padding:16px;">' +
          '<div style="font-size:10px;font-weight:500;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,0.4);margin-bottom:8px;">How It Works</div>' +
          '<div style="font-size:13px;font-weight:300;color:rgba(255,255,255,0.5);line-height:1.65;">Each word in this category carries a natural origin vibration tuned to this system. Correct pronunciation — with the exact mouth position, breath, and resonance — creates the specific frequency that activates and supports these organs.</div>' +
        '</div>' +
      '</div>';

  } else if (_hcpTab === 'sessions') {
    panel.innerHTML =
      '<div style="display:flex;flex-direction:column;align-items:flex-start;gap:10px;padding:8px 0;">' +
        '<div style="width:44px;height:44px;background:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.1);border-radius:12px;display:flex;align-items:center;justify-content:center;">' +
          '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.35)" stroke-width="1.4" stroke-linecap="round"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>' +
        '</div>' +
        '<div style="font-size:15px;font-weight:600;color:rgba(255,255,255,0.7);letter-spacing:0.3px;">No sessions yet</div>' +
        '<div style="font-size:13px;font-weight:300;color:rgba(255,255,255,0.4);line-height:1.6;max-width:260px;">Complete your first session in this category and your history will appear here.</div>' +
      '</div>';
  }
}

function hcpOpenWord(wordName) {
  // Open the word in the player AT its place in this category's list — not
  // as a session of one. One word is "1 of 1" and Next stays greyed out
  // forever, which reads as a broken button; the rest of the category is
  // right here, so the session is the category and Next walks it.
  var lib = (typeof MASTER_WORD_LIBRARY !== 'undefined' ? MASTER_WORD_LIBRARY : []);
  var wordObj = lib.find(function(w) { return w.word === wordName; });
  if (!wordObj) return;
  var list = (typeof getWordsForCategory === 'function' && _hcpCategory) ? getWordsForCategory(_hcpCategory) : [];
  // No category in hand (the word was reached some other way)? Fall back to
  // the word's own first category, the same family rxStartWord uses.
  if (!list || list.indexOf(wordObj) < 0) {
    var cat = (wordObj.categories && wordObj.categories[0]) || '';
    list = cat ? lib.filter(function(x) { return x.categories && x.categories.indexOf(cat) !== -1; }) : [];
    if (!list || list.indexOf(wordObj) < 0) list = [wordObj];
  }
  PRACTICE_WORDS = list;
  window._rtManualLaunch = true;
  _pwIdx = Math.max(0, list.indexOf(wordObj)); _pwRepCount = 0; _pwDone = false; _pwMode = 'listen';
  window._rtStartIdx = _pwIdx;   /* openSub('practice') resets _pwIdx — this survives it */
  _pwAutoPlayOnce = false;
  closeSub('health-category');
  closeSub('hcp-intro');
  setTimeout(function() { openSub('practice'); }, 80);
}

function hcpStartSession() {
  var words = typeof getWordsForCategory === 'function' ? getWordsForCategory(_hcpCategory) : [];
  if (_hcpGender && _hcpGender !== 'both') {
    words = words.filter(function(w) { return !w.gender || w.gender === 'both' || w.gender === _hcpGender; });
  }
  if (!words || words.length === 0) return;
  PRACTICE_WORDS = words;
  window._rtManualLaunch = true;
  window._rtSessionCategory = _hcpCategory;
  _pwIdx = 0; _pwRepCount = 0; _pwDone = false; _pwMode = 'listen';
  _pwAutoPlayOnce = false;
  closeSub('health-category');
  closeSub('hcp-intro');
  setTimeout(function() { openSub('practice'); }, 80);
}
