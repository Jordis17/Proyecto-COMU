%VERIFICAR_ETAPA8  Evaluación del sistema con canal AWGN (Simulink).
%   Ejecutar desde la carpeta del proyecto:  >> verificar_etapa8
%   A) Barrido de (SNR)_C: SDR medido de cada audio frente a la predicción teórica
%      (SNR)_k = (SNR)_C * W * Df^2 * Px / [18 * Wa * (f_k^2 + Wa^2/3)]      [doc §6.9]
%      derivada de la DEP de ruido a la salida del discriminador S_No(f) = N0 f^2 / Ac^2
%      (Haykin, diap. 377-385 del curso). Se observa el efecto umbral y la penalización
%      de los canales de subportadora alta.
%   B) Papel de la sección de RF: misma (SNR)_C con y sin preselector. Sin él, el ruido de
%      la banda imagen (f_c - 2 f_FI) también se convierte a la FI: se espera ~3 dB peor.
%   Duración: ~10 simulaciones de 0.1 s reales en modo acelerado (unos minutos).

clear; clc; close all;
modo   = 'ruido';                      % ocupa toda la banda de cada canal
T_real = 0.1;
snr_c  = [40 35 30 25 20 18 16 14 12 10];
mdl    = 'sistema_fdm_fm';

rng(1);
P0 = params_sistema(10e6, struct('T_real', T_real, 'imprimir', false));
fuente = generar_fuentes(P0, modo);
Px = mean(fuente.X.^2, 2).';
modelo_al_dia(mdl);
load_system(mdl);
try
    set_param(mdl, 'SimulationMode', 'accelerator');
catch
    set_param(mdl, 'SimulationMode', 'normal');
end

%% A) barrido de (SNR)_C
SDR = zeros(numel(snr_c), 3);  TEO = SDR;  CNR = zeros(size(snr_c));
for i = 1:numel(snr_c)
    P = params_sistema(10e6, struct('T_real', T_real, 'snr_c_dB', snr_c(i), 'imprimir', false));
    tic; out = sim(mdl); ts = toc;
    CNR(i) = P.cnr_BT_dB;
    for k = 1:3
        y = out.(sprintf('sim_y%d', k))(:).';
        n = min(numel(y), fuente.Na);
        SDR(i,k) = comparar_senales(fuente.X(k,1:n), y(1:n), P.retardo_audio(k), P.fs_a);
        TEO(i,k) = snr_c(i) + 10*log10(P.W*P.df^2*Px(k) / (18*P.Wa*(P.f_sc(k)^2 + P.Wa^2/3)));
    end
    fprintf('(SNR)_C = %2d dB | CNR en B_T = %5.1f dB | SDR medido %5.1f %5.1f %5.1f | teoría %5.1f %5.1f %5.1f  [%.0f s]\n', ...
        snr_c(i), CNR(i), SDR(i,:), TEO(i,:), ts);
end
d21 = mean(SDR(1:4,1) - SDR(1:4,2));  d31 = mean(SDR(1:4,1) - SDR(1:4,3));
t21 = mean(TEO(1:4,1) - TEO(1:4,2));  t31 = mean(TEO(1:4,1) - TEO(1:4,3));
fprintf('\nDiferencia media entre canales (zona sin umbral): c1-c2 = %.1f dB (teoría %.1f), c1-c3 = %.1f dB (teoría %.1f)\n', d21, t21, d31, t31);
fprintf('  (con audios de igual potencia la teoría da 8.9 y 13.3 dB: solo el efecto f^2 del ruido FM;\n');
fprintf('   aquí cada audio tiene una potencia Px algo distinta y la teoría la incluye)\n');

%% B) con y sin preselector, a la misma (SNR)_C
snr_B = 25;
P = params_sistema(10e6, struct('T_real', T_real, 'snr_c_dB', snr_B, 'imprimir', false));
out = sim(mdl);
sdr_con = zeros(1,3);
for k = 1:3
    y = out.(sprintf('sim_y%d', k))(:).';  n = min(numel(y), fuente.Na);
    sdr_con(k) = comparar_senales(fuente.X(k,1:n), y(1:n), P.retardo_audio(k), P.fs_a);
end
P.h.presel = 1;           % sin sección de RF: el preselector se reemplaza por un cable
P.tau = P.tau - P.fi_info.presel.retardo_s;              % se quita su retardo
P.fase_rx = -2*pi*P.f_sc .* P.tau;
P.retardo_audio = P.retardo_audio - P.fi_info.presel.retardo_s;
out = sim(mdl);           % (en modo acelerado puede recompilar una vez)
sdr_sin = zeros(1,3);
for k = 1:3
    y = out.(sprintf('sim_y%d', k))(:).';  n = min(numel(y), fuente.Na);
    sdr_sin(k) = comparar_senales(fuente.X(k,1:n), y(1:n), P.retardo_audio(k), P.fs_a);
end
fprintf('\n(SNR)_C = %d dB, SDR con preselector: %5.1f %5.1f %5.1f dB\n', snr_B, sdr_con);
fprintf('                SDR sin preselector: %5.1f %5.1f %5.1f dB\n', sdr_sin);
fprintf('  Pérdida por el ruido de la banda imagen: %.1f %.1f %.1f dB (teoría ~3 dB)\n', sdr_con - sdr_sin);
set_param(mdl, 'SimulationMode', 'normal');

%% gráficas
figure('Name', 'Etapa 8: AWGN', 'Color', 'w');
colores = lines(3);
hold on;
for k = 1:3
    plot(snr_c, TEO(:,k), '--', 'Color', colores(k,:));
    plot(snr_c, SDR(:,k), 'o-', 'Color', colores(k,:), 'MarkerFaceColor', colores(k,:));
end
umbral = 10 + 10*log10(P0.B_carson / P0.W);           % CNR = 10 dB en B_T
yl = ylim;  plot(umbral*[1 1], yl, 'k:');
text(umbral, yl(2) - 3, ' umbral FM (CNR \approx 10 dB en B_T)');
grid on; xlabel('(SNR)_C  [dB]  (Haykin: A_c^2 / 2 W N_0, W = 120 kHz)'); ylabel('SDR del audio recuperado [dB]');
legend('canal 1 teoría', 'canal 1 Simulink', 'canal 2 teoría', 'canal 2 Simulink', ...
       'canal 3 teoría', 'canal 3 Simulink', 'Location', 'northwest');
title('Desempeño con AWGN: SDR por canal frente a (SNR)_C');
