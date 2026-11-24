set -e
A="${WORDS:-$(cd "$(dirname "$0")/../.." && pwd)/assets/words}"
cd "${CLIPS:-clips}"
for w in america:1 america:2 ramram:1 ramram:2 ramram:3 washington:1 washington:2; do
  k=${w%%:*}; n=${w##*:}; b=${k}_s${n}
  # The stage's clean recording (denoised, trimmed) as 16 kHz mono reference.
  ffmpeg -loglevel error -y -i $A/$k/${k}_stage${n}_clean.m4a -ac 1 -ar 16000 -c:a pcm_s16le ${b}_clean.wav
  ffmpeg -loglevel error -y -i $A/$k/${k}_stage${n}_ref.wav -ac 1 -ar 16000 -c:a pcm_s16le ${b}_orig.wav
  S=${b}_orig.wav  # degrade the teacher's ORIGINAL take (a fresh live take is raw mic, not denoised)
  d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 $S)
  for snr in 20 15 10; do
    ffmpeg -loglevel error -y -i $S -f lavfi -i "anoisesrc=color=pink:sample_rate=16000:amplitude=1:duration=$d" -filter_complex "[0:a]loudnorm=I=-20:TP=-2[v];[1:a]volume=$(python3 -c "print(10**((-20-$snr-3)/20))")[n];[v][n]amix=inputs=2:normalize=0[o]" -map "[o]" -ac 1 -ar 16000 ${b}_noise${snr}.wav
  done
  ffmpeg -loglevel error -y -i $S -af "aecho=0.8:0.75:35|70|120:0.4|0.3|0.2" ${b}_reverb.wav
  ffmpeg -loglevel error -y -i $S -af "highpass=f=300,lowpass=f=3400,equalizer=f=1500:t=q:w=1:g=6" ${b}_phone.wav
  ffmpeg -loglevel error -y -i $S -af "volume=12dB,alimiter=limit=0.99" ${b}_gain+12.wav
  ffmpeg -loglevel error -y -i $S -af "volume=-12dB" ${b}_gain-12.wav
  for tp in 0.75 0.85 1.15 1.3; do ffmpeg -loglevel error -y -i $S -af "atempo=$tp" ${b}_tempo$tp.wav; done
  for st in -2 2; do r=$(python3 -c "print(2**($st/12))"); ffmpeg -loglevel error -y -i $S -af "asetrate=16000*$r,aresample=16000,atempo=1/$r" ${b}_pitch$st.wav; done
  ffmpeg -loglevel error -y -i $S -af "adelay=1200,apad=pad_dur=1.5" ${b}_silence.wav
  ffmpeg -loglevel error -y -i $S -f lavfi -i "anoisesrc=color=pink:sample_rate=16000:amplitude=1:duration=$(python3 -c "print($d+2.7)")" -filter_complex "[0:a]adelay=1200,apad=pad_dur=1.5,atempo=1.15,asetrate=16000*1.06,aresample=16000,highpass=f=250,lowpass=f=3600,aecho=0.8:0.7:40|90:0.35|0.2,volume=-6dB[v];[1:a]volume=0.006[n];[v][n]amix=inputs=2:normalize=0:duration=first,acompressor=threshold=-30dB:ratio=4:makeup=8[o]" -map "[o]" -ac 1 -ar 16000 ${b}_combo.wav
done
ls | wc -l
