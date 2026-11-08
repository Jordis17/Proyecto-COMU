# Guion del video (10–11 min, máximo 12)

El profesor pidió comparar casos y justificar cada decisión con números, no solo de forma cualitativa. Por eso cada parte del diseño sigue el mismo orden:
1. qué opciones había;
2. qué número dio cada una;
3. qué escogimos y por qué.

Todos los números salen de `decisiones_cuantitativas.md`, que dice de dónde viene cada uno.

- **Pantalla:** lo que se ve mientras se habla.
- **Texto:** lo que se dice. Es una base: díganlo con sus palabras.
- Son unas 1450 palabras habladas: a 140 por minuto dan unos 10.5 min.

Las partes están repartidas entre los dos, pero cada uno debería poder explicar todas.

---

## Escena 1 — El problema (0:00–0:45) · Jordi

**Pantalla:** diagrama de bloques del sistema (nivel principal del `.slx`).

**Texto:**
> Hola, somos Jordi y Abner. Nuestro proyecto manda tres audios por un mismo canal y permite escuchar cualquiera de ellos en el receptor.
>
> Los tres audios se juntan con multiplexación por división de frecuencia, en un máximo de 120 kHz. Ese multiplex se modula en FM sobre una portadora de 10 MHz. El receptor es un superheterodino con frecuencia intermedia de 1.7 MHz: demodula la FM y separa los audios.
>
> En cada parte había varias opciones. En el video vamos a mostrar cuáles comparamos, qué dio cada una y por qué escogimos la que quedó.

---

## Escena 2 — Errores del enunciado (0:45–2:15)

### 2a. Escalamiento · Abner (0:45–1:35)

**Pantalla:** la tabla del §5 del enunciado; al lado, la tabla «1. Escalamiento» de `decisiones_cuantitativas.md`.

**Texto:**
> El enunciado tiene errores a propósito. El primero es la tabla de escalamiento: baja la portadora a 100 kHz y la FI a 17 kHz, pero deja el multiplex en 120 kHz.
>
> Hicimos la cuenta. Nuestra FM ocupa 530 kHz por Carson, así que quedaría entre −165 y 365 kHz: cruza el cero. Y la FI de 17 kHz queda por debajo del mensaje, de 115 kHz.
>
> Comparamos tres opciones:
> - la tabla tal cual, que no funciona;
> - escalar solo la radiofrecuencia, que funciona pero cambia las proporciones: el ancho de banda pasa de ser el 31 % de la FI a ser el 156 %;
> - dividir todo entre 100.
>
> Escogimos la última, porque es la única que cumple lo que pide el mismo enunciado: mantener las proporciones. La interfaz muestra siempre los valores reales.

### 2b. Muestreo · Jordi (1:35–2:15)

**Pantalla:** espectro de la salida del mezclador (GUI, pestaña Receptor) con el producto suma marcado.

**Texto:**
> El segundo error es muestrear a 5 o 10 veces el ancho de banda. Con 530 kHz eso daría entre 2.6 y 5.3 MHz. Pero en el mezclador aparece la suma de la portadora y el oscilador local, que llega a 20.65 MHz. Por Nyquist hacen falta más de 41.3 MHz, así que usamos 48 MHz. Para no simular todo a esa tasa, cada etapa usa la suya: 48 kHz el audio, 480 kHz el multiplex, 4.8 MHz la FI y 48 MHz la RF.

---

## Escena 3 — Decisiones del transmisor y del receptor (2:15–5:00)

### 3a. Plan FDM y desviación · Abner (2:15–3:30)

**Pantalla:** figura 2 de `graficas_sistema` (multiplex) y la tabla «4. Desviación» de `decisiones_cuantitativas.md`.

**Texto:**
> Para el multiplex comparamos DSB-SC con SSB.
> - SSB ocuparía solo 45 kHz, pero un audio real tiene contenido casi desde 0 Hz. Para quitar una banda lateral haría falta un filtro casi ideal.
> - Con DSB-SC en 20, 60 y 100 kHz, con guardas de 10 kHz, usamos 90 de los 120 kHz, o sea el 75 %. Cabe sin problema.
>
> Para la desviación comparamos tres valores. Recordemos que la SNR de salida en FM crece con el cuadrado de la desviación:
> - con 75 kHz, Carson da 380 kHz;
> - con 150 kHz, da 530 kHz y la SNR mejora 6 dB;
> - con 200 kHz, ganaríamos 2.5 dB más, pero Carson llega a 630 kHz, al borde de nuestro filtro de FI de 700 kHz.
>
> Escogimos 150 kHz, que deja 170 kHz de margen. La relación de desviación es 150 entre 115, o sea 1.3. En la simulación, el 99 % de la potencia quedó en 148 kHz.

### 3b. Superheterodino · Jordi (3:30–5:00)

**Pantalla:** pestaña «Receptor superheterodino» de la GUI: plan de frecuencias y espectro de RF con la respuesta de la sección de RF.

**Texto:**
> El oscilador local se calcula solo a partir de la portadora. Comparamos dos formas de hacerlo:
> - con inyección superior, el oscilador queda arriba de la portadora y el producto suma llega a 24 MHz, que necesitaría más de 48 MHz de muestreo;
> - con inyección inferior, el oscilador es la portadora menos 1.7 MHz, y la suma llega a 20.65 MHz, que sí cabe.
>
> Por eso usamos la inferior: a 10 MHz el oscilador queda en 8.3 MHz.
>
> La imagen queda en 6.6 MHz. La sección de RF la rechaza al menos 60 dB. Probamos quitarla: con ruido de 25 dB, el SDR bajó 3 dB, porque entra el ruido de la banda imagen.
>
> El último detalle está en el demultiplexor. Los filtros retrasan la señal, y en DSB-SC un desfase en la subportadora multiplica la salida por el coseno de ese desfase. Sin corregirlo, las ganancias de los tres canales eran 0.09, −0.87 y −0.65: el canal 1 casi desaparecía. Corrigiendo la subportadora con el retardo de los filtros, las tres quedan en 1.

---

## Escena 4 — El demodulador: tres casos (5:00–6:30) · Abner

**Pantalla:** `figuras_video/comparacion_demoduladores.png`. Después, el bloque «Demodulador FM» en el `.slx`.

**Texto:**
> La decisión más grande fue el demodulador. Probamos tres en el mismo modelo y con el mismo ruido: un detector de cuadratura, un PLL y el discriminador del curso.
>
> Con canal ideal, el detector de cuadratura es el más limpio, con unos 60 dB. El discriminador da entre 43 y 54 dB, y el PLL entre 34 y 48. Con ruido de 30 dB los tres dan prácticamente lo mismo: la diferencia es menor a medio dB, porque ahí lo que limita es el ruido. Cerca del umbral, a 16 dB, el PLL aguanta más: 16.7 dB contra 3.9 del discriminador.
>
> Escogimos el discriminador porque es el que vimos en el curso. Cuesta unos 17 dB en el audio 1 con canal ideal, pero sigue arriba de 43 dB, que no se oye. Sobre el umbral no cuesta nada.
>
> Adentro tiene tres partes: un limitador, un detector de pendiente, que es un derivador, y un detector de envolvente. Al limitador también le probamos variantes:
> - sin limitador, falla con ruido;
> - recortando la onda, los armónicos se pliegan en la simulación y la calidad baja a 9–14 dB;
> - dividiendo entre la amplitud, funciona, pero cuando el ruido deja la amplitud casi en cero, la división se dispara.
>
> Por eso la amplitud nunca se toma menor a 0.3. Así, a 20 dB de ruido el audio 1 da 18 dB, cuando sin ese mínimo caía a cero.

---

## Escena 5 — Modelo y radio (6:30–8:30)

### 5a. Modelo · Jordi (6:30–7:15)

**Pantalla:** `sistema_fdm_fm.slx`: nivel principal y luego el receptor.

**Texto:**
> El modelo tiene cinco subsistemas: transmisor FDM, modulador FM, canal, receptor y demultiplexor. Usa solo bloques básicos de Simulink, con paso fijo, y todos los valores salen de un archivo de parámetros, así que al cambiar la portadora se recalcula todo. Las señales llevan los nombres del curso: m(t) es el multiplex, s(t) la señal FM y x(t), que es s(t) más el ruido, lo que llega al receptor.

### 5b. Radio · Abner (7:15–8:30)

**Pantalla:** la radio, grabada antes para no esperar la simulación.

**Texto y acciones:**
> Esta es la radio. Con el dial elegimos la portadora entre 9 y 11 MHz, y el plan de frecuencias se mueve en vivo: el oscilador local cambia y la FI se queda en 1.7 MHz.

*(Mover el dial de 10 a 11 MHz: el LO pasa de 8.3 a 9.3 MHz.)*

> Simulamos, y con los botones elegimos el audio 1, 2 o 3. Esto no vuelve a simular: solo cambia qué salida del demultiplexor escuchamos.

*(Reproducir los tres audios recuperados.)*

> Con canal ideal, el SDR es de 43 a 54 dB con señales de prueba, y de 49, 63 y 55 dB con los audios que grabamos.
>
> Si desintonizamos el receptor 600 kHz, la señal se sale de la FI y el SDR baja a 0.9 dB. El receptor sí selecciona la portadora.

---

## Escena 6 — Ruido y prénfasis (8:30–10:00) · Jordi

**Pantalla:** `fig_awgn.png` y luego `figuras_video/prenfasis_f0.png`.

**Texto:**
> Con ruido blanco variamos la relación señal a ruido del canal de 40 a 14 dB. Sobre el umbral, los resultados quedan a 1–3 dB de la fórmula del curso. El audio 3 sale unos 14 dB peor que el audio 1, porque a la salida del discriminador el ruido crece con el cuadrado de la frecuencia y el audio 3 está en la subportadora más alta. Debajo de unos 20 dB aparece el umbral de la FM y la calidad cae rápido.
>
> El enunciado dice que, si la calidad es baja, consideremos prénfasis. Con canal ideal no hace falta. Con ruido sí, por esa diferencia de 14 dB. El prénfasis no quita ruido: lo reparte entre los canales.
>
> Para elegir la frecuencia de corte comparamos valores:
> - con 10 kHz, el audio 3 gana 2.4 dB y el audio 1 pierde casi 9;
> - con 100 kHz casi no cambia nada;
> - con 30 kHz, el audio 3 gana 2 dB y el audio 1 pierde 5.8.
>
> Escogimos 30 kHz porque bajar más casi no ayuda al audio 3 y le quita mucho al audio 1.
>
> Medido en Simulink, el cambio fue de −5.4, −1.1 y +2.0 dB, casi igual a la teoría. A 25 dB de ruido, la diferencia entre el mejor y el peor audio bajó de 14 a 6 dB. Lo dejamos como una opción en la radio.

---

## Escena 7 — Conclusiones (10:00–10:45) · Abner

**Pantalla:** tabla «10. Resumen» de `decisiones_cuantitativas.md`.

**Texto:**
> En resumen, cada decisión se tomó comparando opciones con un número:
> - escalamos todo entre 100 para mantener las proporciones;
> - muestreamos a 48 MHz por el producto suma;
> - usamos DSB-SC, que ocupa el 75 % de la banda;
> - elegimos una desviación de 150 kHz por los 6 dB que gana y porque cabe en la FI;
> - usamos inyección inferior para que la suma quepa en el muestreo;
> - elegimos el discriminador porque es el del curso, y sobre el umbral rinde igual que los otros;
> - usamos un prénfasis de 30 kHz, que reparte mejor el ruido.
>
> Las limitaciones son tres: la simulación no es en tiempo real, la fase de la subportadora se corrige con un retardo conocido en lugar de un tono piloto, y el canal solo tiene ruido blanco.
>
> Gracias.

---

## Antes de grabar

- [ ] Tener a mano:
  - las figuras de `03_codigo_matlab/figuras/` (de `graficas_sistema`);
  - `fig_awgn.png` (de `analisis_awgn`);
  - las dos de `02_diseno/figuras_video/`, que se generan con `python3 04_verificacion_python/figuras_video.py`.
- [ ] Mostrar las tablas de `decisiones_cuantitativas.md` como diapositivas, o con zoom en pantalla.
- [ ] Grabar la radio por separado, con las simulaciones ya hechas (usar «Simular las 4 combinaciones» antes de grabar).
- [ ] Ensayar con cronómetro. Si pasa de 11 min, recortar primero 5a (el modelo) y las variantes del limitador de la escena 4.
- [ ] Cada uno ensaya también las escenas del otro.
