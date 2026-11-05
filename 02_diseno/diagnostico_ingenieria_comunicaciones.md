# Diagnóstico técnico y decisiones de ingeniería — Proyecto de Comunicaciones Eléctricas

## Propósito de esta revisión

El profesor indicó que el enunciado contiene **errores intencionales** para que el equipo los identifique y corrija al diseñar un sistema que funcione. Por tanto, el objetivo **no es reproducir literalmente los números inconsistentes ni esperar que el profesor entregue sus correcciones**, sino detectar los problemas, justificar las decisiones con teoría y cálculos, implementarlas y demostrar su funcionamiento.

Este documento diferencia:
- **[ERROR DEMOSTRABLE]** Contradicción o recomendación inadecuada que puede demostrarse.
- **[ESPECIFICACIÓN ABIERTA]** Dato no fijado; requiere una decisión técnica del equipo, no implica que esté mal.
- **[MATIZ]** Indicación válida en su intención, pero que debe interpretarse correctamente.

La referencia primaria de los requisitos sigue siendo el archivo `Intrucciones .md` proporcionado por el profesor.

## 1. Errores técnicos que deben corregirse para que el modelo sea coherente

### 1.1 Escalamiento incoherente entre portadora, FI y anchos de banda — [ERROR DEMOSTRABLE; CRÍTICO]

El apartado 5 establece un escalamiento que debe conservar relaciones entre **ancho de banda**, **frecuencia de portadora** y **FI**. Sin embargo:

| Parámetro | Nominal | Referencia del enunciado | Factor aplicado |
|---|---:|---:|---:|
| Audio máximo | 15 kHz | 15 kHz | 1 |
| Ancho FDM máximo | 120 kHz | 120 kHz | 1 |
| Portadora FM | 10 MHz | 100 kHz | 100 |
| FI | 1.7 MHz | 17 kHz | 100 |

Eso **no conserva las proporciones**. Por ejemplo, nominalmente `B_FDM/f_RF = 120 kHz / 10 MHz = 0.012`, pero con la tabla simulada `120 kHz/100 kHz = 1.2`. La diferencia es un factor 100.

**Consecuencia:** se pretende transportar una señal compuesta muy ancha mediante una portadora simulada demasiado baja y después recuperarla en una FI extremadamente baja. Se pierden las condiciones de bandas pasantes separadas que requiere el modelo superheterodino convencional.

**Corrección coherente posible:** usar un factor de escala único de 100 **para todas las frecuencias involucradas** —audio, subportadoras, desviación de FM, bandas de filtro, RF, LO y FI— y ajustar la interpretación temporal. Alternativamente, utilizar un modelo equivalente de banda base compleja/multirritmo que reduzca el costo computacional sin falsificar las relaciones nominales; hay que explicar cuidadosamente cómo satisface la exigencia de escalamiento. **No se trata de imponer automáticamente una única alternativa**, sino de elegir y justificar la más viable.

**Comprobación exigible:** presentar una tabla única `nominal -> modelo`, las relaciones adimensionales relevantes y espectros de RF/FI sin solapamientos indeseados.

### 1.2 Regla de muestreo demasiado general — [ERROR DE APLICACIÓN POTENCIAL; CRÍTICO]

El apartado 8 aconseja muestrear a `5–10 veces el ancho de banda máximo simulado`. Ese criterio **no es suficiente por sí solo para muestras reales de una señal pasobanda**: debe examinarse la frecuencia absoluta máxima presente, no solamente el ancho ocupado. Un mezclador real genera productos de **suma y diferencia**, y el producto de suma puede producir aliasing antes de que actúe el filtro.

**Corrección:** por cada etapa de una implementación real discreta, determinar el máximo componente de frecuencia y elegir `f_s > 2 f_max` con margen y filtros adecuados. En modelos equivalentes complejos, interpolación/decimación o muestreo pasobanda controlado, aplicar y justificar sus reglas específicas, no la fórmula anterior de forma mecánica.

**Comprobación exigible:** cálculo de `f_s` para TX, mezclador, FI y recuperación; análisis espectral de aliasing y control de los productos no deseados.

### 1.3 Confusión posible entre 120 kHz de FDM y ancho FM — [RIESGO GRAVE DE DISEÑO]

Los **120 kHz limitan al multiplex FDM**, pero la señal **FM** ocupa un ancho distinto, que se estima con Carson como `B_FM ≈ 2(Δf + f_m,max)`. La `f_m,max` relevante es la máxima frecuencia significativa del **multiplex FDM**, no automáticamente los 15 kHz de cada audio.

**Ejemplo ilustrativo, no requisito:** elegir tres canales DSB-SC centrados nominalmente en 20, 60 y 100 kHz (audio hasta 15 kHz) produce bandas positivas aproximadas de 5–35, 45–75 y 85–115 kHz. Con desviación pico propuesta de 25 kHz, Carson da `B_FM ≈ 2(25+115) = 280 kHz`.

Si no se escalaran los anchos pero se pusiera la portadora en 100 kHz y FI en 17 kHz, **280 kHz de ancho FM es incompatible con una representación convencional pasobanda centrada en esos valores**. Si se escalan de manera uniforme por 100, los 280 kHz nominales pasan a **2.8 kHz**, coherentes con la portadora simulada de 100 kHz y FI simulada de 17 kHz.

**Corrección:** calcular `Δf`, `f_m,max` y `B_FM` antes de diseñar los filtros RF/FI; verificar que las bandas elegidas admiten esa señal.

**Comprobación exigible:** espectro del multiplex, estimación Carson y espectros antes/después del filtro FI.

## 2. Aspectos abiertos que el equipo debe decidir correctamente

| Aspecto del enunciado | Decisión técnica necesaria | Evidencia de que funciona |
|---|---|---|
| Tipo de FDM | Elegir DSB-SC, SSB u otra técnica justificable; definir subportadoras, guardas y filtros | Espectros de canales separados y audios recuperados |
| Índice FM para mensaje compuesto | Definir `k_f`, amplitud del multiplex, `Δf` y una medida de índice que se explique sin confundirla con una sola senoidal | Desviación y Carson consistentes; demodulación correcta |
| Escalamiento y audio real | Elegir la representación temporal y cómo se recupera/reproduce el audio; evitar que un «escalamiento» simplemente recorte información | Comparación correcta del audio original y recuperado |
| Oscilador local | Elegir inyección superior o inferior con `f_FI = |f_RF - f_LO|`, estudiar productos de mezcla | FI esperada y señal FM recuperable |
| Filtro FI | Dimensionarlo para `B_FM`, no automáticamente para 120 kHz de FDM | No se recortan bandas laterales relevantes |
| Selección en la GUI | Separar **sintonización de portadora RF** de **selección del audio 1, 2 o 3** después de FDM | Cambio de RF actualiza LO; cambio de audio selecciona la salida correcta |
| Prénfasis/deénfasis | Valorar únicamente si aportan una mejora comprobable; implementarlos como par TX/RX | Comparación controlada antes/después |
| Canal ideal y AWGN | Primero validar sin ruido; al final introducir AWGN | Comparaciones audios y métricas a distintos niveles de ruido propuestos |
| Duración, métricas y recursos | Elegir tiempos, pruebas y bloques compatibles con MATLAB/Simulink disponible | Ejecuciones reproducibles y resultados medibles |

**Nota:** estas decisiones no son nuevos requisitos establecidos por el profesor; son decisiones de ingeniería para realizar los objetivos que sí planteó.

## 3. Ejemplo de un plan FDM y su coherencia con el escalamiento

Una propuesta sencilla (no obligatoria) es FDM con DSB-SC:

| Señal | Centro nominal | Banda positiva nominal | Centro a escala 1:100 | Banda positiva escalada |
|---|---:|---:|---:|---:|
| Audio 1 | 20 kHz | 5–35 kHz | 200 Hz | 50–350 Hz |
| Audio 2 | 60 kHz | 45–75 kHz | 600 Hz | 450–750 Hz |
| Audio 3 | 100 kHz | 85–115 kHz | 1 kHz | 850–1150 Hz |

Los tres canales caben en **0–120 kHz nominales** (o 0–1.2 kHz escalados) con guardas de 10 kHz nominales (100 Hz escalados). Con `Δf = 25 kHz` nominal (250 Hz escalados) y `f_m,max = 115 kHz` nominal (1150 Hz escalados), Carson arroja 280 kHz nominales y 2.8 kHz escalados.

Para `f_RF = 10 MHz` y `f_FI = 1.7 MHz`, un LO nominal inferior vale `8.3 MHz`; escalando por 100 se obtiene `f_RF = 100 kHz`, `f_FI = 17 kHz` y `f_LO = 83 kHz`.

**Advertencia sobre audio real:** el escalamiento de audio de 15 kHz a 150 Hz no se logra simplemente filtrando el audio original a 150 Hz; eso eliminaría la mayor parte del contenido. Se necesita una representación temporal bien definida o un modelo equivalente de banda base que conserve la información. También se debe considerar el costo computacional y la duración de simulación.

## 4. Cómo decidir entre soluciones técnicamente válidas

Para cada corrección significativa, comparar alternativas mediante:

1. **Corrección matemática y física:** coherencia de frecuencia, espectro, muestreo, modulación y recuperación.
2. **Cumplimiento funcional:** tres audios independientes simultáneos, FDM, FM, receptor superheterodino, GUI y prueba AWGN.
3. **Calidad comprobable:** separación de canales, recuperación sin distorsión excesiva, reacción correcta a sintonización, estabilidad numérica.
4. **Viabilidad computacional:** cantidad de muestras, tiempos razonables, límites de la versión y toolboxes de MATLAB.
5. **Simplicidad académica:** que el equipo pueda explicar y defender el modelo y sus cálculos en un video de ~10 minutos.

Elegir una alternativa recomendada y dejar trazabilidad de los valores **originales**, la **corrección adoptada**, el **porqué** y la **prueba realizada**. No plantear todas las decisiones como preguntas para el profesor. Una consulta sí procede si un requisito sigue siendo incompatible con el objetivo después de evaluar opciones técnicamente válidas.

## 5. Pruebas mínimas propuestas (para verificar el diseño; no son rúbrica adicional)

- Tres señales de entrada identificables; cada canal individual y la suma FDM en espectro.
- Modulación FM sin aliasing y cálculo de Carson debidamente referenciado.
- RF -> mezcla -> FI con oscilador local consistente; filtro FI dimensionado para FM.
- Recuperación de FDM y de los tres audios por separado, con alineación de retardos y escala al comparar.
- Cambio de portadora con recálculo automático del LO, dentro del rango realmente simulado.
- Selección de audio que actúa después de la demodulación FM.
- Prueba ideal y prueba final con AWGN, bajo parámetros elegidos y declarados.
- Evidencias gráficas y explicación del **porqué de las correcciones intencionales**, no solo demostración visual.

## 6. Alcance oficial del entregable

El documento establece un **video explicativo de aproximadamente 10 minutos**, que muestre teoría, sistema, demostración, GUI y resultados; todos los integrantes deben dominar todos los aspectos. No se debe inventar como requisito oficial un informe escrito, repositorio, número de gráficas ni valores obligatorios de SNR.
