%--------------------------------------------------------------------------
% Apply correction on MVF, AVF and g-ratio maps
% 
% Inputs (should already be in memory): 
%   p_avf  correcting coefficient
%   p_mvf  correcting coefficient
% 
% Outputs:
%   
%--------------------------------------------------------------------------

% TODO: elucidate how AVF is generated.
% TODO: finish gratio part

clear

% load params
run scatlas_parameters.m

fprintf('================\nAPPLY CORRECTION\n================\n')

% go to data folder
cd(fullfile(PATH_DATA))

% load correction coeff 
load('correction_factors')

% go to folder level
cd(fullfile(FOLDER_LEVELS))

% list_levels = sct_tools_ls('*', [], [], 1); % get names of level folders
list_metrics = {'MVF', 'AVF'};
list_correction = {p_mvf, p_avf};

% loop over levels
for level=1:length(LIST_LEVELS)
    
    cd(LIST_LEVELS{level});
    list_samples = list_sample_folders();

    % loop over samples
    for jj=1:length(list_samples)
        cd(char(list_samples(jj)));
        
        for i_metric = 1:length(list_metrics)
            
            file_metric = char(sct_tools_ls(['Sample*_', list_metrics{i_metric}, '.*']));
            img = load_nii(file_metric);
%             img_1= img.img;
            img_corrected = list_correction{i_metric}(1)*img.img + (list_correction{i_metric}(2));
%             save_nii_v2(img_1, [char(list_samples(jj)), '_', list_metrics{i_metric}, '_uncorrected.nii.gz'], file_metric, 16);
            save_nii_v2(img_corrected, [char(list_samples(jj)), '_', list_metrics{i_metric}, '_corrected.nii.gz'], file_metric, 16);
    %       imshow(img_corrected); 
    %       x= img_corrected-img_1;
        end
        cd ..
    end
    cd ..
end 

% re-calculation of gratio
for level= 1:length(LIST_LEVELS)
    cd(LIST_LEVELS{level});
    list_samples = list_sample_folders();

  for jj=1:length(list_samples)
      cd(char(list_samples(jj)));

      name_avf=[char(list_samples(jj)) '_AVF_corrected.nii.gz'];
      name_mvf=[char(list_samples(jj)) '_MVF_corrected.nii.gz'];

      avf_map= load_nii(name_avf);
      mvf_map= load_nii(name_mvf);

      avf=avf_map.img;
      mvf=mvf_map.img;
      avf(mvf<=0)=0.0000;
      mvf(mvf<=0)=0.0000;
      
      gratio_corrected = sqrt(1 ./(1 + mvf ./avf));
      
%       movefile([char(list_samples(jj)), '_GR.nii.gz'], [char(list_samples(jj)), '_GR_uncorrected.nii.gz']);  
      save_nii_v2(gratio_corrected, [char(list_samples(jj)), '_GR_corrected.nii.gz'], [char(list_samples(jj)), '_GR.nii.gz'], 16);
      cd ..
  end
  cd ..
    
end

disp "DONE!"
