%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          Execution Functor - DFEM Transport (upwind)
%
%   Author:         Michael W. Hackemack
%   Institution:    Texas A&M University
%   Year:           2014
%   
%   Description:    
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = exec_func_dfem_transport_upwind_Rev1(data,xsid,qid,groups,mesh,DoF,FE)
global glob
% Setup Solution Space
% ------------------------------------------------------------------------------
[data, flux_out] = setup_solution_space(data, mesh, DoF);
% Loop through Angle Sets
% ------------------------------------------------------------------------------
ang_sets = data.Quadrature(qid).AngleSets; nas = length(ang_sets);
rev_str = [];
for m=1:nas
    % Print Angle Set Iteration
    if glob.print_info
        msg = sprintf('   Calculating Flux for Angle Set: %d of %d',m,nas);
        fprintf([rev_str,msg]);
        rev_str = repmat(sprintf('\b'), 1, length(msg));
    end
    % Collect Matrix and RHS and compute angular fluxes
    L = exec_func_LHS_dfem_transport_upwind_Rev1(data,xsid,qid,ang_sets{m},groups,mesh,DoF,FE);
    rhs = exec_func_RHS_dfem_transport_Rev1(data,qid,ang_sets{m},groups,mesh,DoF,FE);
    y = L\rhs;
    % Postprocess angular flux solutions
    flux_out = add_to_flux(data.Quadrature(qid),ang_sets{m},groups,y,flux_out);
    data = add_reflecting_angular_fluxes(data,qid,xsid,mesh,DoF,ang_sets{m},groups,y);
end
% Set Outputs
% ------------------------------------------------------------------------------
varargout{1} = data;
varargout{2} = flux_out;
% Clear Command Line Text
if glob.print_info, fprintf(rev_str); end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [data, flux_out] = setup_solution_space(data, DoF)
if data.Fluxes.HasReflectingBoundary || data.Fluxes.HasPeriodicBoundary
    data.Fluxes.ReflectingFluxesOld = data.Fluxes.ReflectingFluxes;
    data.Fluxes.PeriodicFluxesOld = data.Fluxes.PeriodicFluxes;
end
% Set zero flux moments
ndof = DoF.TotalDoFs;
flux_out = cell(data.Groups.numberEnergyGroups, data.Fluxes.TotalFluxMoments);
for g=1:data.Groups.numberEnergyGroups
    for m=1:data.Fluxes.TotalFluxMoments
        flux_out{g,m} = zeros(ndof, 1);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function flux = add_to_flux(mquad, angs, groups, ndof, psi, flux)
dofs = (1:ndof)';
ng = length(groups);
na = length(angs);
q_offset = (1:na)*ndof - ndof;
g_offset = (1:ng)*ndof*na - ndof*na;
for q=1:na
    tq = angs(q);
    for g=1:ng
        grp = groups(g);
        qgdofs = dofs + g_offset(g) + q_offset(q);
        for m=1:mquad.TotalFluxMoments
            flux{grp,m} = flux{grp,m} + mquad.discrete_to_moment(m,tq)*psi(qgdofs);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = add_reflecting_angular_fluxes(data,qid,xsid,mesh,DoF,angs,groups,y)
global glob
ndof = DoF.TotalDoFs;
ng = length(groups);
na = length(angs);
q_offset = (1:na)*ndof - ndof;
g_offset = (1:ng)*ndof*na - ndof*na;
for f=1:mesh.TotalBoundaryFaces
    ff = mesh.BoundaryFaces(f);
    fflag = mesh.FaceID(ff);
    if data.XS(xsid).BCFlags(fflag) == glob.Reflecting
        opp_dir = data.Quadrature(qid).ReflectingBoundaryAngles{f};
        fnorm = mesh.FaceNormal(ff,:)';
        for q=1:na
            tq = angs(q);
            adir = data.Quadrature(qid).AngularDirections(tq,:);
            afdot = adir * fnorm;
            if afdot > 0
                opd = opp_dir(tq);
                fnodes = DoF.FaceCellNodes{ff,1};
                for g=1:ng
                    grp = groups(g);
                    fnqg = fnodes + g_offset(g) + q_offset(q);
                    data.Fluxes.IncomingBoundaryFlux{ff}{opd,grp} = y(fnqg);
                end
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%