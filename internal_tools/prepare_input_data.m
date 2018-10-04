%--------------------------------------------------------------------------
% This step prepares inputs (maps of samples) for template
% generation.
% Launch in main folder where you want to generate templates
%--------------------------------------------------------------------------

run scatlas_parameters.m

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

fileID = fopen(fullfile([PATH_DUKE_HISTO, 'template_levels_full.txt']),'r');
list_paths = textscan(fileID,'%s','Delimiter',',');

% for each level in txt file
for levels=1:size(list_paths{1,1},1)/6
    
    % Create folder for that level
    mkdir(list_paths{1,1}{1+6*(levels-1),1});
    cd(list_paths{1,1}{1+6*(levels-1),1});
    
    % For each sample of the current level
    for aa=1:5
        
        % Create folder for that sample
        mkdir(['Sample' num2str(aa)]);
        cd(['Sample' num2str(aa)]); 
        
        % Copy the maps of interest and convert to nii.gz
        outfile = ['Sample' num2str(aa) '_GR.nii' ]; 
        copyfile ([PATH_DUKE_HISTO, list_paths{1,1}{(aa+6*(levels-1))+1,1} '/maps' '/stats_50um/' '1_gRatio.nii' ], outfile); 
        unix(['fslchfiletype NIFTI_GZ ', outfile]) ;

        outfile = ['Sample' num2str(aa) '_AED.nii' ]; 
        copyfile ([PATH_DUKE_HISTO, list_paths{1,1}{(aa+6*(levels-1))+1,1} '/maps' '/stats_50um/' '2_axonEquivDiameter.nii' ], outfile); 
        unix(['fslchfiletype NIFTI_GZ ', outfile]);

        outfile = ['Sample' num2str(aa) '_AD.nii' ]; 
        copyfile ([PATH_DUKE_HISTO, list_paths{1,1}{(aa+6*(levels-1))+1,1} '/maps' '/stats_50um/' '7_Number_axons.nii' ], outfile); 
        unix(['fslchfiletype NIFTI_GZ ', outfile]);

        outfile = ['Sample' num2str(aa) '_MVF.nii' ]; 
        copyfile ([PATH_DUKE_HISTO, list_paths{1,1}{(aa+6*(levels-1))+1,1} '/maps' '/stats_50um/' '10_MVF.nii' ], outfile); 
        unix(['fslchfiletype NIFTI_GZ ', outfile]);

        outfile = ['Sample' num2str(aa) '_AVF.nii' ]; 
        copyfile ([PATH_DUKE_HISTO, list_paths{1,1}{(aa+6*(levels-1))+1,1} '/maps' '/stats_50um/' '11_AVF.nii' ], outfile); 
        unix(['fslchfiletype NIFTI_GZ ', outfile]);

        outfile = ['Sample' num2str(aa) '_MT.nii' ]; 
        copyfile ([PATH_DUKE_HISTO, list_paths{1,1}{(aa+6*(levels-1))+1,1} '/maps' '/stats_50um/' '4_myelinThickness.nii' ], outfile); 
        unix(['fslchfiletype NIFTI_GZ ', outfile]);
        cd ..
    end
    cd .. 
end

% if you want to copy manually-generated files from another data folder to 
% a new folder (in bash):
% for file in `find . -name "Label1.mat"`; do dirname=$(dirname $file); cp $file /Users/julien/Desktop/data/all_levels/${dirname:2}/$(basename $file); done
% for file in `find . -name "Label2.mat"`; do dirname=$(dirname $file); cp $file /Users/julien/Desktop/data/all_levels/${dirname:2}/$(basename $file); done
% for file in `find . -name "*_mask.*"`; do dirname=$(dirname $file); cp $file /Users/julien/Desktop/data/all_levels/${dirname:2}/$(basename $file); done

% remove ugly apple files


