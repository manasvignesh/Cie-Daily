const fs=require('fs'),path=require('path'),{execFileSync}=require('child_process');
const root=__dirname,dir=path.join(root,'public/footage');
const localFF=path.resolve(root,'../cie-daily-commercial/.tools/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe');
const ff=process.env.FFMPEG_PATH || (fs.existsSync(localFF)?localFF:'ffmpeg');
function run(args){execFileSync(ff,['-y','-hide_banner','-loglevel','error',...args],{stdio:'inherit'})}
for(const name of ['discover','discover-alt','deck','article','listen','spaces','reels']){
 run(['-i',path.join(dir,name+'.mp4'),'-vf','crop=1080:2080:0:110,tpad=stop_mode=clone:stop_duration=10,fps=60','-t','10','-an','-c:v','libx264','-preset','fast','-crf','17','-pix_fmt','yuv420p',path.join(dir,name+'-clean.mp4')]);
}
// Deliberate macro framing excludes the old test chat history. No UI is rebuilt.
run(['-ss','4','-i',path.join(dir,'connect.mp4'),'-vf','crop=1080:570:0:1620,tpad=stop_mode=clone:stop_duration=8,fps=60','-t','8','-an','-c:v','libx264','-preset','fast','-crf','17',path.join(dir,'connect-detail.mp4')]);
for(const [name,sec]of [['discover',1],['deck',1],['spaces',1]])run(['-ss',String(sec),'-i',path.join(dir,name+'-clean.mp4'),'-frames:v','1',path.join(dir,name+'-poster.png')]);
run(['-ss','3','-i',path.join(dir,'discover-alt-clean.mp4'),'-frames:v','1',path.join(dir,'discover-poster.png')]);
for(const [input,output,crop]of [['deck-end.png','deck-panel.png','950:620:65:780'],['listen-active.png','listen-panel.png','838:197:120:1268'],['chat-sent.png','chat-header.png','1080:148:0:112']])run(['-i',path.join(dir,input),'-vf','crop='+crop,'-frames:v','1',path.join(dir,output)]);
run(['-i',path.join(dir,'chat-sent.png'),'-vf','crop=1080:570:0:1620','-frames:v','1',path.join(dir,'connect-sent-detail.png')]);
console.log('Prepared real-device media; no product pixels synthesized.');
