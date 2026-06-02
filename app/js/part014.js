
// ── HEALTH CATEGORY PAGE ──
var _hcpCategory = '';
var _hcpGender   = '';
var _hcpTab      = 'words';

// Category meta: organ tag + description
var HCP_BANNER = 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777980772/grok_image_1777980580135_lkpcv2.jpg';

var HCP_META = {
  'Fitness & Muscle':        { organ:'Muscular System',      desc:'Words that activate muscular frequency, physical strength, and endurance through correct phonetic resonance.', bg:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148458/grok_image_1778140366830_kr46gr.jpg', bannerImg:HCP_BANNER },
  'Fitness & Tone':          { organ:'Muscular System',      desc:'Words that activate toning frequency and body composition through targeted phonetic vibration.', bg:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148457/grok_image_1778140408500_ucsplo.jpg', bannerImg:HCP_BANNER },
  'Heart Health':            { organ:'Cardiovascular System',desc:'Words that resonate with cardiac frequency, supporting circulation, rhythm, and heart vitality.', bgM:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148457/grok_image_1778140415087_mn2kog.jpg', bgF:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148458/grok_image_1778140433938_wvgmuz.jpg', bannerImg:HCP_BANNER },
  'Skin & Glow':             { organ:'Integumentary System', desc:'Words that stimulate cellular renewal, collagen vibration, and radiant skin through sound science.', bgM:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778153132/image-71_vamq5d.jpg', bgF:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778153132/image-169_c5i9mm.jpg', bannerImg:HCP_BANNER },
  'Gut Health':              { organ:'Digestive System',     desc:'Words that harmonize the gut microbiome and digestive organs through specific phonetic patterns.', bgM:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148458/grok_image_1778140443107_b0z6fx.jpg', bgF:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148459/grok_image_1778140446573_w5qrvq.jpg', bannerImg:HCP_BANNER },
  'Liver Detox':             { organ:'Hepatic System',       desc:'Words that activate detoxification frequency, supporting liver purification and metabolic clarity.', bgM:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148459/grok_image_1778140452371_ufrjom.jpg', bgF:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148459/grok_image_1778140457587_jdbnuo.jpg', bannerImg:HCP_BANNER },
  'Mental Clarity':          { organ:'Nervous System',       desc:'Words that enhance cognitive resonance, focus, and neural clarity through phonetic activation.', bgM:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148465/grok_image_1778140614054_n3nbsy.jpg', bgF:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148466/grok_image_1778140619655_asmvnn.jpg', bannerImg:HCP_BANNER },
  'Testosterone & Hormones': { organ:'Endocrine System',     desc:'Words that support endocrine balance, testosterone production, and hormonal harmony through syllabic frequency.', bg:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148467/grok_image_1778140862207_vid6oz.jpg', bannerImg:HCP_BANNER },
  'Hormonal Balance':        { organ:'Endocrine System',     desc:'Words that support cycle harmony, hormonal regulation, and endocrine balance through sound vibration.', bg:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148460/grok_image_1778140465237_rooq5n.jpg', bannerImg:HCP_BANNER },
  'Immunity Boost':          { organ:'Immune System',        desc:'Words that activate immune resonance, strengthening the body\'s defense through phonetic frequency.', bgM:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148460/grok_image_1778140472572_epkcrs.jpg', bgF:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148460/grok_image_1778140482721_dwpsis.jpg', bannerImg:HCP_BANNER },
  'Lung & Breath':           { organ:'Respiratory System',   desc:'Words that expand breath capacity and activate bronchial pathways through resonant phonetics.', bg:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148460/grok_image_1778140492244_hkw4dr.jpg', bannerImg:HCP_BANNER },
  'Kidney & Bladder':        { organ:'Urinary System',       desc:'Words that resonate with water-element organs, supporting kidney filtration and fluid balance.', bg:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778153132/image-168_ej7sa8.jpg', bannerImg:HCP_BANNER },
  'Hair Health':             { organ:'Follicular System',    desc:'Words that stimulate scalp circulation and follicle activation through vibrational sound patterns.', bgM:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148466/grok_image_1778140813647_otjm5m.jpg', bgF:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148461/grok_image_1778140503138_vdaqrx.jpg', bannerImg:HCP_BANNER },
  'Glass Skin':              { organ:'Integumentary System', desc:'Words that activate poreless skin clarity, deep hydration and mirror-like luminosity through phonetic sound resonance.', bgM:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148462/grok_image_1778140531353_onoaci.jpg', bgF:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148464/grok_image_1778140578685_cpiw6n.jpg', bannerImg:HCP_BANNER },
  'Anti-Aging':              { organ:'Integumentary System', desc:'Words that activate cellular regeneration, collagen renewal and youth-frequency restoration through phonetic vibration.', bg:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148463/grok_image_1778140574785_c5nkph.jpg', bannerImg:HCP_BANNER },
  'Dark Spot & Pigmentation':{ organ:'Integumentary System', desc:'Words that balance melanin production and support even skin tone through targeted sound resonance.', bg:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148466/grok_image_1778140642487_bb8mes.jpg', bannerImg:HCP_BANNER },
  'Eye Sight Health':        { organ:'Visual System',        desc:'Words that activate ocular frequency, strengthen vision clarity and support eye health through targeted phonetic resonance.', bgM:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148456/1000037180-ezremove_yors9c.png', bgF:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148457/1000037181-ezremove_acyr0e.png', bannerImg:HCP_BANNER },
  'Feminine Radiance':       { organ:'Endocrine · Skin System', desc:'Words that unlock inner glow, divine confidence and feminine luminosity through deep vibrational sound activation.', bg:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148458/fe50c080-49fb-11f1-9ed8-61ad086d2bba_ydglxe.png', bannerImg:HCP_BANNER },
  'Bone & Joint':            { organ:'Skeletal System',      desc:'Words that strengthen bone density and joint resilience through deep phonetic vibration.', bg:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148461/grok_image_1778140508637_kacgmf.jpg', bgF:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778153132/image-94_gokqx5.jpg', bannerImg:HCP_BANNER },
  'Sleep & Recovery':        { organ:'Nervous System',       desc:'Words that induce deep rest states, cellular recovery, and parasympathetic activation through sound.', bgM:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148462/grok_image_1778140553935_lpejkk.jpg', bgF:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148463/grok_image_1778140560786_ls3czt.jpg', bannerImg:HCP_BANNER },
  'Explorer & Courage':      { organ:'Adrenal · Nervous System', desc:'Words that activate boldness, fearless direction, and the primal drive to move into the unknown. Used by those who seek expansion and breakthrough.', bg:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148465/grok_image_1778140594588_bidu9r.jpg', bannerImg:HCP_BANNER },
  'Power & Conquest':        { organ:'Muscular · Adrenal System', desc:'Words that activate raw dominance, primal authority, and unbreakable will. The frequency of those who bend the world to their vision.', bg:'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778148464/grok_image_1778140587120_ihuxzz.jpg', bannerImg:HCP_BANNER }
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

  // Open the intro sub-screen (or skip directly to category if intros disabled)
  if (typeof shouldShowIntro === 'function' && !shouldShowIntro('health-category')) {
    _openActualCategoryPage();
  } else {
    openSub('hcp-intro');
  }
}

function _openActualCategoryPage() {
  // Retrieve current category state
  var category = _hcpCategory;
  var gender   = _hcpGender;

  // Set back button — goes back to intro
  document.getElementById('hcp-back-btn').onclick = function() {
    closeSub('health-category');
    // Re-open intro so user can go back
    openSub('hcp-intro');
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
            '<img decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779717856/30ebb160-5840-11f1-bb0c-71720609fd8f_g5nmcn.png" style="width:44px;height:44px;object-fit:contain;border-radius:50%;background:transparent;" loading="lazy">' +
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
  // Open the word in the player as a single-word session
  var wordObj = (typeof MASTER_WORD_LIBRARY !== 'undefined' ? MASTER_WORD_LIBRARY : []).find(function(w) { return w.word === wordName; });
  if (!wordObj) return;
  PRACTICE_WORDS = [wordObj];
  window._rtManualLaunch = true;
  _pwIdx = 0; _pwRepCount = 0; _pwDone = false; _pwMode = 'listen';
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
