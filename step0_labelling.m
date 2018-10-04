%--------------------------------------------------------------------------
% Name: step0_labelling.m
% Date: 2017/11/23
% Description: Step 0: Labelling: From the axon density image, create 
% labels: Label #1 in the central canal, label #2 in the anterior median 
% fissure.
%
%--------------------------------------------------------------------------

list_levels = sct_tools_ls('*'); % get names of level folders

% loop over levels
for ii=1:length(list_levels)
    
    cd(char(list_levels(ii)));
    list_samples = sct_tools_ls('*'); % get names of sample folders
    
    % loop over samples
    for jj=1:length(list_samples)
        
        % zip the input map
        cd(char(list_samples(jj)));
        if ~exist([char(list_samples(jj)) '_mask.nii.gz']);
            
            name=[char(list_samples(jj)) '_MVF.nii'];
            img_for_mask=load_nii_data(name);
            img_for_mask=imresize(img_for_mask,4);

            % draw white matter mask on img
            disp(['<strong>','*** Please identify the WHITE MATTER by drawing a polygon for ',char(list_levels(ii)),' -> ',char(list_samples(jj)),' *** </strong>']);
            [~,maskWM]=as_tools_getroi(img_for_mask);
            % dra gray matter mask on image
            disp(['<strong>','*** Please identify the GRAY MATTER by drawing a polygon for ',char(list_levels(ii)),' -> ',char(list_samples(jj)),' *** </strong>']);
            [~,maskGM]=as_tools_getroi(img_for_mask);

            % generate and save mask
            final=zeros(size(maskWM,1),size(maskWM,2));
            final(maskWM==true)=1;
            final(maskGM==true)=0;
            WM_mask=imresize(final,0.25);
            WM_mask=im2bw(WM_mask);
            %imshow(WM_mask);

            imwrite(WM_mask,'mask.png');
            name_mask=[char(list_samples(jj)) '_mask.nii.gz'];
            save_nii_v2(WM_mask,name_mask,name,16);
            %gzip(name);
        end 
        
        % create empty reference space
        ref=zeros(151,151);
        resfinal = 0.05;
        save_nii(make_nii(ref,[resfinal resfinal 1]),['ref_template_50um_' char(list_samples(jj)) '.nii.gz']);
        
        % put map into empty reference space
        sct_unix(['sct_register_multimodal -i ' char(list_samples(jj)) '_mask.nii.gz -o ' char(list_samples(jj)) '_mask_reg.nii.gz  -d ref_template_50um_' char(list_samples(jj)) '.nii.gz -identity 1']);

        % identify the 2 labels by user interaction
        src = [char(list_samples(jj)) '_mask_reg.nii.gz'];
        map = load_nii_data(src);
        mask = zeros(size(map));
        disp(['<strong>','*** Please identify the 2 labels by selecting the points with the cursor for ',char(list_levels(ii)),' -> ',char(list_samples(jj)),' *** </strong>']);
        figure
        imagesc(map)
        [x,y,~] = impixel;
        Label1=[y(1),x(1)];
        Label2=[y(2),x(2)];
        save('Label1','Label1');
        save('Label2','Label2');
        cd ..
    end  
    cd .. 
end













