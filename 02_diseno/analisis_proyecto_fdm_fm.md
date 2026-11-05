# Análisis del enunciado: Sistema FDM + FM con receptor superheterodino

Inconsistencias entre teoría y especificaciones, trampas y puntos ambiguos.

---

## 1. El escalamiento de la tabla no mantiene las proporciones (inconsistencia principal)

El texto exige "mantener las relaciones relativas", pero la tabla no lo hace:

| Parámetro | Real | Tabla simulada | Factor |
|---|---|---|---|
| Portadora | 10 MHz | 100 kHz | ÷100 |
| FI | 1.7 MHz | 17 kHz | ÷100 |
| Audio | 15 kHz | 15 kHz | ÷1 |
| FDM | 120 kHz | 120 kHz | ÷1 |

Las frecuencias de RF se dividen entre 100 y las de banda base no se tocan. En el sistema real, el multiplex (120 kHz) es el 1.2 % de la portadora. En la tabla es el 120 %. Consecuencias:

- **Carson:** aun con índice casi cero, BW ≥ 2·f_m = 240 kHz. Centrada en 100 kHz, la señal FM iría de −20 kHz a 220 kHz, es decir, bajo cero. Con un β razonable (≥ 1) sería de −140 a 340 kHz. En señales reales esto produce aliasing contra el espejo de frecuencias negativas, y no se puede corregir después.
- **FI de 17 kHz:** la señal en FI ocuparía más de 240 kHz de ancho, así que ningún filtro de FI centrado en 17 kHz podría seleccionarla.
- **Demodulación:** un discriminador FM necesita FI ≫ f_m. Aquí la FI (17 kHz) es menor que el mensaje (120 kHz). En el sistema real, 1.7 MHz ≫ 120 kHz sí se cumple.
- **Frecuencia imagen:** con LO alto (117 kHz), la imagen cae en 134 kHz, solo 34 kHz de la portadora, dentro de la propia banda de la señal.

El enunciado dice que "los valores pueden variar si se mantienen las proporciones". Eso sugiere que cambiar la tabla es lo esperado, y la rúbrica da 10 puntos a "uso correcto del escalamiento". **Mi lectura: la tabla es la trampa.**

## 2. Recomendación de muestreo ambigua

"5 a 10 veces el ancho de banda máximo simulado" no dice qué ancho se toma:

- Con 15 kHz, fs = 75–150 kHz, que ni siquiera representa una portadora de 100 kHz (Nyquist exige > 200 kHz).
- Con 120 kHz, fs = 0.6–1.2 MHz, que alcanza para la tabla pero oculta el problema del punto 1.

En pasabanda, fs depende de la frecuencia más alta (portadora + BW/2, y el producto suma del mezclador en f_c + f_LO), no solo del ancho de banda.

## 3. "120 kHz" puede significar dos cosas

- **Interpretación A:** 120 kHz es el ancho del multiplex en banda base. Es lo más natural y lleva a BW_FM ≈ 240–480 kHz.
- **Interpretación B:** 120 kHz es el ancho total que puede ocupar la señal transmitida. Entonces Carson exige Δf pequeño (β < 1, FM de banda angosta).

Conviene confirmarlo con el profesor, porque cambia el diseño del índice de modulación.

## 4. Las subportadoras del FDM no están especificadas

El enunciado pide FDM pero no dice con qué modulación se desplazan los canales (DSB-SC, SSB o AM). Esto afecta el diseño:

- Tres canales DSB-SC ocupan 3×30 = 90 kHz, más guardas, y caben en 120 kHz.
- Con SSB bastarían 45 kHz, y los 120 kHz serían excesivos.
- DSB-SC y SSB requieren demodulación coherente. Con canal ideal es trivial, pero con AWGN la fase importa.

Ejemplo viable: subportadoras en 20, 60 y 100 kHz con DSB-SC. Ocupan 5–35, 45–75 y 85–115 kHz, con guardas de 10 kHz.

## 5. Índice de modulación y Carson

- Con un multiplex, β = Δf/f_m no está bien definido como en un tono único. Lo correcto es hablar de razón de desviación D = Δf_pico / f_max.
- Carson es una aproximación (~98 % de la potencia). Verifíquela con el espectro simulado, no solo con la fórmula.
- La desviación depende de la amplitud pico del multiplex. Por eso la "normalización" de los audios importa: la suma de tres señales puede triplicar el pico.
- Si usa preénfasis, sube la desviación en altas frecuencias y cambia el ancho real.

## 6. El receptor superheterodino no puede mostrar su razón de ser

- Con TX y RX conectados directamente y una sola portadora, no hay estación vecina ni imagen que rechazar. La selectividad del superheterodino (rechazo de canal adyacente e imagen) no se demuestra.
- El enunciado pide filtro de FI, pero no un preselector de RF, que es lo que rechaza la imagen en un receptor real.
- No se define si el LO es de inyección alta o baja. Eso determina dónde cae la imagen y qué rango de portadoras es válido (que f_c − f_FI no se acerque a 0).
- El filtro de FI debe tener un ancho cercano al BW de Carson (cientos de kHz en el real), no los 15 kHz del audio. Es un error común.
- Hay dos "selecciones de canal": sintonizar la portadora (RF) y elegir uno de los tres audios (banda base). Son cosas distintas.
- "Visualizar la FI" es trivial, porque es constante. Lo que cambia es el LO.

## 7. Preénfasis y AWGN

- Con canal ideal, la baja calidad no viene del ruido, así que el preénfasis/deénfasis no la arregla. Vendría de filtros mal dimensionados, aliasing o el discriminador.
- El preénfasis sí tiene sentido con AWGN. El ruido tras el demodulador FM crece con f², así que el canal de subportadora más alta (el de 100 kHz) sufre más. Es un buen punto para el análisis. También aparece el efecto umbral.
- El AWGN en Simulink debe definirse respecto al ancho de banda correcto (el de FI), no al de la tasa de muestreo. Si no, el SNR queda mal normalizado.
- El AWGN va "al final" y no aparece en la rúbrica, salvo posiblemente en "Análisis y evaluación" (10 pts).

## 8. Otros detalles

- **Cifras reales raras:** 10 MHz no es banda FM comercial (88–108 MHz) y 1.7 MHz no es una FI estándar (10.7 MHz en FM, 455 kHz en AM). No es un error, pero no se puede apoyar en referencias comerciales.
- **Entregable:** solo se menciona el video. No dice si hay que subir los archivos .slx/.m, así que conviene preguntar.
- **Sección 9** (evidencias del proceso) no tiene criterio propio en la rúbrica, salvo en "Análisis del problema".
- **Toolboxes:** probablemente se necesite Communications Toolbox y DSP System Toolbox.
- **Fecha:** el martes 10 de noviembre es consistente con 2026.

---

## Escalamiento coherente (÷100 uniforme)

| Parámetro | Real | Escalado |
|---|---|---|
| Audio | 15 kHz | 150 Hz |
| Multiplex | 120 kHz | 1.2 kHz |
| Subportadoras (ejemplo) | 20/60/100 kHz | 200/600/1000 Hz |
| Δf (ejemplo) | 75 kHz | 750 Hz |
| BW Carson (D ≈ 0.65) | ≈ 380 kHz | ≈ 3.8 kHz |
| Portadora | 10 MHz | 100 kHz |
| FI | 1.7 MHz | 17 kHz |
| LO (inyección alta) | 11.7 MHz | 117 kHz |
| Imagen | 13.4 MHz | 134 kHz |
| fs sugerida | — | ≈ 1 MHz |

Con esto, la FM ocupa 98–102 kHz y la FI de 17 kHz tiene espacio de sobra. El audio se "ralentiza" 100 veces. Para escucharlo, reinterprete las muestras con una tasa 100 veces mayor. Para simulaciones cortas, use clips breves o tonos sintéticos. El escalamiento debe documentarse y quedar oculto en la GUI, que mostraría frecuencias nominales.

---

## Preguntas para el profesor

1. ¿Los 120 kHz son el multiplex en banda base o el ancho total transmitido?
2. ¿La tabla de escalamiento es obligatoria o puedo reescalar uniformemente toda la tabla?
3. ¿Qué modulación debo usar en las subportadoras del FDM?
4. ¿Debo entregar los archivos del modelo además del video?
5. ¿Se espera un preselector de RF o prueba de rechazo de imagen?
