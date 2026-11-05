function radio_fdm_fm()
%RADIO_FDM_FM  Interfaz tipo radio del sistema FDM + FM + receptor superheterodino.
%   >> radio_fdm_fm      (o ejecutar main.m)
%
%   DOS SELECCIONES INDEPENDIENTES [doc §7]:
%     1) SINTONÍA RF (perilla): fija la portadora de 9 a 11 MHz. Al moverla se recalculan
%        al instante el LO (f_c - 1.7 MHz), la imagen y el preselector; "Sintonizar y
%        simular" ejecuta el modelo Simulink con esos parámetros.
%     2) AUDIO 1 / 2 / 3: elige qué salida del demultiplexor FDM se grafica y se escucha.
%        NO vuelve a simular ni toca el LO (la selección ocurre después de la demodulación).
%   Todas las frecuencias se muestran en valores NOMINALES (simulado x K): el escalamiento
%   es transparente para el usuario. Solo usa MATLAB básico (uifigure) + Simulink.

    mdl = 'sistema_fdm_fm';
    S = struct();                 % estado: parámetros, fuentes, resultados
    S.P = [];  S.fuente = [];  S.out = [];  S.fuente_sim = [];  S.P_sim = [];

    %% ---------------- ventana ----------------
    fig = uifigure('Name', 'Radio FM superheterodina - FDM de 3 canales', 'Position', [60 60 1320 780]);
    g = uigridlayout(fig, [1 2]);
    g.ColumnWidth = {330, '1x'};

    % ---- panel de controles
    pc = uipanel(g, 'Title', 'Radio');
    gl = uigridlayout(pc, [19 2]);
    gl.RowHeight = {150, 22, 22, 22, 22, 22, 22, 10, 22, 28, 10, 22, 22, 22, 22, 22, 30, 30, '1x'};
    gl.ColumnWidth = {150, '1x'};

    perilla = uiknob(gl, 'continuous', 'Limits', [9 11], 'Value', 10, ...
        'MajorTicks', 9:0.5:11, 'MinorTicks', 9:0.1:11, 'ValueChangedFcn', @(~,~) cambio_sintonia());
    perilla.Layout.Row = 1; perilla.Layout.Column = [1 2];

    etiqueta(gl, 2, 'Portadora f_c:');        lbl_fc  = valor(gl, 2);
    etiqueta(gl, 3, 'Oscilador local f_LO:'); lbl_lo  = valor(gl, 3);
    etiqueta(gl, 4, 'Frecuencia intermedia:'); lbl_fi = valor(gl, 4);
    etiqueta(gl, 5, 'Frecuencia imagen:');    lbl_im  = valor(gl, 5);
    etiqueta(gl, 6, 'Desviación / Carson:');  lbl_bw  = valor(gl, 6);
    etiqueta(gl, 7, 'Desintonía RX [kHz]:');
    ed_des = uieditfield(gl, 'numeric', 'Value', 0, 'Limits', [-1000 1000], ...
        'ValueChangedFcn', @(~,~) cambio_sintonia());
    ed_des.Layout.Row = 7; ed_des.Layout.Column = 2;

    etiqueta(gl, 9, 'Audio de salida:');
    dd_canal = uidropdown(gl, 'Items', {'Audio 1', 'Audio 2', 'Audio 3'}, 'Value', 'Audio 1', ...
        'ValueChangedFcn', @(~,~) graficar_canal());
    dd_canal.Layout.Row = 9; dd_canal.Layout.Column = 2;
    lbl_sdr = uilabel(gl, 'Text', 'SDR: -', 'FontWeight', 'bold');
    lbl_sdr.Layout.Row = 10; lbl_sdr.Layout.Column = [1 2];

    etiqueta(gl, 12, 'Fuente de audio:');
    dd_fuente = uidropdown(gl, 'Items', {'demo', 'tonos', 'ruido', 'audio'}, 'Value', 'demo');
    dd_fuente.Layout.Row = 12; dd_fuente.Layout.Column = 2;
    etiqueta(gl, 13, 'Duración [s reales]:');
    ed_T = uieditfield(gl, 'numeric', 'Value', 0.3, 'Limits', [0.02 3]);
    ed_T.Layout.Row = 13; ed_T.Layout.Column = 2;
    cb_awgn = uicheckbox(gl, 'Text', 'Canal AWGN', 'Value', false);
    cb_awgn.Layout.Row = 14; cb_awgn.Layout.Column = 1;
    etiqueta(gl, 15, '(SNR)_C [dB]:');
    ed_snr = uieditfield(gl, 'numeric', 'Value', 25, 'Limits', [0 60]);
    ed_snr.Layout.Row = 15; ed_snr.Layout.Column = 2;
    cb_enf = uicheckbox(gl, 'Text', 'Prénfasis / deénfasis', 'Value', false);
    cb_enf.Layout.Row = 16; cb_enf.Layout.Column = [1 2];

    bt_sim = uibutton(gl, 'Text', 'Sintonizar y simular', 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(~,~) simular());
    bt_sim.Layout.Row = 17; bt_sim.Layout.Column = [1 2];
    bt_rx = uibutton(gl, 'Text', 'Escuchar recuperado', 'ButtonPushedFcn', @(~,~) escuchar(true));
    bt_rx.Layout.Row = 18; bt_rx.Layout.Column = 1;
    bt_tx = uibutton(gl, 'Text', 'Escuchar original', 'ButtonPushedFcn', @(~,~) escuchar(false));
    bt_tx.Layout.Row = 18; bt_tx.Layout.Column = 2;
    lbl_estado = uilabel(gl, 'Text', 'Listo. Elija la portadora y presione "Sintonizar y simular".', ...
        'WordWrap', 'on', 'VerticalAlignment', 'top');
    lbl_estado.Layout.Row = 19; lbl_estado.Layout.Column = [1 2];

    % ---- gráficas
    ga = uigridlayout(g, [2 2]);
    ax_rf  = uiaxes(ga); title(ax_rf,  'Espectro RF recibido');
    ax_mez = uiaxes(ga); title(ax_mez, 'Salida del mezclador');
    ax_mux = uiaxes(ga); title(ax_mux, 'Multiplex FDM recuperado');
    ax_t   = uiaxes(ga); title(ax_t,   'Audio seleccionado');

    cambio_sintonia();

    %% ================= funciones internas =================
    function cambio_sintonia()
        % Se ejecuta al mover la perilla: recalcula LO, imagen, preselector (sin simular).
        fc = round(perilla.Value * 10) / 10;           % pasos de 0.1 MHz
        perilla.Value = fc;
        S.P = params_sistema(fc * 1e6, struct('imprimir', false, 'desintonia', ed_des.Value * 1e3));
        V = S.P.vista;
        lbl_fc.Text = sprintf('%.1f MHz', V.fc_MHz);
        lbl_lo.Text = sprintf('%.2f MHz', V.fLO_MHz);
        lbl_fi.Text = sprintf('%.1f MHz', V.fFI_MHz);
        lbl_im.Text = sprintf('%.2f MHz', V.fimagen_MHz);
        lbl_bw.Text = sprintf('%.0f / %.0f kHz', V.df_kHz, V.carson_kHz);
        if ~isempty(S.out)
            lbl_estado.Text = 'Parámetros actualizados. Presione "Sintonizar y simular" para ver el efecto.';
        end
    end

    function simular()
        bt_sim.Enable = 'off';
        try
            T = ed_T.Value;
            snr = Inf;  if cb_awgn.Value, snr = ed_snr.Value; end
            fc = perilla.Value;
            P = params_sistema(fc * 1e6, struct('imprimir', false, 'T_real', T, 'snr_c_dB', snr, ...
                'desintonia', ed_des.Value * 1e3, 'log_rf_max', 2^18, 'enfasis', cb_enf.Value));
            rng(1);
            fuente = generar_fuentes(P, dd_fuente.Value);
            lbl_estado.Text = sprintf(['Simulando %.2f s reales (%.0f s simulados)... ' ...
                'En modo acelerado tarda unos %.0f s (más la 1.ª vez, que compila).'], T, P.T_sim, 270*T);
            drawnow;
            modelo_al_dia(mdl);            % regenera el .slx si es de una versión anterior
            load_system(mdl);
            assignin('base', 'P', P);
            assignin('base', 'fuente', fuente);
            try
                set_param(mdl, 'SimulationMode', 'accelerator');
                tic; out = sim(mdl);
            catch
                set_param(mdl, 'SimulationMode', 'normal');
                tic; out = sim(mdl);
            end
            t_sim = toc;
            S.out = out;  S.P_sim = P;  S.fuente_sim = fuente;
            graficar_todo();
            pico = max(abs(out.sim_m_n(:)));       % pico de m_n = desviación usada / Df
            lbl_estado.Text = sprintf(['Simulación lista en %.1f s. f_c = %.1f MHz, LO = %.2f MHz%s%s. ' ...
                'Desviación pico usada: %.0f %% de %.0f kHz.'], ...
                t_sim, P.vista.fc_MHz, P.vista.fLO_MHz, ternario(isinf(snr), ', canal ideal', sprintf(', (SNR)_C = %g dB', snr)), ...
                ternario(P.enfasis, ', con prénfasis', ''), 100*pico, P.vista.df_kHz);
        catch err
            lbl_estado.Text = ['Error: ' err.message];
        end
        bt_sim.Enable = 'on';
    end

    function graficar_todo()
        P = S.P_sim;  K = P.K;  out = S.out;
        % espectro RF (muestras finales registradas)
        % señal recibida r = s (+ ruido, si hay AWGN), últimas muestras registradas
        [f, D] = graficar_espectro(out.sim_r(:).', P.fs_rf, K, struct('nfft', 2^14));
        cla(ax_rf); plot(ax_rf, f/1e6, D); hold(ax_rf, 'on');
        yl = [-100 5];
        plot(ax_rf, P.fc_rx*K/1e6*[1 1], yl, 'r--');
        plot(ax_rf, P.f_imagen*K/1e6*[1 1], yl, 'm:');
        hold(ax_rf, 'off'); grid(ax_rf, 'on'); ylim(ax_rf, yl);
        xlim(ax_rf, [P.fc*K/1e6 - 4.5, P.fc*K/1e6 + 2]);
        xlabel(ax_rf, 'f [MHz]'); ylabel(ax_rf, 'DEP [dB]');
        legend(ax_rf, {'señal', 'sintonía RX', 'imagen'}, 'Location', 'northwest');
        title(ax_rf, sprintf('RF: portadora %.1f MHz', P.vista.fc_MHz));

        [f, D] = graficar_espectro(out.sim_mezcla(:).', P.fs_rf, K, struct('nfft', 2^14));
        cla(ax_mez); plot(ax_mez, f/1e6, D); hold(ax_mez, 'on');
        plot(ax_mez, P.f_FI*K/1e6*[1 1], yl, 'r--'); plot(ax_mez, P.f_suma*K/1e6*[1 1], yl, 'm--');
        hold(ax_mez, 'off'); grid(ax_mez, 'on'); ylim(ax_mez, yl); xlim(ax_mez, [0 24]);
        xlabel(ax_mez, 'f [MHz]'); ylabel(ax_mez, 'DEP [dB]');
        legend(ax_mez, {'mezcla', 'FI 1.7 MHz', 'f_c + f_{LO}'}, 'Location', 'northeast');
        title(ax_mez, sprintf('Mezclador: LO = %.2f MHz', P.vista.fLO_MHz));
        graficar_canal();
    end

    function graficar_canal()
        % Selección del audio: solo cambia la salida mostrada (no simula, no toca el LO).
        if isempty(S.out), return; end
        P = S.P_sim;  K = P.K;  out = S.out;  k = canal();
        mh = out.sim_m_hat(:).';
        [f, D] = graficar_espectro(mh, P.fs_m, K, struct('nfft', 4096));
        cla(ax_mux); hold(ax_mux, 'on');
        b = (P.f_sc(k) + [-1 1]*P.Wa) * K / 1e3;
        patch(ax_mux, [b(1) b(2) b(2) b(1)], [-100 -100 5 5], [1 0.9 0.6], 'EdgeColor', 'none');
        plot(ax_mux, f/1e3, D, 'k');
        hold(ax_mux, 'off'); grid(ax_mux, 'on'); ylim(ax_mux, [-100 5]); xlim(ax_mux, [0 240]);
        xlabel(ax_mux, 'f [kHz]'); ylabel(ax_mux, 'DEP [dB]');
        title(ax_mux, sprintf('Multiplex recuperado: canal %d resaltado (%d-%d kHz)', k, round(b(1)), round(b(2))));

        y = out.(sprintf('sim_y%d', k))(:).';
        x = S.fuente_sim.X(k,:);
        n = min(numel(x), numel(y));
        [sdr, ~] = comparar_senales(x(1:n), y(1:n), P.retardo_audio(k), P.fs_a);
        lbl_sdr.Text = sprintf('SDR del audio %d: %.1f dB', k, sdr);
        tr = (0:n-1) / P.fs_a / K * 1e3;               % ms reales
        t0 = min(20, max(tr) / 2);  v = tr >= t0 & tr <= t0 + 5;
        ty = tr - P.retardo_audio(k) / K * 1e3;  vy = ty >= t0 & ty <= t0 + 5;
        cla(ax_t); plot(ax_t, tr(v), x(v), 'Color', [0.6 0.6 0.6], 'LineWidth', 2); hold(ax_t, 'on');
        plot(ax_t, ty(vy), y(vy), 'k'); hold(ax_t, 'off'); grid(ax_t, 'on');
        xlabel(ax_t, 'tiempo real [ms]'); legend(ax_t, {'original', 'recuperado'});
        title(ax_t, sprintf('Audio %d: original vs recuperado (retardo descontado)', k));
    end

    function escuchar(recuperado)
        if isempty(S.out), lbl_estado.Text = 'Primero simule.'; return; end
        k = canal();
        if recuperado
            y = S.out.(sprintf('sim_y%d', k))(:).';
        else
            y = S.fuente_sim.X(k,:);
        end
        if max(abs(y)) > 0, y = 0.9 * y / max(abs(y)); end
        sound(y, S.P_sim.fs_audio_real);    % 48 kHz reales: deshace el escalamiento K
    end

    function k = canal()
        k = find(strcmp(dd_canal.Items, dd_canal.Value));
    end
end

function etiqueta(gl, fila, texto)
    l = uilabel(gl, 'Text', texto);  l.Layout.Row = fila;  l.Layout.Column = 1;
end
function l = valor(gl, fila)
    l = uilabel(gl, 'Text', '-', 'FontWeight', 'bold');  l.Layout.Row = fila;  l.Layout.Column = 2;
end
function v = ternario(c, a, b)
    if c, v = a; else, v = b; end
end
