%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          Iron-Water Mark II Cross Sections
%
%   Author:         Michael W. Hackemack
%   Institution:    Texas A&M University
%   Year:           2014
%
%   Description:    MATLAB script to generate all cross section data needed for
%                   the Iron-Water Mark II cases.
%                   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Notes:          This cross section set is based on the problem in 
%                   Wang and Ragusa, NSE: 166, p. 145-166 (2010).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = get_IronWaterII_XS( data )
% Geometry Information
% --------------------
data.problem.NumberMaterials = 3;
% General Neutronics Information
% ------------------------------
data.Neutronics.numberEnergyGroups = 1;
data.Neutronics.Transport.PnOrder = 0;
% Neutronics Transport Cross-Sections
% -----------------------------------
% Allocate Cross-Sections
nm = data.problem.NumberMaterials;
ng = data.Neutronics.numberEnergyGroups;
nf = data.Neutronics.Transport.PnOrder + 1;
data.Neutronics.Transport.TotalXS = zeros(nm, ng);
data.Neutronics.Transport.AbsorbXS = zeros(nm, ng);
data.Neutronics.Transport.FissionXS = zeros(nm, ng);
data.Neutronics.Transport.NuBar = zeros(nm, ng);
data.Neutronics.Transport.FissSpec = zeros(nm, ng);
data.Neutronics.Transport.ExtSource = zeros(nm, ng);
data.Neutronics.Transport.ScatteringXS = zeros(nm,ng,ng,nf);
% Material 1
data.Neutronics.Transport.TotalXS(1,:) =   1.00;
data.Neutronics.Transport.AbsorbXS(1,:) =  1.00*0.1;
data.Neutronics.Transport.FissionXS(1,:) = 0.00;
data.Neutronics.Transport.NuBar(1,:) =     0.00;
data.Neutronics.Transport.FissSpec(1,:) =  0.00;
data.Neutronics.Transport.ExtSource(1,:) = 1.00;
data.Neutronics.Transport.ScatteringXS(1,:,:,1) = 1.00*.9;
% Material 2
data.Neutronics.Transport.TotalXS(2,:) =   1.50;
data.Neutronics.Transport.AbsorbXS(2,:) =  1.50*0.04;
data.Neutronics.Transport.FissionXS(2,:) = 0.00;
data.Neutronics.Transport.NuBar(2,:) =     0.00;
data.Neutronics.Transport.FissSpec(2,:) =  0.00;
data.Neutronics.Transport.ExtSource(2,:) = 0.00;
data.Neutronics.Transport.ScatteringXS(2,:,:,1) = 1.50*.96;
% Material 3
data.Neutronics.Transport.TotalXS(3,:) =   1.00;
data.Neutronics.Transport.AbsorbXS(3,:) =  1.00*0.7;
data.Neutronics.Transport.FissionXS(3,:) = 0.00;
data.Neutronics.Transport.NuBar(3,:) =     0.00;
data.Neutronics.Transport.FissSpec(3,:) =  0.00;
data.Neutronics.Transport.ExtSource(3,:) = 0.00;
data.Neutronics.Transport.ScatteringXS(3,:,:,1) = 1.00*0.3;