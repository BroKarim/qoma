import {Film,SHOTS} from './Film';
export const WORKBENCH={name:'Constellation Whale',fps:30,width:1920,height:956,total:450,background:'#202225',shots:SHOTS.map(s=>({...s,label:s.id,component:Film,props:{frameOffset:s.from},schema:[]})),transitions:[],captions:[],sfx:[],order:['transitions','captions','overlays'],original:Film};
