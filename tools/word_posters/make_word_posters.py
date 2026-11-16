# Builds flutter_app/assets/word_posters/<word>.webp from the PRANA poster
# (Ribon's example): person + box cut out with rembg birefnet-general, old
# letters removed, the new word set 3x in Archivo 900, ribbon/suit tinted.
# Step 1 (gen.py part) makes clean.png; step 2 (compose part) sets the word.
# Needs: pip install 'rembg[cpu]' opencv-python-headless pillow numpy
# Paths: source + masks in /tmp/wa (prana_src.png = the PRANA attachment).

import numpy as np, cv2
from PIL import Image
S = 1254
src = np.array(Image.open('/tmp/wa/prana_src.png').convert('RGB'))
per = np.array(Image.open('/tmp/wa/mask_birefnet-general.png').convert('L')).astype(np.float32)/255
yy, xx = np.mgrid[0:S, 0:S]
lum = src.astype(np.float32).mean(axis=2)
pm = (per > 0.5).astype(np.uint8)
pm_d = cv2.dilate(pm, np.ones((5,5),np.uint8))
box = (xx > 190) & (xx < 1080) & (yy > 10) & (yy < 565)
letters = ((lum > 110) & box).astype(np.uint8)
letters = cv2.dilate(letters, np.ones((9, 9), np.uint8))
halo = cv2.dilate(letters, np.ones((41,41),np.uint8)) & box.astype(np.uint8)
clean = src.copy()
# top band: pure black except person
top = (yy < 440) & box & (pm_d == 0)
clean[top] = 0
# lower band: inpaint letters and halo-gray
low = ((yy >= 440) & (halo > 0) & ((letters > 0) | (lum > 30)) & (pm_d == 0)).astype(np.uint8)
clean = cv2.inpaint(clean, low*255, 9, cv2.INPAINT_TELEA)
# restore person pixels exactly
a = per[..., None]
clean = (clean*(1-a) + src*a).astype(np.uint8)
Image.fromarray(clean).save('/tmp/wa/clean.png')

# ---- compose ----
import sys, colorsys, numpy as np, cv2
from PIL import Image, ImageDraw, ImageFont, ImageFilter
S = 1254
G = '/usr/share/fonts/truetype/sand-box/google/'
FONT = G + 'Archivo/Archivo-VariableFont_wdth,wght.ttf'
src = np.array(Image.open('/tmp/wa/prana_src.png').convert('RGB'))
clean = np.array(Image.open('/tmp/wa/clean.png').convert('RGB')).astype(np.float32)
per = np.array(Image.open('/tmp/wa/mask_birefnet-general.png').convert('L')).astype(np.float32)/255
yy, xx = np.mgrid[0:S, 0:S]
# kill residual ghost of old letters in the low band
lum = clean.mean(axis=2)
ghost = (yy >= 430) & (yy < 575) & (xx > 190) & (xx < 1080) & (lum < 75) & (per < 0.1)
clean[ghost] *= np.clip((lum[ghost] - 35) / 40, 0, 1)[:, None]

def hexrgb(h): h = h.lstrip('#'); return np.array([int(h[i:i+2], 16) for i in (0, 2, 4)], np.float32)/255

def tint_ribbon(img, color):
    if color is None: return img
    c = hexrgb(color)
    l = img.mean(axis=2, keepdims=True)/255
    hi = np.clip((l - 0.62)/0.38, 0, 1)
    base = np.clip(l/0.62, 0, 1) * c
    out = (base*(1-hi) + hi*(c*0.25 + 0.75)) * 255
    a = (1 - per)[..., None]
    return img*(1-a) + out*a

def recolor_suit(img, color):
    if color is None: return img
    hsv = cv2.cvtColor(img.astype(np.uint8), cv2.COLOR_RGB2HSV).astype(np.float32)
    h, s, v = hsv[..., 0]*2, hsv[..., 1], hsv[..., 2]
    purple = (h > 245) & (h < 300) & (s > 70) & (per > 0.5)
    th, ts, tv = colorsys.rgb_to_hsv(*hexrgb(color))
    hsv[..., 0][purple] = th*180
    sat_scale = np.clip(ts / 0.75, 0.25, 1.15)
    hsv[..., 1][purple] = np.clip(s[purple]*sat_scale, 0, 255)
    soft = cv2.GaussianBlur(purple.astype(np.float32), (5, 5), 0)[..., None]
    rec = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2RGB).astype(np.float32)
    return img*(1-soft) + rec*soft

def text_layer(word):
    cap, tops = 155, (38, 205, 372)
    maxw = min(1010, max(640, 170*len(word)))
    f = None
    for wdth in range(125, 61, -1):
        f = ImageFont.truetype(FONT, 200); f.set_variation_by_axes([900, wdth])
        # find size so cap height == cap
        b = f.getbbox('H'); size = int(200 * cap / (b[3]-b[1]))
        f = ImageFont.truetype(FONT, size); f.set_variation_by_axes([900, wdth])
        track = -0.035*size
        w = sum(f.getlength(ch) for ch in word) + track*(len(word)-1)
        if w <= maxw: break
    if w > maxw:
        size = int(size*maxw/w); f = ImageFont.truetype(FONT, size); f.set_variation_by_axes([900, wdth])
        track = -0.035*size; w = sum(f.getlength(ch) for ch in word) + track*(len(word)-1)
    m = Image.new('L', (S, S), 0); d = ImageDraw.Draw(m)
    hb = f.getbbox('H')
    for top in tops:
        x = (S - w)/2 + 6
        for ch in word:
            d.text((x, top - hb[1]), ch, font=f, fill=255)
            x += f.getlength(ch) + track
    m = np.array(m)
    m = cv2.dilate(m, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7)))
    return cv2.GaussianBlur(m.astype(np.float32)/255, (3, 3), 0)

def make(word, ribbon=None, suit=None, out=None):
    img = recolor_suit(tint_ribbon(clean.copy(), ribbon), suit)
    t = text_layer(word)
    rng = np.random.default_rng(len(word)*7+ord(word[0]))
    noise = cv2.GaussianBlur(rng.random((S, S)).astype(np.float32), (0, 0), 2.4)
    noise = (noise - noise.mean())/noise.std()
    fill = np.clip(242 + 4*noise, 222, 255)
    glow = cv2.GaussianBlur(t, (0, 0), 14)*0.32 + cv2.GaussianBlur(t, (0, 0), 3)*0.18
    bg = img
    # text sits behind the person; glow is additive (screen)
    g = (glow*255)[..., None]
    bg = 255 - (255-bg)*(255-g*(1-per[..., None]))/255
    ta = (t*(1-per))[..., None]
    bg = bg*(1-ta) + fill[..., None]*ta
    # person back on top (unchanged except suit recolor already applied in img)
    pa = per[..., None]
    bg = bg*(1-pa) + img*pa
    im = Image.fromarray(np.clip(bg, 0, 255).astype(np.uint8))
    if out: im.save(out)
    return im

P = {
 'AAROGYA': ('#3DDC97', '#2FB57C'),
 'SHAKTI':  ('#FF3B5C', '#D61F45'),
 'ANANDA':  ('#FF7AC8', '#E0559F'),
 'SOMA':    ('#B58CFF', None),
 'TEJAS':   ('#FFB547', '#C9822A'),
 'OJAS':    ('#FFD25A', '#C9A13A'),
 'VATA':    ('#5FB8FF', '#2F7FD6'),
 'PITTA':   ('#FF6A2B', '#C8481C'),
 'KAPHA':   ('#2FD4C8', '#1E9E95'),
 'SURYA':   ('#FF8A1F', '#D0661A'),
 'CHANDRA': ('#A9D8FF', '#3F6E9E'),
 'NOWSSB':  (None, None),
}
import os
os.makedirs('/tmp/wa/out', exist_ok=True)
for w,(r,su) in P.items():
    make(w, r, su, f'/tmp/wa/out/{w.lower()}.png'); print(w)
