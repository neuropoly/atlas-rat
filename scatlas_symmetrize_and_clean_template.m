%--------------------------------------------------------------------------
% This script takes the Volume4D.nii.gz and Volume4D_std.nii.gz files of 
% each level as inputs and (i) uses the
% left-right flips to symmetrize the output (the average is computed 
% between the template and its flipped version); (ii) cleans the template
% by only keeping the spinal cord (i.e. white + gray matter) and removing
% the outer content.
% 
% Outputs:
%   Volume4D_sym_cleaned.nii.gz       symmetric and cleaned 4d mean
%   Volume4D_sym_std_cleaned.nii.gz   symmetric and cleaned 4d STD
%--------------------------------------------------------------------------


clear

% Params
% none

% load params
run scatlas_parameters.m

fprintf('====================\nSYMMETRIZE AND CLEAN\n====================\n')

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

% list=sct_tools_ls('*', [], [], 1);% get names of level folders

% loop over levels
for level=1:length(LIST_LEVELS)
    
    cd(LIST_LEVELS{level});

    % Part 1: symmetrize by using the flips
    % Load template and the std
    img=load_nii_data('Volume4D.nii.gz');
    img_std=load_nii_data('Volume4D_std.nii.gz');

    % for each level
    for i=1:size(img,4)
    
        map=img(:,:,1,i);
        map_flipped=flip(map);
        img(:,:,1,i)=(map+map_flipped)./2;
 
        map_std=img_std(:,:,1,i);
        map_flipped_std=flip(map_std);
        img_std(:,:,1,i)=(map_std+map_flipped_std)./2;

    end

    % Save symmetrized template and std
    save_nii_v2(img,'Volume4D_sym.nii.gz','Volume4D.nii.gz',16);
    save_nii_v2(img_std,'Volume4D_sym_std.nii.gz','Volume4D_std.nii.gz',16);

    % Part 2: clean template
    % load volume of concatenated metrics template
    Volume4D=load_nii_data('Volume4D_sym.nii.gz');
    Volume4D_std=load_nii_data('Volume4D_sym_std.nii.gz');

    % load mask template output to filter maps (white + gray matter)
    mask=load_nii_data('templategen/template/T_template0.nii.gz');
    mask=im2bw(mask);
    mask=imfill(mask,'holes');
    
    % clean maps and stds
    for ooo=1:size(Volume4D,4)
        Volume4D(:,:,1,ooo)=Volume4D(:,:,1,ooo).*mask;
        Volume4D_std(:,:,1,ooo)=Volume4D_std(:,:,1,ooo).*mask;
    end
    
    % Save cleaned template and std
    save_nii_v2(Volume4D,'Volume4D_sym_cleaned.nii.gz','Volume4D_sym.nii.gz',16);
    save_nii_v2(Volume4D_std,'Volume4D_sym_std_cleaned.nii.gz','Volume4D_sym_std.nii.gz',16);

    cd ..
  
end

disp "DONE!"





    