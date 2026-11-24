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
