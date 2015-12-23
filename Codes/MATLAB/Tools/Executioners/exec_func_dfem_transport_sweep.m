%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          Execution Functor - DFEM Transport with Sweeps
%
%   Author:         Michael W. Hackemack
%   Institution:    Texas A&M University
%   Year:           2014
%   
%   Description:    Invert Transport Operator by Sweeping - upwind scheme is
%                   strongly enforced.
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = exec_func_dfem_transport_sweep(ndat, solvdat, mesh, DoF, FE, x, A)
global glob
% Setup Solution Space
% ------------------------------------------------------------------------------
[ndat, flux_out] = setup_solution_space(ndat, mesh, DoF);
DSA_iterations = 0;
% Loop through Angle Sets
% ------------------------------------------------------------------------------
groups = 1:ndat.numberEnergyGroups;
ang_sets = ndat.Transport.AngleSets; nas = length(ang_sets);
rev_str = [];
for m=1:nas
    % Print Angle Set Iteration
    if glob.print_info
        msg = sprintf('   Calculating Flux for Angle Set: %d of %d',m,nas);
        fprintf([rev_str,msg]);
        rev_str = repmat(sprintf('\b'), 1, length(msg));
    end
    % Perform Sweep Operations
    angs = ndat.Transport.AngleSets{m};
    psi = exec_func_transport_sweep(ndat, mesh, DoF, FE, x, m, groups);
    % Update Flux Information
    flux_out = add_to_flux(psi, ndat, angs, groups, flux_out);
    ndat = add_reflecting_angular_fluxes(psi, ndat, mesh, DoF, angs, groups);
    ndat = compute_partial_boundary_currents(psi, ndat, mesh, DoF, angs, groups);
end
% Perform DSA Update
% ------------------------------------------------------------------------------
if ndat.Transport.performDSA
    % Print DSA Calculation Information
    if glob.print_info
        msg = '   Performing DSA Correction Calculation.';
        fprintf([rev_str,msg]);
        rev_str = repmat(sprintf('\b'), 1, length(msg));
    end
    [flux_out, A, DSA_iterations, DSA_time] = perform_DSA_step(ndat, solvdat, mesh, DoF, FE, flux_out, x, A);
end
% Set Outputs
% ------------------------------------------------------------------------------
nout = nargout;
varargout{1} = ndat;
varargout{2} = flux_out;
if nout > 2, varargout{3} = A; end
if nout > 3, varargout{4} = DSA_iterations; end
if nout > 4, varargout{5} = DSA_time; end
% Clear Command Line Text
if glob.print_info, fprintf(rev_str); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ndat, flux_out] = setup_solution_space(ndat, mesh, DoF)
if ndat.Transport.HasReflectingBoundary || ndat.Transport.HasPeriodicBoundary
    ndat.Transport.ReflectingFluxesOld = ndat.Transport.ReflectingFluxes;
    ndat.Transport.PeriodicFluxesOld = ndat.Transport.PeriodicFluxes;
end
ndat.Transport.OutgoingCurrentsOld = ndat.Transport.OutgoingCurrents;
ndat.Transport.IncomingCurrentsOld = ndat.Transport.IncomingCurrents;
ndat = zero_partial_currents(ndat, mesh, DoF);
% Set zero flux moments
ndof = DoF.TotalDoFs;
flux_out = cell(ndat.numberEnergyGroups, ndat.Transport.TotalFluxMoments);
for g=1:ndat.numberEnergyGroups
    for m=1:ndat.Transport.TotalFluxMoments
        flux_out{g,m} = zeros(ndof, 1);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ndat = add_reflecting_angular_fluxes(psi, ndat, mesh, DoF, angs, groups)
if ~ndat.Transport.HasReflectingBoundary, return; end
global glob
ng = length(groups);
na = length(angs);
for f=1:mesh.TotalBoundaryFaces
    ff = mesh.BoundaryFaces(f);
    fflag = mesh.FaceID(ff);
    if ndat.Transport.BCFlags(fflag) ~= glob.Reflecting, continue; end
    fnorm = mesh.FaceNormal(ff,:)';
    fnodes = DoF.FaceCellNodes{ff,1};
    for q=1:na
        tq = angs(q);
        adir = ndat.Transport.AngularDirections(tq,:);
        afdot = adir * fnorm;
        if afdot > 0
            for g=1:ng
                grp = groups(g);
                ndat.Transport.ReflectingFluxes{ff}{tq}(:,grp) = psi(fnodes,q,g);
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ndat = compute_partial_boundary_currents(x, ndat, mesh, DoF, angs, groups)
ng = length(groups);
na = length(angs);
for f=1:mesh.TotalBoundaryFaces
    ff = mesh.BoundaryFaces(f);
    fnorm = mesh.FaceNormal(ff,:)';
    fnodes = DoF.FaceCellNodes{ff,1};
    for q=1:na
        tq = angs(q);
        adir = ndat.Transport.AngularDirections(tq,:);
        afdot = adir * fnorm;
        wt = ndat.Transport.AngularWeights(tq);
        for g=1:ng
            if afdot > 0
                tv = ndat.Transport.OutgoingCurrents{ff};
                tv(:,g) = tv(:,g) + wt * afdot * x(fnodes,q,g);
                ndat.Transport.OutgoingCurrents{ff}(:,g) = tv(:,g);
            elseif afdot < 0
                tv = ndat.Transport.IncomingCurrents{ff};
                tv(:,g) = tv(:,g) + wt * afdot * x(fnodes,q,g);
                ndat.Transport.IncomingCurrents{ff}(:,g) = tv(:,g);
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ndat = zero_partial_currents(ndat, mesh, DoF)
ng = ndat.numberEnergyGroups;
ndat.Transport.OutgoingCurrents = cell(mesh.TotalFaces, 1);
ndat.Transport.IncomingCurrents = cell(mesh.TotalFaces, 1);
for f=1:mesh.TotalBoundaryFaces
    ff = mesh.BoundaryFaces(f);
    fdn = length(DoF.FaceCellNodes{ff,1});
    ndat.Transport.OutgoingCurrents{ff} = zeros(fdn,ng);
    ndat.Transport.IncomingCurrents{ff} = zeros(fdn,ng);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function flux = add_to_flux(psi, ndat, angs, groups, flux)
ng = length(groups);
na = length(angs);
for q=1:na
    tq = angs(q);
    for g=1:ng
        grp = groups(g);
        for m=1:ndat.Transport.TotalFluxMoments
            d2m = ndat.Transport.discrete_to_moment(m,tq);
            flux{grp,m} = flux{grp,m} + d2m*psi(:,q,g);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [x, A, DSA_it] = perform_DSA_step(ndat, solvdat, mesh, DoF, FE, x, x0, A)
% Form scalar flux differences
for g=1:ndat.numberEnergyGroups
    x0{g} = x{g,1} - x0{g,1};
end
% Switch based on DSA type
if strcmp(ndat.Transport.DSAType, 'MIP')
    [x0, A, DSA_it] = perform_MIP_DSA(ndat, solvdat, mesh, DoF, FE, x0, A);
elseif strcmp(ndat.Transport.DSAType, 'IP')
    [x0, A, DSA_it] = perform_IP_DSA(ndat, solvdat, mesh, DoF, FE, x0, A);
elseif strcmp(ndat.Transport.DSAType, 'M4S')
    [x0, A, DSA_it] = perform_M4S_DSA(ndat, solvdat, mesh, DoF, FE, x0, A);
end
% Add DSA correction
for g=1:ndat.numberEnergyGroups
    x{g,1} = x{g,1} + x0{g};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%