%--------------------------------------------------------------------------
% Concatenates the volumes (x, y, 1, metric) of each level to 
% generate a 4D volume that includes all levels (x, y, z, metric). Also generates 3D
% volumes of each metric across all levels.
%--------------------------------------------------------------------------

clear

% Params
% none

% load params
run scatlas_parameters.m

fprintf('=========================\nCONCATENATE ACROSS LEVELS\n=========================\n')

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS, LIST_LEVELS{1}))

% Read list of levels 'levels.txt'
% fileID = fopen('/Volumes/projects/atlas_rat/levels.txt','r');
% list_levels = textscan(fileID,'%s','Delimiter',',');

% initialize output volume
% cd(list_levels{1,1}{1,1});

Volume4D=load_nii_data('Volume4D_sym_cleaned.nii.gz');
Volume4D_full=zeros(size(Volume4D,1), size(Volume4D,2), length(LIST_LEVELS), size(Volume4D,4));
Volume4D_full_std=zeros(size(Volume4D,1),size(Volume4D,2),length(LIST_LEVELS),size(Volume4D,4));

cd ..

% loop over levels
for level=1:length(LIST_LEVELS)

    cd(LIST_LEVELS{level});
    
    % load volume of concatenated metrics template
    Volume4D=load_nii_data('Volume4D_sym_cleaned.nii.gz');
    Volume4D_std=load_nii_data('Volume4D_sym_std_cleaned.nii.gz');
    
    % control if volume of each level has the right shape
    if size(Volume4D,1)~=size(Volume4D_full,1) || size(Volume4D,2)~=size(Volume4D_full,2) || size(Volume4D,3)~=1 || size(Volume4D,4)~=size(Volume4D_full,4)
        disp(['Volume template of level ' char(LIST_LEVELS{level}) ' does not have the expected shape.']);
        break;
    end
    
    % concatenate volume of level i to full volume
    Volume4D_full(:,:,level,:)=Volume4D(:,:,1,:);
    Volume4D_full_std(:,:,level,:)=Volume4D_std(:,:,1,:);

    cd ..
    
end

% save final volume in nii
ref_4d_full=zeros(size(Volume4D_full,1),size(Volume4D_full,2),size(Volume4D_full,3),size(Volume4D_full,4));
save_nii(make_nii(ref_4d_full,[0.05 0.05 1]),'Volume4D_full_ref.nii.gz');
save_nii_v2(Volume4D_full,'Volume4D_full.nii.gz','Volume4D_full_ref.nii.gz',16);
save_nii_v2(Volume4D_full_std,'Volume4D_full_std.nii.gz','Volume4D_full_ref.nii.gz',16);

% save individual volumes for each metric, across all levels

ref_metric=zeros(size(Volume4D_full,1),size(Volume4D_full,2),size(Volume4D_full,3));
save_nii(make_nii(ref_metric,[0.05 0.05 1]),'Template_metric_ref.nii.gz');

for ii=1:size(Volume4D_full,4)
    
    tmp=Volume4D_full(:,:,:,ii);
    Volume_metric=squeeze(tmp);
    name=['Template_metric_' num2str(ii) '.nii.gz'];
    save_nii_v2(Volume_metric,name,'Template_metric_ref.nii.gz',16);
    
end

% cleaning of the folder
delete('Template_metric_ref.nii.gz'); 
delete('Volume4D_full_ref.nii.gz');

disp "DONE!"



