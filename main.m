% Start message
disp('Starting test with CVX and Gurobi...');

% Ensure the CVX path is added
cvx_path = fullfile(pwd, 'cvx');
if exist(cvx_path, 'dir')
    addpath(cvx_path);
end

cvx_startup

% Configure Gurobi
%setenv('GRB_LICENSE_FILE', '/veracruz/home/m/marcosilva/matlabLCA/cvx/gurobi/a64/gurobi.lic');
%grbgetkey c850ed58-2d16-4581-8ba7-2ec3ccefb705
%export GRB_LICENSE_FILE=/veracruz/home/m/marcosilva/matlabLCA/cvx/gurobi/a64/gurobi.lic

setenv('GRB_LICENSE_FILE', '/veracruz/home/m/marcosilva/matlabLCA/cvx/gurobi/a64/gurobi.lic');
disp(['GRB_LICENSE_FILE set to: ', getenv('GRB_LICENSE_FILE')]);

% Set the solver
cvx_solver gurobi;

% Generate test data
A = randn(10, 5);
b = randn(10, 1);

% Solve the problem with CVX
disp('Starting optimization...');

cvx_begin
    variable x(5)
    minimize( norm(A * x - b) )
    subject to
        x >= 0
cvx_end

% Display results
disp('Optimization completed.');
disp(['CVX status: ', cvx_status]);
disp('Optimal solution found:');
disp(x);

% Save results to a .mat file
filename = 'cvx_test_results.mat';
save(filename, 'A', 'b', 'x', 'cvx_status');

% Verify execution success
if strcmp(cvx_status, 'Solved')
    disp('CVX and Gurobi test successfully completed.');
else
    disp('There was a problem executing CVX with Gurobi.');
end

