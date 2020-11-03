clear;
clc;

% Smoothing to apply
FWHM = 3;
isMVPA = false;

cd(fileparts(mfilename('fullpath')));

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));
warning('off');
% addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));
% spm fmri

initEnv();

% we add all the subfunctions that are in the sub directories
opt = getOptionPitchFT();

checkDependencies();

%% Run batches
%reportBIDS(opt);
%bidsCopyRawFolder(opt, 1);

% In case you just want to run segmentation and skull stripping
% Skull stripping is also included in 'bidsSpatialPrepro'
% bidsSegmentSkullStrip(opt);

% bidsSTC(opt);

 bidsSpatialPrepro(opt);

% The following do not run on octave for now (because of spmup)
%  anatomicalQA(opt);
%  bidsResliceTpmToFunc(opt);
%  functionalQA(opt);

 bidsSmoothing(FWHM, opt);

% The following crash on Travis CI
% bidsFFX('specifyAndEstimate', opt, FWHM);
% bidsFFX('contrasts', opt, FWHM);
% bidsResults(opt, FWHM);
