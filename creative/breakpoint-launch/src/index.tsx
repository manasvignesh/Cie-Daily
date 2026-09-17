import React from 'react';
import {registerRoot, Composition} from 'remotion';
import {Launch} from './Launch';
registerRoot(() => <Composition id="Launch" component={Launch} width={1080} height={1920} fps={60} durationInFrames={1740}/>);
