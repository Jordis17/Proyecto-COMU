# Prénfasis y deénfasis

## Qué pide el enunciado

En §4.5 dice: «Si la calidad de las señales demoduladas es baja, debe considerar el uso de filtros de prénfasis/deénfasis». Es una condición, no un error del enunciado.

- **Con canal ideal** la calidad no es baja: el SDR de los tres audios es de 43 a 54 dB (discriminador). El prénfasis no cambia nada, porque el deénfasis lo deshace exactamente.
- **Con AWGN** la calidad sí baja, y no por igual en todos los canales. A (SNR)_C = 25 dB el canal 1 sale con 27 dB y el canal 3 con unos 13 dB. Aquí sí se cumple la condición, así que lo implementamos y lo medimos.

## Por qué el canal 3 sale peor

A la salida del discriminador, el ruido crece con el cuadrado de la frecuencia: S_No(f) = N₀f²/A_c² (diap. 385). El canal 3 está en la subportadora más alta (100 kHz), así que le toca más ruido que al canal 1 (20 kHz). La diferencia teórica es de unos 13 dB.

## Dónde se colocan

Igual que en la diap. 384: el prénfasis va antes del modulador FM y el deénfasis justo después del demodulador. En nuestro sistema el mensaje que entra al modulador es el multiplex, así que se filtra el multiplex completo:

```
TX: Σ canales → ÷3 → PRÉNFASIS → interpolación → modulador FM
RX: demodulador FM → filtro posdetección → ×3 → DEÉNFASIS → demultiplexor
```

## Los filtros

Son filtros de primer orden, y cada uno es un bloque *Discrete Filter* de Simulink, a 480 kHz nominales:

- Prénfasis: y[n] = g·(x[n] − a·x[n−1]). Realza las frecuencias altas.
- Deénfasis: y[n] = x[n]/g + a·y[n−1]. Es el inverso exacto del prénfasis.
- a = e^(−2π f₀/f_s), con f₀ = 30 kHz nominales: a = 0.675.
- g = 3 / Σ|H(f_k + 15 kHz)| = 1.198. Este valor mantiene el pico del multiplex en ≤ 1, de modo que la desviación pico (150 kHz) y el ancho de Carson (530 kHz) no cambian.

Como los dos filtros juntos dan 1, no cambian los retardos τ_k de la detección coherente.

## Qué se espera

Comparamos con la misma desviación pico. El prénfasis no reduce el ruido total: lo **reparte**. Mejora el canal 3, que es el que limita la calidad del sistema, y empeora el canal 1, que tenía SNR de sobra.

| | Canal 1 | Canal 2 | Canal 3 |
|---|---|---|---|
| Mejora teórica (`P.enf.mejora_dB`) | −5.8 dB | −1.3 dB | +2.0 dB |
| Simulación rápida en Python, (SNR)_C de 20 a 40 dB | −5.7 dB | −1.2 dB | +1.8 dB |
| **Simulink, discriminador** (`analisis_awgn`), (SNR)_C de 20 a 40 dB | **−5.4 dB** | **−1.1 dB** | **+2.0 dB** |
| GUI `radio`, fuente demo, (SNR)_C = 25 dB, a 10 y 11 MHz | −5.5 dB | −1.3 dB | +1.9 dB |

Los resultados de Python salen de `04_verificacion_python/verificar_enfasis_bb.py`. Los de Simulink, de `analisis_awgn.m` (`resultados_awgn.csv`). La diferencia entre el canal 1 y el canal 3 baja de unos 13 a unos 6 dB, y con canal ideal el SDR no cambia (43.9 / 52.6 / 55.1 dB sin preénfasis, 44.8 / 55.9 / 58.5 dB con preénfasis).

Nota: con el preénfasis, el pico de m(t) al modulador fue 0.49, frente a 0.57 sin él. La regla de g es conservadora y deja un poco de desviación sin usar; aun así, el resultado coincide con la teoría.

Con f₀ más bajo el canal 3 mejora un poco más, pero el canal 1 pierde mucho más. La mejora del canal 3 casi no pasa de +2.4 dB. Por eso escogimos 30 kHz como compromiso.

El umbral FM no se mueve, porque la desviación y el ancho de banda son los mismos.

## Cómo se usa

- GUI: casilla «Prénfasis / deénfasis».
- Código: `params_sistema(10e6, struct('enfasis', true))`. Opcional: `'f0_enfasis', 30e3`.
- Verificación: `analisis_awgn` (unos 8–10 min). Guarda `resultados_awgn.csv`, `.mat` y `fig_awgn.png`.
