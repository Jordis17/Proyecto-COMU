function radio_fdm_fm()
% Interfaz tipo radio del sistema.
%   El dial elige la portadora (9 a 11 MHz); el oscilador local y la imagen se recalculan solos.
%   "Sintonizar y simular" corre el modelo de Simulink. Los botones Audio 1, 2 y 3 eligen qué
%   salida se grafica y se escucha, sin volver a simular. Cada simulación queda guardada en
%   radio_guardado.mat para no repetirla. Las frecuencias se muestran con su valor real
%   (el modelo trabaja con todo dividido entre 100).

    mdl = 'sistema_fdm_fm';
    P0 = params_sistema(10e6, struct('imprimir', false));   % constantes del diseño (no dependen de f_c)
    K  = P0.K;
    S = struct('P', [], 'R', [], 'P_sim', [], 'fuente_sim', [], 'sdr', [], ...
        'clave_mostrada', '', 'texto_mostrado', '', 'player', []);
    S.memo = containers.Map();    % simulaciones ya hechas: se vuelven a mostrar sin simular
    % Las simulaciones también se guardan en un archivo, así no se pierden al cerrar MATLAB.
    % Si cambia el modelo, los parámetros, las fuentes o los WAV, se descartan solas.
    archivo_memo = fullfile(fileparts(mfilename('fullpath')), 'radio_guardado.mat');
    firma = firma_archivos(fileparts(mfilename('fullpath')));
    S.memo = cargar_memo(archivo_memo, firma, fileparts(mfilename('fullpath')));
    H = struct();                 % objetos gráficos del plan de frecuencias

    % colores (los mismos en todas las gráficas)
    C.rf     = [0.00 0.45 0.74];      % señal RF y sección de RF
    C.lo     = [0.85 0.15 0.15];      % oscilador local
    C.im     = [0.60 0.20 0.70];      % frecuencia imagen
    C.fi     = [0.15 0.60 0.25];      % FI
    C.suma   = [0.93 0.55 0.10];      % producto suma del mezclador
    C.filtro = [0.30 0.30 0.30];      % respuesta |H| de los filtros
    C.orig   = [0.65 0.65 0.65];      % señales originales
    C.canal  = [0.00 0.45 0.74;       % audio 1
                0.85 0.40 0.05;       % audio 2
                0.47 0.20 0.60];      % audio 3

    %% ---------------- ventana ----------------
    fig = uifigure('Name', 'Radio FM superheterodina - FDM de 3 canales', 'Position', [40 40 1400 820]);
    fig.CloseRequestFcn = @(~,~) cerrar();
    g = uigridlayout(fig, [1 2], 'ColumnSpacing', 8);
    g.ColumnWidth = {390, '1x'};

    % ---- columna de controles: cuatro bloques (se desplaza si la pantalla es pequeña)
    gc = uigridlayout(g, [5 1], 'Scrollable', 'on', 'RowSpacing', 8, 'Padding', [4 4 4 4]);
    gc.RowHeight = {220, 195, 128, 160, 70};

    % 1) Sintonía: pantalla, dial y valores que se recalculan al sintonizar
    p1 = uipanel(gc, 'Title', 'Sintonía', 'FontWeight', 'bold');
    g1 = uigridlayout(p1, [5 4], 'RowSpacing', 4, 'Padding', [8 6 8 6]);
    g1.RowHeight = {52, 50, 20, 20, 24};
    g1.ColumnWidth = {'1x', '1x', '1x', '1x'};
    bt_menos = uibutton(g1, 'Text', char(9664), 'FontSize', 18, 'Tooltip', 'Bajar 0.1 MHz', ...
        'ButtonPushedFcn', @(~,~) paso(-0.1));
    bt_menos.Layout.Row = 1; bt_menos.Layout.Column = 1;
    lcd = uilabel(g1, 'Text', '10.0 MHz', 'FontName', 'Consolas', 'FontSize', 30, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'FontColor', [0.40 1.00 0.55], 'BackgroundColor', [0.06 0.10 0.08], ...
        'Tooltip', 'Portadora del transmisor (valor nominal)');
    lcd.Layout.Row = 1; lcd.Layout.Column = [2 3];
    bt_mas = uibutton(g1, 'Text', char(9654), 'FontSize', 18, 'Tooltip', 'Subir 0.1 MHz', ...
        'ButtonPushedFcn', @(~,~) paso(0.1));
    bt_mas.Layout.Row = 1; bt_mas.Layout.Column = 4;
    % dial de la radio: escala de 9 a 11 MHz, como la banda de un receptor analógico
    dial = uislider(g1, 'Limits', [9 11], 'Value', 10, 'MajorTicks', 9:0.5:11, ...
        'MinorTicks', 9:0.1:11, 'ValueChangingFcn', @(~,ev) arrastre_dial(ev.Value), ...
        'ValueChangedFcn', @(~,~) cambio_sintonia());
    dial.Layout.Row = 2; dial.Layout.Column = [1 4];
    par(g1, 3, 1, 'f_LO:');     lbl_lo = par(g1, 3, 2);
    par(g1, 3, 3, 'FI:');       lbl_fi = par(g1, 3, 4);
    par(g1, 4, 1, 'Imagen:');   lbl_im = par(g1, 4, 2);
    par(g1, 4, 3, 'Δf / B_T:'); lbl_bw = par(g1, 4, 4);
    par(g1, 5, [1 2], 'Desintonía RX [kHz]:');
    ed_des = uieditfield(g1, 'numeric', 'Value', 0, 'Limits', [-1000 1000], ...
        'Tooltip', 'Corre la sintonía del receptor respecto a la portadora (0 = sintonizado)', ...
        'ValueChangedFcn', @(~,~) cambio_sintonia());
    ed_des.Layout.Row = 5; ed_des.Layout.Column = [3 4];

    % 2) Señal y canal
    p2 = uipanel(gc, 'Title', 'Señal y canal', 'FontWeight', 'bold');
    g2 = uigridlayout(p2, [5 2], 'RowSpacing', 6, 'Padding', [8 6 8 6]);
    g2.RowHeight = {22, 22, 22, 42, 22};
    g2.ColumnWidth = {130, '1x'};
    par(g2, 1, 1, 'Fuente de audio:');
    % el texto describe la fuente; el valor es el modo de generar_fuentes
    dd_fuente = uidropdown(g2, 'Items', {'Arpegio, sirena y pitidos', 'Tonos de 1, 3 y 7 kHz', ...
        'Ruido de 0.3 a 15 kHz', 'Grabaciones (WAV)'}, 'ItemsData', {'demo', 'tonos', 'ruido', 'audio'}, ...
        'Value', 'demo', 'Tooltip', 'Los WAV se leen de la carpeta audios (audio1.wav, audio2.wav, audio3.wav)', ...
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
    cb_enf = uicheckbox(g2, 'Text', sprintf('Prénfasis / deénfasis (f0 = %.0f kHz)', P0.vista.f0_enf_kHz), ...
        'Value', false, 'ValueChangedFcn', @(~,~) mostrar_guardada());
    cb_enf.Layout.Row = 5; cb_enf.Layout.Column = [1 2];

    % 3) Simular
    p3 = uipanel(gc, 'Title', 'Simulación', 'FontWeight', 'bold');
    g3 = uigridlayout(p3, [3 1], 'RowSpacing', 6, 'Padding', [8 6 8 6]);
    g3.RowHeight = {32, 28, 22};
    bt_sim = uibutton(g3, 'Text', 'Sintonizar y simular', 'FontWeight', 'bold', 'FontSize', 14, ...
        'BackgroundColor', [0.85 0.92 1.00], 'ButtonPushedFcn', @(~,~) simular());
    bt_4 = uibutton(g3, 'Text', 'Simular las 4 combinaciones', ...
        'Tooltip', 'Ideal y con ruido, sin y con prénfasis. Después se cambia entre ellas sin simular.', ...
        'ButtonPushedFcn', @(~,~) simular_cuatro());
    g3b = uigridlayout(g3, [1 2], 'Padding', [0 0 0 0], 'ColumnSpacing', 6);
    g3b.ColumnWidth = {18, '1x'};
    lamp = uilamp(g3b, 'Color', [0.6 0.6 0.6]);
    lbl_lamp = uilabel(g3b, 'Text', 'Sin simular');

    % 4) Salida: presintonías de audio, SDR y botones de escucha
    p4 = uipanel(gc, 'Title', 'Salida', 'FontWeight', 'bold');
    g4 = uigridlayout(p4, [3 3], 'RowSpacing', 6, 'Padding', [8 6 8 6]);
    g4.RowHeight = {56, 22, 28};
    g4.ColumnWidth = {'1x', '1x', '1x'};
    bg = uibuttongroup(g4, 'BorderType', 'none', 'SelectionChangedFcn', @(~,~) graficar_canal());
    bg.Layout.Row = 1; bg.Layout.Column = [1 3];
    tb = gobjects(1, 3);
    for ic = 1:3
        banda = (P0.f_sc(ic) + [-1 1] * P0.Wa) * K / 1e3;
        tb(ic) = uitogglebutton(bg, 'Text', sprintf('Audio %d', ic), 'FontWeight', 'bold', 'FontSize', 13, ...
            'FontColor', C.canal(ic,:), 'Position', [2 + 115*(ic-1), 4, 108, 48], ...
            'Tooltip', sprintf('Subportadora %.0f kHz (banda de %.0f a %.0f kHz)', P0.f_sc(ic)*K/1e3, banda));
        try    % etiqueta de dos líneas: nombre y subportadora
            tb(ic).Text = {sprintf('Audio %d', ic), sprintf('%.0f kHz', P0.f_sc(ic)*K/1e3)};
        catch
        end
    end
    lbl_sdr = uilabel(g4, 'Text', 'SDR: -', 'FontWeight', 'bold', 'FontSize', 14, ...
        'HorizontalAlignment', 'center');
    lbl_sdr.Layout.Row = 2; lbl_sdr.Layout.Column = [1 3];
    bt_rx = uibutton(g4, 'Text', [char(9654) ' Recuperado'], 'ButtonPushedFcn', @(~,~) escuchar(true));
    bt_rx.Layout.Row = 3; bt_rx.Layout.Column = 1;
    bt_tx = uibutton(g4, 'Text', [char(9654) ' Original'], 'ButtonPushedFcn', @(~,~) escuchar(false));
    bt_tx.Layout.Row = 3; bt_tx.Layout.Column = 2;
    bt_stop = uibutton(g4, 'Text', [char(9632) ' Detener'], 'ButtonPushedFcn', @(~,~) detener());
    bt_stop.Layout.Row = 3; bt_stop.Layout.Column = 3;

    % 5) Estado
    lbl_estado = uilabel(gc, 'Text', 'Elija la portadora y presione "Sintonizar y simular".', ...
        'WordWrap', 'on', 'VerticalAlignment', 'top', 'FontColor', [0.35 0.35 0.35]);

    %% ---------------- gráficas en pestañas ----------------
    tg = uitabgroup(g);
    t1 = uitab(tg, 'Title', 'Receptor superheterodino');
    t2 = uitab(tg, 'Title', 'Demultiplexación y audio');
    ga1 = uigridlayout(t1, [2 2]);
    ax_plan = uiaxes(ga1);  ax_rf = uiaxes(ga1);  ax_mez = uiaxes(ga1);  ax_fi = uiaxes(ga1);
    ga2 = uigridlayout(t2, [2 2]);     % multiplex arriba a todo lo ancho; SDR y audio abajo
    ax_mux = uiaxes(ga2);  ax_mux.Layout.Row = 1;  ax_mux.Layout.Column = [1 2];
    ax_sdr = uiaxes(ga2);  ax_sdr.Layout.Row = 2;  ax_sdr.Layout.Column = 1;
    ax_t   = uiaxes(ga2);  ax_t.Layout.Row   = 2;  ax_t.Layout.Column   = 2;
    % controles que se bloquean mientras se simula
    controles = {bt_menos, bt_mas, dial, ed_des, dd_fuente, ed_T, cb_awgn, sl_snr, cb_enf, ...
        bt_sim, bt_4, bg, bt_rx, bt_tx, bt_stop};

    marcador(ax_rf,  'Espectro de RF');
    marcador(ax_mez, 'Salida del mezclador');
    marcador(ax_fi,  'FI');
    marcador(ax_mux, 'Multiplex FDM');
    marcador(ax_sdr, 'SDR por audio');
    marcador(ax_t,   'Audio en el tiempo');
    iniciar_plan();
    cambio_sintonia();
    if S.memo.Count > 0
        if isempty(S.R)
            estado(sprintf(['Hay %d simulaciones guardadas. Elija ruido y prénfasis para verlas, ' ...
                'o simule una combinación nueva.'], S.memo.Count));
        end
    end

    %% ================= funciones internas =================
    % ---------- sintonía ----------
    function cambio_sintonia()
        % Se ejecuta al soltar el dial: recalcula LO, imagen, preselector y filtros (sin simular).
        fc = round(dial.Value * 10) / 10;           % pasos de 0.1 MHz
        dial.Value = fc;
        try
            S.P = params_sistema(fc * 1e6, struct('imprimir', false, 'desintonia', ed_des.Value * 1e3));
        catch err
            estado(['Error en los parámetros: ' err.message]);
        end
        mostrar_valores(fc, ed_des.Value);
        mostrar_guardada();
    end

    function arrastre_dial(v)
        % Mientras se arrastra el dial: pantalla, valores y plan de frecuencias al instante.
        mostrar_valores(round(v * 10) / 10, ed_des.Value);
    end

    function mostrar_valores(fc, des_kHz)
        % Mismas ecuaciones que params_sistema: f_LO = f_RX - f_FI (inyección inferior).
        FI = P0.f_FI * K / 1e6;  frx = fc + des_kHz / 1e3;
        lcd.Text = sprintf('%.1f MHz', fc);
        lbl_lo.Text = sprintf('%.2f MHz', frx - FI);
        lbl_fi.Text = sprintf('%.1f MHz', FI);
        lbl_im.Text = sprintf('%.2f MHz', frx - 2*FI);
        lbl_bw.Text = sprintf('%.0f / %.0f kHz', P0.vista.df_kHz, P0.vista.carson_kHz);
        actualizar_plan(fc, des_kHz / 1e3);
    end

    function paso(df)
        dial.Value = min(max(round((dial.Value + df) * 10) / 10, 9), 11);
        cambio_sintonia();
    end

    % ---------- plan de frecuencias (no necesita simular) ----------
    function iniciar_plan()
        ax = ax_plan;
        hold(ax, 'on');
        H.pre  = patch(ax, nan(1,4), nan(1,4), 'w', 'FaceColor', 'none', 'EdgeColor', C.rf, ...
            'LineStyle', '--', 'LineWidth', 1.2);
        H.fib  = patch(ax, nan(1,4), nan(1,4), 'w', 'FaceColor', 'none', 'EdgeColor', C.fi, ...
            'LineStyle', '--', 'LineWidth', 1.2);
        H.rf   = patch(ax, nan(1,4), nan(1,4), C.rf, 'EdgeColor', 'none');
        H.dif  = patch(ax, nan(1,4), nan(1,4), C.fi, 'EdgeColor', 'none');
        H.suma = patch(ax, nan(1,4), nan(1,4), C.suma, 'EdgeColor', 'none', 'FaceAlpha', 0.6);
        H.lo   = plot(ax, nan(1,2), nan(1,2), '-', 'Color', C.lo, 'LineWidth', 2.5);
        H.im   = plot(ax, nan(1,2), nan(1,2), ':', 'Color', C.im, 'LineWidth', 2.5);
        H.t_rf = text(ax, 0, 0, '', 'Color', C.rf);
        H.t_lo = text(ax, 0, 0, '', 'Color', C.lo);
        H.t_im = text(ax, 0, 0, '', 'Color', C.im);
        H.t_fi = text(ax, 0, 0, '', 'Color', C.fi);
        H.t_su = text(ax, 0, 0, '', 'Color', C.suma);
        set([H.t_rf H.t_lo H.t_im H.t_fi H.t_su], 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', 'FontSize', 9);
        hold(ax, 'off');
        xlim(ax, [0 22]);  ylim(ax, [0 1.75]);  ax.YTick = [];  ax.XTick = 0:2:22;
        grid(ax, 'on');  box(ax, 'on');
        xlabel(ax, 'f nominal [MHz]');
        leyenda(ax, [H.pre H.fib], {'paso de la sección de RF', 'paso de la sección de FI'}, 'northeast');
        estilo(ax);
    end

    function actualizar_plan(fc, des)
        % fc y des en MHz nominales. Dibuja dónde queda cada frecuencia del superheterodino.
        FI = P0.f_FI * K / 1e6;  HW = P0.HW * K / 1e6;  b2 = P0.B_carson * K / 1e6 / 2;
        frx = fc + des;  flo = frx - FI;  fim = frx - 2*FI;  fsu = fc + flo;  fdi = abs(fc - flo);
        poner_caja(H.rf,   fc,  b2, 1.00);
        poner_caja(H.pre,  frx, HW, 1.12);
        poner_caja(H.dif,  fdi, b2, 0.80);
        poner_caja(H.fib,  FI,  HW, 0.92);
        poner_caja(H.suma, fsu, b2, 0.80);
        set(H.lo, 'XData', [flo flo], 'YData', [0 1.00]);
        set(H.im, 'XData', [fim fim], 'YData', [0 0.60]);
        set(H.t_rf, 'Position', [fc  1.14 0], 'String', sprintf('f_c %.1f', fc));
        set(H.t_lo, 'Position', [flo 1.02 0], 'String', sprintf('LO %.2f', flo));
        set(H.t_im, 'Position', [fim 0.62 0], 'String', sprintf('imagen %.2f', fim));
        set(H.t_fi, 'Position', [fdi 0.94 0], 'String', sprintf('f_c−f_{LO} %.2f', fdi));
        set(H.t_su, 'Position', [fsu 0.82 0], 'String', sprintf('suma %.2f', fsu));
        if abs(fdi - FI) > HW
            title(ax_plan, sprintf('Desintonía de %+.0f kHz: la señal queda fuera de la FI', des*1e3), ...
                'Color', [0.80 0 0]);
        elseif abs(fdi - FI) + b2 > HW
            title(ax_plan, sprintf('Desintonía de %+.0f kHz: la señal se sale en parte de la FI', des*1e3), ...
                'Color', [0.85 0.45 0]);
        else
            title(ax_plan, 'Plan de frecuencias', 'Color', [0 0 0]);
        end
    end

    % ---------- ruido y combinaciones guardadas ----------
    function mostrar_snr(v)
        lbl_snr.Text = sprintf('(SNR)_C = %d dB', round(v));
    end

    function cambio_ruido()
        % La barra queda en valores enteros y solo se activa con el canal AWGN.
        sl_snr.Value = round(sl_snr.Value);
        mostrar_snr(sl_snr.Value);
        sl_snr.Enable = ternario(cb_awgn.Value, 'on', 'off');
        lbl_snr.FontColor = ternario(cb_awgn.Value, [0 0 0], [0.5 0.5 0.5]);
        mostrar_guardada();
    end

    function snr = snr_elegida()
        snr = Inf;  if cb_awgn.Value, snr = sl_snr.Value; end
    end

    function cfg = cfg_actual()
        % Todo lo que cambia el resultado de una simulación.
        cfg = struct('fc', round(dial.Value * 10) / 10, 'des', ed_des.Value, ...
            'fuente', dd_fuente.Value, 'T', ed_T.Value, 'snr', snr_elegida(), 'enf', logical(cb_enf.Value));
    end

    function mostrar_guardada()
        % Si la combinación marcada ya se simuló, la muestra al instante; si no, avisa.
        if ~isempty(S.R) || S.memo.Count > 0
            c = clave_de(cfg_actual());
            if strcmp(c, S.clave_mostrada)
                estado(S.texto_mostrado);
            elseif isKey(S.memo, c)
                mostrar_resultado(c);
                estado([S.texto_mostrado ' (guardado)']);
            elseif isempty(S.R)
                estado('Falta simular esta combinación.');
            else
                estado('Falta simular esta combinación. Se sigue mostrando la anterior.');
            end
        end
        actualizar_lampara();
    end

    function actualizar_lampara()
        if isempty(S.R)
            lamp.Color = [0.6 0.6 0.6];   lbl_lamp.Text = 'Sin simular';
        elseif strcmp(clave_de(cfg_actual()), S.clave_mostrada)
            lamp.Color = [0.20 0.75 0.20]; lbl_lamp.Text = 'Gráficas al día';
        else
            lamp.Color = [0.95 0.65 0.10]; lbl_lamp.Text = 'Falta simular';
        end
    end

    function mostrar_resultado(c)
        r = S.memo(c);
        S.R = r.R;  S.P_sim = r.P;  S.fuente_sim = r.fuente;  S.sdr = r.sdr;
        S.clave_mostrada = c;  S.texto_mostrado = r.texto;
        graficar_todo();
        actualizar_lampara();
    end

    % ---------- simulación ----------
    function simular()
        correr({snr_elegida()}, {logical(cb_enf.Value)});
    end

    function simular_cuatro()
        % Canal ideal y con ruido (el de la barra), cada uno sin y con prénfasis.
        % Las casillas no se tocan: al terminar se muestra la combinación que esté marcada.
        correr({Inf, Inf, sl_snr.Value, sl_snr.Value}, {false, true, false, true});
    end

    function correr(snrs, enfs)
        detener();
        bloquear(true);
        n = numel(snrs);
        dlg = uiprogressdlg(fig, 'Title', 'Simulando en Simulink', 'Indeterminate', 'on', ...
            'Message', 'Preparando el modelo...', 'Cancelable', ternario(n > 1, 'on', 'off'));
        if n > 1, dlg.CancelText = 'Parar después de esta'; end
        hechas = 0;  fallo = false;  t_sim = 0;  texto = '';  c = '';
        try
            if exist('modelo_al_dia', 'file'), modelo_al_dia(mdl); end
            load_system(mdl);
            for i = 1:n
                if n > 1 && dlg.CancelRequested, break; end
                cfg = cfg_actual();  cfg.snr = snrs{i};  cfg.enf = enfs{i};
                P = params_sistema(cfg.fc * 1e6, struct('imprimir', false, 'T_real', cfg.T, ...
                    'snr_c_dB', cfg.snr, 'desintonia', cfg.des * 1e3, 'log_rf_max', 2^18, ...
                    'enfasis', cfg.enf));
                rng(1);
                fuente = generar_fuentes(P, cfg.fuente);
                dlg.Message = sprintf('Simulación %d de %d: %s%s (unos %.0f s).', i, n, ...
                    ternario(isinf(cfg.snr), 'canal ideal', sprintf('(SNR)_C = %g dB', cfg.snr)), ...
                    ternario(cfg.enf, ', con prénfasis', ''), 145*cfg.T);
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
                R = reducir(out, P);
                sdr = sdr_tres(R, P, fuente);      % con las señales en doble precisión
                R = a_single(R);                   % para guardar: la mitad de memoria
                texto = sprintf('%.1f MHz, %s%s.', P.vista.fc_MHz, ...
                    ternario(isinf(cfg.snr), 'canal ideal', sprintf('(SNR)_C = %g dB', cfg.snr)), ...
                    ternario(cfg.enf, ', con prénfasis', ''));
                c = clave_de(cfg);
                S.memo(c) = struct('R', R, 'P', P, 'fuente', fuente, 'sdr', sdr, 'texto', texto);
                hechas = hechas + 1;
            end
        catch err
            fallo = true;
            estado(['Error: ' err.message]);
        end
        if isvalid(dlg), close(dlg); end
        if hechas > 0
            try
                datos = struct('memo', S.memo, 'firma', firma);
                save(archivo_memo, '-struct', 'datos', '-v7');
            catch
            end
        end
        bloquear(false);
        if hechas > 0
            c_act = clave_de(cfg_actual());
            if isKey(S.memo, c_act), mostrar_resultado(c_act); else, mostrar_resultado(c); end
            if ~fallo
                if n == 1
                    estado(sprintf('%s Simulado en %.0f s.', texto, t_sim));
                else
                    estado(sprintf('Listas %d de %d. Cambie ruido y prénfasis para verlas.', hechas, n));
                end
            end
        end
        actualizar_lampara();
    end

    function bloquear(si)
        % Mientras se simula no se puede cambiar nada: así lo que se ve coincide con lo marcado.
        habilitar = ternario(si, 'off', 'on');
        for q = 1:numel(controles)
            controles{q}.Enable = habilitar;
        end
        if ~si, sl_snr.Enable = ternario(cb_awgn.Value, 'on', 'off'); end
    end

    % ---------- gráficas ----------
    function graficar_todo()
        graficar_receptor();
        graficar_canal();
    end

    function graficar_receptor()
        P = S.P_sim;  R = S.R;  yl = [-100 5];  fc = P.vista.fc_MHz;

        % espectro RF recibido (últimas muestras registradas) y |H| de la sección de RF
        [f, D] = graficar_espectro(R.r, P.fs_rf, K, struct('nfft', 2^14));
        cla(ax_rf, 'reset');  hold(ax_rf, 'on');
        h1 = plot(ax_rf, f/1e6, D, 'Color', C.rf);
        h2 = plot(ax_rf, f/1e6, resp_db(P.h.presel, P.fs_rf, f/K), '--', 'Color', C.filtro, 'LineWidth', 1.2);
        h4 = plot(ax_rf, P.f_imagen*K/1e6*[1 1], yl, ':', 'Color', C.im, 'LineWidth', 1.5);
        hold(ax_rf, 'off');  grid(ax_rf, 'on');  ylim(ax_rf, yl);  xlim(ax_rf, fc + [-4.5 2]);
        xlabel(ax_rf, 'f nominal [MHz]');  ylabel(ax_rf, 'DEP [dB]');
        leyenda(ax_rf, [h1 h2 h4], {'señal recibida', 'sección de RF', 'imagen'}, 'northwest');
        title(ax_rf, 'Espectro de RF');  estilo(ax_rf);

        % salida del mezclador y |H| del pasabajos de la sección de FI (quita el producto suma)
        [f, D] = graficar_espectro(R.mezcla, P.fs_rf, K, struct('nfft', 2^14));
        cla(ax_mez, 'reset');  hold(ax_mez, 'on');
        h1 = plot(ax_mez, f/1e6, D, 'Color', C.rf);
        h2 = plot(ax_mez, f/1e6, resp_db(P.h.fi_lpf, P.fs_rf, f/K), '--', 'Color', C.filtro, 'LineWidth', 1.2);
        h3 = plot(ax_mez, P.f_FI*K/1e6*[1 1], yl, '-', 'Color', C.fi, 'LineWidth', 1.2);
        h4 = plot(ax_mez, P.f_suma*K/1e6*[1 1], yl, '--', 'Color', C.suma, 'LineWidth', 1.2);
        hold(ax_mez, 'off');  grid(ax_mez, 'on');  ylim(ax_mez, yl);  xlim(ax_mez, [0 24]);
        xlabel(ax_mez, 'f nominal [MHz]');  ylabel(ax_mez, 'DEP [dB]');
        leyenda(ax_mez, [h2 h3 h4], {'pasabajos de FI', 'FI', 'producto suma'}, 'north');
        title(ax_mez, 'Salida del mezclador');  estilo(ax_mez);

        % FI filtrada, |H| del pasabanda de FI y ancho de Carson
        [f, D] = graficar_espectro(R.fi, P.fs_fi, K, struct('nfft', 2^13));
        fFI = P.f_FI*K/1e6;  bc = P.B_carson*K/1e6/2;
        cla(ax_fi, 'reset');  hold(ax_fi, 'on');
        h1 = plot(ax_fi, f/1e6, D, 'Color', C.fi);
        h2 = plot(ax_fi, f/1e6, resp_db(P.h.fi, P.fs_fi, f/K), '--', 'Color', C.filtro, 'LineWidth', 1.2);
        h3 = plot(ax_fi, [fFI-bc fFI-bc NaN fFI+bc fFI+bc], [yl NaN yl], ':', 'Color', [0 0 0], 'LineWidth', 1.2);
        hold(ax_fi, 'off');  grid(ax_fi, 'on');  ylim(ax_fi, yl);  xlim(ax_fi, fFI + [-0.7 0.7]);
        xlabel(ax_fi, 'f nominal [MHz]');  ylabel(ax_fi, 'DEP [dB]');
        leyenda(ax_fi, [h2 h3], {'pasabanda de FI', 'ancho de Carson'}, 'south');
        if isinf(P.snr_c_dB)
            % ancho que contiene el 99 % de la potencia, dentro del paso de FI
            v = abs(f - P.f_FI*K) <= P.HW*K;  p = 10.^(D(v)/10);  cp = cumsum(p) / sum(p);  fv = f(v);
            B99 = (fv(find(cp >= 0.995, 1)) - fv(find(cp >= 0.005, 1))) / 1e3;
            title(ax_fi, sprintf('FI: 99 %% de la potencia en %.0f kHz', B99));
        else
            title(ax_fi, 'FI con ruido');
        end
        estilo(ax_fi);
    end

    function graficar_canal()
        % Selección del audio: solo cambia la salida mostrada (no simula, no toca el LO).
        if isempty(S.R), return; end
        P = S.P_sim;  R = S.R;  k = canal();

        % multiplex transmitido y recuperado, con las tres bandas FDM
        [f, D1] = graficar_espectro(R.m, P.fs_m, K, struct('nfft', 4096));
        [~, D2] = graficar_espectro(R.m_hat, P.fs_m, K, struct('nfft', 4096));
        cla(ax_mux, 'reset');  hold(ax_mux, 'on');
        for j = 1:3
            b = (P.f_sc(j) + [-1 1]*P.Wa) * K / 1e3;
            patch(ax_mux, b([1 2 2 1]), [-100 -100 15 15], C.canal(j,:), 'EdgeColor', 'none', ...
                'FaceAlpha', ternario(j == k, 0.30, 0.08));
            text(ax_mux, mean(b), 9, sprintf('Audio %d', j), 'HorizontalAlignment', 'center', ...
                'Color', C.canal(j,:), 'FontWeight', ternario(j == k, 'bold', 'normal'));
        end
        h1 = plot(ax_mux, f/1e3, D1, 'Color', C.orig, 'LineWidth', 2);
        h2 = plot(ax_mux, f/1e3, D2, 'k');
        hold(ax_mux, 'off');  grid(ax_mux, 'on');  ylim(ax_mux, [-100 15]);  xlim(ax_mux, [0 240]);
        xlabel(ax_mux, 'f nominal [kHz]');  ylabel(ax_mux, 'DEP [dB]');
        leyenda(ax_mux, [h1 h2], {'transmitido', 'recuperado'}, 'northeast');
        title(ax_mux, 'Multiplex FDM');  estilo(ax_mux);

        % SDR de los tres audios (separación de canales); con ruido, también la teoría
        sdr = S.sdr;  ymax = max([70, sdr + 8]);
        col = C.canal;
        for j = 1:3, if j ~= k, col(j,:) = 0.35*col(j,:) + 0.65; end, end
        cla(ax_sdr, 'reset');  hold(ax_sdr, 'on');
        hb = bar(ax_sdr, 1:3, sdr, 0.6, 'FaceColor', 'flat', 'EdgeColor', 'none');
        hb.CData = col;
        text(ax_sdr, 1:3, sdr, compose('%.1f dB', sdr), 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', 'FontSize', 9);
        if isinf(P.snr_c_dB)
            title(ax_sdr, 'SDR por audio (canal ideal)');
        else
            % (SNR)_k = (SNR)_C W Df^2 Px / [18 Wa (f_k^2 + Wa^2/3)]  (la misma de analisis_awgn)
            Px = mean(S.fuente_sim.X.^2, 2).';
            teo = P.snr_c_dB + 10*log10(P.W * P.df^2 * Px ./ (18 * P.Wa * (P.f_sc.^2 + P.Wa^2/3)));
            if P.enfasis, teo = teo + P.enf.mejora_dB; end
            ht = plot(ax_sdr, [1:3; 1:3] + [-0.35; 0.35], [teo; teo], 'k--', 'LineWidth', 1.5);
            leyenda(ax_sdr, ht(1), {'teoría'}, 'northeast');
            ymax = max([ymax, teo + 8]);
            title(ax_sdr, sprintf('SDR por audio, (SNR)_C = %g dB%s', P.snr_c_dB, ...
                ternario(P.cnr_BT_dB < 14, ' (bajo el umbral)', '')));
        end
        hold(ax_sdr, 'off');  grid(ax_sdr, 'on');
        ax_sdr.XTick = 1:3;  ax_sdr.XTickLabel = {'Audio 1', 'Audio 2', 'Audio 3'};
        xlim(ax_sdr, [0.4 3.6]);  ylim(ax_sdr, [min(0, min(sdr) - 5), ymax]);
        ylabel(ax_sdr, 'SDR [dB]');  estilo(ax_sdr);

        % audio elegido: original y recuperado en el tiempo (retardo descontado)
        x = S.fuente_sim.X(k,:);  y = R.y{k};
        n = min(numel(x), numel(y));  x = x(1:n);  y = y(1:n);
        tr = (0:n-1) / P.fs_a / K * 1e3;               % ms reales
        t0 = min(20, max(tr) / 2);  v = tr >= t0 & tr <= t0 + 5;
        ty = tr - P.retardo_audio(k) / K * 1e3;  vy = ty >= t0 & ty <= t0 + 5;
        cla(ax_t, 'reset');  hold(ax_t, 'on');
        plot(ax_t, tr(v), x(v), 'Color', C.orig, 'LineWidth', 2.5);
        plot(ax_t, ty(vy), y(vy), 'Color', C.canal(k,:));
        hold(ax_t, 'off');  grid(ax_t, 'on');
        xlabel(ax_t, 'tiempo [ms]');  leyenda(ax_t, [], {'original', 'recuperado'}, 'northeast');
        title(ax_t, sprintf('Audio %d en el tiempo', k));  estilo(ax_t);


        % texto del SDR
        lbl_sdr.Text = sprintf('SDR del audio %d: %.1f dB', k, sdr(k));
    end

    % ---------- audio ----------
    function escuchar(recuperado)
        if isempty(S.R), estado('Primero simule.'); return; end
        detener();
        k = canal();
        if recuperado
            y = S.R.y{k};
            % se quita el retardo del sistema: ahí está el chasquido de arranque de los filtros,
            % que si no se quita fija el pico de la normalización y deja la voz muy baja
            n0 = round(S.P_sim.retardo_audio(k) * S.P_sim.fs_a);
            y = y(min(n0, numel(y)-1)+1:end);
        else
            y = S.fuente_sim.X(k,:);
        end
        if max(abs(y)) > 0, y = 0.9 * y / max(abs(y)); end
        try
            S.player = audioplayer(y, S.P_sim.fs_audio_real);   % 48 kHz reales: deshace el escalamiento K
            play(S.player);
        catch
            sound(y, S.P_sim.fs_audio_real);
        end
    end

    function detener()
        try
            if ~isempty(S.player) && isplaying(S.player), stop(S.player); end
        catch
        end
    end

    function k = canal()
        k = find(tb == bg.SelectedObject, 1);
        if isempty(k), k = 1; end
    end

    % ---------- otros ----------
    function estado(txt)
        lbl_estado.Text = txt;
    end

    function cerrar()
        detener();
        delete(fig);
    end
end

% =========================================================================
function c = clave_de(cfg)
% Identifica una simulación por todo lo que cambia su resultado.
    c = sprintf('%.1f|%g|%s|%g|%g|%d', cfg.fc, cfg.des, cfg.fuente, cfg.T, cfg.snr, cfg.enf);
end

function R = reducir(out, P)
% Guarda solo lo que usa la radio (las señales a 48 MHz ya vienen limitadas por log_rf_max).
    R.r      = out.sim_r(:).';
    R.mezcla = out.sim_mezcla(:).';
    % FI: se toma el tramo donde el multiplex tiene más energía. Con una grabación, el final
    % suele ser silencio, y ahí la FM es solo la portadora (el ancho medido saldría casi cero).
    fi = out.sim_fi(:).';  m = out.sim_m(:).';
    L  = min(2^19, numel(fi));  r = round(P.fs_fi / P.fs_m);  Lm = max(1, floor(L / r));
    e  = cumsum([0, m.^2]);
    if numel(m) > Lm
        [~, i0] = max(e(Lm+1:end) - e(1:end-Lm));      % inicio de la ventana de más energía
    else
        i0 = 1;
    end
    k0 = min(max(1, (i0 - 1) * r + 1), numel(fi) - L + 1);
    R.fi = fi(k0:k0 + L - 1);
    R.m      = out.sim_m(:).';
    R.m_hat  = out.sim_m_hat(:).';
    R.pico   = max(abs(out.sim_m_n(:)));       % pico de m_n = desviación usada / Df
    R.y      = cell(1, 3);
    for k = 1:3
        R.y{k} = out.(sprintf('sim_y%d', k))(:).';
    end
end

function R = a_single(R)
% Las señales guardadas solo se grafican y se escuchan: basta precisión simple.
    for f = {'r', 'mezcla', 'fi', 'm', 'm_hat'}
        R.(f{1}) = single(R.(f{1}));
    end
    R.y = cellfun(@single, R.y, 'UniformOutput', false);
end

function f = firma_archivos(carpeta)
% Lo que cambia el resultado de una simulación: el modelo y los WAV (por su fecha) y el código
% de los parámetros, las fuentes y los filtros (sin contar comentarios). La radio no cuenta.
    datos = [dir(fullfile(carpeta, 'sistema_fdm_fm.slx')); dir(fullfile(carpeta, 'audios', 'audio*.wav'))];
    f = [sprintf('%s|', datos.name) sprintf('%.6f|', [datos.datenum])];
    for m = {'params_sistema.m', 'generar_fuentes.m', 'disenar_fir_kaiser.m'}
        f = [f sprintf('%s:%d|', m{1}, suma_codigo(fullfile(carpeta, m{1})))];
    end
end

function c = suma_codigo(archivo)
% Suma de comprobación del código, sin líneas de comentario ni líneas vacías.
    c = 0;
    if ~isfile(archivo), return; end
    lineas = strtrim(splitlines(fileread(archivo)));
    lineas = lineas(~startsWith(lineas, '%') & strlength(lineas) > 0);
    t = double(char(strjoin(lineas, newline)));
    c = mod(sum(t .* mod(1:numel(t), 9973)), 2^31);
end

function memo = cargar_memo(archivo, firma, carpeta)
% Carga las simulaciones guardadas si siguen siendo válidas.
    memo = containers.Map();
    if ~isfile(archivo), return; end
    try
        d = load(archivo, 'memo', 'firma');
        if isa(d.memo, 'containers.Map') && (strcmp(d.firma, firma) || antigua_valida(d.firma, carpeta))
            memo = d.memo;
        end
    catch
    end
end

function ok = antigua_valida(f, carpeta)
% Firmas de versiones anteriores (nombre y fecha de cada archivo). Se aceptan si el modelo y los
% WAV no cambiaron: desde esas versiones, el código de los .m solo cambió en comentarios.
    ok = false;
    if contains(f, ':'), return; end
    p = strsplit(f, '|');  p = p(1:end-1);  n = numel(p) / 2;
    if n < 1 || n ~= round(n), return; end
    nombres = p(1:n);  fechas = p(n+1:end);
    datos = [dir(fullfile(carpeta, 'sistema_fdm_fm.slx')); dir(fullfile(carpeta, 'audios', 'audio*.wav'))];
    for i = 1:numel(datos)
        j = find(strcmp(nombres, datos(i).name), 1);
        if isempty(j) || ~strcmp(fechas{j}, sprintf('%.6f', datos(i).datenum)), return; end
    end
    ok = sum(endsWith(nombres, '.wav')) == sum(endsWith({datos.name}, '.wav'));
end

function sdr = sdr_tres(R, P, fuente)
% SDR de los tres audios recuperados frente a los originales.
    sdr = zeros(1, 3);
    for k = 1:3
        x = fuente.X(k,:);  y = R.y{k};
        n = min(numel(x), numel(y));
        sdr(k) = comparar_senales(x(1:n), y(1:n), P.retardo_audio(k), P.fs_a);
    end
end

function Hdb = resp_db(h, fs, f)
% |H(f)| en dB del FIR h (tasa fs) en las frecuencias f [Hz simulados], 0 dB en el máximo.
    h = h(:);
    Hf = exp(-1j*2*pi*f(:)*(0:numel(h)-1)/fs) * h;
    Hdb = 20*log10(abs(Hf).' + eps);
    Hdb = Hdb - max(Hdb);
end

function leyenda(ax, h, textos, lugar)
% Leyenda pequeña y sin recuadro, igual en todas las gráficas.
    if isempty(h)
        legend(ax, textos, 'Location', lugar, 'Box', 'off', 'FontSize', 8);
    else
        legend(ax, h, textos, 'Location', lugar, 'Box', 'off', 'FontSize', 8);
    end
end

function estilo(ax)
% Aspecto común: letra pequeña, títulos sin negrita y cuadrícula suave.
    ax.FontSize = 9;  ax.TitleFontWeight = 'normal';
    ax.GridAlpha = 0.12;  box(ax, 'on');  grid(ax, 'on');
end

function poner_caja(h, centro, medio, alto)
    set(h, 'XData', centro + medio*[-1 1 1 -1], 'YData', [0 0 alto alto]);
end

function marcador(ax, titulo)
% Eje vacío con una indicación, antes de la primera simulación.
    cla(ax, 'reset');
    title(ax, titulo, 'FontWeight', 'normal');
    ax.XTick = [];  ax.YTick = [];  box(ax, 'on');
    text(ax, 0.5, 0.5, 'Sin simular', 'Units', 'normalized', ...
        'HorizontalAlignment', 'center', 'Color', [0.6 0.6 0.6], 'FontSize', 11);
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
