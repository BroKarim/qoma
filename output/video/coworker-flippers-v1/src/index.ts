import {registerRoot,Composition} from 'remotion';
import React from 'react';
import {Film} from './Film';
registerRoot(()=>React.createElement(Composition,{id:'Coworker',component:Film,durationInFrames:360,fps:30,width:1920,height:1248}));
