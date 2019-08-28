%--------------------------------------------------------------------------
% Create 3D file of spinal levels
%--------------------------------------------------------------------------

clear

% load params
run scatlas_parameters.m

fprintf('=========================\nCREATE SPINAL LEVELS\n=========================')

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

% Load spinal cord mask
mask_cord = load_nii_data(fullfile(PATH_DATA, FOLDER_ATLAS, 'AtlasRat_mask_cord.nii.gz'));

% Initialize 3D empty object
spinal_levels = zeros(size(mask_cord));
nz = size(spinal_levels, 3);
% loop over slice and assign incremental value for each spinal level
for iz=1:nz

    % Replace all non-null pixel with value iz
    ind_nonzero = find(mask_cord(:, :, iz));
    spinal_levels_slice = zeros(size(mask_cord, 1), size(mask_cord, 2));
    spinal_levels_slice(ind_nonzero) = iz;
    % starts with the last slice (which corresponds to the most rostral).
    spinal_levels(:, :, nz-iz+1) = spinal_levels_slice;

end

% save final volume in nii
fprintf('\nSave file...');
save_nii_v2(spinal_levels, fullfile(PATH_DATA, FOLDER_ATLAS, 'AtlasRat_spinal_levels.nii.gz'), fullfile(PATH_DATA, FOLDER_ATLAS, 'AtlasRat_mask_cord.nii.gz'), 4);

fprintf('\nDone!\n');

