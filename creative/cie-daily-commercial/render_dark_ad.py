"""Render the 15-second dark-mode commercial from the supplied real app video.

No generative UI, stock music, original recording audio, or app source changes.
Usage: python render_dark_ad.py [--preview]
"""
from pathlib import Path
import sys, math, subprocess, wave, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parent
FF = ROOT / '.tools/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
SOURCE = Path(r'C:\Users\Manas\Downloads\WhatsApp Video 2026-09-07 at 3.51.48 PM.mp4')
LOGO = ROOT.parents[1] / 'app/assets/icons/app_logo.png'
W, H, FPS = 1080, 1920, 30
ORANGE = (255, 90, 31)
WHITE = (245, 245, 247)
GRAY = (150, 151, 160)
FONTS = Path('C:/Windows/Fonts')
FONT_CACHE = {}

def font(size, bold=False):
    key = (size, bold)
    if key not in FONT_CACHE:
        FONT_CACHE[key] = ImageFont.truetype(str(FONTS / ('segoeuib.ttf' if bold else 'segoeui.ttf')), size)
    return FONT_CACHE[key]

def ease(x):
    x = max(0., min(1., x))
    return 1 - (1-x)**3

def smooth(x):
    x = max(0., min(1., x))
    return x*x*(3-2*x)

def lerp(a,b,t): return a+(b-a)*t

def text(im, s, xy, size, color=WHITE, bold=False, anchor='mm', alpha=1):
    layer = Image.new('RGBA', im.size)
    ImageDraw.Draw(layer).text(xy,s,font=font(size,bold),fill=(*color,int(255*max(0,min(1,alpha)))),anchor=anchor,stroke_width=0)
    im.alpha_composite(layer)

def lines(im, strings, y, size, gap=None, alpha=1):
    for i,s in enumerate(strings):
        text(im,s,(540,y+i*(gap or size*1.1)),size,bold=True,alpha=alpha)

def badge(im, s, y, alpha=1):
    text(im,s,(540,y),24,ORANGE,bold=True,alpha=alpha)

def base():
    yy,xx=np.mgrid[0:H,0:W]
    light=np.exp(-(((xx-580)/650)**2+((yy-830)/1050)**2))
    arr=np.empty((H,W,3),dtype=np.uint8)
    for c,v in enumerate([9,10,13]): arr[:,:,c]=v+light*([14,14,16][c])
    return Image.fromarray(arr).convert('RGBA')

BASE=base()
SCREEN_CACHE={}

def prepare():
    directory=ROOT/'frames'
    directory.mkdir(exist_ok=True)
    # Only the dark-mode, non-private tail is decoded into the working edit.
    if not (directory/'0569.jpg').exists():
        subprocess.run([str(FF),'-loglevel','error','-ss','116','-i',str(SOURCE),'-t','19',
                        '-vf','fps=30','-start_number','0','-q:v','2','-y',str(directory/'%04d.jpg')],check=True)

def screen(sec):
    idx=max(0,min(569,int(round((sec-116)*30))))
    if idx not in SCREEN_CACHE:
        # Remove Android recording status, system navigation, and recorder's right-edge dot.
        SCREEN_CACHE[idx]=Image.open(ROOT/'frames'/f'{idx:04d}.jpg').convert('RGB').crop((0,40,380,795))
    return SCREEN_CACHE[idx]

def phone(im, sec, width=530, cx=540, cy=1040, angle=0, opacity=1):
    sw,sh=500,994
    pw,ph=540,1060
    p=Image.new('RGBA',(pw+100,ph+100))
    d=ImageDraw.Draw(p)
    # Device is a deliberately understated motion-graphics mockup, not AI footage.
    d.rounded_rectangle((48,49,pw+50,ph+51),radius=67,fill=(41,43,49),outline=(94,96,102),width=2)
    d.rounded_rectangle((52,52,pw+46,ph+47),radius=64,fill=(5,6,8),outline=(58,60,65),width=2)
    d.rounded_rectangle((44,212,50,287),radius=3,fill=(90,91,98))
    d.rounded_rectangle((44,312,50,407),radius=3,fill=(72,74,82))
    d.rounded_rectangle((pw+48,265,pw+54,400),radius=3,fill=(91,92,98))
    sc=screen(sec).resize((sw,sh),Image.Resampling.LANCZOS).convert('RGBA')
    mask=Image.new('L',(sw,sh)); ImageDraw.Draw(mask).rounded_rectangle((0,0,sw-1,sh-1),radius=46,fill=255)
    p.paste(sc,(70,79),mask)
    # The camera/speaker is outside the captured app area.
    d=ImageDraw.Draw(p)
    d.rounded_rectangle((pw/2+15,61,pw/2+85,66),radius=3,fill=(57,58,63))
    d.line((80,72,155,58),fill=(140,141,148,135),width=2)
    factor=width/pw
    p=p.resize((round(p.width*factor),round(p.height*factor)),Image.Resampling.LANCZOS)
    if angle: p=p.rotate(angle,Image.Resampling.BICUBIC,expand=True)
    if opacity<1: p.putalpha(p.getchannel('A').point(lambda a:int(a*opacity)))
    x,y=round(cx-p.width/2),round(cy-p.height/2)
    # Grounding shadow follows the same geometry, no glowing halo.
    shadow=Image.new('RGBA',p.size,(0,0,0,0))
    shadow.putalpha(p.getchannel('A').point(lambda a:int(a*.6)))
    shadow=shadow.filter(ImageFilter.GaussianBlur(23))
    im.alpha_composite(shadow,(x+10,y+32)); im.alpha_composite(p,(x,y))

def brand(im, y=1180, scale=1, alpha=1):
    icon=Image.open(LOGO).convert('RGBA')
    size=round(94*scale)
    icon.thumbnail((size,size),Image.Resampling.LANCZOS)
    # Keep the supplied official asset intact; no recoloring/redrawing.
    if alpha<1: icon.putalpha(icon.getchannel('A').point(lambda a:int(a*alpha)))
    lockup_w=round(462*scale)
    im.alpha_composite(icon,(round((W-lockup_w)/2),round(y-size/2)))
    text(im,'CIE Daily',(round((W-lockup_w)/2+size+24*scale),y),round(66*scale),bold=True,anchor='lm',alpha=alpha)

def render(t):
    im=BASE.copy()
    if t<3:
        # Abstract editorial motion, not a fabricated social-media UI.
        active=min(t,1.65)
        d=ImageDraw.Draw(im)
        for j in range(13):
            y=int((j*154-active*480)%2100-100)
            x=75+((j%3)*28)
            d.rounded_rectangle((x,y,1005-x//3,y+5),radius=2,fill=(38,39,45))
            text(im,['MORE.','NEXT.','SCROLL.'][j%3],(x,y+59),70,(42,43,51),bold=True,anchor='lm')
        dark=Image.new('RGBA',(W,H),(5,6,8,100));im.alpha_composite(dark)
        a=ease((t-.35)/.65)
        badge(im,'CIE DAILY',660,a)
        lines(im,['Too much','noise?'],815,108,112,a)
        if t>1.65:
            d=ImageDraw.Draw(im)
            length=int(176*ease((t-1.65)/.35))
            d.rounded_rectangle((540-length//2,1073,540+length//2,1078),radius=2,fill=ORANGE)
        text(im,'Make room for something better.',(540,1180),34,GRAY,alpha=ease((t-1.9)/.35))
        # Tight dark dip before the product arrives.
        if t>2.8: im.alpha_composite(Image.new('RGBA',(W,H),(8,9,12,int(220*smooth((t-2.8)/.2)))))
    elif t<7:
        u=t-3
        badge(im,'MEET CIE DAILY  /  DARK MODE',190,ease(u/.35))
        lines(im,['Discover what','actually matters.'],287,73,83,ease(u/.5))
        # An intentional settling reveal followed by the user's actual deck interaction.
        sec=119.95 if u<1.0 else min(122.5,120+(u-1)*.85)
        phone(im,sec,width=lerp(575,552,smooth(u/4)),cy=lerp(1280,1087,ease(u/.75)),angle=lerp(-5,0,ease(u/2)))
        text(im,'Less glare. More discovery.',(540,1755),34,GRAY,alpha=ease((u-.7)/.45))
    elif t<8:
        u=t-7
        badge(im,'SWIPE DECK',196)
        lines(im,['Tech.'],310,102)
        phone(im,127.1+u*.65,width=590,cy=1100,angle=lerp(2,-1,smooth(u)))
        text(im,'A fresh perspective. One swipe away.',(540,1760),32,GRAY)
    elif t<9:
        u=t-8
        badge(im,'FULL STORY',196)
        lines(im,['Ideas.'],310,102)
        phone(im,130+u*.4,width=590,cy=1100,angle=lerp(-2,0,smooth(u)))
        text(im,'Go beyond the headline.',(540,1760),34,GRAY)
    elif t<10:
        u=t-9
        badge(im,'SPACES  /  OPENING SOON',196)
        lines(im,['People.'],310,102)
        # Clean, honest paused capture: no invented live session or participant data.
        phone(im,117.0,width=575,cy=1100,angle=lerp(1,-1,smooth(u)))
        text(im,'For curious people.',(540,1760),34,GRAY)
    elif t<11:
        u=t-10
        badge(im,'CIE DAILY',196)
        lines(im,['One place.'],310,96)
        phone(im,120,width=570,cy=1100,angle=lerp(-1,0,smooth(u)))
        text(im,'Built for your curiosity.',(540,1760),34,GRAY)
    else:
        u=t-11
        move=ease(u/.85)
        phone(im,120,width=lerp(570,380,move),cy=lerp(1100,660,move),angle=0)
        a=ease((u-.5)/.45)
        brand(im,1215,1,a)
        text(im,'Stay curious. Stay ahead.',(540,1360),46,WHITE,alpha=ease((u-.9)/.45))
        text(im,'Discover CIE Daily in dark mode.',(540,1442),29,GRAY,alpha=ease((u-1.2)/.4))
        c=ease((u-1.45)/.4)
        layer=Image.new('RGBA',(W,H));d=ImageDraw.Draw(layer)
        d.rounded_rectangle((320,1546,760,1640),radius=47,fill=(*ORANGE,int(255*c)))
        im.alpha_composite(layer)
        text(im,'Download now',(540,1591),36,(15,15,18),True,alpha=c)
    return im.convert('RGB')

def audio():
    sr=48000; n=sr*15; out=np.zeros(n,dtype=np.float64)
    rng=np.random.default_rng(23)
    def add(start,sig,gain=1):
        i=round(start*sr); end=min(n,i+len(sig))
        if end>i: out[i:end]+=sig[:end-i]*gain
    def tone(freq,dur,attack=.02,decay=2):
        tt=np.arange(round(dur*sr))/sr
        env=np.minimum(tt/attack,1)*np.exp(-decay*tt)*np.minimum((dur-tt)/.12,1)
        return (np.sin(2*np.pi*freq*tt)+.22*np.sin(2*np.pi*freq*2*tt))*env
    # Original restrained A-minor electronic bed; no sampled/copyrighted recording.
    for at in [.15,.6,1.05]: add(at,tone(110,.25,.004,16),.11)
    add(1.65,tone(65.4,.72,.002,7),.4)
    add(1.65,tone(196,.4,.002,12),.13)
    for at in np.arange(3,11,.5):
        tt=np.arange(int(sr*.26))/sr
        env=np.exp(-tt*23)
        kick=np.sin(2*np.pi*(48*tt+45*.03*(1-np.exp(-tt/.03))))*env
        add(at,kick,.24)
        noise=rng.normal(0,1,int(sr*.06))
        noise=np.concatenate(([0],np.diff(noise)))*np.exp(-np.arange(len(noise))/sr*85)
        add(at+.25,noise,.018)
    notes=[220,329.63,440,523.25,392,329.63,261.63,329.63]
    for j,at in enumerate(np.arange(3,11,.5)): add(at,tone(notes[j%8],.65,.008,5),.075)
    for f in [110,164.81,220]: add(3,tone(f,7.8,.7,.28),.035)
    # Short swipe/cut accents, quiet enough for phone speakers.
    for at in [3,7,8,9,10,11]:
        tt=np.arange(int(sr*.18))/sr
        add(at,np.sin(2*np.pi*(900*tt-1600*tt**2))*np.sin(np.pi*tt/.18)**2,.027)
    for f in [220,329.63,440]:add(11.1,tone(f,3.7,.1,.9),.06)
    add(13.62,tone(659.25,.85,.008,4),.09)
    add(13.87,tone(880,1.03,.008,4),.07)
    out*=np.minimum(np.arange(n)/(sr*.025),1)*np.minimum((n-1-np.arange(n))/(sr*.12),1)
    # Stereo with a tiny original ambient offset; strictly limited below clipping.
    stereo=np.stack([out,np.concatenate((np.zeros(240),out[:-240]))*.94],axis=1)
    peak=np.max(np.abs(stereo));stereo*=.65/max(peak,.65)
    p=ROOT/'original-sound-bed.wav'
    with wave.open(str(p),'wb') as w:
        w.setnchannels(2);w.setsampwidth(2);w.setframerate(sr);w.writeframes((stereo*32767).astype('<i2').tobytes())
    return p

def main():
    prepare()
    times=[0.9,2.2,3.8,5.5,7.5,8.5,9.5,10.5,11.9,13,14,14.9]
    contact=Image.new('RGB',(1080,1920))
    for j,t in enumerate(times):
        frame=render(t)
        frame.save(ROOT/f'preview-{t:04.1f}.jpg',quality=94)
        thumb=frame.resize((270,480),Image.Resampling.LANCZOS)
        contact.paste(thumb,((j%4)*270,(j//4)*480))
    contact=contact.crop((0,0,1080,1440));contact.save(ROOT/'edit-contact.jpg',quality=94)
    if '--preview' in sys.argv:return
    sound=audio()
    target=ROOT/'CIE-Daily-Dark-Mode-15s.mp4'
    cmd=[str(FF),'-hide_banner','-loglevel','warning','-y','-f','rawvideo','-vcodec','rawvideo',
         '-pix_fmt','rgb24','-s',f'{W}x{H}','-r',str(FPS),'-i','pipe:0','-i',str(sound),
         '-map','0:v','-map','1:a','-c:v','libx264','-preset','medium','-crf','18',
         '-pix_fmt','yuv420p','-r','30','-frames:v','450','-t','15','-c:a','aac','-b:a','192k',
         '-af','loudnorm=I=-16:TP=-1.5:LRA=7','-ar','48000','-movflags','+faststart',
         '-color_primaries','bt709','-color_trc','bt709','-colorspace','bt709',str(target)]
    proc=subprocess.Popen(cmd,stdin=subprocess.PIPE)
    try:
        for i in range(450):
            proc.stdin.write(render(i/FPS).tobytes())
            if i%30==0:print(f'Rendered {i}/450 frames',flush=True)
        proc.stdin.close()
        if proc.wait()!=0:raise RuntimeError('Encoder failed')
    except BaseException:
        proc.kill();raise
    (ROOT/'render-manifest.json').write_text(json.dumps({
        'output':str(target),'durationSeconds':15,'frames':450,'fps':30,'width':1080,'height':1920,
        'source':str(SOURCE),'sourceResolution':'390x850','sourceAudioUsed':False,
        'voiceover':False,'audio':'Original synthesized instrumental and sound effects',
        'ui':'Actual dark-mode footage; system bars cropped. Spaces remains Opening soon.',
        'sourceTimeRangesSeconds':[[117,117],[119.95,122.5],[127.1,127.75],[130,130.4]],
        'style':'Dark-mode product motion graphics; no photorealistic generated footage',
        'logo':str(LOGO)},indent=2),encoding='utf-8')
    print(f'FINISHED: {target}',flush=True)

if __name__=='__main__':main()
