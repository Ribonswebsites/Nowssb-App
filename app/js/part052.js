/* ══════════════════════════════════════════════════════════
   LOCATION-BASED CURRENCY — one-time "Enable Location Access" prompt,
   real geolocation + reverse-geocoding, and a shared price-formatting
   helper other screens (Meaning Store, etc.) call into.

   Prices stay defined in the app's base currency everywhere they already
   were (Word Atelier/Ebooks in USD cents, Meaning Store in raw INR) — this
   module only changes what's DISPLAYED to match the user's own country,
   same "shown in local currency" pattern already used by the Verification
   checkout. It never changes what's actually charged.
═══════════════════════════════════════════════════════════ */
(function(){
  'use strict';

  // Country → local currency [code, symbol, approx units per 1 USD].
  var _EU = ['Austria','Belgium','Croatia','Cyprus','Estonia','Finland','France','Germany','Greece','Ireland','Italy','Latvia','Lithuania','Luxembourg','Malta','Netherlands','Portugal','Slovakia','Slovenia','Spain','Andorra','Monaco','Montenegro','Kosovo','San Marino','Vatican City'];
  var CURRENCY_MAP = {
    'United Kingdom':['GBP','£',0.79],'India':['INR','₹',83],'Canada':['CAD','C$',1.36],'Australia':['AUD','A$',1.52],'New Zealand':['NZD','NZ$',1.63],'Japan':['JPY','¥',157],'China':['CNY','¥',7.2],'Switzerland':['CHF','Fr',0.88],'Sweden':['SEK','kr',10.5],'Norway':['NOK','kr',10.7],'Denmark':['DKK','kr',6.9],'Singapore':['SGD','S$',1.35],'Hong Kong':['HKD','HK$',7.8],'United Arab Emirates':['AED','د.إ',3.67],'Saudi Arabia':['SAR','﷼',3.75],'Qatar':['QAR','﷼',3.64],'Kuwait':['KWD','د.ك',0.31],'Brazil':['BRL','R$',5.0],'Mexico':['MXN','MX$',17],'South Africa':['ZAR','R',18.5],'Russia':['RUB','₽',90],'Turkey':['TRY','₺',32],'South Korea':['KRW','₩',1350],'Indonesia':['IDR','Rp',15800],'Malaysia':['MYR','RM',4.7],'Thailand':['THB','฿',36],'Philippines':['PHP','₱',57],'Vietnam':['VND','₫',25000],'Pakistan':['PKR','₨',278],'Bangladesh':['BDT','৳',110],'Sri Lanka':['LKR','Rs',300],'Nepal':['NPR','₨',133],'Nigeria':['NGN','₦',1500],'Kenya':['KES','KSh',130],'Egypt':['EGP','E£',48],'Ghana':['GHS','₵',15],'Israel':['ILS','₪',3.7],'Poland':['PLN','zł',4.0],'Czechia':['CZK','Kč',23],'Hungary':['HUF','Ft',360],'Romania':['RON','lei',4.6],'Ukraine':['UAH','₴',41],'Argentina':['ARS','$',900],'Chile':['CLP','$',950],'Colombia':['COP','$',3900],'Peru':['PEN','S/',3.8]
  };
  _EU.forEach(function(c){ CURRENCY_MAP[c] = ['EUR','€',0.92]; });
  var _NO_DEC = {JPY:1,KRW:1,VND:1,IDR:1,HUF:1,CLP:1,COP:1,PKR:1,NGN:1,INR:1};

  function currencyForCountry(name) {
    var c = CURRENCY_MAP[name];
    if (!c) return { code: 'USD', symbol: '$', rate: 1, dec: 2 };
    return { code: c[0], symbol: c[1], rate: c[2], dec: _NO_DEC[c[0]] ? 0 : 2 };
  }
  window.nwsbCurrencyForCountry = currencyForCountry;

  // window.nwsbCurrency stays null until a real location is detected —
  // formatters fall back to each screen's own native currency (₹ for the
  // INR-native Meaning Store, $ for USD-native screens) rather than
  // silently assuming USD, which was showing $0.59 for a ₹49 meaning
  // before the user had ever granted location access.
  function loadCurrency() {
    try {
      var raw = localStorage.getItem('nwsb_user_currency');
      if (raw) return JSON.parse(raw);
    } catch (e) {}
    return null;
  }
  window.nwsbCurrency = loadCurrency();

  function setCurrency(cur, country) {
    window.nwsbCurrency = cur;
    try {
      localStorage.setItem('nwsb_user_currency', JSON.stringify(cur));
      if (country) localStorage.setItem('nwsb_user_country', country);
    } catch (e) {}
    // Re-render any store screens currently built so prices update live.
    if (typeof window.msRenderStore === 'function') window.msRenderStore();
    if (typeof window.ebRenderStore === 'function') window.ebRenderStore();
  }

  function fmt(v, symbol, dec) {
    var s = dec === 0 ? String(Math.round(v)) : v.toFixed(2);
    s = s.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return symbol + s;
  }
  window.nwsbFormatUSD = function(usd) {
    usd = usd || 0;
    var cur = window.nwsbCurrency;
    if (!cur) return fmt(usd, '$', 2);
    return fmt(usd * cur.rate, cur.symbol, cur.dec);
  };
  // Meaning Store prices are stored natively in INR — convert INR → USD →
  // the detected local currency for display.
  window.nwsbFormatINR = function(inr) {
    inr = inr || 0;
    var cur = window.nwsbCurrency;
    if (!cur) return fmt(inr, '₹', 0);
    var usd = inr / CURRENCY_MAP['India'][2];
    return fmt(usd * cur.rate, cur.symbol, cur.dec);
  };

  /* ── One-time "Enable Location Access" prompt ── */
  window.nwsbLocAccept = function() {
    var el = document.getElementById('nwsbLocOverlay');
    if (el) el.classList.remove('open');
    try { localStorage.setItem('nwsb_location_prompt_seen', '1'); } catch (e) {}
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(function(pos) {
      var lat = pos.coords.latitude, lon = pos.coords.longitude;
      fetch('https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=' + lat + '&longitude=' + lon + '&localityLanguage=en')
        .then(function(r) { return r.json(); })
        .then(function(d) {
          var country = d && d.countryName;
          if (country) setCurrency(currencyForCountry(country), country);
        })
        .catch(function() {});
    }, function() { /* denied or failed — silently keep default currency */ }, { timeout: 8000 });
  };
  window.nwsbLocDismiss = function() {
    var el = document.getElementById('nwsbLocOverlay');
    if (el) el.classList.remove('open');
    try { localStorage.setItem('nwsb_location_prompt_seen', '1'); } catch (e) {}
  };
  window.nwsbMaybeShowLocationPrompt = function() {
    var seen = false;
    try { seen = localStorage.getItem('nwsb_location_prompt_seen') === '1'; } catch (e) {}
    if (seen) return;
    var el = document.getElementById('nwsbLocOverlay');
    if (el) el.classList.add('open');
  };

  /* Fire once, right after the splash finishes and the user lands on Home —
     not tied to any one screen, so the app knows the user's country from
     the very start of the session. Hooks goTo() the same way part021.js
     already does (check currentScreen === 'splash' BEFORE calling through)
     so this stacks safely instead of fighting that existing hook. */
  (function hookGoToForLocationPrompt() {
    var _prevGoTo = window.goTo;
    if (!_prevGoTo) { setTimeout(hookGoToForLocationPrompt, 200); return; }
    window.goTo = function(dest) {
      var fromSplash = (typeof currentScreen !== 'undefined' && currentScreen === 'splash');
      var result = _prevGoTo.apply(this, arguments);
      if (fromSplash && (dest === 'home' || dest === 'home-nm')) {
        setTimeout(function() {
          if (typeof window.nwsbMaybeShowLocationPrompt === 'function') window.nwsbMaybeShowLocationPrompt();
        }, 1200);
      }
      return result;
    };
  })();
})();
