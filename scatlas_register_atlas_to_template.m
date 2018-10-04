%--------------------------------------------------------------------------
% Register an external WM atlas to the generated atlas. The expected intputs
% are: XX_reg_reg_tracts.nii.gz (mask of WM) and XX_WM_reg_reg.nii.gz
% (atlas showing each tract, with a grayscale value per tract), with XX
% being the level (e.g., C2). Note that the atlases used here are
% symmetric. These files should be placed inside the level folder (e.g.,
% data/all_levels/C2/).
% 
% This script works by looping across levels and registering the 2D
% external atlas mask to the 2D generated mask of the corresponding level.
%--------------------------------------------------------------------------                

clear

% Params
% none

% load params
run scatlas_parameters.m

fprintf('==========================\nREGISTER ATLAS TO TEMPLATE\n==========================\n')

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

% loop over levels
for level=1:length(LIST_LEVELS)

    cd(LIST_LEVELS{level});

    %% WM registration
    % parse name
    [~,level_name] = fileparts(pwd);

    % rename files to src and dest
    filename_atlas = [level_name,'_WM_reg_reg.nii.gz'];
    filename_template = 'templategen/template/T_template0.nii.gz';
    img_atlas = load_nii_data(filename_atlas);
    img_template = load_nii_data(filename_template);
%     save_nii_v2(img_atlas,'src.nii.gz',filename_atlas,16);
%     save_nii_v2(img_template,'dest.nii.gz',filename_template,16);
% 
%     atlas = load_nii_data('src.nii.gz');
%     dest = load_nii_data('dest.nii.gz');

    % put atlas in same header as template
    img_atlas_resized = imresize(img_atlas,[151,151]);
    filname_atlas_resized = [level_name,'_WM_reg_reg_resized.nii.gz'];
    save_nii_v2(make_nii(img_atlas_resized, [PIXEL_SIZE PIXEL_SIZE 1]), filname_atlas_resized, filename_atlas);
    filename_atlas = filname_atlas_resized;

    %% Ants registration using BsplineSyn on WM mask
    sct_unix(['isct_antsRegistration --dimensionality 2 --transform Affine[0.5] ', ...
        ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 5] ',...
               '--convergence 100x100 --shrink-factors 8x4 --smoothing-sigmas 5x2vox ',...
               '--transform bsplinesyn[0.5,2]', ...
               ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 4] ',...
               '--convergence 100x100x100x100 --shrink-factors 8x4x2x1 --smoothing-sigmas 0x0x0x0vox ',...
               '--output [warp_, ', [level_name,'_WM_reg_reg_reg.nii.gz'] ']' ,...
               ' --interpolation BSpline[3] --verbose 1']); 

    %% Tracts registration: Apply the estimated warping field to the atlas tracts

    sct_unix(['isct_antsRegistration --dimensionality 2 -r [', filename_template, ', ', filename_atlas, ', 0] --transform Affine[0.5] --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 5] ', ...
          '--convergence 0x0 --shrink-factors 8x4 --smoothing-sigmas 5x2vox ',...
          '--output [warpinit_] --interpolation BSpline[3] --verbose 1']); 

    sct_unix(['isct_antsRegistration --dimensionality 2 --transform Affine[0.5]', ... 
        ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 5] ',...
              '--convergence 100x100 --shrink-factors 8x4 --smoothing-sigmas 5x2vox ',...
              '--transform bsplinesyn[0.5,2]',... 
              ' --metric MeanSquares[' filename_template, ',' filename_atlas, ', 1,4] ',...
              '--convergence 100x100x100x100 --shrink-factors 8x4x2x1 --smoothing-sigmas 0x0x0x0vox ',...
              '--output [warp_', filename_atlas, ',', filename_template ']',... 
              ' --interpolation BSpline[3] --verbose 1']); 

    filename_tracts = [level_name,'_reg_reg_tracts.nii.gz'];
    img_tracts = load_nii_data(filename_tracts);

    % put tracts in same header as template
    img_tracts_resized = imresize(img_tracts, [151,151]);
    filename_tracts_resized = [level_name, '_reg_reg_tracts_resized.nii.gz'];
    save_nii_v2(make_nii(img_tracts_resized, [PIXEL_SIZE PIXEL_SIZE 1]), filename_tracts_resized, filename_tracts);
    filename_tracts = filename_tracts_resized;

    % Use sct_concat_transfo to create warp with the warp_0GenericAffine.met
    % and the warp output from the ANTS registration
    sct_unix(['sct_concat_transfo -d ', filename_template, ' -w warp_0GenericAffine.mat,warp_1Warp.nii.gz -o warp_atlas2template.nii.gz']);

    % Symmetrize the warping field
    warp2 = load_untouch_nii('warp_atlas2template.nii.gz');
    warp2.img(:,:,:,:,1) = 1/2*(warp2.img(:,:,:,:,1)-warp2.img(end:-1:1,:,:,:,1));
    warp2.img(:,:,:,:,2) = 1/2*(warp2.img(:,:,:,:,2)+warp2.img(end:-1:1,:,:,:,2));
    save_untouch_nii(warp2,'warp_atlas2template_sym.nii.gz')

    % Apply warps onto the tracts mask
    sct_unix(['sct_apply_transfo -i ', filename_tracts, ...
        ' -d ', filename_template, ...
        ' -w warpinit_0GenericAffine.mat,warp_atlas2template_sym.nii.gz', ...
        ' -o ', [level_name,'_reg_reg_tracts_reg.nii.gz']]);
    
    % Generate QC
    scatlas_qc_registration({[level_name,'_reg_reg_tracts_reg.nii.gz'], filename_template}, ['../../qc_atlas_', LIST_LEVELS{level}, '.gif']);
    cd ..
    
end

disp "DONE!"
