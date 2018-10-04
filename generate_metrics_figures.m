%--------------------------------------------------------------------------
% Name: generate_metrics_figures.m
% Date: 2017/12/12
% Description: This script generates plot figures for a given 
% level, for each metric. Steps: (i) Loads the Volume4D of a given level,
% (ii) loads the white matter mask of the template, (iii) generates plots
% with colormap jet for all metrics and daves figures in level folder.
%
% Launch this script within a level folder (for example: "C2/")
%--------------------------------------------------------------------------

% read Volume 4D
img=load_nii_data('Volume4D.nii.gz');

cd templategen
cd template

% read mask
mask=load_nii_data('T_template0.nii.gz');
mask=im2bw(mask);

cd ../..

% get names of metrics
list_samplenames= sct_tools_ls('Sample1_*reg_reg.nii.gz');
list_samplenames_split= cellfun(@(x) strsplit(x,'_'), list_samplenames,'UniformOutput',false); 
list_names = cellfun(@(x) x{2}, list_samplenames_split,'UniformOutput',false);
list_samplenames_split= cellfun(@(x) strsplit(x,'.'), list_names,'UniformOutput',false); 
list_names = cellfun(@(x) x{1}, list_samplenames_split,'UniformOutput',false);

% loop for each metric
for i=1:length(list_names)

    img2=img(:,:,1,i);
    img2=img2.*mask;
    h=imagesc(img2');
    colormap('jet');
    colorbar('SouthOutside');
    pbaspect([1 1 1]);
    %caxis([0.5 0.7]);

    file_name=[char(list_names{i}) '.png'];
    saveas(h,file_name);

end
















