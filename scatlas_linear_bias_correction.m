%--------------------------------------------------------------------------
% Due to the limited spatial resolution, the blurry appearance of the 
% images induces bias in the estimation of the myelin+axon segmentation. 
% Based on high-resolution SEM data, we estimate the bias introduced by the
% automatic axon+myelin segmentation.
% 
% Output (written as file): 
%   correction_factors.mat: includes correcting coefficient variables
%--------------------------------------------------------------------------

% load params
run scatlas_parameters.m

% go to data folder
cd(fullfile(PATH_DATA))

%% MVF Calculation Region 1 dans dossier GT
myelinsegGT_1= imread(IM_BIASCORR_MYELIN_GT); % vrai GT myelin
myelinsegdeep_1= imread(IM_BIASCORR_MYELIN_AS); % fait par axonseg
myelinsegdeep_1= im2uint8(myelinsegdeep_1); 
MVFGT_1=blockproc(myelinsegGT_1,[1200 800],@(bb) sum(bb.data(:)>200)/1200/800);
MVFdeep_1=blockproc(myelinsegdeep_1,[1200 800],@(bb) sum(bb.data(:)>200)/1200/800);

%% AVF Calculation Region 1
AxonsegGT_1= imread(IM_BIASCORR_AXON_GT);
Axonsegdeep_1= imread(IM_BIASCORR_AXON_AS);
Axonsegdeep_1= im2uint8(Axonsegdeep_1);
AVFGT_1=blockproc(AxonsegGT_1,[1200 800],@(bb) sum(bb.data(:)>200)/1200/800);
AVFdeep_1=blockproc(Axonsegdeep_1,[1200 800],@(bb) sum(bb.data(:)>200)/1200/800);

% %% FVF Calculation Region 1
% FVFGT_1= (AVFGT_1+MVFGT_1)*100;
% FVFdeep_1= (MVFdeep_1+AVFdeep_1)*100;

%% Linear Index Values
MVFGT_1= cat(1,MVFGT_1(:));
MVFdeep_1= cat(1, MVFdeep_1(:));
AVFVFGT_1= cat(1, AVFGT_1(:)); %FVFGT_1= cat(1, FVFGT_1(:));
AVFdeep_1= cat(1, AVFdeep_1(:)); %FVFdeep_1= cat(1, FVFdeep_1(:));
AVFGT_1=reshape(AVFGT_1,[12,1]);

%% Bland Altman MVF Region 1 and linear regression fit
% BlandAltman(MVFGT_1*100, MVFdeep_1*100,{'MVF Ground Truth', 'MVF AxonSeg', '%'})
p_mvf = polyfit(MVFdeep_1,MVFGT_1,1);
% x1= linspace(0,0.6);
% y1= polyval(p_mvf, x1);
% plot( MVFGT_1, MVFdeep_1, 'o')
% hold on
% plot(x1, y1)
% hold off

%% Bland Altman AVF Region 1 and linear regression fit
% BlandAltman(AVFGT_1, AVFdeep_1,{'AVF Ground Truth', 'AVF AxonSeg', '%'}) %FVFdeep_1,{'FVF Ground Truth', 'FVF AxonSeg', '%'})
p_avf = polyfit(AVFdeep_1,AVFGT_1,1); % p_fvf = polyfit(FVFdeep_1,FVFGT_1,1);

%% save variables
save('correction_factors', 'p_mvf', 'p_avf')

% %% Apply correction on region 2 MVF
% %Load Region 2
% myelinsegGT_2= imread('r4_groundtruth_myelin.png');
% myelinsegdeep_2= imread('r4_deep_myelin.png');
% myelinsegdeep_2= im2uint8(myelinsegdeep_2); 
% MVFGT_2=blockproc(myelinsegGT_2,[1200 800],@(bb) sum(bb.data(:)>200)/1200/800);
% MVFdeep_2=blockproc(myelinsegdeep_2,[1200 800],@(bb) sum(bb.data(:)>200)/1200/800);
% 
% %Corrected Values
% MVFdeep_2_corrected= p_mvf(1)*MVFdeep_2 + p_mvf(2);
% 
% % x1= linspace(0,0.6);
% % y1= polyval(p_mvf, x1);
% % plot (x1, y1)
% % hold on
% % plot( MVFGT_2, MVFdeep_2, 'o')
% % hold on
% % plot(MVFGT_2, MVFdeep_2_corrected, '+')
% % hold on

%% Re-do Bland Altman Correction MVF Region 2
% BlandAltman(MVFGT_2(:)*100, MVFdeep_2_corrected(:)*100,{'MVF Ground Truth', 'MVF AxonSeg-Corrected', '%'})

%% Apply correction on region 2 AVF 
%Load Region 2
AxonsegGT_2= imread(IM_BIASCORR_AXON_GT_VALIDATE);
Axonsegdeep_2= imread(IM_BIASCORR_AXON_AS_VALIDATE);
Axonsegdeep_2= im2uint8(Axonsegdeep_2);
AVFGT_2=blockproc(AxonsegGT_2,[1200 800],@(bb) sum(bb.data(:)>200)/1200/800);
AVFdeep_2=blockproc(Axonsegdeep_2,[1200 800],@(bb) sum(bb.data(:)>200)/1200/800);

% %% Recalculate Corrected FVF Region 2
% FVFGT_2= (AVFGT_2+MVFGT_2)*100
% FVFdeep_2= (MVFdeep_2+AVFdeep_2)*100
% 
% FVFdeep_2_corrected= FVFdeep_2*p_fvf(1) + p_fvf(2);

% %% Re-do Bland Altman with Corrected values FVF Region 2
% BlandAltman(FVFGT_2(:), FVFdeep_2_corrected(:),{'FVF Ground Truth', 'FVF AxonSeg-Corrected', '%'});

disp "DONE!"
