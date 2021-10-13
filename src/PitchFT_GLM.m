clear;
clc;

pth = fullfile(fileparts(mfilename('fullpath')), '..');
addpath(pth);

% add FFT analysis lib
addpath(genpath(fullfile(pth, 'lib', 'FFT_fMRI_analysis')));

% add dice coeff function repo
addpath(genpath('/Users/battal/Documents/GitHub/CPPLab/spmScripts'));

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

%% DICE Coeff Calculation
% % gets result thresholded + binarize, then calculate the dice coeff

% loop to calculate all the contrasts across runs

% note that thresholded SPM saving option gives NaN values in thresholded
% spmT map which causes a crash in tmap->zmap conversion.
% a work around would be: first convert to zmap and then threshold it
% another work around is binarise the tmaps after thresholding it and do
% not use zmap conversion. That is what we are doing

FWHM = 2;

pvalues = [0.001, 0.0001, 0.00001];
baseContrastName = 'A1_gt_B3_run_';
runs = 1:9;

for ipvalue = 1:length(pvalues)

  pvalue = pvalues(ipvalue);

  for iRun = runs

    contrastName = [baseContrastName, num2str(runs(iRun))];

    % define the contrast + threshold
    opt =  getOptionPitchFT_results(contrastName, pvalue);

    % calculate the tmaps +binarised masks
    bidsResults(opt, FWHM);

  end
end

% assuming the previous step is independent (was performed in another
% matlab session) of the below step.
% so we need to call getOptionPitchFT_results again to load the desired
% parameters.
%
% read the binarised masks and calculate dice coeff across runs
opt = getOptionPitchFT_results('A1_gt_B3_run_1', 0.001);
% opt = getOptionPitchFT_results(contrastName, pvalue);
FWHM = 2;
[allCoeff, meanCoeff] = calculateDiceCoeff(opt, FWHM);

%% Calculate the peak SNR and num of supr-thresholded voxels
% that would be calculating the SNR in GLM and FFT analysis both.
% in here we will look at GLM one

% peak SNR

% whole cortex - binarise mask voxel count for A1 vs. B3 contrast (subject
% level)
FWHM = 2;
pvalue = 0.0001; % from Gao etal.,2018
opt =  getOptionPitchFT_results('A1_gt_B3', pvalue);

% calculate the tmaps +binarised masks
bidsResults(opt, FWHM);

% then find the binarise contrast image + count
% such sum(image(:));
