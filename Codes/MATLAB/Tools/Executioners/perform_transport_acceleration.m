%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          Perform Transport Acceleration Step
%
%   Author:         Michael W. Hackemack
%   Institution:    Texas A&M University
%   Year:           2015
%   
%   Description:    
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = perform_transport_acceleration(data,accel_id,mesh,DoF,FE,A)
% Retrieve some data information
% ------------------------------------------------------------------------------
global glob
a_type = data.Acceleration.Info(accel_id).AccelerationType;
groups = data.Acceleration.Info(accel_id).Groups;
mom    = data.Acceleration.Info(accel_id).Moments;
xsid   = data.Acceleration.Info(accel_id).XSID;
[a_handle, is_dsa] = get_accel_function_handle(data.Acceleration.Info(accel_id));
% Perform DSA Preconditioning
% ------------------------------------------------------------------------------
if is_dsa
    % Get DSA system matrix if not set
    if isempty(A), A = a_handle(data,accel_id,xsid,mesh,DoF,FE); end
    % Compute error and apply correction based on DSA type
    if a_type == glob.Accel_WGS_DSA || a_type == glob.Accel_AGS_TG
        dx = A\data.Acceleration.Residual{accel_id};
        data = update_DSA_solutions(data, accel_id, mesh, DoF, dx);
    elseif a_type == glob.Accel_Fission_DSA
        
    end
% Perform TSA Preconditioning
% ------------------------------------------------------------------------------
else
    % nothing yet - this will be a relatively quick fix at a later date...
end
% Apply acceleration outputs
% ------------------------------------------------------------------------------
varargout{1} = data;
varargout{2} = A;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Auxialiary Function Calls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [a_handle, is_dsa] = get_accel_function_handle(accel)
global glob
accel_type = accel.AccelerationType;
accel_disc = accel.DiscretizationType;
% Search through acceleration types
if      accel_type == glob.Accel_WGS_DSA || ...
        accel_type == glob.Accel_AGS_TG  || ...
        accel_type == glob.Accel_Fission_DSA
    is_dsa = true;
    % Switch between diffusion discretizations
    if accel_disc == glob.Accel_DSA_MIP
        a_handle = @exec_func_LHS_DSA_MIP;
    elseif accel_disc == glob.Accel_DSA_IP
        a_handle = @exec_func_LHS_DSA_IP;
    elseif accel_disc == glob.Accel_DSA_DCF
        a_handle = @exec_func_LHS_DSA_DCF;
    elseif accel_disc == glob.Accel_DSA_M4S
        a_handle = @exec_func_LHS_DSA_M4S;
    end
elseif  accel_type == glob.Accel_WGS_TSA || ...
        accel_type == glob.Accel_AGS_TTG
    is_dsa = false;
    if accel_disc == glob.Accel_TSA_DFEM
        a_handle = @exec_func_DFEM_TSA;
    elseif accel_disc == glob.Accel_TSA_CFEM
        a_handle = @exec_func_CFEM_TSA;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = update_DSA_solutions(data, accel_id, mesh, DoF, dx)
eshape = data.Acceleration.Info(accel_id).ErrorShape;
grps = data.Acceleration.Info(accel_id).Groups; ngrps = length(grps);
% Loop through Cells
for c=1:mesh.TotalCells
    mat = mesh.MatID(c);
    tvec = eshape(mat,:);
    cn = DoF.ConnectivityArray{c};
    % Loop through Energy Groups
    for g=1:ngrps
        data.Fluxes.Phi{grps(g),1}(cn) = data.Fluxes.Phi{grps(g),1}(cn) + tvec(g)*dx(cn);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = update_TSA_solutions(data, accel_id, mesh, DoF, dx)
% not implemented yet...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%