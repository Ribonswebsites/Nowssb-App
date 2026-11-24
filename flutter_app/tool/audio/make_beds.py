# Two calm meditation beds, synthesised here from sine waves (no samples,
# no AI): "Warm pad" (a soft A-major-add9 drone with slow swell) and
# "Singing bowl" (bell partials struck every 4 s, long decay). Public domain
# (CC0) — made for NowssB.
import numpy as np, wave
SR = 44100; DUR = 40.0
t = np.arange(int(SR * DUR)) / SR
def save(name, x):
    x = x / np.max(np.abs(x)) * 0.5
    with wave.open(name, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
# Warm pad
pad = np.zeros_like(t)
for f, a in [(110, 1.0), (164.81, .6), (220, .55), (246.94, .3), (329.63, .25)]:
    for det in (-0.6, 0.6):
        pad += a * np.sin(2 * np.pi * (f + det) * t + np.random.rand() * 6.28)
pad *= 0.75 + 0.25 * np.sin(2 * np.pi * t / 9.0)
k = np.exp(-np.arange(400) / 80.0); k /= k.sum()
pad = np.convolve(pad, k, mode='same')
save('warm_pad.wav', pad)
# Singing bowl
bowl = np.zeros_like(t)
for start in np.arange(0, DUR, 4.0):
    m = t >= start; tt = t[m] - start
    for f, a, d in [(196, 1.0, 6.0), (196 * 2.76, .45, 3.5), (196 * 5.4, .2, 2.0), (196 * 8.9, .08, 1.2)]:
        bowl[m] += a * np.sin(2 * np.pi * f * tt) * np.exp(-tt / d) * (1 - np.exp(-tt / 0.01)) * (1 + 0.04 * np.sin(2 * np.pi * 4.5 * tt))
save('singing_bowl.wav', bowl)

# Bansuri: a soft bamboo-flute line (sine + gentle 2nd/3rd harmonics, breath
# noise, slow vibrato) over Sa Re Ga Pa Dha, long notes with soft attacks.
rng = np.random.default_rng(7)
sa = 293.66  # D4
ratios = {'S': 1, 'R': 9/8, 'G': 5/4, 'P': 3/2, 'D': 5/3, "S'": 2, 'd': 5/6}
phrase = ['S', 'R', 'G', 'P', 'G', 'R', 'S', 'd', 'S', 'G', 'P', 'D', 'P', 'G', 'R', 'S']
lens = [2.4, 1.6, 2.6, 3.2, 1.8, 1.6, 3.0, 2.0, 2.8, 2.0, 2.4, 3.2, 1.8, 1.8, 2.0, 4.0]
fl = np.zeros_like(t); pos = 0.5
breath_lp = np.exp(-np.arange(60) / 12.0); breath_lp /= breath_lp.sum()
while pos < DUR - 1:
    for n, L in zip(phrase, lens):
        if pos >= DUR - 1: break
        i0 = int(pos * SR); i1 = min(len(t), int((pos + L + 0.6) * SR))
        tt = np.arange(i1 - i0) / SR
        f = sa * ratios[n]
        vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * tt) * np.clip((tt - 0.4) / 0.6, 0, 1)
        ph = 2 * np.pi * np.cumsum(f * vib) / SR
        env = np.clip(tt / 0.25, 0, 1) * np.exp(-np.clip(tt - L, 0, None) / 0.18) * (0.85 + 0.15 * np.sin(2 * np.pi * tt / max(L, 1)))
        tone = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.07 * np.sin(3 * ph)
        br = np.convolve(rng.standard_normal(len(tt)), breath_lp, mode='same') * 0.12
        fl[i0:i1] += env * (tone + br)
        pos += L
    pos += 3.0
# a little room
ir = np.zeros(int(SR * 1.2)); ir[0] = 1
for d, g in [(0.031, .35), (0.067, .25), (0.11, .18), (0.17, .12), (0.26, .08), (0.4, .05)]:
    ir[int(d * SR)] += g
fl = np.convolve(fl, ir)[:len(t)]
save('bansuri.wav', fl)

# Tanpura: four plucked strings (Pa, Sa', Sa', Sa) in a slow cycle, rich
# harmonics with the buzzing "jawari" brightness that swells after each pluck.
tp = np.zeros_like(t)
low_sa = 146.83  # D3
strings = [low_sa * 3 / 4, low_sa, low_sa, low_sa / 2]
cycle = 4.8
for c0 in np.arange(0, DUR, cycle):
    for k, f in enumerate(strings):
        start = c0 + k * cycle / 4
        m = t >= start; tt = t[m] - start
        s = np.zeros_like(tt)
        for h in range(1, 14):
            jaw = 1 + 0.8 * (h / 14) * np.clip(tt / 0.8, 0, 1) * np.exp(-tt / 3.0)
            s += (1 / h) * jaw * np.sin(2 * np.pi * f * h * tt + h) * np.exp(-tt * (0.35 + 0.05 * h))
        tp[m] += s * (1 - np.exp(-tt / 0.004))
k2 = np.exp(-np.arange(30) / 8.0); k2 /= k2.sum()
tp = np.convolve(tp, k2, mode='same')
save('tanpura.wav', tp)
