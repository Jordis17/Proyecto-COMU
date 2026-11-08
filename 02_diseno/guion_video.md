# Guion del video (~10 min)

**Texto** es una base para hablar, no para leer. Cada parte sigue la misma idea: qué problema había, qué probamos y qué decidimos. Díganlo con sus palabras.

**Pantalla** es lo que se muestra mientras se habla. Todo sale del propio proyecto, sin presentación: la consola de `main`, la radio y el modelo `sistema_fdm_fm.slx`.

En voz alta se dice el razonamiento y la cifra que decide. Los demás números se ven en la consola o en la radio, y su origen está en `decisiones_cuantitativas.md` por si el profesor pregunta.

Son unas 1070 palabras habladas, unos 7.6 minutos. Con los cambios de ventana y la demostración de la radio queda en unos 9–10 minutos.

---

## 1. Sistema (0:00–0:40) · Jordi

**Pantalla:** nivel principal de `sistema_fdm_fm.slx`.

> Hola, somos Jordi y Abner. Nuestro proyecto manda tres audios por un mismo canal.
>
> Primero los juntamos con multiplexación por división de frecuencia, dentro de 120 kHz. Después ese multiplex se modula en FM a 10 MHz. En el receptor, un superheterodino con FI de 1.7 MHz recupera los tres audios.
>
> Antes de poder simular tuvimos que resolver un problema con las frecuencias. Eso lo explica Abner.

---

## 2. Escalamiento y muestreo (0:40–2:00)

### Escalamiento · Abner

**Pantalla:** consola de `main`, tabla «DISEÑO DEL SISTEMA (escala K = 100)»: columna del valor real y columna del simulado.

> Sí. Para poder simular hay que bajar las frecuencias, y el enunciado da una tabla para eso. El problema es que esa tabla baja la portadora a 100 kHz, pero deja el multiplex en 120 kHz. Así, la señal FM queda más ancha que su propia portadora y llega a cruzar el cero.
>
> Por eso dividimos todas las frecuencias entre 100, sin excepción. Así se mantienen las proporciones del sistema real. En la consola se ve: el audio de 15 kHz pasa a 150 Hz y la portadora de 10 MHz pasa a 100 kHz. En la radio siempre vemos los valores reales.

### Muestreo · Jordi

**Pantalla:** la radio a 11 MHz, plan de frecuencias y salida del mezclador (producto suma); luego la consola de `main` (filas «Producto suma» y «Muestreo de la RF»).

> Después había que escoger el muestreo. El enunciado recomienda de 5 a 10 veces el ancho de banda. Pero aquí lo que manda es la frecuencia más alta que aparece, y esa sale del mezclador: la suma de la portadora y el oscilador llega a unos 20 MHz. Por Nyquist necesitamos más del doble, así que usamos 48 MHz.
>
> Solo esa parte va tan rápido. Cada etapa usa el muestreo que necesita, y en la consola se ven todos.

---

## 3. Transmisor (2:00–3:15) · Abner

**Pantalla:** la radio, pestaña «Demultiplexación y audio» (multiplex con las tres bandas); luego el panel de sintonía, que dice «Δf / B_T: 150 / 530 kHz», y la gráfica de FI con las líneas de Carson.

> Para el multiplex usamos DSB-SC, con subportadoras en 20, 60 y 100 kHz. Pensamos en SSB, que ocupa menos, pero el audio real empieza casi en 0 Hz, y separar una sola banda lateral necesitaría un filtro casi ideal. Con DSB-SC los tres canales caben con espacio entre ellos.
>
> Para la FM escogimos una desviación de 150 kHz. Más desviación da mejor calidad, pero también ocupa más ancho de banda. Con 150 kHz ganamos unos 6 dB frente a 75 kHz, y por Carson la señal ocupa 530 kHz, que cabe en el filtro de FI. En Carson usamos 115 kHz, que es lo máximo del multiplex, y no los 15 kHz del audio, porque lo que se modula es el multiplex completo.

---

## 4. Receptor (3:15–4:30) · Jordi

**Pantalla:** pestaña «Receptor superheterodino» de la radio; para el retardo, la consola de `main` (ganancias si no se compensara: −0.90 / +0.52 / −0.79).

> Con el transmisor listo, pasamos al receptor. El superheterodino tiene una ventaja: cualquier portadora que sintonicemos se baja a la misma FI de 1.7 MHz. Así, el filtro de FI y el demodulador no cambian; lo único que cambia es el oscilador local.
>
> El oscilador es la portadora menos 1.7 MHz. Lo pusimos abajo de la portadora porque, si iba arriba, la suma del mezclador no cabía en el muestreo.
>
> Antes del mezclador está la sección de RF, que quita la frecuencia imagen. Probamos quitarla y, con ruido, el audio empeoró unos 3 dB. Por eso se queda.
>
> Un detalle más: los filtros retrasan la señal, y eso desfasa las subportadoras. En la consola se ve qué pasaría sin corregirlo: el audio 2 baja a la mitad y los otros salen invertidos. Por eso el receptor atrasa sus subportadoras lo mismo que los filtros.

---

## 5. Demodulador (4:30–6:00) · Abner

**Pantalla:** «Demodulador FM» en el `.slx` (limitador, detector de pendiente, detector de envolvente).

> Para demodular la FM usamos el discriminador. Al investigar también vimos el detector de cuadratura, pero preferimos el discriminador porque es el que más conocemos del curso.
>
> Donde sí comparamos a fondo fue con el PLL, que también es del curso. Con ruido moderado, los dos dieron lo mismo. Sin ruido, el PLL salió peor: el audio 3 quedaba en 34 dB, y con el discriminador todos pasan de 43 dB. El PLL solo es mejor cerca del umbral, y ahí el audio ya sale mal con los dos. Además, el PLL es más complicado de ajustar. Por eso nos quedamos con el discriminador.
>
> Por dentro tiene un limitador, un derivador y un detector de envolvente. El limitador no lo pudimos hacer recortando la señal, porque en la simulación eso dañaba el audio. Lo hicimos dividiendo la señal entre su amplitud.

---

## 6. Radio (6:00–7:45) · Jordi

**Pantalla:** la radio, grabada con las simulaciones ya hechas.

> Ahora la radio. Con el dial elegimos la portadora. Vean que el oscilador local cambia y la FI se queda en 1.7 MHz.

*(Mover de 10 a 11 MHz: el LO pasa de 8.3 a 9.3 MHz.)*

> Con estos botones elegimos qué audio escuchar. Esto no vuelve a simular.

*(Reproducir los tres audios. En pantalla queda el SDR de cada uno.)*

> Sin ruido, los tres audios salen con más de 43 dB, también con nuestras grabaciones.
>
> Si corremos el receptor 600 kHz de la portadora, la señal se sale de la FI y el audio se pierde. O sea, el receptor solo recupera la emisora que tiene sintonizada.

---

## 7. Ruido y prénfasis (7:45–9:15) · Abner

**Pantalla:** la radio con la fuente «Ruido de 0.3 a 15 kHz» y la barra en 25 dB. Primero sin prénfasis y después con prénfasis (ya simulados con «Simular las 4 combinaciones»). La gráfica «SDR por audio» muestra los tres audios y la teoría.

> Después agregamos ruido blanco. Los resultados siguen la teoría hasta llegar al umbral de la FM. Debajo de ese punto, la calidad cae muy rápido.
>
> Algo que notamos es que el audio 3 sale unos 14 dB peor que el audio 1. La teoría lo explica: a la salida del discriminador, el ruido crece con la frecuencia, y el audio 3 está en la subportadora más alta.
>
> Para eso usamos prénfasis. No quita ruido, lo reparte: mejora el audio 3 y empeora el audio 1, que tenía calidad de sobra. Escogimos 30 kHz como frecuencia de corte, porque bajarla más casi no ayudaba al audio 3. Con eso, la diferencia entre el mejor y el peor audio bajó de 14 a unos 6 dB.

---

## 8. Conclusiones (9:15–10:15) · Jordi y Abner

**Pantalla:** la radio, pestaña «Demultiplexación y audio», con el SDR de los tres audios.

**Jordi:**
> Para cerrar, estas son nuestras conclusiones.
>
> Primero, el sistema cumple lo pedido. Los tres audios caben en 120 kHz, la portadora se elige entre 9 y 11 MHz, y el receptor siempre baja la señal a la misma FI de 1.7 MHz.
>
> Segundo, sin ruido los tres audios se recuperan con más de 43 dB, así que el FDM los separa bien. Y si desintonizamos el receptor, el audio se pierde: el receptor sí selecciona la emisora.
>
> Tercero, escalar todo entre 100 fue lo que hizo posible la simulación. Con la tabla del enunciado, la FM cruzaba el cero.

**Abner:**
> Cuarto, con ruido el sistema se comporta como dice la teoría: el audio 3 sale unos 14 dB peor que el 1, y por debajo del umbral la calidad cae de golpe.
>
> Quinto, el prénfasis no quita ruido, pero lo reparte mejor: la diferencia entre audios bajó de 14 a 6 dB.
>
> Y sexto, el discriminador rinde igual que el PLL donde trabaja el sistema; el PLL solo gana cerca del umbral.
>
> Como limitaciones: la simulación no es en tiempo real, la fase de las subportadoras se corrige con un retardo conocido en vez de un tono piloto, y el canal solo tiene ruido blanco. Gracias.

---

## Antes de grabar

- [ ] Correr `main` y dejar la consola visible: ahí está la tabla de diseño.
- [ ] En la radio, simular antes lo que se va a mostrar, para no esperar en la grabación:
  - **Grabaciones (WAV)**, canal ideal, 10 MHz: para escuchar (sección 6);
  - **Ruido de 0.3 a 15 kHz**, 25 dB, con «Simular las 4 combinaciones»: para ruido y prénfasis (sección 7);
  - **Arpegio, sirena y pitidos**, canal ideal, 11 MHz: para los espectros del receptor (secciones 2 y 4); con las grabaciones, el espectro de RF muestra el silencio del final.
- [ ] Tener abierto `sistema_fdm_fm.slx` (secciones 1 y 5).
- [ ] Al grabar, pasar entre la consola, la radio y Simulink con Alt + Tab.
- [ ] Los números de la sección 7 se leen en la radio. Pueden diferir unas décimas de los del guion, porque dependen de la duración elegida. Digan los que aparezcan en pantalla.
- [ ] Ensayar con cronómetro. El máximo es 12 min.
- [ ] Cada uno debe poder explicar todas las partes.

## Qué se probó y qué se calculó (por si el profesor pregunta)

| Lo que dice el guion | Cómo se obtuvo |
|---|---|
| La tabla del enunciado haría cruzar el cero a la FM | Cálculo |
| La suma del mezclador llega a unos 20 MHz; con inyección superior no cabría en 48 MHz | Cálculo |
| SSB necesitaría un filtro casi ideal | Análisis; no se simuló SSB |
| 150 kHz da unos 6 dB más que 75 kHz | Cálculo (SNR ∝ Δf²) y prueba en Python |
| Sin la sección de RF el audio empeora unos 3 dB | Simulink, con la versión anterior del demodulador. El efecto viene del ruido de la banda imagen, no del demodulador |
| Sin compensar el retardo, el audio 2 baja a la mitad y los audios 1 y 3 salen invertidos | Cálculo que imprime `main`: cos(2π f_k τ_k) = −0.90 / +0.52 / −0.79, con τ = 421.48 / 236.06 / 236.06 µs. El audio 2 pierde 5.7 dB. Con el detector de cuadratura los retardos eran otros y el audio 1 quedaba en 0.09 |
| El superheterodino y la FI de 1.7 MHz | Los pide el enunciado (§4.5). Las condiciones de la FI las revisa `main`: «La banda de FI no toca 0 Hz», «El paso de FI cubre el ancho de Carson» |
| Comparación del PLL con el discriminador | Simulink, mismo modelo y mismo ruido. Sin ruido: PLL 47.6 / 38.7 / 34.0 dB, discriminador 43.3 / 52.2 / 54.4 dB. A 30 dB: iguales. A 16 dB: PLL 16.7 / 7.3 / 4.7, discriminador 3.9 / 2.9 / 2.4 |
| El limitador que recorta empeora mucho el audio | Python: 9–14 dB con canal ideal |
| La elección de f₀ = 30 kHz | Cálculo con la fórmula de `params_sistema.m`. Solo 30 kHz se midió en Simulink (−5.4 / −1.1 / +2.0 dB) |
| Con 600 kHz de desintonía el audio se pierde | Simulink: SDR de 0.9 dB |
| El audio 3 sale unos 14 dB peor que el audio 1 | Simulink (`analisis_awgn`, fuente de ruido): 13.9 dB a 25 y 30 dB. Teoría con la potencia de cada audio (columnas `teo_c1` y `teo_c3` de `resultados_awgn.csv`): 14.2 dB. Si los tres audios tuvieran la misma potencia: 10·log[(100² + 15²/3)/(20² + 15²/3)] = 13.3 dB. A 40 dB la diferencia baja a 12 dB, porque el audio 1 se acerca a su límite sin ruido (43 dB); cerca del umbral (20 dB) baja a 10 dB |
| Con prénfasis la diferencia baja de 14 a unos 6 dB | Simulink, 25 dB: sin prénfasis 26.7 − 12.8 = 13.9 dB; con prénfasis 21.1 − 14.8 = 6.3 dB. Con las grabaciones: de 12.2 a 5.0 dB |
