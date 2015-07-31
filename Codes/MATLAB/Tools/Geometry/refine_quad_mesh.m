%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          Refine Quad Mesh
%
%   Author:         Michael W. Hackemack
%   Institution:    Texas A&M University
%   Year:           2015
%
%   Description:    MATLAB function to refine a 2D quadrilateral mesh.
%                   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Notes:   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function refine_quad_mesh( mesh )
% Quick Error Checking
% ------------------------------------------------------------------------------
if ~isa(mesh, 'AMRGeometry'), error('Requires AMRGeometry object.'); end
% ------------------------------------------------------------------------------
% Sort cells from lowest refinement level - this yields more consistency in
% refinement routines (I think...).
% ------------------------------------------------------------------------------
% No limit on AMR Irregularity
if isinf(mesh.MaxIrregularity)
    new_cells = (1:mesh.TotalCells)';
    new_cells = new_cells(mesh.CellRefinementFlag);
    current_lvls = mesh.CellRefinementLevel(new_cells);
    [~, ind] = sort(current_lvls);
    new_cells = new_cells(ind); num_new_cells = length(new_cells);
% Impose AMR Irregularity limits
else
    ref_cells = (1:mesh.TotalCells)'; ref_cells(~mesh.CellRefinementFlag) = [];
    next_lvls = mesh.CellRefinementLevel;
    next_lvls(ref_cells) = next_lvls(ref_cells) + 1;
    [next_lvls, new_cells] = mesh.check_cell_refinement_differences(next_lvls, ref_cells);
    [~, ind] = sort(next_lvls(new_cells));
    new_cells = new_cells(ind); num_new_cells = length(new_cells);
end
disp(['   -> Number of Refinement Flags: ',num2str(num_new_cells)])
% ------------------------------------------------------------------------------
% Loop through cells and refine cell-by-cell
% ------------------------------------------------------------------------------
c_count = mesh.TotalCells; f_count = mesh.TotalFaces; v_count = mesh.TotalVertices;
mesh.allocate_more_memory(0,num_new_cells*3,0);
for c=1:length(new_cells)
    tcell = new_cells(c);
    % Determine new cell/face/vert counts
    ncells = 3; nfaces = 4; nverts = 1;
    for ff=1:length(mesh.RefCellHigherLvls{tcell})
        if ~mesh.RefCellHigherLvls{tcell}(ff)
            nfaces = nfaces + 1;
            nverts = nverts + 1;
        end
    end
    % Allocate more array memory for mesh
    mesh.allocate_more_memory(nverts,0,nfaces);
    % Refine individual cell
    cnums = c_count + (1:ncells);
    fnums = f_count + (1:nfaces);
    vnums = v_count + (1:nverts);
    refine_individual_cell(mesh, tcell, cnums, fnums, vnums);
    % Update Counts
    c_count = c_count + ncells;
    f_count = f_count + nfaces;
    v_count = v_count + nverts;
    mesh.TotalCells = mesh.TotalCells + ncells;
    mesh.TotalFaces = mesh.TotalFaces + nfaces;
    mesh.TotalVertices = mesh.TotalVertices + nverts;
end
% ------------------------------------------------------------------------------
% Update Final geometry information
% ------------------------------------------------------------------------------
mesh.update_geometry_info_after_modifications();
if mesh.IsExtruded && ~strcmp(mesh.MeshType, 'Quadrilateral')
    mesh.IsExtruded = false;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Refine Individual Cell
%   Variable Listing:
%   1) mesh  - Reference to AMRGeometry object
%   2) c     - Cell to be refined
%   3) cnums - Cell IDs for new cells to be created
%   4) fnums - Face IDs for new faces to be created
%   5) vnums - Vertex IDs for new vertices to be created
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function refine_individual_cell( mesh, c, cnums, fnums, vnums )
% Loop through macro faces and retrieve information
% ------------------------------------------------------------------------------
ncells = length(cnums); nfaces = length(fnums); nverts = length(vnums);
current_lvl = mesh.CellRefinementLevel(c);
next_lvl = current_lvl + 1;
cell_macro_faces = mesh.RefCellFaces{c};
cell_macro_face_verts = mesh.RefCellFaceVerts{c};
cell_macro_face_nums = mesh.RefCellFaceNumbering{c};
cell_macro_cells = mesh.RefCellFaceCells{c};
cell_corner_verts = mesh.RefCellCornerVerts{c};
cell_mid_face_verts = mesh.RefCellMidFaceVerts{c};
cell_center = mean(mesh.Vertices(cell_corner_verts,:));
has_higher_lvl_cells = mesh.RefCellHigherLvls{c};
% Some vertex arrays
new_verts = zeros(nverts, mesh.Dimension);
needed_vert_inds = zeros(9,1);
needed_vert_inds(1:4) = cell_corner_verts;
needed_verts = zeros(9,mesh.Dimension);
needed_verts(1:4,:) = mesh.Vertices(cell_corner_verts,:);
% Some face arrays
cell_boundary_faces = false(length(mesh.RefCellFaces{c}),1);
new_face_vert_inds = zeros(nfaces, 3);
new_face_ids = zeros(nfaces, 1);
new_old_face_vert_inds = [];
new_old_face_combo = zeros(4,2);
% Loop through macro faces
nv_count = 1;
for ff=1:length(cell_macro_faces)
    of = mesh.RefCellFaces{c}{ff};
    fvind = [ff,mod(ff,length(cell_macro_faces))+1];
    fcorn_verts = cell_corner_verts(fvind);
    tcs = mesh.RefCellFaceCells{c}{ff};
    new_face_ids(ff) = 0;
    new_face_vert_inds(ff,1) = ff;
    new_face_vert_inds(ff,3) = vnums(end);
    % Boundary Face
    if isempty(tcs)
        cell_boundary_faces(ff) = true;
        new_verts(nv_count,:) = mean(mesh.Vertices(fcorn_verts,:));
        needed_verts(4+ff,:) = mean(mesh.Vertices(fcorn_verts,:));
        needed_vert_inds(4+ff) = vnums(nv_count);
        new_face_vert_inds(ff,2) = vnums(nv_count);
        new_face_vert_inds(4+nv_count,:) = [ff,vnums(nv_count),fcorn_verts(2)];
        new_face_ids(4+nv_count) = mesh.FaceID(of);
        new_old_face_vert_inds = [new_old_face_vert_inds;ff,fcorn_verts(1),vnums(nv_count)];
        new_old_face_combo(ff,:) = [cell_macro_faces{ff},fnums(4+nv_count)];
        nv_count = nv_count + 1;
    % Face with refinement at same or lower level on other side
    elseif ~has_higher_lvl_cells(ff)
        new_verts(nv_count,:) = mean(mesh.Vertices(fcorn_verts,:));
        needed_verts(4+ff,:) = mean(mesh.Vertices(fcorn_verts,:));
        needed_vert_inds(4+ff) = vnums(nv_count);
        new_face_vert_inds(ff,2) = vnums(nv_count);
        new_face_vert_inds(4+nv_count,:) = [ff,vnums(nv_count),fcorn_verts(2)];
        new_face_ids(4+nv_count) = mesh.FaceID(of);
        new_old_face_vert_inds = [new_old_face_vert_inds;ff,fcorn_verts(1),vnums(nv_count)];
        new_old_face_combo(ff,:) = [cell_macro_faces{ff},fnums(4+nv_count)];
        nv_count = nv_count + 1;
    % Face with higher refinement on other side
    elseif has_higher_lvl_cells(ff)
        needed_verts(4+ff,:) = mesh.Vertices(cell_mid_face_verts(ff),:);
        needed_vert_inds(4+ff) = cell_mid_face_verts(ff);
        new_face_vert_inds(ff,2) = cell_mid_face_verts(ff);
    end
end
new_verts(end,:) = cell_center;
needed_verts(end,:) = cell_center;
needed_vert_inds(end) = vnums(end);
needed_vert_inds = needed_vert_inds';
new_cell_corner_vert_inds = get_new_cell_corner_vertex_indices();
new_cell_macro_faces = get_new_cell_ext_faces();
new_cell_int_faces = get_new_cell_int_faces();
rep_cell_nums = get_replacement_cell_nums();
rep_face_nums = get_replacement_face_nums();
% ------------------------------------------------------------------------------
% Make Modifications for Particular Cell/Faces
% ------------------------------------------------------------------------------
tcnums = [c,cnums];
mesh.MatID(tcnums) = mesh.MatID(c);
% Clear Ref Cell Arrays
for cc=1:length(tcnums)
    mesh.RefCellFaces{tcnums(cc)} = cell(4,1);
    mesh.RefCellFaceCells{tcnums(cc)} = cell(4,1);
    mesh.RefCellFaceVerts{tcnums(cc)} = cell(4,1);
    mesh.RefCellMidFaceVerts{tcnums(cc)} = zeros(1,4);
    mesh.RefCellHigherLvls{tcnums(cc)} = false(1,4);
    mesh.RefCellFaceNumbering{tcnums(cc)} = cell(4,1);
end
mesh.Vertices(vnums,:) = new_verts;
mesh.FaceID(fnums) = new_face_ids;
% Modify newly created faces
for ff=1:nfaces
    f = fnums(ff);
    mesh.FaceVerts{f} = new_face_vert_inds(ff,2:end);
    mesh.FaceCenter(f,:) = mean(mesh.Vertices(mesh.FaceVerts{f},:));
    if ff <= 4
        iif = [ff,mod(ff,4)+1];
        mesh.FaceCells(f,:) = tcnums(iif);
    else
        iif = new_face_vert_inds(ff,1);
        iiff = mod(iif,4)+1;
        mesh.FaceCells(f,:) = zeros(1,2);
        mesh.FaceCells(f,1) = tcnums(iiff);
        if ~cell_boundary_faces(iif)
            mesh.FaceCells(f,2) = cell_macro_cells{iif};
        end
        oface = cell_macro_faces{iif};
        mesh.FaceCells(oface,1) = tcnums(iif);
        if mesh.FaceID(oface) == 0
            mesh.FaceCells(oface,2) = cell_macro_cells{iif};
        end
    end
    dvx = diff(mesh.Vertices(mesh.FaceVerts{f},:));
    mesh.FaceArea(f) = norm(dvx);
end
% Modify old faces that require a change
for ff=1:size(new_old_face_vert_inds,1)
    nofvi = new_old_face_vert_inds(ff,:);
    f = cell_macro_faces{nofvi(1)};
    mesh.FaceVerts{f} = nofvi(2:end);
end
% Loop through cells
for cc=1:length(tcnums)
    ncif = new_cell_int_faces{cc};
    mesh.RefCellCornerVerts{tcnums(cc)} = needed_vert_inds(new_cell_corner_vert_inds(cc,:));
    % Modify Cell/Face interconnections
    % ---------------------------------
    % New interior faces
    mesh.RefCellFaces{tcnums(cc)}{ncif(1,1)} = fnums(ncif(1,2));
    mesh.RefCellFaces{tcnums(cc)}{ncif(2,1)} = fnums(ncif(2,2));
    mesh.RefCellFaceCells{tcnums(cc)}{ncif(1,1)} = tcnums(ncif(1,3));
    mesh.RefCellFaceCells{tcnums(cc)}{ncif(2,1)} = tcnums(ncif(2,3));
    mesh.RefCellMidFaceVerts{tcnums(cc)}(ncif(1,1)) = 0;
    mesh.RefCellMidFaceVerts{tcnums(cc)}(ncif(2,1)) = 0;
    mesh.RefCellFaceVerts{tcnums(cc)}{ncif(1,1)} = needed_vert_inds([4+ncif(1,2),end]);
    mesh.RefCellFaceVerts{tcnums(cc)}{ncif(2,1)} = needed_vert_inds([end,4+ncif(2,2)]);
    mesh.RefCellFaceNumbering{tcnums(cc)}{ncif(1,1)} = ncif(1,4);
    mesh.RefCellFaceNumbering{tcnums(cc)}{ncif(2,1)} = ncif(2,4);
    % Outer faces
    f1 = new_cell_macro_faces(cc,1); f2 = new_cell_macro_faces(cc,2);
    % First Exterior Face
    if ~has_higher_lvl_cells(f1)
        mesh.RefCellFaces{tcnums(cc)}{1} = new_old_face_combo(f1,1);
        mesh.RefCellFaceCells{tcnums(cc)}{1} = cell_macro_cells{f1};
        mesh.RefCellFaceVerts{tcnums(cc)}{1} = needed_vert_inds([f1,4+f1]);
        mesh.RefCellFaceNumbering{tcnums(cc)}{1} = cell_macro_face_nums{f1};
    else
        tcv = cell_macro_face_verts{f1};
        tcf = cell_macro_faces{f1};
        tcc = cell_macro_cells{f1};
        mcfv = cell_mid_face_verts(f1);
        tcfn = cell_macro_face_nums{f1};
        for i=1:length(tcv)
            if mcfv == tcv(i)
                mesh.RefCellFaceVerts{tcnums(cc)}{1} = tcv(1:i);
                mesh.RefCellFaces{tcnums(cc)}{1} = tcf(1:i-1);
                mesh.RefCellFaceCells{tcnums(cc)}{1} = tcc(1:i-1);
                mesh.RefCellFaceNumbering{tcnums(cc)}{1} = tcfn(1:i-1);
                if length(mesh.RefCellFaceCells{tcnums(cc)}{1}) == 1
                    mesh.RefCellMidFaceVerts{tcnums(cc)}(1) = 0; 
                    mesh.RefCellHigherLvls{tcnums(cc)}(1) = false;
                else
                    mesh.RefCellHigherLvls{tcnums(cc)}(1) = true;
                    rcfv = mesh.RefCellFaceVerts{tcnums(cc)}{1};
                    rccv = mesh.RefCellCornerVerts{tcnums(cc)};
                    mrccv = mean(mesh.Vertices(rccv(1:2),:));
                    for ii=1:length(rcfv)
                        if norm(mrccv-mesh.Vertices(rcfv(ii),:)) < 1e-13
                            mesh.RefCellMidFaceVerts{tcnums(cc)}(1) = rcfv(ii);
                            break
                        end
                    end
                end
                break
            end
        end
    end
    % Second Exterior Face
    if ~has_higher_lvl_cells(f2)
        mesh.RefCellFaces{tcnums(cc)}{4} = new_old_face_combo(f2,2);
        mesh.RefCellFaceCells{tcnums(cc)}{4} = cell_macro_cells{f2};
        mesh.RefCellFaceVerts{tcnums(cc)}{4} = [needed_vert_inds(4+f2),needed_vert_inds(cc)];
%         mesh.RefCellFaceVerts{tcnums(cc)}{4} = [needed_vert_inds(4+mod(cc,4)),needed_vert_inds(cc)];
        mesh.RefCellFaceNumbering{tcnums(cc)}{4} = cell_macro_face_nums{f2};
    else
        tcv = cell_macro_face_verts{f2};
        tcf = cell_macro_faces{f2};
        tcc = cell_macro_cells{f2};
        mcfv = cell_mid_face_verts(f2);
        tcfn = cell_macro_face_nums{f2};
        for i=1:length(tcv)
            if mcfv == tcv(i)
                mesh.RefCellFaceVerts{tcnums(cc)}{4} = tcv(i:end);
                mesh.RefCellFaces{tcnums(cc)}{4} = tcf(i:end);
                mesh.RefCellFaceCells{tcnums(cc)}{4} = tcc(i:end);
                mesh.RefCellFaceNumbering{tcnums(cc)}{4} = tcfn(i:end);
                if length(mesh.RefCellFaceCells{tcnums(cc)}{4}) == 1
                    mesh.RefCellMidFaceVerts{tcnums(cc)}(4) = 0; 
                    mesh.RefCellHigherLvls{tcnums(cc)}(4) = false;
                else
                    mesh.RefCellHigherLvls{tcnums(cc)}(4) = true;
                    rcfv = mesh.RefCellFaceVerts{tcnums(cc)}{4};
                    rccv = mesh.RefCellCornerVerts{tcnums(cc)};
                    mrccv = mean(mesh.Vertices(rccv([1,4]),:));
                    for ii=1:length(rcfv)
                        if norm(mrccv-mesh.Vertices(rcfv(ii),:)) < 1e-13
                            mesh.RefCellMidFaceVerts{tcnums(cc)}(4) = rcfv(ii);
                            break
                        end
                    end
                end
                break
            end
        end
    end
    % Accumulate Cell Faces
    cfaces = []; cverts = [];
    for i=1:4
        cfaces = [cfaces,mesh.RefCellFaces{tcnums(cc)}{i}];
        cverts = [cverts,mesh.RefCellFaceVerts{tcnums(cc)}{i}];
    end
    mesh.CellFaces{tcnums(cc)} = unique(cfaces, 'stable');
    mesh.CellVerts{tcnums(cc)} = unique(cverts, 'stable');
    c_center = mean(mesh.Vertices(mesh.CellVerts{tcnums(cc)},:));
    mesh.CellCenter(tcnums(cc),:) = c_center;
end
% ------------------------------------------------------------------------------
% Make Modifications for Cell/Faces Neighbors
% ------------------------------------------------------------------------------
t_rep_cell_nums = fliplr(rep_cell_nums);
for ff=1:4
    if cell_boundary_faces(ff), continue; end
    mc_faces = cell_macro_faces{ff};
    mc_cells = cell_macro_cells{ff};
    mcf_nums = cell_macro_face_nums{ff};
    mc_verts = cell_macro_face_verts{ff};
    % Face with refinement at same or lower level on other side
    if ~has_higher_lvl_cells(ff)
        ocverts = mesh.RefCellFaceVerts{mc_cells}{mcf_nums};
        ocfaces = mesh.RefCellFaces{mc_cells}{mcf_nums};
        occells = mesh.RefCellFaceCells{mc_cells}{mcf_nums};
        oclvl   = mesh.CellRefinementLevel(mc_cells);
        ocnum   = mesh.RefCellFaceNumbering{mc_cells}{mcf_nums};
        mesh.RefCellHigherLvls{mc_cells}(mcf_nums) = true;
        if oclvl == current_lvl
            mesh.RefCellMidFaceVerts{mc_cells}(mcf_nums) = needed_vert_inds(4+ff);
        end
        tc = []; tf = []; tv = ocverts(1); tnum = [];
        for i=1:length(occells)
            if occells(i) == c
                tv = [tv,needed_vert_inds(4+ff),ocverts(i+1:end)];
                tf = [tf,new_old_face_combo(ff,[2,1]),ocfaces(i+1:end)];
                temp_cells = tcnums(rep_cell_nums(ff,:));
                tc = [tc,temp_cells,occells(i+1:end)];
                tnum = [tnum,rep_face_nums(ff,:),ocnum(i+1:end)];
                break
            else
                tf = [tf,ocfaces(i)];
                tv = [tv,ocverts(i+1)];
                tc = [tc,occells(i)];
                tnum = [tnum,ocnum(i)];
            end
        end
        mesh.RefCellFaceVerts{mc_cells}{mcf_nums} = tv;
        mesh.RefCellFaces{mc_cells}{mcf_nums} = tf;
        mesh.RefCellFaceCells{mc_cells}{mcf_nums} = tc;
        mesh.RefCellFaceNumbering{mc_cells}{mcf_nums} = tnum;
        cfaces = []; cverts = [];
        for i=1:4
            cfaces = [cfaces,mesh.RefCellFaces{mc_cells}{i}];
            cverts = [cverts,mesh.RefCellFaceVerts{mc_cells}{i}];
        end
        mesh.CellFaces{mc_cells} = unique(cfaces, 'stable');
        mesh.CellVerts{mc_cells} = unique(cverts, 'stable');
    % Face with higher refinement on other side
    elseif has_higher_lvl_cells(ff)
        % Find mid-face vert index
%         trcn = t_rep_cell_nums(ff,:);
        mcfv = cell_mid_face_verts(ff);
        for i=1:length(mc_verts)
            if mc_verts(i) == mcfv
                mcfv_ind = i;
                break;
            end
        end
        % Loop through cells along face
        for i=1:length(mc_cells)
            tcell = mc_cells(i);
            tface = mc_faces(i);
            tnum = mcf_nums(i);
            if i+1 <= mcfv_ind
                t_ind = 2;
                trcfn = rep_cell_nums(ff,2);
            else
                t_ind = 1;
                trcfn = rep_cell_nums(ff,1);
            end
            mesh.RefCellFaceCells{tcell}{tnum} = tcnums(trcfn);
            mesh.RefCellFaceNumbering{tcell}{tnum} = rep_face_nums(ff,t_ind);
            if mesh.FaceCells(tface,1) == c
                mesh.FaceCells(tface,1) = tcnums(trcfn);
            elseif mesh.FaceCells(tface,2) == c
                mesh.FaceCells(tface,2) = tcnums(trcfn);
            end
        end
    end
end
% ------------------------------------------------------------------------------
% Update Refinement Tree - this is actually mostly general for all mesh types
% ------------------------------------------------------------------------------
mesh.PreviousCell(tcnums) = c;
mesh.CellRefinementLevel(tcnums) = mesh.CellRefinementLevel(c) + 1;
mesh.CellRefinementTop(tcnums) = mesh.CellRefinementTop(c);
ctop = mesh.CellRefinementTop(c);
thier = mesh.CellRefinementTreeHierarchy{c}; nthier = length(thier); chier = cell(nthier+1, 1);
ttree = mesh.CellRefinementTree; tncells{1} = c; tt = ttree; chier{1} = ttree;
for i=1:ncells, tncells{i+1} = cnums(i); end
for i=1:nthier-1
    ii = i + 1;
    chier{ii,1} = tt{thier(i)};
    tt = tt{thier(i)};
end
chier{end,1} = tncells; tt = tncells;
for i=nthier:-1:1
    ii = thier(i);
    tnew = chier{i};
    tnew{ii} = tt;
    tt = tnew;
end
mesh.CellRefinementTree = tt;
mesh.CellRefinementTreeHierarchy{c} = [thier,1];
for i=1:ncells, mesh.CellRefinementTreeHierarchy{cnums(i)} = [thier,i+1]; end
mesh.CellRefinementTreeHierarchyLevel(ctop) = length(mesh.CellRefinementTreeHierarchy{c}) - 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = get_new_cell_corner_vertex_indices()
out = [1,5,9,8;2,6,9,5;3,7,9,6;4,8,9,7];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = get_new_cell_ext_faces()
out = [1,4;2,1;3,2;4,3];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = get_new_cell_int_faces()
out{1} = [2,1,2,3;3,4,4,2];
out{2} = [2,2,3,3;3,1,1,2];
out{3} = [2,3,4,3;3,2,2,2];
out{4} = [2,4,1,3;3,3,3,2];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = get_replacement_cell_nums()
out = [2,1;3,2;4,3;1,4];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = get_replacement_face_nums()
out = [4,1;4,1;4,1;4,1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%