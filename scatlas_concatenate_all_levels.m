%--------------------------------------------------------------------------
% Concatenates the volumes (x, y, 1, metric) of each level to 
% generate a 4D volume that includes all levels (x, y, z, metric). Also generates 3D
% volumes of each metric across all levels.
% Output folder
%--------------------------------------------------------------------------

clear

% load params
run scatlas_parameters.m

fprintf('=========================\nCONCATENATE ACROSS LEVELS\n=========================')

% remove output folder (if exists) and create new one
if isdir(fullfile(PATH_DATA, FOLDER_ATLAS))
    rmdir(fullfile(PATH_DATA, FOLDER_ATLAS), 's');
end
mkdir(fullfile(PATH_DATA, FOLDER_ATLAS));

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS, LIST_LEVELS{1}));

Volume4D=load_nii_data('Volume4D_sym_cleaned.nii.gz');
mask_cord = zeros(size(Volume4D,1), size(Volume4D,2), length(LIST_LEVELS));
mask_wm = zeros(size(Volume4D,1), size(Volume4D,2), length(LIST_LEVELS));
Volume4D_full=zeros(size(Volume4D,1), size(Volume4D,2), length(LIST_LEVELS), size(Volume4D,4));
Volume4D_full_std=zeros(size(Volume4D,1),size(Volume4D,2),length(LIST_LEVELS),size(Volume4D,4));

cd ..

% loop over levels
for level=1:length(LIST_LEVELS)

    fprintf('\nProcessing level %s (%i/%i)...', LIST_LEVELS{level}, level, length(LIST_LEVELS));

    cd(LIST_LEVELS{level});
    
    % load volume of concatenated metrics template
    Volume4D=load_nii_data('Volume4D_sym_cleaned.nii.gz');
    Volume4D_std=load_nii_data('Volume4D_sym_std_cleaned.nii.gz');
    mask_cord_2d = load_nii_data('mask_cord_sym.nii.gz');
    mask_wm_2d = load_nii_data('mask_wm_sym.nii.gz');
    
    % control if volume of each level has the right shape
    if size(Volume4D,1)~=size(Volume4D_full,1) || size(Volume4D,2)~=size(Volume4D_full,2) || size(Volume4D,3)~=1 || size(Volume4D,4)~=size(Volume4D_full,4)
        disp(['Volume template of level ' char(LIST_LEVELS{level}) ' does not have the expected shape.']);
        break;
    end
    
    % concatenate volume of level i to full volume
    Volume4D_full(:,:,level,:)=Volume4D(:,:,1,:);
    Volume4D_full_std(:,:,level,:)=Volume4D_std(:,:,1,:);
    mask_cord(:, :, level) = mask_cord_2d;
    mask_wm(:, :, level) = mask_wm_2d;

    cd ..
    
end

%% save final volume in nii
fprintf('\nSave files...');
% Make references for headers
% ref_4d = zeros(size(Volume4D_full,1), size(Volume4D_full,2), size(Volume4D_full,3), size(Volume4D_full,4));
% save_nii(make_nii(ref_4d,[0.05 0.05 1]),'tmp_ref_4d.nii.gz');
ref_3d = zeros(size(Volume4D_full,1), size(Volume4D_full,2), size(Volume4D_full,3));
save_nii(make_nii(ref_3d,[0.05 0.05 1]), 'tmp_ref_3d.nii.gz');

% save_nii_v2(Volume4D_full, fullfile(PATH_DATA, FOLDER_ATLAS, 'AtlasRat_4D_mean.nii.gz'),'Volume4D_full_ref.nii.gz',16);
% save_nii_v2(Volume4D_full_std, fullfile(PATH_DATA, FOLDER_ATLAS, 'AtlasRat_4D_std.nii.gz'), 'Volume4D_full_ref.nii.gz',16);
save_nii_v2(mask_cord, fullfile(PATH_DATA, FOLDER_ATLAS, 'AtlasRat_mask_cord.nii.gz'), 'tmp_ref_3d.nii.gz',2);
save_nii_v2(mask_wm, fullfile(PATH_DATA, FOLDER_ATLAS, 'AtlasRat_mask_WM.nii.gz'), 'tmp_ref_3d.nii.gz',2);

% save individual volumes for each metric, across all levels
for ii=1:size(Volume4D_full,4)
    tmp = Volume4D_full(:,:,:,ii);
    Volume_metric = squeeze(tmp);  % make it 3D
    name_out = fullfile(PATH_DATA, FOLDER_ATLAS, ['AtlasRat_' LIST_METRICS{ii} '.nii.gz']);
    save_nii_v2(Volume_metric, name_out, 'tmp_ref_3d.nii.gz',16);
end

% Rename corrected files (for clarity)
movefile(fullfile(PATH_DATA, FOLDER_ATLAS, 'AtlasRat_GR_corrected.nii.gz'), fullfile(PATH_DATA, FOLDER_ATLAS, 'AtlasRat_GR.nii.gz'));
movefile(fullfile(PATH_DATA, FOLDER_ATLAS, 'AtlasRat_MVF_corrected.nii.gz'), fullfile(PATH_DATA, FOLDER_ATLAS, 'AtlasRat_MVF.nii.gz'));

% cleaning
delete('tmp_ref_3d.nii.gz'); 
% delete('Volume4D_full_ref.nii.gz');
delete(fullfile(PATH_DATA, FOLDER_ATLAS, 'AtlasRat_AVF_corrected.nii.gz'));

fprintf('\nDone!\n');
