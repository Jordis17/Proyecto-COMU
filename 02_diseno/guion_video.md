# Guion del video (10–11 min)

**Texto** es lo que se dice; es una base, díganlo con sus palabras. **Pantalla** es lo que se muestra mientras se habla. Los números salen de `decisiones_cuantitativas.md`.

---

## 1. Sistema (0:00–0:40) · Jordi

**Pantalla:** nivel principal de `sistema_fdm_fm.slx`.

> Somos Jordi y Abner. El sistema transmite tres audios de 15 kHz. Se multiplexan en frecuencia dentro de 120 kHz, el multiplex se modula en FM a 10 MHz, y un receptor superheterodino con FI de 1.7 MHz recupera los tres audios.

---

## 2. Escalamiento y muestreo (0:40–2:00)

### Escalamiento · Abner

**Pantalla:** tabla del §5 del enunciado y tabla 1 de `decisiones_cuantitativas.md`.

> No usamos la tabla de escalamiento del enunciado. Baja la portadora a 100 kHz, pero deja el multiplex en 120 kHz. Con nuestra FM, que ocupa 530 kHz, la señal iría de −165 a 365 kHz, o sea, cruza el cero. Además, la FI de 17 kHz quedaría por debajo del mensaje.
>
> Dividimos todas las frecuencias entre 100: audio, subportadoras, desviación, portadora y FI. Así el ancho de banda sigue siendo el 31 % de la FI, igual que en el sistema real. Si solo se escala la portadora, ese valor sube a más del 150 %.

### Muestreo · Jordi

**Pantalla:** salida del mezclador en la radio, con el producto suma.

> Muestrear a 5 o 10 veces el ancho de banda daría entre 2.6 y 5.3 MHz. No alcanza, porque el mezclador produce la suma de la portadora y el oscilador, que llega a 20.65 MHz. Hacen falta más de 41.3 MHz, y usamos 48 MHz. Las demás etapas van más lentas: el audio a 48 kHz, el multiplex a 480 kHz y la FI a 4.8 MHz.

---

## 3. Transmisor (2:00–3:15) · Abner

**Pantalla:** espectro del multiplex (figura 2 de `graficas_sistema`); luego la tabla 4 de `decisiones_cuantitativas.md`.

> Cada audio va en DSB-SC, a 20, 60 y 100 kHz, con guardas de 10 kHz. Ocupa 90 de los 120 kHz. SSB usaría la mitad, pero el audio real empieza casi en 0 Hz, y separar una banda lateral necesitaría un filtro casi ideal. Como el espacio alcanzaba, usamos DSB-SC.
>
> Escogimos una desviación de 150 kHz. Con eso, Carson da 2 por 150 más 115, o sea 530 kHz. Usamos 115 y no 15 porque lo que entra al modulador es el multiplex completo. Frente a 75 kHz, la SNR de salida mejora 6 dB, porque crece con el cuadrado de la desviación. Con 200 kHz, Carson llegaría a 630 kHz y quedaría al borde del filtro de FI, que mide 700. Medido en la simulación, el 99 % de la potencia está en 148 kHz.

---

## 4. Receptor (3:15–4:30) · Jordi

**Pantalla:** pestaña «Receptor superheterodino» de la radio.

> El oscilador local se calcula como la portadora menos 1.7 MHz: con 10 MHz queda en 8.3. Si lo pusiéramos arriba de la portadora, la suma llegaría a 24 MHz y no alcanzarían los 48 MHz de muestreo.
>
> La imagen queda en 6.6 MHz. La sección de RF la atenúa al menos 60 dB. Sin esa sección, con ruido de 25 dB el SDR bajó 3 dB, por el ruido que entra desde la banda imagen.
>
> En el demultiplexor, los filtros retrasan la señal. En DSB-SC, un desfase en la subportadora multiplica la salida por el coseno del desfase. Sin corregirlo, el canal 1 quedaba con ganancia 0.09. Por eso la subportadora del receptor se atrasa lo mismo que los filtros.

---

## 5. Demodulador (4:30–6:00) · Abner

**Pantalla:** `figuras_video/comparacion_demoduladores.png`; luego «Demodulador FM» en el `.slx`.

> Probamos tres demoduladores con el mismo ruido: un detector de cuadratura, un PLL y el discriminador.
>
> Con canal ideal, el de cuadratura da unos 60 dB y el discriminador entre 43 y 54. Con ruido de 30 dB, los tres quedan a menos de medio dB entre sí. A 16 dB, el PLL da 16.7 dB y el discriminador 3.9, porque el discriminador entra antes en umbral.
>
> Usamos el discriminador porque es el que se vio en el curso. Con canal ideal pierde unos 17 dB en el audio 1, pero 43 dB no se escuchan. Con ruido moderado da lo mismo que los otros.
>
> El discriminador tiene un limitador, un derivador que convierte la FM en AM, y un detector de envolvente. En la simulación, el limitador no puede recortar la onda, porque los armónicos se pliegan y la calidad baja a entre 9 y 14 dB. Por eso divide la señal entre su amplitud, con un mínimo de 0.3 para que el ruido no la deje en cero.

---

## 6. Radio (6:00–7:45) · Jordi

**Pantalla:** la radio, grabada con las simulaciones ya hechas.

> El dial elige la portadora entre 9 y 11 MHz. Al moverlo cambia el oscilador local, y la FI se queda en 1.7 MHz.

*(Mover de 10 a 11 MHz: el LO pasa de 8.3 a 9.3 MHz.)*

> Elegir el audio no vuelve a simular. Solo cambia la salida del demultiplexor que se escucha.

*(Reproducir los tres audios.)*

> Con canal ideal, el SDR es de 43 a 54 dB con tonos, y de 49, 63 y 55 dB con nuestras grabaciones.
>
> Si el receptor se corre 600 kHz de la portadora, la señal queda fuera de la FI y el SDR baja a 0.9 dB. Eso muestra que el receptor selecciona la portadora.

---

## 7. Ruido y prénfasis (7:45–9:30) · Abner

**Pantalla:** `fig_awgn.png`; luego `figuras_video/prenfasis_f0.png`.

> Agregamos ruido blanco y variamos la SNR del canal de 40 a 14 dB. Arriba del umbral, lo medido queda a 1–3 dB de la fórmula del curso. El audio 3 sale unos 14 dB peor que el audio 1, porque a la salida del discriminador el ruido crece con el cuadrado de la frecuencia, y el audio 3 está en la subportadora más alta. Debajo de unos 20 dB aparece el umbral y la calidad cae rápido.
>
> Por esa diferencia entre canales usamos prénfasis. El prénfasis no quita ruido, sino que lo reparte. Para la frecuencia de corte probamos varios valores. Con 10 kHz, el audio 3 gana 2.4 dB y el audio 1 pierde 8.9. Con 30 kHz, el audio 3 gana 2.0 y el audio 1 pierde 5.8. Escogimos 30 kHz porque bajar más casi no ayuda al audio 3.
>
> En Simulink medimos −5.4, −1.1 y +2.0 dB, casi lo mismo que la teoría. A 25 dB, la diferencia entre el mejor y el peor audio bajó de 14 a 6 dB.

---

## 8. Cierre (9:30–10:15) · Jordi

**Pantalla:** tabla 10 de `decisiones_cuantitativas.md`.

> El sistema cumple lo pedido: tres audios en 120 kHz, FM con portadora seleccionable, receptor superheterodino con FI de 1.7 MHz y una radio para elegir portadora y audio.
>
> Limitaciones: la simulación no es en tiempo real, la fase de la subportadora se corrige con un retardo conocido y no con un tono piloto, y el canal solo tiene ruido blanco.

---

## Antes de grabar

- [ ] Figuras:
  - `03_codigo_matlab/figuras/` (las de `graficas_sistema`);
  - `fig_awgn.png` (de `analisis_awgn`);
  - `02_diseno/figuras_video/`.
- [ ] Simular antes en la radio («Simular las 4 combinaciones») para no esperar en la grabación.
- [ ] Ensayar con cronómetro. Si pasa de 11 min, quitar primero el párrafo del limitador (sección 5) y el del retardo (sección 4).
- [ ] Cada uno debe poder explicar todas las partes.
