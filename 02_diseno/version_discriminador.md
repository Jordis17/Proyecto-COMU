# Versión con discriminador (rama `claude/version-discriminador`)

Es la misma versión agrupada, pero el **Demodulador FM** es el **discriminador de frecuencia** del curso (diap. 342–345, 375) en lugar del detector de cuadratura. El resto del sistema no cambia.

## Cómo es

```
señal de FI → Limitador → Detector de pendiente (derivador) → Detector de envolvente → Convertir a desviación → Filtro posdetección
```

| Bloque | Qué hace | En el curso |
|---|---|---|
| **Limitador** | Divide la FI por su amplitud, para que quede con amplitud constante igual a 1. La amplitud se mide con un detector de ley cuadrática: A = √(2·pasabajos(FI²)). Nunca se usa una amplitud menor a 0.3, como un limitador real, que tiene ganancia finita | Diap. 375: el limitador elimina las variaciones de amplitud |
| **Detector de pendiente (derivador)** | Filtro FIR derivador de 63 coeficientes. Al derivar cos θ(t), la amplitud queda proporcional a dθ/dt = 2π f_i | Discriminador, diap. 342–345: convierte FM en AM |
| **Detector de envolvente** | Ley cuadrática: √(2·pasabajos(d²)). Da la amplitud de la salida del derivador, o sea 2π f_i | Detector de envolvente |
| **Convertir a desviación** | Divide entre 2π y resta f_FI. Sale la desviación de frecuencia en Hz | f_i = f_FI + k_f·m(t) |

**Por qué el limitador divide en vez de recortar.** En una simulación digital, recortar la onda o rectificarla genera armónicos que, a 4.8 MHz de muestreo, se pliegan sobre la señal; probándolo, la calidad baja a 9–14 dB. Dividir por la amplitud logra lo mismo, una amplitud constante, sin generar armónicos.

**Por qué el limitador es imprescindible.** Sin él, la salida es amplitud × frecuencia. El ruido de amplitud se multiplica por toda la FI (1.7 MHz) y tapa la señal: a 40 dB de (SNR)_C, el SDR cae a 5 dB.

## Resultados en Simulink (MATLAB R2026a)

**Canal ideal** (`graficas_sistema`): SDR = **43.3 / 52.2 / 54.4 dB**. Los audios recuperados se superponen con los originales (`fig5`).

**Canal AWGN** (`analisis_awgn`, SDR en dB, sin preénfasis), comparado con el PLL:

| (SNR)_C | Discriminador | PLL |
|---|---|---|
| Canal ideal | 43.9 / 52.6 / 55.1 | 47.4 / 38.8 / 33.9 |
| 40 dB | 39.7 / 31.2 / 27.6 | 40.7 / 30.5 / 26.6 |
| 30 dB | 31.6 / 21.3 / 17.7 | 31.7 / 21.1 / 17.4 |
| 25 dB | 26.7 / 16.3 / 12.8 | 26.7 / 16.2 / 12.6 |
| 20 dB | 18.4 / 10.9 / 8.0 | 21.6 / 11.3 / 8.0 |
| 18 dB | 10.3 / 7.1 / 5.4 | **19.5 / 9.4 / 6.3** |
| 16 dB | 3.9 / 2.9 / 2.4 | **16.7 / 7.3 / 4.7** |

- **Canal ideal:** el discriminador es mejor en los canales 2 y 3 (52–55 dB contra 34–39 dB). El PLL es algo mejor en el canal 1.
- **Ruido moderado (25–40 dB):** son iguales; los dos siguen la teoría de FM.
- **Cerca del umbral (16–20 dB):** el PLL es claramente mejor. El discriminador entra en umbral antes.
- **Preénfasis:** funciona igual que en las otras versiones. Con canal ideal no cambia nada (44.8 / 55.9 / 58.5 dB); con ruido, el canal 3 sube unos 2 dB y el canal 1 baja unos 5 dB.

## Cómo probarla

1. En GitHub Desktop: **Current branch → `claude/version-discriminador`**, y luego **Fetch/Pull**. Cierren el modelo en MATLAB antes de cambiar de rama.
2. En esta rama no hay `.slx`: `main` lo genera. Revisen que no aparezca ningún «Aviso: no se pudo agrupar…». La tabla debe decir «Demodulador: discriminador…».
3. Corran `graficas_sistema` y `analisis_awgn`, como en la rama del PLL.
4. Súbanlo a esta rama y lo comparo con el PLL.

## Si algo falla

- **Error en los bloques «Sqrt» o «Delay»:** pásenme el mensaje completo. Son bloques básicos, pero los nombres de algunos parámetros cambian entre versiones de MATLAB.
- **SDR muy bajo con canal ideal (menos de 20 dB):** el retardo de compensación podría no coincidir. Pásenme la consola de `graficas_sistema`.
