"""Prototipo numerico (Python) del diseno v2 -- verificacion, NO es el modelo Simulink.
Escala uniforme K = 100: todas las frecuencias en Hz SIMULADOS (nominal / 100).
Cadena multirritmo: 480 Hz (audio) -> 4.8 kHz (FDM) -> 480 kHz (RF) y de vuelta.
Uso:  python proto_fdm_fm.py [T_real_s] [demod: iq|disc]
"""
import numpy as np, time, sys
from scipy import signal as sg

K = 100
fs_a, fs_m, fs_rf = 480.0, 4800.0, 480000.0
f_sc = np.array([200.0, 600.0, 1000.0])   # subportadoras DSB-SC (20/60/100 kHz nom.)
Wa = 150.0                                 # audio 15 kHz nom.
W = 1200.0                                 # ancho del multiplex 120 kHz nom.
fm_max = 1150.0                            # borde superior ocupado 115 kHz nom.
df = 1500.0                                # desviacion pico 150 kHz nom.
f_FI = 17000.0                             # FI 1.7 MHz nom.
HW = 3500.0                                # semiancho de paso RF/FI (+-350 kHz nom.)
T_real = float(sys.argv[1]) if len(sys.argv) > 1 else 0.3
DEMOD = sys.argv[2] if len(sys.argv) > 2 else "iq"
T = T_real * K
rng = np.random.default_rng(1)

def fir(x, h):  # FIR fase lineal, retardo (N-1)/2 compensado (equivale a conocer tau)
    return sg.oaconvolve(x, h, mode="same")
def kaiser_lp(fs, fp, fst, A=60, gain=1.0):
    N, b = sg.kaiserord(A, (fst - fp) / (fs / 2)); N |= 1
    return gain * sg.firwin(N, (fp + fst) / 2, window=("kaiser", b), fs=fs)
def kaiser_bp(fs, f1, f2, tw, A=60):
    N, b = sg.kaiserord(A, tw / (fs / 2)); N |= 1
    return sg.firwin(N, [f1, f2], pass_zero=False, window=("kaiser", b), fs=fs)

na = int(T * fs_a)
h_src = kaiser_bp(fs_a, 3, 145, 6)
def make_src():
    x = fir(rng.standard_normal(na), h_src); return x / np.max(np.abs(x))
X = np.vstack([make_src() for _ in range(3)])

def tx(X, fc):
    h_i1 = kaiser_lp(fs_m, 150, 330, gain=10)
    nm = X.shape[1] * 10; t_m = np.arange(nm) / fs_m; m = np.zeros(nm)
    for k in range(3):
        u = np.zeros(nm); u[::10] = X[k]
        m += fir(u, h_i1) * np.cos(2 * np.pi * f_sc[k] * t_m)
    m_n = m / 3.0
    u = np.zeros(nm * 100); u[::100] = m_n
    m_rf = fir(u, kaiser_lp(fs_rf, 1200, 3600, gain=100))
    t = np.arange(m_rf.size) / fs_rf
    return np.cos(2 * np.pi * fc * t + 2 * np.pi * df * np.cumsum(m_rf) / fs_rf), m, m_n

def rx(r, fc, demod=DEMOD):
    t = np.arange(r.size) / fs_rf
    f_LO = fc - f_FI                                            # inyeccion inferior
    v = fir(r, kaiser_bp(fs_rf, fc - HW - 6000, fc + HW + 6000, 12000)) * 2 * np.cos(2 * np.pi * f_LO * t)
    fi = fir(v, kaiser_bp(fs_rf, f_FI - HW - 1000, f_FI + HW + 1000, 2000))[::10]
    fs_fi = fs_rf / 10
    if demod == "iq":      # cuadratura: f_i = fs/2pi * arg(z[n] z*[n-1])
        n = np.arange(fi.size)
        z = fir(fi * np.exp(-2j * np.pi * f_FI * n / fs_fi), kaiser_lp(fs_fi, HW + 500, 9500))
        finst = np.angle(z[1:] * np.conj(z[:-1])) * fs_fi / (2 * np.pi)
        finst = np.concatenate([[finst[0]], finst])
    else:                  # discriminador del curso: limitador -> derivador -> detector de envolvente
        h = sg.remez(201, [0.03, 0.47], [1], type="hilbert", fs=1.0)
        a = fi + 1j * fir(fi, h); lim = np.real(a / np.abs(a))
        d = fir(lim, sg.remez(31, [0, 0.45], [1], type="differentiator", fs=1.0)) * fs_fi
        finst = np.abs(d + 1j * fir(d, h)) / (2 * np.pi) - f_FI
    mh = fir(finst / df, kaiser_lp(fs_fi, 1200, 2400))[::10] * 3.0
    t_m = np.arange(mh.size) / fs_m; Y = []
    for k in range(3):   # canal 1 tambien pasabanda (rechaza DC del discriminador)
        b = kaiser_bp(fs_m, 25, 400, 50) if k == 0 else kaiser_bp(fs_m, f_sc[k] - 200, f_sc[k] + 200, 100)
        Y.append(fir(fir(mh, b) * 2 * np.cos(2 * np.pi * f_sc[k] * t_m), kaiser_lp(fs_m, 150, 200))[::10])
    return np.vstack(Y), mh

def sdr(x, y, edge=0.1):
    e = int(edge * x.size); x, y = x[e:-e], y[e:-e]
    g = np.dot(x, y) / np.dot(y, y)
    return 10 * np.log10(np.sum(x**2) / np.sum((x - g * y) ** 2)), g

def occ_bw(s, fc, frac):
    f, P = sg.welch(s, fs_rf, nperseg=2**17)
    sel = np.abs(f - fc) < 20000; f, P = f[sel], P[sel]; tot = P.sum()
    for half in np.arange(0, 20000, 10):
        if P[np.abs(f - fc) <= half].sum() >= frac * tot: return 2 * half

if __name__ == "__main__":
    fc = 100000.0
    print(f"demod={DEMOD}  df={df*K/1e3:.0f} kHz nom  D={df/fm_max:.2f}  Carson={2*(df+fm_max)*K/1e3:.0f} kHz nom")
    t0 = time.time(); s, m, m_n = tx(X, fc); Y, mh = rx(s, fc)
    print(f"muestras RF {s.size/1e6:.1f} M, TX+RX {time.time()-t0:.1f} s; pico|m_n|={np.max(abs(m_n)):.3f}")
    for k in range(3): print(f"  canal {k+1}: SDR ideal {sdr(X[k],Y[k])[0]:.1f} dB, ganancia {sdr(X[k],Y[k])[1]:.3f}")
    X2 = X.copy(); X2[[0, 2]] = 0; Y2, _ = rx(tx(X2, fc)[0], fc); e = Y2.shape[1] // 10
    p2 = np.mean(Y2[1][e:-e]**2)
    print("  diafonia 2->1, 2->3: %.1f, %.1f dB" % tuple(10*np.log10(np.mean(Y2[k][e:-e]**2)/p2) for k in (0, 2)))
    for fc2 in (90000.0, 110000.0):
        Y3, _ = rx(tx(X, fc2)[0], fc2)
        print(f"  fc={fc2*K/1e6:.0f} MHz (LO {(fc2-f_FI)*K/1e6:.1f} MHz): SDR " + ", ".join(f"{sdr(X[k],Y3[k])[0]:.1f}" for k in range(3)))
    t = np.arange(int(0.1 * K * fs_a)) / fs_a
    st, _, mt = tx(np.vstack([np.cos(2 * np.pi * 150 * t)] * 3), fc)
    print(f"  peor caso (3 tonos 15 kHz): pico m_n {np.max(abs(mt)):.2f}, BW99 {occ_bw(st,fc,.99)*K/1e3:.0f} kHz, BW99.9 {occ_bw(st,fc,.999)*K/1e3:.0f} kHz nom")
    # AWGN con (SNR)_C de Haykin: (A^2/2)/(W N0), W = ancho del multiplex
    Px = np.mean(X**2, axis=1)
    theo = lambda snrc, k: snrc + 10*np.log10(W*df**2*Px[k]/(18*Wa*(f_sc[k]**2 + Wa**2/3)))
    for snrc in (35, 25, 20, 17, 15):
        N0 = 0.5 / (10**(snrc/10) * W)
        Yn, _ = rx(s + rng.standard_normal(s.size) * np.sqrt(N0 * fs_rf / 2), fc)
        print(f"  (SNR)c={snrc} dB [CNR en B_T={snrc-10*np.log10(2*(df+fm_max)/W):.1f}]: medido " +
              ", ".join(f"{sdr(X[k],Yn[k])[0]:5.1f}" for k in range(3)) + " | teoria " +
              ", ".join(f"{theo(snrc,k):5.1f}" for k in range(3)))
