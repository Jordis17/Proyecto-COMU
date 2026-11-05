function [sdr_dB, g] = comparar_senales(x, y, retardo_s, fs, borde)
%COMPARAR_SENALES  SDR entre el audio original x y el recuperado y, alineando retardo y ganancia.
%   [sdr_dB, g] = comparar_senales(x, y, retardo_s, fs, borde)
%   retardo_s : retardo conocido de y respecto a x [s] (puede ser fraccionario en muestras)
%   borde     : fracción descartada al inicio y al final (transitorios), por defecto 0.15
%   El retardo fraccionario se aplica a x en frecuencia (fft), sin toolboxes.
%   g es la ganancia de mínimos cuadrados que mejor ajusta y a x.
    if nargin < 5, borde = 0.15; end
    x = x(:).'; y = y(:).';
    N = numel(x);
    f = [0:floor(N/2), -ceil(N/2)+1:-1] * fs / N;
    xd = real(ifft(fft(x) .* exp(-1j*2*pi*f*retardo_s)));   % x retrasado
    e = round(borde*N);  idx = e+1:N-e;
    a = xd(idx); b = y(idx);
    g = (a*b.') / (b*b.');
    sdr_dB = 10*log10(sum(a.^2) / sum((a - g*b).^2));
end
