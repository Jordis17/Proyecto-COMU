% Simula el sistema con canal ideal y genera las gráficas de cada etapa.
%   Ejecutar desde esta carpeta:  >> graficas_sistema
%
%   Figuras (son la evidencia que pide el enunciado):
%     1) Audios de entrada: tiempo y espectro (<= 15 kHz).
%     2) Multiplex FDM: espectro con las tres bandas y las guardas (enunciado §4.2).
%     3) Señal FM: espectro RF, ancho medido frente a Carson, desviación (enunciado §4.3).
%     4) Receptor: salida del mezclador (FI y producto suma), FI filtrada y multiplex
%        recuperado frente al transmitido (enunciado §4.5).
%     5) Audios originales frente a recuperados, con su SDR (enunciado §6).
%   Las figuras se guardan solas en PNG en la carpeta 'figuras' (fig1_audios.png, ...).
%   Cambie fc_nom (de 9 a 11 MHz) o modo ('ruido', 'tonos', 'demo', 'audio').
%   Tarda alrededor de 1 minuto (0.05 s de audio real).

clear; clc; close all;
rng(1);
fc_nom = 10e6;        % portadora nominal [Hz]
modo   = 'ruido';     % 'ruido' llena toda la banda de cada audio: se ve mejor el plan FDM
T_real = 0.05;        % segundos de audio real

P = params_sistema(fc_nom, struct('T_real', T_real));
fuente = generar_fuentes(P, modo);
K = P.K;
mdl = 'sistema_fdm_fm';
if exist('modelo_al_dia', 'file'), modelo_al_dia(mdl); end
load_system(mdl);
try
    set_param(mdl, 'SimulationMode', 'accelerator');
    out = sim(mdl);
catch
    set_param(mdl, 'SimulationMode', 'normal');
    out = sim(mdl);
end
yl = [-100 5];

%% 1) audios de entrada
figure('Name', '1. Audios de entrada', 'Color', 'w');
n5 = round(5e-3 * K * P.fs_a);                          % primeros 5 ms reales
for k = 1:3
    subplot(4,1,k);
    plot(fuente.t(1:n5)/K*1e3, fuente.X(k,1:n5)); grid on;
    ylabel(sprintf('x_%d', k)); ylim([-1.1 1.1]);
end
xlabel('tiempo real [ms]');
subplot(4,1,4); hold on;
for k = 1:3
    [f, S] = graficar_espectro(fuente.X(k,:), P.fs_a, K, struct('nfft', 1024));
    plot(f/1e3, S);
end
grid on; ylim([-90 5]); xlabel('f [kHz]'); ylabel('DEP [dB]');
legend('audio 1', 'audio 2', 'audio 3'); title('Espectro de los audios (hasta 15 kHz)');

%% 2) multiplex FDM
figure('Name', '2. Multiplex FDM', 'Color', 'w'); hold on;
colores = [0.85 0.92 1; 0.88 1 0.88; 1 0.9 0.85];
for k = 1:3
    b = (P.f_sc(k) + [-1 1]*P.Wa) * K / 1e3;
    patch([b(1) b(2) b(2) b(1)], [yl(1) yl(1) yl(2) yl(2)], colores(k,:), 'EdgeColor', 'none');
    text(mean(b), -60, sprintf('canal %d', k), 'HorizontalAlignment', 'center');
end
[f, S] = graficar_espectro(out.sim_m(:).', P.fs_m, K, struct('nfft', 4096));
plot(f/1e3, S, 'k');
plot(P.W*K/1e3*[1 1], yl, 'r--');
grid on; xlim([0 P.fs_m/2*K/1e3]); ylim(yl);
xlabel('f [kHz]'); ylabel('DEP [dB]');
title('Multiplex FDM: bandas 5-35 / 45-75 / 85-115 kHz, guardas de 10 kHz, límite de 120 kHz');

%% 3) señal FM
s = out.sim_s(:).';
[f, S] = graficar_espectro(s, P.fs_rf, K, struct('nfft', 2^16, 'normalizar', false));
Plin = 10.^(S/10);
cerca = abs(f - P.fc*K) <= 2e6;                         % +-2 MHz alrededor de la portadora
total = sum(Plin(cerca));
paso_f = f(2) - f(1);
for mitad = 0:paso_f:2e6                                % ancho que contiene el 99 % de la potencia
    if sum(Plin(abs(f - P.fc*K) <= mitad)) >= 0.99 * total, break; end
end
BW99 = 2 * mitad;
desv = max(abs(P.kf * out.sim_m_rf(:)));                % desviación pico real [Hz simulados]

figure('Name', '3. Señal FM', 'Color', 'w');
subplot(2,1,1);
plot(f/1e6, S - max(S)); grid on; ylim(yl); xlim([0 P.fs_rf/2*K/1e6]);
xlabel('f [MHz]'); ylabel('DEP [dB]');
title(sprintf('Espectro RF: portadora FM en %.1f MHz', P.vista.fc_MHz));
subplot(2,1,2); hold on;
fz = (f - P.fc*K)/1e3;  z = abs(fz) <= 1000;
plot(fz(z), S(z) - max(S), 'k');
plot(P.B_carson/2*K/1e3*[-1 -1], yl, 'b--', P.B_carson/2*K/1e3*[1 1], yl, 'b--');
plot(BW99/2/1e3*[-1 -1], yl, 'm:', BW99/2/1e3*[1 1], yl, 'm:');
grid on; ylim(yl); xlabel('f - f_c [kHz]'); ylabel('DEP [dB]');
legend('espectro', 'Carson', '', '99 % de la potencia', '', 'Location', 'south');
title(sprintf('Carson = %.0f kHz, medido (99 %%) = %.0f kHz', P.B_carson*K/1e3, BW99/1e3));

%% 4) receptor superheterodino
figure('Name', '4. Receptor superheterodino', 'Color', 'w');
subplot(2,2,1);
[f, S] = graficar_espectro(out.sim_mezcla(:).', P.fs_rf, K, struct('nfft', 2^15));
plot(f/1e6, S); grid on; ylim(yl); xlim([0 P.fs_rf/2*K/1e6]); hold on;
plot(P.f_FI*K/1e6*[1 1], yl, 'r--'); plot(P.f_suma*K/1e6*[1 1], yl, 'm--');
xlabel('f [MHz]'); ylabel('DEP [dB]');
title(sprintf('Mezclador (LO = %.1f MHz): FI y producto suma', P.vista.fLO_MHz));
legend('espectro', 'f_{FI} = 1.7 MHz', 'f_c + f_{LO}', 'Location', 'northeast');
subplot(2,2,2);
[f, S] = graficar_espectro(out.sim_fi(:).', P.fs_fi, K, struct('nfft', 2^14));
plot(f/1e6, S); grid on; ylim(yl); hold on;
banda = (P.f_FI + [-1 1]*P.HW) * K / 1e6;
plot(banda(1)*[1 1], yl, 'r--', banda(2)*[1 1], yl, 'r--');
xlabel('f [MHz]'); ylabel('DEP [dB]'); title('FI filtrada (paso de 1.35 a 2.05 MHz)');
subplot(2,2,[3 4]); hold on;
[f, S1] = graficar_espectro(out.sim_m(:).', P.fs_m, K, struct('nfft', 4096));
[~, S2] = graficar_espectro(out.sim_m_hat(:).', P.fs_m, K, struct('nfft', 4096));
plot(f/1e3, S1, 'Color', [0.6 0.6 0.6], 'LineWidth', 2); plot(f/1e3, S2, 'k');
grid on; ylim([-90 5]); xlim([0 P.fs_m/2*K/1e3]);
xlabel('f [kHz]'); ylabel('DEP [dB]');
legend('multiplex transmitido', 'multiplex recuperado'); title('Multiplex a la salida del demodulador FM');

%% 5) audios originales frente a recuperados
figure('Name', '5. Audios recuperados', 'Color', 'w');
t_real = (0:fuente.Na-1) / P.fs_a / K * 1e3;            % ms reales
fprintf('\nResultados (canal ideal, f_c = %.1f MHz):\n', P.vista.fc_MHz);
fprintf('  Desviación pico usada: %.1f kHz de %.0f kHz (%.0f %%)\n', desv*K/1e3, P.df*K/1e3, 100*desv/P.df);
fprintf('  Ancho de la FM: Carson = %.0f kHz, medido (99 %% de la potencia) = %.0f kHz\n', P.B_carson*K/1e3, BW99/1e3);
for k = 1:3
    y = out.(sprintf('sim_y%d', k))(:).';
    n = min(numel(y), fuente.Na);
    [sdr, g] = comparar_senales(fuente.X(k,1:n), y(1:n), P.retardo_audio(k), P.fs_a);
    fprintf('  Audio %d: SDR = %5.1f dB, ganancia = %.3f\n', k, sdr, 1/g);
    subplot(3,1,k);
    t_y = t_real(1:n) - P.retardo_audio(k) / K * 1e3;   % se descuenta el retardo del sistema
    v = t_real >= 20 & t_real <= 23;  vy = t_y >= 20 & t_y <= 23;
    plot(t_real(v), fuente.X(k, v), 'Color', [0.6 0.6 0.6], 'LineWidth', 2); hold on;
    plot(t_y(vy), y(vy), 'k'); grid on; xlim([20 23]);
    ylabel(sprintf('audio %d', k)); title(sprintf('Audio %d: SDR = %.1f dB', k, sdr));
end
xlabel('tiempo real [ms]');
subplot(3,1,1); legend('original', 'recuperado');
set_param(mdl, 'SimulationMode', 'normal');

%% guardar las figuras en PNG
if ~exist('figuras', 'dir'), mkdir('figuras'); end
nombres = {'fig1_audios', 'fig2_multiplex', 'fig3_senal_fm', 'fig4_receptor', 'fig5_audios_recuperados'};
for k = 1:numel(nombres)
    f = findobj('Type', 'figure', '-regexp', 'Name', sprintf('^%d\\.', k));
    if isempty(f), continue; end
    set(f(1), 'Position', [100 100 1100 650]);
    try
        exportgraphics(f(1), fullfile('figuras', [nombres{k} '.png']), 'Resolution', 150);
    catch
        saveas(f(1), fullfile('figuras', [nombres{k} '.png']));
    end
end
fprintf('Figuras guardadas en la carpeta figuras (fig1 a fig5, PNG).\n');
