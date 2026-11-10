function [h, info] = disenar_fir_kaiser(tipo, fs, bordes, A_dB, ganancia)
% Diseña un filtro FIR de fase lineal por el método de ventana de Kaiser.
%   Solo usa funciones de MATLAB básico (no requiere Signal Processing Toolbox).
%
%   [h, info] = disenar_fir_kaiser('lp', fs, [fp fst], A_dB, ganancia)
%   [h, info] = disenar_fir_kaiser('bp', fs, [fst1 fp1 fp2 fst2], A_dB, ganancia)
%
%   tipo     : 'lp' (pasabajos) o 'bp' (pasabanda)
%   fs       : frecuencia de muestreo de la etapa donde se usa el filtro [Hz]
%   bordes   : bordes de paso y rechazo [Hz]
%   A_dB     : atenuación mínima pedida en la banda de rechazo [dB] (por defecto 60)
%   ganancia : ganancia en la banda de paso (por defecto 1; en interpoladores = L)
%
%   Método (ventana de Kaiser):
%     1) beta = 0.1102 (A - 8.7)                    si A > 50
%     2) orden M = (A - 7.95) / (2.285 * dw),  dw = 2*pi*Δf/fs   (Δf = ancho de transición)
%     3) h_d[n] = respuesta ideal (sinc) desplazada M/2 muestras
%     4) h[n]   = h_d[n] * w_Kaiser[n]
%   El filtro tiene N = M+1 coeficientes (N impar) y retardo de grupo (N-1)/2 muestras.
%   Si la atenuación medida no alcanza A_dB, se aumenta el orden y se repite.

    if nargin < 4 || isempty(A_dB),     A_dB = 60;     end
    if nargin < 5 || isempty(ganancia), ganancia = 1;  end
    bordes = bordes(:).';

    switch lower(tipo)
        case 'lp'
            assert(numel(bordes) == 2 && bordes(1) < bordes(2) && bordes(2) <= fs/2, ...
                'LP: bordes = [fp fst] con fp < fst <= fs/2');
            df_t = bordes(2) - bordes(1);
            fcorte = mean(bordes);
        case 'bp'
            assert(numel(bordes) == 4 && all(diff(bordes) > 0) && bordes(4) <= fs/2 && bordes(1) >= 0, ...
                'BP: bordes = [fst1 fp1 fp2 fst2] crecientes, fst2 <= fs/2');
            df_t = min(bordes(2) - bordes(1), bordes(4) - bordes(3));
            fc1 = (bordes(1) + bordes(2)) / 2;
            fc2 = (bordes(3) + bordes(4)) / 2;
        otherwise
            error('tipo debe ser ''lp'' o ''bp''');
    end

    % --- 1) parámetro beta de Kaiser
    if A_dB > 50
        beta = 0.1102 * (A_dB - 8.7);
    elseif A_dB >= 21
        beta = 0.5842 * (A_dB - 21)^0.4 + 0.07886 * (A_dB - 21);
    else
        beta = 0;
    end

    % --- 2) orden estimado (se fuerza par -> N impar, retardo entero)
    dw = 2 * pi * df_t / fs;
    M  = ceil((A_dB - 7.95) / (2.285 * dw));
    if mod(M, 2) == 1, M = M + 1; end

    for intento = 1:30
        n = 0:M;
        w = besseli(0, beta * sqrt(1 - (2 * n / M - 1).^2)) / besseli(0, beta);
        m = n - M / 2;
        switch lower(tipo)
            case 'lp'
                hd = lp_ideal(fcorte, fs, m);
            case 'bp'
                hd = lp_ideal(fc2, fs, m) - lp_ideal(fc1, fs, m);
        end
        h = hd .* w;

        % normalización de ganancia en la banda de paso
        switch lower(tipo)
            case 'lp', f0 = 0;
            case 'bp', f0 = (bordes(2) + bordes(3)) / 2;
        end
        H0 = abs(sum(h .* exp(-1j * 2 * pi * f0 / fs * n)));
        h  = h * ganancia / H0;

        info = medir_respuesta(h, fs, tipo, bordes, ganancia);
        if info.A_medida_dB >= A_dB - 0.5
            break;
        end
        M = M + 2;   % no alcanzó la atenuación: subir el orden
    end

    info.tipo = lower(tipo);
    info.fs = fs;
    info.bordes = bordes;
    info.A_pedida_dB = A_dB;
    info.beta = beta;
    info.N = numel(h);
    info.retardo_muestras = (numel(h) - 1) / 2;
    info.retardo_s = info.retardo_muestras / fs;
    info.ganancia = ganancia;
end

% -------------------------------------------------------------------------
function hd = lp_ideal(fc, fs, m)
% Respuesta impulsional ideal de un pasabajos con corte fc (sinc), sin toolbox.
    x  = 2 * fc / fs * m;
    hd = 2 * fc / fs * ones(size(m));
    k  = (x ~= 0);
    hd(k) = 2 * fc / fs * sin(pi * x(k)) ./ (pi * x(k));
end

function info = medir_respuesta(h, fs, tipo, b, g)
% Evalúa |H(f)| en una rejilla para verificar paso y rechazo (sin freqz).
    f = linspace(0, fs/2, 3000);
    n = 0:numel(h) - 1;
    H = abs(exp(-1j * 2 * pi * f(:) / fs * n) * h(:)).';
    switch tipo
        case 'lp'
            paso = f <= b(1);
            rech = f >= b(2);
        case 'bp'
            paso = f >= b(2) & f <= b(3);
            rech = f <= b(1) | f >= b(4);
    end
    info.rizado_paso_dB = 20 * log10(max(H(paso)) / min(H(paso)));
    info.A_medida_dB    = -20 * log10(max(H(rech)) / g);
end
