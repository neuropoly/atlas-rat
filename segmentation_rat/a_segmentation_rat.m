% SEGMENTATION PIPELINE: EVALUATE SECTION BY SECTION
%**************************************************************************
%% 0- SETUP (RUN AT EACH USE)
%**************************************************************************

list = sct_tools_ls('201*');

%% Rename files (Image1.png --> 1.png) + uint8 + grayscale

folder = list;
for ii=1:length(folder)
    cd([folder{ii} '/mosaic/'])
    listpng=sct_tools_ls('*.png',0)';
    for il=1:length(listpng)
        img = imread(['' listpng{il}]);
        if il==1 && size(img,3) ==1, disp([folder{ii} ' already processed. Skipping.']); break; end
        if size(img,3)==3, img = uint8(rgb2gray(img)); end
        disp(['Writing ' num2str(il) '.png...'])
        imwrite(img,['' num2str(il) '.png']);
        if ~strcmp([num2str(il) '.png'],listpng{il}), delete([listpng{il}]); end
    end
    cd ../../
end


%**************************************************************************
%% II- SEGMENT 
%**************************************************************************
% LAUNCH SEGMENTATION ON ABBEY OR DJANGO
% batch script:  "AxonSeg_batchmosaic.m" or "AxonSeg_batchmosaic_abbey.m"



%**************************************************************************
%% III- STICTCH USING FIJI
%**************************************************************************
% BEFORE USE:
% Use Java 1.8+ in Matlab: https://www.mathworks.com/matlabcentral/answers/103056-how-do-i-change-the-java-virtual-machine-jvm-that-matlab-is-using-for-mac-os
%                    e.g.: (Terminal:) export MATLAB_JAVA=/Applications/Fiji.app/java/macosx/jdk1.8.0_66/jre/Contents/Home/
%                          (Matlab:) version -java
% Download and Install MIJ.jar: http://bigwww.epfl.ch/sage/soft/mij/ and
% put it in /Application/Fiji.app/Java
% Increase Memory limit: https://www.mathworks.com/matlabcentral/answers/92813-how-do-i-increase-the-heap-space-for-the-java-vm-in-matlab-6-0-r12-and-later-versions
%                        1. Create file java.opts with one line: -Xmx30000m (30Gb)
%                        2. Launch Matlab from this folder 
addpath /Applications/Fiji.app/scripts/
cur=pwd; Miji; cd(cur);
folder = list;
for ii=1:length(folder)
    cd(folder{ii})
    disp(folder{ii})
    im=sct_tools_ls('mosaic/*.png',1,1); im = imread(im{1});
    if size(im,3)>1
        disp('Images in RGB... not processed')
    else
        if ~exist('mosaic/TileConfiguration.registered.txt','file')
            cur=pwd; Miji; cd(cur);
            png=sct_tools_ls('*.PNG'); png = png(cellfun(@isempty,strfind(png,'review')));
            N=sscanf(png{1},'%dx%d.PNG'); % mosaic dimensions
            
            Columns = [1 N(2)];
            cd mosaic
            img = sct_tools_ls('*.png');
            dim=size(imread(img{1}));
            if ~exist('TileConfiguration.txt','file')
                if length(sct_tools_ls('*.png'))~=N(1)*N(2)
                    disp(['You should have ' num2str(N(1)*N(2)) ' images in this folder...'])
                else
                    overlap = .9;
                    [ColPos,RowPos]=meshgrid([0:(dim(2)+1)*overlap:dim(2)*N(2)*overlap]',[0:(dim(1)+1)*overlap:dim(1)*N(1)*overlap]');
                    
                    % If some images are missing, mask them
                    mask = false(N(1),N(2));
                    % mask(1,1)=1; mask(end,end)=1; % modify here if necessary
                    ColPos(mask)=[]; RowPos(mask)=[];
                    
                    as_stitch_WriteTileConfiguration(sct_tools_ls('*.png'),ColPos(:),RowPos(:))
                    movefile('TileConfiguration_matlab.txt','TileConfiguration.txt');
                end
            end
            downsample = 1; % downsampling ratio. .1 --> downsampling by a factor 10
            MIJ.run('Grid/Collection stitching', ['type=[Positions from file] order=[Defined by TileConfiguration] directory=' pwd ' '...
                'layout_file=TileConfiguration.txt '...
                'fusion_method=[Do not fuse images (only write TileConfiguration)] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap computation_parameters=[Save memory (but be slower)] image_output=[Write to disk] ' ...
                'x=' num2str(downsample) ' y=' num2str(downsample) ' width=' num2str(round(dim(2)*downsample)) ' height=' num2str(round(dim(1)*downsample)) ' interpolation=Bicubic average']);
            cd ..
            MIJ.exit
        else
            disp('already processed')
        end
    end
    cd ..
end



%**************************************************************************
%% III- GENERATES MAPS (AFTER SEGMENTATION)
%**************************************************************************
% Also test if already segmented and already stiched
folder = list;
fname = '/Volumes/histology/rat/segmentationlist2.txt';

for ii=1:length(folder)
    disp([folder{ii} '...'])
    % test if already segmented...
    dataArray = read_segmentationlist(fname);
    position = find(~cellfun(@isempty,strfind(dataArray{2},folder{ii})));
    if isempty(position), disp(['... not segmented']); continue; end 
    % ... done
    if dataArray{1}(position(1))==1
        % test if stiching already computed...
        if ~exist([folder{ii} '/maps'],'dir')
            if exist([folder{ii} '/mosaic/TileConfiguration.registered.txt'],'file')
        %... done
                cd([folder{ii} '/mosaic'])
                disp(['Processing ' folder{ii} '...'])
                clear axonlist img
                %**********************************************************
                % MAIN:
                %**********************************************************
                batch_postproc
                %**********************************************************
                cd ../..
            else
                disp(['... no TileConfiguration.registered.txt']);
            end
        else
            disp(['... maps already exist']);
        end
    end
end



%**************************************************************************
%% IV- GENERATE QC
%**************************************************************************
% 1- GENERATE Preview_100.png --> Stitched Intensity image downsampled by 100
for iii=1:length(list)
    cd(list{iii})
    cd mosaic
    clear img
    img = as_StitchfromTileConfig('TileConfiguration_matlab.txt');
    imwrite(imadjust(img(1:100:end,1:100:end,:)),'../Preview_100.png')
    cd /Volumes/data_processing/tanguy/Histo/Human
end

for iii=1:length(list)
    cd(list{iii})
    cd maps/stats_50um
    img = imread('../../Preview_100.png');
    png=sct_tools_ls(['../../*.PNG']); png = png(cellfun(@isempty,strfind(png,'review')));
    if  ~isempty(png) && ~isempty(strfind(png{1},'_RL')), RL=1; else RL = 0; end % Right-Left?
    img =permute(img,[2 1 3 4]);
    if RL
        img = img(end:-1:1,end:-1:1,:,:);
    else
        img =  img(:,end:-1:1,:,:);
    end

    save_nii_v2(imresize(img,size(load_nii_data('1_gRatio.nii'))),'Preview.nii.gz','1_gRatio.nii');
    cd /Volumes/data_processing/tanguy/Histo/Human
end

%**************************************************************************
%% IV- OTHER TOOLS
%**************************************************************************

%% Select a region to reprocess
png=sct_tools_ls('../*.PNG'); png = png(cellfun(@isempty,strfind(png,'review')));
N=sscanf(png{1},'%dx%d.PNG');
MOSAIC=createMontage(sct_tools_ls('axonEquivDiameter_(myelin)*.png',1,1,2,1),'montageSize',N','thumbSize',[150 150*1.4545]);
MOSAIC = rgb2gray(MOSAIC);
[~,mask]=as_tools_getroi(MOSAIC);
maskdownsample=blockproc(mask,[150 150*1.4545],@(x) max(x.data(:)));
RP = find(maskdownsample(:));
imagesc(maskdownsample)
mkdir reprocess
for ii=1:length(RP)
    sct_unix(['cp ' num2str(RP(ii)) '.png reprocess/']);
end

%% CHECK REGISTRATION
[list, path] = sct_tools_ls('201*_H*',0,1,1);
for iii=1:length(list) 
    cd(list{iii})
    unix('fslview maps/stats_50um/Preview.nii.gz atlas/register/dest.nii.gz -b 0,2 -t 1 atlas/atlas_clean.nii.gz -b 0,1000 -l render3 -t .0 &')
    cd /Volumes/data_processing/tanguy/Histo/Human
end


%% CREATE MASKS FOR ALL STATS
[list, path] = sct_tools_ls('201*_H*',0,1,1);
for iii=1:length(list)
    cd(list{iii})
    cd maps/stats_50um
stats = load_nii_data('stats_downsample4D.nii');

    figure
    imagesc(stats(:,:,7)); axis image;
    drawnow;
    msgbox({'Use the slider to generate mask' 'Press any key when you are done..'})
    hsl = uicontrol('Style','slider','Min',0,'Max',100,...
        'SliderStep',[1 1]./100,'Value',20,...
        'Position',[20 20 200 20]);
    set(hsl,'Callback',@(hObject,eventdata) sc(stats(:,:,7),'r',medfilt2(stats(:,:,7)>get(hObject,'Value'))))
    pause
    
    mask=stats(:,:,7)>get(hsl,'Value');
    close
save_nii_v2(medfilt2(mask),'mask.nii.gz','stats_downsample4D.nii',2)
cd /Volumes/data_processing/tanguy/Histo/Human
end

% Correct manually
for iii=1:length(list)
    cd(list{iii})
    cd maps/stats_50um
    unix('fslview Preview.nii.gz -l Greyscale mask.nii.gz -l Red -t .5')
    mask = load_nii_data('mask.nii.gz');
    labeledImage = bwlabel(mask,4);
    blobMeasurements = regionprops(labeledImage, 'area');
    % Get all the areas
    allAreas = [blobMeasurements.Area];
    [vv,ind]=max([allAreas]);
    mask = labeledImage ==ind;
    mask = medfilt2(mask,[3 3]);
    save_nii_v2(mask,'mask.nii.gz','mask.nii.gz',2)
    cd ../../../
end

