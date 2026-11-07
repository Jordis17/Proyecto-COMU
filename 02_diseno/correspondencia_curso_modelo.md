# Correspondencia entre los diagramas del curso y el modelo Simulink

Versión agrupada del modelo (rama `claude/version-agrupada`). En cada nivel del modelo se ven los mismos bloques que en los esquemas de la presentación. Los bloques que solo existen porque la simulación es digital están un nivel más adentro.

**Idea para explicarle al profesor:**

> El sistema tiene los mismos bloques que los esquemas del curso. Algunos bloques, por dentro, tienen piezas extra que solo existen porque la simulación es digital y cada etapa trabaja a su propia frecuencia de muestreo (Nyquist y filtro antitraslape, diap. 388–400). Agrupar no cambia ningún resultado.

---

## 1. Sistema completo

| Esquema del curso | Bloque del modelo | Señal de salida |
|---|---|---|
| Mensajes x_a(t), x_b(t)… (FDM, diap. 264) | Audio 1, 2, 3 | x1(t), x2(t), x3(t) |
| Multiplexor FDM (diap. 264) | **Transmisor FDM** | m(t) multiplex |
| Transmisor FM (diap. 309, 384) | **Modulador FM** | s(t) señal FM |
| Canal con ruido w(t) (diap. 365) | **Canal** | x(t) = s(t) + w(t) |
| Receptor superheterodino (diap. 358) | **Receptor superheterodino** | m(t) recuperado |
| Demultiplexor FDM (diap. 264) | **Demultiplexor FDM** | audio 1, 2, 3 recuperado |

Los bloques «Guardar …» no son parte del sistema: guardan las señales para las gráficas.

## 2. Transmisor FDM (diap. 225, 264)

| Curso | Modelo | Ecuación |
|---|---|---|
| Modulador DSB-SC de cada canal: f(t)·cos ω_c t (diap. 225) | Canal k DSB-SC | x_k(t)·cos(2π f_k t) |
| Suma de canales (diap. 264) | Suma de los 3 canales | m = Σ x_k cos(2π f_k t) |
| — (escala para que \|m\| ≤ 1; relacionada con Δf = k_f·V_m, diap. 310) | Normalización (dividir entre 3) | m / 3 |
| Filtro de preénfasis (diap. 384) | Filtro de preénfasis | y[n] = g(x[n] − a x[n−1]) |

**Dentro de «Canal k DSB-SC»:** Pasabajos 15 kHz → **Interpolación (x10)** → Modulador DSB-SC ← Subportadora cos(2π f_k t).

- **Pasabajos 15 kHz:** limita el audio a su ancho de banda (filtro antitraslape, diap. 400).
- **Interpolación (x10):** *(solo de simulación)* pasa de 48 kHz a 480 kHz. Es un bloque agrupado; adentro tiene subir tasa, tren de pulsos, inserción de ceros y filtro interpolador.

## 3. Modulador FM (diap. 309, 335)

| Curso | Modelo | Ecuación |
|---|---|---|
| Integral del mensaje | Integrador | ∫ m(τ) dτ |
| Sensibilidad k_f (diap. 309–310) | 2 pi kf | 2π k_f ∫ m dτ |
| Fase de la portadora ω_c t | **Fase de la portadora** (agrupa Reloj t y 2 pi fc) | 2π f_c t |
| Fase total θ(t) | Fase total | θ(t) = 2π f_c t + 2π k_f ∫ m dτ |
| Onda FM | cos → Amplitud Ac | s(t) = A_c cos θ(t) |

- **Interpolación (x100):** *(solo de simulación)* pasa de 480 kHz a 48 MHz en dos etapas de x10, para representar la portadora de 10 MHz.

## 4. Canal (diap. 365)

| Curso | Modelo |
|---|---|
| Ruido blanco w(t), DEP N₀/2 | Ruido blanco gaussiano → Nivel de ruido |
| x(t) = s(t) + w(t) | Suma de ruido w(t) |

El nivel de ruido sale de la (SNR)_C del curso (diap. 377). Con nivel 0, el canal es ideal.

## 5. Receptor superheterodino (diap. 358)

| Esquema de la diap. 358 | Bloque del modelo | Qué hace |
|---|---|---|
| Sintonizador / sección de RF | Sección de RF (preselector) | Pasa f_c ± 350 kHz y quita la frecuencia imagen |
| Oscilador local | Oscilador local | 2cos(2π f_LO t), con f_LO = f_c − 1.7 MHz |
| Mezclador | Mezclador | Produce la FI (diferencia) y el producto suma |
| Sección de FI | **Sección de FI** | Deja pasar 1.35–2.05 MHz |
| Detector (aquí, de FM) | **Demodulador FM** | Da la frecuencia instantánea |
| Filtro posdetección (diap. 376) | **Filtro posdetección** | Deja solo el multiplex (120 kHz) |
| Filtro de deénfasis (diap. 384) | Filtro de deénfasis | Inverso del preénfasis |

**Dentro de «Sección de FI»:** Filtro antitraslape → Bajar tasa 10 a 1 (FI) → Pasabanda de FI.
- El pasabanda de FI es el filtro de FI del curso.
- Los otros dos son *de simulación*: bajan de 48 MHz a 4.8 MHz sin traslape (diap. 400).

**Dentro de «Filtro posdetección»:** Dividir entre kf → Pasabajos 120 kHz → Bajar tasa 10 a 1 → Multiplicar por 3.
- El pasabajos es el filtro posdetección del curso.
- «Dividir entre kf» convierte la desviación de frecuencia en el mensaje: el inverso de Δf = k_f·m.
- «Multiplicar por 3» deshace la normalización del transmisor.
- Bajar tasa es *de simulación*.

## 6. Demodulador FM (diap. 342, 309)

El curso explica que un discriminador entrega una salida proporcional a la frecuencia instantánea, f_i = f_c + (1/2π)·dφ/dt. Nuestro demodulador calcula exactamente eso, en forma digital:

| Idea | Bloque del modelo |
|---|---|
| Separar la FI en dos componentes: en fase y en cuadratura (diap. 174) | Rama en fase (I), Rama en cuadratura (Q) |
| Cuánto gira la fase entre una muestra y la siguiente (≈ dφ/dt) | Giro de fase entre muestras |
| Pasar de ángulo a frecuencia: f_i = (f_s/2π)·Δφ | Convertir a frecuencia |

- **Por qué no se usa un limitador** (diap. 375): el ángulo no depende de la amplitud, así que el limitador no hace falta.
- **Por qué no se usa el discriminador clásico** (limitador → derivador → envolvente): se probó y dio peor calidad (36–45 dB contra 60 dB).

## 7. Demultiplexor FDM (diap. 230, 237, 264)

| Curso | Modelo (por canal k) |
|---|---|
| Filtro pasabanda del canal (diap. 264) | Canal k pasabanda |
| Oscilador local del receptor (diap. 237) | Canal k oscilador local |
| Multiplicar por la portadora local (diap. 230) | Canal k detector coherente |
| Filtro pasabajos (diap. 230) | **Canal k pasabajos 15 kHz** (adentro: pasabajos + bajar tasa 10 a 1) |

El oscilador local de cada canal tiene la fase corregida por el retardo de los filtros. Si no se corrige, la salida se multiplica por cos φ (diap. 237–238).

---

## Resumen: bloques que no están en la presentación y por qué

| Bloque | Dónde está | Por qué existe |
|---|---|---|
| Interpolación (x10), Interpolación (x100) | Transmisor y modulador | Subir la frecuencia de muestreo para representar señales más altas (Nyquist, diap. 391–397) |
| Bajar tasa 10 a 1, Filtro antitraslape | Sección de FI, posdetección, demultiplexor | Bajar la frecuencia de muestreo sin traslape (diap. 398–400) |
| Normalización, Dividir entre kf, Multiplicar por 3 | Transmisor y receptor | Escalas de amplitud: \|m\| ≤ 1 y Δf = k_f·m (diap. 309–310) |
| Ramas I y Q, Giro de fase | Demodulador FM | Forma digital de f_i = (1/2π)·dφ/dt |
| Guardar … | Nivel principal | Guardar señales para las gráficas |
