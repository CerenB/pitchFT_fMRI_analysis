clear;
clc;

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
bidsCopyRawFolder(opt, 1);
% %
% % % In case you just want to run segmentation and skull stripping
% % % Skull stripping is also included in 'bidsSpatialPrepro'
%    bidsSegmentSkullStrip(opt);
% %
bidsSTC(opt);
% %
bidsSpatialPrepro(opt);

% Quality control
anatomicalQA(opt);
bidsResliceTpmToFunc(opt);
functionalQA(opt);

% smoothing
FWHM = 3;
bidsSmoothing(FWHM, opt);
%
% % The following crash on Travis CI
% bidsFFX('specifyAndEstimate', opt, FWHM);
% bidsFFX('contrasts', opt, FWHM);

% bidsResults(opt, FWHM);
% isMVPA = false;
