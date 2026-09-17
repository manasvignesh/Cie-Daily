import React, {useEffect, useState} from 'react';
import {AbsoluteFill, Audio, Img, OffthreadVideo, Sequence, staticFile, useCurrentFrame, delayRender, continueRender, cancelRender} from 'remotion';
import {C, between, Environment, Copy, Phone, Wordmark, Dot, Breakout, OrangeWipe} from './system';

const Intro = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill style={{background:C.ink, justifyContent:'center', alignItems:'center'}}>
    <div style={{position:'absolute', top:945, left:0, width:Math.min(540,Math.max(0,(f-8)/47*540)), height:2, background:C.bone, opacity:between(f,67,89,1,0)}}/>
    <Dot size={26} style={{position:'absolute',left:527,top:933,opacity:between(f,28,42,0,1),transform:`scale(${between(f,55,70,1.15,1)})`}}/>
    <div style={{opacity:between(f,70,99,0,1),transform:`translateY(${between(f,70,108,18,0)}px)`}}><Wordmark size={94} lockup={false}/></div>
    <div style={{position:'absolute',top:1070,fontSize:24,letterSpacing:4,color:C.muted,opacity:between(f,86,110,0,1)}}>Worth stopping for.</div>
  </AbsoluteFill>;
};

const Discover = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill><Environment/>
    <Copy kicker="BREAKPOINT / DISCOVER">Find something<br/>worth knowing.</Copy>
    <Phone file="discover-alt-clean.mp4" y={between(f,0,55,1310,1160)} width={680} ry={between(f,0,210,-13,4)} rx={4} rz={between(f,0,200,-4,0)} scale={between(f,0,210,.95,1.03)+between(f,186,210,0,.12)}/>
  </AbsoluteFill>;
};

const Deck = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill><Environment/>
    <Copy kicker="THE SWIPE DECK" size={90}>20 seconds.</Copy>
    <Phone file="deck-clean.mp4" width={780} x={620} y={1220} ry={between(f,0,177,9,-3)} rz={-2} start={30}/>
    {f>95 && <Breakout file="deck-panel.png" width={810} x={between(f,95,140,170,82)} y={between(f,95,148,1100,1060)} opacity={between(f,95,125,0,1)} angle={-3}/>}
  </AbsoluteFill>;
};

const Article = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill><Environment/>
    <Phone file="article-clean.mp4" width={770} x={540} y={1250} ry={between(f,0,78,-7,0)} start={60}/>
    <Copy kicker="THE FULL STORY" size={91}>Or go deeper.</Copy>
  </AbsoluteFill>;
};

const Listen = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill><Environment/>
    <Copy kicker="LISTEN" size={86}>Read it.<br/><span style={{color:f>42?C.bone:C.muted}}>Listen to it.</span></Copy>
    <Phone file="listen-clean.mp4" start={70} width={700} x={490} y={1220} ry={between(f,0,180,-8,5)} rz={2}/>
    <Breakout file="listen-panel.png" width={900} x={90} y={between(f,35,95,1260,1160)} opacity={between(f,35,68,0,1)} angle={-4}/>
    <div style={{position:'absolute',left:110,right:110,top:1570,height:1,background:'#EDE9E033'}}/>
    <Dot size={16} style={{position:'absolute',left:between(f,0,180,110,954),top:1563}}/>
  </AbsoluteFill>;
};

const Spaces = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill><Environment/>
    <Copy kicker="SPACES" size={90}>Learn together.</Copy>
    <Phone file="spaces-clean.mp4" width={695} x={540} y={1150} ry={between(f,0,240,8,-5)} rz={between(f,0,240,2,-1)} start={10}/>
  </AbsoluteFill>;
};

const Connect = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill><Environment/>
    <Copy kicker="CONNECT" size={77}>Talk to people<br/>who get it.</Copy>
    <Breakout file="chat-header.png" width={960} x={60} y={760} angle={-3}/>
    <div style={{position:'absolute',left:60,top:960,width:960,overflow:'hidden',borderRadius:24,border:'1px solid #ffffff18',boxShadow:'0 35px 80px #0009',clipPath:`inset(0 0 ${between(f,0,35,100,0)}% 0)`,transform:`perspective(2000px) rotateY(${between(f,0,240,-3,0)}deg)`}}>
      {f<70 ? <OffthreadVideo muted src={staticFile('footage/connect-detail.mp4')} style={{width:'100%',display:'block'}}/> : <Img src={staticFile('footage/connect-sent-detail.png')} style={{width:'100%',display:'block'}}/>}
    </div>
    <Dot size={18} style={{position:'absolute',left:between(f,0,30,110,952),top:690,opacity:between(f,27,43,1,0)}}/>
  </AbsoluteFill>;
};

const Reels = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill><Environment/>
    <Phone file="reels-clean.mp4" width={between(f,0,100,910,870)} x={540} y={990} ry={between(f,0,180,9,-3)} rz={between(f,0,180,-3,1)}/>
    <div style={{position:'absolute',top:90,left:85,fontSize:23,letterSpacing:5}}>BREAKPOINT / REELS</div>
    <OrangeWipe/>
  </AbsoluteFill>;
};

const Crescendo = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill><Environment/>
    <div style={{position:'absolute',top:165,left:0,right:0}}><Wordmark size={94}/></div>
    <Phone still file="deck-poster.png" width={515} x={between(f,0,75,265,230)} y={1025} ry={18} rz={-9}/>
    <Phone still file="spaces-poster.png" width={515} x={between(f,0,75,810,850)} y={995} ry={-18} rz={9}/>
    <Phone still file="discover-poster.png" width={650} x={540} y={1110} ry={between(f,0,160,-5,0)} scale={between(f,0,162,1.03,1)}/>
    <Breakout file="listen-panel.png" width={700} x={190} y={1530} opacity={between(f,20,60,0,1)}/>
    <div style={{position:'absolute',top:1785,left:0,right:0,textAlign:'center',fontSize:36,letterSpacing:-.5}}>Worth stopping for.</div>
  </AbsoluteFill>;
};

export const EndCard = () => {
  const f = useCurrentFrame();
  return <AbsoluteFill style={{background:C.ink,alignItems:'center',justifyContent:'center'}}>
    <div style={{opacity:between(f,0,25,0,1),transform:`translateY(${between(f,0,40,12,0)}px)`}}><Wordmark size={99}/></div>
    <div style={{marginTop:64,fontSize:42,letterSpacing:-.7,opacity:between(f,15,43,0,1)}}>Worth stopping for.</div>
    <div style={{position:'absolute',bottom:290,fontSize:32,color:C.muted,letterSpacing:.4,opacity:between(f,32,60,0,1)}}>Available on Google Play</div>
    <div style={{position:'absolute',bottom:210,width:44,height:3,background:C.orange}}/>
  </AbsoluteFill>;
};

export const Launch = () => {
  const [fontHandle] = useState(() => delayRender('Load the real brand typeface'));
  useEffect(() => {
    const face = new FontFace('Outfit', `url('${staticFile('Outfit.ttf')}')`, {weight:'100 900'});
    face.load().then(loaded => {
      (document.fonts as FontFaceSet & {add: (font: FontFace) => void}).add(loaded);
      continueRender(fontHandle);
    }).catch(cancelRender);
  }, [fontHandle]);
  return <AbsoluteFill style={{fontFamily:'Outfit',color:C.bone,background:C.ink}}>
    <style>{'*{box-sizing:border-box}'}</style>
    <Audio src={staticFile('soundtrack-master.wav')}/>
    <Sequence from={0} durationInFrames={135}><Intro/></Sequence>
    <Sequence from={135} durationInFrames={210}><Discover/></Sequence>
    <Sequence from={345} durationInFrames={177}><Deck/></Sequence>
    <Sequence from={522} durationInFrames={78}><Article/></Sequence>
    <Sequence from={600} durationInFrames={180}><Listen/></Sequence>
    <Sequence from={780} durationInFrames={240}><Spaces/></Sequence>
    <Sequence from={1020} durationInFrames={240}><Connect/></Sequence>
    <Sequence from={1260} durationInFrames={180}><Reels/></Sequence>
    <Sequence from={1440} durationInFrames={162}><Crescendo/></Sequence>
    <Sequence from={1602} durationInFrames={138}><EndCard/></Sequence>
  </AbsoluteFill>;
};
