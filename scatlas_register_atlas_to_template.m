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

% TODO: change BSpline[3] to linear
% TODO: output will be nx,ny,n_tract (instead of nx,ny)

clear

SIZE_TEMPLATE = 151;
OUTPUT_DTYPE = 4;  % dtype of output 4d file. 4: int16.

% Params
% none

% load params
run scatlas_parameters.m

fprintf('==========================\nREGISTER ATLAS TO TEMPLATE\n==========================\n')

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

% loop over levels
n_levels = length(LIST_LEVELS);
for level=1:n_levels

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

    % put WM mask in same header as template
    img_atlas_resized = imresize(img_atlas,[SIZE_TEMPLATE,SIZE_TEMPLATE], 'bilinear');

    % TODO: check the thing below (why nearest??)    
%     if level==6 || level==8 || level==21 || level==22
%         img_atlas_resized = imresize(img_atlas,[SIZE_TEMPLATE,SIZE_TEMPLATE], 'bilinear');
%     else
%         img_atlas_resized = imresize(img_atlas,[SIZE_TEMPLATE,SIZE_TEMPLATE], 'nearest');
%     end 

    filname_atlas_resized = [level_name,'_WM_reg_reg_resized.nii.gz'];
    save_nii_v2(make_nii(img_atlas_resized, [PIXEL_SIZE PIXEL_SIZE 1]), filname_atlas_resized, filename_atlas);
    filename_atlas = filname_atlas_resized;

    %% Ants registration using BsplineSyn on WM mask
    if level== 6 || level== 8 || level== 27
        % Smoothing sigma and shrink factor are different than with other levels
        sct_unix(['isct_antsRegistration --dimensionality 2 --transform Affine[0.5] ', ...
        ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 5] ',...
               '--convergence 100x100 --shrink-factors 8x4 --smoothing-sigmas 2x2vox ',...
               '--transform bsplinesyn[0.5,2]', ...
               ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 4] ',...
               '--convergence 100x100x100x100 --shrink-factors 8x4x2x1 --smoothing-sigmas 0x0x0x0vox ',...
               '--output [warp_, ', [level_name,'_WM_reg_reg_reg.nii.gz'] ']' ,...
               ' --interpolation BSpline[3] --verbose 1']); 
% 
%         %% Tracts registration: Apply the estimated warping field to the atlas tracts
% 
%         sct_unix(['isct_antsRegistration --dimensionality 2 -r [', filename_template, ', ', filename_atlas, ', 0] --transform Affine[0.5]', ... 
%         ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 5] ', ...
%           '--convergence 0x0 --shrink-factors 8x4 --smoothing-sigmas 2x2vox ',...
%           '--output [warpinit_] --interpolation BSpline[3] --verbose 1']); 
% 
% 
%         sct_unix(['isct_antsRegistration --dimensionality 2 --transform Affine[0.5]', ... 
%         ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 5] ',...
%               '--convergence 100x100 --shrink-factors 8x4 --smoothing-sigmas 2x2vox ',...
%               '--transform bsplinesyn[0.5,2]',... 
%               ' --metric MeanSquares[' filename_template, ',' filename_atlas, ', 1,4] ',...
%               '--convergence 100x100x100x100 --shrink-factors 8x4x2x1 --smoothing-sigmas 0x0x0x0vox ',...
%               '--output [warp_', [level_name,'.nii.gz'] ']',... 
%               ' --interpolation BSpline[3] --verbose 1']); 
    elseif level== 24
        % Smoothing sigma and shrink factor are different than with other levels
        sct_unix(['isct_antsRegistration --dimensionality 2 --transform Affine[0.5] ', ...
        ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 5] ',...
               '--convergence 100x50 --shrink-factors 4x2 --smoothing-sigmas 5x2vox ',...
               '--transform bsplinesyn[0.5,2]', ...
               ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 4] ',...
               '--convergence 100x100x70x500 --shrink-factors 6x4x2x1 --smoothing-sigmas 0x0x0x0vox ',...
               '--output [warp_, ', [level_name,'_WM_reg_reg_reg.nii.gz'] ']' ,...
               ' --interpolation BSpline[3] --verbose 1']); 
% 
%     %% Tracts registration: Apply the estimated warping field to the atlas tracts
% 
%         sct_unix(['isct_antsRegistration --dimensionality 2 -r [', filename_template, ', ', filename_atlas, ', 0] --transform Affine[0.5]', ... 
%         ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 5] ', ...
%           '--convergence 0x0 --shrink-factors 8x4 --smoothing-sigmas 2x2vox ',...
%           '--output [warpinit_] --interpolation BSpline[3] --verbose 1']); 

        % Smoothing sigma is different than with other levels
%         sct_unix(['isct_antsRegistration --dimensionality 2 --transform Affine[0.5]', ... 
%         ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 5] ',...
%               '--convergence 100x100 --shrink-factors 8x4 --smoothing-sigmas 2x2vox ',...
%               '--transform bsplinesyn[0.5,2]',... 
%               ' --metric MeanSquares[' filename_template, ',' filename_atlas, ', 1,4] ',...
%               '--convergence 100x100x100x100 --shrink-factors 8x4x2x1 --smoothing-sigmas 0x0x0x0vox ',...
%               '--output [warp_', [level_name,'.nii.gz'] ']',... 
%               ' --interpolation BSpline[3] --verbose 1']); 
        
    else  
        sct_unix(['isct_antsRegistration --dimensionality 2 --transform Affine[0.5] ', ...
        ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 5] ',...
               '--convergence 100x100 --shrink-factors 8x4 --smoothing-sigmas 5x2vox ',...
               '--transform bsplinesyn[0.5,2]', ...
               ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 4] ',...
               '--convergence 100x100x100x100 --shrink-factors 8x4x2x1 --smoothing-sigmas 0x0x0x0vox ',...
               '--output [warp_, ', [level_name,'_WM_reg_reg_reg.nii.gz'] ']' ,...
               ' --interpolation BSpline[3] --verbose 1']); 
% 
%     %% Tracts registration: Apply the estimated warping field to the WM mask
% 
%         sct_unix(['isct_antsRegistration --dimensionality 2 -r [', filename_template, ', ', filename_atlas, ', 0] --transform Affine[0.5]', ... 
%         ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 5] ', ...
%           '--convergence 0x0 --shrink-factors 8x4 --smoothing-sigmas 5x2vox ',...
%           '--output [warpinit_] --interpolation BSpline[3] --verbose 1']); 

%         % Smoothing sigma is different than with other levels
%         sct_unix(['isct_antsRegistration --dimensionality 2 --transform Affine[0.5]', ... 
%         ' --metric MeanSquares[', filename_template, ', ', filename_atlas, ', 1, 5] ',...
%               '--convergence 100x100 --shrink-factors 8x4 --smoothing-sigmas 5x2vox ',...
%               '--transform bsplinesyn[0.5,2]',... 
%               ' --metric MeanSquares[' filename_template, ',' filename_atlas, ', 1,4] ',...
%               '--convergence 100x100x100x100 --shrink-factors 8x4x2x1 --smoothing-sigmas 0x0x0x0vox ',...
%               '--output [warp_', [level_name,'.nii.gz'] ']',... 
%               ' --interpolation BSpline[3] --verbose 1']); 
    end
    
    % Concatenate affine and non-linear transformations
    sct_unix(['sct_concat_transfo -d ', filename_template, ' -w warp_0GenericAffine.mat warp_1Warp.nii.gz -o warp_atlas2template.nii.gz']);

    % Symmetrize the warping field
    warp2 = load_untouch_nii('warp_atlas2template.nii.gz');
    warp2.img(:,:,:,:,1) = 1/2*(warp2.img(:,:,:,:,1)-warp2.img(end:-1:1,:,:,:,1));
    warp2.img(:,:,:,:,2) = 1/2*(warp2.img(:,:,:,:,2)+warp2.img(end:-1:1,:,:,:,2));
    save_untouch_nii(warp2,'warp_atlas2template_sym.nii.gz')
        
    %% Split each tract into a single file and apply the warping field to each tract     
    
    filename_tracts = [level_name,'_reg_reg_tracts_fixed.nii.gz'];
    img_tracts = load_nii_data(filename_tracts);
    % imagesc(img_tracts)  % for debugging

    % loop across tract, separate each tract into individual file, then apply transformation.
    n_tracts = max(max(img_tracts));
    for i_tract=1:n_tracts
        % extract tract into new image of same size
        img_tract_i = zeros(size(img_tracts));
        ind = find(img_tracts == i_tract);
        img_tract_i(ind) = 1;
        % put tracts in same header as template
        img_tract_i_resized = imresize(img_tract_i, [SIZE_TEMPLATE,SIZE_TEMPLATE], 'bilinear');
        filename_tract_resized = [level_name, '_reg_reg_tracts_fixed_resized_' num2str(i_tract) '.nii.gz'];
        save_nii_v2(make_nii(img_tract_i_resized, [PIXEL_SIZE PIXEL_SIZE 1]), filename_tract_resized, filename_tracts);
        % apply transformation
        sct_unix(['sct_apply_transfo -i ', filename_tract_resized, ...
            ' -d ', filename_template, ...
            ' -x linear', ...
            ' -w warp_atlas2template_sym.nii.gz', ...
            ' -o ', [level_name,'_reg_reg_tracts_fixed_resized_' num2str(i_tract) '_reg.nii.gz']]);
%         sct_unix(['sct_apply_transfo -i ', filename_tract_resized, ...
%             ' -d ', filename_template, ...
%             ' -x linear', ...
%             ' -w warpinit_0GenericAffine.mat,warp_atlas2template_sym.nii.gz', ...
%             ' -o ', [level_name,'_reg_reg_tracts_fixed_reg.nii.gz']]);
        
    end
%         
%         filename_tracts = filename_tracts_resized;
%         filename_tracts_fixed = [level_name,'_reg_reg_tracts_resized_fixed.nii.gz'];
    %unix(['fslmaths ' filename_tracts ' -kernel box 0.15x0.15 -fmedian ' filename_tracts_fixed]);

%     % Apply warps onto the tracts mask
%     if level== 28 || level==29 || level==30 || level== 31
%         sct_unix(['sct_apply_transfo -i ', filename_tracts, ...
%             ' -d ', filename_template, ...
%             ' -x nn', ...
%             ' -w warpinit_0GenericAffine.mat,warp_atlas2template_sym.nii.gz', ...
%             ' -o ', [level_name,'_reg_reg_tracts_fixed_reg.nii.gz']]);
%      else
%             sct_unix(['sct_apply_transfo -i ', filename_tracts, ...
%             ' -d ', filename_template, ...
%             ' -w warpinit_0GenericAffine.mat,warp_atlas2template_sym.nii.gz', ...
%             ' -o ', [level_name,'_reg_reg_tracts_fixed_reg.nii.gz']]);
%     end 
    
    
    % Generate QC: gif anim to compare registered WM mask to template
    scatlas_qc_registration({[level_name,'_WM_reg_reg_reg.nii.gz'], filename_template}, ['../../qc_atlas_', LIST_LEVELS{level}, '.gif']);
    cd ..
end

%% Concatenate each registered tracts into a 4d volume: (x,y,z,tract)
% initialize array
img4d = zeros([SIZE_TEMPLATE, SIZE_TEMPLATE, n_levels, n_tracts]);
for i_level=1:n_levels
    for i_tract=1:n_tracts
        % open image
        img = load_nii_data([level_name filesep level_name '_reg_reg_tracts_fixed_resized_' num2str(i_tract) '_reg.nii.gz']);
        % populate array
        img4d(:, :, i_level, i_tract) = img;
    end
end
% write nifti file
nii = make_nii(img4d, [PIXEL_SIZE PIXEL_SIZE 1]);
nii.hdr.dime.datatype = OUTPUT_DTYPE;
nii.hdr.dime.bitpix = OUTPUT_DTYPE;
save_nii_v2(nii, 'AtlasRat_Paxinos.nii.gz', 4);
disp "DONE!"