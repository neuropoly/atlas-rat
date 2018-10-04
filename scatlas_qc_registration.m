% generate QC to check quality of atlas registration
% list_files: list of cells

function scatlas_qc_registration(list_files, fileout)
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
