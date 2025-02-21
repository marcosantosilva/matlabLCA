% Script de teste MATLAB para LCA Navigator +

% Gerar dados de teste
x = linspace(0, 10, 100);
y = sin(x);

% Guardar resultados em arquivo .mat
filename = 'resultados_teste.mat';
save(filename, 'x', 'y');

disp(['Resultados guardados em: ', filename]);