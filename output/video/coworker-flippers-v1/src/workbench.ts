import {Film,SHOTS} from './Film';
export const WORKBENCH={name:'My coworker has flippers',fps:30,width:1920,height:1248,total:360,background:'#202225',shots:SHOTS.map(s=>({...s,label:s.id,component:Film,props:{frameOffset:s.from},schema:[]})),transitions:[],captions:[],sfx:[],order:['transitions','captions','overlays'],original:Film};
