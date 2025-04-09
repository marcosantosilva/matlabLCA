% 1. Configure Gurobi paths
addpath('/veracruz/home/m/marcosilva/matlabLCA/gurobi1201/linux64/matlab');
setenv('GRB_LICENSE_FILE', '/veracruz/home/m/marcosilva/matlabLCA/gurobi1201/linux64/licenses/gurobi.lic');
setenv('GUROBI_HOME', '/veracruz/home/m/marcosilva/matlabLCA/gurobi1201/linux64');

% 2. Configure CVX
addpath('cvx/');
cvx_setup

% 3. Force CVX to use Gurobi
cvx_solver gurobi
disp(['Current CVX solver: ', cvx_solver]);

% 4. Test Gurobi standalone (opcional)
try
    model.A = sparse([1, 2; 3, 4]);
    model.obj = [1; 1];
    model.rhs = [1; 1];
    model.sense = '<';
    model.modelsense = 'min';
    result = gurobi(model);
    disp('Gurobi standalone works!');
catch ME
    disp('Gurobi standalone error:');
    disp(ME.message);
end

% 5. Test CVX with Gurobi
try
    cvx_begin
    cvx_solver gurobi 
       variable x(2)
        minimize(norm(x, 1))
        subject to
            [1, 2] * x <= 1;
            [3, 4] * x <= 1;
    cvx_end
    disp('CVX + Gurobi works!');
catch ME
    disp('CVX + Gurobi error:');
    disp(ME.message);
end
