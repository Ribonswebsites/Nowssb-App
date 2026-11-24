# Edited versions of the client's recordings: arnndn-denoised clean voice
# (trimmed to the word, peak -1 dBFS), a music version (CC0 drone ducked
# under the voice), and a 16 kHz reference WAV for scoring.
import json, subprocess, sys
sys.path.insert(0, '/workspace/shabda-score/src')
import audio_features as af
R = '/workspace/america-restore/recs'
OUT = '/workspace/am-check/flutter_app/assets/words'
JOBS = [  # (word key, stage, recording id)
    ('ramram', 1, 'dff5ce25'), ('ramram', 2, 'df54a36e'), ('ramram', 3, 'a3f59da4'),
    ('washington', 1, '56b52ac6'), ('washington', 2, 'bb5308ba'),
]
def sh(*a): subprocess.run(a, check=True)
def out(*a): return subprocess.run(a, check=True, capture_output=True, text=True)
info = {}
for key, n, rid in JOBS:
    import os; os.makedirs(f'{OUT}/{key}', exist_ok=True)
    w = f'{key}{n}'
    sh('ffmpeg','-loglevel','error','-y','-i',f'{R}/{rid}.wav','-ac','1','-ar','16000',f'{w}_raw16.wav')
    sh('ffmpeg','-loglevel','error','-y','-i',f'{R}/{rid}.wav','-ac','1','-ar','48000','-af','highpass=f=70,arnndn=m=std.rnnn',f'{w}_full_clean.wav')
    f = af.extract(f'{w}_raw16.wav'); iv = f.vad['intervals']
    a = max(0, iv[0][0] - 0.35); b = min(f.duration, iv[-1][1] + 0.5); d = b - a
    sh('ffmpeg','-loglevel','error','-y','-i',f'{w}_full_clean.wav','-af',f'atrim={a}:{b},asetpts=N/SR/TB,afade=t=in:d=0.015,areverse,afade=t=in:d=0.04,areverse',f'{w}_t.wav')
    vd = subprocess.run(['ffmpeg','-i',f'{w}_t.wav','-af','volumedetect','-f','null','-'],capture_output=True,text=True).stderr
    peak = float(vd.split('max_volume:')[1].split('dB')[0])
    sh('ffmpeg','-loglevel','error','-y','-i',f'{w}_t.wav','-af',f'volume={-1.0-peak}dB','-ar','48000',f'{w}_c.wav')
    base = f'{OUT}/{key}/{key}_stage{n}'
    # Scoring reference = the raw memo, trimmed (scoring against the denoised voice drops self-scores).
    sh('ffmpeg','-loglevel','error','-y','-i',f'{R}/{rid}.wav','-ac','1','-ar','16000','-af',f'atrim={a}:{b},asetpts=N/SR/TB','-c:a','pcm_s16le',f'{base}_ref.wav')
    sh('ffmpeg','-loglevel','error','-y','-i',f'{w}_c.wav','-ac','1','-ar','44100','-c:a','aac','-b:a','128k','-movflags','+faststart',f'{base}_clean.m4a')
    sh('ffmpeg','-loglevel','error','-y','-i',f'{w}_c.wav','-af','adelay=2500,apad=pad_dur=3.5','-ar','44100',f'{w}_v.wav')
    tot = 2.5 + d + 3.5
    sh('ffmpeg','-loglevel','error','-y','-ss','20','-t',str(tot),'-i','drone.mp3','-ac','1','-ar','44100','-af',f'volume=-14dB,afade=t=in:d=1.5,afade=t=out:st={tot-2.2}:d=2.2',f'{w}_m.wav')
    sh('ffmpeg','-loglevel','error','-y','-i',f'{w}_m.wav','-i',f'{w}_v.wav','-filter_complex','[1:a]asplit=2[sc][vo];[0:a][sc]sidechaincompress=threshold=0.02:ratio=8:attack=20:release=450:makeup=1[duck];[duck][vo]amix=inputs=2:normalize=0,alimiter=limit=0.95[out]','-map','[out]','-ac','1','-c:a','aac','-b:a','128k','-movflags','+faststart',f'{base}_music.m4a')
    info[f'{key}/{n}'] = dict(rid=rid, start=a, end=b, seconds=round(d, 2), snr=f.vad['snr_db'])
json.dump(info, open('info.json', 'w'), indent=1)
print(json.dumps(info, indent=1))
