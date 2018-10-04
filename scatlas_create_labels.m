%--------------------------------------------------------------------------
% - Create manual labels
%--------------------------------------------------------------------------

% load params
run scatlas_parameters.m

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

list_levels = sct_tools_ls('*'); % get names of level folders

% loop over levels
for ii=1:length(list_levels)
    
    cd(char(list_levels(ii)));
    list_samples = sct_tools_ls('*'); % get names of sample folders
    
    % loop over samples
    for jj=1:length(list_samples)

        % identify the 2 labels by user interaction
        src = [char(list_samples(jj)) '_mask_reg.nii.gz'];
        map = load_nii_data(src);
        mask = zeros(size(map));
        disp(['<strong>','*** Please identify the 2 labels by selecting the points with the cursor for ',char(list_levels(ii)),' -> ',char(list_samples(jj)),' *** </strong>']);
        figure
        imagesc(map)
        [x,y,~] = impixel;
        Label1=[y(1),x(1)];
        Label2=[y(2),x(2)];
        save('Label1','Label1');
        save('Label2','Label2');
        cd ..
    end  
    cd .. 
end













