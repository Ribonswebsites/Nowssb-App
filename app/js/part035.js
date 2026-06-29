
/* ═══════════════════════════════════════════════
   HEALING BODY MAP CONTROLLER
═══════════════════════════════════════════════ */
window.HBM = {};
window.HBM = (function(){

  // Map organ strings from word data → display names + colors + SVG region IDs
  /* pos = glow-point position over the glass body image (percent of the image box) */
  var ORGANS = [
    { key:'brain',    labels:['Brain','Mind','Mind · Emotions'],                   color:'#bfe8ff', name:'Brain & Mind',       pos:{x:50, y:14, w:26} },
    { key:'lungs',    labels:['Lungs · Heart','Lung','Lungs · Joints','Lungs'],    color:'#9fe0ff', name:'Lungs & Breath',     pos:{x:50, y:56, w:42} },
    { key:'heart',    labels:['Heart · Energy','Heart'],                            color:'#ff9d9d', name:'Heart & Energy',     pos:{x:53, y:58, w:16} },
    { key:'stomach',  labels:['Solar Plexus','Liver · Digestion','Gut'],            color:'#ffd79c', name:'Core & Digestion',   pos:{x:55, y:69, w:18} },
    { key:'liver',    labels:['Liver','Liver · Detox'],                             color:'#d9a8ff', name:'Liver & Detox',      pos:{x:45, y:71, w:20} },
    { key:'immune',   labels:['Immune System','Immune · Vitality'],                 color:'#9dffc6', name:'Immune System',      pos:{x:37, y:63, w:13} },
    { key:'nerves',   labels:['Nervous System'],                                    color:'#f7f0a0', name:'Nervous System',     pos:{x:50, y:51, w:9}  },
    { key:'skin',     labels:['Eyes · Skin','Skin & Glow'],                        color:'#ffcaa0', name:'Skin & Eyes',        pos:{x:50, y:27, w:16} },
    { key:'vitality', labels:['Vitality','Testosterone & Hormones','Reproductive'], color:'#f0a0ff', name:'Vitality & Hormones',pos:{x:50, y:87, w:24} },
    { key:'joints',   labels:['Joints'],                                            color:'#a8c8ff', name:'Joints & Mobility',  pos:{x:50, y:46, w:48} },
  ];
  var HBM_IMG = 'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782744689/image_fddllc.jpg';

  // Match an organ string from PRACTICE_WORDS to an ORGANS key
  function matchOrgan(organStr){
    if (!organStr) return null;
    var s = organStr.toLowerCase();
    for (var i=0; i<ORGANS.length; i++){
      var o = ORGANS[i];
      for (var j=0; j<o.labels.length; j++){
        if (s.indexOf(o.labels[j].toLowerCase()) >= 0 || o.labels[j].toLowerCase().indexOf(s) >= 0) return o.key;
      }
    }
    return null;
  }

  // Build activation counts from session data + MASTER_WORD_LIBRARY
  function buildActivations(sessionData){
    var counts = {};
    ORGANS.forEach(function(o){ counts[o.key] = 0; });

    var wordLib = window.MASTER_WORD_LIBRARY || [];
    var sessions = (sessionData && sessionData.sessions) ? sessionData.sessions : {};

    // Count from firebase session records
    Object.keys(sessions).forEach(function(k){
      var wordName = k.split('_').slice(1).join('_');
      var wordObj = wordLib.find(function(w){ return w.word === wordName; });
      if (!wordObj) return;
      var key = matchOrgan(wordObj.organ);
      if (key) counts[key]++;
    });

    // Also count from current practice session (live)
    var practiced = window._pwSession || [];
    practiced.forEach(function(wordName){
      var wordObj = wordLib.find(function(w){ return w.word === wordName; });
      if (!wordObj) return;
      var key = matchOrgan(wordObj.organ);
      if (key) counts[key] = (counts[key]||0) + 1;
    });

    return counts;
  }

  // Record current word as practiced (called by player)
  window._hbmRecordWord = function(wordName){
    if (!window._pwSession) window._pwSession = [];
    if (window._pwSession.indexOf(wordName) < 0) window._pwSession.push(wordName);
  };

  // ── Build the glass-body map: real image + a glow point per organ ──
  function buildSVG(counts, mini){
    var points = ORGANS.map(function(o){
      if (!o.pos) return '';
      var cnt = counts[o.key] || 0;
      var active = cnt > 0;
      return '<div class="hbm-point'+(active?' active':'')+'" data-key="'+o.key+'" data-count="'+cnt+'" '+
        (mini ? '' : 'onclick="HBM.tipOrgan(event,\''+o.key+'\')" ')+
        'style="--organ-color:'+o.color+';left:'+o.pos.x+'%;top:'+o.pos.y+'%;width:'+o.pos.w+'%;"></div>';
    }).join('');
    return '<div class="hbm-figure'+(mini?' mini':'')+'" style="background-image:url(\''+HBM_IMG+'\')">'+points+'</div>';
  }

  // Build legend chips
  function buildLegend(counts){
    return ORGANS.map(function(o){
      var cnt = counts[o.key]||0;
      var active = cnt > 0;
      return '<div class="hbm-chip'+(active?' active':'')+'" style="--chip-color:'+o.color+'" onclick="HBM.tipChip(\''+o.key+'\')">' +
        '<div class="hbm-chip-dot"></div>'+
        '<span class="hbm-chip-label">'+o.name+(active?' · '+cnt:'')+'</span>'+
        '</div>';
    }).join('');
  }

  // Tooltip
  var _tipTimeout;
  window.HBM.tipOrgan = function(e, key){
    if (!e) return;
    var o = ORGANS.find(function(x){ return x.key===key; }); if(!o) return;
    var target = e.currentTarget || e.target;
    var tip = document.getElementById('hbm-tooltip');
    if (!tip) return;
    var cnt = parseInt(target.getAttribute('data-count')||'0');
    tip.querySelector('.hbm-tooltip-organ').textContent = o.name;
    tip.querySelector('.hbm-tooltip-count').textContent = cnt > 0
      ? 'Activated '+cnt+' time'+(cnt===1?'':'s')
      : 'Not yet activated';
    tip.style.left = '50%'; tip.style.bottom = '50%';
    tip.classList.add('show');
    clearTimeout(_tipTimeout);
    _tipTimeout = setTimeout(function(){ tip.classList.remove('show'); }, 2400);
  };
  window.HBM.tipChip = function(key){
    var o = ORGANS.find(function(x){ return x.key===key; }); if(!o) return;
    var wrap = document.querySelector('.hbm-svg-wrap');
    if (!wrap) return;
    var tip = document.getElementById('hbm-tooltip');
    if (!tip) return;
    var counts = window._hbmLastCounts || {};
    var cnt = counts[key]||0;
    tip.querySelector('.hbm-tooltip-organ').textContent = o.name;
    tip.querySelector('.hbm-tooltip-count').textContent = cnt > 0
      ? 'Activated '+cnt+' time'+(cnt===1?'':'s')
      : 'Not yet activated — practice words that target this organ';
    tip.classList.add('show');
    clearTimeout(_tipTimeout);
    _tipTimeout = setTimeout(function(){ tip.classList.remove('show'); }, 2800);
  };

  // ── Public render functions ──
  return {
    tipOrgan: window.HBM.tipOrgan,
    tipChip:  window.HBM.tipChip,

    // Full map HTML string (injected into mpRender)
    renderHTML: function(sessionData){
      var counts = buildActivations(sessionData);
      window._hbmLastCounts = counts;
      var total = Object.values(counts).reduce(function(a,b){ return a+b; }, 0);
      var activated = Object.keys(counts).filter(function(k){ return counts[k]>0; }).length;

      return '<div class="hbm-wrap">'+
        '<div class="hbm-title-row">'+
          '<span class="hbm-title">Healing Body Map</span>'+
          '<span class="hbm-total">'+activated+' organs · '+total+' activations</span>'+
        '</div>'+
        '<div class="hbm-svg-wrap" style="position:relative;">'+
          buildSVG(counts, false)+
          '<div class="hbm-tooltip" id="hbm-tooltip">'+
            '<div class="hbm-tooltip-organ"></div>'+
            '<div class="hbm-tooltip-count"></div>'+
          '</div>'+
        '</div>'+
        '<div class="hbm-legend">'+buildLegend(counts)+'</div>'+
      '</div>';
    },

    // Mini version for profile header
    renderMini: function(sessionData){
      var counts = buildActivations(sessionData);
      return '<div class="hbm-mini-wrap">'+
        buildSVG(counts, true)+
        '<div class="hbm-mini-label">Body Map</div>'+
      '</div>';
    },

    // Called after each word is practiced to update live
    refresh: function(sessionData){
      var el = document.getElementById('hbm-full');
      if (el) el.innerHTML = this.renderHTML(sessionData);
      var mel = document.getElementById('hbm-profile-mini');
      if (mel) mel.innerHTML = this.renderMini(sessionData);
    }
  };
})();
