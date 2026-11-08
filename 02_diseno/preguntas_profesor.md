# Preguntas probables del profesor

Respuestas cortas para practicar. Las cifras salen de `diseno_final.md`. Lo importante es poder explicar el **porqué** con sus palabras, no repetir el texto.

---

## A. Enunciado y escalamiento

**1. ¿Por qué dicen que la tabla de escalamiento está mal?**
Divide por 100 la portadora y la FI, pero no el audio ni el multiplex. El multiplex pasa de ocupar el 1.2 % de la portadora al 120 %. Con 530 kHz de Carson, la FM quedaría en 100 ± 265 kHz y cruzaría 0 Hz. Además, la FI (17 kHz) quedaría por debajo del mensaje (115 kHz).

**2. ¿Por qué K = 100 y no otro valor?**
Cualquier K mantiene las proporciones si se aplica a todo. Con 100 se conservan los valores de portadora y FI que da la propia tabla (100 kHz y 17 kHz), y las cuentas quedan fáciles.

**3. ¿Escalar ahorra cálculo?**
No por sí solo. Un segundo real se convierte en 100 s simulados, pero con 100 veces menos muestras por segundo, y el total es el mismo. Lo que sí ahorra es que cada etapa trabaje a su propia frecuencia de muestreo: 48 kHz, 480 kHz, 4.8 MHz y 48 MHz.

**4. Si todo está escalado, ¿cómo escuchan el audio?**
Las muestras del audio no se cambian; solo se interpretan como si estuvieran 100 veces más separadas en el tiempo. Al reproducirlas a 48 kHz se escucha el audio original.

**5. ¿Por qué no siguieron la regla de muestrear a 5–10 veces el ancho de banda?**
En pasabanda lo que importa es la frecuencia más alta, no el ancho. El producto suma del mezclador llega a 20.65 MHz, así que Nyquist pide más de 41.3 MHz. Con la regla del enunciado (5–10 × 530 kHz) ni siquiera se representaría la portadora.

---

## B. FDM

**6. ¿Por qué DSB-SC y no SSB?**
Un audio real tiene contenido casi desde 0 Hz, así que las dos bandas laterales quedan pegadas a la subportadora. Separar una sola exigiría un filtro casi ideal. Con DSB-SC basta un multiplicador, y los 120 kHz alcanzan para tres canales de 30 kHz con guardas.

**7. ¿Y por qué no AM con portadora, que se demodula con un detector de envolvente?**
Las portadoras se comerían parte de la desviación de la FM sin llevar información, y eso empeora la SNR. Además, no hace falta: con DSB-SC y detección coherente funciona bien.

**8. ¿Para qué sirven las guardas de 10 kHz?**
Los filtros reales necesitan una banda de transición. Con 10 kHz, los filtros de cada canal pasan su banda completa y rechazan 60 dB la del vecino.

**9. ¿Por qué dividen el multiplex entre 3?**
Cada audio tiene pico 1, así que la suma puede llegar a 3. Al dividir entre 3 (bloque «Normalización (dividir entre 3)»), la señal m(t) que entra al modulador nunca pasa de 1 y la desviación nunca pasa de 150 kHz.

**10. ¿Qué pasa si la subportadora del receptor no está en fase?**
La salida queda multiplicada por cos φ (diap. 237–238). Los filtros retrasan la señal: sin compensar, las ganancias serían −0.90, +0.52 y −0.79 (lo imprime `main`). El canal 2 perdería 5.7 dB y los otros dos saldrían invertidos. El valor depende de los filtros: con el detector de cuadratura, el canal 1 quedaba en 0.09 y caía 21 dB. Por eso el «Canal k oscilador local» del demultiplexor genera cos(2π f_k (t − τ_k)) y el «Canal k detector coherente» multiplica por esa señal ya corregida.

**11. ¿Eso se puede hacer en un receptor real?**
No exactamente, porque no se conoce el retardo. En la práctica se manda un tono piloto, como el de 19 kHz de la FM estéreo, o se usa un PLL. En la simulación el retardo es conocido y fijo, así que lo compensamos directamente. Lo dejamos como limitación.

---

## C. FM

**12. ¿Cuál es el índice de modulación?**
El mensaje tiene muchas frecuencias, así que no hay un único índice. Usamos la relación de desviación (diap. 328): DR = Δf / f_m,máx = 150 / 115 = 1.30.

**13. ¿Por qué Carson con 115 kHz y no con 15 kHz?**
Porque lo que entra al modulador es el multiplex, cuya frecuencia más alta es 115 kHz. Con 15 kHz se subestimaría mucho el ancho de banda.

**14. ¿Por qué el ancho medido (unos 150 kHz) es menor que Carson (530 kHz)?**
Carson supone un tono a la frecuencia máxima con la desviación máxima. En la práctica los tres audios casi nunca llegan juntos a su pico (la desviación real fue del 61 %), y la potencia está repartida en todo el multiplex. Carson es una cota para dimensionar, no el ancho exacto.

**15. ¿Por qué Δf = 150 kHz?**
La SNR de salida en FM crece con Δf² (figura de mérito, diap. 377–378), pero también crece el ancho de banda. Con 150 kHz la señal cabe con margen en la FI y en el muestreo. Pasar de 75 a 150 kHz da unos 6 dB más.

**16. ¿Y si usaran una desviación mucho mayor?**
Ganarían SNR, pero la FM sería más ancha. Entraría más ruido al filtro de FI, el umbral aparecería con una SNR más alta y la banda de FI quedaría más ajustada a la frecuencia de muestreo.

---

## D. Receptor superheterodino

**17. ¿Qué es la frecuencia imagen y cómo la eliminan?**
Es la otra frecuencia que, al mezclarse con el LO, también da 1.7 MHz: f_c − 2·f_FI = 6.6 MHz a 10 MHz. La sección de RF (preselector), antes del mezclador, deja pasar f_c ± 350 kHz y rechaza más de 60 dB desde ±1.55 MHz, así que la imagen, que está a 3.4 MHz de distancia, no pasa.

**18. Si solo hay una emisora, ¿para qué el preselector?**
Para el ruido. Sin preselector, el ruido de la banda imagen también llega a la FI. Lo medimos: con (SNR)_C = 25 dB, quitar el preselector empeora unos 3 dB, que es lo que predice la teoría (se duplica el ruido). Esa prueba se hizo con la versión anterior del demodulador; el efecto viene del ruido de la banda imagen, que entra antes del demodulador.

**19. ¿Por qué inyección inferior, si los ejemplos del curso usan la superior?**
Con la superior el producto suma llegaría a unos 24 MHz y haría falta muestrear a más de 48 MHz. Con la inferior cabe y el espectro no sale invertido. En radio AM se usa la superior por el rango de sintonía del oscilador, pero aquí el rango es solo de 9 a 11 MHz.

**20. ¿Por qué 1.7 MHz es una FI válida?**
Cumple la definición del curso (diap. 359): es menor que la portadora y mayor que el mensaje (115 kHz). Además, 1.7 MHz − 350 kHz > 0, así que la banda de FI no toca 0 Hz.

**21. ¿Cómo se calcula el LO cuando cambio la portadora?**
f_LO = f_c − 1.7 MHz, lo calcula `params_sistema.m`. Al mover el dial también se recalculan la imagen y el preselector, y el plan de frecuencias de la radio se mueve sin simular. La FI no cambia.

**22. ¿Cómo demodulan la FM?**
Con el discriminador del curso (diap. 342–345): limitador → detector de pendiente → detector de envolvente.
- El limitador deja la amplitud constante.
- El derivador convierte la FM en AM: al derivar cos θ(t), la amplitud queda proporcional a dθ/dt = 2π f_i.
- El detector de envolvente saca esa amplitud. Dividiendo entre 2π y restando la FI queda k_f·m(t).

En el modelo es el subsistema «Demodulador FM», dentro del receptor.

**22b. ¿Por qué el limitador divide por la amplitud en vez de recortar la onda?**
En una simulación digital, recortar la onda genera armónicos que, a 4.8 MHz de muestreo, se pliegan sobre la señal: lo probamos y la calidad bajaba a 9–14 dB. Dividir por la amplitud (medida con un detector de ley cuadrática) logra lo mismo, una amplitud constante, sin generar armónicos. Además, nunca se usa una amplitud menor a 0.3, como un limitador real, que tiene ganancia finita.

**22c. ¿Y si se quita el limitador?**
Deja de funcionar con ruido. La salida del discriminador es amplitud × frecuencia, así que el ruido de amplitud queda multiplicado por toda la FI (1.7 MHz). En la prueba en Python, a 40 dB de (SNR)_C el SDR caía a 5 dB. Por eso el curso siempre lo pone (diap. 375).

**22d. ¿Probaron otros demoduladores?**
Sí, un PLL (diap. 347–354) y un detector de cuadratura.
- Con ruido moderado, los tres dan lo mismo.
- El PLL aguanta unos 3–4 dB más antes del umbral (extensión del umbral), pero con canal ideal distorsiona más: 34–48 dB contra 43–54 dB del discriminador.
- El detector de cuadratura no lo usamos porque no se vio en el curso.
- El PLL sí es del curso. No lo usamos porque sin ruido es peor en dos de los tres audios (el audio 3 queda en 34 dB frente a 54 dB del discriminador), su ventaja solo aparece cerca del umbral, donde el audio 3 ya sale mal con cualquiera de los dos, y además hay que diseñar el lazo y compensar su fase.

Está en `comparacion_demoduladores.md`.

**23. ¿Qué pasa si el receptor está desintonizado?**
Con 600 kHz de error, la señal cae fuera del filtro de FI y el audio se pierde (SDR ≈ 0.9 dB). Con errores pequeños (50 kHz) sigue funcionando, porque la FI tiene margen y el pasabanda de cada canal elimina el nivel de DC que aparece.

---

## E. Ruido y prénfasis

**24. ¿Cómo definen la SNR del canal?**
Con la del curso (Haykin, diap. 377): (SNR)_C = (A_c²/2) / (W·N₀), con W = 120 kHz. El ruido se suma a la RF con varianza N₀·f_s/2.

**25. ¿Por qué el canal 3 sale peor que el 1?**
A la salida del discriminador el ruido crece con f² (diap. 385). El canal 3 está en 100 kHz y el canal 1 en 20 kHz. Integrando, la diferencia teórica es de unos 13 dB, y medimos unos 14 dB (los audios no tenían exactamente la misma potencia).

**26. ¿Qué es el efecto umbral?**
Cuando el ruido se hace comparable a la portadora, la fase da saltos y el demodulador produce picos. La calidad cae de golpe en vez de bajar poco a poco. En nuestro sistema, con el discriminador, aparece con una relación portadora a ruido de unos 14 dB en el ancho de Carson ((SNR)_C ≈ 20 dB). Con un PLL aparece unos 3–4 dB más abajo.

**27. ¿Por qué no usaron el prénfasis con canal ideal?**
Porque no hace falta: sin ruido el SDR ya es de 43 a 54 dB. Además, el prénfasis y el deénfasis son inversos, así que sin ruido se cancelan.

**28. ¿Dónde pusieron el prénfasis y por qué ahí?**
Antes del modulador FM y después del demodulador, como en la diap. 384. El mensaje que entra al modulador es el multiplex, así que se filtra el multiplex completo. Es un filtro de primer orden que sube las frecuencias altas; el deénfasis es su inverso exacto. En el modelo son el «Filtro de preénfasis» (al final del transmisor) y el «Filtro de deénfasis» (después del filtro posdetección).

**29. ¿Por qué el prénfasis empeora el canal 1?**
Mantenemos la misma desviación pico para no cambiar el ancho de banda. Si se suben los canales altos, hay que bajar un poco el total, y el canal 1 queda con menos señal. El prénfasis no quita ruido en total: lo reparte. En Simulink medimos −5.4 / −1.1 / +2.0 dB en los canales 1 / 2 / 3 (la teoría da −5.8 / −1.3 / +2.0). El canal 1 tenía SNR de sobra y el 3 era el que limitaba; a 25 dB la diferencia entre ellos bajó de 13.9 a 6.3 dB.

**30. ¿Por qué no usaron el prénfasis de 75 µs de la radio FM?**
En la FM comercial el audio principal está en banda base, donde el ruido crece dentro del propio audio. En nuestro canal 3 el ruido depende sobre todo de la posición de la subportadora, así que dentro del audio es casi plano y un prénfasis por audio casi no ayudaría.

**31. ¿El prénfasis mueve el umbral?**
No, porque la desviación y el ancho de banda son los mismos.

**31b. ¿Por qué con ruido los audios grabados salen mucho peor que los tonos de prueba?**
Por la relación entre el pico y el valor rms. Cada audio se normaliza por su pico para no pasarse de la desviación de 150 kHz, pero contra el ruido cuenta la potencia promedio. Una senoide tiene un pico 3 dB por encima de su rms; nuestras grabaciones, unos 17–18 dB, por los picos de la voz y los silencios. Con el mismo pico llevan unos 14–15 dB menos de potencia y el SDR baja en esa proporción. A 11 MHz, con (SNR)_C = 25 dB y prénfasis, salió 12.7 / 10.2 / 7.7 dB, frente a 28.7 / 24.5 / 17.8 dB con la fuente demo: la diferencia es de 16 / 14 / 10 dB. En el audio 3 es menor porque los pitidos de la fuente demo suenan solo un tercio del tiempo, así que esa fuente ya tenía unos 5 dB menos de potencia. Con canal ideal no se nota (49 / 63 / 55 dB). Las emisoras comerciales comprimen el audio por este motivo.

---

## F. Implementación

**32. ¿Por qué hicieron sus propios filtros?**
Uno de los dos no tiene DSP System Toolbox ni Signal Processing Toolbox. Diseñamos los FIR con ventana de Kaiser en `disenar_fir_kaiser.m`, que sube el orden hasta medir 60 dB de rechazo.

**33. ¿Cómo saben que el modelo de Simulink está bien?**
Escribimos el transmisor, el canal y el receptor hasta la FI en MATLAB puro y comparamos muestra por muestra con Simulink: las diferencias fueron menores a 10⁻⁹. También medimos el SDR de los audios recuperados (43 a 54 dB) y comparamos el resultado con ruido contra la fórmula del curso: a 25 y 30 dB la diferencia es de 0.4 a 0.8 dB. A 40 dB el audio 1 queda 2.7 dB abajo de la fórmula, porque se acerca a su límite sin ruido (43 dB).

**34. ¿Qué es el SDR que reportan?**
La potencia del audio original dividida entre la potencia del error, después de alinear el retardo y la ganancia. 50 dB significa que el error es 100 000 veces más pequeño que la señal (en potencia).

**35. ¿Por qué tarda tanto la simulación?**
La parte de RF va a 48 MHz nominales: un segundo de audio son 48 millones de muestras. En modo acelerado, 2 s de audio tardaron 283 s (unos 2.5 minutos por segundo de audio) en la computadora donde lo probamos. Por eso la radio guarda cada simulación y no hay que repetirla.

**36. ¿Qué se actualiza cuando cambio la portadora en la GUI?**
Se recalculan los parámetros: LO, imagen y coeficientes del preselector. La GUI muestra los valores nuevos al instante, y al simular el modelo los usa, porque ningún bloque tiene números fijos.

**37. ¿Qué significan los nombres de las señales del modelo?**
Usamos la notación del curso (diap. 309, 365 y 384): m(t) es el mensaje que entra al modulador, que aquí es el multiplex; s(t) es la señal FM; w(t) es el ruido del canal, y x(t) = s(t) + w(t) es lo que llega al receptor. Los audios son x1(t), x2(t) y x3(t), como en el esquema de FDM (diap. 264).

**38. ¿Para qué sirven los bloques «Subir tasa» y «Bajar tasa»?** *(están dentro de «Interpolación», «Sección de FI», «Filtro posdetección» y «Canal k pasabajos 15 kHz»)*
Cada parte del sistema trabaja a la frecuencia de muestreo que necesita: 48 kHz el audio, 480 kHz el multiplex, 4.8 MHz la FI y 48 MHz la RF. «Subir tasa» (con el tren de pulsos, la inserción de ceros y el filtro interpolador) pasa a una tasa 10 veces mayor; «Bajar tasa» toma 1 de cada 10 muestras, después de un filtro que evita el traslape. Si todo fuera a 48 MHz, la simulación sería muchísimo más lenta. Como no son parte del sistema de comunicaciones sino de la simulación, los agrupamos adentro de los bloques del curso, para que cada diagrama se vea como el de la presentación.

---

## Cosas que conviene NO decir

- «El prénfasis mejora todos los canales». No es cierto: los reparte.
- «Carson da el ancho exacto». Es una aproximación para dimensionar.
- «El escalamiento hace la simulación más rápida». Lo que la acelera es usar varias frecuencias de muestreo.
- «En la vida real se compensa el retardo igual». En la vida real se usa un piloto o un PLL.
