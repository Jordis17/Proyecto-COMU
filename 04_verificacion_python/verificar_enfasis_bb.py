# Verificación rápida del prénfasis/deénfasis: FM en banda base equivalente, solo numpy.
# Uso: python verificar_enfasis_bb.py [T_simulado_s=20] [f0_simulado_Hz=300]   (K = 100)
import numpy as np, sys
fs_a,fs_m,fs_i=480.,4800.,48000.; fsc=np.array([200.,600.,1000.]); Wa=150.; W=1200.; df=1500.; HW=3500.
rng=np.random.default_rng(1)
def lp(fs,fp,fst,A=60,g=1.):
    dw=2*np.pi*(fst-fp)/fs; M=int(np.ceil((A-7.95)/(2.285*dw))); M+=M%2
    n=np.arange(M+1)-M/2; fc=(fp+fst)/2; h=2*fc/fs*np.sinc(2*fc/fs*n)*np.kaiser(M+1,0.1102*(A-8.7)); return g*h/h.sum()
def bp(fs,a,b,c,d):
    h1=lp(fs,c,d); h0=lp(fs,a,b); L=max(len(h1),len(h0)); pad=lambda h:np.pad(h,((L-len(h))//2,)*2)
    h=pad(h1)-pad(h0); f0=(b+c)/2; n=np.arange(L); return h/abs(np.sum(h*np.exp(-2j*np.pi*f0/fs*n)))
conv=lambda x,h: np.convolve(x,h,'same')
T=float(sys.argv[1]) if len(sys.argv)>1 else 20.0
na=int(T*fs_a); hs=bp(fs_a,0,3,145,150)
X=np.array([ (lambda x:x/np.abs(x).max())(conv(rng.standard_normal(na),hs)) for _ in range(3)])
hi=lp(fs_m,150,330,g=10); nm=na*10; tm=np.arange(nm)/fs_m
xb=[]; m=np.zeros(nm)
for k in range(3):
    u=np.zeros(nm); u[::10]=X[k]; xk=conv(u,hi); xb.append(xk); m+=xk*np.cos(2*np.pi*fsc[k]*tm)
mn0=m/3
h10=lp(fs_i,1200,3600,g=10); hiq=lp(fs_i,HW+500,9500); hmux=lp(fs_i,1200,2400); hpost=lp(fs_m,150,200)
hch=[bp(fs_m,0,50,350,400),bp(fs_m,350,450,750,850),bp(fs_m,750,850,1150,1250)]
def run(snr_dB,alfa,g,seed=7):
    mn=g*(mn0-alfa*np.r_[0,mn0[:-1]])
    u=np.zeros(nm*10); u[::10]=mn; mi=conv(u,h10)
    z=np.exp(2j*np.pi*df*np.cumsum(mi)/fs_i)
    if np.isfinite(snr_dB):
        N0=0.5/(10**(snr_dB/10)*W); s=np.sqrt(N0*fs_i)   # var compleja 2*N0*fs
        r=np.random.default_rng(seed); z=z+s*(r.standard_normal(z.size)+1j*r.standard_normal(z.size))
    z=conv(z,hiq)
    fi=np.r_[0,np.angle(z[1:]*np.conj(z[:-1]))]*fs_i/(2*np.pi)
    mh=conv(fi/df,hmux)[::10]
    # deénfasis: y[n]=x[n]/g + a y[n-1]
    y=np.zeros_like(mh); acc=0.
    for i,v in enumerate(mh): acc=v/g+alfa*acc; y[i]=acc
    mh=3*y; out=[]
    for k in range(3):
        yk=conv(conv(mh,hch[k])*2*np.cos(2*np.pi*fsc[k]*tm),hpost)[::10]
        e=int(0.15*na); a=X[k,e:-e]; b=yk[e:-e]; gg=a@b/(b@b)
        out.append(10*np.log10(np.sum(a**2)/np.sum((a-gg*b)**2)))
    return np.array(out), np.abs(mn).max()
f0=float(sys.argv[2]) if len(sys.argv)>2 else 300.
a=np.exp(-2*np.pi*f0/fs_m); H=lambda f:abs(1-a*np.exp(-2j*np.pi*f/fs_m)); g=3/sum(H(fsc+Wa))
print(f"f0={f0*100/1e3:.0f} kHz nom  a={a:.4f} g={g:.4f}")
for snr in [np.inf,40,30,25,20,18,16]:
    s0,p0=run(snr,0,1); s1,p1=run(snr,a,g)
    print(f"(SNR)_C={snr:>4}: sin {np.round(s0,1)} pico {p0:.2f} | con {np.round(s1,1)} pico {p1:.2f} | dif {np.round(s1-s0,1)}")
