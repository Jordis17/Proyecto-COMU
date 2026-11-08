%PROBAR_AUDIO_REAL  Pasa tres audios reales por el sistema y guarda los audios recuperados.
%   Ejecutar desde esta carpeta:  >> probar_audio_real
%
%   Antes: copiar tres archivos WAV en la carpeta 'audios':
%       audios/audio1.wav, audios/audio2.wav, audios/audio3.wav
%   De preferencia a 48 kHz (si no, se convierten), mono o estéreo (se pasan a mono), y que el
%   sonido empiece desde el inicio del archivo (sin silencio al principio).
%
%   Resultado: audios/recuperado1.wav ... recuperado3.wav (y los originales normalizados
%   original1..3.wav), para escucharlos o usarlos en el video sin tener que esperar.
%   Duración: unos 2.5 minutos de simulación por cada segundo de audio (modo acelerado;
%   2 s tardaron 283 s en la computadora donde se probó).

clear; clc;
T_real   = 2;          % segundos de audio (2 s alcanzan para reconocer cada audio)
fc_nom   = 10e6;       % portadora nominal [Hz]
snr_c    = Inf;        % Inf = canal ideal; por ejemplo 25 para escuchar el efecto del ruido
enfasis  = false;      % true = con prénfasis/deénfasis
escuchar = true;       % reproduce cada audio recuperado al terminar

% log_rf_max: solo se guardan las últimas muestras de RF (si no, la memoria sube a varios GB)
P = params_sistema(fc_nom, struct('T_real', T_real, 'snr_c_dB', snr_c, 'enfasis', enfasis, ...
    'log_rf_max', 2^18, 'imprimir', false));
fuente = generar_fuentes(P, 'audio');
mdl = 'sistema_fdm_fm';
if exist('modelo_al_dia', 'file'), modelo_al_dia(mdl); end
load_system(mdl);
fprintf('Simulando %.1f s de audio real (unos %.0f min)...\n', T_real, 2.5*T_real);
try
    set_param(mdl, 'SimulationMode', 'accelerator');
    tic; out = sim(mdl);
catch
    set_param(mdl, 'SimulationMode', 'normal');
    tic; out = sim(mdl);
end
fprintf('Listo en %.0f s.\n', toc);

fs = P.fs_audio_real;                                   % 48 kHz: deshace el escalamiento
for k = 1:3
    x = fuente.X(k,:);
    y = out.(sprintf('sim_y%d', k))(:).';
    n = min(numel(x), numel(y));
    sdr = comparar_senales(x(1:n), y(1:n), P.retardo_audio(k), P.fs_a);
    fprintf('Audio %d: SDR = %.1f dB\n', k, sdr);
    y = y(round(P.retardo_audio(k) * P.fs_a)+1:end);   % sin el retardo ni el chasquido de arranque
    y = 0.9 * y / max(abs(y));                          % se normaliza solo para escucharlo
    audiowrite(fullfile('audios', sprintf('original%d.wav', k)), 0.9 * x, fs);
    audiowrite(fullfile('audios', sprintf('recuperado%d.wav', k)), y, fs);
    if escuchar
        fprintf('  reproduciendo audio %d recuperado...\n', k);
        sound(y, fs);  pause(numel(y)/fs + 0.5);
    end
end
fprintf('Guardado en la carpeta audios: original1..3.wav y recuperado1..3.wav\n');
set_param(mdl, 'SimulationMode', 'normal');
