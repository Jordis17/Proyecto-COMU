%MAIN  Punto de entrada del proyecto: sistema FDM + FM con receptor superheterodino.
%   Comunicaciones Eléctricas I (EL5513) - ITCR.
%   Ejecutar desde esta carpeta:  >> main
%
%   Requisitos: MATLAB R2026a + Simulink (sin toolboxes adicionales).
%   El modelo Simulink es sistema_fdm_fm.slx (solo bloques básicos).
%
%   Archivos:
%     main.m                este archivo: imprime el diseño y abre la radio
%     params_sistema.m      todos los parámetros (escala K = 100) y las comprobaciones del diseño
%     disenar_fir_kaiser.m  diseño de los filtros FIR (ventana de Kaiser)
%     sistema_fdm_fm.slx    el modelo Simulink
%     generar_fuentes.m     audios de prueba: 'demo', 'tonos', 'ruido' o 'audio' (WAV)
%     radio_fdm_fm.m        interfaz tipo radio
%     graficas_sistema.m    gráficas de cada etapa con canal ideal (evidencia para el informe)
%     analisis_awgn.m       canal AWGN, sin y con prénfasis/deénfasis
%     probar_audio_real.m   pasa 3 WAV reales por el sistema y guarda los recuperados
%     graficar_espectro.m   espectro sin toolboxes (Welch)
%     comparar_senales.m    SDR entre el audio original y el recuperado
%     preparar_entrega.m    (solo para el equipo) arma la carpeta y el .zip de entrega
%     audios/audio1..3.wav  (opcional) audios reales a 48 kHz para el modo 'audio'

clc;
carpeta = fileparts(mfilename('fullpath'));
cd(carpeta);
fprintf('Proyecto FDM + FM + superheterodino. MATLAB %s\n', version);
P = params_sistema(10e6);          % imprime la tabla de diseño y las comprobaciones
mdl = 'sistema_fdm_fm';
if exist('modelo_al_dia', 'file'), modelo_al_dia(mdl); end
radio_fdm_fm();
