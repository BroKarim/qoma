"""Prepare generated pixel atlases without changing their animation registration."""
from pathlib import Path
from PIL import Image, ImageChops
import json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
CAT=ROOT/'Qoma/Assets.xcassets/Companion/PixelCoveV1'
OLD=ROOT/'Qoma/Assets.xcassets/Companion/WatercolorCoveV6'
def save(name,im):
    p=CAT/(name+'.imageset');p.mkdir(parents=True,exist_ok=True)
    im.save(p/(name+'.png'))
    (p/'Contents.json').write_text(json.dumps({'images':[{'filename':name+'.png','idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2))
CAT.mkdir(parents=True,exist_ok=True)
(CAT/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
for key in ['catch','cast','deposit','hop','poses']:
    name='Cove'+key.title()+'V6'
    matte=Image.open(OLD/(name+'.imageset')/(name+'.png')).getchannel('A')
    im=Image.open(HERE/'sources'/(key+'.png')).convert('RGBA').resize(matte.size,Image.Resampling.NEAREST)
    # Use the registered silhouette as a matte to reject generator backgrounds.
    im.putalpha(ImageChops.multiply(matte.point(lambda a:255 if a>128 else 0),
        im.getchannel('A').point(lambda a:255 if a>=249 else 0)))
    cols,rows=(3,2) if key=='poses' else (4,3)
    for i in range(cols*rows):
        cell=im.crop((i%cols*im.width//cols,i//cols*im.height//rows,(i%cols+1)*im.width//cols,(i//cols+1)*im.height//rows))
        assert cell.getchannel('A').getbbox(),(key,i)
    save('Pixel'+key.title()+'V1',im)
im=Image.open(HERE/'sources/island.png').convert('RGBA')
save('PixelIslandV1',im)
# Props are independently cropped from a single clean 4x2 asset-kit sheet.
im=Image.open(HERE/'sources/props.png').convert('RGBA')
props=[]
for i,name in enumerate(['Fish','Bucket','Boot','Shell','Bottle','Splash','Sleep','WaterFish']):
    w,h=im.width//4,im.height//2
    cell=im.crop((i%4*w,i//4*h,(i%4+1)*w,(i//4+1)*h))
    cell.putalpha(cell.getchannel('A').point(lambda a:255 if a>200 else 0))
    box=cell.getchannel('A').getbbox();assert box,name
    cell=cell.crop(box);props.append(cell);save('Pixel'+name+'V1',cell)
atlas=Image.new('RGBA',(1024,256))
for i,k in enumerate([0,2,3,4]):
    item=props[k].copy();item.thumbnail((180,180),Image.Resampling.NEAREST)
    atlas.alpha_composite(item,(i*256+(256-item.width)//2,(256-item.height)//2))
save('PixelCatchesV1',atlas)
print('Prepared 54 character drawings, island and pixel props.')
