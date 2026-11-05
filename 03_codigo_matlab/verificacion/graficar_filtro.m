function graficar_filtro(h, fs, K)
%GRAFICAR_FILTRO  |H(f)| en dB contra frecuencia NOMINAL (simulada * K). Sin toolboxes.
    f = linspace(0, fs/2, 2000);
    H = abs(exp(-1j*2*pi*f(:)/fs*(0:numel(h)-1)) * h(:));
    plot(f*K/1e3, 20*log10(H/max(H) + 1e-12)); grid on;
    ylim([-90 5]); xlabel('f nominal [kHz]'); ylabel('|H| [dB]');
end
