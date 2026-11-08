# Comparación de tres demoduladores de FM

Probamos tres formas de demodular la FM, con la misma señal (multiplex de 3 canales, Δf = 150 kHz, FI de 1.7 MHz muestreada a 4.8 MHz) y el mismo ruido. Script: `04_verificacion_python/comparar_demoduladores.py` (Python, solo numpy).

## Los tres demoduladores

| Demodulador | Cómo funciona | En el curso / bibliografía |
|---|---|---|
| **Detector de cuadratura** (respaldo, no se entrega) | Separa la FI en I y Q y mide cuánto gira la fase entre una muestra y la siguiente | Tomasi: demodulador de FM en cuadratura. Es la forma digital de f_i = (1/2π)·dφ/dt |
| **PLL** | Detector de fase (multiplicador) → filtro de lazo PI → VCO. La salida del filtro de lazo es el mensaje. f_n = 200 kHz, ζ = 0.707 | Diap. 347–354 |
| **Discriminador** | Derivador (detector de pendiente) → detector de envolvente. La amplitud se normaliza para hacer el papel del limitador | Diap. 342–345, 375 |

## Resultados (SDR en dB, canales 1 / 2 / 3)

| (SNR)_C | Cuadratura | PLL | Discriminador |
|---|---|---|---|
| Canal ideal | **63.5 / 63.6 / 63.5** | 38.5 / 56.7 / 36.4 | 42.0 / 44.7 / 44.4 |
| 40 dB | 41.8 / 33.6 / 28.8 | 36.8 / 33.5 / 28.0 | 38.9 / 33.4 / 28.7 |
| 30 dB | 31.8 / 23.6 / 18.9 | 30.8 / 23.5 / 18.6 | 31.4 / 23.6 / 18.8 |
| 25 dB | 26.8 / 18.6 / 14.0 | 26.3 / 18.5 / 13.8 | 26.5 / 18.6 / 13.9 |
| 20 dB | 21.7 / 13.6 / 9.3 | 21.4 / 13.4 / 9.1 | 0 (falla) |
| 18 dB | 15.9 / 10.9 / 7.4 | **19.3 / 11.4 / 7.3** | 0 |
| 16 dB | 10.9 / 7.7 / 5.2 | **17.1 / 9.4 / 5.7** | 0 |
| 14 dB | 3.6 / 3.1 / 2.8 | **12.4 / 6.9 / 3.9** | 0 |

## Confirmación en Simulink (modelo completo, MATLAB R2026a)

| (SNR)_C | Cuadratura | PLL | Discriminador |
|---|---|---|---|
| Canal ideal | 60.3 / 59.4 / 57.1 | 47.6 / 38.7 / 34.0 | 43.3 / 52.2 / 54.4 |
| 40 dB | 41.9 / 31.2 / 27.7 | 40.7 / 30.5 / 26.6 | 39.7 / 31.2 / 27.6 |
| 30 dB | 32.0 / 21.3 / 17.7 | 31.7 / 21.1 / 17.4 | 31.6 / 21.3 / 17.7 |
| 20 dB | 21.9 / 11.5 / 8.2 | 21.6 / 11.3 / 8.0 | 18.4 / 10.9 / 8.0 |
| 18 dB | 17.5 / 9.6 / 6.4 | **19.5 / 9.4 / 6.3** | 10.3 / 7.1 / 5.4 |
| 16 dB | 11.9 / 6.6 / 4.4 | **16.7 / 7.3 / 4.7** | 3.9 / 2.9 / 2.4 |
| 14 dB | 4.1 / 2.7 / 2.1 | **9.6 / 4.8 / 3.0** | 1.3 / 0.9 / 0.9 |

Cada demodulador está en su rama: discriminador en la rama principal (`claude/affectionate-bardeen-qmc9v9`) y en `claude/version-discriminador`, PLL en `claude/version-pll` y cuadratura en `claude/version-cuadratura`. En Simulink, el discriminador (con el limitador que normaliza la amplitud y tiene un mínimo de 0.3) salió mejor que en la prueba de Python con canal ideal y se degrada de forma gradual cerca del umbral.

## Qué se ve

- **Con ruido moderado (25–40 dB), los tres dan casi lo mismo.** Lo que limita es el ruido, no el demodulador, y los tres siguen la teoría de FM del curso.
- **Con canal ideal, el detector de cuadratura es el más limpio.**
  - El **PLL** no sigue perfectamente los cambios rápidos de frecuencia del multiplex (hasta 115 kHz con 150 kHz de desviación). Esa diferencia genera distorsión, y los canales 1 y 3 quedan en 36–39 dB.
  - El **discriminador** queda en 42–45 dB: el derivador y el detector de envolvente no son perfectos.
- **Cerca del umbral, el PLL es el mejor.** A 16 dB, el canal 1 sale con 17 dB contra 11 dB del detector de cuadratura. Es la conocida «extensión del umbral» de los PLL: el lazo sigue la fase aunque haya picos de ruido.
- **El discriminador es el que antes entra en umbral** (alrededor de 20 dB).
  - Sin limitador no sirve: la salida es amplitud × frecuencia, así que el ruido de amplitud se multiplica por la FI completa y tapa la señal. Por eso el curso lo pone siempre con limitador (diap. 375).
  - El limitador «de verdad» (recortar la onda) y el rectificador no funcionan en una simulación digital a 4.8 MHz: generan armónicos que se pliegan sobre la señal y el resultado baja a 9–14 dB.
  - La versión que funciona divide por la amplitud medida, y cuando el ruido hace que la amplitud pase cerca de cero, esa división genera picos enormes.

## Conclusión

Usamos el **discriminador** (limitador → detector de pendiente → detector de envolvente), porque es el que se vio en el curso (diap. 342–345 y 375).

- **Lo que cuesta:**
  - Con canal ideal da 43.3 / 52.2 / 54.4 dB, frente a 60.3 / 59.4 / 57.1 del detector de cuadratura. Sigue por encima de 43 dB, así que la distorsión no se oye.
  - Entra en umbral unos 2–4 dB antes que los otros.
- **Lo que no cuesta:** sobre el umbral, que es donde trabaja el sistema, da lo mismo que los otros dos. A 30 dB: 31.6 / 21.3 / 17.7 dB.
- **Las otras dos opciones quedan guardadas:**
  - el PLL, que aguanta más cerca del umbral, en `claude/version-pll`;
  - el detector de cuadratura, que no se vio en el curso, en `claude/version-cuadratura`.

El resumen de todas las decisiones, con números, está en `decisiones_cuantitativas.md`.
