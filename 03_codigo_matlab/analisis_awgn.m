% Desempeño del sistema con canal AWGN, sin y con prénfasis/deénfasis.
%   Ejecutar desde esta carpeta:  >> analisis_awgn
%
%   A) Canal ideal: con el prénfasis encendido el SDR debe ser igual (~60 dB), porque el
%      deénfasis lo deshace exactamente. El pico de m(t) al modulador debe seguir <= 1.
%   B) Barrido de (SNR)_C (definición del curso: Ac^2 / (2 W N0), W = 120 kHz), con el mismo
%      ruido en las dos corridas. Para cada canal se compara el SDR medido con la teoría:
%        (SNR)_k = (SNR)_C * W * Df^2 * Px / [18 * Wa * (f_k^2 + Wa^2/3)]
%      que sale de que el ruido a la salida del discriminador crece como f^2 (diap. 385).
%      Con prénfasis, la teoría se suma con la mejora P.enf.mejora_dB.
%   Qué se espera: el canal 3 sale peor (subportadora más alta, más ruido); el prénfasis lo
%   mejora unos +2 dB a costa del canal 1 (unos -6 dB). Por debajo de CNR ~ 10 dB en el
%   ancho de Carson aparece el umbral FM y la calidad cae de golpe.
%
%   Guarda: resultados_awgn.csv, resultados_awgn.mat y fig_awgn.png
%   Duración: 18 simulaciones de 0.1 s reales en modo acelerado (unos 8-10 minutos).

clear; clc; close all;
modo   = 'ruido';                   % llena toda la banda de cada canal
T_real = 0.1;
snr_c  = [40 30 25 20 18 16 14];
mdl    = 'sistema_fdm_fm';
opc    = struct('T_real', T_real, 'imprimir', false);

rng(1);
P0 = params_sistema(10e6, opc);
fuente = generar_fuentes(P0, modo);
Px = mean(fuente.X.^2, 2).';        % potencia de cada audio normalizado
if exist('modelo_al_dia', 'file'), modelo_al_dia(mdl); end
load_system(mdl);
try
    set_param(mdl, 'SimulationMode', 'accelerator');
catch
    set_param(mdl, 'SimulationMode', 'normal');
end

%% A) canal ideal, sin y con prénfasis
fprintf('A) Canal ideal\n');
SDR_ideal = zeros(2, 3);  pico = zeros(1, 2);
for e = 0:1
    o = opc;  o.enfasis = logical(e);
    P = params_sistema(10e6, o);
    out = sim(mdl);
    pico(e+1) = max(abs(out.sim_m_n(:)));
    SDR_ideal(e+1,:) = medir_sdr(out, fuente, P);
    fprintf('   prénfasis %-3s: SDR = %5.1f / %5.1f / %5.1f dB, pico de m(t) al modulador = %.2f\n', ...
        ternario(e, 'sí', 'no'), SDR_ideal(e+1,:), pico(e+1));
end
fprintf('   (Las dos filas deben ser casi iguales y el pico debe ser <= 1.)\n\n');

%% B) barrido de (SNR)_C, sin y con prénfasis
fprintf('B) Canal AWGN (SDR en dB, canales 1 / 2 / 3)\n');
SDR0 = zeros(numel(snr_c), 3);  SDR1 = SDR0;  TEO = SDR0;  CNR = zeros(size(snr_c));
for i = 1:numel(snr_c)
    for e = 0:1
        o = opc;  o.snr_c_dB = snr_c(i);  o.enfasis = logical(e);
        P = params_sistema(10e6, o);
        out = sim(mdl);
        if e == 0, SDR0(i,:) = medir_sdr(out, fuente, P); else, SDR1(i,:) = medir_sdr(out, fuente, P); end
    end
    CNR(i) = P.cnr_BT_dB;
    TEO(i,:) = snr_c(i) + 10*log10(P.W * P.df^2 * Px ./ (18 * P.Wa * (P.f_sc.^2 + P.Wa^2/3)));
    fprintf('   (SNR)_C = %2d dB (CNR %4.1f dB) | sin: %5.1f %5.1f %5.1f | con: %5.1f %5.1f %5.1f | teoría sin: %5.1f %5.1f %5.1f\n', ...
        snr_c(i), CNR(i), SDR0(i,:), SDR1(i,:), TEO(i,:));
end
mejora_teo = P.enf.mejora_dB;
alto = CNR > 13;                    % puntos claramente por encima del umbral
fprintf('\n   Diferencia con prénfasis (sobre el umbral): medida %+5.1f %+5.1f %+5.1f dB | teoría %+5.1f %+5.1f %+5.1f dB\n', ...
    mean(SDR1(alto,:) - SDR0(alto,:), 1), mejora_teo);

%% guardar
tabla = array2table([snr_c(:) CNR(:) SDR0 SDR1 TEO], 'VariableNames', ...
    {'snr_c_dB', 'cnr_BT_dB', 'sin_c1', 'sin_c2', 'sin_c3', 'con_c1', 'con_c2', 'con_c3', ...
     'teo_c1', 'teo_c2', 'teo_c3'});
writetable(tabla, 'resultados_awgn.csv');
save('resultados_awgn.mat', 'snr_c', 'CNR', 'SDR0', 'SDR1', 'TEO', 'SDR_ideal', 'pico', ...
    'mejora_teo', 'Px', 'T_real', 'modo');

figure('Name', 'Canal AWGN', 'Color', 'w', 'Position', [100 100 900 450]); hold on;
col = lines(3);
for k = 1:3
    plot(snr_c, TEO(:,k), ':', 'Color', col(k,:), 'HandleVisibility', 'off');
    plot(snr_c, SDR0(:,k), '--o', 'Color', col(k,:));
    plot(snr_c, SDR1(:,k), '-s', 'Color', col(k,:), 'MarkerFaceColor', col(k,:));
end
umbral = 10 + 10*log10(P.B_carson / P.W);          % CNR = 10 dB en el ancho de Carson
yl = ylim;  plot(umbral*[1 1], yl, 'k:', 'HandleVisibility', 'off');
text(umbral, yl(2) - 3, ' umbral FM');
grid on; xlabel('(SNR)_C [dB]'); ylabel('SDR del audio recuperado [dB]');
legend({'c1 sin prénfasis', 'c1 con prénfasis', 'c2 sin', 'c2 con', 'c3 sin', 'c3 con'}, ...
    'Location', 'southeast');
title(sprintf('Canal AWGN (punteado: teoría sin prénfasis; f_0 = %.0f kHz)', P.vista.f0_enf_kHz));
saveas(gcf, 'fig_awgn.png');
set_param(mdl, 'SimulationMode', 'normal');
fprintf('\nGuardado: resultados_awgn.csv, resultados_awgn.mat, fig_awgn.png\n');

function sdr = medir_sdr(out, fuente, P)
    sdr = zeros(1, 3);
    for k = 1:3
        y = out.(sprintf('sim_y%d', k))(:).';
        n = min(numel(y), fuente.Na);
        sdr(k) = comparar_senales(fuente.X(k,1:n), y(1:n), P.retardo_audio(k), P.fs_a);
    end
end

function v = ternario(c, a, b)
    if c, v = a; else, v = b; end
end
