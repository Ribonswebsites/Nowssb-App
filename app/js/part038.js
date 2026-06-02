
window.chatInboxOpen = function() {
  var overlay = document.getElementById('chatInboxOverlay');
  if (!overlay) return;
  var bn = document.getElementById('ig-bottomnav');
  var sn = document.getElementById('ig-social-nav');
  overlay._prevBn = bn ? bn.style.display : null;
  overlay._prevSn = sn ? sn.style.display : null;
  if (bn) bn.style.display = 'none';
  if (sn) sn.style.display = 'none';
  overlay.style.display = 'flex';
  chatInboxRender();
};
window.chatInboxClose = function() {
  var overlay = document.getElementById('chatInboxOverlay');
  if (!overlay) return;
  var bn = document.getElementById('ig-bottomnav');
  var sn = document.getElementById('ig-social-nav');
  if (bn && overlay._prevBn !== null) bn.style.display = overlay._prevBn || '';
  if (sn && overlay._prevSn !== null) sn.style.display = overlay._prevSn || '';
  overlay.style.display = 'none';
  // Highlight chat button in social nav (setSocialNavActive is private to IG IIFE)
  ['home','feed','profile','chat'].forEach(function(k){
    var el = document.getElementById('igsn-'+k);
    if (el) el.classList.toggle('active', k === 'chat');
  });
};
window.chatInboxNew = function() {
  chatInboxClose();
  document.getElementById('sub-ig-profile').classList.remove('open');
  document.getElementById('sub-people').classList.add('open');
  if (typeof renderExplore === 'function') renderExplore();
  var sn = document.getElementById('ig-social-nav');
  if (sn) sn.style.display = 'flex';
  setSocialNavActive('chat');
};
window.chatInboxRender = function() {
  var list = document.getElementById('chatInboxList');
  if (!list) return;
  var KEY = 'nowssb_chat_v1';
  var PEOPLE = (window.IG && window.IG._allPeople) ? window.IG._allPeople : [
    {id:1,username:'kavya.frequency',fullName:'Kavya Singh',avatar:'https://i.pravatar.cc/150?img=5'},
    {id:2,username:'aryan.sound',fullName:'Aryan Mehta',avatar:'https://i.pravatar.cc/150?img=13'},
    {id:3,username:'priya.heals',fullName:'Priya Nair',avatar:'https://i.pravatar.cc/150?img=20'},
    {id:4,username:'rohan.resonance',fullName:'Rohan Desai',avatar:'https://i.pravatar.cc/150?img=33'},
    {id:5,username:'aisha.vibration',fullName:'Aisha Patel',avatar:'https://i.pravatar.cc/150?img=45'},
    {id:6,username:'dev.tones',fullName:'Dev Sharma',avatar:'https://i.pravatar.cc/150?img=51'},
    {id:7,username:'meera.om',fullName:'Meera Iyer',avatar:'https://i.pravatar.cc/150?img=47'},
    {id:8,username:'kabir.naad',fullName:'Kabir Khan',avatar:'https://i.pravatar.cc/150?img=60'}
  ];
  var me = window._currentUid || 'me';

  // Placeholder preview lines for people with no messages yet
  var PLACEHOLDERS = [
    'Tap to start a conversation',
    'Say hi 👋',
    'Share your practice today',
    'Send a healing frequency 🙏',
    'Start your first message'
  ];

  // Build a row for every person — real conversations first, then suggested chats
  var rows = PEOPLE.map(function(p, idx) {
    var them = p.id || p.username || 'them';
    var roomId = [me, them].sort().join('_');
    var msgs = [];
    try { msgs = JSON.parse(localStorage.getItem(KEY + '_' + roomId) || '[]'); } catch(e) {}
    var hasMsgs = msgs.length > 0;
    var last = hasMsgs ? msgs[msgs.length-1] : null;
    return { person: p, hasMsgs: hasMsgs, last: last, placeholder: PLACEHOLDERS[idx % PLACEHOLDERS.length] };
  });

  // Sort: people with real messages on top (newest first), then the rest in order
  rows.sort(function(a,b){
    if (a.hasMsgs && !b.hasMsgs) return -1;
    if (!a.hasMsgs && b.hasMsgs) return 1;
    if (a.hasMsgs && b.hasMsgs) return (b.last.ts||0)-(a.last.ts||0);
    return 0;
  });

  if (!rows.length) {
    list.innerHTML = '<div style="padding:48px 24px;text-align:center;">' +
      '<div style="font-size:44px;margin-bottom:16px;">💬</div>' +
      '<div style="font-size:16px;font-weight:700;color:#fff;font-family:\'DM Sans\',sans-serif;margin-bottom:8px;">No people yet</div>' +
      '<div style="font-size:13px;color:rgba(255,255,255,.4);font-family:\'DM Sans\',sans-serif;margin-bottom:24px;">Find practitioners and start healing conversations</div>' +
      '<button onclick="chatInboxNew()" style="padding:12px 28px;border-radius:24px;border:none;background:#e8d5a3;color:#060c18;font-size:14px;font-weight:700;font-family:\'DM Sans\',sans-serif;cursor:pointer;">Find People</button>' +
      '</div>';
    return;
  }

  list.innerHTML = rows.map(function(c) {
    var p = c.person;
    var subText, subColor, timeStr = '';
    if (c.hasMsgs) {
      var lastText = c.last.text || '';
      if (lastText.length > 42) lastText = lastText.slice(0,42) + '…';
      var isMe = c.last.from === me;
      subText = (isMe?'You: ':'') + lastText;
      subColor = 'rgba(255,255,255,.45)';
      if (c.last.ts) {
        var d = new Date(c.last.ts);
        timeStr = (d.getHours()<10?'0':'')+d.getHours()+':'+(d.getMinutes()<10?'0':'')+d.getMinutes();
      }
    } else {
      subText = c.placeholder;
      subColor = 'rgba(255,255,255,.3)';
    }
    return '<div onclick="chatInboxOpenConvo(\''+String(p.id||p.username)+'\')" style="display:flex;align-items:center;gap:14px;padding:14px 18px;border-bottom:1px solid rgba(255,255,255,.05);cursor:pointer;-webkit-tap-highlight-color:transparent;">' +
      '<img src="'+p.avatar+'" style="width:48px;height:48px;border-radius:50%;object-fit:cover;flex-shrink:0;" alt="">' +
      '<div style="flex:1;min-width:0;">' +
        '<div style="font-size:15px;font-weight:600;color:#fff;font-family:\'DM Sans\',sans-serif;overflow:hidden;white-space:nowrap;text-overflow:ellipsis;">'+(p.fullName||p.username)+'</div>' +
        '<div style="font-size:12px;color:'+subColor+';font-family:\'DM Sans\',sans-serif;overflow:hidden;white-space:nowrap;text-overflow:ellipsis;">'+subText+'</div>' +
      '</div>' +
      (timeStr ? '<div style="font-size:10px;color:rgba(255,255,255,.3);font-family:\'DM Sans\',sans-serif;flex-shrink:0;">'+timeStr+'</div>' : '') +
      '</div>';
  }).join('');
};
window.chatInboxOpenConvo = function(key) {
  // Look in IG people first, then fall back to the same placeholder list the inbox renders
  var PEOPLE = (window.IG && window.IG._allPeople && window.IG._allPeople.length) ? window.IG._allPeople : [
    {id:1,username:'kavya.frequency',fullName:'Kavya Singh',avatar:'https://i.pravatar.cc/150?img=5',category:'Practitioner'},
    {id:2,username:'aryan.sound',fullName:'Aryan Mehta',avatar:'https://i.pravatar.cc/150?img=13',category:'Practitioner'},
    {id:3,username:'priya.heals',fullName:'Priya Nair',avatar:'https://i.pravatar.cc/150?img=20',category:'Practitioner'},
    {id:4,username:'rohan.resonance',fullName:'Rohan Desai',avatar:'https://i.pravatar.cc/150?img=33',category:'Practitioner'},
    {id:5,username:'aisha.vibration',fullName:'Aisha Patel',avatar:'https://i.pravatar.cc/150?img=45',category:'Practitioner'},
    {id:6,username:'dev.tones',fullName:'Dev Sharma',avatar:'https://i.pravatar.cc/150?img=51',category:'Practitioner'},
    {id:7,username:'meera.om',fullName:'Meera Iyer',avatar:'https://i.pravatar.cc/150?img=47',category:'Practitioner'},
    {id:8,username:'kabir.naad',fullName:'Kabir Khan',avatar:'https://i.pravatar.cc/150?img=60',category:'Practitioner'}
  ];
  var user = PEOPLE.find ? PEOPLE.find(function(p){ return String(p.id)===String(key) || p.username===key; }) : null;
  if (!user) user = { id:key, fullName:'NowssB Practitioner', username:'practitioner', avatar:'https://i.pravatar.cc/150?img=12', category:'Practitioner' };
  chatInboxClose();
  setTimeout(function(){ if (window.CHAT) CHAT.open(user); }, 60);
};
