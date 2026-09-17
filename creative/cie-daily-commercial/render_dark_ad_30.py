"""Expanded 30-second cut. Preserves the original 15-second deliverable."""
import sys, subprocess, json, wave
import numpy as np
from PIL import Image, ImageDraw
import render_dark_ad as core
from render_dark_ad import ROOT, FF, W, H, FPS, WHITE, GRAY, ORANGE, ease, smooth, lerp, text, lines, badge, phone

def caption(im, a, b, y=1710):
    text(im,a,(540,y),34,WHITE)
    text(im,b,(540,y+51),30,GRAY)

def scene(t):
    if t<3: return core.render(t)
    if t>=25: return core.render(11+(t-25)*.8)
    im=core.BASE.copy()
    if t<8:
        u=t-3
        badge(im,'01  /  DISCOVER',186,ease(u/.4))
        lines(im,['Find your next','interesting idea.'],280,73,83,ease(u/.55))
        phone(im,120 if u<2.8 else 126.75+min(.4,(u-2.8)*.2),width=565,
              cy=lerp(1230,1060,ease(u/.9)),angle=lerp(-4,0,ease(u/2)))
        caption(im,'Tech, startups and fresh perspectives.','Choose a story that pulls you in.')
    elif t<13:
        u=t-8
        badge(im,'02  /  SWIPE DECK',186)
        lines(im,['The key ideas.','Without the noise.'],280,72,83)
        # Pause on the real brief so the key points have time to be read.
        phone(im,128.6+min(.35,u*.09),width=590,cy=1060,angle=lerp(1.5,0,smooth(u/5)))
        caption(im,'Scan the essentials. Take in the key facts.','Open the full story when you want more.')
    elif t<18:
        u=t-13
        badge(im,'03  /  FULL STORY',186)
        lines(im,['Go deeper.','Stay curious.'],280,76,86)
        # Two seconds to read the headline, then a controlled view of the real scroll.
        sec=130 if u<2 else 130+min(2.65,(u-2)*.88)
        phone(im,sec,width=590,cy=1060,angle=lerp(-1.5,0,smooth(u/5)))
        caption(im,'Explore the context behind the headline.','Read the details at your own pace.')
    elif t<22:
        u=t-18
        badge(im,'04  /  SPACES — OPENING SOON',186)
        lines(im,['Curiosity is better','together.'],280,72,83)
        phone(im,117,width=575,cy=1060,angle=lerp(1,0,smooth(u/4)))
        caption(im,'Live sessions for curious people.','Listen, ask and discuss. Coming soon.')
    else:
        u=t-22
        badge(im,'CIE DAILY  /  DARK MODE',186)
        lines(im,['Your curiosity.','After dark.'],280,76,86)
        phone(im,120,width=570,cy=1060,angle=0)
        caption(im,'Charcoal tones. Warm text. CIE orange.','A calmer way to discover something new.')
    return im.convert('RGB')

def render(t):
    # Brief editorial dissolves, rather than abrupt one-second feature cuts.
    for cut in [8,13,18,22]:
        if cut<=t<cut+.28:
            return Image.blend(scene(cut-.001),scene(t),smooth((t-cut)/.28))
    return scene(t)

def audio():
    sr=48000; n=30*sr; out=np.zeros(n);rng=np.random.default_rng(43)
    def add(at,sig,gain):
        i=round(at*sr);end=min(n,i+len(sig))
        out[i:end]+=sig[:end-i]*gain
    def tone(f,dur,attack=.02,decay=2):
        t=np.arange(round(sr*dur))/sr
        env=np.minimum(t/attack,1)*np.exp(-decay*t)*np.minimum((dur-t)/.16,1)
        return (np.sin(2*np.pi*f*t)+.18*np.sin(4*np.pi*f*t))*env
    for at in [.15,.6,1.05]:add(at,tone(110,.25,.004,16),.09)
    add(1.65,tone(65.4,.75,.002,7),.3);add(1.65,tone(196,.4,.002,12),.1)
    notes=[220,329.63,440,523.25,392,329.63,261.63,329.63]
    for j,at in enumerate(np.arange(3,25,.625)):
        t=np.arange(round(sr*.28))/sr
        kick=np.sin(2*np.pi*(48*t+45*.03*(1-np.exp(-t/.03))))*np.exp(-t*23)
        add(at,kick,.16)
        add(at,tone(notes[j%8],.8,.015,4),.07)
        noise=rng.normal(0,1,round(sr*.055))
        noise=np.r_[0,np.diff(noise)]*np.exp(-np.arange(len(noise))/sr*85)
        add(at+.3125,noise,.012)
    for at,chord in [(3,[110,164.81,220]),(8,[130.81,196,261.63]),(13,[87.31,130.81,174.61]),(18,[98,146.83,196]),(22,[110,164.81,220])]:
        for f in chord:add(at,tone(f,5,.7,.4),.032)
    for at in [3,8,13,18,22,25]:
        t=np.arange(round(sr*.22))/sr
        add(at,np.sin(2*np.pi*(900*t-1500*t*t))*np.sin(np.pi*t/.22)**2,.023)
    for f in [220,329.63,440]:add(25.1,tone(f,4.8,.1,.65),.055)
    add(28.05,tone(659.25,1.4,.008,3),.08);add(28.35,tone(880,1.5,.008,3),.06)
    out*=np.minimum(np.arange(n)/(sr*.025),1)*np.minimum((n-1-np.arange(n))/(sr*.2),1)
    stereo=np.stack([out,np.r_[np.zeros(240),out[:-240]]*.94],axis=1)
    stereo*=.65/max(np.max(np.abs(stereo)),.65)
    path=ROOT/'original-sound-bed-30s.wav'
    with wave.open(str(path),'wb') as w:
        w.setnchannels(2);w.setsampwidth(2);w.setframerate(sr);w.writeframes((stereo*32767).astype('<i2').tobytes())
    return path

def main():
    core.prepare()
    contact=Image.new('RGB',(1080,1440))
    for j,t in enumerate([2,4,7,9,12,14,17,19,21,23,27,29.5]):
        contact.paste(render(t).resize((270,480)),((j%4)*270,(j//4)*480))
    contact.save(ROOT/'edit-contact-30s.jpg',quality=95)
    if '--preview' in sys.argv:return
    target=ROOT/'CIE-Daily-Dark-Mode-30s.mp4'
    cmd=[str(FF),'-hide_banner','-loglevel','warning','-y','-f','rawvideo','-pix_fmt','rgb24',
         '-s',f'{W}x{H}','-r','30','-i','pipe:0','-i',str(audio()),'-map','0:v','-map','1:a',
         '-c:v','libx264','-preset','medium','-crf','18','-pix_fmt','yuv420p','-r','30',
         '-frames:v','900','-t','30','-c:a','aac','-b:a','192k','-ar','48000',
         '-af','loudnorm=I=-16:TP=-1.5:LRA=7','-movflags','+faststart',str(target)]
    p=subprocess.Popen(cmd,stdin=subprocess.PIPE)
    try:
        for i in range(900):
            p.stdin.write(render(i/30).tobytes())
            if i%90==0:print(f'Rendered {i}/900',flush=True)
        p.stdin.close()
        if p.wait()!=0:raise RuntimeError('Encoder failed')
    except BaseException:p.kill();raise
    (ROOT/'render-manifest-30s.json').write_text(json.dumps({
        'duration':30,'frames':900,'fps':30,'resolution':[1080,1920],'source':str(core.SOURCE),
        'sourceAudioUsed':False,'voiceover':False,'original15SecondCutPreserved':True,
        'chapters':{'0-3':'Problem','3-8':'Discover','8-13':'Swipe Deck','13-18':'Full Story',
                    '18-22':'Spaces — Opening soon','22-25':'Dark mode','25-30':'Brand / CTA'},
        'output':str(target)},indent=2),encoding='utf-8')
    print(f'FINISHED: {target}',flush=True)

if __name__=='__main__':main()
