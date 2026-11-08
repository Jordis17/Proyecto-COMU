# Versión con PLL (rama `claude/version-pll`)

Es la misma versión agrupada, pero el **Demodulador FM** es un **PLL** (diap. 347–354) en lugar del detector de cuadratura. El resto del sistema no cambia.

## Cómo es el PLL del modelo

```
señal de FI → Detector de fase (×) → Filtro de lazo (PI) → desviación de frecuencia → Filtro posdetección
                     ↑                                        │
                     └────────── VCO ←────────────────────────┘
```

| Bloque | Qué hace |
|---|---|
| **Detector de fase** | Multiplica la FI por −2·sen(fase del VCO). Si las dos fases están cerca, la salida es ≈ sen(diferencia de fase) |
| **Filtro de lazo** (adentro: Proporcional Kp + Integral Ki) | Convierte el error de fase en una corrección de frecuencia. **Su salida es la desviación de frecuencia, o sea el mensaje** |
| **VCO** (adentro: frecuencia de reposo f_FI + corrección → 2π → integrador → sen → ×(−2)) | Oscilador cuya frecuencia es f_FI + la corrección. Cuando el lazo «engancha», su fase sigue a la de la FI |

**Diseño del lazo:** frecuencia natural f_n = 200 kHz y amortiguamiento ζ = 0.707.
- Kp = 2ζω_n/2π.
- Ki = ω_n²/2π.

Lo calcula `params_sistema.m`. El lazo tiene que ser rápido para seguir un multiplex de 115 kHz con 150 kHz de desviación. Con un lazo más rápido, el término de doble frecuencia del detector de fase lo perturba.

**Compensación de fase:** el PLL desfasa un poco cada subportadora (+1.4°, +2.6° y 0°). `params_sistema.m` lo calcula con el modelo lineal del lazo y lo suma a τ_k.

## Resultados en Simulink (MATLAB R2026a)

**Canal ideal** (`graficas_sistema`): SDR = **47.6 / 38.7 / 34.0 dB**, contra 60.3 / 59.4 / 57.1 dB del detector de cuadratura. Los audios se reconocen bien, pero en el espectro del multiplex recuperado (`fig4_receptor.png`) se ve que la distorsión del PLL sube el piso de las guardas de −75 a −60 dB.

**Canal AWGN** (`analisis_awgn`, SDR en dB, sin preénfasis):

| (SNR)_C | Cuadratura (rama principal) | PLL (esta rama) |
|---|---|---|
| 40 dB | 41.9 / 31.2 / 27.7 | 40.7 / 30.5 / 26.6 |
| 30 dB | 32.0 / 21.3 / 17.7 | 31.7 / 21.1 / 17.4 |
| 20 dB | 21.9 / 11.5 / 8.2 | 21.6 / 11.3 / 8.0 |
| 18 dB | 17.5 / 9.6 / 6.4 | **19.5** / 9.4 / 6.3 |
| 16 dB | 11.9 / 6.6 / 4.4 | **16.7 / 7.3 / 4.7** |
| 14 dB | 4.1 / 2.7 / 2.1 | **9.6 / 4.8 / 3.0** |

- **Con ruido moderado (20–40 dB)**, los dos son prácticamente iguales: los dos siguen la teoría de FM.
- **Cerca del umbral, el PLL es mejor.** A 16 dB, el canal 1 sale con 16.7 dB contra 11.9: es la extensión del umbral.
- **Con preénfasis** el comportamiento es el mismo que en la rama principal: el canal 3 mejora y el canal 1 empeora.
- **Canal ideal:** el PLL distorsiona más.

Coincide con lo previsto en Python (`04_verificacion_python/comparar_demoduladores.py`).

## Cómo probarla

1. En GitHub Desktop: **Current branch → `claude/version-pll`**, y luego **Fetch/Pull**. Cierren el modelo en MATLAB antes de cambiar de rama.
2. En esta rama no hay `.slx`: `main` lo genera. Revisen que no aparezca ningún «Aviso: no se pudo agrupar…».
3. `main`: la tabla debe mostrar «Demodulador PLL: f_n = 200 kHz…». Prueben la radio a 10 MHz y escuchen los audios.
4. `graficas_sistema`: anoten los SDR (esperado, unos 36–57 dB).
5. `analisis_awgn`: comparen con los resultados de la rama principal, sobre todo en 14–18 dB.
6. Pásenme la consola y las figuras (o súbanlas en esta rama) para compararlas con la versión de cuadratura.

## Si algo falla

- **Error de «algebraic loop»:** avisen. El VCO usa un integrador de Euler hacia adelante justamente para evitarlo.
- **SDR muy bajo (menos de 20 dB) con canal ideal:** puede ser que el lazo no enganche o que la compensación de fase no coincida. Pásenme la consola de `graficas_sistema`.
