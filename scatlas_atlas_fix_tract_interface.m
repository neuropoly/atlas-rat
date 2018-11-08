%--------------------------------------------------------------------------
% Fix inacuracies at tract interfaces, yielding the following error:
% https://github.com/neuropoly/atlas_rat/issues/1
% 
% This function applies a median filter on the high resolution tract
% images.
% 
% Dependencies: FSL
%--------------------------------------------------------------------------                

clear

% Params
% none

% load params
run scatlas_parameters.m

fprintf('==========================\nFIX TRACT INTERFACES\n==========================\n')

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

% loop over levels
for level=1:length(LIST_LEVELS)

    cd(LIST_LEVELS{level});

    % apply median filter on nifti file
    % parse name
    [~,level_name] = fileparts(pwd);
    filename_atlas = [level_name,'_reg_reg_tracts.nii.gz'];
    filename_atlas_fixed = [level_name,'_reg_reg_tracts_fixed.nii.gz'];
    unix(['fslmaths ' filename_atlas ' -kernel box 0.5x0.5 -fmedian ' filename_atlas_fixed]);
    
    cd .. 
end

disp "DONE!"
