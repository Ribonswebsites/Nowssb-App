"""Per-stage akshara timings for the karaoke highlight.

For each teacher stage recording (the _ref.wav, same trim as _clean.m4a) the
voiced region is found from short-time energy, then split into N aksharas at
the N-1 deepest energy valleys between onsets (each akshara at least 250 ms);
if no clean valleys are found it falls back to an equal split. Writes
"akshara": [[start, end], ...] (seconds, clean-audio timebase) into
assets/content/client_words.json.
Run: python3 tool/audio/akshara_times.py
"""
import json, wave, sys
import numpy as np

VIRAMA = '\u094d'

def aksharas(s):
    out = []
    for ch in s:
        if ch == ' ':
            continue
        cp = ord(ch)
        dependent = 0x093A <= cp <= 0x094F or 0x0900 <= cp <= 0x0903 or 0x0955 <= cp <= 0x0957 or 0x0962 <= cp <= 0x0963
        if out and (dependent or out[-1].endswith(VIRAMA)):
            out[-1] += ch
        else:
            out.append(ch)
    return out

def energy(path):
    w = wave.open(path)
    sr = w.getframerate()
    x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768
    if w.getnchannels() > 1:
        x = x.reshape(-1, w.getnchannels()).mean(1)
    hop = int(sr * 0.01); win = int(sr * 0.03)
    e = np.array([np.sqrt(np.mean(x[i:i + win] ** 2) + 1e-12) for i in range(0, max(1, len(x) - win), hop)])
    db = 20 * np.log10(e + 1e-9)
    k = np.ones(5) / 5
    return np.convolve(db, k, mode='same'), 0.01, len(x) / sr

def split(path, n):
    db, hop, dur = energy(path)
    voiced = np.where(db > db.max() - 32)[0]
    a, b = voiced[0], voiced[-1]
    if n <= 1:
        return [[round(a * hop, 3), round(b * hop, 3)]]
    seg = db[a:b + 1]
    mins = [i for i in range(2, len(seg) - 2) if seg[i] <= seg[i - 1] and seg[i] <= seg[i + 1] and seg[i] <= seg[i - 2] and seg[i] <= seg[i + 2]]
    # Depth: how far the valley dips below the peaks around it.
    def depth(i):
        l = seg[max(0, i - 15):i].max(); r = seg[i + 1:i + 16].max() if i + 1 < len(seg) else seg[i]
        return min(l, r) - seg[i]
    mins = sorted(mins, key=depth, reverse=True)
    picked = []
    for m in mins:
        if depth(m) < 1.5:
            break
        if all(abs(m - p) >= 25 for p in picked) and m >= 25 and m <= len(seg) - 26:
            picked.append(m)
        if len(picked) == n - 1:
            break
    if len(picked) < n - 1:
        cuts = [round(len(seg) * k / n) for k in range(1, n)]
        how = 'equal'
    else:
        cuts = sorted(picked)
        how = 'valleys'
    edges = [0] + cuts + [len(seg) - 1]
    t = [[round(float((a + edges[k]) * hop), 3), round(float((a + edges[k + 1]) * hop), 3)] for k in range(n)]
    return t, how

def main():
    p = 'assets/content/client_words.json'
    d = json.load(open(p))
    for it in d['items']:
        word_deva = (it.get('deva') or '').strip()
        for st in (it.get('practice') or {}).get('stages', []):
            deva = (st.get('deva') or word_deva).strip()
            if not deva:
                st.pop('akshara', None)
                continue
            ak = aksharas(deva)
            t, how = split(st['reference'], len(ak))
            st['akshara'] = t
            print(it['key'], st['stage'], deva, ak, how, t)
    # Write each timing onto its stage's "reference" line, keeping the file's layout.
    text = open(p).read()
    import re
    text = re.sub(r', "akshara": \[[^\n]*\]\]', '', text)
    for it in d['items']:
        for st in (it.get('practice') or {}).get('stages', []):
            if 'akshara' not in st:
                continue
            line = '"reference": "%s",' % st['reference']
            i = text.index(line)
            j = text.index('\n', i + len(line))  # the seconds line follows
            j = text.index('\n', j + 1)
            text = text[:j] + ', "akshara": ' + json.dumps(st['akshara']) + text[j:]
    open(p, 'w').write(text)

if __name__ == '__main__':
    main()
