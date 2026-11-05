# Proyecto Comunicaciones Eléctricas — Diagnóstico crítico y diseño base (v2)

Sistema: 3 audios → FDM → FM → canal (ideal / AWGN) → receptor superheterodino → demultiplexación → GUI tipo radio.

**Etiquetas:** **[REQ]** requisito original · **[ERROR]** error demostrado · **[INADECUADA]** recomendación inadecuada · **[ABIERTO]** dato no especificado · **[DECISIÓN]** decisión del equipo · **[VERIFICADO-PY]** comprobado en un prototipo en Python (no en MATLAB/Simulink) · **[CURSO]** respaldo en la presentación del curso · **[TOMASI]** respaldo en Tomasi, *Sistemas de Comunicaciones Electrónicas*, 4.ª ed.

**Cambios respecto a v1:**
- Se incorporó la presentación del curso (basada en Haykin & Moher).
- Δf pasa de 75 a **150 kHz**, justificado con la figura de mérito de Haykin y un barrido simulado.
- El ruido se define con la (SNR)_C del curso.
- Se compara el FDM con el ejemplo SSB del curso.
- Se valida el discriminador clásico del curso.
- El filtro del canal 1 pasa a ser pasabanda.
- Se recalcularon todos los parámetros dependientes.

> **Fuentes:**
> - `Intrucciones originales.md` (enunciado).
> - Los dos diagnósticos previos.
> - `Comunicaciones Eléctricas.pdf`: 620 diapositivas escaneadas, leídas mediante OCR. Diapositivas clave: 225–243 (DSB-SC, detección coherente, error de fase, piloto), 244–246 (FM estéreo), 263–266 (FDM), 309–328 (índice, Carson, Bessel, DR), 342–354 (discriminadores, PLL), 356–361 (superheterodino, imagen), 362–387 (ruido en FM, umbral, prénfasis).
> - Tomasi (texto). Haykin y Stremler están escaneados: se usan a través de la presentación, que cita a Haykin.
>
> Los valores [VERIFICADO-PY] provienen del prototipo en Python (`04_verificacion_python/`). Los resultados medidos en MATLAB/Simulink R2026a están en §8b.

---

## 1. Requisitos reales

### 1.1 Obligatorios [REQ]

| # | Requisito | Sección |
|---|---|---|
| R1 | Tres audios independientes, de ancho de banda ≤ 15 kHz, identificables a la salida | 4.1 |
| R2 | FDM en ≤ 120 kHz: plan de frecuencias, separación, justificación del uso de banda y espectro | 4.2 |
| R3 | FM del multiplex con portadora nominal de 10 MHz configurable y seleccionable desde la GUI | 4.3 |
| R4 | Definir y justificar el índice de modulación y verificar el ancho de banda con Carson | 4.3 |
| R5 | Canal ideal y, al final, AWGN | 4.4 |
| R6 | Superheterodino clásico con FI de 1.7 MHz, LO automático, conversión, filtrado FI y demodulación FM | 4.5 |
| R7 | Evidenciar la selección de canal, la recuperación del multiplex y la separación de los tres audios | 4.5 |
| R8 | Escalamiento obligatorio, documentado y transparente para la GUI | 5 |
| R9 | MATLAB/Simulink, modular, con cada bloque modelado matemáticamente | 1, 6 |
| R10 | Evidencias en tiempo y en frecuencia, y comparación original/recuperada | 6 |
| R11 | GUI tipo radio: portadora, FI visible, selección de señal y actualización automática | 7 |
| R12 | Video de ~10 min tipo informe técnico, con dominio de todos los integrantes | 10 |
| R13 | Entrega de los archivos del modelo (`.slx` y `.m`) junto con el video | Aclaración posterior confirmada por el equipo |

### 1.2 Datos abiertos [ABIERTO]

- Modulación de las subportadoras, posiciones y guardas.
- Δf, k_f y normalización.
- Rango de sintonía.
- Inyección del LO.
- Filtros.
- Preselector.
- Tipo de demodulador.
- f_s por bloque y duración de las señales.
- Definición y nivel de la SNR.
- Audio real o sintético.

---

## 2. Auditoría independiente del enunciado

| # | Sección | Texto (resumido) | Clasificación | Comentario |
|---|---|---|---|---|
| A1 | 5, tabla | Audio y FDM sin escalar; portadora y FI ÷100 | **[ERROR]** crítico | Ver E1 |
| A2 | 5, premisa | «Por limitaciones computacionales no se simulan las frecuencias nominales» | Premisa imprecisa | El escalamiento uniforme no ahorra muestras (E3). Se cumple igualmente. |
| A3 | 8 | «f_s 5–10 × ancho de banda máximo» | **[INADECUADA]** | En pasabanda manda f_max, incluido el producto suma (E2) |
| A4 | 4.5 | «Si la calidad es baja, prénfasis/deénfasis» | **Válida (condicional)** | No es un error. Con canal ideal la calidad es buena y no hace falta; con AWGN el canal 3 sale unos 14 dB peor que el canal 1 y se implementa (E4) |
| A5 | 8 | «Simulaciones cortas» | Matiz | Al escalar, 1 s real equivale a 100 s simulados. Lo que hay que limitar son las muestras. |
| A6 | 4.3 | «Definir el índice de modulación» | Matiz | Con moduladora compuesta se usa la **relación de desviación DR = Δf_máx/f_m(máx)** [CURSO diap. 328] [TOMASI ec. 6-29] |
| A7 | 4.3 | «Verificar con Carson» | Válida, con riesgo | f_m = 115 kHz del multiplex, no 15 kHz. Con DR ≈ 1 Carson subestima frente a Bessel [TOMASI §6] → se comprueban ambos |
| A8 | 4.2 | «120 kHz para la señal multiplexada» | **Válida** | Es el ancho del multiplex, no el de la FM (§4.1) |
| A9 | 4.3 | Portadora 10 MHz configurable | Válida + [ABIERTO] rango | Se propone 9–11 MHz |
| A10 | 4.5 | FI de 1.7 MHz | **Válida** | Cumple la definición del curso: «FI menor que la portadora pero mayor que la señal de salida» [CURSO diap. 359]. 1.7 MHz > B_T/2 |
| A11 | 4.5 | Conversión, filtrado FI, demodulación | Válida, pero incompleta | El esquema del curso incluye «Sección de RF / sintonizador» antes del mezclador [CURSO diap. 358]. Se añade el preselector. |
| A12 | 4.5 / 7 | «Selección del canal» | Ambigua | Hay dos selecciones: sintonía RF y elección del audio 1/2/3 |
| A13 | 4.1 | «Normalizadas» | Válida + [ABIERTO] | Fija la desviación real (§6.3) |
| A14 | 4.4 | AWGN | Válida + [ABIERTO] SNR | Se usa la (SNR)_C del curso (§6.9) |
| A15 | 7 | «Visualizar la FI» | Válida (trivial) | Se muestran también el LO y la imagen |
| A16 | 6, 8 | Modular, discreto, paso fijo, parámetros centralizados | Válidas | Se adoptan |

**Nota sobre la diapositiva 358 del curso:** el esquema escribe «IF_inf = f_local − f_RF, IF_sup = f_local + f_RF». Son los **dos productos del mezclador** (diferencia y suma). No deben confundirse con la *inyección* superior o inferior del LO. Como un superheterodino lleva la señal a una FI **menor** que la portadora (diap. 359), se usa la diferencia: **f_FI = |f_RF − f_LO|**.

---

## 3. Errores técnicos detallados

### E1 — La tabla de escalamiento no conserva proporciones [ERROR, §5]

**Qué dice:** audio 15 → 15 kHz, FDM 120 → 120 kHz, portadora 10 MHz → 100 kHz, FI 1.7 MHz → 17 kHz, «manteniendo relaciones relativas».

**Demostración:**

| Relación | Nominal | Tabla | Cambio |
|---|---|---|---|
| B_FDM / f_c | 0.012 | 1.2 | ×100 |
| f_FI / f_c | 0.17 | 0.17 | ✓ |
| f_m,max / f_FI | 0.068 | 6.8 | ×100 |

**Consecuencias con la tabla literal** (Δf = 150 kHz, f_m,max = 115 kHz):
1. Carson: B_T = 2(150 + 115) = 530 kHz → la FM ocuparía 100 ± 265 kHz, es decir de −165 a 365 kHz. Cruza 0 Hz y se solapa con su espejo.
2. En FI ocurriría lo mismo: 17 ± 265 kHz.
3. f_FI (17 kHz) < f_m,max (115 kHz): no cumple la definición de superheterodino del curso (FI mayor que la señal de salida).
4. Aun con Δf → 0: 100 ± 115 kHz, de −15 a 215 kHz. Sigue cruzando 0 Hz.

**Corrección [DECISIÓN]:** escala **uniforme K = 100**. Se conservan las filas RF/FI de la tabla (100 kHz y 17 kHz). Se corrigen audio → **150 Hz** y FDM → **1.2 kHz**, junto con todo lo que depende de ellas.

**Verificación:** tabla con relaciones adimensionales y espectros RF/FI sin cruce por 0 Hz. [VERIFICADO-PY] SDR ≈ 46 dB en los tres canales para f_c = 9, 10 y 11 MHz.

### E2 — Regla «5–10 × ancho de banda» [INADECUADA, §8]

Con B_T = 5.3 kHz simulados: 5–10 × 5.3 = 26.5–53 kHz < 2 × 103.5 kHz, y la portadora ni siquiera queda representada. Lo que manda es la frecuencia absoluta máxima. Con inyección inferior, el producto suma es 2f_c − f_FI = 2·11 − 1.7 = 20.3 MHz; con la mitad del ancho (+0.35) llega a **20.65 MHz** → f_s,RF > 41.3 MHz → se elige **48 MHz**. Se diseña **por etapa**, con multirritmo (§6.6).

### E3 — El escalamiento uniforme no ahorra cómputo (premisa del §5)

N = (K·T_r)·(f_s,RF,nom/K) = **T_r·f_s,RF,nom**: no depende de K. Escalar solo renombra el eje de tiempo: 48 M muestras por segundo de audio real con cualquier K.

El ahorro viene del **multirritmo** y de los **clips cortos**. El audio real no se filtra a 150 Hz: se usan las mismas muestras declarando el tiempo de muestreo como 1/480 s simulados, y se escuchan con `sound(y,48000)`.

### E4 — Prénfasis/deénfasis [REQ condicional, §4.5]

El enunciado dice «si la calidad es baja, considerar prénfasis/deénfasis». **No es un error del enunciado.** Es una condición, y hay que revisar cuándo se cumple:

- **Canal ideal:** la calidad no es baja (SDR ≈ 60 dB). El prénfasis y el deénfasis son filtros inversos, así que sin ruido se cancelan y no cambian nada.
- **Canal AWGN:** la calidad sí baja, y no por igual en los tres canales. Según el curso [diap. 385], el ruido a la salida del discriminador crece como f² (S_No(f) = N₀f²/A_c²). Integrando alrededor de cada subportadora, el ruido del canal k es ∝ (f_k² + W_a²/3):

| Canal | f_k² + W_a²/3 (kHz²) | Ruido relativo |
|---|---|---|
| 1 | 400 + 75 = 475 | 0 dB |
| 2 | 3600 + 75 = 3675 | +8.9 dB |
| 3 | 10000 + 75 = 10075 | +13.3 dB |

Por eso se implementa con AWGN. Se coloca donde indica el curso [diap. 384]: el prénfasis antes del modulador FM y el deénfasis después del demodulador. Como aquí el mensaje es el multiplex completo, se filtra el multiplex. Son dos filtros de primer orden; el detalle está en `02_diseno/prenfasis_deenfasis.md`.

**Resultado esperado** (misma desviación pico): el prénfasis no reduce el ruido total, lo reparte. Con f₀ = 30 kHz, el canal 3 mejora unos +2 dB, el canal 2 baja unos −1 dB y el canal 1 baja unos −6 dB, que tenía SNR de sobra. La teoría y la simulación en Python coinciden. **Pendiente medirlo en Simulink** con `verificar_enfasis.m`.

**Por qué no se aplica a cada audio por separado** (como el prénfasis de 75 µs de la FM estéreo [diap. 244–246]): en la FM estéreo el canal L+R está en banda base, donde el ruido sí crece dentro del audio. En nuestro canal 3, lo que domina es el término f_k², así que el ruido es casi plano dentro del audio y un prénfasis por audio casi no ayuda.

### E5 — Riesgos de interpretación

- **Carson con f_m del multiplex**, no del audio.
- **Filtro FI dimensionado para B_T** (incluso para el ancho por Bessel), no para 120 kHz.
- **Retardo en DSB-SC.** [CURSO diap. 237–238] Con un error de fase φ, la salida es ½f(t)·cos φ. Los filtros FIR retrasan la señal. Con los filtros actuales de `params_sistema.m` (interpolación y FI en dos etapas), el retardo hasta el producto de cada canal es τ_1 = 411.8 µs y τ_2 = τ_3 = 226.4 µs nominales. Sin compensarlo, las ganancias serían cos(2π f_k τ_k) = **+0.09 / −0.87 / −0.65**: el canal 1 casi desaparecería (−21 dB). [RESULTADO VERIFICADO] Simulink midió las mismas ganancias (§8b). Por eso se compensa (§6.7). Tomasi describe la misma práctica en la FM estéreo: se retarda L+R «para mantener la integridad de fase».

---

## 4. Revisión crítica de los diagnósticos previos

### 4.1 Diagnóstico 1

**Correcto:**
- La trampa de la tabla.
- Carson con f_m del multiplex.
- FI < f_m.
- Ruido ∝ f² y umbral.
- La doble selección de canal.

**Imprecisiones:**
- **La interpretación B de los 120 kHz es descartable.** El texto dice «para la señal multiplexada». Además, B_T ≤ 120 kHz exigiría Δf + f_m ≤ 60 kHz: no caben tres canales DSB-SC y con SSB quedaría Δf ≈ 0–5 kHz.
- **«La sincronización DSB-SC es trivial con canal ideal».** No lo es: el retardo de los filtros desfasa las subportadoras (E5, curso diap. 238).
- **«La selectividad no se demuestra».** Con AWGN, el preselector evita que se pliegue el ruido de la banda imagen, y se puede añadir una señal en la imagen.
- **No advierte la invariancia del cómputo frente a K.**
- **Menciona una rúbrica** que no aparece en el enunciado disponible.

### 4.2 Diagnóstico 2

Coherente en lo esencial.

**Mejorable:**
- **Δf = 25 kHz** (DR = 0.22). Según la figura de mérito del curso, la SNR de salida es ∝ Δf². Con 150 kHz, la mejora es (150/25)² = 36 → **+15.6 dB**.
- **No concluye una arquitectura.**
- **No cuantifica el desfase de DSB-SC.**

---

## 5. Arquitectura de simulación: comparación y elección

| Criterio | (a) K = 100 uniforme, pasobanda real, multirritmo | (b) Envolvente compleja | (c) Tabla literal | (d) Escalar solo RF |
|---|---|---|---|---|
| Exactitud | Alta: mezcla real, suma/diferencia, imagen | Alta para FM/FDM; el mezclador es abstracto | Imposible | Rompe proporciones |
| Cumple §5 | **Sí** | Débil (cambio de representación) | No | No |
| Superheterodino del curso (diap. 358) | **Completo** | Parcial | — | Sí, revalidando todo |
| Muestras por segundo de audio real | 48 M (24 M con aliasing controlado) | ≈1–2 M | — | Menor |
| Dificultad | Media | Media-alta: la envolvente compleja no figura en la presentación | — | Media |

**Recomendación: (a).** Es la única que cumple el §5 literalmente y reproduce el esquema superheterodino del curso: sección RF, mezclador, LO, sección FI, detector y procesamiento del mensaje. El costo se controla con:
- multirritmo;
- clips de 0.1–0.2 s reales para pruebas y de 1–2 s para la demostración;
- registrar solo las señales decimadas;
- si hiciera falta, f_s,RF = 24 MHz con aliasing controlado (verificado con los parámetros de v1; **hay que revalidarlo con Δf = 150 kHz**).

**Límites:** no funciona en tiempo real; cada cambio en la GUI vuelve a simular.

---

## 6. Diseño numérico [DECISIÓN — propuesta del equipo]

K = 100. «Simulado» = nominal ÷ 100.

### 6.1 Tabla maestra

| Parámetro | Nominal | Simulado | Fundamento |
|---|---|---|---|
| K | — | 100 | Conserva las filas RF/FI del profesor |
| Ancho de audio W_a | 15 kHz | 150 Hz | [REQ] |
| f_s audio | 48 kHz | 480 Hz | > 2·15 kHz |
| Subportadoras | 20, 60, 100 kHz | 200, 600, 1000 Hz | DSB-SC, §6.2 |
| Bandas | 5–35, 45–75, 85–115 kHz | 50–350, 450–750, 850–1150 Hz | f_k ± W_a |
| Guardas | 10 kHz (+5 kHz en cada extremo) | 100 Hz | Margen de transición; el margen de 0–5 kHz aleja al canal 1 de DC |
| f_m,max (multiplex) | 115 kHz | 1.15 kHz | Borde del canal 3 |
| W (ancho del multiplex, para la SNR) | 120 kHz | 1.2 kHz | [REQ] 4.2 |
| f_s multiplex | 480 kHz | 4.8 kHz | > 2·120 kHz |
| Normalización | m_n = m/3 | igual | \|m_n\| ≤ 1 |
| **Δf = k_f** | **150 kHz** | **1.5 kHz** | §6.4 |
| **DR** | **1.30** | 1.30 | 150/115 |
| **Carson** | **530 kHz** | 5.3 kHz | 2(Δf + f_m) |
| **Bessel (bandas laterales ≥ 1 %)** | **690 kHz** | 6.9 kHz | n = 3 → 2·3·115 |
| f_c (rango) | 10 MHz (9–11, pasos de 0.1) | 100 kHz (90–110) | [REQ] + [ABIERTO] |
| f_FI | 1.7 MHz | 17 kHz | [REQ] |
| Inyección | inferior | inferior | §6.5 |
| f_LO = f_c − f_FI | 8.3 MHz (7.3–9.3) | 83 kHz | Automática |
| Imagen = f_c − 2f_FI | 6.6 MHz (5.6–7.6) | 66 kHz | La rechaza el preselector |
| Producto suma | 18.3 MHz (16.3–20.3) | 183 kHz | Lo rechaza el filtro FI |
| f_s RF | 48 MHz | 480 kHz | > 2·20.65 MHz |
| f_s FI / demodulación | 4.8 MHz | 48 kHz | > 2·2.25 MHz |
| Preselector | pasa f_c ± 0.35, rechaza ± 1.55 MHz | ±3.5 / ±15.5 kHz | Imagen a 3.4 MHz → ≥ 60 dB |
| Filtro FI | pasa 1.35–2.05, rechaza < 1.15 y > 2.25 MHz | 13.5–20.5 / 11.5–22.5 kHz | Paso de 700 kHz ≥ 690 kHz de Bessel |

### 6.2 Plan FDM: DSB-SC frente al SSB del ejemplo del curso

El ejemplo de FDMA del curso [diap. 265–266] usa **SSB**: voces de 300–3400 Hz mezcladas a 20, 25 y 30 kHz, conservando solo la banda lateral superior mediante un pasabanda.

| | DSB-SC (elegida) | SSB (ejemplo del curso) |
|---|---|---|
| Ancho de 3 canales | 90 kHz: cabe en 120 con guardas | 45 kHz |
| Generación | Solo un multiplicador | Pasabanda que elimine una banda lateral |
| Problema con audio real | Ninguno | El audio real llega casi a 0 Hz. Las bandas laterales quedan pegadas a la subportadora y harían falta filtros extremadamente abruptos. El ejemplo del curso funciona porque la voz telefónica empieza en 300 Hz. |
| Demodulación | Coherente [diap. 230–238] | Coherente |
| Antecedente en el curso | FM estéreo: L−R en DSB-SC sobre FM [diap. 244–246] | Telefonía FDMA |
| SNR por canal | Igual (figura de mérito 1 en ambos casos, Haykin) | Igual |

**Elegida: DSB-SC.** El ancho disponible lo permite, no exige filtros abruptos y es exactamente el esquema de la FM estéreo que se ve en el curso. La FM estéreo es el ejemplo real más cercano a este proyecto (FDM sobre FM).

**Comprobación:** 20 ± 15 = 5–35; 60 ± 15 = 45–75; 100 ± 15 = 85–115 kHz. Guardas: 45 − 35 = 85 − 75 = 10 kHz; 115 ≤ 120 ✓. Ocupación: 90/120 = 75 %.

### 6.3 Normalización y sensibilidad

m(t) = Σ x_k(t)·cos(2π f_k t), con |x_k| ≤ 1 → |m| ≤ 3 → m_n = m/3.
s(t) = A cos[2π f_c t + 2π k_f ∫ m_n dτ], con k_f = Δf = 150 kHz por unidad de m_n.
Siguiendo la notación del curso [diap. 309]: sensibilidad k_f, desviación Δf = k_f·V_m y porcentaje de modulación = Δf_real/Δf_máx [diap. 311].

[VERIFICADO-PY] Con audio tipo ruido, el pico real de m_n fue 0.656, es decir, un 66 % de modulación. Opción a evaluar con AWGN: normalizar por el pico medido, que aporta +3.7 dB.

### 6.4 Índice (DR), Carson, Bessel y elección de Δf

**Criterio del curso** [diap. 377–378, Haykin §2.13]: (SNR)_O = 3A_c²k_f²P / (2N₀W³) y figura de mérito = 3k_f²P/W². La SNR crece con Δf², a costa de ancho de banda.

**Restricciones para elegir Δf:**
1. La FI debe alojar la señal: f_FI − B/2 > 0 con margen.
2. La banda FI debe caber bajo el Nyquist de la etapa de 4.8 MHz (2.4 MHz).
3. Cuanto mayor es B_T, más ruido entra en la FI, y el umbral (CNR ≈ 10 dB en B_T) aparece con una (SNR)_C mayor.

**Barrido [VERIFICADO-PY]**, SDR del canal 1 / canal 3 en dB, con N₀ fijo:

| (SNR)_C | Δf = 75 kHz | **Δf = 150 kHz** | Δf = 250 kHz |
|---|---|---|---|
| 35 dB | 29.7 / 17.3 | **35.4 / 23.3** | 39.3 / 27.6 |
| 25 dB | 19.7 / 7.8 | **25.6 / 13.2** | 30.0 / 17.6 |
| 17 dB | 10.6 / 2.3 | **14.6 / 5.8** | 14.1 / 9.0 (canal 1 ya en umbral) |

**Elegido: Δf = 150 kHz (DR = 1.30).** Da +6 dB respecto a 75 kHz, lo esperado porque (150/75)² = 4. Además, DR = 1.30 está cerca de la FM estéreo comercial (75/53 ≈ 1.4) y el ancho cabe holgadamente en la FI. Con 250 kHz se ganan otros +4 dB, pero el umbral aparece antes y la FI queda más ajustada a 4.8 MHz.

**Anchos de banda:**
- **Carson:** B_T = 2(150 + 115) = **530 kHz**. Abarca ≈ 98 % de la potencia [CURSO diap. 326].
- **Bessel** [CURSO diap. 327] [TOMASI ec. 6-27]: con β = 1.30, J₀ = 0.67, J₁ = 0.52, J₂ = 0.17, J₃ = 0.037, J₄ = 0.006. Hay 3 bandas laterales ≥ 0.01, así que B = 2·3·115 = **690 kHz**. Como advierten el curso y Tomasi, con índices bajos o medios Carson se queda corto.
- **Medido.** Hay dos mediciones con señales distintas, y no deben mezclarse:
  - Prototipo en Python, peor caso de tres tonos de 15 kHz a plena escala (pico m_n = 1): BW 99 % = **292 kHz**, BW 99.9 % = **450 kHz**.
  - Simulink, fuentes de ruido de 0.3–15 kHz (desviación pico 91.6 kHz, 61 %): BW 98/99/99.9 % = **119 / 148 / 229 kHz**.
  - En los dos casos el ancho queda dentro de Carson (530 kHz) y del paso de FI (700 kHz).
- **Decisión:** se dimensiona con el valor más exigente (Bessel, 690 kHz). Por eso el paso del preselector y de la FI es ±350 kHz.

### 6.5 RF / LO / FI — inyección

| | Inferior (elegida) | Superior (ejemplos del curso, diap. 361) |
|---|---|---|
| f_LO a 10 MHz | 8.3 MHz | 11.7 MHz |
| Imagen | f_c − 2f_FI = 6.6 MHz | f_c + 2f_FI = 13.4 MHz |
| Producto suma máximo (+B/2) | 20.65 MHz → f_s > 41.3 MHz | 24.05 MHz → f_s > 48.1 MHz |
| Espectro en FI | No invertido | Invertido: el multiplex sale con signo − |

Los ejemplos del curso y de Tomasi usan inyección superior. En radiodifusión AM se usa por el rango de sintonía del oscilador, un argumento que aquí no aplica porque el rango es de solo 9–11 MHz. **Elegimos inferior** porque la f_s = 48 MHz es suficiente sin aliasing y no hay inversión espectral. Queda como parámetro: con inyección superior bastaría invertir el signo del demodulador y revalidar f_s.

**Comprobaciones:**
- |10 − 8.3| = 1.7 MHz ✓.
- f_FI/f_m,max = 14.8 ✓ (cumple la definición de superheterodino del curso).
- La banda FI, 1.35–2.05 MHz, no toca DC ✓.
- El LO, la RF y el producto suma quedan fuera del paso FI ✓.

**Rechazo de imagen** [TOMASI ec. 4-9]: IFRR = √(1 + Q²ρ²), con ρ = f_im/f_RF − f_RF/f_im = 0.66 − 1.515 = −0.855 (no depende de K).
- Un preselector analógico de un solo circuito con Q = 50 daría IFRR = √(1 + 42.75²) ≈ 42.8.
- El preselector FIR propuesto da ≥ 60 dB (relación ≥ 1000). En Simulink se mide directamente como la ganancia en f_RF entre la ganancia en f_im.

### 6.6 Frecuencias de muestreo (multirritmo)

```
TX:  audio 48 kHz --x10--> FDM 480 kHz --x100--> RF 48 MHz
RX:  RF 48 MHz --FI, /10--> 4.8 MHz --demod, LPF, /10--> 480 kHz --demux, /10--> 48 kHz
```

| Etapa | f_max | 2f_max | f_s | ✓ |
|---|---|---|---|---|
| Audio | 15 kHz | 30 kHz | 48 kHz | ✓ |
| Multiplex | 120 kHz | 240 kHz | 480 kHz | ✓ |
| RF + mezclador | 20.65 MHz | 41.3 MHz | 48 MHz | ✓ |
| FI decimada | 2.25 MHz (borde de rechazo) | 4.5 MHz | 4.8 MHz | ✓ |

### 6.7 Filtros (FIR de fase lineal, Kaiser, 60 dB)

> Los coeficientes definitivos los genera `params_sistema.m` con `disenar_fir_kaiser.m`, sin toolboxes. Los órdenes N pueden diferir en unas pocas unidades de esta tabla, porque la función sube el orden hasta medir el rechazo pedido. La fuente de verdad es la salida de `params_sistema`.

| Filtro | f_s | Paso / rechazo (nominal) | N |
|---|---|---|---|
| LPF audio TX | 48 kHz | 15 / 18 kHz | 63 |
| Interpolación ×10 (audio → multiplex) | 480 kHz | 15 / 33 kHz | 105 |
| Prénfasis (opcional) | 480 kHz | g·(1 − a z⁻¹), f₀ = 30 kHz | 2 |
| Interpolación ×100, etapa a (×10) | 4.8 MHz | 120 / 360 kHz | 75 |
| Interpolación ×100, etapa b (×10) | 48 MHz | 120 kHz / 4.68 MHz | 47 |
| Preselector (sintonizable) | 48 MHz | f_c ± 0.35 / ± 1.55 MHz | 167 |
| Pasabajos FI antes de ↓10 | 48 MHz | 2.05 / 2.75 MHz | 251 |
| Pasabanda FI | 4.8 MHz | 1.35–2.05 / 1.15 y 2.25 MHz | 93 |
| LPF I/Q | 4.8 MHz | 400 / 950 kHz | 33 |
| LPF multiplex (posdetección) + ↓10 | 4.8 MHz | 120 / 240 kHz | 147 |
| Deénfasis (opcional) | 480 kHz | (1/g) / (1 − a z⁻¹) | IIR, 1 polo |
| **BPF canal 1** | 480 kHz | **5–35 kHz**, rechazo en 0 Hz y > 40 kHz | 355 |
| BPF canales 2 y 3 | 480 kHz | f_k ± 15 kHz / rechazo desde f_k ± 25 kHz | 177 |
| LPF tras producto + ↓10 | 480 kHz | 15 / 20 kHz | 351 |

Los N se recalcularon con el mismo algoritmo de `disenar_fir_kaiser.m`. El preselector tiene el mismo N para cualquier f_c, porque N solo depende del ancho de transición.

**El canal 1 usa un pasabanda (5–35 kHz), igual que los canales 2 y 3.** Así los tres canales tienen el mismo tipo de filtro, y además se elimina cualquier nivel de DC a la salida del demodulador, como el que aparece cuando el receptor está desintonizado. Para esto sirve dejar libre el margen de 0–5 kHz del plan. [VERIFICADO-PY] Con el discriminador clásico, un pasabajos que deja pasar 0 Hz hacía caer el SDR del canal 1 a 3.6 dB.

**Compensación de retardo:** τ_k = Σ (N_i − 1)/(2f_s,i), sumando todos los FIR entre la modulación DSB-SC y el producto del canal k, más ½ muestra del demodulador. En el RX se usa cos(2π f_k (t − τ_k)). **Alternativa más cercana al curso:** un tono piloto [diap. 243], como en la FM estéreo. Queda como mejora opcional.

### 6.8 Demodulador FM

El curso presenta dos familias [diap. 342–354]:
- **Directa:** discriminadores de frecuencia (detector de pendiente, balanceado, Foster-Seeley, detector de relación). Todos convierten FM en AM y detectan la envolvente, y requieren un limitador.
- **Indirecta:** PLL.

| Opción | Implementación digital | [VERIFICADO-PY] canal ideal |
|---|---|---|
| **Cuadratura (base)** | Mezcla I/Q en FI → f_i = (f_s/2π)·arg(z[n]·z*[n−1]) | SDR 46 / 46 / 46 dB, diafonía −72 dB |
| Discriminador del curso | Limitador ideal → derivador FIR → detector de envolvente (Hilbert) | SDR 36.5 / 39.8 / 45.1 dB, diafonía ≤ −44 dB |
| Discriminador con rectificador + LPF | — | Malo a 4.8 MHz (≈ 10 dB): los armónicos del rectificador se pliegan en banda |
| PLL | Lazo con VCO digital | No probado |

**Recomendación:** usar el **demodulador en cuadratura** como base. Es la forma discreta exacta del discriminador ideal (f_i = (1/2π)·dφ/dt), no necesita limitador y da la mejor calidad. Para la parte teórica del video conviene implementar también el **discriminador del curso** (limitador + derivador + envolvente) y compararlos: es un buen momento para demostrar dominio de la materia.

### 6.9 Definición de AWGN (alineada con el curso)

**Definición principal [CURSO diap. 377]:** (SNR)_C = (A_c²/2) / (W·N₀), con W = 120 kHz (el mensaje es el multiplex). Es la misma definición de la figura de mérito de Haykin.

**Implementación:** el ruido se suma a f_s,RF con varianza σ² = N₀·f_s/2.

**Equivalencias:**
- CNR en el ancho de Carson = (SNR)_C − 10·log₁₀(B_T/W) = (SNR)_C − **6.45 dB**.
- Si el bloque AWGN define la SNR sobre toda la banda muestreada: SNR_bloque = (SNR)_C − 10·log₁₀((f_s/2)/W) = (SNR)_C − **23.0 dB**.

**SNR teórica por canal** (derivada de S_No(f) = N₀f²/A_c² del curso, con demodulación coherente del canal k):

(SNR)_k = (SNR)_C · W·Δf²·P_x / [18·W_a·(f_k² + W_a²/3)]

Aquí P_x es la potencia de cada audio normalizado; el 18 sale de la normalización /3 y de la detección coherente.

[VERIFICADO-PY] Con P_x ≈ 0.066–0.074:

| (SNR)_C | Canal 1 medido / teoría | Canal 2 medido / teoría | Canal 3 medido / teoría |
|---|---|---|---|
| 35 dB | 35.4 / 36.4 | 26.8 / 27.4 | 23.3 / 23.7 |
| 25 dB | 25.6 / 26.4 | 17.0 / 17.4 | 13.2 / 13.7 |
| 20 dB | 20.6 / 21.4 | 11.9 / 12.4 | 8.6 / 8.7 |
| 17 dB | 14.6 / 18.4 | 8.4 / 9.4 | 5.8 / 5.7 |
| 15 dB | 6.5 / 16.4 | 4.7 / 7.4 | 3.6 / 3.7 |

Por encima del umbral, la teoría coincide con la simulación con un error de alrededor de 1 dB. Por debajo de (SNR)_C ≈ 17 dB, es decir CNR ≈ 10.5 dB en B_T, la medida se aleja bruscamente de la teoría: es el **efecto umbral** [CURSO diap. 381–382].

**Barrido para el video:** (SNR)_C = 35, 25, 20, 17, 15 dB.

### 6.10 Duraciones

- Pruebas con tonos: 0.1–0.2 s reales, es decir 10–20 s simulados (4.8–9.6 M muestras RF).
- Demostración final: 1–2 s reales, es decir 100–200 s simulados (48–96 M muestras).
- Referencia: el prototipo en Python procesa 14.4 M muestras (TX+RX) en ≈ 2–5 s. En Simulink el tiempo hay que medirlo.

---

## 7. Arquitectura por bloques

Sigue el esquema del curso [diap. 259 FDM, 358 superheterodino]:

```
TRANSMISOR
 x1,x2,x3 (48 kHz) → LPF 15 kHz + normalización → ↑10 (480 kHz)
   → × cos(2π f_k t)  (DSB-SC, k = 1..3) → Σ → ÷3 = m_n          [espectro del multiplex]
   → ↑100 (48 MHz) → MODULADOR FM: φ[n] = 2π f_c n/f_s + 2π k_f Σ m_n/f_s ; s = A cos φ   [espectro RF]
CANAL:  ideal | + AWGN ((SNR)_C)
RECEPTOR SUPERHETERODINO
   → SECCIÓN DE RF: preselector centrado en f_c (rechaza la imagen f_c − 3.4 MHz)
   → MEZCLADOR × 2cos(2π f_LO t),  f_LO = f_c − f_FI (automático)     [FI + producto suma]
   → SECCIÓN DE FI: pasabanda 1.35–2.05 MHz → ↓10 (4.8 MHz)            [espectro FI]
   → DEMODULADOR FM (cuadratura; alternativa: discriminador del curso) → ×3/Δf
   → LPF 120 kHz (filtro posdetección, diap. 376) → ↓10 = multiplex recuperado
DEMULTIPLEXOR FDM (3 ramas)
   → BPF canal k → × 2cos(2π f_k (t − τ_k)) → LPF 15 kHz → ↓10 → audio k (48 kHz)
SELECTOR DE AUDIO (GUI) → altavoz y gráficas
```

**Las dos selecciones de la GUI:**
1. **Sintonía RF** (9.0–11.0 MHz): fija f_c en el TX y recalcula f_LO, el preselector y la imagen. Muestra f_c, f_LO, f_FI e imagen en **valores nominales** (simulado × K).
2. **Audio 1/2/3**: un conmutador **después** de la demultiplexación que no toca el LO.

**Opcionales:**
- AWGN on/off y (SNR)_C.
- Δf seleccionable (75 / 150 / 250 kHz), para mostrar el compromiso SNR–ancho de banda del curso. Implica recalcular los filtros FI y el preselector.
- Desintonía del RX.
- Señal interferente en la imagen.

---

## 8. Plan de implementación y pruebas

| Etapa | Qué construir | Qué mostrar | Criterio [DECISIÓN] |
|---|---|---|---|
| 0 | `params_sistema.m`: valores de §6, coeficientes FIR, τ_k, comprobaciones `assert` | Tabla nominal/simulado | Todas las comprobaciones pasan |
| 1 | Fuentes: audio real (`audioread` → mono → 48 kHz → LPF → pico 1) y tonos | Tiempo y espectro | ≤ 15 kHz |
| 2 | FDM TX | Espectro del multiplex con bandas y guardas | 5–35 / 45–75 / 85–115 kHz; \|m_n\| ≤ 1 |
| 3 | Modulador FM | Espectro RF, f_i(t), BW medido frente a Carson y Bessel | Desviación ≤ 150 kHz |
| 4 | FM espalda con espalda | m frente a m̂ | Aísla el modulador y el demodulador |
| 5 | Superheterodino | Espectros: RF, preselector, mezclador (FI + suma), FI; barrido de 9/10/11 MHz; desintonía; imagen (IFRR medida) | FI siempre en 1.7 MHz |
| 6 | Demultiplexación | Audios frente a originales; ganancias con y sin τ_k; diafonía | Ganancia ≈ 1; diafonía < −40 dB |
| 7 | GUI (App Designer → `sim`) | Sintonía → LO; selector → audio | Actualización automática |
| 8 | AWGN | Barrido de (SNR)_C; comparación con la fórmula de §6.9; umbral; efecto f² por canal; prénfasis/deénfasis on/off (E4) | Explicado con la teoría del curso |

**Toolboxes:** solo MATLAB y Simulink básicos (ver §8b-1). No se usan DSP System Toolbox, Signal Processing Toolbox ni Communications Toolbox.

**Consejos para Simulink:** solver discreto de paso fijo, procesamiento por tramas y registrar solo las señales decimadas.

---

## 8b. Estado de la implementación

**Etapa 0 completada** (carpeta `proyecto_matlab/`, solo MATLAB básico + Simulink; ver §8b-1):
- `params_sistema.m`: todos los parámetros de §6, filtros, τ_k, AWGN y 18 comprobaciones `assert`.
- `disenar_fir_kaiser.m`: diseño FIR por ventana de Kaiser con verificación de la respuesta, sin Signal Processing Toolbox.
- `modelo_referencia.m`: la cadena completa en MATLAB con filtros causales. Es la referencia contra la que se comparará el `.slx`.
- `comparar_senales.m`: SDR con alineación de retardo fraccionario y de ganancia.
- `graficar_filtro.m`.
- `prueba_etapa0.m`: script de verificación.

**[VERIFICADO-MATLAB-REF]** Ejecutado en GNU Octave con el mismo código `.m`, pendiente de repetir en MATLAB R2026a. T = 0.1 s reales.

| Prueba | Resultado |
|---|---|
| SDR canal ideal, f_c = 9 / 10 / 11 MHz | 60.4 / 59.9 / 60.0 dB en los tres casos, ganancia ≈ 1.002 |
| Diafonía (solo canal 2 activo) | −71.4 dB y −71.5 dB |
| Ganancia sin compensar τ_k | +0.74 / +0.16 / +0.97 (teoría: idéntica). Corresponde a los filtros de una sola etapa; con los filtros actuales es +0.09 / −0.87 / −0.65 |
| AWGN, (SNR)_C = 35 / 25 / 20 dB | Medido dentro de ≈1 dB de la fórmula de §6.9 |
| AWGN, (SNR)_C = 17 dB | Canal 1: 13.1 dB frente a 18.9 teóricos → efecto umbral |

**Etapas 1–6 verificadas en Simulink R2026a** (`construir_modelo.m` genera `sistema_fdm_fm.slx` solo con bloques básicos). **[RESULTADO VERIFICADO]**, 0.05 s reales, fuentes de ruido 0.3–15 kHz, canal ideal, f_c = 10 MHz:

| Etapa | Comparación Simulink frente a referencia | Resultado |
|---|---|---|
| 2. Transmisor FDM | m_n: 3e-12 | Bandas 5–35 / 45–75 / 85–115 kHz, guardas ≈ −75 dB |
| 3. Interpolación ×100 + FM | m_rf: 1.6e-12; s_FM: 1.4e-9 | Desviación pico 91.6 kHz (61 %); BW 98/99/99.9 % = 119/148/229 kHz frente a Carson 530 y Bessel 690 kHz |
| 5. Superheterodino | FI: 5e-10; multiplex: 1.2e-10 | Mezclador: FI en 1.7 MHz y producto suma en 18.3 MHz |
| 6. Demultiplexor | Audios: 9e-12 a 4e-11 | **SDR 60.3 / 59.4 / 57.1 dB**, ganancia ≈ 1.00 |

**Decisiones tomadas durante la implementación [DECISIÓN]:**
- **Retardo del Rate Transition.** Al pasar de una tasa lenta a una rápida, el bloque retrasa **1 muestra lenta**, aun en modo de una sola tarea. Se midió en `verificar_etapa2`. Es determinista, así que se modela (`P.rt_retardo = 1`) en la referencia y en τ_k. La decimación (de rápida a lenta) no añade retardo (`P.rt_dec = 0`, verificado).
- **Interpolación ×100 en dos etapas de ×10** y **sección de FI en dos etapas** (pasabajos antialiasing a 48 MHz, ↓10, pasabanda selectivo a 4.8 MHz). Hacen lo mismo con mucho menos cálculo que un solo FIR a 48 MHz. El retardo total cambió, y las ganancias sin compensar (+0.09 / −0.87 / −0.65) coinciden con la predicción.
- **Modo acelerado de Simulink:** 4.3 veces más rápido, con resultados idénticos (diferencia 0). Tiempo del sistema completo: ≈ 13 s por cada 0.05 s de audio real, es decir ≈ 4.5 min por segundo de audio.
- **f_s,RF = 48 MHz** se mantiene (no 24 MHz), para que el producto suma aparezca en su frecuencia real en el video.
- **Desintonía del receptor** como opción de la GUI. Con 50 kHz se recupera bien, porque el pasabanda de cada canal elimina el nivel de DC. Con 600 kHz el SDR cae a ≈ 0 dB: esto demuestra la selección de la portadora.

**Etapa 7 (GUI) verificada en MATLAB R2026a:**

| Caso | LO | Resultado |
|---|---|---|
| f_c = 10 MHz | 8.30 MHz | SDR del audio 1 = 69 dB (fuente demo) |
| f_c = 11 MHz | 9.30 MHz, recalculado automáticamente | Producto suma en 20.3 MHz; SDR = 69 dB |
| f_c = 11 MHz con 600 kHz de desintonía | 9.90 MHz | La señal cae en 1.1 MHz, fuera del paso FI; SDR = 0.9 dB |

Cada simulación de 0.3 s reales tarda ≈ 40 s en modo acelerado.

**Etapa 8 (AWGN):** `verificar_etapa8.m` hace un barrido de (SNR)_C frente a la teoría y una prueba con y sin preselector. En la referencia (Octave), quitar la sección de RF cuesta **3.0 / 2.9 / 2.8 dB**: el ruido de la banda imagen se convierte a la FI, como predice la teoría (3 dB). Es el argumento cuantitativo para el preselector.

**Etapa 8 verificada en Simulink** (0.1 s reales, fuentes de ruido, f_c = 10 MHz). **[RESULTADO VERIFICADO]**

| (SNR)_C [dB] | CNR en B_T [dB] | SDR medido c1/c2/c3 [dB] | Teoría §6.9 [dB] |
|---|---|---|---|
| 40 | 33.5 | 41.9 / 31.2 / 27.7 | 42.4 / 32.0 / 28.2 |
| 30 | 23.5 | 32.0 / 21.3 / 17.7 | 32.4 / 22.0 / 18.2 |
| 20 | 13.5 | 21.9 / 11.5 / 8.2 | 22.4 / 12.0 / 8.2 |
| 18 | 11.5 | 17.5 / 9.6 / 6.4 | 20.4 / 10.0 / 6.2 |
| 16 | 9.5 | 11.9 / 6.6 / 4.4 | 18.4 / 8.0 / 4.2 |
| 14 | 7.5 | 4.1 / 2.7 / 2.1 | 16.4 / 6.0 / 2.2 |
| 10 | 3.5 | 0.4 / 0.2 / 0.3 | 12.4 / 2.0 / −1.8 |

- **Por encima del umbral:** el SDR medido queda entre 0.4 y 0.8 dB por debajo de la teoría de Haykin.
- **Umbral FM:** aparece con CNR ≈ 11–12 dB en B_T. El canal 1, que es el de menos ruido f², es el primero en separarse de la teoría. Por debajo de CNR ≈ 7 dB los tres canales colapsan a ≈ 0 dB.
- **Diferencia entre canales:** la medida (10.7 y 14.3 dB) coincide con la teoría para las potencias reales de cada audio (10.4 y 14.2 dB). Con potencias iguales sería 8.9 y 13.3 dB, debido solo al ruido f².
- **Sin preselector**, con (SNR)_C = 25 dB, el SDR baja **3.0 / 2.7 / 2.6 dB**: el ruido de la banda imagen pasa a la FI.

**Detalle de la etapa 7:** `radio_fdm_fm.m` y `main.m`.
- **Sintonía:** la perilla de 9–11 MHz recalcula LO, imagen y preselector.
- **Selector de audio 1/2/3:** actúa después del demux, sin volver a simular.
- **Otros controles:** AWGN con (SNR)_C, fuente «demo» (arpegio, sirena y pitidos) y botones para escuchar el audio original y el recuperado a 48 kHz.

**§8b-1 Toolboxes del equipo:** ambos integrantes tienen R2026a; uno de ellos no tiene DSP System Toolbox ni Signal Processing Toolbox. **[DECISIÓN]** Todo el proyecto usa solo MATLAB básico y Simulink básico:
- **Filtros:** Discrete FIR Filter.
- **Cambio de tasa:** Rate Transition, con inserción de ceros mediante un tren de pulsos al interpolar.
- **Espectros:** propios, calculados con `fft`.

## 9. Consultas al profesor y entrega de archivos

No hay ninguna contradicción técnica bloqueante. La duda administrativa quedó resuelta: **además del video se entregan los `.slx` y `.m`** (R13).

**Consecuencias para la implementación [DECISIÓN]:** como el profesor abrirá y ejecutará los archivos, el modelo debe funcionar sin depender de nuestro equipo.
- **Un solo punto de entrada.** Un script, por ejemplo `main.m`, que ejecute `params_sistema.m`, abra la GUI o simule el modelo con los valores por defecto.
- **Rutas relativas.** Sin rutas absolutas de nuestras computadoras; los audios de prueba van dentro de la carpeta entregada.
- **Parámetros centralizados.** Ningún número escrito a mano dentro de los bloques del `.slx` (lo pide también el §8 del enunciado).
- **Versión de MATLAB y toolboxes.** Anotar con `ver` en qué versión se guardó el `.slx` y qué toolboxes usa. Guardar con la versión más antigua que tenga el equipo, para que se pueda abrir.
- **Ejecución razonable con los valores por defecto.** Por ejemplo, un clip corto, de modo que la simulación termine en un tiempo prudente.
- **Comentarios mínimos** en cada `.m` y anotaciones en cada subsistema del `.slx` que indiquen qué hace el bloque y con qué ecuación del documento se corresponde.

Estas son decisiones de organización del equipo; el profesor no fijó ningún formato.
