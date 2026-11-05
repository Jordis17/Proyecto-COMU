# Sistema FDM + FM con receptor superheterodino

Comunicaciones Eléctricas I (EL5513), ITCR, II semestre 2026. Jordi y Abner.

Este documento resume el diseño final y sirve de base para el video. El detalle de cada cálculo y las pruebas intermedias están en `01_diagnostico_y_diseno_FDM_FM.md`.

---

## 1. El problema

Hay que transmitir tres audios de hasta 15 kHz por un mismo canal y recuperar cualquiera de ellos en el receptor. La cadena que pide el enunciado es:

```
3 audios → FDM (≤ 120 kHz) → FM (portadora de 10 MHz, configurable) → canal ideal / AWGN
        → receptor superheterodino (FI de 1.7 MHz) → demodulador FM → demultiplexor → audio 1, 2 o 3
```

Todo se hace en MATLAB/Simulink, con una interfaz tipo radio que permite elegir la portadora y el audio de salida, y que muestra la FI.

El profesor avisó que el enunciado tiene errores a propósito. Primero los buscamos y después diseñamos.

## 2. Errores del enunciado y cómo los corregimos

**1) La tabla de escalamiento no mantiene las proporciones (§5).** La tabla baja la portadora de 10 MHz a 100 kHz y la FI de 1.7 MHz a 17 kHz, pero deja el audio en 15 kHz y el multiplex en 120 kHz. Así, el multiplex pasa de ocupar el 1.2 % de la portadora a ocupar el 120 %. Con nuestra FM (ancho de Carson de 530 kHz), la señal quedaría en 100 ± 265 kHz, es decir, cruzaría 0 Hz. La FI de 17 kHz además quedaría por debajo de la frecuencia más alta del mensaje (115 kHz), y eso no es un superheterodino.

*Corrección:* dividimos **todas** las frecuencias por el mismo factor K = 100: audio, subportadoras, desviación, filtros, RF, LO y FI. Así las proporciones son las mismas que en el sistema real, y se conservan los valores de portadora y FI que da la tabla.

**2) La regla de muestrear a «5–10 veces el ancho de banda» no sirve en pasabanda (§8).** Lo que importa es la frecuencia más alta que aparece en la simulación, no el ancho de banda. En el mezclador aparece el producto suma f_c + f_LO, que llega a 20.65 MHz (con f_c = 11 MHz). Entonces hace falta f_s > 41.3 MHz, y usamos 48 MHz.

**3) Prénfasis/deénfasis: no es un error.** El enunciado dice «si la calidad es baja, considerar prénfasis/deénfasis». Con canal ideal la calidad es buena (SDR ≈ 60 dB) y no hace falta. Con AWGN sí baja, sobre todo en el canal 3, así que lo implementamos (sección 3.7).

**Detalles menores:**
- Con un mensaje formado por muchas frecuencias no se habla de índice de modulación sino de relación de desviación, DR = Δf/f_m,máx (diap. 328).
- El receptor descrito no tiene sección de RF antes del mezclador. Le agregamos un preselector, como en el esquema del curso (diap. 358).
- Escalar no ahorra cálculo por sí mismo: 1 s de audio real se convierte en 100 s simulados con 100 veces menos muestras por segundo, y el total queda igual. Lo que sí ahorra es usar una frecuencia de muestreo distinta en cada etapa (sección 3.6).

## 3. Diseño

### 3.1 Escalamiento

| Parámetro | Nominal | Simulado (÷100) |
|---|---|---|
| Audio | 15 kHz | 150 Hz |
| Subportadoras | 20, 60, 100 kHz | 200, 600, 1000 Hz |
| Ancho del multiplex | 120 kHz | 1.2 kHz |
| Desviación Δf | 150 kHz | 1.5 kHz |
| Portadora | 9–11 MHz (10 MHz nominal) | 90–110 kHz |
| FI | 1.7 MHz | 17 kHz |

La GUI siempre muestra los valores nominales, así que el escalamiento no se nota para el usuario. Los audios no se modifican: se usan las mismas muestras y se escuchan a 48 kHz.

### 3.2 Plan FDM

Cada audio modula en DSB-SC a su subportadora: m(t) = Σ x_k(t)·cos(2π f_k t).

| Canal | Subportadora | Banda |
|---|---|---|
| 1 | 20 kHz | 5–35 kHz |
| 2 | 60 kHz | 45–75 kHz |
| 3 | 100 kHz | 85–115 kHz |

- Las guardas son de 10 kHz entre canales, y quedan 5 kHz libres a cada lado (de 0 a 5 kHz y de 115 a 120 kHz).
- Se usa el 75 % de los 120 kHz disponibles.

*¿Por qué DSB-SC y no SSB?* El ejemplo del curso usa SSB con voz telefónica, que empieza en 300 Hz. Un audio real tiene contenido casi desde 0 Hz, así que separar una banda lateral necesitaría filtros casi ideales. En DSB-SC basta un multiplicador y el ancho de banda alcanza. Además, es el mismo esquema de la FM estéreo, donde L−R va en DSB-SC.

Como cada audio tiene pico 1, el multiplex puede llegar a 3; por eso se divide entre 3 antes del modulador (m_n = m/3, |m_n| ≤ 1).

### 3.3 FM

s(t) = A_c·cos[2π f_c t + 2π k_f ∫ m_n dt], con k_f = Δf = 150 kHz.

- **Relación de desviación:** DR = 150/115 = 1.30.
- **Carson:** B_T = 2(Δf + f_m,máx) = 2(150 + 115) = **530 kHz**. La f_m,máx que se usa es la del multiplex (115 kHz), no la del audio.
- **Medido en Simulink** (fuentes de prueba de ruido de 0.3 a 15 kHz): el 99 % de la potencia queda en 148 kHz, menos que Carson. La desviación pico fue de 92 kHz, no 150, porque los tres audios casi nunca llegan juntos a su pico.

*¿Por qué Δf = 150 kHz?* En FM la SNR de salida crece con Δf² (figura de mérito, diap. 377–378), pero también crece el ancho de banda. Con 150 kHz la señal cabe con margen en la FI. En una prueba con el prototipo en Python, pasar de 75 a 150 kHz mejoró unos 6 dB, que es lo esperado porque (150/75)² = 4.

### 3.4 Receptor superheterodino

- **LO automático, inyección inferior:** f_LO = f_c − 1.7 MHz. A 10 MHz, el LO queda en 8.3 MHz.
- **Mezclador:** da la diferencia (1.7 MHz, la FI) y la suma (18.3 MHz, que se filtra).
- **Imagen:** f_c − 2·f_FI = 6.6 MHz. El preselector deja pasar f_c ± 350 kHz y rechaza al menos 60 dB a partir de ±1.55 MHz, así que la imagen, que está a 3.4 MHz de distancia, queda eliminada.
- **Filtro de FI:** de 1.35 a 2.05 MHz (700 kHz). Es más ancho que Carson para tener margen.

*¿Por qué inyección inferior?* Con inyección superior el producto suma llegaría a 24 MHz y haría falta más de 48 MHz de muestreo. Además, con la inferior el espectro no sale invertido en la FI.

### 3.5 Demodulación FM y demultiplexación

**Demodulador en cuadratura.** La FI se baja a 0 Hz con cos y −sen (componentes I y Q). La frecuencia instantánea se calcula como el giro de fase entre dos muestras seguidas:

f_i[n] = (f_s / 2π) · ángulo(z[n] · z*[n−1])

Es la versión digital de f_i = (1/2π)·dφ/dt y no necesita limitador. Después viene un filtro de 120 kHz (posdetección), que deja solo el multiplex.

**Demultiplexor.** Para cada canal: pasabanda → × 2cos(2π f_k t) → pasabajos de 15 kHz.

**Retardo de los filtros.** En DSB-SC, si la subportadora del receptor llega con un error de fase φ, la salida queda multiplicada por cos φ (diap. 237–238). Los filtros FIR retrasan la señal:

- El retardo hasta el detector es τ_1 = 412 µs y τ_2 = τ_3 = 226 µs.
- Sin corregirlo, las ganancias serían +0.09, −0.87 y −0.65: el canal 1 casi desaparecería.
- Por eso el receptor usa cos(2π f_k (t − τ_k)), donde τ_k es la suma de los retardos (N−1)/(2 f_s) de los filtros.

### 3.6 Frecuencias de muestreo por etapa

| Etapa | Frecuencia más alta | f_s (nominal) |
|---|---|---|
| Audio | 15 kHz | 48 kHz |
| Multiplex | 120 kHz | 480 kHz |
| FI (después de decimar) | 2.25 MHz | 4.8 MHz |
| RF y mezclador | 20.65 MHz | 48 MHz |

Cada etapa trabaja a la tasa que necesita, y entre etapas se interpola o se decima por 10. Todos los filtros son FIR diseñados con ventana de Kaiser (60 dB de rechazo) en `disenar_fir_kaiser.m`, sin toolboxes.

### 3.7 Prénfasis y deénfasis

A la salida del discriminador, el ruido crece como f² (diap. 385). El canal 3, que está en la subportadora más alta, recibe más ruido: unos 13 dB más que el canal 1.

Como indica el curso (diap. 384), el prénfasis va antes del modulador y el deénfasis después del demodulador. Aquí el mensaje es el multiplex completo:

- Prénfasis: y[n] = g·(x[n] − a·x[n−1]).
- Deénfasis: el inverso exacto, y[n] = x[n]/g + a·y[n−1].
- Con f₀ = 30 kHz: a = 0.675 y g = 1.20. El factor g mantiene la misma desviación pico.

Sin ruido, los dos filtros se cancelan y no cambian nada. Con ruido, el prénfasis no reduce el ruido total, lo **reparte**. La teoría da:

| Canal 1 | Canal 2 | Canal 3 |
|---|---|---|
| −5.8 dB | −1.3 dB | +2.0 dB |

Mejora el canal más ruidoso a costa del que tenía SNR de sobra, y la diferencia entre canales baja de unos 13 dB a unos 6 dB. La prueba en Python dio lo mismo: −5.7 / −1.2 / +1.8 dB. **Falta confirmarlo en Simulink** con `analisis_awgn.m`.

### 3.8 Canal AWGN

Se usa la definición del curso (Haykin, diap. 377): (SNR)_C = (A_c²/2) / (W·N₀), con W = 120 kHz. El ruido se suma a la señal de RF con varianza N₀·f_s/2.

## 4. Implementación

**Modelo Simulink** (`sistema_fdm_fm.slx`, generado por `construir_modelo.m`). Solo usa bloques básicos, con solver discreto de paso fijo. Tiene cinco subsistemas:

```
Transmisor_FDM → Modulador_FM → Canal → Receptor_Superheterodino → Demultiplexor_FDM
```

Ningún bloque tiene números escritos a mano: todos leen la estructura `P` de `params_sistema.m`. Ese archivo también revisa el diseño antes de simular: bandas dentro de 120 kHz, Nyquist, imagen rechazada, producto suma fuera de la FI y filtros de 60 dB.

**GUI** (`radio_fdm_fm.m`):

- Una perilla para la portadora (9–11 MHz). Al moverla se recalculan al instante el LO, la imagen y el preselector.
- Muestra la FI, el LO, la imagen, Δf y Carson.
- Un selector de audio 1/2/3. Actúa después del demultiplexor, así que no vuelve a simular ni toca el LO.
- Casillas para AWGN y para el prénfasis, y un campo de desintonía.
- Gráficas del espectro de RF, la salida del mezclador, el multiplex recuperado y el audio original frente al recuperado.
- Botones para escuchar el audio original y el recuperado.

**Scripts:**

| Script | Qué hace |
|---|---|
| `main` | Imprime el diseño y abre la radio |
| `graficas_sistema` | Figuras de cada etapa con canal ideal |
| `analisis_awgn` | Barrido de ruido, con y sin prénfasis |
| `probar_audio_real` | Pasa tres WAV por el sistema y guarda los audios recuperados |

## 5. Resultados (Simulink R2026a)

**Canal ideal:**

- La salida de Simulink coincide con una versión del mismo sistema escrita en MATLAB, con diferencias menores a 10⁻⁹.
- Audios recuperados: SDR de 60.3 / 59.4 / 57.1 dB, con ganancia ≈ 1.
- Con la GUI a 10 MHz el LO queda en 8.30 MHz; a 11 MHz, en 9.30 MHz. En los dos casos el SDR es de 69 dB (fuente demo).
- Con 600 kHz de desintonía, la señal cae fuera de la FI y el SDR baja a 0.9 dB. Esto muestra que el receptor sí selecciona la portadora.

**Canal AWGN** (SDR en dB):

| (SNR)_C | CNR en Carson | Canal 1 | Canal 2 | Canal 3 |
|---|---|---|---|---|
| 40 dB | 33.5 dB | 41.9 | 31.2 | 27.7 |
| 30 dB | 23.5 dB | 32.0 | 21.3 | 17.7 |
| 20 dB | 13.5 dB | 21.9 | 11.5 | 8.2 |
| 16 dB | 9.5 dB | 11.9 | 6.6 | 4.4 |
| 14 dB | 7.5 dB | 4.1 | 2.7 | 2.1 |
| 10 dB | 3.5 dB | 0.4 | 0.2 | 0.3 |

- **Sobre el umbral:** los resultados quedan a menos de 1 dB de la fórmula teórica.
- **Diferencia entre canales:** el canal 3 queda unos 14 dB por debajo del canal 1, por el ruido que crece con f².
- **Umbral FM:** por debajo de una CNR de unos 11 dB en el ancho de Carson, la calidad cae de golpe (diap. 381–382).
- **Sin preselector:** con (SNR)_C = 25 dB, el SDR baja unos 3 dB, porque también entra el ruido de la banda imagen.

**Prénfasis:** pendiente de medir en Simulink (sección 3.7).

**Audios reales:** pendiente (`probar_audio_real`).

## 6. Limitaciones

- No funciona en tiempo real. Cada cambio en la GUI vuelve a simular, y un segundo de audio tarda unos 4–5 minutos en modo acelerado.
- La portadora del receptor se genera con la fase correcta porque conocemos el retardo de los filtros. En un receptor real se usaría un tono piloto o un PLL, como en la FM estéreo.
- El canal solo tiene ruido blanco: no hay desvanecimiento ni interferencias.

## 7. Propuesta para el video (~10 min)

| Min | Escena | Qué mostrar |
|---|---|---|
| 0–1 | El problema | Diagrama de bloques del sistema |
| 1–3 | Errores del enunciado | Tabla de escalamiento con el cálculo de la FM que cruza 0 Hz; la regla de muestreo; el prénfasis como condición |
| 3–5 | Diseño | Plan FDM y su espectro, Δf/DR/Carson con el espectro FM, LO, imagen y FI |
| 5–7 | Modelo y GUI | Recorrido por los subsistemas; cambiar la portadora y ver que el LO cambia y la FI queda en 1.7 MHz; elegir audio 1, 2 o 3 y escucharlos |
| 7–9 | AWGN | Gráfica del barrido; por qué el canal 3 sale peor; umbral; efecto del prénfasis |
| 9–10 | Conclusiones | Lo que se cumplió y las limitaciones |

Los dos debemos poder explicar cualquier parte, así que conviene que cada uno practique también las escenas del otro.
