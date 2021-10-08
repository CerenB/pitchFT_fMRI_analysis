clear;
clc;

pth = fullfile(fileparts(mfilename('fullpath')), '..');
addpath(pth);

% add FFT analysis lib
addpath(genpath(fullfile(pth, 'lib', 'FFT_fMRI_analysis')));

%% set paths
% set spm
[~, hostname] = system('hostname');
warning('off');

if strcmp(deblank(hostname), 'tux')
  addpath(genpath('/home/tomo/Documents/MATLAB/spm12'));
elseif strcmp(deblank(hostname), 'mac-114-168.local')
  warning('off');
  addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));
end

% add cpp repo
run ../lib/CPP_BIDS_SPM_pipeline/initCppSpm.m;

% we add all the subfunctions that are in the sub directories
opt = getOptionPitchFT();


%% Run batches
% reportBIDS(opt);
% bidsCopyRawFolder(opt, 1);
% %
% % % In case you just want to run segmentation and skull stripping
% % % Skull stripping is also included in 'bidsSpatialPrepro'
%    bidsSegmentSkullStrip(opt);
% %
tic;
bidsSTC(opt);
% %

bidsSpatialPrepro(opt);

% Quality control
% anatomicalQA(opt);
% bidsResliceTpmToFunc(opt);
% functionalQA(opt);

% smoothing
FWHM = 2;
bidsSmoothing(FWHM, opt);

FWHM = 3;
bidsSmoothing(FWHM, opt);

FWHM = 6;
bidsSmoothing(FWHM, opt);

toc;
%
% % The following crash on Travis CI
bidsFFX('specifyAndEstimate', opt, FWHM);
bidsFFX('contrasts', opt, FWHM);

% in the future below would work for RUN level
% % get results thresholded + binarize
FWHM = 2;
opt =  getOptionPitchFT_results();
bidsResults(opt, FWHM);

% loop to calculate all the contrasts across runs
pvalues =[0.001, 0.0001, 0.00001];
baseContrastName = 'A1_gt_B3_run_';
runs = 1:9;
for ipvalue = 1:length(pvalues)
    
    pvalue = pvalues(ipvalue);
    
    for iRun = runs
        
        contrastName = [baseContrastName, num2str(runs(iRun))];
        opt =  getOptionPitchFT_results(contrastName, pvalue);
        
        %caulate the tmaps 
        bidsResults(opt, FWHM);
        
    end
end



% isMVPA = false;
