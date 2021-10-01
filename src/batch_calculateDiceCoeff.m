function batch_calculateDiceCoeff
% this function should be a batch for calculating dice coefficient
% last edit on 29.09.2021

% find the 


% this is a small function to read/load & rename the t-maps and convert
% them into z-maps. 

%resultReport = opt.result.Steps;
opt = getOptionPitchFT_results;
thresholdP = opt.result.Steps.Contrasts.p;

% which smoothing/files/spm.mat to take?
FWHM = 2; 

% all pitch 
df = 873; 

% run number
runNum = 9; % if we decide make loop for all the tmaps


% check if tmap --> zmap --> binarisation 
% is different than tmap --> binarisation (for dice coeff)

% making contrast in contrast manager:
% Run1_A1_gt_B3: 1 0 -1 (spmT_0044.nii)
% Run2_A1_gt_B3: 0 0 0 0 0 0 0 0 0 0 1 0 -1 (spmT_0045.nii)

% note that thresholded SPM saving option gives NaN values in thresholded
% spmT map which causes a crash in tmap->zmap conversion.
% a work around would be: first convert to zmap and then threshold it
% another work around is binarise the tmaps after thresholding it and do
% not use zmap conversion 


for iSub = 1:numel(opt.subjects)
    
    % find the tmaps to load
    subLabel = opt.subjects{iSub};
    imagePath =  getFFXdir(subLabel, FWHM, opt);
    
    % if bidsResults work to create desired contrast, use below:
    %imageName = returnName(subLabel, resultReport, opt);
    % %image = 'sub-001_task-RhythmBlock_space-MNI_desc-AllCateg_label-0023_p-0001_k-0_MC-none_spmT.nii';

    % for now use manual definition of Tmaps
    imageName1 = 'pvalue_0001_spmT_0044.nii';
    
%     % if bidsResults work to create desired contrast, use below:
%     % add suffix to load image
%     imageNameLoad = [imageName, '_spmT.nii'];
%     % save image as
%     imageNameSave = [imageName, '_spmZ.nii'];

%     hdr1 = spm_vol(fullfile(imagePath, imageNameLoad));

    % do the t to z-map conversion here
    outputImage = convertTstatsToZscore(imageName1, imagePath, df);

    
    % then save the z-map
    % do we need this part? convertTstatsToZscore is already saving
    
    
    
    
end

end


function name = returnName(sub, result, opt)

contrastName = result.Contrasts(1).Name;
correction = result.Contrasts(1).MC;
pvalue = result.Contrasts(1).p;
clusterSize = result.Contrasts(1).k;
tLabel = '0023';

name = ['sub-', sub, ...
    '_task-', opt.taskName, ...
    '_space-', opt.space, ...
    '_desc-', contrastName, ...
    '_label-', tLabel, ...
    '_p-', num2str(pvalue), ...
    '_k-', num2str(clusterSize), ...
    '_MC-', correction];

name = strrep(name,'.', '');


end









