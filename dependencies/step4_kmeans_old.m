
% (pixels x, pixels y, metric, sample)
Volume4D=zeros(151,151,5,4);


%Lexie7
list={'Sample1/Sample1_AD_reg_reg.nii.gz','Sample1/Sample1_AED_reg_reg.nii.gz','Sample1/Sample1_GR_reg_reg.nii.gz','Sample1/Sample1_MT_reg_reg.nii.gz','Sample1/Sample1_MVF_reg_reg.nii.gz'};
for i=1:size(list,2)
    name=char(list(i));
    Volume4D(:,:,i,1)=load_nii_data(name);
end

%Lexie10
list={'Sample2/Sample2_AD_reg_reg.nii.gz','Sample2/Sample2_AED_reg_reg.nii.gz','Sample2/Sample2_GR_reg_reg.nii.gz','Sample2/Sample2_MT_reg_reg.nii.gz','Sample2/Sample2_MVF_reg_reg.nii.gz'};
for i=1:size(list,2)
    name=char(list(i));
    Volume4D(:,:,i,2)=load_nii_data(name);
end

%Maxo2
list={'sample3/AD_reg_reg_reg.nii.gz','sample3/AED_reg_reg_reg.nii.gz','sample3/GR_reg_reg_reg.nii.gz','sample3/MT_reg_reg_reg.nii.gz','sample3/MVF_reg_reg_reg.nii.gz'};
for i=1:size(list,2)
    name=char(list(i));
    Volume4D(:,:,i,3)=load_nii_data(name);
end

%Maxo3
list={'sample4/AD_reg_reg_reg.nii.gz','sample4/AED_reg_reg_reg.nii.gz','sample4/GR_reg_reg_reg.nii.gz','sample4/MT_reg_reg_reg.nii.gz','sample4/MVF_reg_reg_reg.nii.gz'};
for i=1:size(list,2)
    name=char(list(i));
    Volume4D(:,:,i,4)=load_nii_data(name);
end

save('Volume4D_init','Volume4D');


imshow(Volume4D(:,:,3,3));

%% create 4D volume AFTER averaging (average)

average_AD=(Volume4D(:,:,1,1)+Volume4D(:,:,1,2)+Volume4D(:,:,1,3)+Volume4D(:,:,1,4))./4;
imagesc(average_AD);

average_AED=(Volume4D(:,:,2,1)+Volume4D(:,:,2,2)+Volume4D(:,:,2,3)+Volume4D(:,:,2,4))./4;
imagesc(average_AED);

average_GR=(Volume4D(:,:,3,1)+Volume4D(:,:,3,2)+Volume4D(:,:,3,3)+Volume4D(:,:,3,4))./4;
imagesc(average_GR);

average_MT=(Volume4D(:,:,4,1)+Volume4D(:,:,4,2)+Volume4D(:,:,4,3)+Volume4D(:,:,4,4))./4;
imagesc(average_MT);

average_MVF=(Volume4D(:,:,5,1)+Volume4D(:,:,5,2)+Volume4D(:,:,5,3)+Volume4D(:,:,5,4))./4;
imagesc(average_MVF);





average_AD=(Volume4D(:,:,1,1)+Volume4D(:,:,1,2))./2;
imagesc(average_AD);

average_AED=(Volume4D(:,:,2,1)+Volume4D(:,:,2,2))./2;
imagesc(average_AED);

average_GR=(Volume4D(:,:,3,1)+Volume4D(:,:,3,2))./2;
imagesc(average_GR);

average_MT=(Volume4D(:,:,4,1)+Volume4D(:,:,4,2))./2;
imagesc(average_MT);

average_MVF=(Volume4D(:,:,5,1)+Volume4D(:,:,5,2))./2;
imagesc(average_MVF);

save('Volume4D_average','average_*');

%% mask


img=load_nii_data('Sample2_AD.nii');
img=uint8(img);
% WM
[~,maskWM]=as_tools_getroi(img);
% GM
[~,maskGM]=as_tools_getroi(img);

final=zeros(size(maskWM,1),size(maskWM,2));
final(maskWM==true)=1;
final(maskGM==true)=0;
imshow(final);
save_nii_v2(final,'mask.nii.gz','Sample2_AD.nii',64);

% mask=imread('WM_GM.png');
% 
% mask2=zeros(size(mask,1),size(mask,2));
% for i=1:size(mask,1)
%     for j=1:size(mask,2)
%         if mask(i,j)==255, mask2(i,j)=true; end; 
%     end
% end
% 
% % go to maps folder to launch this
% map=load_nii_data('test.nii.gz');
% % map=map;
% mask = im2bw(mask2);
% imshow(mask);


%% mask for kmeans

img=load_nii_data('Sample1_AD_reg_reg.nii.gz');
img=uint8(img);
% WM
[~,maskWM]=as_tools_getroi(img);
% GM
[~,maskGM]=as_tools_getroi(img);

final=zeros(size(maskWM,1),size(maskWM,2));
final(maskWM==true)=1;
final(maskGM==true)=0;
imshow(final);


mask=im2bw(final);
% save_nii_v2(final,'mask.nii.gz','Sample1_AD_reg_reg.nii.gz',64);

% mask=imread('WM_GM.png');
% 
% mask2=zeros(size(mask,1),size(mask,2));
% for i=1:size(mask,1)
%     for j=1:size(mask,2)
%         if mask(i,j)==255, mask2(i,j)=true; end; 
%     end
% end
% 
% % go to maps folder to launch this
% map=load_nii_data('test.nii.gz');
% % map=map;
% mask = im2bw(mask2);
% imshow(mask);




%% 2) Prepare input matrix of selected map features

% list of features to use for k-means clustering
load('Volume4D_average.mat');

features=zeros(5,sum(mask(:)));
features(1,:) = average_AD(mask(:)); 
features(2,:) = average_AED(mask(:)); 
features(3,:) = average_GR(mask(:)); 
features(4,:) = average_MT(mask(:)); 
features(5,:) = average_MVF(mask(:)); 

data=features';

%% 3) Apply k-means  clustering and save results on current folder

for k=2:5
    h=figure;

    result = zeros(size(average_AD),'uint8');
    result(~~mask) = kmeans(data,k);
    imagesc(result);

    % filter
    fun = @(x) mode(x(:)); 
    resultfilt = nlfilter(result,[3 3],fun);
    resultfilt=resultfilt';
    imagesc(resultfilt);
    colormap('hot');
    
    ticks=1:1:k;
    labels=cell(1,k);
    
    for ii=1:k
        labels{ii}=num2str(ii);
    end
    
    colorbar('YTick',ticks,'YTickLabels',labels,'Location','SouthOutside');
    pbaspect([1 1 1]);
    
    file_name=['kmeans_fig_' num2str(k) '.png'];
    file_name2=['kmeans_' num2str(k) '.png'];
    saveas(h,file_name);
    imwrite(resultfilt,file_name2);
    A=zeros(k,10);
    for ii=1:k
        tract=zeros(151,151);
        tract(resultfilt==ii)=1;
        tract=im2bw(tract);
        
        mean_AD=mean(average_AD(tract));
        mean_AED=mean(average_AED(tract));
        mean_GR=mean(average_GR(tract));
        mean_MT=mean(average_MT(tract));
        mean_MVF=mean(average_MVF(tract));

        std_AD=std(average_AD(tract));
        std_AED=std(average_AED(tract));
        std_GR=std(average_GR(tract));
        std_MT=std(average_MT(tract));
        std_MVF=std(average_MVF(tract));
        
        
        A(ii,:)=[mean_AD,std_AD,mean_AED,std_AED,mean_GR,std_GR,mean_MT,std_MT,mean_MVF,std_MVF];

    end
    
        T = array2table(A,'VariableNames',{'AD_mean','AD_std','AED_mean','AED_std','GR_mean','GR_std','MT_mean','MT_std','MVF_mean','MVF_std'});
        save(['Stats_' num2str(k) ],'T');
    
    
end

%% Silhouette mean : find the optimal Kmeans

Silhouette_mean=zeros(1,19);

for k=2:20
    test=kmeans(data,k,'Distance','cityblock','Display','iter');
    [silh,h]=silhouette(data,test,'cityblock');
    h=gca;
    cluster_mean=mean(silh);
    Silhouette_mean(1,k-1)=cluster_mean;
end

h=figure;
k_values=2:1:20;
plot(k_values,Silhouette_mean);
xlabel('k value (number of clusters)');
ylabel('Silhouette mean metric');
saveas(h,'silhouette.png');















