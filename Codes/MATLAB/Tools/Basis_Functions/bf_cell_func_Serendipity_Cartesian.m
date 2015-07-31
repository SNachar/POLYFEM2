%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          Cartesian Serendipity Main Generation Function
%
%   Author:         Michael W. Hackemack
%   Institution:    Texas A&M University
%   Year:           2014
%
%   Description:    MATLAB function to produce the elementary volume and
%                   surface matrices, along with the appropriate quadrature
%                   set outputs for the Serendipity basis functions on quad and 
%                   hex meshes.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Input Space:    1) Number of geometric vertices
%                   2) Vertices
%                   3) Face Vertices
%                   4) FEM Order
%                   5) Volumetric Matrix Flags
%                   6) Surface Matrix Flags
%                   7) Quadrature boolean
%                   8) Quadrature Order (Optional)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = bf_cell_func_Serendipity_Cartesian( varargin )
% Collect Input/Output Arguments
% ------------------------------
nout = nargout;
nverts = varargin{1};
verts = varargin{2}(1:nverts,:);
faces = varargin{3}; nf = length(faces);
ord = varargin{4};
v_flags = varargin{5};
s_flags = varargin{6};
q_bool = varargin{7};
q_ord = ord+2;
if nargin > 7
    if ~isempty(varargin{8}),q_ord = varargin{8};end
end
% Prepare Vertices and Dimensional Space
% --------------------------------------
[mv,nv] = size(verts); 
if nv > mv, verts = verts'; end
[nv,dim] = size(verts);
% Quick Error Checking
% --------------------

% Compute and exit immediately if 1D
% ------------------------------------------------------------------------------
if dim == 1
    [bf_V,bf_S,QV,QS] = bf_func_1D(varargin{:});
    varargout = {bf_V, bf_S, QV, QS};
    return
end
% ------------------------------------------------------------------------------

