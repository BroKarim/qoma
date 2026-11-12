"""Prepare generated pixel atlases without changing their animation registration."""
from pathlib import Path
from PIL import Image
import json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
CAT=ROOT/'Qoma/Assets.xcassets/Companion/PixelCoveV1'
def save(name,im):
    p=CAT/(name+'.imageset');p.mkdir(parents=True,exist_ok=True)
    im.save(p/(name+'.png'))
    (p/'Contents.json').write_text(json.dumps({'images':[{'filename':name+'.png','idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2))
CAT.mkdir(parents=True,exist_ok=True)
(CAT/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
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
print('Prepared island and pixel props; character atlas export is in pixel-cove-v2.')
