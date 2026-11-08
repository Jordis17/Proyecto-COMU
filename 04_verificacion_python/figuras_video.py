"""Figuras de comparación para el video (datos ya medidos; no simula nada).

Datos de Simulink: 02_diseno/comparacion_demoduladores.md (tabla «Confirmación en Simulink»).
Prénfasis: fórmula de params_sistema.m (P.enf.mejora_dB) evaluada para varios f0, y lo medido
con analisis_awgn (f0 = 30 kHz).

Uso:  python3 figuras_video.py      -> guarda los PNG en 02_diseno/figuras_video/
"""
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

SALIDA = os.path.join(os.path.dirname(__file__), "..", "02_diseno", "figuras_video")
os.makedirs(SALIDA, exist_ok=True)
plt.rcParams.update({"font.size": 11, "axes.titlesize": 12, "axes.titleweight": "normal",
                     "axes.grid": True, "grid.alpha": 0.25, "axes.spines.top": False,
                     "axes.spines.right": False})

# ---------------- 1) Demoduladores: SDR frente a (SNR)_C (Simulink) ----------------
snr = [40, 30, 20, 18, 16, 14]
ideal = {"Cuadratura": [60.3, 59.4, 57.1], "PLL": [47.6, 38.7, 34.0], "Discriminador": [43.3, 52.2, 54.4]}
sdr = {  # audio 1, audio 3
    "Cuadratura":    ([41.9, 32.0, 21.9, 17.5, 11.9, 4.1], [27.7, 17.7, 8.2, 6.4, 4.4, 2.1]),
    "PLL":           ([40.7, 31.7, 21.6, 19.5, 16.7, 9.6], [26.6, 17.4, 8.0, 6.3, 4.7, 3.0]),
    "Discriminador": ([39.7, 31.6, 18.4, 10.3, 3.9, 1.3], [27.6, 17.7, 8.0, 5.4, 2.4, 0.9]),
}
estilo = {"Cuadratura": dict(color="0.6", ls="--", marker="s"),
          "PLL": dict(color="#d95f02", ls="-.", marker="^"),
          "Discriminador": dict(color="#1b5e9e", ls="-", marker="o", lw=2.2)}

fig, ax = plt.subplots(1, 3, figsize=(13, 4.2), gridspec_kw={"width_ratios": [1, 1.4, 1.4]})
x = np.arange(3)
for i, (n, v) in enumerate(ideal.items()):
    ax[0].bar(x + (i - 1) * 0.27, v, 0.25, label=n, color=estilo[n]["color"])
ax[0].set_xticks(x, ["Audio 1", "Audio 2", "Audio 3"])
ax[0].set_ylabel("SDR [dB]")
ax[0].set_title("Canal ideal")
ax[0].set_ylim(0, 80)
ax[0].legend(frameon=False, fontsize=9, loc="upper center", ncol=3, columnspacing=0.8, handlelength=1.2)
for j, aud in enumerate(["Audio 1", "Audio 3"]):
    a = ax[j + 1]
    for n in sdr:
        a.plot(snr, sdr[n][j], label=n, **estilo[n])
    a.set_xlabel("(SNR)$_C$ [dB]")
    a.set_title(f"{aud} con ruido")
    a.set_xlim(41, 13)
    a.set_ylim(0, 45)
    a.axvspan(13, 20, color="0.92", zorder=0)
    a.text(16.5, 41, "zona del\numbral", ha="center", va="top", fontsize=9, color="0.4")
ax[1].set_ylabel("SDR [dB]")
ax[1].legend(frameon=False, fontsize=9, loc="upper right", bbox_to_anchor=(0.62, 1.0))
fig.suptitle("Tres demoduladores con el mismo modelo y el mismo ruido (Simulink)", fontsize=13)
fig.tight_layout()
fig.savefig(os.path.join(SALIDA, "comparacion_demoduladores.png"), dpi=150)

# ---------------- 2) Prénfasis: elección de f0 (teoría) y lo medido ----------------
fs = 480e3
fsc = np.array([20e3, 60e3, 100e3])
Wa = 15e3


def mejora(f0):
    a = np.exp(-2 * np.pi * f0 / fs)
    H = lambda f: np.abs(1 - a * np.exp(-2j * np.pi * f / fs))
    g = 3 / np.sum(H(fsc + Wa))
    out = []
    for k in range(3):
        ff = np.linspace(fsc[k] - Wa, fsc[k] + Wa, 501)
        out.append(10 * np.log10(g**2 * np.trapezoid(ff**2, ff) / np.trapezoid(ff**2 / H(ff)**2, ff)))
    return np.array(out)


f0s = np.linspace(5e3, 120e3, 116)
M = np.array([mejora(f) for f in f0s])
fig, ax = plt.subplots(1, 2, figsize=(12, 4.2))
col = ["#1b5e9e", "#d95f02", "#6a3d9a"]
for k in range(3):
    ax[0].plot(f0s / 1e3, M[:, k], color=col[k], lw=2, label=f"Audio {k+1}")
ax[0].axvline(30, color="k", ls=":", lw=1)
ax[0].axhline(0, color="0.5", lw=0.8)
ax[0].text(31.5, -9.4, "f$_0$ = 30 kHz", fontsize=9)
ax[0].set_xlabel("f$_0$ del prénfasis [kHz]")
ax[0].set_ylabel("Cambio de SNR [dB]")
ax[0].set_title("Teoría: lo que gana el audio 3 lo pierde el audio 1")
ax[0].legend(frameon=False, fontsize=9)
ax[0].set_ylim(-10, 4)

# medido con analisis_awgn a (SNR)_C = 25 dB: sin y con prénfasis
sin = [26.7, 16.3, 12.8]
con = [21.1, 15.2, 14.8]
x = np.arange(3)
ax[1].bar(x - 0.18, sin, 0.34, color="0.7", label="sin prénfasis")
ax[1].bar(x + 0.18, con, 0.34, color="#1b5e9e", label="con prénfasis (f$_0$ = 30 kHz)")
for i in range(3):
    ax[1].text(x[i] - 0.18, sin[i] + 0.4, f"{sin[i]:.1f}", ha="center", fontsize=9)
    ax[1].text(x[i] + 0.18, con[i] + 0.4, f"{con[i]:.1f}", ha="center", fontsize=9)
ax[1].set_xticks(x, ["Audio 1", "Audio 2", "Audio 3"])
ax[1].set_ylabel("SDR [dB]")
ax[1].set_title("Medido en Simulink, (SNR)$_C$ = 25 dB")
ax[1].set_ylim(0, 32)
ax[1].legend(frameon=False, fontsize=9)
fig.tight_layout()
fig.savefig(os.path.join(SALIDA, "prenfasis_f0.png"), dpi=150)
print("Figuras guardadas en", os.path.abspath(SALIDA))
