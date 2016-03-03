%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          Fourier Analysis Script
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
% Clear Project Space
% ------------------------------------------------------------------------------
if exist('pbool', 'var')
    clearvars -except pbool
else
    clear; pbool = false;
end
clc; close all; format long e
if ~pbool, fpath = get_path(); addpath(fpath); pbool = true; end
% Define Path
% -----------
global glob
glob = get_globals('Home');
glob.print_info = false;
% Define all user inputs
% ------------------------------------------------------------------------------
inp = '2D_1G_DSA'; addpath([glob.input_path,inp]);
data = load_user_input();
% additional inputs
data.Type = 'Grid';
data.NumberPhasePerDim = 121;
% end user input section
% ------------------------------------------------------------------------------
% Populate data and output structures
% -----------------------------------
print_FA_heading(data);
[data, inputs] = process_fourier_inputs( data );
inputs = build_phase_transformation_matrix(data, inputs);
% Create directory and output file names
% --------------------------------------
outdir = sprintf('outputs/PHI/%dD/%s/',data.problem.Dimension,data.geometry.type);
if data.Neutronics.FEMLumping
    lump = 'L';
else
    lump = 'U';
end
if ~data.Neutronics.PerformAcceleration % Unaccelerated
    outname = sprintf('%s_%s',data.Neutronics.TransportMethod,data.Neutronics.SpatialMethod);
elseif data.Neutronics.PerformAcceleration % Accelerated
    outname = sprintf('%s_%s_C=%d_%s%s%d',data.Neutronics.TransportMethod,data.Neutronics.DSAType,data.Neutronics.IP_Constant,lump,data.Neutronics.SpatialMethod,data.Neutronics.FEMDegree);
end
if ~isequal(exist(outdir, 'dir'),7),mkdir(outdir); end
% Retrieve all spectrum data and postprocess
% ------------------------------------------
outputs = calculate_eigenspectrums(data, inputs);
% Loop through quadrature sets
if data.Output.plotting_bool
    for q=1:length(data.Neutronics.Transport.SnLevels)
        % Loop through meshes in 1D
        if data.problem.Dimension == 1
            
        else
            % Loop through meshes in 2D/3D
            c = 0;
            for j=1:inputs.nyz
                for i=1:inputs.nx
                    c = c + 1;
                    
                end
            end
        end
    end
end
