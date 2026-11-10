% Arma la carpeta y el .zip de respaldo para el profesor.
%   Copia lo que se muestra en el video (el modelo, main y la radio) y lo necesario para que
%   funcione, revisa que la carpeta corra sola y la comprime.
%   Ejecutar desde esta carpeta:  >> preparar_entrega

clear; clc;
origen  = fileparts(mfilename('fullpath'));
destino = fullfile(origen, '..', '..', 'entrega_FDM_FM');
mdl     = 'sistema_fdm_fm';
archivos = {'main.m', 'radio_fdm_fm.m', 'params_sistema.m', 'disenar_fir_kaiser.m', ...
            'generar_fuentes.m', 'graficar_espectro.m', 'comparar_senales.m'};

cd(origen);
% si la radio o el modelo quedaron abiertos (por ejemplo, al probar la entrega), se cierran
delete(findall(groot, 'Type', 'figure', 'Name', 'Radio FM superheterodina - FDM de 3 canales'));
if bdIsLoaded(mdl), close_system(mdl, 0); end
assert(isfile(fullfile(origen, [mdl '.slx'])), 'No se encontró %s.slx', mdl);

% copiar
if exist(destino, 'dir')
    try
        rmdir(destino, 's');
    catch
        % OneDrive o el explorador pueden tener la carpeta abierta: se vacía en vez de borrarla
        fprintf('No se pudo borrar la carpeta de entrega (está abierta en otro programa); se vacía.\n');
        delete(fullfile(destino, '*.*'));
        if exist(fullfile(destino, 'audios'), 'dir'), delete(fullfile(destino, 'audios', '*.*')); end
    end
end
if ~exist(destino, 'dir'), mkdir(destino); end
cd(destino); destino = pwd; cd(origen);
if ~exist(fullfile(destino, 'audios'), 'dir'), mkdir(fullfile(destino, 'audios')); end
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

% LEEME
fid = fopen(fullfile(destino, 'LEEME.txt'), 'w', 'n', 'UTF-8');
fprintf(fid, ['Sistema FDM + FM con receptor superheterodino\n' ...
    'Comunicaciones Eléctricas I (EL5513), II semestre 2026. Jordi y Abner.\n\n' ...
    'Es lo que se muestra en el video. Se probó en MATLAB R%s con Simulink, sin toolboxes adicionales.\n\n' ...
    'Para correrlo, abrir esta carpeta en MATLAB y escribir: main\n' ...
    'main muestra en la consola los parámetros del diseño (valor real y valor simulado) y abre la radio.\n\n' ...
    'En la radio se elige la portadora (9 a 11 MHz), la fuente de audio, el ruido y el prénfasis,\n' ...
    'y se presiona "Sintonizar y simular". Cada segundo de audio tarda unos 2 a 3 minutos en\n' ...
    'simularse; por eso la duración viene en 0.3 s.\n\n' ...
    'Para poder simularlo, todas las frecuencias del modelo están divididas entre 100. La consola\n' ...
    'y la radio muestran los valores reales.\n\n' ...
    'El modelo de Simulink es sistema_fdm_fm.slx. Las grabaciones están en la carpeta audios.\n'], ...
    version('-release'));
fclose(fid);

% comprobar que la carpeta funciona sola
fprintf('Comprobando la carpeta...\n');
cd(destino);
ok = true;
for i = 1:numel(archivos)
    [~, nombre] = fileparts(archivos{i});
    if ~startsWith(which(nombre), pwd)
        fprintf('  [FALLA] %s se toma de otra carpeta: %s\n', nombre, which(nombre));
        ok = false;
    end
end
try
    P = params_sistema(10e6, struct('imprimir', false));
    fprintf('  [OK] params_sistema: %d comprobaciones del diseño\n', size(P.chequeos, 1));
    load_system(mdl);
    fprintf('  [OK] el modelo carga\n');
    close_system(mdl, 0);
catch err
    fprintf('  [FALLA] %s\n', err.message);
    ok = false;
end
cd(origen);

% comprimir
zipfile = [destino '.zip'];
[raiz, carpeta] = fileparts(destino);
zip(zipfile, carpeta, raiz);
d = dir(zipfile);
fprintf('\nCarpeta: %s\nZIP:     %s (%.1f MB)\n', destino, zipfile, d.bytes/1e6);
if ~isempty(faltan)
    fprintf('Aviso: faltan %s en la carpeta audios.\n', strjoin(faltan, ', '));
end
if ok
    fprintf('Listo. Antes de enviarlo, abra la carpeta de entrega en MATLAB y corra main.\n');
else
    fprintf('Hay fallas: revise los mensajes de arriba.\n');
end
