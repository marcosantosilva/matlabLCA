function genFig3(sd,se)
addpath('/veracruz/home/m/marcosilva/matlabLCA/gurobi1201/linux64/matlab')
addpath("cvx/");
setenv('GRB_LICENSE_FILE','/veracruz/home/m/marcosilva/matlabLCA/gurobi1201/linux64/licenses/gurobi.lic')
cvx_setup

    %for seedd = [ 1:5 25:29 41:45 51:55 91:95 101:105 ]
    
        seedd = sd
        rng(seedd)
        SEAll = se; %0.25:0.25:10; % Array of SE values

        % Definir nome do arquivo final
        filename = strcat('MIPsim', num2str(seedd), '_SE_', num2str(se), '.mat');
        
        % Verificar se o arquivo já existe em resT/
        if exist(strcat('resT/', filename), 'file')
            fprintf('O arquivo %s já existe. O script será encerrado.\n', filename);
            return;
        end
        
        % Verificar se o arquivo temporário já existe em temp/
        if exist(strcat('temp/', filename), 'file')
            fprintf('O arquivo temporário %s já existe. O script será encerrado.\n', filename);
            return;
        end
        
        % Criar um arquivo temporário
        temp_filename = strcat('temp/', filename);
        fprintf('Arquivo temporário criado: %s\n', temp_filename);
        save(temp_filename, 'seedd', 'se'); % Salva variáveis temporárias necessárias

        % Network configuration
        L = 16; % Number of Access Points (APs)
        N = 4;  % Number of antennas per AP
        K = 8;  % Number of User Equipments (UEs) in the network
        W = 4;  % Number of Data Units (DUs)
    
        % Spectral Efficiency (SE) range and setup initialization
        numberSetup = length(SEAll); % Number of SE setups
    
        % Initialize matrices to store results for each setup
        Axx = zeros(K,L,numberSetup);
        Add = zeros(W,numberSetup);
        Azz = zeros(L,numberSetup);
        All = zeros(W,numberSetup);
        Arho = zeros(K*L,numberSetup);
    
        Bxx = zeros(K,L,numberSetup);
        Bdd = zeros(W,numberSetup);
        Bzz = zeros(L,numberSetup);
        Bll = zeros(W,numberSetup);
        Brho = zeros(K*L,numberSetup);
    
        TotalPower = zeros(2,numberSetup);
    
        % System parameters
        nbrOfRealizations = 500; % Number of channel realizations per setup
        Nsmooth = 12;
        Nslot = 16;
        tau_c = Nsmooth*Nslot; % Coherence block length
    
        %Length of pilot sequences
        tau_p = K;
    
        %Compute the prelog factor assuming only downlink data transmission
        preLogFactor = (tau_c-tau_p)/tau_c;
    
        %Angular standard deviation in the local scattering model (in radians)
        ASD_varphi = deg2rad(15);  %azimuth angle
        ASD_theta = deg2rad(15);   %elevation angle
    
        % Transmit power configuration
        p = 100; % Uplink transmit power per UE (mW)
        rho_tot = 1000; % Downlink transmit power per AP (mW)
    
        %Generate one setup with UEs at random locations
        [gainOverNoisedB,R,pilotIndex,D,D_small,APpositions,UEpositions] = generateSetup(L,K,N,tau_p,1,0,ASD_varphi,ASD_theta);
    
        %Generate channel realizations, channel estimates, and estimation
        %error correlation matrices for all UEs to the cell-free APs
        [Hhat,H,B,C] = functionChannelEstimates(R,nbrOfRealizations,L,K,N,tau_p,pilotIndex,p);
    
        % Full uplink power for the computation of precoding vectors using
        % virtual uplink-downlink duality
        p_full = p*ones(K,1);
    
        %Define the case when all APs serve all UEs
        D_all = ones(L,K);
    
        %Obtain the expectations 
        [signal_LP_MMSE,signal2_LP_MMSE, scaling_LP_MMSE] = ...
            functionComputeExpectationsV2(Hhat,H,D_all,C,nbrOfRealizations,N,K,L,p_full);
     
        % Initialize matrices for signal vectors
        bk = zeros(L, K);
        Ck = zeros(L, L, K, K);
    
        %Go through all UEs
        for k = 1:K
    
            % Desired signal vector for UE k
            % `bk(:, k)` contains the signal values for UE k received across all APs.
            % The real part is taken because the SINR calculation considers only real values
            % The vector is normalized by sqrt(scaling_LP_MMSE) to adjust the signal strength
            % based on the channel's scaling factor.
            bk(:,k) = real(vec(signal_LP_MMSE(k,k,:)))./sqrt(scaling_LP_MMSE(:,k));
            
            %Go through all UEs
            % Loop over all UEs to calculate signal and interference covariance matrices
            for i = 1:K
    
                if i==k
                    % Desired signal covariance matrix for UE k
                    % When i equals k, this represents the power of the desired signal
                    % for UE k. It is calculated as the outer product of `bk(:, k)`.
                    Ck(:,:,k,k) = bk(:,k)*bk(:,k)';
                else
                    % Interference covariance matrix for UE k from other UEs (i ≠ k)
                    % Interference terms are scaled by `scaling_LP_MMSE` to reflect
                    % the impact of the channel's scaling factor.
                    % The interference is calculated as the outer product of signal vectors
                    % between UE k and UE i.
                    Ck(:,:,k,i) = diag(1./sqrt(scaling_LP_MMSE(:,i)))...
                        *(vec(signal_LP_MMSE(k,i,:))...
                        *vec(signal_LP_MMSE(k,i,:))')...
                        *diag(1./sqrt(scaling_LP_MMSE(:,i)));
                end
    
                % Adjust covariance matrix for each AP-UE link
                % For each AP j, calculate the interference power for UE i received at AP j.
                % This interference term is normalized by the scaling factor for each AP-UE link.
                for j = 1:L
                    Ck(j,j,k,i) = signal2_LP_MMSE(k,i,j)/scaling_LP_MMSE(j,i);
                end
            end
        end
    
        % Taking the real part of covariance matrices (since imaginary parts cancel)
        % Removes any imaginary component from `Ck`, keeping only real values,
        % which are relevant for the SINR calculations.
        Ck = real(Ck);
        % Initialize matrices for storing compacted signal and interference vectors
        bb = zeros(L*K, K); % Stores signal vectors in a compact form
        CC = zeros(L*K, L*K, K); % Stores covariance matrices for each UE in a compact form
        CC2 = zeros(L*K, L*K, K); % Stores square root of covariance matrices for SINR calculations
        
        % Loop over UEs to create flattened versions of the matrices for SINR optimization
        for k = 1:K
    
            % Flattening `Ck` into `CC` for each UE, `i*L` offsets used to account for all APs.
            for i = 1:K
                CC((i-1)*L+1:i*L,(i-1)*L+1:i*L,k) = Ck(:,:,k,i);
            end
            % `CC2` contains square root matrices of `CC` to facilitate SINR constraint calculations.
            CC2(:,:,k) = sqrtm(CC(:,:,k));
            % `bb` stores the flattened version of `bk` for each UE in a compact form for easier processing.
            bb((k-1)*L+1:k*L,k) = vec(bk(:,k));
        end
    
        %%
        for sss = 1:numberSetup
            sss
            % Define value for the QoS -> Not defined in the paper
            gamma = 2^(SEAll(sss)/preLogFactor)-1;
            
            % PAP0 - Average antenna power per AP (mW)
            PAP0 = 6.8 * N; % Represents the power consumed by each AP for maintaining transmission and reception. Multiplied by the number of antennas (N).
            
            % DeltaTr - Transition power (mW)
            DeltaTr = 4; % Power associated with the transition state, likely for switching devices between active and inactive modes.
            
            % PONU - Optical Network Unit (ONU) power (mW)
            PONU = 7.7; % Power consumed by the Optical Network Unit, which connects APs to the main network.
            
            % sigmaCool - Cooling system efficiency factor
            sigmaCool = 0.9; % Efficiency factor for the device cooling system, used to adjust power consumption considering cooling losses.
            
            % POLT - Optical Line Termination power (mW)
            POLT = 20; % Power consumed by the optical line termination, a point in fiber networks that connects with APs.
            
            % Pdisp - Dissipated power (mW)
            Pdisp = 120; % Power dissipated in network devices, representing inherent power losses in electronic equipment.
            
            % Pproc0 - Base processing power (mW)
            Pproc0 = 20.8; % Initial power required for data processing, before adding adjustments based on processing rate and operations.
            
            % DeltaProc - Power increment per processing unit (mW/GOPS)
            DeltaProc = 74; % Additional power consumed per billion operations per second (GOPS) needed for additional processing load.
            
            % GOPSmax - Maximum operations per second capacity (GOPS)
            GOPSmax = 180; % Maximum processing capacity in billions of operations per second (GOPS) that the system can handle.
            
            % fs - System sampling rate (Hz)
            fs = 30.72*10^6;  % Number of samples of an analog signal collected per second, essential for data rate and processing load calculations.
    
            % Ts - Symbol time (s)
            Ts = 71.4*10^(-6); % Duration of each transmitted symbol in seconds, related to the sampling rate, determining the total number of symbols processed.
    
            % NDFT - Discrete Fourier Transform (DFT) size
            NDFT = 2048;% Number of points used in the Discrete Fourier Transform, critical for converting between time and frequency domains in signal processing.
    
            % Nused - Number of subcarriers used in transmission
            Nused = 1200; % Number of active subcarriers used for data transmission, important for determining the processing load.
            
            % Nbits - Number of bits per sample
            Nbits = 12; % Number of bits used to represent each signal sample, affecting the system's signal quality and data bandwidth.
    
    
            % Calculation of computational costs for filtering and DFT operations
            Cfilter = 40*N*fs/(10^9);% Filtering cost based on the number of antennas (N) and sampling rate (fs). Divided by 1e9 to convert to GOPS (billion operations per second).
    
            % Cost of the DFT operation based on the number of antennas (N), DFT size (NDFT), and symbol time (Ts). Converted to GOPS.
            CDFT = (8*N*NDFT*log2(NDFT)/Ts)/(10^9);
    
            % Setup-dependent processing costs
            % Define target SE for this setup
            SE0 = SEAll(sss); % Spectral efficiency for the current setup
    
            % Computational cost of AP-side precoding, considering pilot length and antenna configurations
            % (18)
            CprecodingAP = Nused/(Ts*tau_c*10^9)*...
                ((8*N*tau_p+8*N^2)*tau_p + (4*N^2+4*N)*tau_p + 8*(N^3-N)/3);
    
            % Additional computational costs at APs based on bit depth and antenna count
            CotherAP = ((Nbits/16)^(1.2))*(1.3*N) ...
                + ((Nbits/16)^(0.2))*(2.7*sqrt(N));
    
            % Z defined in eq (20)
            ZLP = Cfilter + CDFT + CprecodingAP + CotherAP;
    
            % CprecodingUE - Computational cost of precoding on the UE side
            % This term calculates the UE-side computational load for precoding operations.
            % (18)
            CprecodingUE = Nused*(tau_c-tau_p)/(Ts*tau_c*10^9)*8*N ...
                + Nused/(Ts*tau_c*10^9)*8*N ...
                + Nused/(Ts*tau_c*10^9)*(8*N^2);
            
            % FLP - Computational load based on spectral efficiency (SE) requirements
            % Fixed GOPS for UE that are independent of the number of serving
            % O-RUs. Declared as F in the paper (eq 20) but not defined
            FLP = ((Nbits/16)^(1.2))*( 1.3*((SE0/6)^(1.5))*K )...
                + ((Nbits/16)^(1.2))*( 1.3*SE0/6*K )...
                + 8*SE0/6*K;
            % Uses `SE0`, which is the target spectral efficiency for this setup, scaled by the number of bits per sample (Nbits) and the number of UEs (K).
           
            % XLP - Defined as X in eq (20)
            XLP = CprecodingUE; % Sets the UE precoding computational load directly to the value of `CprecodingUE`.
    
            % Rmax - Maximum fronthaul data rate (bits per second)
            Rmax = 10 * 10^9; % Maximum allowable data rate for the fronthaul link, set to 10 Gbps.
            
            % Rfronthaul - Required data rate for the fronthaul link
            Rfronthaul = 2 * fs * Nbits * N;
            % Calculates the fronthaul data rate required based on sampling frequency (fs), bit depth (Nbits), and number of antennas (N).
            % The factor of 2 accounts for uplink and downlink data flow requirements.
            
            % Wmax - Maximum number of DUs that can support the fronthaul link
            Wmax = floor(Rmax / Rfronthaul);
            % Calculates the maximum number of DUs  that can be supported by the fronthaul link,
            % based on the ratio of maximum fronthaul rate (Rmax) to the fronthaul rate required by each DU (Rfronthaul).
            
            % aux funcion to eq (24a) 
            % represents all the terms in 24a thar are multiplied by sum(zz)
            PPl = PAP0 + PONU + DeltaProc/GOPSmax*ZLP/sigmaCool;
    
            %% Cell-free C-RAN
            cvx_begin quiet
            cvx_solver gurobi
            variable xx(K, L) binary % Binary variable matrix representing AP-UE connections
            variable dd(W, 1) binary % Binary variable vector for DU activation
            variable zz(L, 1) binary % Binary variable vector indicating active APs
            variable ll(W, 1) binary % Binary variable vector indicating active DUs
            variable rho(K * L, 1) % Variable for power allocation per AP-UE link
    
            % Objective function: Minimize total power consumption considering
            % various components
            % Objective Funtion (24a)
            minimize Pdisp + PPl*sum(zz) + DeltaTr*quad_form(rho,eye(K*L))/10 ...
                + POLT*(1:W)*ll/sigmaCool + Pproc0*(1:W)*dd/sigmaCool ...
                + DeltaProc/GOPSmax*XLP*sum(sum(xx))/sigmaCool ...
                + DeltaProc/GOPSmax*FLP/sigmaCool
            % Constraints to ensure balanced resource allocation, power limits, and fronthaul capacity
            subject to
          
            sum(xx,2) >= ones(K,1); % Ensure each UE is served by at least one AP
            % (24d)
            sum(zz) <= sum(sum(xx)); % Number of active APs does not exceed connections
            
            for k = 1:K
                % SINR constraint for each UE to ensure minimum quality of service
                % (24b)
                norm([CC2(:,:,k)*10*rho; 1]) <= sqrt((gamma+1)/gamma)*bb(:,k)'*10*rho;
            end
            
            % (24c)
            sum(zz) <= Wmax*W; % Limit the number of active APs based on fronthaul capacity
            % (24d)
            zz <= (sum(xx,1)).'; % Ensure that APs only serve UEs if active
            K*zz >= (sum(xx,1)).'; % Each active AP must serve at least one UE
            % (24e)
            sum(zz)/Wmax <= (1:W)*ll;
            sum(zz)/Wmax >= (0:W-1)*ll;
            
            % Ensure that total processing cost at APs does not exceed maximum capacity
            % (24f)
            ZLP*sum(zz) + XLP*sum(sum(xx)) + FLP <= GOPSmax*(1:W)*dd;
            
            % Constraints to ensure only one DU and one DU group is active
            % (24g)
            sum(dd) == 1;
            sum(ll) == 1;
            
            % Enforce hierarchical relationship between DU and DU group activation
            % (24h)
            (1:W)*dd >= (1:W)*ll;
            
            % Power allocation constraints: Ensure power values are non-negative and within the allowable range
            % (24i)
            zeros(K*L,1) <= rho;
            rho <= sqrt(rho_tot/100)*vec(xx.');
    
            % Additional per-AP constraint to limit power allocation based on active status
            % (24j)
            for ell = 1:L
                norm(rho(ell:L:end,1)) <= sqrt(rho_tot/100)*zz(ell,1);
            end
    
            cvx_end
    
            % Calculate the total power consumption for the current setup
            % (24a)
            TotalPower(1,sss) = Pdisp + PPl*sum(zz) + DeltaTr*quad_form(rho,eye(K*L))/10 ...
                + POLT*(1:W)*ll/sigmaCool + Pproc0*(1:W)*dd/sigmaCool ...
                + DeltaProc/GOPSmax*XLP*sum(sum(xx))/sigmaCool ...
                + DeltaProc/GOPSmax*FLP/sigmaCool;
    
            % Save the optimization results for this setup in matrices
            Axx(:,:,sss) = xx; % Stores AP-UE connection matrix for this setup
            Add(:,sss) = dd; % Stores DU activation state for this setup
            Azz(:,sss) = zz; % Stores AP activation state for this setup
            All(:,sss) = ll; % Stores LCs activation state for this setup
            Arho(:,sss) = rho; % Stores power allocation per AP-UE link for this setup
    
    
            % Check if the total power for this setup is NaN (Not a Number)
            if isnan(TotalPower(1, sss))
                break % Exit the loop if NaN is detected, indicating an invalid or failed optimization result
            end
    
            %% Small-cell C-RAN
            cvx_begin quiet
            variable xx(K,L) binary
            variable dd(W,1) binary
            variable zz(L,1) binary
            variable ll(W,1) binary
            variable rho(K*L,1)
            minimize Pdisp + PPl*sum(zz) + DeltaTr*quad_form(rho,eye(K*L))/10 ...
                + POLT*(1:W)*ll/sigmaCool + Pproc0*(1:W)*dd/sigmaCool ...
                + DeltaProc/GOPSmax*XLP*sum(sum(xx))/sigmaCool ...
                + DeltaProc/GOPSmax*FLP/sigmaCool
            subject to
            %%%%% Diff
            sum(xx,2) == ones(K,1);
            sum(zz) <= sum(sum(xx));
            for k = 1:K
                norm([CC2(:,:,k)*10*rho; 1]) <= sqrt((gamma+1)/gamma)*bb(:,k)'*10*rho;
            end
            sum(zz) <= Wmax*W;
            zz <= (sum(xx,1)).';
            K*zz >= (sum(xx,1)).';
            sum(zz)/Wmax <= (1:W)*ll;
            sum(zz)/Wmax >= (0:W-1)*ll;
    
            ZLP*sum(zz) + XLP*sum(sum(xx)) + FLP <= GOPSmax*(1:W)*dd;
    
            sum(dd) == 1;
            sum(ll) == 1;
    
    
            (1:W)*dd >= (1:W)*ll;
            zeros(K*L,1) <= rho;
            rho <= sqrt(rho_tot/100)*vec(xx.');
    
            for ell = 1:L
                norm(rho(ell:L:end,1)) <= sqrt(rho_tot/100)*zz(ell,1);
            end
    
    
            cvx_end
    
    
            TotalPower(2,sss) = Pdisp + PPl*sum(zz) + DeltaTr*quad_form(rho,eye(K*L))/10 ...
                + POLT*(1:W)*ll/sigmaCool + Pproc0*(1:W)*dd/sigmaCool ...
                + DeltaProc/GOPSmax*XLP*sum(sum(xx))/sigmaCool ...
                + DeltaProc/GOPSmax*FLP/sigmaCool;
    
            Bxx(:,:,sss) = xx;
            Bdd(:,sss) = dd;
            Bzz(:,sss) = zz;
            Bll(:,sss) = ll;
            Brho(:,sss) = rho;
        save(strcat('resT/MIPsim',num2str(seedd),'_SE_',num2str(se),'.mat'))

        % Ao final, excluir o arquivo temporário
        if exist(temp_filename, 'file')
            delete(temp_filename);
            fprintf('Arquivo temporário removido: %s\n', temp_filename);
        end

        end
        %save(strcat('MIPsim',num2str(seedd),'.mat'))
  %  end
end
