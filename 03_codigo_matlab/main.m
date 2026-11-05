%MAIN  Punto de entrada del proyecto: sistema FDM + FM con receptor superheterodino.
%   Comunicaciones Eléctricas I (EL5513) - ITCR.
%   Ejecutar desde esta carpeta:  >> main
%
%   Requisitos: MATLAB R2026a + Simulink (sin toolboxes adicionales).
%   El modelo sistema_fdm_fm.slx se genera con construir_modelo.m si no existe.
%
%   Archivos principales:
%     params_sistema.m      todos los parámetros del diseño (escala K = 100) y comprobaciones
%     construir_modelo.m    genera el modelo Simulink por bloques
%     radio_fdm_fm.m        interfaz tipo radio
%     modelo_referencia.m   la misma cadena en MATLAB, para verificar el modelo
%     verificar_etapa*.m    scripts de verificación de cada etapa
%     audios/audio1..3.wav  (opcional) audios reales a 48 kHz para el modo 'audio'

clc;
carpeta = fileparts(mfilename('fullpath'));
cd(carpeta);
fprintf('Proyecto FDM + FM + superheterodino. MATLAB %s\n', version);
P = params_sistema(10e6);          % imprime la tabla de diseño y las comprobaciones
modelo_al_dia('sistema_fdm_fm');   % genera/actualiza el .slx si hace falta
radio_fdm_fm();
