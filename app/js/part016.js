
// ── GSAP SCROLL REVEALS ──
// Runs after home screen is active
function initGSAP() {
  if (typeof gsap === 'undefined') return;
  gsap.registerPlugin(ScrollTrigger);

  const homeEl = document.getElementById('home');

  // Hero brand name drops in
  gsap.from('.brand-name', {
    y: -40, opacity: 0, duration: 1.1,
    ease: 'power4.out', delay: 0.2
  });

  // Home cards stagger up on scroll
  // home-card-static cards are excluded — they're always rendered at full opacity/position
  gsap.utils.toArray('.home-card, .home-tile').forEach((el, i) => {
    if (el.classList.contains('home-card-static')) {
      // Force fully visible immediately, no scroll gate
      gsap.set(el, { opacity: 1, y: 0 });
      return;
    }
    gsap.from(el, {
      scrollTrigger: {
        trigger: el,
        scroller: homeEl,
        start: 'top 92%',
        toggleActions: 'play none none none'
      },
      y: 48, opacity: 0, duration: 0.75,
      delay: i * 0.08,
      ease: 'power3.out'
    });
  });

  // Section labels slide in from left
  gsap.utils.toArray('.home-greeting, .home-tagline').forEach(el => {
    gsap.from(el, {
      scrollTrigger: {
        trigger: el,
        scroller: homeEl,
        start: 'top 95%',
        toggleActions: 'play none none none'
      },
      x: -32, opacity: 0, duration: 0.8,
      ease: 'power3.out'
    });
  });
}

// ── HERO PARALLAX on touch/mouse ──
const heroSection = document.querySelector('.hero-section');
let tiltActive = false;

function applyTilt(x, y) {
  const rect = heroSection.getBoundingClientRect();
  const cx = rect.width / 2;
  const cy = rect.height / 2;
  const dx = (x - rect.left - cx) / cx;
  const dy = (y - rect.top  - cy) / cy;
  const rotY =  dx * 6;
  const rotX = -dy * 4;
  heroSection.style.transform = `perspective(900px) rotateX(${rotX}deg) rotateY(${rotY}deg) scale(1.015)`;
  heroSection.style.transition = 'transform 0.12s ease-out';
}

function resetTilt() {
  heroSection.style.transform = 'perspective(900px) rotateX(0deg) rotateY(0deg) scale(1)';
  heroSection.style.transition = 'transform 0.55s cubic-bezier(0.25,0.46,0.45,0.94)';
}

// ── All home interaction listeners are registered once ──
if (!window._homeListenersInit) {
  window._homeListenersInit = true;

// Touch
heroSection.addEventListener('touchmove', e => {
  applyTilt(e.touches[0].clientX, e.touches[0].clientY);
}, { passive: true });
heroSection.addEventListener('touchend', resetTilt);

// Mouse (desktop)
heroSection.addEventListener('mousemove', e => applyTilt(e.clientX, e.clientY));
heroSection.addEventListener('mouseleave', resetTilt);

// ── HERO BG PARALLAX on scroll ──
const homeScreen = document.getElementById('home');
homeScreen.addEventListener('scroll', () => {
  const sy = homeScreen.scrollTop;
  document.querySelectorAll('.hero-bg').forEach(bg => {
    bg.style.transform = `translateY(${sy * 0.38}px)`;
  });
}, { passive: true });

// ── CARD MAGNETIC HOVER (home tiles) ──
document.querySelectorAll('.home-tile, .home-card').forEach(card => {
  card.addEventListener('mousemove', e => {
    const r = card.getBoundingClientRect();
    const x = ((e.clientX - r.left) / r.width  - 0.5) * 12;
    const y = ((e.clientY - r.top)  / r.height - 0.5) * 12;
    card.style.transform = `perspective(600px) rotateX(${-y}deg) rotateY(${x}deg) translateZ(6px)`;
    card.style.transition = 'transform 0.1s ease';
  });
  card.addEventListener('mouseleave', () => {
    card.style.transform = 'perspective(600px) rotateX(0) rotateY(0) translateZ(0)';
    card.style.transition = 'transform 0.4s ease';
  });
});

// ── GLASS PANEL SHIMMER on touch (sub-cards only — NOT home tiles/cards) ──
document.querySelectorAll('.glass-panel, .sub-card').forEach(el => {
  el.addEventListener('touchstart', e => {
    const r = el.getBoundingClientRect();
    const x = ((e.touches[0].clientX - r.left) / r.width * 100).toFixed(1);
    const y = ((e.touches[0].clientY - r.top)  / r.height * 100).toFixed(1);
    el.style.background = `radial-gradient(circle at ${x}% ${y}%, rgba(255,255,255,0.14) 0%, rgba(255,255,255,0.07) 60%)`;
  }, { passive: true });
  el.addEventListener('touchend', () => {
    el.style.background = '';
  });
});

} // end _homeListenersInit guard

// Init GSAP after a tick so home screen elements exist
setTimeout(initGSAP, 400);

// ── HEALTH BANNER ROTATION ──
const maleBanners = [
  'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777706672/grok_image_1777706360035_kdvj3e.jpg',
  'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777706671/grok_image_1777706008418_slbqza.jpg'
];
const femaleBanners = [
  'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777706671/grok_image_1777706116245_awevjm.jpg',
  'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777706672/grok_image_1777706263630_mahjss.jpg'
];
let maleIdx = 0, femaleIdx = 0;
function rotateBanner(el, banners, idxRef, setIdx) {
  if (!el) return;
  el.style.opacity = '0';
  setTimeout(() => {
    const next = (idxRef + 1) % banners.length;
    el.style.backgroundImage = "url('" + banners[next] + "')";
    el.style.opacity = '1';
    setIdx(next);
  }, 700);
}
// Banner intervals are started by goTo() when the health sub-screen opens,
// and cleared before each start to prevent stacking. No parse-time start needed.

// ── BACKGROUND IMAGE PRELOADER ──
// All variables now defined — safe to reference HERO_IMGS, maleBanners, femaleBanners
// Runs after splash starts, silently caches all screen backgrounds
setTimeout(() => {
  const allImages = [
    ...Object.values(bgImages).filter(Boolean),
    ...HERO_IMGS,
    ...maleBanners,
    ...femaleBanners,
  ];
  const unique = [...new Set(allImages)];
  unique.forEach((src, i) => {
    setTimeout(() => {
      const img = new Image();
      img.src = src;
    }, i * 100);
  });
}, 500); // wait 500ms so splash render comes first
