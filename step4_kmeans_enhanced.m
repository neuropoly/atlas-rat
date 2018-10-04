%--------------------------------------------------------------------------
% Name: step4_kmeans.m
% Date: 2017/11/27
% Description: This step uses to concatenated volume of metrics for each
% level and performs the k means clustering of the data. 
% You can specify the minimum and maximum number of clusters you want to
% generate for the k-means before launching this batch.
% For example: if you want to compute the k-means for k between 3 and 12
% clusters, you can assign the 2 following variables as follows:
% min_nbr_clusters=3;
% max_nbr_clusters=12;
% Default values: min_nbr_clusters=2 and max_nbr_clusters=10.
%--------------------------------------------------------------------------

list=sct_tools_ls('*');% get names of level folders
rng(1); % to have reproductible results for different runs

% verify if user has specified a minimal k value (nbr of clusters to use)
if ~exist('min_nbr_clusters')
    min_nbr_clusters=2;
end

% verify if user has specified a maximal k value (nbr of clusters to use)
if ~exist('max_nbr_clusters')
    max_nbr_clusters=10;
end


% loop over levels
for i=1:length(list)
    
    cd(char(list(i)))
    mkdir('k_means');
    
    % load volume of concatenated metrics template
    Volume4D=load_nii_data('Volume4D.nii.gz');
    Volume3D=squeeze(Volume4D);

    % load mask template output to filter features (only white matter used)
    mask=load_nii_data('templategen/template/T_template0.nii.gz');
    mask=im2bw(mask);
    
    % smooth feature maps before kmeans
    
    gaussian_smoothing = fspecial('gaussian', [5,5], 1);
    
    for nn=1:size(Volume3D,3)
        Volume3D(:,:,nn)=imfilter(Volume3D(:,:,nn),gaussian_smoothing); 
    end    
    
    
    
    % get the features for the k-means
    features=zeros(size(Volume3D,3),sum(mask(:)));
    
    for aa=1:size(features,1)
        metric_tmp=squeeze(Volume3D(:,:,aa));
        features(aa,:) = metric_tmp(mask(:)); 
    end

    features=features';
        
    cd k_means
    
    Silhouette_mean=zeros(1,max_nbr_clusters-1);
    
    disp(['Computing k means for level ' char(list(i)) '. - - - - -']);
    
    % for each number of clusters, compute k-means
    for k=min_nbr_clusters:max_nbr_clusters
        
        disp(['Computing k means for ' num2str(k) ' clusters.']);
        
        % compute k-means
        h=figure;
        result = zeros(size(metric_tmp),'uint8');
        result(~~mask) = kmeans(features,k);
        
        % clean results with mode with 3x3 kernel
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
        %file_name2=['kmeans_' num2str(k) '.tif'];
        saveas(h,file_name);
        %imwrite(resultfilt,file_name2);
        A=zeros(k,size(Volume3D,3)*2);
        close(h);

        % compute mean and std values for each metric for each cluster
        for ii=1:k
            
            tract=zeros(151,151);
            tract(resultfilt==ii)=1;
            tract=im2bw(tract);
            
            for aaa=1:size(Volume3D,3)
            
                tmp=Volume3D(:,:,aaa);
                mean_metric=mean(tmp(tract));
                std_metric=std(tmp(tract));
                
                A(ii,aaa*2-1:aaa*2)=[mean_metric,std_metric];
            
            end
        end

        % save metrics means and stds as tables with corresponding name
        T = array2table(A,'VariableNames',{'AD_mean','AD_std','AED_mean','AED_std','GR_mean','GR_std','MT_mean','MT_std','MVF_mean','MVF_std'});
        save(['Stats_' num2str(k) ],'T');
        
        % save boxplot metrics for each k and each metric
        
        for bbb=1:size(Volume3D,3)
            x = 1:1:k;
            y = A(:,bbb*2-1);
            h2=scatter(x,y);
            hold on;
            err = A(:,bbb*2);
            errorbar(x, y, err, 'LineStyle','none');
            xlabel('cluster ID');
            title(['Mean and std values per cluster for metric ' num2str(bbb)]);
            file_name=['kmeans_scatter_' num2str(k) '_metric' num2str(bbb) '.png'];
            saveas(h2,file_name);
            hold off;
        end

        % compute silhouette mean to identify optimized number of clusters
        test=kmeans(features,k,'Distance','cityblock');
        [silh]=silhouette(features,test,'cityblock');
        %h=gca;
        cluster_mean=mean(silh);
        Silhouette_mean(1,k-1)=cluster_mean;

    end

    % plot and save silhouette plot
    h=figure;
    k_values=min_nbr_clusters:1:max_nbr_clusters;
    plot(k_values,Silhouette_mean);
    xlabel('k value (number of clusters)');
    ylabel('Silhouette mean metric');
    saveas(h,'silhouette.png');
    close(h);
      
    cd ../..
  
end
    
