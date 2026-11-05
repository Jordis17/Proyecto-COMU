%VERIFICAR_ETAPA5  Sistema completo en Simulink (canal ideal): superheterodino + demux FDM.
%   Ejecutar desde la carpeta del proyecto:  >> verificar_etapa5
%   1) Construye el modelo completo y lo simula (modo acelerado si está disponible).
%   2) Compara FI, multiplex demodulado y los 3 audios con modelo_referencia.m.
%   3) Mide el SDR de cada audio recuperado frente al original (alineando retardo y ganancia).
%   4) Grafica los espectros del receptor (salida del mezclador con FI y producto suma,
%      FI filtrada, multiplex recuperado) y los audios originales vs recuperados.
%   Cambie fc_nom para probar otra portadora (9 a 11 MHz): el LO se recalcula solo.

clear; clc; close all;
rng(1);
modo     = 'ruido';    % 'tonos', 'ruido' o 'audio'
T_real   = 0.05;       % s reales
fc_nom   = 10e6;       % portadora nominal [Hz]
escuchar = false;      % true: reproduce los audios recuperados (útil con modo 'audio')

P = params_sistema(fc_nom, struct('T_real', T_real, 'imprimir', false));
fuente = generar_fuentes(P, modo);
K = P.K;
fprintf('Portadora %.1f MHz -> LO %.1f MHz, FI %.1f MHz, imagen %.1f MHz\n', ...
    P.vista.fc_MHz, P.vista.fLO_MHz, P.vista.fFI_MHz, P.vista.fimagen_MHz);

%% 1) construir y simular
construir_modelo();
mdl = 'sistema_fdm_fm';
try
    set_param(mdl, 'SimulationMode', 'accelerator');
    tic; out = sim(mdl); fprintf('Simulación (modo acelerado): %.1f s\n', toc);
catch err_acc
    fprintf('Modo acelerado no disponible (%s). Se usa modo normal.\n', err_acc.message);
    set_param(mdl, 'SimulationMode', 'normal');
    tic; out = sim(mdl); fprintf('Simulación (modo normal): %.1f s\n', toc);
end

%% 2) comparación con la referencia
R = modelo_referencia(P, fuente.X);
fi_sim   = out.sim_fi(:).';
mhat_sim = out.sim_m_hat(:).';
Y_sim    = [out.sim_y1(:).'; out.sim_y2(:).'; out.sim_y3(:).'];
comparar = @(a, b) max(abs(a(1:min(numel(a),numel(b))) - b(1:min(numel(a),numel(b)))));
e_fi = comparar(fi_sim, R.fi);
e_mh = comparar(mhat_sim, R.m_hat);
fprintf('\nError máximo vs referencia:  FI %.3g | multiplex demodulado %.3g | audios %.3g %.3g %.3g\n', ...
    e_fi, e_mh, comparar(Y_sim(1,:), R.Y(1,:)), comparar(Y_sim(2,:), R.Y(2,:)), comparar(Y_sim(3,:), R.Y(3,:)));
if e_fi > 1e-6
    n1 = min(numel(fi_sim), 2e5);
    [e2, d2] = mejor_desfase(fi_sim(1:n1), R.fi(1:n1), 30);
    fprintf('  FI coincide con error %.3g desplazada %d muestras de fs_fi -> revisar P.rt_dec\n', e2, d2);
elseif e_mh > 1e-6
    [e2, d2] = mejor_desfase(mhat_sim, R.m_hat, 30);
    fprintf('  Multiplex coincide con error %.3g desplazado %d muestras de fs_m -> revisar P.rt_dec\n', e2, d2);
end

%% 3) calidad de los audios recuperados (lo que importa)
fprintf('\nAudios recuperados por Simulink (canal ideal):\n');
for k = 1:3
    n = min(fuente.Na, size(Y_sim,2));
    [sdr, g] = comparar_senales(fuente.X(k,1:n), Y_sim(k,1:n), P.retardo_audio(k), P.fs_a);
    fprintf('  audio %d: SDR = %5.1f dB, ganancia = %.3f\n', k, sdr, 1/g);
end

%% 4) gráficas
figure('Name', 'Etapa 5: receptor superheterodino', 'Color', 'w');
subplot(2,2,1);
[f, S] = graficar_espectro(out.sim_mezcla(:).', P.fs_rf, K, struct('nfft', 2^15));
plot(f/1e6, S); grid on; ylim([-100 5]); xlim([0 P.fs_rf/2*K/1e6]);
hold on;
plot(P.f_FI*K/1e6*[1 1], [-100 5], 'r--'); plot(P.f_suma*K/1e6*[1 1], [-100 5], 'm--');
xlabel('f nominal [MHz]'); ylabel('DEP [dB]');
title(sprintf('Salida del mezclador: FI %.1f MHz y suma %.1f MHz', P.f_FI*K/1e6, P.f_suma*K/1e6));
legend('espectro', 'f_{FI}', 'f_c + f_{LO}', 'Location', 'northeast');

subplot(2,2,2);
[f, S] = graficar_espectro(fi_sim, P.fs_fi, K, struct('nfft', 2^14));
plot(f/1e6, S); grid on; ylim([-100 5]); hold on;
banda = (P.f_FI + [-1 1]*P.HW) * K / 1e6;
plot(banda(1)*[1 1], [-100 5], 'r--', banda(2)*[1 1], [-100 5], 'r--');
xlabel('f nominal [MHz]'); ylabel('DEP [dB]');
title('Sección de FI (tras el pasabanda), paso 1.35-2.05 MHz');

subplot(2,2,[3 4]); hold on;
[f, S1] = graficar_espectro(R.m_n * P.normalizacion, P.fs_m, K, struct('nfft', 4096));
[~, S2] = graficar_espectro(mhat_sim, P.fs_m, K, struct('nfft', 4096));
plot(f/1e3, S1, 'Color', [0.6 0.6 0.6], 'LineWidth', 2); plot(f/1e3, S2, 'k');
grid on; ylim([-90 5]); xlim([0 P.fs_m/2*K/1e3]);
xlabel('f nominal [kHz]'); ylabel('DEP [dB]');
legend('multiplex transmitido', 'multiplex recuperado (salida del demodulador FM)');
title('Recuperación del multiplex FDM');

figure('Name', 'Etapa 6: audios recuperados', 'Color', 'w');
t_real = (0:fuente.Na-1) / P.fs_a / K * 1e3;           % ms reales
ventana = t_real >= 20 & t_real <= 23;                  % 3 ms, lejos del transitorio inicial
for k = 1:3
    subplot(3,1,k);
    t_y = t_real - P.retardo_audio(k) / K * 1e3;       % se descuenta el retardo del sistema
    plot(t_real(ventana), fuente.X(k, ventana), 'Color', [0.6 0.6 0.6], 'LineWidth', 2); hold on;
    vy = t_y >= 20 & t_y <= 23;
    plot(t_y(vy), Y_sim(k, vy), 'k');
    grid on; ylabel(sprintf('audio %d', k)); xlim([20 23]);
end
xlabel('tiempo real [ms]');
subplot(3,1,1); legend('original', 'recuperado (retardo descontado)');

if escuchar
    for k = 1:3
        fprintf('Reproduciendo audio %d recuperado...\n', k);
        y = Y_sim(k,:) / max(abs(Y_sim(k,:)));
        sound(y, P.fs_audio_real); pause(numel(y)/P.fs_audio_real + 0.5);
    end
end

function [e_min, d_min] = mejor_desfase(y, x, dmax)
    N = min(numel(x), numel(y)); e_min = inf; d_min = 0;
    for d = -dmax:dmax
        i1 = max(1, 1+d):min(N, N+d);
        e = max(abs(y(i1) - x(i1 - d)));
        if e < e_min, e_min = e; d_min = d; end
    end
end
