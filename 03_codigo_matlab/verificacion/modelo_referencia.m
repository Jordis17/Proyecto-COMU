function R = modelo_referencia(P, X)
% Cadena completa TX -> canal -> superheterodino -> demux, en MATLAB puro.
%   R = modelo_referencia(P, X)
%   P : estructura de params_sistema
%   X : 3 x Na, los tres audios muestreados a P.fs_a (cada uno normalizado, |x| <= 1)
%
%   Usa filtros CAUSALES (filter), igual que Simulink, por lo que los retardos son reales
%   y las subportadoras del RX se compensan con P.fase_rx. Sirve como referencia numérica
%   para comparar con el modelo .slx bloque por bloque. Solo MATLAB básico.
%
%   Salida R: audios recuperados R.Y (3 x Na), multiplex TX/RX, señal FI, etc.

    assert(size(X,1) == 3, 'X debe tener 3 filas (un audio por fila)');
    Na = size(X, 2);

    %% ===================== TRANSMISOR =====================
    % 1) LPF de audio (limita a 15 kHz nom) y 2) interpolación x L1 por inserción de ceros
    Nm  = Na * P.L1;
    t_m = (0:Nm-1) / P.fs_m;
    m   = zeros(1, Nm);
    xb  = zeros(3, Nm);                                 % banda base interpolada (para depurar)
    for k = 1:3
        xa = filter(P.h.audio_tx, 1, X(k,:));
        u  = zeros(1, Nm);  u(1:P.L1:end) = xa;
        u  = retrasar(u, P.rt_retardo * P.L1);          % retardo del Rate Transition (si existe)
        xk = filter(P.h.interp1, 1, u);                 % ganancia L1 incluida en el filtro
        xb(k,:) = xk;
        m  = m + xk .* cos(2*pi*P.f_sc(k)*t_m);         % 3) DSB-SC
    end
    m_n = m / P.normalizacion;                            % 4) |m_n| <= 1
    m_n = filter(P.enf.num_tx, 1, m_n);                   % 4b) prénfasis (cable si P.enfasis = false)

    % 5) interpolación x L2 = L2a * L2b hasta la tasa de RF (dos etapas x10)
    Ni = Nm * P.L2a;
    u = zeros(1, Ni);  u(1:P.L2a:end) = m_n;
    u = retrasar(u, P.rt_retardo * P.L2a);
    m_i = filter(P.h.interp2a, 1, u);
    Nrf = Ni * P.L2b;
    u = zeros(1, Nrf);  u(1:P.L2b:end) = m_i;
    u = retrasar(u, P.rt_retardo * P.L2b);
    m_rf = filter(P.h.interp2b, 1, u);

    % 6) modulador FM: s = Ac cos(2 pi fc t + 2 pi kf * integral(m_n))
    t_rf = (0:Nrf-1) / P.fs_rf;
    fase = 2*pi*P.fc*t_rf + 2*pi*P.kf*cumsum(m_rf)/P.fs_rf;
    s = P.Ac * cos(fase);

    %% ===================== CANAL =====================
    r = s;
    if P.sigma_ruido > 0
        r = r + P.sigma_ruido * randn(size(s));
    end

    %% ===================== RECEPTOR SUPERHETERODINO =====================
    v  = filter(P.h.presel, 1, r);                        % sección de RF (preselector)
    v  = v .* (2*cos(2*pi*P.f_LO*t_rf));                  % mezclador con LO
    v  = filter(P.h.fi_lpf, 1, v);                        % pasabajos anti-aliasing (quita suma)
    v  = v(1:P.M1:end);                                   % decimación -> fs_fi
    fi = filter(P.h.fi, 1, v);                            % sección de FI (pasabanda selectivo)

    % demodulador FM: discriminador (igual que el modelo)
    A  = max(sqrt(max(2*filter(P.h.iq, 1, fi.^2), 0)), P.disc.amin);     % limitador: amplitud
    fd = [zeros(1, P.disc.d_env), fi(1:end-P.disc.d_env)];               % FI retrasada para alinear
    d  = filter(P.disc.h_der, 1, fd ./ A);                              % detector de pendiente
    finst = sqrt(max(2*filter(P.h.iq, 1, d.^2), 0)) / (2*pi) - P.f_FI;   % detector de envolvente
    m_hat = filter(P.h.mux, 1, finst / P.kf);             % filtro posdetección (120 kHz nom)
    m_hat = m_hat(1:P.M2:end) * P.normalizacion;          % -> fs_m, deshace /3
    m_hat = filter(P.enf.num_rx, P.enf.den_rx, m_hat);   % deénfasis (cable si P.enfasis = false)

    %% ===================== DEMULTIPLEXOR FDM =====================
    t_m2 = (0:numel(m_hat)-1) / P.fs_m;
    Y = zeros(3, Na);
    for k = 1:3
        y = filter(P.h.canal{k}, 1, m_hat);
        y = y .* (2*cos(2*pi*P.f_sc(k)*t_m2 + P.fase_rx(k)));   % detección coherente con tau_k compensado
        y = filter(P.h.post, 1, y);
        y = y(1:P.M3:end);
        Y(k,:) = y(1:Na);
    end

    R.Y = Y; R.xb = xb; R.m_rf = m_rf; R.m = m; R.m_n = m_n; R.m_hat = m_hat; R.fi = fi; R.s = s; R.r = r;
end

function y = retrasar(x, d)
% Retardo entero de d muestras (con ceros al inicio), igual que una cadena de retardos.
    if d <= 0, y = x; return; end
    y = [zeros(1, d) x(1:end-d)];
end
