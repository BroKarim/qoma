from pathlib import Path
import json, subprocess
p=Path(__file__).resolve().parent/'out/coworker-flippers-v1.mp4'
m=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_streams','-show_format','-of','json',str(p)]))
v=next(s for s in m['streams'] if s['codec_type']=='video')
assert int(v['nb_frames'])==360 and abs(float(v['duration'])-12)<.001
assert (v['width'],v['height'])==(1920,1248)
subprocess.run(['ffmpeg','-v','error','-i',str(p),'-f','null','-'],check=True)
print('PASS: 360 frames, 12 seconds, 1920x1248, full decode')
