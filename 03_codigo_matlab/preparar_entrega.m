%PREPARAR_ENTREGA  Copia los archivos de la entrega a una carpeta aparte y la comprime.
%   Ejecutar desde esta carpeta:  >> preparar_entrega
%
%   1) Usa el sistema_fdm_fm.slx de esta carpeta (el ordenado a mano); solo lo genera si falta.
%   2) Crea ../../entrega_FDM_FM con los 8 .m de la entrega, el .slx, los WAV de audios/
%      y un LEEME.txt para el profesor. No se copian: construir_modelo.m y modelo_al_dia.m
%      (se manda el .slx ya hecho), analisis_awgn.m y probar_audio_real.m (sus resultados
%      se muestran en el video), preparar_entrega.m y la carpeta verificacion/.
%   3) Revisa que la carpeta funcione sola: que cada función se encuentre dentro de ella
%      y que params_sistema y el modelo carguen sin errores.
%   4) Crea entrega_FDM_FM.zip al lado de la carpeta. Es lo que se manda.
%   5) Crea también entrega_FDM_FM_respaldo.zip: la entrega anterior, con 10 .m (los 8 más
%      analisis_awgn.m y probar_audio_real.m). NO se manda; queda guardada por si el
%      profesor pide los scripts que generaron los resultados del video.
%   No simula (eso se prueba aparte con main / graficas_sistema).

clear; clc;
origen  = fileparts(mfilename('fullpath'));
destino = fullfile(origen, '..', '..', 'entrega_FDM_FM');
mdl     = 'sistema_fdm_fm';

archivos = {'main.m', 'params_sistema.m', 'disenar_fir_kaiser.m', 'generar_fuentes.m', ...
            'radio_fdm_fm.m', 'graficas_sistema.m', 'graficar_espectro.m', 'comparar_senales.m'};

%% 1) modelo al día
cd(origen);
modelo_al_dia(mdl);
if bdIsLoaded(mdl), close_system(mdl, 0); end

%% 2) copiar
if exist(destino, 'dir')
    fprintf('La carpeta %s ya existe: se reemplaza.\n', destino);
    rmdir(destino, 's');
end
mkdir(destino);
cd(destino); destino = pwd; cd(origen);              % ruta completa, sin '..'
mkdir(fullfile(destino, 'audios'));
for i = 1:numel(archivos)
    copyfile(fullfile(origen, archivos{i}), destino);
end
copyfile(fullfile(origen, [mdl '.slx']), destino);
copyfile(fullfile(origen, 'audios', 'LEEME.txt'), fullfile(destino, 'audios'));
faltan = {};
for k = 1:3
    wav = fullfile(origen, 'audios', sprintf('audio%d.wav', k));
    if exist(wav, 'file')
        copyfile(wav, fullfile(destino, 'audios'));
    else
        faltan{end+1} = sprintf('audio%d.wav', k); %#ok<SAGROW>
    end
end

% LEEME para el profesor
fid = fopen(fullfile(destino, 'LEEME.txt'), 'w', 'n', 'UTF-8');
fprintf(fid, ['Sistema FDM + FM con receptor superheterodino\n' ...
    'Comunicaciones Eléctricas I (EL5513), ITCR, II semestre 2026 - Jordi y Abner\n\n' ...
    'Requisitos: MATLAB %s + Simulink. No usa toolboxes adicionales.\n\n' ...
    'Cómo usarlo (desde esta carpeta):\n' ...
    '  main               imprime la tabla de diseño y abre la radio\n' ...
    '  graficas_sistema   gráficas de cada etapa con canal ideal (~1 min)\n\n' ...
    'En la radio: perilla de portadora (9-11 MHz), FI y LO calculados solos, selector de audio,\n' ...
    'canal AWGN, prénfasis/deénfasis y fuente de audio (demo, tonos o los WAV de la carpeta audios).\n' ...
    'Cada segundo de audio tarda unos 4-5 minutos en simularse; use duraciones cortas.\n\n' ...
    'Escalamiento: todas las frecuencias del modelo están divididas por K = 100.\n' ...
    'La interfaz muestra siempre los valores nominales (10 MHz, 1.7 MHz, etc.).\n\n' ...
    'El modelo Simulink es sistema_fdm_fm.slx (solo bloques básicos, solver discreto de paso fijo).\n'], version);
fclose(fid);

%% 3) comprobar que la carpeta funciona sola
fprintf('\nComprobando la carpeta de entrega...\n');
cd(destino);
ok = true;
for i = 1:numel(archivos)
    [~, nombre] = fileparts(archivos{i});
    ruta = which(nombre);
    if ~startsWith(ruta, pwd)
        fprintf('  [FALLA] %s se encuentra fuera de la carpeta: %s\n', nombre, ruta);
        ok = false;
    end
end
try
    P = params_sistema(10e6, struct('imprimir', false));
    fprintf('  [OK] params_sistema: %d comprobaciones del diseño\n', size(P.chequeos, 1));
    load_system(mdl);
    fprintf('  [OK] el modelo %s.slx carga\n', mdl);
    close_system(mdl, 0);
catch err
    fprintf('  [FALLA] %s\n', err.message);
    ok = false;
end
cd(origen);

%% 4) comprimir
zipfile = [destino '.zip'];
[raiz, carpeta] = fileparts(destino);
zip(zipfile, carpeta, raiz);
d = dir(zipfile);

fprintf('\nCarpeta: %s\n', destino);
fprintf('ZIP:     %s (%.1f MB)\n', zipfile, d.bytes/1e6);
%% 5) respaldo: la entrega anterior con 10 .m (no se manda)
respaldo = [destino '_respaldo'];
if exist(respaldo, 'dir'), rmdir(respaldo, 's'); end
copyfile(destino, respaldo);
extra = {'analisis_awgn.m', 'probar_audio_real.m'};
for i = 1:numel(extra)
    copyfile(fullfile(origen, extra{i}), respaldo);
end
fid = fopen(fullfile(respaldo, 'LEEME.txt'), 'a', 'n', 'UTF-8');
fprintf(fid, ['\nScripts adicionales (generan los resultados del video):\n' ...
    '  analisis_awgn      canal AWGN, sin y con prénfasis/deénfasis (~8-10 min)\n' ...
    '  probar_audio_real  pasa audios/audio1..3.wav por el sistema (~9 min para 2 s)\n']);
fclose(fid);
zip_resp = [respaldo '.zip'];
[raiz_r, carpeta_r] = fileparts(respaldo);
zip(zip_resp, carpeta_r, raiz_r);
fprintf('Respaldo: %s (10 .m, NO se manda)\n', zip_resp);

if ~isempty(faltan)
    fprintf('AVISO: faltan los audios %s en audios/. El modo ''audio'' no funcionará.\n', strjoin(faltan, ', '));
end
if ok
    fprintf('Listo. Antes de enviar: abrir MATLAB en la carpeta de entrega y correr main.\n');
else
    fprintf('Hay fallas: revisar los mensajes de arriba.\n');
end
