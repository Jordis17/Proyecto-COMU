function fuente = generar_fuentes(P, modo, carpeta_audios)
% Crea las tres señales de audio y las prepara para Simulink.
%   fuente = generar_fuentes(P, modo)
%   modo:
%     'tonos'  : canal 1 = 1 kHz, canal 2 = 3 kHz, canal 3 = 7 kHz (nominales). Fáciles de
%                identificar en los espectros y para verificar la separación de canales.
%     'ruido'  : ruido limitado a 0.3-15 kHz nom (ocupa toda la banda; prueba exigente).
%     'demo'   : arpegio / sirena / pitidos: tres sonidos distintos para escuchar en la GUI.
%     'audio'  : archivos audio1.wav, audio2.wav y audio3.wav de la carpeta 'audios'
%                (o de carpeta_audios). Se pasan a mono, se llevan a 48 kHz y se normalizan.
%
%   Escalamiento del audio real: las muestras del archivo no se modifican. Solo se
%   declara su tiempo de muestreo como 1/P.fs_a (= K/48 kHz). Para escuchar el resultado se
%   reproduce a 48 kHz con sound(y, P.fs_audio_real), lo que deshace el escalamiento.
%
%   Salida (struct):
%     fuente.X       3 x Na, audios normalizados (|x| <= 1)
%     fuente.t       1 x Na, tiempo simulado de cada muestra
%     fuente.audio1  [t x1] para el bloque From Workspace (ídem audio2, audio3)
%     fuente.T_stop  tiempo de parada del modelo
%     fuente.modo
%   Solo MATLAB básico.

    if nargin < 2 || isempty(modo), modo = 'tonos'; end
    if nargin < 3 || isempty(carpeta_audios), carpeta_audios = 'audios'; end
    Na = round(P.T_sim * P.fs_a);
    t  = (0:Na-1) / P.fs_a;

    switch lower(modo)
        case 'tonos'
            f_tonos = [1e3 3e3 7e3] / P.K;                 % nominal -> simulado
            X = zeros(3, Na);
            for k = 1:3, X(k,:) = 0.9 * sin(2*pi*f_tonos(k)*t); end

        case 'demo'
            % tres sonidos distintos y fáciles de reconocer al oído (frecuencias nominales):
            %   audio 1: arpegio Do-Mi-Sol-Do (523, 659, 784, 1047 Hz), notas de 0.1 s
            %   audio 2: sirena, barrido senoidal entre 600 Hz y 2.4 kHz, 3 veces por segundo
            %   audio 3: pitidos de 3 kHz de 50 ms, cada 150 ms (estilo Morse)
            tr = t / P.K;                                   % tiempo real [s]
            notas = [523.25 659.25 783.99 1046.5];
            idx = mod(floor(tr / 0.1), 4) + 1;
            fase1 = 2*pi*cumsum(notas(idx)) / P.fs_audio_real;
            f2 = 1500 + 900*sin(2*pi*3*tr);
            fase2 = 2*pi*cumsum(f2) / P.fs_audio_real;
            pulso = mod(tr, 0.15) < 0.05;
            X = [sin(fase1); sin(fase2); pulso .* sin(2*pi*3000*tr)];

        case 'ruido'
            h = disenar_fir_kaiser('bp', P.fs_a, [0 3 145 150], 60, 1);
            X = zeros(3, Na);
            for k = 1:3
                x = filter(h, 1, randn(1, Na + 400));  x = x(401:end);
                X(k,:) = x;
            end

        case 'audio'
            X = zeros(3, Na);
            for k = 1:3
                archivo = fullfile(carpeta_audios, sprintf('audio%d.wav', k));
                assert(exist(archivo, 'file') == 2, 'No se encontró %s', archivo);
                [x, fs_arch] = audioread(archivo);
                x = mean(x, 2).';                              % a mono
                x = a_48kHz(x, fs_arch, P);
                x = quitar_silencio_inicial(x, P.fs_audio_real);
                n = min(Na, numel(x));
                X(k, 1:n) = x(1:n);                            % se recorta a la duración pedida
            end
        otherwise
            error('modo debe ser ''tonos'', ''demo'', ''ruido'' o ''audio''');
    end

    % normalización a pico 1 (cada audio por separado)
    for k = 1:3
        pk = max(abs(X(k,:)));
        if pk > 0, X(k,:) = X(k,:) / pk; end
    end

    fuente.X = X;
    fuente.t = t;
    % Tiempos para el bloque From Workspace (interpolación apagada = retención):
    % se adelantan 1/4 de muestra para que, en el instante n*Ts, el bloque tome siempre
    % la muestra n y no la anterior por errores de redondeo en el tiempo de simulación.
    t_fw = max(0, ((0:Na-1) - 0.25) / P.fs_a);
    fuente.audio1 = [t_fw(:) X(1,:).'];
    fuente.audio2 = [t_fw(:) X(2,:).'];
    fuente.audio3 = [t_fw(:) X(3,:).'];
    fuente.Na = Na;
    fuente.T_stop = (Na * P.L1 - 1) / P.fs_m;   % cubre las Na muestras de audio
    fuente.modo = lower(modo);
end

function x = quitar_silencio_inicial(x, fs)
% Quita el silencio del inicio de una grabación: empieza 10 ms antes de la primera muestra
% que pasa del 5 % del pico. Así la radio, que usa solo los primeros segundos, oye el sonido.
    i0 = find(abs(x) > 0.05 * max(abs(x)), 1);
    if isempty(i0), return; end
    x = x(max(1, i0 - round(0.01 * fs)):end);
end

function y = a_48kHz(x, fs_arch, P)
% Lleva el audio a 48 kHz reales. Primero limita a 15 kHz (para no crear aliasing)
% y luego, si hace falta, interpola con spline (MATLAB básico, sin resample).
    fs_obj = P.fs_audio_real;
    if fs_arch ~= fs_obj
        warning('audio a %g Hz: se convierte a 48 kHz con interpolación spline. Mejor exportar los WAV a 48 kHz.', fs_arch);
        if fs_arch > 2*16e3
            h = disenar_fir_kaiser('lp', fs_arch, [15e3 min(17e3, fs_arch/2)], 60, 1);
            x = filter(h, 1, [x zeros(1, (numel(h)-1)/2)]);
            x = x((numel(h)-1)/2 + 1:end);
        end
        t_in  = (0:numel(x)-1) / fs_arch;
        t_out = 0:1/fs_obj:t_in(end);
        y = interp1(t_in, x, t_out, 'spline');
    else
        y = x;
    end
end
