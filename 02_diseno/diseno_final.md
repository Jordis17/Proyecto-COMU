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

**3) Prénfasis/deénfasis: no es un error.** El enunciado dice «si la calidad es baja, considerar prénfasis/deénfasis». Con canal ideal la calidad es buena (SDR de 43 a 54 dB) y no hace falta. Con AWGN sí baja, sobre todo en el canal 3, así que lo implementamos (sección 3.7).

**Detalles menores:**
- Con un mensaje formado por muchas frecuencias no se habla de índice de modulación sino de relación de desviación, DR = Δf/f_m,máx (diap. 328).
- El receptor descrito no tiene sección de RF antes del mezclador. Le agregamos una sección de RF (preselector), como en el esquema del curso (diap. 358).
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

Como cada audio tiene pico 1, el multiplex puede llegar a 3; por eso se divide entre 3 antes del modulador. Así el mensaje que entra al modulador, m(t), nunca pasa de 1.

### 3.3 FM

s(t) = A_c·cos[2π f_c t + 2π k_f ∫ m(τ) dτ], con k_f = Δf = 150 kHz. Es la notación del curso (diap. 309): m(t) es el mensaje (aquí, el multiplex) y s(t) la señal FM.

- **Relación de desviación:** DR = 150/115 = 1.30.
- **Carson:** B_T = 2(Δf + f_m,máx) = 2(150 + 115) = **530 kHz**. La f_m,máx que se usa es la del multiplex (115 kHz), no la del audio.
- **Medido en Simulink** (fuentes de prueba de ruido de 0.3 a 15 kHz): el 99 % de la potencia queda en 148 kHz, menos que Carson. La desviación pico fue de 92 kHz, no 150, porque los tres audios casi nunca llegan juntos a su pico.

*¿Por qué Δf = 150 kHz?* En FM la SNR de salida crece con Δf² (figura de mérito, diap. 377–378), pero también crece el ancho de banda. Con 150 kHz la señal cabe con margen en la FI. En una prueba con el prototipo en Python, pasar de 75 a 150 kHz mejoró unos 6 dB, que es lo esperado porque (150/75)² = 4.

### 3.4 Receptor superheterodino

- **LO automático, inyección inferior:** f_LO = f_c − 1.7 MHz. A 10 MHz, el LO queda en 8.3 MHz.
- **Mezclador:** da la diferencia (1.7 MHz, la FI) y la suma (18.3 MHz, que se filtra).
- **Imagen:** f_c − 2·f_FI = 6.6 MHz. La sección de RF (preselector) deja pasar f_c ± 350 kHz y rechaza al menos 60 dB a partir de ±1.55 MHz, así que la imagen, que está a 3.4 MHz de distancia, queda eliminada.
- **Sección de FI:** filtro de 1.35 a 2.05 MHz (700 kHz). Es más ancho que Carson para tener margen.

*¿Por qué inyección inferior?* Con inyección superior el producto suma llegaría a 24 MHz y haría falta más de 48 MHz de muestreo. Además, con la inferior el espectro no sale invertido en la FI.

### 3.5 Demodulación FM y demultiplexación

**Demodulador FM: discriminador del curso** (diap. 342–345, 375). Tiene tres partes:

1. **Limitador.** Deja la FI con amplitud constante. En una simulación digital, recortar la onda genera armónicos que se pliegan sobre la señal, así que se divide la FI por su amplitud, medida con un detector de ley cuadrática: A = √(2·pasabajos(FI²)). La amplitud nunca se toma menor a 0.3, como un limitador real, que tiene ganancia finita.
2. **Detector de pendiente (derivador).** Es un FIR derivador de 63 coeficientes. Al derivar cos θ(t), la amplitud queda proporcional a dθ/dt = 2π f_i: convierte la FM en AM.
3. **Detector de envolvente.** Es de ley cuadrática: √(2·pasabajos(d²)) = 2π f_i. Dividiendo entre 2π y restando f_FI queda la desviación k_f·m(t).

Sin limitador no funciona: la salida sería amplitud × frecuencia, y el ruido de amplitud se multiplicaría por toda la FI.

Después viene el filtro posdetección (diap. 376), de 120 kHz, que deja solo el multiplex.

*Alternativas probadas* (`comparacion_demoduladores.md`):
- **PLL** (diap. 347–354): con ruido moderado da lo mismo y aguanta unos dB más antes del umbral, pero con canal ideal distorsiona más (34–48 dB).
- **Detector de cuadratura:** da 57–60 dB, pero no se vio en el curso.

**Demultiplexor.** Para cada canal: pasabanda → oscilador local 2cos(2π f_k (t − τ_k)) → detector coherente (diap. 230) → pasabajos de 15 kHz.

**Retardo de los filtros.** En DSB-SC, si la subportadora del receptor llega con un error de fase φ, la salida queda multiplicada por cos φ (diap. 237–238). Los filtros FIR retrasan la señal:

- El retardo hasta el detector es τ_1 = 421 µs y τ_2 = τ_3 = 236 µs.
- Sin corregirlo, las ganancias serían −0.90, +0.52 y −0.79: el canal 2 perdería la mitad de su amplitud y los otros dos saldrían invertidos. Con otros filtros podría ser peor (con el detector de cuadratura, el canal 1 quedaba en 0.09).
- Por eso el receptor usa cos(2π f_k (t − τ_k)), donde τ_k es la suma de los retardos (N−1)/(2 f_s) de los filtros.

### 3.6 Frecuencias de muestreo por etapa

| Etapa | Frecuencia más alta | f_s (nominal) |
|---|---|---|
| Audio | 15 kHz | 48 kHz |
| Multiplex | 120 kHz | 480 kHz |
| FI (después de bajar la tasa) | 2.25 MHz | 4.8 MHz |
| RF y mezclador | 20.65 MHz | 48 MHz |

Cada etapa trabaja a la tasa que necesita. Entre etapas, los bloques «Subir tasa 1 a 10» (con un filtro interpolador) y «Bajar tasa 10 a 1» (después de un filtro antitraslape, diap. 400) cambian la frecuencia de muestreo por 10. Todos los filtros son FIR diseñados con ventana de Kaiser (60 dB de rechazo) en `disenar_fir_kaiser.m`, sin toolboxes.

### 3.7 Prénfasis y deénfasis

A la salida del discriminador, el ruido crece como f² (diap. 385). El canal 3, que está en la subportadora más alta, recibe más ruido: unos 13 dB más que el canal 1.

Como indica el curso (diap. 384), el prénfasis va antes del modulador y el deénfasis después del demodulador. Aquí el mensaje es el multiplex completo:

- Prénfasis: y[n] = g·(x[n] − a·x[n−1]).
- Deénfasis: el inverso exacto, y[n] = x[n]/g + a·y[n−1].
- Con f₀ = 30 kHz: a = 0.675 y g = 1.20. El factor g mantiene la misma desviación pico.
- En el modelo son los bloques «Filtro de preénfasis», al final del transmisor, y «Filtro de deénfasis», después del filtro posdetección. En la radio se activan con una casilla.

Sin ruido, los dos filtros se cancelan y no cambian nada. Con ruido, el prénfasis no reduce el ruido total, lo **reparte**. La teoría da:

| Canal 1 | Canal 2 | Canal 3 |
|---|---|---|
| −5.8 dB | −1.3 dB | +2.0 dB |

Mejora el canal más ruidoso a costa del que tenía SNR de sobra. **Medido en Simulink** (`analisis_awgn`, discriminador, (SNR)_C de 20 a 40 dB): −5.4 / −1.1 / +2.0 dB, casi igual a la teoría. A 25 dB, la diferencia entre el canal 1 y el canal 3 baja de 13.9 a 6.3 dB. Con canal ideal el SDR no cambia.

### 3.8 Canal AWGN

Se usa la definición del curso (Haykin, diap. 377): (SNR)_C = (A_c²/2) / (W·N₀), con W = 120 kHz. El ruido se suma a la señal de RF con varianza N₀·f_s/2.

## 4. Implementación

**Modelo Simulink** (`sistema_fdm_fm.slx`, generado por `construir_modelo.m`). Solo usa bloques básicos, con solver discreto de paso fijo. Tiene cinco subsistemas:

```
Transmisor FDM → Modulador FM → Canal → Receptor superheterodino → Demultiplexor FDM
```

Las señales principales llevan nombre con la notación del curso:

| Señal | Qué es | Diap. |
|---|---|---|
| x1(t), x2(t), x3(t) | Los tres audios | 264 |
| m(t) multiplex | Mensaje que entra al modulador FM | 309, 384 |
| s(t) señal FM | Señal modulada | 365 |
| x(t) = s(t) + w(t) | Lo que llega al receptor (w(t) es el ruido) | 365 |
| m(t) recuperado | Multiplex a la salida del receptor | — |
| audio 1, 2, 3 recuperado | Salidas del demultiplexor | — |

Los bloques llevan nombres en español con los términos del curso, y cada nivel tiene los mismos bloques que los esquemas de la presentación. Dentro del receptor: «Sección de RF (preselector)», «Oscilador local», «Mezclador», «Sección de FI», «Demodulador FM», «Filtro posdetección» y «Filtro de deénfasis». En el demultiplexor, cada canal tiene «pasabanda», «oscilador local», «detector coherente» y «pasabajos 15 kHz». Los bloques que solo existen por la simulación digital (cambios de tasa, filtro antitraslape, escalas) están agrupados un nivel más adentro. La correspondencia con el curso está en `correspondencia_curso_modelo.md` y la explicación de cada diagrama en `explicacion_diagramas.md`.

Ningún bloque tiene números escritos a mano: todos leen la estructura `P` de `params_sistema.m`. Ese archivo también revisa el diseño antes de simular: bandas dentro de 120 kHz, Nyquist, imagen rechazada, producto suma fuera de la FI y filtros de 60 dB.

**GUI** (`radio_fdm_fm.m`):

- Un dial para la portadora (9–11 MHz) con botones de ±0.1 MHz. Al moverlo se recalculan al instante el LO, la imagen y el preselector, y se redibuja el plan de frecuencias sin simular.
- Muestra la FI, el LO, la imagen, Δf y Carson.
- Botones Audio 1/2/3. Actúan después del demultiplexor, así que no vuelven a simular ni tocan el LO.
- Fuente de audio (señales de prueba o grabaciones), casillas para AWGN (con una barra de 10 a 40 dB) y prénfasis, y un campo de desintonía.
- Siete gráficas en dos pestañas: plan de frecuencias, espectro de RF, salida del mezclador y FI; multiplex, SDR de los tres audios y audio en el tiempo.
- Cada simulación se guarda (también en `radio_guardado.mat`), y al volver a una combinación ya simulada se muestra sin simular.

**Scripts:**

| Script | Qué hace | ¿Se entrega? |
|---|---|---|
| `main` | Imprime el diseño y abre la radio | Sí |
| `graficas_sistema` | Figuras de cada etapa con canal ideal | Sí |
| `analisis_awgn` | Barrido de ruido, con y sin prénfasis | No (resultados en el video; va en el respaldo) |
| `probar_audio_real` | Pasa tres WAV por el sistema y guarda los audios recuperados | No (los WAV recuperados se usan en el video; va en el respaldo) |

**Entrega.** Al profesor se le manda el video y `entrega_FDM_FM.zip`, que contiene el modelo `sistema_fdm_fm.slx`, 8 archivos `.m` (`main`, `params_sistema`, `disenar_fir_kaiser`, `generar_fuentes`, `radio_fdm_fm`, `graficas_sistema`, `graficar_espectro`, `comparar_senales`), los tres WAV y un `LEEME.txt`. El script `preparar_entrega` la arma y comprueba que funcione sola. También crea `entrega_FDM_FM_respaldo.zip`, con los 10 `.m`, que no se manda.

## 5. Resultados (Simulink R2026a)

**Canal ideal:**

- El transmisor, el canal y el receptor hasta la FI se verificaron contra una versión del mismo sistema escrita en MATLAB, con diferencias menores a 10⁻⁹.
- Audios recuperados (`graficas_sistema`): SDR de 43.3 / 52.2 / 54.4 dB. Los audios recuperados se superponen con los originales.
- Con la GUI a 10 MHz el LO queda en 8.30 MHz; a 11 MHz, en 9.30 MHz.
- Con 600 kHz de desintonía, la señal cae fuera de la FI y el SDR baja a 0.9 dB. Esto muestra que el receptor sí selecciona la portadora.

**Canal AWGN** (`analisis_awgn`, discriminador, SDR en dB):

| (SNR)_C | CNR en Carson | Canal 1 | Canal 2 | Canal 3 |
|---|---|---|---|---|
| 40 dB | 33.5 dB | 39.7 | 31.2 | 27.6 |
| 30 dB | 23.5 dB | 31.6 | 21.3 | 17.7 |
| 25 dB | 18.5 dB | 26.7 | 16.3 | 12.8 |
| 20 dB | 13.5 dB | 18.4 | 10.9 | 8.0 |
| 18 dB | 11.5 dB | 10.3 | 7.1 | 5.4 |
| 16 dB | 9.5 dB | 3.9 | 2.9 | 2.4 |
| 14 dB | 7.5 dB | 1.3 | 0.9 | 0.9 |

- **Sobre el umbral:** los resultados quedan cerca de la fórmula teórica (a 1–3 dB).
- **Diferencia entre canales:** el canal 3 queda unos 14 dB por debajo del canal 1, por el ruido que crece con f².
- **Umbral FM:** por debajo de una CNR de unos 14 dB en el ancho de Carson ((SNR)_C ≈ 20 dB), la calidad cae rápido (diap. 381–382). Un PLL aguanta unos 3–4 dB más (ver `comparacion_demoduladores.md`).
- **Sin preselector:** con (SNR)_C = 25 dB, el SDR baja unos 3 dB, porque también entra el ruido de la banda imagen. Se midió con la versión anterior del demodulador; el efecto no depende del demodulador.

**Prénfasis** (f₀ = 30 kHz, misma (SNR)_C y mismo ruido, SDR en dB):

| (SNR)_C | Sin: c1 / c2 / c3 | Con: c1 / c2 / c3 |
|---|---|---|
| 40 dB | 39.7 / 31.2 / 27.6 | 35.6 / 30.1 / 29.7 |
| 30 dB | 31.6 / 21.3 / 17.7 | 26.1 / 20.2 / 19.8 |
| 25 dB | 26.7 / 16.3 / 12.8 | 21.1 / 15.2 / 14.8 |
| 20 dB | 18.4 / 10.9 / 8.0 | 12.2 / 9.7 / 9.8 |
| 18 dB | 10.3 / 7.1 / 5.4 | 5.3 / 5.6 / 6.8 |
| 16 dB | 3.9 / 2.9 / 2.4 | 1.1 / 2.0 / 3.2 |

Sobre el umbral, el preénfasis cambia el SDR en −5.4 / −1.1 / +2.0 dB, casi lo mismo que predice la teoría (−5.8 / −1.3 / +2.0). Con canal ideal no cambia nada (44.8 / 55.9 / 58.5 dB con preénfasis).

**Audios reales** (grabaciones del equipo, 2 s, 10 MHz):

| Caso | Audio 1 | Audio 2 | Audio 3 |
|---|---|---|---|
| Canal ideal (`probar_audio_real` y radio) | 49.1 | 63.4 | 55.2 |
| (SNR)_C = 25 dB, sin prénfasis (radio) | 18.3 | 11.3 | 6.1 |
| (SNR)_C = 25 dB, con prénfasis (radio) | 12.7 | 10.2 | 7.7 |

Con ruido, la voz sale peor que las señales de prueba porque su pico está unos 17–18 dB sobre su valor rms (una senoide, 3 dB): con el mismo pico lleva menos potencia.

## 6. Limitaciones

- No funciona en tiempo real. Cada combinación nueva hay que simularla: 2 s de audio tardaron 283 s en modo acelerado. La radio guarda lo ya simulado para no repetirlo.
- La portadora del receptor se genera con la fase correcta porque conocemos el retardo de los filtros. En un receptor real se usaría un tono piloto o un PLL, como en la FM estéreo.
- El canal solo tiene ruido blanco: no hay desvanecimiento ni interferencias.

## 7. Video

El guion está en `guion_video.md` y la justificación de cada decisión, con números, en `decisiones_cuantitativas.md`.
