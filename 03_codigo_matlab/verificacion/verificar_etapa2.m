% Simula el transmisor FDM en Simulink y lo compara con el modelo de referencia.
%   Ejecutar desde la carpeta del proyecto:  >> verificar_etapa2
%   UBICACIÓN: carpeta verificacion/. Se ejecuta desde 03_codigo_matlab con:
%       >> addpath verificacion
%   Son pruebas internas del equipo: no forman parte del entregable.
%   1) Calcula parámetros y fuentes, (re)construye sistema_fdm_fm.slx y lo simula.
%   2) Compara el multiplex m_n de Simulink con el de modelo_referencia.m (mismas fuentes).
%   3) Grafica: audios en el tiempo, espectros de los audios y espectro del multiplex FDM
%      con las bandas y guardas del plan de frecuencias.
%   Cambie 'modo' a 'tonos', 'ruido' o 'audio' (archivos audios/audio1..3.wav a 48 kHz).

clear; clc; close all;
rng(1);
modo   = 'ruido';      % 'ruido' llena las bandas: mejor para ver el plan FDM
T_real = 0.1;          % segundos de audio real (= K*T_real segundos simulados)

P = params_sistema(10e6, struct('T_real', T_real, 'imprimir', false));
fuente = generar_fuentes(P, modo);

%% 1) construir y simular
construir_modelo();
tic;
out = sim('sistema_fdm_fm');
fprintf('Simulación Simulink: %.1f s\n', toc);
m_n_sim = out.sim_m_n(:).';

%% 2) comparación con la referencia en MATLAB
R = modelo_referencia(P, fuente.X);
N = min(numel(m_n_sim), numel(R.m_n));
err = max(abs(m_n_sim(1:N) - R.m_n(1:N)));
fprintf('Muestras del multiplex: Simulink %d, referencia %d\n', numel(m_n_sim), numel(R.m_n));
fprintf('Error máximo |m_n(Simulink) - m_n(referencia)| = %.3g\n', err);
if err <= 1e-6
    fprintf('  => Simulink y la referencia coinciden: transmisor FDM VERIFICADO.\n');
end
if err > 1e-6
    fprintf('  => NO coinciden: revisar el transmisor (filtros, Rate Transition y P.rt_retardo).\n');
end
fprintf('Pico |m_n| = %.3f (debe ser <= 1)\n', max(abs(m_n_sim)));
fprintf('Porcentaje de modulación (pico) = %.1f %%\n', 100*max(abs(m_n_sim)));

%% 3) gráficas
K = P.K;
% (a) audios en el tiempo (primeros 5 ms reales)
figure('Name', 'Etapa 1: audios', 'Color', 'w');
n5 = round(5e-3 * K * P.fs_a);
for k = 1:3
    subplot(3,1,k);
    plot(fuente.t(1:n5)/K*1e3, fuente.X(k,1:n5)); grid on;
    ylabel(sprintf('x_%d', k)); ylim([-1.1 1.1]);
end
xlabel('tiempo real [ms]  (= tiempo simulado / K)');

% (b) espectro de cada audio y (c) espectro del multiplex
figure('Name', 'Etapa 2: espectros FDM', 'Color', 'w');
subplot(2,1,1); hold on;
for k = 1:3
    [f, S] = graficar_espectro(fuente.X(k,:), P.fs_a, K, struct('nfft', 1024));
    plot(f/1e3, S);
end
grid on; xlabel('f nominal [kHz]'); ylabel('DEP [dB]'); ylim([-90 5]);
legend('audio 1', 'audio 2', 'audio 3'); title('Audios de entrada (banda base, \leq 15 kHz)');

subplot(2,1,2); hold on;
yl = [-90 5];
colores = [0.85 0.92 1; 0.88 1 0.88; 1 0.9 0.85];
for k = 1:3   % bandas asignadas f_k +/- 15 kHz
    b = (P.f_sc(k) + [-1 1]*P.Wa) * K / 1e3;
    patch([b(1) b(2) b(2) b(1)], [yl(1) yl(1) yl(2) yl(2)], colores(k,:), 'EdgeColor', 'none');
    text(mean(b), -50, sprintf('canal %d', k), 'HorizontalAlignment', 'center');
end
[f, S] = graficar_espectro(m_n_sim, P.fs_m, K, struct('nfft', 4096));
plot(f/1e3, S, 'k');
xline_simple(P.W*K/1e3, yl, 'W = 120 kHz');
grid on; xlim([0 P.fs_m/2*K/1e3]); ylim(yl);
xlabel('f nominal [kHz]'); ylabel('DEP [dB]');
title('Multiplex FDM m_n (Simulink): bandas 5-35 / 45-75 / 85-115 kHz, guardas de 10 kHz');

function [e_min, d_min] = mejor_desfase(y, x, dmax)
% Busca el retardo entero d (y(n) ~ x(n-d)) que minimiza el error máximo.
    N = min(numel(x), numel(y)); e_min = inf; d_min = 0;
    for d = -dmax:dmax
        i1 = max(1, 1+d):min(N, N+d);
        e = max(abs(y(i1) - x(i1 - d)));
        if e < e_min, e_min = e; d_min = d; end
    end
end

function xline_simple(x, yl, txt)
    plot([x x], yl, 'r--');
    text(x, yl(2) - 20, [' ' txt], 'Color', 'r');
end
