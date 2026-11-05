function modelo_al_dia(mdl)
%MODELO_AL_DIA  Genera el modelo Simulink si no existe o si construir_modelo.m es más nuevo.
%   Así, si alguien cambia construir_modelo.m, el .slx se vuelve a generar solo.
    if nargin < 1, mdl = 'sistema_fdm_fm'; end
    archivo = [mdl '.slx'];
    regenerar = ~exist(archivo, 'file');
    if ~regenerar
        a = dir(archivo);  b = dir(which('construir_modelo'));
        regenerar = b.datenum > a.datenum;
    end
    if regenerar
        if bdIsLoaded(mdl), close_system(mdl, 0); end
        fprintf('Generando %s...\n', archivo);
        construir_modelo(mdl);
    end
end
