clc; clear;
disp('=== TESTING CVX & GUROBI CONFIGURATION ===');

% 1. Check if CVX is installed
cvx_path = fullfile(pwd, 'cvx');
if exist(cvx_path, 'dir')
    addpath(cvx_path);
    disp('✔ CVX path added.');
else
    disp('✘ WARNING: CVX path not found. Continuing without adding CVX path.');
end

% Definir variável de ambiente com o caminho da licença
 setenv('GRB_LICENSE_FILE', '/veracruz/home/m/marcosilva/matlabLCA/cvx/gurobi/a64/gurobi.lic');

% Verificar se a licença está corretamente definida
 disp(['✔ GRB_LICENSE_FILE set to: ', getenv('GRB_LICENSE_FILE')]);

% Configurar licença WLS para Gurobi
% setenv('GRB_LICENSE_FILE', 'WLSLICENSE=39f5f2bc-9979-45cd-8a7c-91a9da080f91');

% Verificar se a variável está corretamente definida
% disp(['✔ WLS License set: ', getenv('GRB_LICENSE_FILE')]);



% 2. Run CVX setup
try
    cvx_setup;
    disp('✔ CVX setup completed.');
catch ME
    error(['✘ ERROR: CVX setup failed. Details: ', ME.message]);
end

% 3. Check available solvers in CVX
try
    solvers = cvx_solver;
    disp('✔ Available CVX solvers:');
    disp(solvers);

    if any(strcmp(solvers, 'gurobi'))
        disp('✔ Gurobi solver is available in CVX.');
    else
        error('✘ ERROR: Gurobi is NOT in the list of CVX solvers. Check CVX installation.');
    end
catch ME
    error(['✘ ERROR: Failed to check CVX solvers. Details: ', ME.message]);
end

% 4. Set Gurobi as the solver
try
    cvx_solver gurobi;
    disp('✔ Gurobi set as the default solver for CVX.');
catch ME
    disp(['✘ ERROR: Could not set Gurobi as the solver. Details: ', ME.message]);
end

% 5. Test Gurobi Optimization inside CVX
disp('✔ Running test optimization with CVX and Gurobi...');
try
    A = randn(10, 5);
    b = randn(10, 1);

    cvx_begin
        variable x(5)
        minimize(norm(A * x - b))
        subject to
            x >= 0
    cvx_end

    disp('✔ Optimization completed successfully.');
    disp(['CVX status: ', cvx_status]);
    disp('Optimal solution found:');
    disp(x);

    % Save results
    filename = 'cvx_gurobi_test_results.mat';
    save(filename, 'A', 'b', 'x', 'cvx_status');
    disp(['✔ Results saved in: ', filename]);

    % Final check
    if strcmp(cvx_status, 'Solved')
        disp('✔ CVX and Gurobi test completed successfully.');
    else
        disp('✘ WARNING: CVX optimization did not complete successfully.');
    end

catch ME
    error(['✘ ERROR: Optimization test failed. Details: ', ME.message]);
end

