% Test Configuration of Gurobi and CVX in MATLAB
clc; clear;
disp('=== STARTING TEST FOR GUROBI AND CVX ===');

% 1. Check if the Gurobi directory exists
gurobi_path = '/veracruz/home/m/marcosilva/matlabLCA/cvx/gurobi/a64';
if exist(gurobi_path, 'dir') ~= 7
    disp('ERROR: The Gurobi directory does not exist or is incorrect: %s', gurobi_path);
else
    disp(' Gurobi directory found.');
end

% 2. Add Gurobi path
addpath(gurobi_path);
disp(' Gurobi path added.');

% 3. Check if Gurobi is accessible
if isempty(which('gurobi'))
    disp('ERROR: Gurobi is not accessible in MATLAB. Check the installation and path.');
else
    disp(' Gurobi found in MATLAB.');
end

% 4. Verify if the Gurobi license file is properly configured
license_file = '/veracruz/home/m/marcosilva/matlabLCA/cvx/gurobi/a64/gurobi.lic';
if exist(license_file, 'file') ~= 2
    disp('ERROR: The Gurobi license file was not found: %s', license_file);
else
    disp(' Gurobi license file found.');
end
setenv('GRB_LICENSE_FILE', license_file);
disp(' Gurobi license environment variable set.');

% 5. Test Gurobi initialization
try
    cvx_startup;
    gurobi_setup;
    disp(' Gurobi successfully configured.');
catch ME
    error('ERROR: Gurobi could not be initialized. Details: %s', ME.message);
end

% 6. Configure and test CVX
try
    cvx_setup;
    disp(' CVX configured.');
    
    % Check if Gurobi is listed among CVX solvers
    solvers = cvx_solver;
    if any(strcmp(solvers, 'gurobi'))
        disp(' Gurobi solver found in CVX.');
    else
        disp('ERROR: Gurobi is not in the list of CVX solvers.');
    end
    
    % Set Gurobi as the default solver
    cvx_solver gurobi;
    disp(' Gurobi set as the default solver for CVX.');
    
catch ME
    disp('ERROR: Problem configuring CVX. Details: %s', ME.message);
end

% 7. Run a simple optimization test
disp(' Running optimization test with CVX and Gurobi...');
try
    A = randn(10, 5);
    b = randn(10, 1);
    
    cvx_begin
        variable x(5)
        minimize(norm(A * x - b))
        subject to
            x >= 0
    cvx_end
    disp(' Optimization successfully completed.');
catch ME
    disp('ERROR: The optimization problem failed. Details: %s', ME.message);
end

disp('TEST COMPLETED SUCCESSFULLY');

