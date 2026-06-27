
(function(){
  var oldPanel = document.getElementById('ss-panel-profile-edit');
  if(!oldPanel) return;
  oldPanel.innerHTML = `
    <div class="ss-panel-header">
      <button class="ss-panel-back" onclick="nwsbCloseEditProfile()">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
        Back
      </button>
      <div class="ss-panel-title">Edit Profile</div>
      <div class="ss-panel-sub">Your public NowssB identity</div>
    </div>
    <div style="padding:24px 20px;display:flex;flex-direction:column;gap:20px;">

      <!-- Avatar -->
      <div style="display:flex;align-items:center;gap:16px;">
        <div id="profile-edit-avatar-circle" class="nwsb-pe-avatar" onclick="profileEditPhoto()" style="width:88px;height:88px;border-radius:50% !important;background:linear-gradient(135deg,rgba(232,213,163,.12),rgba(200,232,245,.08));display:flex;align-items:center;justify-content:center;flex-shrink:0;cursor:pointer;overflow:hidden;position:relative;background-size:cover;background-position:center;">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="rgba(232,213,163,.6)" stroke-width="1.5"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>
        </div>
        <div>
          <div class="nwsb-pe-label" style="font-size:15px;font-weight:700;color:#fff;font-family:'DM Sans',sans-serif;margin-bottom:6px;">Profile Photo</div>
          <button class="nwsb-pe-btn" onclick="profileEditPhoto()" style="padding:9px 18px;border-radius:12px;border:1px solid rgba(232,213,163,.4);background:transparent;color:#e8d5a3;font-size:13px;font-weight:600;font-family:'DM Sans',sans-serif;cursor:pointer;">Change Photo</button>
        </div>
      </div>

      <!-- Display Name -->
      <div>
        <div class="slbl" style="margin-bottom:10px;">DISPLAY NAME</div>
        <input id="ss-name-edit" class="ss-input" type="text" placeholder="Your name..." maxlength="40">
      </div>

      <!-- Bio -->
      <div>
        <div class="slbl" style="margin-bottom:10px;">BIO</div>
        <textarea id="ss-bio-edit" class="ss-input" rows="4" maxlength="300" placeholder="Tell your healing story..." style="resize:none;height:100px;"></textarea>
        <div style="text-align:right;font-size:11px;color:rgba(255,255,255,.3);font-family:'DM Sans',sans-serif;margin-top:4px;">300 chars max</div>
      </div>

      <!-- Banner -->
      <div>
        <div class="slbl" style="margin-bottom:10px;">PROFILE BANNER</div>
        <div id="profile-edit-banner-preview" class="nwsb-pe-banner" onclick="nwsbBannerChooser()" style="height:120px;background-color:rgba(255,255,255,.06);border-radius:16px;display:flex;flex-direction:column;align-items:center;justify-content:center;cursor:pointer;position:relative;overflow:hidden;gap:10px;background-size:cover;background-position:center;">
          <div class="nwsb-pe-banner-ico" style="width:46px;height:46px;border-radius:50% !important;display:flex;align-items:center;justify-content:center;">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.6"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
          </div>
          <div class="nwsb-pe-banner-txt" style="font-size:12px;font-weight:600;color:#e8d5a3;font-family:'DM Sans',sans-serif;">Tap to upload banner · 1200×400</div>
        </div>
      </div>

      <!-- Profile Theme -->
      <div>
        <div class="slbl" style="margin-bottom:10px;">PROFILE THEME</div>
        <div style="display:flex;gap:12px;">
          <button type="button" id="nwsb-theme-neu" onclick="nwsbSetSocTheme('neu')" style="flex:1;padding:14px 8px;border:none;border-radius:14px;background:#f0f2f7;cursor:pointer;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:700;color:#1a1a2e;box-shadow:4px 4px 10px rgba(0,0,0,.12), -3px -3px 8px rgba(255,255,255,.95);">NowssB</button>
          <button type="button" id="nwsb-theme-glass" onclick="nwsbSetSocTheme('glass')" style="flex:1;padding:14px 8px;border:none;border-radius:14px;background:#f0f2f7;cursor:pointer;font-family:'DM Sans',sans-serif;font-size:13px;font-weight:700;color:#1a1a2e;box-shadow:4px 4px 10px rgba(0,0,0,.12), -3px -3px 8px rgba(255,255,255,.95);">NowssB Fashion</button>
        </div>
        <div style="font-size:11px;color:rgba(0,0,0,.4);margin-top:8px;font-family:'DM Sans',sans-serif;">Neumorphism or frosted glass — applies to your social profile.</div>
      </div>

      <button class="ss-btn-primary nwsb-pe-save" onclick="if(window.SS&&SS.saveBio)SS.saveBio();nwsbCloseEditProfile()">Save Profile</button>
    </div>`;
})();
