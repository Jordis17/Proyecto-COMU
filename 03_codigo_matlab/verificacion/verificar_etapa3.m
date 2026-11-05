%VERIFICAR_ETAPA3  Interpolación x100 + modulador FM en Simulink, contra la referencia.
%   Ejecutar desde la carpeta del proyecto:  >> verificar_etapa3
%   UBICACIÓN: carpeta verificacion/. Se ejecuta desde 03_codigo_matlab con:
%       >> addpath verificacion
%   Son pruebas internas del equipo: no forman parte del entregable.
%   1) Simula el modelo (fuentes + FDM + FM) y compara m_rf y s_FM con modelo_referencia.m.
%   2) Mide la desviación pico real y el ancho de banda de la FM (98 / 99 / 99.9 % de la
%      potencia) y lo compara con Carson y con Bessel [doc §6.4].
%   3) Grafica: espectro RF completo, zoom alrededor de f_c con Carson/Bessel/paso FI,
%      y la frecuencia instantánea f_i(t) = f_c + kf * m_n(t).

clear; clc; close all;
rng(1);
modo   = 'ruido';
T_real = 0.05;                     % 0.05 s reales = 5 s simulados = 2.4 M muestras RF

P = params_sistema(10e6, struct('T_real', T_real, 'imprimir', false));
fuente = generar_fuentes(P, modo);
K = P.K;

%% 1) construir, simular y comparar
construir_modelo();
mdl = 'sistema_fdm_fm';
set_param(mdl, 'SimulationMode', 'normal');
tic; out = sim(mdl); t_normal = toc;
fprintf('Simulación en modo normal: %.1f s\n', t_normal);

% modo acelerado: Simulink compila el modelo a código C (la 1.ª vez incluye la compilación)
try
    set_param(mdl, 'SimulationMode', 'accelerator');
    tic; out_acc = sim(mdl); t1 = toc;
    tic; out_acc = sim(mdl); t2 = toc;
    fprintf('Modo acelerado: 1.ª corrida %.1f s (con compilación), 2.ª corrida %.1f s\n', t1, t2);
    fprintf('  Diferencia normal vs acelerado en s_FM: %.3g\n', max(abs(out_acc.sim_s(:) - out.sim_s(:))));
catch err_acc
    fprintf('Modo acelerado NO disponible en esta computadora: %s\n', err_acc.message);
end
set_param(mdl, 'SimulationMode', 'normal');
save_system(mdl);
s_sim   = out.sim_s(:).';
mrf_sim = out.sim_m_rf(:).';
R = modelo_referencia(P, fuente.X);

N = min(numel(s_sim), numel(R.s));
e_mrf = max(abs(mrf_sim(1:N) - R.m_rf(1:N)));
e_s   = max(abs(s_sim(1:N) - R.s(1:N)));
fprintf('Muestras RF: Simulink %d, referencia %d\n', numel(s_sim), numel(R.s));
fprintf('Error máximo m_rf (interpolación x100): %.3g\n', e_mrf);
fprintf('Error máximo s_FM  (modulador):          %.3g\n', e_s);
if e_mrf > 1e-6
    n1 = min(N, 2e5);   % basta un tramo para hallar el desfase
    [e2, d2] = mejor_desfase(mrf_sim(1:n1), R.m_rf(1:n1), 300);
    fprintf('  m_rf coincide con error %.3g si se desplaza %d muestras de fs_rf\n', e2, d2);
    fprintf('  (%d muestras = %.3g muestras de fs_m). Revisar P.rt_retardo.\n', d2, d2/P.L2);
end
if e_mrf <= 1e-6 && e_s <= 1e-6
    fprintf('  => Interpolación x100 y modulador FM VERIFICADOS (coinciden con la referencia).\n');
end

%% 2) desviación y ancho de banda
fi_inst = P.fc + P.kf * mrf_sim;                       % frecuencia instantánea [Hz sim]
dev_pico = max(abs(fi_inst - P.fc));
fprintf('\nDesviación pico real = %.1f kHz nom (máx. de diseño %.0f kHz) -> %.1f %% de modulación\n', ...
    dev_pico*K/1e3, P.df*K/1e3, 100*dev_pico/P.df);

nfft = 2^16;                                            % resolución = fs_rf/nfft = 0.73 kHz nom
[f_nom, S] = graficar_espectro(s_sim, P.fs_rf, K, struct('nfft', nfft, 'normalizar', false));
Plin = 10.^(S/10);
df_n = f_nom(2) - f_nom(1);
fc_n = P.fc*K;
sel = abs(f_nom - fc_n) <= 2e6;                         % ventana de +-2 MHz alrededor de f_c
tot = sum(Plin(sel));
anchos = [0.98 0.99 0.999];  BW = zeros(size(anchos));
for i = 1:numel(anchos)
    for half = 0:df_n:2e6
        if sum(Plin(abs(f_nom - fc_n) <= half)) >= anchos(i)*tot, BW(i) = 2*half; break; end
    end
end
fprintf('Ancho de banda medido: 98 %% = %.0f kHz, 99 %% = %.0f kHz, 99.9 %% = %.0f kHz\n', BW/1e3);
fprintf('Carson = %.0f kHz,  Bessel (n = %d) = %.0f kHz,  paso FI = %.0f kHz  (nominales)\n', ...
    P.B_carson*K/1e3, P.n_bessel, P.B_bessel*K/1e3, 2*P.HW*K/1e3);

%% 3) gráficas
figure('Name', 'Etapa 3: señal FM', 'Color', 'w');
subplot(2,2,[1 2]);
plot(f_nom/1e6, S - max(S)); grid on; ylim([-100 5]); xlim([0 P.fs_rf/2*K/1e6]);
xlabel('f nominal [MHz]'); ylabel('DEP [dB]');
title(sprintf('Espectro RF completo: portadora FM en %.1f MHz', P.vista.fc_MHz));

subplot(2,2,3); hold on;
fz = (f_nom - fc_n)/1e3;  z = abs(fz) <= 1000;
plot(fz(z), S(z) - max(S), 'k');
yl = [-100 5];
lineas = [P.B_carson/2, P.B_bessel/2, P.HW] * K / 1e3;
estilos = {'b--', 'm--', 'r-'};
nombres = {'Carson', 'Bessel', 'paso FI'};
for i = 1:3
    plot(lineas(i)*[1 1], yl, estilos{i}); plot(-lineas(i)*[1 1], yl, estilos{i}, 'HandleVisibility', 'off');
end
grid on; ylim(yl); xlabel('f - f_c  [kHz nominales]'); ylabel('DEP [dB]');
legend(['espectro' nombres], 'Location', 'south');
title('Zoom alrededor de f_c');

subplot(2,2,4);
% tramo de 1 ms real a partir de los 5 ms (los filtros ya se llenaron: el retardo
% de la cadena del transmisor es de ~0.8 ms reales)
i0 = round(5e-3 * K * P.fs_rf);  n_ms = round(1e-3 * K * P.fs_rf);
idx = i0 + (1:n_ms);
t_ms = (idx - 1) / P.fs_rf / K * 1e3;
plot(t_ms, (fi_inst(idx) - P.fc) * K / 1e3); grid on;
hold on; plot(t_ms([1 end]), P.df*K/1e3*[1 1], 'r--', t_ms([1 end]), -P.df*K/1e3*[1 1], 'r--');
xlabel('tiempo real [ms]'); ylabel('f_i - f_c [kHz]');
title('Frecuencia instantánea, límites \pm\Deltaf');

function [e_min, d_min] = mejor_desfase(y, x, dmax)
    N = min(numel(x), numel(y)); e_min = inf; d_min = 0;
    for d = -dmax:dmax
        i1 = max(1, 1+d):min(N, N+d);
        e = max(abs(y(i1) - x(i1 - d)));
        if e < e_min, e_min = e; d_min = d; end
    end
end
