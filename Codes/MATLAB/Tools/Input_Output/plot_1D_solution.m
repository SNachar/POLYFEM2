%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          Plot 1D Solution
%
%   Author:         Michael W. Hackemack
%   Institution:    Texas A&M University
%   Year:           2015
%
%   Description:    MATLAB function to plot scalar solutions in 1D.
%                   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Notes:          We use the quadrature points as additional interpolation
%                   points besides the solution nodes. This acts to make the 1D
%                   solution plot 'smoother' for higher order problems.
%
%                   This has been so far tested out to an FEM order of k=16 for
%                   a Reed problem that is highly diffusive and using MIP DSA.
%                   Eventually, depending on the quadrature set used, imaginary
%                   solutions begin to appear or the solution fails to converge.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_1D_solution(mesh, DoF, FE, x)
if iscell(x), x = x{1}; end
hold on
xlim([min(mesh.Vertices), max(mesh.Vertices)])
if DoF.Degree == 0
    
else
    for c=1:DoF.TotalCells
        % Retrieve DoF information for cell
        cn = DoF.ConnectivityArray{c};
        nodes = DoF.NodeLocations(cn,:);
        % Interpolate to all quadrature points - this acts to build a larger
        % interpolation space and make higher order 1D basis functions not appear
        % linear when plotted.
        qx = FE.CellQuadNodes{c};
        bv = FE.CellBasisValues{c}; yy = x(cn);
        xlin = [nodes;qx];
        y = [yy;bv*yy];
        [xlin, ind]=sort(xlin);
        y=y(ind);
        % Plot Values
        plot(xlin, y, 'k');
    end
end
hold off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%