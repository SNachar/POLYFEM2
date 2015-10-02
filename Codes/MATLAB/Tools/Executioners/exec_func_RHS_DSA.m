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
function data = exec_func_RHS_DSA(data,accel_id,xsid,mesh,DoF,FE)
% Retrieve some data information
% ------------------------------------------------------------------------------
global glob
accel = data.Acceleration.Info(accel_id);
a_type = accel.AccelerationType;
% Utilize residual contribution based on acceleration type
% ------------------------------------------------------------------------------
if a_type == glob.Accel_WGS_DSA || a_type == glob.Accel_AGS_TG
    res = get_scattering_residual_contribution(accel,data.XS(xsid),mesh,DoF,FE,data.Fluxes.Phi,data.Fluxes.PhiOld);
    data.Acceleration.Residual{accel_id} = res;
elseif a_type == glob.Accel_Fission_DSA
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Function Listing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = get_scattering_residual_contribution(accel,XS,mesh,DoF,FE,x,x0)
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
function [gb,ge,ggb,gge] = get_group_bounds(accel)
global glob
ng = length(accel.Groups);
if accel.AccelerationType == glob.Accel_WGS_DSA
    gb = 1; ge = ng;
    ggb = ones(ng,1); 
    gge = ng*ones(ng,1);
elseif accel.AccelerationType == glob.Accel_AGS_TG
    gb = 1; ge = ng;
    gge = ng*ones(ng,1);
    ggb = 1 + (1:ng);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%