# Guion del video (~10 min)

**Texto** es lo que se dice; es una base, díganlo con sus palabras. **Pantalla** es lo que se muestra mientras se habla.

**Cómo usar los números:**
- **Se dice:** el razonamiento y la cifra que decide.
- **Se muestra:** los demás números, en la tabla o figura que esté en pantalla.

Todos los números salen de `decisiones_cuantitativas.md`. Si el profesor pregunta por uno que no se dijo, está ahí.

Son unas 900 palabras habladas, unos 6.5 minutos. Con la demostración de la radio y las pausas en las figuras queda en 9–10 minutos.

---

## 1. Sistema (0:00–0:40) · Jordi

**Pantalla:** nivel principal de `sistema_fdm_fm.slx`.

> Somos Jordi y Abner. El sistema transmite tres audios por un mismo canal. Primero se multiplexan en frecuencia, después el multiplex se modula en FM a 10 MHz, y un receptor superheterodino los recupera para escuchar el que uno elija.

---

## 2. Escalamiento y muestreo (0:40–2:00)

### Escalamiento · Abner

**Pantalla:** tabla del §5 del enunciado junto a la tabla 1 de `decisiones_cuantitativas.md`.

> Para poder simular hay que bajar las frecuencias. La tabla del enunciado baja la portadora y la FI, pero deja igual el ancho del multiplex. Con eso la señal FM queda tan ancha comparada con su portadora que cruzaría el cero, y la FI quedaría por debajo del propio mensaje.
>
> Por eso dividimos todas las frecuencias entre 100, sin excepción. Así las proporciones son las del sistema real, y la radio siempre muestra los valores reales.

### Muestreo · Jordi

**Pantalla:** salida del mezclador en la radio; al lado, la tabla de frecuencias de muestreo (tabla 2).

> La regla de muestrear a 5 o 10 veces el ancho de banda sirve en banda base, pero no aquí. Lo que manda es la frecuencia más alta que aparece en la simulación, y esa la produce el mezclador al sumar la portadora y el oscilador: unos 20 MHz. Por Nyquist necesitamos más del doble, así que usamos 48 MHz. Procesar el audio a esa velocidad no tendría sentido, así que cada etapa usa la tasa que necesita.

---

## 3. Transmisor (2:00–3:15) · Abner

**Pantalla:** espectro del multiplex (figura 2 de `graficas_sistema`); luego la tabla 4 de `decisiones_cuantitativas.md`.

> Cada audio va en DSB-SC a su propia subportadora, con bandas de guarda entre ellas, y entre los tres ocupan tres cuartas partes de los 120 kHz. SSB usaría menos espacio, pero el audio real tiene contenido casi desde 0 Hz, y separar una sola banda lateral necesitaría un filtro casi ideal. Como el espacio alcanzaba, DSB-SC era lo más simple.
>
> En FM, mientras más desviación, mejor relación señal a ruido, pero también más ancho de banda. Escogimos 150 kHz. Frente a 75 kHz, eso nos da 6 dB más, y la señal, que por Carson ocupa 530 kHz, todavía cabe con margen en el filtro de FI. Para Carson usamos la frecuencia máxima del multiplex y no la del audio, porque lo que se modula es el multiplex completo.

---

## 4. Receptor (3:15–4:30) · Jordi

**Pantalla:** pestaña «Receptor superheterodino» de la radio.

> El oscilador local se calcula solo, como la portadora menos 1.7 MHz. Lo pusimos abajo de la portadora y no arriba porque, si estuviera arriba, la suma del mezclador ya no cabría en nuestro muestreo.
>
> La frecuencia imagen también caería en la FI, así que antes del mezclador va la sección de RF, que la elimina. Probamos quitarla, y con ruido el audio empeoró 3 dB, porque entraba también el ruido de la banda imagen.
>
> Hay un detalle en el demultiplexor. Los filtros retrasan la señal, y en DSB-SC un desfase en la subportadora atenúa la salida. Sin corregirlo, el audio 1 casi desaparecía. Por eso la subportadora del receptor se atrasa lo mismo que los filtros.

---

## 5. Demodulador (4:30–6:00) · Abner

**Pantalla:** `figuras_video/comparacion_demoduladores.png`; luego «Demodulador FM» en el `.slx`.

> Probamos tres demoduladores con el mismo modelo y el mismo ruido: un detector de cuadratura, un PLL y el discriminador. Con ruido moderado los tres dan prácticamente lo mismo, porque ahí lo que limita es el ruido. Las diferencias aparecen en los extremos. Sin ruido, el detector de cuadratura es el más limpio. Cerca del umbral, el PLL aguanta más.
>
> Usamos el discriminador porque es el que vimos en el curso. Con canal ideal da al menos 43 dB, que ya no se escucha, y en el rango donde trabaja el sistema rinde igual que los otros.
>
> Tiene un limitador, un derivador que convierte la FM en AM, y un detector de envolvente. En la simulación, el limitador no puede recortar la onda, porque los armónicos se pliegan sobre la señal. Por eso divide la señal entre su amplitud, con un valor mínimo para que el ruido no la deje en cero.

---

## 6. Radio (6:00–7:45) · Jordi

**Pantalla:** la radio, grabada con las simulaciones ya hechas.

> Con el dial elegimos la portadora. El oscilador local se mueve con ella, y la FI se queda siempre en 1.7 MHz.

*(Mover de 10 a 11 MHz y mostrar que el LO pasa de 8.3 a 9.3 MHz.)*

> Elegir el audio no vuelve a simular. Solo cambia qué salida del demultiplexor escuchamos.

*(Reproducir los tres audios. En pantalla queda el SDR de cada uno.)*

> Los tres audios salen con más de 43 dB, también con nuestras grabaciones. Y si corremos el receptor fuera de la portadora, la señal se sale de la FI y el audio se pierde. Eso muestra que el receptor de verdad selecciona la emisora.

---

## 7. Ruido y prénfasis (7:45–9:30) · Abner

**Pantalla:** `fig_awgn.png`; luego `figuras_video/prenfasis_f0.png`.

> Con ruido, los resultados siguen la fórmula del curso hasta llegar al umbral, y debajo de él la calidad cae rápido. El audio 3 sale unos 14 dB peor que el audio 1. La razón es que, a la salida del discriminador, el ruido crece con la frecuencia, y el audio 3 está en la subportadora más alta.
>
> Por eso usamos prénfasis. No quita ruido, lo reparte: el audio 3 mejora a costa del audio 1, que tenía calidad de sobra. La frecuencia de corte es un compromiso. Si se baja, el audio 3 casi no gana más, pero el audio 1 pierde mucho. Con 30 kHz, el audio 3 gana 2 dB y la diferencia entre el mejor y el peor audio baja de 14 a 6 dB, que es lo que buscábamos.

---

## 8. Cierre (9:30–10:00) · Jordi

**Pantalla:** tabla 10 de `decisiones_cuantitativas.md`.

> El sistema cumple lo pedido: tres audios en 120 kHz, FM con portadora seleccionable, receptor superheterodino y una radio para elegir portadora y audio. Como limitaciones: no funciona en tiempo real, la fase de la subportadora se corrige con un retardo conocido y no con un tono piloto, y el canal solo tiene ruido blanco.

---

## Antes de grabar

- [ ] Figuras a mano:
  - `03_codigo_matlab/figuras/` (las de `graficas_sistema`);
  - `fig_awgn.png` (de `analisis_awgn`);
  - `02_diseno/figuras_video/`.
- [ ] Tablas de `decisiones_cuantitativas.md` listas para mostrar: los números que no se dicen tienen que verse.
- [ ] Simular antes en la radio («Simular las 4 combinaciones») para no esperar en la grabación.
- [ ] Ensayar con cronómetro. El máximo es 12 min.
- [ ] Cada uno debe poder explicar todas las partes y responder por los números de la tabla, aunque no los diga.
