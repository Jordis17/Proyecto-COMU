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
%     graficas_sistema.m    gráficas de cada etapa con canal ideal
%     graficar_espectro.m   espectro sin toolboxes (Welch)
%     comparar_senales.m    SDR entre el audio original y el recuperado
%     audios/audio1..3.wav  audios reales a 48 kHz para el modo 'audio'

clc;
carpeta = fileparts(mfilename('fullpath'));
cd(carpeta);
fprintf('Proyecto FDM + FM + superheterodino. MATLAB %s\n', version);
P = params_sistema(10e6, struct('imprimir', false));
mostrar_diseno(P);                 % tabla de diseño (valor real y simulado) y comprobaciones
mdl = 'sistema_fdm_fm';
if exist('modelo_al_dia', 'file'), modelo_al_dia(mdl); end
radio_fdm_fm();

function mostrar_diseno(P)
% Lo principal del diseño, en valores reales (nominales) y simulados (÷K).
    K = P.K;
    fprintf('\n===== DISEÑO DEL SISTEMA (escala K = %d) =====\n', K);
    fprintf('%-28s %16s %16s\n', 'Parámetro', 'Valor real', 'Simulado');
    L = {'Ancho de cada audio',       P.Wa;
         'Subportadora 1',            P.f_sc(1);
         'Subportadora 2',            P.f_sc(2);
         'Subportadora 3',            P.f_sc(3);
         'Ancho del multiplex',       P.W;
         'Desviación pico',           P.df;
         'Ancho de Carson',           P.B_carson;
         'Portadora',                 P.fc;
         'FI',                        P.f_FI;
         'Oscilador local',           P.f_LO;
         'Frecuencia imagen',         P.f_imagen;
         'Producto suma',             P.f_suma;
         'Muestreo del audio',        P.fs_a;
         'Muestreo del multiplex',    P.fs_m;
         'Muestreo de la FI',         P.fs_fi;
         'Muestreo de la RF',         P.fs_rf};
    for i = 1:size(L, 1)
        fprintf('%-28s %12.1f kHz %12.1f Hz\n', L{i,1}, L{i,2} * K / 1e3, L{i,2});
    end
    fprintf('%-28s %16.2f\n', 'Relación de desviación', P.DR);
    fprintf('\nGanancia de cada canal si NO se compensara el retardo de los filtros:\n');
    for k = 1:3
        fprintf('  audio %d: cos(2 pi f_k tau_k) = %+.2f\n', k, P.ganancia_sin_compensar(k));
    end
    fprintf('\nComprobaciones del diseño:\n');
    for i = 1:size(P.chequeos, 1)
        fprintf('  [OK] %s\n', P.chequeos{i,1});
    end
    fprintf('\n');
end
