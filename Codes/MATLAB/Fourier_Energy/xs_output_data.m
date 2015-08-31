%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Title:          Output XS Data
%
%   Author:         Michael W. Hackemack
%   Institution:    Texas A&M University
%   Year:           2015
%   
%   Description:    
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xs_output_data(data, xs_data)
disp('Outputting XS Files.')
full_dir = [data.out_dir,'/MT_'];
for i=1:length(xs_data.mats)
    o_name = [full_dir,num2str(xs_data.mats(i).MT),'.mat'];
    mat = xs_data.mats(i).mat;
    save(o_name,'mat');
end