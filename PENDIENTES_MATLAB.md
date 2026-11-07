# Pendiente de correr en MATLAB

Los cambios de la revisión (prénfasis/deénfasis, limpieza del código, nombres de bloques y señales, scripts nuevos) se escribieron sin poder ejecutar MATLAB. Hay que correr esto en orden, desde `03_codigo_matlab/`. Si algo falla, guardar el mensaje de error **completo** (con archivo y línea).

## 1. `main` (1–2 min)

- La primera vez imprime «Generando sistema_fdm_fm.slx...». Es normal: el modelo cambió y se regenera solo.
- [ ] No debe aparecer ningún «Aviso: no se pudo renombrar…» ni «Aviso: no se pudo ordenar el diagrama…». Si aparece, copiar el mensaje completo.
- La tabla debe terminar con **9 líneas `[OK]`** y decir «Prénfasis/deénfasis apagado».
- Valores que no deberían cambiar respecto de antes:
  - tau = 411.79 / 226.37 / 226.37 µs
  - ganancias sin compensar +0.09 / −0.87 / −0.65
- En la radio:
  - [ ] simular a 10 MHz con la casilla de prénfasis apagada → SDR ≈ 69 dB (fuente demo), igual que antes
  - [ ] lo mismo con la casilla de prénfasis encendida → SDR casi igual
  - [ ] el mensaje de estado muestra la desviación usada (debe ser ≤ 100 %)

### Revisar el modelo (`sistema_fdm_fm.slx`)

El diagrama se ordena solo con el «Auto Arrange» de Simulink. Revisar que se vea así:

- [ ] **Nivel principal:** Audio 1–3 → «Transmisor FDM» → «Modulador FM» → «Canal» → «Receptor superheterodino» → «Demultiplexor FDM» → «Guardar audio 1–3». Las líneas llevan los nombres: x1(t) audio 1 (y 2, 3), m(t) multiplex, s(t) señal FM, x(t) = s(t) + w(t), m(t) recuperado, audio 1 recuperado (y 2, 3).
- [ ] **Transmisor FDM:** tres bloques «Canal k DSB-SC» → «Suma de los 3 canales» → «Normalización (dividir entre 3)» → «Filtro de preénfasis».
- [ ] **Dentro de «Canal k DSB-SC»:** Pasabajos 15 kHz → Subir tasa 1 a 10 → Inserción de ceros (con Tren de pulsos) → Filtro interpolador → Modulador DSB-SC (con Subportadora cos(2 pi fk t)).
- [ ] **Modulador FM:** Subir tasa (a) y (b) → Integrador → 2 pi kf → Fase total (con Reloj t → 2 pi fc) → cos → Amplitud Ac.
- [ ] **Canal:** Ruido blanco gaussiano → Nivel de ruido → Suma de ruido w(t).
- [ ] **Receptor superheterodino:** Sección de RF (preselector) → Mezclador (con Oscilador local) → Filtro antitraslape → Bajar tasa 10 a 1 (FI) → Sección de FI → Demodulador FM → Dividir entre kf → Filtro posdetección → Bajar tasa 10 a 1 (multiplex) → Multiplicar por 3 → Filtro de deénfasis.
- [ ] **Demodulador FM:** Mezcla en fase (I) y en cuadratura (Q) → Pasabajos I y Q → Muestra anterior → productos «I por I anterior», etc. → Parte real / Parte imaginaria → Ángulo girado (atan2) → Convertir a frecuencia. Es el que más probablemente quede con líneas cruzadas.
- [ ] **Demultiplexor FDM:** por canal, Canal k pasabanda → Canal k detector coherente (con Canal k oscilador local) → Canal k pasabajos 15 kHz → Canal k bajar tasa 10 a 1.
- Si algún subsistema queda confuso, avisar cuál y mandar una captura.

## 2. `graficas_sistema` (~1 min)

- [ ] Salen 5 figuras: audios, multiplex, FM, receptor, audios recuperados.
- [ ] La consola imprime los SDR. Deben ser parecidos a los de antes: 60.3 / 59.4 / 57.1 dB.
- [ ] La desviación pico debe ser ≈ 92 kHz (61 %), y el ancho al 99 % de la potencia ≈ 148 kHz.
- Guardar las figuras que se vayan a usar en el video.

## 3. `analisis_awgn` (~8–10 min)

- Parte A, canal ideal:
  - [ ] las dos filas (sin y con prénfasis) dan casi el mismo SDR
  - [ ] el «pico de m(t) al modulador» es ≤ 1
- Parte B, AWGN:
  - [ ] la columna «sin» debería parecerse a la tabla anterior (por ejemplo, a 30 dB: 32.0 / 21.3 / 17.7)
  - [ ] la línea «Diferencia con prénfasis» debería dar cerca de **−6 / −1 / +2 dB**
- Pasar a la conversación: la salida de consola, `resultados_awgn.csv` y `fig_awgn.png`.

## 4. `probar_audio_real` (cuando haya WAV; ~9 min para 2 s)

- [ ] Poner `audio1.wav`, `audio2.wav` y `audio3.wav` en `audios/` (ver `audios/LEEME.txt`).
- [ ] Anotar el SDR de cada audio y escuchar los archivos `recuperado1..3.wav`: ¿se reconocen?
- Opcional: repetir con `snr_c = 25` y con `enfasis = true` (variables al inicio del script).

## 5. `preparar_entrega` (al final, < 1 min)

- [ ] Crea la carpeta `entrega_FDM_FM` (dos niveles arriba de `03_codigo_matlab`) y `entrega_FDM_FM.zip`. Lleva 8 `.m` (main, params_sistema, disenar_fir_kaiser, generar_fuentes, radio_fdm_fm, graficas_sistema, graficar_espectro, comparar_senales), el `.slx` y los WAV. No se entregan `construir_modelo.m`, `modelo_al_dia.m`, `analisis_awgn.m` ni `probar_audio_real.m`.
- [ ] También crea `entrega_FDM_FM_respaldo.zip` (10 `.m`, la versión anterior). Ese **no se manda**: es un respaldo.
- El `.slx` del repositorio es el que ordenaron a mano. Ya no se regenera solo: `modelo_al_dia` solo lo crea si no existe. Si alguna vez corren `construir_modelo` a propósito, se pierde el orden manual (se puede recuperar con git).
- [ ] Todas las líneas deben salir `[OK]`, sin `[FALLA]`.
- [ ] Si avisa que faltan audios, copiar los WAV a `audios/` y volver a correrlo.
- [ ] Prueba final: abrir MATLAB nuevo, ir a `entrega_FDM_FM` y correr `main`.

## Si algo sale distinto

| Síntoma | Causa probable |
|---|---|
| Error en el bloque «Filtro de deénfasis» con el prénfasis apagado | Simulink no acepta el denominador `[1 0]`. Avisar y se cambia. |
| SDR con canal ideal mucho menor que antes | Se coló un cambio en los retardos τ_k. Comparar con la tabla de `params_sistema`. |
| «Falla de diseño: ...» al iniciar | Alguna de las 9 comprobaciones falló. Copiar el texto completo. |
| «Aviso: no se pudo renombrar…» | Simulink no aceptó algún nombre nuevo. El modelo funciona igual, pero ese bloque conserva su nombre interno. Copiar el aviso. |
| Error al compilar en modo acelerado que menciona un nombre con tilde (por ejemplo «Sección de FI») | La compilación no acepta tildes en los nombres. Avisar y se cambian por nombres sin tilde. Mientras tanto, la GUI cae sola a modo normal (más lento). |
| Error de memoria en `probar_audio_real` | Bajar `T_real` a 1 s. |
