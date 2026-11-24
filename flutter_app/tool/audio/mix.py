# Each stage's cleaned voice over the two synthesised beds, ducked the same
# way as the drone version: <key>_stage<n>_music2.m4a (Warm pad) and
# _music3.m4a (Singing bowl).
import subprocess, glob, os, json
W = '/workspace/am-check/flutter_app/assets/words'
def sh(*a): subprocess.run(a, check=True)
def dur(f): return float(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','csv=p=0',f]).decode())
out = {}
for clean in sorted(glob.glob(f'{W}/*/*_clean.m4a')):
    base = clean[:-len('_clean.m4a')]
    d = dur(clean); tot = 2.5 + d + 3.5
    sh('ffmpeg','-loglevel','error','-y','-i',clean,'-af','adelay=2500,apad=pad_dur=3.5','-ac','1','-ar','44100','v.wav')
    for bed, suffix, vol in [('warm_pad.wav', 'music2', -24), ('singing_bowl.wav', 'music3', -21)]:
        sh('ffmpeg','-loglevel','error','-y','-t',str(tot),'-i',bed,'-ac','1','-ar','44100','-af',f'volume={vol}dB,afade=t=in:d=1.5,afade=t=out:st={tot-2.2}:d=2.2','m.wav')
        sh('ffmpeg','-loglevel','error','-y','-i','m.wav','-i','v.wav','-filter_complex','[1:a]asplit=2[sc][vo];[0:a][sc]sidechaincompress=threshold=0.02:ratio=8:attack=20:release=450:makeup=1[duck];[duck][vo]amix=inputs=2:normalize=0,alimiter=limit=0.95[out]','-map','[out]','-ac','1','-c:a','aac','-b:a','128k','-movflags','+faststart',f'{base}_{suffix}.m4a')
        out[f'{base}_{suffix}.m4a'] = round(dur(f'{base}_{suffix}.m4a'), 2)
print(json.dumps(out, indent=1))
