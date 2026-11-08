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

## Qué esperar (Python, `04_verificacion_python/comparar_demoduladores.py`)

| (SNR)_C | Discriminador | PLL (en Simulink) |
|---|---|---|
| Canal ideal | ≈ 41 / 45 / 44 dB | 47.6 / 38.7 / 34.0 dB |
| 30 dB | ≈ 31 / 24 / 19 | 31.7 / 21.1 / 17.4 |
| 25 dB | ≈ 27 / 19 / 14 | 26.7 / 16.2 / 12.6 |
| 20 dB | ≈ 18 / 13 / 9 | 21.6 / 11.3 / 8.0 |
| 16 dB | ≈ 4 / 3 / 3 | 16.7 / 7.3 / 4.7 |

Lo que se espera:
- **Canal ideal:** un poco mejor que el PLL en los canales 2 y 3.
- **Ruido moderado:** igual que el PLL.
- **Cerca del umbral:** el discriminador se cae antes; el PLL es claramente mejor.

En Simulink los números pueden cambiar un poco.

## Cómo probarla

1. En GitHub Desktop: **Current branch → `claude/version-discriminador`**, y luego **Fetch/Pull**. Cierren el modelo en MATLAB antes de cambiar de rama.
2. En esta rama no hay `.slx`: `main` lo genera. Revisen que no aparezca ningún «Aviso: no se pudo agrupar…». La tabla debe decir «Demodulador: discriminador…».
3. Corran `graficas_sistema` y `analisis_awgn`, como en la rama del PLL.
4. Súbanlo a esta rama y lo comparo con el PLL.

## Si algo falla

- **Error en los bloques «Sqrt» o «Delay»:** pásenme el mensaje completo. Son bloques básicos, pero los nombres de algunos parámetros cambian entre versiones de MATLAB.
- **SDR muy bajo con canal ideal (menos de 20 dB):** el retardo de compensación podría no coincidir. Pásenme la consola de `graficas_sistema`.
