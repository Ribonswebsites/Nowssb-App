
/* ═══════════════════════════════════════════════
   HEALING BODY MAP CONTROLLER
═══════════════════════════════════════════════ */
window.HBM = {};
window.HBM = (function(){

  // Map organ strings from word data → display names + colors + SVG region IDs
  var ORGANS = [
    { key:'brain',    labels:['Brain','Mind','Mind · Emotions'],                   color:'#c8e8f5', name:'Brain & Mind'       },
    { key:'lungs',    labels:['Lungs · Heart','Lung','Lungs · Joints','Lungs'],    color:'#a8d8f5', name:'Lungs & Breath'      },
    { key:'heart',    labels:['Heart · Energy','Heart'],                            color:'#f5a8a8', name:'Heart & Energy'      },
    { key:'stomach',  labels:['Solar Plexus','Liver · Digestion','Gut'],            color:'#f5d0a8', name:'Core & Digestion'    },
    { key:'liver',    labels:['Liver','Liver · Detox'],                             color:'#d4a8f5', name:'Liver & Detox'       },
    { key:'immune',   labels:['Immune System','Immune · Vitality'],                 color:'#a8f5c8', name:'Immune System'       },
    { key:'nerves',   labels:['Nervous System'],                                    color:'#f5f0a8', name:'Nervous System'      },
    { key:'skin',     labels:['Eyes · Skin','Skin & Glow'],                        color:'#f5c8a8', name:'Skin & Eyes'         },
    { key:'vitality', labels:['Vitality','Testosterone & Hormones','Reproductive'], color:'#e8a8f5', name:'Vitality & Hormones' },
    { key:'joints',   labels:['Joints'],                                            color:'#a8c8f5', name:'Joints & Mobility'  },
  ];

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

  // ── Build full body SVG ──
  function buildSVG(counts, mini){
    var scale = mini ? 0.5 : 1;
    var w = mini ? 90 : 180, h = mini ? 210 : 420;

    function organ(key, pathD, cx, cy){
      var o = ORGANS.find(function(x){ return x.key===key; });
      var cnt = counts[key] || 0;
      var active = cnt > 0;
      return '<g class="hbm-organ'+(active?' active':'')+'" style="--organ-color:'+o.color+'" data-key="'+key+'" data-count="'+cnt+'" onclick="HBM.tipOrgan(event,\''+key+'\')">'+
        '<path class="organ-fill organ-pulse" d="'+pathD+'"/>'+
        '</g>';
    }

    // Paths drawn at 180×420 (1× scale), then scaled via viewBox
    return '<svg viewBox="0 0 180 420" xmlns="http://www.w3.org/2000/svg" class="'+(mini?'hbm-mini':'hbm-body')+'">'+
      // Body silhouette
      '<g opacity=".18">'+
        // Head
        '<ellipse cx="90" cy="38" rx="28" ry="34" fill="rgba(255,255,255,.4)"/>'+
        // Neck
        '<rect x="80" y="68" width="20" height="22" rx="6" fill="rgba(255,255,255,.3)"/>'+
        // Torso
        '<path d="M48 90 Q38 120 36 180 Q36 230 40 260 L140 260 Q144 230 144 180 Q142 120 132 90 Q112 84 90 84 Q68 84 48 90Z" fill="rgba(255,255,255,.25)"/>'+
        // Arms
        '<path d="M48 95 Q24 120 18 180 Q16 210 22 230 L34 230 Q34 200 38 170 Q42 130 54 105Z" fill="rgba(255,255,255,.2)"/>'+
        '<path d="M132 95 Q156 120 162 180 Q164 210 158 230 L146 230 Q146 200 142 170 Q138 130 126 105Z" fill="rgba(255,255,255,.2)"/>'+
        // Legs
        '<path d="M64 258 Q56 290 52 340 Q50 375 54 410 L82 410 Q80 375 80 340 Q82 295 84 258Z" fill="rgba(255,255,255,.2)"/>'+
        '<path d="M116 258 Q124 290 128 340 Q130 375 126 410 L98 410 Q100 375 100 340 Q98 295 96 258Z" fill="rgba(255,255,255,.2)"/>'+
      '</g>'+

      // ── Organs ──
      // Brain (head area)
      organ('brain',  'M72 20 Q72 8 90 7 Q108 8 108 20 Q112 38 108 52 Q108 58 90 59 Q72 58 72 52 Q68 38 72 20Z', 90, 34)+
      // Lungs (upper chest)
      organ('lungs',  'M50 100 Q42 108 40 130 Q40 150 48 164 Q56 172 68 170 Q78 165 80 150 Q82 132 78 112 Q72 98 62 96Z M110 100 Q118 108 140 130 Q140 150 132 164 Q124 172 112 170 Q102 165 100 150 Q98 132 102 112 Q108 98 118 96Z', 90, 135)+
      // Heart (center chest)
      organ('heart',  'M82 118 Q76 110 68 114 Q60 120 64 132 Q68 142 82 152 Q88 156 90 158 Q92 156 98 152 Q112 142 116 132 Q120 120 112 114 Q104 110 98 118 Q94 113 90 115 Q86 113 82 118Z', 90, 135)+
      // Solar plexus / stomach
      organ('stomach','M66 170 Q64 188 66 205 Q68 218 80 224 Q88 228 90 228 Q92 228 100 224 Q112 218 114 205 Q116 188 114 170 Q100 164 90 163 Q80 164 66 170Z', 90, 196)+
      // Liver (right side)
      organ('liver',  'M114 172 Q126 176 130 192 Q132 206 126 214 Q120 220 112 218 Q104 214 102 202 Q100 190 106 178Z', 118, 195)+
      // Immune (lymph nodes — scattered dots represented as area)
      organ('immune', 'M58 130 Q50 142 50 156 Q52 168 60 172 Q66 174 70 168 Q74 160 72 148 Q70 138 62 132Z', 60, 153)+
      // Nervous system (spine-ish area center)
      organ('nerves', 'M86 86 Q84 100 84 120 Q84 160 84 200 Q84 220 86 240 L94 240 Q96 220 96 200 Q96 160 96 120 Q96 100 94 86Z', 90, 163)+
      // Skin/eyes (face area + outline)
      organ('skin',   'M76 26 Q82 20 90 19 Q98 20 104 26 Q110 32 108 40 Q104 50 90 52 Q76 50 72 40 Q70 32 76 26Z', 90, 36)+
      // Vitality (lower abdomen)
      organ('vitality','M68 228 Q64 244 66 258 L90 262 L114 258 Q116 244 112 228 Q100 236 90 236 Q80 236 68 228Z', 90, 244)+
      // Joints (shoulders + hips)
      organ('joints', 'M42 92 Q34 98 32 108 Q32 116 40 120 Q48 122 54 116 Q60 108 56 100 Q50 92 42 92Z M138 92 Q146 92 150 100 Q154 108 146 116 Q140 122 126 120 Q118 116 124 108 Q130 98 138 92Z', 90, 106)+

    '</svg>';
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
