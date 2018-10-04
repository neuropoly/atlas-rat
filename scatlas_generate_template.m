%--------------------------------------------------------------------------
% Create average 2D template using axon density maps using 
% antsmultivariateTemplateConstrusction2.sh.
% 
% Output
%   warping(subject,level)
%--------------------------------------------------------------------------

clear

% Params
suffix_mask = '*mask_reg_reg.nii.gz'  % suffix used to generate template

% load params
run scatlas_parameters.m

fprintf('=================\nGENERATE TEMPLATE\n=================\n')

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

list = sct_tools_ls('*', [], [], 1);

% loop over levels
for i= 1:length(list)
    
    % create folder where the input images from each sample will be placed
    % (need to have all in put images in the same folder for the template
    % to run)
    cd(char(list(i)))
    mkdir templategen
    list_samples = sct_tools_ls('Sample*', [], [], 1);

    % loop over samples
    for jj= 1:length(list_samples)
        
        % copy the input files into one folder to be used for template 
        % generation  
        cd (char(list_samples(jj)))
        copyfile (suffix_mask, '../templategen'); 
        cd ..  
    end
    
    % create the template for each level  
    cd templategen
    % need to set ANTSPATH variable, which will be used by ANTs'
    % antsMultivariateTemplateConstruction2.sh script
    setenv('ANTSPATH', PATH_ANTS);
    cmd=[PATH_ANTS, 'antsMultivariateTemplateConstruction2.sh ',...
      '-d 2 ',...
      '-o ./template/T_ ',...
      '-i 4 ',...
      '-g 0.15 ',...
      '-j 2 ',...
      '-c 0 ',...
      '-k 1 ',...
      '-w 1 ',...
      '-f 8x4x2 ',...
      '-s 0x0x0 ',...
      '-q 200x50x20 ',...
      '-n 0 ',...
      '-r 0 ',...
      '-l 1 ',...
      '-m MSQ ',...
      '-t BSplineSyN[0.15,2,0] ',...
      './', suffix_mask];
    [status, output]= unix(cmd);
    
    % generate QC gif images of registration quality
    fname_templategen = pwd;
    fileout = ['../../../qc_template_', char(list(i)), '.gif'];  % save gif in root folder (where all levels are)
    generate_template_qc(fname_templategen, fileout);
    % back to previous folder
    cd ../..
end 

disp "DONE!"
