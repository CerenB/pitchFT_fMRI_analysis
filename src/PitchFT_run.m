clear;
clc;

% init the packages
addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

initEnv();

% we add all the subfunctions that are in the sub directories
opt = getOptionPitchFT();

checkDependencies();

%% Run batches
% reportBIDS(opt);
% bidsCopyRawFolder(opt, 1);
% %
% % % In case you just want to run segmentation and skull stripping
% % % Skull stripping is also included in 'bidsSpatialPrepro'
%    bidsSegmentSkullStrip(opt);
% %
tic;
% bidsSTC(opt);
% %

bidsSpatialPrepro(opt);

% Quality control
% anatomicalQA(opt);
% bidsResliceTpmToFunc(opt);
% functionalQA(opt);

% smoothing
FWHM = 3;
bidsSmoothing(FWHM, opt);
toc;

FWHM = 6;
bidsSmoothing(FWHM, opt);
%
% % The following crash on Travis CI
% bidsFFX('specifyAndEstimate', opt, FWHM);
% bidsFFX('contrasts', opt, FWHM);

% bidsResults(opt, FWHM);
% isMVPA = false;
