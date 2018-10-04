%--------------------------------------------------------------------------
% - Create white matter masks (don't re-create if already exists)
% - Create output referential image
%--------------------------------------------------------------------------

% TODO: do not ls on *, instead list folders inside parameters.m file
% TODO: remove SCT dependency for interpolating to dest image

% load params
run scatlas_parameters.m

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

list_levels = sct_tools_ls('*', [], [], 1); % get names of level folders

% loop over levels
for ii=1:length(list_levels)
    
    cd(char(list_levels(ii)));
    list_samples = list_sample_folders();
    
    % loop over samples
    for jj=1:length(list_samples)
        
        % zip the input map
        cd(char(list_samples(jj)));
        if ~exist([char(list_samples(jj)) '_mask.nii.gz']);
            
            name=[char(list_samples(jj)) '_MVF.nii.gz'];
            img_for_mask=load_nii_data(name);
            img_for_mask=imresize(img_for_mask,4);

            % draw white matter mask on img
            disp(['<strong>','*** Please identify the SPINAL CORD by drawing a polygon around it for ',char(list_levels(ii)),' -> ',char(list_samples(jj)),' *** </strong>']);
            [~,maskWM]=as_tools_getroi(img_for_mask);
            % dra gray matter mask on image
            disp(['<strong>','*** Please identify the GRAY MATTER by drawing a polygon around it for ',char(list_levels(ii)),' -> ',char(list_samples(jj)),' *** </strong>']);
            [~,maskGM]=as_tools_getroi(img_for_mask);

            % generate and save mask
            final=zeros(size(maskWM,1),size(maskWM,2));
            final(maskWM==true)=1;
            final(maskGM==true)=0;
            WM_mask=imresize(final,0.25);
            WM_mask=im2bw(WM_mask);
            %imshow(WM_mask);

            imwrite(WM_mask,'mask.png');
            name_mask=[char(list_samples(jj)) '_mask.nii.gz'];
            save_nii_v2(WM_mask,name_mask,name,16);
            %gzip(name);
        end 
        
        % create empty reference space
        ref=zeros(151,151);
        resfinal = 0.05;
        save_nii(make_nii(ref,[resfinal resfinal 1]),['ref_template_50um_' char(list_samples(jj)) '.nii.gz']);
        
        % put map into empty reference space
        sct_unix(['sct_register_multimodal -i ' char(list_samples(jj)) '_mask.nii.gz -o ' char(list_samples(jj)) '_mask_reg.nii.gz -d ref_template_50um_' char(list_samples(jj)) '.nii.gz -identity 1']);
        cd ..
    end  
    cd .. 
end

disp "DONE!"











