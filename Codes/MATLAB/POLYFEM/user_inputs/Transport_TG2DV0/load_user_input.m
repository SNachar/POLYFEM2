function [data, geometry] = load_user_input()
global glob
% Problem Input Parameters
% ------------------------------------------------------------------------------
data.IO.Path = 'Transport/Homogeneous';
data.IO.Name = 'AMR_cart_Irr=3_rtol=0.2';
data.IO.PlotSolution = 0;
data.IO.SaveSolution = 0;
data.IO.SaveVTKSolution = 0;
data.IO.PrintIterationInfo = 1;
data.IO.PrintConstructionInfo = 1;
% AMR Input Parameters
% ------------------------------------------------------------------------------
data.AMR.RefineMesh = 0;
% MMS Input Parameters
% ------------------------------------------------------------------------------
data.MMS.PerformMMS = 0;
% Overall Problem Data
% ------------------------------------------------------------------------------
data.problem.NumberMaterials = 1;
data.problem.ProblemType = 'SourceDriven';
data.problem.PowerLevel = 1.0;
data.problem.TransportMethod = 'Transport';
data.problem.FEMType = 'DFEM';
data.problem.SpatialMethod = 'PWLD';
data.problem.FEMLumping = false;
data.problem.FEMDegree = 1;
% Transport Properties
% ------------------------------------------------------------------------------
% Tranpsort Type Properties - most of this only applies to hybrid transport
data.Transport.PerformAcceleration = true;
data.Transport.PnOrder = 0;
data.Transport.XSID = 1; data.Transport.QuadID = 1;
data.Transport.TransportType = 'upwind';
data.Transport.PerformSweeps = 0;
data.Transport.VisualizeSweeping = 0;
data.Transport.StabilizationMethod = 'EGDG';
data.Transport.FluxStabilization = 2.0;
data.Transport.CurrentStabilization = 1.0;
% Quadrature Properties
data.Quadrature(1).PnOrder = data.Transport.PnOrder;
data.Quadrature(1).AngleAggregation = 'all';
data.Quadrature(1).QuadType = 'LS';
data.Quadrature(1).SnLevels = 8;
data.Quadrature(1).PolarLevels = 4;
data.Quadrature(1).AzimuthalLevels = 4;
% Flux Properties
data.Fluxes.StartingSolution = 'zero';
% Construct Group Set Information
data.Groups.NumberEnergyGroups = 99;
data.Groups.FastGroups = 1:42;
data.Groups.ThermalGroups = 43:99;
data.Groups.NumberGroupSets = data.Groups.NumberEnergyGroups;
data.Groups.GroupSets = cell(data.Groups.NumberGroupSets,1);
data.Groups.GroupSetUpscattering = [false(length(data.Groups.FastGroups),1);true(length(data.Groups.ThermalGroups),1)];
for g=1:data.Groups.NumberGroupSets, data.Groups.GroupSets{g} = g; end
% Retrieve All Physical Properties
% ------------------------------------------------------------------------------
% Air
% data = add_xs_component_contribution(data, 1, 1, 'FG_CNat_99G', 7.4906E-9);
% data = add_xs_component_contribution(data, 1, 1, 'N14_99G', 3.9123E-5);
% data = add_xs_component_contribution(data, 1, 1, 'O16_99G', 1.0511E-5);
% data = add_xs_component_contribution(data, 1, 1, 'Ar40_99G', 2.3297E-7);
% Graphite
% data = add_xs_component_contribution(data, 1, 2, 'graphite_99G', 8.5238E-2);
% data = add_xs_component_contribution(data, 1, 2, 'B10_99G', 2.4335449e-06);
% HDPE
data = add_xs_component_contribution(data, 1, 1, 'PolyH1_99G', 8.1570E-2);
data = add_xs_component_contribution(data, 1, 1, 'FG_CNat_99G', 4.0787E-2);
% BHDPE
% data = add_xs_component_contribution(data, 1, 1, 'PolyH1_99G', 5.0859E-2);
% data = add_xs_component_contribution(data, 1, 1, 'FG_CNat_99G', 2.5429E-2);
% data = add_xs_component_contribution(data, 1, 1, 'B10_99G', 6.6256E-3);
% data = add_xs_component_contribution(data, 1, 1, 'B11_99G', 2.6669E-2);
% AmBe
% data = add_xs_component_contribution(data, 1, 4, 'Am241_99G', 1.1649E-3);
% data = add_xs_component_contribution(data, 1, 4, 'Be9_99G', 1.9077E-1);
% data = add_xs_component_contribution(data, 1, 4, 'O16_99G', 1.0511E-5);
data.XS(1).ExtSource = rand(data.problem.NumberMaterials,data.Groups.NumberEnergyGroups);
data.XS(1).BCFlags = [glob.Vacuum, glob.Reflecting];
data.XS(1).BCVals{1} = 0;
data.XS(1).BCVals{2} = 0;
% Acceleration Properties
% ------------------------------------------------------------------------------
data.Acceleration.WGSAccelerationBool = false(data.Groups.NumberGroupSets,1);
data.Acceleration.AGSAccelerationBool = true;
data.Acceleration.WGSAccelerationResidual = false(data.Groups.NumberGroupSets,1);
data.Acceleration.AGSAccelerationResidual = false;
data.Acceleration.WGSAccelerationID = zeros(data.Groups.NumberGroupSets,1);
data.Acceleration.AGSAccelerationID = 1;
data.Acceleration.Info(1).AccelerationType = glob.Accel_AGS_TG;
data.Acceleration.Info(1).DiscretizationType = glob.Accel_DSA_MIP;
data.Acceleration.Info(1).IP_Constant = 4;
data.Acceleration.Info(1).Groups = data.Groups.ThermalGroups;
data.Acceleration.Info(1).Moments = 1;
data.Acceleration.Info(1).XSID = 2;
data = collapse_tg_xs(data,1,2,1);
% Solver Input Parameters
% ------------------------------------------------------------------------------
data.solver.AGSMaxIterations = 1e4;
data.solver.WGSMaxIterations = 1e4*ones(data.Groups.NumberGroupSets,1);
data.solver.AGSRelativeTolerance = 1e-4;
data.solver.AGSAbsoluteTolerance = 1e-4;
data.solver.WGSRelativeTolerance = 1e-6*ones(data.Groups.NumberGroupSets,1);
data.solver.WGSAbsoluteTolerance = 1e-6*ones(data.Groups.NumberGroupSets,1);
% Geometry Data
% ------------------------------------------------------------------------------
data.problem.Dimension = 2;
Lx = 35; Ly = 45;
xd = [0,1,20,35];
yd = [0,3,35,45];
x = [linspace(xd(1),xd(2),2),linspace(xd(2),xd(3),6),linspace(xd(3),xd(4),4)];
y = [linspace(yd(1),yd(2),2),linspace(yd(2),yd(3),6),linspace(yd(3),yd(4),4)];
geometry = CartesianGeometry(2,unique(x),unique(y));
% Set material regions

% Set boundary conditions
geometry.set_face_flag_on_surface(2,[0,0;0,Ly]);
