"""Compara tres demoduladores de FM con el mismo sistema (FM en FI, multiplex FDM de 3 canales).
   1) Detector de cuadratura (el del modelo): ángulo de z[n]·z*[n-1].
   2) PLL: detector de fase (multiplicador) -> filtro de lazo PI -> VCO.  fn = 200 kHz, zeta = 0.707.
   3) Discriminador del curso: derivador -> detector de envolvente de ley cuadrática, con la
      amplitud normalizada (hace el papel del limitador).
Unidades simuladas (K = 100). Solo numpy.  Uso:  python comparar_demoduladores.py
La fase de cada subportadora del receptor se fija una sola vez, sin ruido (como haría el receptor real)."""
import numpy as np
fs_a, fs_m, fs_i = 480., 4800., 48000.          # 48 kHz, 480 kHz, 4.8 MHz nominales
fsc = np.array([200., 600., 1000.]); Wa = 150.; df = 1500.; fFI = 17000.; W = 1200.
rng = np.random.default_rng(1)
def lp(fs, fp, fst, A=60, g=1.):
    dw = 2*np.pi*(fst-fp)/fs; M = int(np.ceil((A-7.95)/(2.285*dw))); M += M % 2
    n = np.arange(M+1)-M/2; fc = (fp+fst)/2
    h = 2*fc/fs*np.sinc(2*fc/fs*n)*np.kaiser(M+1, 0.1102*(A-8.7)); return g*h/h.sum()
def bp(fs, a, b, c, d):
    h1 = lp(fs, c, d); h0 = lp(fs, a, b); L = max(len(h1), len(h0)); pad = lambda h: np.pad(h, ((L-len(h))//2,)*2)
    h = pad(h1)-pad(h0); f0 = (b+c)/2; n = np.arange(L); return h/abs(np.sum(h*np.exp(-2j*np.pi*f0/fs*n)))
conv = lambda x, h: np.convolve(x, h, 'same')
# ---- transmisor: 3 audios de ruido 0.3-15 kHz, FDM DSB-SC, FM en FI
T = 6.0; na = int(T*fs_a); hs = bp(fs_a, 0, 3, 145, 150)
X = np.array([(lambda v: v/np.abs(v).max())(conv(rng.standard_normal(na), hs)) for _ in range(3)])
nm = na*10; tm = np.arange(nm)/fs_m; m = np.zeros(nm); hi = lp(fs_m, 150, 330, g=10)
for k in range(3):
    u = np.zeros(nm); u[::10] = X[k]; m += conv(u, hi)*np.cos(2*np.pi*fsc[k]*tm)
u = np.zeros(nm*10); u[::10] = m/3; mi = conv(u, lp(fs_i, 1200, 3600, g=10)); t = np.arange(mi.size)/fs_i
x = np.cos(2*np.pi*fFI*t + 2*np.pi*df*np.cumsum(mi)/fs_i)
hfi = bp(fs_i, 11500, 13500, 20500, 22500); hmux = lp(fs_i, 1200, 2400); hpost = lp(fs_m, 150, 200)
hch = [bp(fs_m, 0, 50, 350, 400), bp(fs_m, 350, 450, 750, 850), bp(fs_m, 750, 850, 1150, 1250)]
# ---- demoduladores (salida: desviación de frecuencia en Hz)
def cuadratura(r):
    z = conv(r*np.exp(-2j*np.pi*fFI*t), lp(fs_i, 4000, 9500))
    return np.r_[0, np.angle(z[1:]*np.conj(z[:-1]))]*fs_i/(2*np.pi)
def pll(r, fn=2000., zeta=0.707):
    wn = 2*np.pi*fn; Kp = 2*zeta*wn/(2*np.pi); Ki = wn**2/(2*np.pi)/fs_i
    th = 0.; integ = 0.; v = np.zeros_like(r)
    for n in range(len(r)):
        e = r[n]*(-2*np.sin(th))                 # detector de fase
        integ += Ki*e; v[n] = Kp*e + integ       # filtro de lazo PI
        th += 2*np.pi*(fFI + v[n])/fs_i          # VCO
    return v
N = 63; nn = np.arange(N)-(N-1)//2; hd = np.zeros(N); hd[nn != 0] = np.cos(np.pi*nn[nn != 0])/nn[nn != 0]; hd *= np.kaiser(N, 6)*fs_i
hl = lp(fs_i, 4000, 9500)
def discriminador(r):
    d = conv(r, hd)                                                   # derivador (detector de pendiente)
    return np.sqrt(np.maximum(conv(d*d, hl), 0)/np.maximum(conv(r*r, hl), 1e-12))/(2*np.pi) - fFI
# ---- evaluación
fr = np.fft.rfftfreq(x.size, 1/fs_i); M = np.fft.rfft(df*mi)
def fases(v):
    V = np.fft.rfft(v); return [np.angle(np.sum(V[abs(fr-f) < 120]*np.conj(M[abs(fr-f) < 120]))) for f in fsc]
def sdr(v, ph):
    mh = 3*conv(v/df, hmux)[::10]; out = []
    for k in range(3):
        y = conv(conv(mh, hch[k])*2*np.cos(2*np.pi*fsc[k]*tm + ph[k]), hpost)[::10]
        e = int(.15*na); a = X[k, e:-e]; b = y[e:-e]; g = a@b/(b@b); out.append(10*np.log10(np.sum(a**2)/np.sum((a-g*b)**2)))
    return out
D = {'cuadratura': cuadratura, 'PLL': pll, 'discriminador': discriminador}
xf = conv(x, hfi); PH = {k: fases(f(xf)) for k, f in D.items()}
print('SDR en dB, canales 1 / 2 / 3')
print('(SNR)_C  | ' + ' | '.join(f'{k:17s}' for k in D))
for snr in [None, 40, 30, 25, 20, 18, 16, 14]:
    if snr is None: r = xf
    else:
        s = np.sqrt(0.5/(10**(snr/10)*W)*fs_i/2); r = conv(x + s*np.random.default_rng(7).standard_normal(x.size), hfi)
    fila = [sdr(f(r), PH[k]) for k, f in D.items()]
    print(f'{"ideal" if snr is None else str(snr)+" dB":>7}  | ' + ' | '.join(f'{a[0]:5.1f} {a[1]:5.1f} {a[2]:5.1f}' for a in fila), flush=True)
