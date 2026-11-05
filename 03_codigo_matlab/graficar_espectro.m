function [f_nom, PdB] = graficar_espectro(x, fs, K, opciones)
%GRAFICAR_ESPECTRO  Densidad espectral promediada (método de Welch propio, sin toolboxes).
%   graficar_espectro(x, fs, K)            grafica contra frecuencia NOMINAL (f*K) en kHz
%   [f_nom, PdB] = graficar_espectro(...)  devuelve los datos sin graficar si se piden salidas
%   opciones.nfft     longitud de cada segmento (por defecto 4096)
%   opciones.unilado  true = solo frecuencias positivas (por defecto true)
%   opciones.normalizar true = 0 dB en el máximo (por defecto true)
%   Ventana de Hann y 50 % de solapamiento.
    if nargin < 4, opciones = struct(); end
    nfft = campo(opciones, 'nfft', 4096);
    unilado = campo(opciones, 'unilado', true);
    normalizar = campo(opciones, 'normalizar', true);

    x = x(:).';
    nfft = min(nfft, 2^floor(log2(numel(x))));
    w = 0.5 - 0.5*cos(2*pi*(0:nfft-1)/(nfft-1));         % ventana de Hann
    paso = nfft/2;
    nseg = floor((numel(x) - nfft)/paso) + 1;
    S = zeros(1, nfft);
    for i = 1:nseg
        seg = x((i-1)*paso + (1:nfft));
        S = S + abs(fft((seg - mean(seg)) .* w)).^2;
    end
    S = S / (nseg * fs * sum(w.^2));                     % densidad [unidades^2/Hz]
    if unilado
        S = S(1:nfft/2+1);  S(2:end-1) = 2*S(2:end-1);
        f = (0:nfft/2) * fs / nfft;
    else
        S = fftshift(S);
        f = (-nfft/2:nfft/2-1) * fs / nfft;
    end
    PdB = 10*log10(S + eps);
    if normalizar, PdB = PdB - max(PdB); end
    f_nom = f * K;
    if nargout == 0
        plot(f_nom/1e3, PdB); grid on;
        xlabel('f nominal [kHz]'); ylabel('DEP [dB]');
    end
end

function v = campo(s, n, d)
    if isfield(s, n), v = s.(n); else, v = d; end
end
