%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          2D Unresolved Boundary Layer (grazing angle and opposing
%                   reflecting y-dimension boundaries)
%
%   Author:         Michael W. Hackemack
%   Institution:    Texas A&M University
%   Year:           2016
%   
%   Description:    
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Note(s):        
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prepare Project Space
% ------------------------------------------------------------------------------
clc; close all; format long e; clear;
fpath = get_path(); addpath(fpath);
global glob; glob = get_globals('Office');
inp = 'Transport_UBL_REF';
addpath([glob.input_path,inp]); % This one must be last to properly switch input files
% Being User Input Section
% ------------------------------------------------------------------------------
sdm = {'LAGRANGE'};
fedeg = [1];
% sdm = {'WACHSPRESS','PWLD','MV','MAXENT'};
% fedeg = [1,2];
dat_in.FEMLumping = false;
% ---
dat_in.QuadType = 'PGLC';
dat_in.SnLevels = 8;
dat_in.AzimuthalLevels = 1;
dat_in.PolarLevels = 8;
dat_in.PolarDimension = 1;
% ---
geom_in.Dimension = 2;
geom_in.GeometryType = 'cart';
geom_in.Lx = 1;
geom_in.Ly = 1;
geom_in.x = unique([linspace(0,0.01,1001),linspace(0.01,1,251)]);
geom_in.y = [0,1];
geom_in.xmin_bound_type = glob.Function;
geom_in.xmax_bound_type = glob.Vacuum;
geom_in.ymin_bound_type = glob.Reflecting;
geom_in.ymax_bound_type = glob.Reflecting;
geom_in.xmin_val = str2func(sprintf('BoundaryFunc_UBL_PGLC%d',dat_in.PolarLevels));
geom_in.xmax_val = 0;
geom_in.ymin_val = 0;
geom_in.ymax_val = 0;
% ---
dat_in.refineMesh = 0;
dat_in.refinementLevels = 4;
dat_in.AMRIrregularity = 1;
dat_in.refinementTolerance = 0.3;
dat_in.projectSolution = 1;
% ---
sigt = [500];
sr = [0.9,0.95,0.99,0.999,0.9999];
dat_in.RHSFunc = {@ZeroTransportFunction};
% Execute Problem Suite
% ------------------------------------------------------------------------------
% Loop through FEM degrees
for k=1:length(fedeg)
    dat_in.FEMDegree = fedeg(k);
    % Loop through basis functions
    for s=1:length(sdm)
        dat_in.SpatialMethod = sdm{s};
        % Loop through total cross sections
        for t=1:length(sigt)
            for cc=1:length(sr)
                dat_in.TotalXS = sigt(t);
                dat_in.c = sr(cc);
                data = load_user_input(dat_in, geom_in);
                [data,geometry] = load_geometry_input(data, geom_in);
                data.problem.Path = ['Transport/UnresolvedBoundaryLayer_REF/',geom_in.GeometryType];
                data.problem.Name = sprintf('PGLC%d_sig%d_c=%d_%s%d',dat_in.PolarLevels,sigt(t),dat_in.c,sdm{s},fedeg(k));
                % Run problem iteration
                [data, geometry] = process_input_data(data, geometry);
                data = cleanup_neutronics_input_data(data, geometry);
                [data, sol, geometry, DoF, FE] = execute_problem(data, geometry);
                plot_solution(geometry,DoF,FE,sol.flux);
            end
        end
    end
end

