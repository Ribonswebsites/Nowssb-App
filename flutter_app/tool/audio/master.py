# Loudness master for every teacher stage: the clean voice to -14 LUFS (true
# peak under -1 dBFS), and each music version rebuilt from it with the bed at
# about -26 LUFS (12 dB under the voice), ducked further while the voice
# speaks. Beds: Drone (CC0 drone.mp3), Warm pad, Singing bowl, Bansuri,
# Tanpura (all synthesised by tool/audio/make_beds.py, CC0).
# Run from a folder holding drone.mp3 and the make_beds.py output:
#   python3 tool/audio/master.py <assets/words dir>
import glob, json, re, subprocess, sys
W = sys.argv[1] if len(sys.argv) > 1 else 'assets/words'
VOICE = -14.0
BED = VOICE - 12.0
BEDS = [('', 'drone.mp3', 20), ('2', 'warm_pad.wav', 0), ('3', 'singing_bowl.wav', 0), ('4', 'bansuri.wav', 0), ('5', 'tanpura.wav', 0)]
def sh(*a): subprocess.run(a, check=True)
def lufs(f):
    e = subprocess.run(['ffmpeg', '-nostats', '-i', f, '-af', 'ebur128=peak=true', '-f', 'null', '-'], capture_output=True, text=True).stderr
    i = float(re.findall(r'I:\s+(-?[\d.]+) LUFS', e)[-1])
    return i
def dur(f): return float(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f]).decode())
report = {}
for clean in sorted(glob.glob(f'{W}/*/*_clean.m4a')):
    base = clean[:-len('_clean.m4a')]
    sh('ffmpeg', '-loglevel', 'error', '-y', '-i', clean, '-ac', '1', '-ar', '44100', 'v0.wav')
    g = VOICE - lufs('v0.wav')
    sh('ffmpeg', '-loglevel', 'error', '-y', '-i', 'v0.wav', '-af', f'volume={g:.2f}dB,alimiter=limit=0.89:level=false:attack=2:release=40', 'vn.wav')
    sh('ffmpeg', '-loglevel', 'error', '-y', '-i', 'vn.wav', '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', clean)
    d = dur('vn.wav'); tot = 2.5 + d + 3.5
    sh('ffmpeg', '-loglevel', 'error', '-y', '-i', 'vn.wav', '-af', 'adelay=2500,apad=pad_dur=3.5', '-ar', '44100', 'v.wav')
    row = {'voice_gain_db': round(g, 1), 'clean_lufs': round(lufs(clean), 1)}
    for suf, bed, ss in BEDS:
        sh('ffmpeg', '-loglevel', 'error', '-y', '-ss', str(ss), '-t', f'{tot:.3f}', '-i', bed, '-ac', '1', '-ar', '44100', 'b0.wav')
        bg = BED - lufs('b0.wav')
        sh('ffmpeg', '-loglevel', 'error', '-y', '-i', 'b0.wav', '-af', f'volume={bg:.2f}dB,afade=t=in:d=1.5,afade=t=out:st={tot-2.2:.3f}:d=2.2', 'm.wav')
        out = f'{base}_music{suf}.m4a'
        sh('ffmpeg', '-loglevel', 'error', '-y', '-i', 'm.wav', '-i', 'v.wav', '-filter_complex',
           '[1:a]asplit=2[sc][vo];[0:a][sc]sidechaincompress=threshold=0.03:ratio=4:attack=20:release=500:makeup=1[duck];'
           '[duck][vo]amix=inputs=2:normalize=0,alimiter=limit=0.89:level=false[out]',
           '-map', '[out]', '-ac', '1', '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', out)
        row[f'music{suf or "1"}_lufs'] = round(lufs(out), 1)
        row[f'bed{suf or "1"}_lufs'] = round(lufs('m.wav'), 1)
        row['musicSeconds'] = round(dur(out), 2)
    report[base.split('/')[-1]] = row
print(json.dumps(report, indent=1))
