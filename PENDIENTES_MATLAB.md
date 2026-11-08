# Pendiente de correr en MATLAB

> **Estado:** la rama principal usa el **discriminador** (verificado en Simulink: SDR 43.3 / 52.2 / 54.4 dB con canal ideal; ver `02_diseno/version_discriminador.md`). Los resultados marcados ✔ más abajo con 60.3 / 59.4 / 57.1 dB son de la versión anterior (detector de cuadratura).

Los cambios de la revisión (prénfasis/deénfasis, limpieza del código, nombres de bloques y señales, scripts nuevos) se escribieron sin poder ejecutar MATLAB. Hay que correr esto en orden, desde `03_codigo_matlab/`. Si algo falla, guardar el mensaje de error **completo** (con archivo y línea).


## 0c. RAMA DISCRIMINADOR (`claude/version-discriminador`)

Esta rama usa el discriminador del curso como demodulador. Los pasos de prueba están en `02_diseno/version_discriminador.md`.

## 0. Esta es la VERSIÓN AGRUPADA (rama `claude/version-agrupada`)

- [x] En GitHub Desktop, cambiar a la rama `claude/version-agrupada` (Current branch). La versión anterior sigue intacta en `claude/affectionate-bardeen-qmc9v9`.
- [x] En esta rama no hay `.slx`: al correr `main` se genera el modelo agrupado («No existe sistema_fdm_fm.slx: se genera…»).
- [x] No debe aparecer ningún «Aviso: no se pudo agrupar…» ni «Aviso: no se pudo renombrar…». Si aparece, copiar el mensaje.
- [x] Abrir el modelo y comparar cada nivel con `02_diseno/correspondencia_curso_modelo.md`. Por ejemplo, el receptor debe verse: Sección de RF → Mezclador (con Oscilador local) → Sección de FI → Demodulador FM → Filtro posdetección → Filtro de deénfasis.
- [x] Correr `graficas_sistema`: los SDR deben salir **iguales** a los de la otra versión (60.3 / 59.4 / 57.1 dB). Agrupar no cambia los cálculos.
- [x] Si les gusta, ordenen a mano lo que haga falta y suban el `.slx`. Si no, vuelvan a la otra rama.
- **Hecho:** todos los grupos se crearon sin avisos; diagramas revisados (`Diagramas nuevos.pdf`); SDR 60.3 / 59.4 / 57.1 dB, igual que la versión anterior. ✔

## 1. `main` (1–2 min)

- La primera vez imprime «Generando sistema_fdm_fm.slx...». Es normal: el modelo cambió y se regenera solo.
- [x] No debe aparecer ningún «Aviso: no se pudo renombrar…» ni «Aviso: no se pudo ordenar el diagrama…». Si aparece, copiar el mensaje completo.
- La tabla debe terminar con **9 líneas `[OK]`** y decir «Prénfasis/deénfasis apagado».
- Valores que no deberían cambiar respecto de antes:
  - tau = 411.79 / 226.37 / 226.37 µs
  - ganancias sin compensar +0.09 / −0.87 / −0.65
- **Hecho (MATLAB R2026a Update 4):** 9 [OK], tau y ganancias iguales, órdenes de filtros iguales a los calculados. ✔
- En la radio:
  - [ ] simular a 10 MHz con la casilla de prénfasis apagada → anotar el SDR (fuente demo; con el discriminador se espera algo menos que los 69 dB del detector de cuadratura)
  - [ ] lo mismo con la casilla de prénfasis encendida → SDR casi igual
  - [ ] el mensaje de estado muestra la desviación usada (debe ser ≤ 100 %)
- **Hecho con ruido (discriminador, fuente demo, 0.3 s, AWGN (SNR)_C = 25 dB):** ✔

  | f_c | Prénfasis | Audio 1 | Audio 2 | Audio 3 |
  |---|---|---|---|---|
  | 10 MHz | no | 34.2 dB | 25.7 dB | 15.8 dB |
  | 10 MHz | sí | 28.7 dB | 24.4 dB | 17.7 dB |
  | 11 MHz | no | 34.4 dB | 25.8 dB | 15.9 dB |
  | 11 MHz | sí | 28.7 dB | 24.5 dB | 17.8 dB |

  - Efecto del prénfasis: −5.5 / −1.3 / +1.9 dB (teoría −5.8 / −1.3 / +2.0).
  - 10 y 11 MHz dan lo mismo (±0.1 dB): la sintonía funciona en las dos portadoras.
  - Los valores absolutos son más altos que los de `analisis_awgn` (26.7 / 16.3 / 12.8) porque la fuente es otra: `analisis_awgn` usa ruido que llena toda la banda de 15 kHz, y la fuente demo usa senoides, que tienen más potencia para el mismo pico.

### Revisar el modelo (`sistema_fdm_fm.slx`)

El diagrama se ordena solo con el «Auto Arrange» de Simulink. Revisar que se vea así:

- [ ] **Nivel principal:** Audio 1–3 → «Transmisor FDM» → «Modulador FM» → «Canal» → «Receptor superheterodino» → «Demultiplexor FDM» → «Guardar audio 1–3». Las líneas llevan los nombres: x1(t) audio 1 (y 2, 3), m(t) multiplex, s(t) señal FM, x(t) = s(t) + w(t), m(t) recuperado, audio 1 recuperado (y 2, 3).
- [ ] **Transmisor FDM:** tres bloques «Canal k DSB-SC» → «Suma de los 3 canales» → «Normalización (dividir entre 3)» → «Filtro de preénfasis».
- [ ] **Dentro de «Canal k DSB-SC»:** Pasabajos 15 kHz → Subir tasa 1 a 10 → Inserción de ceros (con Tren de pulsos) → Filtro interpolador → Modulador DSB-SC (con Subportadora cos(2 pi fk t)).
- [ ] **Modulador FM:** Subir tasa (a) y (b) → Integrador → 2 pi kf → Fase total (con Reloj t → 2 pi fc) → cos → Amplitud Ac.
- [ ] **Canal:** Ruido blanco gaussiano → Nivel de ruido → Suma de ruido w(t).
- [ ] **Receptor superheterodino:** Sección de RF (preselector) → Mezclador (con Oscilador local) → Filtro antitraslape → Bajar tasa 10 a 1 (FI) → Sección de FI → Demodulador FM → Dividir entre kf → Filtro posdetección → Bajar tasa 10 a 1 (multiplex) → Multiplicar por 3 → Filtro de deénfasis.
- [ ] **Demodulador FM (discriminador):** Limitador → Detector de pendiente (derivador) → Detector de envolvente → Convertir a desviación.
- [ ] **Demultiplexor FDM:** por canal, Canal k pasabanda → Canal k detector coherente (con Canal k oscilador local) → Canal k pasabajos 15 kHz → Canal k bajar tasa 10 a 1.
- Si algún subsistema queda confuso, avisar cuál y mandar una captura.

## 2. `graficas_sistema` (~1 min)

- [x] Salen 5 figuras: audios, multiplex, FM, receptor, audios recuperados.
- [x] La consola imprime los SDR. Deben ser parecidos a los de antes: 60.3 / 59.4 / 57.1 dB.
- [x] La desviación pico debe ser ≈ 92 kHz (61 %), y el ancho al 99 % de la potencia ≈ 148 kHz.
- Las figuras se guardan solas en `03_codigo_matlab/figuras/` (fig1 a fig5, PNG).
- **Hecho:** desviación pico 91.6 kHz (61 %), ancho al 99 % 148 kHz (Carson 530 kHz), SDR 60.3 / 59.4 / 57.1 dB, ganancia ≈ 0.997–0.998. ✔

## 3. `analisis_awgn` (~8–10 min)

- Parte A, canal ideal:
  - [x] las dos filas (sin y con prénfasis) dan casi el mismo SDR
  - [x] el «pico de m(t) al modulador» es ≤ 1
- Parte B, AWGN:
  - [x] la columna «sin» debería parecerse a la tabla anterior (por ejemplo, a 30 dB: 32.0 / 21.3 / 17.7)
  - [x] la línea «Diferencia con prénfasis» debería dar cerca de **−6 / −1 / +2 dB**
- Pasar a la conversación: la salida de consola, `resultados_awgn.csv` y `fig_awgn.png`.
- **Hecho (resultados_awgn.csv):** canal ideal 60.3 / 59.7 / 60.0 dB con y sin prénfasis; pico 0.57 sin y 0.49 con; diferencia con prénfasis −5.7 / −1.1 / +2.0 dB. ✔

## 4. `probar_audio_real` (cuando haya WAV; ~9 min para 2 s)

- [x] Poner `audio1.wav`, `audio2.wav` y `audio3.wav` en `audios/` (ver `audios/LEEME.txt`).
- [x] Anotar el SDR de cada audio y escuchar los archivos `recuperado1..3.wav`: ¿se reconocen?
- **Hecho (discriminador, canal ideal):** se subieron `original1..3.wav` y `recuperado1..3.wav`. Consola de MATLAB: SDR = 49.1 / 63.4 / 55.2 dB (simulación de 2 s en 283 s). Con los tonos de prueba fue 43.3 / 52.2 / 54.4 dB.
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
| «The file containing block diagram 'sistema_fdm_fm' has been changed on disk» | Se bajó un `.slx` nuevo con el viejo abierto. Correr `close_system('sistema_fdm_fm', 0)` y repetir. |
| «Code generation folder … slprj was created for a different release» | Carpeta temporal de otra versión de MATLAB (sincronizada por OneDrive). Borrar `slprj` y `sistema_fdm_fm.slxc`. Desde ahora Simulink usa la carpeta temporal de cada computadora. |
