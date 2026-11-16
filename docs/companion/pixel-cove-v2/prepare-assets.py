"""Export repaired character atlases with their own alpha; never apply silhouette masks."""
from pathlib import Path
from PIL import Image
import json
HERE=Path(__file__).resolve().parent
CAT=HERE.parents[2]/'Qoma/Assets.xcassets/Companion/PixelCoveV2'
CAT.mkdir(parents=True,exist_ok=True)
(CAT/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
for key in ['catch','cast','deposit','hop','poses']:
    im=Image.open(HERE/'sources'/f'{key}.png').convert('RGBA')
    size=(1024,768) if key=='hop' else (1536,1024)
    im=im.resize(size,Image.Resampling.NEAREST)
    cols,rows=(3,2) if key=='poses' else (4,3)
    for i in range(cols*rows):
        w,h=im.width//cols,im.height//rows
        cell=im.crop((i%cols*w,i//cols*h,(i%cols+1)*w,(i//cols+1)*h))
        assert cell.getchannel('A').getbbox(),(key,i)
        # Interior torso must remain opaque; this catches accidentally punched-out bodies.
        cx=0.5 if key=='hop' else 0.6
        assert cell.getpixel((int(w*cx),int(h*0.65)))[3]>128,(key,i,'torso missing')
    name=f'Pixel{key.title()}V2';dest=CAT/f'{name}.imageset';dest.mkdir(exist_ok=True)
    im.save(dest/f'{name}.png')
    (dest/'Contents.json').write_text(json.dumps({'images':[{'filename':f'{name}.png','idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2))
print('Exported 54 repaired drawings with native alpha and intact torso checks.')
