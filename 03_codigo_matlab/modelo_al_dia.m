function modelo_al_dia(mdl)
%MODELO_AL_DIA  Regenera el modelo Simulink si no existe o si es de una versión anterior.
    if nargin < 1, mdl = 'sistema_fdm_fm'; end
    regenerar = ~exist([mdl '.slx'], 'file');
    if ~regenerar
        load_system(mdl);
        regenerar = ~strcmp(get_param(mdl, 'Description'), sprintf('version_modelo=%d', version_modelo()));
    end
    if regenerar
        fprintf('Generando %s.slx (versión %d)...\n', mdl, version_modelo());
        construir_modelo(mdl);
    end
end
