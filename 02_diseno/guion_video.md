# Guion del video (~10 min)

**Texto** es una base para hablar, no para leer. Lo importante es la secuencia de ideas de cada parte: problema → qué revisamos o probamos → qué decidimos → qué resultó. Cada uno lo dice con sus palabras.

**Pantalla** es lo que se muestra mientras se habla.

**Qué se muestra:** solo el propio proyecto, sin presentación.
- **`main`:** imprime en la consola la tabla de diseño, con cada frecuencia en su valor real y simulado, y abre la radio.
- **La radio.**
- **El modelo `sistema_fdm_fm.slx`.**

Se dice el razonamiento y la cifra que decide. Los demás números están en la consola o en la radio, y todos tienen su origen en `decisiones_cuantitativas.md` por si el profesor pregunta.

Son unas 1480 palabras habladas, unos 10.5 minutos. Con los cambios de ventana y la demostración se acerca a los 12 minutos del máximo, así que conviene recortar al ensayar. Lo primero que se puede quitar: el párrafo del limitador (sección 5) y el del retardo (sección 4), unos 140 palabras, cerca de 1 minuto.

---

## 1. Sistema (0:00–0:40) · Jordi

**Pantalla:** nivel principal de `sistema_fdm_fm.slx`.

> Hola, somos Jordi y Abner. Nuestro proyecto transmite tres audios por un mismo canal. Los tres se juntan con multiplexación por división de frecuencia dentro de 120 kHz, ese multiplex se modula en FM con una portadora de 10 MHz, y en el receptor usamos un superheterodino con una FI de 1.7 MHz para recuperar los tres audios y escuchar el que uno elija.
>
> Antes de poder simular esto tuvimos que resolver un problema con las frecuencias, y eso lo va a explicar Abner.

---

## 2. Escalamiento y muestreo (0:40–2:00)

### Escalamiento · Abner

**Pantalla:** consola de `main`, tabla «DISEÑO DEL SISTEMA (escala K = 100)»: columna del valor real y columna del simulado.

> Sí. El enunciado pide simular con las frecuencias escaladas y da una tabla de referencia. Cuando revisamos esa tabla vimos que bajaba la portadora y la FI, pero dejaba igual el ancho del multiplex. Hicimos el cálculo con nuestra señal FM y, con esos valores, el espectro quedaba tan ancho comparado con la portadora que llegaba a cruzar el cero. Además, la FI quedaba por debajo del propio mensaje.
>
> El mismo enunciado dice que hay que mantener las proporciones, así que decidimos dividir todas las frecuencias del sistema entre 100: el audio, las subportadoras, la desviación, la portadora y la FI. Así las relaciones entre frecuencias son las mismas del sistema real. En la consola se ve: el audio de 15 kHz queda en 150 Hz, la portadora de 10 MHz en 100 kHz y la FI en 17 kHz. Las muestras del audio no cambian; solo se leen 100 veces más despacio, y para escucharlo se reproducen otra vez a 48 kHz. En la radio siempre se muestran los valores reales.

### Muestreo · Jordi

**Pantalla:** la radio a 11 MHz, plan de frecuencias y salida del mezclador (producto suma); luego la consola de `main` (filas «Producto suma» y «Muestreo de la RF»).

> Con las frecuencias ya escaladas había que definir el muestreo. El enunciado recomienda trabajar entre 5 y 10 veces el ancho de banda. Cuando revisamos etapa por etapa, vimos que en una señal pasabanda lo que importa es la frecuencia más alta que aparece, y que después del mezclador esa regla no alcanza. El mezclador genera la suma de la portadora y el oscilador local, que llega a unos 20 MHz. Para no tener aliasing hay que muestrear a más del doble, así que en esa parte usamos 48 MHz.
>
> Como no tenía sentido simular todo a 48 MHz, cada etapa trabaja a la frecuencia de muestreo que necesita. En la consola se ven los valores de cada una.

---

## 3. Transmisor (2:00–3:15) · Abner

**Pantalla:** la radio, pestaña «Demultiplexación y audio» (multiplex con las tres bandas); luego el panel de sintonía, que dice «Δf / B_T: 150 / 530 kHz», y la gráfica de FI con las líneas de Carson.

> En el transmisor, lo primero era repartir los tres audios dentro de los 120 kHz. Analizamos dos opciones, DSB-SC y SSB. SSB usa menos ancho de banda, pero un audio real tiene contenido casi desde 0 Hz, y para quedarse con una sola banda lateral haría falta un filtro casi ideal. Como con DSB-SC los tres canales cabían, con bandas de guarda entre ellos y usando cerca de tres cuartas partes del ancho disponible, nos quedamos con DSB-SC.
>
> Después había que escoger la desviación de la FM. Aquí hay un compromiso: con más desviación mejora la relación señal a ruido, pero la señal ocupa más ancho de banda. Comparamos varios valores y nos quedamos con 150 kHz. Frente a 75 kHz eso da unos 6 dB más, y por Carson la señal ocupa 530 kHz, que todavía cabe con margen en el filtro de FI. Una cosa importante es que en Carson usamos la frecuencia máxima del multiplex y no la del audio, porque lo que entra al modulador es el multiplex completo.

---

## 4. Receptor (3:15–4:30) · Jordi

**Pantalla:** pestaña «Receptor superheterodino» de la radio; para el retardo, la consola de `main` (ganancias si no se compensara: −0.90 / +0.52 / −0.79).

> Con el transmisor listo, faltaba ver que el receptor pudiera recuperar la señal. El enunciado pide un superheterodino, y la ventaja se ve en la radio: sin importar qué portadora sintonicemos, la señal siempre se baja a la misma FI de 1.7 MHz. Así, el filtro de FI y el demodulador se diseñan una sola vez, y lo único que cambia con la sintonía es el oscilador local. Esa FI además sirve: está por debajo de la portadora, por encima del mensaje de 115 kHz, y su banda no llega a 0 Hz.
>
> El oscilador local se calcula solo a partir de la portadora: es la portadora menos 1.7 MHz. Lo pusimos por debajo de la portadora porque, si lo poníamos por encima, la suma del mezclador ya no cabía en los 48 MHz de muestreo.
>
> En el superheterodino también hay que cuidar la frecuencia imagen, porque al mezclarse cae en la misma FI. Para eso está la sección de RF antes del mezclador. Probamos qué pasaba si la quitábamos: con ruido, la calidad del audio bajó unos 3 dB, porque entraba también el ruido de la banda imagen. Por eso la dejamos.
>
> En el demultiplexor hay otro detalle. Los filtros retrasan la señal, y en DSB-SC, si la subportadora del receptor queda desfasada, la salida se atenúa. Cuando calculamos ese efecto, cada audio quedaba multiplicado por un número distinto: el audio 2 bajaba a la mitad y los otros dos salían invertidos. Por eso la subportadora del receptor se atrasa lo mismo que los filtros.

---

## 5. Demodulador (4:30–6:00) · Abner

**Pantalla:** «Demodulador FM» en el `.slx` (limitador, detector de pendiente, detector de envolvente).

> Para demodular la FM, al investigar encontramos también el detector de cuadratura. Decidimos seguir con el discriminador porque es el que más conocemos del curso, y eso nos facilitaba implementarlo y relacionarlo con la teoría.
>
> La comparación que sí hicimos a fondo fue contra el PLL, que también es del curso. Probamos los dos en el mismo modelo y con el mismo ruido. Con ruido moderado dieron prácticamente lo mismo, porque ahí lo que limita es el ruido. Sin ruido, el PLL salió peor en dos de los tres audios: el audio 3 quedaba en 34 dB, porque el lazo no alcanza a seguir los cambios rápidos de frecuencia del multiplex, mientras que el discriminador da al menos 43 dB. El PLL solo aguantó más cerca del umbral, y ahí el audio 3 ya sale mal con cualquiera de los dos. Además, el PLL necesita diseñar el lazo y compensar su fase. Por eso nos quedamos con el discriminador.
>
> El discriminador tiene un limitador, un derivador que convierte la FM en AM, y un detector de envolvente. Con el limitador tuvimos un problema. Al recortar la señal directamente, como en un limitador analógico, en la simulación aparecían componentes que se plegaban sobre la señal y empeoraban mucho el audio. Por eso lo implementamos normalizando la señal, o sea, dividiéndola entre su amplitud, con un valor mínimo para no dividir entre valores demasiado pequeños cuando hay ruido.

---

## 6. Radio (6:00–7:45) · Jordi

**Pantalla:** la radio, grabada con las simulaciones ya hechas.

> Si nos vamos a la radio, con el dial elegimos la portadora. Ahora podemos ver que el oscilador local se mueve con ella y que la FI se queda siempre en 1.7 MHz.

*(Mover de 10 a 11 MHz y mostrar que el LO pasa de 8.3 a 9.3 MHz.)*

> Con estos botones elegimos qué audio escuchar. Esto no vuelve a simular: solo cambia qué salida del demultiplexor se escucha.

*(Reproducir los tres audios. En pantalla queda el SDR de cada uno.)*

> Con canal ideal, los tres audios salen con más de 43 dB, y con nuestras grabaciones también.
>
> También probamos desintonizar el receptor, o sea, dejarlo sintonizado 600 kHz al lado de la portadora. En ese caso la señal queda fuera del filtro de FI y el audio prácticamente se pierde. Con esto comprobamos en la simulación que el receptor solo recupera el audio cuando está sintonizado a la portadora correcta.

---

## 7. Ruido y prénfasis (7:45–9:30) · Abner

**Pantalla:** la radio con la fuente «Ruido de 0.3 a 15 kHz» y la barra en 25 dB. Primero sin prénfasis y después con prénfasis (ya simulados con «Simular las 4 combinaciones»). La gráfica «SDR por audio» muestra los tres audios y la teoría.

> Después agregamos el canal AWGN para ver cómo se comportaba el sistema cuando ya no era un canal ideal. Los resultados siguieron la tendencia que da la teoría del curso, pero al acercarnos al umbral de la FM la calidad empezó a caer bastante rápido.
>
> También notamos que, con ruido moderado, el audio 3 salía unos 14 dB peor que el audio 1. La explicación está en la teoría: a la salida del discriminador el ruido crece con el cuadrado de la frecuencia, y el audio 3 está en la subportadora más alta. Con la fórmula del curso, usando la potencia que tenía cada audio, da también unos 14 dB.
>
> Para compensar esa diferencia usamos prénfasis y deénfasis. El prénfasis no elimina el ruido, lo reparte: el audio 3 mejora a costa del audio 1, que tenía calidad de sobra. Para escoger la frecuencia de corte calculamos qué pasaba con varios valores. Si se baja mucho, el audio 3 casi no mejora más, pero el audio 1 pierde bastante. Por eso dejamos 30 kHz. En la simulación, el audio 3 mejoró unos 2 dB, y la diferencia entre el mejor y el peor audio bajó de 14 a unos 6 dB.

---

## 8. Cierre (9:30–10:00) · Jordi

**Pantalla:** la radio o el nivel principal del modelo.

> En general, logramos integrar todo lo que pedía el proyecto: el FDM, la FM, el receptor superheterodino y la radio. Lo que más trabajo nos dio fue que todas las etapas fueran compatibles entre sí, y para eso tuvimos que ir probando y corrigiendo varias decisiones.
>
> También tiene limitaciones. La simulación no funciona en tiempo real, la fase de la subportadora se corrige usando un retardo que conocemos, cuando un receptor real usaría un tono piloto, y el canal solo tiene ruido blanco. Aun así, el modelo nos permitió comprobar el sistema completo y ver qué pasa al cambiar las condiciones del canal.

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
