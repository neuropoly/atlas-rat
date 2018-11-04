%%-------------------------------------------------------------------------
% Extract metrics within tracts defined by the atlas.
% 
% 1) Creates an image showing a metric with an overlay of the atlas, where
% each tract is shown with a different color.
% 2) Extracts metrics
% 3) Generate violin plot form and stats.
% 
% Inputs:
% - LEVEL_reg_reg_tracts_reg     output of scatlas_register_atlas_to_template.m
% - Volume4D_sym_cleaned.nii.gz  output of scatlas_symmetrize_and_clean_template.m
% 
% Outputs:
% - atlas_color.png              colored atlas overlaid on axon density map
% - *.png                        different violin plots (axonDensity, etc.)
%--------------------------------------------------------------------------

% Params
fname_metrics = 'Volume4D_sym_cleaned.nii.gz';  % 4d volume that contains all concatenated metrics

% load params
run scatlas_parameters.m

fprintf('===============\nEXTRACT METRICS\n===============\n')

% go to data folder
cd(fullfile(PATH_DATA, FOLDER_LEVELS))

% loop over levels
for level=1:length(LIST_LEVELS)

    cd(LIST_LEVELS{level});
    
    %% Make color atlas
    atlas = uint8(round(load_nii_data([LIST_LEVELS{level},'_reg_reg_tracts_reg.nii.gz'])));
    atlas = atlas*2;  % change the dynamic of the color scaling
    % change color of right tracts
    atlas(end/2:end,:,:) = atlas(end/2:end,:,:)-1;

    if level== 1 || level==2 || level==3
        % set tract values
        tract_values = 1:16;
    else
        tract_values = 1:14; 
    end 

    % keep largest blob
    atlas_clean = zeros(size(atlas),'uint16');
    for ii=1:16
        [labeledImage] = bwlabel(atlas==ii,4);
        blobMeasurements = regionprops(labeledImage, 'area');
        % Get all the areas
        allAreas = [blobMeasurements.Area];
        [vv,ind] = max([allAreas]);
        %  ind=find(allAreas>minimalsize & allAreas<size(atlas,1)*size(atlas,2)*.1);
        % Extract the "numberToExtract" largest blob(a)s using ismember().
        if ~isempty(ind)
            tractmask = labeledImage ==ind;
            atlas_clean = atlas_clean + uint16(tractmask)*ii;
        end
    end

    %% Load Volume4D (=stats) of concatenated metrics template
    stats=load_nii_data(fname_metrics); % The 4th dimension contains the metrics values: 1) axondensity, 2) axondiameter, 3) AVF Corrected, 4)g-ratio, 5)Myelin Thickness 6) MVF Corrected


    %% Write png of atlas overlayed on first metric image (ie axon density)
    Pcolors = zeros(max(tract_values),3);
    cmap = hsv(max(tract_values)/2+1);
    cmap = cmap(1:end-1,:);
    Pcolors(1:2:end,:)= cmap;
    Pcolors(2:2:end,:)= cmap;

    atlascolor = atlas_clean;
    for ii=1:length(tract_values)
        atlascolor(atlascolor==tract_values(ii))=ii;
    end
    img = stats(:,:,:,1);
    sc(sc(img,[0,300]) + .3*imresize(sc(ind2rgb(atlascolor,colormap(cat(1,[0 0 0],Pcolors)))),size(img)));
    axis image

    export_fig atlas_color.png -r300

    %% extract stats per tract
    % get the features for all the tracts
    val=cell(length(tract_values),size(stats,4));

    for ii=1:length(tract_values)
        %sc(atlas_clean==ordertractval(ii)); drawnow; pause
        for is=1:size(stats,4)
            stats_tmp = stats(:,:,:,is);
            val{ii,is} = stats_tmp(ismember(atlas_clean,tract_values(ii)) & stats_tmp>0);
            save('tract_metrics.mat', 'val');
        end
    end

    %% violin plot
    metrics = {'Axon Density', 'Axon Diameter', 'AVF Corrected', 'G Ratio', 'Myelin Thickness', 'MVF Corrected'};
    contrast = {[0 600],        [0 3],          [0 0.7],         [0.4 0.8],        [0 1],        [0 0.7]};

    for im = 1:length(metrics)
        figure
        violin(val(~cellfun(@isempty,val(:,im)'),im)','facecolor',Pcolors)
        hold off
        ylabel(metrics{im})
        set(gca,'Xtick',[])
        ylim(contrast{im})
        export_fig(genvarname(metrics{im}), '-r150')
    end
    
    for ii= 1:length(tract_values)
        for m= 1:length(metrics)
            x(ii,m)= mean(val{ii,m});
            save('tract_averages.mat', 'x')
        end
    end
        
    cd .. 
end

