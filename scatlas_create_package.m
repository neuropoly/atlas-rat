%--------------------------------------------------------------------------
% Create atlas package to be uploaded to web server
%--------------------------------------------------------------------------

clear

path_script = fileparts(mfilename('fullpath'));

% load params
run scatlas_parameters.m

fprintf('=========================\nCREATE PACKAGE\n=========================\n')

% copy package files (mostly documentation)
copyfile(fullfile(path_script, 'package', '*'), fullfile(PATH_DATA, FOLDER_ATLAS));
 
zip('AtlasRat', fullfile(PATH_DATA, FOLDER_ATLAS));

fprintf('\nDone!\n');

