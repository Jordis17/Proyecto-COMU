# Explicación de los diagramas del modelo, uno por uno

Sigue el orden de `Diagramas nuevos.pdf` (23 páginas). Todas las frecuencias están en **valores nominales**: en el modelo están divididas por K = 100.

## Antes de empezar: cómo leer los íconos de Simulink

| Ícono | Bloque de Simulink | Qué hace |
|---|---|---|
| `num(z)/1` | Discrete Filter (FIR) | Filtro digital: y[n] = Σ h[k]·x[n−k]. Los coeficientes h los calcula `params_sistema.m` |
| `num(z)/den(z)` | Discrete Filter (IIR) | Igual, pero con realimentación. Solo lo usa el deénfasis |
| `Db_buf` o `Buf` | Rate Transition | Conecta dos partes con distinta frecuencia de muestreo |
| Onda cuadrada de pulsos | Pulse Generator | Tren de pulsos: un 1 cada 10 muestras |
| Senoide | Sine Wave | Coseno o seno muestreado: portadoras y osciladores |
| `x` | Product | Multiplica dos señales: mezcladores y moduladores |
| `+ +` | Add | Suma |
| Triángulo (`-K-`, `2*pi*P.kf`…) | Gain | Multiplica por una constante |
| `K Ts z/(z−1)` | Discrete-Time Integrator | Integral digital (suma acumulada) |
| `12:34` | Digital Clock | Da el tiempo t de cada muestra |
| `1/z` | Unit Delay | Retrasa una muestra: da el valor anterior |
| `cos`, `atan2` | Trigonometric Function | Coseno; ángulo de un número complejo |
| Óvalo numerado | Inport / Outport | Entradas y salidas de un subsistema |
| `fuente.audio1` | From Workspace | Lee los audios desde MATLAB |
| `out.sim_…` | To Workspace («Guardar …») | Guarda una señal para las gráficas. No forma parte del sistema |

Hay una idea que se repite en casi todos los diagramas. En una simulación digital, cada señal necesita una frecuencia de muestreo mayor que el doble de su frecuencia más alta (Nyquist, diap. 391–397). El audio llega a 15 kHz, pero la señal de RF llega a unos 20 MHz. Si todo trabajara a 48 MHz, la simulación sería muy lenta. Por eso **cada etapa usa su propia frecuencia de muestreo**, y por eso aparecen los bloques de «subir tasa» y «bajar tasa».

| Etapa | Frecuencia de muestreo |
|---|---|
| Audio | 48 kHz |
| Multiplex | 480 kHz |
| FI | 4.8 MHz |
| RF | 48 MHz |

---

## Página 1. Nivel principal: el sistema completo

```
Audio 1..3 → Transmisor FDM → Modulador FM → Canal → Receptor superheterodino → Demultiplexor FDM → audio 1..3 recuperado
```

| Bloque | Qué es |
|---|---|
| **Audio 1, 2, 3** (`fuente.audio1`…) | Los tres audios, que salen de `generar_fuentes.m`. Salen como x1(t), x2(t), x3(t) |
| **Transmisor FDM** | Pone cada audio en su subportadora y los suma: el multiplex m(t) |
| **Modulador FM** | Modula en FM la portadora de 10 MHz con m(t). Sale s(t) |
| **Canal** | Suma ruido: x(t) = s(t) + w(t). Con ruido 0 es el canal ideal |
| **Receptor superheterodino** | Baja la señal a la FI de 1.7 MHz, demodula la FM y entrega m(t) recuperado |
| **Demultiplexor FDM** | Separa los tres audios del multiplex |
| **Guardar …** | Guardan señales para las gráficas y la GUI. No son parte del sistema |

**Por qué el transmisor tiene dos salidas:**
- «m(t) al modulador» es la señal que se transmite: normalizada y con preénfasis.
- «multiplex m(t)» es el multiplex sin normalizar, solo para graficar su espectro.

**Por qué el receptor tiene tres salidas:** «m(t) recuperado» es la salida real. «Señal de FI» y «salida del mezclador» solo se guardan para mostrar sus espectros.

**Por qué el modulador tiene una segunda salida:** «m(t) a tasa RF» se usa para medir la desviación de frecuencia.

## Página 2. Canal

```
Ruido blanco gaussiano → Nivel de ruido (σ) → Suma de ruido w(t) ← s(t)  →  x(t)
```

| Bloque | Qué hace | Por qué |
|---|---|---|
| **Ruido blanco gaussiano** | Números aleatorios gaussianos de varianza 1, uno por muestra (a 48 MHz) | Es el ruido AWGN del modelo del curso (diap. 365) |
| **Nivel de ruido** (`P.sigma_ruido`) | Multiplica el ruido por σ | σ sale de la (SNR)_C que se pide (diap. 377): σ² = N₀·f_s/2 |
| **Suma de ruido w(t)** | x(t) = s(t) + w(t) | Lo que llega al receptor |

Con canal ideal, σ = 0 y x(t) = s(t).

## Página 3. Demultiplexor FDM

Tres ramas iguales, una por canal (diap. 264 y 230):

```
m(t) recuperado → Canal k pasabanda → Canal k detector coherente → Canal k pasabajos 15 kHz → audio k recuperado
                                              ↑
                                    Canal k oscilador local
```

| Bloque | Qué hace | Por qué |
|---|---|---|
| **Canal k pasabanda** | Deja pasar solo la banda del canal: 5–35, 45–75 u 85–115 kHz | Separa el canal de los otros dos (FDM, diap. 264) |
| **Canal k oscilador local** | 2·cos(2π f_k (t − τ_k)), con f_k = 20, 60 o 100 kHz | La portadora local de la detección coherente. Lleva la fase corregida por el retardo de los filtros, τ_k (diap. 237–238) |
| **Canal k detector coherente** | Multiplica la señal del canal por la portadora local | Lleva el audio de vuelta a 0 Hz: f(t)cos ω t · 2cos ω t = f(t) + f(t)cos 2ωt (diap. 230) |
| **Canal k pasabajos 15 kHz** | Subsistema (páginas 4–6) | Quita el término en 2f_k y deja solo el audio |

**Por qué hace falta τ_k.** Los filtros retrasan la señal unos 421 µs (canal 1) o 236 µs (canales 2 y 3). Si el oscilador local no tuviera ese mismo retardo, la salida saldría multiplicada por cos φ: −0.90, +0.52 y −0.79. El canal 2 perdería la mitad de su amplitud y los otros dos saldrían invertidos.

## Páginas 4, 5 y 6. Canal k pasabajos 15 kHz

```
entrada → Pasabajos 15 kHz → Bajar tasa 10 a 1 → salida
```

| Bloque | Qué hace | Por qué |
|---|---|---|
| **Pasabajos 15 kHz** | Filtro FIR de 351 coeficientes: pasa hasta 15 kHz y rechaza 60 dB desde 20 kHz | Es el pasabajos del detector coherente (diap. 230). Quita el término en 2f_k |
| **Bajar tasa 10 a 1** | Toma 1 de cada 10 muestras: de 480 kHz a 48 kHz | *De simulación.* El audio solo necesita 48 kHz. Se puede bajar sin traslape porque el pasabajos ya quitó todo lo que está arriba de 24 kHz (diap. 400) |

Las tres páginas son iguales, una por canal.

## Página 7. Modulador FM

```
m(t) → Interpolación (x100) → Integrador → 2 pi kf → Fase total → cos → Amplitud Ac → s(t)
                                                      ↑
                                         Fase de la portadora (2π f_c t)
```

Es la ecuación de FM del curso (diap. 309):

**s(t) = A_c · cos[ 2π f_c t + 2π k_f ∫ m(τ) dτ ]**

| Bloque | Qué hace | En la ecuación |
|---|---|---|
| **Interpolación (x100)** | Pasa m(t) de 480 kHz a 48 MHz (página 9) | *De simulación.* La portadora de 10 MHz necesita 48 MHz de muestreo |
| **Integrador** | Suma acumulada de m(t) | ∫ m(τ) dτ |
| **2 pi kf** | Multiplica por 2π·k_f, con k_f = 150 kHz | 2π k_f ∫ m dτ. Como \|m\| ≤ 1, la desviación pico es Δf = 150 kHz |
| **Fase de la portadora** | Subsistema (página 8) | 2π f_c t |
| **Fase total** | Suma las dos fases | θ(t) |
| **cos** | Coseno de la fase total | cos θ(t) |
| **Amplitud Ac** | Multiplica por A_c = 1 | s(t) = A_c cos θ(t) |
| Salida «m(t) a tasa RF» | — | Solo para medir la desviación |

## Página 8. Fase de la portadora

```
Reloj t → 2 pi fc → 2π f_c t
```

- **Reloj t:** da el tiempo de cada muestra.
- **2 pi fc:** lo multiplica por 2π f_c. f_c es la portadora elegida en la radio (9–11 MHz) y se lee de `P.fc`, así que cambia sola al mover el dial.

## Página 9. Interpolación (x100)

```
m(t) → [Subir tasa 1 a 10 (a) → Inserción de ceros (a) ← Tren de pulsos (a) → Filtro interpolador (a)]
     → [ … lo mismo (b) … ] → m(t) a tasa RF
```

Son dos etapas iguales de ×10 (480 kHz → 4.8 MHz → 48 MHz). Hacerlo en dos etapas necesita filtros mucho más cortos que un solo ×100. Cada etapa tiene cuatro bloques:

| Bloque | Qué hace | Por qué |
|---|---|---|
| **Subir tasa 1 a 10** | Pasa a una tasa 10 veces mayor repitiendo cada muestra | Simulink necesita este bloque para conectar dos tasas distintas |
| **Tren de pulsos** | 1, 0, 0, …, 0 (un 1 cada 10 muestras) | — |
| **Inserción de ceros** | Multiplica las dos señales: queda la muestra original y 9 ceros | Así funciona la interpolación ideal: se insertan ceros y se filtra |
| **Filtro interpolador** | Pasabajos de 120 kHz, con ganancia 10 | Insertar ceros crea copias del espectro cada 480 kHz. El filtro las quita y «rellena» los ceros con valores intermedios. La ganancia 10 compensa la energía perdida por los ceros |

Este bloque es *de simulación*. En un transmisor real, m(t) es una señal continua.

## Página 10. Receptor superheterodino

Es el esquema de la diap. 358:

```
x(t) → Sección de RF (preselector) → Mezclador → Sección de FI → Demodulador FM → Filtro posdetección → Filtro de deénfasis → m(t) recuperado
                                         ↑
                                  Oscilador local
```

| Bloque | Qué hace | Por qué |
|---|---|---|
| **Sección de RF (preselector)** | Pasabanda centrado en la portadora sintonizada: pasa f_c ± 350 kHz y rechaza 60 dB desde ±1.55 MHz | Quita la **frecuencia imagen** (f_c − 3.4 MHz = 6.6 MHz) antes del mezclador. Si llegara al mezclador, también caería en 1.7 MHz y ya no se podría separar (diap. 361). Con ruido, sin él entran 3 dB más de ruido |
| **Oscilador local** | 2·cos(2π f_LO t), con f_LO = f_c − 1.7 MHz (8.3 MHz a 10 MHz) | Se calcula solo a partir de la portadora elegida (inyección inferior) |
| **Mezclador** | Multiplica x(t) por el oscilador local | Produce la diferencia (1.7 MHz, la FI) y la suma (18.3 MHz). Es el heterodinaje (diap. 357) |
| **Sección de FI** | Subsistema (página 16) | Deja solo la FI, 1.35–2.05 MHz |
| **Demodulador FM** | Subsistema: discriminador (ver «Demodulador FM») | Entrega la desviación de frecuencia |
| **Filtro posdetección** | Subsistema (página 15) | Deja solo el multiplex (diap. 376) |
| **Filtro de deénfasis** | Filtro IIR de primer orden, inverso del preénfasis | Baja el ruido de alta frecuencia (diap. 384). Con la casilla apagada es un cable |
| Salidas «señal de FI» y «salida del mezclador» | — | Solo para las gráficas |

## Demodulador FM: discriminador del curso

> Páginas del PDF `Diagramas Discriminador.pdf`: Demodulador FM en la 11, Convertir a desviación en la 12, Detector de envolvente en la 13 y Limitador en la 14. Las demás páginas no cambian.

```
señal de FI → Limitador → Detector de pendiente (derivador) → Detector de envolvente → Convertir a desviación → frecuencia instantánea
```

Es el discriminador de las diap. 342–345 y 375: un limitador deja la amplitud constante, el detector de pendiente convierte la FM en AM y el detector de envolvente recupera esa amplitud.

| Bloque | Qué hace | Por qué |
|---|---|---|
| **Limitador** | Divide la FI por su amplitud: queda con amplitud 1 | Sin él, la salida sería amplitud × frecuencia y el ruido de amplitud tapa el mensaje (diap. 375) |
| **Detector de pendiente (derivador)** | FIR derivador de 63 coeficientes | Al derivar cos θ(t) sale −2π f_i·sen θ(t): la amplitud es proporcional a la frecuencia instantánea |
| **Detector de envolvente** | Saca la amplitud de la salida del derivador | Da 2π f_i |
| **Convertir a desviación** | Divide entre 2π y resta f_FI | Queda f_i − f_FI = k_f·m(t), la desviación en Hz |

## Limitador (dentro del Demodulador FM)

```
señal de FI → Cuadrado de la FI → Pasabajos (amplitud) → ×2 → No negativo → Raíz → Amplitud mínima ┐
señal de FI → Retardo para alinear ───────────────────────────────────────────────────────────────→ Dividir por la amplitud → FI con amplitud 1
```

| Bloque | Qué hace | Por qué |
|---|---|---|
| **Cuadrado de la FI** (`x`) | FI² = A²·cos²θ = A²/2 + A²/2·cos 2θ | Primer paso del detector de ley cuadrática |
| **Pasabajos (amplitud)** | FIR de 33 coeficientes: pasa 400 kHz | Quita el término en 2θ y deja A²/2 |
| **×2**, **No negativo**, **Raíz** | √(2·A²/2) = A | Sale la amplitud. «No negativo» evita la raíz de un número negativo por redondeo |
| **Amplitud mínima** (Saturation) | Nunca deja que A sea menor a 0.3 | Como un limitador real, que tiene ganancia finita. Sin esto, cuando el ruido acerca la amplitud a cero, la división dispara picos enormes |
| **Retardo para alinear** (Delay) | Retrasa la FI lo mismo que tarda el pasabajos (16 muestras) | Para dividir cada muestra por *su* amplitud y no por la de un instante anterior |
| **Dividir por la amplitud** (Divide) | FI / A | La salida tiene amplitud 1: hace lo mismo que el limitador del curso |

**Por qué divide en vez de recortar.** Un limitador clásico recorta la onda y genera armónicos. En una simulación digital a 4.8 MHz, esos armónicos se pliegan sobre la señal: probándolo, la calidad bajaba a 9–14 dB.

## Detector de pendiente (derivador)

Es un único bloque Discrete Filter (FIR de 63 coeficientes). Es un derivador ideal (h[n] = cos(πn)/n) suavizado con ventana de Kaiser y multiplicado por f_s para que salga en rad/s.

**Ejemplo con números.** Si la FI está en 1.85 MHz (f_i = f_FI + 150 kHz), la salida es una senoide de amplitud 2π·1.85·10⁶. Si está en 1.55 MHz, su amplitud es 2π·1.55·10⁶. **La frecuencia se convirtió en amplitud**: FM → AM.

## Detector de envolvente (dentro del Demodulador FM)

```
salida del derivador → Cuadrado → Pasabajos → ×2 → No negativo → Raíz → envolvente = 2π f_i
```

Es el mismo detector de ley cuadrática que el del limitador: cuadrado → pasabajos (quita el término en 2θ) → ×2 → raíz. Da la amplitud de la salida del derivador, o sea 2π f_i.

## Convertir a desviación (dentro del Demodulador FM)

```
envolvente → Dividir entre 2 pi → Restar la FI ← Frecuencia de FI (1.7 MHz) → desviación de frecuencia
```

f_i − f_FI = k_f·m(t): es lo que sigue al «Filtro posdetección», que divide entre k_f.

## Página 15. Filtro posdetección

```
frecuencia instantánea → Dividir entre kf → Pasabajos 120 kHz → Bajar tasa 10 a 1 (multiplex) → Multiplicar por 3 → m(t) recuperado
```

| Bloque | Qué hace | Por qué |
|---|---|---|
| **Dividir entre kf** | Divide por k_f = 150 kHz | Pasa de desviación en Hz a mensaje: si f_i − f_c = k_f·m(t), entonces m(t) = (f_i − f_c)/k_f |
| **Pasabajos 120 kHz** | FIR de 147 coeficientes: pasa hasta 120 kHz | **Es el filtro posdetección del curso** (diap. 376): deja solo la banda del mensaje y quita el ruido de fuera de banda |
| **Bajar tasa 10 a 1 (multiplex)** | De 4.8 MHz a 480 kHz | *De simulación.* El multiplex solo necesita 480 kHz |
| **Multiplicar por 3** | ×3 | Deshace la división entre 3 del transmisor |

## Página 16. Sección de FI

```
salida del mezclador → Filtro antitraslape → Bajar tasa 10 a 1 (FI) → Pasabanda de FI → señal de FI
```

| Bloque | Qué hace | Por qué |
|---|---|---|
| **Filtro antitraslape** | Pasabajos a 48 MHz: pasa hasta 2.05 MHz y rechaza desde 2.75 MHz | Quita el producto suma (18.3 MHz) y todo lo que se plegaría sobre la FI al bajar la tasa (diap. 400) |
| **Bajar tasa 10 a 1 (FI)** | De 48 MHz a 4.8 MHz | *De simulación.* La FI llega como mucho a 2.05 MHz, así que 4.8 MHz alcanza |
| **Pasabanda de FI** | Pasa 1.35–2.05 MHz y rechaza 60 dB fuera de 1.15–2.25 MHz | **Es el filtro de FI del curso** (diap. 358). Deja solo la señal sintonizada; su ancho de 700 kHz cubre Carson (530 kHz) |

## Página 17. Transmisor FDM

```
x1(t) → Canal 1 DSB-SC ┐
x2(t) → Canal 2 DSB-SC ├→ Suma de los 3 canales → Normalización (÷3) → Filtro de preénfasis → m(t) al modulador
x3(t) → Canal 3 DSB-SC ┘                    └→ multiplex m(t) (solo para graficar)
```

| Bloque | Qué hace | Por qué |
|---|---|---|
| **Canal k DSB-SC** | Modula cada audio en su subportadora (páginas 18–23) | FDM con DSB-SC (diap. 225, 264) |
| **Suma de los 3 canales** | m = Σ x_k(t)·cos(2π f_k t) | El multiplex |
| **Normalización (dividir entre 3)** | ×1/3 | Cada audio tiene pico 1, así que la suma puede llegar a 3. Al dividir, \|m\| ≤ 1 y la desviación nunca pasa de 150 kHz (Δf = k_f·V_m, diap. 310) |
| **Filtro de preénfasis** | y[n] = g·(x[n] − a·x[n−1]) | Sube las frecuencias altas antes del modulador (diap. 384). Con la casilla apagada es un cable |

## Páginas 18, 20 y 22. Canal 1, 2 y 3 DSB-SC

```
x(t) → Pasabajos 15 kHz → Interpolación (x10) → Modulador DSB-SC → señal DSB-SC
                                                       ↑
                                       Subportadora cos(2π f_k t)
```

| Bloque | Qué hace | Por qué |
|---|---|---|
| **Pasabajos 15 kHz** | FIR de 63 coeficientes a 48 kHz: pasa hasta 15 kHz | Asegura que cada audio ocupe como máximo 15 kHz (requisito del enunciado). Si no, invadiría la banda del canal vecino |
| **Interpolación (x10)** | De 48 kHz a 480 kHz (páginas 19, 21, 23) | *De simulación.* La subportadora de 100 kHz necesita más de 200 kHz de muestreo |
| **Subportadora cos(2 pi fk t)** | cos(2π f_k t), con f_k = 20, 60 o 100 kHz | La «portadora» de cada canal en el FDM |
| **Modulador DSB-SC** | x(t)·cos(2π f_k t) | La modulación DSB-SC de la diap. 225: φ(t) = f(t)cos ω_c t |

## Páginas 19, 21 y 23. Interpolación (x10)

Igual que una etapa de la página 9: subir tasa → inserción de ceros (con el tren de pulsos) → filtro interpolador. Aquí pasa de 48 kHz a 480 kHz, con un filtro de 105 coeficientes que pasa hasta 15 kHz y quita las copias del espectro.

---

## Resumen para explicar en una frase cada tipo de bloque

- **Bloques del curso:** moduladores DSB-SC, suma FDM, integrador y cos del FM, sección de RF, oscilador local, mezclador, sección de FI, demodulador, filtro posdetección, pasabanda, detector coherente, pasabajos, preénfasis y deénfasis, ruido AWGN.
- **Bloques de muestreo** (interpolación, subir y bajar tasa, filtro antitraslape): existen porque la simulación es digital y cada etapa usa la frecuencia de muestreo que necesita (Nyquist, diap. 391–400).
- **Escalas** (÷3, ×3, 2π k_f, ÷k_f, f_s/2π): ajustan unidades. Vienen de Δf = k_f·m(t) y de f_i = (1/2π)·dφ/dt.
- **Guardar …:** solo guardan señales para las gráficas.
