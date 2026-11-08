# Comparación de tres demoduladores de FM

Probamos tres formas de demodular la FM, con la misma señal (multiplex de 3 canales, Δf = 150 kHz, FI de 1.7 MHz muestreada a 4.8 MHz) y el mismo ruido. Script: `04_verificacion_python/comparar_demoduladores.py` (Python, solo numpy).

## Los tres demoduladores

| Demodulador | Cómo funciona | En el curso / bibliografía |
|---|---|---|
| **Detector de cuadratura** (el del modelo) | Separa la FI en I y Q y mide cuánto gira la fase entre una muestra y la siguiente | Tomasi: demodulador de FM en cuadratura. Es la forma digital de f_i = (1/2π)·dφ/dt |
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

## Confirmación en Simulink (PLL contra cuadratura)

| | Cuadratura | PLL |
|---|---|---|
| Canal ideal | 60.3 / 59.4 / 57.1 dB | 47.6 / 38.7 / 34.0 dB |
| (SNR)_C = 30 dB | 32.0 / 21.3 / 17.7 | 31.7 / 21.1 / 17.4 |
| (SNR)_C = 16 dB | 11.9 / 6.6 / 4.4 | **16.7 / 7.3 / 4.7** |
| (SNR)_C = 14 dB | 4.1 / 2.7 / 2.1 | **9.6 / 4.8 / 3.0** |

El PLL se probó en el modelo completo (rama `claude/version-pll`, ver `version_pll.md`). Confirma lo de Python: con ruido moderado son iguales, el PLL es mejor cerca del umbral y distorsiona más con canal ideal. El discriminador no se pasó a Simulink.

## Qué se ve

- **Con ruido moderado (25–40 dB), los tres dan casi lo mismo.** Lo que limita es el ruido, no el demodulador, y los tres siguen la teoría de FM del curso.
- **Con canal ideal, el detector de cuadratura es el más limpio.**
  - El **PLL** no sigue perfectamente los cambios rápidos de frecuencia del multiplex (hasta 115 kHz con 150 kHz de desviación). Esa diferencia genera distorsión, y los canales 1 y 3 quedan en 36–39 dB.
  - El **discriminador** queda en 42–45 dB: el derivador y el detector de envolvente no son perfectos.
- **Cerca del umbral, el PLL es el mejor.** A 16 dB, el canal 1 sale con 17 dB contra 11 dB del detector de cuadratura. Es la conocida «extensión del umbral» de los PLL: el lazo sigue la fase aunque haya picos de ruido.
- **El discriminador es el que antes se cae** (alrededor de 20 dB).
  - Sin limitador no sirve: la salida es amplitud × frecuencia, así que el ruido de amplitud se multiplica por la FI completa y tapa la señal. Por eso el curso lo pone siempre con limitador (diap. 375).
  - El limitador «de verdad» (recortar la onda) y el rectificador no funcionan en una simulación digital a 4.8 MHz: generan armónicos que se pliegan sobre la señal y el resultado baja a 9–14 dB.
  - La versión que funciona divide por la amplitud medida, y cuando el ruido hace que la amplitud pase cerca de cero, esa división genera picos enormes.

## Conclusión

Usamos el **detector de cuadratura**:
- es el más limpio con canal ideal (63 dB);
- con ruido rinde igual que los otros por encima del umbral;
- no necesita limitador.

El **PLL** es una buena alternativa si interesa trabajar cerca del umbral, a costa de más distorsión con canal ideal (está implementado en la rama `claude/version-pll`). El **discriminador** del curso, en digital, es el más delicado: necesita normalizar la amplitud y es el primero en fallar con ruido.
