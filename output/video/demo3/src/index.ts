import {registerRoot,Composition} from 'remotion';
import React from 'react';
import {Film} from './Film';
registerRoot(()=>React.createElement(Composition,{id:'Legendary',component:Film,durationInFrames:450,fps:30,width:1920,height:956}));
