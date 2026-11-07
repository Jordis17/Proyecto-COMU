function modelo_al_dia(mdl)
%MODELO_AL_DIA  Genera el modelo Simulink SOLO si el .slx no existe.
%   El .slx se ordenó a mano en Simulink, así que nunca se sobrescribe solo.
%   Para generarlo de nuevo desde cero (se pierde el orden manual):
%       >> construir_modelo
    if nargin < 1, mdl = 'sistema_fdm_fm'; end
    if ~exist([mdl '.slx'], 'file')
        fprintf('No existe %s.slx: se genera con construir_modelo.\n', mdl);
        construir_modelo(mdl);
    end
end
