% generate QC to check quality of atlas registration
% the input is a list of 2D nifti files, and the output is a gif anim.

function scatlas_qc_registration(list_files, fileout)
    % list_files: list of cells. Each cell is a path to a nifti file.
    % loop across image and write to GIF
    for file=1:length(list_files)
        % get image matrix
        im = load_nii(list_files{file});
        img = uint8(flipud(im.img'));
        if file == 1 
            imwrite(img,gray(2),fileout,'gif', 'Loopcount', inf, 'DelayTime', 0.2);
        else 
            imwrite(img,gray(2),fileout,'gif', 'WriteMode','append', 'DelayTime', 0.2);
        end 
    end
