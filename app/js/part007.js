
function wsEnterFromIntro() {
  var intro = document.getElementById('wsIntroPage');
  var main  = document.getElementById('wsMainContent');
  if (!intro || !main) return;
  intro.classList.add('sl-intro-hidden');
  setTimeout(function() {
    intro.style.display = 'none';
    main.style.display  = 'flex';
  }, 320);
}

function shabdaEnterFromIntro() {
  var intro = document.getElementById('shabdaIntroPage');
  var main  = document.getElementById('shabdaMainContent');
  if (!intro || !main) return;
  intro.classList.add('sl-intro-hidden');
  setTimeout(function() {
    intro.style.display = 'none';
    main.style.display  = 'flex';
  }, 320);
}

function wsShowTab(idx) {
  var tabs   = document.querySelectorAll('.ws-tab');
  var panels = document.querySelectorAll('.ws-panel');
  tabs.forEach(function(t,i){ t.classList.toggle('ws-active', i===idx); });
  panels.forEach(function(p,i){
    var wasActive = p.classList.contains('ws-panel-active');
    p.classList.toggle('ws-panel-active', i===idx);
    if (i===idx && !wasActive) { p.scrollTop = 0; }
  });
  // Scroll active tab into view
  if(tabs[idx]) tabs[idx].scrollIntoView({inline:'center',behavior:'smooth'});
}

// Reset intro when word-science is closed
(function() {
  var _origClose = window.closeSub;
  window.closeSub = function(id) {
    if (id === 'word-science') {
      setTimeout(function() {
        var intro = document.getElementById('wsIntroPage');
        var main  = document.getElementById('wsMainContent');
        if (intro) { intro.style.display = ''; intro.classList.remove('sl-intro-hidden'); }
        if (main)  { main.style.display  = 'none'; }
        wsShowTab(0);
      }, 350);
    }
    if (id === 'shabdapathy') {
      setTimeout(function() {
        var intro = document.getElementById('shabdaIntroPage');
        var main  = document.getElementById('shabdaMainContent');
        if (intro) { intro.style.display = ''; intro.classList.remove('sl-intro-hidden'); }
        if (main)  { main.style.display  = 'none'; }
      }, 350);
    }
    if (_origClose) _origClose(id);
  };
})();
