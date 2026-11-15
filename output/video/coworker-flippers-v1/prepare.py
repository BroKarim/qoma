from pathlib import Path
import subprocess
from PIL import Image, ImageDraw
P=Path(__file__).resolve().parent/'public'
im=Image.open(P/'desktop-original.png').convert('RGB').resize((1920,1248),Image.Resampling.LANCZOS)
d=ImageDraw.Draw(im)
# Replace only the old floating island with the editor panel's sampled surface.
for y in range(1005,1167):
 d.line((1631,y,1843,y),fill=im.getpixel((1620,y)))
for x in range(1844,1852):
 for y in range(1005,1155): im.putpixel((x,y),im.getpixel((x,1000)))
im.save(P/'desktop.png')
mask=Image.open(P/'island-mask.png')
dec=subprocess.Popen(['ffmpeg','-v','error','-i',str(P/'source.mp4'),'-frames:v','360','-f','rawvideo','-pix_fmt','rgb24','-'],stdout=subprocess.PIPE)
for n in range(360):
 b=dec.stdout.read(1080*1184*3); assert len(b)==1080*1184*3
 frame=Image.frombytes('RGB',(1080,1184),b).convert('RGBA'); frame.putalpha(mask)
 frame.crop((0,300,1080,1140)).resize((756,588),Image.Resampling.LANCZOS).save(P/'frames'/f'{n:03d}.png')
assert dec.wait()==0
fish=Image.open(P/'fish.webp').convert('RGBA'); fish=fish.crop(fish.getbbox()); fish.save(P/'fish.png')
print('Prepared 360 transparent island frames')
