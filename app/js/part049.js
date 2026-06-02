
window.showFashionHomeIntro = function() {
  if (!window._splashDone) return;
  var el = document.getElementById('fashionHomeIntro');
  if (!el) return;
  // Unlock the CSS lock — without this body class, !important keeps it hidden
  document.body.classList.add('fi-ready');
  el.style.display = 'block';
  el.style.opacity = '0';
  el.style.transition = 'opacity 0.5s ease';
  requestAnimationFrame(function(){ requestAnimationFrame(function(){ el.style.opacity = '1'; }); });
};
window.fashionHomeIntroEnter = function() {
  var el = document.getElementById('fashionHomeIntro');
  if (!el) return;
  el.style.transition = 'opacity 0.38s ease';
  el.style.opacity = '0';
  setTimeout(function(){
    el.style.display = 'none';
    document.body.classList.remove('fi-ready');
    localStorage.setItem('nwsb_home_mode', 'home');
    document.querySelectorAll('.sub-screen.open').forEach(function(s){ s.classList.remove('open'); });
    if (typeof goTo === 'function') goTo('home');
  }, 400);
};

;

/* ── Radial / Meaning helpers added for redesigned player ── */
window.pwToggleRadial = function() {
  var w = document.getElementById('spRadialWrap');
  if (w) w.classList.toggle('open');
};
window.pwCycleRepTarget = function() {
  var t = [3,7,21]; var i = t.indexOf(_pwRepTarget);
  _pwRepTarget = t[(i+1)%t.length];
  var rv = document.getElementById('ssRepsVal');
  if (rv) rv.textContent = _pwRepTarget + '×';
};
window.pwExpandMeaning = function() {
  var s = document.getElementById('spMeaningSheet');
  if (!s) return;
  var w = PRACTICE_WORDS[_pwIdx]; if (!w) return;
  s.innerHTML = '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;"><div style="font-size:16px;font-weight:700;color:#fff;font-family:\'DM Sans\',sans-serif;">' + w.word + '</div><button onclick="pwCloseMeaning()" style="background:none;border:none;color:rgba(255,255,255,0.5);font-size:20px;cursor:pointer;line-height:1;">×</button></div>' +
    '<div style="font-size:13px;color:rgba(255,255,255,0.75);line-height:1.7;font-family:\'DM Sans\',sans-serif;margin-bottom:10px;">' + w.meaning + '</div>' +
    '<div style="font-size:10px;letter-spacing:1px;color:rgba(232,213,163,0.65);margin-bottom:6px;text-transform:uppercase;">' + w.organ + '</div>' +
    '<div style="font-size:12px;color:rgba(255,255,255,0.55);line-height:1.65;font-family:\'DM Sans\',sans-serif;">' + (w.benefit||'') + '</div>';
  s.classList.add('open');
};
window.pwCloseMeaning = function() {
  var s = document.getElementById('spMeaningSheet');
  if (s) s.classList.remove('open');
};
