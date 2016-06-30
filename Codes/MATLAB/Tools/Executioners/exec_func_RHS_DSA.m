%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          Execution Functor - DSA RHS Residuals
%
%   Author:         Michael W. Hackemack
%   Institution:    Texas A&M University
%   Year:           2015
%   
%   Description:    Builds 
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = exec_func_RHS_DSA(data,accel_id,xsid,mesh,DoF,FE,phi,phi0)
% Retrieve some data information
% ------------------------------------------------------------------------------
global glob
accel = data.Acceleration.Info(accel_id);
a_type = accel.AccelerationType;
% Utilize residual contribution based on acceleration type
% ------------------------------------------------------------------------------
if a_type == glob.Accel_WGS_DSA || a_type == glob.Accel_AGS_TG || ...
   a_type == glob.Accel_AGS_MTG
    res = get_dsa_scattering_residual_contribution(accel,data.XS(xsid),mesh,DoF,FE,phi,phi0);
    data.Acceleration.Residual{accel_id} = res;
elseif a_type == glob.Accel_WGS_MJIA_DSA
    % Calculate acceleration residuals
    res = get_mjia_residual(accel,data.XS(xsid),mesh,DoF,FE,phi,phi0);
    data.Acceleration.Residual{accel_id} = res;
elseif a_type == glob.Accel_Fission_DSA
    
elseif a_type == glob.Accel_AGS_TTG || a_type == glob.Accel_AGS_MTTG
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Function Listing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = get_dsa_scattering_residual_contribution(accel,XS,mesh,DoF,FE,x,x0)
% Get some data
[gb,ge,ggb,gge] = get_group_bounds(accel);
ndof = DoF.TotalDoFs; out = zeros(ndof,1);
groups = accel.Groups;
% Loop through cells
for c=1:mesh.TotalCells
    cmat = mesh.MatID(c);
    cdof = DoF.ConnectivityArray{c};
    M = FE.CellMassMatrix{c};
    for g=gb:ge
        grp = groups(g);
        for gg=ggb(g):gge(g)
            ggrp = groups(gg);
            sxs = XS.ScatteringXS(cmat,grp,ggrp,1);
            out(cdof) = out(cdof) + sxs*M*(x{ggrp,1}(cdof) - x0{ggrp,1}(cdof));
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = get_mjia_residual(accel,XS,mesh,DoF,FE,x,x0)
% Get some data
grps = accel.Groups;
ngrps = length(grps);
ndof = DoF.TotalDoFs;
% Allocate memory space
out = zeros(ndof,1);
% Loop through cells
for c=1:mesh.TotalCells
    cmat = mesh.MatID(c);
    cdof = DoF.ConnectivityArray{c};
    M = FE.CellMassMatrix{c};
    for g=1:ngrps
        
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [gb,ge,ggb,gge] = get_group_bounds(accel)
global glob
ng = length(accel.Groups);
if accel.AccelerationType == glob.Accel_WGS_DSA
    gb = 1; ge = ng;
    ggb = ones(ng,1); gge = ng*ones(ng,1);
elseif accel.AccelerationType == glob.Accel_AGS_TG || ...
       accel.AccelerationType == glob.Accel_AGS_TTG
    gb = 1; ge = ng;
    ggb = 1 + (1:ng); gge = ng*ones(ng,1);
elseif accel.AccelerationType == glob.Accel_AGS_MTG || ...
       accel.AccelerationType == glob.Accel_AGS_MTTG
    gb = 1; ge = ng;
    ggb = (1:ng); gge = ng*ones(ng,1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%