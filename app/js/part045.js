
(function() {
  /* Inject promo bars into key sub-screens for free users */
  var PROMO_SCREENS = [
    /* [container-id, variant-label] */
    ['slContent',        'Unlock 50+ premium words — Sound Library is just the start.'],
    /* The Word Atelier now has its own full product page (highlights,
       certificate, buy CTA, etc.) — the generic upgrade bar was redundant
       there and the user asked for it removed from this page specifically. */
    ['msMeaningBody',    'Upgrade for unlimited Meaning Store access and AI word origin insights.'],
    ['mpBody',           'Pro members unlock deeper progress analytics and healing rank tracking.'],
    ['routinesBody',     'Upgrade for 5 custom routine slots and AI-personalised practice sequences.'],
    ['routineDetailBody','Pro access unlocks advanced routine timing and AI session feedback.'],
  ];

  function _openUpgrade() { if (window.SS) window.SS.open('subscription'); }

  function _dismissedKey(containerId) { return 'nwsb_sp_bar_dismissed_' + containerId; }
  function _isDismissed(containerId) { try { return localStorage.getItem(_dismissedKey(containerId)) === '1'; } catch (e) { return false; } }

  function _buildBar(text, containerId) {
    var bar = document.createElement('div');
    bar.className = 'sp-bar';
    bar.dataset.containerId = containerId;
    bar.onclick = _openUpgrade;
    bar.innerHTML =
      '<div class="sp-bar-close" onclick="event.stopPropagation();this.closest(\'.sp-bar\').style.display=\'none\';try{localStorage.setItem(\'nwsb_sp_bar_dismissed_' + containerId + '\',\'1\')}catch(e){}">' +
        '<svg width="10" height="10" viewBox="0 0 10 10" fill="none"><path d="M1 1L9 9M9 1L1 9" stroke="rgba(255,255,255,0.5)" stroke-width="1.4" stroke-linecap="round"/></svg>' +
      '</div>' +
      '<div class="sp-bar-text"><strong>NowssB Edition</strong> — ' + text + '</div>' +
      '<div class="sp-bar-btn">Upgrade</div>';
    return bar;
  }

  function _injectBars() {
    var t = window.GATE ? window.GATE.tier() : 'free';
    if (t==='resonance'||t==='frequency'||t==='frequencyX') return;

    PROMO_SCREENS.forEach(function(pair) {
      var el = document.getElementById(pair[0]);
      if (!el || el.querySelector('.sp-bar')) return; // already injected
      if (_isDismissed(pair[0])) return; // user closed this one — stay gone
      var bar = _buildBar(pair[1], pair[0]);
      el.appendChild(bar);
    });
    // Make them visible (CSS display:none → flex)
    document.querySelectorAll('.sp-bar').forEach(function(b) {
      b.style.display = 'flex';
    });
  }

  function _updateBarsVisibility() {
    var t = window.GATE ? window.GATE.tier() : 'free';
    var hasPlan = (t==='resonance'||t==='frequency'||t==='frequencyX');
    document.querySelectorAll('.sp-bar').forEach(function(b) {
      if (hasPlan) { b.style.display = 'none'; return; }
      if (_isDismissed(b.dataset.containerId)) return; // stays closed once dismissed
      b.style.display = 'flex';
    });
    var homeCard = document.getElementById('sub-promo-card');
    if (homeCard) homeCard.style.display = hasPlan ? 'none' : 'block';
  }

  // Run after user data loads (auth state change fires, data cached)
  document.addEventListener('DOMContentLoaded', function() {
    // Delay to allow Firebase auth + Firestore to resolve user data
    setTimeout(function() {
      _injectBars();
      _updateBarsVisibility();
    }, 2000);

    // Also re-evaluate whenever user data cache is updated
    var _origFbSetDoc = window._fbSetDoc;
    window._spRefreshPromo = _updateBarsVisibility;
  });
})();

/* ══════════════════════════════════════════════════════════
   GATE — Feature access control system
   ══════════════════════════════════════════════════════════ */
window.GATE = (function(){
  /* Full-access allowlist — accounts here always get 'frequencyX' regardless
     of their actual subscription (the account that should "see and play
     with everything"). Fill in with the real uid/email once known. */
  var ADMIN_UIDS   = [];
  var ADMIN_EMAILS = [];
  function _isAdminAccount() {
    var u = window._currentUser, d = window._userDataCache;
    if (u && u.uid && ADMIN_UIDS.indexOf(u.uid) !== -1) return true;
    if (u && u.email && ADMIN_EMAILS.indexOf(u.email) !== -1) return true;
    if (d && d.email && ADMIN_EMAILS.indexOf(d.email) !== -1) return true;
    return false;
  }

  function _tier() {
    if (_isAdminAccount()) return 'frequencyX';
    var d = window._userDataCache;
    if (!d) return 'trial'; // before data loads, assume trial (graceful)
    // Active paid subscriptions
    if (d.tier === 'frequencyX' || d.tier === 'elite_x')  return 'frequencyX';
    if (d.tier === 'frequency'  || d.tier === 'elite')    return 'frequency';
    if (d.tier === 'resonance'  || d.isPro)               return 'resonance';
    // Trial check — 'expired' means a real trial was started and genuinely
    // ran out. An account with no trialEndDate at all never started one
    // (never subscribed, never entered payment) — that's 'free', not
    // 'expired'. The two used to be conflated, which is why accounts that
    // never touched the Subscription screen were incorrectly shown the
    // "trial expired" block.
    if (d.trialEndDate) {
      return new Date() < new Date(d.trialEndDate) ? 'trial' : 'expired';
    }
    return 'free';
  }

  /* ── Weekly new-word limit — 5 / 10 / 20 by tier, unlimited on trial.
     Tracks which words have already been "spent" this calendar week
     (Mon–Sun) in localStorage; re-practicing an already-counted word is
     always free, only NEW words count against the cap. ── */
  function _wordsPerWeek() {
    var t = _tier();
    if (t === 'frequencyX') return 20;
    if (t === 'frequency')  return 10;
    if (t === 'resonance')  return 5;
    return Infinity; // trial = full access, no weekly cap
  }
  function _weekStartISO() {
    var d = new Date();
    var day = d.getDay(); // 0=Sun..6=Sat
    var diffToMonday = (day === 0 ? 6 : day - 1);
    d.setHours(0, 0, 0, 0);
    d.setDate(d.getDate() - diffToMonday);
    return d.toISOString().slice(0, 10);
  }
  function _wordsThisWeek() {
    var data = null;
    try { data = JSON.parse(localStorage.getItem('nwsb_words_this_week') || 'null'); } catch (e) {}
    var wk = _weekStartISO();
    if (!data || data.weekStart !== wk) data = { weekStart: wk, words: [] };
    return data;
  }
  function _saveWordsThisWeek(data) {
    try { localStorage.setItem('nwsb_words_this_week', JSON.stringify(data)); } catch (e) {}
  }
  /* Call when a word becomes active in the player. Returns true if allowed
     (and records it as spent, if new); false if the weekly cap is hit —
     caller should show the upgrade prompt / block the session. */
  function _canStartWord(word) {
    var limit = _wordsPerWeek();
    if (limit === Infinity || !word) return true;
    var data = _wordsThisWeek();
    if (data.words.indexOf(word) !== -1) return true; // already spent this week
    if (data.words.length >= limit) return false;
    data.words.push(word);
    _saveWordsThisWeek(data);
    return true;
  }
  function _wordsUsedThisWeek() { return _wordsThisWeek().words.length; }

  function _canAccess() {
    var t = _tier();
    return t === 'trial' || t === 'resonance' || t === 'frequency' || t === 'frequencyX';
  }

  function _showGateModal(level) {
    var m = document.getElementById('gate-upgrade-modal');
    var n = document.getElementById('gate-modal-tier-name');
    if (!m) return;
    var names = { resonance:'Resonance', frequency:'Frequency', frequencyX:'Frequency X' };
    if (n) n.textContent = names[level] || 'a paid plan';
    m.style.display = 'flex';
  }

  function _showExpiredOverlay() {
    var ov = document.getElementById('trial-expired-overlay');
    if (ov) { ov.style.display = 'flex'; }
    else { if (window.SS) window.SS.open('subscription'); }
  }

  function _showWordLimitModal() {
    if (window.nwsbToast) {
      nwsbToast('Weekly word limit reached — upgrade for more');
    }
    var m = document.getElementById('gate-upgrade-modal');
    var n = document.getElementById('gate-modal-tier-name');
    if (m) {
      if (n) n.textContent = 'more words this week';
      m.style.display = 'flex';
    } else if (window.SS) {
      window.SS.open('subscription');
    }
  }

  return {
    tier: _tier,
    canAccess: _canAccess,
    isResonance:  function(){ var t=_tier(); return t==='resonance'||t==='frequency'||t==='frequencyX'||t==='trial'; },
    isFrequency:  function(){ var t=_tier(); return t==='frequency'||t==='frequencyX'||t==='trial'; },
    isFrequencyX: function(){ var t=_tier(); return t==='frequencyX'||t==='trial'; },
    wordsPerWeek: _wordsPerWeek,
    wordsUsedThisWeek: _wordsUsedThisWeek,
    /* Call when a word becomes active in the player. Returns true/allows if
       under the weekly cap (and records it); shows the upgrade prompt and
       returns false if the cap is already hit. */
    checkWordLimit: function(word) {
      // The player always opens — 'expired'/'free' tiers no longer hard-block
      // here (see _wordsPerWeek, which already gives them the same unlimited
      // access as 'trial'). Only an actual paid-tier weekly cap can deny.
      var ok = _canStartWord(word);
      if (!ok) _showWordLimitModal();
      return ok;
    },
    check: function(featureLevel, onDenied) {
      var ok = false;
      if (featureLevel === 'resonance')  ok = this.isResonance();
      if (featureLevel === 'frequency')  ok = this.isFrequency();
      if (featureLevel === 'frequencyX') ok = this.isFrequencyX();
      if (!ok) {
        if (typeof onDenied === 'function') onDenied();
        else _showGateModal(featureLevel);
      }
      return ok;
    }
  };
})();

/* ── Trial banner update ── */
window._updateTrialBanner = function() {
  var banner = document.getElementById('trial-banner');
  if (!banner) return;
  var d = window._userDataCache;
  if (!d || !d.trialEndDate) { banner.style.display = 'none'; return; }
  var t = window.GATE ? window.GATE.tier() : 'expired';
  if (t !== 'trial') { banner.style.display = 'none'; return; }
  var end = new Date(d.trialEndDate);
  var now = new Date();
  var daysLeft = Math.ceil((end - now) / (1000 * 60 * 60 * 24));
  if (daysLeft < 0) { banner.style.display = 'none'; return; }
  var daysEl = document.getElementById('trial-days-left');
  if (daysEl) daysEl.textContent = daysLeft;
  banner.style.display = 'flex';
};

/* ── Subscribe with Razorpay ── */
window.ssStartSubscription = function(planId, billing) {
  var plan = SS_PLANS.find(function(p){ return p.id === planId; });
  if (!plan) return;
  var amount = billing === 'yearly' ? plan.price.yearly : plan.price.monthly;
  var amountMinor = Math.round(amount * 100); // USD dollars → cents (the minor unit)
  var user = window._currentUser;
  var email = (user && user.email) || '';
  var RAZORPAY_KEY_ID = 'rzp_live_REPLACE_WITH_YOUR_KEY';
  var apiBase = (typeof NOWSSB_API !== 'undefined') ? NOWSSB_API : '';

  function _openPayment(orderId) {
    var options = {
      key: RAZORPAY_KEY_ID,
      amount: amountMinor,
      currency: 'USD',
      name: 'NowssB',
      description: plan.name + ' — ' + (billing === 'yearly' ? 'Yearly' : 'Monthly'),
      order_id: orderId || undefined,
      prefill: { email: email },
      theme: { color: '#e8d5a3' },
      notes: { tier: planId, billing: billing },
      handler: function(response) {
        _onSubscriptionSuccess(response, planId, billing, amount);
      }
    };
    if (typeof Razorpay !== 'undefined') {
      try { new Razorpay(options).open(); }
      catch(e) { _onSubscriptionSuccess({ razorpay_payment_id: 'sim_' + Date.now() }, planId, billing, amount); }
    } else {
      _onSubscriptionSuccess({ razorpay_payment_id: 'sim_' + Date.now() }, planId, billing, amount);
    }
  }

  if (apiBase) {
    fetch(apiBase + '/api/razorpay/order', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amount: amountMinor, currency: 'USD', notes: { tier: planId, billing: billing, email: email } })
    })
    .then(function(r){ return r.json(); })
    .then(function(ord){ _openPayment(ord.id); })
    .catch(function(){ _openPayment(''); });
  } else {
    _openPayment('');
  }
};

function _onSubscriptionSuccess(response, planId, billing, amount) {
  var user = window._currentUser;
  if (!user) return;
  var now = new Date();
  var endDate = new Date(now);
  if (billing === 'yearly') endDate.setFullYear(endDate.getFullYear() + 1);
  else endDate.setMonth(endDate.getMonth() + 1);

  // Write to Firestore
  if (window._fbSetDoc) {
    window._fbSetDoc(user.uid, {
      isPro: true,
      tier: planId,
      subscriptionBilling: billing,
      subscriptionStartDate: now.toISOString(),
      subscriptionEndDate: endDate.toISOString(),
      subscriptionPaymentId: response.razorpay_payment_id || '',
    }).catch(function(){});
  }

  // Update local cache
  if (window._userDataCache) {
    window._userDataCache.isPro = true;
    window._userDataCache.tier = planId;
    window._userDataCache.subscriptionBilling = billing;
    window._userDataCache.subscriptionStartDate = now.toISOString();
    window._userDataCache.subscriptionEndDate = endDate.toISOString();
  }

  // Some plans include a free verification badge (Frequency X → Blue) — grant
  // it, but never downgrade a tier the user already has (e.g. already Gold).
  var subscribedPlan = SS_PLANS.find(function(p){ return p.id === planId; });
  if (subscribedPlan && subscribedPlan.grantsVerifyTier) {
    var vtierRank = { blue:1, silver:2, gold:3, diamond:4 };
    var curVtier = '';
    try { curVtier = localStorage.getItem('nwsb_verify_tier') || ''; } catch(e) {}
    if (!curVtier) curVtier = (window._userDataCache && window._userDataCache.verifyTier) || '';
    if (!curVtier || (vtierRank[subscribedPlan.grantsVerifyTier] || 0) > (vtierRank[curVtier] || 0)) {
      try { localStorage.setItem('nwsb_verify_tier', subscribedPlan.grantsVerifyTier); } catch(e) {}
      if (window._userDataCache) window._userDataCache.verifyTier = subscribedPlan.grantsVerifyTier;
      if (window._fbSetDoc) window._fbSetDoc(user.uid, { verifyTier: subscribedPlan.grantsVerifyTier }).catch(function(){});
    }
  }

  // Hide trial banner and promo bars
  var banner = document.getElementById('trial-banner');
  if (banner) banner.style.display = 'none';
  if (window._spRefreshPromo) window._spRefreshPromo();

  // Hide expired overlay if shown
  var expOv = document.getElementById('trial-expired-overlay');
  if (expOv) expOv.style.display = 'none';

  // Close subscription panel
  if (window.ssClosePanel) window.ssClosePanel('subscription');

  // Show success screen
  _showSubscriptionSuccess(planId);
}

/* Render plan cards inside the trial-expired overlay */
function _renderExpiredPlanCards() {
  var container = document.getElementById('trial-exp-plan-cards');
  if (!container || !window.SS_PLANS) return;
  container.innerHTML = SS_PLANS.map(function(p) {
    var bg = { resonance:'linear-gradient(135deg,#a8d4e8,#7ab8d4)', frequency:'linear-gradient(135deg,#e8d5a3,#c8a96e)', frequencyX:'linear-gradient(135deg,#e0e0e0,#b0b0b0)' };
    return '<div style="padding:20px;border-radius:16px;border:1.5px solid rgba(255,255,255,.1);background:rgba(255,255,255,.04);">'+
      '<div style="font-size:17px;font-weight:700;color:'+p.color+';font-family:\'DM Sans\',sans-serif;margin-bottom:4px;">'+p.name+'</div>'+
      '<div style="font-size:11px;color:rgba(255,255,255,.45);font-family:\'DM Sans\',sans-serif;margin-bottom:14px;">'+p.tagline+'</div>'+
      '<div style="font-size:22px;font-weight:800;color:#fff;font-family:\'DM Sans\',sans-serif;margin-bottom:16px;">$'+p.price.monthly+'<span style="font-size:12px;font-weight:400;color:rgba(255,255,255,.45);">/mo</span></div>'+
      '<button onclick="ssStartSubscription(\''+p.id+'\',\'monthly\');document.getElementById(\'trial-expired-overlay\').style.display=\'none\'" style="width:100%;padding:13px 0;border-radius:12px;border:none;background:'+(bg[p.id]||bg.frequency)+';color:#060c18;font-size:14px;font-weight:700;font-family:\'DM Sans\',sans-serif;cursor:pointer;">Continue with '+p.name+'</button>'+
      '</div>';
  }).join('');
}
document.addEventListener('DOMContentLoaded', function(){
  setTimeout(_renderExpiredPlanCards, 1500);
  setTimeout(function(){
    if (window._updateTrialBanner) window._updateTrialBanner();
  }, 2500);
});

function _showSubscriptionSuccess(planId) {
  var overlay = document.getElementById('sub-success-overlay');
  if (!overlay) return;
  var names  = { resonance:'Resonance', frequency:'Frequency', frequencyX:'Frequency X' };
  var titles = { resonance:'Your practice begins now.', frequency:'You are the frequency.', frequencyX:'Mastery unlocked.' };
  var unlocks = {
    resonance: ['All 20 health categories', 'AI pronunciation scoring', 'AI daily word prescription'],
    frequency: ['Voice Resonance Score overlay', 'Sentence Alchemy personalised', 'Unlimited Word Atelier', 'Premium certificates + export'],
    frequencyX:['5 custom word requests/month', 'Word Drop 48h early access', 'ElevenLabs studio voice', 'Exclusive Frequency X community']
  };
  var color = { resonance:'#c8e8f5', frequency:'#e8d5a3', frequencyX:'#f0f0f0' };
  var planName = names[planId] || planId;
  var planTitle = titles[planId] || 'Welcome.';
  var planColor = color[planId] || '#e8d5a3';
  var planUnlocks = (unlocks[planId] || []);
  var nameEl    = document.getElementById('sub-success-plan-name');
  var titleEl   = document.getElementById('sub-success-title');
  var unlocksEl = document.getElementById('sub-success-unlocks');
  if (nameEl)    nameEl.textContent  = planName;
  if (nameEl)    nameEl.style.color  = planColor;
  if (titleEl)   titleEl.textContent = planTitle;
  if (unlocksEl) unlocksEl.innerHTML = planUnlocks.map(function(u){
    return '<div style="display:flex;align-items:center;gap:10px;padding:10px 0;border-bottom:1px solid rgba(255,255,255,.06);">'+
      '<div style="width:20px;height:20px;border-radius:50%;background:'+planColor+'18;border:1.5px solid '+planColor+';display:flex;align-items:center;justify-content:center;flex-shrink:0;">'+
      '<svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="'+planColor+'" stroke-width="2.5"><path d="M20 6L9 17l-5-5"/></svg>'+
      '</div><span style="font-size:14px;color:rgba(255,255,255,.85);font-family:\'DM Sans\',sans-serif;">'+u+'</span></div>';
  }).join('');
  overlay.style.display = 'flex';
}
