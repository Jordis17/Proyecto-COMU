# Guion del video (~10 min)

Basado en `diseno_final.md`. Unas 1500 palabras habladas: a ritmo tranquilo (unas 140 por minuto) son poco menos de 11 min, así que conviene ir un poco más rápido o recortar lo indicado al final.

- **Pantalla:** lo que se ve mientras se habla.
- **Texto:** lo que se dice. Es una base: díganlo con sus palabras, no hace falta leerlo.
- **[PENDIENTE]:** datos que hay que completar con lo que salga de MATLAB (ver `PENDIENTES_MATLAB.md`).

Las partes están repartidas entre los dos, pero cada uno debería poder explicar todas.

---

## Escena 1 — El problema (0:00–1:00) · Jordi

**Pantalla:** diagrama de bloques completo (3 audios → FDM → FM → canal → superheterodino → demux → GUI).

**Texto:**
> Hola, somos Jordi y Abner, y este es nuestro proyecto de Comunicaciones Eléctricas I.
>
> La idea es mandar tres audios por un mismo canal y poder escuchar cualquiera de ellos en el receptor. Primero juntamos los tres audios con multiplexación por división de frecuencia: cada uno va a su propia banda dentro de un máximo de 120 kHz. Ese multiplex se modula en FM sobre una portadora de 10 MHz. En el receptor usamos un superheterodino: bajamos la señal a una frecuencia intermedia de 1.7 MHz, demodulamos la FM y separamos los tres audios.
>
> Todo está hecho en MATLAB y Simulink, con una interfaz tipo radio. Probamos el sistema con canal ideal y con ruido blanco.
>
> El profesor nos dijo que el enunciado tenía errores a propósito, así que empezamos por ahí.

---

## Escena 2 — Errores del enunciado (1:00–3:00)

### 2a. Escalamiento · Abner (1:00–2:00)

**Pantalla:** la tabla del §5 del enunciado; al lado, el espectro FM de 100 ± 265 kHz cruzando 0 Hz.

**Texto:**
> No se pueden simular directamente 10 MHz con audio de 15 kHz, porque haría falta muchísimas muestras. Por eso el enunciado pide escalar las frecuencias manteniendo las proporciones.
>
> Pero su tabla no las mantiene: baja la portadora de 10 MHz a 100 kHz y la FI de 1.7 MHz a 17 kHz, y deja el audio y el multiplex igual. Entonces el multiplex, que ocupaba el 1.2 % de la portadora, pasa a ocupar el 120 %. Con nuestra FM, que ocupa unos 530 kHz por Carson, la señal quedaría entre −165 y 365 kHz: cruza el cero y se mezcla con su propio espejo. Y la FI de 17 kHz quedaría por debajo del mensaje, de 115 kHz, y eso ya no es un superheterodino.
>
> Lo corregimos dividiendo todo por el mismo factor, K = 100: audio, subportadoras, desviación, filtros, portadora, oscilador local y FI. Así las proporciones son las del sistema real. La interfaz siempre muestra los valores nominales, así que el usuario no nota el escalamiento.

### 2b. Muestreo y prénfasis · Jordi (2:00–3:00)

**Pantalla:** espectro de la salida del mezclador con la FI y el producto suma marcados; la frase del §4.5 del enunciado.

**Texto:**
> El segundo error es la recomendación de muestrear a 5 o 10 veces el ancho de banda. En una señal pasabanda eso no basta: lo que manda es la frecuencia más alta que aparece. En el mezclador aparece la suma de la portadora y el oscilador local, que con 11 MHz llega a unos 20.6 MHz. Por Nyquist necesitamos más de 41 MHz, así que muestreamos la parte de RF a 48 MHz. Para no gastar cálculo, cada etapa trabaja a su propia frecuencia: 48 kHz el audio, 480 kHz el multiplex, 4.8 MHz la FI y 48 MHz la RF.
>
> Sobre el prénfasis: el enunciado dice que lo consideremos si la calidad es baja. No lo vemos como un error sino como una condición. Con canal ideal la calidad es muy buena, así que no hace falta. Con ruido sí hace falta, y lo mostramos al final.

---

## Escena 3 — Diseño (3:00–5:15)

### 3a. Plan FDM · Abner (3:00–3:45)

**Pantalla:** figura 2 de `graficas_sistema` (multiplex con las tres bandas coloreadas).

**Texto:**
> Cada audio modula en DSB-SC a una subportadora: 20, 60 y 100 kHz. Así ocupan las bandas de 5 a 35, de 45 a 75 y de 85 a 115 kHz, con guardas de 10 kHz entre ellas. Usamos el 75 % de los 120 kHz.
>
> Escogimos DSB-SC y no SSB porque un audio real tiene contenido casi desde 0 Hz. Para quitar una banda lateral necesitaríamos filtros casi ideales. Además, es el mismo esquema de la FM estéreo, donde la señal L menos R va en DSB-SC.

### 3b. FM y Carson · Jordi (3:45–4:30)

**Pantalla:** figura 3 de `graficas_sistema` (espectro FM con las líneas de Carson y del 99 %).

**Texto:**
> Para la FM elegimos una desviación de 150 kHz. Como el mensaje tiene muchas frecuencias, en vez del índice de modulación usamos la relación de desviación: 150 entre 115, que da 1.3.
>
> Por Carson, el ancho es 2 por 150 más 115, o sea 530 kHz. Un error común es usar los 15 kHz del audio, pero lo que entra al modulador es el multiplex completo, que llega a 115 kHz. En la simulación, el 99 % de la potencia quedó en unos 150 kHz, dentro de Carson.
>
> ¿Por qué 150 kHz? Porque en FM la relación señal a ruido crece con el cuadrado de la desviación, pero también crece el ancho de banda. Con 150 kHz la señal cabe con margen en la FI.

### 3c. Superheterodino · Abner (4:30–5:15)

**Pantalla:** figura 4 de `graficas_sistema` (salida del mezclador y FI filtrada).

**Texto:**
> El oscilador local se calcula solo: es la portadora menos 1.7 MHz. Con 10 MHz queda en 8.3 MHz. El mezclador da la diferencia, que es la FI de 1.7 MHz, y la suma, de 18.3 MHz, que se elimina con un filtro.
>
> Antes del mezclador está la sección de RF, que hace de preselector, igual que en el esquema del curso. Su función es quitar la frecuencia imagen, que está a 6.6 MHz: si llegara al mezclador, también caería en 1.7 MHz. Después, la sección de FI deja pasar de 1.35 a 2.05 MHz, más que el ancho de Carson.
>
> Usamos inyección inferior porque con la superior el producto suma pasaría de 24 MHz y no cabría con 48 MHz de muestreo.

---

## Escena 4 — Modelo y GUI (5:15–7:30)

### 4a. Modelo Simulink · Jordi (5:15–6:15)

**Pantalla:** `sistema_fdm_fm.slx`.
1. Nivel principal: señalar los nombres de las señales x1(t)…x3(t), m(t) multiplex, s(t) señal FM, x(t) = s(t) + w(t) y m(t) recuperado.
2. Abrir «Receptor superheterodino» y, dentro, «Demodulador FM».
3. Abrir «Demultiplexor FDM».

**Texto:**
> El modelo tiene cinco subsistemas, uno por cada parte: transmisor FDM, modulador FM, canal, receptor superheterodino y demultiplexor FDM. Las señales llevan los nombres del curso: m(t) es el multiplex que entra al modulador, s(t) es la señal FM y x(t), que es s(t) más el ruido w(t), es lo que llega al receptor. Solo usa bloques básicos de Simulink, con solver discreto de paso fijo, y todos los valores salen de un archivo de parámetros.
>
> Dentro del receptor están los bloques del esquema del curso: sección de RF, oscilador local, mezclador, sección de FI, demodulador FM y filtro posdetección. Algunos, como la sección de FI, tienen adentro piezas extra que solo existen porque la simulación es digital y cada etapa usa su propia frecuencia de muestreo. El demodulador FM es el discriminador del curso. Primero, un limitador deja la FI con amplitud constante. Después, un detector de pendiente, que es un derivador, convierte la FM en AM: al derivar, la amplitud queda proporcional a la frecuencia instantánea. Por último, un detector de envolvente saca esa amplitud, y restándole la FI queda el mensaje.
>
> En el demultiplexor, cada canal tiene un pasabanda, su oscilador local, un detector coherente y un pasabajos de 15 kHz. Aquí hay un detalle: los filtros retrasan la señal, y en DSB-SC un desfase en la subportadora multiplica la salida por el coseno de ese desfase. Sin corregirlo, el canal 1 quedaba con una ganancia de 0.09, casi nada. Por eso calculamos el retardo de los filtros y desfasamos la subportadora del receptor en esa misma cantidad.

### 4b. Demostración de la GUI · Abner (6:15–7:30)

**Pantalla:** la radio en vivo, o grabada antes para no esperar la simulación.

**Texto y acciones:**
> Esta es la radio. Con la perilla elegimos la portadora entre 9 y 11 MHz. Vean que al moverla el oscilador local cambia solo, y la FI siempre queda en 1.7 MHz.

*(Poner 10 MHz → simular → mostrar LO 8.3 MHz y las gráficas.)*

> Arriba se ve el espectro recibido y la salida del mezclador, con la FI y el producto suma. Abajo, el multiplex recuperado y el audio elegido comparado con el original.

*(Cambiar a 11 MHz → LO 9.3 MHz.)*

> Con el selector elegimos el audio 1, 2 o 3. Esto no vuelve a simular: solo cambia qué salida del demultiplexor escuchamos.

*(Reproducir los tres audios recuperados. Si son audios reales, usar los `recuperado1..3.wav` de `probar_audio_real`.)*

> Con canal ideal, el SDR de los audios recuperados es de 43 a 54 dB, según el canal. Con los audios que grabamos sale parecido: unos 44, 56 y 54 dB.
>
> Si desintonizamos el receptor 600 kHz, la señal cae fuera de la FI y el audio se pierde: el SDR baja a casi 0 dB. Eso muestra que el receptor de verdad selecciona la portadora.

---

## Escena 5 — Canal con ruido y prénfasis (7:30–9:15) · Jordi

**Pantalla:** `fig_awgn.png` de `analisis_awgn`.

**Texto:**
> Ahora agregamos ruido blanco. Usamos la definición del curso de relación señal a ruido del canal, y la variamos de 40 a 14 dB.
>
> Primero, mientras el ruido no es muy fuerte, los resultados quedan cerca de la fórmula teórica. Segundo, el canal 3 siempre sale unos 14 dB peor que el canal 1. La razón es que, a la salida del discriminador FM, el ruido crece con el cuadrado de la frecuencia, y el canal 3 está en la subportadora más alta. Tercero, cuando la relación portadora a ruido en el ancho de Carson baja de unos 14 dB, la calidad se cae rápido: es el efecto umbral de la FM. También probamos un PLL como demodulador: con ruido moderado da lo mismo, aguanta unos dB más antes del umbral, pero con canal ideal distorsiona más, por eso nos quedamos con el discriminador.
>
> Aquí entra el prénfasis. Como dice el curso, va antes del modulador FM y el deénfasis va después del demodulador. En el modelo son el «Filtro de preénfasis», al final del transmisor, y el «Filtro de deénfasis», después del filtro posdetección. Filtramos el multiplex completo con un filtro de primer orden que sube las frecuencias altas, y en el receptor aplicamos el filtro inverso. Sin ruido, los dos filtros se cancelan y no cambia nada. En la radio se activan con una casilla.
>
> Con ruido, el canal 3 mejora unos 2 dB y el canal 1 pierde unos 5 dB, como predice la teoría. Es decir, el prénfasis no quita ruido en total: lo reparte. Y eso nos sirve, porque el canal 3 era el que limitaba la calidad, y el canal 1 tenía calidad de sobra. La diferencia entre canales baja de 14 a unos 6 dB.

---

## Escena 6 — Conclusiones (9:15–10:00) · Abner

**Pantalla:** tabla de requisitos con marcas de cumplido.

**Texto:**
> En resumen: los tres audios se transmiten en FDM dentro de 120 kHz, se modulan en FM con portadora configurable, y el superheterodino los recupera con buena calidad. La interfaz permite elegir la portadora y el audio, y muestra la FI.
>
> Corregimos el escalamiento del enunciado para mantener las proporciones, y calculamos el muestreo a partir de la frecuencia más alta y no del ancho de banda. Con ruido vimos el efecto de la subportadora en cada canal y el umbral de la FM, y el prénfasis ayudó al canal más afectado.
>
> Como limitaciones: la simulación no es en tiempo real, la fase de la subportadora se corrige con un retardo conocido en vez de un tono piloto o un PLL, y el canal solo tiene ruido blanco.
>
> Gracias.

---

## Antes de grabar

- [x] Completar los [PENDIENTE] con los resultados de `analisis_awgn` y `probar_audio_real`.
- [ ] Tener a mano las figuras: `graficas_sistema` las guarda en `03_codigo_matlab/figuras/` y `analisis_awgn` guarda `fig_awgn.png`.
- [ ] Grabar la demostración de la GUI por separado (cada simulación tarda), o tener ya simulado lo que se va a mostrar.
- [ ] Ensayar con cronómetro: si se pasa de 10 min, recortar primero 3c (inyección inferior) y 4a (detalle del retardo).
- [ ] Cada uno ensaya también las escenas del otro.
