% generate QC to check quality of template generation
% to launch within the 

function generate_template_qc(fname_templategen, fileout)
    cd([fname_templategen, filesep, 'template'])
    % get each image warped to template
    list_images = sct_tools_ls('T_template0Sample*WarpedToTemplate.nii.gz');
    % loop across image and write to GIF
    for ii=1:length(list_images)
        name_im = list_images{ii};
        % get image matrix
        im = load_nii(name_im);
        img = uint8(flipud(im.img'));
        if ii == 1 
            imwrite(img,gray(2),fileout,'gif', 'Loopcount', inf, 'DelayTime', 0.2);
        else 
            imwrite(img,gray(2),fileout,'gif', 'WriteMode','append', 'DelayTime', 0.2);
        end 
    end
    cd ..
