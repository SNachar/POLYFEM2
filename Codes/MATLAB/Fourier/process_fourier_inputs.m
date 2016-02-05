%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          Process Fourier User Input
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
function [data, inputs] = process_fourier_inputs( data )
% Build Input Space
% ------------------------------------------------------------------------------
x      = data.geometry.x;      nx = length(x);
yz     = data.geometry.dyz;    nyz = length(yz);
ncellx = data.geometry.ncellx;
ncelly = data.geometry.ncelly;
ncellz = data.geometry.ncellz;
mats   = data.geometry.mats;
check_geometry_inputs(data,x,yz);
ntot = nx*nyz;
inputs.x = x';
inputs.yz = yz';
inputs.nx = nx;
inputs.nyz = nyz;
inputs.TotalMeshes = ntot;
inputs.meshes = cell(ntot, 1);
inputs.dofs = cell(ntot, 1);
inputs.fes = cell(ntot, 1);
inputs.ScatteringMatrix = cell(ntot, 1);
% Build Meshes
% ------------------------------------------------------------------------------
if data.problem.Dimension == 1
    for i=1:nx
        inputs.meshes{i} = CartesianGeometry(1, linspace(0,x(i),ncellx+1));
%         inputs.meshes{i} = CartesianGeometry(1, [0,x(i)]);
        inputs.meshes{i}.set_periodic_flag(1, 'x');
    end
elseif data.problem.Dimension == 2
    c = 0;
    for j=1:nyz
        for i=1:nx
            c = c + 1;
            if strcmp(data.geometry.type,'cart')
                inputs.meshes{c} = CartesianGeometry(2, linspace(0,x(i),ncellx+1), linspace(0,x(i)*yz(j),ncelly+1));
%                 inputs.meshes{c} = CartesianGeometry(2, [0,x(i)], [0,x(i)*yz(j)]);
            elseif strcmp(data.geometry.type,'tri')
                [xx,yy] = meshgrid(linspace(0,x(i),ncellx+1), linspace(0,x(i)*yz(j),ncelly+1));
%                 [xx,yy] = meshgrid([0,x(i)], [0,x(i)*yz(j)]);
                xx=xx(:);yy=yy(:);
                tri = delaunayTriangulation(xx,yy);
                inputs.meshes{c} = GeneralGeometry(2, 'Delaunay', tri);
            end
            inputs.meshes{c}.set_periodic_flag(1, 'x');
            inputs.meshes{c}.set_periodic_flag(1, 'y');
        end
    end
elseif data.problem.Dimension == 3
    c = 0;
    for j=1:nyz
        for i=1:nx
            c = c + 1;
            if strcmp(data.geometry.type,'cart')
                inputs.meshes{c} = CartesianGeometry(3, linspace(0,x(i),ncellx+1), linspace(0,x(i)*yz(j),ncelly+1), linspace(0,x(i)*yz(j),ncellz+1));
%                 inputs.meshes{c} = CartesianGeometry(3, [0,x(i)], [0,x(i)*yz(j)], [0,x(i)*yz(j)]);
            elseif strcmp(data.geometry.type,'tet')
                [xx,yy,zz] = meshgrid(linspace(0,x(i),ncellx+1), linspace(0,x(i)*yz(j),ncelly+1), linspace(0,x(i)*yz(j),ncellz+1));
%                 [xx,yy,zz] = meshgrid([0,x(i)], [0,x(i)*yz(j)], [0,x(i)*yz(j)]);
                xx=xx(:);yy=yy(:);zz=zz(:);
                tri = delaunayTriangulation(xx,yy,zz);
                inputs.meshes{c} = GeneralGeometry(3, 'Delaunay', tri);
            elseif strcmp(data.geometry.type,'tri')
                [xx,yy] = meshgrid(linspace(0,x(i),ncellx+1), linspace(0,x(i)*yz(j),ncelly+1));
%                 [xx,yy] = meshgrid([0,x(i)], [0,x(i)*yz(j)]);
                xx=xx(:);yy=yy(:);
                tri = delaunayTriangulation(xx,yy);
                inputs.meshes{c} = GeneralGeometry(2, 'Delaunay', tri);
                inputs.meshes{c}.extrude_mesh_2D_to_3D(linspace(0,x(i)*yz(j),ncellz+1));
%                 inputs.meshes{c}.extrude_mesh_2D_to_3D([0,x(i)*yz(j)]);
            end
            inputs.meshes{c}.set_periodic_flag(1, 'x');
            inputs.meshes{c}.set_periodic_flag(1, 'y');
            inputs.meshes{c}.set_periodic_flag(1, 'z');
        end
    end
end
% 
% ------------------------------------------------------------------------------
if ~isempty(mats)
    nmats = length(mats);
    c = 0;
    for j=1:nyz
        for i=1:nx
            c = c + 1;
            for m=1:nmats
                id  = mats(m).ID;
                reg = mats(m).Region;
                mx = [reg(:,1)*x(i),reg(:,2)*x(i)*yz(j)];
                inputs.meshes{c}.set_cell_matIDs_inside_domain(id,mx);
            end
        end
    end
end
% Build DoFs and FEs
% ------------------------------------------------------------------------------
deg  = data.Neutronics.FEMDegree;
fem  = data.Neutronics.FEMType;
sdm  = data.Neutronics.SpatialMethod;
lump = data.Neutronics.FEMLumping;
if strcmpi(sdm, 'lagrange')
    dtype = 1;
else
    dtype = 2;
end
for i=1:ntot
    inputs.dofs{i} = DoFHandler(inputs.meshes{i}, deg, fem, dtype);
    inputs.fes{i} = FEHandler(inputs.meshes{i}, inputs.dofs{i}, sdm, lump, [1,1,1], [1,1,0,0]);
%     inputs.ScatteringMatrix{i} = build_0th_scattering_matrices(data,inputs.meshes{i},inputs.dofs{i},inputs.fes{i});
end
% Get Angular Quadrature
% ------------------------------------------------------------------------------
mdir = data.Neutronics.Transport.SnLevels; m_num = length(mdir);
data.Neutronics.Transport.NumSnLevels = m_num;
inputs.quadrature = cell(m_num, 1);
for i=1:m_num
    m_data = data;
    m_data.Neutronics.Transport.SnLevels = mdir(i);
    m_data.Neutronics.Transport = get_angular_quadrature(m_data.Neutronics.Transport, data.problem.Dimension);
    m_data.Neutronics.TotalFluxMoments = m_data.Neutronics.Transport.TotalFluxMoments;
    inputs = combine_angular_quadratures(inputs, m_data, i);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function inputs = combine_angular_quadratures( inputs, m_data, m )
inputs.quadrature{m}.AngQuadNorm = m_data.Neutronics.Transport.AngQuadNorm;
inputs.quadrature{m}.NumberAngularDirections = m_data.Neutronics.Transport.NumberAngularDirections;
inputs.quadrature{m}.AngularDirections = m_data.Neutronics.Transport.AngularDirections;
inputs.quadrature{m}.AngularWeights = m_data.Neutronics.Transport.AngularWeights;
inputs.quadrature{m}.Opposite_Angular_Indices = m_data.Neutronics.Transport.Opposite_Angular_Indices;
inputs.quadrature{m}.discrete_to_moment = m_data.Neutronics.Transport.discrete_to_moment;
inputs.quadrature{m}.moment_to_discrete = m_data.Neutronics.Transport.moment_to_discrete;
inputs.quadrature{m}.TotalFluxMoments = m_data.Neutronics.Transport.TotalFluxMoments;
inputs.quadrature{m}.SphericalHarmonics = m_data.Neutronics.Transport.SphericalHarmonics;
inputs.quadrature{m}.MomentOrders = m_data.Neutronics.Transport.MomentOrders;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function check_geometry_inputs(data, x, yz)
dim = data.problem.Dimension;
gt = data.geometry.type;
if dim == 1
    
elseif dim == 2
    if ~strcmp(gt, 'cart') && ~strcmp(gt, 'tri')
        error('Unknown 2D geometry type.');
    end
elseif dim == 3
    if ~strcmp(gt, 'cart') && ~strcmp(gt, 'tri') && ~strcmp(gt, 'tet')
        error('Unknown 3D geometry type.');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%