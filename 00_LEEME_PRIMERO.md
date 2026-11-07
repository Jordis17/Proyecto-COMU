# Paquete de revisión — Proyecto FDM + FM + receptor superheterodino

Comunicaciones Eléctricas I (EL5513), ITCR, II semestre 2026. Equipo: Jordi y Abner.

Este paquete reúne todo lo necesario para que una IA (u otra persona) **revise el proyecto** sin haber participado en su desarrollo. Léelo completo antes de abrir los demás archivos.

---

## 1. Qué se te pide

Actúa como **revisor técnico** del proyecto. Tu trabajo es:

1. Comprobar que el diseño y el código cumplen el objetivo del enunciado (sección 3 de este archivo).
2. Verificar que las **correcciones a los errores intencionales del enunciado** están bien demostradas y justificadas.
3. Revisar el código MATLAB/Simulink: coherencia con el documento de diseño, errores, riesgos, cosas que podrían fallar en la computadora del profesor.
4. Señalar lo que falte para el entregable (video de ~10 min + archivos `.m`/`.slx`).
5. Proponer mejoras concretas, priorizadas, sin rehacer lo que ya funciona.

Reglas de trabajo (vienen de las instrucciones del proyecto, archivo `07_instrucciones_permanentes_IA.md`):

- Responde en **español**, al nivel de estudiantes de ingeniería electrónica.
- Para cada cálculo: fórmula, sustitución, unidades, resultado e interpretación.
- Distingue siempre: **[REQUISITO ORIGINAL]**, **[ERROR DEMOSTRADO]**, **[DATO NO ESPECIFICADO]**, **[DECISIÓN DEL EQUIPO]** y **[RESULTADO VERIFICADO]**.
- **No inventes resultados.** Tú no puedes ejecutar MATLAB/Simulink: distingue lo que verificaste leyendo/calculando de lo que habría que correr. Los resultados de la sección 6 sí fueron medidos por el equipo en MATLAB R2026a.
- No inventes rúbricas, SNR mínimas ni toolboxes obligatorias.
- La **presentación del curso** es la referencia principal; cita diapositivas cuando puedas (texto OCR en `05_material_curso/`).
- Si encuentras un error, muestra: `texto/código actual → problema → corrección → justificación → cómo probarlo`.

---

## 2. Contenido del paquete

| Carpeta / archivo | Qué es |
|---|---|
| `00_LEEME_PRIMERO.md` | Este archivo: contexto, estado y resultados |
| `07_instrucciones_permanentes_IA.md` | Instrucciones permanentes del proyecto (rol, criterios, puntos a auditar) |
| `01_enunciado/enunciado_original_profesor.md` | Enunciado del profesor. **Contiene errores intencionales** |
| `02_diseno/diseno_final.md` | **Documento principal**: resumen corto del diseño, resultados y propuesta del video |
| `02_diseno/01_diagnostico_y_diseno_FDM_FM.md` | Detalle completo: diagnóstico de errores, cálculos y estado de las etapas 0–8 |
| `02_diseno/prenfasis_deenfasis.md` | Detalle del prénfasis/deénfasis |
| `02_diseno/guion_video.md` | Guion del video (~10 min, repartido entre Jordi y Abner) |
| `02_diseno/preguntas_profesor.md` | 38 preguntas probables del profesor con respuesta corta |
| `PENDIENTES_MATLAB.md` | Lista de lo que hay que correr en MATLAB y qué debe salir |
| `03_codigo_matlab/` | Todo el código del proyecto (17 archivos `.m`) |
| `04_verificacion_python/proto_fdm_fm.py` | Prototipo en Python usado al inicio para validar el diseño |
| `05_material_curso/presentacion_curso_OCR.txt` | Texto OCR (en inglés aproximado, escaneo) de las 620 diapositivas del curso, separadas por `===== DIAPOSITIVA NNN =====` |
| `05_material_curso/indice_diapositivas.md` | Índice de las diapositivas relevantes al proyecto |
| `06_guia_estudio/guia_fdm_fm.html` | Guía de estudio interactiva del proyecto (abrir en navegador). Resume teoría + proyecto |

**No incluido (por tamaño):** el PDF de la presentación (48 MB), Haykin, Tomasi y Stremler. Están en la carpeta del equipo; se pueden subir aparte si hace falta. El modelo `sistema_fdm_fm.slx` **no se incluye porque se genera** ejecutando `construir_modelo.m` (o `main.m`).

---

## 3. El proyecto en una página

Tres audios de 15 kHz → **FDM** (DSB-SC) en ≤ 120 kHz → **FM** con portadora seleccionable de 9–11 MHz → canal (ideal o **AWGN**) → **receptor superheterodino** (sección de RF, oscilador local, mezclador, sección de FI de 1.7 MHz) → demodulador FM → demultiplexor FDM → audio 1, 2 o 3 en una **GUI tipo radio**. Todo en MATLAB/Simulink.

### Decisiones principales del equipo

| Tema | Decisión | Justificación corta |
|---|---|---|
| Escalamiento | Uniforme **K = 100** a todo (audio, subportadoras, Δf, filtros, RF, LO, FI) | La tabla del enunciado escala solo RF/FI → proporciones rotas |
| Arquitectura de simulación | **Multirritmo**: audio 48 kHz, multiplex 480 kHz, FI 4.8 MHz, RF 48 MHz (nominales) | Escalar no reduce muestras; el ahorro real viene de las tasas por etapa |
| FDM | DSB-SC, subportadoras **20 / 60 / 100 kHz**, bandas 5–35 / 45–75 / 85–115 kHz, guardas 10 kHz, multiplex ÷3 | Audio llega casi a 0 Hz → SSB exigiría filtros casi ideales |
| FM | **Δf = k_f = 150 kHz**, f_m,máx = 115 kHz, DR = 1.30, Carson 530 kHz, Bessel (n = 3) 690 kHz | Compromiso SNR (∝Δf²) / ancho de banda |
| Superheterodino | **Inyección inferior** f_LO = f_c − 1.7 MHz; imagen f_c − 3.4 MHz; sección de RF (preselector) ±350 kHz (rechazo 60 dB desde ±1.55 MHz); FI 1.35–2.05 MHz en dos etapas (LPF a 48 MHz, ↓10, BPF a 4.8 MHz) | Suma más baja (cabe en 48 MHz), sin inversión espectral |
| Demodulación FM | En **cuadratura**: f_i = (f_s/2π)·arg(z[n]·z*[n−1]) con atan2 | Discriminador del curso (limitador→derivador→envolvente) probado como alternativa, peor desempeño |
| Detección DSB-SC | Coherente con fase compensada: cos(2π f_k (t − τ_k)), τ_1 = 411.79 µs, τ_2 = τ_3 = 226.37 µs | Sin compensar, ganancias +0.09 / −0.87 / −0.65 |
| Filtros | FIR Kaiser propios (`disenar_fir_kaiser.m`), 60 dB | **Sin toolboxes**: Abner no tiene DSP ni Signal Processing Toolbox |
| Simulink | Solo bloques básicos; solver discreto paso fijo; `EnableMultiTasking` off; modo acelerado | Portabilidad y velocidad (4.3×) |
| Ruido | (SNR)_C de Haykin = A_c²/(2·W·N₀), W = 120 kHz | Definición del curso (diap. 377) |
| Prénfasis/deénfasis | Filtros de 1.er orden sobre el multiplex (antes del modulador / después del demodulador), f₀ = 30 kHz, misma desviación pico; on/off en la GUI | Curso diap. 384–387; reparte la SNR: canal 3 ≈ +2 dB, canal 1 ≈ −6 dB (teoría y Python; falta Simulink) |

### Errores del enunciado detectados (resumen; detalle en el documento de diseño)

1. **Tabla de escalamiento (§5):** escala portadora y FI ÷100 pero deja audio y FDM → B_FDM/f_c pasa de 0.012 a 1.2, la FM cruza 0 Hz, FI (17 kHz) < f_m,máx (115 kHz). **Corrección:** escalar todo por K = 100.
2. **«Se escala por limitaciones computacionales»:** escalar no ahorra muestras (N = T_real·f_s,nominal). El ahorro se obtiene con multirritmo.
3. **Muestrear a 5–10 × ancho de banda (§8):** el criterio es f_s > 2·f_máx incluyendo el producto suma del mezclador (hasta 20.65 MHz) → 48 MHz.
4. **Prénfasis/deénfasis (§4.5) no es un error:** es una condición. Con canal ideal no hace falta (SDR ≈ 60 dB). Con AWGN el canal 3 sale unos 14 dB peor por el ruido ∝ f², así que se implementa sobre el multiplex y se mide (`analisis_awgn.m`).
5. **Matices de redacción:** «índice de modulación» con mensaje compuesto → DR; falta sección de RF (preselector) en el receptor descrito.

---

## 4. Cómo se ejecuta (en MATLAB R2026a + Simulink, sin toolboxes)

```matlab
cd 03_codigo_matlab
main                 % tabla de diseño + genera el .slx si hace falta + abre la radio
graficas_sistema     % gráficas de cada etapa con canal ideal (~1 min)
analisis_awgn        % AWGN sin y con prénfasis/deénfasis (~8-10 min)
probar_audio_real    % 3 WAV reales en audios/ -> audios recuperados en WAV (~9 min para 2 s)
preparar_entrega     % copia la entrega a ../../entrega_FDM_FM, la revisa y crea el .zip
```

Pruebas internas del equipo (no van en la entrega), en `03_codigo_matlab/verificacion/`:

```matlab
addpath verificacion
prueba_etapa0        % referencia en MATLAB (sin Simulink)
verificar_etapa2     % transmisor FDM: Simulink vs referencia
verificar_etapa3     % modulador FM
verificar_etapa5     % cadena completa, canal ideal
verificar_etapa8     % barrido AWGN y prueba sin preselector
```

### Archivos de `03_codigo_matlab/`

Se entregan 8 `.m` (los marcados con ✔), el `.slx` y los audios; el resto queda para el equipo. `preparar_entrega` crea además `entrega_FDM_FM_respaldo.zip`, la versión anterior con 10 `.m` (incluye `analisis_awgn.m` y `probar_audio_real.m`), que **no se manda** y queda como respaldo.

| Archivo | Función |
|---|---|
| ✔ `main.m` | Punto de entrada: imprime el diseño y abre la radio |
| ✔ `params_sistema.m` | Todos los parámetros, filtros, retardos τ_k y σ del ruido; 9 comprobaciones del diseño. Opciones: `imprimir`, `snr_c_dB`, `T_real`, `desintonia`, `enfasis` (false), `f0_enfasis` (30 kHz), `log_rf_max` |
| ✔ `disenar_fir_kaiser.m` | Diseño FIR LP/BP por ventana de Kaiser; sube el orden hasta cumplir el rechazo |
| `construir_modelo.m` | **(No se entrega.)** Genera `sistema_fdm_fm.slx` por código (subsistemas Transmisor FDM, Modulador FM, Canal, Receptor superheterodino, Demultiplexor FDM) y pone los nombres de bloques y señales (sección 5) |
| `modelo_al_dia.m` | **(No se entrega.)** Genera el `.slx` solo si no existe (el `.slx` del repositorio está ordenado a mano y nunca se sobrescribe solo). Los scripts de la entrega lo usan solo si existe; sin él, usan el `.slx` tal cual |
| ✔ `generar_fuentes.m` | Fuentes: `demo`, `tonos`, `ruido`, `audio` (WAV en la carpeta `audios/`, que hay que crear) |
| ✔ `radio_fdm_fm.m` | GUI: perilla de portadora, LO automático, selector de audio, AWGN, prénfasis, desintonía |
| ✔ `graficas_sistema.m` | Figuras de cada etapa: audios, multiplex, FM con Carson, receptor, audios recuperados |
| `analisis_awgn.m` | **(No se entrega; resultados en el video.)** Barrido AWGN frente a la teoría, sin y con prénfasis. Guarda CSV, MAT y PNG |
| `probar_audio_real.m` | **(No se entrega; los WAV recuperados se usan en el video.)** Pasa `audios/audio1..3.wav` por el sistema y guarda `recuperado1..3.wav` (ver `audios/LEEME.txt`) |
| ✔ `graficar_espectro.m` | Espectro sin toolbox (Welch propio) |
| ✔ `comparar_senales.m` | SDR alineando retardo (fraccionario) y ganancia |

En `verificacion/` quedan `modelo_referencia.m` (la misma cadena en MATLAB puro), `graficar_filtro.m`, `prueba_etapa0.m` y `verificar_etapa2/3/5/8.m`.

---

## 5. Detalles de implementación que conviene saber

- **Nombres en el modelo:** las señales principales usan la notación del curso: x1(t)–x3(t) (audios, diap. 264), m(t) multiplex (mensaje que entra al modulador, diap. 309/384), s(t) señal FM, x(t) = s(t) + w(t) (lo que llega al receptor, diap. 365), m(t) recuperado y audio k recuperado. Los bloques tienen nombres en español con términos del curso: «Sección de RF (preselector)», «Oscilador local», «Mezclador», «Filtro antitraslape», «Sección de FI», «Demodulador FM», «Filtro posdetección», «Filtro de preénfasis/deénfasis» y, en cada canal, «pasabanda», «oscilador local», «detector coherente», «pasabajos 15 kHz». Los cambios de frecuencia de muestreo se llaman «Subir tasa 1 a 10» y «Bajar tasa 10 a 1». En el código (`params_sistema.m`) se sigue usando `m_n` para el multiplex normalizado.
- **Rate Transition** (lenta → rápida) añade 1 muestra lenta de retardo incluso en una sola tarea (medido) → `P.rt_retardo = 1`. La decimación no añade retardo.
- **From Workspace**: los tiempos se adelantan 0.25 muestra para evitar que tome la muestra anterior por redondeo.
- Interpolación ×100 en dos etapas ×10 (inserción de ceros con Pulse Generator × Rate Transition + FIR).
- El filtro del canal 1 en el demux es **pasabanda** (5–35 kHz), igual que los otros dos: elimina cualquier nivel de DC a la salida del demodulador (por ejemplo, con desintonía).
- Teoría de ruido por canal: (SNR)_k = (SNR)_C · W·Δf²·P_x / [18·W_a·(f_k² + W_a²/3)].

---

## 6. Resultados verificados por el equipo (MATLAB R2026a)

| Prueba | Resultado |
|---|---|
| Referencia MATLAB, canal ideal (9/10/11 MHz) | SDR ≈ 60 dB |
| Simulink vs referencia: FI / multiplex | error 5·10⁻¹⁰ / 1.2·10⁻¹⁰ |
| Audios recuperados, canal ideal (Simulink) | SDR 60.3 / 59.4 / 57.1 dB |
| GUI, f_c = 10 MHz | LO 8.30 MHz, SDR 69 dB |
| GUI, f_c = 11 MHz | LO 9.30 MHz, SDR 69 dB |
| GUI, desintonía 600 kHz | SDR 0.9 dB (falla esperada) |
| Ancho FM medido (98 / 99 / 99.9 % potencia) | 119 / 148 / 229 kHz |
| Velocidad, modo acelerado | 13.4 s por 0.05 s de audio; ~40 s por 0.3 s en la GUI |

Barrido AWGN (`verificar_etapa8`, SDR en dB, canales 1/2/3):

| (SNR)_C [dB] | C1 | C2 | C3 |
|---|---|---|---|
| 40 | 41.9 | 31.2 | 27.7 |
| 35 | 37.0 | 26.3 | 22.7 |
| 30 | 32.0 | 21.3 | 17.7 |
| 25 | 27.0 | 16.3 | 12.8 |
| 20 | 21.9 | 11.5 | 8.2 |
| 18 | 17.5 | 9.6 | 6.4 |
| 16 | 11.9 | 6.6 | 4.4 |
| 14 | 4.1 | 2.7 | 2.1 |
| 12 | 1.2 | 0.8 | 0.8 |
| 10 | 0.4 | 0.2 | 0.3 |

- Teoría: desfases +2.4 / −8.0 / −11.8 dB respecto a (SNR)_C; Simulink queda a 0.4–0.8 dB sobre el umbral.
- Umbral: CNR ≈ 11 dB en el ancho de Carson.
- Sin preselector: −3.0 / −2.7 / −2.6 dB (teoría ≈ 3 dB, ruido de la banda imagen).

---

## 7. Estado y pendientes

- Etapas 0–8 **completas y verificadas** en MATLAB R2026a (ver documento de diseño).
- Los cambios de la revisión (prénfasis/deénfasis, limpieza del código, nombres de bloques, scripts nuevos) **todavía no se han corrido en MATLAB**: seguir `PENDIENTES_MATLAB.md`.
- El guion del video y las preguntas probables están en `02_diseno/`; faltan los datos marcados [PENDIENTE] (prénfasis medido en Simulink y audio real).
- Faltan los tres audios reales (`03_codigo_matlab/audios/audio1..3.wav`).

### Sugerencia de orden para la revisión

1. Leer el enunciado (`01_enunciado`) y buscar tú mismo los errores antes de ver la solución.
2. Leer `02_diseno/diseno_final.md` (y el detalle en `01_diagnostico_y_diseno_FDM_FM.md`) y contrastar.
3. Revisar `params_sistema.m` (corazón del diseño) y luego `construir_modelo.m`, `verificacion/modelo_referencia.m`, `radio_fdm_fm.m`.
4. Comprobar coherencia entre los números del documento, el código y los resultados de la sección 6.
5. Entregar: hallazgos priorizados (crítico / importante / menor), riesgos para la defensa en el video y preguntas probables del profesor.
