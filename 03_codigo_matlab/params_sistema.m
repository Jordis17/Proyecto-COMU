function P = params_sistema(fc_nom_Hz, opciones)
%PARAMS_SISTEMA  Todos los parámetros del sistema FDM + FM + receptor superheterodino.
%
%   P = params_sistema()                 % portadora nominal de 10 MHz
%   P = params_sistema(10.5e6)           % otra portadora nominal (de 9 a 11 MHz)
%   P = params_sistema(10e6, opciones)   % opciones (struct, todos los campos son opcionales):
%        .imprimir    true/false: imprime la tabla de diseño (por defecto true)
%        .snr_c_dB    (SNR)_C del canal en dB; Inf = canal ideal (por defecto Inf)
%        .T_real      duración del audio en segundos reales (por defecto 0.2 s)
%        .desintonia  desintonía del receptor respecto a la portadora [Hz nominales] (por defecto 0)
%        .enfasis     true/false: prénfasis (TX) y deénfasis (RX) del multiplex (por defecto false)
%        .f0_enfasis  frecuencia de quiebre del prénfasis [Hz nominales] (por defecto 30 kHz)
%        .log_rf_max  máximo de muestras RF que se guardan (por defecto inf; la GUI usa menos)
%
%   ESCALAMIENTO: todas las frecuencias del modelo están divididas por K = 100
%   (valor simulado = valor nominal / K), y el tiempo simulado es K veces el real.
%   La GUI siempre muestra valores nominales (simulado * K).
%   Solo usa MATLAB básico. Necesita disenar_fir_kaiser.m en la misma carpeta.

    if nargin < 1 || isempty(fc_nom_Hz), fc_nom_Hz = 10e6; end
    if nargin < 2, opciones = struct(); end
    imprimir   = obtener(opciones, 'imprimir', true);
    snr_c_dB   = obtener(opciones, 'snr_c_dB', Inf);
    T_real     = obtener(opciones, 'T_real', 0.2);
    desint_nom = obtener(opciones, 'desintonia', 0);
    enfasis    = obtener(opciones, 'enfasis', false);
    f0_enf_nom = obtener(opciones, 'f0_enfasis', 30e3);
    log_rf_max = obtener(opciones, 'log_rf_max', inf);

    % Carpeta donde Simulink compila el modelo (modo acelerado): en la carpeta temporal de
    % cada computadora y no junto al proyecto. Así no se sincroniza por OneDrive ni choca
    % entre computadoras con versiones distintas de MATLAB.
    try
        cache = fullfile(tempdir, ['sistema_fdm_fm_' version('-release')]);
        if ~strcmp(Simulink.fileGenControl('get', 'CacheFolder'), cache)
            Simulink.fileGenControl('set', 'CacheFolder', cache, 'CodeGenFolder', cache, 'createDir', true);
        end
    catch
    end

    %% ---------------- Escalamiento ----------------
    % La tabla del enunciado divide la portadora y la FI por 100 pero no el audio ni el FDM,
    % y así se pierden las proporciones. Aquí se divide TODO por el mismo K.
    P.K = 100;
    K = P.K;

    %% ---------------- Audio ----------------
    P.Wa      = 15e3 / K;             % ancho de cada audio: 15 kHz
    P.fs_a    = 48e3 / K;             % tasa del audio: 48 kHz
    P.fs_audio_real = 48e3;           % tasa para escucharlo con sound() (deshace el escalamiento)

    %% ---------------- FDM con DSB-SC ----------------
    P.f_sc    = [20e3 60e3 100e3] / K;          % subportadoras: bandas 5-35, 45-75, 85-115 kHz
    P.W       = 120e3 / K;                      % ancho máximo del multiplex (enunciado: 120 kHz)
    P.fm_max  = max(P.f_sc) + P.Wa;             % frecuencia más alta del multiplex: 115 kHz
    P.fs_m    = 480e3 / K;                      % tasa del multiplex
    P.L1      = P.fs_m / P.fs_a;                % interpolación audio -> multiplex (x10)
    P.normalizacion = 3;                        % m_n = m/3, así |m_n| <= 1

    %% ---------------- Prénfasis / deénfasis del multiplex ----------------
    % Como en el curso (diap. 384), el prénfasis va antes del modulador FM y el deénfasis
    % justo después del demodulador. El mensaje que entra al modulador es el multiplex,
    % así que se filtra el multiplex completo (a fs_m):
    %   prénfasis : y[n] = g*(x[n] - a*x[n-1])   realza las frecuencias altas (canal 3)
    %   deénfasis : y[n] = x[n]/g + a*y[n-1]     es el inverso exacto del prénfasis
    % con a = exp(-2*pi*f0/fs_m). La ganancia g deja el pico de m_n en <= 1, así que la
    % desviación pico y el ancho de Carson no cambian. Como los dos filtros juntos dan 1,
    % no cambian los retardos tau_k.
    P.enfasis = logical(enfasis);
    P.f0_enf  = f0_enf_nom / K;
    if P.enfasis
        P.alfa_enf = exp(-2*pi*P.f0_enf / P.fs_m);
    else
        P.alfa_enf = 0;                         % con a = 0 y g = 1 los filtros son un cable
    end
    H_enf = @(f) abs(1 - P.alfa_enf * exp(-1j*2*pi*f/P.fs_m));
    P.g_enf = 3 / sum(H_enf(P.f_sc + P.Wa));    % |H| crece con f: el máximo de cada banda está en su borde superior
    P.enf.num_tx = P.g_enf * [1, -P.alfa_enf];
    P.enf.num_rx = 1 / P.g_enf;
    P.enf.den_rx = [1, -P.alfa_enf];
    % mejora teórica de la SNR de cada canal (el ruido a la salida del discriminador crece como f^2)
    for k = 1:3
        ff = linspace(P.f_sc(k) - P.Wa, P.f_sc(k) + P.Wa, 501);
        P.enf.mejora_dB(k) = 10*log10(P.g_enf^2 * trapz(ff, ff.^2) / trapz(ff, ff.^2 ./ H_enf(ff).^2));
    end

    %% ---------------- FM ----------------
    P.Ac      = 1;                              % amplitud de la portadora
    P.df      = 150e3 / K;                      % desviación pico (= k_f, porque |m_n| <= 1)
    P.kf      = P.df;
    P.DR      = P.df / P.fm_max;                % relación de desviación DR = 150/115 = 1.30
    P.B_carson = 2 * (P.df + P.fm_max);         % Carson: 530 kHz
    nb = find(abs(besselj(1:20, P.DR)) >= 0.01, 1, 'last');   % bandas laterales con J_n >= 0.01
    P.n_bessel = nb;
    P.B_bessel = 2 * nb * P.fm_max;
    paso_HW = 500;                              % se redondea a 500 Hz simulados (50 kHz)
    P.HW = ceil(max(P.B_carson, P.B_bessel) / 2 / paso_HW) * paso_HW;   % medio ancho del paso RF/FI: 350 kHz

    %% ---------------- RF / LO / FI ----------------
    P.fc_rango_nom = [9e6 11e6];
    assert(fc_nom_Hz >= P.fc_rango_nom(1) && fc_nom_Hz <= P.fc_rango_nom(2), ...
        'La portadora nominal debe estar entre 9 y 11 MHz.');
    P.fc      = fc_nom_Hz / K;
    P.f_FI    = 1.7e6 / K;
    P.desintonia = desint_nom / K;              % 0 = receptor sintonizado en la portadora
    P.fc_rx   = P.fc + P.desintonia;            % frecuencia que sintoniza el receptor
    P.f_LO    = P.fc_rx - P.f_FI;               % LO automático, inyección inferior
    P.f_imagen = P.fc_rx - 2 * P.f_FI;
    P.f_suma  = P.fc + P.f_LO;                  % producto suma del mezclador
    P.log_rf_max = log_rf_max;
    P.fs_rf   = 48e6 / K;                       % > 2 * (producto suma + 350 kHz) = 41.3 MHz
    P.fs_fi   = 4.8e6 / K;                      % tasa de la FI (y tasa intermedia del TX)
    P.L2      = P.fs_rf / P.fs_m;               % interpolación multiplex -> RF (x100)
    P.L2a     = P.fs_fi / P.fs_m;               % se hace en dos etapas de x10
    P.L2b     = P.fs_rf / P.fs_fi;
    P.M1      = P.fs_rf / P.fs_fi;              % decimación RF -> FI (/10)
    P.M2      = P.fs_fi / P.fs_m;               % decimación FI -> multiplex (/10)
    P.M3      = P.fs_m / P.fs_a;                % decimación multiplex -> audio (/10)

    %% ---------------- Filtros FIR (ventana de Kaiser, 60 dB de rechazo) ----------------
    A = 60;
    [P.h.audio_tx, P.fi_info.audio_tx] = disenar_fir_kaiser('lp', P.fs_a, [150 180], A, 1);
    [P.h.interp1,  P.fi_info.interp1]  = disenar_fir_kaiser('lp', P.fs_m, [150 330], A, P.L1);
    % interpolación x100 en dos etapas x10 (mucho menos cálculo que un solo filtro a fs_rf)
    [P.h.interp2a, P.fi_info.interp2a] = disenar_fir_kaiser('lp', P.fs_fi, [P.W, P.fs_m - P.W], A, P.L2a);
    [P.h.interp2b, P.fi_info.interp2b] = disenar_fir_kaiser('lp', P.fs_rf, [P.W, P.fs_fi - P.W], A, P.L2b);
    % preselector (sección de RF): pasa f_c +/- 350 kHz, rechaza desde +/- 1.55 MHz (la imagen está a 3.4 MHz)
    [P.h.presel,   P.fi_info.presel]   = disenar_fir_kaiser('bp', P.fs_rf, ...
        [P.fc_rx - P.HW - 12000, P.fc_rx - P.HW, P.fc_rx + P.HW, P.fc_rx + P.HW + 12000], A, 1);
    % sección de FI en dos pasos: pasabajos a fs_rf (quita el producto suma y evita el aliasing
    % al decimar) y luego el pasabanda de FI, de 1.35 a 2.05 MHz, a fs_fi
    [P.h.fi_lpf,   P.fi_info.fi_lpf]   = disenar_fir_kaiser('lp', P.fs_rf, ...
        [P.f_FI + P.HW, P.fs_fi - (P.f_FI + P.HW)], A, 1);
    [P.h.fi,       P.fi_info.fi]       = disenar_fir_kaiser('bp', P.fs_fi, ...
        [P.f_FI - P.HW - 2000, P.f_FI - P.HW, P.f_FI + P.HW, P.f_FI + P.HW + 2000], A, 1);
    [P.h.iq,       P.fi_info.iq]       = disenar_fir_kaiser('lp', P.fs_fi, [P.HW + 500, 9500], A, 1);
    [P.h.mux,      P.fi_info.mux]      = disenar_fir_kaiser('lp', P.fs_fi, [1200 2400], A, 1);   % filtro posdetección 120 kHz
    bordes_canal = [   0  50  350  400;     % canal 1: 5-35 kHz (pasabanda: también quita el DC)
                     350 450  750  850;     % canal 2: 45-75 kHz
                     750 850 1150 1250];    % canal 3: 85-115 kHz
    for k = 1:3
        [P.h.canal{k}, P.fi_info.canal{k}] = disenar_fir_kaiser('bp', P.fs_m, bordes_canal(k,:), A, 1);
    end
    [P.h.post,     P.fi_info.post]     = disenar_fir_kaiser('lp', P.fs_m, [150 200], A, 1);

    %% ---------------- Demodulador FM: discriminador (diap. 342-345, 375) ----------------
    % limitador -> detector de pendiente (derivador) -> detector de envolvente (ley cuadrática)
    % Derivador: FIR ideal h[n] = cos(pi n)/n (n ~= 0) con ventana de Kaiser, por fs para dar rad/s.
    % Los dos detectores de ley cuadrática usan el mismo pasabajos que P.h.iq (400 / 950 kHz).
    Nd = 63;  beta_d = 6;  n = (0:Nd-1) - (Nd-1)/2;
    hder = zeros(1, Nd);  hder(n ~= 0) = cos(pi*n(n ~= 0)) ./ n(n ~= 0);
    wk = besseli(0, beta_d*sqrt(1 - (2*(0:Nd-1)/(Nd-1) - 1).^2)) / besseli(0, beta_d);
    P.disc.h_der = hder .* wk * P.fs_fi;
    P.disc.amin  = 0.3;                          % el limitador no considera amplitudes menores (amplitud normal = 1)
    P.disc.d_env = (numel(P.h.iq) - 1) / 2;      % retardo del pasabajos de amplitud, en muestras (para alinear la FI)
    % retardo total del discriminador: limitador + derivador + detector de envolvente
    P.disc.retardo_s = (P.disc.d_env + (Nd-1)/2 + (numel(P.h.iq)-1)/2) / P.fs_fi;

    %% ---------------- Retardo tau_k y fase de las subportadoras del RX ----------------
    % En DSB-SC, si la subportadora del receptor tiene un error de fase phi, la salida queda
    % multiplicada por cos(phi) (diap. 237-238). Los filtros retrasan la señal, así que el RX
    % usa cos(2*pi*f_k*(t - tau_k)), donde tau_k es la suma de los retardos (N-1)/(2 fs) de los
    % filtros entre el modulador DSB-SC y el detector del canal k.
    % Cada Rate Transition de tasa lenta a rápida agrega 1 muestra lenta (medido en Simulink).
    I = P.fi_info;
    P.rt_retardo = 1;
    tau_comun = P.rt_retardo / P.fs_m + I.interp2a.retardo_s + P.rt_retardo / P.fs_fi + I.interp2b.retardo_s + ...
                I.presel.retardo_s + I.fi_lpf.retardo_s + I.fi.retardo_s + ...
                P.disc.retardo_s + I.mux.retardo_s;                  % discriminador: limitador + derivador + envolvente
    for k = 1:3
        P.tau(k) = tau_comun + I.canal{k}.retardo_s;
    end
    P.fase_rx = -2 * pi * P.f_sc .* P.tau;      % cos(2*pi*f_k*t + fase_rx) = cos(2*pi*f_k*(t - tau_k))
    P.ganancia_sin_compensar = cos(2 * pi * P.f_sc .* P.tau);
    % retardo total de cada audio, de la entrada a la salida (para compararlos)
    P.retardo_audio = P.tau + P.rt_retardo / P.fs_a + I.audio_tx.retardo_s + I.interp1.retardo_s + I.post.retardo_s;

    %% ---------------- Canal AWGN ----------------
    % (SNR)_C del curso (Haykin, diap. 377): (Ac^2/2) / (W N0), con W = ancho del multiplex
    P.snr_c_dB = snr_c_dB;
    P.semilla_ruido = 1;
    if isinf(snr_c_dB)
        P.N0 = 0; P.sigma_ruido = 0;
    else
        P.N0 = (P.Ac^2 / 2) / (10^(snr_c_dB / 10) * P.W);
        P.sigma_ruido = sqrt(P.N0 * P.fs_rf / 2);   % ruido real con DEP N0/2 muestreado a fs_rf
    end
    P.cnr_BT_dB = snr_c_dB - 10 * log10(P.B_carson / P.W);   % relación portadora/ruido en el ancho de Carson

    %% ---------------- Duración ----------------
    P.T_real = T_real;
    P.T_sim  = K * T_real;
    P.n_muestras_rf = round(P.T_sim * P.fs_rf);

    %% ---------------- Valores que muestra la GUI (nominales) ----------------
    P.vista.fc_MHz      = P.fc * K / 1e6;
    P.vista.fLO_MHz     = P.f_LO * K / 1e6;
    P.vista.fFI_MHz     = P.f_FI * K / 1e6;
    P.vista.fimagen_MHz = P.f_imagen * K / 1e6;
    P.vista.df_kHz      = P.df * K / 1e3;
    P.vista.carson_kHz  = P.B_carson * K / 1e3;
    P.vista.f0_enf_kHz  = P.f0_enf * K / 1e3;

    %% ---------------- Comprobaciones del diseño ----------------
    P.chequeos = comprobar(P);
    if imprimir, imprimir_tabla(P); end
end

% =========================================================================
function v = obtener(s, campo, defecto)
    if isfield(s, campo) && ~isempty(s.(campo)), v = s.(campo); else, v = defecto; end
end

function c = comprobar(P)
% Si alguna falla, el diseño tiene un error y el programa se detiene.
    tol = 1e-9;
    bandas = [P.f_sc(:) - P.Wa, P.f_sc(:) + P.Wa];
    I = P.fi_info;
    filtros_ok = all(cellfun(@(n) I.(n).A_medida_dB >= 59.5, ...
        {'audio_tx','interp1','interp2a','interp2b','presel','fi_lpf','fi','iq','mux','post'})) && ...
        all(cellfun(@(s) s.A_medida_dB >= 59.5, I.canal));
    c = {
        'Canales FDM dentro de 0-120 kHz y sin solaparse', ...
            all(bandas(:,1) > 0) && all(bandas(:,2) <= P.W + tol) && all(bandas(2:end,1) > bandas(1:end-1,2));
        'Nyquist del multiplex: fs_m > 2W',                 P.fs_m > 2 * P.W;
        'La banda de FI no toca 0 Hz (f_FI > B/2)',          P.f_FI - P.HW > 0;
        'El paso de FI cubre el ancho de Carson',           2 * P.HW >= P.B_carson - tol;
        'f_FI = |f_RF - f_LO|',                             abs(abs(P.fc_rx - P.f_LO) - P.f_FI) < tol;
        'Nyquist de RF: fs_rf/2 > producto suma + B/2',      P.fs_rf / 2 > P.f_suma + P.HW;
        'El preselector rechaza la frecuencia imagen',      P.f_imagen < I.presel.bordes(1);
        'El producto suma queda fuera del paso de FI',      P.f_suma - P.HW > I.fi_lpf.bordes(2);
        'Todos los filtros rechazan al menos 60 dB',        filtros_ok};
    for i = 1:size(c, 1)
        assert(c{i,2}, ['Falla de diseño: ' c{i,1}]);
    end
end

function imprimir_tabla(P)
    K = P.K;
    fprintf('\n===== PARÁMETROS DEL SISTEMA (K = %d) =====\n', K);
    fprintf('%-34s %17s %16s\n', 'Parámetro', 'Nominal', 'Simulado');
    L = {
        'Ancho de audio Wa',            P.Wa;
        'f_s audio',                    P.fs_a;
        'Subportadora 1',               P.f_sc(1);
        'Subportadora 2',               P.f_sc(2);
        'Subportadora 3',               P.f_sc(3);
        'f_m,max del multiplex',        P.fm_max;
        'Ancho del multiplex W',        P.W;
        'f_s multiplex',                P.fs_m;
        'Desviación pico Df',           P.df;
        'Carson',                       P.B_carson;
        'Bessel (bandas >= 1 %)',       P.B_bessel;
        'Medio ancho del paso RF/FI',   P.HW;
        'Portadora f_c',                P.fc;
        'FI',                           P.f_FI;
        'LO (inyección inferior)',      P.f_LO;
        'Frecuencia imagen',            P.f_imagen;
        'Producto suma',                P.f_suma;
        'f_s RF',                       P.fs_rf;
        'f_s FI',                       P.fs_fi};
    for i = 1:size(L,1)
        fprintf('%-34s %13.4f kHz %13.4f Hz\n', L{i,1}, L{i,2} * K / 1e3, L{i,2});
    end
    fprintf('%-34s %13.3f\n', 'Relación de desviación DR', P.DR);
    fprintf('\nFiltros (N coeficientes, rechazo medido):\n');
    nombres = {'audio_tx','interp1','interp2a','interp2b','presel','fi_lpf','fi','iq','mux','post'};
    for i = 1:numel(nombres)
        s = P.fi_info.(nombres{i});
        fprintf('  %-9s N = %4d   A = %5.1f dB   retardo = %8.3f ms sim\n', nombres{i}, s.N, s.A_medida_dB, s.retardo_s*1e3);
    end
    for k = 1:3
        s = P.fi_info.canal{k};
        fprintf('  canal %d    N = %4d   A = %5.1f dB   retardo = %8.3f ms sim\n', k, s.N, s.A_medida_dB, s.retardo_s*1e3);
    end
    fprintf('\nDemodulador: discriminador (limitador -> derivador de %d coef. -> detector de envolvente), amplitud mínima %.1f\n', numel(P.disc.h_der), P.disc.amin);
    fprintf('\nRetardo hasta el detector de cada canal (tau_k) y ganancia si NO se compensara:\n');
    for k = 1:3
        fprintf('  canal %d: tau = %7.2f us nom  -> cos(2 pi f_k tau) = %+.2f\n', k, P.tau(k)*1e6/K, P.ganancia_sin_compensar(k));
    end
    if P.enfasis
        fprintf('\nPrénfasis/deénfasis ACTIVO: f0 = %.0f kHz nom, a = %.4f, g = %.4f\n', P.f0_enf*K/1e3, P.alfa_enf, P.g_enf);
        fprintf('  mejora teórica de SNR por canal: %+.1f / %+.1f / %+.1f dB\n', P.enf.mejora_dB);
    else
        fprintf('\nPrénfasis/deénfasis apagado.\n');
    end
    if ~isinf(P.snr_c_dB)
        fprintf('AWGN: (SNR)_C = %.1f dB -> CNR en el ancho de Carson = %.1f dB, sigma = %.4g\n', ...
            P.snr_c_dB, P.cnr_BT_dB, P.sigma_ruido);
    else
        fprintf('Canal ideal (sin ruido).\n');
    end
    fprintf('Duración: %.3g s reales = %.3g s simulados -> %.3g M muestras RF\n', P.T_real, P.T_sim, P.n_muestras_rf/1e6);
    fprintf('\nComprobaciones:\n');
    for i = 1:size(P.chequeos, 1)
        fprintf('  [OK] %s\n', P.chequeos{i,1});
    end
    fprintf('==========================================\n\n');
end
