% idea is to have a small function to load and calculate the maximum
% FFT z-score across different rois (whole-brain, aud, BG, premotor...)

% also maybe add GLM tstats convert into z-score  to find the maximum

%% set output folder/name

 % setup output directory
fftDir = fullfile(opt.derivativesDir, '..', 'rnb_fft');
destinationDir = fullfile(fftDir, 'group');
 
savefileMat = fullfile(destinationDir, ...
    [opt.taskName, ...
    'Zscore_', ...
    'space-', opt.space,...
    '_s', num2str(opt.funcFWHM), ...
    '_', datestr(now, 'yyyymmddHHMM'), '.mat']);

savefileCsv = fullfile(destinationDir, ...
    [opt.taskName, ...
    'Zscore_', ...
    'space-', opt.space,...
    '_s', num2str(opt.funcFWHM), ...
    '_', datestr(now, 'yyyymmddHHMM'), '.csv']);

    
for iSub = 1:numel(opt.subjects)
    
    subLabel = opt.subjects{iSub};
    
 for iMask = 1: length(maskNames)
     
     inputMaskPath = getFFTdir(opt, subLabel);
     
     roiList = spm_select('FPlist', ...
            fullfile(inputMaskPath), ...
            '^*._AvgZTarget_.*bold.nii.*$');
        roiList = cellstr(roiList);
 end
    
end