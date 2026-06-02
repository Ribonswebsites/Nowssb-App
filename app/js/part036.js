
/* ═══════════════════════════════════════════════
   WORD MASTERY CERTIFICATE CONTROLLER
═══════════════════════════════════════════════ */
window.CERT = (function(){

  // Storage key for mastery progress
  var STORE_KEY = 'nowssb_mastery_v1';

  function load(){
    try { return JSON.parse(localStorage.getItem(STORE_KEY)||'{}'); } catch(e){ return {}; }
  }
  function save(data){
    try { localStorage.setItem(STORE_KEY, JSON.stringify(data)); } catch(e){}
  }

  // Record a score for a word. Returns true if mastery just achieved.
  function recordScore(wordName, score){
    var data = load();
    if (!data[wordName]) data[wordName] = { scores:[], mastered:false, masteredDate:null };
    var entry = data[wordName];
    if (entry.mastered) { save(data); return false; } // already mastered

    if (score >= 90){
      entry.scores.push(score);
    } else {
      entry.scores = []; // reset streak on any score < 90
    }

    if (entry.scores.length >= 3){
      entry.mastered = true;
      entry.masteredDate = new Date().toISOString().split('T')[0];
      entry.avgScore = Math.round(entry.scores.reduce(function(a,b){return a+b;},0)/entry.scores.length);
      save(data);
      return true; // mastery achieved!
    }
    save(data);
    return false;
  }

  function getProgress(wordName){
    var data = load();
    var entry = data[wordName];
    if (!entry) return { count:0, mastered:false };
    return { count: entry.mastered ? 3 : entry.scores.length, mastered: entry.mastered, avgScore: entry.avgScore, masteredDate: entry.masteredDate };
  }

  function getAllMastered(){
    var data = load();
    return Object.keys(data).filter(function(k){ return data[k].mastered; }).map(function(k){
      return Object.assign({ word:k }, data[k]);
    });
  }

  // Show toast progress indicator below the player
  function showProgressToast(wordName, count){
    var existing = document.getElementById('cert-toast');
    if (existing) existing.remove();
    var toast = document.createElement('div');
    toast.id = 'cert-toast';
    toast.className = 'cert-progress-toast';
    var dots = [0,1,2].map(function(i){
      return '<div class="cert-toast-dot'+(i<count?' filled':'')+'"></div>';
    }).join('');
    toast.innerHTML = '<div class="cert-toast-dots">'+dots+'</div>'+
      '<div class="cert-toast-text">Mastery: '+count+'/3 perfect sessions</div>';
    document.body.appendChild(toast);
    setTimeout(function(){ if(toast.parentNode) toast.remove(); }, 3500);
  }

  // Show the certificate overlay
  function showCert(wordName, word){
    var progress = getProgress(wordName);
    var userName = window._userDataCache && window._userDataCache.displayName
      ? window._userDataCache.displayName
      : (window._userName || 'Practitioner');

    var el = function(id){ return document.getElementById(id); };
    if (el('certUserName'))  el('certUserName').textContent  = userName;
    if (el('certWord'))      el('certWord').textContent      = wordName;
    if (el('certPhonetic'))  el('certPhonetic').textContent  = (word && word.phonetic) ? word.phonetic.toUpperCase() : '';
    if (el('certOrgan'))     el('certOrgan').textContent     = (word && word.organ) ? word.organ.toUpperCase() : 'FREQUENCY MASTERED';
    if (el('certScoreText')) el('certScoreText').textContent = 'Avg score ' + (progress.avgScore||'—') + ' · 3 sessions';
    if (el('certDate')){
      var d = progress.masteredDate ? new Date(progress.masteredDate) : new Date();
      el('certDate').textContent = d.toLocaleDateString('en',{day:'numeric',month:'long',year:'numeric'});
    }
    var overlay = document.getElementById('cert-overlay');
    if (overlay) overlay.classList.add('open');
  }

  // Public API
  return {
    // Called from pwScoreRecording after score is determined
    onScore: function(wordName, score, wordObj){
      var justMastered = recordScore(wordName, score);
      var progress = getProgress(wordName);

      if (justMastered){
        // Small delay so score UI renders first
        setTimeout(function(){
          showCert(wordName, wordObj);
          // Also update certificates panel if open
          if (typeof ssRenderCertificates === 'function') ssRenderCertificates();
        }, 800);
      } else if (score >= 90 && !progress.mastered){
        showProgressToast(wordName, progress.count);
      }
    },

    open: function(wordName){
      var data = load();
      var entry = data[wordName] || {};
      var lib = window.MASTER_WORD_LIBRARY || [];
      var wordObj = lib.find(function(w){ return w.word===wordName; });
      showCert(wordName, wordObj);
    },

    close: function(){
      var overlay = document.getElementById('cert-overlay');
      if (overlay) overlay.classList.remove('open');
    },

    share: function(){
      var card = document.getElementById('certCard');
      if (!card) return;
      var word = document.getElementById('certWord');
      var text = 'I just mastered the word ' + (word ? word.textContent : '') +
        ' on NowssB — Shabdapathy pronunciation practice. nowssb.com';
      if (navigator.share){
        navigator.share({ title:'NowssB Word Mastery', text:text }).catch(function(){});
      } else {
        try { navigator.clipboard.writeText(text); } catch(e){}
        alert('Certificate text copied! Share it anywhere.');
      }
    },

    getAll:      getAllMastered,
    getProgress: getProgress,
    addMockCert: function(wordName){ // for testing
      var lib = window.MASTER_WORD_LIBRARY||[];
      var w = lib.find(function(x){ return x.word===wordName; })||{word:wordName};
      var data = load();
      data[wordName] = { scores:[92,95,97], mastered:true,
        masteredDate: new Date().toISOString().split('T')[0], avgScore:95 };
      save(data);
      showCert(wordName, w);
    }
  };
})();

/* ── Hook into pwScoreRecording — patch the score handler ── */
(function(){
  function patchScorer(){
    var orig = window.pwScoreRecording;
    if (typeof orig !== 'function'){ return setTimeout(patchScorer, 300); }
    window.pwScoreRecording = async function(){
      // Run original first
      await orig.apply(this, arguments);
      // Then check the displayed score and notify CERT
      var scoreEl = document.getElementById('spScoreNum');
      if (!scoreEl) return;
      var score = parseInt(scoreEl.textContent, 10);
      if (isNaN(score)) return;
      var w = (window.PRACTICE_WORDS && window.PRACTICE_WORDS[window._pwIdx])
            ? window.PRACTICE_WORDS[window._pwIdx] : null;
      if (!w) return;
      window.CERT.onScore(w.word, score, w);
    };
  }
  patchScorer();
})();

/* ── Wire Certificates panel to show real earned certs ── */
(function(){
  var _origRender = window.ssRenderCertificates;
  window.ssRenderCertificates = function(){
    var box = document.getElementById('ss-cert-list');
    if (!box){ if(_origRender) _origRender(); return; }

    var lib = window.MASTER_WORD_LIBRARY || [];
    var earned = window.CERT.getAll();

    // Also check progress for unearned words that have been attempted
    var STORE_KEY = 'nowssb_mastery_v1';
    var allData = {};
    try { allData = JSON.parse(localStorage.getItem(STORE_KEY)||'{}'); } catch(e){}
    var inProgress = Object.keys(allData).filter(function(k){ return !allData[k].mastered && allData[k].scores && allData[k].scores.length > 0; });

    var html = '';

    if (earned.length === 0 && inProgress.length === 0){
      html = '<div style="text-align:center;padding:40px 20px;color:rgba(255,255,255,.3);font-size:13px;font-family:\'DM Sans\',sans-serif;line-height:1.7;">'+
        'No certificates yet.<br>Score 90+ three sessions in a row<br>to earn your first certificate.</div>';
    }

    earned.forEach(function(entry){
      var w = lib.find(function(x){ return x.word===entry.word; }) || {};
      html += '<div onclick="CERT.open(\''+entry.word+'\')" style="cursor:pointer;border:1.5px solid rgba(232,213,163,.3);border-radius:18px;padding:18px;margin-bottom:14px;background:linear-gradient(135deg,rgba(232,213,163,.06),rgba(200,232,245,.03));position:relative;overflow:hidden;">'+
        '<div style="position:absolute;top:-20px;right:-20px;width:80px;height:80px;border-radius:50%;background:#e8d5a3;opacity:.05;filter:blur(18px);"></div>'+
        '<div style="display:flex;align-items:center;gap:12px;">'+
        '<div style="width:46px;height:46px;border-radius:12px;background:rgba(232,213,163,.1);display:flex;align-items:center;justify-content:center;flex-shrink:0;">'+
        '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.5"><circle cx="12" cy="8" r="6"/><polyline points="8.5 13.5 7 22 12 19 17 22 15.5 13.5"/></svg></div>'+
        '<div style="flex:1;">'+
        '<div style="font-size:18px;font-weight:800;color:#e8d5a3;font-family:\'DM Sans\',sans-serif;letter-spacing:.5px;">'+entry.word+'</div>'+
        '<div style="font-size:12px;color:rgba(255,255,255,.45);font-family:\'DM Sans\',sans-serif;">'+(w.organ||'')+(entry.masteredDate?' · '+entry.masteredDate:'')+'</div></div>'+
        '<div style="text-align:right;"><div style="font-size:18px;font-weight:800;color:#e8d5a3;font-family:\'DM Sans\',sans-serif;">'+(entry.avgScore||'—')+'%</div>'+
        '<div style="font-size:10px;color:rgba(232,213,163,.5);font-family:\'DM Sans\',sans-serif;">avg</div></div></div></div>';
    });

    inProgress.forEach(function(wordName){
      var w = lib.find(function(x){ return x.word===wordName; }) || {};
      var count = allData[wordName].scores.length;
      html += '<div style="border:1px dashed rgba(255,255,255,.1);border-radius:18px;padding:18px;margin-bottom:14px;opacity:.7;">'+
        '<div style="display:flex;align-items:center;gap:12px;">'+
        '<div style="width:46px;height:46px;border-radius:12px;background:rgba(255,255,255,.04);display:flex;align-items:center;justify-content:center;flex-shrink:0;">'+
        '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,.3)" stroke-width="1.5"><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 018 0v4"/></svg></div>'+
        '<div style="flex:1;">'+
        '<div style="font-size:16px;font-weight:700;color:rgba(255,255,255,.6);font-family:\'DM Sans\',sans-serif;">'+wordName+'</div>'+
        '<div style="font-size:12px;color:rgba(255,255,255,.3);font-family:\'DM Sans\',sans-serif;">'+(w.organ||'')+'</div>'+
        '<div style="display:flex;gap:5px;margin-top:8px;">'+
        [0,1,2].map(function(i){ return '<div style="width:10px;height:10px;border-radius:50%;'+(i<count?'background:#e8d5a3;box-shadow:0 0 5px rgba(232,213,163,.4);':'border:1.5px solid rgba(255,255,255,.2);')+'""></div>'; }).join('')+
        '<span style="font-size:10px;color:rgba(255,255,255,.3);font-family:\'DM Sans\',sans-serif;margin-left:6px;">'+count+'/3 sessions</span>'+
        '</div></div></div></div>';
    });

    box.innerHTML = html;
  };
})();
