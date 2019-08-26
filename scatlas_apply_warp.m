%--------------------------------------------------------------------------
% Apply the rigid transformation + warping fields to all metrics maps and
% generate spatial statistics (mean, STD). Note that the output volume is 
% 4d in shape, but the 3rd dimension (corresponding to z) is a singleton
% to anticipate future concatenation (done in later scripts).
% 
% Outputs:
%   Volume4D.nii.gz      (x, y, 1, metric). Mean across samples 
%   Volume4D_std.nii.gz  (x, y, 1, metric). STD across samples 

%--------------------------------------------------------------------------

clear

% load params
run scatlas_parameters.m

fprintf('==========\nAPPLY WARP\n==========\n')

%% PART 1: APPLY THE WARPING FIELDS TO THE METRIC MAPS

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

% loop over levels
for i=1:length(LIST_LEVELS)
    
    cd(LIST_LEVELS{i})
    list_samples = sct_tools_ls('Sample*',[],[],1); % get names of sample folders
            
    % Loop across samples
    for ii=1:2:length(list_samples)
        cd(char(list_samples(ii)));

        % loop across metrics and apply warps
        for iii=1:length(LIST_METRICS)
            % resample metric into template space
            sct_unix(['sct_register_multimodal -i '  char(list_samples(ii)) '_' char(LIST_METRICS(iii)) '.nii.gz'...
            ' -o ' char(list_samples(ii)) '_' char(LIST_METRICS(iii)) '_reg.nii.gz  -d ref_template_50um_' char(list_samples(ii)) '.nii.gz -identity 1']);
            % Apply the warping fields to the metric
            sct_unix(['isct_antsApplyTransforms -d 2', ...
                ' -i ', char(list_samples(ii)), '_', char(LIST_METRICS(iii)), ...
                '_reg.nii.gz', ' -o ', char(list_samples(ii)), '_', ...
                char(LIST_METRICS(iii)), '_reg_reg.nii.gz -t', ...
                ' ../templategen/template/T_', char(list_samples(ii)), '_mask_reg_reg', num2str(ii-1), '1Warp.nii.gz', ...
                ' ../templategen/template/T_', char(list_samples(ii)), '_mask_reg_reg', num2str(ii-1), '0GenericAffine.mat', ...
                ' affine_transfo.txt', ...
                ' -r ref_template_50um_' char(list_samples(ii)) '.nii.gz']);

            % copy each final metric map of each sample to the level folder
            copyfile ([char(list_samples(ii)) '_' char(LIST_METRICS(iii)) '_reg_reg.nii.gz'], ['..']);         
        end
        
        cd ..
    end
    cd .. 
end 


%% PART 2: COMPUTE THE MEAN AND STD RESULTS (TEMPLATE)

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

for i=1:length(LIST_LEVELS)
    
    cd(LIST_LEVELS{i});
    
    % initialize volume that is going to store final metrics maps for
    % each level of the spinal cord
    name=[char(list_samples(1)) '_' char(LIST_METRICS(1)) '_reg_reg.nii.gz'];
    ref_for_size=load_nii_data(name);  
    
    Volume4D=zeros(size(ref_for_size,1),size(ref_for_size,2),1,length(LIST_METRICS));
    Volume4D_std=zeros(size(ref_for_size,1),size(ref_for_size,2),1,length(LIST_METRICS));
    
    tmp=zeros(size(ref_for_size,1),size(ref_for_size,2),length(list_samples)/2);
    tmp_mask=ones(size(ref_for_size,1),size(ref_for_size,2),length(list_samples)/2);   
       
    % get maps
    for mm=1:length(LIST_METRICS)    
        for mmm=1:2:length(list_samples)
            name=[char(list_samples(mmm)) '_' char(LIST_METRICS(mm)) '_reg_reg.nii.gz'];
            sample_id=(mmm+1)/2;
            tmp(:,:,sample_id)=load_nii_data(name);
        end     
    end
      
    % get masks
    for mmm=1:2:length(list_samples)
        name_mask=[char(list_samples(mmm)) '_mask.png'];
        sample_id=(mmm+1)/2;
        if exist(name_mask,'file') == 2
            tmp_mask(:,:,sample_id)=imread(name_mask);
        end
    end
    
    % Get nbr of samples for each depending on mask
    mask_nbr=sum(tmp_mask,3);
    save_nii_v2(mask_nbr,'nbr_of_samples.nii.gz','Sample1_AD_reg_reg.nii.gz',16);
    
    % get nnz matrix
    nnz_matrix=zeros(size(tmp_mask,1),size(tmp_mask,2));

    for hhh=1:size(tmp_mask,1)
        for kkk=1:size(tmp_mask,2)
            nnz_matrix(hhh,kkk)=nnz(tmp_mask(hhh,kkk,:));
        end
    end


    for ii=1:2:length(list_samples)

        % concatenate all metrics and compute average template for each
        % metric across samples of the current level
        for mm=1:length(LIST_METRICS)    
            for mmm=1:2:length(list_samples)
                name=[char(list_samples(mmm)) '_' char(LIST_METRICS(mm)) '_reg_reg.nii.gz'];
                sample_id=(mmm+1)/2;
                tmp(:,:,sample_id)=load_nii_data(name);
            end  
            
        Volume4D(:,:,1,mm)=dot(tmp,tmp_mask,3)./nnz_matrix;
        aaa=tmp.*tmp_mask;
        aaa(aaa==0) = NaN;
        Volume4D_std(:,:,1,mm)=nanstd(aaa,0,3);
        end
    end
                
    % save the final volume of metrics (input for k-means in next step)
    ref_4d=zeros(size(ref_for_size,1),size(ref_for_size,2),1,length(LIST_METRICS));
    save_nii(make_nii(ref_4d,[0.05 0.05 1]),'Volume4D_ref.nii.gz');
    save_nii_v2(Volume4D,'Volume4D.nii.gz','Volume4D_ref.nii.gz',16);
    save_nii_v2(Volume4D_std,'Volume4D_std.nii.gz','Volume4D_ref.nii.gz',16);

    % delete all files copied to generate the final 3D volume
    %delete('*_reg_reg.nii.gz');

    % delete 3d ref used to save the final 3d volume
    delete('Volume4D_ref.nii.gz');    

    cd ..
    
end

%% PART 3: COPY THE WM MASKS

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

for i=1:length(LIST_LEVELS)
    
    cd(LIST_LEVELS{i});
    % copy average WM mask generated during template creation
    copyfile('templategen/template/T_template0.nii.gz', 'mask_WM.nii.gz');
    cd ..
    
end

disp "DONE!"
