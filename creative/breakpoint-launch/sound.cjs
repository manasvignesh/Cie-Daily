// Original score. Pure synthesis, no samples, stock music or third-party recordings.
const fs=require('fs'); const path=require('path');
const rate=48000,duration=29,N=rate*duration,channels=[new Float64Array(N),new Float64Array(N)];
let seed=72;const rnd=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296*2-1};
function add(at,len,fn,amp=.2,pan=0){for(let i=0;i<len*rate;i++){let j=Math.round(at*rate)+i;if(j>=N)break;let v=fn(i/rate)*amp;channels[0][j]+=v*Math.sqrt((1-pan)/2);channels[1][j]+=v*Math.sqrt((1+pan)/2)}}
function impact(t,a=.3){add(t,.8,x=>Math.sin(2*Math.PI*(47*x+25*(1-Math.exp(-x*26))/26))*Math.exp(-x*9),a);add(t,.07,x=>rnd()*Math.exp(-x*95),a*.2)}
function tone(t,f,a=.1,len=.7,pan=0){add(t,len,x=>(Math.sin(2*Math.PI*f*x)+.16*Math.sin(2*Math.PI*f*2*x))*Math.min(1,x*100)*Math.exp(-x*5),a,pan)}
function air(t,len=.3,a=.025){let lp=0;add(t,len,x=>{lp=lp*.86+rnd()*.14;return lp*Math.sin(Math.PI*x/len)},a)}
// The interruption is mostly silent. Impact lands exactly at the dot stop.
tone(.3,1700,.018,.08,-.4);tone(.61,2100,.015,.08,.4);impact(55/60,.38);
for(const t of [2.25,5.75,10,13,17,21,24,26.7]){impact(t,t===21?.36:.24);air(t-.14,.3,.09)}
// A restrained D minor suspended bed. No melody competing with the product.
for(const t of [2.25,6.25,10.25,14.25,18.25,22.25])for(const [k,f]of [146.83,220,293.66,329.63].entries())add(t,4.5,x=>Math.sin(2*Math.PI*f*x+Math.sin(x*.9)*.08)*Math.min(x/1.2,1)*Math.min((4.5-x)/1.2,1),.026,k%2?.5:-.5);
for(let t=3.25;t<26.5;t+=.5){const q=Math.round((t-3.25)*2);if(q%4===0)impact(t,.10);if(q%2===1)tone(t,[587.33,440,659.25,880][q%4],.035,.28,q%3===0?-.4:.4);if(t>20)air(t,.06,.06)}
tone(10.12,587.33,.13,.65,-.25);tone(10.37,880,.08,.55,.25);
tone(18.5,880,.12,.4);tone(18.64,1174.66,.075,.4,.25);
tone(26.9,293.66,.16,1.5,-.2);tone(27.12,440,.11,1.5,.2);tone(27.35,587.33,.08,1.4);
let peak=0;for(let i=0;i<N;i++)for(let c=0;c<2;c++){channels[c][i]*=Math.min(1,(N-i)/(rate*.35));peak=Math.max(peak,Math.abs(channels[c][i]))}
const b=Buffer.alloc(44+N*4);b.write('RIFF');b.writeUInt32LE(b.length-8,4);b.write('WAVEfmt ',8);b.writeUInt32LE(16,16);b.writeUInt16LE(1,20);b.writeUInt16LE(2,22);b.writeUInt32LE(rate,24);b.writeUInt32LE(rate*4,28);b.writeUInt16LE(4,32);b.writeUInt16LE(16,34);b.write('data',36);b.writeUInt32LE(N*4,40);
for(let i=0;i<N;i++)for(let c=0;c<2;c++)b.writeInt16LE(Math.round(channels[c][i]/peak*.76*32767),44+i*4+c*2);
fs.writeFileSync(path.join(__dirname,'public','soundtrack.wav'),b);console.log('Original 29s stereo score; peak -2.4 dBFS');
