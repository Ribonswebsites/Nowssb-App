/* ══════════════════════════════════════════════════════════
   CONTENT, PART TWO — the word library, the eBooks, and your inbox.

   app/js/part069.js made two things editable from the studio: the Word
   Atelier's shelves (content/words) and the Meaning Store's catalogue
   (content/meanings). Both are thin by design — a shelf entry is a name
   and a root, a meaning is a name, a price and a picture.

   Everything the app actually TEACHES lives somewhere else: the twelve
   words in MASTER_WORD_LIBRARY (part004.js), each with an organ, a healing
   benefit, a meaning, a mouth position, a resonance point, a common
   mistake, a tip and its syllables — and the eBooks in EB_BOOKS
   (part017.js). Those were written into JavaScript, so no studio edit
   could ever reach them. This file makes both content, on the same terms
   as part069: shipped list first so nothing is ever empty, last seen copy
   second so a publish survives being offline, Firestore third and live.

   The word record grew, and why
   -----------------------------
   A NowssB word is not an English word. It is a sound, and the sound is
   written in Devanagari, which has letters English does not have —
   there is no roman spelling of ऋ or ङ that a reader can simply read out.
   So a word is carried in four parts at once, and the app shows all four:

     deva      आरोग्य        the real word, as it is actually written
     word      AAROGYA       a roman spelling to hold on to
     parts[]   आ · रो · ग्य   the pronunciation boxes, three to five of them
     audio     a recording    the only thing that settles an argument

   Each box carries its own roman spelling, its own Devanagari, how long to
   hold it, one plain sentence saying how to make the sound, and optionally
   its own recording. That is what a reader who has never seen Devanagari
   needs: something to look at, something to read, something to hear.

   `syllables` is kept filled from `parts` so every screen that already
   drew syllables keeps working without knowing any of this happened.

   Your inbox
   ----------
   The last piece: the studio answering one person. You ask for a meaning;
   it gets made; you are told. A push says it now, and users/<uid>/inbox
   says it whenever you next open the app — so the message is not lost
   because a phone was off. Read once, raised once, marked.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var K_LIB   = 'nwsb_content_library';
  var K_BOOKS = 'nwsb_content_books';
  var K_SEEN  = 'nwsb_inbox_seen';

  function ls(k) { try { return localStorage.getItem(k); } catch (e) { return null; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  /* ── Normalising a word ────────────────────────────────────────────
     One place decides what a complete record looks like, so the studio,
     the player and every screen in between agree. Anything missing gets a
     safe empty value rather than undefined — a half-filled word should
     render as a word with blanks, never throw. */
  function normWord(w) {
    if (!w || typeof w.word !== 'string' || !w.word.trim()) return null;

    var parts = Array.isArray(w.parts) ? w.parts.filter(Boolean).slice(0, 5).map(function (p) {
      if (typeof p === 'string') p = { roman: p };
      return {
        roman: String(p.roman || '').trim(),
        deva:  String(p.deva  || '').trim(),
        hold:  Number(p.hold) > 0 ? Number(p.hold) : 1.5,
        say:   String(p.say   || '').trim(),
        audio: String(p.audio || '').trim()
      };
    }).filter(function (p) { return p.roman || p.deva; }) : [];

    /* Older records carry `syllables` and no `parts`; build the boxes from
       them rather than showing nothing. */
    if (!parts.length && Array.isArray(w.syllables)) {
      parts = w.syllables.slice(0, 5).map(function (s) {
        return { roman: String(s), deva: '', hold: 1.5, say: '', audio: '' };
      });
    }

    return {
      key: String(w.key || w.word).trim().toLowerCase().replace(/\s+/g, '-'),
      word: String(w.word).trim(),
      deva: String(w.deva || '').trim(),
      translit: String(w.translit || '').trim(),
      phonetic: String(w.phonetic || parts.map(function (p) { return p.roman; }).join(' · ')).trim(),
      parts: parts,
      /* Kept in step with parts so nothing that already drew syllables has
         to learn about any of this. */
      syllables: parts.map(function (p) { return p.roman || p.deva; }),
      audioMale: String(w.audioMale || '').trim(),
      audioFemale: String(w.audioFemale || '').trim(),
      organ: String(w.organ || '').trim(),
      origin: String(w.origin || 'Natural Origin').trim(),
      benefit: String(w.benefit || '').trim(),
      meaning: String(w.meaning || '').trim(),
      mouthPos: String(w.mouthPos || '').trim(),
      resonance: String(w.resonance || '').trim(),
      mistake: String(w.mistake || '').trim(),
      tip: String(w.tip || '').trim(),
      categories: Array.isArray(w.categories) ? w.categories.map(String) : [],
      gender: ['M', 'F', 'both'].indexOf(w.gender) >= 0 ? w.gender : 'both',
      time: ['morning', 'evening', 'night', 'any'].indexOf(w.time) >= 0 ? w.time : 'any',
      price: Number(w.price) || 0,
      img: String(w.img || '').trim()
    };
  }
  window.nwsbNormWord = normWord;

  /* ── Applying ──────────────────────────────────────────────────────
     Mutated in place, never replaced: MASTER_WORD_LIBRARY is a top-level
     const that half a dozen files hold a reference to, and PRACTICE_WORDS
     was spread from it at load. Handing anybody a new array would leave
     them drawing the old library forever. Same reason as part069.js. */
  function applyLibrary(list) {
    if (!Array.isArray(list) || !list.length) return false;
    var clean = list.map(normWord).filter(Boolean);
    if (!clean.length) return false;

    var live = window.MASTER_WORD_LIBRARY;
    if (!Array.isArray(live)) return false;
    live.length = 0;
    for (var i = 0; i < clean.length; i++) live.push(clean[i]);

    /* The player may be showing a word from the old list. Redrawing is the
       job of whoever owns the screen; say it happened and let them. */
    try { window.dispatchEvent(new CustomEvent('nwsb-library', { detail: { count: clean.length } })); } catch (e) {}
    return true;
  }

  function applyBooks(list) {
    if (!Array.isArray(list) || !list.length) return false;
    var clean = list.filter(function (b) {
      return b && typeof b.key === 'string' && typeof b.title === 'string' && b.key && b.title;
    });
    if (!clean.length) return false;
    var live = window.EB_BOOKS;
    if (!Array.isArray(live)) return false;
    live.length = 0;
    for (var i = 0; i < clean.length; i++) live.push(clean[i]);
    try { window.dispatchEvent(new CustomEvent('nwsb-books', { detail: { count: clean.length } })); } catch (e) {}
    return true;
  }

  /* ── What the studio publishes first ───────────────────────────────
     Built from exactly what ships, so the first publish cannot drift from
     the app. Same contract as nwsbContentDefaults in part069.js. */
  window.nwsbLibraryDefaults = function () {
    return {
      library: (window.MASTER_WORD_LIBRARY || []).map(normWord).filter(Boolean),
      books: window.EB_BOOKS || null
    };
  };

  /* ── 2. The last copy seen ─────────────────────────────────────────── */
  function applyCache() {
    var l = ls(K_LIB), b = ls(K_BOOKS);
    if (l) { try { applyLibrary(JSON.parse(l)); } catch (e) {} }
    if (b) { try { applyBooks(JSON.parse(b)); } catch (e) {} }
  }

  /* ── 3. Firestore, watched ─────────────────────────────────────────── */
  function watch(fs) {
    var db = window._db;

    fs.onSnapshot(fs.doc(db, 'content', 'library'), function (snap) {
      if (!snap.exists()) return;
      var items = (snap.data() || {}).items;
      if (applyLibrary(items)) lsSet(K_LIB, JSON.stringify(items));
    }, function () { /* offline or refused — the cache stands */ });

    fs.onSnapshot(fs.doc(db, 'content', 'books'), function (snap) {
      if (!snap.exists()) return;
      var items = (snap.data() || {}).items;
      if (applyBooks(items)) lsSet(K_BOOKS, JSON.stringify(items));
    }, function () {});
  }

  /* ── The inbox ─────────────────────────────────────────────────────
     Watched only while signed in, and only ever your own. Each message is
     raised once — nwsbNotify puts it in the app's own feed and part068.js
     carries it to the phone from there, so this needs to know nothing
     about either. `seen` is kept locally as well as on the document
     because a message read on one phone should not shout on the other. */
  function seen() {
    try { var a = JSON.parse(ls(K_SEEN) || '[]'); return Array.isArray(a) ? a : []; }
    catch (e) { return []; }
  }
  function markSeen(id) {
    var a = seen();
    if (a.indexOf(id) >= 0) return;
    a.push(id);
    lsSet(K_SEEN, JSON.stringify(a.slice(-200)));
  }

  var inboxUnsub = null;
  function watchInbox(fs) {
    var uid = window._currentUid;
    if (!uid || inboxUnsub) return;
    var db = window._db;
    inboxUnsub = fs.onSnapshot(
      fs.collection(db, 'users', uid, 'inbox'),
      function (snap) {
        var already = seen();
        snap.forEach(function (d) {
          var m = d.data() || {};
          if (m.read || already.indexOf(d.id) >= 0) return;
          markSeen(d.id);
          if (window.nwsbNotify) {
            try {
              window.nwsbNotify({
                type: m.type || 'support',
                title: m.title || 'NowssB',
                body: m.body || ''
              });
            } catch (e) {}
          }
          /* Marked on the server too, so a second device stays quiet. */
          try { fs.setDoc(fs.doc(db, 'users', uid, 'inbox', d.id), { read: true }, { merge: true }); } catch (e) {}
        });
      },
      function () { /* signed out or offline — nothing to do */ }
    );
  }

  /* ── Boot ──────────────────────────────────────────────────────────── */
  function start() {
    applyCache();

    var tries = 0;
    var t = setInterval(function () {
      if (window._db) {
        clearInterval(t);
        import('https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js')
          .then(function (fs) {
            watch(fs);
            /* Sign-in lands after this; wait for a uid rather than racing it. */
            if (window._currentUid) watchInbox(fs);
            else {
              var n = 0;
              var u = setInterval(function () {
                if (window._currentUid) { clearInterval(u); watchInbox(fs); }
                else if (++n > 240) clearInterval(u);
              }, 1000);
            }
          })
          .catch(function () {});
      } else if (++tries > 60) clearInterval(t);
    }, 250);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();

})();
