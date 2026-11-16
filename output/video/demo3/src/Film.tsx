import React from 'react';
import {AbsoluteFill,Img,staticFile,useCurrentFrame} from 'remotion';

export const SHOTS=[{id:'Desktop',from:0,duration:60},{id:'Zoom',from:60,duration:60},{id:'Bite',from:120,duration:90},{id:'Reveal',from:210,duration:90},{id:'Showcase',from:300,duration:60},{id:'Bucket',from:360,duration:90}];
const clamp=(x:number)=>Math.min(1,Math.max(0,x));
const ease=(x:number)=>{const s=clamp(x);return s*s*s*(10+s*(-15+6*s));};
const mix=(a:number,b:number,t:number)=>a+(b-a)*t;
export const Film:React.FC<{frameOffset?:number}>=({frameOffset=0})=>{
 const f=useCurrentFrame()+frameOffset,t=f/30,z=ease((f-60)/60);
 const rise=ease((t-7)/3), drop=ease((t-12)/1.2);
 const gold=clamp((t-4)/2)* (1-ease((t-12)/1.5));
 const hover=Math.sin((t-10)*4)*2*ease((t-10)/.3)*(1-drop);
 const whaleX=mix(94,189,drop),whaleY=mix(mix(144,-18,rise)+hover,108,drop)-15*Math.sin(Math.PI*drop);
 const size=mix(mix(72,144,rise),6,drop);
 const splash=clamp((t-7)/1.2);
 const pose=f<200?f:f<300?200+Math.floor((f-200)*.65):f<396?265:300+Math.min(f-396,53);
 return <AbsoluteFill style={{background:'#0c0c0c'}}>
  <div style={{position:'absolute',width:1920,height:956,transformOrigin:'0 0',transform:`translate(${-1445*3.2*z}px,${-657*3.2*z}px) scale(${1+2.2*z})`}}>
   <Img src={staticFile('opencode.png')} style={{position:'absolute',width:1920,height:956}}/>
   <div style={{position:"absolute",left:1900,top:0,width:22,height:956,background:"#0c0c0c",opacity:z}}/>

   <div style={{position:'absolute',left:1639,top:746,width:266,height:201,background:'#0c0c0c'}}/>
   <div style={{position:'absolute',left:1640,top:747,width:264,height:199}}>
    <Img src={staticFile(`frames/${String(pose).padStart(3,'0')}.png`)} style={{position:'absolute',width:264,height:199}}/>
    {t>=2.9&&t<4.8&&<Img src={staticFile('fish.png')} style={{position:'absolute',width:19,left:65+26*ease((t-2.9)/1.4),top:145-13*ease((t-2.9)/1.4),opacity:.75*(1-ease((t-4.4)/.4))}}/>}
    <svg width="264" height="199" style={{position:'absolute',overflow:'visible'}}>
     {[0,1,2].map(i=>{const p=((t*.85+i/3)%1+1)%1;return <ellipse key={i} cx="94" cy="145" rx={4+34*p} ry={1+9*p} fill="none" stroke="#efc37b" strokeWidth=".8" opacity={gold*(1-p)*.85}/>;})}
     {t>=7&&t<8.2&&Array.from({length:14},(_,i)=><rect key={i} x={94+(i-6.5)*5*splash} y={145-Math.sin(Math.PI*splash)*(13+i%4*7)} width={i%3===0?2:1} height="2" fill={i%2?'#dbc795':'#b8e1e0'} opacity={1-splash}/>)}
    </svg>
    {t>=7&&t<13.2&&<div style={{position:'absolute',left:whaleX-size/2,top:whaleY-size/2,width:size,height:size,clipPath:t<10?`inset(0 0 ${Math.max(0,100*(whaleY+size/2-149)/size)}% 0)`:undefined}}>
     <Img src={staticFile('whale.png')} style={{width:'100%',height:'100%',transform:`rotate(${mix(-13,4,rise)+drop*16}deg)`,filter:'drop-shadow(0 0 4px #dfa74b99)'}}/>
    </div>}
    {t>=8&&t<13.2&&Array.from({length:7},(_,i)=>{const a=i*2.4;return <div key={i} style={{position:'absolute',left:whaleX+Math.cos(a)*size*.54,top:whaleY+Math.sin(a)*size*.35,font:'7px monospace',color:'#ffda91',opacity:gold*(.55+.45*Math.sin(t*5+i))}}>✦</div>;})}
    {t>=6.3&&t<8.7&&<div style={{position:'absolute',left:182,top:62,color:'#ffd686',font:'bold 18px monospace',textShadow:'1px 1px #49341c',transform:`translateY(${-5*ease((t-6.3)/.2)}px)`,opacity:1-ease((t-8.4)/.3)}}>!</div>}
    {t>=13.1&&t<13.7&&<div style={{position:'absolute',left:184,top:107,color:'#ffdb93',font:'12px monospace',opacity:1-ease((t-13.1)/.6)}}>✦</div>}
   </div>
  </div>
 </AbsoluteFill>;
};
