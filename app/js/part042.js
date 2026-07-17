
/* Move ss-panels that are outside #sub-social into it so the scoped CSS applies */
(function(){
  function move(){
    var social = document.getElementById('sub-social');
    if (!social){ setTimeout(move, 100); return; }
    ['ss-panel-voice','ss-panel-speed','ss-panel-reps','ss-panel-sensitivity',
     'ss-panel-ambient','ss-panel-chatperm','ss-panel-blackedition','ss-panel-intro-settings',
     'ss-panel-fashionbg'
    ].forEach(function(id){
      var el = document.getElementById(id);
      if (el && el.parentNode !== social) social.appendChild(el);
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', move);
  else move();
})();

;

/* ══ COMPLETELY REBUILD THE SETTINGS TAB HTML ══ */
(function(){
  function waitFor(id, fn, tries){
    var el = document.getElementById(id);
    if(el){ fn(el); return; }
    if(tries>20) return;
    setTimeout(function(){ waitFor(id, fn, (tries||0)+1); }, 200);
  }

  waitFor('ss-content-settings', function(el){
    el.innerHTML = `
    <!-- Banner -->
    <div class="menu-banner" style="height:220px;margin-bottom:-60px;">
      <img decoding="async" loading="eager" src="https://res.cloudinary.com/dcda8ed8e/image/upload/v1779455673/image-2_gv7pht.jpg" alt="Settings Banner" style="width:100%;height:100%;object-fit:cover;display:block;">
      <div style="position:absolute;inset:0;background:linear-gradient(to bottom,transparent 40%,#060c18 100%);"></div>
    </div>
    <!-- Header -->
    <div style="padding:70px 20px 8px;position:relative;z-index:1;">
      <div style="font-size:10px;letter-spacing:3px;color:#e8d5a3;font-weight:700;font-family:'DM Sans',sans-serif;margin-bottom:6px;">NOWSBANSIU</div>
      <div style="font-size:28px;font-weight:800;color:#fff;font-family:'DM Sans',sans-serif;">Settings</div>
    </div>
    <!-- ── ACCOUNT ── -->
    <div class="ss-section-title">ACCOUNT</div>
    <div class="ss-section">
      <div class="sr" onclick="SS.open('profile-edit')">
        <div class="sr-icon gold"><img loading="lazy" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779563282/62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png" style="width:24px;height:24px;object-fit:contain;display:block;" alt=""></div>
        <div class="sr-body"><div class="sr-label" id="ss-prof-name">Practitioner</div><div class="sr-sub" id="ss-prof-email">—</div></div>
        <span class="sub-badge starter" id="ss-prof-badge" style="font-size:9px;padding:3px 8px;border-radius:6px;font-weight:700;font-family:'DM Sans',sans-serif;">FREE</span>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
      <div class="sr" onclick="SS.open('subscription')">
        <div class="sr-icon gold"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="12" cy="12" r="9"/><path d="M12 3v3M12 18v3M3 12h3M18 12h3"/></svg></div>
        <div class="sr-body"><div class="sr-label">Subscription</div><div class="sr-sub">View or upgrade your plan</div></div>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
      <div class="sr last" onclick="SS.open('certificates')">
        <div class="sr-icon gold"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="12" cy="8" r="6"/><polyline points="8.5 13.5 7 22 12 19 17 22 15.5 13.5"/></svg></div>
        <div class="sr-body"><div class="sr-label">My Certificates</div><div class="sr-sub">Word Mastery achievements</div></div>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
    </div>

    <!-- ── PRACTICE ── -->
    <div class="ss-section-title">PRACTICE</div>
    <div class="ss-section">
      <div class="sr" onclick="SS.open('voice')">
        <div class="sr-icon blue"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M19.07 4.93a10 10 0 010 14.14M15.54 8.46a5 5 0 010 7.07"/></svg></div>
        <div class="sr-body"><div class="sr-label">Default Voice</div><div class="sr-sub">Female or Male — ElevenLabs</div></div>
        <span class="sr-val gold" id="ss-voice-val">Female</span>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
      <div class="sr" onclick="SS.open('speed')">
        <div class="sr-icon blue"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg></div>
        <div class="sr-body"><div class="sr-label">Playback Speed</div><div class="sr-sub">Affects speech synthesis</div></div>
        <span class="sr-val" id="ss-speed-val">1.0×</span>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
      <div class="sr" onclick="SS.open('reps')">
        <div class="sr-icon blue"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><polyline points="17 1 21 5 17 9"/><path d="M3 11V9a4 4 0 014-4h14M7 23l-4-4 4-4"/><path d="M21 13v2a4 4 0 01-4 4H3"/></svg></div>
        <div class="sr-body"><div class="sr-label">Repeat Count</div><div class="sr-sub">Default reps in player</div></div>
        <span class="sr-val" id="ss-reps-val">x3</span>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
      <div class="sr" onclick="SS.open('sensitivity')">
        <div class="sr-icon blue"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg></div>
        <div class="sr-body"><div class="sr-label">Pronunciation Sensitivity</div><div class="sr-sub">Scoring threshold</div></div>
        <span class="sr-val" id="ss-sens-val">Normal</span>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
      <div class="sr" onclick="SS.open('persona')">
        <div class="sr-icon blue"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="12" cy="8" r="4"/><path d="M4 20v-1a8 8 0 0116 0v1"/></svg></div>
        <div class="sr-body"><div class="sr-label">AI Persona</div><div class="sr-sub">Your feedback guide voice</div></div>
        <span class="sr-val" id="personaSubLabel" style="font-size:12px;font-weight:600;color:rgba(255,255,255,.5);font-family:'DM Sans',sans-serif;">Sound Healer</span>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
      <div class="sr last" onclick="SS.toggle('sound')">
        <div class="sr-icon blue"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/></svg></div>
        <div class="sr-body"><div class="sr-label">Session Sounds</div><div class="sr-sub">Audio feedback on completion</div></div>
        <div class="stgl" id="sstgl-sound" style="background:#e8d5a3;"><div class="stgl-knob" style="left:24px;background:#060c18;"></div></div>
      </div>
    </div>


    <!-- ── AUDIO ── -->
    <div class="ss-section-title">AUDIO</div>
    <div class="ss-section">
      <div class="sr" onclick="SS.open('ambient')">
        <div class="sr-icon"><img loading="lazy" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779563282/c500a990-56cf-11f1-8fad-095787cce754_1_zqzbal.png" style="width:24px;height:24px;object-fit:contain;display:block;" alt=""></div>
        <div class="sr-body"><div class="sr-label">Ambient Sound</div><div class="sr-sub">Practice background audio</div></div>
        <span class="sr-val" id="ss-ambient-val">None</span>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
      <div class="sr last" onclick="SS.toggle('notif')">
        <div class="sr-icon"><img loading="lazy" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779657311/e3815a20-57ad-11f1-ae7e-3f26811e4481_y2zb7t.png" style="width:24px;height:24px;object-fit:contain;display:block;" alt=""></div>
        <div class="sr-body"><div class="sr-label">Practice Reminders</div><div class="sr-sub">Daily routine notifications</div></div>
        <div class="stgl" id="sstgl-notif" style="background:#e8d5a3;"><div class="stgl-knob" style="left:24px;background:#060c18;"></div></div>
      </div>
    </div>

    <!-- ── BLACK EDITION ── -->
    <div class="ss-section-title">APPEARANCE</div>
    <div class="ss-section">
      <div class="sr" onclick="SS.open('blackedition')">
        <div class="sr-icon" style="background:#000;border:1px solid rgba(255,255,255,.18);display:flex;align-items:center;justify-content:center;">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <rect x="2" y="2" width="20" height="20" rx="5" fill="#000" stroke="rgba(255,255,255,0.35)" stroke-width="1.5"/>
            <rect x="6" y="6" width="5" height="5" rx="1.5" fill="rgba(255,255,255,0.12)" stroke="rgba(255,255,255,0.25)" stroke-width="1"/>
            <rect x="13" y="6" width="5" height="5" rx="1.5" fill="rgba(232,213,163,0.3)" stroke="rgba(232,213,163,0.6)" stroke-width="1"/>
            <rect x="6" y="13" width="5" height="5" rx="1.5" fill="rgba(255,255,255,0.06)" stroke="rgba(255,255,255,0.15)" stroke-width="1"/>
            <rect x="13" y="13" width="5" height="5" rx="1.5" fill="rgba(200,232,245,0.12)" stroke="rgba(200,232,245,0.3)" stroke-width="1"/>
          </svg>
        </div>
        <div class="sr-body"><div class="sr-label">Black Edition</div><div class="sr-sub">Customise your app appearance</div></div>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
      <div class="sr last" onclick="SS.open('fashionbg')">
        <div class="sr-icon" style="background:rgba(232,213,163,0.1);border:1px solid rgba(232,213,163,0.25);display:flex;align-items:center;justify-content:center;">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.6"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
        </div>
        <div class="sr-body"><div class="sr-label">Fashion Background</div><div class="sr-sub">Backdrop photo for the Fashion home</div></div>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
    </div>

    <!-- ── INTRO PAGES ── -->
    <div class="ss-section-title">INTRO PAGES</div>
    <div class="ss-section">
      <div class="sr last" id="intro-setting-row" onclick="ssOpenPanel('intro-settings');ispStart();">
        <div class="sr-icon" style="background:rgba(232,213,163,0.1);border:1px solid rgba(232,213,163,0.25);display:flex;align-items:center;justify-content:center;">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.6"><circle cx="12" cy="12" r="5"/><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/></svg>
        </div>
        <div class="sr-body"><div class="sr-label">Screen Meditation Intros</div><div class="sr-sub" id="isp-status-sub">Showing before each section</div></div>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
    </div>

    <!-- ── PRIVACY ── -->
    <div class="ss-section-title">PRIVACY & SOCIAL</div>
    <div class="ss-section">
      <div class="sr" onclick="SS.toggle('visible')">
        <div class="sr-icon"><img loading="lazy" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779563281/246883f0-56d8-11f1-8fad-095787cce754_m4vnqu.png" style="width:24px;height:24px;object-fit:contain;display:block;" alt=""></div>
        <div class="sr-body"><div class="sr-label">Appear in Discover</div><div class="sr-sub">Others can find your profile</div></div>
        <div class="stgl" id="sstgl-visible" style="background:#e8d5a3;"><div class="stgl-knob" style="left:24px;background:#060c18;"></div></div>
      </div>
      <div class="sr" onclick="SS.open('chatperm')">
        <div class="sr-icon"><img loading="lazy" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779657309/7153c4b0-57ad-11f1-ae7e-3f26811e4481_rn0wwi.png" style="width:24px;height:24px;object-fit:contain;display:block;" alt=""></div>
        <div class="sr-body"><div class="sr-label">Chat Permissions</div><div class="sr-sub">Who can message you</div></div>
        <span class="sr-val" id="ss-chatperm-val">Everyone</span>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
      <div class="sr" onclick="SS.open('privacy')">
        <div class="sr-icon"><img loading="lazy" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/e_background_removal/v1779657311/25bb3d70-57ae-11f1-ae7e-3f26811e4481_fhfzwy.png" style="width:24px;height:24px;object-fit:contain;display:block;" alt=""></div>
        <div class="sr-body"><div class="sr-label">Privacy Settings</div><div class="sr-sub">Profile visibility &amp; data</div></div>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
      <div class="sr last" onclick="SS.downloadData()">
        <div class="sr-icon"><img loading="lazy" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779657311/6f8d5c90-57ad-11f1-ae7e-3f26811e4481_y6etkn.png" style="width:24px;height:24px;object-fit:contain;display:block;" alt=""></div>
        <div class="sr-body"><div class="sr-label">Download My Data</div><div class="sr-sub">Export everything as JSON</div></div>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
    </div>

    <!-- ── ABOUT ── -->
    <div class="ss-section-title">ABOUT</div>
    <div class="ss-section">
      <div class="sr" onclick="SS.open('about')">
        <div class="sr-icon"><img loading="lazy" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779657309/fdd80ef0-57ad-11f1-ae7e-3f26811e4481_lfscbr.png" style="width:24px;height:24px;object-fit:contain;display:block;" alt=""></div>
        <div class="sr-body"><div class="sr-label">About NowssB</div><div class="sr-sub">Version 1.0.0 · nowssb.com</div></div>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
      <div class="sr last" onclick="SS.open('terms')">
        <div class="sr-icon"><img loading="lazy" decoding="async" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779563283/260480b0-56d8-11f1-8fad-095787cce754_rz6zbi.png" style="width:24px;height:24px;object-fit:contain;display:block;" alt=""></div>
        <div class="sr-body"><div class="sr-label">Terms &amp; Privacy Policy</div></div>
        <svg class="sr-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 18l6-6-6-6"/></svg>
      </div>
    </div>

    <!-- ── SIGN OUT ── -->
    <div style="padding:0 16px 40px;">
      <button onclick="ssSignOut()" style="width:100%;padding:15px;border-radius:14px;border:1.5px solid rgba(255,80,80,.25);background:rgba(255,80,80,.06);color:rgba(255,100,100,.9);font-size:15px;font-weight:700;font-family:'DM Sans',sans-serif;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:10px;">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
        Sign Out
      </button>
    </div>`;
  });
})();
