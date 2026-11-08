function radio_fdm_fm()
%RADIO_FDM_FM  Interfaz tipo radio del sistema FDM + FM + receptor superheterodino.
%   >> radio_fdm_fm      (o ejecutar main.m)
%
%   DOS SELECCIONES INDEPENDIENTES:
%     1) SINTONÍA RF (dial de 9 a 11 MHz y botones de ±0.1 MHz): fija la portadora. Al
%        moverla se recalculan al instante el LO (f_c - 1.7 MHz), la imagen y el preselector;
%        "Sintonizar y simular" ejecuta el modelo Simulink con esos parámetros.
%     2) AUDIO 1 / 2 / 3: elige qué salida del demultiplexor FDM se grafica y se escucha.
%        NO vuelve a simular ni toca el LO (la selección ocurre después de la demodulación).
%   Cada simulación queda guardada: al volver a una combinación ya simulada (ruido,
%   prénfasis, portadora...) se muestra al instante. "Simular las 4 combinaciones" deja
%   listas la de canal ideal y la de ruido, cada una sin y con prénfasis.
%   Todas las frecuencias se muestran en valores NOMINALES (simulado x K): el escalamiento
%   es transparente para el usuario. Solo usa MATLAB básico (uifigure) + Simulink.

    mdl = 'sistema_fdm_fm';
    S = struct();                 % estado: parámetros, fuentes, resultados
    S.P = [];  S.fuente = [];  S.out = [];  S.fuente_sim = [];  S.P_sim = [];
    S.memo = containers.Map();    % simulaciones ya hechas: se vuelven a mostrar sin simular

    %% ---------------- ventana ----------------
    fig = uifigure('Name', 'Radio FM superheterodina - FDM de 3 canales', 'Position', [40 40 1360 760]);
    g = uigridlayout(fig, [1 2]);
    g.ColumnWidth = {390, '1x'};

    % ---- columna de controles: cuatro bloques (se desplaza si la pantalla es pequeña)
    gc = uigridlayout(g, [5 1], 'Scrollable', 'on', 'RowSpacing', 8, 'Padding', [4 4 4 4]);
    gc.RowHeight = {220, 195, 105, 125, '1x'};

    % 1) Sintonía: pantalla, dial y valores que se recalculan al sintonizar
    p1 = uipanel(gc, 'Title', 'Sintonía', 'FontWeight', 'bold');
    g1 = uigridlayout(p1, [5 4], 'RowSpacing', 4, 'Padding', [8 6 8 6]);
    g1.RowHeight = {52, 50, 20, 20, 24};
    g1.ColumnWidth = {'1x', '1x', '1x', '1x'};
    bt_menos = uibutton(g1, 'Text', char(9664), 'FontSize', 18, 'Tooltip', 'Bajar 0.1 MHz', ...
        'ButtonPushedFcn', @(~,~) paso(-0.1));
    bt_menos.Layout.Row = 1; bt_menos.Layout.Column = 1;
    lcd = uilabel(g1, 'Text', '10.0 MHz', 'FontName', 'Consolas', 'FontSize', 30, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'FontColor', [0.40 1.00 0.55], 'BackgroundColor', [0.06 0.10 0.08]);
    lcd.Layout.Row = 1; lcd.Layout.Column = [2 3];
    bt_mas = uibutton(g1, 'Text', char(9654), 'FontSize', 18, 'Tooltip', 'Subir 0.1 MHz', ...
        'ButtonPushedFcn', @(~,~) paso(0.1));
    bt_mas.Layout.Row = 1; bt_mas.Layout.Column = 4;
    % dial de la radio: escala de 9 a 11 MHz, como la banda de un receptor analógico
    dial = uislider(g1, 'Limits', [9 11], 'Value', 10, 'MajorTicks', 9:0.5:11, ...
        'MinorTicks', 9:0.1:11, 'ValueChangingFcn', @(~,ev) mostrar_fc(ev.Value), ...
        'ValueChangedFcn', @(~,~) cambio_sintonia());
    dial.Layout.Row = 2; dial.Layout.Column = [1 4];
    par(g1, 3, 1, 'f_LO:');     lbl_lo = par(g1, 3, 2);
    par(g1, 3, 3, 'FI:');       lbl_fi = par(g1, 3, 4);
    par(g1, 4, 1, 'Imagen:');   lbl_im = par(g1, 4, 2);
    par(g1, 4, 3, 'Δf / B_T:'); lbl_bw = par(g1, 4, 4);
    par(g1, 5, [1 2], 'Desintonía RX [kHz]:');
    ed_des = uieditfield(g1, 'numeric', 'Value', 0, 'Limits', [-1000 1000], ...
        'ValueChangedFcn', @(~,~) cambio_sintonia());
    ed_des.Layout.Row = 5; ed_des.Layout.Column = [3 4];

    % 2) Señal y canal
    p2 = uipanel(gc, 'Title', 'Señal y canal', 'FontWeight', 'bold');
    g2 = uigridlayout(p2, [5 2], 'RowSpacing', 6, 'Padding', [8 6 8 6]);
    g2.RowHeight = {22, 22, 22, 42, 22};
    g2.ColumnWidth = {130, '1x'};
    par(g2, 1, 1, 'Fuente de audio:');
    dd_fuente = uidropdown(g2, 'Items', {'demo', 'tonos', 'audio'}, 'Value', 'demo', ...
        'ValueChangedFcn', @(~,~) mostrar_guardada());
    dd_fuente.Layout.Row = 1; dd_fuente.Layout.Column = 2;
    par(g2, 2, 1, 'Duración [s reales]:');
    ed_T = uieditfield(g2, 'numeric', 'Value', 0.3, 'Limits', [0.02 3], ...
        'ValueChangedFcn', @(~,~) mostrar_guardada());
    ed_T.Layout.Row = 2; ed_T.Layout.Column = 2;
    cb_awgn = uicheckbox(g2, 'Text', 'Canal AWGN', 'Value', false, ...
        'ValueChangedFcn', @(~,~) cambio_ruido());
    cb_awgn.Layout.Row = 3; cb_awgn.Layout.Column = 1;
    lbl_snr = uilabel(g2, 'Text', '(SNR)_C = 25 dB', 'FontColor', [0.5 0.5 0.5]);
    lbl_snr.Layout.Row = 3; lbl_snr.Layout.Column = 2;
    % barra de ruido: 10 dB (mucho ruido, bajo el umbral) a 40 dB (poco ruido), de 1 en 1 dB
    sl_snr = uislider(g2, 'Limits', [10 40], 'Value', 25, 'MajorTicks', 10:5:40, ...
        'MinorTicks', 10:1:40, 'Enable', 'off', ...
        'ValueChangingFcn', @(~,ev) mostrar_snr(ev.Value), 'ValueChangedFcn', @(~,~) cambio_ruido());
    sl_snr.Layout.Row = 4; sl_snr.Layout.Column = [1 2];
    cb_enf = uicheckbox(g2, 'Text', 'Prénfasis / deénfasis', 'Value', false, ...
        'ValueChangedFcn', @(~,~) mostrar_guardada());
    cb_enf.Layout.Row = 5; cb_enf.Layout.Column = [1 2];

    % 3) Simular
    p3 = uipanel(gc, 'Title', 'Simulación', 'FontWeight', 'bold');
    g3 = uigridlayout(p3, [2 1], 'RowSpacing', 6, 'Padding', [8 6 8 6]);
    g3.RowHeight = {32, 28};
    bt_sim = uibutton(g3, 'Text', 'Sintonizar y simular', 'FontWeight', 'bold', 'FontSize', 14, ...
        'BackgroundColor', [0.85 0.92 1.00], 'ButtonPushedFcn', @(~,~) simular());
    bt_4 = uibutton(g3, 'Text', 'Simular las 4 combinaciones', ...
        'Tooltip', 'Ideal y con ruido, sin y con prénfasis. Después se cambia entre ellas sin simular.', ...
        'ButtonPushedFcn', @(~,~) simular_cuatro());

    % 4) Salida: qué audio se grafica y se escucha
    p4 = uipanel(gc, 'Title', 'Salida', 'FontWeight', 'bold');
    g4 = uigridlayout(p4, [3 2], 'RowSpacing', 6, 'Padding', [8 6 8 6]);
    g4.RowHeight = {22, 24, 28};
    g4.ColumnWidth = {'1x', '1x'};
    par(g4, 1, 1, 'Audio de salida:');
    dd_canal = uidropdown(g4, 'Items', {'Audio 1', 'Audio 2', 'Audio 3'}, 'Value', 'Audio 1', ...
        'ValueChangedFcn', @(~,~) graficar_canal());
    dd_canal.Layout.Row = 1; dd_canal.Layout.Column = 2;
    lbl_sdr = uilabel(g4, 'Text', 'SDR: -', 'FontWeight', 'bold', 'FontSize', 14);
    lbl_sdr.Layout.Row = 2; lbl_sdr.Layout.Column = [1 2];
    bt_rx = uibutton(g4, 'Text', 'Escuchar recuperado', 'ButtonPushedFcn', @(~,~) escuchar(true));
    bt_rx.Layout.Row = 3; bt_rx.Layout.Column = 1;
    bt_tx = uibutton(g4, 'Text', 'Escuchar original', 'ButtonPushedFcn', @(~,~) escuchar(false));
    bt_tx.Layout.Row = 3; bt_tx.Layout.Column = 2;

    % 5) Estado
    lbl_estado = uilabel(gc, 'Text', 'Listo. Elija la portadora y presione "Sintonizar y simular".', ...
        'WordWrap', 'on', 'VerticalAlignment', 'top');

    % controles que se bloquean mientras se simula
    controles = {bt_menos, bt_mas, dial, ed_des, dd_fuente, ed_T, cb_awgn, sl_snr, cb_enf, ...
        bt_sim, bt_4, dd_canal, bt_rx, bt_tx};

    % ---- gráficas
    ga = uigridlayout(g, [2 2]);
    ax_rf  = uiaxes(ga); title(ax_rf,  'Espectro RF recibido');
    ax_mez = uiaxes(ga); title(ax_mez, 'Salida del mezclador');
    ax_mux = uiaxes(ga); title(ax_mux, 'Multiplex FDM recuperado');
    ax_t   = uiaxes(ga); title(ax_t,   'Audio seleccionado');

    cambio_sintonia();

    %% ================= funciones internas =================
    function cambio_sintonia()
        % Se ejecuta al mover el dial: recalcula LO, imagen, preselector (sin simular).
        fc = round(dial.Value * 10) / 10;           % pasos de 0.1 MHz
        dial.Value = fc;
        S.P = params_sistema(fc * 1e6, struct('imprimir', false, 'desintonia', ed_des.Value * 1e3));
        V = S.P.vista;
        mostrar_fc(V.fc_MHz);
        lbl_lo.Text = sprintf('%.2f MHz', V.fLO_MHz);
        lbl_fi.Text = sprintf('%.1f MHz', V.fFI_MHz);
        lbl_im.Text = sprintf('%.2f MHz', V.fimagen_MHz);
        lbl_bw.Text = sprintf('%.0f / %.0f kHz', V.df_kHz, V.carson_kHz);
        if ~isempty(S.out), mostrar_guardada(); end
    end

    function mostrar_fc(v)
        lcd.Text = sprintf('%.1f MHz', round(v * 10) / 10);
    end

    function paso(df)
        dial.Value = min(max(round((dial.Value + df) * 10) / 10, 9), 11);
        cambio_sintonia();
    end

    function bloquear(si)
        % Mientras se simula no se puede cambiar nada: así lo que se ve coincide con lo marcado.
        for c = 1:numel(controles)
            controles{c}.Enable = ~si;
        end
        if ~si, sl_snr.Enable = cb_awgn.Value; end
    end

    function mostrar_snr(v)
        lbl_snr.Text = sprintf('(SNR)_C = %d dB', round(v));
    end

    function cambio_ruido()
        % La barra queda en valores enteros y solo se activa con el canal AWGN.
        sl_snr.Value = round(sl_snr.Value);
        mostrar_snr(sl_snr.Value);
        sl_snr.Enable = cb_awgn.Value;
        lbl_snr.FontColor = ternario(cb_awgn.Value, [0 0 0], [0.5 0.5 0.5]);
        mostrar_guardada();
    end

    function snr = snr_elegida()
        snr = Inf;  if cb_awgn.Value, snr = sl_snr.Value; end
    end

    function c = clave(snr, enf)
        % Identifica una simulación por todo lo que cambia su resultado.
        c = sprintf('%.1f|%g|%s|%g|%g|%d', dial.Value, ed_des.Value, dd_fuente.Value, ...
            ed_T.Value, snr, enf);
    end

    function mostrar_guardada()
        % Si esta combinación ya se simuló, la muestra al instante; si no, avisa.
        if isempty(S.out), return; end
        c = clave(snr_elegida(), cb_enf.Value);
        if isKey(S.memo, c)
            r = S.memo(c);
            S.out = r.out;  S.P_sim = r.P;  S.fuente_sim = r.fuente;
            graficar_todo();
            lbl_estado.Text = ['Resultado guardado (sin volver a simular): ' r.texto];
        else
            lbl_estado.Text = ['Esta combinación todavía no se ha simulado. Presione "Sintonizar y simular". ' ...
                'Las gráficas y el audio siguen siendo los de la simulación anterior.'];
        end
    end

    function simular()
        correr({snr_elegida()}, {cb_enf.Value});
    end

    function simular_cuatro()
        % Canal ideal y con ruido (el de la barra), cada uno sin y con prénfasis.
        % Las casillas no se tocan: al terminar se muestra la combinación que esté marcada.
        correr({Inf, Inf, sl_snr.Value, sl_snr.Value}, {false, true, false, true});
        mostrar_guardada();
    end

    function correr(snrs, enfs)
        bloquear(true);
        try
            T = ed_T.Value;  fc = dial.Value;  n = numel(snrs);
            if exist('modelo_al_dia', 'file'), modelo_al_dia(mdl); end
            load_system(mdl);
            for i = 1:n
                snr = snrs{i};  enf = enfs{i};
                P = params_sistema(fc * 1e6, struct('imprimir', false, 'T_real', T, 'snr_c_dB', snr, ...
                    'desintonia', ed_des.Value * 1e3, 'log_rf_max', 2^18, 'enfasis', enf));
                rng(1);
                fuente = generar_fuentes(P, dd_fuente.Value);
                lbl_estado.Text = sprintf(['Simulando %d de %d (%.2f s reales)... En modo acelerado ' ...
                    'tarda unos %.0f s cada una (más la 1.ª vez, que compila).'], i, n, T, 270*T);
                drawnow;
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
                pico = max(abs(out.sim_m_n(:)));       % pico de m_n = desviación usada / Df
                texto = sprintf('f_c = %.1f MHz, LO = %.2f MHz%s%s. Desviación pico usada: %.0f %% de %.0f kHz.', ...
                    P.vista.fc_MHz, P.vista.fLO_MHz, ternario(isinf(snr), ', canal ideal', sprintf(', (SNR)_C = %g dB', snr)), ...
                    ternario(P.enfasis, ', con prénfasis', ''), 100*pico, P.vista.df_kHz);
                S.memo(clave(snr, enf)) = struct('out', out, 'P', P, 'fuente', fuente, 'texto', texto);
                S.out = out;  S.P_sim = P;  S.fuente_sim = fuente;
            end
            graficar_todo();
            if n == 1
                lbl_estado.Text = sprintf('Simulación lista en %.1f s. %s', t_sim, texto);
            end
        catch err
            lbl_estado.Text = ['Error: ' err.message];
        end
        bloquear(false);
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
            % se quita el retardo del sistema: ahí está el chasquido de arranque de los filtros,
            % que si no se quita fija el pico de la normalización y deja la voz muy baja
            n0 = round(S.P_sim.retardo_audio(k) * S.P_sim.fs_a);
            y = y(min(n0, numel(y)-1)+1:end);
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

function l = par(gl, fila, col, texto)
% Etiqueta en (fila, col). Sin texto, es un valor en negrita que se llena después.
    if nargin < 4
        l = uilabel(gl, 'Text', '-', 'FontWeight', 'bold');
    else
        l = uilabel(gl, 'Text', texto);
    end
    l.Layout.Row = fila;  l.Layout.Column = col;
end
function v = ternario(c, a, b)
    if c, v = a; else, v = b; end
end
