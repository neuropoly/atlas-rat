%--------------------------------------------------------------------------
% Symmetrization of digital atlas.
% 
% - Loop across each png file, which represents the axial view of the 
%   Paxinos atlas. 
% - Manually delineate the cord and the GM contours, as well as each tract
%   both on the left and right.
% - Symmetrize the generated masks.
% 
% Inputs:
%           original atlas: <LEVEL>.png
% 
% Outputs:
%           atlas WM mask: C1_WM_reg_reg.nii.gz
%           tracts atlas mask: C1_reg_reg_tracts.nii.gz
%
%--------------------------------------------------------------------------

%% MAKE ATLAS WM MASK

% create empty reference space
clear all
ref=zeros(1300,900);
resfinal = 0.05;
save_nii(make_nii(ref,[resfinal resfinal 1]),'ref_template.nii.gz');

% Load atlas image and save as nii

level_name='C1';

img_atlas=imread([level_name,'.png']);
img_atlas=rgb2gray(img_atlas);
img_atlas=imresize(flip(img_atlas',2),[1300,900]);

save_nii_v2(img_atlas,[level_name,'.nii.gz'],'ref_template.nii.gz',16);

% Get WM mask

clear all
file_name = 'C1.nii.gz';
map=load_nii_data(file_name);
map=map./255;
%map=imresize(map,4);


% draw left white matter mask on image
[~,maskWM]=as_tools_getroi(map);

% draw left gray matter mask on image
[~,maskGM]=as_tools_getroi(map);

% generate and save mask
final=zeros(size(maskWM,1),size(maskWM,2));
final(maskWM==true)=1;
final(maskGM==true)=0;           
WM_mask=imresize(final,0.25);
WM_mask=im2bw(WM_mask);

%imshow(WM_mask);
% imwrite(mask_final,mask_name);
WM_mask_2=imresize(WM_mask,[1300,900]);
imwrite(WM_mask_2,'C1_WM.png');
mask_name='C1_WM.nii.gz';
save_nii_v2(WM_mask_2,mask_name,file_name,16);

%% MAKE  ATLAS TRACTS MASK

nbr_of_regions = 7;
file_name = 'C1.nii.gz';

map=load_nii_data(file_name);
map=map./255;
%map=imresize(map,4);

mask=zeros(size(map,1),size(map,2),nbr_of_regions);

for i=1:nbr_of_regions

    % draw tract on img
    disp(['<strong>','*** Please identify the tract ',num2str(i), ' by drawing a polygon around it ',' *** </strong>']);
    [~,mask_i]=as_tools_getroi(map);
    mask(:,:,i)=mask_i.*i;

end

mask_final=sum(mask,3);
%mask_final=imresize(mask_final,0.25);
% mask_final=im2bw(mask_final,0.1);

mask_name='C1.nii.gz';
%mask_name='C1_left_mask_tracts.png';
% imwrite(mask_final,mask_name);
save_nii_v2(mask_final,mask_name,file_name,16);

%% LABELS FOR ATLAS TRACT MASK (step:scatlas_create_labels.m of pipeline)

% create empty reference space
ref=zeros(1301,1301);
resfinal = 0.05;
save_nii(make_nii(ref,[resfinal resfinal 1]),'ref_template_50um_C1.nii.gz');

% put tracts atlas mask into empty reference space
%sct_unix(['sct_register_multimodal -i C1.nii.gz -o C1_reg.nii.gz  -d ref_template_50um_C1.nii.gz -identity 1']);

sct_unix(['sct_register_multimodal -i ' level_name '.nii.gz -o ' level_name '_reg.nii.gz  -d ref_template_50um_' level_name '.nii.gz -identity 1']);


% identify the 2 labels by user interaction, Label #1 in the central canal, label #2 in the anterior median fissure.
src = 'C1_reg.nii.gz';
map = load_nii_data(src);
mask = zeros(size(map));
disp(['<strong>','*** Please identify the 2 labels by selecting the points with the cursor']);
figure
imagesc(map)
[x,y,~] = impixel;
Label1=[y(1),x(1)];
Label2=[y(2),x(2)];
save('Label1','Label1');
save('Label2','Label2');


%% APPLY AFFINE TRANSFO ON ATLAS TRACTS MASK (step:scatlas_transform_to_common_space.m of pipeline)

        
    load('Label1');
    load('Label2');
    x1=Label1(1);
    y1=Label1(2);
    x2=Label2(1);
    y2=Label2(2);

    PixelSize=0.05; 

    % find right orientation of the rotation
    name=[ level_name '.nii.gz'];
    img=load_nii_data(name);
    sizey=size(img,2);

    ym=(sizey-1)/2;
    line_eq = ym;

    if y2>=ym
        y2=-y2;
    end

    % find the translation

    xref1=651;
    yref1=651;

    dx=xref1-x1;
    dy=yref1-y1;
    Translation_Matrix = [1 0 0; 0 1 0; dx dy 1];

    % find the rotation

    A=[0;0]; 
    B=[0;1];
    u= A-B;
    x_u=u(1);
    y_u=u(2);

    C=[x1;y1]; 
    D=[x2;-y2];
    v=D-C;
    x_v=v(1);
    y_v=v(2);

    theta_deg=radtodeg(atan2(x_u*y_v-x_v*y_u,x_u*x_v+y_u*y_v));
    Rotation_Matrix= [cosd(theta_deg) sind(theta_deg) 0;-sind(theta_deg) cosd(theta_deg) 0;0 0 1];

    Transfo_Matrix=Rotation_Matrix;
    Transfo_Matrix(1,3)=dx*PixelSize;
    Transfo_Matrix(2,3)=dy*PixelSize;

    % write the full rigid transformation into a text file
    Ants_writeaffinetransfo(Transfo_Matrix);

    % Apply the rigid transformation on the image using ANTs
    sct_unix(['isct_antsApplyTransforms -d 2 -i ' level_name '_reg.nii.gz -o ' level_name '_reg_reg.nii.gz -t affine_transfo.txt -r ref_template_50um_' level_name '.nii.gz']);
    %sct_unix(['isct_antsApplyTransforms -d 2 -i S3_reg.nii.gz -o S3_reg_reg.nii.gz -t affine_transfo.txt -r ref_template_50um_S3.nii.gz']);


%% DO FLIP FOR ATLAS TRACTS MASK MASK AND SAVE 

img_wm=load_nii_data('C1_reg_reg.nii.gz');
% img_tracts=load_nii_data('C1_left_mask_tracts.nii.gz');

img_wm2=flip(img_wm,1);
img_wm_final=img_wm+img_wm2;
% img_wm_final=im2bw(img_wm_final);
imagesc(img_wm_final);

save_nii_v2(img_wm_final,'C1_reg_reg_tracts.nii.gz', 'C1_reg_reg.nii.gz',16);



%% APPLY TRANSFOS FOR ATLAS WM MASK ALSO AND SAVE 

% put map into empty reference space
%sct_unix(['sct_register_multimodal -i C1_WM.nii.gz -o C1_WM_reg.nii.gz  -d ref_template_50um_C1.nii.gz -identity 1']);


sct_unix(['sct_register_multimodal -i ' level_name '_WM.nii.gz -o ' level_name '_WM_reg.nii.gz  -d ref_template_50um_' level_name '.nii.gz -identity 1']);


% Apply the rigid transformation on the image using ANTs
sct_unix(['isct_antsApplyTransforms -d 2 -i ' level_name '_WM_reg.nii.gz -o ' level_name '_WM_reg_reg.nii.gz -t affine_transfo.txt -r ref_template_50um_' level_name '.nii.gz']);
%sct_unix(['isct_antsApplyTransforms -d 2 -i S3_WM_reg.nii.gz -o S3_WM_reg_reg.nii.gz -t affine_transfo.txt -r ref_template_50um_S3.nii.gz']);

img_wm=load_nii_data('C1_WM_reg_reg.nii.gz');

% img_tracts=load_nii_data('C1_left_mask_tracts.nii.gz');

%% DO FLIP FOR ATLAS WM MASK MASK AND SAVE
img_wm2=flip(img_wm,1);
img_wm_final=img_wm+img_wm2;
img_wm_final=im2bw(img_wm_final);
imagesc(img_wm_final);

save_nii_v2(img_wm_final,'C1_WM_reg_reg.nii.gz', 'C1_reg_reg.nii.gz',16);









