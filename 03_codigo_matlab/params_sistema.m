function P = params_sistema(fc_nom_Hz, opciones)
%PARAMS_SISTEMA  Parámetros centralizados del sistema FDM + FM + superheterodino.
%
%   P = params_sistema()                 % portadora nominal por defecto: 10 MHz
%   P = params_sistema(10.5e6)           % otra portadora nominal (9 a 11 MHz)
%   P = params_sistema(10e6, opciones)   % opciones (struct, todos los campos opcionales):
%        .imprimir    true/false   imprime la tabla nominal/simulado (por defecto true)
%        .snr_c_dB    (SNR)_C del canal en dB; Inf = canal ideal (por defecto Inf)
%        .T_real      duración del audio en segundos "reales" (por defecto 0.2 s)
%        .tau_extra   corrección de retardo medida en Simulink [s simulados] (por defecto 0)
%        .rt_retardo  retardo de cada Rate Transition lento->rápido, en muestras lentas (por defecto 1, medido)
%        .rt_dec      retardo de cada Rate Transition rápido->lento (decimación), en muestras lentas (0)
%        .semilla     semilla del ruido del canal (por defecto 1)
%        .desintonia  desintonía del receptor respecto a la portadora [Hz nominales] (por defecto 0)
%        .log_rf_max  máximo de muestras RF que se registran (por defecto inf; la GUI usa menos)
%        .enfasis     true/false: filtros de prénfasis (TX) y deénfasis (RX) sobre el multiplex
%                     (por defecto false)
%        .f0_enfasis  frecuencia de quiebre del prénfasis [Hz nominales] (por defecto 30 kHz)
%
%   CONVENCIÓN: todas las frecuencias del modelo están ESCALADAS por K = 100
%   (valor simulado = valor nominal / K). El tiempo simulado es K veces el real.
%   La GUI muestra siempre valores nominales = simulado * K.
%
%   Referencia de cada número: documento 01_diagnostico_y_diseno_FDM_FM.md (v2), sección 6.
%   Solo usa MATLAB básico (sin toolboxes). Requiere disenar_fir_kaiser.m en la misma carpeta.

    if nargin < 1 || isempty(fc_nom_Hz), fc_nom_Hz = 10e6; end
    if nargin < 2, opciones = struct(); end
    imprimir  = obtener(opciones, 'imprimir', true);
    snr_c_dB  = obtener(opciones, 'snr_c_dB', Inf);
    desint_nom = obtener(opciones, 'desintonia', 0);   % desintonía del receptor [Hz nominales]
    log_rf_max = obtener(opciones, 'log_rf_max', inf); % máx. de muestras RF registradas (GUI)
    T_real    = obtener(opciones, 'T_real', 0.2);
    tau_extra = obtener(opciones, 'tau_extra', 0);
    % Retardo de los Rate Transition lento->rápido, en muestras de la tasa lenta.
    % MEDIDO en Simulink R2026a (verificar_etapa2): 1 muestra lenta, aun en una sola tarea.
    % Es determinista, así que se modela en la referencia y se incluye en tau_k.
    rt_retardo = obtener(opciones, 'rt_retardo', 1);
    % Retardo de los Rate Transition rápido->lento (decimación), en muestras de la tasa lenta.
    % Se espera 0; verificar_etapa5 lo mide.
    rt_dec = obtener(opciones, 'rt_dec', 0);
    enfasis    = obtener(opciones, 'enfasis', false);
    f0_enf_nom = obtener(opciones, 'f0_enfasis', 30e3);

    %% ---------------- Escalamiento [DECISIÓN, E1] ----------------
    P.K = 100;                        % factor de escala uniforme
    K = P.K;

    %% ---------------- Señales de audio [REQ 4.1] ----------------
    P.Wa      = 15e3 / K;             % ancho de cada audio: 15 kHz nom -> 150 Hz
    P.fs_a    = 48e3 / K;             % tasa de audio: 48 kHz nom -> 480 Hz
    P.fs_audio_real = 48e3;           % tasa para reproducir con sound() (deshace el escalamiento)

    %% ---------------- FDM DSB-SC [DECISIÓN, 6.2] ----------------
    P.f_sc    = [20e3 60e3 100e3] / K;          % subportadoras
    P.W       = 120e3 / K;                      % ancho máximo del multiplex [REQ 4.2]
    P.fm_max  = max(P.f_sc) + P.Wa;             % borde ocupado superior (115 kHz nom)
    P.fs_m    = 480e3 / K;                      % tasa del multiplex
    P.L1      = P.fs_m / P.fs_a;                % interpolación audio -> multiplex (10)
    P.normalizacion = 3;                        % m_n = m/3  -> |m_n| <= 1

    %% ---------------- Prénfasis / deénfasis del multiplex [REQ 4.5] ----------------
    % Curso, diap. 384-387: el prénfasis va antes del modulador FM y el deénfasis justo
    % después del discriminador. Aquí el "mensaje" que entra al modulador es el multiplex,
    % así que se filtra el multiplex completo (a fs_m):
    %   prénfasis : y[n] = g*(x[n] - a*x[n-1])     -> realza las altas frecuencias (canal 3)
    %   deénfasis : y[n] = x[n]/g + a*y[n-1]         -> inverso exacto: H_de = 1/H_pre
    % con a = exp(-2*pi*f0/fs_m). La ganancia g mantiene el pico de m_n en <= 1 (misma
    % desviación pico, mismo Carson): cada canal k sale escalado por ~|H(f_k)|, así que
    % g = 3 / suma_k |H(f_k + Wa)|  (|H| crece con f, el máximo de cada banda está en el borde superior).
    % Como H_de*H_pre = 1, el par no cambia los retardos tau_k ni la señal sin ruido.
    P.enfasis = logical(enfasis);
    P.f0_enf  = f0_enf_nom / K;
    if P.enfasis
        P.alfa_enf = exp(-2*pi*P.f0_enf / P.fs_m);
    else
        P.alfa_enf = 0;                              % filtro = cable
    end
    H_enf = @(f) abs(1 - P.alfa_enf * exp(-1j*2*pi*f/P.fs_m));
    P.g_enf = 3 / sum(H_enf(P.f_sc + P.Wa));
    P.enf.num_tx = P.g_enf * [1, -P.alfa_enf];      % prénfasis (FIR de 2 coeficientes)
    P.enf.num_rx = 1 / P.g_enf;                      % deénfasis (IIR de 1 polo)
    P.enf.den_rx = [1, -P.alfa_enf];
    % mejora teórica de la SNR de cada canal (ruido del discriminador ~ f^2, Haykin):
    %   mejora_k = g^2 * integral(f^2) / integral(f^2/|H|^2)   sobre f_k +/- Wa
    for k = 1:3
        ff = linspace(P.f_sc(k) - P.Wa, P.f_sc(k) + P.Wa, 501);
        P.enf.mejora_dB(k) = 10*log10(P.g_enf^2 * trapz(ff, ff.^2) / trapz(ff, ff.^2 ./ H_enf(ff).^2));
    end

    %% ---------------- FM [DECISIÓN, 6.3-6.4] ----------------
    P.Ac      = 1;                              % amplitud de portadora
    P.df      = 150e3 / K;                      % desviación pico = k_f (por unidad de m_n)
    P.kf      = P.df;
    P.DR      = P.df / P.fm_max;                % relación de desviación (curso diap. 328)
    P.B_carson = 2 * (P.df + P.fm_max);
    nb = find(abs(besselj(1:20, P.DR)) >= 0.01, 1, 'last');   % bandas laterales significativas
    P.n_bessel = nb;
    P.B_bessel = 2 * nb * P.fm_max;
    paso_HW = 500;                              % redondeo a 500 Hz simulados (50 kHz nom)
    P.HW = ceil(max(P.B_carson, P.B_bessel) / 2 / paso_HW) * paso_HW;   % semiancho de paso RF/FI

    %% ---------------- RF / LO / FI [REQ 4.3, 4.5 + DECISIÓN 6.5] ----------------
    P.fc_rango_nom = [9e6 11e6];
    assert(fc_nom_Hz >= P.fc_rango_nom(1) && fc_nom_Hz <= P.fc_rango_nom(2), ...
        'La portadora nominal debe estar entre 9 y 11 MHz (rango del diseño).');
    P.fc      = fc_nom_Hz / K;
    P.f_FI    = 1.7e6 / K;
    P.inyeccion = 'inferior';
    P.desintonia = desint_nom / K;              % 0 = receptor sintonizado en la portadora
    P.fc_rx   = P.fc + P.desintonia;            % frecuencia que sintoniza el receptor
    P.f_LO    = P.fc_rx - P.f_FI;               % LO automático (sigue a la sintonía)
    P.f_imagen = P.fc_rx - 2 * P.f_FI;
    P.f_suma  = P.fc + P.f_LO;                  % producto suma del mezclador
    P.log_rf_max = log_rf_max;
    P.fs_rf   = 48e6 / K;
    P.L2      = P.fs_rf / P.fs_m;               % interpolación multiplex -> RF (100 en total)
    P.fs_fi   = 4.8e6 / K;                      % tasa intermedia (TX) y de FI (RX)
    P.L2a     = P.fs_fi / P.fs_m;               % 1.ª etapa de interpolación (x10)
    P.L2b     = P.fs_rf / P.fs_fi;              % 2.ª etapa de interpolación (x10)
    P.M1      = P.fs_rf / P.fs_fi;              % decimación RF -> FI (10)
    P.M2      = P.fs_fi / P.fs_m;               % decimación FI -> multiplex (10)
    P.M3      = P.fs_m / P.fs_a;                % decimación multiplex -> audio (10)

    %% ---------------- Filtros FIR (Kaiser, 60 dB) [6.7] ----------------
    A = 60;
    [P.h.audio_tx, P.fi_info.audio_tx] = disenar_fir_kaiser('lp', P.fs_a, [150 180], A, 1);
    [P.h.interp1,  P.fi_info.interp1]  = disenar_fir_kaiser('lp', P.fs_m, [150 330], A, P.L1);
    % interpolación x100 en dos etapas x10 (mucho menos cómputo que un solo FIR a fs_rf):
    %   etapa a (a fs_fi): imágenes en fs_m +/- W  -> rechazo desde fs_m - W
    %   etapa b (a fs_rf): imágenes en fs_fi +/- W -> rechazo desde fs_fi - W (transición ancha)
    [P.h.interp2a, P.fi_info.interp2a] = disenar_fir_kaiser('lp', P.fs_fi, [P.W, P.fs_m - P.W], A, P.L2a);
    [P.h.interp2b, P.fi_info.interp2b] = disenar_fir_kaiser('lp', P.fs_rf, [P.W, P.fs_fi - P.W], A, P.L2b);
    [P.h.presel,   P.fi_info.presel]   = disenar_fir_kaiser('bp', P.fs_rf, ...
        [P.fc_rx - P.HW - 12000, P.fc_rx - P.HW, P.fc_rx + P.HW, P.fc_rx + P.HW + 12000], A, 1);
    % sección de FI en dos etapas:
    %   1) pasabajos a fs_rf: deja la banda FI (<= f_FI+HW) y rechaza todo lo que, al decimar
    %      por M1, caería sobre ella (>= fs_fi - (f_FI+HW)); elimina también el producto suma
    %   2) pasabanda FI selectivo ya a fs_fi
    [P.h.fi_lpf,   P.fi_info.fi_lpf]   = disenar_fir_kaiser('lp', P.fs_rf, ...
        [P.f_FI + P.HW, P.fs_fi - (P.f_FI + P.HW)], A, 1);
    [P.h.fi,       P.fi_info.fi]       = disenar_fir_kaiser('bp', P.fs_fi, ...
        [P.f_FI - P.HW - 2000, P.f_FI - P.HW, P.f_FI + P.HW, P.f_FI + P.HW + 2000], A, 1);
    [P.h.iq,       P.fi_info.iq]       = disenar_fir_kaiser('lp', P.fs_fi, [P.HW + 500, 9500], A, 1);
    [P.h.mux,      P.fi_info.mux]      = disenar_fir_kaiser('lp', P.fs_fi, [1200 2400], A, 1);
    bordes_canal = [   0  50  350  400;     % canal 1: pasabanda (rechaza DC del discriminador)
                     350 450  750  850;     % canal 2
                     750 850 1150 1250];    % canal 3
    for k = 1:3
        [P.h.canal{k}, P.fi_info.canal{k}] = disenar_fir_kaiser('bp', P.fs_m, bordes_canal(k,:), A, 1);
    end
    [P.h.post,     P.fi_info.post]     = disenar_fir_kaiser('lp', P.fs_m, [150 200], A, 1);

    %% ---------------- Retardos y fase de las subportadoras del RX [E5, 6.7] ----------------
    % tau_k = suma de retardos de grupo entre la modulación DSB-SC y el producto del canal k
    I = P.fi_info;
    P.rt_retardo = rt_retardo;
    P.rt_dec = rt_dec;
    tau_comun = rt_retardo / P.fs_m + I.interp2a.retardo_s + rt_retardo / P.fs_fi + I.interp2b.retardo_s + ...
                I.presel.retardo_s + I.fi_lpf.retardo_s + rt_dec / P.fs_fi + I.fi.retardo_s + rt_dec / P.fs_m + ...
                I.iq.retardo_s + 0.5 / P.fs_fi + I.mux.retardo_s;
    P.tau_extra = tau_extra;
    for k = 1:3
        P.tau(k) = tau_comun + I.canal{k}.retardo_s + tau_extra;
    end
    P.fase_rx = -2 * pi * P.f_sc .* P.tau;      % cos(2*pi*f_k*t + fase_rx(k)) = cos(2*pi*f_k*(t - tau_k))
    P.ganancia_sin_compensar = cos(2 * pi * P.f_sc .* P.tau);
    % retardo total audio_in -> audio_out (para alinear en comparaciones)
    P.retardo_audio = P.tau + rt_retardo / P.fs_a + rt_dec / P.fs_a + I.audio_tx.retardo_s + I.interp1.retardo_s + I.post.retardo_s;

    %% ---------------- Canal AWGN [6.9] ----------------
    % (SNR)_C de Haykin: (Ac^2/2) / (W N0), W = ancho del multiplex
    P.snr_c_dB = snr_c_dB;
    P.semilla_ruido = obtener(opciones, 'semilla', 1);
    if isinf(snr_c_dB)
        P.N0 = 0; P.sigma_ruido = 0;
    else
        P.N0 = (P.Ac^2 / 2) / (10^(snr_c_dB / 10) * P.W);
        P.sigma_ruido = sqrt(P.N0 * P.fs_rf / 2);   % ruido real muestreado a fs_rf
    end
    P.cnr_BT_dB  = snr_c_dB - 10 * log10(P.B_carson / P.W);
    P.snr_bloque_dB = snr_c_dB - 10 * log10((P.fs_rf / 2) / P.W);

    %% ---------------- Duración ----------------
    P.T_real = T_real;
    P.T_sim  = K * T_real;
    P.n_muestras_rf = round(P.T_sim * P.fs_rf);

    %% ---------------- Valores para la GUI (nominales) ----------------
    P.vista.fc_MHz     = P.fc * K / 1e6;
    P.vista.fLO_MHz    = P.f_LO * K / 1e6;
    P.vista.fFI_MHz    = P.f_FI * K / 1e6;
    P.vista.fimagen_MHz = P.f_imagen * K / 1e6;
    P.vista.fcrx_MHz   = P.fc_rx * K / 1e6;
    P.vista.df_kHz     = P.df * K / 1e3;
    P.vista.carson_kHz = P.B_carson * K / 1e3;
    P.vista.f0_enf_kHz = P.f0_enf * K / 1e3;

    %% ---------------- Comprobaciones automáticas ----------------
    P.chequeos = comprobar(P, bordes_canal);
    if imprimir, imprimir_tabla(P); end
end

% =========================================================================
function v = obtener(s, campo, defecto)
    if isfield(s, campo) && ~isempty(s.(campo)), v = s.(campo); else, v = defecto; end
end

function c = comprobar(P, bordes_canal)
    K = P.K; tol = 1e-9;
    c = {};
    % FDM
    bandas = [P.f_sc(:) - P.Wa, P.f_sc(:) + P.Wa];
    c{end+1} = {'Bandas FDM dentro de 0..W', all(bandas(:,1) > 0) && all(bandas(:,2) <= P.W + tol)};
    c{end+1} = {'Bandas FDM sin solaparse (guardas > 0)', all(bandas(2:end,1) - bandas(1:end-1,2) > 0)};
    c{end+1} = {'Nyquist multiplex: fs_m > 2W', P.fs_m > 2 * P.W};
    c{end+1} = {'Nyquist audio: fs_a > 2Wa', P.fs_a > 2 * P.Wa};
    % FM / FI
    c{end+1} = {'FI > B/2 (la banda FI no toca DC)', P.f_FI - P.HW > 0};
    c{end+1} = {'FI > f_m,max (definición de superheterodino)', P.f_FI > P.fm_max};
    c{end+1} = {'Paso FI cubre Bessel y Carson', 2 * P.HW >= max(P.B_bessel, P.B_carson) - tol};
    c{end+1} = {'f_FI = |f_RF - f_LO| (receptor sintonizado)', abs(abs(P.fc_rx - P.f_LO) - P.f_FI) < tol};
    c{end+1} = {'LO > 0', P.f_LO > 0};
    % muestreo RF y FI
    c{end+1} = {'Nyquist RF: fs_rf/2 > producto suma + HW', P.fs_rf / 2 > P.f_suma + P.HW};
    c{end+1} = {'Rechazo FI dentro de Nyquist de fs_fi', P.fi_info.fi.bordes(4) < P.fs_fi / 2};
    c{end+1} = {'Pasabajos FI evita aliasing al decimar', P.fi_info.fi_lpf.bordes(2) >= P.fs_fi - (P.f_FI + P.HW) - 1e-9};
    c{end+1} = {'Producto suma en rechazo del pasabajos FI', P.f_suma - P.HW > P.fi_info.fi_lpf.bordes(2)};
    c{end+1} = {'Imagen en banda de rechazo del preselector', P.f_imagen < P.fi_info.presel.bordes(1)};
    c{end+1} = {'Producto suma fuera del paso FI', P.f_suma - P.HW > P.fi_info.fi.bordes(4)};
    c{end+1} = {'Factores de tasa enteros', all(abs([P.L1 P.L2 P.M1 P.M2 P.M3] - round([P.L1 P.L2 P.M1 P.M2 P.M3])) < tol)};
    % filtros
    nombres = {'audio_tx','interp1','interp2a','interp2b','presel','fi_lpf','fi','iq','mux','post'};
    ok = true;
    for i = 1:numel(nombres), ok = ok && P.fi_info.(nombres{i}).A_medida_dB >= 59.5; end
    for k = 1:3, ok = ok && P.fi_info.canal{k}.A_medida_dB >= 59.5; end
    c{end+1} = {'Todos los filtros con rechazo >= 60 dB', ok};
    % FDM: bordes de los filtros de canal respetan las guardas
    c{end+1} = {'Filtros de canal: paso cubre f_k +/- Wa', ...
        all(bordes_canal(:,2) <= (P.f_sc(:) - P.Wa) + tol) && all(bordes_canal(:,3) >= (P.f_sc(:) + P.Wa) - tol)};

    for i = 1:numel(c)
        assert(c{i}{2}, ['Falla de diseño: ' c{i}{1}]);
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
        'Bessel (n significativas)',    P.B_bessel;
        'Semiancho paso RF/FI',         P.HW;
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
    fprintf('%-34s %13d\n', 'Bandas laterales Bessel (>=1%)', P.n_bessel);
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
    fprintf('\nRetardo hasta el producto del canal k (tau_k) y ganancia si NO se compensara:\n');
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
        fprintf('\nAWGN: (SNR)_C = %.1f dB -> CNR en B_T = %.1f dB, SNR bloque = %.1f dB, sigma = %.4g\n', ...
            P.snr_c_dB, P.cnr_BT_dB, P.snr_bloque_dB, P.sigma_ruido);
    else
        fprintf('\nCanal ideal (sin ruido).\n');
    end
    fprintf('Duración: %.3g s reales = %.3g s simulados -> %.3g M muestras RF\n', P.T_real, P.T_sim, P.n_muestras_rf/1e6);
    fprintf('\nComprobaciones:\n');
    for i = 1:numel(P.chequeos)
        fprintf('  [OK] %s\n', P.chequeos{i}{1});
    end
    fprintf('==========================================\n\n');
end
