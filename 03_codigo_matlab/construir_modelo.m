function construir_modelo(nombre)
%CONSTRUIR_MODELO  Genera el modelo Simulink del sistema a partir de bloques básicos.
%   construir_modelo()            crea/reemplaza 'sistema_fdm_fm.slx' en la carpeta actual
%
%   Contiene: fuentes, transmisor FDM (DSB-SC + prénfasis opcional), modulador FM, canal
%   (ideal/AWGN), receptor superheterodino (con deénfasis opcional) y demultiplexor FDM.
%   La GUI (radio_fdm_fm.m) solo cambia parámetros y llama a sim().
%   El .slx siempre se puede regenerar ejecutando este script.
%
%   Los bloques NO contienen números escritos a mano: todo se lee de las variables del
%   workspace base 'P' (params_sistema) y 'fuente' (generar_fuentes).
%   Solo usa la biblioteca básica de Simulink (sin DSP System Toolbox).

    if nargin < 1, nombre = 'sistema_fdm_fm'; end
    mdl = nombre;
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
    new_system(mdl);
    open_system(mdl);

    %% Configuración del solver: discreto, paso fijo, una sola tarea [§8 del enunciado]
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 'auto', 'StopTime', 'fuente.T_stop');
    % Una sola tarea para todas las tasas. Aun así, cada Rate Transition de tasa lenta a
    % rápida retrasa 1 muestra lenta (medido en verificar_etapa2); params_sistema lo incluye
    % en tau_k con P.rt_retardo.
    try, set_param(mdl, 'EnableMultiTasking', 'off'); catch, end
    try, set_param(mdl, 'SolverMode', 'SingleTasking'); catch, end
    set_param(mdl, 'ReturnWorkspaceOutputs', 'on');

    %% ---------------- Fuentes de audio ----------------
    for k = 1:3
        add_block('simulink/Sources/From Workspace', sprintf('%s/Audio%d', mdl, k), ...
            'VariableName', sprintf('fuente.audio%d', k), ...
            'SampleTime', '1/P.fs_a', ...
            'Interpolate', 'off', ...
            'OutputAfterFinalValue', 'Setting to zero', ...
            'Position', caja(40, 60 + 90*(k-1), 110, 30));
    end

    %% ---------------- Transmisor FDM ----------------
    tx = [mdl '/Transmisor_FDM'];
    add_block('built-in/Subsystem', tx, 'Position', caja(220, 70, 160, 200));
    construir_tx_fdm(tx);
    set_param(tx, 'Description', ...
        'FDM DSB-SC: LPF 15 kHz, interpolación x10 por inserción de ceros, subportadoras 20/60/100 kHz nom, m_n = m/3, prénfasis (opcional)');

    for k = 1:3
        add_line(mdl, sprintf('Audio%d/1', k), sprintf('Transmisor_FDM/%d', k), 'autorouting', 'on');
    end

    %% ---------------- Modulador FM (etapa 3) ----------------
    fm = [mdl '/Modulador_FM'];
    add_block('built-in/Subsystem', fm, 'Position', caja(480, 70, 160, 120));
    construir_modulador_fm(fm);
    set_param(fm, 'Description', ...
        'Interpolación x100 en dos etapas x10 (fs_m -> fs_fi -> fs_rf) y FM: s = Ac cos(2 pi fc t + 2 pi kf * suma(m_n)/fs_rf)');
    add_line(mdl, 'Transmisor_FDM/1', 'Modulador_FM/1', 'autorouting', 'on');

    %% ---------------- Canal (etapa 4): ideal o AWGN ----------------
    ch = [mdl '/Canal'];
    add_block('built-in/Subsystem', ch, 'Position', caja(720, 85, 120, 60));
    construir_canal(ch);
    set_param(ch, 'Description', 'r = s + n, n gaussiano de varianza P.sigma_ruido^2 (0 = canal ideal). (SNR)_C de Haykin, doc 6.9');
    add_line(mdl, 'Modulador_FM/1', 'Canal/1', 'autorouting', 'on');

    %% ---------------- Receptor superheterodino (etapa 5) ----------------
    rx = [mdl '/Receptor_Superheterodino'];
    add_block('built-in/Subsystem', rx, 'Position', caja(900, 70, 170, 120));
    construir_receptor(rx);
    set_param(rx, 'Description', ['Sección RF (preselector en f_c) -> mezclador con LO = f_c - f_FI -> ' ...
        'pasabajos + decimación -> pasabanda FI 1.7 MHz -> demodulador FM en cuadratura -> filtro posdetección -> deénfasis (opcional)']);
    add_line(mdl, 'Canal/1', 'Receptor_Superheterodino/1', 'autorouting', 'on');

    %% ---------------- Demultiplexor FDM (etapa 6) ----------------
    dm = [mdl '/Demultiplexor_FDM'];
    add_block('built-in/Subsystem', dm, 'Position', caja(1140, 70, 160, 200));
    construir_demux(dm);
    set_param(dm, 'Description', 'Por canal: BPF -> x 2cos(2 pi f_k (t - tau_k)) -> LPF 15 kHz -> decimación a fs_a');
    add_line(mdl, 'Receptor_Superheterodino/1', 'Demultiplexor_FDM/1', 'autorouting', 'on');

    %% ---------------- Registro de señales ----------------
    a_workspace(mdl, 'Log_m_n',  'sim_m_n',  caja(480, 230, 90, 30));
    a_workspace(mdl, 'Log_m',    'sim_m',    caja(480, 290, 90, 30));
    a_workspace(mdl, 'Log_s_rf', 'sim_s',    caja(720, 200, 90, 30), 'P.log_rf_max');
    a_workspace(mdl, 'Log_m_rf', 'sim_m_rf', caja(720, 260, 90, 30), 'P.log_rf_max');
    a_workspace(mdl, 'Log_mezcla', 'sim_mezcla', caja(1140, 300, 90, 30), 'P.log_rf_max');
    a_workspace(mdl, 'Log_r_rf',   'sim_r',      caja(900, 230, 90, 30), 'P.log_rf_max');
    add_line(mdl, 'Canal/1', 'Log_r_rf/1', 'autorouting', 'on');
    a_workspace(mdl, 'Log_fi',     'sim_fi',     caja(1140, 350, 90, 30));
    a_workspace(mdl, 'Log_m_hat',  'sim_m_hat',  caja(1140, 400, 90, 30));
    add_line(mdl, 'Transmisor_FDM/1', 'Log_m_n/1', 'autorouting', 'on');
    add_line(mdl, 'Transmisor_FDM/2', 'Log_m/1',   'autorouting', 'on');
    add_line(mdl, 'Modulador_FM/1', 'Log_s_rf/1', 'autorouting', 'on');
    add_line(mdl, 'Modulador_FM/2', 'Log_m_rf/1', 'autorouting', 'on');
    add_line(mdl, 'Receptor_Superheterodino/1', 'Log_m_hat/1', 'autorouting', 'on');
    add_line(mdl, 'Receptor_Superheterodino/2', 'Log_fi/1',    'autorouting', 'on');
    add_line(mdl, 'Receptor_Superheterodino/3', 'Log_mezcla/1','autorouting', 'on');
    for k = 1:3
        a_workspace(mdl, sprintf('Log_audio%d', k), sprintf('sim_y%d', k), caja(1380, 75 + 70*(k-1), 90, 30));
        add_line(mdl, sprintf('Demultiplexor_FDM/%d', k), sprintf('Log_audio%d/1', k), 'autorouting', 'on');
    end

    % marca de versión: la GUI y main.m regeneran el modelo si no coincide
    set_param(mdl, 'Description', sprintf('version_modelo=%d', version_modelo()));
    save_system(mdl, fullfile(pwd, [mdl '.slx']));
    try
        fprintf('Multitarea: %s\n', get_param(mdl, 'EnableMultiTasking'));
    catch
    end
    fprintf('Modelo %s.slx creado (fuentes, FDM, FM, canal, superheterodino, demux).\n', mdl);
end

% =========================================================================
function construir_tx_fdm(tx)
% Dentro de Transmisor_FDM: 3 ramas DSB-SC, suma y normalización.
    for k = 1:3
        add_block('built-in/Inport', sprintf('%s/audio%d', tx, k), 'Position', caja(30, 50 + 120*(k-1), 30, 14));
        rama = sprintf('%s/Canal%d_DSB', tx, k);
        add_block('built-in/Subsystem', rama, 'Position', caja(130, 35 + 120*(k-1), 140, 50));
        construir_rama_dsb(rama, k);
        add_line(tx, sprintf('audio%d/1', k), sprintf('Canal%d_DSB/1', k), 'autorouting', 'on');
    end
    add_block('simulink/Math Operations/Add', [tx '/Suma_FDM'], 'Inputs', '+++', ...
        'Position', caja(340, 140, 30, 80));
    for k = 1:3
        add_line(tx, sprintf('Canal%d_DSB/1', k), sprintf('Suma_FDM/%d', k), 'autorouting', 'on');
    end
    add_block('simulink/Math Operations/Gain', [tx '/Normalizacion'], 'Gain', '1/P.normalizacion', ...
        'Position', caja(420, 165, 50, 30));
    add_line(tx, 'Suma_FDM/1', 'Normalizacion/1', 'autorouting', 'on');
    % Prénfasis del multiplex (curso, diap. 384): y[n] = g (x[n] - a x[n-1]).
    % Con P.enfasis = false, P.enf.num_tx = [1 0] y el bloque es un cable.
    add_block('simulink/Discrete/Discrete Filter', [tx '/Prenfasis'], ...
        'Numerator', 'P.enf.num_tx', 'Denominator', '1', 'SampleTime', '-1', ...
        'Position', caja(500, 165, 80, 30));
    set_param([tx '/Prenfasis'], 'Description', ...
        'Prénfasis H(z) = g (1 - a z^-1): realza los canales altos antes del modulador FM');
    add_block('built-in/Outport', [tx '/m_n'], 'Position', caja(620, 173, 30, 14));
    add_block('built-in/Outport', [tx '/m'],   'Position', caja(620, 253, 30, 14));
    add_line(tx, 'Normalizacion/1', 'Prenfasis/1', 'autorouting', 'on');
    add_line(tx, 'Prenfasis/1', 'm_n/1', 'autorouting', 'on');
    add_line(tx, 'Suma_FDM/1', 'm/1', 'autorouting', 'on');
end

function construir_rama_dsb(rama, k)
% x_k -> LPF 15 kHz -> (fs_a -> fs_m) -> inserción de ceros -> filtro interpolador
%     -> x cos(2 pi f_k t)
    add_block('built-in/Inport', [rama '/x'], 'Position', caja(20, 63, 30, 14));

    add_block('simulink/Discrete/Discrete Filter', [rama '/LPF_audio_15kHz'], ...
        'Numerator', 'P.h.audio_tx', 'Denominator', '1', 'SampleTime', '-1', ...
        'Position', caja(80, 55, 100, 30));

    add_block('simulink/Signal Attributes/Rate Transition', [rama '/Cambio_tasa'], ...
        'OutPortSampleTime', '1/P.fs_m', 'Integrity', 'on', 'Deterministic', 'off', ...
        'Position', caja(210, 55, 50, 30));

    add_block('simulink/Sources/Pulse Generator', [rama '/Tren_pulsos_L1'], ...
        'PulseType', 'Sample based', 'Amplitude', '1', 'Period', 'P.L1', ...
        'PulseWidth', '1', 'PhaseDelay', '0', 'SampleTime', '1/P.fs_m', ...
        'Position', caja(210, 120, 50, 30));

    add_block('simulink/Math Operations/Product', [rama '/Insercion_ceros'], ...
        'Position', caja(290, 62, 30, 40));

    add_block('simulink/Discrete/Discrete Filter', [rama '/Filtro_interpolador'], ...
        'Numerator', 'P.h.interp1', 'Denominator', '1', 'SampleTime', '-1', ...
        'Position', caja(350, 67, 100, 30));

    add_block('simulink/Sources/Sine Wave', [rama '/Subportadora'], ...
        'SineType', 'Time based', 'Amplitude', '1', ...
        'Frequency', sprintf('2*pi*P.f_sc(%d)', k), 'Phase', 'pi/2', ...   % cos = sin(.+pi/2)
        'Bias', '0', 'SampleTime', '1/P.fs_m', ...
        'Position', caja(350, 130, 50, 30));

    add_block('simulink/Math Operations/Product', [rama '/Modulador_DSB'], ...
        'Position', caja(490, 74, 30, 40));

    add_block('built-in/Outport', [rama '/y'], 'Position', caja(560, 87, 30, 14));

    add_line(rama, 'x/1', 'LPF_audio_15kHz/1', 'autorouting', 'on');
    add_line(rama, 'LPF_audio_15kHz/1', 'Cambio_tasa/1', 'autorouting', 'on');
    add_line(rama, 'Cambio_tasa/1', 'Insercion_ceros/1', 'autorouting', 'on');
    add_line(rama, 'Tren_pulsos_L1/1', 'Insercion_ceros/2', 'autorouting', 'on');
    add_line(rama, 'Insercion_ceros/1', 'Filtro_interpolador/1', 'autorouting', 'on');
    add_line(rama, 'Filtro_interpolador/1', 'Modulador_DSB/1', 'autorouting', 'on');
    add_line(rama, 'Subportadora/1', 'Modulador_DSB/2', 'autorouting', 'on');
    add_line(rama, 'Modulador_DSB/1', 'y/1', 'autorouting', 'on');

    % puntos de registro para depuración (audio filtrado y banda base interpolada)
    a_workspace(rama, 'Log_xa', sprintf('sim_xa%d', k), caja(210, 190, 70, 26));
    a_workspace(rama, 'Log_xb', sprintf('sim_xb%d', k), caja(490, 190, 70, 26));
    add_line(rama, 'LPF_audio_15kHz/1', 'Log_xa/1', 'autorouting', 'on');
    add_line(rama, 'Filtro_interpolador/1', 'Log_xb/1', 'autorouting', 'on');

    set_param(rama, 'Description', sprintf( ...
        'Canal %d: DSB-SC con subportadora P.f_sc(%d). Interpolación x P.L1 = Rate Transition (retención) x tren de pulsos -> inserción de ceros; luego FIR con ganancia L1.', k, k));
end

function construir_modulador_fm(fm)
% m_n (fs_m) -> interpolación x L2a (-> fs_fi) -> interpolación x L2b (-> fs_rf)
%             -> integrador -> fase -> cos
    add_block('built-in/Inport', [fm '/m_n'], 'Position', caja(20, 63, 30, 14));
    etapa_interpolacion(fm, 'a', 'P.fs_fi', 'P.L2a', 'P.h.interp2a', 70);
    etapa_interpolacion(fm, 'b', 'P.fs_rf', 'P.L2b', 'P.h.interp2b', 330);
    add_line(fm, 'm_n/1', 'Cambio_tasa_a/1', 'autorouting', 'on');
    add_line(fm, 'Interpolador_a/1', 'Cambio_tasa_b/1', 'autorouting', 'on');

    % integral de m_n: Euler hacia atrás = suma acumulada incluyendo la muestra actual
    add_block('simulink/Discrete/Discrete-Time Integrator', [fm '/Integrador'], ...
        'IntegratorMethod', 'Integration: Backward Euler', 'gainval', '1', ...
        'InitialCondition', '0', 'SampleTime', '-1', 'Position', caja(620, 67, 50, 30));
    add_block('simulink/Math Operations/Gain', [fm '/Ganancia_2pi_kf'], 'Gain', '2*pi*P.kf', ...
        'Position', caja(700, 67, 60, 30));
    % fase de la portadora 2 pi fc t
    add_block('simulink/Sources/Digital Clock', [fm '/Reloj'], 'SampleTime', '1/P.fs_rf', ...
        'Position', caja(620, 150, 50, 30));
    add_block('simulink/Math Operations/Gain', [fm '/Ganancia_2pi_fc'], 'Gain', '2*pi*P.fc', ...
        'Position', caja(700, 150, 60, 30));
    add_block('simulink/Math Operations/Add', [fm '/Fase_total'], 'Inputs', '++', 'Position', caja(800, 95, 30, 50));
    add_block('simulink/Math Operations/Trigonometric Function', [fm '/cos'], 'Operator', 'cos', ...
        'Position', caja(860, 105, 40, 30));
    add_block('simulink/Math Operations/Gain', [fm '/Amplitud_Ac'], 'Gain', 'P.Ac', 'Position', caja(930, 105, 40, 30));
    add_block('built-in/Outport', [fm '/s_FM'], 'Position', caja(1010, 113, 30, 14));
    add_block('built-in/Outport', [fm '/m_rf'], 'Position', caja(700, 20, 30, 14));

    add_line(fm, 'Interpolador_b/1', 'Integrador/1', 'autorouting', 'on');
    add_line(fm, 'Integrador/1', 'Ganancia_2pi_kf/1', 'autorouting', 'on');
    add_line(fm, 'Reloj/1', 'Ganancia_2pi_fc/1', 'autorouting', 'on');
    add_line(fm, 'Ganancia_2pi_kf/1', 'Fase_total/1', 'autorouting', 'on');
    add_line(fm, 'Ganancia_2pi_fc/1', 'Fase_total/2', 'autorouting', 'on');
    add_line(fm, 'Fase_total/1', 'cos/1', 'autorouting', 'on');
    add_line(fm, 'cos/1', 'Amplitud_Ac/1', 'autorouting', 'on');
    add_line(fm, 'Amplitud_Ac/1', 's_FM/1', 'autorouting', 'on');
    add_line(fm, 'Interpolador_b/1', 'm_rf/1', 'autorouting', 'on');
end

function etapa_interpolacion(sys, id, fs_salida, L, h, x0)
% Interpolación x L con bloques básicos: Rate Transition (retención) x tren de pulsos
% = inserción de ceros; luego FIR pasabajos con ganancia L.
    add_block('simulink/Signal Attributes/Rate Transition', [sys '/Cambio_tasa_' id], ...
        'OutPortSampleTime', ['1/' fs_salida], 'Integrity', 'on', 'Deterministic', 'off', ...
        'Position', caja(x0, 55, 50, 30));
    add_block('simulink/Sources/Pulse Generator', [sys '/Tren_pulsos_' id], ...
        'PulseType', 'Sample based', 'Amplitude', '1', 'Period', L, ...
        'PulseWidth', '1', 'PhaseDelay', '0', 'SampleTime', ['1/' fs_salida], ...
        'Position', caja(x0, 120, 50, 30));
    add_block('simulink/Math Operations/Product', [sys '/Insercion_ceros_' id], ...
        'Position', caja(x0 + 80, 62, 30, 40));
    add_block('simulink/Discrete/Discrete Filter', [sys '/Interpolador_' id], ...
        'Numerator', h, 'Denominator', '1', 'SampleTime', '-1', ...
        'Position', caja(x0 + 140, 67, 90, 30));
    add_line(sys, ['Cambio_tasa_' id '/1'], ['Insercion_ceros_' id '/1'], 'autorouting', 'on');
    add_line(sys, ['Tren_pulsos_' id '/1'], ['Insercion_ceros_' id '/2'], 'autorouting', 'on');
    add_line(sys, ['Insercion_ceros_' id '/1'], ['Interpolador_' id '/1'], 'autorouting', 'on');
end

function construir_canal(ch)
    add_block('built-in/Inport', [ch '/s'], 'Position', caja(20, 43, 30, 14));
    add_block('simulink/Sources/Random Number', [ch '/Ruido_gaussiano'], ...
        'Mean', '0', 'Variance', '1', 'Seed', 'P.semilla_ruido', 'SampleTime', '1/P.fs_rf', ...
        'Position', caja(20, 100, 60, 30));
    add_block('simulink/Math Operations/Gain', [ch '/sigma'], 'Gain', 'P.sigma_ruido', ...
        'Position', caja(110, 100, 50, 30));
    add_block('simulink/Math Operations/Add', [ch '/Suma_ruido'], 'Inputs', '++', ...
        'Position', caja(200, 45, 30, 50));
    add_block('built-in/Outport', [ch '/r'], 'Position', caja(270, 63, 30, 14));
    add_line(ch, 'Ruido_gaussiano/1', 'sigma/1', 'autorouting', 'on');
    add_line(ch, 's/1', 'Suma_ruido/1', 'autorouting', 'on');
    add_line(ch, 'sigma/1', 'Suma_ruido/2', 'autorouting', 'on');
    add_line(ch, 'Suma_ruido/1', 'r/1', 'autorouting', 'on');
end

function construir_receptor(rx)
% r -> preselector -> x 2cos(2 pi f_LO t) -> LPF anti-aliasing -> /M1 -> BPF FI -> demod FM
%   -> /kf -> filtro posdetección -> /M2 -> x normalización -> m_hat
    add_block('built-in/Inport', [rx '/r'], 'Position', caja(20, 63, 30, 14));
    add_block('simulink/Discrete/Discrete Filter', [rx '/Seccion_RF_preselector'], ...
        'Numerator', 'P.h.presel', 'Denominator', '1', 'SampleTime', '-1', ...
        'Position', caja(80, 55, 110, 30));
    add_block('simulink/Sources/Sine Wave', [rx '/Oscilador_local'], ...
        'SineType', 'Time based', 'Amplitude', '2', 'Frequency', '2*pi*P.f_LO', ...
        'Phase', 'pi/2', 'Bias', '0', 'SampleTime', '1/P.fs_rf', 'Position', caja(130, 130, 60, 30));
    add_block('simulink/Math Operations/Product', [rx '/Mezclador'], 'Position', caja(230, 62, 30, 40));
    add_block('simulink/Discrete/Discrete Filter', [rx '/LPF_antialiasing_FI'], ...
        'Numerator', 'P.h.fi_lpf', 'Denominator', '1', 'SampleTime', '-1', ...
        'Position', caja(300, 67, 100, 30));
    add_block('simulink/Signal Attributes/Rate Transition', [rx '/Decimacion_M1'], ...
        'OutPortSampleTime', '1/P.fs_fi', 'Integrity', 'on', 'Deterministic', 'off', ...
        'Position', caja(430, 67, 50, 30));
    add_block('simulink/Discrete/Discrete Filter', [rx '/Seccion_FI_pasabanda'], ...
        'Numerator', 'P.h.fi', 'Denominator', '1', 'SampleTime', '-1', ...
        'Position', caja(510, 67, 100, 30));
    dem = [rx '/Demodulador_FM'];
    add_block('built-in/Subsystem', dem, 'Position', caja(650, 55, 120, 55));
    construir_demodulador_fm(dem);
    set_param(dem, 'Description', 'Cuadratura: z = FI * exp(-j 2 pi f_FI t), LPF, f_i = fs/(2 pi) * atan2(Im, Re) de z[n] z*[n-1]');
    add_block('simulink/Math Operations/Gain', [rx '/Escala_1_kf'], 'Gain', '1/P.kf', ...
        'Position', caja(800, 67, 50, 30));
    add_block('simulink/Discrete/Discrete Filter', [rx '/Filtro_posdeteccion'], ...
        'Numerator', 'P.h.mux', 'Denominator', '1', 'SampleTime', '-1', ...
        'Position', caja(880, 67, 100, 30));
    add_block('simulink/Signal Attributes/Rate Transition', [rx '/Decimacion_M2'], ...
        'OutPortSampleTime', '1/P.fs_m', 'Integrity', 'on', 'Deterministic', 'off', ...
        'Position', caja(1010, 67, 50, 30));
    add_block('simulink/Math Operations/Gain', [rx '/Deshace_normalizacion'], 'Gain', 'P.normalizacion', ...
        'Position', caja(1090, 67, 50, 30));
    % Deénfasis justo después del demodulador (curso, diap. 384): inverso exacto del prénfasis,
    % H(z) = (1/g) / (1 - a z^-1). Con P.enfasis = false es un cable.
    add_block('simulink/Discrete/Discrete Filter', [rx '/Deenfasis'], ...
        'Numerator', 'P.enf.num_rx', 'Denominator', 'P.enf.den_rx', 'SampleTime', '-1', ...
        'Position', caja(1170, 67, 80, 30));
    set_param([rx '/Deenfasis'], 'Description', ...
        'Deénfasis H(z) = (1/g)/(1 - a z^-1): devuelve el multiplex a su forma original y atenúa el ruido de alta frecuencia');
    add_block('built-in/Outport', [rx '/m_hat'],  'Position', caja(1290, 75, 30, 14));
    add_block('built-in/Outport', [rx '/fi'],     'Position', caja(650, 160, 30, 14));
    add_block('built-in/Outport', [rx '/mezcla'], 'Position', caja(300, 160, 30, 14));

    add_line(rx, 'r/1', 'Seccion_RF_preselector/1', 'autorouting', 'on');
    add_line(rx, 'Seccion_RF_preselector/1', 'Mezclador/1', 'autorouting', 'on');
    add_line(rx, 'Oscilador_local/1', 'Mezclador/2', 'autorouting', 'on');
    add_line(rx, 'Mezclador/1', 'LPF_antialiasing_FI/1', 'autorouting', 'on');
    add_line(rx, 'LPF_antialiasing_FI/1', 'Decimacion_M1/1', 'autorouting', 'on');
    add_line(rx, 'Decimacion_M1/1', 'Seccion_FI_pasabanda/1', 'autorouting', 'on');
    add_line(rx, 'Seccion_FI_pasabanda/1', 'Demodulador_FM/1', 'autorouting', 'on');
    add_line(rx, 'Demodulador_FM/1', 'Escala_1_kf/1', 'autorouting', 'on');
    add_line(rx, 'Escala_1_kf/1', 'Filtro_posdeteccion/1', 'autorouting', 'on');
    add_line(rx, 'Filtro_posdeteccion/1', 'Decimacion_M2/1', 'autorouting', 'on');
    add_line(rx, 'Decimacion_M2/1', 'Deshace_normalizacion/1', 'autorouting', 'on');
    add_line(rx, 'Deshace_normalizacion/1', 'Deenfasis/1', 'autorouting', 'on');
    add_line(rx, 'Deenfasis/1', 'm_hat/1', 'autorouting', 'on');
    add_line(rx, 'Seccion_FI_pasabanda/1', 'fi/1', 'autorouting', 'on');
    add_line(rx, 'Mezclador/1', 'mezcla/1', 'autorouting', 'on');
end

function construir_demodulador_fm(dem)
% I = FI*cos(w t), Q = -FI*sin(w t), filtrados; z[n] z*[n-1] = (I I1 + Q Q1) + j (Q I1 - I Q1)
% f_i = fs_fi/(2 pi) * atan2(Q I1 - I Q1, I I1 + Q Q1)
    add_block('built-in/Inport', [dem '/fi'], 'Position', caja(20, 120, 30, 14));
    add_block('simulink/Sources/Sine Wave', [dem '/cos_FI'], 'SineType', 'Time based', ...
        'Amplitude', '1', 'Frequency', '2*pi*P.f_FI', 'Phase', 'pi/2', 'Bias', '0', ...
        'SampleTime', '1/P.fs_fi', 'Position', caja(20, 40, 50, 30));
    add_block('simulink/Sources/Sine Wave', [dem '/menos_sen_FI'], 'SineType', 'Time based', ...
        'Amplitude', '-1', 'Frequency', '2*pi*P.f_FI', 'Phase', '0', 'Bias', '0', ...
        'SampleTime', '1/P.fs_fi', 'Position', caja(20, 190, 50, 30));
    add_block('simulink/Math Operations/Product', [dem '/Mezcla_I'], 'Position', caja(110, 50, 30, 40));
    add_block('simulink/Math Operations/Product', [dem '/Mezcla_Q'], 'Position', caja(110, 170, 30, 40));
    add_block('simulink/Discrete/Discrete Filter', [dem '/LPF_I'], 'Numerator', 'P.h.iq', ...
        'Denominator', '1', 'SampleTime', '-1', 'Position', caja(170, 55, 70, 30));
    add_block('simulink/Discrete/Discrete Filter', [dem '/LPF_Q'], 'Numerator', 'P.h.iq', ...
        'Denominator', '1', 'SampleTime', '-1', 'Position', caja(170, 175, 70, 30));
    add_block('simulink/Discrete/Unit Delay', [dem '/Retardo_I'], 'InitialCondition', '0', ...
        'SampleTime', '-1', 'Position', caja(270, 100, 40, 30));
    add_block('simulink/Discrete/Unit Delay', [dem '/Retardo_Q'], 'InitialCondition', '0', ...
        'SampleTime', '-1', 'Position', caja(270, 230, 40, 30));
    add_block('simulink/Math Operations/Product', [dem '/I_I1'], 'Position', caja(350, 30, 30, 40));
    add_block('simulink/Math Operations/Product', [dem '/Q_Q1'], 'Position', caja(350, 90, 30, 40));
    add_block('simulink/Math Operations/Product', [dem '/Q_I1'], 'Position', caja(350, 160, 30, 40));
    add_block('simulink/Math Operations/Product', [dem '/I_Q1'], 'Position', caja(350, 220, 30, 40));
    add_block('simulink/Math Operations/Add', [dem '/Re'], 'Inputs', '++', 'Position', caja(420, 50, 30, 50));
    add_block('simulink/Math Operations/Add', [dem '/Im'], 'Inputs', '+-', 'Position', caja(420, 180, 30, 50));
    add_block('simulink/Math Operations/Trigonometric Function', [dem '/atan2'], 'Operator', 'atan2', ...
        'Position', caja(490, 110, 50, 50));
    add_block('simulink/Math Operations/Gain', [dem '/fs_sobre_2pi'], 'Gain', 'P.fs_fi/(2*pi)', ...
        'Position', caja(570, 120, 60, 30));
    add_block('built-in/Outport', [dem '/f_inst'], 'Position', caja(670, 128, 30, 14));

    add_line(dem, 'fi/1', 'Mezcla_I/1', 'autorouting', 'on');
    add_line(dem, 'cos_FI/1', 'Mezcla_I/2', 'autorouting', 'on');
    add_line(dem, 'fi/1', 'Mezcla_Q/1', 'autorouting', 'on');
    add_line(dem, 'menos_sen_FI/1', 'Mezcla_Q/2', 'autorouting', 'on');
    add_line(dem, 'Mezcla_I/1', 'LPF_I/1', 'autorouting', 'on');
    add_line(dem, 'Mezcla_Q/1', 'LPF_Q/1', 'autorouting', 'on');
    add_line(dem, 'LPF_I/1', 'Retardo_I/1', 'autorouting', 'on');
    add_line(dem, 'LPF_Q/1', 'Retardo_Q/1', 'autorouting', 'on');
    add_line(dem, 'LPF_I/1', 'I_I1/1', 'autorouting', 'on');
    add_line(dem, 'Retardo_I/1', 'I_I1/2', 'autorouting', 'on');
    add_line(dem, 'LPF_Q/1', 'Q_Q1/1', 'autorouting', 'on');
    add_line(dem, 'Retardo_Q/1', 'Q_Q1/2', 'autorouting', 'on');
    add_line(dem, 'LPF_Q/1', 'Q_I1/1', 'autorouting', 'on');
    add_line(dem, 'Retardo_I/1', 'Q_I1/2', 'autorouting', 'on');
    add_line(dem, 'LPF_I/1', 'I_Q1/1', 'autorouting', 'on');
    add_line(dem, 'Retardo_Q/1', 'I_Q1/2', 'autorouting', 'on');
    add_line(dem, 'I_I1/1', 'Re/1', 'autorouting', 'on');
    add_line(dem, 'Q_Q1/1', 'Re/2', 'autorouting', 'on');
    add_line(dem, 'Q_I1/1', 'Im/1', 'autorouting', 'on');
    add_line(dem, 'I_Q1/1', 'Im/2', 'autorouting', 'on');
    add_line(dem, 'Im/1', 'atan2/1', 'autorouting', 'on');
    add_line(dem, 'Re/1', 'atan2/2', 'autorouting', 'on');
    add_line(dem, 'atan2/1', 'fs_sobre_2pi/1', 'autorouting', 'on');
    add_line(dem, 'fs_sobre_2pi/1', 'f_inst/1', 'autorouting', 'on');
end

function construir_demux(dm)
    add_block('built-in/Inport', [dm '/m_hat'], 'Position', caja(20, 173, 30, 14));
    for k = 1:3
        y0 = 40 + 130*(k-1);
        b  = sprintf('%s/Canal%d', dm, k);
        add_block('simulink/Discrete/Discrete Filter', [b '_BPF'], ...
            'Numerator', sprintf('P.h.canal{%d}', k), 'Denominator', '1', 'SampleTime', '-1', ...
            'Position', caja(100, y0, 90, 30));
        add_block('simulink/Sources/Sine Wave', [b '_subportadora_RX'], 'SineType', 'Time based', ...
            'Amplitude', '2', 'Frequency', sprintf('2*pi*P.f_sc(%d)', k), ...
            'Phase', sprintf('pi/2 + P.fase_rx(%d)', k), 'Bias', '0', 'SampleTime', '1/P.fs_m', ...
            'Position', caja(160, y0 + 55, 60, 30));
        add_block('simulink/Math Operations/Product', [b '_deteccion_coherente'], ...
            'Position', caja(250, y0 + 5, 30, 40));
        add_block('simulink/Discrete/Discrete Filter', [b '_LPF_15kHz'], ...
            'Numerator', 'P.h.post', 'Denominator', '1', 'SampleTime', '-1', ...
            'Position', caja(310, y0 + 10, 90, 30));
        add_block('simulink/Signal Attributes/Rate Transition', [b '_decimacion_M3'], ...
            'OutPortSampleTime', '1/P.fs_a', 'Integrity', 'on', 'Deterministic', 'off', ...
            'Position', caja(430, y0 + 10, 50, 30));
        add_block('built-in/Outport', sprintf('%s/audio%d', dm, k), 'Position', caja(520, y0 + 18, 30, 14));
        n = sprintf('Canal%d', k);
        add_line(dm, 'm_hat/1', [n '_BPF/1'], 'autorouting', 'on');
        add_line(dm, [n '_BPF/1'], [n '_deteccion_coherente/1'], 'autorouting', 'on');
        add_line(dm, [n '_subportadora_RX/1'], [n '_deteccion_coherente/2'], 'autorouting', 'on');
        add_line(dm, [n '_deteccion_coherente/1'], [n '_LPF_15kHz/1'], 'autorouting', 'on');
        add_line(dm, [n '_LPF_15kHz/1'], [n '_decimacion_M3/1'], 'autorouting', 'on');
        add_line(dm, [n '_decimacion_M3/1'], sprintf('audio%d/1', k), 'autorouting', 'on');
    end
end

function a_workspace(sys, nombre_bloque, variable, pos, max_puntos)
    if nargin < 5, max_puntos = 'inf'; end
    add_block('simulink/Sinks/To Workspace', [sys '/' nombre_bloque], ...
        'VariableName', variable, 'SaveFormat', 'Array', 'MaxDataPoints', max_puntos, ...
        'SampleTime', '-1', 'Position', pos);
end

function p = caja(x, y, w, h)
    p = [x y x+w y+h];
end
