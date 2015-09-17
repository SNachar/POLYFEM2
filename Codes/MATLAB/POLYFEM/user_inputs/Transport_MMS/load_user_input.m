function [data, geometry] = load_user_input()
global glob
% Problem Input Parameters
% ------------------------------------------------------------------------------
data.problem.Path = 'Transport_MMS/Gauss_iso_2D';
data.problem.Name = 'AMR_tri_Irr=3_rtol=0.5';
data.problem.NumberMaterials = 1;
data.problem.problemType = 'SourceDriven';
data.problem.plotSolution = 0;
data.problem.saveSolution = 0;
data.problem.saveVTKSolution = 0;
% AMR Input Parameters
% ------------------------------------------------------------------------------
data.problem.refineMesh = 1;
data.problem.refinementLevels = 10;
data.problem.refinementTolerance = 0.3;
data.problem.AMRIrregularity = 1;
data.problem.projectSolution = 0;
data.problem.refinementType = 1; % 0 = err(c)/maxerr < c, 1 = numc/totalCells = c
% Neutronics Data
% ------------------------------------------------------------------------------
data.Neutronics.PowerLevel = 1.0; % only for eigenvalue problems
data.Neutronics.StartingSolution = 'zero';
data.Neutronics.transportMethod = 'Transport';
data.Neutronics.FEMType = 'DFEM';
data.Neutronics.SpatialMethod = 'MAXENT';
data.Neutronics.FEMDegree = 2;
data.Neutronics.numberEnergyGroups = 1;
% Transport Properties
% ------------------------------------------------------------------------------
% MMS Properties
data.Neutronics.Transport.MMS = true;
data.Neutronics.Transport.QuadOrder = 6;
data.Neutronics.Transport.ExtSource = cell(data.Neutronics.numberEnergyGroups,1);
data.Neutronics.Transport.ExactSolution = cell(data.Neutronics.numberEnergyGroups,1);
% Flux/Angle Properties
data.Neutronics.Transport.fluxMoments = 0;
data.Neutronics.Transport.AngleAggregation = 'single';
data.Neutronics.Transport.QuadType = 'LS';
data.Neutronics.Transport.SnLevels = 4;
data.Neutronics.Transport.QuadAngles  = [1,1];  % Angles for manual set, not needed otherwise
data.Neutronics.Transport.QuadWeights = [1];    % Weights for manual set, not needed otherwise
% Sweep Operations
data.Neutronics.Transport.performSweeps = 0;
data.Neutronics.Transport.visualizeSweeping = 0;
% Tranpsort Type Properties - most of this only applies to hybrid transport
data.Neutronics.Transport.transportType = 'upwind';
data.Neutronics.Transport.StabilizationMethod = 'EGDG';
data.Neutronics.Transport.FluxStabilization = 2.0;
data.Neutronics.Transport.CurrentStabilization = 1.0;
% Physical Properties
data.Neutronics.Transport.ScatteringXS = zeros(1,1,1);
% data.Neutronics.Transport.TotalXS = [0];
% data.Neutronics.Transport.AbsorbXS = [0];
data.Neutronics.Transport.TotalXS = [1];
data.Neutronics.Transport.AbsorbXS = [1];
data.Neutronics.Transport.ScatteringXS(1,:,:) = [0.0];
data.Neutronics.Transport.FissionXS = [0.0];
data.Neutronics.Transport.NuBar = [0.0];
data.Neutronics.Transport.FissSpec = [0.0];
data.Neutronics.Transport.ExtSource{1,1} = @rhs_func_gauss_iso;
data.Neutronics.Transport.ExactSolution{1,1} = @sol_func_gauss_iso;
% Boundary Conditions
% data.Neutronics.Transport.BCFlags = [glob.Function];
% data.Neutronics.Transport.BCVals{1,1} = @ang_sol_func_quad_patch;
data.Neutronics.Transport.BCFlags = [glob.Vacuum];
data.Neutronics.Transport.BCVals = [0.0];

% DSA Properties
% ------------------------------------------------------------------------------
data.Neutronics.Transport.performDSA = 0;
data.Neutronics.Transport.DSAType = 'MIP';
data.Neutronics.IP_Constant = 4;

% Solver Input Parameters
% -----------------------
data.solver.absoluteTolerance = 1e-8;
data.solver.relativeTolerance = 1e-8;
data.solver.maxIterations = 2000;
data.solver.performNKA = 0;
data.solver.kyrlovSubspace = [];

% Geometry Data
% ------------------------------------------------------------------------------
data.problem.Dimension = 2;
L = 1; ncells = 4;

% xx=linspace(0,L,ncells+1);
% [x,y]=meshgrid(xx,xx);
% x=x(:);y=y(:);
% tri = delaunayTriangulation(x,y);
% geometry = GeneralGeometry(2, 'Delaunay', tri);

x=linspace(0,L,ncells+1);
y=linspace(0,L,ncells+1);
% z=linspace(0,L,ncells+1);
% geometry = CartesianGeometry(1,x);
geometry = CartesianGeometry(2,x,y);
% geometry = CartesianGeometry(3,x,y,z);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   MMS Function Listings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = rhs_func_gauss_iso(xx, dir)
x = xx(:,1); y = xx(:,2);
Lx = 1; Ly = 1;
x0 = 0.75*Lx; y0 = 0.75*Ly;
Omegax = dir(1); Omegay = dir(2);
sigma_t = 1.0; varia=Lx^2/100;
out = -Omegay.*(1.0./Lx.^2.*1.0./Ly.^2.*x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*...
    (Lx-x).*1.0e2-1.0./Lx.^2.*1.0./Ly.^2.*x.*exp(-((x-x0).^2+(y-y0).^2)./varia).*...
    (Lx-x).*(Ly-y).*1.0e2+(1.0./Lx.^2.*1.0./Ly.^2.*x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*...
    (y.*2.0-y0.*2.0).*(Lx-x).*(Ly-y).*1.0e2)./varia)-Omegax.*(1.0./Lx.^2.*1.0./Ly.^2.*...
    x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*(Ly-y).*1.0e2-1.0./Lx.^2.*1.0./Ly.^2.*...
    y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*(Lx-x).*(Ly-y).*1.0e2+(1.0./Lx.^2.*1.0./Ly.^2.*...
    x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*(x.*2.0-x0.*2.0).*(Lx-x).*(Ly-y).*1.0e2)./varia)...
    +1.0./Lx.^2.*1.0./Ly.^2.*sigma_t.*x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*(Lx-x).*(Ly-y).*1.0e2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = ang_sol_func_gauss_iso(xx, ~)
x = xx(:,1); y = xx(:,2);
Lx = 1; Ly = 1;
x0 = 0.75*Lx; y0 = 0.75*Ly;
varia=Lx^2/100;
out = 1.0./Lx.^2.*1.0./Ly.^2.*x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*(Lx-x).*(Ly-y).*1.0e2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = sol_func_gauss_iso(xx, ~)
x = xx(:,1); y = xx(:,2);
Lx = 1; Ly = 1;
x0 = 0.75*Lx; y0 = 0.75*Ly;
varia=Lx^2/100;
out = 1.0./Lx.^2.*1.0./Ly.^2.*pi.*x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*(Lx-x).*(Ly-y).*2.0e2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = rhs_func_gauss_quad(xx, dir)
x = xx(:,1); y = xx(:,2);
Lx = 1; Ly = 1;
x0 = 0.75*Lx; y0 = 0.75*Ly;
Omegax = dir(1); Omegay = dir(2);
sigma_t = 1.0; varia=Lx^2/100;
out = -Omegay.*(1.0./Lx.^2.*1.0./Ly.^2.*x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*...
    (Omegax.^2-1.0).*(Omegay.^2-1.0).*(Lx-x).*1.0e2-1.0./Lx.^2.*1.0./Ly.^2.*x.*...
    exp(-((x-x0).^2+(y-y0).^2)./varia).*(Omegax.^2-1.0).*(Omegay.^2-1.0).*(Lx-x).*(Ly-y).*...
    1.0e2+(1.0./Lx.^2.*1.0./Ly.^2.*x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*(Omegax.^2-1.0).*...
    (Omegay.^2-1.0).*(y.*2.0-y0.*2.0).*(Lx-x).*(Ly-y).*1.0e2)./varia)-Omegax.*...
    (1.0./Lx.^2.*1.0./Ly.^2.*x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*(Omegax.^2-1.0).*...
    (Omegay.^2-1.0).*(Ly-y).*1.0e2-1.0./Lx.^2.*1.0./Ly.^2.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*...
    (Omegax.^2-1.0).*(Omegay.^2-1.0).*(Lx-x).*(Ly-y).*1.0e2+(1.0./Lx.^2.*1.0./Ly.^2.*...
    x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*(x.*2.0-x0.*2.0).*(Omegax.^2-1.0).*...
    (Omegay.^2-1.0).*(Lx-x).*(Ly-y).*1.0e2)./varia)+1.0./Lx.^2.*1.0./Ly.^2.*sigma_t.*...
    x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*(Omegax.^2-1.0).*(Omegay.^2-1.0).*(Lx-x).*(Ly-y).*1.0e2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = sol_func_gauss_quad(xx, ~)
x = xx(:,1); y = xx(:,2);
Lx = 1; Ly = 1;
x0 = 0.75*Lx; y0 = 0.75*Ly;
varia=Lx^2/100;
out = 1.0./Lx.^2.*1.0./Ly.^2.*pi.*x.*y.*exp(-((x-x0).^2+(y-y0).^2)./varia).*(Lx-x).*(Ly-y).*2.5e1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = rhs_func_quad_patch(xx, dir)
x = xx(:,1); y = xx(:,2);
Omegax = dir(1); Omegay = dir(2);

out = -Omegax.*(x.*-2.0+y.*3.0+2.0)+Omegay.*(x.*-3.0+y.*8.0+6.0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = sol_func_quad_patch(xx, ~)
x = xx(:,1); y = xx(:,2);

out = pi.*(x.*-2.0+y.*6.0-x.*y.*3.0+x.^2+y.^2.*4.0+1.0).*2.0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = ang_sol_func_quad_patch(xx, ~)
x = xx(:,1); y = xx(:,2);

out = x.*-2.0+y.*6.0-x.*y.*3.0+x.^2+y.^2.*4.0+1.0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%