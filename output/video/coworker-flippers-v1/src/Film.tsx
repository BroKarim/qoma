import React from 'react';
import {AbsoluteFill,Img,staticFile,useCurrentFrame} from 'remotion';
export const SHOTS=[{id:'desktop',from:0,duration:60},{id:'zoom',from:60,duration:60},{id:'catch',from:120,duration:150},{id:'deposit',from:270,duration:90}];
const clamp=(v:number)=>Math.max(0,Math.min(1,v));
const ease=(v:number)=>{const t=clamp(v); return t*t*t*(10+t*(-15+6*t));};
export const Film:React.FC<{frameOffset?:number}>=({frameOffset=0})=>{
 const f=useCurrentFrame()+frameOffset,t=f/30,z=ease((f-60)/60),scale=1+2.2*z;
 const approach=ease((t-4)/2.3),fly=clamp((t-7)/2.3);
 let fishX=65+25*approach,fishY=132-23*approach;
 if(t>=7){fishX=90+65*fly;fishY=109-15*fly-70*Math.sin(Math.PI*fly);}
 const fishVisible=t>=4&&t<9.3;
 return <AbsoluteFill style={{background:'#202225'}}>
  <div style={{position:'absolute',width:1920,height:1248,transformOrigin:'0 0',transform:`translate(${-1320*3.2*z}px,${-858*3.2*z}px) scale(${scale})`}}>
   <Img src={staticFile('desktop.png')} style={{position:'absolute',width:1920,height:1248,filter:`blur(${z*.35}px)`}}/>
   <div style={{position:'absolute',left:1631,top:1005,width:220,height:171}}>
    <Img src={staticFile(`frames/${String(f).padStart(3,'0')}.png`)} style={{width:220,height:171,position:'absolute'}}/>
    <svg width="220" height="171" style={{position:'absolute',overflow:'visible'}}>
     {Array.from({length:22},(_,i)=>{const x=8+((i*71)%204)+2*Math.sin(t+i),y=-25+((i*37+t*(6+i%4))%188);return <rect key={i} x={x} y={y} width={i%3===0?.65:.4} height={i%3===0?.65:.4} fill="#f4fbfc" opacity=".7"/>;})}
     {t>=6.7&&t<7.7&&Array.from({length:9},(_,i)=>{const p=(t-6.7),a=(i/9)*Math.PI;return <circle key={i} cx={90+Math.cos(a)*p*24} cy={109-Math.sin(a)*p*29+p*p*16} r={.5} fill="#d9f4f6" opacity={1-p}/>;})}
     {t>=6.7&&t<8.1&&<ellipse cx="90" cy="111" rx={3+(t-6.7)*13} ry={1+(t-6.7)*3} fill="none" stroke="#d7f2f0" strokeWidth=".4" opacity={Math.max(0,1-(t-6.7)/1.4)}/>}
     {t>=9.3&&t<9.8&&<ellipse cx="157" cy="94" rx={3+Math.sin((t-9.3)*Math.PI*2)*2} ry="1" fill="none" stroke="#e9f5ee" strokeWidth=".5"/>}
    </svg>
    {fishVisible&&<Img src={staticFile('fish.png')} style={{position:'absolute',left:fishX-12,top:fishY-6,width:24,height:12,objectFit:'contain',opacity:t<6.3?.6:1,transform:`rotate(${t>=7?-25+fly*80:Math.sin(t*6)*8}deg)`}}/>}
    {t>=5&&t<6.7&&<Img src={staticFile('bird.png')} style={{position:'absolute',left:-25+(t-5)*130,top:-20-8*Math.sin((t-5)*Math.PI/1.7),width:12,height:8,imageRendering:'pixelated',transform:`scaleY(${Math.sin(t*24)>0?1:.65})`}}/>}
   </div>
  </div>
 </AbsoluteFill>;
};
