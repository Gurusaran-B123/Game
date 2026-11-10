#!/usr/bin/env python3
"""Generates the PLACEHOLDER art + sounds for Deplo Hatch.
Replace any file in assets/ with your own (same file name) - no code change needed.
Run:  python3 tools/make_assets.py   (needs: pillow, numpy, ffmpeg)
"""
import math, os, subprocess, wave
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
IMG = os.path.join(ROOT, "assets/images"); AUD = os.path.join(ROOT, "assets/audio")
os.makedirs(IMG, exist_ok=True); os.makedirs(AUD, exist_ok=True)
SS = 3  # supersample

def canvas(w, h): return Image.new("RGBA", (w*SS, h*SS), (0,0,0,0))
def fin(im, w, h): return im.resize((w, h), Image.LANCZOS)
def S(v): return [int(x*SS) for x in v]
def shade(c, f): return tuple(max(0, min(255, int(x*f))) for x in c[:3]) + (255,)

# ---------------------------------------------------------------- eggs
EGGS = {  # name: (colour, pattern)
 "white": ((250,248,240), "none"), "brown": ((176,112,64), "dots"),
 "yellow": ((255,236,140), "none"), "blue": ((70,120,235), "dots"),
 "green": ((80,190,90), "stripes"), "teal": ((30,170,170), "zig"),
 "lightblue": ((170,215,250), "dots"), "skyblue": ((90,185,245), "stripes"),
 "red": ((235,60,60), "dots"), "orange": ((255,150,40), "stripes"),
 "black": ((50,50,60), "zig"),
}
def egg_pts(cx, cy, a, b, n=120):
    pts = []
    for i in range(n):
        t = 2*math.pi*i/n
        pts.append(((cx + a*math.sin(t)*(1-0.16*math.cos(t)))*SS, (cy - b*math.cos(t))*SS))
    return pts

def make_egg(name, col, pat):
    W, H = 220, 270
    im = canvas(W, H); d = ImageDraw.Draw(im)
    d.polygon(egg_pts(W/2+4, H/2+8, 88, 118), fill=(0,0,0,50))      # shadow
    pts = egg_pts(W/2, H/2, 88, 118)
    d.polygon(pts, fill=shade(col, 0.72))
    inner = Image.new("RGBA", im.size, (0,0,0,0)); di = ImageDraw.Draw(inner)
    di.polygon(egg_pts(W/2, H/2, 82, 112), fill=col+(255,) if len(col)==3 else col)
    dk = shade(col, 0.82)
    if pat == "dots":
        for x, y, r in [(80,120,9),(130,100,7),(110,170,10),(150,160,6),(75,185,6),(120,130,5)]:
            di.ellipse(S((x-r,y-r,x+r,y+r)), fill=dk)
    elif pat == "stripes":
        for y in (110, 150, 190):
            di.rectangle(S((0,y,W,y+14)), fill=dk)
    elif pat == "zig":
        for y in (115, 175):
            pts2 = []
            for i in range(0, 12):
                pts2.append(S((20+i*15, y + (14 if i%2 else 0))))
            di.line(pts2, fill=dk, width=7*SS)
    mask = Image.new("L", im.size, 0); ImageDraw.Draw(mask).polygon(egg_pts(W/2, H/2, 82, 112), fill=255)
    im.paste(inner, (0,0), mask)
    d = ImageDraw.Draw(im)
    d.ellipse(S((64,60,96,110)), fill=(255,255,255,120))            # highlight
    fin(im, W, H).save(os.path.join(IMG, f"egg_{name}.png"))
for k, (c, p) in EGGS.items(): make_egg(k, c, p)

# ---------------------------------------------------------------- nest
def make_nest():
    W, H = 300, 190
    im = canvas(W, H); d = ImageDraw.Draw(im)
    d.ellipse(S((10,40,290,180)), fill=(110,70,35,255))
    d.ellipse(S((22,28,278,150)), fill=(150,100,52,255))
    d.ellipse(S((46,42,254,134)), fill=(95,58,28,255))           # hollow
    import random; random.seed(4)
    for _ in range(90):
        a = random.uniform(0, 2*math.pi); r = random.uniform(0.82, 1.0)
        x = 150 + 128*r*math.cos(a); y = 90 + 62*r*math.sin(a)
        l = random.uniform(24, 44); b = a + random.uniform(-0.5, 0.5) + math.pi/2
        d.line(S((x, y, x+l*math.cos(b), y+l*0.45*math.sin(b))),
               fill=random.choice([(205,160,90,255),(180,130,70,255),(225,190,120,255)]), width=4*SS)
    fin(im, W, H).save(os.path.join(IMG, "nest.png"))
make_nest()

# ---------------------------------------------------------------- animals (256x256)
def eye(d, x, y, r=11):
    d.ellipse(S((x-r,y-r,x+r,y+r)), fill=(255,255,255,255))
    d.ellipse(S((x-r*.55,y-r*.5,x+r*.55,y+r*.6)), fill=(30,30,40,255))
    d.ellipse(S((x-r*.3,y-r*.5,x,y-r*.1)), fill=(255,255,255,255))

def chick():
    im = canvas(256,256); d = ImageDraw.Draw(im)
    d.ellipse(S((70,225,190,245)), fill=(0,0,0,40))
    for x in (100,148): d.line(S((x,208,x,236)), fill=(255,150,30,255), width=7*SS); d.polygon(S((x-14,238,x+14,238,x,224)), fill=(255,150,30,255))
    d.ellipse(S((38,50,218,222)), fill=(255,214,40,255))
    d.ellipse(S((52,66,204,210)), fill=(255,230,90,255))
    d.ellipse(S((28,120,84,180)), fill=(255,196,20,255)); d.ellipse(S((172,120,228,180)), fill=(255,196,20,255))
    d.polygon(S((112,100,144,100,128,122)), fill=(255,140,30,255))
    eye(d,98,92,13); eye(d,158,92,13)
    d.ellipse(S((70,106,92,122)), fill=(255,150,140,170)); d.ellipse(S((164,106,186,122)), fill=(255,150,140,170))
    for dx in (-10,0,10): d.line(S((128,52,128+dx*1.6,28)), fill=(255,180,20,255), width=5*SS)
    return im
def peacock():
    im = canvas(256,256); d = ImageDraw.Draw(im)
    for i in range(9):
        a = math.radians(200 + i*17.5); x = 128+92*math.cos(a); y = 170+92*math.sin(a)
        d.line(S((128,170,x,y)), fill=(20,120,90,255), width=8*SS)
        d.ellipse(S((x-20,y-24,x+20,y+24)), fill=(30,170,120,255))
        d.ellipse(S((x-12,y-15,x+12,y+15)), fill=(40,100,220,255)); d.ellipse(S((x-5,y-7,x+5,y+7)), fill=(255,210,50,255))
    d.ellipse(S((78,140,178,228)), fill=(40,110,230,255)); d.ellipse(S((92,160,164,224)), fill=(90,160,250,255))
    for x in (106,150): d.line(S((x,222,x,242)), fill=(240,170,50,255), width=6*SS)
    d.ellipse(S((92,84,164,156)), fill=(40,110,230,255))
    d.line(S((128,86,128,56)), fill=(50,50,60,255), width=3*SS)
    for dx in (-14,0,14): d.line(S((128,84,128+dx,58)), fill=(50,50,60,255), width=3*SS); d.ellipse(S((128+dx-5,50,128+dx+5,62)), fill=(60,200,130,255))
    d.polygon(S((120,118,136,118,128,132)), fill=(255,190,40,255)); eye(d,108,108,9); eye(d,148,108,9)
    return im
def penguin():
    im = canvas(256,256); d = ImageDraw.Draw(im)
    d.ellipse(S((60,226,196,246)), fill=(0,0,0,40))
    d.polygon(S((88,236,120,236,104,218)), fill=(255,150,30,255)); d.polygon(S((136,236,168,236,152,218)), fill=(255,150,30,255))
    d.ellipse(S((56,40,200,230)), fill=(40,50,80,255))
    d.ellipse(S((82,92,174,220)), fill=(250,250,255,255))
    d.ellipse(S((34,110,80,190)), fill=(30,40,70,255)); d.ellipse(S((176,110,222,190)), fill=(30,40,70,255))
    d.ellipse(S((70,62,186,150)), fill=(250,250,255,255)); d.ellipse(S((68,40,188,120)), fill=(40,50,80,255)); d.ellipse(S((86,70,170,140)), fill=(250,250,255,255))
    eye(d,106,88,11); eye(d,150,88,11)
    d.polygon(S((112,104,144,104,128,126)), fill=(255,160,30,255))
    d.ellipse(S((84,104,102,118)), fill=(255,150,150,150)); d.ellipse(S((154,104,172,118)), fill=(255,150,150,150))
    return im
def dragon():
    im = canvas(256,256); d = ImageDraw.Draw(im)
    d.ellipse(S((60,226,200,246)), fill=(0,0,0,50))
    d.polygon(S((60,130,4,70,30,150,6,170,70,170)), fill=(140,20,30,255)); d.polygon(S((196,130,252,70,226,150,250,170,186,170)), fill=(140,20,30,255))
    d.polygon(S((170,200,236,222,246,196,214,206,200,170)), fill=(200,40,40,255))   # tail
    d.ellipse(S((56,80,200,232)), fill=(215,45,45,255)); d.ellipse(S((86,130,170,226)), fill=(255,205,110,255))
    for y in (140,160,180,200): d.line(S((100,y,156,y)), fill=(235,170,80,255), width=3*SS)
    for x in (100,128,156): d.polygon(S((x-12,86,x+12,86,x,58)), fill=(255,150,40,255))
    d.polygon(S((82,70,98,22,116,66)), fill=(250,235,200,255)); d.polygon(S((174,70,158,22,140,66)), fill=(250,235,200,255))
    d.ellipse(S((74,62,182,160)), fill=(225,55,55,255))
    d.ellipse(S((104,110,152,150)), fill=(245,100,90,255)); d.ellipse(S((114,122,122,132)), fill=(90,20,20,255)); d.ellipse(S((134,122,142,132)), fill=(90,20,20,255))
    eye(d,102,96,12); eye(d,154,96,12)
    for x in (96,160): d.ellipse(S((x-10,214,x+10,236)), fill=(180,30,35,255))
    return im
for n, f in [("chick",chick),("peacock",peacock),("penguin",penguin),("dragon",dragon)]:
    fin(f(),256,256).save(os.path.join(IMG, f"animal_{n}.png"))

# ---------------------------------------------------------------- backgrounds 540x960
def grad(w, h, top, bot):
    a = np.linspace(0,1,h)[:,None,None]
    arr = (np.array(top)[None,None,:]*(1-a) + np.array(bot)[None,None,:]*a)
    arr = np.repeat(arr, w, axis=1).astype(np.uint8)
    return Image.fromarray(arr, "RGB").convert("RGBA")
W, H = 540, 960
def bg_farm():
    im = grad(W,H,(140,215,255),(215,245,255)); d = ImageDraw.Draw(im)
    for x,y in [(80,120),(380,90),(260,200)]:
        for dx,dy,r in [(0,0,34),(32,8,28),(-30,10,26),(10,-14,24)]: d.ellipse((x+dx-r,y+dy-r,x+dx+r,y+dy+r), fill=(255,255,255,255))
    d.ellipse((-150,330,420,700), fill=(120,200,90,255)); d.ellipse((200,380,760,760), fill=(100,185,80,255))
    d.rectangle((0,560,W,H), fill=(130,205,95,255)); d.rectangle((0,700,W,H), fill=(150,215,100,255))
    d.rectangle((330,330,500,470), fill=(200,60,50,255)); d.polygon(((315,335),(415,260),(515,335)), fill=(150,40,35,255)); d.rectangle((388,390,442,470), fill=(250,240,220,255))
    for x in range(0,W,60): d.rectangle((x,520,x+12,590), fill=(180,130,80,255))
    d.rectangle((0,538,W,550), fill=(200,150,95,255)); d.rectangle((0,565,W,575), fill=(200,150,95,255))
    return im
def bg_forest():
    im = grad(W,H,(150,225,200),(60,150,100)); d = ImageDraw.Draw(im)
    d.rectangle((0,0,W,60), fill=(40,110,70,255))
    d.polygon(((0,160),(220,60),(540,150),(540,520),(0,520)), fill=(90,120,110,255))   # rock
    d.rectangle((240,60,330,560), fill=(190,235,255,255)); d.rectangle((255,60,275,560), fill=(240,252,255,255))   # waterfall
    d.ellipse((170,520,400,620), fill=(150,215,245,255))
    for x in (40,130,430,500):
        d.rectangle((x-12,380,x+12,700), fill=(90,60,35,255)); d.ellipse((x-70,230,x+70,440), fill=(35,130,70,255)); d.ellipse((x-50,170,x+50,330), fill=(50,160,85,255))
    d.rectangle((0,640,W,H), fill=(70,160,80,255)); d.rectangle((0,760,W,H), fill=(60,145,72,255))
    return im
def bg_ice():
    im = grad(W,H,(150,200,245),(235,248,255)); d = ImageDraw.Draw(im)
    for x,y,s in [(60,90,5),(300,60,4),(450,200,6),(180,260,4),(500,40,3)]: d.ellipse((x,y,x+s*2,y+s*2), fill=(255,255,255,255))
    d.polygon(((0,520),(130,300),(240,460),(330,330),(460,480),(540,380),(540,560),(0,560)), fill=(190,225,250,255))
    d.polygon(((130,300),(170,380),(110,400)), fill=(225,242,255,255)); d.polygon(((330,330),(370,400),(300,410)), fill=(225,242,255,255))
    d.rectangle((0,540,W,H), fill=(215,238,252,255)); d.rectangle((0,700,W,H), fill=(190,225,248,255))
    d.ellipse((60,780,260,850), fill=(165,210,240,255)); d.ellipse((300,820,500,890), fill=(165,210,240,255))
    return im
def bg_volcano():
    im = grad(W,H,(60,15,25),(190,70,35)); d = ImageDraw.Draw(im)
    d.ellipse((120,40,420,300), fill=(110,40,35,150))
    d.polygon(((60,620),(210,230),(330,230),(480,620)), fill=(60,35,35,255)); d.polygon(((200,230),(340,230),(300,250),(240,250)), fill=(255,120,30,255))
    d.polygon(((250,250),(235,420),(270,330),(290,500),(300,300)), fill=(255,140,40,255))
    for x,y,r in [(180,150,10),(330,110,8),(280,60,12),(410,190,7)]: d.ellipse((x-r,y-r,x+r,y+r), fill=(255,170,60,255))
    d.polygon(((0,520),(120,420),(200,560),(0,620)), fill=(45,28,30,255)); d.polygon(((540,500),(440,400),(380,560),(540,640)), fill=(45,28,30,255))
    d.rectangle((0,610,W,H), fill=(50,28,28,255)); d.rectangle((0,760,W,H), fill=(38,22,24,255))
    for pts in [((40,700),(160,720),(260,700)),((300,820),(420,840),(520,810))]:
        d.line(pts, fill=(255,130,30,255), width=7)
    return im
for n,f in [("farm",bg_farm),("forest",bg_forest),("ice",bg_ice),("volcano",bg_volcano)]:
    f().convert("RGB").save(os.path.join(IMG, f"bg_{n}.jpg"), quality=88)

# icon
ic = Image.new("RGBA",(512,512),(255,196,60,255)); ImageDraw.Draw(ic).ellipse((-100,-100,612,612), fill=(255,170,40,255))
egg = Image.open(os.path.join(IMG,"egg_white.png")).resize((300,368)); ic.alpha_composite(egg,(106,70))
ImageDraw.Draw(ic).polygon([(256,250),(300,300),(270,320),(256,290),(240,330),(215,300)], fill=(255,190,60,255))
ic.convert("RGB").save(os.path.join(IMG,"icon.png"))

# ---------------------------------------------------------------- audio
SR = 22050
def tone(f, d, wave_="sine", vol=0.5, a=0.01, r=0.1):
    t = np.arange(int(SR*d))/SR
    ph = 2*np.pi*(f if np.isscalar(f) else np.cumsum(np.interp(t, np.linspace(0,d,len(f)), f))/SR*1.0)*(t if np.isscalar(f) else 1)
    if not np.isscalar(f): ph = 2*np.pi*np.cumsum(np.interp(t, np.linspace(0,d,len(f)), f))/SR
    s = {"sine":np.sin(ph), "tri":2/np.pi*np.arcsin(np.sin(ph)), "sq":np.sign(np.sin(ph))*0.6, "saw":2*((ph/(2*np.pi))%1)-1}[wave_]
    env = np.minimum(1, t/max(a,1e-4)) * np.minimum(1, (d-t)/max(r,1e-4))
    return s*env*vol
def noise(d, vol=0.4, lp=0.3, decay=3):
    n = np.random.RandomState(1).randn(int(SR*d)); k = max(1,int(1/lp)); n = np.convolve(n, np.ones(k)/k, "same")
    t = np.arange(len(n))/SR; return n*np.exp(-decay*t/d)*vol
def cat(*xs): return np.concatenate(xs)
def mix(*xs):
    n = max(len(x) for x in xs); o = np.zeros(n)
    for x in xs: o[:len(x)] += x
    return o
def save(name, x, norm=0.8):
    x = x/ max(1e-6, np.abs(x).max()) * norm
    w = os.path.join("/tmp", name+".wav")
    with wave.open(w,"wb") as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR); f.writeframes((x*32767).astype(np.int16).tobytes())
    subprocess.run(["ffmpeg","-y","-loglevel","error","-i",w,"-b:a","64k",os.path.join(AUD,name+".mp3")], check=True); os.remove(w)

save("pop", tone(np.linspace(300,900,2000), 0.12, vol=0.7, a=0.002, r=0.05))
save("wrong", mix(tone(140,0.35,"saw",0.5,0.005,0.1), tone(147,0.35,"saw",0.5,0.005,0.1)))
save("crack", mix(noise(0.25,0.9,0.5,6), tone(np.linspace(900,200,800),0.2,"sq",0.2,0.001,0.1)))
save("click", tone(700,0.06,"tri",0.6,0.002,0.03))
save("win", cat(*[tone(f,0.16,"tri",0.6) for f in (523,659,784,1047)], tone(1047,0.5,"tri",0.6,0.01,0.3)))
save("lose", cat(*[tone(f,0.25,"tri",0.6) for f in (392,330,262)], tone(196,0.5,"tri",0.6,0.01,0.3)))
save("star", tone(np.linspace(800,1600,1500),0.18,"sine",0.6))
cheep = lambda: cat(tone(np.linspace(2400,3200,800),0.09,"sine",0.6,0.005,0.03), np.zeros(int(SR*0.05)), tone(np.linspace(2600,3400,800),0.09,"sine",0.6,0.005,0.03))
save("hatch_chick", cat(cheep(), np.zeros(int(SR*0.1)), cheep()))
save("hatch_peacock", cat(tone(np.linspace(700,1500,2000),0.22,"saw",0.4,0.01,0.05), tone(np.linspace(1500,900,2000),0.35,"saw",0.4,0.01,0.2)))
save("hatch_penguin", cat(tone(np.linspace(500,900,1500),0.12,"sq",0.35), tone(np.linspace(900,600,1500),0.15,"sq",0.35,0.005,0.08), np.zeros(int(SR*0.05)), tone(np.linspace(600,1000,1500),0.15,"sq",0.35,0.005,0.08)))
roar = mix(tone(np.linspace(180,70,int(SR*0.9)),0.9,"saw",0.6,0.05,0.4), noise(0.9,0.5,0.4,1.5))
save("hatch_dragon", roar)
save("fire", noise(0.8,0.9,0.15,2.0))
# background music: short seamless loops
def song(notes, step, wave_, vol, bass=None, bw="tri", gap=0.9):
    seq = cat(*[tone(f,step*gap,wave_,vol,0.01,step*0.4) if f else np.zeros(int(SR*step*gap)) for f in notes for _ in [0]] ) if False else None
    parts = []
    for f in notes:
        n = int(SR*step)
        seg = np.zeros(n)
        if f:
            s = tone(f, step*gap, wave_, vol, 0.01, step*0.45); seg[:len(s)] = s
        parts.append(seg)
    lead = np.concatenate(parts)
    if bass:
        bp = []
        for f in bass:
            n = int(SR*step*2); seg = np.zeros(n); s = tone(f, step*1.9, bw, vol*0.8, 0.02, step*0.8); seg[:len(s)] = s; bp.append(seg)
        b = np.concatenate(bp)[:len(lead)]; lead = lead[:len(b)] + b
    return lead
N = {"0":0}; N.update(dict(C4=262,D4=294,E4=330,G4=392,A4=440,C5=523,D5=587,E5=659,G5=784,A5=880,C6=1047, A3=220,G3=196,C3=131,F3=175,E3=165,B4=494,F4=349,Bb4=466,D3=147))
farm = [N[k] for k in "C5 E5 G5 E5 A5 G5 E5 C5 D5 E5 G5 0 E5 D5 C5 0".split()]
save("bgm_farm", song(farm, 0.28, "tri", 0.45, [N["C3"],N["F3"],N["G3"],N["C3"],N["C3"],N["F3"],N["G3"],N["C3"]][:8]), 0.6)
forest = [N[k] for k in "E4 0 G4 A4 0 C5 0 A4 G4 0 E4 0 D4 0 0 0".split()]
save("bgm_forest", mix(song(forest, 0.45, "sine", 0.5, [N["A3"],N["E3"],N["A3"],N["E3"]]), noise(7.2,0.06,0.05,0.001)), 0.6)
ice = [N[k] for k in "G5 0 E5 0 D5 0 E5 0 G5 0 A5 0 G5 0 E5 0".split()]
save("bgm_ice", song(ice, 0.5, "sine", 0.4, [N["C3"],N["G3"],N["F3"],N["G3"]]), 0.55)
volc = [220,220,262,220,294,220,262,220,220,220,330,220,294,262,220,0]
save("bgm_volcano", song(volc, 0.22, "saw", 0.22, [110,110,98,110,131,110,98,110][:8], "saw"), 0.6)
print("assets ok")
