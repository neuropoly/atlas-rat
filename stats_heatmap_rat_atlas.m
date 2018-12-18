%--------------------------------------------------------------------------
% Generation of Heatmaps
% 
% This script outputs the heatmaps for whatever metric you wish to see,
% included right now are mean, median and iqr.
%--------------------------------------------------------------------------  

run scatlas_parameters.m
stat= input('Input a statistical metric: ', 's'); 


metrics = {'Axon Density', 'Axon Diameter', 'AVF Corrected', 'G Ratio', 'Myelin Thickness', 'MVF Corrected'};
tract_list= {'Tract 1', 'Tract 2', 'Tract 3', 'Tract 4', 'Tract 5', 'Tract 6', 'Tract 7', 'Tract 8'};
x= zeros(31, 16);

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))


    for m= 1:length(metrics)
        
        for level=1:length(LIST_LEVELS)
            
            if level== 1 || level==2 || level==3
            % set tract values
                tract_values= 1:16;
            else
                tract_values=1:14;
            end 
                
            
            cd(LIST_LEVELS{level})
            
            for ii= 1:length(tract_values)

                load('tract_metrics.mat');
                
                switch stat
                    case 'mean'
                        x(level,ii)= mean(cell2mat(val(ii, m)));
                    
                    case 'median'
                        x(level,ii)= median(cell2mat(val(ii, m)));
                        
                    case 'iqr'
                        x(level,ii)= iqr(cell2mat(val(ii, m)));
                end 
                
            end
            cd .. 
        end
        % Remove all values of 0 from the table and replace with NaN
        x(:, all(isnan(x), 1))=[];
        x(x==0)= NaN;
        x(:, all(isnan(x), 1))=[];
        x(x==0)= NaN; 
        
        %Compar proper tracts by shifting columns for C1-C3 to one to the 
        %left and get rid of 8th column of the extra tract
        shift= x(1:3, 7:8);
        x(1:3, 6:7)= shift;
        x(:,8)= [];
        save([metrics{m} '_' stat '.mat'], 'x');
        imagesc(x)
        ylabel('Spinal Level');
        xlabel('Tracts');
        colorbar
        export_fig([metrics{m} '_' stat '_heatmap.png'], '-r300');

    end 
    

disp "DONE!"


