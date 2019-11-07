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
% 
% The input of this function are the files XX_reg_reg_tracts_fixed.nii.gz.
% By default, they are located under: /Volumes/projects/atlas_rat/Generated_Atlas_final_results/data/all_levels/XX 
% Note: on the original Paxinos atlas, C1, C2 and C3 levels have an
% additional tract (LatC). To overcome the problem of having a variable
% number of tracts across levels, we decided to fuse this tract with its
% neighbor LSp (as is the case in other levels). The original tract file
% with all the labels is called: XX_reg_reg_tracts_fixed_AdditionalTracts.nii.gz
% 
% Tested with ANTs Version: 2.1.0.post735-gae5a6
%--------------------------------------------------------------------------                

% TODO: check levels 8 and 27 (counting first level as 0).
% TODO: fix inconsistencies in tract numbering for levels 0, 1, 2.
clear

SIZE_TEMPLATE = 151;
OUTPUT_DTYPE = 16;  % dtype of output 4d file. 4: int16, 16: float-32 (see: https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/submissions/8797/versions/28/previews/make_nii.m/index.html).

% load params
run scatlas_parameters.m

fprintf('==========================\nREGISTER ATLAS TO TEMPLATE\n==========================\n')

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

% loop over levels
n_levels = length(LIST_LEVELS);
for level=1:n_levels
%     level=27;
    cd(LIST_LEVELS{level});

    %% WM registration
    % parse name
    [~,level_name] = fileparts(pwd);

    % rename files to src and dest
    filename_atlas = [level_name,'_WM_reg_reg.nii.gz'];
    filename_template = 'templategen/template/T_template0.nii.gz';
    img_atlas = load_nii_data(filename_atlas);
    img_template = load_nii_data(filename_template);

    % put WM mask in same header as template
    img_atlas_resized = imresize(img_atlas,[SIZE_TEMPLATE,SIZE_TEMPLATE], 'bilinear');
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
    end
    
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
        img = load_nii_data([LIST_LEVELS{i_level} filesep LIST_LEVELS{i_level} '_reg_reg_tracts_fixed_resized_' num2str(i_tract) '_reg.nii.gz']);
        % populate array
        img4d(:, :, i_level, i_tract) = img;
    end
end
% write nifti file
nii = make_nii(img4d, [PIXEL_SIZE PIXEL_SIZE 1]);
nii.hdr.dime.datatype = OUTPUT_DTYPE;
nii.hdr.dime.bitpix = OUTPUT_DTYPE;
save_nii_v2(nii, 'AtlasRat_Paxinos.nii.gz', OUTPUT_DTYPE);
disp "DONE!"