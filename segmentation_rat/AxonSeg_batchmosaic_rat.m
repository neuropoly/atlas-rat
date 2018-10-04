%% Script for abbey (segment mosaics based on list in txt file)
% The txt file is a list with code & path (string) to mosaics of each
% sample

% Code : 
% 0 : to process
% 1 : already segmented
% 2 : currently processed in abbey
% 2 : currently processed in django

%% Read the txt file and get codes & paths
I=1;

% CHANGE THIS!
logfile = '/Users/alzaia/Documents/histology/Pipeline/b_rat_Generate_Atlas/segmentation_rat/log.txt';

while(~isempty(I))
    j_disp(logfile,'STARTING SEGMENTATION!')
    % CHANGE THIS!
    filename = '/Users/alzaia/Documents/histology/Pipeline/b_rat_Generate_Atlas/segmentation_rat/segmentationlist.txt';
    delimiter = ' ';
    formatSpec = '%f%s%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true,  'ReturnOnError', false,'CommentStyle','#');
    fclose(fileID);
    Status = dataArray{:, 1};
    FolderPath = dataArray{:, 2};
    clearvars delimiter formatSpec fileID dataArray ans;

    % Find samples that are not segmented yet & get path of first sample not
    % segmented

    I = find(Status==0);

    if ~isempty(I)
        foldertoprocess=FolderPath{I(1)}; 
        j_disp(logfile,['Processing Folder ' foldertoprocess])
        cd(foldertoprocess);
        srcFiles = sct_tools_ls('*.png');

    % Change current processed sample to code 2 & update txt file
        formatSpec ='%u %s\n';
        Status(I(1))=2;
        fileID = fopen(filename,'w');
        for i=1:size(Status,1)
            fprintf(fileID,formatSpec,Status(i),FolderPath{i});   
        end
        fclose(fileID);   

    % Segmentation of the sample
    
    for i = 1:length(srcFiles)
        img_filename = [srcFiles{i}];
        [~,name]=fileparts(img_filename);
        output=[name '_Segmentation' filesep 'axonlist_full_image.mat'];
        if ~exist(output,'file')
            try
                as_Segmentation_full_image(img_filename, './SegParameters.mat',2500,100);
            catch err
                j_disp(logfile,[foldertoprocess img_filename])
            end
        end
    end


    
    % CHANGE THIS!
    filename = '/Users/alzaia/Documents/histology/Pipeline/b_rat_Generate_Atlas/segmentation_rat/segmentationlist.txt';
    delimiter = ' ';
    formatSpec = '%f%s%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true,  'ReturnOnError', false,'CommentStyle','#');
    fclose(fileID);
    Status = dataArray{:, 1};
    FolderPath = dataArray{:, 2};
    clearvars delimiter formatSpec fileID dataArray ans;
    
    J = find(Status==2);
    

        formatSpec ='%u %s\n';
        Status(J(1))=1;
        
        
        
        % Update txt file after segmentation of current path is done 
        fileID = fopen(filename,'w');
        for i=1:size(Status,1)
            fprintf(fileID,formatSpec,Status(i),FolderPath{i});   
        end
        fclose(fileID);  


    else
        disp('No more mosaic to segment in txt file!');
    end

end


% addpath(genpath('/home/neuropoly/Documents/MATLAB/djangolink/tanguy/Histo/Rat/SCRIPTS'))


