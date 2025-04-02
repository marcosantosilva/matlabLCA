addpath('/veracruz/home/m/marcosilva/matlabLCA/gurobi1201/linux64/matlab')
addpath("cvx/");
%export GRB_LICENSE_FILE=/veracruz/home/m/marcosilva/matlabLCA/gurobi1201/linux64/licenses
%gurobi_setup
setenv('GRB_LICENSE_FILE','/veracruz/home/m/marcosilva/matlabLCA/gurobi1201/linux64/licenses/gurobi.lic')
cvx_setup
cvx_solver


