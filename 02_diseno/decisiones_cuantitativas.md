# Decisiones del diseño, con números

Para cada decisión: qué opciones comparamos, qué dio cada una y por qué escogimos la que quedó. Al lado de cada número está de dónde sale:
- **Simulink:** medido con el modelo completo en MATLAB R2026a.
- **Python:** prototipo en `04_verificacion_python/`.
- **Cálculo:** fórmula del curso con los parámetros del diseño.

SDR = relación señal a distorsión del audio recuperado frente al original (`comparar_senales.m`), en dB. Los tres valores separados por «/» son los audios 1, 2 y 3.

---

## 1. Escalamiento de frecuencias (§5 del enunciado)

| Opción | Qué pasa | Fuente |
|---|---|---|
| Tabla del enunciado (portadora 100 kHz, FI 17 kHz, audio y FDM sin escalar) | La FM ocupa 100 ± 265 kHz, o sea de −165 a 365 kHz: **cruza 0 Hz**. La FI (17 kHz) queda por debajo del mensaje (115 kHz) | Cálculo |
| Escalar solo la RF (por ejemplo ÷5) | Funciona, pero B_T / f_FI pasa de **0.31** (real) a **1.56**: la FI deja de ser de banda angosta | Cálculo |
| **Escalar todo ÷100 (elegida)** | Todas las proporciones quedan iguales a las del sistema real: B_T / f_FI = 0.31 | Cálculo |

**Por qué:** es la única opción que cumple la regla del propio §5, «mantener las relaciones relativas». Los audios se siguen escuchando bien, porque basta reproducirlos a 48 kHz.

## 2. Frecuencia de muestreo (§8)

| Opción | Valor | ¿Alcanza? | Fuente |
|---|---|---|---|
| Regla del enunciado: 5–10 veces el ancho de banda (530 kHz) | 2.65–5.3 MHz | No: el producto suma del mezclador llega a 20.65 MHz | Cálculo |
| Nyquist con la frecuencia más alta | > 41.3 MHz | Sí | Cálculo |
| **Elegida: 48 MHz en RF, con multirritmo** | 48 kHz audio, 480 kHz multiplex, 4.8 MHz FI, 48 MHz RF | Sí, con margen | Simulink |

**Por qué:** en pasabanda, el muestreo lo fija la frecuencia más alta que aparece, no el ancho de banda. Cada etapa usa la tasa que necesita, así no se simula todo a 48 MHz.

## 3. Plan FDM

| Opción | Ocupación de los 120 kHz | Problema | Fuente |
|---|---|---|---|
| **DSB-SC en 20, 60 y 100 kHz, guardas de 10 kHz (elegida)** | 90 kHz (**75 %**) | Ninguno: cabe con margen | Cálculo |
| SSB | 45 kHz (37.5 %) | El audio real tiene contenido casi desde 0 Hz: separar una banda lateral necesita un filtro con transición casi nula | Cálculo |

**Por qué:** el ancho de banda alcanza para DSB-SC. Además, es el mismo esquema que el canal L−R de la FM estéreo.

## 4. Desviación de frecuencia Δf

| Δf | Carson 2(Δf + 115 kHz) | ¿Cabe en la FI de 700 kHz? | Efecto en la SNR | Fuente |
|---|---|---|---|---|
| 75 kHz | 380 kHz | Sí, de sobra | Referencia | Cálculo |
| **150 kHz (elegida)** | **530 kHz** | Sí, con 170 kHz de margen | **+6 dB** frente a 75 kHz | Cálculo (SNR ∝ Δf²) y Python |
| 200 kHz | 630 kHz | Quedaría al borde (35 kHz por lado) | +2.5 dB más frente a 150 kHz | Cálculo |

- Medido en Simulink: el 99 % de la potencia queda en **148 kHz**, bastante menos que Carson.
- Relación de desviación: DR = 150 / 115 = **1.30**.

**Por qué:** 150 kHz da la mayor SNR que todavía cabe con margen en la FI.

## 5. Inyección del oscilador local

| Opción | f_LO a 10 MHz | Producto suma máximo | Muestreo necesario | Fuente |
|---|---|---|---|---|
| **Inferior: f_LO = f_c − 1.7 MHz (elegida)** | 8.3 MHz | 20.65 MHz | > 41.3 MHz: **cabe en 48 MHz** | Cálculo |
| Superior: f_LO = f_c + 1.7 MHz | 11.7 MHz | 24.05 MHz | > 48.1 MHz: **no cabe en 48 MHz** | Cálculo |

**Por qué:** con la inferior basta 48 MHz y el espectro no sale invertido en la FI.

## 6. Sección de RF (preselector)

| Caso | Resultado | Fuente |
|---|---|---|
| Imagen a 6.6 MHz (3.4 MHz de la portadora) con preselector | Rechazo de al menos **60 dB** desde ±1.55 MHz | Cálculo del filtro |
| Sin preselector, (SNR)_C = 25 dB | El SDR baja unos **3 dB**, porque entra también el ruido de la banda imagen | Simulink (versión anterior del demodulador; el efecto no depende del demodulador) |

## 7. Compensación del retardo en el demultiplexor

| Caso | Ganancia de cada canal | Fuente |
|---|---|---|
| Sin compensar | **+0.09 / −0.87 / −0.65**: el canal 1 casi desaparece | Cálculo: cos(2π f_k τ_k) |
| **Compensando τ_k = 412 / 226 / 226 µs (elegida)** | 1 / 1 / 1. SDR 43.3 / 52.2 / 54.4 dB | Simulink |

## 8. Demodulador FM (la decisión más grande)

Los tres demoduladores se probaron con el mismo modelo, la misma señal y el mismo ruido. SDR en dB, audios 1 / 2 / 3 (Simulink):

| (SNR)_C | Detector de cuadratura | PLL | **Discriminador (elegido)** |
|---|---|---|---|
| Canal ideal | 60.3 / 59.4 / 57.1 | 47.6 / 38.7 / 34.0 | **43.3 / 52.2 / 54.4** |
| 30 dB | 32.0 / 21.3 / 17.7 | 31.7 / 21.1 / 17.4 | 31.6 / 21.3 / 17.7 |
| 20 dB | 21.9 / 11.5 / 8.2 | 21.6 / 11.3 / 8.0 | 18.4 / 10.9 / 8.0 |
| 16 dB | 11.9 / 6.6 / 4.4 | 16.7 / 7.3 / 4.7 | 3.9 / 2.9 / 2.4 |

**Qué muestran los números:**
- **Con ruido moderado (30 dB)**, los tres dan lo mismo, con 0.4 dB de diferencia como máximo. Ahí limita el ruido, no el demodulador.
- **Con canal ideal**, el más limpio es el detector de cuadratura. El discriminador da 43 dB o más en los tres audios, y a ese nivel la distorsión ya no se oye.
- **Cerca del umbral (16 dB)**, el PLL aguanta más. El discriminador es el primero en caer, unos 2–4 dB antes.

**Por qué el discriminador:** es el demodulador que se vio en el curso (diap. 342–345 y 375). El detector de cuadratura no se vio en el curso. Elegirlo cuesta unos 17 dB en el audio 1 con canal ideal, pero sigue por encima de 43 dB. Sobre el umbral, que es donde trabaja el sistema, no cuesta nada.

**Cómo se hizo el limitador del discriminador:**

| Variante | Resultado | Fuente |
|---|---|---|
| Sin limitador | Falla con ruido: la salida queda multiplicada por la amplitud | Python |
| Limitador que recorta la onda (o detector con rectificador) | **9–14 dB** con canal ideal: los armónicos se pliegan a 4.8 MHz | Python |
| Divide por la amplitud, sin mínimo | Con (SNR)_C = 20 dB cae a **0 dB** (picos al dividir entre una amplitud casi nula) | Python |
| **Divide por la amplitud, con mínimo de 0.3 (elegida)** | 43–54 dB con canal ideal; **18.4 dB** en el audio 1 a 20 dB | Simulink |

## 9. Prénfasis y deénfasis

**¿Hace falta?** Con canal ideal no: el SDR es de 43–54 dB. Con ruido sí, porque el audio 3 sale unos 14 dB peor que el audio 1: el ruido a la salida del discriminador crece con f².

**Elección de f₀.** Cambio teórico de la SNR de cada canal, con la misma desviación pico:

| f₀ | Audio 1 | Audio 2 | Audio 3 |
|---|---|---|---|
| 10 kHz | −8.9 dB | −1.5 dB | +2.4 dB |
| 20 kHz | −7.2 dB | −1.4 dB | +2.2 dB |
| **30 kHz (elegida)** | **−5.8 dB** | **−1.3 dB** | **+2.0 dB** |
| 60 kHz | −3.1 dB | −0.9 dB | +1.4 dB |
| 100 kHz | −1.4 dB | −0.5 dB | +0.8 dB |

Bajar f₀ de 30 a 10 kHz le da al audio 3 solo 0.4 dB más, pero le quita 3.1 dB más al audio 1. Por eso 30 kHz es el compromiso. Este cálculo es la misma fórmula de `params_sistema.m` (`P.enf.mejora_dB`), evaluada con varios f₀.

**Medido con f₀ = 30 kHz:**

| Prueba | Audio 1 | Audio 2 | Audio 3 |
|---|---|---|---|
| `analisis_awgn`, (SNR)_C de 20 a 40 dB | −5.4 dB | −1.1 dB | +2.0 dB |
| GUI, fuente demo, 25 dB, 10 y 11 MHz | −5.5 dB | −1.3 dB | +1.9 dB |

- A 25 dB, la diferencia entre el audio 1 y el audio 3 baja de **13.9 dB** (26.7 frente a 12.8) a **6.3 dB** (21.1 frente a 14.8).
- **Decisión:** se deja como opción en la GUI. Mejora el audio que limita la calidad del sistema sin cambiar la desviación ni el ancho de Carson.

## 10. Resumen

| Decisión | Elegido | Número que la justifica |
|---|---|---|
| Escalamiento | Todo ÷100 | B_T / f_FI = 0.31, igual que el real (la tabla del enunciado cruza 0 Hz) |
| Muestreo RF | 48 MHz, multirritmo | Producto suma de 20.65 MHz → hace falta más de 41.3 MHz |
| FDM | DSB-SC 20/60/100 kHz | Ocupa el 75 % de los 120 kHz |
| Δf | 150 kHz | +6 dB frente a 75 kHz; Carson de 530 kHz dentro de la FI de 700 kHz |
| Inyección | Inferior | Suma de 20.65 MHz frente a 24.05 MHz con la superior |
| Preselector | Sí | Imagen rechazada al menos 60 dB; sin él, −3 dB de SDR |
| Retardo | Compensado | Sin compensar, el canal 1 queda con ganancia 0.09 |
| Demodulador | Discriminador | Es el del curso; ≥ 43 dB ideal; igual a los otros sobre el umbral |
| Prénfasis | f₀ = 30 kHz, opcional | Audio 3 +2.0 dB; diferencia entre audios de 13.9 a 6.3 dB |
