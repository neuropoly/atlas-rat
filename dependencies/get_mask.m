

img=load_nii_data('Sample1_MVF.nii');
% imshow(img);

% WM
[~,maskWM]=as_tools_getroi(img);
% GM
[~,maskGM]=as_tools_getroi(img);

final=zeros(size(maskWM,1),size(maskWM,2));
final(maskWM==true)=1;
final(maskGM==true)=0;
WM_mask=im2bw(final);
imshow(WM_mask);

imwrite(WM_mask,'mask.png');
save_nii_v2(WM_mask,'mask.nii.gz','Sample1_MVF.nii',64);


