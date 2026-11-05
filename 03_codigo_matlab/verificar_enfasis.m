%VERIFICAR_ENFASIS  Prueba de los filtros de prénfasis/deénfasis (enunciado §4.5) en Simulink.
%   Ejecutar desde la carpeta del proyecto:  >> verificar_enfasis
%
%   A) Canal ideal: con el prénfasis encendido el SDR debe quedar igual (~60 dB), porque el
%      deénfasis es el inverso exacto del prénfasis. También se mide el pico de m_n (debe
%      seguir <= 1: la desviación pico y el ancho de Carson no cambian).
%   B) Canal AWGN: misma fuente y mismo ruido (misma semilla), con y sin prénfasis.
%      Se compara la diferencia medida con la mejora teórica P.enf.mejora_dB.
%
%   Qué se espera (con f0 = 30 kHz): canal 3 mejora ~ +2 dB, canal 2 ~ -1 dB, canal 1 ~ -6 dB.
%   Es decir, el prénfasis reparte la calidad: mejora el canal peor (el 3, que tiene más
%   ruido por estar en la subportadora más alta) a costa del canal 1, que tiene SNR de sobra.
%
%   Guarda: resultados_enfasis.csv, resultados_enfasis.mat y fig_enfasis.png
%   Duración: 14 simulaciones de 0.1 s reales en modo acelerado (unos 6-8 minutos).

clear; clc; close all;
modo   = 'ruido';                   % ocupa toda la banda de cada canal (prueba exigente)
T_real = 0.1;
snr_c  = [35 30 25 20 18 16];
mdl    = 'sistema_fdm_fm';
opc    = struct('T_real', T_real, 'imprimir', false);

rng(1);
P0 = params_sistema(10e6, opc);
fuente = generar_fuentes(P0, modo);
modelo_al_dia(mdl);
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
    for k = 1:3
        y = out.(sprintf('sim_y%d', k))(:).';
        n = min(numel(y), fuente.Na);
        SDR_ideal(e+1, k) = comparar_senales(fuente.X(k,1:n), y(1:n), P.retardo_audio(k), P.fs_a);
    end
    fprintf('   prénfasis %-3s: SDR = %5.1f / %5.1f / %5.1f dB, pico de m_n = %.2f\n', ...
        ternario(e, 'sí', 'no'), SDR_ideal(e+1,:), pico(e+1));
end
fprintf('   (Ambas filas deben ser casi iguales y el pico debe ser <= 1.)\n\n');

%% B) canal AWGN, sin y con prénfasis (misma semilla de ruido)
fprintf('B) Canal AWGN\n');
SDR0 = zeros(numel(snr_c), 3);  SDR1 = SDR0;
for i = 1:numel(snr_c)
    for e = 0:1
        o = opc;  o.snr_c_dB = snr_c(i);  o.enfasis = logical(e);
        P = params_sistema(10e6, o);
        out = sim(mdl);
        for k = 1:3
            y = out.(sprintf('sim_y%d', k))(:).';
            n = min(numel(y), fuente.Na);
            s = comparar_senales(fuente.X(k,1:n), y(1:n), P.retardo_audio(k), P.fs_a);
            if e == 0, SDR0(i,k) = s; else, SDR1(i,k) = s; end
        end
    end
    fprintf('   (SNR)_C = %2d dB | sin: %5.1f %5.1f %5.1f | con: %5.1f %5.1f %5.1f | diferencia: %+5.1f %+5.1f %+5.1f dB\n', ...
        snr_c(i), SDR0(i,:), SDR1(i,:), SDR1(i,:) - SDR0(i,:));
end
mejora_teo = P.enf.mejora_dB;
fprintf('   Mejora teórica (sobre el umbral): %+5.1f %+5.1f %+5.1f dB  (f0 = %.0f kHz)\n', ...
    mejora_teo, P.vista.f0_enf_kHz);

%% guardar
tabla = array2table([snr_c(:) SDR0 SDR1 SDR1 - SDR0], 'VariableNames', ...
    {'snr_c_dB', 'sin_c1', 'sin_c2', 'sin_c3', 'con_c1', 'con_c2', 'con_c3', 'dif_c1', 'dif_c2', 'dif_c3'});
writetable(tabla, 'resultados_enfasis.csv');
save('resultados_enfasis.mat', 'snr_c', 'SDR0', 'SDR1', 'SDR_ideal', 'pico', 'mejora_teo', 'T_real', 'modo');

figure('Name', 'Prénfasis / deénfasis', 'Position', [100 100 900 420]);
col = lines(3);
for k = 1:3
    plot(snr_c, SDR0(:,k), '--o', 'Color', col(k,:)); hold on;
    plot(snr_c, SDR1(:,k), '-s',  'Color', col(k,:), 'LineWidth', 1.5);
end
grid on; xlabel('(SNR)_C [dB]'); ylabel('SDR del audio recuperado [dB]');
legend({'c1 sin', 'c1 con', 'c2 sin', 'c2 con', 'c3 sin', 'c3 con'}, 'Location', 'northwest');
title(sprintf('Efecto del prénfasis/deénfasis (f_0 = %.0f kHz)', P.vista.f0_enf_kHz));
saveas(gcf, 'fig_enfasis.png');
fprintf('\nGuardado: resultados_enfasis.csv, resultados_enfasis.mat, fig_enfasis.png\n');

function v = ternario(c, a, b)
    if c, v = a; else, v = b; end
end
