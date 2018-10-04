list = sct_tools_ls('*',0,0,1)
for ii=1:length(list)
    cd(list{ii})
    %% move everything to backup
% mkdir backup
% sct_unix('mv ./* backup/')
% sct_unix('mv backup/T_template0.nii.gz ./')
% sct_unix('mv backup/*_WM_reg_reg.nii.gz ./')
% sct_unix('mv backup/*_reg_reg_tracts.nii.gz ./')

%% run
    step9_register_atlas_to_template

    cd ..
end