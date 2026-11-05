# Pendiente de correr en MATLAB

Los cambios de la revisión (prénfasis/deénfasis, limpieza del código, scripts nuevos) se escribieron sin poder ejecutar MATLAB. Hay que correr esto en orden, desde `03_codigo_matlab/`. Si algo falla, guardar el mensaje de error **completo** (con archivo y línea).

## 1. `main` (1–2 min)

- La primera vez imprime «Generando sistema_fdm_fm.slx...». Es normal: el modelo cambió y se regenera solo.
- La tabla debe terminar con **9 líneas `[OK]`** y decir «Prénfasis/deénfasis apagado».
- Valores que no deberían cambiar respecto de antes:
  - tau = 411.79 / 226.37 / 226.37 µs
  - ganancias sin compensar +0.09 / −0.87 / −0.65
- En la radio:
  - [ ] simular a 10 MHz con la casilla de prénfasis apagada → SDR ≈ 69 dB (fuente demo), igual que antes
  - [ ] lo mismo con la casilla de prénfasis encendida → SDR casi igual
  - [ ] el mensaje de estado muestra la desviación usada (debe ser ≤ 100 %)

## 2. `graficas_sistema` (~1 min)

- [ ] Salen 5 figuras: audios, multiplex, FM, receptor, audios recuperados.
- [ ] La consola imprime los SDR. Deben ser parecidos a los de antes: 60.3 / 59.4 / 57.1 dB.
- [ ] La desviación pico debe ser ≈ 92 kHz (61 %), y el ancho al 99 % de la potencia ≈ 148 kHz.
- Guardar las figuras que se vayan a usar en el video.

## 3. `analisis_awgn` (~8–10 min)

- Parte A, canal ideal:
  - [ ] las dos filas (sin y con prénfasis) dan casi el mismo SDR
  - [ ] el pico de m_n es ≤ 1
- Parte B, AWGN:
  - [ ] la columna «sin» debería parecerse a la tabla anterior (por ejemplo, a 30 dB: 32.0 / 21.3 / 17.7)
  - [ ] la línea «Diferencia con prénfasis» debería dar cerca de **−6 / −1 / +2 dB**
- Pasar a la conversación: la salida de consola, `resultados_awgn.csv` y `fig_awgn.png`.

## 4. `probar_audio_real` (cuando haya WAV; ~9 min para 2 s)

- [ ] Poner `audio1.wav`, `audio2.wav` y `audio3.wav` en `audios/` (ver `audios/LEEME.txt`).
- [ ] Anotar el SDR de cada audio y escuchar los archivos `recuperado1..3.wav`: ¿se reconocen?
- Opcional: repetir con `snr_c = 25` y con `enfasis = true` (variables al inicio del script).

## 5. `preparar_entrega` (al final, < 1 min)

- [ ] Crea la carpeta `entrega_FDM_FM` (dos niveles arriba de `03_codigo_matlab`) y `entrega_FDM_FM.zip`. Lleva 10 `.m` y el `.slx`; `construir_modelo.m` y `modelo_al_dia.m` no se entregan.
- [ ] Si ordenan el diagrama del `.slx` a mano, háganlo **después** de cualquier cambio en `construir_modelo.m`. Si ese archivo cambia luego, el `.slx` se vuelve a generar y se pierde el orden manual.
- [ ] Todas las líneas deben salir `[OK]`, sin `[FALLA]`.
- [ ] Si avisa que faltan audios, copiar los WAV a `audios/` y volver a correrlo.
- [ ] Prueba final: abrir MATLAB nuevo, ir a `entrega_FDM_FM` y correr `main`.

## Si algo sale distinto

| Síntoma | Causa probable |
|---|---|
| Error en el bloque `Deenfasis` con el prénfasis apagado | Simulink no acepta el denominador `[1 0]`. Avisar y se cambia. |
| SDR con canal ideal mucho menor que antes | Se coló un cambio en los retardos τ_k. Comparar con la tabla de `params_sistema`. |
| «Falla de diseño: ...» al iniciar | Alguna de las 9 comprobaciones falló. Copiar el texto completo. |
| Error de memoria en `probar_audio_real` | Bajar `T_real` a 1 s. |
