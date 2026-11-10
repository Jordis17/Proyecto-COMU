% Verificación de params_sistema.m y del modelo de referencia (MATLAB puro).
%   Ejecutar desde la carpeta del proyecto:  >> prueba_etapa0
%   UBICACIÓN: carpeta verificacion/. Se ejecuta desde 03_codigo_matlab con:
%       >> addpath verificacion
%   Son pruebas internas del equipo: no forman parte del entregable.
%   1) Imprime la tabla de parámetros y las comprobaciones automáticas.
%   2) Grafica la respuesta de todos los filtros (si hay pantalla).
%   3) Ejecuta la cadena completa con 3 audios de prueba (ruido limitado a 0.3-15 kHz nom)
%      para f_c = 9, 10 y 11 MHz, y mide SDR por canal y diafonía.
%   4) Repite a 10 MHz con AWGN para algunos valores de (SNR)_C.
%   No requiere toolboxes. Duración por defecto: 0.1 s reales (10 s simulados).

clear; clc;
rng(1);
T_real = 0.1;

%% 1) parámetros
P = params_sistema(10e6, struct('T_real', T_real));

%% 2) respuesta de los filtros
if usejava('desktop')   % solo si MATLAB tiene interfaz gráfica
    nombres = {'audio_tx','interp1','interp2a','interp2b','presel','fi_lpf','fi','iq','mux','post'};
    figure('Name','Filtros del sistema','Color','w');
    for i = 1:numel(nombres)
        subplot(4,4,i); graficar_filtro(P.h.(nombres{i}), P.fi_info.(nombres{i}).fs, P.K); title(nombres{i}, 'Interpreter', 'none');
    end
    for k = 1:3
        subplot(4,4,10+k); graficar_filtro(P.h.canal{k}, P.fs_m, P.K); title(sprintf('canal %d',k));
    end
end

%% 3) audios de prueba: ruido limitado en banda 0.3-15 kHz nom
Na = round(P.T_sim * P.fs_a);
h_src = disenar_fir_kaiser('bp', P.fs_a, [0 3 145 150], 60, 1);
X = zeros(3, Na);
for k = 1:3
    x = filter(h_src, 1, randn(1, Na + 400));  x = x(401:end);
    X(k,:) = x / max(abs(x));
end

fprintf('--- Canal ideal ---\n');
for fc_nom = [9e6 10e6 11e6]
    Pc = params_sistema(fc_nom, struct('imprimir', false, 'T_real', T_real));
    tic; R = modelo_referencia(Pc, X); t = toc;
    fprintf('f_c = %4.1f MHz (LO %4.1f MHz): SDR = ', fc_nom/1e6, Pc.vista.fLO_MHz);
    for k = 1:3
        [s, g] = comparar_senales(X(k,:), R.Y(k,:), Pc.retardo_audio(k), Pc.fs_a);
        fprintf('%5.1f dB (g=%.3f)  ', s, g);
    end
    fprintf('[%.1f s]\n', t);
end

% diafonía: solo el canal 2 activo
X2 = X; X2([1 3],:) = 0;
R2 = modelo_referencia(P, X2);
e = round(0.15*Na); idx = e+1:Na-e;
p2 = mean(R2.Y(2,idx).^2);
fprintf('Diafonía canal 2 -> 1: %.1f dB,  2 -> 3: %.1f dB\n', ...
    10*log10(mean(R2.Y(1,idx).^2)/p2), 10*log10(mean(R2.Y(3,idx).^2)/p2));

% efecto de NO compensar el retardo de las subportadoras
Pn = P; Pn.fase_rx = [0 0 0];
Rn = modelo_referencia(Pn, X);
fprintf('Sin compensar tau_k, ganancia medida: ');
for k = 1:3
    [~, g] = comparar_senales(X(k,:), Rn.Y(k,:), P.retardo_audio(k), P.fs_a);
    fprintf('%+.2f  ', 1/g);
end
fprintf('(teoría: %+.2f %+.2f %+.2f)\n', P.ganancia_sin_compensar);

%% 4) AWGN
fprintf('--- AWGN a 10 MHz ---\n');
Px = mean(X.^2, 2).';
for snr_c = [35 25 20 17]
    Pa = params_sistema(10e6, struct('imprimir', false, 'T_real', T_real, 'snr_c_dB', snr_c));
    Ra = modelo_referencia(Pa, X);
    fprintf('(SNR)_C = %2d dB (CNR_BT %4.1f dB): ', snr_c, Pa.cnr_BT_dB);
    for k = 1:3
        s = comparar_senales(X(k,:), Ra.Y(k,:), Pa.retardo_audio(k), Pa.fs_a);
        teo = snr_c + 10*log10(Pa.W*Pa.df^2*Px(k) / (18*Pa.Wa*(Pa.f_sc(k)^2 + Pa.Wa^2/3)));
        fprintf('c%d %5.1f (teo %5.1f)  ', k, s, teo);
    end
    fprintf('\n');
end
