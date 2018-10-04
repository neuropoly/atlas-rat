% 1) Go inside level folder (ex: C6)
% 2) In matlab command window, launch: step3_generate_mask(file_name,nbr_of_regions);
% For example, to generate mask for sample 4 and you have 2 different black
% holes in that sample, use: step3_generate_mask('Sample4_MVF_reg_reg.nii.gz',2);
% When launching the fct, you will then draw polygons around the black
% holes, one by one.

function step3_generate_mask(file_name,nbr_of_regions)

    map=load_nii_data(file_name);
    map=imresize(map,4);
    
    mask=zeros(size(map,1),size(map,2),nbr_of_regions);
    
    for i=1:nbr_of_regions
        
        % draw hole mask on img
        disp(['<strong>','*** Please identify the black hole ',num2str(i), ' by drawing a polygon around it ',' *** </strong>']);
        [~,mask_i]=as_tools_getroi(map);
        mask(:,:,i)=mask_i;
 
    end

    mask_final=sum(mask,3);
    mask_final=imresize(mask_final,0.25);
    mask_final=im2bw(mask_final,0.1);
    mask_final=imcomplement(mask_final);
    
    mask_name=[file_name(1:8) 'mask.png'];
    imwrite(mask_final,mask_name);

end



