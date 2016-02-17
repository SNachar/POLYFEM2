%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          SI-upwind + IP matrix functor
%
%   Author:         Michael W. Hackemack
%   Institution:    Texas A&M University
%   Year:           2015
%   
%   Description:    
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Note(s):        
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function P = func_build_SI_upwind_IP(lam, input)
global glob
% Build Phase Matrix
if input.mesh.Dimension == size(lam,2); lam=lam'; end
node_locs = input.dof.NodeLocations;
PV = exp(1i*node_locs*lam);
PM = diag(PV);
% Retrieve terms
ng = input.data.numberEnergyGroups;
ndofs = input.dof.TotalDoFs;
zdofs = (1:ndofs);
g_offset = (1:ng)*ndofs - ndofs;
m2d = input.Quadrature.moment_to_discrete;
d2m = input.Quadrature.discrete_to_moment;
% Retrieve Matrices
L = func_mat_SI_upwind(lam, input);
A = func_mat_IP(lam, input);
S0 = input.ScatteringMatrix;
P = input.ProjectionMatrix;
I = eye(ndofs*ng);
% Build full matrix based on acceleration type
% P = T + (A\B)*(T - I);
if input.data.AccelType == glob.Accel_WGS_DSA
    % Build Scattering matrix
    S = zeros(ng*ndofs);
    for g=1:ng
        gdofs = zdofs + g_offset(g);
        for gg=1:ng
            ggdofs = zdofs + g_offset(gg);
            S(gdofs,ggdofs) = S0(:,:,g,gg)*PM;
        end
    end
    % Build transport operators
    T = zeros(ndofs*ng);
    for q=1:input.Quadrature.NumberAngularDirections
        T = T + d2m(1,q)*( L{q}\( m2d(1,q)*S ));
    end
%     E = T;
    TT = T - I;
    % Build final matrix based on energy group numbers
    if ng == 1
        E = T + (A\S)*TT;
    else
        MDSA = zeros(ndofs,ng*ndofs); SS = S*TT;
        for g=1:ng
            gdofs = zdofs + g_offset(g);
            for gg=(g+1):ng
            end
            MDSA = MDSA + SS(gdofs,:);
        end
        E = T + P*(A\MDSA);
    end
elseif input.data.AccelType == glob.Accel_AGS_TG
    % Build scattering matrices
    Sd = zeros(ng*ndofs);
    Su = zeros(ng*ndofs);
    S  = zeros(ng*ndofs);
    for g=1:ng
        gdofs = zdofs + g_offset(g);
        for gg=1:ng
            ggdofs = zdofs + g_offset(gg);
            tS0 = S0(:,:,g,gg)*PM;
            if gg <= g
                Sd(gdofs,ggdofs) = tS0;
            elseif gg > g
                Su(gdofs,ggdofs) = tS0;
            end
            S(gdofs,ggdofs) = tS0;
        end
    end
    % Build tranpsort matrices
    B = zeros(ng*ndofs); C = zeros(ng*ndofs);
%     SSd = sparse(Sd); SSu = sparse(Su);
    for q=1:input.Quadrature.NumberAngularDirections
        B = B + d2m(1,q)*( L{q}\( m2d(1,q)*Sd ));
        C = C + d2m(1,q)*( L{q}\( m2d(1,q)*Su ));
    end
    TC = (I-B)\C;
    TCI = TC - I;
%     E = TC;
    % Build restriction/projection operators
    MDSA = zeros(ndofs,ng*ndofs); SS = Su*TCI;
    for g=1:ng
        gdofs = zdofs + g_offset(g);
        for gg=(g+1):ng
%             ggdofs = zdofs + g_offset(gg);
%             MDSA(:,ggdofs) = MDSA(:,ggdofs) + Su(gdofs,ggdofs)*TCI(ggdofs,gdofs);
%             MDSA(:,ggdofs) = MDSA(:,ggdofs) + Su(gdofs,ggdofs)*TCI(gdofs,ggdofs);
%             MDSA(:,ggdofs) = MDSA(:,ggdofs) + SS(gdofs,ggdofs);
        end
        MDSA = MDSA + SS(gdofs,:);
    end
    E = TC + P*(A\MDSA);
elseif input.data.AccelType == glob.Accel_AGS_MTG
    
end