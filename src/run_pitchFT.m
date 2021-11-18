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

% get all the parameters needed
opt = getOptionPitchFT();

%% FFT analysis

opt.maskType = 'whole-brain';
[opt.maskFile] = getMaskFile(opt);

% want to save each run FFT results
opt.saveEachRun = 1;
% do not save/run FT on averaged RUNs
opt.calculateAverage = 0;
for iSmooth = 2 % 0 2 3 or 6mm smoothing

  opt.FWHM = iSmooth;

  opt.nStepsPerPeriod = 4;
  calculateSNR(opt);
end


%% group analysis
% for now only in MNI
% individual space would require fsaverage
opt.nStepsPerPeriod = 4;
opt.FWHM = 0;
opt = groupAverageSNR(opt);


%% calculate Dice coeff across FT runs
opt.FWHM = 2;
opt.nStepsPerPeriod = 4;
opt.maskType = 'whole-brain';
opt.anatMask = 0;
contrastName = 'A1GtB3Run'; %bids name of the GLM contrast
[allCoeff, meanCoeff] = calculateDiceCoeffFT(opt,contrastName);


%% let's do ROI-FFT
%let's load masks
opt.maskType = 'freesurfer';
opt = getMaskFile(opt);
% remember there's also opt.maskLabel with the roi names

% let's calculate the FFT on those masks
opt.FWHM = 2;
opt.nStepsPerPeriod = 4;
% want to save each run FFT results
opt.saveEachRun = 0;
% do not save/run FT on averaged RUNs
opt.calculateAverage = 1;
% do not save harmonic.nii file
opt.saveHarmonicImg.do = 0;
% ... and GO !
calculateSNR(opt);

%% now read max z-scores across rois
% ROIs
% mask the whole-brain spmT map with ROIs to get highest z score values
% 1. peak SNR
opt.maskType = 'freesurfer'; %'hmat'
% opt.maskType = 'whole-brain'; % this is for calculating full-brain
% z-score
opt = getMaskFile(opt);

% this is where we stop - still calculatePeakSNR is in WIP
opt.FWHM = 2;
opt.nStepsPerPeriod = 4;
calculatePeakSNR(opt);

%% group level visualisation - threshold and save the maps 
% later on workbench to visualise 
opt.nStepsPerPeriod = 4;
opt.FWHM = 6;
pvalue = 1e-3; % 1e-6;
opt.save.zmap = true;
groupLevelzMapThreshold(opt, pvalue)










