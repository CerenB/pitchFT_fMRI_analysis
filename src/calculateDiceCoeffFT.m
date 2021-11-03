function [allCoeff, meanCoeff] = calculateDiceCoeffFT(opt, contrastName)

% clear;
% clc;
% 
% warning('off');
% addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));
% 
% run ../lib/CPP_BIDS_SPM_pipeline/initCppSpm.m;
% 

%%

% save path
outputDir = returnOutputPath(opt, opt.FWHM, contrastName);
  
% save results
savefileMat = fullfile(outputDir, ...
    ['WholeBrain_FFT', ...
    '_N-', num2str(numel(opt.subjects)), ...
    '_p-All', ...
    '_', datestr(now, 'yyyymmddHHMM'), '.mat']);

savefileCsv = fullfile(outputDir, ...
    ['WholeBrain_FFT', ...
    '_N-', num2str(numel(opt.subjects)), ...
    '_p-All',  ...
    '_', datestr(now, 'yyyymmddHHMM'), '.csv']);

savefileAllSubjectCsv = fullfile(outputDir, ...
    ['AllSubjectWholeBrain_FFT', ...
    '_N-', num2str(numel(opt.subjects)), ...
    '_p-All',  ...
    '_', datestr(now, 'yyyymmddHHMM'), '.csv']);

maskType = opt.maskType;


% to keep only values above a certain threshold
pvalues = [0.001, 0.0001, 0.00001, 0.000001, 0.0000001,...
           0.00000000001, 0.0000000000001, ...
           0.000000000000001, 0.00000000000000001, ...
           0.0000000000000000001, 0.0000000000000000000001]; 
%correspond to z-values:
%threshold = round(abs(norminv(pvalues)),2);
threshold = [3.09, 3.72, 4.26, 4.75, 5.2,...
             6.71, 7.35, 7.94, 8.49, 9.01, 9.74];
    
% here we read already thresholded & binarize tmaps (assuming that tmaps
% would not be different than zmaps as long as the threshold is the same

count = 1; % counter to save all dice coefficients
kount = 1; %counter to save all subject's mean dice across z-scores

for iSub = 1:numel(opt.subjects)
   
    % find the output directory
     subLabel = opt.subjects{iSub};
     imagePath = getFFTdir(opt, subLabel);

     % find zMap to binarise
     patternZMap = [maskType, '*SNR*_bold.nii'];
     zMapFiles = dir(fullfile(imagePath, patternZMap));
     zMapFiles([zMapFiles.isdir]) = [];
    
    % Threshold  Zmap into a binary mask
    for iThres = 1: length(threshold)
        for iRun = 1: length(zMapFiles)
            
            zMap = fullfile(imagePath, zMapFiles(iRun).name);
            binaryName = thresholdToMask(zMap, threshold(iThres));
            renameBinary(binaryName, threshold(iThres));
        end
    end

    % find binarised masks to calculate Dice coeff
    for iThres = 1: length(threshold)
        
        % find mask/binarised images
        patternThres = strrep(num2str(threshold(iThres)), '.', '');

        patternBinary = [maskType, '_SNR_', '*', 'z-', patternThres, '_mask.nii'];
        binaryMapFiles = dir(fullfile(imagePath, patternBinary));
        binaryMapFiles([binaryMapFiles.isdir]) = [];
        
        % make all the combinations of runs
        indices = nchoosek(1:length(binaryMapFiles), 2);
        coeff = nan(1, length(indices));

        
        % loop for calculating dice coeff across runs
        for iPairs = 1:length(indices)
            
            image1 = fullfile(imagePath, binaryMapFiles(indices(iPairs, 1)).name);
            image2 = fullfile(imagePath, binaryMapFiles(indices(iPairs, 2)).name);
            [coeff(iPairs), voxNb1, voxNb2] = nii_dice(image1, image2);
            fprintf('Dice coeff of Sub%d Run%d and Run%d is %f\n', iSub, ...
                indices(iPairs, 1), indices(iPairs, 2), coeff(iPairs));
            
            allCoeff(count).coeff = coeff(iPairs);
            allCoeff(count).subID = iSub;
            allCoeff(count).run1 = indices(iPairs, 1);
            allCoeff(count).run2 = indices(iPairs, 2);
            allCoeff(count).voxelNb1 = voxNb1;
            allCoeff(count).voxelNb2 = voxNb2;
            allCoeff(count).zvalue = threshold(iThres);
            allCoeff(count).pvalue = pvalues(iThres);
            allCoeff(count).label = contrastName;
            allCoeff(count).img1 = binaryMapFiles(indices(iPairs, 1)).name;
            allCoeff(count).img2 = binaryMapFiles(indices(iPairs, 2)).name;
            count = count + 1;
        end
        
        % calculate the mean dice coeff
        meanCoeff(kount).coeff =  mean(coeff, 'omitnan');
        meanCoeff(kount).coeffisNan =  mean(coeff);
        meanCoeff(kount).subID = iSub;
        meanCoeff(kount).zvalue = threshold(iThres);
        meanCoeff(kount).pvalue = pvalues(iThres);
        kount = kount +1;
        
    end
    % save the dice coeff value
    save(savefileMat, 'meanCoeff', 'allCoeff');
    % only save the mean values for plotting
    writetable(struct2table(meanCoeff), savefileCsv);
    
    writetable(struct2table(allCoeff), savefileAllSubjectCsv);
    
end

end

function outputDir = returnOutputPath(opt, FWHM, contrastName)
  % makes directory is not there
  main = fullfile(opt.derivativesDir, '..', 'rnb_fft', 'group', 'dice-coeff');

  if ~exist(main, 'dir')
    mkdir(main);
  end

  outputDir = fullfile(main, ['task-', opt.taskName, ...
                              '_space-', opt.space, ...
                              '_FWHM-', num2str(FWHM), ...
                              '_desc-', contrastName]);

  if ~exist(outputDir, 'dir')
    mkdir(outputDir);
  end

end

function outputImage = renameBinary(inputImage, threshold)

  basename = spm_file(inputImage, 'basename');
  parts = strsplit(basename, '_');
  parts{6} = [parts{6}, '_z-', ...
      bids.internal.camel_case(num2str(threshold))];
  newName = [strjoin(parts, '_'),'.nii'];

  outputImage = spm_file(inputImage, 'filename', newName);

  movefile(inputImage, outputImage);
  
end