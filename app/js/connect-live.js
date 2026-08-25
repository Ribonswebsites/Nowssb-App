/* NowssB Connect — shared Firestore/R2 data layer.
 *
 * This module intentionally contains no demo people and no fake replies. Public
 * social data comes from publicProfiles/posts in Firestore. Media is uploaded
 * through the authenticated Cloudflare Worker into R2. Existing CHAT and RTC
 * modules remain responsible for message rendering and WebRTC media exchange.
 */
import {
  collection, query, limit, orderBy, getDocs, addDoc, setDoc, deleteDoc,
  doc, serverTimestamp, onSnapshot
} from 'https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js';
import { getAuth } from 'https://www.gstatic.com/firebasejs/11.8.1/firebase-auth.js';

const API_BASE = 'https://nowssb-api.ribonpatil2.workers.dev';
const auth = getAuth();
const MAX_CAPTION = 2200;
let feedUnsub = null;
let profiles = [];
let posts = [];
let profileMap = new Map();

const esc = (value) => String(value ?? '').replace(/[&<>"']/g, (c) => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
}[c]));

function safeUrl(value) {
  const url = String(value || '');
  return /^(https?:\/\/|data:image\/)/i.test(url) ? url : '';
}

function currentUid() { return auth.currentUser?.uid || window._currentUid || ''; }
function db() { return window._db; }
function requireLogin() {
  if (!currentUid()) {
    if (typeof window.goTo === 'function') window.goTo('login');
    throw new Error('Sign in to use Connect.');
  }
}
function profileFromDoc(snapshot) {
  const d = snapshot.data() || {};
  const name = d.displayName || 'NowssB Practitioner';
  return {
    id: snapshot.id,
    uid: d.uid || snapshot.id,
    username: d.username || name.toLowerCase().replace(/[^a-z0-9]+/g, '.').replace(/^\.|\.$/g, ''),
    fullName: name,
    avatar: safeUrl(d.photoURL),
    bannerURL: safeUrl(d.bannerURL),
    bio: d.bio || '',
    category: d.category || 'Practitioner',
    link: d.link || '',
    followers: Number(d.followersCount || 0),
    following: Number(d.followingCount || 0),
    posts: Number(d.postsCount || 0),
    verified: !!(d.isPro || d.verifyTier),
    verifyTier: d.verifyTier || '',
    following_state: false,
    mock: false,
    self: snapshot.id === currentUid(),
  };
}
function postFromDoc(snapshot) {
  const d = snapshot.data() || {};
  return {
    id: snapshot.id,
    uid: d.uid || '',
    displayName: d.displayName || 'NowssB Practitioner',
    photoURL: safeUrl(d.photoURL),
    mediaUrl: safeUrl(d.mediaUrl || d.img || d.image),
    mediaType: d.mediaType || 'image',
    caption: d.caption || '',
    location: d.location || '',
    visibility: d.visibility || 'public',
    likeCount: Number(d.likeCount || 0),
    commentCount: Number(d.commentCount || 0),
    createdAt: d.createdAt?.toMillis ? d.createdAt.toMillis() : Number(d.createdAt || 0),
  };
}

async function syncPublicProfile() {
  if (!db() || !auth.currentUser) return;
  const user = auth.currentUser;
  const existing = window._userDataCache || {};
  const name = existing.displayName || user.displayName || 'NowssB Practitioner';
  const username = existing.username || name.toLowerCase().replace(/[^a-z0-9]+/g, '.').replace(/^\.|\.$/g, '') || 'practitioner';
  await setDoc(doc(db(), 'publicProfiles', user.uid), {
    uid: user.uid,
    displayName: name,
    username,
    photoURL: existing.photoURL || user.photoURL || '',
    bio: existing.bio || '',
    category: existing.healthFocus || 'Practitioner',
    profileVisibility: existing.profileVisibility || 'public',
    updatedAt: serverTimestamp(),
  }, { merge: true });
}

async function loadProfiles() {
  requireLogin();
  const snap = await getDocs(query(collection(db(), 'publicProfiles'), limit(100)));
  profiles = snap.docs.map(profileFromDoc).filter((p) => p.uid && p.fullName);
  profileMap = new Map(profiles.map((p) => [p.uid, p]));
  if (window.IG) {
    window.IG._allPeople = profiles;
    window.IG._connectProfiles = profiles;
  }
  return profiles;
}

async function loadPosts() {
  requireLogin();
  const snap = await getDocs(query(collection(db(), 'posts'), orderBy('createdAt', 'desc'), limit(80)));
  posts = snap.docs.map(postFromDoc).filter((p) => p.mediaUrl && p.visibility === 'public');
  return posts;
}

function profileFor(uid, fallback) {
  return profileMap.get(uid) || fallback || {
    uid, id: uid, fullName: 'NowssB Practitioner', username: 'practitioner', avatar: '', category: 'Practitioner'
  };
}

function formatTime(ts) {
  if (!ts) return '';
  const d = new Date(ts);
  const diff = Math.max(0, Date.now() - d.getTime());
  if (diff < 60000) return 'just now';
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m`;
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h`;
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

function feedCard(p) {
  const author = profileFor(p.uid, { fullName: p.displayName, avatar: p.photoURL, username: p.displayName });
  const media = p.mediaType.startsWith('video')
    ? `<video class="nwsb-live-post-media" src="${esc(p.mediaUrl)}" controls playsinline preload="metadata"></video>`
    : `<img class="nwsb-live-post-media" src="${esc(p.mediaUrl)}" alt="${esc(p.caption || 'NowssB post')}" loading="lazy">`;
  return `<article class="nwsb-live-post" data-post-id="${esc(p.id)}">
    <button class="nwsb-live-author" onclick="NWSBConnect.openProfile('${esc(p.uid)}')">
      ${author.avatar ? `<img src="${esc(author.avatar)}" alt="">` : `<span class="nwsb-live-avatar-fallback">${esc((author.fullName || 'N').charAt(0).toUpperCase())}</span>`}
      <span><b>${esc(author.fullName || p.displayName)}</b><small>@${esc(author.username || 'practitioner')}</small></span>
    </button>
    ${media}
    <div class="nwsb-live-post-actions">
      <button onclick="NWSBConnect.likePost('${esc(p.id)}')" aria-label="Like">♡</button>
      <button onclick="NWSBConnect.focusComment('${esc(p.id)}')" aria-label="Comment">◌</button>
      <button onclick="NWSBConnect.sharePost('${esc(p.id)}')" aria-label="Share">↗</button>
      <span></span><time>${esc(formatTime(p.createdAt))}</time>
    </div>
    <div class="nwsb-live-likes">${p.likeCount} likes</div>
    ${p.caption ? `<p class="nwsb-live-caption"><b>${esc(author.username || author.fullName)}</b> ${esc(p.caption)}</p>` : ''}
    ${p.location ? `<div class="nwsb-live-location">${esc(p.location)}</div>` : ''}
    <div class="nwsb-live-comment-row"><input id="nwsb-comment-${esc(p.id)}" maxlength="500" placeholder="Add a comment…" onkeydown="if(event.key==='Enter')NWSBConnect.commentPost('${esc(p.id)}',this.value)"><button onclick="NWSBConnect.commentPost('${esc(p.id)}',document.getElementById('nwsb-comment-${esc(p.id)}').value)">Post</button></div>
  </article>`;
}

function renderFeed() {
  const screen = document.getElementById('sub-ig-feed');
  if (!screen) return;
  const me = profileMap.get(currentUid());
  const avatar = me?.avatar || safeUrl(auth.currentUser?.photoURL);
  const avatarHtml = avatar ? `<img src="${esc(avatar)}" alt="">` : `<span>${esc((me?.fullName || 'N').charAt(0).toUpperCase())}</span>`;
  screen.innerHTML = `<div class="nwsb-live-feed-shell">
    <header class="nwsb-live-feed-header"><button onclick="IG.nav('home')" aria-label="Back">‹</button><div class="nwsb-live-brand"><img src="assets/media/image/logo-disc-8b052034.webp" alt="NowssB"><strong>NowssB Connect</strong></div><button onclick="NWSBConnect.openComposer()" aria-label="Create">＋</button></header>
    <div class="nwsb-live-feed-tools"><button onclick="IG.openExplore()">Find practitioners</button><button onclick="chatInboxOpen()">Messages</button><button onclick="NWSBConnect.openProfile('${esc(currentUid())}')">${avatarHtml} My profile</button></div>
    <main class="nwsb-live-feed-list">${posts.length ? posts.map(feedCard).join('') : `<div class="nwsb-live-empty"><img src="assets/media/image/logo-disc-8b052034.webp" alt="NowssB"><h2>Your Connect feed starts here</h2><p>Share the first public practice post or find another practitioner to follow.</p><button onclick="NWSBConnect.openComposer()">Create a post</button></div>`}</main>
  </div>`;
}

function renderPeople(term = '') {
  const box = document.getElementById('ig-search-results');
  const grid = document.getElementById('ig-explore-grid');
  const empty = document.getElementById('ig-explore-empty');
  if (!box) return;
  const needle = String(term || '').trim().toLowerCase();
  const found = profiles.filter((p) => !needle || `${p.fullName} ${p.username} ${p.category}`.toLowerCase().includes(needle));
  if (grid) { grid.style.display = 'none'; grid.innerHTML = ''; }
  if (empty) empty.style.display = 'none';
  box.style.display = 'block';
  box.innerHTML = found.length ? found.map((p) => `<button class="nwsb-live-person" onclick="NWSBConnect.openProfile('${esc(p.uid)}')">
    ${p.avatar ? `<img src="${esc(p.avatar)}" alt="">` : `<span>${esc(p.fullName.charAt(0).toUpperCase())}</span>`}
    <span><b>${esc(p.fullName)}</b><small>@${esc(p.username)} · ${esc(p.category)}</small></span><em>${p.following_state ? 'Following' : 'View'}</em>
  </button>`).join('') : '<div class="nwsb-live-empty-small">No public practitioners match that search.</div>';
}

async function openPeople() {
  requireLogin();
  const screen = document.getElementById('sub-people');
  if (!screen) return;
  screen.classList.add('open');
  const input = document.getElementById('ig-search-input');
  if (input) input.placeholder = 'Search NowssB practitioners';
  try { await loadProfiles(); renderPeople(input?.value || ''); }
  catch (error) { if (boxFor('ig-search-results')) boxFor('ig-search-results').innerHTML = `<div class="nwsb-live-error">${esc(error.message)}</div>`; }
}
function boxFor(id) { return document.getElementById(id); }

async function openProfile(uid) {
  requireLogin();
  if (!profiles.length) await loadProfiles();
  const p = profileFor(uid);
  const publicPosts = posts.filter((post) => post.uid === uid);
  const isSelf = uid === currentUid();
  const overlay = document.getElementById('nwsb-live-profile') || document.createElement('div');
  overlay.id = 'nwsb-live-profile';
  overlay.className = 'nwsb-live-profile-overlay';
  const avatar = p.avatar ? `<img src="${esc(p.avatar)}" alt="">` : `<span>${esc((p.fullName || 'N').charAt(0).toUpperCase())}</span>`;
  overlay.innerHTML = `<div class="nwsb-live-profile-card"><button class="nwsb-live-profile-close" onclick="NWSBConnect.closeProfile()">×</button><div class="nwsb-live-profile-head">${avatar}<div><h2>${esc(p.fullName)}</h2><p>@${esc(p.username)}</p><small>${esc(p.category)}</small></div></div><p class="nwsb-live-bio">${esc(p.bio || 'A NowssB practitioner building a daily sound practice.')}</p><div class="nwsb-live-profile-actions">${isSelf ? `<button onclick="NWSBConnect.openComposer()">Create post</button>` : `<button onclick="NWSBConnect.toggleFollow('${esc(uid)}')">${p.following_state ? 'Following' : 'Follow'}</button><button onclick="NWSBConnect.message('${esc(uid)}')">Message</button><button onclick="NWSBConnect.call('${esc(uid)}','audio')">Call</button><button onclick="NWSBConnect.call('${esc(uid)}','video')">Video</button>`}</div><div class="nwsb-live-profile-stats"><span><b>${publicPosts.length}</b> posts</span><span><b>${p.followers || 0}</b> followers</span><span><b>${p.following || 0}</b> following</span></div><div class="nwsb-live-profile-grid">${publicPosts.length ? publicPosts.map((post) => `<button onclick="NWSBConnect.openPost('${esc(post.id)}')"><img src="${esc(post.mediaUrl)}" alt=""></button>`).join('') : '<div class="nwsb-live-empty-small">No public posts yet.</div>'}</div></div>`;
  if (!overlay.parentNode) document.body.appendChild(overlay);
  overlay.style.display = 'flex';
}

function closeProfile() {
  const overlay = document.getElementById('nwsb-live-profile');
  if (overlay) overlay.style.display = 'none';
}

async function toggleFollow(uid) {
  requireLogin();
  if (uid === currentUid()) return;
  const ref = doc(db(), 'follows', currentUid(), 'following', uid);
  const reverse = doc(db(), 'follows', uid, 'followers', currentUid());
  const p = profileMap.get(uid);
  const nowFollowing = !p?.following_state;
  if (nowFollowing) {
    await Promise.all([
      setDoc(ref, { uid, createdAt: serverTimestamp() }),
      setDoc(reverse, { uid: currentUid(), createdAt: serverTimestamp() }),
    ]);
  } else {
    await Promise.all([deleteDoc(ref), deleteDoc(reverse)]);
  }
  if (p) p.following_state = nowFollowing;
  await openProfile(uid);
}

async function ensureChat(peer) {
  requireLogin();
  const peerUid = peer.uid || peer.id;
  const participants = [currentUid(), peerUid].sort();
  const chatId = participants.join('_');
  await setDoc(doc(db(), 'chats', chatId), { participants, updatedAt: serverTimestamp() }, { merge: true });
  return chatId;
}

async function message(uid) {
  requireLogin();
  const p = profileMap.get(uid) || { uid, id: uid, fullName: 'NowssB Practitioner', username: 'practitioner', avatar: '' };
  await ensureChat(p);
  if (window.CHAT) window.CHAT.open(p);
}

async function call(uid, kind) {
  requireLogin();
  const p = profileMap.get(uid);
  if (!p) return;
  await ensureChat(p);
  if (window.RTC) window.RTC.startCall(p, kind);
}

async function likePost(postId) {
  requireLogin();
  const post = posts.find((p) => p.id === postId);
  if (!post) return;
  const likeRef = doc(db(), 'posts', postId, 'likes', currentUid());
  await setDoc(likeRef, { uid: currentUid(), createdAt: serverTimestamp() });
  await setDoc(doc(db(), 'posts', postId), { likeCount: (post.likeCount || 0) + 1 }, { merge: true });
  await refreshFeed();
}

async function commentPost(postId, text) {
  requireLogin();
  const value = String(text || '').trim().slice(0, 500);
  if (!value) return;
  await addDoc(collection(db(), 'posts', postId, 'comments'), { uid: currentUid(), text: value, createdAt: serverTimestamp() });
  const post = posts.find((p) => p.id === postId);
  await setDoc(doc(db(), 'posts', postId), { commentCount: (post?.commentCount || 0) + 1 }, { merge: true });
  await refreshFeed();
}

function focusComment(postId) {
  document.getElementById(`nwsb-comment-${postId}`)?.focus();
}

async function sharePost(postId) {
  const url = `${location.origin}/?connect-post=${encodeURIComponent(postId)}`;
  if (navigator.share) await navigator.share({ title: 'NowssB Connect', text: 'A practice shared on NowssB', url }).catch(() => {});
  else if (navigator.clipboard) await navigator.clipboard.writeText(url);
}

async function uploadMedia(file, kind) {
  const user = auth.currentUser;
  if (!user) throw new Error('Sign in to upload media.');
  const token = await user.getIdToken();
  const form = new FormData(); form.append('file', file); form.append('kind', kind);
  const response = await fetch(`${API_BASE}/api/connect/media`, { method: 'POST', headers: { Authorization: `Bearer ${token}` }, body: form });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error || 'Could not upload this media.');
  return data;
}

function openComposer() {
  requireLogin();
  let overlay = document.getElementById('nwsb-live-composer');
  if (overlay) { overlay.style.display = 'flex'; return; }
  overlay = document.createElement('div'); overlay.id = 'nwsb-live-composer'; overlay.className = 'nwsb-live-composer-overlay';
  overlay.innerHTML = `<form class="nwsb-live-composer-card"><button type="button" class="nwsb-live-profile-close" data-close>×</button><h2>New NowssB post</h2><input name="media" type="file" accept="image/jpeg,image/png,image/webp,image/gif,video/mp4,video/webm" required><textarea name="caption" maxlength="${MAX_CAPTION}" placeholder="Share your practice…"></textarea><input name="location" maxlength="120" placeholder="Add location (optional)"><button class="nwsb-live-submit" type="submit">Share to Connect</button><p class="nwsb-live-form-note">Images and videos up to 8 MB. Your post will be visible to signed-in Connect members.</p></form>`;
  document.body.appendChild(overlay); overlay.style.display = 'flex';
  overlay.querySelector('[data-close]').onclick = () => { overlay.style.display = 'none'; };
  overlay.querySelector('form').onsubmit = async (event) => {
    event.preventDefault();
    const form = event.currentTarget; const file = form.media.files[0]; const button = form.querySelector('button[type=submit]');
    if (!file) return;
    button.disabled = true; button.textContent = 'Uploading…';
    try {
      const uploaded = await uploadMedia(file, 'post');
      const user = auth.currentUser; const u = window._userDataCache || {};
      await addDoc(collection(db(), 'posts'), { uid: currentUid(), displayName: u.displayName || user.displayName || 'NowssB Practitioner', photoURL: u.photoURL || user.photoURL || '', mediaUrl: uploaded.url, mediaType: file.type, caption: form.caption.value.trim(), location: form.location.value.trim(), visibility: 'public', likeCount: 0, commentCount: 0, createdAt: serverTimestamp() });
      form.reset(); overlay.style.display = 'none'; await refreshFeed();
    } catch (error) { button.disabled = false; button.textContent = 'Share to Connect'; alert(error.message); }
  };
}

async function refreshFeed() {
  await loadProfiles();
  await loadPosts();
  renderFeed();
}

function patchLegacyUI() {
  if (!window.IG || window.IG._nwsbLivePatched) return;
  window.IG._nwsbLivePatched = true;
  window.IG.openFeed = function () { refreshFeed().catch((e) => console.warn('Connect feed:', e)); };
  window.IG.openExplore = function () { openPeople().catch((e) => console.warn('Connect people:', e)); };
  window.IG.search = function (value) { renderPeople(value); };
  window.IG.message = function (id) { message(String(id)).catch((e) => alert(e.message)); };
  window.IG.openProfile = function (id) { openProfile(typeof id === 'object' ? (id.uid || id.id) : String(id)).catch((e) => alert(e.message)); };
  window.IG.closeProfile = closeProfile;
  window.IG.toggleFollow = function (id) { toggleFollow(String(id)).catch((e) => alert(e.message)); };
  window.IG.toggleFollowMini = function (id) { toggleFollow(String(id)).catch((e) => alert(e.message)); };
  window.IG.shareProfile = function () { sharePost('profile'); };
  window.nwsbOpenCreate = openComposer;
  const fab = document.getElementById('nwsbCreateFab'); if (fab) fab.onclick = openComposer;
  if (window.CHAT && !window.CHAT._nwsbLiveChatPatched) {
    const originalOpen = window.CHAT.open.bind(window.CHAT);
    window.CHAT.open = function (peer) { ensureChat(peer).catch((e) => console.warn('Connect chat room:', e)); return originalOpen(peer); };
    window.CHAT._nwsbLiveChatPatched = true;
  }
}

window.NWSBConnect = { refreshFeed, loadProfiles, loadPosts, openComposer, openProfile, closeProfile, toggleFollow, message, call, likePost, commentPost, focusComment, sharePost, openPost: (id) => { const p = posts.find((x) => x.id === id); if (p) window.open(p.mediaUrl, '_blank', 'noopener'); } };
window.NWSBConnectReady = true;

function boot() {
  patchLegacyUI();
  if (auth.currentUser) syncPublicProfile().catch((e) => console.warn('Connect profile sync:', e));
  auth.onAuthStateChanged((user) => {
    if (!user) return;
    syncPublicProfile().catch((e) => console.warn('Connect profile sync:', e));
    patchLegacyUI();
  });
}

if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
